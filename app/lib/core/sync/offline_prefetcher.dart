import '../network/miel_client.dart';
import '../network/miel_server_status_classifier.dart';
import '../storage/app_database.dart';

/// Servicio de precarga segura de páginas de solo lectura para el Modo Sin Conexión (Fase 9).
///
/// Invariantes críticas de seguridad y respeto de efectos colaterales (`AGENTS.md`):
/// 1. NUNCA consulta `/contenido/archivos/...` (Contenidos se cachea únicamente al abrirse
///    interactivamente o cuando `SyncEngine` ya lo consultó con badge > 0 habilitado).
/// 2. NUNCA consulta `/mensajeria/verEntrada/...` (solo lista bandejas seguras de solo lectura).
/// 3. NUNCA consulta `/forov2/mensajes/...` (solo lista el índice seguro de temas abiertos).
class OfflinePrefetcher {
  const OfflinePrefetcher({required this.client, required this.database});

  final MielInteractiveReader client;
  final AppDatabase database;

  Future<bool> _storeIfValid({
    required String cacheKey,
    required String idComision,
    required String module,
    required String html,
    required int maxCacheMb,
    required bool Function() cancelled,
  }) async {
    if (cancelled() ||
        html.isEmpty ||
        isLikelyLoginRedirectHtml(html) ||
        isLikelyMielMaintenanceHtml(html)) {
      return false;
    }
    await database.putOfflinePage(
      cacheKey: cacheKey,
      idComision: idComision,
      module: module,
      htmlContent: html,
      maxCacheMb: maxCacheMb,
    );
    return true;
  }

  Future<int> prefetchSafeModules({
    required List<Subject> activeSubjects,
    bool Function()? isCancelled,
    int maxCacheMb = 100,
    bool skipInterno = false,
  }) async {
    var count = 0;
    bool cancelled() => isCancelled != null && isCancelled();

    if (cancelled()) return count;

    // 1. Precargar panel principal si no fue cancelado ni recién guardado por SyncEngine
    if (!skipInterno) {
      try {
        final internoHtml = await client.fetchInternoHtml();
        if (await _storeIfValid(
          cacheKey: 'principal:interno',
          idComision: '',
          module: 'principal',
          html: internoHtml,
          maxCacheMb: maxCacheMb,
          cancelled: cancelled,
        )) {
          count++;
        }
      } catch (_) {}
    }

    // 2. Precargar exclusivamente módulos 100% libres de efectos colaterales
    for (final subject in activeSubjects) {
      if (cancelled()) break;

      // Docentes y detalles de la comisión (solo lectura segura)
      try {
        final docentesHtml = await client.fetchCursoDetallesHtml(
          subject.idComision,
        );
        if (await _storeIfValid(
          cacheKey: 'cursoDetalles:${subject.idComision}',
          idComision: subject.idComision,
          module: 'docentes',
          html: docentesHtml,
          maxCacheMb: maxCacheMb,
          cancelled: cancelled,
        )) {
          count++;
        }
      } catch (_) {}

      // Portafolio: Lista de prácticas (solo lectura segura)
      if (subject.hasPortafolio) {
        if (cancelled()) break;
        try {
          final practicasHtml = await client.fetchPortafolioPracticasHtml(
            subject.idComision,
          );
          if (await _storeIfValid(
            cacheKey: 'portafolio:practicas:${subject.idComision}',
            idComision: subject.idComision,
            module: 'portafolio',
            html: practicasHtml,
            maxCacheMb: maxCacheMb,
            cancelled: cancelled,
          )) {
            count++;
          }
        } catch (_) {}
      }

      // Mensajería: Página 1 de bandeja de entrada (seguro, REGLA 2: nunca verEntrada)
      if (subject.hasMensajeria) {
        if (cancelled()) break;
        try {
          final entradaHtml = await client.fetchMensajeriaEntradaPageHtml(
            subject.idComision,
            page: 1,
          );
          if (await _storeIfValid(
            cacheKey: 'mensajeria:entrada:${subject.idComision}:p1',
            idComision: subject.idComision,
            module: 'mensajeria',
            html: entradaHtml,
            maxCacheMb: maxCacheMb,
            cancelled: cancelled,
          )) {
            count++;
          }
        } catch (_) {}
      }

      // Foros: Lista de temas (seguro, REGLA 3: nunca forov2/mensajes)
      if (subject.hasForo) {
        if (cancelled()) break;
        try {
          final temasHtml = await client.fetchForoTemasHtml(subject.idComision);
          if (await _storeIfValid(
            cacheKey: 'foro:temas:${subject.idComision}',
            idComision: subject.idComision,
            module: 'forov2',
            html: temasHtml,
            maxCacheMb: maxCacheMb,
            cancelled: cancelled,
          )) {
            count++;
          }
        } catch (_) {}
      }

      // Evaluación: Lista de evaluaciones (solo lectura segura)
      if (subject.hasEvaluacion) {
        if (cancelled()) break;
        try {
          final evalHtml = await client.fetchEvaluacionesHtml(
            subject.idComision,
          );
          if (await _storeIfValid(
            cacheKey: 'evaluaciones:${subject.idComision}',
            idComision: subject.idComision,
            module: 'evaluacion',
            html: evalHtml,
            maxCacheMb: maxCacheMb,
            cancelled: cancelled,
          )) {
            count++;
          }
        } catch (_) {}
      }

      // Encuestas: Listado (solo lectura segura)
      if (subject.hasEncuestas) {
        if (cancelled()) break;
        try {
          final encuestasHtml = await client.fetchEncuestasHtml(
            subject.idComision,
          );
          if (await _storeIfValid(
            cacheKey: 'encuestas:${subject.idComision}',
            idComision: subject.idComision,
            module: 'encuestas',
            html: encuestasHtml,
            maxCacheMb: maxCacheMb,
            cancelled: cancelled,
          )) {
            count++;
          }
        } catch (_) {}
      }

      // Autoguía: Módulos (solo lectura segura)
      if (subject.hasAutoguia) {
        if (cancelled()) break;
        try {
          final autoguiaHtml = await client.fetchAutoguiaHtml(
            subject.idComision,
          );
          if (await _storeIfValid(
            cacheKey: 'autoguia:${subject.idComision}',
            idComision: subject.idComision,
            module: 'autoguia',
            html: autoguiaHtml,
            maxCacheMb: maxCacheMb,
            cancelled: cancelled,
          )) {
            count++;
          }
        } catch (_) {}
      }
    }

    return count;
  }
}
