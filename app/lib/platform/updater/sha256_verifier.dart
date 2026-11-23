import 'dart:io';

import 'package:crypto/crypto.dart';

/// Excepción lanzada cuando falta el manifiesto `SHA256SUMS.txt` o el hash
/// esperado para el artefacto está ausente o mal formado.
class MissingChecksumException implements Exception {
  const MissingChecksumException([
    this.message =
        'No se encontró un hash SHA-256 oficial válido en SHA256SUMS.txt. '
        'Se canceló la actualización por seguridad.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Excepción lanzada cuando el hash SHA-256 de un instalador descargado
/// no coincide con el registrado oficialmente en `SHA256SUMS.txt`.
class ChecksumMismatchException implements Exception {
  const ChecksumMismatchException({
    required this.fileName,
    required this.expectedHash,
    required this.actualHash,
  });

  final String fileName;
  final String expectedHash;
  final String actualHash;

  @override
  String toString() =>
      'ChecksumMismatchException: El hash SHA-256 de $fileName no coincide '
      '(esperado: $expectedHash, obtenido: $actualHash). '
      'El archivo ha sido eliminado por seguridad.';
}

/// Utilidades de análisis y verificación de integridad criptográfica SHA-256.
class Sha256Verifier {
  static final RegExp _sha256HexPattern = RegExp(r'^[0-9a-f]{64}$');

  /// Retorna `true` si [hash] es un digest SHA-256 hexadecimal válido de 64 caracteres.
  static bool isValidSha256(String hash) {
    return _sha256HexPattern.hasMatch(hash.trim().toLowerCase());
  }

  /// Parsea el contenido de `SHA256SUMS.txt` en un mapa `nombreArchivo -> hashSha256`.
  /// Admite formato estándar de `sha256sum`: `<hash>  <archivo>` o `<hash> *<archivo>`.
  static Map<String, String> parseSha256Sums(String content) {
    final result = <String, String>{};
    final lines = content.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final hash = parts[0].trim().toLowerCase();
        var fileName = parts.sublist(1).join(' ').trim();
        if (fileName.startsWith('*')) {
          fileName = fileName.substring(1).trim();
        }
        if (fileName.startsWith('./')) {
          fileName = fileName.substring(2).trim();
        }
        if (isValidSha256(hash) && fileName.isNotEmpty) {
          result[fileName] = hash;
        }
      }
    }

    return result;
  }

  /// Calcula el hash SHA-256 de un archivo en disco procesándolo en bloques (streaming).
  static Future<String> computeFileSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }

  /// Verifica el archivo en disco contra [expectedHash].
  /// Si [expectedHash] es vacío/inválido o no coincide, elimina el archivo y lanza excepción.
  static Future<void> verifyOrDelete(File file, String expectedHash) async {
    final expected = expectedHash.trim().toLowerCase();
    if (!isValidSha256(expected)) {
      await _deleteSafely(file);
      throw const MissingChecksumException();
    }

    final actual = await computeFileSha256(file);

    if (actual != expected) {
      await _deleteSafely(file);
      throw ChecksumMismatchException(
        fileName: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : file.path,
        expectedHash: expected,
        actualHash: actual,
      );
    }
  }

  static Future<void> _deleteSafely(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
