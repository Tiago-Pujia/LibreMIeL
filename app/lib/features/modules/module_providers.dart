import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/network/miel_server_status_classifier.dart';
import '../../core/parsers/miel_parsers.dart';
import '../navigation/navigation_history_entry.dart';

/// Tipo de bandeja de Mensajería en MIeL.
enum MensajeriaBoxKind { entrada, salida, borradores, favoritos }

// --- Bfcache de sesión en memoria (Fase 12) ---
int _sessionBfCacheGeneration = -1;
final LinkedHashMap<String, String> _sessionBfHtmlCache =
    LinkedHashMap<String, String>();
final Set<String> _forceLiveCacheKeys = <String>{};
final Set<String> _bfCacheExpectedKeys = <String>{};

/// Marca una o más claves para restauración garantizada desde el bfcache en memoria
/// al retroceder o avanzar en el historial de navegación (Fase 12).
void markBfCacheRestoreKeys(Iterable<String> keys) {
  _bfCacheExpectedKeys.addAll(keys);
}

/// Marca una o más claves para forzar consulta en vivo en la red ignorando el caché
/// pasivo (Ctrl + Shift + R / Ctrl + F5).
void markForceLiveCacheKeys(Iterable<String> keys) {
  _forceLiveCacheKeys.addAll(keys);
}

/// Resultado estructurado de una consulta HTML interactiva indicando si provino
/// de red en vivo o del caché local offline (Fase 9).
class InteractiveHtmlFetchResult {
  const InteractiveHtmlFetchResult({
    required this.html,
    required this.fromCache,
  });

  final String html;
  final bool fromCache;
}

/// Ejecuta una consulta HTML interactiva con recuperación automática silenciosa
/// de sesión (Fase 5) y contingencia/fallback al caché local si MIeL está caído
/// o no hay conexión a internet (Fase 9), retornando si provino de caché.
Future<InteractiveHtmlFetchResult> fetchInteractiveHtmlResultWithAuth(
  Ref ref,
  Future<String> Function(MielInteractiveReader reader) fetcher, {
  String? cacheKey,
  String idComision = '',
  String module = '',
}) async {
  var offlineEnabled = false;
  var isAuthenticated = false;
  var maxCacheMb = 100;
  try {
    final session = ref.read(appSessionProvider);
    offlineEnabled = session.offlineModeEnabled;
    isAuthenticated = session.isAuthenticated;
    maxCacheMb = session.offlineCacheMaxMb;
  } catch (_) {}

  final canUseOfflineCache = offlineEnabled && isAuthenticated;

  int sessionGen = 0;
  try {
    sessionGen = ref.watch(sessionGenerationProvider);
  } catch (_) {}
  if (_sessionBfCacheGeneration != sessionGen) {
    _sessionBfHtmlCache.clear();
    _forceLiveCacheKeys.clear();
    _bfCacheExpectedKeys.clear();
    _sessionBfCacheGeneration = sessionGen;
  }

  final isForceLive = cacheKey != null && _forceLiveCacheKeys.remove(cacheKey);

  if (cacheKey != null && !isForceLive) {
    final isExpectedBf = _bfCacheExpectedKeys.remove(cacheKey);
    final inMemoryHtml = _sessionBfHtmlCache[cacheKey];
    if (inMemoryHtml != null && (isExpectedBf || canUseOfflineCache)) {
      _sessionBfHtmlCache.remove(cacheKey);
      _sessionBfHtmlCache[cacheKey] = inMemoryHtml;
      return InteractiveHtmlFetchResult(html: inMemoryHtml, fromCache: true);
    }
  }

  void tryReportStatus(MielServerStatus status) {
    try {
      ref.read(appSessionProvider.notifier).reportServerStatus(status);
    } catch (_) {}
  }

  Future<InteractiveHtmlFetchResult?> tryReadOfflineCache() async {
    if (!canUseOfflineCache || cacheKey == null) return null;
    final db = ref.read(databaseProvider);
    final cached = await db.getOfflinePage(cacheKey);
    if (cached != null && cached.htmlContent.isNotEmpty) {
      _sessionBfHtmlCache.remove(cacheKey);
      _sessionBfHtmlCache[cacheKey] = cached.htmlContent;
      return InteractiveHtmlFetchResult(
        html: cached.htmlContent,
        fromCache: true,
      );
    }
    return null;
  }

  try {
    final reader = await ref.read(mielInteractiveReaderProvider.future);
    var html = await fetcher(reader);

    if (isLikelyLoginRedirectHtml(html)) {
      final recovered = await _recoverInteractiveSession(ref, reader);
      if (recovered) {
        html = await fetcher(reader);
      }
      if (isLikelyLoginRedirectHtml(html)) {
        throw const MielSessionExpiredException();
      }
    }

    if (isLikelyMielMaintenanceHtml(html)) {
      throw const HttpException(
        'MIeL devolvió página de mantenimiento o error HTTP',
      );
    }

    tryReportStatus(MielServerStatus.online);

    if (cacheKey != null &&
        html.isNotEmpty &&
        !isLikelyLoginRedirectHtml(html)) {
      _sessionBfHtmlCache.remove(cacheKey);
      _sessionBfHtmlCache[cacheKey] = html;
      while (_sessionBfHtmlCache.length > 40) {
        _sessionBfHtmlCache.remove(_sessionBfHtmlCache.keys.first);
      }
    }

    // Si el modo offline está activo con sesión autenticada y hay cacheKey, persistir copia local
    if (canUseOfflineCache &&
        cacheKey != null &&
        html.isNotEmpty &&
        !isLikelyLoginRedirectHtml(html)) {
      final db = ref.read(databaseProvider);
      unawaited(() async {
        final mediaBytes = await ref
            .read(offlineMediaServiceProvider)
            .getTotalCachedMediaBytes();
        await db.putOfflinePage(
          cacheKey: cacheKey,
          idComision: idComision,
          module: module,
          htmlContent: html,
          maxCacheMb: maxCacheMb,
          reservedBytes: mediaBytes,
        );
      }());
    }

    return InteractiveHtmlFetchResult(html: html, fromCache: false);
  } on MielSessionExpiredException {
    // Si la recuperación falló porque MIeL se cayó o no hay internet, degradar al caché local
    var isOfflineNow = false;
    try {
      isOfflineNow =
          ref.read(appSessionProvider).serverStatus != MielServerStatus.online;
    } catch (_) {}

    if (isOfflineNow) {
      final cached = await tryReadOfflineCache();
      if (cached != null) return cached;
    }
    rethrow;
  } catch (error) {
    final status = classifyMielNetworkError(error);
    tryReportStatus(status);

    final cached = await tryReadOfflineCache();
    if (cached != null) return cached;
    rethrow;
  }
}

/// Wrapper compatible que devuelve directamente el HTML de [fetchInteractiveHtmlResultWithAuth].
Future<String> fetchInteractiveHtmlWithAuth(
  Ref ref,
  Future<String> Function(MielInteractiveReader reader) fetcher, {
  String? cacheKey,
  String idComision = '',
  String module = '',
}) async {
  final result = await fetchInteractiveHtmlResultWithAuth(
    ref,
    fetcher,
    cacheKey: cacheKey,
    idComision: idComision,
    module: module,
  );
  return result.html;
}

/// Recupera la sesión silenciosamente priorizando `AppSessionController.ensureActiveSession`
/// (y con fallback limpio si un test de widget aislado no inicializa el controlador).
Future<bool> _recoverInteractiveSession(
  Ref ref,
  MielInteractiveReader reader,
) async {
  try {
    if (await reader.isLogged()) return true;
  } catch (_) {}

  try {
    final ok = await ref
        .read(appSessionProvider.notifier)
        .ensureActiveSession(forceRelogin: true);
    if (ok) return true;
  } catch (_) {}

  try {
    final creds = await ref
        .read(appSessionProvider.notifier)
        .loadActiveCredentials();
    if (creds != null) {
      final loginRes = await reader.login(
        creds.username,
        creds.password,
        remember: true,
      );
      return loginRes.isSuccess;
    }
  } catch (_) {}
  return false;
}

/// Ejecuta una operación de escritura de **Fase 3** (`MielWriter`) con reconexión
/// automática silenciosa (Fase 5) si la sesión expiró en MIeL.
///
/// Si MIeL está caído o el dispositivo está desconectado (Fase 9), interrumpe
/// el envío de inmediato con un mensaje informativo para no colgarse en timeouts.
Future<T> runMielWriteWithAuth<T>(
  WidgetRef ref,
  Future<T> Function(MielWriter writer) action,
) async {
  try {
    final session = ref.read(appSessionProvider);
    if (session.serverStatus != MielServerStatus.online) {
      throw const HttpException(
        'No se puede enviar en este momento: los servidores de MIeL no responden o no hay conexión a internet.',
      );
    }
  } catch (e) {
    if (e is HttpException) rethrow;
  }

  final writer = await ref.read(mielWriterProvider.future);
  try {
    return await action(writer);
  } on MielSessionExpiredException {
    final ok = await ref
        .read(appSessionProvider.notifier)
        .ensureActiveSession(forceRelogin: true);
    if (!ok) rethrow;
    return action(writer);
  } catch (e) {
    if (e is DioException ||
        e is SocketException ||
        e is TimeoutException ||
        e is HandshakeException ||
        e is TlsException ||
        e is HttpException) {
      try {
        ref
            .read(appSessionProvider.notifier)
            .reportServerStatus(classifyMielNetworkError(e));
      } catch (_) {}
    }
    rethrow;
  }
}

/// Obtiene el formulario de redacción (`/mensajeria/redactar/comision/{id}`)
/// con la lista real de destinatarios (`tutores`, `tutor`, `alumno`, `grupo`).
final mensajeriaRedactarFormProvider = FutureProvider.autoDispose
    .family<ComposeMessageFormData, String>((ref, idComision) async {
      final writer = await ref.read(mielWriterProvider.future);
      try {
        var html = await writer.fetchMensajeriaRedactarHtml(idComision);
        if (isLikelyLoginRedirectHtml(html)) {
          final reader = await ref.read(mielInteractiveReaderProvider.future);
          if (await _recoverInteractiveSession(ref, reader)) {
            html = await writer.fetchMensajeriaRedactarHtml(idComision);
          }
        }
        if (isLikelyMielMaintenanceHtml(html)) {
          throw const HttpException(
            'MIeL devolvió página de mantenimiento o error HTTP',
          );
        }
        return parseMensajeriaRedactarHtml(html, idComision);
      } catch (e) {
        try {
          ref
              .read(appSessionProvider.notifier)
              .reportServerStatus(classifyMielNetworkError(e));
        } catch (_) {}
        rethrow;
      }
    });

// --- Contenidos Providers ---

final contenidosPageProvider = FutureProvider.autoDispose
    .family<ContentPageData, String>((ref, idComision) async {
      final result = await fetchInteractiveHtmlResultWithAuth(
        ref,
        (r) => r.fetchContenidosHtml(idComision),
        cacheKey: 'contenidos:$idComision',
        idComision: idComision,
        module: 'contenidos',
      );
      final page = parseContenidosPageHtml(result.html, idComision);
      // Solo limpiar el badge local si la consulta llegó efectivamente al servidor de MIeL
      if (!result.fromCache) {
        await ref.read(databaseProvider).clearContenidosBadge(idComision);
      }
      return page;
    });

final contenidosGlosarioProvider = FutureProvider.autoDispose
    .family<GlossaryPageData, ({String idComision, String? letra})>((
      ref,
      arg,
    ) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchContenidosGlosarioHtml(arg.idComision, letra: arg.letra),
        cacheKey: 'contenidos:glosario:${arg.idComision}:${arg.letra ?? 'all'}',
        idComision: arg.idComision,
        module: 'contenidos',
      );
      return parseContenidosGlosarioHtml(html);
    });

final contenidosFaqProvider = FutureProvider.autoDispose
    .family<List<FaqItem>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchContenidosFaqHtml(idComision),
        cacheKey: 'contenidos:faq:$idComision',
        idComision: idComision,
        module: 'contenidos',
      );
      return parseContenidosFaqHtml(html);
    });

// --- Portafolio Providers ---

final portafolioPracticasProvider = FutureProvider.autoDispose
    .family<List<PortfolioPractice>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioPracticasHtml(idComision),
        cacheKey: 'portafolio:practicas:$idComision',
        idComision: idComision,
        module: 'portafolio',
      );
      return parsePortafolioPracticasHtml(html, idComision);
    });

final portafolioEntregasDetalleProvider = FutureProvider.autoDispose
    .family<PortfolioPracticeDetail, ({String idComision, String idPractica})>((
      ref,
      arg,
    ) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioEntregasHtml(arg.idComision, arg.idPractica),
        cacheKey: 'portafolio:entregas:${arg.idComision}:${arg.idPractica}',
        idComision: arg.idComision,
        module: 'portafolio',
      );
      return parsePortafolioEntregasDetalleHtml(
        html,
        arg.idComision,
        arg.idPractica,
      );
    });

final portafolioArchivosEnviadosProvider = FutureProvider.autoDispose
    .family<List<PortfolioSentFile>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioArchivosEnviadosHtml(idComision),
        cacheKey: 'portafolio:archivos:$idComision',
        idComision: idComision,
        module: 'portafolio',
      );
      return parsePortafolioArchivosEnviadosHtml(html);
    });

final portafolioGruposProvider = FutureProvider.autoDispose
    .family<List<PortfolioGroup>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioGruposHtml(idComision),
        cacheKey: 'portafolio:grupos:$idComision',
        idComision: idComision,
        module: 'portafolio',
      );
      return parsePortafolioGruposHtml(html);
    });

final portafolioNotasProvider = FutureProvider.autoDispose
    .family<PortfolioGradesData, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioNotasHtml(idComision),
        cacheKey: 'portafolio:notas:$idComision',
        idComision: idComision,
        module: 'portafolio',
      );
      return parsePortafolioNotasHtml(html);
    });

final portafolioCompetenciasProvider = FutureProvider.autoDispose
    .family<PortfolioCompetenciesData, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioCompetenciasHtml(idComision),
        cacheKey: 'portafolio:competencias:$idComision',
        idComision: idComision,
        module: 'portafolio',
      );
      return parsePortafolioCompetenciasHtml(html);
    });

// --- Mensajería Providers ---

final mensajeriaBandejaProvider = FutureProvider.autoDispose
    .family<
      MessageBoxPageData,
      ({String idComision, MensajeriaBoxKind box, int page})
    >((ref, arg) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) {
          switch (arg.box) {
            case MensajeriaBoxKind.entrada:
              return r.fetchMensajeriaEntradaPageHtml(
                arg.idComision,
                page: arg.page,
              );
            case MensajeriaBoxKind.salida:
              return r.fetchMensajeriaSalidaHtml(
                arg.idComision,
                page: arg.page,
              );
            case MensajeriaBoxKind.borradores:
              return r.fetchMensajeriaBorradoresHtml(
                arg.idComision,
                page: arg.page,
              );
            case MensajeriaBoxKind.favoritos:
              return r.fetchMensajeriaFavoritosHtml(
                arg.idComision,
                page: arg.page,
              );
          }
        },
        cacheKey: 'mensajeria:${arg.box.name}:${arg.idComision}:p${arg.page}',
        idComision: arg.idComision,
        module: 'mensajeria',
      );
      return parseMensajeriaBandejaHtml(
        html,
        arg.idComision,
        isOutbox: arg.box == MensajeriaBoxKind.salida,
      );
    });

/// Bandeja de entrada unificada (modo solo lectura: solo lee `/mensajeria/entrada/comision/{id}`,
/// jamás llama a `/verEntrada/`).
final mensajeriaUnifiedInboxProvider =
    FutureProvider.autoDispose<List<InboxMessageSummary>>((ref) async {
      final db = ref.read(databaseProvider);
      final allSubjects = await db.getAllSubjects();
      final activeSubjects = allSubjects
          .where(
            (s) =>
                s.hasMensajeria &&
                (s.localVisibilityOverride == 1 ||
                    (s.localVisibilityOverride != -1 && !s.isHiddenInMiel)),
          )
          .toList();

      final combined = <InboxMessageSummary>[];
      for (final subject in activeSubjects) {
        try {
          final html = await fetchInteractiveHtmlWithAuth(
            ref,
            (r) => r.fetchMensajeriaEntradaPageHtml(subject.idComision),
            cacheKey: 'mensajeria:entrada:${subject.idComision}:p1',
            idComision: subject.idComision,
            module: 'mensajeria',
          );
          final page = parseMensajeriaBandejaHtml(html, subject.idComision);
          for (final msg in page.messages) {
            combined.add(msg.copyWith(subjectNameLabel: subject.name));
          }
        } catch (_) {
          // Si una comisión falla puntualmente, continuar con las demás.
        }
      }
      return combined;
    });

final mensajeriaDetalleProvider = FutureProvider.autoDispose
    .family<
      MessageDetail,
      ({String idComision, String idMensaje, String detailUrl, bool wasUnread})
    >((ref, arg) async {
      final url = arg.detailUrl.isNotEmpty
          ? arg.detailUrl
          : '/mensajeria/verEntrada/comision/${arg.idComision}/pag/1/from/entrada/id/${arg.idMensaje}';
      final result = await fetchInteractiveHtmlResultWithAuth(
        ref,
        (r) => r.fetchMensajeriaDetalleHtml(url),
        cacheKey: 'mensajeria:detalle:${arg.idComision}:${arg.idMensaje}',
        idComision: arg.idComision,
        module: 'mensajeria',
      );
      final detail = parseMensajeriaDetalleHtml(
        result.html,
        arg.idComision,
        arg.idMensaje,
      );
      if (arg.wasUnread && !result.fromCache) {
        await ref.read(databaseProvider).decrementMensajesBadge(arg.idComision);
      }
      return detail;
    });

final mensajeriaDestinatariosProvider = FutureProvider.autoDispose
    .family<List<MessageRecipient>, String>((ref, url) async {
      if (url.isEmpty) return const [];
      final extractedComision =
          RegExp(r'/comision/(\d+)').firstMatch(url)?.group(1) ?? '';
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchMensajeriaDestinatariosHtml(url),
        cacheKey: 'mensajeria:destinatarios:$url',
        idComision: extractedComision,
        module: 'mensajeria',
      );
      return parseMensajeriaDestinatariosHtml(html);
    });

// --- Foros Providers ---

final foroTemasProvider = FutureProvider.autoDispose
    .family<List<ForumTopicSummary>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchForoTemasHtml(idComision),
        cacheKey: 'foro:temas:$idComision',
        idComision: idComision,
        module: 'forov2',
      );
      return parseForoTemasHtml(html, idComision);
    });

final foroMensajesProvider = FutureProvider.autoDispose
    .family<
      ForumThreadData,
      ({String idComision, String idTema, int unreadBadge})
    >((ref, arg) async {
      final result = await fetchInteractiveHtmlResultWithAuth(
        ref,
        (r) => r.fetchForoMensajesHtml(arg.idComision, arg.idTema),
        cacheKey: 'foro:mensajes:${arg.idComision}:${arg.idTema}',
        idComision: arg.idComision,
        module: 'forov2',
      );
      final thread = parseForoMensajesHtml(
        result.html,
        arg.idComision,
        arg.idTema,
      );
      if (arg.unreadBadge > 0 && !result.fromCache) {
        await ref
            .read(databaseProvider)
            .decrementForoBadge(arg.idComision, arg.unreadBadge);
      }
      return thread;
    });

// --- Módulos Secundarios Providers ---

final evaluacionesListProvider = FutureProvider.autoDispose
    .family<List<EvaluationItem>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchEvaluacionesHtml(idComision),
        cacheKey: 'evaluaciones:$idComision',
        idComision: idComision,
        module: 'evaluacion',
      );
      return parseEvaluacionesHtml(html, idComision);
    });

final encuestasListProvider = FutureProvider.autoDispose
    .family<List<SurveyItem>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchEncuestasHtml(idComision),
        cacheKey: 'encuestas:$idComision',
        idComision: idComision,
        module: 'encuestas',
      );
      return parseEncuestasHtml(html, idComision);
    });

final autoguiaListProvider = FutureProvider.autoDispose
    .family<List<AutoguiaModule>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchAutoguiaHtml(idComision),
        cacheKey: 'autoguia:$idComision',
        idComision: idComision,
        module: 'autoguia',
      );
      return parseAutoguiaHtml(html, idComision);
    });

// --- Caché en memoria y disco para imágenes autenticadas de Foros y perfiles ---

int _authenticatedImageCacheGeneration = -1;
final Map<String, Uint8List> _authenticatedImageMemoryCache =
    <String, Uint8List>{};

final authenticatedImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, url) async {
      final sessionGen = ref.watch(sessionGenerationProvider);
      if (_authenticatedImageCacheGeneration != sessionGen) {
        _authenticatedImageMemoryCache.clear();
        _authenticatedImageCacheGeneration = sessionGen;
      }

      final cached = _authenticatedImageMemoryCache[url];
      if (cached != null) return cached;

      var canUseDiskCache = false;
      var maxCacheMb = 100;
      try {
        final session = ref.read(appSessionProvider);
        canUseDiskCache = session.offlineModeEnabled && session.isAuthenticated;
        maxCacheMb = session.offlineCacheMaxMb;
      } catch (_) {}

      if (canUseDiskCache) {
        final mediaService = ref.read(offlineMediaServiceProvider);
        final diskCached = await mediaService.getCachedImageBytes(url);
        if (diskCached != null) {
          _authenticatedImageMemoryCache[url] = diskCached;
          return diskCached;
        }
      }

      try {
        final reader = await ref.read(mielInteractiveReaderProvider.future);
        final bytes = await reader.downloadAuthenticatedBytes(url);
        if (_authenticatedImageCacheGeneration != sessionGen) {
          return bytes;
        }
        if (_authenticatedImageMemoryCache.length >= 64) {
          _authenticatedImageMemoryCache.remove(
            _authenticatedImageMemoryCache.keys.first,
          );
        }
        _authenticatedImageMemoryCache[url] = bytes;

        if (canUseDiskCache) {
          final mediaService = ref.read(offlineMediaServiceProvider);
          final maxMediaBytes = (maxCacheMb * 1024 * 1024 * 0.6).round();
          unawaited(
            mediaService.saveCachedImageBytes(
              url,
              bytes,
              maxTotalBytes: maxMediaBytes,
            ),
          );
        }

        return bytes;
      } catch (e) {
        if (canUseDiskCache) {
          final mediaService = ref.read(offlineMediaServiceProvider);
          final diskFallback = await mediaService.getCachedImageBytes(url);
          if (diskFallback != null) {
            return diskFallback;
          }
        }
        rethrow;
      }
    });

/// Invalida únicamente los providers correspondientes a la ruta activa ante recargas
/// de usuario (F5 / Ctrl + R / Ctrl + Shift + R) evitando peticiones redundantes (Fase 12).
void invalidateRouteProviders(
  WidgetRef ref,
  NavigationHistoryEntry entry, {
  bool forceLive = false,
}) {
  if (entry.section == BrowserShellSection.home ||
      entry.section == BrowserShellSection.novedades) {
    ref.read(appSessionProvider.notifier).syncNow(includeCycle2: true);
    return;
  }

  if (entry.section == BrowserShellSection.ajustes ||
      entry.subjectId == null ||
      entry.subjectId!.isEmpty) {
    return;
  }

  final sId = entry.subjectId!;

  switch (entry.tool) {
    case MielToolKind.contenidos:
      final key = 'contenidos:$sId';
      if (forceLive) {
        _sessionBfHtmlCache.remove(key);
        markForceLiveCacheKeys([key]);
      }
      ref.invalidate(contenidosPageProvider(sId));
      break;

    case MielToolKind.portafolio:
      if (entry.portafolioPractice != null) {
        final key =
            'portafolio:entrega:$sId:${entry.portafolioPractice!.idPractica}';
        if (forceLive) {
          _sessionBfHtmlCache.remove(key);
          markForceLiveCacheKeys([key]);
        }
        ref.invalidate(
          portafolioEntregasDetalleProvider((
            idComision: sId,
            idPractica: entry.portafolioPractice!.idPractica,
          )),
        );
      } else {
        switch (entry.moduleSectionIndex) {
          case 1:
            final key = 'portafolio:enviados:$sId';
            if (forceLive) {
              _sessionBfHtmlCache.remove(key);
              markForceLiveCacheKeys([key]);
            }
            ref.invalidate(portafolioArchivosEnviadosProvider(sId));
            break;
          case 2:
            final key = 'portafolio:grupos:$sId';
            if (forceLive) {
              _sessionBfHtmlCache.remove(key);
              markForceLiveCacheKeys([key]);
            }
            ref.invalidate(portafolioGruposProvider(sId));
            break;
          case 3:
            final keyNotas = 'portafolio:notas:$sId';
            final keyComp = 'portafolio:competencias:$sId';
            if (forceLive) {
              _sessionBfHtmlCache.remove(keyNotas);
              _sessionBfHtmlCache.remove(keyComp);
              markForceLiveCacheKeys([keyNotas, keyComp]);
            }
            ref.invalidate(portafolioNotasProvider(sId));
            ref.invalidate(portafolioCompetenciasProvider(sId));
            break;
          default:
            final key = 'portafolio:practicas:$sId';
            if (forceLive) {
              _sessionBfHtmlCache.remove(key);
              markForceLiveCacheKeys([key]);
            }
            ref.invalidate(portafolioPracticasProvider(sId));
            break;
        }
      }
      break;

    case MielToolKind.mensajeria:
      if (entry.mensajeriaState.selectedMessage != null) {
        final msg = entry.mensajeriaState.selectedMessage!;
        final key = 'mensajeria:detalle:${msg.idComision}:${msg.idMensaje}';
        if (forceLive) {
          _sessionBfHtmlCache.remove(key);
          markForceLiveCacheKeys([key]);
        }
        ref.invalidate(
          mensajeriaDetalleProvider((
            idComision: msg.idComision,
            idMensaje: msg.idMensaje,
            detailUrl: msg.detailUrl,
            wasUnread: false,
          )),
        );
      } else if (entry.mensajeriaState.inlineComposeMode ||
          entry.moduleSectionIndex == 0) {
        final key = 'mensajeria:redactar:$sId';
        if (forceLive) {
          _sessionBfHtmlCache.remove(key);
          markForceLiveCacheKeys([key]);
        }
        ref.invalidate(mensajeriaRedactarFormProvider(sId));
      } else if (entry.mensajeriaState.unifiedCrossSubjectMode) {
        final key = 'mensajeria:unified:${entry.mensajeriaState.page}';
        if (forceLive) {
          _sessionBfHtmlCache.remove(key);
          markForceLiveCacheKeys([key]);
        }
        ref.invalidate(mensajeriaUnifiedInboxProvider);
      } else {
        final boxKind = switch (entry.moduleSectionIndex) {
          2 => MensajeriaBoxKind.salida,
          3 => MensajeriaBoxKind.borradores,
          4 => MensajeriaBoxKind.favoritos,
          _ => MensajeriaBoxKind.entrada,
        };
        final key =
            'mensajeria:${boxKind.name}:$sId:${entry.mensajeriaState.page}';
        if (forceLive) {
          _sessionBfHtmlCache.remove(key);
          markForceLiveCacheKeys([key]);
        }
        ref.invalidate(
          mensajeriaBandejaProvider((
            idComision: sId,
            box: boxKind,
            page: entry.mensajeriaState.page,
          )),
        );
      }
      break;

    case MielToolKind.foro:
      if (entry.foroTopicId != null) {
        final key = 'foro:mensajes:$sId:${entry.foroTopicId}';
        if (forceLive) {
          _sessionBfHtmlCache.remove(key);
          markForceLiveCacheKeys([key]);
        }
        ref.invalidate(
          foroMensajesProvider((
            idComision: sId,
            idTema: entry.foroTopicId!,
            unreadBadge: 0,
          )),
        );
      } else {
        final key = 'foro:temas:$sId';
        if (forceLive) {
          _sessionBfHtmlCache.remove(key);
          markForceLiveCacheKeys([key]);
        }
        ref.invalidate(foroTemasProvider(sId));
      }
      break;

    case MielToolKind.evaluacion:
      final key = 'evaluacion:$sId';
      if (forceLive) {
        _sessionBfHtmlCache.remove(key);
        markForceLiveCacheKeys([key]);
      }
      ref.invalidate(evaluacionesListProvider(sId));
      break;

    case MielToolKind.encuestas:
      final key = 'encuestas:$sId';
      if (forceLive) {
        _sessionBfHtmlCache.remove(key);
        markForceLiveCacheKeys([key]);
      }
      ref.invalidate(encuestasListProvider(sId));
      break;

    case MielToolKind.autoguia:
    case MielToolKind.chat:
      final key = 'autoguia:$sId';
      if (forceLive) {
        _sessionBfHtmlCache.remove(key);
        markForceLiveCacheKeys([key]);
      }
      ref.invalidate(autoguiaListProvider(sId));
      break;
  }
}
