import 'dart:convert';

import '../core/models/miel_models.dart';
import '../core/storage/app_database.dart';
import '../core/theme/miel_theme.dart';

/// Materia activa resumida para mostrar en los App Widgets de Android.
class AndroidWidgetSubjectItem {
  const AndroidWidgetSubjectItem({
    required this.idComision,
    required this.name,
    required this.commissionCode,
    required this.contenidosBadge,
    required this.mensajesBadge,
    required this.foroBadge,
    required this.defaultTool,
  });

  final String idComision;
  final String name;
  final String commissionCode;
  final int contenidosBadge;
  final int mensajesBadge;
  final int foroBadge;
  final String defaultTool;

  int get totalBadges => contenidosBadge + mensajesBadge + foroBadge;

  Map<String, dynamic> toJson() => {
    'idComision': idComision,
    'name': name,
    'commissionCode': commissionCode,
    'contenidosBadge': contenidosBadge,
    'mensajesBadge': mensajesBadge,
    'foroBadge': foroBadge,
    'totalBadges': totalBadges,
    'defaultTool': defaultTool,
  };

  factory AndroidWidgetSubjectItem.fromJson(Map<String, dynamic> json) =>
      AndroidWidgetSubjectItem(
        idComision: json['idComision'] as String? ?? '',
        name: json['name'] as String? ?? '',
        commissionCode: json['commissionCode'] as String? ?? '',
        contenidosBadge: (json['contenidosBadge'] as num?)?.toInt() ?? 0,
        mensajesBadge: (json['mensajesBadge'] as num?)?.toInt() ?? 0,
        foroBadge: (json['foroBadge'] as num?)?.toInt() ?? 0,
        defaultTool: json['defaultTool'] as String? ?? 'contenidos',
      );
}

/// Novedad reciente resumida para renderizar en los App Widgets de Android.
class AndroidWidgetNotificationItem {
  const AndroidWidgetNotificationItem({
    required this.id,
    required this.idComision,
    required this.subjectName,
    required this.module,
    required this.title,
    required this.body,
    required this.targetUrl,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String idComision;
  final String subjectName;
  final String module;
  final String title;
  final String body;
  final String targetUrl;
  final bool isRead;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'idComision': idComision,
    'subjectName': subjectName,
    'module': module,
    'title': title,
    'body': body,
    'targetUrl': targetUrl,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AndroidWidgetNotificationItem.fromJson(Map<String, dynamic> json) =>
      AndroidWidgetNotificationItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        idComision: json['idComision'] as String? ?? '',
        subjectName: json['subjectName'] as String? ?? '',
        module: json['module'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        targetUrl: json['targetUrl'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Instantánea serializable compartida con los `AppWidgetProvider` nativos en Android.
class AndroidWidgetSnapshot {
  const AndroidWidgetSnapshot({
    this.schemaVersion = 1,
    required this.isAuthenticated,
    required this.serverStatus,
    this.authPaused = false,
    this.unreadCount = 0,
    this.pendingSubjectsBadgeCount = 0,
    this.lastSyncAt,
    this.lastOnlineSuccessAt,
    this.recentNotifications = const [],
    this.activeSubjects = const [],
  });

  factory AndroidWidgetSnapshot.signedOut() => const AndroidWidgetSnapshot(
    isAuthenticated: false,
    serverStatus: MielServerStatus.online,
  );

  final int schemaVersion;
  final bool isAuthenticated;
  final MielServerStatus serverStatus;
  final bool authPaused;
  final int unreadCount;
  final int pendingSubjectsBadgeCount;
  final DateTime? lastSyncAt;
  final DateTime? lastOnlineSuccessAt;
  final List<AndroidWidgetNotificationItem> recentNotifications;
  final List<AndroidWidgetSubjectItem> activeSubjects;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'isAuthenticated': isAuthenticated,
    'serverStatus': serverStatus.name,
    'authPaused': authPaused,
    'unreadCount': unreadCount,
    'pendingSubjectsBadgeCount': pendingSubjectsBadgeCount,
    if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.toIso8601String(),
    if (lastOnlineSuccessAt != null)
      'lastOnlineSuccessAt': lastOnlineSuccessAt!.toIso8601String(),
    'recentNotifications': [for (final n in recentNotifications) n.toJson()],
    'activeSubjects': [for (final s in activeSubjects) s.toJson()],
  };

  String toJsonString() => jsonEncode(toJson());

  factory AndroidWidgetSnapshot.fromJson(Map<String, dynamic> json) {
    final statusName = json['serverStatus'] as String? ?? 'online';
    final status = MielServerStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => MielServerStatus.online,
    );
    final rawNotifs = json['recentNotifications'] as List<dynamic>? ?? const [];
    final rawSubjects = json['activeSubjects'] as List<dynamic>? ?? const [];
    return AndroidWidgetSnapshot(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      serverStatus: status,
      authPaused: json['authPaused'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      pendingSubjectsBadgeCount:
          (json['pendingSubjectsBadgeCount'] as num?)?.toInt() ?? 0,
      lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
      lastOnlineSuccessAt: DateTime.tryParse(
        json['lastOnlineSuccessAt'] as String? ?? '',
      ),
      recentNotifications: rawNotifs
          .whereType<Map<String, dynamic>>()
          .map(AndroidWidgetNotificationItem.fromJson)
          .toList(growable: false),
      activeSubjects: rawSubjects
          .whereType<Map<String, dynamic>>()
          .map(AndroidWidgetSubjectItem.fromJson)
          .toList(growable: false),
    );
  }

  static AndroidWidgetSnapshot? tryFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AndroidWidgetSnapshot.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }
}

/// Construye un [AndroidWidgetSnapshot] limpio a partir del estado local de SQLite.
class AndroidWidgetSnapshotBuilder {
  const AndroidWidgetSnapshotBuilder();

  static const int maxRecentNotifications = 5;
  static const int maxActiveSubjects = 6;

  static String resolveDefaultToolForSubject(Subject subject) {
    if (subject.lastMensajesBadge > 0 && subject.hasMensajeria) {
      return MielModuleType.mensajeria.name;
    }
    if (subject.lastContenidosBadge > 0 && subject.hasContenidos) {
      return MielModuleType.contenidos.name;
    }
    if (subject.lastForoBadge > 0 && subject.hasForo) {
      return MielModuleType.foros.name;
    }
    if (subject.hasContenidos) return MielModuleType.contenidos.name;
    if (subject.hasMensajeria) return MielModuleType.mensajeria.name;
    if (subject.hasForo) return MielModuleType.foros.name;
    if (subject.hasPortafolio) return MielModuleType.portafolio.name;
    if (subject.hasEvaluacion) return MielModuleType.evaluacion.name;
    return MielModuleType.contenidos.name;
  }

  Future<AndroidWidgetSnapshot> buildFromDatabase({
    required AppDatabase database,
    required bool isAuthenticated,
    required MielServerStatus serverStatus,
    bool? authPaused,
    DateTime? lastSyncAt,
    DateTime? lastOnlineSuccessAt,
  }) async {
    if (!isAuthenticated) {
      return AndroidWidgetSnapshot.signedOut();
    }

    final effectiveAuthPaused =
        authPaused ??
        (((await database.getSetting(SettingKeys.accountPausedReason)) ?? '')
            .isNotEmpty);

    var effectiveLastSync = lastSyncAt;
    if (effectiveLastSync == null) {
      final rawLastCycle1 = await database.getSetting(SettingKeys.lastCycle1At);
      if (rawLastCycle1 != null && rawLastCycle1.isNotEmpty) {
        effectiveLastSync = DateTime.tryParse(rawLastCycle1);
      }
    }

    final allSubjects = await database.getAllSubjects();
    final visibleSubjects = allSubjects
        .where((s) => !s.isEffectivelyHidden)
        .toList(growable: false);

    final sortedSubjects = [...visibleSubjects]
      ..sort((a, b) {
        final aBadges =
            a.lastContenidosBadge + a.lastMensajesBadge + a.lastForoBadge;
        final bBadges =
            b.lastContenidosBadge + b.lastMensajesBadge + b.lastForoBadge;
        final aHas = aBadges > 0 ? 1 : 0;
        final bHas = bBadges > 0 ? 1 : 0;
        if (aHas != bHas) return bHas.compareTo(aHas);
        if (aBadges != bBadges) return bBadges.compareTo(aBadges);
        final sortCmp = a.sortOrder.compareTo(b.sortOrder);
        if (sortCmp != 0) return sortCmp;
        return a.name.compareTo(b.name);
      });

    final pendingSubjectsBadgeCount = visibleSubjects
        .where(
          (s) =>
              s.lastContenidosBadge + s.lastMensajesBadge + s.lastForoBadge > 0,
        )
        .length;

    final widgetSubjects = sortedSubjects
        .take(maxActiveSubjects)
        .map(
          (s) => AndroidWidgetSubjectItem(
            idComision: s.idComision,
            name: s.name,
            commissionCode: s.commissionCode,
            contenidosBadge: s.lastContenidosBadge,
            mensajesBadge: s.lastMensajesBadge,
            foroBadge: s.lastForoBadge,
            defaultTool: resolveDefaultToolForSubject(s),
          ),
        )
        .toList(growable: false);

    final unreadCount = await database.getUnreadNotificationsCount();
    final recentLogs = await database.getRecentNotifications(
      limit: maxRecentNotifications,
    );
    final widgetNotifications = recentLogs
        .map(
          (log) => AndroidWidgetNotificationItem(
            id: log.id,
            idComision: log.idComision,
            subjectName: log.subjectName,
            module: log.module,
            title: log.title,
            body: log.body,
            targetUrl: log.targetUrl,
            isRead: log.isRead,
            createdAt: log.createdAt,
          ),
        )
        .toList(growable: false);

    return AndroidWidgetSnapshot(
      isAuthenticated: true,
      serverStatus: serverStatus,
      authPaused: effectiveAuthPaused,
      unreadCount: unreadCount,
      pendingSubjectsBadgeCount: pendingSubjectsBadgeCount,
      lastSyncAt: effectiveLastSync,
      lastOnlineSuccessAt:
          lastOnlineSuccessAt ??
          (serverStatus == MielServerStatus.online ? effectiveLastSync : null),
      recentNotifications: widgetNotifications,
      activeSubjects: widgetSubjects,
    );
  }
}
