import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'asset_resolver.dart';
import 'sha256_verifier.dart';
import 'update_models.dart';

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
       _repoName = repoName ?? 'LibreMIeL';

  final Dio _dio;
  final String? _currentVersionOverride;
  final String _repoOwner;
  final String _repoName;

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

    // Buscar y descargar SHA256SUMS.txt si está disponible
    final checksumAsset = assets.firstWhere(
      (a) => (a['name'] as String? ?? '').toLowerCase() == 'sha256sums.txt',
      orElse: () => const {},
    );

    var sha256Map = <String, String>{};
    if (checksumAsset.isNotEmpty) {
      final shaUrl = checksumAsset['browser_download_url'] as String? ?? '';
      if (shaUrl.isNotEmpty) {
        try {
          final shaResp = await _dio.get(
            shaUrl,
            options: Options(responseType: ResponseType.plain),
          );
          if (shaResp.statusCode == 200 && shaResp.data != null) {
            sha256Map = Sha256Verifier.parseSha256Sums(shaResp.data.toString());
          }
        } catch (_) {
          // Si falla la descarga del archivo de checksums, se intentará luego o fallará la verificación
        }
      }
    }

    // Seleccionar el asset óptimo para la plataforma actual
    final bestAsset = AssetResolver.selectBestAsset(assets: assets);
    if (bestAsset == null) {
      return UpdateCheckResult(isNewVersionAvailable: false, etag: newEtag);
    }

    final assetName = bestAsset['name'] as String? ?? '';
    final downloadUrl = bestAsset['browser_download_url'] as String? ?? '';
    final assetSize = bestAsset['size'] as int? ?? 0;
    final expectedSha256 = sha256Map[assetName] ?? '';

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
