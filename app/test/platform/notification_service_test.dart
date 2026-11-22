import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/platform/notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
  });

  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationService(plugin: mockPlugin);
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
    });

    test('showBatch configura ledOnMs y ledOffMs para evitar PlatformException(invalid_led_details)', () async {
      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

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
          id: any(named: 'id'),
          title: 'PUJIA, TIAGO NAHUEL',
          body: 'asd',
          notificationDetails: captureAny(named: 'notificationDetails'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;

      final details = captured[0] as NotificationDetails;
      final android = details.android!;

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

        // No debe lanzar excepción
        await expectLater(service.showBatch([notif]), completes);
      },
    );
  });
}
