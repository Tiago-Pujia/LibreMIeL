import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'asset_resolver.dart';
import 'sha256_verifier.dart';
import 'update_models.dart';

/// Valida que una URL de descarga o manifiesto pertenezca a los dominios HTTPS
/// oficiales de GitHub Releases.
bool isTrustedGitHubDownloadUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host == 'github.com' ||
      host == 'api.github.com' ||
      host.endsWith('.githubusercontent.com');
}

/// Excepción para límites de cuota de la API de GitHub.
class GitHubRateLimitException implements Exception {
  const GitHubRateLimitException([
    this.message = 'Límite de cuota de GitHub API alcanzado.',
  ]);
  final String message;
  @override
  String toString() => message;
}

/// Resultado de una comprobación de actualización.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.isNewVersionAvailable,
    this.releaseInfo,
    this.etag,
    this.notModified = false,
  });

  final bool isNewVersionAvailable;
  final ReleaseInfo? releaseInfo;
  final String? etag;
  final bool notModified;
}

/// Comprobador de actualizaciones contra GitHub Releases.
class UpdateChecker {
  UpdateChecker({
    Dio? dio,
    String? currentVersionOverride,
    String? repoOwner,
    String? repoName,
    this.overrideOs,
    this.overrideIsArm64,
    this.overrideLinuxKind,
    Future<List<String>> Function()? androidAbisProvider,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 20),
               headers: {
                 'Accept': 'application/vnd.github+json',
                 'User-Agent': 'LibreMIeL-App',
               },
               validateStatus: (status) =>
                   status != null &&
                   (status >= 200 && status < 400 || status == 304),
             ),
           ),
       _currentVersionOverride = currentVersionOverride?.trim(),
       _repoOwner = repoOwner ?? 'Tiago-Pujia',
       _repoName = repoName ?? 'LibreMIeL',
       _androidAbisProvider =
           androidAbisProvider ?? AssetResolver.getAndroidSupportedAbis;

  final Dio _dio;
  final String? _currentVersionOverride;
  final String _repoOwner;
  final String _repoName;
  final String? overrideOs;
  final bool? overrideIsArm64;
  final LinuxInstallKind? overrideLinuxKind;
  final Future<List<String>> Function() _androidAbisProvider;

  /// Obtiene la versión actual de la app instalada.
  Future<SemVer> getCurrentVersion() async {
    final overrideVer = _currentVersionOverride;
    if (overrideVer != null) {
      return SemVer.parse(overrideVer);
    }
    final info = await PackageInfo.fromPlatform();
    final vStr = info.buildNumber.isNotEmpty
        ? '${info.version}+${info.buildNumber}'
        : info.version;
    return SemVer.parse(vStr);
  }

  /// Comprueba si existe una versión más reciente publicada en GitHub Releases.
  Future<UpdateCheckResult> checkForUpdate({
    String? cachedEtag,
    String? skippedReleaseVersion,
    bool includePrereleases = false,
  }) async {
    final currentVer = await getCurrentVersion();
    final url =
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

    final options = Options(headers: {});
    if (cachedEtag != null && cachedEtag.isNotEmpty) {
      options.headers!['If-None-Match'] = cachedEtag;
    }

    Response response;
    try {
      response = await _dio.get(url, options: options);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403 || status == 429) {
        throw const GitHubRateLimitException();
      }
      rethrow;
    }

    // 304 Not Modified
    if (response.statusCode == 304) {
      return UpdateCheckResult(
        isNewVersionAvailable: false,
        etag: cachedEtag,
        notModified: true,
      );
    }

    final newEtag = response.headers.value('etag');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return UpdateCheckResult(isNewVersionAvailable: false, etag: newEtag);
    }

    final isDraft = data['draft'] == true;
    final isPrerelease = data['prerelease'] == true;
    if (isDraft || (isPrerelease && !includePrereleases)) {
      return UpdateCheckResult(isNewVersionAvailable: false, etag: newEtag);
    }

    final tagName = data['tag_name'] as String? ?? '';
    final releaseVer = SemVer.tryParse(tagName);
    if (releaseVer == null) {
      return UpdateCheckResult(isNewVersionAvailable: false, etag: newEtag);
    }

    // Si la versión publicada no es mayor que la instalada
    if (!releaseVer.isGreaterThan(currentVer)) {
      return UpdateCheckResult(isNewVersionAvailable: false, etag: newEtag);
    }

    // Si el usuario eligió omitir esta versión
    if (skippedReleaseVersion != null &&
        skippedReleaseVersion.isNotEmpty &&
        (skippedReleaseVersion == releaseVer.toString() ||
            skippedReleaseVersion == tagName ||
            skippedReleaseVersion == 'v${releaseVer.toString()}')) {
      return UpdateCheckResult(isNewVersionAvailable: false, etag: newEtag);
    }

    // Parsear lista de assets
    final rawAssets = data['assets'];
    final assets = <Map<String, dynamic>>[];
    if (rawAssets is List) {
      for (final a in rawAssets) {
        if (a is Map<String, dynamic>) {
          assets.add(a);
        }
      }
    }

    // Resolver ABIs reales del dispositivo en Android antes de seleccionar el asset
    List<String>? androidAbis;
    final effectiveOs =
        overrideOs ?? (!kIsWeb && Platform.isAndroid ? 'android' : null);
    if (effectiveOs == 'android') {
      androidAbis = await _androidAbisProvider();
    }

    // Seleccionar el asset óptimo para la plataforma actual
    final bestAsset = AssetResolver.selectBestAsset(
      assets: assets,
      overrideOs: overrideOs,
      overrideIsArm64: overrideIsArm64,
      overrideAndroidAbis: androidAbis,
      overrideLinuxKind: overrideLinuxKind,
    );
    if (bestAsset == null) {
      return UpdateCheckResult(isNewVersionAvailable: false, etag: newEtag);
    }

    final assetName = bestAsset['name'] as String? ?? '';
    final downloadUrl = bestAsset['browser_download_url'] as String? ?? '';
    final assetSize = (bestAsset['size'] as num?)?.toInt() ?? 0;
    if (assetName.isEmpty || !isTrustedGitHubDownloadUrl(downloadUrl)) {
      throw const FormatException(
        'El artefacto de actualización no proviene de una URL HTTPS oficial de GitHub.',
      );
    }

    // Invariante #10: SHA256SUMS.txt es obligatorio antes de ofrecer la descarga
    final checksumAsset = assets.firstWhere(
      (a) => (a['name'] as String? ?? '').toLowerCase() == 'sha256sums.txt',
      orElse: () => const {},
    );
    final shaUrl = checksumAsset['browser_download_url'] as String? ?? '';
    if (checksumAsset.isEmpty || !isTrustedGitHubDownloadUrl(shaUrl)) {
      throw const MissingChecksumException(
        'El release no incluye un archivo SHA256SUMS.txt oficial válido. '
        'No se puede verificar la integridad de la actualización.',
      );
    }

    final Response shaResp;
    try {
      shaResp = await _dio.get(
        shaUrl,
        options: Options(responseType: ResponseType.plain),
      );
    } catch (_) {
      throw const MissingChecksumException(
        'No se pudo descargar SHA256SUMS.txt para verificar la integridad del release.',
      );
    }

    if (shaResp.statusCode != 200 || shaResp.data == null) {
      throw const MissingChecksumException(
        'SHA256SUMS.txt respondió con un estado inválido y no permite verificar la actualización.',
      );
    }

    final sha256Map = Sha256Verifier.parseSha256Sums(shaResp.data.toString());
    final expectedSha256 = sha256Map[assetName] ?? '';
    if (!Sha256Verifier.isValidSha256(expectedSha256)) {
      throw MissingChecksumException(
        'No se encontró el checksum SHA-256 oficial para $assetName en SHA256SUMS.txt.',
      );
    }

    final releaseNotes = data['body'] as String? ?? '';
    final publishedAtStr = data['published_at'] as String? ?? '';
    final publishedAt = DateTime.tryParse(publishedAtStr) ?? DateTime.now();

    final info = ReleaseInfo(
      version: releaseVer.toString(),
      tagName: tagName,
      releaseNotes: releaseNotes,
      assetName: assetName,
      downloadUrl: downloadUrl,
      assetSize: assetSize,
      expectedSha256: expectedSha256,
      publishedAt: publishedAt,
      isPrerelease: isPrerelease,
    );

    return UpdateCheckResult(
      isNewVersionAvailable: true,
      releaseInfo: info,
      etag: newEtag,
    );
  }
}
