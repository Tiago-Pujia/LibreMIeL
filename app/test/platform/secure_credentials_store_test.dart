import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/platform/secure_credentials_store.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureCredentialsStore (Fase 5 — Sesión Permanente)', () {
    late Directory tempDir;
    late _MockSecureStorage mockStorage;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('libremiel_creds_test_');
      mockStorage = _MockSecureStorage();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('guarda credenciales en llavero y archivo .env privado con escapes seguros, y borra ambos en clear()', () async {
      final mem = <String, String>{};
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((inv) async {
        mem[inv.namedArguments[#key] as String] =
            inv.namedArguments[#value] as String;
      });
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((inv) async => mem[inv.namedArguments[#key] as String]);
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((inv) async {
            mem.remove(inv.namedArguments[#key] as String);
          });

      final store = SecureCredentialsStore(
        storage: mockStorage,
        supportDirResolver: () async => tempDir,
        enableLocalEnvFile: true,
      );

      const creds = MielCredentials(
        username: '12345678',
        password: r'Clave#"Compleja$Con\Escapes!',
      );
      await store.save(creds);

      final envFile = File(p.join(tempDir.path, '.env'));
      expect(envFile.existsSync(), isTrue);
      final rawEnv = await envFile.readAsString();
      expect(rawEnv, contains('MIEL_USUARIO='));
      expect(rawEnv, contains('MIEL_CLAVE='));

      // Lectura cuando el llavero funciona
      final read1 = await store.read();
      expect(read1?.username, '12345678');
      expect(read1?.password, creds.password);
      expect(store.usingEnvFallbackOnly, isFalse);

      // Si el llavero falla temporalmente, recupera automáticamente desde .env
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenThrow(Exception('keyring locked'));
      final read2 = await store.read();
      expect(read2?.username, '12345678');
      expect(read2?.password, creds.password);
      expect(store.usingEnvFallbackOnly, isTrue);

      // Al cerrar sesión se eliminan tanto llavero como .env
      await store.clear();
      expect(envFile.existsSync(), isFalse);
      expect(mem, isEmpty);
    });

    test('migra automáticamente credenciales legadas (.creds.dat/.creds.key) hacia .env', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(Exception('no keyring'));

      final payload = utf8.encode(
        jsonEncode({'u': '99887766', 'p': 'PassLegada123'}),
      );
      final key = List<int>.filled(payload.length, 42);
      final masked = List<int>.generate(
        payload.length,
        (i) => payload[i] ^ key[i],
      );
      File(p.join(tempDir.path, '.creds.dat')).writeAsBytesSync(masked);
      File(p.join(tempDir.path, '.creds.key')).writeAsBytesSync(key);

      final store = SecureCredentialsStore(
        storage: mockStorage,
        supportDirResolver: () async => tempDir,
        enableLocalEnvFile: true,
      );

      final migrated = await store.read();
      expect(migrated?.username, '99887766');
      expect(migrated?.password, 'PassLegada123');
      expect(File(p.join(tempDir.path, '.env')).existsSync(), isTrue);
      expect(File(p.join(tempDir.path, '.creds.dat')).existsSync(), isFalse);
      expect(File(p.join(tempDir.path, '.creds.key')).existsSync(), isFalse);
    });

    test('parseDotEnvLines soporta comentarios, export y comillas', () {
      final parsed = parseDotEnvLines([
        '# Comentario',
        '',
        'export MIEL_USUARIO="11223344"',
        "MIEL_CLAVE='mi_clave_#1'",
      ]);
      expect(parsed['MIEL_USUARIO'], '11223344');
      expect(parsed['MIEL_CLAVE'], 'mi_clave_#1');
    });
  });
}
