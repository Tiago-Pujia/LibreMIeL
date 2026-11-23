import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'sha256_verifier.dart';
import 'update_checker.dart';
import 'update_models.dart';

/// Gestor de descarga segura de assets con seguimiento de progreso y verificación SHA-256 obligatoria.
class UpdateDownloader {
  UpdateDownloader({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 10),
            ),
          );

  final Dio _dio;

  /// Obtiene o crea el directorio temporal para alojar las descargas de actualizaciones.
  Future<Directory> getUpdatesDirectory() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory(p.join(temp.path, 'libremiel_updates'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Descarga el archivo del release y verifica obligatoriamente su checksum SHA-256.
  Future<File> downloadAndVerify({
    required ReleaseInfo release,
    void Function(UpdateProgress progress)? onProgress,
    void Function()? onVerifying,
    CancelToken? cancelToken,
  }) async {
    if (!Sha256Verifier.isValidSha256(release.expectedSha256)) {
      throw const MissingChecksumException();
    }
    if (!isTrustedGitHubDownloadUrl(release.downloadUrl)) {
      throw const FormatException(
        'La URL de descarga no pertenece a un dominio HTTPS oficial de GitHub.',
      );
    }

    final safeFileName = p.basename(release.assetName.trim());
    if (safeFileName.isEmpty || safeFileName == '.' || safeFileName == '..') {
      throw const FormatException('Nombre de artefacto de descarga inválido.');
    }

    final dir = await getUpdatesDirectory();
    final targetFile = File(p.join(dir.path, safeFileName));

    // Si ya existe un archivo previo con el mismo nombre, eliminarlo
    if (targetFile.existsSync()) {
      try {
        targetFile.deleteSync();
      } catch (_) {}
    }

    await _dio.download(
      release.downloadUrl,
      targetFile.path,
      cancelToken: cancelToken,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (onProgress != null) {
          onProgress(
            UpdateProgress(
              receivedBytes: received,
              totalBytes: total > 0 ? total : release.assetSize,
            ),
          );
        }
      },
    );

    // Verificación criptográfica obligatoria de SHA-256 (Invariante #10)
    onVerifying?.call();
    await Sha256Verifier.verifyOrDelete(targetFile, release.expectedSha256);

    return targetFile;
  }
}
