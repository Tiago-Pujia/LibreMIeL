import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/sync/sync_engine.dart';
import 'package:libremiel/platform/android_background_worker.dart';
import 'package:libremiel/platform/notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('runAndroidBackgroundSyncTask', () {
    late AppDatabase db;
    late MockSyncEngine mockEngine;
    late MockNotificationService mockNotifications;

    Future<MielCredentials?> fakeCreds() async =>
        const MielCredentials(username: '12345678', password: 'secret');

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      mockEngine = MockSyncEngine();
      mockNotifications = MockNotificationService();

      when(
        () => mockNotifications.initialize(
          requestPermissions: any(named: 'requestPermissions'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockNotifications.showBatch(any())).thenAnswer((_) async {});
      when(() => mockNotifications.showMielRecoveredNotification())
          .thenAnswer((_) async {});
    });

    tearDown(() async {
      await db.close();
    });

    test('inicializa notificaciones sin pedir permisos y emite novedades en Ciclo 1', () async {
      final notif = DetectedNotification(
        dedupeKey: 'cont_1',
        idComision: '100',
        subjectName: 'Programación',
        module: MielModuleType.contenidos,
        title: 'Nuevo archivo',
        body: 'Clase 1.pdf',
        targetUrl: 'https://miel.unlam.edu.ar/',
        detectedAt: DateTime(2026, 11, 23, 12, 0),
      );

      when(
        () => mockEngine.runCycle1(
          loadCredentials: any(named: 'loadCredentials'),
        ),
      ).thenAnswer(
        (_) async =>
            SyncRunSummary(cycle: 1, isBaseline: false, notifications: [notif]),
      );

      final ok = await runAndroidBackgroundSyncTask(
        taskName: kAndroidCycle1TaskName,
        database: db,
        notifications: mockNotifications,
        engine: mockEngine,
        loadCredentials: fakeCreds,
      );

      expect(ok, isTrue);
      verify(() => mockNotifications.initialize(requestPermissions: false))
          .called(1);
      verify(() => mockNotifications.showBatch([notif])).called(1);
      verifyNever(() => mockNotifications.showMielRecoveredNotification());
    });

    test(
      'ejecuta runCycle2 cuando la tarea es kAndroidCycle2TaskName',
      () async {
        when(
          () => mockEngine.runCycle2(
            loadCredentials: any(named: 'loadCredentials'),
          ),
        ).thenAnswer(
          (_) async => const SyncRunSummary(
            cycle: 2,
            isBaseline: false,
            notifications: [],
          ),
        );

        final ok = await runAndroidBackgroundSyncTask(
          taskName: kAndroidCycle2TaskName,
          database: db,
          notifications: mockNotifications,
          engine: mockEngine,
          loadCredentials: fakeCreds,
        );

        expect(ok, isTrue);
        verify(
          () => mockEngine.runCycle2(
            loadCredentials: any(named: 'loadCredentials'),
          ),
        ).called(1);
        verifyNever(
          () => mockEngine.runCycle1(
            loadCredentials: any(named: 'loadCredentials'),
          ),
        );
      },
    );

    test('registra caída de MIeL sin disparar reintento fallido y notifica al recuperarse', () async {
      when(
        () => mockEngine.runCycle1(
          loadCredentials: any(named: 'loadCredentials'),
        ),
      ).thenAnswer(
        (_) async => const SyncRunSummary(
          cycle: 1,
          isBaseline: false,
          notifications: [],
          networkErrorStatus: MielServerStatus.mielDown,
        ),
      );

      final downResult = await runAndroidBackgroundSyncTask(
        taskName: kAndroidCycle1TaskName,
        database: db,
        notifications: mockNotifications,
        engine: mockEngine,
        loadCredentials: fakeCreds,
        nowProvider: () => DateTime(2026, 11, 23, 14, 0),
      );

      expect(downResult, isTrue);
      expect(await db.getSetting(SettingKeys.mielOutageDetectedAt), isNotNull);
      verifyNever(() => mockNotifications.showMielRecoveredNotification());

      // Ahora MIeL vuelve a responder en línea
      when(
        () => mockEngine.runCycle1(
          loadCredentials: any(named: 'loadCredentials'),
        ),
      ).thenAnswer(
        (_) async => const SyncRunSummary(
          cycle: 1,
          isBaseline: false,
          notifications: [],
        ),
      );

      final recoveredResult = await runAndroidBackgroundSyncTask(
        taskName: kAndroidCycle1TaskName,
        database: db,
        notifications: mockNotifications,
        engine: mockEngine,
        loadCredentials: fakeCreds,
        nowProvider: () => DateTime(2026, 11, 23, 14, 15),
      );

      expect(recoveredResult, isTrue);
      expect(await db.getSetting(SettingKeys.mielOutageDetectedAt), isNull);
      verify(() => mockNotifications.showMielRecoveredNotification()).called(1);
    });

    test(
      'respeta notifyOnMielRecovery=false y no emite aviso al recuperarse MIeL',
      () async {
        await db.setSetting(SettingKeys.notifyOnMielRecovery, 'false');
        await db.setSetting(
          SettingKeys.mielOutageDetectedAt,
          DateTime(2026, 11, 23, 14, 0).toIso8601String(),
        );

        when(
          () => mockEngine.runCycle1(
            loadCredentials: any(named: 'loadCredentials'),
          ),
        ).thenAnswer(
          (_) async => const SyncRunSummary(
            cycle: 1,
            isBaseline: false,
            notifications: [],
          ),
        );

        final ok = await runAndroidBackgroundSyncTask(
          taskName: kAndroidCycle1TaskName,
          database: db,
          notifications: mockNotifications,
          engine: mockEngine,
          loadCredentials: fakeCreds,
        );

        expect(ok, isTrue);
        expect(await db.getSetting(SettingKeys.mielOutageDetectedAt), isNull);
        verifyNever(() => mockNotifications.showMielRecoveredNotification());
      },
    );
  });
}
