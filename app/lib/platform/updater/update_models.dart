import 'package:flutter/foundation.dart';

/// Representación estructurada y comparación de Versionado Semántico (SemVer).
@immutable
class SemVer implements Comparable<SemVer> {
  const SemVer({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber,
    this.preRelease,
  });

  final int major;
  final int minor;
  final int patch;
  final int? buildNumber;
  final String? preRelease;

  /// Parsea cadenas como "v0.1.0", "0.1.0+1", "1.2.3-beta.1+42", etc.
  static SemVer? tryParse(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1).trim();
    }
    if (v.isEmpty) return null;

    int? buildNum;
    if (v.contains('+')) {
      final plusParts = v.split('+');
      v = plusParts[0];
      if (plusParts.length > 1) {
        buildNum = int.tryParse(plusParts[1]);
      }
    }

    String? pre;
    if (v.contains('-')) {
      final dashIndex = v.indexOf('-');
      pre = v.substring(dashIndex + 1);
      v = v.substring(0, dashIndex);
    }

    final segments = v.split('.');
    if (segments.isEmpty) return null;

    final maj = int.tryParse(segments[0]);
    if (maj == null) return null;

    final min = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
    final pat = segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0;

    return SemVer(
      major: maj,
      minor: min,
      patch: pat,
      buildNumber: buildNum,
      preRelease: pre,
    );
  }

  static SemVer parse(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) {
      throw FormatException('Formato de versión SemVer inválido: $raw');
    }
    return parsed;
  }

  /// Retorna `true` si esta versión es estrictamente mayor que [other].
  bool isGreaterThan(SemVer other) => compareTo(other) > 0;

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Comparar pre-release: versión sin pre-release es mayor que versión con pre-release
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease != null && other.preRelease != null) {
      final preComp = preRelease!.compareTo(other.preRelease!);
      if (preComp != 0) return preComp;
    }

    // Comparar build number si ambos están presentes
    if (buildNumber != null && other.buildNumber != null) {
      return buildNumber!.compareTo(other.buildNumber!);
    }

    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemVer &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          buildNumber == other.buildNumber &&
          preRelease == other.preRelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, buildNumber, preRelease);

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    final withPre = preRelease != null ? '$base-$preRelease' : base;
    return buildNumber != null ? '$withPre+$buildNumber' : withPre;
  }
}

/// Información completa de un release publicado en GitHub.
@immutable
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    required this.assetName,
    required this.downloadUrl,
    required this.assetSize,
    required this.expectedSha256,
    required this.publishedAt,
    this.isPrerelease = false,
  });

  final String version;
  final String tagName;
  final String releaseNotes;
  final String assetName;
  final String downloadUrl;
  final int assetSize;
  final String expectedSha256;
  final DateTime publishedAt;
  final bool isPrerelease;

  String get formattedSize {
    if (assetSize <= 0) return '';
    if (assetSize < 1024 * 1024) {
      return '${(assetSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(assetSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Progreso reactivo de la descarga de una actualización.
@immutable
class UpdateProgress {
  const UpdateProgress({required this.receivedBytes, required this.totalBytes});

  final int receivedBytes;
  final int totalBytes;

  double get fraction {
    if (totalBytes <= 0) return 0.0;
    final f = receivedBytes / totalBytes;
    if (f < 0.0) return 0.0;
    if (f > 1.0) return 1.0;
    return f;
  }

  String get formattedReceived => _formatBytes(receivedBytes);
  String get formattedTotal => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Estados posibles del ciclo de vida del actualizador.
enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  verifyingChecksum,
  readyToInstall,
  installing,
  error,
}

/// Tipo de distribución instalada en Linux.
enum LinuxInstallKind { appImage, deb, rpm, arch, portable }
