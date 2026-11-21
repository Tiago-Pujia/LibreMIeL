import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/miel_models.dart';

part 'app_database.g.dart';

/// Materias / comisiones detectadas en `/principal/interno/` y sus preferencias locales.
class Subjects extends Table {
  TextColumn get idComision => text()();
  TextColumn get name => text()();
  TextColumn get subjectCode => text().withDefault(const Constant(''))();
  TextColumn get commissionCode => text().withDefault(const Constant(''))();
  TextColumn get roleLabel => text().withDefault(const Constant(''))();
  BoolColumn get isHiddenInMiel =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  BoolColumn get notifyContenidos =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get notifyPortafolio =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get notifyMensajeria =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get notifyForos => boolean().withDefault(const Constant(true))();
  BoolColumn get notifyEvaluacion =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get hasContenidos => boolean().withDefault(const Constant(true))();
  BoolColumn get hasAutoguia => boolean().withDefault(const Constant(false))();
  BoolColumn get hasPortafolio =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get hasMensajeria => boolean().withDefault(const Constant(true))();
  BoolColumn get hasForo => boolean().withDefault(const Constant(true))();
  BoolColumn get hasChat => boolean().withDefault(const Constant(false))();
  BoolColumn get hasEncuestas => boolean().withDefault(const Constant(false))();
  BoolColumn get hasEvaluacion =>
      boolean().withDefault(const Constant(false))();
  IntColumn get lastContenidosBadge =>
      integer().withDefault(const Constant(0))();
  IntColumn get lastMensajesBadge => integer().withDefault(const Constant(0))();
  IntColumn get lastForoBadge => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get localVisibilityOverride =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {idComision};
}

/// Caché local de docentes (`Tutor/a`) por comisión obtenidos desde `/principal/cursoDetalles/`.
class CachedTeachers extends Table {
  TextColumn get idComision => text()();
  TextColumn get normalizedName => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text().withDefault(const Constant('Tutor/a'))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {idComision, normalizedName};
}

/// Snapshots por módulo e ítem para detección determinista de novedades (diff local).
class SnapshotEntries extends Table {
  TextColumn get idComision => text()();
  TextColumn get module => text()();
  TextColumn get itemId => text()();
  TextColumn get fingerprint => text()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {idComision, module, itemId};
}

/// Historial local de notificaciones emitidas por LibreMIeL (Feed unificado).
class NotificationLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dedupeKey => text().unique()();
  TextColumn get idComision => text()();
  TextColumn get subjectName => text()();
  TextColumn get module => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get targetUrl => text().withDefault(const Constant(''))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Registro local de archivos y foros descargados / respaldados.
class DownloadedResources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idComision => text()();
  TextColumn get module => text()(); // 'contenidos', 'forov2'
  TextColumn get resourceId => text()(); // idElemento o idTema
  TextColumn get title => text()();
  TextColumn get localPath => text()();
  Int64Column get fileSize => int64()();
  TextColumn get sha256 => text().nullable()();
  DateTimeColumn get downloadedAt => dateTime()();
}

/// Configuración clave-valor persistida localmente (intervalo, modo de foros, baseline, etc.).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class SettingKeys {
  static const String baselineCompleted = 'baseline_completed';
  static const String syncIntervalMinutes = 'sync_interval_minutes';
  static const String forumSyncMode = 'forum_sync_mode';
  static const String monitorEvaluaciones = 'monitor_evaluaciones';
  static const String accountPausedReason = 'account_paused_reason';
  static const String accountUsername = 'account_username';
  static const String studentName = 'student_name';
  static const String studentAvatarUrl = 'student_avatar_url';
  static const String globalNovedadesBadge = 'global_novedades_badge';
  static const String lastCycle1At = 'last_cycle1_at';
  static const String lastCycle2At = 'last_cycle2_at';
  static const String themeMode = 'theme_mode';
  static const String launchAtStartup = 'launch_at_startup';
}

@DriftDatabase(
  tables: [
    Subjects,
    CachedTeachers,
    SnapshotEntries,
    NotificationLogs,
    AppSettings,
    DownloadedResources,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'libremiel'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(subjects, subjects.subjectCode);
        await m.addColumn(subjects, subjects.roleLabel);
        await m.addColumn(subjects, subjects.hasContenidos);
        await m.addColumn(subjects, subjects.hasAutoguia);
        await m.addColumn(subjects, subjects.hasMensajeria);
        await m.addColumn(subjects, subjects.hasForo);
        await m.addColumn(subjects, subjects.hasChat);
        await m.addColumn(subjects, subjects.hasEncuestas);
      }
      if (from < 3) {
        await m.addColumn(subjects, subjects.sortOrder);
        await m.addColumn(subjects, subjects.localVisibilityOverride);
      }
      if (from < 4) {
        await m.createTable(downloadedResources);
      }
    },
  );

  // --- Settings ---

  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  Future<void> deleteSetting(String key) async {
    await (delete(appSettings)..where((t) => t.key.equals(key))).go();
  }

  Future<bool> isBaselineCompleted() async {
    return (await getSetting(SettingKeys.baselineCompleted)) == 'true';
  }

  Future<int> getSyncIntervalMinutes() async {
    final raw = await getSetting(SettingKeys.syncIntervalMinutes);
    return int.tryParse(raw ?? '') ?? 15;
  }

  Future<ForumSyncMode> getForumSyncMode() async {
    final raw = await getSetting(SettingKeys.forumSyncMode);
    if (raw == ForumSyncMode.teacherReplies.name) {
      return ForumSyncMode.teacherReplies;
    }
    return ForumSyncMode.nonInvasive;
  }

  Future<bool> getMonitorEvaluaciones() async {
    final raw = await getSetting(SettingKeys.monitorEvaluaciones);
    return raw != 'false';
  }

  // --- Subjects ---

  Future<List<Subject>> getAllSubjects() {
    return (select(subjects)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.name),
        ]))
        .get();
  }

  Stream<List<Subject>> watchAllSubjects() {
    return (select(subjects)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.name),
        ]))
        .watch();
  }

  Future<Subject?> getSubject(String idComision) {
    return (select(
      subjects,
    )..where((t) => t.idComision.equals(idComision))).getSingleOrNull();
  }

  Future<Subject> upsertSubjectFromInterno(
    MielSubjectBadgeSummary summary,
    DateTime syncedAt,
  ) async {
    final existing = await getSubject(summary.idComision);
    if (existing == null) {
      await into(subjects).insert(
        SubjectsCompanion.insert(
          idComision: summary.idComision,
          name: summary.name,
          subjectCode: Value(summary.subjectCode),
          commissionCode: Value(summary.commissionCode),
          roleLabel: Value(summary.roleLabel),
          isHiddenInMiel: Value(summary.isHidden),
          muted: Value(summary.isHidden),
          hasContenidos: Value(summary.hasContenidos),
          hasAutoguia: Value(summary.hasAutoguia),
          hasPortafolio: Value(summary.hasPortafolio),
          hasMensajeria: Value(summary.hasMensajeria),
          hasForo: Value(summary.hasForo),
          hasChat: Value(summary.hasChat),
          hasEncuestas: Value(summary.hasEncuestas),
          hasEvaluacion: Value(summary.hasEvaluacion),
          lastContenidosBadge: Value(summary.contenidosBadge),
          lastMensajesBadge: Value(summary.mensajesBadge),
          lastForoBadge: Value(summary.foroBadge),
          lastSyncedAt: Value(syncedAt),
        ),
      );
    } else {
      await (update(
        subjects,
      )..where((t) => t.idComision.equals(summary.idComision))).write(
        SubjectsCompanion(
          name: Value(summary.name),
          subjectCode: Value(summary.subjectCode),
          commissionCode: Value(summary.commissionCode),
          roleLabel: Value(summary.roleLabel),
          isHiddenInMiel: Value(summary.isHidden),
          hasContenidos: Value(summary.hasContenidos),
          hasAutoguia: Value(summary.hasAutoguia),
          hasPortafolio: Value(summary.hasPortafolio),
          hasMensajeria: Value(summary.hasMensajeria),
          hasForo: Value(summary.hasForo),
          hasChat: Value(summary.hasChat),
          hasEncuestas: Value(summary.hasEncuestas),
          hasEvaluacion: Value(summary.hasEvaluacion),
          lastContenidosBadge: Value(summary.contenidosBadge),
          lastMensajesBadge: Value(summary.mensajesBadge),
          lastForoBadge: Value(summary.foroBadge),
          lastSyncedAt: Value(syncedAt),
        ),
      );
    }
    return (await getSubject(summary.idComision))!;
  }

  Future<void> updateSubjectsOrder(List<String> orderedIds) async {
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(subjects)
              ..where((t) => t.idComision.equals(orderedIds[i])))
            .write(SubjectsCompanion(sortOrder: Value(i + 1)));
      }
    });
  }

  /// `overrideValue`: `-1` ocultar localmente, `1` forzar visible, `0` seguir a MIeL.
  Future<void> setSubjectLocalVisibility(
    String idComision,
    int overrideValue,
  ) async {
    await (update(
      subjects,
    )..where((t) => t.idComision.equals(idComision))).write(
      SubjectsCompanion(localVisibilityOverride: Value(overrideValue)),
    );
  }

  Future<void> updateSubjectPreferences({
    required String idComision,
    bool? muted,
    bool? notifyContenidos,
    bool? notifyPortafolio,
    bool? notifyMensajeria,
    bool? notifyForos,
    bool? notifyEvaluacion,
  }) async {
    await (update(
      subjects,
    )..where((t) => t.idComision.equals(idComision))).write(
      SubjectsCompanion(
        muted: muted != null ? Value(muted) : const Value.absent(),
        notifyContenidos: notifyContenidos != null
            ? Value(notifyContenidos)
            : const Value.absent(),
        notifyPortafolio: notifyPortafolio != null
            ? Value(notifyPortafolio)
            : const Value.absent(),
        notifyMensajeria: notifyMensajeria != null
            ? Value(notifyMensajeria)
            : const Value.absent(),
        notifyForos: notifyForos != null
            ? Value(notifyForos)
            : const Value.absent(),
        notifyEvaluacion: notifyEvaluacion != null
            ? Value(notifyEvaluacion)
            : const Value.absent(),
      ),
    );
  }

  /// Al abrir interactivamente Contenidos en Fase 2, MIeL limpia el badge del servidor.
  Future<void> clearContenidosBadge(String idComision) async {
    await (update(subjects)..where((t) => t.idComision.equals(idComision)))
        .write(const SubjectsCompanion(lastContenidosBadge: Value(0)));
  }

  /// Al abrir interactivamente un mensaje no leído (`verEntrada`), descuenta 1 del badge local.
  Future<void> decrementMensajesBadge(
    String idComision, {
    int delta = 1,
  }) async {
    final subject = await getSubject(idComision);
    if (subject == null || subject.lastMensajesBadge <= 0) return;
    final next = (subject.lastMensajesBadge - delta).clamp(0, 9999);
    await (update(subjects)..where((t) => t.idComision.equals(idComision)))
        .write(SubjectsCompanion(lastMensajesBadge: Value(next)));
  }

  /// Al abrir interactivamente un tema de foro con no leídos, descuenta su badge del total local.
  Future<void> decrementForoBadge(String idComision, int delta) async {
    if (delta <= 0) return;
    final subject = await getSubject(idComision);
    if (subject == null || subject.lastForoBadge <= 0) return;
    final next = (subject.lastForoBadge - delta).clamp(0, 9999);
    await (update(subjects)..where((t) => t.idComision.equals(idComision)))
        .write(SubjectsCompanion(lastForoBadge: Value(next)));
  }

  // --- Teachers cache ---

  Future<List<CachedTeacher>> getTeachersForSubject(String idComision) {
    return (select(
      cachedTeachers,
    )..where((t) => t.idComision.equals(idComision))).get();
  }

  Stream<List<CachedTeacher>> watchTeachersForSubject(String idComision) {
    return (select(cachedTeachers)
          ..where((t) => t.idComision.equals(idComision))
          ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
        .watch();
  }

  Future<void> replaceTeachersForSubject(
    String idComision,
    List<CourseTeacher> teachers,
    DateTime cachedAt,
  ) async {
    await transaction(() async {
      await (delete(
        cachedTeachers,
      )..where((t) => t.idComision.equals(idComision))).go();
      for (final t in teachers) {
        await into(cachedTeachers).insertOnConflictUpdate(
          CachedTeachersCompanion.insert(
            idComision: idComision,
            normalizedName: t.normalizedName,
            displayName: t.name,
            role: Value(t.role),
            cachedAt: cachedAt,
          ),
        );
      }
    });
  }

  // --- Snapshots ---

  Future<Map<String, SnapshotEntry>> getSnapshots(
    String idComision,
    String module,
  ) async {
    final rows =
        await (select(snapshotEntries)..where(
              (t) => t.idComision.equals(idComision) & t.module.equals(module),
            ))
            .get();
    return {for (final r in rows) r.itemId: r};
  }

  Stream<List<SnapshotEntry>> watchSnapshotsForSubject(
    String idComision,
    String module,
  ) {
    return (select(snapshotEntries)
          ..where(
            (t) => t.idComision.equals(idComision) & t.module.equals(module),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<void> upsertSnapshot({
    required String idComision,
    required String module,
    required String itemId,
    required String fingerprint,
    String summary = '',
    required DateTime updatedAt,
  }) async {
    await into(snapshotEntries).insertOnConflictUpdate(
      SnapshotEntriesCompanion.insert(
        idComision: idComision,
        module: module,
        itemId: itemId,
        fingerprint: fingerprint,
        summary: Value(summary),
        updatedAt: updatedAt,
      ),
    );
  }

  // --- Notifications ---

  Future<bool> insertNotificationIfNew(
    DetectedNotification notification,
  ) async {
    final existing =
        await (select(notificationLogs)
              ..where((t) => t.dedupeKey.equals(notification.dedupeKey)))
            .getSingleOrNull();
    if (existing != null) return false;

    await into(notificationLogs).insert(
      NotificationLogsCompanion.insert(
        dedupeKey: notification.dedupeKey,
        idComision: notification.idComision,
        subjectName: notification.subjectName,
        module: notification.module.name,
        title: notification.title,
        body: notification.body,
        targetUrl: Value(notification.targetUrl),
        createdAt: notification.detectedAt,
      ),
    );
    return true;
  }

  Stream<List<NotificationLog>> watchNotifications({
    String? idComision,
    String? module,
  }) {
    final query = select(notificationLogs)
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (idComision != null && idComision.isNotEmpty) {
      query.where((t) => t.idComision.equals(idComision));
    }
    if (module != null && module.isNotEmpty) {
      query.where((t) => t.module.equals(module));
    }
    return query.watch();
  }

  Stream<int> watchUnreadNotificationsCount() {
    final query = select(notificationLogs)
      ..where((t) => t.isRead.equals(false));
    return query.watch().map((rows) => rows.length);
  }

  Future<void> markNotificationRead(int id, {bool isRead = true}) async {
    await (update(notificationLogs)..where((t) => t.id.equals(id))).write(
      NotificationLogsCompanion(isRead: Value(isRead)),
    );
  }

  Future<void> markAllNotificationsRead() async {
    await update(notificationLogs)
        .write(const NotificationLogsCompanion(isRead: Value(true)));
  }

  /// Elimina materias (junto con sus docentes y snapshots) que ya no existen
  /// en `/principal/interno/` para evitar datos residuales entre cuentas o cuatrimestres.
  Future<void> pruneSubjectsNotIn(Set<String> activeCommissionIds) async {
    await transaction(() async {
      if (activeCommissionIds.isEmpty) {
        await delete(cachedTeachers).go();
        await delete(snapshotEntries).go();
        await delete(subjects).go();
        return;
      }
      final ids = activeCommissionIds.toList();
      await (delete(subjects)..where((t) => t.idComision.isNotIn(ids))).go();
      await (delete(
        cachedTeachers,
      )..where((t) => t.idComision.isNotIn(ids))).go();
      await (delete(
        snapshotEntries,
      )..where((t) => t.idComision.isNotIn(ids))).go();
    });
  }

  /// Borra únicamente los datos asociados a la cuenta de MIeL (materias, snapshots,
  /// docentes, notificaciones y estado de sesión), preservando preferencias globales
  /// de la app (tema, intervalo de sync, inicio automático).
  Future<void> clearAccountData() async {
    await transaction(() async {
      await delete(notificationLogs).go();
      await delete(snapshotEntries).go();
      await delete(cachedTeachers).go();
      await delete(subjects).go();
      await (delete(appSettings)..where(
            (t) => t.key.isIn(const [
              SettingKeys.accountUsername,
              SettingKeys.studentName,
              SettingKeys.studentAvatarUrl,
              SettingKeys.globalNovedadesBadge,
              SettingKeys.baselineCompleted,
              SettingKeys.lastCycle1At,
              SettingKeys.lastCycle2At,
              SettingKeys.accountPausedReason,
            ]),
          ))
          .go();
    });
  }

  // --- Downloaded Resources (Fase 4) ---

  Future<int> recordDownloadedResource({
    required String idComision,
    required String module,
    required String resourceId,
    required String title,
    required String localPath,
    required BigInt fileSize,
    String? sha256,
  }) async {
    final existing = await (select(downloadedResources)
          ..where((t) =>
              t.idComision.equals(idComision) &
              t.module.equals(module) &
              t.resourceId.equals(resourceId)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(downloadedResources)..where((t) => t.id.equals(existing.id))).write(
        DownloadedResourcesCompanion(
          title: Value(title),
          localPath: Value(localPath),
          fileSize: Value(fileSize),
          sha256: Value(sha256),
          downloadedAt: Value(DateTime.now()),
        ),
      );
      return existing.id;
    } else {
      return into(downloadedResources).insert(
        DownloadedResourcesCompanion.insert(
          idComision: idComision,
          module: module,
          resourceId: resourceId,
          title: title,
          localPath: localPath,
          fileSize: fileSize,
          sha256: Value(sha256),
          downloadedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<DownloadedResource?> getDownloadedResource({
    required String idComision,
    required String module,
    required String resourceId,
  }) {
    return (select(downloadedResources)
          ..where((t) =>
              t.idComision.equals(idComision) &
              t.module.equals(module) &
              t.resourceId.equals(resourceId)))
        .getSingleOrNull();
  }

  Future<List<DownloadedResource>> getDownloadedResourcesForSubject(
    String idComision, {
    String? module,
  }) {
    final query = select(downloadedResources)..where((t) => t.idComision.equals(idComision));
    if (module != null) {
      query.where((t) => t.module.equals(module));
    }
    return query.get();
  }

  Future<bool> isResourceDownloaded({
    required String idComision,
    required String module,
    required String resourceId,
  }) async {
    final count = await (selectOnly(downloadedResources)
          ..addColumns([downloadedResources.id.count()])
          ..where(
            downloadedResources.idComision.equals(idComision) &
                downloadedResources.module.equals(module) &
                downloadedResources.resourceId.equals(resourceId),
          ))
        .getSingle();
    final total = count.read(downloadedResources.id.count()) ?? 0;
    return total > 0;
  }

  Future<void> clearDownloadedResourcesForSubject(String idComision) async {
    await (delete(downloadedResources)..where((t) => t.idComision.equals(idComision))).go();
  }

  /// Borra todos los datos locales al cerrar sesión.
  Future<void> clearAllLocalData() async {
    await transaction(() async {
      await delete(downloadedResources).go();
      await delete(notificationLogs).go();
      await delete(snapshotEntries).go();
      await delete(cachedTeachers).go();
      await delete(subjects).go();
      await delete(appSettings).go();
    });
  }
}
