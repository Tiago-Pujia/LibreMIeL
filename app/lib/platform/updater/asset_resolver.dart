import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'update_models.dart';

/// Resolvedor determinista del artefacto de actualización adecuado para el entorno actual.
class AssetResolver {
  static const MethodChannel _androidChannel = MethodChannel(
    'io.github.tiago_pujia.libremiel/updater',
  );

  /// Detecta el tipo de instalación activa en Linux.
  static LinuxInstallKind detectLinuxInstallKind() {
    if (!kIsWeb && Platform.isLinux) {
      if (Platform.environment['APPIMAGE'] != null &&
          Platform.environment['APPIMAGE']!.isNotEmpty) {
        return LinuxInstallKind.appImage;
      }

      final exec = Platform.resolvedExecutable;
      if (exec.startsWith('/opt/libremiel') || exec.startsWith('/usr/')) {
        if (File('/etc/debian_version').existsSync()) {
          return LinuxInstallKind.deb;
        }
        if (File('/etc/redhat-release').existsSync() ||
            File('/etc/fedora-release').existsSync()) {
          return LinuxInstallKind.rpm;
        }
        if (File('/etc/arch-release').existsSync()) {
          return LinuxInstallKind.arch;
        }
        return LinuxInstallKind.deb;
      }
    }
    return LinuxInstallKind.portable;
  }

  /// Obtiene la lista de ABIs soportadas en Android en orden de preferencia.
  static Future<List<String>> getAndroidSupportedAbis() async {
    if (kIsWeb || !Platform.isAndroid) return const [];
    try {
      final res = await _androidChannel.invokeMethod<List<dynamic>>(
        'getSupportedAbis',
      );
      if (res != null) {
        return res.map((e) => e.toString().trim()).toList();
      }
    } catch (_) {}
    return const ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
  }

  /// Detecta si el sistema operativo subyacente es ARM64 / AArch64.
  static bool isArm64Architecture() {
    final v = Platform.version.toLowerCase();
    final uname = Platform.environment['HOSTTYPE']?.toLowerCase() ?? '';
    return v.contains('arm64') ||
        v.contains('aarch64') ||
        uname.contains('arm64') ||
        uname.contains('aarch64');
  }

  /// Selecciona el asset más adecuado de la lista de assets de un release en GitHub.
  /// Cada elemento en [assets] es un mapa JSON con claves `name`, `size`, `browser_download_url`.
  static Map<String, dynamic>? selectBestAsset({
    required List<Map<String, dynamic>> assets,
    String? overrideOs, // 'windows', 'android', 'linux', 'macos'
    bool? overrideIsArm64,
    List<String>? overrideAndroidAbis,
    LinuxInstallKind? overrideLinuxKind,
  }) {
    if (assets.isEmpty) return null;

    final os =
        overrideOs ??
        (Platform.isWindows
            ? 'windows'
            : Platform.isAndroid
            ? 'android'
            : Platform.isLinux
            ? 'linux'
            : Platform.isMacOS
            ? 'macos'
            : 'unknown');

    final isArm64 = overrideIsArm64 ?? isArm64Architecture();

    switch (os) {
      case 'windows':
        return _selectWindowsAsset(assets, isArm64: isArm64);
      case 'android':
        return _selectAndroidAsset(
          assets,
          supportedAbis:
              overrideAndroidAbis ??
              const ['arm64-v8a', 'armeabi-v7a', 'x86_64'],
        );
      case 'linux':
        return _selectLinuxAsset(
          assets,
          isArm64: isArm64,
          kind: overrideLinuxKind ?? detectLinuxInstallKind(),
        );
      case 'macos':
        return _selectMacOsAsset(assets);
      default:
        return null;
    }
  }

  static Map<String, dynamic>? _selectWindowsAsset(
    List<Map<String, dynamic>> assets, {
    required bool isArm64,
  }) {
    final targetArch = isArm64 ? 'arm64' : 'x64';

    // 1. Preferir instalador .exe
    final installer = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('windows') &&
          name.contains(targetArch) &&
          name.endsWith('-setup.exe');
    }, orElse: () => const {});
    if (installer.isNotEmpty) return installer;

    // Fallback instalador x64 en general
    final fallbackExe = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('windows') && name.endsWith('.exe');
    }, orElse: () => const {});
    if (fallbackExe.isNotEmpty) return fallbackExe;

    // Fallback portable .zip
    final zip = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('windows') &&
          name.contains(targetArch) &&
          name.endsWith('.zip');
    }, orElse: () => const {});
    if (zip.isNotEmpty) return zip;

    return null;
  }

  static Map<String, dynamic>? _selectAndroidAsset(
    List<Map<String, dynamic>> assets, {
    required List<String> supportedAbis,
  }) {
    // 1. Buscar coincidencia exacta por ABI preferida del dispositivo
    for (final abi in supportedAbis) {
      final match = assets.firstWhere((a) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        return name.contains('android') &&
            name.contains(abi.toLowerCase()) &&
            name.endsWith('.apk');
      }, orElse: () => const {});
      if (match.isNotEmpty) return match;
    }

    // 2. Fallback APK Universal
    final universal = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('android') &&
          name.contains('universal') &&
          name.endsWith('.apk');
    }, orElse: () => const {});
    if (universal.isNotEmpty) return universal;

    // 3. Cualquier APK disponible
    final anyApk = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('android') && name.endsWith('.apk');
    }, orElse: () => const {});
    if (anyApk.isNotEmpty) return anyApk;

    return null;
  }

  static Map<String, dynamic>? _selectLinuxAsset(
    List<Map<String, dynamic>> assets, {
    required bool isArm64,
    required LinuxInstallKind kind,
  }) {
    final flutterArch = isArm64 ? 'arm64' : 'x64';
    final linuxArch = isArm64 ? 'aarch64' : 'x86_64';
    final debArch = isArm64 ? 'arm64' : 'amd64';

    switch (kind) {
      case LinuxInstallKind.appImage:
        final appImage = assets.firstWhere((a) {
          final name = (a['name'] as String? ?? '').toLowerCase();
          return name.contains('linux') &&
              (name.contains(flutterArch) || name.contains(linuxArch)) &&
              name.endsWith('.appimage');
        }, orElse: () => const {});
        if (appImage.isNotEmpty) return appImage;
        break;

      case LinuxInstallKind.deb:
        final deb = assets.firstWhere((a) {
          final name = (a['name'] as String? ?? '').toLowerCase();
          return name.contains('linux') &&
              name.contains(debArch) &&
              name.endsWith('.deb');
        }, orElse: () => const {});
        if (deb.isNotEmpty) return deb;
        break;

      case LinuxInstallKind.rpm:
        final rpm = assets.firstWhere((a) {
          final name = (a['name'] as String? ?? '').toLowerCase();
          return name.contains('linux') &&
              name.contains(linuxArch) &&
              name.endsWith('.rpm');
        }, orElse: () => const {});
        if (rpm.isNotEmpty) return rpm;
        break;

      case LinuxInstallKind.arch:
        final archPkg = assets.firstWhere((a) {
          final name = (a['name'] as String? ?? '').toLowerCase();
          return name.contains('linux') &&
              name.contains(linuxArch) &&
              name.endsWith('.pkg.tar.zst');
        }, orElse: () => const {});
        if (archPkg.isNotEmpty) return archPkg;
        break;

      case LinuxInstallKind.portable:
        break;
    }

    // Fallback Portable .tar.gz
    final portable = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('linux') &&
          name.contains(flutterArch) &&
          name.endsWith('.tar.gz');
    }, orElse: () => const {});
    if (portable.isNotEmpty) return portable;

    // Fallback AppImage si portable no está
    final anyAppImage = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('linux') && name.endsWith('.appimage');
    }, orElse: () => const {});
    if (anyAppImage.isNotEmpty) return anyAppImage;

    return null;
  }

  static Map<String, dynamic>? _selectMacOsAsset(
    List<Map<String, dynamic>> assets,
  ) {
    // 1. Preferir DMG Universal
    final dmg = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('macos') && name.endsWith('.dmg');
    }, orElse: () => const {});
    if (dmg.isNotEmpty) return dmg;

    // 2. Fallback ZIP Portable Universal
    final zip = assets.firstWhere((a) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      return name.contains('macos') && name.endsWith('.zip');
    }, orElse: () => const {});
    if (zip.isNotEmpty) return zip;

    return null;
  }
}
