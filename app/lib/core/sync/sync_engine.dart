import '../models/miel_models.dart';
import '../network/miel_client.dart';
import '../parsers/miel_parsers.dart';
import '../storage/app_database.dart';

typedef CredentialsLoader = Future<MielCredentials?> Function();
typedef NowProvider = DateTime Function();

/// Motor de sincronización en dos ciclos de LibreMIEL.
///
/// Respeta todas las invariantes críticas documentadas en `docs/AGENTS.md`:
/// - Ciclo 1 parte de un único `GET /principal/interno/` y solo profundiza donde hay badge > 0.
/// - Jamás llama a `/contenido/archivos/...` si su badge es 0 (evita borrar avisos en MIEL).
/// - Jamás llama a `/mensajeria/verEntrada/...` (evita marcar mensajes como leídos).
/// - En foros, respeta `ForumSyncMode.nonInvasive` vs `ForumSyncMode.teacherReplies`.
/// - Ante error de autenticación (`estado: 1/2/3`), pausa el polling automático para evitar bloqueos.
class SyncEngine {
  SyncEngine({
    required this._client,
    required AppDatabase database,
    NowProvider? nowProvider,
  }) : _db = database,
       _now = nowProvider ?? DateTime.now;

  final MielApiClient _client;
  final AppDatabase _db;
  final NowProvider _now;

  static const String _modContenidos = 'contenidos';
  static const String _modPortafolio = 'portafolio';
  static const String _modMensajeria = 'mensajeria';
  static const String _modForoTemas = 'foro_temas';
  static const String _modForoMensajes = 'foro_mensajes';
  static const String _modEvaluacion = 'evaluacion';

  /// Limpia el estado de pausa tras un inicio de sesión manual exitoso.
  Future<void> clearAuthPause() async {
    await _db.deleteSetting(SettingKeys.accountPausedReason);
  }

  /// Ciclo 1 (frecuente): 1 `GET /principal/interno/` + módulos con badge > 0.
  Future<SyncRunSummary> runCycle1({
    required CredentialsLoader loadCredentials,
    bool ignoreAuthPause = false,
    bool Function()? isCancelled,
  }) async {
    bool cancelled() => isCancelled?.call() ?? false;
    final now = _now();
    final warnings = <String>[];

    if (cancelled()) {
      return const SyncRunSummary(
        cycle: 1,
        isBaseline: false,
        notifications: [],
      );
    }

    if (!ignoreAuthPause) {
      final pausedReason = await _db.getSetting(
        SettingKeys.accountPausedReason,
      );
      if (pausedReason != null && pausedReason.isNotEmpty) {
        return SyncRunSummary(
          cycle: 1,
          isBaseline: false,
          notifications: const [],
          authPaused: true,
          authErrorMessage: pausedReason,
        );
      }
    }

    final authCheck = await _ensureAuthenticated(loadCredentials, now);
    if (authCheck != null || cancelled()) {
      return authCheck ??
          const SyncRunSummary(cycle: 1, isBaseline: false, notifications: []);
    }

    final internoHtml = await _client.fetchInternoHtml();
    if (cancelled()) {
      return const SyncRunSummary(
        cycle: 1,
        isBaseline: false,
        notifications: [],
      );
    }
    final overview = parseInternoHtml(internoHtml);

    if (overview.subjects.isEmpty && !internoHtml.contains('materia-bloque')) {
      warnings.add(
        'No se detectaron tarjetas de materias en /principal/interno/. '
        'Verificá si la sesión expiró o si MIEL cambió su formato HTML.',
      );
      return SyncRunSummary(
        cycle: 1,
        isBaseline: false,
        notifications: const [],
        warnings: warnings,
      );
    }

    await _db.setSetting(SettingKeys.studentName, overview.studentName);
    if (overview.studentAvatarUrl.isNotEmpty) {
      await _db.setSetting(
        SettingKeys.studentAvatarUrl,
        overview.studentAvatarUrl,
      );
    } else {
      await _db.deleteSetting(SettingKeys.studentAvatarUrl);
    }
    final isBaseline = !(await _db.isBaselineCompleted());
    final forumMode = await _db.getForumSyncMode();
    final notifications = <DetectedNotification>[];

    // 1. Novedades globales del menú lateral
    final prevGlobalRaw = await _db.getSetting(
      SettingKeys.globalNovedadesBadge,
    );
    final prevGlobal = int.tryParse(prevGlobalRaw ?? '') ?? 0;
    await _db.setSetting(
      SettingKeys.globalNovedadesBadge,
      overview.globalNovedadesBadge.toString(),
    );
    if (!isBaseline && overview.globalNovedadesBadge > prevGlobal) {
      final n = DetectedNotification(
        dedupeKey:
            'novedades:${overview.globalNovedadesBadge}:${now.year}-${now.month}-${now.day}',
        idComision: 'global',
        subjectName: 'MIEL — Institucional',
        module: MielModuleType.novedades,
        title: 'Nuevas novedades institucionales',
        body:
            'Tenés ${overview.globalNovedadesBadge} aviso(s) nuevo(s) en la sección Novedades de MIEL.',
        targetUrl: '$kMielBaseUrl/principal/novedades/',
        detectedAt: now,
      );
      if (await _db.insertNotificationIfNew(n)) {
        notifications.add(n);
      }
    }

    // 2. Podar materias que ya no pertenecen al usuario/cuatrimestre actual en /principal/interno/
    final activeCommissionIds = overview.subjects
        .map((s) => s.idComision)
        .toSet();
    if (activeCommissionIds.isNotEmpty) {
      await _db.pruneSubjectsNotIn(activeCommissionIds);
    }

    // 3. Actualizar materias y procesar únicamente las que tienen badge > 0
    for (final summary in overview.subjects) {
      if (cancelled()) {
        return const SyncRunSummary(
          cycle: 1,
          isBaseline: false,
          notifications: [],
        );
      }
      final subject = await _db.upsertSubjectFromInterno(summary, now);
      if (subject.muted || subject.isHiddenInMiel) continue;

      // A) Contenidos: SOLO consultar si badge > 0 y ya se completó el baseline
      if (!isBaseline &&
          subject.notifyContenidos &&
          summary.contenidosBadge > 0) {
        final newContenidos = await _syncContenidos(subject, now);
        notifications.addAll(newContenidos);
      }

      if (cancelled()) {
        return const SyncRunSummary(
          cycle: 1,
          isBaseline: false,
          notifications: [],
        );
      }

      // B) Mensajería: seguro de solo lectura (/entrada/comision/{id}, nunca verEntrada)
      if (subject.notifyMensajeria &&
          (summary.mensajesBadge > 0 || isBaseline)) {
        final result = await _syncMensajeria(
          subject,
          isBaseline: isBaseline,
          now: now,
        );
        notifications.addAll(result.notifications);

        // Si llegó un mensaje automático de "Corrección" y no es baseline, actualizar Portafolio ya
        if (!cancelled() &&
            !isBaseline &&
            result.triggeredPortfolioCorrection &&
            subject.notifyPortafolio) {
          final portNotifs = await _syncPortafolio(
            subject,
            isBaseline: false,
            now: now,
          );
          notifications.addAll(portNotifs);
        }
      }

      if (cancelled()) {
        return const SyncRunSummary(
          cycle: 1,
          isBaseline: false,
          notifications: [],
        );
      }

      // C) Foros: listar temas es solo lectura (no altera badges)
      if (subject.notifyForos && (summary.foroBadge > 0 || isBaseline)) {
        final foroNotifs = await _syncForos(
          subject,
          mode: forumMode,
          isBaseline: isBaseline,
          now: now,
        );
        notifications.addAll(foroNotifs);
      }

      if (cancelled()) {
        return const SyncRunSummary(
          cycle: 1,
          isBaseline: false,
          notifications: [],
        );
      }

      // En baseline, capturar snapshot inicial de Portafolio y Evaluaciones silenciosamente
      if (isBaseline) {
        if (subject.hasPortafolio) {
          await _syncPortafolio(subject, isBaseline: true, now: now);
        }
        if (!cancelled() &&
            subject.hasEvaluacion &&
            await _db.getMonitorEvaluaciones()) {
          await _syncEvaluaciones(subject, isBaseline: true, now: now);
        }
      }
    }

    if (cancelled()) {
      return const SyncRunSummary(
        cycle: 1,
        isBaseline: false,
        notifications: [],
      );
    }

    if (isBaseline) {
      await _db.setSetting(SettingKeys.baselineCompleted, 'true');
    }
    await _db.setSetting(SettingKeys.lastCycle1At, now.toIso8601String());

    return SyncRunSummary(
      cycle: 1,
      isBaseline: isBaseline,
      notifications: notifications,
      warnings: warnings,
    );
  }

  /// Ciclo 2 (secundario, cada 30–60 min): módulos sin badge en `/principal/interno/`
  /// (Portafolio y, opcionalmente, Evaluaciones).
  Future<SyncRunSummary> runCycle2({
    required CredentialsLoader loadCredentials,
    bool ignoreAuthPause = false,
    bool Function()? isCancelled,
  }) async {
    bool cancelled() => isCancelled?.call() ?? false;
    final now = _now();
    if (cancelled()) {
      return const SyncRunSummary(
        cycle: 2,
        isBaseline: false,
        notifications: [],
      );
    }

    if (!ignoreAuthPause) {
      final pausedReason = await _db.getSetting(
        SettingKeys.accountPausedReason,
      );
      if (pausedReason != null && pausedReason.isNotEmpty) {
        return SyncRunSummary(
          cycle: 2,
          isBaseline: false,
          notifications: const [],
          authPaused: true,
          authErrorMessage: pausedReason,
        );
      }
    }

    final isBaseline = !(await _db.isBaselineCompleted());
    if (isBaseline) {
      return runCycle1(
        loadCredentials: loadCredentials,
        ignoreAuthPause: ignoreAuthPause,
        isCancelled: isCancelled,
      );
    }

    final authCheck = await _ensureAuthenticated(loadCredentials, now);
    if (authCheck != null || cancelled()) {
      return authCheck ??
          const SyncRunSummary(cycle: 2, isBaseline: false, notifications: []);
    }

    final subjects = await _db.getAllSubjects();
    final monitorEval = await _db.getMonitorEvaluaciones();
    final notifications = <DetectedNotification>[];

    for (final subject in subjects) {
      if (cancelled()) {
        return const SyncRunSummary(
          cycle: 2,
          isBaseline: false,
          notifications: [],
        );
      }
      if (subject.muted || subject.isHiddenInMiel) continue;

      if (subject.hasPortafolio && subject.notifyPortafolio) {
        final portNotifs = await _syncPortafolio(
          subject,
          isBaseline: false,
          now: now,
        );
        notifications.addAll(portNotifs);
      }
      if (cancelled()) {
        return const SyncRunSummary(
          cycle: 2,
          isBaseline: false,
          notifications: [],
        );
      }
      if (monitorEval && subject.hasEvaluacion && subject.notifyEvaluacion) {
        final evalNotifs = await _syncEvaluaciones(
          subject,
          isBaseline: false,
          now: now,
        );
        notifications.addAll(evalNotifs);
      }
    }

    if (cancelled()) {
      return const SyncRunSummary(
        cycle: 2,
        isBaseline: false,
        notifications: [],
      );
    }

    await _db.setSetting(SettingKeys.lastCycle2At, now.toIso8601String());

    return SyncRunSummary(
      cycle: 2,
      isBaseline: false,
      notifications: notifications,
    );
  }

  Future<SyncRunSummary?> _ensureAuthenticated(
    CredentialsLoader loadCredentials,
    DateTime now,
  ) async {
    if (await _client.isLogged()) {
      return null;
    }

    final creds = await loadCredentials();
    if (creds == null || creds.username.isEmpty || creds.password.isEmpty) {
      return const SyncRunSummary(
        cycle: 1,
        isBaseline: false,
        notifications: [],
        authPaused: true,
        authErrorMessage:
            'No hay credenciales guardadas para iniciar sesión en MIEL.',
      );
    }

    final loginRes = await _client.login(creds.username, creds.password);
    if (loginRes.isSuccess) {
      await clearAuthPause();
      return null;
    }

    // Protección crítica: pausar polling automático ante credenciales inválidas o cuenta bloqueada
    if (loginRes.status == MielAuthStatus.invalidCredentials ||
        loginRes.status == MielAuthStatus.accountBlocked) {
      final reason =
          loginRes.message ??
          'Error de autenticación en MIEL (código ${loginRes.rawCode}).';
      await _db.setSetting(SettingKeys.accountPausedReason, reason);

      final alert = DetectedNotification(
        dedupeKey:
            'auth_paused:${loginRes.status.name}:${now.year}-${now.month}-${now.day}',
        idComision: 'sistema',
        subjectName: 'LibreMIEL — Cuenta',
        module: MielModuleType.sistema,
        title: loginRes.status == MielAuthStatus.accountBlocked
            ? 'Sincronización pausada: cuenta bloqueada'
            : 'Sincronización pausada: revisá tu clave',
        body:
            '$reason Se pausaron las comprobaciones automáticas para proteger tu cuenta.',
        targetUrl: '$kMielBaseUrl/principal/home/',
        detectedAt: now,
      );
      final inserted = await _db.insertNotificationIfNew(alert);

      return SyncRunSummary(
        cycle: 1,
        isBaseline: false,
        notifications: inserted ? [alert] : const [],
        authPaused: true,
        authErrorMessage: reason,
      );
    }

    return SyncRunSummary(
      cycle: 1,
      isBaseline: false,
      notifications: const [],
      warnings: [loginRes.message ?? 'Error temporal al autenticar con MIEL.'],
    );
  }

  Future<List<DetectedNotification>> _syncContenidos(
    Subject subject,
    DateTime now,
  ) async {
    final html = await _client.fetchContenidosHtml(subject.idComision);
    final items = parseContenidosHtml(html, subject.idComision);
    final prevSnapshots = await _db.getSnapshots(
      subject.idComision,
      _modContenidos,
    );
    final notifications = <DetectedNotification>[];

    for (final item in items) {
      final isUnseen = !prevSnapshots.containsKey(item.idElemento);
      final shouldNotify =
          item.isHighlightedNew || (prevSnapshots.isNotEmpty && isUnseen);

      if (shouldNotify) {
        final n = DetectedNotification(
          dedupeKey: 'contenido:${subject.idComision}:${item.idElemento}',
          idComision: subject.idComision,
          subjectName: subject.name,
          module: MielModuleType.contenidos,
          title: 'Nuevo contenido en ${subject.name}',
          body:
              '${item.moduleName}: ${item.title}'
              '${item.uploadDate.isNotEmpty ? ' (${item.uploadDate})' : ''}',
          targetUrl: item.url.isNotEmpty
              ? item.url
              : '$kMielBaseUrl/contenido/archivos/comision/${subject.idComision}',
          detectedAt: now,
        );
        if (await _db.insertNotificationIfNew(n)) {
          notifications.add(n);
        }
      }

      await _db.upsertSnapshot(
        idComision: subject.idComision,
        module: _modContenidos,
        itemId: item.idElemento,
        fingerprint: '${item.uploadDate}|${item.title}|${item.sizeLabel}',
        summary: item.title,
        updatedAt: now,
      );
    }

    return notifications;
  }

  Future<
    ({
      List<DetectedNotification> notifications,
      bool triggeredPortfolioCorrection,
    })
  >
  _syncMensajeria(
    Subject subject, {
    required bool isBaseline,
    required DateTime now,
  }) async {
    final html = await _client.fetchMensajeriaEntradaHtml(subject.idComision);
    final messages = parseMensajeriaEntradaHtml(html, subject.idComision);
    final prevSnapshots = await _db.getSnapshots(
      subject.idComision,
      _modMensajeria,
    );
    final notifications = <DetectedNotification>[];
    var triggeredPortfolioCorrection = false;

    List<String>? teacherNames;

    for (final msg in messages) {
      final isNew = !prevSnapshots.containsKey(msg.idMensaje);
      if (!isBaseline && msg.isUnread && isNew) {
        teacherNames ??= await _getOrRefreshTeachers(subject.idComision, now);
        final fromTeacher = isSenderTeacher(msg.senderName, teacherNames);
        final isCorrection = isPortfolioCorrectionMessage(msg);
        if (isCorrection) {
          triggeredPortfolioCorrection = true;
        }

        final roleTag = fromTeacher ? ' (Docente)' : '';
        final n = DetectedNotification(
          dedupeKey: 'mensaje:${subject.idComision}:${msg.idMensaje}',
          idComision: subject.idComision,
          subjectName: subject.name,
          module: MielModuleType.mensajeria,
          title: isCorrection
              ? 'Corrección en ${subject.name}'
              : 'Nuevo mensaje en ${subject.name}',
          body:
              '${msg.senderName}$roleTag: ${msg.subject}'
              '${msg.hasAttachment ? ' 📎' : ''}',
          targetUrl: msg.detailUrl.isNotEmpty
              ? msg.detailUrl
              : '$kMielBaseUrl/mensajeria/entrada/comision/${subject.idComision}',
          detectedAt: now,
        );
        if (await _db.insertNotificationIfNew(n)) {
          notifications.add(n);
        }
      }

      await _db.upsertSnapshot(
        idComision: subject.idComision,
        module: _modMensajeria,
        itemId: msg.idMensaje,
        fingerprint: '${msg.isUnread}|${msg.date}|${msg.subject}',
        summary: '${msg.senderName}: ${msg.subject}',
        updatedAt: now,
      );
    }

    return (
      notifications: notifications,
      triggeredPortfolioCorrection: triggeredPortfolioCorrection,
    );
  }

  Future<List<String>> _getOrRefreshTeachers(
    String idComision,
    DateTime now,
  ) async {
    final cached = await _db.getTeachersForSubject(idComision);
    final isFresh =
        cached.isNotEmpty &&
        now.difference(cached.first.cachedAt) < const Duration(hours: 24);
    if (isFresh) {
      return cached.map((t) => t.normalizedName).toList();
    }

    try {
      final detailsHtml = await _client.fetchCursoDetallesHtml(idComision);
      final details = parseCursoDetallesHtml(detailsHtml, idComision);
      if (details.teachers.isNotEmpty) {
        await _db.replaceTeachersForSubject(idComision, details.teachers, now);
        return details.teachers.map((t) => t.normalizedName).toList();
      }
    } catch (_) {
      // Si falla cursoDetalles, degradar suavemente al cache anterior si existía
    }
    return cached.map((t) => t.normalizedName).toList();
  }

  Future<List<DetectedNotification>> _syncPortafolio(
    Subject subject, {
    required bool isBaseline,
    required DateTime now,
  }) async {
    final html = await _client.fetchPortafolioPracticasHtml(subject.idComision);
    final practices = parsePortafolioPracticasHtml(html, subject.idComision);
    final prevSnapshots = await _db.getSnapshots(
      subject.idComision,
      _modPortafolio,
    );
    final notifications = <DetectedNotification>[];

    for (final p in practices) {
      final prev = prevSnapshots[p.idPractica];
      final fp = p.fingerprint;

      if (!isBaseline && (prev == null || prev.fingerprint != fp)) {
        final isNewPractice = prev == null;
        var title = isNewPractice
            ? 'Nueva práctica en ${subject.name}'
            : 'Actualización de Portafolio en ${subject.name}';
        final parts = <String>[
          if (p.moduleName.isNotEmpty)
            '${p.moduleName} — ${p.title}'
          else
            p.title,
        ];

        // Si hubo corrección / estado / nota nueva, enriquecer con div.correccion
        final hasCorrectionUpdate =
            !isNewPractice &&
            (p.correctionDate.isNotEmpty ||
                p.status.isNotEmpty ||
                p.grade.isNotEmpty);
        if (hasCorrectionUpdate) {
          title = 'Devolución en Portafolio — ${subject.name}';
          try {
            final detailHtml = await _client.fetchPortafolioEntregasHtml(
              subject.idComision,
              p.idPractica,
            );
            final corrections = parsePortafolioCorreccionesHtml(detailHtml);
            if (corrections.isNotEmpty) {
              final latest = corrections.first;
              if (latest.status.isNotEmpty) {
                parts.add('Estado: ${latest.status}');
              }
              if (latest.grade.isNotEmpty) {
                parts.add('Nota: ${latest.grade}');
              }
              if (latest.correctedBy.isNotEmpty) {
                parts.add('Por: ${latest.correctedBy}');
              }
              if (latest.observations.isNotEmpty) {
                parts.add('Obs: ${latest.observations}');
              }
            }
          } catch (_) {
            if (p.status.isNotEmpty) parts.add('Estado: ${p.status}');
            if (p.grade.isNotEmpty) parts.add('Nota: ${p.grade}');
          }
        } else if (p.dueDate.isNotEmpty) {
          parts.add('Vencimiento: ${p.dueDate}');
        }

        final n = DetectedNotification(
          dedupeKey: 'portafolio:${subject.idComision}:${p.idPractica}:$fp',
          idComision: subject.idComision,
          subjectName: subject.name,
          module: MielModuleType.portafolio,
          title: title,
          body: parts.join(' · '),
          targetUrl: p.detailUrl.isNotEmpty
              ? p.detailUrl
              : '$kMielBaseUrl/portafolio/practicas/comision/${subject.idComision}',
          detectedAt: now,
        );
        if (await _db.insertNotificationIfNew(n)) {
          notifications.add(n);
        }
      }

      await _db.upsertSnapshot(
        idComision: subject.idComision,
        module: _modPortafolio,
        itemId: p.idPractica,
        fingerprint: fp,
        summary: p.title,
        updatedAt: now,
      );
    }

    return notifications;
  }

  Future<List<DetectedNotification>> _syncForos(
    Subject subject, {
    required ForumSyncMode mode,
    required bool isBaseline,
    required DateTime now,
  }) async {
    final html = await _client.fetchForoTemasHtml(subject.idComision);
    final topics = parseForoTemasHtml(html, subject.idComision);
    final prevTopics = await _db.getSnapshots(
      subject.idComision,
      _modForoTemas,
    );
    final notifications = <DetectedNotification>[];

    for (final topic in topics) {
      final prev = prevTopics[topic.idTema];
      final changed = prev == null || prev.fingerprint != topic.fingerprint;

      if (!isBaseline && changed && topic.unreadBadge > 0) {
        if (mode == ForumSyncMode.nonInvasive) {
          final n = DetectedNotification(
            dedupeKey:
                'foro_tema:${subject.idComision}:${topic.idTema}:${topic.fingerprint}',
            idComision: subject.idComision,
            subjectName: subject.name,
            module: MielModuleType.foros,
            title: 'Actividad en foro de ${subject.name}',
            body:
                '${topic.title} (${topic.unreadBadge} sin leer'
                '${topic.lastMessageDate.isNotEmpty ? ' · último ${topic.lastMessageDate}' : ''})',
            targetUrl: topic.url.isNotEmpty
                ? topic.url
                : '$kMielBaseUrl/forov2/temas/comision/${subject.idComision}',
            detectedAt: now,
          );
          if (await _db.insertNotificationIfNew(n)) {
            notifications.add(n);
          }
        } else {
          // Modo detallado: inspeccionar hilo para detectar respuestas de Tutor/a al usuario
          final threadHtml = await _client.fetchForoMensajesHtml(
            subject.idComision,
            topic.idTema,
          );
          final thread = parseForoMensajesHtml(
            threadHtml,
            subject.idComision,
            topic.idTema,
          );
          final prevMsgs = await _db.getSnapshots(
            subject.idComision,
            _modForoMensajes,
          );

          for (final msg in thread.messages) {
            final msgKey = '${topic.idTema}:${msg.id}';
            final isNewMsg = !prevMsgs.containsKey(msgKey);
            if (isNewMsg && isTeacherReplyToCurrentUser(msg, thread)) {
              final preview = msg.bodyText.length > 140
                  ? '${msg.bodyText.substring(0, 140)}…'
                  : msg.bodyText;
              final n = DetectedNotification(
                dedupeKey:
                    'foro_reply:${subject.idComision}:${topic.idTema}:${msg.id}',
                idComision: subject.idComision,
                subjectName: subject.name,
                module: MielModuleType.foros,
                title: 'Un docente te respondió en ${subject.name}',
                body: '${msg.authorName} en "${thread.title}": $preview',
                targetUrl: topic.url.isNotEmpty
                    ? topic.url
                    : '$kMielBaseUrl/forov2/mensajes/comision/${subject.idComision}/tema/${topic.idTema}',
                detectedAt: now,
              );
              if (await _db.insertNotificationIfNew(n)) {
                notifications.add(n);
              }
            }

            await _db.upsertSnapshot(
              idComision: subject.idComision,
              module: _modForoMensajes,
              itemId: msgKey,
              fingerprint: '${msg.authorId}|${msg.date}',
              summary: msg.authorName,
              updatedAt: now,
            );
          }
        }
      }

      await _db.upsertSnapshot(
        idComision: subject.idComision,
        module: _modForoTemas,
        itemId: topic.idTema,
        fingerprint: topic.fingerprint,
        summary: topic.title,
        updatedAt: now,
      );
    }

    return notifications;
  }

  Future<List<DetectedNotification>> _syncEvaluaciones(
    Subject subject, {
    required bool isBaseline,
    required DateTime now,
  }) async {
    final html = await _client.fetchEvaluacionesHtml(subject.idComision);
    final items = parseEvaluacionesHtml(html, subject.idComision);
    final prev = await _db.getSnapshots(subject.idComision, _modEvaluacion);
    final notifications = <DetectedNotification>[];

    for (final item in items) {
      final old = prev[item.id];
      final changed = old == null || old.fingerprint != item.fingerprint;
      if (!isBaseline && changed) {
        final n = DetectedNotification(
          dedupeKey:
              'eval:${subject.idComision}:${item.id}:${item.fingerprint}',
          idComision: subject.idComision,
          subjectName: subject.name,
          module: MielModuleType.evaluacion,
          title: 'Evaluación en ${subject.name}',
          body:
              '${item.type.isNotEmpty ? '[${item.type}] ' : ''}${item.title} — '
              '${item.status.isNotEmpty ? item.status : (item.isEnabled ? 'Habilitada' : 'Publicada')}',
          targetUrl:
              '$kMielBaseUrl/evaluacion/evaluaciones/comision/${subject.idComision}',
          detectedAt: now,
        );
        if (await _db.insertNotificationIfNew(n)) {
          notifications.add(n);
        }
      }

      await _db.upsertSnapshot(
        idComision: subject.idComision,
        module: _modEvaluacion,
        itemId: item.id,
        fingerprint: item.fingerprint,
        summary: item.title,
        updatedAt: now,
      );
    }

    return notifications;
  }
}
