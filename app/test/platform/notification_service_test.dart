import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/platform/notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(const AndroidNotificationChannel('test', 'test'));
  });

  group('deterministicNotificationId', () {
    test('genera IDs positivos deterministas y distintos por clave', () {
      final a1 = deterministicNotificationId('msg_11193534');
      final a2 = deterministicNotificationId('msg_11193534');
      final b = deterministicNotificationId('msg_11193535');

      expect(a1, equals(a2));
      expect(a1, greaterThan(0));
      expect(a1, lessThanOrEqualTo(0x7fffffff));
      expect(a1, isNot(equals(b)));
    });
  });

  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late MockAndroidNotificationsPlugin mockAndroidPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      mockAndroidPlugin = MockAndroidNotificationsPlugin();
      service = NotificationService(
        plugin: mockPlugin,
        isAndroidOverride: true,
      );
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroidPlugin);
      when(() => mockAndroidPlugin.requestNotificationsPermission())
          .thenAnswer((_) async => true);
      when(() => mockAndroidPlugin.createNotificationChannel(any()))
          .thenAnswer((_) async {});
      when(() => mockAndroidPlugin.areNotificationsEnabled())
          .thenAnswer((_) async => true);
      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
    });

    test('initialize(requestPermissions: false) no solicita permiso sin Activity y crea ambos canales con ícono monocromático', () async {
      await service.initialize(requestPermissions: false);

      final initCaptured = verify(
        () => mockPlugin.initialize(
          settings: captureAny(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).captured;
      final initSettings = initCaptured.single as InitializationSettings;
      expect(
        initSettings.android?.defaultIcon,
        equals(NotificationService.androidSmallIcon),
      );

      verifyNever(() => mockAndroidPlugin.requestNotificationsPermission());

      final channels = verify(
        () => mockAndroidPlugin.createNotificationChannel(captureAny()),
      ).captured.cast<AndroidNotificationChannel>();
      expect(channels.length, equals(2));
      expect(
        channels.map((c) => c.id),
        containsAll([
          NotificationService.androidUpdatesChannelId,
          NotificationService.androidSystemChannelId,
        ]),
      );
    });

    test('initialize(requestPermissions: true) continúa creando canales aunque requestNotificationsPermission lance error', () async {
      when(() => mockAndroidPlugin.requestNotificationsPermission()).thenThrow(
        PlatformException(code: 'no_activity', message: 'Activity is null'),
      );

      await expectLater(
        service.initialize(requestPermissions: true),
        completes,
      );

      verify(() => mockAndroidPlugin.createNotificationChannel(any()))
          .called(2);
    });

    test('showBatch configura ledOnMs y ledOffMs para evitar PlatformException(invalid_led_details)', () async {
      final notif = DetectedNotification(
        dedupeKey: 'msg_11193534',
        subjectName: 'Gestión Aplicada al Desarrollo de Software I',
        module: MielModuleType.mensajeria,
        title: 'PUJIA, TIAGO NAHUEL',
        body: 'asd',
        targetUrl:
            'https://miel.unlam.edu.ar/mensajeria/entrada/comision/117982/',
        idComision: '117982',
        detectedAt: DateTime.now(),
      );

      await service.showBatch([notif]);

      final captured = verify(
        () => mockPlugin.show(
          id: deterministicNotificationId('msg_11193534'),
          title: 'PUJIA, TIAGO NAHUEL',
          body: 'asd',
          notificationDetails: captureAny(named: 'notificationDetails'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;

      final details = captured[0] as NotificationDetails;
      final android = details.android!;

      expect(
        android.channelId,
        equals(NotificationService.androidUpdatesChannelId),
      );
      expect(android.enableLights, isTrue);
      expect(android.ledColor, isNotNull);
      expect(
        android.ledOnMs,
        equals(1000),
        reason: 'Debe especificar ledOnMs para evitar invalid_led_details en Android',
      );
      expect(
        android.ledOffMs,
        equals(500),
        reason: 'Debe especificar ledOffMs para evitar invalid_led_details en Android',
      );
      expect(android.category, equals(AndroidNotificationCategory.message));
      expect(
        android.subText,
        equals('Gestión Aplicada al Desarrollo de Software I'),
      );
    });

    test('showBatch emite notificación resumen de grupo cuando hay 2 o más novedades de una misma comisión en Android', () async {
      final now = DateTime(2026, 11, 23, 10, 0);
      final batch = [
        DetectedNotification(
          dedupeKey: 'msg_1',
          subjectName: 'Sistemas Embebidos',
          module: MielModuleType.mensajeria,
          title: 'Docente A',
          body: 'Subimos enunciado TP1',
          targetUrl:
              'https://miel.unlam.edu.ar/mensajeria/entrada/comision/555/',
          idComision: '555',
          detectedAt: now,
        ),
        DetectedNotification(
          dedupeKey: 'cont_2',
          subjectName: 'Sistemas Embebidos',
          module: MielModuleType.contenidos,
          title: 'Nuevo archivo',
          body: 'Guia_TP1.pdf',
          targetUrl:
              'https://miel.unlam.edu.ar/contenido/archivos/comision/555/',
          idComision: '555',
          detectedAt: now,
        ),
      ];

      await service.showBatch(batch);

      final capturedDetails = verify(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: captureAny(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).captured.cast<NotificationDetails>();

      expect(capturedDetails.length, equals(3));
      final summaryAndroid = capturedDetails.last.android!;
      expect(summaryAndroid.setAsGroupSummary, isTrue);
      expect(
        summaryAndroid.groupKey,
        equals('io.github.tiago_pujia.libremiel.555'),
      );
      expect(
        summaryAndroid.groupAlertBehavior,
        equals(GroupAlertBehavior.children),
      );
      expect(summaryAndroid.styleInformation, isA<InboxStyleInformation>());
    });

    test('showUpdateNotification y showMielRecoveredNotification usan el canal de sistema', () async {
      await service.showUpdateNotification(
        version: '0.2.0',
        releaseNotes: 'Mejoras de Android',
      );
      await service.showMielRecoveredNotification();

      final captured = verify(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: captureAny(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).captured.cast<NotificationDetails>();

      expect(captured.length, equals(2));
      for (final details in captured) {
        expect(
          details.android!.channelId,
          equals(NotificationService.androidSystemChannelId),
        );
        expect(
          details.android!.importance,
          equals(Importance.defaultImportance),
        );
      }
    });

    test(
      'showBatch captura PlatformException y no interrumpe el flujo',
      () async {
        when(
          () => mockPlugin.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(
          PlatformException(
            code: 'invalid_led_details',
            message: 'Must specify both ledOnMs and ledOffMs',
          ),
        );

        final notif = DetectedNotification(
          dedupeKey: 'msg_123',
          subjectName: 'Materia Test',
          module: MielModuleType.contenidos,
          title: 'Nuevo archivo',
          body: 'Apunte 1',
          targetUrl: 'https://miel.unlam.edu.ar/',
          idComision: '123',
          detectedAt: DateTime.now(),
        );

        await expectLater(service.showBatch([notif]), completes);
      },
    );
  });
}
