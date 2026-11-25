import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/theme/miel_theme.dart';
import 'package:libremiel/features/home/home_shell.dart';
import 'package:libremiel/features/modules/widgets/module_state_views.dart';
import 'package:libremiel/features/navigation/navigation_history_controller.dart';
import 'package:libremiel/features/navigation/navigation_history_entry.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/miel_fixtures.dart';

const String _fixtureSalidaConMensajes = '''
<div>Página 1 de 1</div>
<table>
  <tbody>
    <tr class="mensaje-leido">
      <td>20/11/2026</td>
      <td>PROFESOR, JUAN</td>
      <td></td>
      <td><a class="verMensaje" href="https://miel.unlam.edu.ar/mensajeria/verSalida/comision/117967/id/998877">Entrega de TP final</a></td>
      <td></td>
      <td><span>20/11/2026</span></td>
    </tr>
    <tr class="mensaje-leido">
      <td>15/11/2026</td>
      <td>DOCENTE, PEDRO</td>
      <td><i class="material-icons">attachment</i></td>
      <td><a class="verMensaje" href="https://miel.unlam.edu.ar/mensajeria/verSalida/comision/117967/id/998878">Consulta ejercicio</a></td>
      <td></td>
      <td><span>15/11/2026</span></td>
    </tr>
  </tbody>
</table>
''';

const String _fixtureBorradoresConMensajes = '''
<div>Página 1 de 1</div>
<table>
  <tbody>
    <tr class="mensaje-leido">
      <td>22/11/2026</td>
      <td>AYUDANTE, LUCAS</td>
      <td></td>
      <td><a class="verMensaje" href="https://miel.unlam.edu.ar/mensajeria/redactar/comision/117967/borrador/554433">Borrador de consulta</a></td>
      <td>
        <a class="botonEliminarBorrador" data-id="554433"><i>delete</i></a>
      </td>
      <td></td>
    </tr>
  </tbody>
</table>
''';

class _FakeInteractiveReader implements MielInteractiveReader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> fetchInternoHtml() async => fixtureInternoSinBadges;

  @override
  Future<String> fetchCursoDetallesHtml(String idComision) async =>
      fixtureCursoDetalles;

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
  }) async => _fixtureSalidaConMensajes;

  @override
  Future<String> fetchMensajeriaBorradoresHtml(
    String idComision, {
    int page = 1,
  }) async => _fixtureBorradoresConMensajes;

  @override
  Future<String> fetchMensajeriaFavoritosHtml(
    String idComision, {
    int page = 1,
  }) async => '<p>No se encontraron mensajes guardados en favoritos.</p>';
}

class _FakeWriter implements MielWriter {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> fetchMensajeriaRedactarHtml(String idComision) async =>
      '''<form id="formRedactar" action="/mensajeria/event/enviarMensaje/comision/$idComision">
        <select id="listaDestinatarios">
          <option value="1">Docente 1</option>
        </select>
        <input name="asunto" value="" />
        <textarea name="mensaje"></textarea>
      </form>''';
}

class _TestSessionController extends Notifier<AppSessionState>
    implements AppSessionController {
  _TestSessionController(this._initial);
  final AppSessionState _initial;

  @override
  AppSessionState build() => _initial;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<AppDatabase> createTestDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.upsertSubjectFromInterno(
      const MielSubjectBadgeSummary(
        idComision: '117967',
        name: 'Materia Demo',
        subjectCode: '1001',
        commissionCode: '01',
        isHidden: false,
        contenidosBadge: 0,
        mensajesBadge: 1,
        foroBadge: 0,
        hasContenidos: true,
        hasPortafolio: true,
        hasMensajeria: true,
        hasForo: true,
        hasEvaluacion: true,
      ),
      DateTime(2026, 11, 20),
    );
    return db;
  }

  Future<void> cleanUp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Widget buildTestApp(AppDatabase db) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        mielInteractiveReaderProvider.overrideWith((_) async => _FakeInteractiveReader()),
        mielWriterProvider.overrideWith((_) async => _FakeWriter()),
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
    );
  }

  testWidgets(
    'Nuevo mensaje NO contiene el botón Abrir en MIeL',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final db = await createTestDb();

      await tester.pumpWidget(buildTestApp(db));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)),
      );
      // Navega a sección 0: Nuevo mensaje
      container.read(navigationHistoryProvider.notifier).navigateTo(
        const NavigationHistoryEntry(
          section: BrowserShellSection.module,
          subjectId: '117967',
          tool: MielToolKind.mensajeria,
          moduleSectionIndex: 0,
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que no exista botón 'Abrir en MIeL' en la vista
      expect(find.text('Abrir en MIeL'), findsNothing);
      expect(find.text('Nuevo mensaje'), findsWidgets);

      await cleanUp(tester, db);
    },
  );

  testWidgets(
    'Bandeja de Entrada: Redactar navega a Nuevo Mensaje y Filtrar filtra en tiempo real',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final db = await createTestDb();

      await tester.pumpWidget(buildTestApp(db));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)),
      );
      // Navega a Bandeja de Entrada (sección 1)
      container.read(navigationHistoryProvider.notifier).navigateTo(
        const NavigationHistoryEntry(
          section: BrowserShellSection.module,
          subjectId: '117967',
          tool: MielToolKind.mensajeria,
          moduleSectionIndex: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bandeja de Entrada'), findsOneWidget);
      expect(find.text('DOCENTE, UNO'), findsOneWidget);
      expect(find.text('ALUMNO, DOS'), findsOneWidget);

      // 1. Probar botón Filtrar
      await tester.tap(find.widgetWithText(MielActionButton, 'Filtrar'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar mensajes'), findsOneWidget);
      expect(find.text('Usuario / Remitente:'), findsOneWidget);

      // Filtrar por texto 'DOCENTE'
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        'DOCENTE',
      );
      await tester.pumpAndSettle();

      expect(find.text('DOCENTE, UNO'), findsOneWidget);
      expect(find.text('ALUMNO, DOS'), findsNothing);

      // Limpiar filtros
      await tester.tap(find.widgetWithText(MielActionButton, 'Limpiar filtros'));
      await tester.pumpAndSettle();

      expect(find.text('DOCENTE, UNO'), findsOneWidget);
      expect(find.text('ALUMNO, DOS'), findsOneWidget);

      // 2. Probar botón Redactar
      await tester.tap(find.widgetWithText(MielActionButton, 'Redactar'));
      await tester.pumpAndSettle();

      // Debe haber navegado a sección 0 (Nuevo mensaje)
      expect(
        container.read(navigationHistoryProvider).current.moduleSectionIndex,
        0,
      );
      expect(find.text('Abrir en MIeL'), findsNothing);

      await cleanUp(tester, db);
    },
  );

  testWidgets(
    'Bandeja de Salida: Redactar navega a Nuevo Mensaje y Filtrar muestra Destinatario',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final db = await createTestDb();

      await tester.pumpWidget(buildTestApp(db));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)),
      );
      // Navega a Bandeja de Salida (sección 2)
      container.read(navigationHistoryProvider.notifier).navigateTo(
        const NavigationHistoryEntry(
          section: BrowserShellSection.module,
          subjectId: '117967',
          tool: MielToolKind.mensajeria,
          moduleSectionIndex: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bandeja de Salida'), findsOneWidget);
      expect(find.text('PROFESOR, JUAN'), findsOneWidget);
      expect(find.text('DOCENTE, PEDRO'), findsOneWidget);

      // 1. Probar botón Filtrar
      await tester.tap(find.widgetWithText(MielActionButton, 'Filtrar'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar mensajes'), findsOneWidget);
      expect(find.text('Destinatario:'), findsOneWidget);

      // Filtrar por destinatario 'JUAN'
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        'JUAN',
      );
      await tester.pumpAndSettle();

      expect(find.text('PROFESOR, JUAN'), findsOneWidget);
      expect(find.text('DOCENTE, PEDRO'), findsNothing);

      // 2. Probar botón Redactar
      await tester.tap(find.widgetWithText(MielActionButton, 'Redactar'));
      await tester.pumpAndSettle();

      expect(
        container.read(navigationHistoryProvider).current.moduleSectionIndex,
        0,
      );

      await cleanUp(tester, db);
    },
  );

  testWidgets(
    'Borradores: Redactar navega a Nuevo Mensaje y Filtrar funciona con Destinatario',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final db = await createTestDb();

      await tester.pumpWidget(buildTestApp(db));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeShell)),
      );
      // Navega a Borradores (sección 3)
      container.read(navigationHistoryProvider.notifier).navigateTo(
        const NavigationHistoryEntry(
          section: BrowserShellSection.module,
          subjectId: '117967',
          tool: MielToolKind.mensajeria,
          moduleSectionIndex: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(MielModuleHeader, 'Borradores'),
        findsOneWidget,
      );
      expect(find.text('AYUDANTE, LUCAS'), findsOneWidget);

      // 1. Probar botón Filtrar
      await tester.tap(find.widgetWithText(MielActionButton, 'Filtrar'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar mensajes'), findsOneWidget);
      expect(find.text('Destinatario:'), findsOneWidget);

      // Filtrar por texto inexistente
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        'NO_EXISTE',
      );
      await tester.pumpAndSettle();

      expect(find.text('AYUDANTE, LUCAS'), findsNothing);
      expect(
        find.text(
          'No se encontraron mensajes que coincidan con los filtros aplicados.',
        ),
        findsOneWidget,
      );

      // 2. Probar botón Redactar
      await tester.tap(find.widgetWithText(MielActionButton, 'Redactar'));
      await tester.pumpAndSettle();

      expect(
        container.read(navigationHistoryProvider).current.moduleSectionIndex,
        0,
      );

      await cleanUp(tester, db);
    },
  );
}
