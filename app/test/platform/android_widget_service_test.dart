import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/platform/android_widget_models.dart';
import 'package:libremiel/platform/android_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidWidgetService', () {
    const channel = MethodChannel(
      'io.github.tiago_pujia.libremiel/android_widget_test',
    );
    final calls = <MethodCall>[];
    String? initialPayloadToReturn;

    setUp(() {
      calls.clear();
      initialPayloadToReturn = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'updateSnapshot' => true,
              'clearSnapshot' => true,
              'consumeInitialLaunchPayload' => initialPayloadToReturn,
              'isPinWidgetSupported' => true,
              'requestPinWidget' => true,
              _ => null,
            };
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('updateSnapshot, clearSnapshot, pinning y consumeInitialTapPayload en Android', () async {
      const service = AndroidWidgetService(
        channel: channel,
        isAndroidOverride: true,
      );
      await service.initialize(forceRegisterHandler: true);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '555',
          name: 'Redes de Computadoras',
          commissionCode: '01-1200',
          isHidden: false,
          mensajesBadge: 2,
        ),
        DateTime(2026, 11, 23, 15, 0),
      );

      await service.syncFromDatabase(
        database: db,
        isAuthenticated: true,
        serverStatus: MielServerStatus.online,
        lastSyncAt: DateTime(2026, 11, 23, 15, 0),
      );

      expect(calls, hasLength(1));
      expect(calls.first.method, 'updateSnapshot');
      final sentJson =
          (calls.first.arguments as Map<dynamic, dynamic>)['snapshotJson']
              as String;
      final parsed = AndroidWidgetSnapshot.tryFromJsonString(sentJson);
      expect(parsed, isNotNull);
      expect(parsed!.isAuthenticated, isTrue);
      expect(parsed.activeSubjects.single.idComision, '555');

      initialPayloadToReturn = jsonEncode({
        'idComision': '555',
        'module': 'mensajeria',
        'targetUrl':
            'https://miel.unlam.edu.ar/mensajeria/entrada/comision/555',
        'notificationId': 77,
      });
      final tapped = await service.consumeInitialTapPayload();
      expect(tapped, isNotNull);
      expect(tapped!.idComision, '555');
      expect(tapped.module, 'mensajeria');
      expect(tapped.notificationId, 77);

      expect(await service.isPinWidgetSupported(), isTrue);
      expect(await service.requestPinWidget(AndroidWidgetKind.feed), isTrue);
      expect(calls.last.arguments, equals(<String, dynamic>{'kind': 'feed'}));

      await service.clearSnapshot();
      expect(calls.last.method, 'clearSnapshot');
    });

    test('emite eventos en onWidgetTapped cuando Kotlin invoca onWidgetTapped en warm start', () async {
      const service = AndroidWidgetService(
        channel: channel,
        isAndroidOverride: true,
      );
      await service.initialize(forceRegisterHandler: true);

      final receivedFuture = AndroidWidgetService.onWidgetTapped.stream.first;
      final payloadJson = jsonEncode({
        'idComision': '202',
        'module': 'foros',
        'targetUrl':
            'https://miel.unlam.edu.ar/forov2/mensajes/comision/202/tema/88',
      });

      final codec = const StandardMethodCodec();
      final bytes = codec.encodeMethodCall(
        MethodCall('onWidgetTapped', payloadJson),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(channel.name, bytes, (_) {});

      final received = await receivedFuture;
      expect(received.idComision, '202');
      expect(received.module, 'foros');
      expect(received.targetUrl, contains('/tema/88'));
    });

    test('es no-op seguro fuera de Android', () async {
      const service = AndroidWidgetService(
        channel: channel,
        isAndroidOverride: false,
      );

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await service.initialize(forceRegisterHandler: true);
      await service.syncFromDatabase(
        database: db,
        isAuthenticated: true,
        serverStatus: MielServerStatus.online,
      );
      await service.clearSnapshot();
      expect(await service.consumeInitialTapPayload(), isNull);
      expect(await service.isPinWidgetSupported(), isFalse);
      expect(
        await service.requestPinWidget(AndroidWidgetKind.compact),
        isFalse,
      );
      expect(calls, isEmpty);
    });
  });
}
