import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/platform/updater/asset_resolver.dart';
import 'package:libremiel/platform/updater/update_models.dart';

void main() {
  group('AssetResolver tests', () {
    final mockAssets = <Map<String, dynamic>>[
      {
        'name': 'LibreMIeL-0.2.0-windows-x64-setup.exe',
        'browser_download_url': 'https://github.com/dl/win-x64.exe',
        'size': 15000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-windows-x64-portable.zip',
        'browser_download_url': 'https://github.com/dl/win-x64.zip',
        'size': 14000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-android-universal.apk',
        'browser_download_url': 'https://github.com/dl/android-universal.apk',
        'size': 25000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-android-arm64-v8a.apk',
        'browser_download_url': 'https://github.com/dl/android-arm64.apk',
        'size': 18000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-linux-x64.AppImage',
        'browser_download_url': 'https://github.com/dl/linux-x64.AppImage',
        'size': 35000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-linux-amd64.deb',
        'browser_download_url': 'https://github.com/dl/linux-amd64.deb',
        'size': 20000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-linux-x86_64.rpm',
        'browser_download_url': 'https://github.com/dl/linux-x86_64.rpm',
        'size': 20000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-linux-x86_64.pkg.tar.zst',
        'browser_download_url': 'https://github.com/dl/linux-arch.pkg.tar.zst',
        'size': 20000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-linux-x64-portable.tar.gz',
        'browser_download_url':
            'https://github.com/dl/linux-x64-portable.tar.gz',
        'size': 22000000,
      },
      {
        'name': 'LibreMIeL-0.2.0-macos-universal.dmg',
        'browser_download_url': 'https://github.com/dl/macos.dmg',
        'size': 30000000,
      },
      {
        'name': 'SHA256SUMS.txt',
        'browser_download_url': 'https://github.com/dl/SHA256SUMS.txt',
        'size': 1024,
      },
    ];

    test('Windows asset selection prefers setup.exe', () {
      final selected = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'windows',
        overrideIsArm64: false,
      );
      expect(selected, isNotNull);
      expect(selected!['name'], 'LibreMIeL-0.2.0-windows-x64-setup.exe');
    });

    test('Android asset selection matches device ABI preference', () {
      final selected = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'android',
        overrideAndroidAbis: ['arm64-v8a', 'armeabi-v7a'],
      );
      expect(selected, isNotNull);
      expect(selected!['name'], 'LibreMIeL-0.2.0-android-arm64-v8a.apk');

      // Si no hay APK de la ABI solicitada, cae a universal.apk
      final fallbackUniversal = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'android',
        overrideAndroidAbis: ['riscv64'],
      );
      expect(fallbackUniversal, isNotNull);
      expect(
        fallbackUniversal!['name'],
        'LibreMIeL-0.2.0-android-universal.apk',
      );
    });

    test('Linux asset selection respects installation kind', () {
      // AppImage
      final appImage = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'linux',
        overrideIsArm64: false,
        overrideLinuxKind: LinuxInstallKind.appImage,
      );
      expect(appImage, isNotNull);
      expect(appImage!['name'], 'LibreMIeL-0.2.0-linux-x64.AppImage');

      // Deb
      final deb = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'linux',
        overrideIsArm64: false,
        overrideLinuxKind: LinuxInstallKind.deb,
      );
      expect(deb, isNotNull);
      expect(deb!['name'], 'LibreMIeL-0.2.0-linux-amd64.deb');

      // RPM
      final rpm = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'linux',
        overrideIsArm64: false,
        overrideLinuxKind: LinuxInstallKind.rpm,
      );
      expect(rpm, isNotNull);
      expect(rpm!['name'], 'LibreMIeL-0.2.0-linux-x86_64.rpm');

      // Arch
      final arch = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'linux',
        overrideIsArm64: false,
        overrideLinuxKind: LinuxInstallKind.arch,
      );
      expect(arch, isNotNull);
      expect(arch!['name'], 'LibreMIeL-0.2.0-linux-x86_64.pkg.tar.zst');

      // Portable .tar.gz
      final portable = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'linux',
        overrideIsArm64: false,
        overrideLinuxKind: LinuxInstallKind.portable,
      );
      expect(portable, isNotNull);
      expect(portable!['name'], 'LibreMIeL-0.2.0-linux-x64-portable.tar.gz');
    });

    test('macOS asset selection prefers DMG', () {
      final selected = AssetResolver.selectBestAsset(
        assets: mockAssets,
        overrideOs: 'macos',
      );
      expect(selected, isNotNull);
      expect(selected!['name'], 'LibreMIeL-0.2.0-macos-universal.dmg');
    });
  });
}
