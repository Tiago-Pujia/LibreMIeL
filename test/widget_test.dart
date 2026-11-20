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
}

void main() {
  testWidgets(
    'LoginScreen replica estética MIeL con LibreMIEL y aviso de privacidad local',
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

      expect(find.text('LibreMIEL'), findsOneWidget);
      expect(find.text('Usuario:'), findsOneWidget);
      expect(find.text('Contraseña:'), findsOneWidget);
      expect(find.text('Mantener mi sesión activa.'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.textContaining('miel.unlam.edu.ar'), findsWidgets);
    },
  );

  testWidgets(
    'HomeShell muestra Materias activas estilo MIeL y navega a borrador Fase 2 y Novedades',
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

      // Verifica pantalla inicial fiel a /principal/interno/
      expect(find.text('Materias activas'), findsWidgets);
      expect(find.text('ESTUDIANTE, DEMO'), findsOneWidget);
      expect(find.text('Fundamentos de Sistemas Embebidos'), findsOneWidget);
      expect(find.text('3631 - Com: 01-1300 - Alumno/a'), findsOneWidget);
      expect(find.text('Contenidos'), findsOneWidget);
      expect(find.text('Portafolio'), findsOneWidget);
      expect(find.text('Mensajes'), findsOneWidget);
      expect(find.text('Foro'), findsOneWidget);
      expect(find.text('Evaluación'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Abrir módulo Contenidos en modo borrador (Fase 2)
      await tester.tap(find.text('Contenidos'));
      await tester.pumpAndSettle();

      expect(find.text('BORRADOR · FASE 2'), findsOneWidget);
      expect(find.text('Archivos'), findsWidgets);
      expect(find.text('Glosario'), findsOneWidget);
      expect(find.text('Abrir Contenidos en MIeL'), findsOneWidget);

      // Volver a inicio usando el botón Home de la barra verde
      await tester.tap(find.byIcon(Icons.home).first);
      await tester.pumpAndSettle();
      expect(find.text('Materias activas'), findsWidgets);

      // Abrir diálogo de detalle y configuración de alertas de la materia (⋮)
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Docentes (caché local)'), findsOneWidget);
      expect(find.text('Notificaciones de esta materia'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // Activar modo "Organizar materias"
      await tester.tap(find.text('Organizar materias'));
      await tester.pumpAndSettle();
      expect(find.text('Finalizar organización'), findsOneWidget);
      await tester.tap(find.text('Finalizar organización'));
      await tester.pumpAndSettle();

      // Cambiar tema claro <-> oscuro con brightness_4
      await tester.tap(find.byIcon(Icons.brightness_4));
      await tester.pumpAndSettle();

      // Abrir Novedades desde el menú lateral
      await tester.tap(find.text('Novedades').first);
      await tester.pumpAndSettle();
      expect(find.text('Nuevo archivo en Contenidos'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeShell se renderiza sin desbordes en viewport móvil (390×844)',
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
      expect(find.text('3622 - Com: 12-6300 - Alumno/a'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
