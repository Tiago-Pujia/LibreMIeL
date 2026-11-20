import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../core/storage/app_database.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error al cargar materias: $err')),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No hay materias sincronizadas todavía.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(appSessionProvider.notifier)
                        .syncNow(includeCycle2: true),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sincronizar ahora'),
                  ),
                ],
              ),
            ),
          );
        }

        final visible = subjects.where((s) => !s.isHiddenInMiel).toList();
        final hidden = subjects.where((s) => s.isHiddenInMiel).toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final subject in visible) _SubjectTile(subject: subject),
            if (hidden.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Materias ocultas en MIEL (${hidden.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final subject in hidden) _SubjectTile(subject: subject),
            ],
          ],
        );
      },
    );
  }
}

class _SubjectTile extends ConsumerWidget {
  const _SubjectTile({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final subtitleParts = <String>[
      if (subject.commissionCode.isNotEmpty) 'Com: ${subject.commissionCode}',
      if (subject.lastContenidosBadge > 0)
        'Contenidos (${subject.lastContenidosBadge})',
      if (subject.lastMensajesBadge > 0)
        'Mensajes (${subject.lastMensajesBadge})',
      if (subject.lastForoBadge > 0) 'Foro (${subject.lastForoBadge})',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          subject.muted
              ? Icons.notifications_off_outlined
              : Icons.notifications_active_outlined,
          color: subject.muted
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(subject.name),
        subtitle: subtitleParts.isNotEmpty
            ? Text(subtitleParts.join(' · '))
            : null,
        trailing: Switch(
          value: !subject.muted,
          onChanged: (active) => db.updateSubjectPreferences(
            idComision: subject.idComision,
            muted: !active,
          ),
        ),
        children: [
          SwitchListTile(
            dense: true,
            title: const Text('Contenidos'),
            value: subject.notifyContenidos,
            onChanged: subject.muted
                ? null
                : (v) => db.updateSubjectPreferences(
                    idComision: subject.idComision,
                    notifyContenidos: v,
                  ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Portafolio (prácticas y correcciones)'),
            value: subject.notifyPortafolio,
            onChanged: subject.muted
                ? null
                : (v) => db.updateSubjectPreferences(
                    idComision: subject.idComision,
                    notifyPortafolio: v,
                  ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Mensajería'),
            value: subject.notifyMensajeria,
            onChanged: subject.muted
                ? null
                : (v) => db.updateSubjectPreferences(
                    idComision: subject.idComision,
                    notifyMensajeria: v,
                  ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Foros'),
            value: subject.notifyForos,
            onChanged: subject.muted
                ? null
                : (v) => db.updateSubjectPreferences(
                    idComision: subject.idComision,
                    notifyForos: v,
                  ),
          ),
          if (subject.hasEvaluacion)
            SwitchListTile(
              dense: true,
              title: const Text('Evaluaciones'),
              value: subject.notifyEvaluacion,
              onChanged: subject.muted
                  ? null
                  : (v) => db.updateSubjectPreferences(
                      idComision: subject.idComision,
                      notifyEvaluacion: v,
                    ),
            ),
        ],
      ),
    );
  }
}
