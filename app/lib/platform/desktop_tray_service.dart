import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Gestión de bandeja del sistema (*system tray*) y ventana en Windows, macOS y Linux.
class DesktopTrayService with TrayListener, WindowListener {
  DesktopTrayService({required this.onQuit});

  final Future<void> Function() onQuit;

  bool _initialized = false;
  bool _trayReady = false;
  int _unreadCount = 0;

  static bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  /// Bandera global que indica si la aplicación fue invocada con `--minimized` o `--hidden`.
  static bool startMinimizedRequested = false;

  String _resolveIconPath(int unreadCount) {
    final hasUnread = unreadCount > 0;
    if (Platform.isWindows) {
      return hasUnread
          ? 'assets/icons/tray_icon_unread.ico'
          : 'assets/icons/tray_icon.ico';
    }
    return hasUnread
        ? 'assets/icons/tray_icon_unread.png'
        : 'assets/icons/tray_icon.png';
  }

  Future<void> _applyTrayState() async {
    await trayManager.setIcon(_resolveIconPath(_unreadCount));
    final showLabel = _unreadCount > 0
        ? 'Abrir LibreMIeL ($_unreadCount sin leer)'
        : 'Abrir LibreMIeL';
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: showLabel),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Salir completamente'),
        ],
      ),
    );

    if (!Platform.isLinux) {
      try {
        final tooltip = _unreadCount > 0
            ? 'LibreMIeL — $_unreadCount notificación(es) sin leer'
            : 'LibreMIeL — Monitor de novedades MIeL';
        await trayManager.setToolTip(tooltip);
      } catch (_) {
        // Tooltip opcional; no afecta el menú contextual.
      }
    }
  }

  /// Actualiza el ícono y menú de la bandeja del sistema según la cantidad de notificaciones no leídas.
  Future<void> setUnreadCount(int count) async {
    if (_unreadCount == count && _trayReady) return;
    _unreadCount = count;
    if (!_trayReady) return;
    try {
      await _applyTrayState();
    } catch (e) {
      debugPrint('DesktopTrayService: error actualizando ícono de bandeja: $e');
    }
  }

  Future<void> initialize({bool? startMinimized}) async {
    if (!isDesktop || _initialized) return;
    final minimized = startMinimized ?? startMinimizedRequested;

    // 1. Inicializar bandeja del sistema primero.
    // IMPORTANTE: en Linux `tray_manager` (libayatana-appindicator3) NO implementa
    // `setToolTip` y lanza MissingPluginException; por eso debe llamarse
    // `setContextMenu` siempre de forma independiente antes de cualquier tooltip.
    try {
      trayManager.addListener(this);
      await _applyTrayState();
      _trayReady = true;
    } catch (e) {
      debugPrint('DesktopTrayService: no se pudo inicializar la bandeja: $e');
      _trayReady = false;
    }

    // 2. Configurar controles de ventana.
    // Solo interceptamos el cierre de ventana para minimizar a bandeja si el menú
    // de la bandeja quedó registrado correctamente (evita dejar procesos atrapados).
    try {
      await windowManager.ensureInitialized();
      await windowManager.setTitle('LibreMIeL');
      await windowManager.setMinimumSize(const Size(720, 520));
      await windowManager.setPreventClose(_trayReady);
      windowManager.addListener(this);
      if (minimized) {
        await windowManager.hide();
      }
    } catch (e) {
      debugPrint('DesktopTrayService: error configurando window_manager: $e');
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    try {
      await windowManager.setPreventClose(false);
    } catch (_) {}
    if (_trayReady) {
      try {
        await trayManager.destroy();
      } catch (_) {}
      _trayReady = false;
    }
    _initialized = false;
  }

  Future<void> _quitCompletely() async {
    try {
      await trayManager.destroy();
    } catch (_) {}
    try {
      await windowManager.setPreventClose(false);
    } catch (_) {}
    try {
      await onQuit();
    } catch (_) {}
    try {
      await windowManager.destroy();
    } catch (_) {}
    exit(0);
  }

  @override
  void onWindowClose() async {
    if (_trayReady) {
      // Minimiza a bandeja para seguir monitoreando novedades en segundo plano
      await windowManager.hide();
    } else {
      await _quitCompletely();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() async {
    try {
      await trayManager.popUpContextMenu();
    } catch (_) {
      // En Linux AppIndicator abre el menú GTK automáticamente desde el sistema.
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await windowManager.show();
        await windowManager.focus();
      case 'quit':
        await _quitCompletely();
    }
  }
}
