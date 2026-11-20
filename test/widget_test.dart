import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/theme/miel_theme.dart';
import 'package:libremiel/features/auth/login_screen.dart';
import 'package:libremiel/features/home/home_shell.dart';
import 'package:material_ui/material_ui.dart';

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
  Future<void> updateLaunchAtStartup(bool enabled) async {
    state = state.copyWith(launchAtStartup: enabled);
  }
}

void main() {
  testWidgets(
    'LoginScreen replica estética MIeL con fondo animado y aviso de privacidad local',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildMielLightTheme(),
            home: const LoginScreen(),
          ),
        ),
      );

      // Avanzar la animación del fondo sin errores
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LibreMIEL'), findsOneWidget);
      expect(find.text('Usuario:'), findsOneWidget);
      expect(find.text('Contraseña:'), findsOneWidget);
      expect(find.text('Mantener mi sesión activa.'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.textContaining('miel.unlam.edu.ar'), findsWidgets);
    },
  );

  testWidgets(
    'HomeShell aplica personalizaciones (sin Chat ni ítems sobrantes, Mi perfil, organizar/ocultar, autostart y borrador Fase 2)',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '117967',
          name: 'Fundamentos de Sistemas Embebidos',
          subjectCode: '3631',
          commissionCode: '01-1300',
          roleLabel: 'Alumno/a',
          isHidden: false,
          contenidosBadge: 2,
          mensajesBadge: 1,
          foroBadge: 0,
          hasContenidos: true,
          hasPortafolio: true,
          hasMensajeria: true,
          hasForo: true,
          hasChat: true,
          hasEvaluacion: true,
        ),
        DateTime(2026, 11, 20),
      );

      await db.insertNotificationIfNew(
        DetectedNotification(
          dedupeKey: 'test:1',
          idComision: '117967',
          subjectName: 'Fundamentos de Sistemas Embebidos',
          module: MielModuleType.contenidos,
          title: 'Nuevo archivo en Contenidos',
          body: 'Se publicó Guía TP 2',
          targetUrl:
              'https://miel.unlam.edu.ar/contenido/archivos/comision/117967',
          detectedAt: DateTime(2026, 11, 20, 14, 30),
        ),
      );

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
                  autostartSupported: true,
                ),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final session = ref.watch(appSessionProvider);
              return MaterialApp(
                themeMode: session.themeMode,
                theme: buildMielLightTheme(),
                darkTheme: buildMielDarkTheme(),
                home: const HomeShell(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica barra superior con Mi perfil (sin Ajustes) y barra lateral limpia
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Calendario'), findsNothing);
      expect(find.text('Biblioteca BiDi'), findsNothing);
      expect(find.text('Tutoriales'), findsNothing);
      expect(find.text('Preguntas frecuentes'), findsNothing);

      // Verifica materia sin botón Chat
      expect(find.text('Fundamentos de Sistemas Embebidos'), findsOneWidget);
      expect(find.text('3631 - Com: 01-1300 - Alumno/a'), findsOneWidget);
      expect(find.text('Contenidos'), findsOneWidget);
      expect(find.text('Portafolio'), findsOneWidget);
      expect(find.text('Mensajes'), findsOneWidget);
      expect(find.text('Foro'), findsOneWidget);
      expect(find.text('Evaluación'), findsOneWidget);
      expect(find.text('Chat'), findsNothing);

      // Abrir modal Mi perfil desde la barra superior
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Perfil en MIeL'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // Modo Organizar materias: aparece drag_handle y botón ocultar (close)
      await tester.tap(find.text('Organizar materias'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ocultar materia localmente y verificar que aparece "Ver materias ocultas" junto al botón
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Ver materias ocultas'), findsOneWidget);

      // Desplegar materias ocultas y volver a mostrar la materia
      await tester.tap(find.text('Ver materias ocultas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finalizar organización'));
      await tester.pumpAndSettle();

      // Abrir módulo Contenidos en modo borrador (Fase 2)
      await tester.tap(find.text('Contenidos'));
      await tester.pumpAndSettle();
      expect(find.text('BORRADOR · FASE 2'), findsOneWidget);
      expect(find.text('Abrir Contenidos en MIeL'), findsOneWidget);

      // Abrir Novedades desde la campana en la barra verde superior
      await tester.tap(find.byIcon(Icons.notifications_active).first);
      await tester.pumpAndSettle();
      expect(find.text('Nuevo archivo en Contenidos'), findsOneWidget);

      // Abrir Alertas y ajustes desde sidebar y verificar opción de inicio del sistema
      await tester.tap(find.text('Alertas y ajustes'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ejecutar LibreMIEL al iniciar el sistema'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeShell se renderiza sin desbordes en viewport móvil (390×844) con botón de usuario',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '117968',
          name: 'Análisis Matemático I',
          subjectCode: '3622',
          commissionCode: '12-6300',
          roleLabel: 'Alumno/a',
          isHidden: false,
          hasContenidos: true,
          hasAutoguia: true,
          hasPortafolio: true,
          hasMensajeria: true,
          hasForo: true,
          hasChat: true,
          hasEvaluacion: true,
        ),
        DateTime(2026, 11, 20),
      );

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
          child: MaterialApp(
            theme: buildMielDarkTheme(),
            home: const HomeShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Materias activas'), findsOneWidget);
      expect(find.text('Análisis Matemático I'), findsOneWidget);
      expect(find.text('Chat'), findsNothing);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
