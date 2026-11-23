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
import '../platform/android_system_service.dart';
import '../platform/autostart_service.dart';
import '../platform/desktop_tray_service.dart';
import '../platform/file_download_service.dart';
import '../platform/notification_service.dart';
import '../platform/secure_credentials_store.dart';
import '../core/network/miel_server_status_classifier.dart';
import '../core/storage/offline_media_service.dart';
import '../core/sync/offline_prefetcher.dart';
import '../core/theme/miel_theme.dart';
import '../platform/updater/updater_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final offlineMediaServiceProvider = Provider<OfflineMediaService>((ref) {
  return const OfflineMediaService();
});

final offlinePrefetcherProvider = FutureProvider<OfflinePrefetcher>((
  ref,
) async {
  final reader = await ref.watch(mielInteractiveReaderProvider.future);
  final db = ref.watch(databaseProvider);
  return OfflinePrefetcher(client: reader, database: db);
});

final credentialsStoreProvider = Provider<SecureCredentialsStore>((ref) {
  return SecureCredentialsStore();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final androidSystemServiceProvider = Provider<AndroidSystemService>((ref) {
  return const AndroidSystemService();
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
    this.forumSyncMode = ForumSyncMode.mentionsAndReplies,
    this.monitorEvaluaciones = true,
    this.themeMode = ThemeMode.system,
    this.globalNovedadesBadge = 0,
    this.launchAtStartup = false,
    this.autostartSupported = false,
    this.serverStatus = MielServerStatus.online,
    this.serverDownSince,
    this.lastOnlineSuccessAt,
    this.offlineModeEnabled = false,
    this.offlineCacheMaxMb = 100,
    this.offlinePrefetchSafeModules = false,
    this.notifyOnMielRecovery = true,
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
  final MielServerStatus serverStatus;
  final DateTime? serverDownSince;
  final DateTime? lastOnlineSuccessAt;
  final bool offlineModeEnabled;
  final int offlineCacheMaxMb;
  final bool offlinePrefetchSafeModules;
  final bool notifyOnMielRecovery;

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
    MielServerStatus? serverStatus,
    DateTime? serverDownSince,
    bool clearServerDownSince = false,
    DateTime? lastOnlineSuccessAt,
    bool? offlineModeEnabled,
    int? offlineCacheMaxMb,
    bool? offlinePrefetchSafeModules,
    bool? notifyOnMielRecovery,
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
      serverStatus: serverStatus ?? this.serverStatus,
      serverDownSince: clearServerDownSince
          ? null
          : (serverDownSince ?? this.serverDownSince),
      lastOnlineSuccessAt: lastOnlineSuccessAt ?? this.lastOnlineSuccessAt,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      offlineCacheMaxMb: offlineCacheMaxMb ?? this.offlineCacheMaxMb,
      offlinePrefetchSafeModules:
          offlinePrefetchSafeModules ?? this.offlinePrefetchSafeModules,
      notifyOnMielRecovery: notifyOnMielRecovery ?? this.notifyOnMielRecovery,
    );
  }
}

class AppSessionController extends Notifier<AppSessionState> {
  Timer? _desktopCycle1Timer;
  Timer? _desktopCycle2Timer;
  Timer? _desktopKeepAliveTimer;
  Timer? _recoveryBackoffTimer;
  int _recoveryBackoffAttempt = 0;
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
      _recoveryBackoffTimer?.cancel();
      _trayUnreadSub?.cancel();
      _trayService?.dispose();
    });
    Future.microtask(_bootstrap);
    return const AppSessionState();
  }

  /// Libera timers y bandeja del sistema antes de salir para aplicar una actualización.
  Future<void> prepareForAppExit() async {
    _desktopCycle1Timer?.cancel();
    _desktopCycle2Timer?.cancel();
    _desktopKeepAliveTimer?.cancel();
    _recoveryBackoffTimer?.cancel();
    await _trayUnreadSub?.cancel();
    _trayUnreadSub = null;
    await _trayService?.dispose();
    _trayService = null;
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

    try {
      await notifService.initialize();
    } catch (_) {}

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
        await ref.read(offlineMediaServiceProvider).clearAllCachedMedia();
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
    final offlineModeEnabled = await db.getOfflineModeEnabled();
    final offlineCacheMaxMb = await db.getOfflineCacheMaxMb();
    final offlinePrefetch = await db.getOfflinePrefetchSafeModules();
    final notifyOnMielRecovery = await db.getNotifyOnMielRecovery();

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
      lastOnlineSuccessAt: lastSyncAt,
      offlineModeEnabled: offlineModeEnabled,
      offlineCacheMaxMb: offlineCacheMaxMb,
      offlinePrefetchSafeModules: offlinePrefetch,
      notifyOnMielRecovery: notifyOnMielRecovery,
    );

    if (authenticated) {
      await _startBackgroundSchedulers(interval);
      if (pausedReason == null || pausedReason.isEmpty) {
        unawaited(syncNow(includeCycle2: false));
      }
    }

    // Comprobar actualizaciones de la app en segundo plano (respetando frecuencia de 24h)
    unawaited(
      ref.read(updaterProvider.notifier).checkForUpdates(manual: false),
    );
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
          reportServerStatus(MielServerStatus.online);
          return true;
        }
      } catch (e) {
        reportServerStatus(classifyMielNetworkError(e));
      }
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
      reportServerStatus(MielServerStatus.online);
      await db.deleteSetting(SettingKeys.accountPausedReason);
      if (state.authPausedReason != null) {
        state = state.copyWith(clearAuthPausedReason: true);
      }
      return true;
    }

    if (loginRes.status == MielAuthStatus.networkError) {
      reportServerStatus(
        loginRes.networkErrorStatus ?? MielServerStatus.mielDown,
      );
      return false;
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
        reportServerStatus(MielServerStatus.online);
      } else {
        await ensureActiveSession(forceRelogin: true);
      }
    } catch (e) {
      // Error de red transitorio: nunca desloguear; reportar estado y reintentar con backoff.
      reportServerStatus(classifyMielNetworkError(e));
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
      await ref.read(offlineMediaServiceProvider).clearAllCachedMedia();
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
    final offlineModeEnabled = await db.getOfflineModeEnabled();
    final offlineCacheMaxMb = await db.getOfflineCacheMaxMb();
    final offlinePrefetch = await db.getOfflinePrefetchSafeModules();
    final notifyOnMielRecovery = await db.getNotifyOnMielRecovery();

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
      lastOnlineSuccessAt: DateTime.now(),
      syncIntervalMinutes: state.syncIntervalMinutes,
      forumSyncMode: state.forumSyncMode,
      monitorEvaluaciones: state.monitorEvaluaciones,
      themeMode: state.themeMode,
      globalNovedadesBadge: isDifferentAccount ? 0 : state.globalNovedadesBadge,
      launchAtStartup: state.launchAtStartup,
      autostartSupported: state.autostartSupported,
      offlineModeEnabled: offlineModeEnabled,
      offlineCacheMaxMb: offlineCacheMaxMb,
      offlinePrefetchSafeModules: offlinePrefetch,
      notifyOnMielRecovery: notifyOnMielRecovery,
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

      // Si Ciclo 1 falló por caída de MIeL o falta de internet, NO marcar online
      if (summary1.networkErrorStatus != null) {
        final netStatus = summary1.networkErrorStatus!;
        state = state.copyWith(
          isSyncing: false,
          lastSyncMessage: summary1.warnings.isNotEmpty
              ? summary1.warnings.first
              : (netStatus == MielServerStatus.deviceOffline
                    ? 'Sin conexión a internet.'
                    : 'Los servidores de MIeL no responden.'),
        );
        reportServerStatus(netStatus);
        return;
      }

      // Si la sincronización fue pausada por estado 1/2/3, conservar estado de red real
      if (summary1.authPaused) {
        if (!summary1.isBaseline && summary1.notifications.isNotEmpty) {
          await notifService.showBatch(summary1.notifications);
        }
        if (isCancelled()) return;
        state = state.copyWith(
          isSyncing: false,
          authPausedReason: summary1.authErrorMessage,
          lastSyncMessage:
              summary1.authErrorMessage ??
              'Sincronización pausada por error de cuenta.',
        );
        return;
      }

      // Si /principal/interno/ devolvió HTML inválido sin materias ni error de auth
      if (summary1.warnings.isNotEmpty) {
        state = state.copyWith(
          isSyncing: false,
          lastSyncMessage: summary1.warnings.first,
        );
        return;
      }

      final allNotifs = <DetectedNotification>[...summary1.notifications];

      if (includeCycle2 && !summary1.isBaseline) {
        final summary2 = await engine.runCycle2(
          loadCredentials: loadActiveCredentials,
          ignoreAuthPause: ignoreAuthPause,
          isCancelled: isCancelled,
        );
        if (isCancelled()) return;
        if (summary2.networkErrorStatus != null) {
          state = state.copyWith(
            isSyncing: false,
            lastSyncMessage: summary2.warnings.isNotEmpty
                ? summary2.warnings.first
                : 'Error de red durante Ciclo 2.',
          );
          reportServerStatus(summary2.networkErrorStatus!);
          return;
        }
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

      final msg = summary1.isBaseline
          ? 'Estado inicial guardado. A partir de ahora te avisaremos de cada novedad.'
          : allNotifs.isEmpty
          ? 'Sin actividades nuevas.'
          : 'Se detectaron ${allNotifs.length} actividad(es) nueva(s).';

      await db.deleteSetting(SettingKeys.mielOutageDetectedAt);
      reportServerStatus(MielServerStatus.online);

      final now = DateTime.now();
      state = state.copyWith(
        isSyncing: false,
        studentName: studentName,
        studentAvatarUrl: studentAvatarUrl,
        globalNovedadesBadge: globalNov,
        clearAuthPausedReason: true,
        lastSyncMessage: msg,
        lastSyncAt: now,
        lastOnlineSuccessAt: now,
        clearServerDownSince: true,
      );

      // Precarga segura de solo lectura si está habilitada por el usuario
      // (SyncEngine ya guardó principal:interno y los módulos que consultó)
      if (state.offlineModeEnabled && state.offlinePrefetchSafeModules) {
        try {
          final prefetcher = await ref.read(offlinePrefetcherProvider.future);
          final activeSubjects = await db.getAllSubjects();
          await prefetcher.prefetchSafeModules(
            activeSubjects: activeSubjects
                .where((s) => !s.isEffectivelyHidden)
                .toList(),
            isCancelled: isCancelled,
            maxCacheMb: state.offlineCacheMaxMb,
            skipInterno: true,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (isCancelled()) return;
      final status = classifyMielNetworkError(e);
      state = state.copyWith(
        isSyncing: false,
        lastSyncMessage: 'Error durante la sincronización: $e',
      );
      reportServerStatus(status);
    }
  }

  void reportServerStatus(MielServerStatus status) {
    final previous = state.serverStatus;
    final now = DateTime.now();

    if (status == MielServerStatus.online) {
      _recoveryBackoffTimer?.cancel();
      _recoveryBackoffTimer = null;
      _recoveryBackoffAttempt = 0;

      final recoveredFromOutage = previous == MielServerStatus.mielDown;
      if (previous != status || state.serverDownSince != null) {
        state = state.copyWith(
          serverStatus: MielServerStatus.online,
          clearServerDownSince: true,
          lastOnlineSuccessAt: now,
        );
      }

      if (recoveredFromOutage && state.isAuthenticated) {
        unawaited(
          ref
              .read(databaseProvider)
              .deleteSetting(SettingKeys.mielOutageDetectedAt)
              .catchError((_) {}),
        );
      }

      if (recoveredFromOutage &&
          state.isAuthenticated &&
          state.notifyOnMielRecovery) {
        unawaited(
          ref.read(notificationServiceProvider).showMielRecoveredNotification(),
        );
      }
      return;
    }

    if (status == MielServerStatus.mielDown &&
        previous != MielServerStatus.mielDown &&
        state.isAuthenticated) {
      unawaited(
        ref
            .read(databaseProvider)
            .setSetting(
              SettingKeys.mielOutageDetectedAt,
              (state.serverDownSince ?? now).toIso8601String(),
            )
            .catchError((_) {}),
      );
    }

    if (previous != status) {
      state = state.copyWith(
        serverStatus: status,
        serverDownSince: state.serverDownSince ?? now,
      );
    }

    if (state.isAuthenticated && state.authPausedReason == null) {
      _scheduleRecoveryBackoff();
    }
  }

  void _scheduleRecoveryBackoff() {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (_recoveryBackoffTimer?.isActive == true) return;

    const backoffMinutes = <int>[1, 2, 5, 10];
    final idx = _recoveryBackoffAttempt < backoffMinutes.length
        ? _recoveryBackoffAttempt
        : backoffMinutes.length - 1;
    final cappedMinutes = backoffMinutes[idx] > state.syncIntervalMinutes
        ? state.syncIntervalMinutes
        : backoffMinutes[idx];
    _recoveryBackoffAttempt++;

    _recoveryBackoffTimer = Timer(Duration(minutes: cappedMinutes), () {
      _recoveryBackoffTimer = null;
      if (!state.isAuthenticated ||
          state.serverStatus == MielServerStatus.online ||
          state.authPausedReason != null) {
        return;
      }
      unawaited(syncNow(includeCycle2: false));
    });
  }

  Future<void> updateOfflineModeEnabled(bool enabled) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(
      SettingKeys.offlineModeEnabled,
      enabled ? 'true' : 'false',
    );
    if (!enabled) {
      await db.clearOfflineCache();
      await ref.read(offlineMediaServiceProvider).clearAllCachedMedia();
    }
    state = state.copyWith(offlineModeEnabled: enabled);
  }

  Future<void> updateOfflinePrefetchSafeModules(bool enabled) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(
      SettingKeys.offlinePrefetchSafeModules,
      enabled ? 'true' : 'false',
    );
    state = state.copyWith(offlinePrefetchSafeModules: enabled);
  }

  Future<void> updateOfflineCacheMaxMb(int maxMb) async {
    final safeMb = maxMb < 10 ? 10 : maxMb;
    final db = ref.read(databaseProvider);
    final mediaService = ref.read(offlineMediaServiceProvider);
    await db.setSetting(SettingKeys.offlineCacheMaxMb, safeMb.toString());

    final totalMaxBytes = safeMb * 1024 * 1024;
    await mediaService.pruneToMaxBytes((totalMaxBytes * 0.6).round());
    final mediaBytes = await mediaService.getTotalCachedMediaBytes();
    await db.pruneOfflineCacheToQuota(
      maxCacheMb: safeMb,
      reservedBytes: mediaBytes,
    );
    state = state.copyWith(offlineCacheMaxMb: safeMb);
  }

  Future<void> updateNotifyOnMielRecovery(bool enabled) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(
      SettingKeys.notifyOnMielRecovery,
      enabled ? 'true' : 'false',
    );
    state = state.copyWith(notifyOnMielRecovery: enabled);
  }

  Future<void> clearOfflineCache() async {
    final db = ref.read(databaseProvider);
    await db.clearOfflineCache();
    await ref.read(offlineMediaServiceProvider).clearAllCachedMedia();
  }

  Future<void> retryConnection() async {
    await syncNow(includeCycle2: true, ignoreAuthPause: false);
  }

  Future<void> updateSyncInterval(int minutes) async {
    final safeMinutes = minutes < 5 ? 5 : minutes;
    final db = ref.read(databaseProvider);
    await db.setSetting(
      SettingKeys.syncIntervalMinutes,
      safeMinutes.toString(),
    );
    state = state.copyWith(syncIntervalMinutes: safeMinutes);
    await _startBackgroundSchedulers(safeMinutes, intervalChanged: true);
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
    _recoveryBackoffTimer?.cancel();
    _recoveryBackoffTimer = null;
    _recoveryBackoffAttempt = 0;
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
    final preservedOfflineEnabled = state.offlineModeEnabled;
    final preservedOfflineMaxMb = state.offlineCacheMaxMb;
    final preservedOfflinePrefetch = state.offlinePrefetchSafeModules;
    final preservedNotifyRecovery = state.notifyOnMielRecovery;

    final client = await ref.read(mielClientProvider.future);
    await client.clearSession();
    await credsStore.clear();
    await AndroidBackgroundWorker.cancelAll();
    await db.deleteSetting(SettingKeys.mielOutageDetectedAt);

    // Invariante #11: al cerrar sesión SIEMPRE se vacía el caché offline y media autenticada
    await db.clearOfflineCache();
    await ref.read(offlineMediaServiceProvider).clearAllCachedMedia();

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
      offlineModeEnabled: wipeLocalData ? false : preservedOfflineEnabled,
      offlineCacheMaxMb: wipeLocalData ? 100 : preservedOfflineMaxMb,
      offlinePrefetchSafeModules: wipeLocalData
          ? false
          : preservedOfflinePrefetch,
      notifyOnMielRecovery: wipeLocalData ? true : preservedNotifyRecovery,
    );
  }

  Future<void> _startBackgroundSchedulers(
    int intervalMinutes, {
    bool intervalChanged = false,
  }) async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      await AndroidBackgroundWorker.initializeAndSchedule(
        intervalMinutes: intervalMinutes,
        updateExisting: intervalChanged,
      );
      return;
    }

    if (DesktopTrayService.isDesktop) {
      _trayService ??= DesktopTrayService(
        onQuit: () async {
          _desktopCycle1Timer?.cancel();
          _desktopCycle2Timer?.cancel();
          _desktopKeepAliveTimer?.cancel();
          _recoveryBackoffTimer?.cancel();
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

/// Consulta en modo solo lectura `GET /principal/cursoDetalles/id/{idComision}` para el modal ⋮,
/// con respaldo automático en `OfflinePageCache` cuando MIeL no responde (Fase 9).
final courseDetailsProvider = FutureProvider.autoDispose
    .family<CourseDetails?, String>((ref, idComision) async {
      final db = ref.read(databaseProvider);
      var offlineEnabled = false;
      var isAuthenticated = false;
      var maxCacheMb = 100;
      try {
        final session = ref.read(appSessionProvider);
        offlineEnabled = session.offlineModeEnabled;
        isAuthenticated = session.isAuthenticated;
        maxCacheMb = session.offlineCacheMaxMb;
      } catch (_) {}

      final cacheKey = 'cursoDetalles:$idComision';

      try {
        final client = await ref.read(mielClientProvider.future);
        final html = await client.fetchCursoDetallesHtml(idComision);
        if (isLikelyLoginRedirectHtml(html) ||
            isLikelyMielMaintenanceHtml(html)) {
          throw const HttpException(
            'MIeL no devolvió los detalles de la comisión.',
          );
        }

        if (offlineEnabled && isAuthenticated && html.isNotEmpty) {
          unawaited(
            db.putOfflinePage(
              cacheKey: cacheKey,
              idComision: idComision,
              module: 'docentes',
              htmlContent: html,
              maxCacheMb: maxCacheMb,
            ),
          );
        }

        final details = parseCursoDetallesHtml(html, idComision);
        if (details.teachers.isNotEmpty) {
          await db.replaceTeachersForSubject(
            idComision,
            details.teachers,
            DateTime.now(),
          );
        }
        return details;
      } catch (_) {
        if (offlineEnabled && isAuthenticated) {
          final cached = await db.getOfflinePage(cacheKey);
          if (cached != null && cached.htmlContent.isNotEmpty) {
            return parseCursoDetallesHtml(cached.htmlContent, idComision);
          }
        }
        return null;
      }
    });
