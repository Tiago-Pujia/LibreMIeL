import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/platform/updater/update_models.dart';

void main() {
  group('SemVer tests', () {
    test('tryParse parses standard SemVer strings', () {
      final v1 = SemVer.tryParse('0.1.0');
      expect(v1, isNotNull);
      expect(v1!.major, 0);
      expect(v1.minor, 1);
      expect(v1.patch, 0);
      expect(v1.buildNumber, isNull);
      expect(v1.preRelease, isNull);

      final v2 = SemVer.tryParse('v1.2.3');
      expect(v2, isNotNull);
      expect(v2!.major, 1);
      expect(v2.minor, 2);
      expect(v2.patch, 3);

      final v3 = SemVer.tryParse('2.0.1+45');
      expect(v3, isNotNull);
      expect(v3!.major, 2);
      expect(v3.minor, 0);
      expect(v3.patch, 1);
      expect(v3.buildNumber, 45);

      final v4 = SemVer.tryParse('v0.2.0-beta.1+12');
      expect(v4, isNotNull);
      expect(v4!.major, 0);
      expect(v4.minor, 2);
      expect(v4.patch, 0);
      expect(v4.preRelease, 'beta.1');
      expect(v4.buildNumber, 12);
    });

    test('tryParse returns null on invalid strings', () {
      expect(SemVer.tryParse(''), isNull);
      expect(SemVer.tryParse('abc'), isNull);
      expect(SemVer.tryParse('v'), isNull);
      expect(SemVer.tryParse('not.a.version'), isNull);
      expect(SemVer.tryParse('1.abc.3'), isNull);
      expect(SemVer.tryParse('1.2.xyz'), isNull);
      expect(SemVer.tryParse('1.2.3.4'), isNull);
      expect(SemVer.tryParse('1.0.0-'), isNull);
    });

    test('isGreaterThan and compareTo comparisons', () {
      final v010 = SemVer.parse('0.1.0');
      final v011 = SemVer.parse('0.1.1');
      final v020 = SemVer.parse('0.2.0');
      final v100 = SemVer.parse('1.0.0');

      expect(v011.isGreaterThan(v010), isTrue);
      expect(v020.isGreaterThan(v011), isTrue);
      expect(v100.isGreaterThan(v020), isTrue);
      expect(v010.isGreaterThan(v011), isFalse);
      expect(v010.isGreaterThan(v010), isFalse);

      // Build number comparison
      final v010b1 = SemVer.parse('0.1.0+1');
      final v010b2 = SemVer.parse('0.1.0+2');
      expect(v010b2.isGreaterThan(v010b1), isTrue);
      expect(v010b1.isGreaterThan(v010b2), isFalse);

      // Pre-release comparison: standard release is greater than pre-release
      final v010pre = SemVer.parse('0.1.0-alpha');
      expect(v010.isGreaterThan(v010pre), isTrue);
      expect(v010pre.isGreaterThan(v010), isFalse);

      // SemVer 2.0 numeric pre-release identifiers: beta.10 > beta.2
      final beta2 = SemVer.parse('1.0.0-beta.2');
      final beta10 = SemVer.parse('1.0.0-beta.10');
      expect(beta10.isGreaterThan(beta2), isTrue);
      expect(beta2.isGreaterThan(beta10), isFalse);
    });

    test('ReleaseInfo toJson/fromJson round-trip preserves all fields', () {
      final orig = ReleaseInfo(
        version: '0.2.0',
        tagName: 'v0.2.0',
        releaseNotes: 'Notas de prueba',
        assetName: 'LibreMIeL-0.2.0-linux-x64.AppImage',
        downloadUrl: 'https://github.com/Tiago-Pujia/LibreMIeL/releases/dl/app',
        assetSize: 123456,
        expectedSha256:
            '5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03',
        publishedAt: DateTime.utc(2026, 11, 22, 10, 0),
      );
      final restored = ReleaseInfo.fromJson(orig.toJson());
      expect(restored.version, orig.version);
      expect(restored.tagName, orig.tagName);
      expect(restored.releaseNotes, orig.releaseNotes);
      expect(restored.assetName, orig.assetName);
      expect(restored.downloadUrl, orig.downloadUrl);
      expect(restored.assetSize, orig.assetSize);
      expect(restored.expectedSha256, orig.expectedSha256);
      expect(restored.publishedAt, orig.publishedAt);
    });

    test('toString formats correctly', () {
      expect(SemVer.parse('0.1.0').toString(), '0.1.0');
      expect(SemVer.parse('v1.2.3+4').toString(), '1.2.3+4');
      expect(SemVer.parse('v2.0.0-rc.1+10').toString(), '2.0.0-rc.1+10');
    });

    test('equality and hashCode', () {
      final a = SemVer.parse('v0.1.0+5');
      final b = SemVer.parse('0.1.0+5');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
