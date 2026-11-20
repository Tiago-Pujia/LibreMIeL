import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/storage/app_database.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String? _selectedModule;

  static const _filters = <(String?, String)>[
    (null, 'Todo'),
    ('contenidos', 'Contenidos'),
    ('portafolio', 'Portafolio'),
    ('mensajeria', 'Mensajería'),
    ('foros', 'Foros'),
    ('evaluacion', 'Evaluación'),
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final notificationsAsync = ref.watch(
      notificationsStreamProvider(_selectedModule),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (key, label) in _filters)
                FilterChip(
                  label: Text(label),
                  selected: _selectedModule == key,
                  onSelected: (_) => setState(() => _selectedModule = key),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () =>
                    ref.read(databaseProvider).markAllNotificationsRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Marcar todo leído'),
              ),
            ],
          ),
        ),
        if (session.lastSyncMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              session.lastSyncMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Error al leer novedades: $err')),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Todavía no hay novedades registradas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cuando un docente publique en Contenidos, Portafolio, '
                          'Mensajería o Foros aparecerá acá.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(appSessionProvider.notifier)
                    .syncNow(includeCycle2: true),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _NotificationCard(item: items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item});

  final NotificationLog item;

  IconData _iconForModule(String module) {
    if (module == MielModuleType.contenidos.name) {
      return Icons.folder_outlined;
    }
    if (module == MielModuleType.portafolio.name) {
      return Icons.assignment_turned_in_outlined;
    }
    if (module == MielModuleType.mensajeria.name) {
      return Icons.mail_outline;
    }
    if (module == MielModuleType.foros.name) {
      return Icons.forum_outlined;
    }
    if (module == MielModuleType.evaluacion.name) {
      return Icons.quiz_outlined;
    }
    if (module == MielModuleType.novedades.name) {
      return Icons.campaign_outlined;
    }
    return Icons.info_outline;
  }

  Future<void> _openTarget(WidgetRef ref) async {
    await ref.read(databaseProvider).markNotificationRead(item.id);
    final uri = Uri.tryParse(item.targetUrl);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dt = item.createdAt.toLocal();
    final timeStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      color: item.isRead
          ? null
          : theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isRead
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primaryContainer,
          child: Icon(_iconForModule(item.module)),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${item.body}\n$timeStr'),
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Abrir en MIEL',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => _openTarget(ref),
        ),
        onTap: () => _openTarget(ref),
      ),
    );
  }
}
