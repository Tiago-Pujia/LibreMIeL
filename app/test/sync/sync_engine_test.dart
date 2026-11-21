import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/sync/sync_engine.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/miel_fixtures.dart';

class MockMielApiClient extends Mock implements MielApiClient {}

void main() {
  late MockMielApiClient client;
  late AppDatabase db;
  late SyncEngine engine;
  final fixedNow = DateTime(2026, 11, 20, 14, 0);

  Future<MielCredentials?> fakeCreds() async =>
      const MielCredentials(username: '00000000', password: 'secret');

  setUp(() {
    client = MockMielApiClient();
    db = AppDatabase(NativeDatabase.memory());
    engine = SyncEngine(
      client: client,
      database: db,
      nowProvider: () => fixedNow,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngine invariants', () {
    test(
      'Baseline silencioso no dispara notificaciones ni consulta Contenidos',
      () async {
        when(() => client.isLogged()).thenAnswer((_) async => true);
        when(() => client.fetchInternoHtml())
            .thenAnswer((_) async => fixtureInternoSinBadges);
        when(() => client.fetchMensajeriaEntradaHtml('117967'))
            .thenAnswer((_) async => fixtureMensajeriaVacia);
        when(() => client.fetchForoTemasHtml('117967'))
            .thenAnswer((_) async => fixtureForoTemasInicial);
        when(() => client.fetchPortafolioPracticasHtml('117967'))
            .thenAnswer((_) async => fixturePortafolioInicial);
        when(() => client.fetchEvaluacionesHtml('117967'))
            .thenAnswer((_) async => fixtureEvaluaciones);

        final summary = await engine.runCycle1(loadCredentials: fakeCreds);

        expect(summary.isBaseline, isTrue);
        expect(summary.notifications, isEmpty);
        expect(await db.isBaselineCompleted(), isTrue);

        // Invariante crítica: nunca consultar Contenidos cuando badge == 0 o en baseline
        verifyNever(() => client.fetchContenidosHtml(any()));
        // Nunca consultar materias ocultas (.materia-bloque-oculta)
        verifyNever(() => client.fetchContenidosHtml('999001'));
        verifyNever(() => client.fetchMensajeriaEntradaHtml('999001'));
      },
    );

    test('Ciclo 1 con badges notifica Contenidos, Mensajería (+Corrección -> Portafolio) y Foro no invasivo', () async {
      when(() => client.isLogged()).thenAnswer((_) async => true);

      // Paso 1: Baseline inicial sin badges
      when(() => client.fetchInternoHtml())
          .thenAnswer((_) async => fixtureInternoSinBadges);
      when(() => client.fetchMensajeriaEntradaHtml('117967'))
          .thenAnswer((_) async => fixtureMensajeriaVacia);
      when(() => client.fetchForoTemasHtml('117967'))
          .thenAnswer((_) async => fixtureForoTemasInicial);
      when(() => client.fetchPortafolioPracticasHtml('117967'))
          .thenAnswer((_) async => fixturePortafolioInicial);
      when(() => client.fetchEvaluacionesHtml('117967'))
          .thenAnswer((_) async => fixtureEvaluaciones);
      await engine.runCycle1(loadCredentials: fakeCreds);

      // Paso 2: Aparecen badges en /principal/interno/
      when(() => client.fetchInternoHtml())
          .thenAnswer((_) async => fixtureInternoConBadges);
      when(() => client.fetchContenidosHtml('117967'))
          .thenAnswer((_) async => fixtureContenidosConNovedad);
      when(() => client.fetchMensajeriaEntradaHtml('117967'))
          .thenAnswer((_) async => fixtureMensajeriaConCorreccion);
      when(() => client.fetchCursoDetallesHtml('117967'))
          .thenAnswer((_) async => fixtureCursoDetalles);
      when(() => client.fetchPortafolioPracticasHtml('117967'))
          .thenAnswer((_) async => fixturePortafolioCorregido);
      when(() => client.fetchPortafolioEntregasHtml('117967', '282463'))
          .thenAnswer((_) async => fixturePortafolioEntregasCorregido);
      when(() => client.fetchForoTemasHtml('117967'))
          .thenAnswer((_) async => fixtureForoTemasConActividad);

      final summary = await engine.runCycle1(loadCredentials: fakeCreds);

      expect(summary.isBaseline, isFalse);
      final modules = summary.notifications.map((n) => n.module).toList();
      expect(modules, contains(MielModuleType.novedades));
      expect(
        modules.where((m) => m == MielModuleType.contenidos),
        hasLength(2),
      );
      expect(modules, contains(MielModuleType.mensajeria));
      expect(modules, contains(MielModuleType.portafolio));
      expect(modules, contains(MielModuleType.foros));

      // Verifica enriquecimiento docente en Mensajería y observaciones en Portafolio
      final msgNotif = summary.notifications.firstWhere(
        (n) => n.module == MielModuleType.mensajeria,
      );
      expect(msgNotif.body, contains('(Docente)'));

      final portNotif = summary.notifications.firstWhere(
        (n) => n.module == MielModuleType.portafolio,
      );
      expect(portNotif.body, contains('Nota: 9'));
      expect(portNotif.body, contains('Excelente resolución.'));

      // En modo no invasivo por defecto, JAMÁS se abre /forov2/mensajes/...
      verifyNever(() => client.fetchForoMensajesHtml(any(), any()));
    });

    test('Modo teacherReplies en Foros notifica solo respuestas de Tutor/a al usuario', () async {
      when(() => client.isLogged()).thenAnswer((_) async => true);
      await db.setSetting(
        SettingKeys.forumSyncMode,
        ForumSyncMode.teacherReplies.name,
      );

      // Baseline
      when(() => client.fetchInternoHtml())
          .thenAnswer((_) async => fixtureInternoSinBadges);
      when(() => client.fetchMensajeriaEntradaHtml('117967'))
          .thenAnswer((_) async => fixtureMensajeriaVacia);
      when(() => client.fetchForoTemasHtml('117967'))
          .thenAnswer((_) async => fixtureForoTemasInicial);
      when(() => client.fetchPortafolioPracticasHtml('117967'))
          .thenAnswer((_) async => fixturePortafolioInicial);
      when(() => client.fetchEvaluacionesHtml('117967'))
          .thenAnswer((_) async => fixtureEvaluaciones);
      await engine.runCycle1(loadCredentials: fakeCreds);

      // Nueva actividad en foro
      when(() => client.fetchInternoHtml())
          .thenAnswer((_) async => fixtureInternoConBadges);
      when(() => client.fetchContenidosHtml('117967'))
          .thenAnswer((_) async => fixtureContenidosConNovedad);
      when(() => client.fetchMensajeriaEntradaHtml('117967'))
          .thenAnswer((_) async => fixtureMensajeriaVacia);
      when(() => client.fetchForoTemasHtml('117967'))
          .thenAnswer((_) async => fixtureForoTemasConActividad);
      when(() => client.fetchForoMensajesHtml('117967', '229745'))
          .thenAnswer((_) async => fixtureForoMensajesHilo);

      final summary = await engine.runCycle1(loadCredentials: fakeCreds);
      final foroNotifs = summary.notifications
          .where((n) => n.module == MielModuleType.foros)
          .toList();

      expect(foroNotifs, hasLength(1));
      expect(foroNotifs.first.title, contains('docente te respondió'));
      expect(foroNotifs.first.body, contains('DOCENTE, UNO'));
    });

    test(
      'Error de login estado 3 pausa inmediatamente el polling automático',
      () async {
        when(() => client.isLogged()).thenAnswer((_) async => false);
        when(() => client.login('00000000', 'secret')).thenAnswer(
          (_) async => const MielLoginResult(
            status: MielAuthStatus.accountBlocked,
            rawCode: 3,
            message: 'Tu cuenta de MIEL figura bloqueada (estado 3).',
          ),
        );

        final first = await engine.runCycle1(loadCredentials: fakeCreds);
        expect(first.authPaused, isTrue);
        expect(first.notifications, hasLength(1));
        expect(first.notifications.first.module, MielModuleType.sistema);

        // Segundo ciclo automático NO debe volver a intentar login ni llamar a MIEL
        final second = await engine.runCycle1(loadCredentials: fakeCreds);
        expect(second.authPaused, isTrue);
        expect(second.notifications, isEmpty);
        verify(() => client.login('00000000', 'secret')).called(1);
      },
    );

    test('Ciclo 1 poda materias residuales que ya no existen en /principal/interno/', () async {
      // Simula materia residual de otra cuenta o cuatrimestre previo
      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '888888',
          name: 'MATERIA DE OTRA CUENTA',
          commissionCode: '01-9999',
          isHidden: false,
        ),
        fixedNow,
      );
      await db.replaceTeachersForSubject('888888', const [
        CourseTeacher(
          name: 'DOCENTE, VIEJO',
          normalizedName: 'docente, viejo',
          role: 'Tutor/a',
        ),
      ], fixedNow);

      when(() => client.isLogged()).thenAnswer((_) async => true);
      when(() => client.fetchInternoHtml())
          .thenAnswer((_) async => fixtureInternoConBadges);
      when(() => client.fetchMensajeriaEntradaHtml('117967'))
          .thenAnswer((_) async => fixtureMensajeriaVacia);
      when(() => client.fetchForoTemasHtml('117967'))
          .thenAnswer((_) async => fixtureForoTemasInicial);
      when(() => client.fetchPortafolioPracticasHtml('117967'))
          .thenAnswer((_) async => fixturePortafolioInicial);
      when(() => client.fetchEvaluacionesHtml('117967'))
          .thenAnswer((_) async => fixtureEvaluaciones);

      await engine.runCycle1(loadCredentials: fakeCreds);

      final allSubjects = await db.getAllSubjects();
      expect(allSubjects.map((s) => s.idComision), ['117967']);
      expect(await db.getTeachersForSubject('888888'), isEmpty);
    });

    test('AppDatabase.clearAccountData limpia datos de la cuenta previa preservando preferencias globales', () async {
      await db.setSetting(SettingKeys.themeMode, 'dark');
      await db.setSetting(SettingKeys.syncIntervalMinutes, '30');
      await db.setSetting(SettingKeys.accountUsername, 'cuenta_a');
      await db.setSetting(SettingKeys.studentName, 'ALUMNO, A');
      await db.setSetting(
        SettingKeys.studentAvatarUrl,
        'https://miel.unlam.edu.ar/data2/avatares/a.jpg',
      );
      await db.setSetting(SettingKeys.baselineCompleted, 'true');
      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '777777',
          name: 'MATERIA CUENTA A',
          commissionCode: '01-1000',
          isHidden: false,
        ),
        fixedNow,
      );

      await db.clearAccountData();

      expect(await db.getAllSubjects(), isEmpty);
      expect(await db.getSetting(SettingKeys.accountUsername), isNull);
      expect(await db.getSetting(SettingKeys.studentName), isNull);
      expect(await db.getSetting(SettingKeys.studentAvatarUrl), isNull);
      expect(await db.isBaselineCompleted(), isFalse);
      // Preferencias globales preservadas
      expect(await db.getSetting(SettingKeys.themeMode), 'dark');
      expect(await db.getSyncIntervalMinutes(), 30);
    });
  });
}
