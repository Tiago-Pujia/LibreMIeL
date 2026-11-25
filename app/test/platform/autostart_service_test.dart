import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/platform/autostart_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AutostartService', () {
    test(
      'en Linux crea, detecta y elimina correctamente el archivo XDG .desktop',
      () async {
        if (!Platform.isLinux) return;
        final tmp = await Directory.systemTemp.createTemp('libremiel_auto_');
        addTearDown(() async {
          if (tmp.existsSync()) await tmp.delete(recursive: true);
        });

        final service = AutostartService(
          linuxConfigHome: tmp.path,
          executableOverride: '/opt/libremiel/libremiel',
        );

        expect(service.isSupported, isTrue);
        expect(await service.isEnabled(), isFalse);

        final enabled = await service.setEnabled(true);
        expect(enabled, isTrue);
        expect(await service.isEnabled(), isTrue);

        final desktopFile = File(
          p.join(
            tmp.path,
            'autostart',
            'io.github.tiago_pujia.libremiel.desktop',
          ),
        );
        expect(desktopFile.existsSync(), isTrue);
        final contents = await desktopFile.readAsString();
        expect(contents, contains('Exec=/opt/libremiel/libremiel --minimized'));
        expect(contents, contains('X-GNOME-Autostart-enabled=true'));

        final disabled = await service.setEnabled(false);
        expect(disabled, isFalse);
        expect(await service.isEnabled(), isFalse);
        expect(desktopFile.existsSync(), isFalse);
      },
    );
  });
}
