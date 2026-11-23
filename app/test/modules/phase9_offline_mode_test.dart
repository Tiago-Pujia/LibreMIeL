import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/storage/offline_media_service.dart';
import 'package:libremiel/core/sync/sync_engine.dart';
import 'package:libremiel/features/home/widgets/miel_status_banner.dart';
import 'package:libremiel/features/modules/module_providers.dart';
import 'package:libremiel/platform/notification_service.dart';
import 'package:libremiel/platform/secure_credentials_store.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

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

class TestableSessionController extends AppSessionController {
  TestableSessionController(this._initialState);
  final AppSessionState _initialState;

  @override
  AppSessionState build() => _initialState;
}

class FakeReader implements MielInteractiveReader {
  FakeReader({this.contenidosFetcher});

  final Future<String> Function(String idComision)? contenidosFetcher;

  @override
  Future<bool> isLogged() async => true;

  @override
  Future<String> fetchContenidosHtml(String idComision) async {
    if (contenidosFetcher != null) return contenidosFetcher!(idComision);
    throw const HttpException('502 Bad Gateway');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMielClient extends Mock implements MielApiClient {}

class _MockCredsStore extends Mock implements SecureCredentialsStore {}

class _MockNotifService extends Mock implements NotificationService {}

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
          offlineModeEnabled: true,
          serverDownSince: DateTime.now().subtract(const Duration(minutes: 5)),
          lastSyncAt: DateTime(2026, 11, 22, 10, 30),
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
      expect(find.textContaining('22/11 10:30'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(controller.retryConnectionCalled, isTrue);
    });

    testWidgets('renders blue/grey banner when status is deviceOffline', (
      tester,
    ) async {
      final controller = FakeAppSessionController(
        const AppSessionState(
          serverStatus: MielServerStatus.deviceOffline,
          offlineModeEnabled: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appSessionProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: Scaffold(body: MielStatusBanner())),
        ),
      );

      expect(find.textContaining('Sin conexión a internet'), findsOneWidget);
      expect(
        find.textContaining('Activá el Modo sin conexión'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(controller.retryConnectionCalled, isTrue);
    });
  });

  group('fetchInteractiveHtmlWithAuth offline fallback & invariants', () {
    test(
      'falls back to local cached page when authenticated and network throws',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        await db.putOfflinePage(
          cacheKey: 'test_comision_999',
          idComision: '999',
          module: 'comision',
          htmlContent: '<html>Cached offline subject</html>',
        );

        final controller = FakeAppSessionController(
          const AppSessionState(
            isAuthenticated: true,
            offlineModeEnabled: true,
            offlineCacheMaxMb: 50,
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

        final result = await fetchInteractiveHtmlResultWithAuth(
          container.asRef(),
          (reader) async => throw const HttpException('502 Bad Gateway'),
          cacheKey: 'test_comision_999',
          idComision: '999',
          module: 'comision',
        );

        expect(result.html, '<html>Cached offline subject</html>');
        expect(result.fromCache, isTrue);
      },
    );

    test(
      'INVARIANT #11: refuses offline cache when session is NOT authenticated',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        await db.putOfflinePage(
          cacheKey: 'secret_page',
          idComision: '999',
          module: 'mensajeria',
          htmlContent: '<html>Private student message</html>',
        );

        final controller = FakeAppSessionController(
          const AppSessionState(
            isAuthenticated: false,
            offlineModeEnabled: true,
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

        await expectLater(
          () => fetchInteractiveHtmlWithAuth(
            container.asRef(),
            (reader) async => throw const HttpException('502 Bad Gateway'),
            cacheKey: 'secret_page',
          ),
          throwsA(isA<HttpException>()),
        );
      },
    );

    test(
      'rethrows exception when offline mode is disabled or no cache available',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        final controller = FakeAppSessionController(
          const AppSessionState(
            isAuthenticated: true,
            offlineModeEnabled: false,
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

    test('contenidosPageProvider does NOT clear local badge when serving from offline cache', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '555',
          name: 'Arquitectura',
          commissionCode: '01-555',
          isHidden: false,
          contenidosBadge: 3,
        ),
        DateTime(2026, 11, 22),
      );
      await db.putOfflinePage(
        cacheKey: 'contenidos:555',
        idComision: '555',
        module: 'contenidos',
        htmlContent:
            '<html><body><p>No se encontraron archivos</p></body></html>',
      );

      final controller = FakeAppSessionController(
        const AppSessionState(isAuthenticated: true, offlineModeEnabled: true),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appSessionProvider.overrideWith(() => controller),
          mielInteractiveReaderProvider.overrideWith((_) async => FakeReader()),
        ],
      );
      addTearDown(() => container.dispose());

      await container.read(contenidosPageProvider('555').future);
      final subjAfterCache = await db.getSubject('555');
      expect(subjAfterCache!.lastContenidosBadge, 3);
    });
  });

  group('SyncEngine + AppSessionController outage detection & cleanup', () {
    test('syncNow marks mielDown/deviceOffline (NEVER online) when SyncEngine fails authentication due to network error', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final client = _MockMielClient();
      final creds = _MockCredsStore();
      final notif = _MockNotifService();

      when(() => creds.read()).thenAnswer(
        (_) async =>
            const MielCredentials(username: '12345678', password: 'secret'),
      );
      when(() => client.isLogged()).thenAnswer((_) async => false);
      when(() => client.login('12345678', 'secret')).thenAnswer(
        (_) async => const MielLoginResult(
          status: MielAuthStatus.networkError,
          message: 'Failed host lookup: miel.unlam.edu.ar',
          networkErrorStatus: MielServerStatus.deviceOffline,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          mielClientProvider.overrideWith((_) async => client),
          credentialsStoreProvider.overrideWithValue(creds),
          notificationServiceProvider.overrideWithValue(notif),
          appSessionProvider.overrideWith(
            () => TestableSessionController(
              const AppSessionState(
                isChecking: false,
                isAuthenticated: true,
                offlineModeEnabled: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      await container.read(appSessionProvider.notifier).syncNow();
      final st = container.read(appSessionProvider);
      expect(st.serverStatus, MielServerStatus.deviceOffline);
      expect(st.serverDownSince, isNotNull);
      expect(st.lastOnlineSuccessAt, isNull);
    });

    test(
      'SyncEngine detects maintenance HTML in /principal/interno/ as mielDown',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());
        final client = _MockMielClient();
        when(() => client.isLogged()).thenAnswer((_) async => true);
        when(() => client.fetchInternoHtml()).thenAnswer(
          (_) async => '<html><head><title>502 Bad Gateway</title></head><body>502 Bad Gateway</body></html>',
        );

        final engine = SyncEngine(client: client, database: db);
        final summary = await engine.runCycle1(
          loadCredentials: () async =>
              const MielCredentials(username: '1234', password: 'pw'),
        );

        expect(summary.networkErrorStatus, MielServerStatus.mielDown);
      },
    );

    test('INVARIANT #11: logout(wipeLocalData: false) always clears OfflinePageCache and OfflineMediaService', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final mediaDir = Directory.systemTemp.createTempSync('media_logout_');
      addTearDown(() {
        if (mediaDir.existsSync()) mediaDir.deleteSync(recursive: true);
      });
      final mediaService = OfflineMediaService(overrideDirectory: mediaDir);

      await db.putOfflinePage(
        cacheKey: 'mensajeria:entrada:100:p1',
        idComision: '100',
        module: 'mensajeria',
        htmlContent: '<html>Private inbox</html>',
      );
      await mediaService.saveCachedImageBytes(
        'https://miel.unlam.edu.ar/avatar/1.jpg',
        Uint8List.fromList([1, 2, 3, 4]),
      );

      final client = _MockMielClient();
      final creds = _MockCredsStore();
      when(() => client.clearSession()).thenAnswer((_) async {});
      when(() => creds.clear()).thenAnswer((_) async {});
      when(() => creds.read()).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          offlineMediaServiceProvider.overrideWithValue(mediaService),
          mielClientProvider.overrideWith((_) async => client),
          credentialsStoreProvider.overrideWithValue(creds),
          appSessionProvider.overrideWith(
            () => TestableSessionController(
              const AppSessionState(
                isChecking: false,
                isAuthenticated: true,
                offlineModeEnabled: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      await container
          .read(appSessionProvider.notifier)
          .logout(wipeLocalData: false);

      expect(await db.getOfflineCacheTotalBytes(), 0);
      expect(await mediaService.getTotalCachedMediaBytes(), 0);
    });

    test('reportServerStatus emits recovery notification when transitioning mielDown -> online', () async {
      final notif = _MockNotifService();
      when(() => notif.showMielRecoveredNotification())
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(notif),
          appSessionProvider.overrideWith(
            () => TestableSessionController(
              const AppSessionState(
                isChecking: false,
                isAuthenticated: true,
                serverStatus: MielServerStatus.mielDown,
                notifyOnMielRecovery: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      container
          .read(appSessionProvider.notifier)
          .reportServerStatus(MielServerStatus.online);

      expect(
        container.read(appSessionProvider).serverStatus,
        MielServerStatus.online,
      );
      verify(() => notif.showMielRecoveredNotification()).called(1);
    });

    test(
      'OfflineMediaService.pruneToMaxBytes evicts oldest files LRU',
      () async {
        final mediaDir = Directory.systemTemp.createTempSync('media_lru_');
        addTearDown(() {
          if (mediaDir.existsSync()) mediaDir.deleteSync(recursive: true);
        });
        final media = OfflineMediaService(overrideDirectory: mediaDir);

        await media.saveCachedImageBytes(
          'https://miel.unlam.edu.ar/img1.png',
          Uint8List(100),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await media.saveCachedImageBytes(
          'https://miel.unlam.edu.ar/img2.png',
          Uint8List(100),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await media.saveCachedImageBytes(
          'https://miel.unlam.edu.ar/img3.png',
          Uint8List(100),
        );

        expect(await media.getTotalCachedMediaBytes(), 300);

        await media.pruneToMaxBytes(200);
        expect(await media.getTotalCachedMediaBytes(), 200);
        expect(
          await media.getCachedImageBytes('https://miel.unlam.edu.ar/img1.png'),
          isNull,
        );
        expect(
          await media.getCachedImageBytes('https://miel.unlam.edu.ar/img3.png'),
          isNotNull,
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
