import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/features/home/home_shell.dart';
import 'package:libremiel/features/modules/module_providers.dart';
import 'package:libremiel/platform/android_widget_service.dart';
import 'package:libremiel/platform/notification_service.dart';
import 'package:libremiel/platform/secure_credentials_store.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockWidgetService extends Mock implements AndroidWidgetService {}

class _MockMielClient extends Mock implements MielApiClient {}

class _MockCredsStore extends Mock implements SecureCredentialsStore {}

class _MockNotifService extends Mock implements NotificationService {}

class _TestableSessionController extends AppSessionController {
  _TestableSessionController(this._initial);
  final AppSessionState _initial;

  @override
  AppSessionState build() => _initial;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MielSubjectBadgeSummary(
        idComision: '0',
        name: 'Fallback',
        commissionCode: '0',
        isHidden: false,
      ),
    );
  });

  group('Phase 10 Android Widget integration', () {
    test('AppSessionController.logout() llama a clearSnapshot() para proteger privacidad', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final mockClient = _MockMielClient();
      final mockCreds = _MockCredsStore();
      final mockWidget = _MockWidgetService();

      when(() => mockClient.clearSession()).thenAnswer((_) async {});
      when(() => mockCreds.clear()).thenAnswer((_) async {});
      when(() => mockWidget.isSupported).thenReturn(true);
      when(() => mockWidget.clearSnapshot()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          mielClientProvider.overrideWith((_) async => mockClient),
          credentialsStoreProvider.overrideWithValue(mockCreds),
          androidWidgetServiceProvider.overrideWithValue(mockWidget),
          appSessionProvider.overrideWith(
            () => _TestableSessionController(
              const AppSessionState(
                isChecking: false,
                isAuthenticated: true,
                studentName: 'ESTUDIANTE, DEMO',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appSessionProvider.notifier).logout();

      expect(container.read(appSessionProvider).isAuthenticated, isFalse);
      verify(() => mockWidget.clearSnapshot()).called(1);
    });

    testWidgets(
      'HomeShell enruta deep-links desde AndroidWidgetService (cold start + warm start) y marca leída la notificación',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 840);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await db.upsertSubjectFromInterno(
          const MielSubjectBadgeSummary(
            idComision: '117967',
            name: 'Sistemas Embebidos',
            subjectCode: '3631',
            commissionCode: '01-1300',
            roleLabel: 'Alumno/a',
            isHidden: false,
            hasContenidos: true,
            hasMensajeria: true,
            hasForo: true,
          ),
          DateTime(2026, 11, 23),
        );

        await db.insertNotificationIfNew(
          DetectedNotification(
            dedupeKey: 'widget_tap_msg_1',
            idComision: '117967',
            subjectName: 'Sistemas Embebidos',
            module: MielModuleType.mensajeria,
            title: 'DOCENTE, UNO (Docente)',
            body: 'Aviso importante',
            targetUrl:
                'https://miel.unlam.edu.ar/mensajeria/entrada/comision/117967',
            detectedAt: DateTime(2026, 11, 23, 14, 0),
          ),
        );
        final inserted = (await db.getRecentNotifications(limit: 1)).single;
        expect(inserted.isRead, isFalse);

        final mockWidget = _MockWidgetService();
        when(() => mockWidget.isSupported).thenReturn(true);
        when(
          () => mockWidget.initialize(
            forceRegisterHandler: any(named: 'forceRegisterHandler'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockWidget.consumeInitialTapPayload()).thenAnswer(
          (_) async => NotificationTapPayload(
            idComision: '117967',
            module: 'mensajeria',
            targetUrl:
                'https://miel.unlam.edu.ar/mensajeria/entrada/comision/117967',
            notificationId: inserted.id,
          ),
        );

        final mockNotif = _MockNotifService();
        when(() => mockNotif.getLaunchDetails()).thenAnswer((_) async => null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              notificationServiceProvider.overrideWithValue(mockNotif),
              androidWidgetServiceProvider.overrideWithValue(mockWidget),
              mensajeriaBandejaProvider((
                idComision: '117967',
                box: MensajeriaBoxKind.entrada,
                page: 1,
              )).overrideWith(
                (ref) async => const MessageBoxPageData(
                  idComision: '117967',
                  currentPage: 1,
                  totalPages: 1,
                  messages: [],
                ),
              ),
              foroTemasProvider('117967')
                  .overrideWith((ref) async => const <ForumTopicSummary>[]),
              foroMensajesProvider((
                idComision: '117967',
                idTema: '999',
                unreadBadge: 0,
              )).overrideWith(
                (ref) async => const ForumThreadData(
                  idComision: '117967',
                  idTema: '999',
                  title: 'Consultas TP 2',
                  currentUserId: '1',
                  messages: [],
                ),
              ),
              appSessionProvider.overrideWith(
                () => _TestableSessionController(
                  const AppSessionState(
                    isChecking: false,
                    isAuthenticated: true,
                    studentName: 'ESTUDIANTE, DEMO',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: HomeShell()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Cold start abrió Mensajería de la comisión 117967 y marcó leída la notificación
        expect(find.text('Mensajería'), findsWidgets);
        expect(find.textContaining('Sistemas Embebidos'), findsWidgets);
        final updatedLog = (await db.getRecentNotifications(limit: 1)).single;
        expect(updatedLog.isRead, isTrue);

        // 2. Warm start desde el stream de widget hacia un tema específico de Foros
        AndroidWidgetService.onWidgetTapped.add(
          const NotificationTapPayload(
            idComision: '117967',
            module: 'foros',
            targetUrl: 'https://miel.unlam.edu.ar/forov2/mensajes/comision/117967/tema/999',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Consultas TP 2'), findsWidgets);

        // 3. Warm start hacia Inicio ("home")
        AndroidWidgetService.onWidgetTapped.add(
          const NotificationTapPayload(
            idComision: 'home',
            module: 'home',
            targetUrl: '',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Materias activas'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });
}
