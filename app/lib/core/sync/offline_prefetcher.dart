import '../network/miel_client.dart';
import '../storage/app_database.dart';

/// Servicio de precarga segura de páginas de solo lectura para el Modo Sin Conexión (Fase 9).
///
/// Invariantes críticas de seguridad y respeto de efectos colaterales (`AGENTS.md`):
/// 1. NUNCA consulta `/contenido/archivos/...` si el badge de Contenidos es `0`.
/// 2. NUNCA consulta `/mensajeria/verEntrada/...` (solo lista bandejas seguras de solo lectura).
/// 3. NUNCA consulta `/forov2/mensajes/...` (solo lista el índice seguro de temas abiertos).
class OfflinePrefetcher {
  const OfflinePrefetcher({required this.client, required this.database});

  final MielInteractiveReader client;
  final AppDatabase database;

  Future<int> prefetchSafeModules({
    required List<Subject> activeSubjects,
    bool Function()? isCancelled,
    int maxCacheMb = 100,
  }) async {
    var count = 0;
    bool cancelled() => isCancelled != null && isCancelled();

    if (cancelled()) return count;

    // 1. Precargar panel principal si no fue cancelado
    try {
      final internoHtml = await client.fetchInternoHtml();
      if (!cancelled()) {
        await database.putOfflinePage(
          cacheKey: 'principal:interno',
          idComision: '',
          module: 'principal',
          htmlContent: internoHtml,
          maxCacheMb: maxCacheMb,
        );
        count++;
      }
    } catch (_) {}

    // 2. Precargar módulos seguros de materias activas
    for (final subject in activeSubjects) {
      if (cancelled()) break;

      // Docentes de la comisión (seguro)
      try {
        final docentesHtml = await client.fetchCursoDetallesHtml(
          subject.idComision,
        );
        if (!cancelled()) {
          await database.putOfflinePage(
            cacheKey: 'cursoDetalles:${subject.idComision}',
            idComision: subject.idComision,
            module: 'docentes',
            htmlContent: docentesHtml,
            maxCacheMb: maxCacheMb,
          );
          count++;
        }
      } catch (_) {}

      // Contenidos: REGLA 1: Solo si badge > 0 para no borrar el estado en el servidor
      if (subject.hasContenidos && subject.lastContenidosBadge > 0) {
        if (cancelled()) break;
        try {
          final contenidosHtml = await client.fetchContenidosHtml(
            subject.idComision,
          );
          if (!cancelled()) {
            await database.putOfflinePage(
              cacheKey: 'contenidos:${subject.idComision}',
              idComision: subject.idComision,
              module: 'contenidos',
              htmlContent: contenidosHtml,
              maxCacheMb: maxCacheMb,
            );
            count++;
          }
        } catch (_) {}
      }

      // Portafolio: Lista de prácticas (seguro)
      if (subject.hasPortafolio) {
        if (cancelled()) break;
        try {
          final practicasHtml = await client.fetchPortafolioPracticasHtml(
            subject.idComision,
          );
          if (!cancelled()) {
            await database.putOfflinePage(
              cacheKey: 'portafolio:practicas:${subject.idComision}',
              idComision: subject.idComision,
              module: 'portafolio',
              htmlContent: practicasHtml,
              maxCacheMb: maxCacheMb,
            );
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
          if (!cancelled()) {
            await database.putOfflinePage(
              cacheKey: 'mensajeria:entrada:${subject.idComision}:p1',
              idComision: subject.idComision,
              module: 'mensajeria',
              htmlContent: entradaHtml,
              maxCacheMb: maxCacheMb,
            );
            count++;
          }
        } catch (_) {}
      }

      // Foros: Lista de temas (seguro, REGLA 3: nunca forov2/mensajes)
      if (subject.hasForo) {
        if (cancelled()) break;
        try {
          final temasHtml = await client.fetchForoTemasHtml(subject.idComision);
          if (!cancelled()) {
            await database.putOfflinePage(
              cacheKey: 'foro:temas:${subject.idComision}',
              idComision: subject.idComision,
              module: 'forov2',
              htmlContent: temasHtml,
              maxCacheMb: maxCacheMb,
            );
            count++;
          }
        } catch (_) {}
      }

      // Evaluación: Lista de evaluaciones (seguro)
      if (subject.hasEvaluacion) {
        if (cancelled()) break;
        try {
          final evalHtml = await client.fetchEvaluacionesHtml(
            subject.idComision,
          );
          if (!cancelled()) {
            await database.putOfflinePage(
              cacheKey: 'evaluaciones:${subject.idComision}',
              idComision: subject.idComision,
              module: 'evaluacion',
              htmlContent: evalHtml,
              maxCacheMb: maxCacheMb,
            );
            count++;
          }
        } catch (_) {}
      }
    }

    return count;
  }
}
