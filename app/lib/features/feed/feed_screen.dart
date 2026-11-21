import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/miel_theme.dart';

/// Feed unificado de notificaciones de LibreMIeL estilizado con la estética de MIeL
/// (encabezado h1 Light, botones planos y filas no leídas estilo `.mensaje-no-leido`).
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, this.onOpenSubjectModule});

  final void Function(String idComision, MielToolKind tool)?
  onOpenSubjectModule;

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
    final palette = MielPalette.of(context);
    final session = ref.watch(appSessionProvider);
    final notificationsAsync = ref.watch(
      notificationsStreamProvider(_selectedModule),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final hPad = isCompact ? 16.0 : 26.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Novedades',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      Material(
                        color: palette.buttonSecondaryBackground,
                        borderRadius: BorderRadius.circular(3),
                        child: InkWell(
                          onTap: () => ref
                              .read(databaseProvider)
                              .markAllNotificationsRead(),
                          borderRadius: BorderRadius.circular(3),
                          hoverColor: palette.buttonSecondaryHover,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.done_all,
                                  size: 16,
                                  color: palette.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isCompact
                                      ? 'Todo leído'
                                      : 'Marcar todo como leído',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (session.lastSyncMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.lastSyncMessage!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (key, label) in _filters)
                        _MielFilterButton(
                          label: label,
                          selected: _selectedModule == key,
                          onTap: () => setState(() => _selectedModule = key),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: palette.divider, height: 1),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error al leer novedades: $err')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 460),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: palette.cardBackground,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                size: 46,
                                color: palette.textMuted,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Todavía no hay novedades registradas',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cuando un docente publique en Contenidos, Portafolio, '
                                'Mensajería, Foros o Evaluaciones aparecerá acá.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: palette.primary,
                    onRefresh: () => ref
                        .read(appSessionProvider.notifier)
                        .syncNow(includeCycle2: true),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _MielNotificationRow(
                        item: items[index],
                        onOpenSubjectModule: widget.onOpenSubjectModule,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MielFilterButton extends StatelessWidget {
  const _MielFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Material(
      color: selected ? palette.primary : palette.buttonSecondaryBackground,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        hoverColor: selected
            ? palette.primaryHover
            : palette.buttonSecondaryHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? Colors.white : palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MielNotificationRow extends ConsumerWidget {
  const _MielNotificationRow({required this.item, this.onOpenSubjectModule});

  final NotificationLog item;
  final void Function(String idComision, MielToolKind tool)?
  onOpenSubjectModule;

  IconData _iconForModule(String module) {
    if (module == MielModuleType.contenidos.name) return Icons.import_contacts;
    if (module == MielModuleType.portafolio.name) return Icons.description;
    if (module == MielModuleType.mensajeria.name) return Icons.drafts;
    if (module == MielModuleType.foros.name) return Icons.forum;
    if (module == MielModuleType.evaluacion.name) {
      return Icons.assignment_turned_in;
    }
    if (module == MielModuleType.novedades.name) return Icons.campaign;
    return Icons.notifications;
  }

  MielToolKind? _toolForModule(String module) {
    if (module == MielModuleType.contenidos.name) {
      return MielToolKind.contenidos;
    }
    if (module == MielModuleType.portafolio.name) {
      return MielToolKind.portafolio;
    }
    if (module == MielModuleType.mensajeria.name) {
      return MielToolKind.mensajeria;
    }
    if (module == MielModuleType.foros.name) return MielToolKind.foro;
    if (module == MielModuleType.evaluacion.name) {
      return MielToolKind.evaluacion;
    }
    return null;
  }

  void _handleOpenNotification(
    WidgetRef ref, {
    required bool canOpenModule,
    required MielToolKind? linkedTool,
  }) {
    ref.read(databaseProvider).markNotificationRead(item.id);
    if (canOpenModule && linkedTool != null) {
      onOpenSubjectModule!(item.idComision, linkedTool);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final dt = item.createdAt.toLocal();
    final timeStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final unread = !item.isRead;
    final linkedTool = _toolForModule(item.module);
    final canOpenDraft =
        onOpenSubjectModule != null &&
        linkedTool != null &&
        item.idComision != 'global' &&
        item.idComision.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Material(
        color: unread ? palette.unreadBackground : palette.cardBackground,
        child: InkWell(
          onTap: () => _handleOpenNotification(
            ref,
            canOpenModule: canOpenDraft,
            linkedTool: linkedTool,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: unread ? palette.unreadBorder : palette.cardBorder,
                  width: unread ? 4 : 1,
                ),
                top: BorderSide(color: palette.cardBorder),
                right: BorderSide(color: palette.cardBorder),
                bottom: BorderSide(color: palette.cardBorder),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _iconForModule(item.module),
                    size: 22,
                    color: unread ? palette.linkAccent : palette.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: unread
                                    ? palette.linkAccent
                                    : palette.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subjectName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canOpenDraft) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Ver borrador del módulo',
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _handleOpenNotification(
                      ref,
                      canOpenModule: canOpenDraft,
                      linkedTool: linkedTool,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
