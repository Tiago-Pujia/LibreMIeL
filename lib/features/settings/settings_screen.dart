import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/theme/miel_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final session = ref.watch(appSessionProvider);
    final controller = ref.read(appSessionProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Alertas y ajustes',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),

                // Apariencia (Claro / Oscuro / Sistema)
                _SectionHeader(title: 'Apariencia', palette: palette),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema de la interfaz (también podés cambiarlo rápido con el ícono de contraste en la barra verde).',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ThemeChoiceButton(
                              label: 'Automático',
                              icon: Icons.brightness_auto,
                              selected: session.themeMode == ThemeMode.system,
                              onTap: () =>
                                  controller.updateThemeMode(ThemeMode.system),
                            ),
                            _ThemeChoiceButton(
                              label: 'Modo claro',
                              icon: Icons.light_mode,
                              selected: session.themeMode == ThemeMode.light,
                              onTap: () =>
                                  controller.updateThemeMode(ThemeMode.light),
                            ),
                            _ThemeChoiceButton(
                              label: 'Modo oscuro',
                              icon: Icons.dark_mode,
                              selected: session.themeMode == ThemeMode.dark,
                              onTap: () =>
                                  controller.updateThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Inicio con el sistema
                _SectionHeader(title: 'Inicio del sistema', palette: palette),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: session.autostartSupported
                      ? SwitchListTile(
                          secondary: Icon(
                            Icons.power_settings_new,
                            color: palette.linkAccent,
                          ),
                          title: const Text(
                            'Ejecutar LibreMIEL al iniciar el sistema',
                          ),
                          subtitle: Text(
                            'Inicia la aplicación automáticamente al encender tu equipo '
                            'para recibir notificaciones en segundo plano.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                          value: session.launchAtStartup,
                          onChanged: controller.updateLaunchAtStartup,
                        )
                      : ListTile(
                          leading: Icon(
                            Icons.power_settings_new,
                            color: palette.linkAccent,
                          ),
                          title: const Text(
                            'Inicio automático en segundo plano',
                          ),
                          subtitle: Text(
                            'En Android, la sincronización periódica se reanuda '
                            'automáticamente tras reiniciar el dispositivo.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Sincronización
                _SectionHeader(title: 'Sincronización', palette: palette),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.schedule,
                          color: palette.linkAccent,
                        ),
                        title: const Text(
                          'Frecuencia de comprobación (Ciclo 1)',
                        ),
                        subtitle: Text(
                          'En Android el mínimo del sistema es 15 min para cuidar la batería.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        trailing: DropdownButton<int>(
                          value:
                              const [
                                15,
                                30,
                                60,
                              ].contains(session.syncIntervalMinutes)
                              ? session.syncIntervalMinutes
                              : 15,
                          dropdownColor: palette.dropdownBackground,
                          items: const [
                            DropdownMenuItem(
                              value: 15,
                              child: Text('Cada 15 min'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('Cada 30 min'),
                            ),
                            DropdownMenuItem(
                              value: 60,
                              child: Text('Cada 60 min'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) controller.updateSyncInterval(v);
                          },
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.assignment_turned_in,
                          color: palette.linkAccent,
                        ),
                        title: const Text('Monitorear Evaluaciones abiertas'),
                        subtitle: Text(
                          'Revisa periódicamente la sección Evaluación en materias que la habilitan.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        value: session.monitorEvaluaciones,
                        onChanged: controller.updateMonitorEvaluaciones,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Comportamiento en Foros
                _SectionHeader(
                  title: 'Comportamiento en Foros',
                  palette: palette,
                ),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: RadioGroup<ForumSyncMode>(
                    groupValue: session.forumSyncMode,
                    onChanged: (mode) {
                      if (mode != null) controller.updateForumSyncMode(mode);
                    },
                    child: Column(
                      children: [
                        RadioListTile<ForumSyncMode>(
                          value: ForumSyncMode.nonInvasive,
                          activeColor: palette.primary,
                          title: const Text('Modo no invasivo (recomendado)'),
                          subtitle: Text(
                            'Avisa qué tema tuvo actividad nueva sin abrir el hilo. '
                            'Conserva intactos los contadores de no leídos en MIeL web.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                        Divider(height: 1, color: palette.divider),
                        RadioListTile<ForumSyncMode>(
                          value: ForumSyncMode.teacherReplies,
                          activeColor: palette.primary,
                          title: const Text('Modo respuestas de docentes'),
                          subtitle: Text(
                            'Inspecciona los hilos con actividad para avisarte específicamente '
                            'cuando un docente te responde. Nota: al abrir el hilo, MIeL web marca '
                            'ese tema como leído.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Cuenta y Datos Locales
                _SectionHeader(
                  title: 'Cuenta y Datos Locales',
                  palette: palette,
                ),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.key_outlined,
                          color: palette.linkAccent,
                        ),
                        title: const Text('Almacenamiento de credenciales'),
                        subtitle: Text(
                          ref
                              .read(credentialsStoreProvider)
                              .storageBackendLabel,
                          style: TextStyle(color: palette.textMuted),
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      ListTile(
                        leading: Icon(Icons.sync, color: palette.linkAccent),
                        title: const Text(
                          'Forzar sincronización completa ahora',
                        ),
                        subtitle: Text(
                          'Ejecuta Ciclo 1 (panel) y Ciclo 2 (Portafolio/Evaluación).',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        onTap: session.isSyncing
                            ? null
                            : () => controller.syncNow(
                                includeCycle2: true,
                                ignoreAuthPause: true,
                              ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      ListTile(
                        leading: Icon(Icons.logout, color: palette.badgeRed),
                        title: Text(
                          'Cerrar sesión',
                          style: TextStyle(color: palette.badgeRed),
                        ),
                        subtitle: Text(
                          'Elimina credenciales del llavero y detiene alertas.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        onTap: () => controller.logout(wipeLocalData: false),
                      ),
                      Divider(height: 1, color: palette.divider),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          color: palette.badgeRed,
                        ),
                        title: Text(
                          'Cerrar sesión y borrar historial local',
                          style: TextStyle(color: palette.badgeRed),
                        ),
                        subtitle: Text(
                          'Limpia también snapshots, materias y novedades guardadas.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        onTap: () => controller.logout(wipeLocalData: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.palette});

  final String title;
  final MielPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: palette.linkAccent,
      ),
    );
  }
}

class _MielPanel extends StatelessWidget {
  const _MielPanel({required this.palette, required this.child});

  final MielPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(color: palette.cardBorder),
      ),
      child: child,
    );
  }
}

class _ThemeChoiceButton extends StatelessWidget {
  const _ThemeChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Material(
      color: selected ? palette.primary : palette.pageBackground,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: selected ? palette.primary : palette.inputBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : palette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? Colors.white : palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
