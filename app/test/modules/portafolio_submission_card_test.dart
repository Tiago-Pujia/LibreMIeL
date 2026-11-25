import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/features/modules/module_providers.dart';
import 'package:libremiel/features/modules/portafolio_view.dart';
import 'package:libremiel/features/modules/widgets/module_state_views.dart';
import 'package:libremiel/features/modules/widgets/portafolio_submission_card.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
      'PortafolioSubmissionCard renderiza campos en el orden exacto solicitado: '
      '1. Docente destinatario, 2. Mensaje, 3. Cargar archivo, 4. Entrega grupal, 5. Grupo, 6. Enviar entrega',
      (tester) async {
    const meta = PortfolioSubmissionFormMeta(
      canSubmit: true,
      tutors: [
        PortfolioTutorOption(id: '0', name: 'Todos los docentes de la comisión'),
        PortfolioTutorOption(id: '10', name: 'Prof. Demo'),
      ],
      allowsGroup: true,
      isGroupDefault: true,
      groups: [
        PortfolioGroupOption(id: '1', name: 'Los Backyardigans'),
      ],
      maxSizeMb: 40,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portafolioGruposProvider('119341').overrideWith(
            (ref) async => const [
              PortfolioGroup(
                idGrupo: '1',
                name: 'Los Backyardigans',
                members: ['Pujia, Tiago'],
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortafolioSubmissionCard(
                idComision: '119341',
                idPractica: '55512',
                practiceTitle: 'Trabajo Práctico - Modelo de Procesos',
                formMeta: meta,
                deliveryType: 'Entrega obligatoria grupal',
                webUrl: 'https://miel.unlam.edu.ar/portafolio/entregas',
                onSubmitted: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Docente destinatario
    final tutorFinder = find.text('Docente destinatario:');
    expect(tutorFinder, findsOneWidget);

    // 2. Mensaje
    final messageFinder = find.text('Mensaje / observaciones (opcional):');
    expect(messageFinder, findsOneWidget);

    // 3. Cargar archivo
    final fileHeaderFinder =
        find.text('Archivo de entrega (máx. 40 MB):');
    expect(fileHeaderFinder, findsOneWidget);
    final fileButtonFinder =
        find.text('Cargar archivo (hasta 40 MB)');
    expect(fileButtonFinder, findsOneWidget);

    // 4. Entrega grupal
    final groupCheckFinder = find.text(
        'Entrega grupal (práctica realizada por varios alumnos).');
    expect(groupCheckFinder, findsOneWidget);

    // 5. Grupo
    final groupLabelFinder = find.text('Grupo:');
    expect(groupLabelFinder, findsOneWidget);
    final groupOptionFinder = find.text('Los Backyardigans');
    expect(groupOptionFinder, findsOneWidget);

    // 6. Enviar entrega
    final submitButtonFinder = find.text('Enviar entrega');
    expect(submitButtonFinder, findsOneWidget);

    // Verificar orden vertical descendente (Y-coordinate estricto)
    final y1 = tester.getTopLeft(tutorFinder).dy;
    final y2 = tester.getTopLeft(messageFinder).dy;
    final y3 = tester.getTopLeft(fileHeaderFinder).dy;
    final y4 = tester.getTopLeft(groupCheckFinder).dy;
    final y5 = tester.getTopLeft(groupLabelFinder).dy;
    final y6 = tester.getTopLeft(submitButtonFinder).dy;

    expect(y1 < y2, isTrue, reason: '1. Docente destinatario debe estar antes de 2. Mensaje');
    expect(y2 < y3, isTrue, reason: '2. Mensaje debe estar antes de 3. Cargar archivo');
    expect(y3 < y4, isTrue, reason: '3. Cargar archivo debe estar antes de 4. Entrega grupal');
    expect(y4 < y5, isTrue, reason: '4. Entrega grupal debe estar antes de 5. Grupo');
    expect(y5 < y6, isTrue, reason: '5. Grupo debe estar antes de 6. Enviar entrega');
  });

  testWidgets('PortafolioView detalle de práctica solo tiene 1 botón de Volver en la parte superior', (tester) async {
    const practice = PortfolioPractice(
      idPractica: '55512',
      idComision: '119341',
      moduleName: 'Trabajos Prácticos',
      title: 'Trabajo Práctico - Modelo de Procesos',
      deliveryType: 'Entrega obligatoria grupal',
      dueDate: '',
      deliveryDate: '',
      correctionDate: '',
      status: '',
      grade: '',
      detailUrl: 'https://miel.unlam.edu.ar/portafolio/entregas',
    );
    const detail = PortfolioPracticeDetail(
      idComision: '119341',
      idPractica: '55512',
      headerTitle: 'Trabajo Práctico - Modelo de Procesos',
      deliveryModeLabel: 'Entrega obligatoria grupal',
      corrections: [],
      deliveries: [],
      submissionForm: PortfolioSubmissionFormMeta(canSubmit: false),
    );

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    final subject = await db.upsertSubjectFromInterno(
      const MielSubjectBadgeSummary(
        idComision: '119341',
        name: 'Gestión Aplicada al Desarrollo de Software I',
        subjectCode: '3659',
        commissionCode: '01-4900',
        roleLabel: 'Alumno/a',
        isHidden: false,
        contenidosBadge: 0,
        mensajesBadge: 0,
        foroBadge: 0,
        hasContenidos: true,
        hasPortafolio: true,
        hasMensajeria: true,
        hasForo: true,
        hasEvaluacion: true,
      ),
      DateTime(2026, 11, 20),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          portafolioEntregasDetalleProvider((
            idComision: '119341',
            idPractica: '55512',
          )).overrideWith((ref) async => detail),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PortafolioView(
              subject: subject,
              sectionIndex: 0,
              hasControlledPractice: true,
              controlledSelectedPractice: practice,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Debe haber exactamente UN botón con texto 'Volver' en la vista (el superior en MielModuleHeader)
    final volverFinder = find.widgetWithText(MielActionButton, 'Volver');
    expect(volverFinder, findsOneWidget);
  });
}
