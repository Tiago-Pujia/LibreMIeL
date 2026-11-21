import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/theme/miel_theme.dart';
import 'package:libremiel/features/modules/contenidos_view.dart';
import 'package:libremiel/features/modules/foro_view.dart';
import 'package:libremiel/features/modules/mensajeria_view.dart';
import 'package:libremiel/features/modules/module_sections.dart';
import 'package:libremiel/features/modules/portafolio_view.dart';
import 'package:libremiel/features/modules/secondary_modules_view.dart';
import 'package:material_ui/material_ui.dart';

import '../fixtures/miel_fixtures.dart';

/// PNG transparente 1x1 válido para tests de `MielAuthenticatedImage`.
final Uint8List _kOnePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _FakeInteractiveReader implements MielInteractiveReader {
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
  Future<String> fetchContenidosHtml(String idComision) async =>
      fixtureContenidosFase2Jerarquico;

  @override
  Future<String> fetchContenidosGlosarioHtml(
    String idComision, {
    String? letra,
  }) async => '<p>No se encontraron términos.</p>';

  @override
  Future<String> fetchContenidosFaqHtml(String idComision) async =>
      '<p>No se encontraron preguntas frecuentes.</p>';

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
      '<p>No se le asignó ningún grupo en esta comisión.</p>';

  @override
  Future<String> fetchPortafolioNotasHtml(String idComision) async =>
      fixturePortafolioNotasAsistencia;

  @override
  Future<String> fetchPortafolioCompetenciasHtml(String idComision) async =>
      '<p>Esta materia no tiene habilitada la evaluación por competencias.</p>';

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
  }) async => '<p>No se encontraron mensajes guardados en favoritos.</p>';

  @override
  Future<String> fetchMensajeriaDetalleHtml(String urlOrPath) async =>
      fixtureMensajeriaVerEntradaDetalle;

  @override
  Future<String> fetchMensajeriaDestinatariosHtml(String urlOrPath) async =>
      '<ul><li>DOCENTE, UNO</li><li>ESTUDIANTE, DEMO 1</li></ul>';

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
      '<p>No hay encuestas o formularios disponibles.</p>';

  @override
  Future<String> fetchAutoguiaHtml(String idComision) async => '';

  @override
  Future<Uint8List> downloadAuthenticatedBytes(String urlOrPath) async =>
      _kOnePixelPng;

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
      bytesWritten: 128,
    );
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<(AppDatabase, Subject)> createTestSubject() async {
    final db = AppDatabase(NativeDatabase.memory());
    final subject = await db.upsertSubjectFromInterno(
      const MielSubjectBadgeSummary(
        idComision: '117967',
        name: 'Gestión Aplicada al Desarrollo de Software I',
        subjectCode: '3659',
        commissionCode: '01-4900',
        roleLabel: 'Alumno/a',
        isHidden: false,
        contenidosBadge: 2,
        mensajesBadge: 1,
        foroBadge: 3,
        hasContenidos: true,
        hasPortafolio: true,
        hasMensajeria: true,
        hasForo: true,
        hasEvaluacion: true,
      ),
      DateTime(2026, 11, 20),
    );
    return (db, subject);
  }

  Future<void> cleanUpTestWidgetAndDb(
    WidgetTester tester,
    AppDatabase db,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
    'ContenidosView renderiza carpetas plegables, submódulos thead/tbody, descripciones y limpia badge local',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      expect(mielSectionsForTool(MielToolKind.contenidos).map((s) => s.label), [
        'Archivos',
      ]);
      expect(mielSectionsForTool(MielToolKind.portafolio).map((s) => s.label), [
        'Prácticas',
        'Archivos enviados',
        'Mis grupos',
        'Asistencia, notas y cert.',
      ]);

      final (db, subject) = await createTestSubject();
      final fakeReader = _FakeInteractiveReader();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            mielInteractiveReaderProvider.overrideWith((_) async => fakeReader),
          ],
          child: MaterialApp(
            theme: buildMielDarkTheme(),
            home: Scaffold(
              body: ContenidosView(subject: subject, sectionIndex: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica carpeta plegable y submódulos directos
      expect(find.text('Presentaciones de Clase'), findsOneWidget);
      expect(
        find.text('Módulo 00 | Presentación de la materia'),
        findsOneWidget,
      );
      expect(find.text('Encuesta Alumnos'), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
      expect(find.text('Abrir en MIeL'), findsNothing);

      // Expandir carpeta .desplegarModulo
      await tester.tap(find.text('Presentaciones de Clase'));
      await tester.pumpAndSettle();
      expect(find.text('Slides Teoría'), findsOneWidget);
      expect(find.text('Presentación Unidad 1'), findsOneWidget);

      // Expandir descripción oculta (.verDescripcion •••)
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('https://prezi.example.com/ciclo-de-vida'),
        findsOneWidget,
      );

      // El badge local de Contenidos se limpió a 0 tras abrir la vista
      final updated = await db.getSubject('117967');
      expect(updated!.lastContenidosBadge, 0);

      await cleanUpTestWidgetAndDb(tester, db);
    },
  );

  testWidgets(
    'PortafolioView renderiza tabla de Prácticas, reinicia al re-clickear sección, muestra Archivos enviados y Justificado azul',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (db, subject) = await createTestSubject();
      final fakeReader = _FakeInteractiveReader();
      var activeTab = 0;
      var resetTick = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            mielInteractiveReaderProvider.overrideWith((_) async => fakeReader),
          ],
          child: StatefulBuilder(
            builder: (context, setHostState) => MaterialApp(
              theme: buildMielDarkTheme(),
              home: Scaffold(
                appBar: AppBar(
                  actions: [
                    TextButton(
                      onPressed: () => setHostState(() {
                        activeTab = 0;
                        resetTick++;
                      }),
                      child: const Text('Re-click Prácticas'),
                    ),
                    TextButton(
                      onPressed: () => setHostState(() {
                        activeTab = 1;
                        resetTick++;
                      }),
                      child: const Text('Ir a Enviados'),
                    ),
                    TextButton(
                      onPressed: () => setHostState(() {
                        activeTab = 3;
                        resetTick++;
                      }),
                      child: const Text('Ir a Notas'),
                    ),
                  ],
                ),
                body: PortafolioView(
                  subject: subject,
                  sectionIndex: activeTab,
                  sectionResetTick: resetTick,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TP N°1'), findsOneWidget);
      expect(find.text('[ENTREGAR / VER]'), findsOneWidget);

      // Abrir detalle de entregas y correcciones
      await tester.tap(find.text('[ENTREGAR / VER]'));
      await tester.pumpAndSettle();

      expect(find.text('Entrega de prácticas'), findsOneWidget);
      expect(find.text('CORRECCIÓN DOCENTE'), findsOneWidget);
      expect(find.text('Excelente resolución.'), findsOneWidget);
      expect(find.text('1º ENTREGA'), findsOneWidget);
      expect(find.text('Entrega-Grupo-Demo.pdf'), findsOneWidget);

      // Re-clickear Prácticas en la barra lateral vuelve al listado principal
      await tester.tap(find.text('Re-click Prácticas'));
      await tester.pumpAndSettle();
      expect(find.text('[ENTREGAR / VER]'), findsOneWidget);
      expect(find.text('Entrega de prácticas'), findsNothing);

      // Cambiar a pestaña 1: Archivos enviados con cabecera de tabla oficial
      await tester.tap(find.text('Ir a Enviados'));
      await tester.pumpAndSettle();

      expect(find.text('Prácticas: Archivos enviados'), findsOneWidget);
      expect(find.text('Archivo o enlace enviado'), findsOneWidget);
      expect(find.text('Fecha y hora'), findsOneWidget);
      expect(find.text('Tamaño'), findsOneWidget);
      expect(find.text('Descargar'), findsOneWidget);
      expect(find.text('Entrega-Grupo-Demo.pdf'), findsOneWidget);
      expect(find.text('6.562 KB'), findsOneWidget);

      // Cambiar a pestaña 3: Asistencia, notas y certificados
      await tester.tap(find.text('Ir a Notas'));
      await tester.pumpAndSettle();

      expect(find.text('Asistencia, notas y certificados'), findsOneWidget);
      expect(find.text('18/08/2026'), findsOneWidget);
      expect(find.text('Presente'), findsOneWidget);
      expect(find.text('Justificado'), findsOneWidget);
      expect(find.text('Ausente'), findsOneWidget);

      // Verificar color azul oficial MIeL dark (.w3-blue = #4F90C4) en Justificado
      final justifiedContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Justificado'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (justifiedContainer.decoration as BoxDecoration).color,
        const Color(0xFF4F90C4),
      );

      await cleanUpTestWidgetAndDb(tester, db);
    },
  );

  testWidgets(
    'MensajeriaView renderiza Bandeja de Entrada, abre lector verEntrada, descuenta badge y vuelve al re-clickear bandeja',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (db, subject) = await createTestSubject();
      final fakeReader = _FakeInteractiveReader();
      var resetTick = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            mielInteractiveReaderProvider.overrideWith((_) async => fakeReader),
          ],
          child: StatefulBuilder(
            builder: (context, setHostState) => MaterialApp(
              theme: buildMielLightTheme(),
              home: Scaffold(
                appBar: AppBar(
                  actions: [
                    TextButton(
                      onPressed: () => setHostState(() => resetTick++),
                      child: const Text('Re-click Entrada'),
                    ),
                  ],
                ),
                body: MensajeriaView(
                  subject: subject,
                  sectionIndex: 1,
                  sectionResetTick: resetTick,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bandeja de Entrada'), findsOneWidget);
      expect(find.text('Página 1 de 2'), findsOneWidget);
      expect(find.text('Corrección'), findsOneWidget);
      expect(find.text('Consulta vieja'), findsOneWidget);

      // Abrir mensaje no leído
      await tester.tap(find.text('Corrección'));
      await tester.pumpAndSettle();

      expect(find.text('Ejercicio de bondad de ajuste'), findsOneWidget);
      expect(find.text('De: DOCENTE, UNO'), findsOneWidget);
      expect(find.text('enunciado_bondad.pdf'), findsOneWidget);

      // El badge de Mensajes bajó de 1 a 0
      final updated = await db.getSubject('117967');
      expect(updated!.lastMensajesBadge, 0);

      // Re-clickear Bandeja de entrada en la barra lateral vuelve al listado de mensajes
      await tester.tap(find.text('Re-click Entrada'));
      await tester.pumpAndSettle();
      expect(find.text('Bandeja de Entrada'), findsOneWidget);
      expect(find.text('Ejercicio de bondad de ajuste'), findsNothing);

      await cleanUpTestWidgetAndDb(tester, db);
    },
  );

  testWidgets(
    'ForoView renderiza Temas abiertos y abre hilo al hacer click en cualquier parte del foro',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (db, subject) = await createTestSubject();
      final fakeReader = _FakeInteractiveReader();
      String? activeTopicId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            mielInteractiveReaderProvider.overrideWith((_) async => fakeReader),
          ],
          child: StatefulBuilder(
            builder: (context, setHostState) => MaterialApp(
              theme: buildMielDarkTheme(),
              home: Scaffold(
                body: ForoView(
                  subject: subject,
                  selectedTopicId: activeTopicId,
                  onSelectTopic: (tid) =>
                      setHostState(() => activeTopicId = tid),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Temas abiertos'), findsOneWidget);
      expect(find.text('Consultas Parcial 2'), findsOneWidget);

      // Abrir el tema haciendo click en la línea de cantidad de mensajes (no solo el ícono/título)
      await tester.tap(find.textContaining('8 mensajes'));
      await tester.pumpAndSettle();

      expect(find.text('Tema: Consultas Parcial 2'), findsOneWidget);
      expect(find.text('DOCENTE, UNO'), findsWidgets);
      expect(find.text('Guia4-Resuelta.pdf'), findsOneWidget);
      expect(find.text('Me gusta (2)'), findsOneWidget);
      expect(find.text('Invertir orden'), findsOneWidget);

      await cleanUpTestWidgetAndDb(tester, db);
    },
  );

  testWidgets(
    'EvaluacionView renderiza tabla oficial de 6 columnas con estado e intentos',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (db, subject) = await createTestSubject();
      final fakeReader = _FakeInteractiveReader();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            mielInteractiveReaderProvider.overrideWith((_) async => fakeReader),
          ],
          child: MaterialApp(
            theme: buildMielDarkTheme(),
            home: Scaffold(body: EvaluacionView(subject: subject)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evaluaciones'), findsOneWidget);
      expect(find.text('Auto-Evaluacion'), findsOneWidget);
      expect(
        find.text('Autoevaluación: Revisión de Ensayo de Hipótesis'),
        findsOneWidget,
      );
      expect(find.text('0/2 intentos'), findsOneWidget);
      expect(find.text('[Ingresar]'), findsOneWidget);

      await cleanUpTestWidgetAndDb(tester, db);
    },
  );
}
