import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final controller = ref.read(appSessionProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Sincronización',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Frecuencia de comprobación (Ciclo 1)'),
                subtitle: const Text(
                  'En Android el mínimo del sistema es 15 min para cuidar la batería.',
                ),
                trailing: DropdownButton<int>(
                  value:
                      const [15, 30, 60].contains(session.syncIntervalMinutes)
                      ? session.syncIntervalMinutes
                      : 15,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('Cada 15 min')),
                    DropdownMenuItem(value: 30, child: Text('Cada 30 min')),
                    DropdownMenuItem(value: 60, child: Text('Cada 60 min')),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.updateSyncInterval(v);
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.quiz_outlined),
                title: const Text('Monitorear Evaluaciones abiertas'),
                subtitle: const Text(
                  'Revisa periódicamente la sección Evaluación en materias que la habilitan.',
                ),
                value: session.monitorEvaluaciones,
                onChanged: controller.updateMonitorEvaluaciones,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Comportamiento en Foros',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: RadioGroup<ForumSyncMode>(
            groupValue: session.forumSyncMode,
            onChanged: (mode) {
              if (mode != null) controller.updateForumSyncMode(mode);
            },
            child: const Column(
              children: [
                RadioListTile<ForumSyncMode>(
                  value: ForumSyncMode.nonInvasive,
                  title: Text('Modo no invasivo (recomendado)'),
                  subtitle: Text(
                    'Avisa qué tema tuvo actividad nueva sin abrir el hilo. '
                    'Conserva intactos los contadores de no leídos en MIEL web.',
                  ),
                ),
                Divider(height: 1),
                RadioListTile<ForumSyncMode>(
                  value: ForumSyncMode.teacherReplies,
                  title: Text('Modo respuestas de docentes'),
                  subtitle: Text(
                    'Inspecciona los hilos con actividad para avisarte específicamente '
                    'cuando un docente te responde. Nota: al abrir el hilo, MIEL web marca '
                    'ese tema como leído.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Cuenta y Datos Locales',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Forzar sincronización completa ahora'),
                subtitle: const Text(
                  'Ejecuta Ciclo 1 (panel) y Ciclo 2 (Portafolio/Evaluación).',
                ),
                onTap: session.isSyncing
                    ? null
                    : () => controller.syncNow(
                        includeCycle2: true,
                        ignoreAuthPause: true,
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'Elimina credenciales del llavero y detiene alertas.',
                ),
                onTap: () => controller.logout(wipeLocalData: false),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Cerrar sesión y borrar historial local',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'Limpia también snapshots, materias y novedades guardadas.',
                ),
                onTap: () => controller.logout(wipeLocalData: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
