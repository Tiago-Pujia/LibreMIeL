import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/platform/updater/sha256_verifier.dart';
import 'package:libremiel/platform/updater/update_checker.dart';
import 'package:libremiel/platform/updater/update_downloader.dart';
import 'package:libremiel/platform/updater/update_models.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
  });

  group('UpdateChecker tests', () {
    test(
      'checkForUpdate returns releaseInfo when newer version is published',
      () async {
        final checker = UpdateChecker(
          dio: mockDio,
          currentVersionOverride: '0.1.0',
        );

        final releaseJson = {
          'tag_name': 'v0.2.0',
          'name': 'LibreMIeL v0.2.0',
          'draft': false,
          'prerelease': false,
          'body':
              'Novedades de la versión 0.2.0:\n- Mejoras en sincronización.',
          'published_at': '2026-11-22T10:00:00Z',
          'assets': [
            {
              'name': 'LibreMIeL-0.2.0-linux-x64.AppImage',
              'browser_download_url':
                  'https://github.com/dl/linux-x64.AppImage',
              'size': 35000000,
            },
            {
              'name': 'SHA256SUMS.txt',
              'browser_download_url': 'https://github.com/dl/SHA256SUMS.txt',
              'size': 150,
            },
          ],
        };

        const shaContent = '''
5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03  LibreMIeL-0.2.0-linux-x64.AppImage
''';

        when(() => mockDio.get(any(), options: any(named: 'options')))
            .thenAnswer((invocation) async {
              final url = invocation.positionalArguments[0] as String;
              if (url.endsWith('releases/latest')) {
                return Response(
                  requestOptions: RequestOptions(path: url),
                  statusCode: 200,
                  data: releaseJson,
                  headers: Headers.fromMap({
                    'etag': ['"etag123"'],
                  }),
                );
              } else if (url.endsWith('SHA256SUMS.txt')) {
                return Response(
                  requestOptions: RequestOptions(path: url),
                  statusCode: 200,
                  data: shaContent,
                );
              }
              return Response(
                requestOptions: RequestOptions(path: url),
                statusCode: 404,
              );
            });

        final result = await checker.checkForUpdate();
        expect(result.isNewVersionAvailable, isTrue);
        expect(result.releaseInfo, isNotNull);
        expect(result.releaseInfo!.version, '0.2.0');
        expect(result.etag, '"etag123"');
        expect(
          result.releaseInfo!.expectedSha256,
          '5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03',
        );
      },
    );

    test('checkForUpdate returns notModified on 304 response', () async {
      final checker = UpdateChecker(
        dio: mockDio,
        currentVersionOverride: '0.1.0',
      );

      when(() => mockDio.get(any(), options: any(named: 'options')))
          .thenAnswer((invocation) async {
            final url = invocation.positionalArguments[0] as String;
            return Response(
              requestOptions: RequestOptions(path: url),
              statusCode: 304,
            );
          });

      final result = await checker.checkForUpdate(cachedEtag: '"etag123"');
      expect(result.isNewVersionAvailable, isFalse);
      expect(result.notModified, isTrue);
      expect(result.etag, '"etag123"');
    });

    test(
      'checkForUpdate returns false when published version is not newer',
      () async {
        final checker = UpdateChecker(
          dio: mockDio,
          currentVersionOverride: '0.2.0',
        );

        final releaseJson = {
          'tag_name': 'v0.1.5',
          'draft': false,
          'prerelease': false,
          'body': '',
          'assets': [],
        };

        when(() => mockDio.get(any(), options: any(named: 'options')))
            .thenAnswer((invocation) async {
              return Response(
                requestOptions: RequestOptions(path: ''),
                statusCode: 200,
                data: releaseJson,
              );
            });

        final result = await checker.checkForUpdate();
        expect(result.isNewVersionAvailable, isFalse);
      },
    );

    test('checkForUpdate respects skippedReleaseVersion', () async {
      final checker = UpdateChecker(
        dio: mockDio,
        currentVersionOverride: '0.1.0',
      );

      final releaseJson = {
        'tag_name': 'v0.2.0',
        'draft': false,
        'prerelease': false,
        'body': '',
        'assets': [],
      };

      when(() => mockDio.get(any(), options: any(named: 'options')))
          .thenAnswer((invocation) async {
            return Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: releaseJson,
            );
          });

      final result = await checker.checkForUpdate(
        skippedReleaseVersion: '0.2.0',
      );
      expect(result.isNewVersionAvailable, isFalse);
    });

    test(
      'checkForUpdate throws GitHubRateLimitException on 403 / 429',
      () async {
        final checker = UpdateChecker(
          dio: mockDio,
          currentVersionOverride: '0.1.0',
        );

        when(() => mockDio.get(any(), options: any(named: 'options')))
            .thenThrow(
              DioException(
                requestOptions: RequestOptions(path: ''),
                response: Response(
                  requestOptions: RequestOptions(path: ''),
                  statusCode: 403,
                ),
              ),
            );

        expect(
          () => checker.checkForUpdate(),
          throwsA(isA<GitHubRateLimitException>()),
        );
      },
    );

    test('checkForUpdate throws MissingChecksumException when SHA256SUMS.txt is missing', () async {
      final checker = UpdateChecker(
        dio: mockDio,
        currentVersionOverride: '0.1.0',
        overrideOs: 'linux',
        overrideIsArm64: false,
        overrideLinuxKind: LinuxInstallKind.appImage,
      );

      final releaseJson = {
        'tag_name': 'v0.2.0',
        'draft': false,
        'prerelease': false,
        'body': 'Release sin checksums',
        'assets': [
          {
            'name': 'LibreMIeL-0.2.0-linux-x64.AppImage',
            'browser_download_url': 'https://github.com/Tiago-Pujia/LibreMIeL/releases/download/v0.2.0/LibreMIeL-0.2.0-linux-x64.AppImage',
            'size': 35000000,
          },
        ],
      };

      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: releaseJson,
        ),
      );

      expect(
        () => checker.checkForUpdate(),
        throwsA(isA<MissingChecksumException>()),
      );
    });

    test('checkForUpdate throws FormatException on untrusted non-GitHub download URL', () async {
      final checker = UpdateChecker(
        dio: mockDio,
        currentVersionOverride: '0.1.0',
        overrideOs: 'linux',
        overrideIsArm64: false,
        overrideLinuxKind: LinuxInstallKind.appImage,
      );

      final releaseJson = {
        'tag_name': 'v0.2.0',
        'draft': false,
        'prerelease': false,
        'body': '',
        'assets': [
          {
            'name': 'LibreMIeL-0.2.0-linux-x64.AppImage',
            'browser_download_url': 'http://evil.example.com/app.AppImage',
            'size': 1000,
          },
          {
            'name': 'SHA256SUMS.txt',
            'browser_download_url': 'https://github.com/dl/SHA256SUMS.txt',
            'size': 100,
          },
        ],
      };

      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: releaseJson,
        ),
      );

      expect(() => checker.checkForUpdate(), throwsA(isA<FormatException>()));
    });

    test('checkForUpdate queries real Android ABIs and selects matching x86_64 APK', () async {
      var abiProviderCalled = false;
      final checker = UpdateChecker(
        dio: mockDio,
        currentVersionOverride: '0.1.0',
        overrideOs: 'android',
        androidAbisProvider: () async {
          abiProviderCalled = true;
          return const ['x86_64', 'armeabi-v7a'];
        },
      );

      final releaseJson = {
        'tag_name': 'v0.2.0',
        'draft': false,
        'prerelease': false,
        'body': 'Android ABI test',
        'published_at': '2026-11-22T10:00:00Z',
        'assets': [
          {
            'name': 'LibreMIeL-0.2.0-android-arm64-v8a.apk',
            'browser_download_url':
                'https://github.com/dl/android-arm64-v8a.apk',
            'size': 18000000,
          },
          {
            'name': 'LibreMIeL-0.2.0-android-x86_64.apk',
            'browser_download_url': 'https://github.com/dl/android-x86_64.apk',
            'size': 19000000,
          },
          {
            'name': 'SHA256SUMS.txt',
            'browser_download_url': 'https://github.com/dl/SHA256SUMS.txt',
            'size': 200,
          },
        ],
      };

      const shaContent = '''
1111111111111111111111111111111111111111111111111111111111111111  LibreMIeL-0.2.0-android-arm64-v8a.apk
2222222222222222222222222222222222222222222222222222222222222222  LibreMIeL-0.2.0-android-x86_64.apk
''';

      when(() => mockDio.get(any(), options: any(named: 'options')))
          .thenAnswer((invocation) async {
            final url = invocation.positionalArguments[0] as String;
            if (url.endsWith('releases/latest')) {
              return Response(
                requestOptions: RequestOptions(path: url),
                statusCode: 200,
                data: releaseJson,
              );
            }
            return Response(
              requestOptions: RequestOptions(path: url),
              statusCode: 200,
              data: shaContent,
            );
          });

      final result = await checker.checkForUpdate();
      expect(abiProviderCalled, isTrue);
      expect(result.isNewVersionAvailable, isTrue);
      expect(
        result.releaseInfo!.assetName,
        'LibreMIeL-0.2.0-android-x86_64.apk',
      );
      expect(
        result.releaseInfo!.expectedSha256,
        '2222222222222222222222222222222222222222222222222222222222222222',
      );
    });

    test('UpdateDownloader rejects download immediately when expectedSha256 is empty', () async {
      final downloader = UpdateDownloader(dio: mockDio);
      final unverifiedRelease = ReleaseInfo(
        version: '0.2.0',
        tagName: 'v0.2.0',
        releaseNotes: '',
        assetName: 'LibreMIeL-0.2.0-linux-x64.AppImage',
        downloadUrl: 'https://github.com/dl/app.AppImage',
        assetSize: 1000,
        expectedSha256: '',
        publishedAt: DateTime(2026, 11, 22),
      );

      await expectLater(
        downloader.downloadAndVerify(release: unverifiedRelease),
        throwsA(isA<MissingChecksumException>()),
      );
    });
  });
}
