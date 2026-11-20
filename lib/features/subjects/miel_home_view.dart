import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/libremiel_brand.dart';
import '../../core/theme/miel_theme.dart';

/// Pantalla inicial fiel a `/principal/interno/` de MIeL ("Materias activas").
class MielHomeView extends ConsumerStatefulWidget {
  const MielHomeView({
    super.key,
    required this.onOpenModule,
    required this.onOpenNotifications,
  });

  final void Function(Subject subject, MielToolKind tool) onOpenModule;
  final VoidCallback onOpenNotifications;

  @override
  ConsumerState<MielHomeView> createState() => _MielHomeViewState();
}

class _MielHomeViewState extends ConsumerState<MielHomeView> {
  bool _organizeMode = false;
  bool _showHidden = false;

  Future<void> _openMielWeb() async {
    final uri = Uri.parse('$kMielBaseUrl/principal/interno/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openSubjectDetail(Subject subject) {
    showDialog<void>(
      context: context,
      builder: (_) => _SubjectDetailDialog(
        subject: subject,
        onOpenModule: (tool) {
          Navigator.of(context).pop();
          widget.onOpenModule(subject, tool);
        },
      ),
    );
  }

  Future<void> _reorderVisibleSubjects(
    List<Subject> visible,
    int oldIndex,
    int newIndex,
  ) async {
    final updated = List<Subject>.from(visible);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    await ref
        .read(databaseProvider)
        .updateSubjectsOrder(updated.map((s) => s.idComision).toList());
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final session = ref.watch(appSessionProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    final allSubjects = subjectsAsync.value ?? const <Subject>[];
    final hiddenCount = allSubjects.where((s) => s.isEffectivelyHidden).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final horizontalPadding = isCompact ? 16.0 : 26.0;

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (hiddenCount > 0)
              _HiddenSubjectsToggle(
                count: hiddenCount,
                expanded: _showHidden,
                onTap: () => setState(() => _showHidden = !_showHidden),
              ),
            _MielSecondaryButton(
              label: _organizeMode
                  ? 'Finalizar organización'
                  : 'Organizar materias',
              icon: _organizeMode ? Icons.check : null,
              active: _organizeMode,
              onPressed: () => setState(() => _organizeMode = !_organizeMode),
            ),
          ],
        );

        return RefreshIndicator(
          color: palette.primary,
          onRefresh: () => ref
              .read(appSessionProvider.notifier)
              .syncNow(includeCycle2: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera "Materias activas" + botones "Ver materias ocultas" y "Organizar materias" juntos
                if (isCompact) ...[
                  Text(
                    'Materias activas',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  actionButtons,
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Materias activas',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      actionButtons,
                    ],
                  ),
                ],

                if (_organizeMode) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: palette.unreadBackground,
                        border: Border(
                          left: BorderSide(color: palette.primary, width: 4),
                        ),
                      ),
                      child: Text(
                        'Modo organizar materias: arrastrá desde ≡ para reordenar, '
                        'usá ✕ para ocultar una materia o la campana para silenciar sus alertas.',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],

                // Aviso compacto de novedades sin leer (adaptación LibreMIEL)
                if (unreadCount > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Material(
                      color: palette.unreadBackground,
                      child: InkWell(
                        onTap: widget.onOpenNotifications,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: palette.unreadBorder,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                size: 18,
                                color: palette.linkAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  unreadCount == 1
                                      ? 'Tenés 1 novedad nueva detectada por LibreMIEL.'
                                      : 'Tenés $unreadCount novedades nuevas detectadas por LibreMIEL.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                'Ver novedades',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: palette.linkAccent,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: palette.linkAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                if (session.isSyncing) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    minHeight: 2,
                    color: palette.primary,
                    backgroundColor: palette.divider,
                  ),
                ],

                const SizedBox(height: 14),

                // Lista de tarjetas de materias (.materia-bloque)
                subjectsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Error al cargar materias: $err'),
                  ),
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      return _EmptySubjectsPlaceholder(
                        isSyncing: session.isSyncing,
                        lastSyncMessage: session.lastSyncMessage,
                        onSync: () => ref
                            .read(appSessionProvider.notifier)
                            .syncNow(includeCycle2: true),
                      );
                    }

                    final visible = subjects
                        .where((s) => !s.isEffectivelyHidden)
                        .toList();
                    final hidden = subjects
                        .where((s) => s.isEffectivelyHidden)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (visible.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: palette.cardBackground,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Text(
                              'Todas las materias están ocultas. Usá "Ver materias ocultas" '
                              'arriba para volver a mostrarlas.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: palette.textSecondary,
                              ),
                            ),
                          )
                        else if (_organizeMode)
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: visible.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                _reorderVisibleSubjects(
                                  visible,
                                  oldIndex,
                                  newIndex,
                                ),
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                color: Colors.transparent,
                                elevation: 6,
                                child: child,
                              );
                            },
                            itemBuilder: (context, index) {
                              final subject = visible[index];
                              return Padding(
                                key: ValueKey('vis_${subject.idComision}'),
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _MielSubjectCard(
                                  subject: subject,
                                  isCompact: isCompact,
                                  organizeMode: true,
                                  isHiddenCard: false,
                                  dragIndex: index,
                                  onOpenModule: (tool) =>
                                      widget.onOpenModule(subject, tool),
                                  onOpenDetail: () =>
                                      _openSubjectDetail(subject),
                                  onToggleMute: () => ref
                                      .read(databaseProvider)
                                      .updateSubjectPreferences(
                                        idComision: subject.idComision,
                                        muted: !subject.muted,
                                      ),
                                  onToggleHidden: () => ref
                                      .read(databaseProvider)
                                      .setSubjectLocalVisibility(
                                        subject.idComision,
                                        -1,
                                      ),
                                ),
                              );
                            },
                          )
                        else
                          for (final subject in visible) ...[
                            _MielSubjectCard(
                              subject: subject,
                              isCompact: isCompact,
                              organizeMode: false,
                              isHiddenCard: false,
                              onOpenModule: (tool) =>
                                  widget.onOpenModule(subject, tool),
                              onOpenDetail: () => _openSubjectDetail(subject),
                              onToggleMute: () => ref
                                  .read(databaseProvider)
                                  .updateSubjectPreferences(
                                    idComision: subject.idComision,
                                    muted: !subject.muted,
                                  ),
                              onToggleHidden: () => ref
                                  .read(databaseProvider)
                                  .setSubjectLocalVisibility(
                                    subject.idComision,
                                    -1,
                                  ),
                            ),
                            const SizedBox(height: 14),
                          ],

                        // Materias ocultas desplegadas (cuando el botón superior está activo)
                        if (_showHidden && hidden.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Materias ocultas (${hidden.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                          for (final subject in hidden) ...[
                            Opacity(
                              opacity: 0.76,
                              child: _MielSubjectCard(
                                subject: subject,
                                isCompact: isCompact,
                                organizeMode: _organizeMode,
                                isHiddenCard: true,
                                onOpenModule: (tool) =>
                                    widget.onOpenModule(subject, tool),
                                onOpenDetail: () => _openSubjectDetail(subject),
                                onToggleMute: () => ref
                                    .read(databaseProvider)
                                    .updateSubjectPreferences(
                                      idComision: subject.idComision,
                                      muted: !subject.muted,
                                    ),
                                onToggleHidden: () => ref
                                    .read(databaseProvider)
                                    .setSubjectLocalVisibility(
                                      subject.idComision,
                                      1,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ],
                    );
                  },
                ),

                // Footer estilo MIeL (separado por <hr>, centrado)
                const SizedBox(height: 20),
                Divider(color: palette.divider, height: 1),
                const SizedBox(height: 16),
                Text(
                  'LibreMIEL · Cliente libre y no oficial (Licencia MIT) para MIeL UNLaM',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: palette.textMuted),
                ),
                const SizedBox(height: 6),
                Center(
                  child: InkWell(
                    onTap: _openMielWeb,
                    child: Text(
                      'Abrir MIeL oficial en el navegador',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: palette.linkAccent,
                      ),
                    ),
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

class _MielSubjectCard extends StatefulWidget {
  const _MielSubjectCard({
    required this.subject,
    required this.isCompact,
    required this.organizeMode,
    required this.isHiddenCard,
    required this.onOpenModule,
    required this.onOpenDetail,
    required this.onToggleMute,
    required this.onToggleHidden,
    this.dragIndex,
  });

  final Subject subject;
  final bool isCompact;
  final bool organizeMode;
  final bool isHiddenCard;
  final int? dragIndex;
  final ValueChanged<MielToolKind> onOpenModule;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleHidden;

  @override
  State<_MielSubjectCard> createState() => _MielSubjectCardState();
}

class _MielSubjectCardState extends State<_MielSubjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tools = widget.subject.enabledTools;
    final subtitle = widget.subject.formattedSubtitle;

    final cardBg = _hovered && isDark
        ? palette.cardHover
        : palette.cardBackground;

    final boxShadow = _hovered && !isDark
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(3),
          border: isDark ? Border.all(color: palette.cardBorder) : null,
          boxShadow: boxShadow,
        ),
        child: widget.isCompact
            ? _buildMobileCard(palette, tools, subtitle)
            : _buildDesktopCard(palette, tools, subtitle),
      ),
    );
  }

  Widget _buildDesktopCard(
    MielPalette palette,
    List<MielToolKind> tools,
    String subtitle,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 74),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Columna izquierda: título, código/comisión/rol y controles (.botoneraDetalle / .botoneraOrganizar)
          SizedBox(
            width: widget.organizeMode ? 356 : 318,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.subject.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.subject.name.length > 34
                                ? 13.5
                                : 15,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: palette.textPrimary,
                          ),
                        ),
                        if (subtitle.isNotEmpty || widget.subject.muted) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (subtitle.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              if (widget.subject.muted) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: 'Notificaciones silenciadas',
                                  child: Icon(
                                    Icons.notifications_off_outlined,
                                    size: 14,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildCardTrailingAction(palette),
                ],
              ),
            ),
          ),

          // Columna derecha: barra horizontal de herramientas (86×74px)
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final tool in tools)
                  _MielToolTile(
                    tool: tool,
                    badgeCount: widget.subject.badgeFor(tool),
                    width: 86,
                    height: 74,
                    onTap: () => widget.onOpenModule(tool),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(
    MielPalette palette,
    List<MielToolKind> tools,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subject.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty || widget.subject.muted) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (subtitle.isNotEmpty)
                            Flexible(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                          if (widget.subject.muted) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 14,
                              color: palette.textMuted,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildCardTrailingAction(palette),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 300 ? 4 : 3;
              final tileWidth = constraints.maxWidth / cols;
              return Wrap(
                children: [
                  for (final tool in tools)
                    _MielToolTile(
                      tool: tool,
                      badgeCount: widget.subject.badgeFor(tool),
                      width: tileWidth,
                      height: 70,
                      onTap: () => widget.onOpenModule(tool),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardTrailingAction(MielPalette palette) {
    // En tarjetas ocultas desplegadas, mostrar siempre acceso rápido para volver a mostrarla
    if (widget.isHiddenCard) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mostrar en Materias activas',
            icon: Icon(Icons.visibility, size: 19, color: palette.linkAccent),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: widget.onToggleHidden,
          ),
          IconButton(
            tooltip: 'Ver detalle y alertas',
            icon: Icon(Icons.more_vert, size: 19, color: palette.textSecondary),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: widget.onOpenDetail,
          ),
        ],
      );
    }

    if (widget.organizeMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: widget.subject.muted
                ? 'Activar notificaciones de esta materia'
                : 'Silenciar notificaciones de esta materia',
            icon: Icon(
              widget.subject.muted
                  ? Icons.notifications_off
                  : Icons.notifications_active,
              size: 19,
              color: widget.subject.muted
                  ? palette.textMuted
                  : palette.linkAccent,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: widget.onToggleMute,
          ),
          IconButton(
            tooltip: 'Ocultar materia',
            icon: Icon(Icons.close, size: 19, color: palette.textSecondary),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: widget.onToggleHidden,
          ),
          if (widget.dragIndex != null)
            ReorderableDragStartListener(
              index: widget.dragIndex!,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Tooltip(
                  message: 'Arrastrar para reordenar',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return IconButton(
      tooltip: 'Ver detalle y alertas',
      icon: Icon(Icons.more_vert, size: 19, color: palette.textSecondary),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: widget.onOpenDetail,
    );
  }
}

/// Botón de herramienta de materia fiel a `.materia-herramientas a` (`86×70px`, hover semántico y badge rojo).
class _MielToolTile extends StatefulWidget {
  const _MielToolTile({
    required this.tool,
    required this.badgeCount,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final MielToolKind tool;
  final int badgeCount;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  State<_MielToolTile> createState() => _MielToolTileState();
}

class _MielToolTileState extends State<_MielToolTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final hoverBg = widget.tool.hoverColor(palette);
    final fgColor = _hovered ? Colors.white : palette.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? hoverBg : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: hoverBg,
          splashColor: hoverBg.withValues(alpha: 0.35),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.tool.icon, size: 34, color: fgColor),
                      const SizedBox(height: 2),
                      Text(
                        widget.tool.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: fgColor,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.badgeCount > 0)
                  Positioned(
                    top: 6,
                    left: 10,
                    child: MielRedBadge(
                      count: widget.badgeCount,
                      backgroundColor: palette.badgeRed,
                      compact: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MielSecondaryButton extends StatefulWidget {
  const _MielSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.active = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool active;

  @override
  State<_MielSecondaryButton> createState() => _MielSecondaryButtonState();
}

class _MielSecondaryButtonState extends State<_MielSecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final bg = widget.active
        ? (_hovered ? palette.primaryHover : palette.primary)
        : (_hovered
              ? palette.buttonSecondaryHover
              : palette.buttonSecondaryBackground);
    final fg = widget.active ? Colors.white : palette.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HiddenSubjectsToggle extends StatefulWidget {
  const _HiddenSubjectsToggle({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_HiddenSubjectsToggle> createState() => _HiddenSubjectsToggleState();
}

class _HiddenSubjectsToggleState extends State<_HiddenSubjectsToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final bg = _hovered
        ? palette.buttonSecondaryHover
        : palette.buttonSecondaryBackground;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.expanded ? Icons.visibility_off : Icons.visibility,
                  size: 17,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  widget.expanded
                      ? 'Ocultar materias ocultas'
                      : 'Ver materias ocultas',
                  style: TextStyle(fontSize: 13, color: palette.textPrimary),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySubjectsPlaceholder extends StatelessWidget {
  const _EmptySubjectsPlaceholder({
    required this.isSyncing,
    required this.lastSyncMessage,
    required this.onSync,
  });

  final bool isSyncing;
  final String? lastSyncMessage;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 48, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(
            'Todavía no hay materias sincronizadas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lastSyncMessage ?? 'Sincronizá con MIeL para cargar tus materias activas y sus herramientas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isSyncing ? null : onSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            icon: const Icon(Icons.sync, size: 18),
            label: Text(isSyncing ? 'Sincronizando…' : 'Sincronizar ahora'),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de detalle de comisión y configuración granular de alertas (al tocar ⋮ en una tarjeta).
class _SubjectDetailDialog extends ConsumerWidget {
  const _SubjectDetailDialog({
    required this.subject,
    required this.onOpenModule,
  });

  final Subject subject;
  final ValueChanged<MielToolKind> onOpenModule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final subjects = ref.watch(subjectsStreamProvider).value ?? const [];
    final liveSubject = subjects.firstWhere(
      (s) => s.idComision == subject.idComision,
      orElse: () => subject,
    );
    final teachersAsync = ref.watch(
      subjectTeachersProvider(liveSubject.idComision),
    );
    final db = ref.read(databaseProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera verde esmeralda estilo modal de MIeL
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveSubject.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (liveSubject.formattedSubtitle.isNotEmpty)
                          Text(
                            liveSubject.formattedSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Docentes cacheados
                    Text(
                      'Docentes (caché local)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.linkAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    teachersAsync.when(
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (_, _) => Text(
                        'No se pudo leer la lista de docentes.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.textMuted,
                        ),
                      ),
                      data: (teachers) {
                        if (teachers.isEmpty) {
                          return Text(
                            'Se completará automáticamente al sincronizar mensajes o foros de esta materia.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.textMuted,
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in teachers)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.cardBackground,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: palette.divider),
                                ),
                                child: Text(
                                  '${t.displayName} (${t.role})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Divider(color: palette.divider, height: 1),
                    const SizedBox(height: 12),

                    // Preferencias de notificaciones por materia y módulo
                    Text(
                      'Notificaciones de esta materia',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.linkAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Recibir alertas de esta materia'),
                      value: !liveSubject.muted,
                      onChanged: (active) => db.updateSubjectPreferences(
                        idComision: liveSubject.idComision,
                        muted: !active,
                      ),
                    ),
                    if (liveSubject.hasContenidos)
                      SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 12),
                        title: const Text('Contenidos (archivos y enlaces)'),
                        value: liveSubject.notifyContenidos,
                        onChanged: liveSubject.muted
                            ? null
                            : (v) => db.updateSubjectPreferences(
                                idComision: liveSubject.idComision,
                                notifyContenidos: v,
                              ),
                      ),
                    if (liveSubject.hasPortafolio)
                      SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 12),
                        title: const Text(
                          'Portafolio (prácticas y correcciones)',
                        ),
                        value: liveSubject.notifyPortafolio,
                        onChanged: liveSubject.muted
                            ? null
                            : (v) => db.updateSubjectPreferences(
                                idComision: liveSubject.idComision,
                                notifyPortafolio: v,
                              ),
                      ),
                    if (liveSubject.hasMensajeria)
                      SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 12),
                        title: const Text('Mensajería'),
                        value: liveSubject.notifyMensajeria,
                        onChanged: liveSubject.muted
                            ? null
                            : (v) => db.updateSubjectPreferences(
                                idComision: liveSubject.idComision,
                                notifyMensajeria: v,
                              ),
                      ),
                    if (liveSubject.hasForo)
                      SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 12),
                        title: const Text('Foros'),
                        value: liveSubject.notifyForos,
                        onChanged: liveSubject.muted
                            ? null
                            : (v) => db.updateSubjectPreferences(
                                idComision: liveSubject.idComision,
                                notifyForos: v,
                              ),
                      ),
                    if (liveSubject.hasEvaluacion)
                      SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 12),
                        title: const Text('Evaluaciones'),
                        value: liveSubject.notifyEvaluacion,
                        onChanged: liveSubject.muted
                            ? null
                            : (v) => db.updateSubjectPreferences(
                                idComision: liveSubject.idComision,
                                notifyEvaluacion: v,
                              ),
                      ),
                  ],
                ),
              ),
            ),

            Divider(color: palette.divider, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (liveSubject.enabledTools.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          onOpenModule(liveSubject.enabledTools.first),
                      icon: Icon(
                        Icons.open_in_browser,
                        size: 17,
                        color: palette.linkAccent,
                      ),
                      label: Text(
                        'Abrir borrador',
                        style: TextStyle(color: palette.linkAccent),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
