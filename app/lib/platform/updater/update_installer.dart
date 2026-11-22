import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'asset_resolver.dart';
import 'update_models.dart';

/// Ejecutor de la instalación de una actualización descargada y verificada.
class UpdateInstaller {
  static const MethodChannel _androidChannel = MethodChannel(
    'io.github.tiago_pujia.libremiel/updater',
  );

  /// Ejecuta el proceso de instalación según el sistema operativo.
  static Future<void> install({
    required File downloadedFile,
    required ReleaseInfo release,
  }) async {
    if (kIsWeb) return;

    if (Platform.isWindows) {
      await _installWindows(downloadedFile);
    } else if (Platform.isAndroid) {
      await _installAndroid(downloadedFile);
    } else if (Platform.isLinux) {
      await _installLinux(downloadedFile);
    } else if (Platform.isMacOS) {
      await _installMacOs(downloadedFile);
    }
  }

  static Future<void> _installWindows(File file) async {
    if (file.path.toLowerCase().endsWith('.exe')) {
      // Ejecución silenciosa con relanzamiento automático de Inno Setup
      await Process.start(file.path, [
        '/SILENT',
        '/CLOSEAPPLICATIONS',
        '/RESTARTAPPLICATIONS',
      ], mode: ProcessStartMode.detached);
      exit(0);
    } else {
      // Portable zip: abrir la carpeta que lo contiene
      await Process.start('explorer.exe', ['/select,', file.path]);
    }
  }

  static Future<void> _installAndroid(File file) async {
    final canInstall =
        await _androidChannel.invokeMethod<bool>('canRequestPackageInstalls') ??
        true;

    if (!canInstall) {
      await _androidChannel.invokeMethod('openInstallPermissionSettings');
      // No continuar hasta que el usuario conceda el permiso
      return;
    }

    await _androidChannel.invokeMethod('installApk', {'apkPath': file.path});
  }

  static Future<void> _installLinux(File file) async {
    final kind = AssetResolver.detectLinuxInstallKind();

    if (kind == LinuxInstallKind.appImage) {
      final appImagePath = Platform.environment['APPIMAGE'];
      if (appImagePath != null && appImagePath.isNotEmpty) {
        // 1. Dar permisos de ejecución al nuevo AppImage
        await Process.run('chmod', ['+x', file.path]);

        // 2. Reemplazo atómico del AppImage actual
        final target = File(appImagePath);
        try {
          // En Linux se puede renombrar sobre el archivo en ejecución de forma atómica
          await file.rename(target.path);
        } catch (_) {
          // Si están en distintos filesystems (ej. /tmp vs /home), copiar y reemplazar
          await file.copy(target.path);
          await Process.run('chmod', ['+x', target.path]);
        }

        // 3. Relanzar el nuevo AppImage desacoplado
        await Process.start(target.path, [], mode: ProcessStartMode.detached);
        exit(0);
      }
    }

    // Para paquetes .deb, .rpm, .pkg.tar.zst o portable: abrir con el gestor gráfico
    try {
      await Process.start('xdg-open', [
        file.path,
      ], mode: ProcessStartMode.detached);
    } catch (_) {
      // Si falla xdg-open, abrir el directorio contenedor
      await Process.start('xdg-open', [
        file.parent.path,
      ], mode: ProcessStartMode.detached);
    }
  }

  static Future<void> _installMacOs(File file) async {
    if (file.path.toLowerCase().endsWith('.dmg')) {
      await Process.start('open', [file.path], mode: ProcessStartMode.detached);
    } else {
      // Portable zip: abrir con Archive Utility o mostrar en Finder
      await Process.start('open', [
        '-R',
        file.path,
      ], mode: ProcessStartMode.detached);
    }
  }
}
