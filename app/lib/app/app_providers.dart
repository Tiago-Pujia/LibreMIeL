import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show Brightness, ThemeMode;

import '../core/models/miel_models.dart';
import '../core/network/miel_client.dart';
import '../core/parsers/miel_parsers.dart';
import '../core/storage/app_database.dart';
import '../core/sync/sync_engine.dart';
import '../platform/android_background_worker.dart';
import '../platform/autostart_service.dart';
import '../platform/desktop_tray_service.dart';
import '../platform/notification_service.dart';
import '../platform/secure_credentials_store.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final credentialsStoreProvider = Provider<SecureCredentialsStore>((ref) {
  return SecureCredentialsStore();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final autostartServiceProvider = Provider<AutostartService>((ref) {
  return AutostartService();
});

final mielClientProvider = FutureProvider<MielApiClient>((ref) async {
  return DioMielClient.createPersistent();
});

class AppSessionState {
  const AppSessionState({
    this.isChecking = true,
    this.isAuthenticated = false,
    this.isSyncing = false,
    this.studentName = '',
    this.authPausedReason,
    this.lastSyncMessage,
    this.lastSyncAt,
    this.syncIntervalMinutes = 15,
    this.forumSyncMode = ForumSyncMode.nonInvasive,
    this.monitorEvaluaciones = true,
    this.themeMode = ThemeMode.system,
    this.globalNovedadesBadge = 0,
    this.launchAtStartup = false,
    this.autostartSupported = false,
  });

  final bool isChecking;
  final bool isAuthenticated;
  final bool isSyncing;
  final String studentName;
  final String? authPausedReason;
  final String? lastSyncMessage;
  final DateTime? lastSyncAt;
  final int syncIntervalMinutes;
  final ForumSyncMode forumSyncMode;
  final bool monitorEvaluaciones;
  final ThemeMode themeMode;
  final int globalNovedadesBadge;
  final bool launchAtStartup;
  final bool autostartSupported;

  AppSessionState copyWith({
    bool? isChecking,
    bool? isAuthenticated,
    bool? isSyncing,
    String? studentName,
    String? authPausedReason,
    bool clearAuthPausedReason = false,
    String? lastSyncMessage,
    DateTime? lastSyncAt,
    int? syncIntervalMinutes,
    ForumSyncMode? forumSyncMode,
    bool? monitorEvaluaciones,
    ThemeMode? themeMode,
    int? globalNovedadesBadge,
    bool? launchAtStartup,
    bool? autostartSupported,
  }) {
    return AppSessionState(
      isChecking: isChecking ?? this.isChecking,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSyncing: isSyncing ?? this.isSyncing,
      studentName: studentName ?? this.studentName,
      authPausedReason: clearAuthPausedReason
          ? null
          : (authPausedReason ?? this.authPausedReason),
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      forumSyncMode: forumSyncMode ?? this.forumSyncMode,
      monitorEvaluaciones: monitorEvaluaciones ?? this.monitorEvaluaciones,
      themeMode: themeMode ?? this.themeMode,
      globalNovedadesBadge: globalNovedadesBadge ?? this.globalNovedadesBadge,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      autostartSupported: autostartSupported ?? this.autostartSupported,
    );
  }
}

class AppSessionController extends Notifier<AppSessionState> {
  Timer? _desktopCycle1Timer;
  Timer? _desktopCycle2Timer;
  DesktopTrayService? _trayService;
  MielCredentials? _memoryCredentials;

  @override
  AppSessionState build() {
    ref.onDispose(() {
      _desktopCycle1Timer?.cancel();
      _desktopCycle2Timer?.cancel();
      _trayService?.dispose();
    });
    Future.microtask(_bootstrap);
    return const AppSessionState();
  }

  ThemeMode _parseThemeMode(String? raw) {
    if (raw == 'light') return ThemeMode.light;
    if (raw == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> _bootstrap() async {
    final db = ref.read(databaseProvider);
    final credsStore = ref.read(credentialsStoreProvider);
    final notifService = ref.read(notificationServiceProvider);
    final autostart = ref.read(autostartServiceProvider);

    await notifService.initialize();

    final interval = await db.getSyncIntervalMinutes();
    final forumMode = await db.getForumSyncMode();
    final monitorEval = await db.getMonitorEvaluaciones();
    final pausedReason = await db.getSetting(SettingKeys.accountPausedReason);
    final studentName = (await db.getSetting(SettingKeys.studentName)) ?? '';
    final themeRaw = await db.getSetting(SettingKeys.themeMode);
    final globalNovRaw = await db.getSetting(SettingKeys.globalNovedadesBadge);
    final lastCycle1Raw = await db.getSetting(SettingKeys.lastCycle1At);
    final lastSyncAt = lastCycle1Raw != null
        ? DateTime.tryParse(lastCycle1Raw)
        : null;
    final autostartSupported = autostart.isSupported;
    final launchAtStartup = autostartSupported
        ? await autostart.isEnabled()
        : false;

    MielCredentials? savedCreds;
    try {
      savedCreds = await credsStore.read();
    } catch (_) {
      savedCreds = null;
    }

    final authenticated = savedCreds != null;
    state = state.copyWith(
      isChecking: false,
      isAuthenticated: authenticated,
      studentName: studentName,
      authPausedReason: pausedReason,
      syncIntervalMinutes: interval,
      forumSyncMode: forumMode,
      monitorEvaluaciones: monitorEval,
      themeMode: _parseThemeMode(themeRaw),
      globalNovedadesBadge: int.tryParse(globalNovRaw ?? '') ?? 0,
      launchAtStartup: launchAtStartup,
      autostartSupported: autostartSupported,
      lastSyncAt: lastSyncAt,
    );

    if (authenticated) {
      await _startBackgroundSchedulers(interval);
    }
  }

  Future<MielCredentials?> _loadActiveCredentials() async {
    if (_memoryCredentials != null) return _memoryCredentials;
    try {
      return await ref.read(credentialsStoreProvider).read();
    } catch (_) {
      return null;
    }
  }

  Future<MielLoginResult> login({
    required String username,
    required String password,
    required bool saveCredentials,
  }) async {
    final client = await ref.read(mielClientProvider.future);
    final db = ref.read(databaseProvider);
    final credsStore = ref.read(credentialsStoreProvider);

    final result = await client.login(
      username,
      password,
      remember: saveCredentials,
    );
    if (!result.isSuccess) {
      return result;
    }

    final creds = MielCredentials(
      username: username.trim(),
      password: password,
    );
    _memoryCredentials = creds;
    if (saveCredentials) {
      await credsStore.save(creds);
    }

    await db.deleteSetting(SettingKeys.accountPausedReason);

    state = state.copyWith(
      isAuthenticated: true,
      clearAuthPausedReason: true,
      lastSyncMessage: 'Sesión iniciada. Sincronizando materias…',
    );

    await _startBackgroundSchedulers(state.syncIntervalMinutes);
    await syncNow(includeCycle2: true, ignoreAuthPause: true);
    return result;
  }

  Future<void> syncNow({
    bool includeCycle2 = false,
    bool ignoreAuthPause = false,
  }) async {
    if (state.isSyncing || !state.isAuthenticated) return;
    state = state.copyWith(isSyncing: true);

    try {
      final client = await ref.read(mielClientProvider.future);
      final db = ref.read(databaseProvider);
      final notifService = ref.read(notificationServiceProvider);
      final engine = SyncEngine(client: client, database: db);

      final summary1 = await engine.runCycle1(
        loadCredentials: _loadActiveCredentials,
        ignoreAuthPause: ignoreAuthPause,
      );

      final allNotifs = <DetectedNotification>[...summary1.notifications];

      if (includeCycle2 && !summary1.authPaused && !summary1.isBaseline) {
        final summary2 = await engine.runCycle2(
          loadCredentials: _loadActiveCredentials,
          ignoreAuthPause: ignoreAuthPause,
        );
        allNotifs.addAll(summary2.notifications);
      }

      if (!summary1.isBaseline && allNotifs.isNotEmpty) {
        await notifService.showBatch(allNotifs);
      }

      final studentName =
          (await db.getSetting(SettingKeys.studentName)) ?? state.studentName;
      final globalNovRaw = await db.getSetting(
        SettingKeys.globalNovedadesBadge,
      );
      final globalNov = int.tryParse(globalNovRaw ?? '') ?? 0;
      final msg = summary1.authPaused
          ? (summary1.authErrorMessage ??
                'Sincronización pausada por error de cuenta.')
          : summary1.isBaseline
          ? 'Estado inicial guardado. A partir de ahora te avisaremos de cada novedad.'
          : allNotifs.isEmpty
          ? 'Sin novedades nuevas.'
          : 'Se detectaron ${allNotifs.length} novedad(es).';

      state = state.copyWith(
        isSyncing: false,
        studentName: studentName,
        globalNovedadesBadge: globalNov,
        authPausedReason: summary1.authPaused
            ? summary1.authErrorMessage
            : null,
        clearAuthPausedReason: !summary1.authPaused,
        lastSyncMessage: msg,
        lastSyncAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastSyncMessage: 'Error durante la sincronización: $e',
      );
    }
  }

  Future<void> updateSyncInterval(int minutes) async {
    final safeMinutes = minutes < 5 ? 5 : minutes;
    final db = ref.read(databaseProvider);
    await db.setSetting(
      SettingKeys.syncIntervalMinutes,
      safeMinutes.toString(),
    );
    state = state.copyWith(syncIntervalMinutes: safeMinutes);
    await _startBackgroundSchedulers(safeMinutes);
  }

  Future<void> updateForumSyncMode(ForumSyncMode mode) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.forumSyncMode, mode.name);
    state = state.copyWith(forumSyncMode: mode);
  }

  Future<void> updateMonitorEvaluaciones(bool enabled) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.monitorEvaluaciones, enabled.toString());
    state = state.copyWith(monitorEvaluaciones: enabled);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.themeMode, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> toggleThemeMode(Brightness currentBrightness) async {
    final nextMode = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await updateThemeMode(nextMode);
  }

  Future<void> updateLaunchAtStartup(bool enabled) async {
    final autostart = ref.read(autostartServiceProvider);
    final actual = await autostart.setEnabled(enabled);
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.launchAtStartup, actual.toString());
    state = state.copyWith(launchAtStartup: actual);
  }

  Future<void> logout({bool wipeLocalData = false}) async {
    _desktopCycle1Timer?.cancel();
    _desktopCycle2Timer?.cancel();
    _memoryCredentials = null;
    await _trayService?.dispose();
    _trayService = null;

    final preservedTheme = state.themeMode;
    final preservedAutostart = state.launchAtStartup;
    final preservedAutostartSupported = state.autostartSupported;
    final client = await ref.read(mielClientProvider.future);
    await client.clearSession();
    await ref.read(credentialsStoreProvider).clear();
    await AndroidBackgroundWorker.cancelAll();

    if (wipeLocalData) {
      await ref.read(databaseProvider).clearAllLocalData();
      await ref
          .read(databaseProvider)
          .setSetting(SettingKeys.themeMode, preservedTheme.name);
    }

    state = AppSessionState(
      isChecking: false,
      isAuthenticated: false,
      themeMode: preservedTheme,
      launchAtStartup: preservedAutostart,
      autostartSupported: preservedAutostartSupported,
    );
  }

  Future<void> _startBackgroundSchedulers(int intervalMinutes) async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      await AndroidBackgroundWorker.initializeAndSchedule(
        intervalMinutes: intervalMinutes,
      );
      return;
    }

    if (DesktopTrayService.isDesktop) {
      _trayService ??= DesktopTrayService(
        onQuit: () async {
          _desktopCycle1Timer?.cancel();
          _desktopCycle2Timer?.cancel();
        },
      );
      await _trayService!.initialize();

      _desktopCycle1Timer?.cancel();
      _desktopCycle2Timer?.cancel();

      _desktopCycle1Timer = Timer.periodic(
        Duration(minutes: intervalMinutes),
        (_) => syncNow(includeCycle2: false),
      );
      _desktopCycle2Timer = Timer.periodic(
        Duration(minutes: intervalMinutes < 30 ? 45 : intervalMinutes * 2),
        (_) => syncNow(includeCycle2: true),
      );
    }
  }
}

final appSessionProvider =
    NotifierProvider<AppSessionController, AppSessionState>(
      AppSessionController.new,
    );

final subjectsStreamProvider = StreamProvider<List<Subject>>((ref) {
  return ref.watch(databaseProvider).watchAllSubjects();
});

final notificationsStreamProvider =
    StreamProvider.family<List<NotificationLog>, String?>((ref, moduleFilter) {
      return ref
          .watch(databaseProvider)
          .watchNotifications(module: moduleFilter);
    });

final subjectNotificationsProvider =
    StreamProvider.family<
      List<NotificationLog>,
      ({String idComision, String? module})
    >((ref, filter) {
      return ref
          .watch(databaseProvider)
          .watchNotifications(
            idComision: filter.idComision,
            module: filter.module,
          );
    });

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).watchUnreadNotificationsCount();
});

final subjectTeachersProvider =
    StreamProvider.family<List<CachedTeacher>, String>((ref, idComision) {
      return ref.watch(databaseProvider).watchTeachersForSubject(idComision);
    });

final subjectSnapshotsProvider =
    StreamProvider.family<
      List<SnapshotEntry>,
      ({String idComision, String module})
    >((ref, key) {
      return ref
          .watch(databaseProvider)
          .watchSnapshotsForSubject(key.idComision, key.module);
    });

/// Consulta en modo solo lectura `GET /principal/cursoDetalles/id/{idComision}` para el modal ⋮.
final courseDetailsProvider = FutureProvider.autoDispose
    .family<CourseDetails?, String>((ref, idComision) async {
      try {
        final client = await ref.read(mielClientProvider.future);
        final html = await client.fetchCursoDetallesHtml(idComision);
        final details = parseCursoDetallesHtml(html, idComision);
        if (details.teachers.isNotEmpty) {
          await ref
              .read(databaseProvider)
              .replaceTeachersForSubject(
                idComision,
                details.teachers,
                DateTime.now(),
              );
        }
        return details;
      } catch (_) {
        return null;
      }
    });
