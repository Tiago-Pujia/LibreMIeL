import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Almacenamiento local de medios estáticos autenticados (imágenes de foros,
/// adjuntos visuales y fotos de perfil/avatares) para consulta sin conexión (Fase 9).
class OfflineMediaService {
  const OfflineMediaService();

  static Directory? _cachedMediaDir;

  Future<Directory> _getMediaDirectory() async {
    final cached = _cachedMediaDir;
    if (cached != null && cached.existsSync()) return cached;

    Directory dir;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      dir = Directory(
        p.join(Directory.systemTemp.path, 'libremiel_offline_media'),
      );
    } else {
      try {
        final appSupport = await getApplicationSupportDirectory();
        dir = Directory(p.join(appSupport.path, 'offline_media'));
      } catch (_) {
        dir = Directory(
          p.join(Directory.systemTemp.path, 'libremiel_offline_media'),
        );
      }
    }
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _cachedMediaDir = dir;
    return dir;
  }

  String _hashUrl(String url) {
    final digest = sha256.convert(utf8.encode(url.trim()));
    return digest.toString();
  }

  Future<Uint8List?> getCachedImageBytes(String url) async {
    try {
      if (url.trim().isEmpty) return null;
      final dir = await _getMediaDirectory();
      final file = File(p.join(dir.path, '${_hashUrl(url)}.bin'));
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCachedImageBytes(String url, Uint8List bytes) async {
    try {
      if (url.trim().isEmpty || bytes.isEmpty) return;
      final dir = await _getMediaDirectory();
      final file = File(p.join(dir.path, '${_hashUrl(url)}.bin'));
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  Future<int> getTotalCachedMediaBytes() async {
    try {
      final dir = await _getMediaDirectory();
      if (!dir.existsSync()) return 0;
      var total = 0;
      for (final entity in dir.listSync()) {
        if (entity is File) {
          total += entity.lengthSync();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearAllCachedMedia() async {
    try {
      final dir = await _getMediaDirectory();
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
