import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Gestiona el inicio automático de LibreMIEL al encender el sistema en escritorio
/// (Linux XDG Autostart, Windows HKCU Run y macOS LaunchAgents).
class AutostartService {
  AutostartService({
    this.linuxConfigHome,
    this.macOsHome,
    this.executableOverride,
    ProcessRunner? processRunner,
  }) : _runProcess = processRunner ?? Process.run;

  static const String _desktopEntryId = 'io.github.tiago_pujia.libremiel';
  static const String _windowsRegKey =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _windowsValueName = 'LibreMIEL';

  final String? linuxConfigHome;
  final String? macOsHome;
  final String? executableOverride;
  final ProcessRunner _runProcess;

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  String _resolveLaunchCommand() {
    if (executableOverride != null && executableOverride!.isNotEmpty) {
      return executableOverride!;
    }
    if (Platform.isLinux) {
      final appImage = Platform.environment['APPIMAGE'];
      if (appImage != null && appImage.isNotEmpty) {
        return appImage;
      }
    }
    return Platform.resolvedExecutable;
  }

  File _linuxDesktopFile() {
    final configBase =
        linuxConfigHome ??
        Platform.environment['XDG_CONFIG_HOME'] ??
        p.join(Platform.environment['HOME'] ?? '', '.config');
    return File(p.join(configBase, 'autostart', '$_desktopEntryId.desktop'));
  }

  File _macOsPlistFile() {
    final home = macOsHome ?? Platform.environment['HOME'] ?? '';
    return File(
      p.join(home, 'Library', 'LaunchAgents', '$_desktopEntryId.plist'),
    );
  }

  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      if (Platform.isLinux) {
        return _linuxDesktopFile().existsSync();
      }
      if (Platform.isMacOS) {
        return _macOsPlistFile().existsSync();
      }
      if (Platform.isWindows) {
        final res = await _runProcess('reg', [
          'query',
          _windowsRegKey,
          '/v',
          _windowsValueName,
        ]);
        return res.exitCode == 0;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!isSupported) return false;
    try {
      if (Platform.isLinux) {
        final file = _linuxDesktopFile();
        if (!enabled) {
          if (file.existsSync()) file.deleteSync();
          return false;
        }
        await file.parent.create(recursive: true);
        final execPath = _resolveLaunchCommand();
        final quotedExec = execPath.contains(' ') ? '"$execPath"' : execPath;
        await file.writeAsString(
          '[Desktop Entry]\n'
          'Type=Application\n'
          'Version=1.0\n'
          'Name=LibreMIEL\n'
          'Comment=Cliente libre para MIeL (UNLaM)\n'
          'Exec=$quotedExec\n'
          'Icon=$_desktopEntryId\n'
          'Terminal=false\n'
          'StartupNotify=false\n'
          'X-GNOME-Autostart-enabled=true\n',
        );
        return true;
      }

      if (Platform.isMacOS) {
        final file = _macOsPlistFile();
        if (!enabled) {
          if (file.existsSync()) file.deleteSync();
          return false;
        }
        await file.parent.create(recursive: true);
        final execPath = _escapeXml(_resolveLaunchCommand());
        await file.writeAsString(
          '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
          '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
          '<plist version="1.0">\n'
          '<dict>\n'
          '  <key>Label</key>\n'
          '  <string>$_desktopEntryId</string>\n'
          '  <key>ProgramArguments</key>\n'
          '  <array>\n'
          '    <string>$execPath</string>\n'
          '  </array>\n'
          '  <key>RunAtLoad</key>\n'
          '  <true/>\n'
          '</dict>\n'
          '</plist>\n',
        );
        return true;
      }

      if (Platform.isWindows) {
        if (!enabled) {
          await _runProcess('reg', [
            'delete',
            _windowsRegKey,
            '/v',
            _windowsValueName,
            '/f',
          ]);
          return false;
        }
        final execPath = _resolveLaunchCommand();
        final res = await _runProcess('reg', [
          'add',
          _windowsRegKey,
          '/v',
          _windowsValueName,
          '/t',
          'REG_SZ',
          '/d',
          '"$execPath"',
          '/f',
        ]);
        return res.exitCode == 0;
      }
    } catch (_) {
      return isEnabled();
    }
    return false;
  }

  String _escapeXml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
