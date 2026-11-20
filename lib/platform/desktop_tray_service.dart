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

  static bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  Future<void> initialize() async {
    if (!isDesktop || _initialized) return;

    try {
      await windowManager.ensureInitialized();
      await windowManager.setTitle('LibreMIEL');
      await windowManager.setMinimumSize(const Size(720, 520));
      await windowManager.setPreventClose(true);
      windowManager.addListener(this);
    } catch (_) {
      // Si el entorno gráfico no soporta controles avanzados de ventana, continuar.
    }

    try {
      trayManager.addListener(this);
      await trayManager.setIcon(
        Platform.isWindows
            ? 'windows/runner/resources/app_icon.ico'
            : 'assets/icons/libremiel.png',
      );
      await trayManager.setToolTip('LibreMIEL — Monitor de novedades MIEL');
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
    } catch (_) {
      // En entornos headless o WMs Linux sin bandeja del sistema, operar en modo ventana normal.
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _initialized = false;
  }

  @override
  void onWindowClose() async {
    // Minimiza a bandeja para seguir monitoreando novedades en segundo plano
    await windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
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
        await windowManager.setPreventClose(false);
        await onQuit();
        await windowManager.destroy();
    }
  }
}
