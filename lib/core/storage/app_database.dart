import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/miel_models.dart';

part 'app_database.g.dart';

/// Materias / comisiones detectadas en `/principal/interno/` y sus preferencias locales.
class Subjects extends Table {
  TextColumn get idComision => text()();
  TextColumn get name => text()();
  TextColumn get commissionCode => text().withDefault(const Constant(''))();
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
  BoolColumn get hasPortafolio =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get hasEvaluacion =>
      boolean().withDefault(const Constant(false))();
  IntColumn get lastContenidosBadge =>
      integer().withDefault(const Constant(0))();
  IntColumn get lastMensajesBadge => integer().withDefault(const Constant(0))();
  IntColumn get lastForoBadge => integer().withDefault(const Constant(0))();
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

/// Historial local de notificaciones emitidas por LibreMIEL (Feed unificado).
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
  static const String studentName = 'student_name';
  static const String globalNovedadesBadge = 'global_novedades_badge';
  static const String lastCycle1At = 'last_cycle1_at';
  static const String lastCycle2At = 'last_cycle2_at';
}

@DriftDatabase(
  tables: [
    Subjects,
    CachedTeachers,
    SnapshotEntries,
    NotificationLogs,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'libremiel'));

  @override
  int get schemaVersion => 1;

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
          (t) => OrderingTerm.asc(t.isHiddenInMiel),
          (t) => OrderingTerm.asc(t.name),
        ]))
        .get();
  }

  Stream<List<Subject>> watchAllSubjects() {
    return (select(subjects)..orderBy([
          (t) => OrderingTerm.asc(t.isHiddenInMiel),
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
          commissionCode: Value(summary.commissionCode),
          isHiddenInMiel: Value(summary.isHidden),
          muted: Value(summary.isHidden),
          hasPortafolio: Value(summary.hasPortafolio),
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
          commissionCode: Value(summary.commissionCode),
          isHiddenInMiel: Value(summary.isHidden),
          hasPortafolio: Value(summary.hasPortafolio),
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

  // --- Teachers cache ---

  Future<List<CachedTeacher>> getTeachersForSubject(String idComision) {
    return (select(
      cachedTeachers,
    )..where((t) => t.idComision.equals(idComision))).get();
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

  Future<void> markNotificationRead(int id, {bool isRead = true}) async {
    await (update(notificationLogs)..where((t) => t.id.equals(id))).write(
      NotificationLogsCompanion(isRead: Value(isRead)),
    );
  }

  Future<void> markAllNotificationsRead() async {
    await update(notificationLogs)
        .write(const NotificationLogsCompanion(isRead: Value(true)));
  }

  /// Borra todos los datos locales al cerrar sesión.
  Future<void> clearAllLocalData() async {
    await transaction(() async {
      await delete(notificationLogs).go();
      await delete(snapshotEntries).go();
      await delete(cachedTeachers).go();
      await delete(subjects).go();
      await delete(appSettings).go();
    });
  }
}
