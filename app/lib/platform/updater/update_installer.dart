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
  static Future<InstallLaunchResult> install({
    required File downloadedFile,
    required ReleaseInfo release,
    Future<void> Function()? beforeExit,
  }) async {
    if (kIsWeb) return InstallLaunchResult.launchedExternalInstaller;

    if (Platform.isWindows) {
      return _installWindows(downloadedFile, beforeExit: beforeExit);
    } else if (Platform.isAndroid) {
      return _installAndroid(downloadedFile);
    } else if (Platform.isLinux) {
      return _installLinux(downloadedFile, beforeExit: beforeExit);
    } else if (Platform.isMacOS) {
      return _installMacOs(downloadedFile);
    }
    return InstallLaunchResult.launchedExternalInstaller;
  }

  static Future<InstallLaunchResult> _installWindows(
    File file, {
    Future<void> Function()? beforeExit,
  }) async {
    if (file.path.toLowerCase().endsWith('.exe')) {
      // Ejecución silenciosa con Inno Setup: CloseApplications cierra instancias
      // residuales y la entrada `[Run] Check: WizardSilent` relanza una sola vez.
      await Process.start(file.path, [
        '/SILENT',
        '/CLOSEAPPLICATIONS',
      ], mode: ProcessStartMode.detached);
      if (beforeExit != null) {
        try {
          await beforeExit();
        } catch (_) {}
      }
      exit(0);
    } else {
      // Portable zip: abrir la carpeta que lo contiene
      await Process.start('explorer.exe', ['/select,', file.path]);
      return InstallLaunchResult.launchedExternalInstaller;
    }
  }

  static Future<InstallLaunchResult> _installAndroid(File file) async {
    final canInstall =
        await _androidChannel.invokeMethod<bool>('canRequestPackageInstalls') ??
        true;

    if (!canInstall) {
      await _androidChannel.invokeMethod('openInstallPermissionSettings');
      return InstallLaunchResult.needsAndroidInstallPermission;
    }

    await _androidChannel.invokeMethod('installApk', {'apkPath': file.path});
    return InstallLaunchResult.launchedExternalInstaller;
  }

  static Future<InstallLaunchResult> _installLinux(
    File file, {
    Future<void> Function()? beforeExit,
  }) async {
    final kind = AssetResolver.detectLinuxInstallKind();

    if (kind == LinuxInstallKind.appImage) {
      final appImagePath = Platform.environment['APPIMAGE'];
      if (appImagePath != null && appImagePath.isNotEmpty) {
        await replaceAppImageAtomically(
          downloadedFile: file,
          targetAppImagePath: appImagePath,
        );

        // Relanzar el nuevo AppImage desacoplado
        await Process.start(appImagePath, [], mode: ProcessStartMode.detached);
        if (beforeExit != null) {
          try {
            await beforeExit();
          } catch (_) {}
        }
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
    return InstallLaunchResult.launchedExternalInstaller;
  }

  /// Reemplaza un AppImage de forma atómica incluso entre distintos sistemas de
  /// archivos (`/tmp` vs `/home`) sin escribir jamás sobre el archivo montado
  /// en ejecución (evita `ETXTBSY` y corrupción de SquashFS).
  @visibleForTesting
  static Future<void> replaceAppImageAtomically({
    required File downloadedFile,
    required String targetAppImagePath,
  }) async {
    await Process.run('chmod', ['+x', downloadedFile.path]);

    final target = File(targetAppImagePath);
    try {
      await downloadedFile.rename(target.path);
    } on FileSystemException {
      // Distintos filesystems (EXDEV): copiar a archivo temporal en el MISMO
      // directorio destino, marcar ejecutable y renombrar atómicamente.
      final staged = File(
        '${target.path}.update.${DateTime.now().millisecondsSinceEpoch}.new',
      );
      try {
        await downloadedFile.copy(staged.path);
        await Process.run('chmod', ['+x', staged.path]);
        await staged.rename(target.path);
        try {
          if (await downloadedFile.exists()) {
            await downloadedFile.delete();
          }
        } catch (_) {}
      } catch (_) {
        try {
          if (await staged.exists()) {
            await staged.delete();
          }
        } catch (_) {}
        rethrow;
      }
    }
  }

  static Future<InstallLaunchResult> _installMacOs(File file) async {
    if (file.path.toLowerCase().endsWith('.dmg')) {
      await Process.start('open', [file.path], mode: ProcessStartMode.detached);
    } else {
      // Portable zip: abrir con Archive Utility o mostrar en Finder
      await Process.start('open', [
        '-R',
        file.path,
      ], mode: ProcessStartMode.detached);
    }
    return InstallLaunchResult.launchedExternalInstaller;
  }
}
