import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/features/home/widgets/miel_status_banner.dart';
import 'package:libremiel/features/modules/module_providers.dart';

class FakeAppSessionController extends AppSessionController {
  FakeAppSessionController(this._initialState);
  final AppSessionState _initialState;
  bool retryConnectionCalled = false;

  @override
  AppSessionState build() => _initialState;

  @override
  void reportServerStatus(MielServerStatus status) {
    state = state.copyWith(serverStatus: status);
  }

  @override
  Future<void> retryConnection() async {
    retryConnectionCalled = true;
  }
}

class FakeReader implements MielInteractiveReader {
  @override
  Future<bool> isLogged() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MielStatusBanner widget tests', () {
    testWidgets('renders nothing when status is online', (tester) async {
      final controller = FakeAppSessionController(
        const AppSessionState(serverStatus: MielServerStatus.online),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appSessionProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: Scaffold(body: MielStatusBanner())),
        ),
      );

      expect(find.byType(MielStatusBanner), findsOneWidget);
      expect(find.textContaining('MIeL'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('renders amber banner when status is mielDown', (tester) async {
      final controller = FakeAppSessionController(
        AppSessionState(
          serverStatus: MielServerStatus.mielDown,
          serverDownSince: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appSessionProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: Scaffold(body: MielStatusBanner())),
        ),
      );

      expect(
        find.textContaining('Los servidores de MIeL no responden'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(controller.retryConnectionCalled, isTrue);
    });

    testWidgets('renders blue/grey banner when status is deviceOffline', (
      tester,
    ) async {
      final controller = FakeAppSessionController(
        const AppSessionState(serverStatus: MielServerStatus.deviceOffline),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appSessionProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: Scaffold(body: MielStatusBanner())),
        ),
      );

      expect(find.textContaining('Sin conexión a internet'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(controller.retryConnectionCalled, isTrue);
    });
  });

  group('fetchInteractiveHtmlWithAuth offline fallback tests', () {
    test('falls back to local cached page when network throws', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Preparamos página en caché
      await db.putOfflinePage(
        cacheKey: 'test_comision_999',
        idComision: '999',
        module: 'comision',
        htmlContent: '<html>Cached offline subject</html>',
      );

      final controller = FakeAppSessionController(
        const AppSessionState(offlineModeEnabled: true, offlineCacheMaxMb: 50),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appSessionProvider.overrideWith(() => controller),
          mielInteractiveReaderProvider.overrideWith((_) async => FakeReader()),
        ],
      );
      addTearDown(() => container.dispose());

      // Llamamos con fetcher que falla con 502 Bad Gateway
      final html = await fetchInteractiveHtmlWithAuth(
        container.asRef(),
        (reader) async => throw const HttpException('502 Bad Gateway'),
        cacheKey: 'test_comision_999',
        idComision: '999',
        module: 'comision',
      );

      expect(html, '<html>Cached offline subject</html>');
    });

    test(
      'rethrows exception when offline mode is disabled or no cache available',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        final controller = FakeAppSessionController(
          const AppSessionState(
            offlineModeEnabled: false, // deshabilitado
          ),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            appSessionProvider.overrideWith(() => controller),
            mielInteractiveReaderProvider.overrideWith(
              (_) async => FakeReader(),
            ),
          ],
        );
        addTearDown(() => container.dispose());

        expect(
          () => fetchInteractiveHtmlWithAuth(
            container.asRef(),
            (reader) async => throw const HttpException('502 Bad Gateway'),
            cacheKey: 'missing_key',
          ),
          throwsA(isA<HttpException>()),
        );
      },
    );
  });
}

extension ContainerRefExtension on ProviderContainer {
  Ref asRef() {
    return read(_dummyRefProvider);
  }
}

final _dummyRefProvider = Provider<Ref>((ref) => ref);
