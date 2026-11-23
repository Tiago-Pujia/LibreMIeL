import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/theme/miel_theme.dart';
import 'package:libremiel/features/updates/update_dialog.dart';
import 'package:libremiel/platform/notification_service.dart';
import 'package:libremiel/platform/updater/update_checker.dart';
import 'package:libremiel/platform/updater/update_downloader.dart';
import 'package:libremiel/platform/updater/update_installer.dart';
import 'package:libremiel/platform/updater/update_models.dart';
import 'package:libremiel/platform/updater/updater_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockUpdateChecker extends Mock implements UpdateChecker {}

class _MockUpdateDownloader extends Mock implements UpdateDownloader {}

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  final sampleRelease = ReleaseInfo(
    version: '0.2.0',
    tagName: 'v0.2.0',
    releaseNotes: 'Notas del release de prueba con correcciones importantes.',
    assetName: 'LibreMIeL-0.2.0-linux-x64.AppImage',
    downloadUrl: 'https://github.com/dl/app.AppImage',
    assetSize: 35 * 1024 * 1024,
    expectedSha256:
        '5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03',
    publishedAt: DateTime(2026, 11, 22),
  );

  group('UpdateDialog widget tests', () {
    testWidgets(
      'renders release info and action buttons when update is available',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            updaterProvider.overrideWith(
              () => _FakeUpdaterNotifier(
                UpdaterState(
                  status: UpdateStatus.updateAvailable,
                  availableRelease: sampleRelease,
                  currentVersion: '0.1.0',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMielLightTheme(),
              home: const Scaffold(body: UpdateDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nueva versión disponible'), findsOneWidget);
        expect(find.text('v0.2.0'), findsOneWidget);
        expect(
          find.textContaining('Notas del release de prueba'),
          findsOneWidget,
        );
        expect(find.text('LibreMIeL-0.2.0-linux-x64.AppImage'), findsOneWidget);
        expect(find.text('35.0 MB'), findsOneWidget);
        expect(find.text('Actualizar ahora'), findsOneWidget);
        expect(find.text('Omitir versión'), findsOneWidget);
        expect(find.text('Más tarde'), findsOneWidget);
      },
    );

    testWidgets('renders up to date message when already on latest version', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          updaterProvider.overrideWith(
            () => _FakeUpdaterNotifier(
              const UpdaterState(
                status: UpdateStatus.upToDate,
                currentVersion: '0.1.0',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildMielLightTheme(),
            home: const Scaffold(body: UpdateDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('versión más reciente'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);
    });

    testWidgets(
      'renders loading dialog when checking with no release loaded yet',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            updaterProvider.overrideWith(
              () => _FakeUpdaterNotifier(
                const UpdaterState(
                  status: UpdateStatus.checking,
                  currentVersion: '0.1.0',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMielLightTheme(),
              home: const Scaffold(body: UpdateDialog()),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Buscando actualizaciones…'), findsOneWidget);
        expect(find.text('Actualizar ahora'), findsNothing);
      },
    );

    testWidgets(
      'renders info message and install button after Android permission prompt',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            updaterProvider.overrideWith(
              () => _FakeUpdaterNotifier(
                UpdaterState(
                  status: UpdateStatus.readyToInstall,
                  availableRelease: sampleRelease,
                  currentVersion: '0.1.0',
                  infoMessage: 'Habilitá el permiso "Instalar apps desconocidas" para LibreMIeL.',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildMielLightTheme(),
              home: const Scaffold(body: UpdateDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Instalar apps desconocidas'),
          findsOneWidget,
        );
        expect(find.text('Instalar actualización'), findsOneWidget);
      },
    );
  });

  group('UpdaterNotifier lifecycle & installer tests', () {
    test('preserves cached release on 304 Not Modified and deduplicates notifications per version', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final checker = _MockUpdateChecker();
      final notif = _MockNotificationService();

      when(() => checker.getCurrentVersion())
          .thenAnswer((_) async => SemVer.parse('0.1.0'));
      when(
        () => notif.showUpdateNotification(
          version: any(named: 'version'),
          releaseNotes: any(named: 'releaseNotes'),
          assetName: any(named: 'assetName'),
        ),
      ).thenAnswer((_) async {});

      var callCount = 0;
      when(
        () => checker.checkForUpdate(
          cachedEtag: any(named: 'cachedEtag'),
          skippedReleaseVersion: any(named: 'skippedReleaseVersion'),
          includePrereleases: any(named: 'includePrereleases'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return UpdateCheckResult(
            isNewVersionAvailable: true,
            releaseInfo: sampleRelease,
            etag: '"etag-v020"',
          );
        }
        return const UpdateCheckResult(
          isNewVersionAvailable: false,
          etag: '"etag-v020"',
          notModified: true,
        );
      });

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          updateCheckerProvider.overrideWithValue(checker),
          notificationServiceProvider.overrideWithValue(notif),
        ],
      );
      addTearDown(container.dispose);

      // Esperar microtask inicial de _loadInitialSettings
      container.read(updaterProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 1ra comprobación automática: detecta v0.2.0 y notifica una vez
      await container
          .read(updaterProvider.notifier)
          .checkForUpdates(manual: false);
      expect(container.read(updaterProvider).hasUpdate, isTrue);
      expect(
        container.read(updaterProvider).availableRelease?.version,
        '0.2.0',
      );
      verify(
        () => notif.showUpdateNotification(
          version: '0.2.0',
          releaseNotes: any(named: 'releaseNotes'),
          assetName: any(named: 'assetName'),
        ),
      ).called(1);

      // Simular que pasaron 25 horas para disparar otra comprobación automática que recibe 304
      await db.setLastUpdateCheckAt(
        DateTime.now().subtract(const Duration(hours: 25)),
      );
      await container
          .read(updaterProvider.notifier)
          .checkForUpdates(manual: false);

      // El 304 NO debe borrar el release pendiente ni re-notificar la misma versión
      expect(container.read(updaterProvider).hasUpdate, isTrue);
      expect(
        container.read(updaterProvider).availableRelease?.version,
        '0.2.0',
      );
      verifyNever(
        () => notif.showUpdateNotification(
          version: any(named: 'version'),
          releaseNotes: any(named: 'releaseNotes'),
          assetName: any(named: 'assetName'),
        ),
      );
    });

    test('downloadUpdate emits verifyingChecksum and installUpdate handles Android permission result cleanly', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final checker = _MockUpdateChecker();
      final downloader = _MockUpdateDownloader();
      final notif = _MockNotificationService();

      final tempDir = Directory.systemTemp.createTempSync('updater_test_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final fakeApk = File('${tempDir.path}/update.apk')
        ..writeAsStringSync('apk-bytes');

      when(() => checker.getCurrentVersion())
          .thenAnswer((_) async => SemVer.parse('0.1.0'));
      when(
        () => checker.checkForUpdate(
          cachedEtag: any(named: 'cachedEtag'),
          skippedReleaseVersion: any(named: 'skippedReleaseVersion'),
          includePrereleases: any(named: 'includePrereleases'),
        ),
      ).thenAnswer(
        (_) async => UpdateCheckResult(
          isNewVersionAvailable: true,
          releaseInfo: sampleRelease,
        ),
      );
      when(
        () => downloader.downloadAndVerify(
          release: sampleRelease,
          onProgress: any(named: 'onProgress'),
          onVerifying: any(named: 'onVerifying'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final onVerifying =
            invocation.namedArguments[#onVerifying] as void Function()?;
        onVerifying?.call();
        return fakeApk;
      });

      final seenStatuses = <UpdateStatus>[];
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          updateCheckerProvider.overrideWithValue(checker),
          updateDownloaderProvider.overrideWithValue(downloader),
          notificationServiceProvider.overrideWithValue(notif),
          updateInstallerCallbackProvider.overrideWithValue(({
            required File downloadedFile,
            required ReleaseInfo release,
            Future<void> Function()? beforeExit,
          }) async {
            return InstallLaunchResult.needsAndroidInstallPermission;
          }),
        ],
      );
      addTearDown(container.dispose);

      container.listen(updaterProvider, (_, next) {
        seenStatuses.add(next.status);
      }, fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await container
          .read(updaterProvider.notifier)
          .checkForUpdates(manual: true);
      await container.read(updaterProvider.notifier).downloadUpdate();

      expect(seenStatuses, contains(UpdateStatus.verifyingChecksum));
      expect(container.read(updaterProvider).isReadyToInstall, isTrue);

      await container.read(updaterProvider.notifier).installUpdate();
      final postInstall = container.read(updaterProvider);
      expect(postInstall.status, UpdateStatus.readyToInstall);
      expect(postInstall.infoMessage, contains('Instalar apps desconocidas'));
    });

    test(
      'UpdateInstaller.replaceAppImageAtomically replaces target file cleanly',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('appimage_test_');
        addTearDown(() {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });

        final target = File('${tempDir.path}/LibreMIeL.AppImage')
          ..writeAsStringSync('old-appimage');
        final downloaded = File('${tempDir.path}/downloaded.AppImage')
          ..writeAsStringSync('new-appimage');

        await UpdateInstaller.replaceAppImageAtomically(
          downloadedFile: downloaded,
          targetAppImagePath: target.path,
        );

        expect(target.existsSync(), isTrue);
        expect(target.readAsStringSync(), 'new-appimage');
      },
    );
  });
}

class _FakeUpdaterNotifier extends UpdaterNotifier {
  _FakeUpdaterNotifier(this._initialState);
  final UpdaterState _initialState;

  @override
  UpdaterState build() => _initialState;
}
