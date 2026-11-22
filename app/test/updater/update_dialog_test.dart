import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:libremiel/core/theme/miel_theme.dart';
import 'package:libremiel/features/updates/update_dialog.dart';
import 'package:libremiel/platform/updater/update_models.dart';
import 'package:libremiel/platform/updater/updater_controller.dart';

void main() {
  group('UpdateDialog widget tests', () {
    testWidgets(
      'renders release info and action buttons when update is available',
      (tester) async {
        final mockRelease = ReleaseInfo(
          version: '0.2.0',
          tagName: 'v0.2.0',
          releaseNotes:
              'Notas del release de prueba con correcciones importantes.',
          assetName: 'LibreMIeL-0.2.0-linux-x64.AppImage',
          downloadUrl: 'https://github.com/dl/app.AppImage',
          assetSize: 35 * 1024 * 1024,
          expectedSha256: '5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03',
          publishedAt: DateTime(2026, 11, 22),
        );

        final container = ProviderContainer(
          overrides: [
            updaterProvider.overrideWith(
              () => _FakeUpdaterNotifier(
                UpdaterState(
                  status: UpdateStatus.updateAvailable,
                  availableRelease: mockRelease,
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
  });
}

class _FakeUpdaterNotifier extends UpdaterNotifier {
  _FakeUpdaterNotifier(this._initialState);
  final UpdaterState _initialState;

  @override
  UpdaterState build() => _initialState;
}
