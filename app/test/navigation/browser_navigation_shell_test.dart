import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/theme/miel_theme.dart';
import 'package:libremiel/features/home/home_shell.dart';
import 'package:libremiel/features/modules/module_providers.dart';
import 'package:libremiel/features/navigation/browser_find_bar.dart';
import 'package:libremiel/features/navigation/browser_find_controller.dart';
import 'package:libremiel/features/navigation/browser_navigation_host.dart';
import 'package:libremiel/features/navigation/browser_zoom_viewport.dart';
import 'package:libremiel/features/navigation/draft_dirty_registry.dart';
import 'package:libremiel/features/navigation/navigation_history_controller.dart';
import 'package:libremiel/features/navigation/navigation_history_entry.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/miel_fixtures.dart';

class _FakeNavReader implements MielInteractiveReader {
  int fetchContenidosCount = 0;

  @override
  Future<MielLoginResult> login(
    String username,
    String password, {
    bool remember = true,
  }) async => const MielLoginResult(status: MielAuthStatus.ok, rawCode: 0);

  @override
  Future<bool> isLogged() async => true;

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<String> fetchInternoHtml() async => fixtureInternoSinBadges;

  @override
  Future<String> fetchCursoDetallesHtml(String idComision) async =>
      fixtureCursoDetalles;

  @override
  Future<String> fetchContenidosHtml(String idComision) async {
    fetchContenidosCount++;
    return fixtureContenidosFase2Jerarquico;
  }

  @override
  Future<String> fetchContenidosGlosarioHtml(
    String idComision, {
    String? letra,
  }) async => '<p>Glosario vacío</p>';

  @override
  Future<String> fetchContenidosFaqHtml(String idComision) async =>
      '<p>FAQ vacío</p>';

  @override
  Future<void> markExternalContentDownloaded(
    String idComision,
    String idElemento,
  ) async {}

  @override
  Future<String> fetchPortafolioPracticasHtml(String idComision) async =>
      fixturePortafolioCorregido;

  @override
  Future<String> fetchPortafolioEntregasHtml(
    String idComision,
    String idPractica,
  ) async => fixturePortafolioEntregasCorregido;

  @override
  Future<String> fetchPortafolioArchivosEnviadosHtml(String idComision) async =>
      fixturePortafolioArchivosEnviados;

  @override
  Future<String> fetchPortafolioGruposHtml(String idComision) async =>
      '<p>Sin grupos</p>';

  @override
  Future<String> fetchPortafolioNotasHtml(String idComision) async =>
      fixturePortafolioNotasAsistencia;

  @override
  Future<String> fetchPortafolioCompetenciasHtml(String idComision) async =>
      '<p>Sin competencias</p>';

  @override
  Future<String> fetchMensajeriaEntradaHtml(String idComision) async =>
      fixtureMensajeriaConCorreccion;

  @override
  Future<String> fetchMensajeriaEntradaPageHtml(
    String idComision, {
    int page = 1,
  }) async => fixtureMensajeriaConCorreccion;

  @override
  Future<String> fetchMensajeriaSalidaHtml(
    String idComision, {
    int page = 1,
  }) async => fixtureMensajeriaVacia;

  @override
  Future<String> fetchMensajeriaBorradoresHtml(
    String idComision, {
    int page = 1,
  }) async => fixtureMensajeriaVacia;

  @override
  Future<String> fetchMensajeriaFavoritosHtml(
    String idComision, {
    int page = 1,
  }) async => '<p>Sin favoritos</p>';

  @override
  Future<String> fetchMensajeriaDetalleHtml(String urlOrPath) async =>
      fixtureMensajeriaVerEntradaDetalle;

  @override
  Future<String> fetchMensajeriaDestinatariosHtml(String urlOrPath) async =>
      '<ul><li>DOCENTE, UNO</li></ul>';

  @override
  Future<String> fetchForoTemasHtml(String idComision) async =>
      fixtureForoTemasConActividad;

  @override
  Future<String> fetchForoMensajesHtml(
    String idComision,
    String idTema,
  ) async => fixtureForoMensajesHilo;

  @override
  Future<String> fetchEvaluacionesHtml(String idComision) async =>
      fixtureEvaluaciones6Columnas;

  @override
  Future<String> fetchEncuestasHtml(String idComision) async =>
      '<p>Sin encuestas</p>';

  @override
  Future<String> fetchAutoguiaHtml(String idComision) async => '';

  @override
  Future<String> fetchPerfilHtml() async => '<form id="formUsuario"></form>';

  @override
  Future<Uint8List> downloadAuthenticatedBytes(String urlOrPath) async =>
      Uint8List(0);

  @override
  Future<DownloadedFileResult> downloadAuthenticatedFile(
    String urlOrPath,
    String destinationDir, {
    String? fallbackFileName,
    void Function(int received, int total)? onProgress,
  }) async {
    return DownloadedFileResult(
      filePath: '$destinationDir/${fallbackFileName ?? "demo.pdf"}',
      fileName: fallbackFileName ?? 'demo.pdf',
      bytesWritten: 0,
    );
  }
}

class _TestSessionController extends AppSessionController {
  _TestSessionController(this._initial);

  final AppSessionState _initial;

  @override
  AppSessionState build() => _initial;

  @override
  Future<void> toggleThemeMode(Brightness currentBrightness) async {
    state = state.copyWith(
      themeMode: currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark,
    );
  }

  @override
  Future<void> updateUiZoomScale(double scale) async {
    final clamped = (scale.clamp(0.8, 1.5) * 10).round() / 10.0;
    state = state.copyWith(uiZoomScale: clamped);
  }

  @override
  Future<void> stepUiZoomScale(double delta) async {
    await updateUiZoomScale(state.uiZoomScale + delta);
  }

  @override
  Future<void> resetUiZoomScale() async {
    await updateUiZoomScale(1.0);
  }

  @override
  Future<void> updateShowBrowserNavControls(bool enabled) async {
    state = state.copyWith(showBrowserNavControls: enabled);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('BrowserNavigationHost Tests (Fase 12)', () {
    testWidgets(
      'Mouse 4 (back) y Mouse 5 (forward) disparan callbacks sin doble salto',
      (tester) async {
        int backCount = 0;
        int forwardCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BrowserNavigationHost(
                onBack: () => backCount++,
                onForward: () => forwardCount++,
                onReload: ({bool forceLive = false}) {},
                onEscape: () {},
                onFindInPage: () {},
                onGoHome: () {},
                onStepZoom: (_) {},
                onResetZoom: () {},
                child: const Center(child: Text('Host Child')),
              ),
            ),
          ),
        );

        final targetCenter = tester.getCenter(find.text('Host Child'));

        // Simular Mouse 4 (kBackMouseButton = 0x08)
        TestWidgetsFlutterBinding.instance.handlePointerEvent(
          PointerDownEvent(
            position: targetCenter,
            kind: PointerDeviceKind.mouse,
            buttons: kBackMouseButton,
          ),
        );
        // Mover el ratón manteniendo presionado Mouse 4 no debe duplicar la invocación
        TestWidgetsFlutterBinding.instance.handlePointerEvent(
          PointerMoveEvent(
            position: targetCenter + const Offset(2, 2),
            kind: PointerDeviceKind.mouse,
            buttons: kBackMouseButton,
          ),
        );
        TestWidgetsFlutterBinding.instance.handlePointerEvent(
          PointerUpEvent(
            position: targetCenter + const Offset(2, 2),
            kind: PointerDeviceKind.mouse,
            buttons: 0,
          ),
        );
        await tester.pump();

        expect(backCount, 1);
        expect(forwardCount, 0);

        // Simular Mouse 5 (kForwardMouseButton = 0x10)
        TestWidgetsFlutterBinding.instance.handlePointerEvent(
          PointerDownEvent(
            position: targetCenter,
            kind: PointerDeviceKind.mouse,
            buttons: kForwardMouseButton,
          ),
        );
        TestWidgetsFlutterBinding.instance.handlePointerEvent(
          PointerUpEvent(
            position: targetCenter,
            kind: PointerDeviceKind.mouse,
            buttons: 0,
          ),
        );
        await tester.pump();

        expect(backCount, 1);
        expect(forwardCount, 1);
      },
    );

    testWidgets(
      'Atajos de teclado Alt+Left, Alt+Right, Alt+Home, Ctrl+F, Esc, F5 y Zoom',
      (tester) async {
        int backCount = 0;
        int forwardCount = 0;
        int homeCount = 0;
        int findCount = 0;
        int escapeCount = 0;
        double zoomDelta = 0.0;
        int resetZoomCount = 0;
        bool reloaded = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BrowserNavigationHost(
                onBack: () => backCount++,
                onForward: () => forwardCount++,
                onReload: ({bool forceLive = false}) => reloaded = true,
                onEscape: () => escapeCount++,
                onFindInPage: () => findCount++,
                onGoHome: () => homeCount++,
                onStepZoom: (d) => zoomDelta += d,
                onResetZoom: () => resetZoomCount++,
                child: const Center(child: Text('Host Child')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Alt + ArrowLeft -> onBack
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        expect(backCount, 1);

        // Alt + ArrowRight -> onForward
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        expect(forwardCount, 1);

        // Alt + Home -> onGoHome
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        expect(homeCount, 1);

        // Ctrl + F -> onFindInPage
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(findCount, 1);

        // Esc -> onEscape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        expect(escapeCount, 1);

        // F5 -> onReload
        await tester.sendKeyEvent(LogicalKeyboardKey.f5);
        expect(reloaded, isTrue);

        // Ctrl + Equal (+) -> onStepZoom(0.1)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(zoomDelta, closeTo(0.1, 0.001));

        // Ctrl + Minus (-) -> onStepZoom(-0.1)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(zoomDelta, closeTo(0.0, 0.001));

        // Ctrl + Digit0 -> onResetZoom
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(resetZoomCount, 1);
      },
    );

    testWidgets(
      'Input protection: foco dentro de TextField no activa scroll global',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BrowserNavigationHost(
                onBack: () {},
                onForward: () {},
                onReload: ({bool forceLive = false}) {},
                onEscape: () {},
                onFindInPage: () {},
                onGoHome: () {},
                onStepZoom: (_) {},
                onResetZoom: () {},
                contentScrollController: scrollController,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SizedBox(
                    height: 2000,
                    child: Column(
                      children: const [
                        TextField(key: Key('test_input')),
                        SizedBox(height: 1000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Enfocar el campo de texto
        await tester.tap(find.byKey(const Key('test_input')));
        await tester.pump();

        // Enviar tecla PageDown
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pump(const Duration(milliseconds: 250));

        // El offset debe mantenerse en 0 porque hay un EditableText con foco
        expect(scrollController.offset, 0.0);
      },
    );
  });

  group('BrowserZoomViewport & BrowserFindBar Tests (Fase 12)', () {
    testWidgets(
      'BrowserZoomViewport escala visualmente a 1.2 sin errores de desborde',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BrowserZoomViewport(
                zoomScale: 1.2,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                  child: const Text('Zoomed Content'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Zoomed Content'), findsOneWidget);
        expect(find.byType(FittedBox), findsOneWidget);
      },
    );

    testWidgets(
      'BrowserZoomViewport mantiene hit-test y hover en bordes inferiores y derechos con zoom 0.8 y 1.2',
      (tester) async {
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);

        for (final scale in [0.8, 1.2]) {
          var bottomLeftTaps = 0;
          var topRightTaps = 0;
          var bottomLeftHovered = false;
          var topRightHovered = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BrowserZoomViewport(
                  zoomScale: scale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => topRightHovered = true,
                          onExit: (_) => topRightHovered = false,
                          child: GestureDetector(
                            onTap: () => topRightTaps++,
                            child: const SizedBox(
                              width: 120,
                              height: 44,
                              child: Center(child: Text('TopRightBtn')),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => bottomLeftHovered = true,
                          onExit: (_) => bottomLeftHovered = false,
                          child: GestureDetector(
                            onTap: () => bottomLeftTaps++,
                            child: const SizedBox(
                              width: 160,
                              height: 44,
                              child: Center(child: Text('BottomLeftBtn')),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await mouse.moveTo(tester.getCenter(find.text('TopRightBtn')));
          await tester.pumpAndSettle();
          expect(
            topRightHovered,
            isTrue,
            reason: 'Hover debe funcionar en borde derecho a zoom $scale',
          );

          await tester.tap(find.text('TopRightBtn'));
          await tester.pumpAndSettle();
          expect(topRightTaps, 1);

          await mouse.moveTo(tester.getCenter(find.text('BottomLeftBtn')));
          await tester.pumpAndSettle();
          expect(
            bottomLeftHovered,
            isTrue,
            reason: 'Hover debe funcionar en borde inferior a zoom $scale',
          );

          await tester.tap(find.text('BottomLeftBtn'));
          await tester.pumpAndSettle();
          expect(bottomLeftTaps, 1);
        }
      },
    );

    testWidgets(
      'BrowserFindBar emite cambios de query y cierre al pulsar botón',
      (tester) async {
        String currentQuery = '';
        bool closed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: buildMielLightTheme(),
            home: Scaffold(
              body: BrowserFindBar(
                initialQuery: 'inicial',
                onQueryChanged: (q) => currentQuery = q,
                onClose: () => closed = true,
              ),
            ),
          ),
        );

        expect(find.textContaining('Buscar en la página'), findsOneWidget);
        expect(find.text('inicial'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'término buscado');
        expect(currentQuery, 'término buscado');

        await tester.tap(find.byIcon(Icons.close));
        expect(closed, isTrue);
      },
    );
  });

  group('HomeShell Browser Navigation Integration Tests (Fase 12)', () {
    testWidgets(
      'PopScope cierra BrowserFindBar antes de retroceder en historial',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              appSessionProvider.overrideWith(
                () => _TestSessionController(
                  const AppSessionState(
                    isChecking: false,
                    isAuthenticated: true,
                    studentName: 'ESTUDIANTE, DEMO',
                  ),
                ),
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                return MaterialApp(
                  theme: buildMielLightTheme(),
                  home: const HomeShell(),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Abrir la barra de búsqueda Ctrl+F
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeShell)),
        );
        container.read(browserFindProvider.notifier).open();
        await tester.pumpAndSettle();

        expect(find.byType(BrowserFindBar), findsOneWidget);

        // Simular evento pop del sistema (atrás)
        await Navigator.of(tester.element(find.byType(HomeShell))).maybePop();
        await tester.pumpAndSettle();

        // FindBar debe haberse cerrado
        expect(find.byType(BrowserFindBar), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Protección de borradores sucios: cancela navegación o la confirma tras descartar',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await db.upsertSubjectFromInterno(
          const MielSubjectBadgeSummary(
            idComision: '117967',
            name: 'Materia Demo',
            subjectCode: '1001',
            commissionCode: '01',
            roleLabel: 'Alumno/a',
            isHidden: false,
            hasContenidos: true,
          ),
          DateTime(2026, 11, 20),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              mielInteractiveReaderProvider.overrideWith(
                (ref) async => _FakeNavReader(),
              ),
              contenidosPageProvider('117967').overrideWith(
                (ref) async => const ContentPageData(
                  idComision: '117967',
                  sections: [],
                  allItems: [],
                ),
              ),
              appSessionProvider.overrideWith(
                () => _TestSessionController(
                  const AppSessionState(
                    isChecking: false,
                    isAuthenticated: true,
                    studentName: 'ESTUDIANTE, DEMO',
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: buildMielLightTheme(),
              home: const HomeShell(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeShell)),
        );

        // Navegar a una materia para tener canGoBack == true
        container
            .read(navigationHistoryProvider.notifier)
            .navigateTo(
              const NavigationHistoryEntry.module(
                subjectId: '117967',
                tool: MielToolKind.contenidos,
              ),
            );
        await tester.pumpAndSettle();

        expect(container.read(navigationHistoryProvider).canGoBack, isTrue);

        // Registrar un borrador sucio
        container
            .read(draftDirtyRegistryProvider)
            .setDirty('test_editor', isDirty: true, label: 'mensaje borrador');
        expect(
          container.read(draftDirtyRegistryProvider).hasDirtyDrafts,
          isTrue,
        );

        // Simular intento de retroceso (PopScope)
        await Navigator.of(tester.element(find.byType(HomeShell))).maybePop();
        await tester.pumpAndSettle();

        // Debe aparecer el diálogo de confirmación con el label
        expect(find.text('¿Descartar cambios?'), findsOneWidget);
        expect(find.textContaining('mensaje borrador'), findsWidgets);
        expect(find.text('Seguir editando'), findsOneWidget);
        expect(find.text('Descartar y continuar'), findsOneWidget);

        // 1. Pulsar 'Seguir editando' cancela el retroceso
        await tester.tap(find.text('Seguir editando'));
        await tester.pumpAndSettle();

        expect(find.text('¿Descartar cambios?'), findsNothing);
        expect(
          container.read(navigationHistoryProvider).current.section,
          BrowserShellSection.module,
        );
        expect(
          container.read(draftDirtyRegistryProvider).hasDirtyDrafts,
          isTrue,
        );

        // 2. Simular intento de retroceso de nuevo y pulsar 'Descartar y continuar'
        await Navigator.of(tester.element(find.byType(HomeShell))).maybePop();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Descartar y continuar'));
        await tester.pumpAndSettle();

        expect(
          container.read(draftDirtyRegistryProvider).hasDirtyDrafts,
          isFalse,
        );
        expect(
          container.read(navigationHistoryProvider).current.section,
          BrowserShellSection.home,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Controles opcionales de navegación en barra superior se muestran según showBrowserNavControls',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              appSessionProvider.overrideWith(
                () => _TestSessionController(
                  const AppSessionState(
                    isChecking: false,
                    isAuthenticated: true,
                    studentName: 'ESTUDIANTE, DEMO',
                    showBrowserNavControls: false,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: buildMielLightTheme(),
              home: const HomeShell(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Con showBrowserNavControls = false (por defecto) no están presentes
        expect(find.byIcon(Icons.arrow_back), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);

        // 2. Activar showBrowserNavControls en la sesión
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeShell)),
        );
        await container
            .read(appSessionProvider.notifier)
            .updateShowBrowserNavControls(true);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byTooltip('Atrás (deshabilitado)'), findsOneWidget);
        expect(find.byTooltip('Adelante (deshabilitado)'), findsOneWidget);
        expect(
          find.byTooltip('Recargar (F5 / Ctrl+R) [Shift = bypass caché]'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    test('bfcache en RAM: markBfCacheRestoreKeys reutiliza HTML sin llamadas de red', () async {
      final container = ProviderContainer(
        overrides: [
          appSessionProvider.overrideWith(
            () => _TestSessionController(
              const AppSessionState(
                isChecking: false,
                isAuthenticated: true,
                studentName: 'ESTUDIANTE, DEMO',
              ),
            ),
          ),
          mielInteractiveReaderProvider.overrideWith(
            (ref) async => _FakeNavReader(),
          ),
        ],
      );
      addTearDown(container.dispose);

      const cacheKey = 'test_bfcache_key';
      const initialHtml = '<html><body>Contenido original</body></html>';

      int readerCalls = 0;
      final fetchTestProvider =
          FutureProvider.family<InteractiveHtmlFetchResult, String>((
            ref,
            key,
          ) async {
            return fetchInteractiveHtmlResultWithAuth(ref, (reader) async {
              readerCalls++;
              return initialHtml;
            }, cacheKey: key);
          });

      // 1. Primera consulta: puebla el caché
      final res1 = await container.read(fetchTestProvider(cacheKey).future);

      expect(res1.html, initialHtml);
      expect(res1.fromCache, isFalse);
      expect(readerCalls, 1);

      // 2. Marcar clave como esperada por bfcache al navegar Back
      markBfCacheRestoreKeys([cacheKey]);

      // 3. Segunda consulta con nuevo fetcher que retornaría algo distinto si llamara al reader
      final secondFetchProvider =
          FutureProvider.family<InteractiveHtmlFetchResult, String>((
            ref,
            key,
          ) async {
            return fetchInteractiveHtmlResultWithAuth(ref, (reader) async {
              readerCalls++;
              return '<html><body>Nuevo contenido que NO debe ser llamado</body></html>';
            }, cacheKey: key);
          });

      final res2 = await container.read(secondFetchProvider(cacheKey).future);

      expect(res2.html, initialHtml);
      expect(res2.fromCache, isTrue);
      expect(readerCalls, 1); // No incrementó
    });

    test(
      'logout() limpia la pila de navegación y el registro de borradores',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            mielClientProvider.overrideWith((ref) async => _FakeNavReader()),
            mielInteractiveReaderProvider.overrideWith(
              (ref) async => _FakeNavReader(),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Registrar navegación y borrador
        container
            .read(navigationHistoryProvider.notifier)
            .navigateTo(const NavigationHistoryEntry.novedades());
        container
            .read(navigationHistoryProvider.notifier)
            .navigateTo(const NavigationHistoryEntry.ajustes());
        container
            .read(draftDirtyRegistryProvider)
            .setDirty('test_owner', isDirty: true, label: 'borrador en curso');

        expect(container.read(navigationHistoryProvider).canGoBack, isTrue);
        expect(
          container.read(draftDirtyRegistryProvider).hasDirtyDrafts,
          isTrue,
        );

        // Ejecutar logout
        await container.read(appSessionProvider.notifier).logout();

        // Verificar que el historial fue reseteado a Home único y no hay borradores
        final history = container.read(navigationHistoryProvider);
        expect(history.canGoBack, isFalse);
        expect(history.canGoForward, isFalse);
        expect(history.current.section, BrowserShellSection.home);
        expect(
          container.read(draftDirtyRegistryProvider).hasDirtyDrafts,
          isFalse,
        );
      },
    );
  });
}
