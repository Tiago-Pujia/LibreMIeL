import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/parsers/miel_parsers.dart';

/// Tipo de bandeja de Mensajería en MIeL.
enum MensajeriaBoxKind { entrada, salida, borradores, favoritos }

/// Ejecuta una consulta HTML interactiva de Fase 2 con recuperación automática de sesión
/// (un único re-login si la cookie `PHPSESSID` expiró).
Future<String> fetchInteractiveHtmlWithAuth(
  Ref ref,
  Future<String> Function(MielInteractiveReader reader) fetcher,
) async {
  final reader = await ref.read(mielInteractiveReaderProvider.future);
  var html = await fetcher(reader);

  if (isLikelyLoginRedirectHtml(html)) {
    final logged = await reader.isLogged();
    if (!logged) {
      final creds = await ref
          .read(appSessionProvider.notifier)
          .loadActiveCredentials();
      if (creds != null) {
        final loginRes = await reader.login(creds.username, creds.password);
        if (loginRes.isSuccess) {
          html = await fetcher(reader);
        }
      }
    }
  }
  return html;
}

// --- Contenidos Providers ---

final contenidosPageProvider = FutureProvider.autoDispose
    .family<ContentPageData, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchContenidosHtml(idComision),
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
      );
      return parseContenidosGlosarioHtml(html);
    });

final contenidosFaqProvider = FutureProvider.autoDispose
    .family<List<FaqItem>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchContenidosFaqHtml(idComision),
      );
      return parseContenidosFaqHtml(html);
    });

// --- Portafolio Providers ---

final portafolioPracticasProvider = FutureProvider.autoDispose
    .family<List<PortfolioPractice>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioPracticasHtml(idComision),
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
      );
      return parsePortafolioArchivosEnviadosHtml(html);
    });

final portafolioGruposProvider = FutureProvider.autoDispose
    .family<List<PortfolioGroup>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioGruposHtml(idComision),
      );
      return parsePortafolioGruposHtml(html);
    });

final portafolioNotasProvider = FutureProvider.autoDispose
    .family<PortfolioGradesData, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioNotasHtml(idComision),
      );
      return parsePortafolioNotasHtml(html);
    });

final portafolioCompetenciasProvider = FutureProvider.autoDispose
    .family<PortfolioCompetenciesData, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchPortafolioCompetenciasHtml(idComision),
      );
      return parsePortafolioCompetenciasHtml(html);
    });

// --- Mensajería Providers ---

final mensajeriaBandejaProvider = FutureProvider.autoDispose
    .family<
      MessageBoxPageData,
      ({String idComision, MensajeriaBoxKind box, int page})
    >((ref, arg) async {
      final html = await fetchInteractiveHtmlWithAuth(ref, (r) {
        switch (arg.box) {
          case MensajeriaBoxKind.entrada:
            return r.fetchMensajeriaEntradaPageHtml(
              arg.idComision,
              page: arg.page,
            );
          case MensajeriaBoxKind.salida:
            return r.fetchMensajeriaSalidaHtml(arg.idComision, page: arg.page);
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
      });
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
      );
      return parseMensajeriaDestinatariosHtml(html);
    });

// --- Foros Providers ---

final foroTemasProvider = FutureProvider.autoDispose
    .family<List<ForumTopicSummary>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchForoTemasHtml(idComision),
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
      );
      return parseEvaluacionesHtml(html, idComision);
    });

final encuestasListProvider = FutureProvider.autoDispose
    .family<List<SurveyItem>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchEncuestasHtml(idComision),
      );
      return parseEncuestasHtml(html, idComision);
    });

final autoguiaListProvider = FutureProvider.autoDispose
    .family<List<AutoguiaModule>, String>((ref, idComision) async {
      final html = await fetchInteractiveHtmlWithAuth(
        ref,
        (r) => r.fetchAutoguiaHtml(idComision),
      );
      return parseAutoguiaHtml(html, idComision);
    });

// --- Caché en memoria para imágenes autenticadas de Foros y perfiles ---

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
      return bytes;
    });
