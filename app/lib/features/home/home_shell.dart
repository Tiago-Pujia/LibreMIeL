import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/libremiel_brand.dart';
import '../../core/theme/miel_theme.dart';
import '../../platform/android_widget_service.dart';
import '../../platform/notification_service.dart';
import '../../platform/updater/updater_controller.dart';
import '../feed/feed_screen.dart';
import '../modules/module_providers.dart';
import '../modules/module_reader_host.dart';
import '../modules/module_sections.dart';
import '../modules/widgets/module_state_views.dart';
import '../navigation/browser_find_bar.dart';
import '../navigation/browser_find_controller.dart';
import '../navigation/browser_navigation_host.dart';
import '../navigation/browser_zoom_viewport.dart';
import '../navigation/draft_dirty_registry.dart';
import '../navigation/navigation_history_controller.dart';
import '../navigation/navigation_history_entry.dart';
import '../settings/settings_screen.dart';
import '../subjects/miel_home_view.dart';
import '../downloads/bulk_download_sheet.dart';
import '../updates/update_dialog.dart';
import 'widgets/miel_status_banner.dart';

/// Shell principal de LibreMIeL fiel al layout de MIeL UNLaM:
/// - Fila 1: Barra de marca superior (`#FFFFFF` / `#121212`) con usuario y links.
/// - Fila 2: Barra verde `#menu-principal` (`#009674` / `#128268`) con breadcrumbs y acciones.
/// - Menú lateral izquierdo (`230px` fijo en `>992px`, Drawer deslizable en `<=992px`).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _contentScrollController = ScrollController();
  final FocusNode _nativeSearchFocusNode = FocusNode(
    debugLabel: 'NativeSearchFocus',
  );
  int _moduleSectionNavTick = 0;
  int _findFocusTick = 0;
  MielProfileTab _settingsInitialTab = MielProfileTab.datosPersonales;

  StreamSubscription<NotificationTapPayload>? _notifTapSub;
  StreamSubscription<NotificationTapPayload>? _widgetTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifTapSub = NotificationService.onNotificationTapped.stream.listen((
      payload,
    ) {
      if (!mounted) return;
      unawaited(_handleNotificationPayloadTap(payload));
    });
    _widgetTapSub = AndroidWidgetService.onWidgetTapped.stream.listen((
      payload,
    ) {
      if (!mounted) return;
      unawaited(_handleNotificationPayloadTap(payload));
    });
    unawaited(ref.read(androidWidgetServiceProvider).initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkInitialNotification());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifTapSub?.cancel();
    _widgetTapSub?.cancel();
    _contentScrollController.dispose();
    _nativeSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb && Platform.isAndroid) {
      // WorkManager ejecuta en un motor Flutter independiente: al volver a
      // primer plano notificamos a Drift para refrescar streams de novedades y materias.
      ref.read(databaseProvider).notifyExternalTableUpdates();
      unawaited(
        ref.read(appSessionProvider.notifier).syncAndroidWidgetFromDb(),
      );
    }
  }

  Future<void> _checkInitialNotification() async {
    final details = await ref
        .read(notificationServiceProvider)
        .getLaunchDetails();
    if (!mounted) return;
    if (details != null && details.didNotificationLaunchApp) {
      final raw = details.notificationResponse?.payload;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            await _handleNotificationPayloadTap(
              NotificationTapPayload.fromJson(decoded),
            );
            return;
          }
        } catch (_) {}
      }
    }

    final widgetPayload = await ref
        .read(androidWidgetServiceProvider)
        .consumeInitialTapPayload();
    if (!mounted || widgetPayload == null) return;
    await _handleNotificationPayloadTap(widgetPayload);
  }

  String? _extractForoTopicId(String targetUrl) {
    if (targetUrl.isEmpty) return null;
    final match = RegExp(
      r'/(?:idTema|tema)/(\d+)',
      caseSensitive: false,
    ).firstMatch(targetUrl);
    return match?.group(1);
  }

  Future<void> _handleNotificationPayloadTap(
    NotificationTapPayload payload,
  ) async {
    if (!mounted) return;

    if (payload.notificationId != null) {
      unawaited(
        ref
            .read(databaseProvider)
            .markNotificationRead(payload.notificationId!)
            .catchError((_) {}),
      );
    }

    if (payload.module == 'app_update' ||
        payload.targetUrl.startsWith('libremiel://update')) {
      final updater = ref.read(updaterProvider);
      if (updater.availableRelease == null && !updater.isChecking) {
        unawaited(
          ref.read(updaterProvider.notifier).checkForUpdates(manual: true),
        );
      }
      UpdateDialog.show(context);
      return;
    }

    if (payload.module == 'home' || payload.idComision == 'home') {
      _goHome();
      return;
    }

    if (payload.module == 'novedades' ||
        payload.idComision.isEmpty ||
        payload.idComision == 'global' ||
        payload.idComision == 'sistema') {
      _goNovedades();
      return;
    }

    var subjects = ref.read(subjectsStreamProvider).value ?? const <Subject>[];
    if (subjects.isEmpty) {
      // En arranques en frío (app cerrada) el StreamProvider puede no haber
      // emitido todavía: consultar SQLite directamente para no perder el toque.
      try {
        subjects = await ref.read(databaseProvider).getAllSubjects();
      } catch (_) {
        subjects = const <Subject>[];
      }
      if (!mounted) return;
    }

    final tool = switch (payload.module) {
      'contenidos' => MielToolKind.contenidos,
      'portafolio' => MielToolKind.portafolio,
      'mensajeria' => MielToolKind.mensajeria,
      'foros' || 'foro' => MielToolKind.foro,
      'evaluacion' => MielToolKind.evaluacion,
      _ => null,
    };

    if (tool != null) {
      final topicId = tool == MielToolKind.foro
          ? _extractForoTopicId(payload.targetUrl)
          : null;
      final opened = _openModuleById(
        subjects,
        payload.idComision,
        tool,
        foroTopicId: topicId,
      );
      if (!opened) {
        _goNovedades();
      }
    } else {
      _goNovedades();
    }
  }

  Future<void> _navigateTo(
    NavigationHistoryEntry next, {
    bool replace = false,
  }) async {
    final canProceed = await confirmDiscardDirtyDraftsIfNeeded(
      context,
      ref.read(draftDirtyRegistryProvider),
    );
    if (!canProceed) return;

    if (_contentScrollController.hasClients) {
      ref
          .read(navigationHistoryProvider.notifier)
          .saveScrollOffset(_contentScrollController.offset);
    }
    ref.read(browserFindProvider.notifier).close();

    ref
        .read(navigationHistoryProvider.notifier)
        .navigateTo(next, replace: replace);
    _closeDrawerIfOpen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_contentScrollController.hasClients) {
        _contentScrollController.jumpTo(next.scrollOffset);
      }
    });
  }

  Future<void> _goBack() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _closeDrawerIfOpen();
      return;
    }
    if (ref.read(browserFindProvider).isOpen) {
      ref.read(browserFindProvider.notifier).close();
      return;
    }
    final canProceed = await confirmDiscardDirtyDraftsIfNeeded(
      context,
      ref.read(draftDirtyRegistryProvider),
    );
    if (!canProceed) return;

    if (_contentScrollController.hasClients) {
      ref
          .read(navigationHistoryProvider.notifier)
          .saveScrollOffset(_contentScrollController.offset);
    }
    ref.read(browserFindProvider.notifier).close();

    final prev = ref.read(navigationHistoryProvider.notifier).goBack();
    if (prev != null) {
      markBfCacheRestoreKeys([prev.locationKey]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_contentScrollController.hasClients) {
          _contentScrollController.jumpTo(prev.scrollOffset);
        }
      });
    }
  }

  Future<void> _goForward() async {
    final canProceed = await confirmDiscardDirtyDraftsIfNeeded(
      context,
      ref.read(draftDirtyRegistryProvider),
    );
    if (!canProceed) return;

    if (_contentScrollController.hasClients) {
      ref
          .read(navigationHistoryProvider.notifier)
          .saveScrollOffset(_contentScrollController.offset);
    }
    ref.read(browserFindProvider.notifier).close();

    final next = ref.read(navigationHistoryProvider.notifier).goForward();
    if (next != null) {
      markBfCacheRestoreKeys([next.locationKey]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_contentScrollController.hasClients) {
          _contentScrollController.jumpTo(next.scrollOffset);
        }
      });
    }
  }

  void _reloadActiveRoute({bool forceLive = false}) {
    final current = ref.read(navigationHistoryProvider).current;
    if (forceLive) {
      markForceLiveCacheKeys([current.locationKey]);
    }
    invalidateRouteProviders(ref, current, forceLive: forceLive);
  }

  void _goHome() {
    _navigateTo(const NavigationHistoryEntry.home());
  }

  void _goNovedades() {
    _navigateTo(const NavigationHistoryEntry.novedades());
  }

  void _goAjustes({MielProfileTab initialTab = MielProfileTab.ajustesLibreMiel}) {
    setState(() {
      _settingsInitialTab = initialTab;
    });
    _navigateTo(const NavigationHistoryEntry.ajustes());
  }

  void _openUserProfile(AppSessionState session, List<Subject> subjects) {
    _goAjustes(initialTab: MielProfileTab.datosPersonales);
  }

  void _openModule(
    Subject subject,
    MielToolKind tool, {
    String? foroTopicId,
    PortfolioPractice? portafolioPractice,
    MensajeriaViewRouteState? mensajeriaState,
  }) {
    _moduleSectionNavTick++;
    _navigateTo(
      NavigationHistoryEntry.module(
        subjectId: subject.idComision,
        tool: tool,
        moduleSectionIndex: defaultSectionIndexForTool(tool),
        foroTopicId: tool == MielToolKind.foro ? foroTopicId : null,
        portafolioPractice: portafolioPractice,
        mensajeriaState: mensajeriaState ?? const MensajeriaViewRouteState(),
      ),
    );
  }

  bool _openModuleById(
    List<Subject> subjects,
    String idComision,
    MielToolKind tool, {
    String? foroTopicId,
  }) {
    final match = subjects.where((s) => s.idComision == idComision).firstOrNull;
    if (match == null) return false;
    _openModule(match, tool, foroTopicId: foroTopicId);
    return true;
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
    final historyState = ref.watch(navigationHistoryProvider);
    final currentEntry = historyState.current;
    final findState = ref.watch(browserFindProvider);

    final width = MediaQuery.sizeOf(context).width;
    final hasDesktopSidebar = width > 992;
    final isMobileHeader = width <= 600;

    Subject? activeSubject;
    if (currentEntry.section == BrowserShellSection.module &&
        currentEntry.subjectId != null) {
      activeSubject = subjects
          .where((s) => s.idComision == currentEntry.subjectId)
          .firstOrNull;
    }

    final effectiveSection =
        (currentEntry.section == BrowserShellSection.module &&
            activeSubject == null)
        ? BrowserShellSection.home
        : currentEntry.section;

    final activeTool = currentEntry.tool;
    final activeModuleSectionIndex = currentEntry.moduleSectionIndex;
    final activeForoTopicId = currentEntry.foroTopicId;

    final sidebarWidget = _MielSidebar(
      section: effectiveSection,
      activeSubject: activeSubject,
      activeTool: activeTool,
      activeModuleSectionIndex: activeModuleSectionIndex,
      activeForoTopicId: activeForoTopicId,
      unreadAlertsCount: unreadCount,
      onSelectHome: _goHome,
      onSelectNovedades: _goNovedades,
      onSelectAjustes: _goAjustes,
      onSelectModuleSection: (idx) {
        _moduleSectionNavTick++;
        _navigateTo(
          currentEntry.copyWith(
            moduleSectionIndex: idx,
            clearForoTopicId: true,
            clearPortafolioPractice: true,
            mensajeriaState: const MensajeriaViewRouteState(),
          ),
        );
      },
      onSelectForoTopic: (topicId) {
        _navigateTo(
          currentEntry.copyWith(
            tool: MielToolKind.foro,
            foroTopicId: topicId,
            clearForoTopicId: topicId == null,
          ),
        );
      },
      onOpenBulkDownload: () {
        _closeDrawerIfOpen();
        showBulkDownloadDialog(context, initialSubject: activeSubject);
      },
      onOpenExternal: _openExternal,
    );

    final mainView = switch (effectiveSection) {
      BrowserShellSection.home => MielHomeView(
        onOpenModule: _openModule,
        onOpenNotifications: _goNovedades,
        scrollController: _contentScrollController,
        inPageFindQuery: findState.query,
      ),
      BrowserShellSection.novedades => FeedScreen(
        onOpenSubjectModule: (idComision, tool) =>
            _openModuleById(subjects, idComision, tool),
        scrollController: _contentScrollController,
        inPageFindQuery: findState.query,
      ),
      BrowserShellSection.ajustes => SettingsScreen(
        initialTab: _settingsInitialTab,
        onGoHome: _goHome,
      ),
      BrowserShellSection.module => ModuleReaderHost(
        subject: activeSubject!,
        tool: activeTool,
        sectionIndex: activeModuleSectionIndex,
        sectionResetTick: _moduleSectionNavTick,
        onSelectSection: (idx) {
          _moduleSectionNavTick++;
          _navigateTo(
            currentEntry.copyWith(
              moduleSectionIndex: idx,
              clearForoTopicId: true,
              clearPortafolioPractice: true,
              mensajeriaState: const MensajeriaViewRouteState(),
            ),
          );
        },
        selectedForoTopicId: activeForoTopicId,
        onSelectForoTopic: (topicId) {
          _navigateTo(
            currentEntry.copyWith(
              tool: MielToolKind.foro,
              foroTopicId: topicId,
              clearForoTopicId: topicId == null,
            ),
          );
        },
        mensajeriaState: currentEntry.mensajeriaState,
        onMensajeriaStateChanged: (nextState) {
          _navigateTo(currentEntry.copyWith(mensajeriaState: nextState));
        },
        selectedPortafolioPractice: currentEntry.portafolioPractice,
        hasControlledPortafolioPractice:
            currentEntry.portafolioPractice != null,
        onSelectPortafolioPractice: (practice) {
          _navigateTo(
            currentEntry.copyWith(
              portafolioPractice: practice,
              clearPortafolioPractice: practice == null,
            ),
          );
        },
        scrollController: _contentScrollController,
        inPageFindQuery: findState.query,
        nativeSearchFocusNode: _nativeSearchFocusNode,
        findFocusTick: _findFocusTick,
      ),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: palette.pageBackground,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    final contentArea = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (findState.isOpen)
          BrowserFindBar(
            initialQuery: findState.query,
            onQueryChanged: (query) {
              ref.read(browserFindProvider.notifier).setQuery(query);
            },
            onClose: () {
              ref.read(browserFindProvider.notifier).close();
            },
          ),
        Expanded(child: mainView),
      ],
    );

    final scaffold = Scaffold(
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _MielDoubleHeader(
              isMobileHeader: isMobileHeader,
              hasDesktopSidebar: hasDesktopSidebar,
              section: effectiveSection,
              session: session,
              subjects: subjects,
              activeSubject: activeSubject,
              activeTool: activeTool,
              unreadAlertsCount: unreadCount,
              canGoBack: historyState.canGoBack,
              canGoForward: historyState.canGoForward,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onGoHome: _goHome,
              onGoNovedades: _goNovedades,
              onGoBack: _goBack,
              onGoForward: _goForward,
              onReload: ({bool forceLive = false}) =>
                  _reloadActiveRoute(forceLive: forceLive),
              onOpenProfile: () => _openUserProfile(session, subjects),
              onSelectSubject: (subject) {
                final tools = subject.enabledTools;
                final nextTool = tools.contains(activeTool)
                    ? activeTool
                    : (tools.isNotEmpty
                          ? tools.first
                          : MielToolKind.contenidos);
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
              onGoAjustes: () =>
                  _goAjustes(initialTab: MielProfileTab.datosPersonales),
              onLogout: () => ref.read(appSessionProvider.notifier).logout(),
            ),

            const MielStatusBanner(),

            if (session.authPausedReason != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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

            Expanded(
              child: BrowserZoomViewport(
                zoomScale: session.uiZoomScale,
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
                    Expanded(child: contentArea),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _closeDrawerIfOpen();
            return;
          }
          if (ref.read(browserFindProvider).isOpen) {
            ref.read(browserFindProvider.notifier).close();
            return;
          }
          final canProceed = await confirmDiscardDirtyDraftsIfNeeded(
            context,
            ref.read(draftDirtyRegistryProvider),
          );
          if (!canProceed) return;

          if (ref.read(navigationHistoryProvider).canGoBack) {
            await _goBack();
            return;
          }
          if (context.mounted) {
            SystemNavigator.pop();
          }
        },
        child: BrowserNavigationHost(
          onBack: _goBack,
          onForward: _goForward,
          onReload: ({bool forceLive = false}) =>
              _reloadActiveRoute(forceLive: forceLive),
          onEscape: () {
            if (ref.read(browserFindProvider).isOpen) {
              ref.read(browserFindProvider.notifier).close();
              return;
            }
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              _closeDrawerIfOpen();
              return;
            }
          },
          onFindInPage: () {
            ref.read(browserFindProvider.notifier).open();
            _findFocusTick++;
            _nativeSearchFocusNode.requestFocus();
          },
          onGoHome: _goHome,
          onStepZoom: (delta) =>
              ref.read(appSessionProvider.notifier).stepUiZoomScale(delta),
          onResetZoom: () =>
              ref.read(appSessionProvider.notifier).resetUiZoomScale(),
          contentScrollController: _contentScrollController,
          child: scaffold,
        ),
      ),
    );
  }
}

/// Barra doble superior fiel a MIeL con hovers visibles en todos los controles:
/// 1) Barra de marca blanca/negra (`54px`) con perfil de usuario
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
    required this.canGoBack,
    required this.canGoForward,
    required this.onOpenDrawer,
    required this.onGoHome,
    required this.onGoNovedades,
    required this.onGoBack,
    required this.onGoForward,
    required this.onReload,
    required this.onOpenProfile,
    required this.onSelectSubject,
    required this.onSelectTool,
    required this.onSyncNow,
    required this.onToggleTheme,
    required this.onGoAjustes,
    required this.onLogout,
  });

  final bool isMobileHeader;
  final bool hasDesktopSidebar;
  final BrowserShellSection section;
  final AppSessionState session;
  final List<Subject> subjects;
  final Subject? activeSubject;
  final MielToolKind activeTool;
  final int unreadAlertsCount;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onOpenDrawer;
  final VoidCallback onGoHome;
  final VoidCallback onGoNovedades;
  final VoidCallback onGoBack;
  final VoidCallback onGoForward;
  final void Function({bool forceLive}) onReload;
  final VoidCallback onOpenProfile;
  final ValueChanged<Subject> onSelectSubject;
  final ValueChanged<MielToolKind> onSelectTool;
  final VoidCallback onSyncNow;
  final VoidCallback onToggleTheme;
  final VoidCallback onGoAjustes;
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
        // Fila 1: Barra de marca (54px) usando Material para hovers reales
        Material(
          color: palette.topBarBackground,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: isMobileHeader ? 62 : 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isMobileHeader
                    ? Center(
                        child: _HoverableBrandButton(onTap: onGoHome, size: 34),
                      )
                    : Row(
                        children: [
                          _HoverableBrandButton(onTap: onGoHome, size: 36),
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
                                    label: 'Mi perfil',
                                    color: palette.linkAccent,
                                    onTap: onOpenProfile,
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
                          _HoverableAvatarButton(
                            palette: palette,
                            avatarUrl: session.studentAvatarUrl,
                            onTap: onOpenProfile,
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
              if (session.showBrowserNavControls) ...[
                _NavIconAction(
                  tooltip: canGoBack
                      ? 'Atrás (Alt+← / Mouse 4)'
                      : 'Atrás (deshabilitado)',
                  icon: Icons.arrow_back,
                  onTap: canGoBack ? onGoBack : null,
                ),
                _NavIconAction(
                  tooltip: canGoForward
                      ? 'Adelante (Alt+→ / Mouse 5)'
                      : 'Adelante (deshabilitado)',
                  icon: Icons.arrow_forward,
                  onTap: canGoForward ? onGoForward : null,
                ),
                _NavIconAction(
                  tooltip: 'Recargar (F5 / Ctrl+R) [Shift = bypass caché]',
                  icon: Icons.refresh,
                  onTap: () => onReload(forceLive: false),
                ),
              ],
              _NavIconAction(
                tooltip: 'Menú principal (Materias activas)',
                icon: Icons.home,
                onTap: onGoHome,
              ),
              if (section == BrowserShellSection.module &&
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
                    BrowserShellSection.home => 'Menú principal',
                    BrowserShellSection.novedades => 'Notificaciones',
                    BrowserShellSection.ajustes => 'Menú principal',
                    BrowserShellSection.module => 'Menú principal',
                  },
                  onTap: onGoHome,
                ),
              ],

              const Spacer(),

              // Derecha: Sincronizar + Campana de notificaciones + Contraste claro/oscuro + Ajustes (+ Usuario/Salir en móvil)
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

              _NavIconAction(
                tooltip: 'Cambiar modo claro / oscuro',
                icon: Icons.brightness_4,
                onTap: onToggleTheme,
              ),

              _NavIconAction(
                tooltip: 'Ajustes y perfil',
                icon: Icons.settings,
                onTap: onGoAjustes,
              ),

              if (isMobileHeader) ...[
                _NavIconAction(
                  tooltip: 'Mi perfil',
                  icon: Icons.person,
                  onTap: onOpenProfile,
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
        if (session.showBrowserNavControls && session.isSyncing)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: palette.primary,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
      ],
    );
  }
}

class _HoverableBrandButton extends StatefulWidget {
  const _HoverableBrandButton({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  State<_HoverableBrandButton> createState() => _HoverableBrandButtonState();
}

class _HoverableBrandButtonState extends State<_HoverableBrandButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _hovered ? 0.80 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: LibreMielMark(size: widget.size),
          ),
        ),
      ),
    );
  }
}

class _HoverableAvatarButton extends StatefulWidget {
  const _HoverableAvatarButton({
    required this.palette,
    required this.avatarUrl,
    required this.onTap,
  });

  final MielPalette palette;
  final String avatarUrl;
  final VoidCallback onTap;

  @override
  State<_HoverableAvatarButton> createState() => _HoverableAvatarButtonState();
}

class _HoverableAvatarButtonState extends State<_HoverableAvatarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Mi perfil',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovered
                    ? widget.palette.linkAccent
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: MielAvatar(
              avatarUrl: widget.avatarUrl,
              radius: 17,
              fallbackBackgroundColor: _hovered
                  ? widget.palette.primary.withValues(alpha: 0.85)
                  : widget.palette.textMuted.withValues(alpha: 0.35),
              fallbackIconColor: _hovered
                  ? Colors.white
                  : widget.palette.pageBackground,
              fallbackIconSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopLink extends StatefulWidget {
  const _TopLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_TopLink> createState() => _TopLinkState();
}

class _TopLinkState extends State<_TopLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? palette.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.color,
              decoration: _hovered
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: widget.color,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text('·', style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

/// Contenedor reutilizable con estado hover claro para todos los ítems de la barra verde superior.
class _HoverableGreenNavTile extends StatefulWidget {
  const _HoverableGreenNavTile({required this.child, this.onTap, this.tooltip});

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  State<_HoverableGreenNavTile> createState() => _HoverableGreenNavTileState();
}

class _HoverableGreenNavTileState extends State<_HoverableGreenNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.onTap != null) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.onTap != null) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        color: _hovered && widget.onTap != null
            ? Colors.black.withValues(alpha: 0.18)
            : Colors.transparent,
        child: widget.onTap != null
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: widget.child,
              )
            : widget.child,
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }
    return content;
  }
}

class _NavIconAction extends StatelessWidget {
  const _NavIconAction({required this.tooltip, required this.icon, this.onTap});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _HoverableGreenNavTile(
      tooltip: tooltip,
      onTap: onTap,
      child: SizedBox(
        height: 40,
        width: 40,
        child: Icon(
          icon,
          size: 21,
          color: onTap != null ? Colors.white : Colors.white38,
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
    return _HoverableGreenNavTile(
      onTap: onTap,
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
    final activeList = subjects.where((s) => !s.isEffectivelyHidden).toList();
    final itemsList = activeList.isNotEmpty ? activeList : subjects;

    return _HoverableGreenNavTile(
      child: PopupMenuButton<String>(
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
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      activeSubject.breadcrumbLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.white,
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

    return _HoverableGreenNavTile(
      child: PopupMenuButton<MielToolKind>(
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
    required this.activeForoTopicId,
    required this.unreadAlertsCount,
    required this.onSelectHome,
    required this.onSelectNovedades,
    required this.onSelectAjustes,
    required this.onSelectModuleSection,
    required this.onSelectForoTopic,
    required this.onOpenBulkDownload,
    required this.onOpenExternal,
  });

  final BrowserShellSection section;
  final Subject? activeSubject;
  final MielToolKind activeTool;
  final int activeModuleSectionIndex;
  final String? activeForoTopicId;
  final int unreadAlertsCount;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectNovedades;
  final VoidCallback onSelectAjustes;
  final VoidCallback onOpenBulkDownload;
  final ValueChanged<int> onSelectModuleSection;
  final ValueChanged<String?> onSelectForoTopic;
  final ValueChanged<String> onOpenExternal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);

    // Dentro de un módulo (Fase 2), el sidebar replica el sub-menú del módulo en MIeL
    if (section == BrowserShellSection.module && activeSubject != null) {
      final items = mielSectionsForTool(activeTool);

      // En Foros, listar los temas abiertos de la materia (en vivo o desde caché local)
      final liveForoTopics = activeTool == MielToolKind.foro
          ? (ref.watch(foroTemasProvider(activeSubject!.idComision)).value ??
                const <ForumTopicSummary>[])
          : const <ForumTopicSummary>[];
      final cachedForoTopics =
          (activeTool == MielToolKind.foro && liveForoTopics.isEmpty)
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 14),
              children: [
                _SidebarHeading(title: activeTool.fullLabel, palette: palette),
                const SizedBox(height: 6),
                for (var i = 0; i < items.length; i++)
                  _SidebarItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected:
                        i == activeModuleSectionIndex &&
                        activeForoTopicId == null,
                    onTap: () => onSelectModuleSection(i),
                  ),
                if (liveForoTopics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final topic in liveForoTopics)
                    _SidebarItem(
                      icon: Icons.message,
                      label: topic.title,
                      selected: activeForoTopicId == topic.idTema,
                      onTap: () => onSelectForoTopic(topic.idTema),
                    ),
                ] else if (cachedForoTopics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final topic in cachedForoTopics.take(15))
                    _SidebarItem(
                      icon: Icons.message,
                      label: topic.summary.isNotEmpty
                          ? topic.summary
                          : 'Tema #${topic.itemId}',
                      selected: activeForoTopicId == topic.itemId,
                      onTap: () => onSelectForoTopic(topic.itemId),
                    ),
                ],
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Divider(color: palette.divider, height: 1),
                ),
                const SizedBox(height: 10),
                _SidebarItem(
                  icon: Icons.download_for_offline_outlined,
                  label: 'Respaldo offline',
                  selected: false,
                  onTap: onOpenBulkDownload,
                ),
                _SidebarItem(
                  icon: Icons.arrow_back,
                  label: 'Materias Activas',
                  selected: false,
                  onTap: onSelectHome,
                ),
              ],
            ),
          ),
          Divider(color: palette.divider, height: 1),
          _SidebarFooterLinks(onOpenExternal: onOpenExternal),
        ],
      );
    }

    // Menú lateral personalizado de LibreMIeL:
    // Utilidades (Materias Activas) + Funcionalidades (Ajustes, Notificaciones, Respaldo offline) + enlaces externos abajo
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 14),
            children: [
              _SidebarHeading(title: 'Utilidades', palette: palette),
              const SizedBox(height: 6),
              _SidebarItem(
                icon: Icons.home,
                label: 'Materias Activas',
                selected: section == BrowserShellSection.home,
                onTap: onSelectHome,
              ),
              const SizedBox(height: 22),
              _SidebarHeading(title: 'Funcionalidades', palette: palette),
              const SizedBox(height: 6),
              _SidebarItem(
                icon: Icons.tune,
                label: 'Ajustes',
                selected: section == BrowserShellSection.ajustes,
                onTap: onSelectAjustes,
              ),
              _SidebarItem(
                icon: Icons.notifications_active,
                label: 'Notificaciones',
                selected: section == BrowserShellSection.novedades,
                badgeCount: unreadAlertsCount,
                onTap: onSelectNovedades,
              ),
              _SidebarItem(
                icon: Icons.download_for_offline_outlined,
                label: 'Respaldo offline',
                selected: false,
                onTap: onOpenBulkDownload,
              ),
            ],
          ),
        ),
        Divider(color: palette.divider, height: 1),
        _SidebarFooterLinks(onOpenExternal: onOpenExternal),
      ],
    );
  }
}

const String _kLibreMielRepoUrl = 'https://github.com/Tiago-Pujia/LibreMIeL';
const String _kLibreMielWebsiteUrl = 'https://tiago-pujia.github.io/LibreMIeL/';
const String _kLibreMielReportIssuesUrl = 'https://wa.me/+5491135201875';

class _SidebarFooterLinks extends StatelessWidget {
  const _SidebarFooterLinks({required this.onOpenExternal});

  final ValueChanged<String> onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SidebarItem(
            icon: Icons.code,
            label: 'Repositorio GitHub',
            selected: false,
            onTap: () => onOpenExternal(_kLibreMielRepoUrl),
          ),
          _SidebarItem(
            icon: Icons.open_in_new,
            label: 'Abrir MIeL web',
            selected: false,
            onTap: () => onOpenExternal('$kMielBaseUrl/principal/interno/'),
          ),
          _SidebarItem(
            icon: Icons.bug_report_outlined,
            label: 'Reportar errores',
            selected: false,
            onTap: () => onOpenExternal(_kLibreMielReportIssuesUrl),
          ),
          _SidebarItem(
            icon: Icons.language,
            label: 'Sitio web',
            selected: false,
            onTap: () => onOpenExternal(_kLibreMielWebsiteUrl),
          ),
        ],
      ),
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
          fontSize: 24,
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
