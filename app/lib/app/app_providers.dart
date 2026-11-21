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
import '../platform/file_download_service.dart';
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

final fileDownloadServiceProvider = Provider<FileDownloadService>((ref) {
  return const FileDownloadService();
});

final mielClientProvider = FutureProvider<MielApiClient>((ref) async {
  return DioMielClient.createPersistent();
});

final mielInteractiveReaderProvider = FutureProvider<MielInteractiveReader>((
  ref,
) async {
  final client = await ref.watch(mielClientProvider.future);
  if (client is MielInteractiveReader) {
    return client;
  }
  return DioMielClient.createPersistent();
});

final mielWriterProvider = FutureProvider<MielWriter>((ref) async {
  final client = await ref.watch(mielClientProvider.future);
  if (client is MielWriter) {
    return client as MielWriter;
  }
  return await DioMielClient.createPersistent();
});

class SessionGenerationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Contador monotónico que se incrementa en cada login/logout para invalidar
/// cachés en memoria (por ejemplo, avatares e imágenes autenticadas) sin efectos secundarios.
final sessionGenerationProvider =
    NotifierProvider<SessionGenerationNotifier, int>(
      SessionGenerationNotifier.new,
    );

class AppSessionState {
  const AppSessionState({
    this.isChecking = true,
    this.isAuthenticated = false,
    this.isSyncing = false,
    this.studentName = '',
    this.studentAvatarUrl = '',
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
  final String studentAvatarUrl;
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
    String? studentAvatarUrl,
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
      studentAvatarUrl: studentAvatarUrl ?? this.studentAvatarUrl,
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
  Timer? _desktopKeepAliveTimer;
  StreamSubscription<int>? _trayUnreadSub;
  DesktopTrayService? _trayService;
  MielCredentials? _memoryCredentials;
  Future<bool>? _reloginInFlight;
  int _sessionGeneration = 0;

  @override
  AppSessionState build() {
    ref.onDispose(() {
      _desktopCycle1Timer?.cancel();
      _desktopCycle2Timer?.cancel();
      _desktopKeepAliveTimer?.cancel();
      _trayUnreadSub?.cancel();
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
    final themeRaw = await db.getSetting(SettingKeys.themeMode);
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
    if (authenticated) {
      _memoryCredentials = savedCreds;
      final currentUser = savedCreds.username.trim().toLowerCase();
      final storedUser = await db.getSetting(SettingKeys.accountUsername);
      if (storedUser == null || storedUser.isEmpty) {
        await db.setSetting(SettingKeys.accountUsername, currentUser);
      } else if (storedUser != currentUser) {
        await db.clearAccountData();
        await db.setSetting(SettingKeys.accountUsername, currentUser);
      }
    }

    final pausedReason = await db.getSetting(SettingKeys.accountPausedReason);
    final studentName = (await db.getSetting(SettingKeys.studentName)) ?? '';
    final studentAvatarUrl =
        (await db.getSetting(SettingKeys.studentAvatarUrl)) ?? '';
    final globalNovRaw = await db.getSetting(SettingKeys.globalNovedadesBadge);
    final lastCycle1Raw = await db.getSetting(SettingKeys.lastCycle1At);
    final lastSyncAt = lastCycle1Raw != null
        ? DateTime.tryParse(lastCycle1Raw)
        : null;

    state = state.copyWith(
      isChecking: false,
      isAuthenticated: authenticated,
      studentName: studentName,
      studentAvatarUrl: studentAvatarUrl,
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
      if (pausedReason == null || pausedReason.isEmpty) {
        unawaited(syncNow(includeCycle2: false));
      }
    }
  }

  Future<MielCredentials?> loadActiveCredentials() async {
    if (_memoryCredentials != null) return _memoryCredentials;
    try {
      final creds = await ref.read(credentialsStoreProvider).read();
      _memoryCredentials = creds;
      return creds;
    } catch (_) {
      return null;
    }
  }

  /// Garantiza una sesión HTTP activa con MIeL re-autenticando silenciosamente
  /// con las credenciales locales persistidas (Fase 5 — Sesión Permanente).
  ///
  /// - Serializa llamadas concurrentes para evitar múltiples POST de login.
  /// - Respeta la invariante anti-bloqueo (`estado: 1, 2 o 3`): si la clave cambió
  ///   o la cuenta está bloqueada, pausa la reconexión automática sin borrar datos.
  Future<bool> ensureActiveSession({bool forceRelogin = false}) async {
    if (!state.isAuthenticated) return false;
    final inFlight = _reloginInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _doEnsureActiveSession(forceRelogin: forceRelogin);
    _reloginInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_reloginInFlight, future)) {
        _reloginInFlight = null;
      }
    }
  }

  Future<bool> _doEnsureActiveSession({required bool forceRelogin}) async {
    final gen = _sessionGeneration;
    final db = ref.read(databaseProvider);
    final pausedReason = await db.getSetting(SettingKeys.accountPausedReason);
    if (pausedReason != null && pausedReason.isNotEmpty) {
      return false;
    }

    final client = await ref.read(mielClientProvider.future);
    if (!forceRelogin) {
      try {
        if (await client.isLogged()) {
          return true;
        }
      } catch (_) {}
    }

    final creds = await loadActiveCredentials();
    if (creds == null || gen != _sessionGeneration) {
      return false;
    }

    final loginRes = await client.login(
      creds.username,
      creds.password,
      remember: true,
    );
    if (gen != _sessionGeneration) return false;

    if (loginRes.isSuccess) {
      await db.deleteSetting(SettingKeys.accountPausedReason);
      if (state.authPausedReason != null) {
        state = state.copyWith(clearAuthPausedReason: true);
      }
      return true;
    }

    if (loginRes.status == MielAuthStatus.invalidCredentials ||
        loginRes.status == MielAuthStatus.accountBlocked) {
      final msg =
          loginRes.message ??
          'Error de autenticación en MIeL (código ${loginRes.rawCode}).';
      await db.setSetting(SettingKeys.accountPausedReason, msg);
      state = state.copyWith(authPausedReason: msg);
    }
    return false;
  }

  Future<void> _keepSessionAlive() async {
    if (!state.isAuthenticated || state.authPausedReason != null) return;
    try {
      final client = await ref.read(mielClientProvider.future);
      if (await client.isLogged()) {
        await client.refreshSession();
      } else {
        await ensureActiveSession(forceRelogin: true);
      }
    } catch (_) {
      // Error de red transitorio: nunca desloguear; se reintentará en el próximo ciclo.
    }
  }

  Future<MielLoginResult> login({
    required String username,
    required String password,
    bool saveCredentials = true,
  }) async {
    final client = await ref.read(mielClientProvider.future);
    final db = ref.read(databaseProvider);
    final credsStore = ref.read(credentialsStoreProvider);

    final result = await client.login(username, password, remember: true);
    if (!result.isSuccess) {
      return result;
    }

    final normalizedUser = username.trim().toLowerCase();
    final previousUser = await db.getSetting(SettingKeys.accountUsername);
    final isDifferentAccount =
        previousUser == null || previousUser != normalizedUser;
    if (isDifferentAccount) {
      await db.clearAccountData();
    }
    await db.setSetting(SettingKeys.accountUsername, normalizedUser);

    final creds = MielCredentials(
      username: username.trim(),
      password: password,
    );
    _memoryCredentials = creds;
    if (saveCredentials) {
      await credsStore.save(creds);
    } else {
      await credsStore.clear();
    }

    await db.deleteSetting(SettingKeys.accountPausedReason);

    final restoredName = isDifferentAccount
        ? ''
        : ((await db.getSetting(SettingKeys.studentName)) ?? '');
    final restoredAvatar = isDifferentAccount
        ? ''
        : ((await db.getSetting(SettingKeys.studentAvatarUrl)) ?? '');

    _sessionGeneration++;
    ref.read(sessionGenerationProvider.notifier).bump();
    state = AppSessionState(
      isChecking: false,
      isAuthenticated: true,
      isSyncing: false,
      studentName: restoredName,
      studentAvatarUrl: restoredAvatar,
      authPausedReason: null,
      lastSyncMessage: 'Sesión iniciada. Sincronizando materias…',
      lastSyncAt: isDifferentAccount ? null : state.lastSyncAt,
      syncIntervalMinutes: state.syncIntervalMinutes,
      forumSyncMode: state.forumSyncMode,
      monitorEvaluaciones: state.monitorEvaluaciones,
      themeMode: state.themeMode,
      globalNovedadesBadge: isDifferentAccount ? 0 : state.globalNovedadesBadge,
      launchAtStartup: state.launchAtStartup,
      autostartSupported: state.autostartSupported,
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
    final gen = _sessionGeneration;
    bool isCancelled() => gen != _sessionGeneration;
    state = state.copyWith(isSyncing: true);

    try {
      final client = await ref.read(mielClientProvider.future);
      final db = ref.read(databaseProvider);
      final notifService = ref.read(notificationServiceProvider);
      final engine = SyncEngine(client: client, database: db);

      final summary1 = await engine.runCycle1(
        loadCredentials: loadActiveCredentials,
        ignoreAuthPause: ignoreAuthPause,
        isCancelled: isCancelled,
      );
      if (isCancelled()) return;

      final allNotifs = <DetectedNotification>[...summary1.notifications];

      if (includeCycle2 && !summary1.authPaused && !summary1.isBaseline) {
        final summary2 = await engine.runCycle2(
          loadCredentials: loadActiveCredentials,
          ignoreAuthPause: ignoreAuthPause,
          isCancelled: isCancelled,
        );
        if (isCancelled()) return;
        allNotifs.addAll(summary2.notifications);
      }

      if (!summary1.isBaseline && allNotifs.isNotEmpty) {
        await notifService.showBatch(allNotifs);
      }
      if (isCancelled()) return;

      final studentName =
          (await db.getSetting(SettingKeys.studentName)) ?? state.studentName;
      final studentAvatarUrl =
          (await db.getSetting(SettingKeys.studentAvatarUrl)) ?? '';
      final globalNovRaw = await db.getSetting(
        SettingKeys.globalNovedadesBadge,
      );
      final globalNov = int.tryParse(globalNovRaw ?? '') ?? 0;
      if (isCancelled()) return;

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
        studentAvatarUrl: studentAvatarUrl,
        globalNovedadesBadge: globalNov,
        authPausedReason: summary1.authPaused
            ? summary1.authErrorMessage
            : null,
        clearAuthPausedReason: !summary1.authPaused,
        lastSyncMessage: msg,
        lastSyncAt: DateTime.now(),
      );
    } catch (e) {
      if (isCancelled()) return;
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
    _sessionGeneration++;
    ref.read(sessionGenerationProvider.notifier).bump();
    _desktopCycle1Timer?.cancel();
    _desktopCycle2Timer?.cancel();
    _desktopKeepAliveTimer?.cancel();
    final db = ref.read(databaseProvider);
    final credsStore = ref.read(credentialsStoreProvider);

    if (!wipeLocalData) {
      final existingOwner = await db.getSetting(SettingKeys.accountUsername);
      if (existingOwner == null || existingOwner.isEmpty) {
        final activeCreds = await loadActiveCredentials();
        if (activeCreds != null && activeCreds.username.trim().isNotEmpty) {
          await db.setSetting(
            SettingKeys.accountUsername,
            activeCreds.username.trim().toLowerCase(),
          );
        }
      }
    }

    _memoryCredentials = null;
    await _trayUnreadSub?.cancel();
    _trayUnreadSub = null;
    await _trayService?.dispose();
    _trayService = null;

    final preservedTheme = state.themeMode;
    final preservedAutostart = state.launchAtStartup;
    final preservedAutostartSupported = state.autostartSupported;
    final client = await ref.read(mielClientProvider.future);
    await client.clearSession();
    await credsStore.clear();
    await AndroidBackgroundWorker.cancelAll();

    if (wipeLocalData) {
      await db.clearAllLocalData();
      await db.setSetting(SettingKeys.themeMode, preservedTheme.name);
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
          _desktopKeepAliveTimer?.cancel();
          await _trayUnreadSub?.cancel();
          _trayUnreadSub = null;
        },
      );
      await _trayService!.initialize();

      await _trayUnreadSub?.cancel();
      final db = ref.read(databaseProvider);
      _trayUnreadSub = db.watchUnreadNotificationsCount().listen((unreadCount) {
        unawaited(_trayService?.setUnreadCount(unreadCount));
      });

      _desktopCycle1Timer?.cancel();
      _desktopCycle2Timer?.cancel();
      _desktopKeepAliveTimer?.cancel();

      _desktopCycle1Timer = Timer.periodic(
        Duration(minutes: intervalMinutes),
        (_) => syncNow(includeCycle2: false),
      );
      _desktopCycle2Timer = Timer.periodic(
        Duration(minutes: intervalMinutes < 30 ? 45 : intervalMinutes * 2),
        (_) => syncNow(includeCycle2: true),
      );
      _desktopKeepAliveTimer = Timer.periodic(
        const Duration(minutes: 20),
        (_) => unawaited(_keepSessionAlive()),
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
