import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
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

  /// Uso oficial de los 3 puntitos (⋮) en MIeL: ver detalle de comisión y docentes (`cursoDetalles`).
  void _openCourseDetail(Subject subject) {
    showDialog<void>(
      context: context,
      builder: (_) => _MielCourseDetailDialog(subject: subject),
    );
  }

  /// Campana de LibreMIeL junto a los 3 puntitos: configuración de notificaciones por materia/módulo.
  void _openSubjectAlerts(Subject subject) {
    showDialog<void>(
      context: context,
      builder: (_) => _SubjectAlertsDialog(subject: subject),
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

        // Fiel a MIeL: "Ver materias ocultas" al lado de "Organizar materias".
        // Al hacer click en "Organizar materias", el botón mantiene su color y texto original
        // y alterna entre la botonera normal y la botonera vertical de organización.
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
              label: 'Organizar materias',
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

                // Aviso compacto de novedades sin leer (adaptación LibreMIeL)
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
                                      ? 'Tenés 1 novedad nueva detectada por LibreMIeL.'
                                      : 'Tenés $unreadCount novedades nuevas detectadas por LibreMIeL.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                'Ver notificaciones',
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
                                  onOpenCourseDetail: () =>
                                      _openCourseDetail(subject),
                                  onOpenAlerts: () =>
                                      _openSubjectAlerts(subject),
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
                              onOpenCourseDetail: () =>
                                  _openCourseDetail(subject),
                              onOpenAlerts: () => _openSubjectAlerts(subject),
                              onToggleHidden: () => ref
                                  .read(databaseProvider)
                                  .setSubjectLocalVisibility(
                                    subject.idComision,
                                    -1,
                                  ),
                            ),
                            const SizedBox(height: 14),
                          ],

                        // Materias ocultas desplegadas
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
                                onOpenCourseDetail: () =>
                                    _openCourseDetail(subject),
                                onOpenAlerts: () => _openSubjectAlerts(subject),
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
                  'LibreMIeL · Cliente libre y no oficial (Licencia MIT) para MIeL UNLaM',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: palette.textMuted),
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
    required this.onOpenCourseDetail,
    required this.onOpenAlerts,
    required this.onToggleHidden,
    this.dragIndex,
  });

  final Subject subject;
  final bool isCompact;
  final bool organizeMode;
  final bool isHiddenCard;
  final int? dragIndex;
  final ValueChanged<MielToolKind> onOpenModule;
  final VoidCallback onOpenCourseDetail;
  final VoidCallback onOpenAlerts;
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
          // Columna izquierda fija (318px) para que las herramientas no se desplacen al organizar
          SizedBox(
            width: 318,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
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
    // Tarjetas ocultas desplegadas: botón mostrar + detalle oficial MIeL
    if (widget.isHiddenCard) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactCardIcon(
            tooltip: 'Mostrar en Materias activas',
            icon: Icons.visibility,
            color: palette.linkAccent,
            onTap: widget.onToggleHidden,
          ),
          _CompactCardIcon(
            tooltip: 'Ver detalle',
            icon: Icons.more_vert,
            color: palette.textSecondary,
            onTap: widget.onOpenCourseDetail,
          ),
        ],
      );
    }

    // Modo organizar (fiel a .botoneraOrganizar de MIeL): vertical (arrastrar arriba, ocultar abajo)
    if (widget.organizeMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.dragIndex != null)
            ReorderableDragStartListener(
              index: widget.dragIndex!,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Tooltip(
                  message: 'Arrastre para ordenar',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      size: 19,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          _CompactCardIcon(
            tooltip: 'Ocultar materia',
            icon: Icons.close,
            color: palette.textSecondary,
            size: 18,
            onTap: widget.onToggleHidden,
          ),
        ],
      );
    }

    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : palette.textSecondary;

    // Modo normal: campana de notificaciones de LibreMIeL al lado de los 3 puntitos (Ver detalle de MIeL)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompactCardIcon(
          tooltip: widget.subject.muted
              ? 'Notificaciones silenciadas (tocar para configurar)'
              : 'Notificaciones de esta materia',
          icon: widget.subject.muted
              ? Icons.notifications_off_outlined
              : Icons.notifications_active,
          color: widget.subject.muted ? palette.textMuted : iconColor,
          onTap: widget.onOpenAlerts,
        ),
        _CompactCardIcon(
          tooltip: 'Ver detalle',
          icon: Icons.more_vert,
          color: iconColor,
          onTap: widget.onOpenCourseDetail,
        ),
      ],
    );
  }
}

class _CompactCardIcon extends StatefulWidget {
  const _CompactCardIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 19,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  State<_CompactCardIcon> createState() => _CompactCardIconState();
}

class _CompactCardIconState extends State<_CompactCardIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            width: 28,
            height: 26,
            decoration: BoxDecoration(
              color: _hovered
                  ? palette.divider.withValues(alpha: 0.65)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: widget.size, color: widget.color),
          ),
        ),
      ),
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(widget.tool.icon, size: 34, color: fgColor),
                      if (widget.badgeCount > 0)
                        Positioned(
                          top: -2,
                          left: -8,
                          child: MielRedBadge(
                            count: widget.badgeCount,
                            backgroundColor: palette.badgeRed,
                            compact: true,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.tool.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: fgColor, height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MielSecondaryButton extends StatefulWidget {
  const _MielSecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_MielSecondaryButton> createState() => _MielSecondaryButtonState();
}

class _MielSecondaryButtonState extends State<_MielSecondaryButton> {
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
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: palette.textPrimary,
              ),
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

/// Modal oficial de MIeL al tocar los 3 puntitos (⋮): Detalle del curso (`/principal/cursoDetalles/id/{id}`).
class _MielCourseDetailDialog extends ConsumerWidget {
  const _MielCourseDetailDialog({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final liveDetailsAsync = ref.watch(
      courseDetailsProvider(subject.idComision),
    );
    final cachedTeachers =
        ref.watch(subjectTeachersProvider(subject.idComision)).value ??
        const <CachedTeacher>[];

    final liveDetails = liveDetailsAsync.value;
    final teacherEntries =
        liveDetails != null && liveDetails.teachers.isNotEmpty
        ? liveDetails.teachers.map((t) => (name: t.name, role: t.role)).toList()
        : cachedTeachers
              .map((t) => (name: t.displayName, role: t.role))
              .toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        const Text(
                          'Detalle de la comisión',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          subject.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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

            if (liveDetailsAsync.isLoading)
              LinearProgressIndicator(
                minHeight: 2,
                color: palette.primary,
                backgroundColor: palette.divider,
              ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subject.subjectCode.isNotEmpty)
                      _DetailRow(
                        label: 'Código de materia',
                        value: subject.subjectCode,
                        palette: palette,
                      ),
                    if (subject.commissionCode.isNotEmpty)
                      _DetailRow(
                        label: 'Comisión',
                        value: subject.commissionCode,
                        palette: palette,
                      ),
                    if (subject.roleLabel.isNotEmpty)
                      _DetailRow(
                        label: 'Rol',
                        value: subject.roleLabel,
                        palette: palette,
                      ),
                    if (liveDetails != null && liveDetails.term.isNotEmpty)
                      _DetailRow(
                        label: 'Cuatrimestre',
                        value: liveDetails.term,
                        palette: palette,
                      ),
                    if (liveDetails != null && liveDetails.modality.isNotEmpty)
                      _DetailRow(
                        label: 'Modalidad',
                        value: liveDetails.modality,
                        palette: palette,
                      ),
                    if (liveDetails != null && liveDetails.classroom.isNotEmpty)
                      _DetailRow(
                        label: 'Aula',
                        value: liveDetails.classroom,
                        palette: palette,
                      ),

                    const SizedBox(height: 12),
                    Divider(color: palette.divider, height: 1),
                    const SizedBox(height: 12),

                    Text(
                      'Docentes',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: palette.linkAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (teacherEntries.isEmpty)
                      Text(
                        liveDetailsAsync.isLoading
                            ? 'Consultando docentes en MIeL…'
                            : 'Sin docentes registrados en caché todavía.',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final t in teacherEntries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: palette.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${t.name} (${t.role})',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final MielPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal de configuración de notificaciones por materia (accesible desde la campana junto a ⋮).
class _SubjectAlertsDialog extends ConsumerWidget {
  const _SubjectAlertsDialog({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final subjects = ref.watch(subjectsStreamProvider).value ?? const [];
    final liveSubject = subjects.firstWhere(
      (s) => s.idComision == subject.idComision,
      orElse: () => subject,
    );
    final db = ref.read(databaseProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notificaciones de esta materia',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          liveSubject.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Divider(color: palette.divider, height: 12),
                    if (liveSubject.hasContenidos)
                      SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 8),
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
                        contentPadding: const EdgeInsets.only(left: 8),
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
                        contentPadding: const EdgeInsets.only(left: 8),
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
                        contentPadding: const EdgeInsets.only(left: 8),
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
                        contentPadding: const EdgeInsets.only(left: 8),
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
