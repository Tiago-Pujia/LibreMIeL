import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/libremiel_brand.dart';
import '../../core/theme/miel_theme.dart';
import '../feed/feed_screen.dart';
import '../modules/module_draft_view.dart';
import '../settings/settings_screen.dart';
import '../subjects/miel_home_view.dart';

enum _ShellSection { home, novedades, ajustes, moduleDraft }

/// Shell principal de LibreMIEL fiel al layout de MIeL UNLaM:
/// - Fila 1: Barra de marca superior (`#FFFFFF` / `#121212`) con usuario y links.
/// - Fila 2: Barra verde `#menu-principal` (`#009674` / `#128268`) con breadcrumbs y acciones.
/// - Menú lateral izquierdo (`230px` fijo en `>992px`, Drawer deslizable en `<=992px`).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _ShellSection _section = _ShellSection.home;
  String? _activeSubjectId;
  MielToolKind _activeTool = MielToolKind.contenidos;
  int _activeModuleSectionIndex = 0;

  void _goHome() {
    setState(() {
      _section = _ShellSection.home;
    });
    _closeDrawerIfOpen();
  }

  void _goNovedades() {
    setState(() {
      _section = _ShellSection.novedades;
    });
    _closeDrawerIfOpen();
  }

  void _goAjustes() {
    setState(() {
      _section = _ShellSection.ajustes;
    });
    _closeDrawerIfOpen();
  }

  void _openModule(Subject subject, MielToolKind tool) {
    setState(() {
      _section = _ShellSection.moduleDraft;
      _activeSubjectId = subject.idComision;
      _activeTool = tool;
      _activeModuleSectionIndex = defaultSectionIndexForTool(tool);
    });
    _closeDrawerIfOpen();
  }

  void _openModuleById(
    List<Subject> subjects,
    String idComision,
    MielToolKind tool,
  ) {
    final match = subjects.where((s) => s.idComision == idComision).firstOrNull;
    if (match == null) return;
    _openModule(match, tool);
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openExternal(String url) async {
    _closeDrawerIfOpen();
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final session = ref.watch(appSessionProvider);
    final subjects = ref.watch(subjectsStreamProvider).value ?? const [];
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    final width = MediaQuery.sizeOf(context).width;
    final hasDesktopSidebar = width > 992;
    final isMobileHeader = width <= 600;

    Subject? activeSubject;
    if (_section == _ShellSection.moduleDraft && _activeSubjectId != null) {
      activeSubject = subjects
          .where((s) => s.idComision == _activeSubjectId)
          .firstOrNull;
    }

    // Si se borró/reseteó la materia activa, volver a Inicio limpiamente
    final effectiveSection =
        (_section == _ShellSection.moduleDraft && activeSubject == null)
        ? _ShellSection.home
        : _section;

    final sidebarWidget = _MielSidebar(
      section: effectiveSection,
      activeSubject: activeSubject,
      activeTool: _activeTool,
      activeModuleSectionIndex: _activeModuleSectionIndex,
      unreadAlertsCount: unreadCount,
      globalNovedadesBadge: session.globalNovedadesBadge,
      onSelectHome: _goHome,
      onSelectNovedades: _goNovedades,
      onSelectAjustes: _goAjustes,
      onSelectModuleSection: (idx) {
        setState(() => _activeModuleSectionIndex = idx);
        _closeDrawerIfOpen();
      },
      onOpenExternal: _openExternal,
    );

    final mainView = switch (effectiveSection) {
      _ShellSection.home => MielHomeView(
        onOpenModule: _openModule,
        onOpenNotifications: _goNovedades,
      ),
      _ShellSection.novedades => FeedScreen(
        onOpenSubjectModule: (idComision, tool) =>
            _openModuleById(subjects, idComision, tool),
      ),
      _ShellSection.ajustes => const SettingsScreen(),
      _ShellSection.moduleDraft => ModuleDraftView(
        subject: activeSubject!,
        tool: _activeTool,
        sectionIndex: _activeModuleSectionIndex,
        onBackHome: _goHome,
      ),
    };

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.pageBackground,
      drawer: hasDesktopSidebar
          ? null
          : Drawer(
              width: 248,
              backgroundColor: palette.sidebarBackground,
              shape: const RoundedRectangleBorder(),
              child: SafeArea(child: sidebarWidget),
            ),
      body: Column(
        children: [
          // Encabezado doble fiel a MIeL (#encabezado = barra de marca + #menu-principal)
          _MielDoubleHeader(
            isMobileHeader: isMobileHeader,
            hasDesktopSidebar: hasDesktopSidebar,
            section: effectiveSection,
            session: session,
            subjects: subjects,
            activeSubject: activeSubject,
            activeTool: _activeTool,
            unreadAlertsCount: unreadCount,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            onGoHome: _goHome,
            onGoNovedades: _goNovedades,
            onGoAjustes: _goAjustes,
            onSelectSubject: (subject) {
              final tools = subject.enabledTools;
              final nextTool = tools.contains(_activeTool)
                  ? _activeTool
                  : (tools.isNotEmpty ? tools.first : MielToolKind.contenidos);
              _openModule(subject, nextTool);
            },
            onSelectTool: (tool) {
              if (activeSubject != null) {
                _openModule(activeSubject, tool);
              }
            },
            onSyncNow: () => ref
                .read(appSessionProvider.notifier)
                .syncNow(includeCycle2: true),
            onToggleTheme: () => ref
                .read(appSessionProvider.notifier)
                .toggleThemeMode(Theme.of(context).brightness),
            onLogout: () => ref.read(appSessionProvider.notifier).logout(),
          ),

          // Banner de alerta crítica si la autenticación fue pausada (estado 1/2/3)
          if (session.authPausedReason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: palette.paleRedBackground,
                border: Border(
                  bottom: BorderSide(color: palette.paleRedBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: palette.badgeRed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sincronización pausada: ${session.authPausedReason}',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(appSessionProvider.notifier).logout(),
                    child: Text(
                      'Actualizar clave',
                      style: TextStyle(
                        color: palette.badgeRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Cuerpo: Sidebar fijo izquierdo (230px en >992px) + contenido principal
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasDesktopSidebar)
                  Container(
                    width: 230,
                    decoration: BoxDecoration(
                      color: palette.sidebarBackground,
                      border: Border(
                        right: BorderSide(color: palette.sidebarBorder),
                      ),
                    ),
                    child: sidebarWidget,
                  ),
                Expanded(child: mainView),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra doble superior fiel a MIeL:
/// 1) Barra de marca blanca/negra (`54px`)
/// 2) Barra de navegación verde esmeralda `#menu-principal` (`40px`) con sombra
class _MielDoubleHeader extends StatelessWidget {
  const _MielDoubleHeader({
    required this.isMobileHeader,
    required this.hasDesktopSidebar,
    required this.section,
    required this.session,
    required this.subjects,
    required this.activeSubject,
    required this.activeTool,
    required this.unreadAlertsCount,
    required this.onOpenDrawer,
    required this.onGoHome,
    required this.onGoNovedades,
    required this.onGoAjustes,
    required this.onSelectSubject,
    required this.onSelectTool,
    required this.onSyncNow,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final bool isMobileHeader;
  final bool hasDesktopSidebar;
  final _ShellSection section;
  final AppSessionState session;
  final List<Subject> subjects;
  final Subject? activeSubject;
  final MielToolKind activeTool;
  final int unreadAlertsCount;
  final VoidCallback onOpenDrawer;
  final VoidCallback onGoHome;
  final VoidCallback onGoNovedades;
  final VoidCallback onGoAjustes;
  final ValueChanged<Subject> onSelectSubject;
  final ValueChanged<MielToolKind> onSelectTool;
  final VoidCallback onSyncNow;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final displayName = session.studentName.isNotEmpty
        ? session.studentName.toUpperCase()
        : 'ESTUDIANTE';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila 1: Barra de marca (54px)
        Container(
          color: palette.topBarBackground,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isMobileHeader
                    ? Center(
                        child: InkWell(
                          onTap: onGoHome,
                          child: const LibreMielMark(size: 32),
                        ),
                      )
                    : Row(
                        children: [
                          InkWell(
                            onTap: onGoHome,
                            child: const LibreMielMark(size: 34),
                          ),
                          const Spacer(),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TopLink(
                                    label: 'Ajustes',
                                    color: palette.linkAccent,
                                    onTap: onGoAjustes,
                                  ),
                                  _TopLinkDot(color: palette.textMuted),
                                  _TopLink(
                                    label: 'Sincronizar',
                                    color: palette.linkAccent,
                                    onTap: onSyncNow,
                                  ),
                                  _TopLinkDot(color: palette.textMuted),
                                  _TopLink(
                                    label: 'Cerrar sesión',
                                    color: palette.linkAccent,
                                    onTap: onLogout,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: palette.textMuted.withValues(
                              alpha: 0.35,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 26,
                              color: palette.pageBackground,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        // Fila 2: Barra verde esmeralda #menu-principal (40px) con sombra w3-card-2
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.primary,
            boxShadow: const [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              // Izquierda: menú móvil + home + breadcrumbs / "Menú principal"
              if (!hasDesktopSidebar)
                _NavIconAction(
                  tooltip: 'Menú lateral',
                  icon: Icons.menu,
                  onTap: onOpenDrawer,
                ),
              _NavIconAction(
                tooltip: 'Menú principal (Materias activas)',
                icon: Icons.home,
                onTap: onGoHome,
              ),
              if (section == _ShellSection.moduleDraft &&
                  activeSubject != null) ...[
                _SubjectBreadcrumbDropdown(
                  activeSubject: activeSubject!,
                  subjects: subjects,
                  maxWidth: isMobileHeader ? 150 : 280,
                  onSelected: onSelectSubject,
                ),
                _ToolBreadcrumbDropdown(
                  activeTool: activeTool,
                  availableTools: activeSubject!.enabledTools,
                  onSelected: onSelectTool,
                ),
              ] else if (!isMobileHeader) ...[
                _NavTextAction(
                  label: switch (section) {
                    _ShellSection.home => 'Menú principal',
                    _ShellSection.novedades => 'Novedades',
                    _ShellSection.ajustes => 'Alertas y ajustes',
                    _ShellSection.moduleDraft => 'Menú principal',
                  },
                  onTap: onGoHome,
                ),
              ],

              const Spacer(),

              // Derecha: Sincronizar + Campana de notificaciones + Contraste claro/oscuro (+ Ajustes/Salir en móvil)
              if (session.isSyncing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                _NavIconAction(
                  tooltip: 'Sincronizar ahora',
                  icon: Icons.sync,
                  onTap: onSyncNow,
                ),

              _NavNotificationAction(
                unreadCount: unreadAlertsCount,
                onTap: onGoNovedades,
              ),

              _NavIconAction(
                tooltip: 'Cambiar modo claro / oscuro',
                icon: Icons.brightness_4,
                onTap: onToggleTheme,
              ),

              if (isMobileHeader) ...[
                _NavIconAction(
                  tooltip: 'Alertas y ajustes',
                  icon: Icons.tune,
                  onTap: onGoAjustes,
                ),
                _NavIconAction(
                  tooltip: 'Cerrar sesión',
                  icon: Icons.logout,
                  onTap: onLogout,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TopLink extends StatelessWidget {
  const _TopLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TopLinkDot extends StatelessWidget {
  const _TopLinkDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('·', style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _NavIconAction extends StatelessWidget {
  const _NavIconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: palette.primaryHover,
          child: SizedBox(
            height: 40,
            width: 40,
            child: Icon(icon, size: 21, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _NavNotificationAction extends StatelessWidget {
  const _NavNotificationAction({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Tooltip(
      message: unreadCount > 0
          ? 'Novedades ($unreadCount sin leer)'
          : 'Novedades',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: palette.primaryHover,
          child: SizedBox(
            height: 40,
            width: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  unreadCount > 0
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  size: 21,
                  color: Colors.white,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 4,
                    right: 3,
                    child: MielRedBadge(
                      count: unreadCount,
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

class _NavTextAction extends StatelessWidget {
  const _NavTextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: palette.primaryHover,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectBreadcrumbDropdown extends StatelessWidget {
  const _SubjectBreadcrumbDropdown({
    required this.activeSubject,
    required this.subjects,
    required this.maxWidth,
    required this.onSelected,
  });

  final Subject activeSubject;
  final List<Subject> subjects;
  final double maxWidth;
  final ValueChanged<Subject> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final activeList = subjects.where((s) => !s.isHiddenInMiel).toList();
    final itemsList = activeList.isNotEmpty ? activeList : subjects;

    return PopupMenuButton<String>(
      tooltip: 'Cambiar de materia',
      color: palette.dropdownBackground,
      offset: const Offset(0, 40),
      onSelected: (id) {
        final found = itemsList.where((s) => s.idComision == id).firstOrNull;
        if (found != null) onSelected(found);
      },
      itemBuilder: (_) => [
        for (final s in itemsList)
          PopupMenuItem<String>(
            value: s.idComision,
            child: Text(
              s.breadcrumbLabel,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: s.idComision == activeSubject.idComision
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: palette.textPrimary,
              ),
            ),
          ),
      ],
      child: Container(
        height: 40,
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                activeSubject.breadcrumbLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ToolBreadcrumbDropdown extends StatelessWidget {
  const _ToolBreadcrumbDropdown({
    required this.activeTool,
    required this.availableTools,
    required this.onSelected,
  });

  final MielToolKind activeTool;
  final List<MielToolKind> availableTools;
  final ValueChanged<MielToolKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final options = availableTools.isNotEmpty ? availableTools : [activeTool];

    return PopupMenuButton<MielToolKind>(
      tooltip: 'Cambiar de herramienta',
      color: palette.dropdownBackground,
      offset: const Offset(0, 40),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final t in options)
          PopupMenuItem<MielToolKind>(
            value: t,
            child: Row(
              children: [
                Icon(t.icon, size: 18, color: palette.textSecondary),
                const SizedBox(width: 8),
                Text(
                  t.fullLabel,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: t == activeTool
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeTool.fullLabel,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Menú lateral `#menu-lateral` fiel a MIeL (`230px`, fondo `#F3F9F6` / `#262626`).
class _MielSidebar extends ConsumerWidget {
  const _MielSidebar({
    required this.section,
    required this.activeSubject,
    required this.activeTool,
    required this.activeModuleSectionIndex,
    required this.unreadAlertsCount,
    required this.globalNovedadesBadge,
    required this.onSelectHome,
    required this.onSelectNovedades,
    required this.onSelectAjustes,
    required this.onSelectModuleSection,
    required this.onOpenExternal,
  });

  final _ShellSection section;
  final Subject? activeSubject;
  final MielToolKind activeTool;
  final int activeModuleSectionIndex;
  final int unreadAlertsCount;
  final int globalNovedadesBadge;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectNovedades;
  final VoidCallback onSelectAjustes;
  final ValueChanged<int> onSelectModuleSection;
  final ValueChanged<String> onOpenExternal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);

    // Si estamos dentro de un módulo (Fase 2 borrador), el sidebar replica el sub-menú del módulo
    if (section == _ShellSection.moduleDraft && activeSubject != null) {
      final items = mielSectionsForTool(activeTool);
      final cachedForoTopics = activeTool == MielToolKind.foro
          ? (ref
                    .watch(
                      subjectSnapshotsProvider((
                        idComision: activeSubject!.idComision,
                        module: 'foro_temas',
                      )),
                    )
                    .value ??
                const <SnapshotEntry>[])
          : const <SnapshotEntry>[];

      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 14),
        children: [
          _SidebarHeading(title: activeTool.fullLabel, palette: palette),
          const SizedBox(height: 6),
          for (var i = 0; i < items.length; i++)
            _SidebarItem(
              icon: items[i].icon,
              label: items[i].label,
              selected: i == activeModuleSectionIndex,
              onTap: () => onSelectModuleSection(i),
            ),
          if (cachedForoTopics.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final topic in cachedForoTopics.take(12))
              _SidebarItem(
                icon: Icons.message,
                label: topic.summary.isNotEmpty
                    ? topic.summary
                    : 'Tema #${topic.itemId}',
                selected: false,
                onTap: () => onSelectModuleSection(0),
              ),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(color: palette.divider, height: 1),
          ),
          const SizedBox(height: 10),
          _SidebarItem(
            icon: Icons.arrow_back,
            label: 'Materias activas',
            selected: false,
            onTap: onSelectHome,
          ),
        ],
      );
    }

    // Menú principal: Utilidades + Ayuda (fiel a /principal/interno/)
    final novedadesBadge = unreadAlertsCount > 0
        ? unreadAlertsCount
        : globalNovedadesBadge;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      children: [
        _SidebarHeading(title: 'Utilidades', palette: palette),
        const SizedBox(height: 6),
        _SidebarItem(
          icon: Icons.home,
          label: 'Materias activas',
          selected: section == _ShellSection.home,
          onTap: onSelectHome,
        ),
        _SidebarItem(
          icon: Icons.campaign,
          label: 'Novedades',
          selected: section == _ShellSection.novedades,
          badgeCount: novedadesBadge,
          onTap: onSelectNovedades,
        ),
        _SidebarItem(
          icon: Icons.notifications_active,
          label: 'Alertas y ajustes',
          selected: section == _ShellSection.ajustes,
          onTap: onSelectAjustes,
        ),
        _SidebarItem(
          icon: Icons.calendar_today,
          label: 'Calendario',
          selected: false,
          onTap: () => onOpenExternal('$kMielBaseUrl/calendario/'),
        ),
        _SidebarItem(
          icon: Icons.local_library,
          label: 'Biblioteca BiDi',
          selected: false,
          onTap: () => onOpenExternal('$kMielBaseUrl/principal/interno/'),
        ),
        const SizedBox(height: 22),
        _SidebarHeading(title: 'Ayuda', palette: palette),
        const SizedBox(height: 6),
        _SidebarItem(
          icon: Icons.subscriptions,
          label: 'Tutoriales',
          selected: false,
          onTap: () => onOpenExternal('$kMielBaseUrl/ayuda/tutoriales/'),
        ),
        _SidebarItem(
          icon: Icons.help,
          label: 'Preguntas frecuentes',
          selected: false,
          onTap: () => onOpenExternal('$kMielBaseUrl/ayuda/faq/'),
        ),
        _SidebarItem(
          icon: Icons.open_in_new,
          label: 'Abrir MIeL Web',
          selected: false,
          onTap: () => onOpenExternal('$kMielBaseUrl/principal/interno/'),
        ),
      ],
    );
  }
}

class _SidebarHeading extends StatelessWidget {
  const _SidebarHeading({required this.title, required this.palette});

  final String title;
  final MielPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          height: 1.25,
          color: palette.textPrimary,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final bg = widget.selected
        ? palette.sidebarSelected
        : _hovered
        ? palette.sidebarHover
        : Colors.transparent;
    final iconColor = (widget.selected || _hovered)
        ? palette.sidebarIconActive
        : palette.sidebarIcon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(4),
            hoverColor: palette.sidebarHover,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Icon(widget.icon, size: 19, color: iconColor),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: widget.selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.badgeCount > 0) ...[
                    const SizedBox(width: 6),
                    MielRedBadge(
                      count: widget.badgeCount,
                      backgroundColor: palette.badgeRed,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
