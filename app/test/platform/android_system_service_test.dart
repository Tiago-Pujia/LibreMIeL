import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/platform/android_system_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidSystemService', () {
    const channel = MethodChannel(
      'io.github.tiago_pujia.libremiel/android_system_test',
    );
    final calledMethods = <String>[];

    setUp(() {
      calledMethods.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calledMethods.add(call.method);
            return switch (call.method) {
              'isIgnoringBatteryOptimizations' => true,
              'requestIgnoreBatteryOptimizations' => true,
              'openAppNotificationSettings' => true,
              _ => null,
            };
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('invoca los métodos del MethodChannel en Android', () async {
      const service = AndroidSystemService(
        channel: channel,
        isAndroidOverride: true,
      );

      expect(await service.isIgnoringBatteryOptimizations(), isTrue);
      expect(await service.requestIgnoreBatteryOptimizations(), isTrue);
      expect(await service.openAppNotificationSettings(), isTrue);
      expect(
        calledMethods,
        equals([
          'isIgnoringBatteryOptimizations',
          'requestIgnoreBatteryOptimizations',
          'openAppNotificationSettings',
        ]),
      );
    });

    test('es no-op seguro fuera de Android', () async {
      const service = AndroidSystemService(
        channel: channel,
        isAndroidOverride: false,
      );

      expect(await service.isIgnoringBatteryOptimizations(), isNull);
      expect(await service.requestIgnoreBatteryOptimizations(), isFalse);
      expect(await service.openAppNotificationSettings(), isFalse);
      expect(calledMethods, isEmpty);
    });
  });
}
