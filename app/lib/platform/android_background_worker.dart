import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/models/miel_models.dart';
import '../core/network/miel_client.dart';
import '../core/storage/app_database.dart';
import '../core/sync/sync_engine.dart';
import 'android_widget_service.dart';
import 'notification_service.dart';
import 'secure_credentials_store.dart';

const String kAndroidCycle1TaskName = 'libremiel_cycle1_sync';
const String kAndroidCycle2TaskName = 'libremiel_cycle2_sync';
const String kAndroidWidgetRefreshTaskName = 'libremiel_widget_refresh';

/// Ejecuta un ciclo de sincronización en segundo plano sin requerir `Activity`.
///
/// Separado del callback de `WorkManager` para permitir pruebas unitarias
/// deterministas de inicialización headless, notificaciones, widgets y recuperación de MIeL.
Future<bool> runAndroidBackgroundSyncTask({
  required String taskName,
  required AppDatabase database,
  required NotificationService notifications,
  required SyncEngine engine,
  required CredentialsLoader loadCredentials,
  AndroidWidgetService? widgetService,
  DateTime Function()? nowProvider,
}) async {
  // Crítico: en el isolate headless de WorkManager no existe Activity, por lo que
  // pedir permisos de notificación lanzaría NullPointerException en Android.
  await notifications.initialize(requestPermissions: false);

  final effectiveNowProvider = nowProvider ?? DateTime.now;
  final effectiveWidgetService = widgetService ?? const AndroidWidgetService();

  SyncRunSummary? summary;
  try {
    summary = taskName == kAndroidCycle2TaskName
        ? await engine.runCycle2(loadCredentials: loadCredentials)
        : await engine.runCycle1(loadCredentials: loadCredentials);

    final now = effectiveNowProvider();

    if (summary.networkErrorStatus == MielServerStatus.mielDown) {
      final existingOutage = await database.getSetting(
        SettingKeys.mielOutageDetectedAt,
      );
      if (existingOutage == null || existingOutage.isEmpty) {
        await database.setSetting(
          SettingKeys.mielOutageDetectedAt,
          now.toIso8601String(),
        );
      }
      // Devolver true evita que WorkManager entre en un bucle agresivo de reintentos
      // contra los servidores de UNLaM mientras MIeL está caído.
      return true;
    }

    if (summary.networkErrorStatus == MielServerStatus.deviceOffline) {
      return true;
    }

    if (!summary.authPaused && summary.warnings.isEmpty) {
      final existingOutage = await database.getSetting(
        SettingKeys.mielOutageDetectedAt,
      );
      if (existingOutage != null && existingOutage.isNotEmpty) {
        await database.deleteSetting(SettingKeys.mielOutageDetectedAt);
        if (await database.getNotifyOnMielRecovery()) {
          await notifications.showMielRecoveredNotification();
        }
      }
    }

    if (!summary.isBaseline && summary.notifications.isNotEmpty) {
      await notifications.showBatch(summary.notifications);
    }

    return true;
  } finally {
    await _syncWidgetAfterBackgroundRun(
      database: database,
      widgetService: effectiveWidgetService,
      loadCredentials: loadCredentials,
      summary: summary,
      now: effectiveNowProvider(),
    );
  }
}

Future<void> _syncWidgetAfterBackgroundRun({
  required AppDatabase database,
  required AndroidWidgetService widgetService,
  required CredentialsLoader loadCredentials,
  required SyncRunSummary? summary,
  required DateTime now,
}) async {
  try {
    final storedUser = await database.getSetting(SettingKeys.accountUsername);
    final creds = await loadCredentials();
    final isAuthenticated =
        (storedUser != null && storedUser.isNotEmpty) ||
        (creds != null && creds.username.isNotEmpty);

    if (!isAuthenticated) {
      await widgetService.clearSnapshot();
      return;
    }

    final MielServerStatus serverStatus;
    if (summary?.networkErrorStatus != null) {
      serverStatus = summary!.networkErrorStatus!;
    } else if (summary == null || summary.warnings.isNotEmpty) {
      final existingOutage = await database.getSetting(
        SettingKeys.mielOutageDetectedAt,
      );
      serverStatus = (existingOutage != null && existingOutage.isNotEmpty)
          ? MielServerStatus.mielDown
          : MielServerStatus.online;
    } else {
      serverStatus = MielServerStatus.online;
    }

    final syncSucceeded =
        summary != null &&
        summary.networkErrorStatus == null &&
        !summary.authPaused &&
        summary.warnings.isEmpty;

    await widgetService.syncFromDatabase(
      database: database,
      isAuthenticated: true,
      serverStatus: serverStatus,
      authPaused: summary?.authPaused,
      lastSyncAt: syncSucceeded ? now : null,
      lastOnlineSuccessAt: syncSucceeded ? now : null,
    );
  } catch (_) {
    // Nunca fallar el Worker por un error de actualización del widget.
  }
}

@pragma('vm:entry-point')
void libremielBackgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    try {
      final client = await DioMielClient.createPersistent();
      final creds = SecureCredentialsStore();
      final notifications = NotificationService();
      final engine = SyncEngine(client: client, database: db);

      return await runAndroidBackgroundSyncTask(
        taskName: task,
        database: db,
        notifications: notifications,
        engine: engine,
        loadCredentials: creds.read,
        widgetService: const AndroidWidgetService(),
      );
    } catch (e, st) {
      debugPrint('[LibreMIeL Background Worker] Error: $e\n$st');
      return false;
    } finally {
      await db.close();
    }
  });
}

/// Configura las tareas periódicas en segundo plano de Android (`WorkManager`).
/// Android impone una frecuencia mínima de 15 minutos respetando Doze Mode.
class AndroidBackgroundWorker {
  static bool _initialized = false;

  /// Inicializa `WorkManager` una única vez por instancia de motor Flutter.
  static Future<void> ensureInitialized() async {
    if (kIsWeb || !Platform.isAndroid || _initialized) return;
    await Workmanager().initialize(libremielBackgroundCallbackDispatcher);
    _initialized = true;
  }

  static Future<void> initializeAndSchedule({
    required int intervalMinutes,
    bool updateExisting = false,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    await ensureInitialized();
    await schedule(
      intervalMinutes: intervalMinutes,
      updateExisting: updateExisting,
    );
  }

  static Future<void> schedule({
    required int intervalMinutes,
    bool updateExisting = false,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final safeCycle1 = intervalMinutes < 15 ? 15 : intervalMinutes;
    final safeCycle2 = safeCycle1 < 30 ? 60 : safeCycle1 * 2;
    final policy = updateExisting
        ? ExistingPeriodicWorkPolicy.update
        : ExistingPeriodicWorkPolicy.keep;

    await Workmanager().registerPeriodicTask(
      kAndroidCycle1TaskName,
      kAndroidCycle1TaskName,
      frequency: Duration(minutes: safeCycle1),
      existingWorkPolicy: policy,
      constraints: Constraints(networkType: NetworkType.connected),
    );

    await Workmanager().registerPeriodicTask(
      kAndroidCycle2TaskName,
      kAndroidCycle2TaskName,
      frequency: Duration(minutes: safeCycle2),
      existingWorkPolicy: policy,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await Workmanager().cancelAll();
  }
}
