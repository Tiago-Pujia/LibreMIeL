import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/platform/secure_credentials_store.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureCredentialsStore Linux fallback', () {
    late MockFlutterSecureStorage mockStorage;
    late Directory tempDir;
    late SecureCredentialsStore store;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      tempDir = Directory.systemTemp.createTempSync('libremiel_creds_test_');
      store = SecureCredentialsStore(
        storage: mockStorage,
        supportDirResolver: () async => tempDir,
        enableLinuxFileFallback: true,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'guarda, lee y borra en fallback chmod 600 cuando libsecret falla',
      () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('org.freedesktop.secrets not provided'));
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenThrow(Exception('org.freedesktop.secrets not provided'));
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenThrow(Exception('org.freedesktop.secrets not provided'));

        const creds = MielCredentials(
          username: '12345678',
          password: 'mi_clave_test',
        );
        await store.save(creds);

        expect(store.usingLinuxFallback, isTrue);

        final loaded = await store.read();
        expect(loaded, isNotNull);
        expect(loaded!.username, '12345678');
        expect(loaded.password, 'mi_clave_test');

        // Verifica que el archivo en disco no contiene la contraseña en texto plano
        final rawBytes = File('${tempDir.path}/.creds.dat').readAsBytesSync();
        expect(
          String.fromCharCodes(rawBytes),
          isNot(contains('mi_clave_test')),
        );

        await store.clear();
        expect(await store.read(), isNull);
      },
    );
  });
}
