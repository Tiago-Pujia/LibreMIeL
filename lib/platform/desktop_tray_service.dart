import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Gestión de bandeja del sistema (*system tray*) y ventana en Windows, macOS y Linux.
class DesktopTrayService with TrayListener, WindowListener {
  DesktopTrayService({required this.onSyncNow, required this.onQuit});

  final Future<void> Function() onSyncNow;
  final Future<void> Function() onQuit;

  bool _initialized = false;
  bool _trayReady = false;

  static bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  Future<void> initialize() async {
    if (!isDesktop || _initialized) return;

    // 1. Inicializar bandeja del sistema primero.
    // IMPORTANTE: en Linux `tray_manager` (libayatana-appindicator3) NO implementa
    // `setToolTip` y lanza MissingPluginException; por eso debe llamarse
    // `setContextMenu` siempre de forma independiente antes de cualquier tooltip.
    try {
      trayManager.addListener(this);
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/icons/libremiel.ico'
            : 'assets/icons/libremiel.png',
      );
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show', label: 'Abrir LibreMIEL'),
            MenuItem(key: 'sync', label: 'Revisar novedades ahora'),
            MenuItem.separator(),
            MenuItem(key: 'quit', label: 'Salir completamente'),
          ],
        ),
      );
      _trayReady = true;
    } catch (e) {
      debugPrint('DesktopTrayService: no se pudo inicializar la bandeja: $e');
      _trayReady = false;
    }

    if (_trayReady && !Platform.isLinux) {
      try {
        await trayManager.setToolTip('LibreMIEL — Monitor de novedades MIeL');
      } catch (_) {
        // Tooltip opcional; no afecta el menú contextual.
      }
    }

    // 2. Configurar controles de ventana.
    // Solo interceptamos el cierre de ventana para minimizar a bandeja si el menú
    // de la bandeja quedó registrado correctamente (evita dejar procesos atrapados).
    try {
      await windowManager.ensureInitialized();
      await windowManager.setTitle('LibreMIEL');
      await windowManager.setMinimumSize(const Size(720, 520));
      await windowManager.setPreventClose(_trayReady);
      windowManager.addListener(this);
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
      case 'sync':
        await onSyncNow();
      case 'quit':
        await _quitCompletely();
    }
  }
}
