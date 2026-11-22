import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/network/miel_client.dart';
import '../core/storage/app_database.dart';
import '../core/sync/sync_engine.dart';
import 'notification_service.dart';
import 'secure_credentials_store.dart';

const String kAndroidCycle1TaskName = 'libremiel_cycle1_sync';
const String kAndroidCycle2TaskName = 'libremiel_cycle2_sync';

@pragma('vm:entry-point')
void libremielBackgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    try {
      final client = await DioMielClient.createPersistent();
      final creds = SecureCredentialsStore();
      final notifications = NotificationService();
      await notifications.initialize();

      final engine = SyncEngine(client: client, database: db);
      final summary = task == kAndroidCycle2TaskName
          ? await engine.runCycle2(loadCredentials: creds.read)
          : await engine.runCycle1(loadCredentials: creds.read);

      if (!summary.isBaseline && summary.notifications.isNotEmpty) {
        await notifications.showBatch(summary.notifications);
      }
      return true;
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
  static Future<void> initializeAndSchedule({
    required int intervalMinutes,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    await Workmanager().initialize(libremielBackgroundCallbackDispatcher);
    await schedule(intervalMinutes: intervalMinutes);
  }

  static Future<void> schedule({required int intervalMinutes}) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final safeCycle1 = intervalMinutes < 15 ? 15 : intervalMinutes;
    final safeCycle2 = safeCycle1 < 30 ? 60 : safeCycle1 * 2;

    await Workmanager().registerPeriodicTask(
      kAndroidCycle1TaskName,
      kAndroidCycle1TaskName,
      frequency: Duration(minutes: safeCycle1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );

    await Workmanager().registerPeriodicTask(
      kAndroidCycle2TaskName,
      kAndroidCycle2TaskName,
      frequency: Duration(minutes: safeCycle2),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await Workmanager().cancelAll();
  }
}
