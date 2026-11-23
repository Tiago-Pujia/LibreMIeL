import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/platform/updater/sha256_verifier.dart';

void main() {
  group('Sha256Verifier tests', () {
    test('parseSha256Sums correctly parses standard sha256sum outputs', () {
      const sample = '''
# Checksums oficiales de LibreMIeL v0.2.0
5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03  LibreMIeL-0.2.0-linux-x64.AppImage
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 *LibreMIeL-0.2.0-windows-x64-setup.exe
a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90  LibreMIeL-0.2.0-android-universal.apk

# Línea vacía arriba y abajo
''';

      final map = Sha256Verifier.parseSha256Sums(sample);
      expect(map.length, 3);
      expect(
        map['LibreMIeL-0.2.0-linux-x64.AppImage'],
        '5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03',
      );
      expect(
        map['LibreMIeL-0.2.0-windows-x64-setup.exe'],
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        map['LibreMIeL-0.2.0-android-universal.apk'],
        'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
      );
    });

    test('computeFileSha256 and verifyOrDelete with valid file', () async {
      final tempDir = Directory.systemTemp.createTempSync('sha_test_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      final testFile = File('${tempDir.path}/test_asset.bin');
      testFile.writeAsStringSync('Contenido binario de prueba LibreMIeL');

      final expectedHash = sha256
          .convert(testFile.readAsBytesSync())
          .toString();
      final computed = await Sha256Verifier.computeFileSha256(testFile);
      expect(computed, expectedHash);

      // verifyOrDelete no debe lanzar excepción si coincide
      await expectLater(
        Sha256Verifier.verifyOrDelete(testFile, expectedHash),
        completes,
      );
      expect(testFile.existsSync(), isTrue);
    });

    test('verifyOrDelete deletes file and throws on mismatch', () async {
      final tempDir = Directory.systemTemp.createTempSync('sha_test_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      final testFile = File('${tempDir.path}/corrupt_asset.bin');
      testFile.writeAsStringSync('Archivo corrupto o modificado');

      const fakeHash =
          '0000000000000000000000000000000000000000000000000000000000000000';

      await expectLater(
        Sha256Verifier.verifyOrDelete(testFile, fakeHash),
        throwsA(isA<ChecksumMismatchException>()),
      );

      // El archivo debe haber sido eliminado automáticamente por seguridad
      expect(testFile.existsSync(), isFalse);
    });

    test('verifyOrDelete deletes file and throws MissingChecksumException on empty or invalid hash', () async {
      final tempDir = Directory.systemTemp.createTempSync('sha_missing_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      final f1 = File('${tempDir.path}/unverified1.bin')
        ..writeAsStringSync('payload');
      await expectLater(
        Sha256Verifier.verifyOrDelete(f1, ''),
        throwsA(isA<MissingChecksumException>()),
      );
      expect(f1.existsSync(), isFalse);

      final f2 = File('${tempDir.path}/unverified2.bin')
        ..writeAsStringSync('payload');
      await expectLater(
        Sha256Verifier.verifyOrDelete(f2, 'z' * 64),
        throwsA(isA<MissingChecksumException>()),
      );
      expect(f2.existsSync(), isFalse);
    });

    test('parseSha256Sums ignores non-hex hashes and strips ./ prefix', () {
      const sample = '''
zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz  bad.bin
5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03  ./LibreMIeL-0.2.0-linux-x64.AppImage
''';
      final map = Sha256Verifier.parseSha256Sums(sample);
      expect(map.containsKey('bad.bin'), isFalse);
      expect(
        map['LibreMIeL-0.2.0-linux-x64.AppImage'],
        '5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03',
      );
    });
  });
}
