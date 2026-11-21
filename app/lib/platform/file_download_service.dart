import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/network/miel_client.dart';

/// Servicio multiplataforma para guardar y abrir archivos descargados desde MIeL.
class FileDownloadService {
  const FileDownloadService();

  /// Obtiene el directorio de descargas para archivos de LibreMIeL (`Downloads/LibreMIeL`
  /// en escritorio o directorio de documentos de la aplicación si no está disponible).
  Future<Directory> resolveDownloadsDirectory() async {
    Directory? baseDir;
    try {
      baseDir = await getDownloadsDirectory();
    } catch (_) {
      baseDir = null;
    }
    baseDir ??= await getApplicationDocumentsDirectory();

    final target = Directory(p.join(baseDir.path, 'LibreMIeL'));
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }
    return target;
  }

  /// Descarga un archivo autenticado desde MIeL hacia la carpeta `LibreMIeL` local.
  Future<DownloadedFileResult> downloadFromMiel({
    required MielInteractiveReader reader,
    required String urlOrPath,
    String? fallbackFileName,
    void Function(int received, int total)? onProgress,
  }) async {
    final targetDir = await resolveDownloadsDirectory();
    return reader.downloadAuthenticatedFile(
      urlOrPath,
      targetDir.path,
      fallbackFileName: fallbackFileName,
      onProgress: onProgress,
    );
  }

  /// Abre un archivo local con la aplicación predeterminada del sistema operativo.
  Future<bool> openDownloadedFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return false;

    try {
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [filePath]);
        if (result.exitCode == 0) return true;
      } else if (Platform.isMacOS) {
        final result = await Process.run('open', [filePath]);
        if (result.exitCode == 0) return true;
      } else if (Platform.isWindows) {
        final result = await Process.run('cmd', [
          '/c',
          'start',
          '',
          filePath,
        ], runInShell: true);
        if (result.exitCode == 0) return true;
      }
    } catch (_) {}

    final uri = Uri.file(filePath);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Abre la carpeta que contiene el archivo descargado en el explorador del sistema.
  Future<bool> openContainingFolder(String filePath) async {
    final dirPath = p.dirname(filePath);
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return false;

    try {
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [dirPath]);
        if (result.exitCode == 0) return true;
      } else if (Platform.isMacOS) {
        final result = await Process.run('open', ['-R', filePath]);
        if (result.exitCode == 0) return true;
      } else if (Platform.isWindows) {
        final result = await Process.run('explorer.exe', ['/select,$filePath']);
        if (result.exitCode == 0) return true;
      }
    } catch (_) {}

    final uri = Uri.directory(dirPath);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
