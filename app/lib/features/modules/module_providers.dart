import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/network/miel_server_status_classifier.dart';
import '../../core/parsers/miel_parsers.dart';

/// Tipo de bandeja de Mensajería en MIeL.
enum MensajeriaBoxKind { entrada, salida, borradores, favoritos }

/// Ejecuta una consulta HTML interactiva con recuperación automática silenciosa
/// de sesión (Fase 5) y contingencia/fallback al caché local si MIeL está caído
/// o no hay conexión a internet (Fase 9).
Future<String> fetchInteractiveHtmlWithAuth(
  Ref ref,
  Future<String> Function(MielInteractiveReader reader) fetcher, {
  String? cacheKey,
  String idComision = '',
  String module = '',
}) async {
  var offlineEnabled = false;
  var maxCacheMb = 100;
  try {
    final session = ref.read(appSessionProvider);
    offlineEnabled = session.offlineModeEnabled;
    maxCacheMb = session.offlineCacheMaxMb;
  } catch (_) {}

  void tryReportStatus(MielServerStatus status) {
    try {
      ref.read(appSessionProvider.notifier).reportServerStatus(status);
    } catch (_) {}
  }

  try {
    final reader = await ref.read(mielInteractiveReaderProvider.future);
    var html = await fetcher(reader);

    if (isLikelyLoginRedirectHtml(html)) {
      final recovered = await _recoverInteractiveSession(ref, reader);
      if (recovered) {
        html = await fetcher(reader);
      }
    }

    if (isLikelyMielMaintenanceHtml(html)) {
      throw HttpException('MIeL devolvió página de mantenimiento o error HTTP');
    }

    tryReportStatus(MielServerStatus.online);

    // Si el modo offline está activo y hay cacheKey, persistir copia local en segundo plano
    if (offlineEnabled &&
        cacheKey != null &&
        html.isNotEmpty &&
        !isLikelyLoginRedirectHtml(html)) {
      final db = ref.read(databaseProvider);
      unawaited(
        db.putOfflinePage(
          cacheKey: cacheKey,
          idComision: idComision,
          module: module,
          htmlContent: html,
          maxCacheMb: maxCacheMb,
        ),
      );
    }

    return html;
  } catch (error) {
    final status = classifyMielNetworkError(error);
    tryReportStatus(status);

    // Fallback a copia local guardada previamente
    if (offlineEnabled && cacheKey != null) {
      final db = ref.read(databaseProvider);
      final cached = await db.getOfflinePage(cacheKey);
      if (cached != null && cached.htmlContent.isNotEmpty) {
        return cached.htmlContent;
      }
    }
    rethrow;
  }
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
  }
}

/// Obtiene el formulario de redacción (`/mensajeria/redactar/comision/{id}`)
/// con la lista real de destinatarios (`tutores`, `tutor`, `alumno`, `grupo`).
final mensajeriaRedactarFormProvider = FutureProvider.autoDispose
    .family<ComposeMessageFormData, String>((ref, idComision) async {
      final writer = await ref.read(mielWriterProvider.future);
      var html = await writer.fetchMensajeriaRedactarHtml(idComision);
      if (isLikelyLoginRedirectHtml(html)) {
        final reader = await ref.read(mielInteractiveReaderProvider.future);
        if (await _recoverInteractiveSession(ref, reader)) {
          html = await writer.fetchMensajeriaRedactarHtml(idComision);
        }
      }
      return parseMensajeriaRedactarHtml(html, idComision);
    });

// --- Contenidos Providers ---

final contenidosPageProvider = FutureProvider.autoDispose
    .family<ContentPageData, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchContenidosHtml(idComision),
        cacheKey: 'contenidos:$idComision',
        idComision: idComision,
        module: 'contenidos',
      );
      final page = parseContenidosPageHtml(html, idComision);
      // Abrir Contenidos en MIeL limpia el badge del servidor; sincronizamos el badge local.
      await ref.read(databaseProvider).clearContenidosBadge(idComision);
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
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchMensajeriaDetalleHtml(url),
        cacheKey: 'mensajeria:detalle:${arg.idComision}:${arg.idMensaje}',
        idComision: arg.idComision,
        module: 'mensajeria',
      );
      final detail = parseMensajeriaDetalleHtml(
        html,
        arg.idComision,
        arg.idMensaje,
      );
      if (arg.wasUnread) {
        await ref.read(databaseProvider).decrementMensajesBadge(arg.idComision);
      }
      return detail;
    });

final mensajeriaDestinatariosProvider = FutureProvider.autoDispose
    .family<List<MessageRecipient>, String>((ref, url) async {
      if (url.isEmpty) return const [];
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchMensajeriaDestinatariosHtml(url),
        cacheKey: 'mensajeria:destinatarios:$url',
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
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchForoMensajesHtml(arg.idComision, arg.idTema),
        cacheKey: 'foro:mensajes:${arg.idComision}:${arg.idTema}',
        idComision: arg.idComision,
        module: 'forov2',
      );
      final thread = parseForoMensajesHtml(html, arg.idComision, arg.idTema);
      if (arg.unreadBadge > 0) {
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

      var offlineEnabled = false;
      try {
        offlineEnabled = ref.read(appSessionProvider).offlineModeEnabled;
      } catch (_) {}

      if (offlineEnabled) {
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

        if (offlineEnabled) {
          final mediaService = ref.read(offlineMediaServiceProvider);
          unawaited(mediaService.saveCachedImageBytes(url, bytes));
        }

        return bytes;
      } catch (e) {
        if (offlineEnabled) {
          final mediaService = ref.read(offlineMediaServiceProvider);
          final diskFallback = await mediaService.getCachedImageBytes(url);
          if (diskFallback != null) {
            return diskFallback;
          }
        }
        rethrow;
      }
    });
