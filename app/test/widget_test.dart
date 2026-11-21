import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/app/app_providers.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/theme/miel_theme.dart';
import 'package:libremiel/features/auth/login_screen.dart';
import 'package:libremiel/features/home/home_shell.dart';
import 'package:libremiel/features/modules/module_providers.dart';
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

      expect(find.text('LibreMIeL'), findsOneWidget);
      expect(find.text('Usuario:'), findsOneWidget);
      expect(find.text('Contraseña:'), findsOneWidget);
      expect(find.text('Olvidé mi contraseña'), findsOneWidget);
      expect(find.text('Sesión permanente activa.'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.textContaining('miel.unlam.edu.ar'), findsWidgets);
    },
  );

  testWidgets(
    'HomeShell aplica estructura personalizada (sidebar, sin Sincronizar arriba, campana + ⋮ MIeL, organizar vertical, autostart y borrador Fase 2)',
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

      await db.replaceTeachersForSubject('117967', const [
        CourseTeacher(
          name: 'DOCENTE, UNO',
          normalizedName: 'docente, uno',
          role: 'Tutor/a',
        ),
      ], DateTime(2026, 11, 20));

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
            courseDetailsProvider('117967').overrideWith(
              (ref) async => const CourseDetails(
                idComision: '117967',
                term: '2C 2026',
                modality: 'Presencial',
                classroom: 'Lab 2',
                teachers: [
                  CourseTeacher(
                    name: 'DOCENTE, UNO',
                    normalizedName: 'docente, uno',
                    role: 'Tutor/a',
                  ),
                ],
              ),
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

      // Barra superior superior: Mi perfil · Cerrar sesión (sin Sincronizar)
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Sincronizar'), findsNothing);

      // Barra lateral exacta: Utilidades (Materias Activas), Funcionalidades (Ajustes, Notificaciones), Repositorio GitHub, Abrir MIeL web
      expect(find.text('Utilidades'), findsOneWidget);
      expect(find.text('Materias Activas'), findsOneWidget);
      expect(find.text('Funcionalidades'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Repositorio GitHub'), findsOneWidget);
      expect(find.text('Abrir MIeL web'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Repositorio GitHub')).dy,
        lessThan(tester.getTopLeft(find.text('Abrir MIeL web')).dy),
      );
      expect(find.text('Calendario'), findsNothing);
      expect(find.text('Biblioteca BiDi'), findsNothing);

      // Tarjeta sin botón Chat, con campana al lado de los 3 puntitos
      expect(find.text('Fundamentos de Sistemas Embebidos'), findsOneWidget);
      expect(find.text('Chat'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Los 3 puntitos (⋮) abren el detalle oficial de MIeL (cursoDetalles)
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de la comisión'), findsOneWidget);
      expect(find.text('2C 2026'), findsOneWidget);
      expect(find.text('DOCENTE, UNO (Tutor/a)'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // La campana al lado de los 3 puntitos abre la configuración de notificaciones de la materia
      await tester.tap(find.byTooltip('Notificaciones de esta materia'));
      await tester.pumpAndSettle();
      expect(find.text('Notificaciones de esta materia'), findsOneWidget);
      expect(find.text('Recibir alertas de esta materia'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // Organizar materias mantiene el texto "Organizar materias" y muestra drag_handle + close en vertical
      await tester.tap(find.text('Organizar materias'));
      await tester.pumpAndSettle();
      expect(find.text('Organizar materias'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ocultar materia, ver materias ocultas junto al botón y restaurarla
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Ver materias ocultas'), findsOneWidget);

      await tester.tap(find.text('Ver materias ocultas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Salir de modo organizar con el mismo botón "Organizar materias"
      await tester.tap(find.text('Organizar materias'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Abrir vista nativa Fase 2 (Contenidos)
      await tester.tap(find.text('Contenidos'));
      await tester.pumpAndSettle();
      expect(find.text('Archivos'), findsWidgets);
      expect(find.text('Tipo de archivo:'), findsOneWidget);
      expect(find.text('Palabra clave:'), findsOneWidget);

      // Abrir Notificaciones desde Funcionalidades en el sidebar
      await tester.tap(find.byIcon(Icons.home).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo archivo en Contenidos'), findsOneWidget);

      // Abrir Ajustes desde Funcionalidades en el sidebar y verificar autostart (sin Apariencia)
      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Apariencia'), findsNothing);
      expect(
        find.text('Ejecutar LibreMIeL al iniciar el sistema'),
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
