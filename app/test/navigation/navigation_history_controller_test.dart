import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/features/navigation/navigation_history_controller.dart';
import 'package:libremiel/features/navigation/navigation_history_entry.dart';

void main() {
  group('NavigationHistoryController & Entry Tests (Fase 12)', () {
    late ProviderContainer container;
    late NavigationHistoryController controller;

    setUp(() {
      container = ProviderContainer();
      controller = container.read(navigationHistoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Estado inicial inicia en Home con stack de tamaño 1', () {
      final state = container.read(navigationHistoryProvider);
      expect(state.entries.length, 1);
      expect(state.currentIndex, 0);
      expect(state.canGoBack, false);
      expect(state.canGoForward, false);
      expect(state.current.section, BrowserShellSection.home);
    });

    test('navigateTo apila rutas, goBack retrocede y goForward avanza', () {
      controller.navigateTo(const NavigationHistoryEntry.novedades());
      var state = container.read(navigationHistoryProvider);
      expect(state.entries.length, 2);
      expect(state.currentIndex, 1);
      expect(state.canGoBack, true);
      expect(state.canGoForward, false);
      expect(state.current.section, BrowserShellSection.novedades);

      controller.navigateTo(const NavigationHistoryEntry.ajustes());
      state = container.read(navigationHistoryProvider);
      expect(state.entries.length, 3);
      expect(state.currentIndex, 2);
      expect(state.current.section, BrowserShellSection.ajustes);

      final prev = controller.goBack();
      expect(prev?.section, BrowserShellSection.novedades);
      state = container.read(navigationHistoryProvider);
      expect(state.currentIndex, 1);
      expect(state.canGoBack, true);
      expect(state.canGoForward, true);

      final next = controller.goForward();
      expect(next?.section, BrowserShellSection.ajustes);
      state = container.read(navigationHistoryProvider);
      expect(state.currentIndex, 2);
      expect(state.canGoForward, false);
    });

    test(
      'Navegación trunca rama forward al avanzar desde un estado previo',
      () {
        controller.navigateTo(const NavigationHistoryEntry.novedades());
        controller.navigateTo(const NavigationHistoryEntry.ajustes());
        controller.goBack(); // estamos en novedades

        const newModuleEntry = NavigationHistoryEntry.module(
          subjectId: '101',
          tool: MielToolKind.contenidos,
        );
        controller.navigateTo(newModuleEntry);

        final state = container.read(navigationHistoryProvider);
        expect(state.entries.length, 3);
        expect(state.currentIndex, 2);
        expect(state.entries.map((e) => e.section).toList(), [
          BrowserShellSection.home,
          BrowserShellSection.novedades,
          BrowserShellSection.module,
        ]);
        expect(state.canGoForward, false);
      },
    );

    test('Deduplica entradas consecutivas con la misma locationKey', () {
      controller.navigateTo(const NavigationHistoryEntry.home());
      controller.navigateTo(const NavigationHistoryEntry.home());
      expect(container.read(navigationHistoryProvider).entries.length, 1);

      controller.navigateTo(const NavigationHistoryEntry.novedades());
      controller.navigateTo(const NavigationHistoryEntry.novedades());
      expect(container.read(navigationHistoryProvider).entries.length, 2);
    });

    test('Capacidad máxima de 80 entradas con poda FIFO', () {
      for (var i = 1; i <= 100; i++) {
        controller.navigateTo(
          NavigationHistoryEntry.module(
            subjectId: '$i',
            tool: MielToolKind.contenidos,
          ),
        );
      }

      final state = container.read(navigationHistoryProvider);
      expect(state.entries.length, NavigationHistoryController.maxEntries);
      expect(state.entries.length, 80);
      expect(state.currentIndex, 79);
      expect(state.current.subjectId, '100');
      // La primera debe ser la 21 (100 - 80 + 1)
      expect(state.entries.first.subjectId, '21');
    });

    test('canonicalMielUrl genera las URLs web oficiales exactas de MIeL', () {
      const home = NavigationHistoryEntry.home();
      expect(
        home.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/principal/interno/',
      );

      const novedades = NavigationHistoryEntry.novedades();
      expect(
        novedades.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/principal/interno/',
      );

      const ajustes = NavigationHistoryEntry.ajustes();
      expect(
        ajustes.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/perfil/datos/',
      );

      const contenidos = NavigationHistoryEntry.module(
        subjectId: '5432',
        tool: MielToolKind.contenidos,
      );
      expect(
        contenidos.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/contenido/archivos/comision/5432',
      );

      const foro = NavigationHistoryEntry.module(
        subjectId: '5432',
        tool: MielToolKind.foro,
        foroTopicId: '9988',
      );
      expect(
        foro.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/forov2/mensajes/comision/5432/tema/9988',
      );

      const mensajeriaRedactar = NavigationHistoryEntry.module(
        subjectId: '5432',
        tool: MielToolKind.mensajeria,
        moduleSectionIndex: 0,
      );
      expect(
        mensajeriaRedactar.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/mensajeria/redactar/comision/5432',
      );

      const mensajeriaEntrada = NavigationHistoryEntry.module(
        subjectId: '5432',
        tool: MielToolKind.mensajeria,
        moduleSectionIndex: 1,
      );
      expect(
        mensajeriaEntrada.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/mensajeria/entrada/comision/5432/pag/1',
      );

      const portafolio = NavigationHistoryEntry.module(
        subjectId: '5432',
        tool: MielToolKind.portafolio,
        moduleSectionIndex: 0,
      );
      expect(
        portafolio.canonicalMielUrl(),
        'https://miel.unlam.edu.ar/portafolio/practicas/comision/5432',
      );
    });

    test('saveScrollOffset actualiza el offset en la entrada actual', () {
      controller.saveScrollOffset(342.5);
      final current = container.read(navigationHistoryProvider).current;
      expect(current.scrollOffset, 342.5);
    });

    test('reset() restablece la pila al estado inicial', () {
      controller.navigateTo(const NavigationHistoryEntry.novedades());
      controller.navigateTo(const NavigationHistoryEntry.ajustes());
      expect(container.read(navigationHistoryProvider).entries.length, 3);

      controller.reset();
      final state = container.read(navigationHistoryProvider);
      expect(state.entries.length, 1);
      expect(state.currentIndex, 0);
      expect(state.current.section, BrowserShellSection.home);
    });
  });
}
