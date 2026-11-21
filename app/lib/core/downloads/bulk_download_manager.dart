import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../exporters/content_exporter.dart';
import '../exporters/forum_exporter.dart';
import '../models/miel_models.dart';
import '../network/miel_client.dart';
import '../parsers/contenidos_parser.dart';
import '../parsers/forov2_parser.dart';
import '../storage/app_database.dart';

class BulkDownloadCancelledException implements Exception {
  const BulkDownloadCancelledException();
  @override
  String toString() => 'La descarga masiva fue cancelada por el usuario.';
}

/// Opciones de configuración para una descarga masiva de contenidos y foros.
class BulkDownloadOptions {
  const BulkDownloadOptions({
    required this.subjects,
    required this.baseDirectory,
    this.includeContenidos = true,
    this.includeForos = true,
    this.exportMarkdown = true,
    this.exportJson = true,
    this.exportHtml = true,
    this.downloadForumAttachments = true,
    this.incremental = true,
    this.delayBetweenRequests = const Duration(milliseconds: 250),
  });

  final List<Subject> subjects;
  final String baseDirectory;
  final bool includeContenidos;
  final bool includeForos;
  final bool exportMarkdown;
  final bool exportJson;
  final bool exportHtml;
  final bool downloadForumAttachments;
  final bool incremental;
  final Duration delayBetweenRequests;
}

/// Estado en vivo del progreso de la descarga masiva.
class BulkDownloadProgress {
  const BulkDownloadProgress({
    this.totalItems = 0,
    this.completedItems = 0,
    this.skippedItems = 0,
    this.failedItems = 0,
    this.totalBytesDownloaded = 0,
    this.currentItemLabel = '',
    this.currentSubjectName = '',
    this.error,
    this.isRunning = false,
    this.isPaused = false,
    this.isCancelled = false,
    this.isFinished = false,
  });

  final int totalItems;
  final int completedItems;
  final int skippedItems;
  final int failedItems;
  final int totalBytesDownloaded;
  final String currentItemLabel;
  final String currentSubjectName;
  final String? error;
  final bool isRunning;
  final bool isPaused;
  final bool isCancelled;
  final bool isFinished;

  double get progressFraction {
    if (totalItems <= 0) return 0.0;
    final processed = completedItems + skippedItems;
    final frac = processed / totalItems;
    return frac > 1.0 ? 1.0 : frac;
  }

  BulkDownloadProgress copyWith({
    int? totalItems,
    int? completedItems,
    int? skippedItems,
    int? failedItems,
    int? totalBytesDownloaded,
    String? currentItemLabel,
    String? currentSubjectName,
    String? error,
    bool? isRunning,
    bool? isPaused,
    bool? isCancelled,
    bool? isFinished,
  }) {
    return BulkDownloadProgress(
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      skippedItems: skippedItems ?? this.skippedItems,
      failedItems: failedItems ?? this.failedItems,
      totalBytesDownloaded: totalBytesDownloaded ?? this.totalBytesDownloaded,
      currentItemLabel: currentItemLabel ?? this.currentItemLabel,
      currentSubjectName: currentSubjectName ?? this.currentSubjectName,
      error: error,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isCancelled: isCancelled ?? this.isCancelled,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

/// Gestor de descarga masiva secuencial y respetuoso con MIeL (UNLaM).
///
/// Implementa soporte incremental con registro en SQLite (`DownloadedResources`),
/// pausa, reanudación, cancelación limpia, auto-reconexión y sanitización multiplataforma.
class BulkDownloadManager {
  BulkDownloadManager({
    required this.client,
    required this.database,
    this.ensureActiveSession,
  });

  final MielInteractiveReader client;
  final AppDatabase database;
  final Future<void> Function()? ensureActiveSession;

  final StreamController<BulkDownloadProgress> _progressController =
      StreamController<BulkDownloadProgress>.broadcast();

  Stream<BulkDownloadProgress> get progressStream => _progressController.stream;

  BulkDownloadProgress _currentProgress = const BulkDownloadProgress();
  BulkDownloadProgress get currentProgress => _currentProgress;

  bool _isPaused = false;
  bool _isCancelled = false;
  Completer<void>? _pauseCompleter;

  void pause() {
    if (!_isPaused && !_isCancelled && _currentProgress.isRunning) {
      _isPaused = true;
      _pauseCompleter = Completer<void>();
      _emit(_currentProgress.copyWith(isPaused: true));
    }
  }

  void resume() {
    if (_isPaused && !_isCancelled) {
      _isPaused = false;
      _pauseCompleter?.complete();
      _pauseCompleter = null;
      _emit(_currentProgress.copyWith(isPaused: false));
    }
  }

  void cancel() {
    _isCancelled = true;
    if (_isPaused) {
      _pauseCompleter?.complete();
      _pauseCompleter = null;
    }
    _emit(_currentProgress.copyWith(
      isRunning: false,
      isCancelled: true,
      currentItemLabel: 'Cancelado por el usuario',
    ));
  }

  void _emit(BulkDownloadProgress progress) {
    _currentProgress = progress;
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  Future<void> _checkPauseAndCancel() async {
    if (_isCancelled) {
      throw const BulkDownloadCancelledException();
    }
    if (_isPaused && _pauseCompleter != null) {
      await _pauseCompleter!.future;
    }
    if (_isCancelled) {
      throw const BulkDownloadCancelledException();
    }
  }

  Future<void> _politeDelay(Duration delay) async {
    await _checkPauseAndCancel();
    await Future.delayed(delay);
    await _checkPauseAndCancel();
  }

  Future<T> _withSessionRetry<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on MielSessionExpiredException {
      final ensureAuth = ensureActiveSession;
      if (ensureAuth != null) {
        await ensureAuth();
        return await call();
      }
      rethrow;
    }
  }

  /// Ejecuta el proceso de descarga masiva para las materias y opciones provistas.
  Future<BulkDownloadProgress> start(BulkDownloadOptions options) async {
    _isCancelled = false;
    _isPaused = false;
    _pauseCompleter = null;

    _emit(const BulkDownloadProgress(
      isRunning: true,
      currentItemLabel: 'Preparando descarga masiva...',
    ));

    final baseDir = Directory(options.baseDirectory);
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    try {
      for (final subject in options.subjects) {
        await _checkPauseAndCancel();

        final codDisplay = subject.commissionCode.isNotEmpty
            ? subject.commissionCode
            : subject.idComision;
        final subjectFolder = sanitizeFileName('${subject.name} - $codDisplay');
        final subjectDir = Directory(p.join(baseDir.path, subjectFolder));
        if (!await subjectDir.exists()) {
          await subjectDir.create(recursive: true);
        }

        _emit(_currentProgress.copyWith(
          currentSubjectName: subject.name,
          currentItemLabel: 'Consultando módulos de ${subject.name}...',
        ));

        // 1. Descarga de Contenidos
        if (options.includeContenidos && subject.hasContenidos) {
          await _processContenidos(subject, subjectDir, options);
        }

        // 2. Descarga de Foros
        if (options.includeForos && subject.hasForo) {
          await _processForos(subject, subjectDir, options);
        }
      }

      _emit(_currentProgress.copyWith(
        isRunning: false,
        isFinished: true,
        currentItemLabel: 'Respaldo completado con éxito',
      ));
    } on BulkDownloadCancelledException {
      _emit(_currentProgress.copyWith(
        isRunning: false,
        isCancelled: true,
        currentItemLabel: 'Respaldo cancelado',
      ));
    } catch (e) {
      _emit(_currentProgress.copyWith(
        isRunning: false,
        error: e.toString(),
        currentItemLabel: 'Error durante el respaldo: $e',
      ));
    }

    return _currentProgress;
  }

  Future<void> _processContenidos(
    Subject subject,
    Directory subjectDir,
    BulkDownloadOptions options,
  ) async {
    await _checkPauseAndCancel();

    final html = await _withSessionRetry(
      () => client.fetchContenidosHtml(subject.idComision),
    );
    final pageData = parseContenidosPageHtml(html, subject.idComision);

    final contenidosDir = Directory(p.join(subjectDir.path, 'Contenidos'));
    if (!await contenidosDir.exists()) {
      await contenidosDir.create(recursive: true);
    }

    // Guardar índices .md
    await saveContentIndexFiles(
      targetDir: contenidosDir,
      content: pageData,
      subjectName: subject.name,
      commissionCode: subject.commissionCode,
    );

    // Recopilar todos los archivos binarios descargables
    final itemsToDownload = <({
      ContentItem item,
      String sectionTitle,
      String submoduleTitle,
    })>[];

    for (final sec in pageData.sections) {
      for (final sub in sec.submodules) {
        for (final item in sub.items) {
          if (!item.isExternal && item.url.isNotEmpty) {
            itemsToDownload.add((
              item: item,
              sectionTitle: sec.title,
              submoduleTitle: sub.title,
            ));
          }
        }
      }
    }

    _emit(_currentProgress.copyWith(
      totalItems: _currentProgress.totalItems + itemsToDownload.length,
    ));

    for (final entry in itemsToDownload) {
      await _checkPauseAndCancel();

      final item = entry.item;
      final secFolder = sanitizeFileName(
        entry.sectionTitle.isNotEmpty ? entry.sectionTitle : 'Sección',
      );
      final subFolder = sanitizeFileName(
        entry.submoduleTitle.isNotEmpty ? entry.submoduleTitle : 'Archivos',
      );
      final targetSubDir = Directory(
        p.join(contenidosDir.path, secFolder, subFolder),
      );

      final cleanName = sanitizeFileName(item.title);
      final targetFilePath = p.join(targetSubDir.path, cleanName);
      final targetFile = File(targetFilePath);

      // Comprobación incremental
      if (options.incremental) {
        final existingRecord = await database.getDownloadedResource(
          idComision: subject.idComision,
          module: 'contenidos',
          resourceId: item.idElemento,
        );
        if (existingRecord != null && await targetFile.exists()) {
          _emit(_currentProgress.copyWith(
            skippedItems: _currentProgress.skippedItems + 1,
            currentItemLabel: 'Omitido (ya descargado): $cleanName',
          ));
          continue;
        }
        if (await targetFile.exists() && await targetFile.length() > 0) {
          _emit(_currentProgress.copyWith(
            skippedItems: _currentProgress.skippedItems + 1,
            currentItemLabel: 'Omitido (existe en disco): $cleanName',
          ));
          continue;
        }
      }

      _emit(_currentProgress.copyWith(
        currentItemLabel: 'Descargando: ${subject.name} > $cleanName',
      ));

      await _politeDelay(options.delayBetweenRequests);

      try {
        final bytes = await _withSessionRetry(
          () => client.downloadAuthenticatedBytes(item.url),
        );

        if (!await targetSubDir.exists()) {
          await targetSubDir.create(recursive: true);
        }

        await targetFile.writeAsBytes(bytes, flush: true);
        final fileHash = sha256.convert(bytes).toString();

        await database.recordDownloadedResource(
          idComision: subject.idComision,
          module: 'contenidos',
          resourceId: item.idElemento,
          title: item.title,
          localPath: targetFilePath,
          fileSize: BigInt.from(bytes.length),
          sha256: fileHash,
        );

        // Notificar a MIeL descarga externa
        try {
          await client.markExternalContentDownloaded(
            subject.idComision,
            item.idElemento,
          );
        } catch (_) {}

        _emit(_currentProgress.copyWith(
          completedItems: _currentProgress.completedItems + 1,
          totalBytesDownloaded:
              _currentProgress.totalBytesDownloaded + bytes.length,
        ));
      } catch (err) {
        _emit(_currentProgress.copyWith(
          failedItems: _currentProgress.failedItems + 1,
          currentItemLabel: 'Error al descargar $cleanName ($err)',
        ));
      }
    }
  }

  Future<void> _processForos(
    Subject subject,
    Directory subjectDir,
    BulkDownloadOptions options,
  ) async {
    await _checkPauseAndCancel();

    final html = await _withSessionRetry(
      () => client.fetchForoTemasHtml(subject.idComision),
    );
    final topics = parseForoTemasHtml(html, subject.idComision);

    final forosDir = Directory(p.join(subjectDir.path, 'Foros'));
    if (!await forosDir.exists()) {
      await forosDir.create(recursive: true);
    }

    _emit(_currentProgress.copyWith(
      totalItems: _currentProgress.totalItems + topics.length,
    ));

    for (final topicSummary in topics) {
      await _checkPauseAndCancel();

      final topicFolderName = sanitizeFileName(
        '${topicSummary.idTema} - ${topicSummary.title}',
      );
      final topicDir = Directory(p.join(forosDir.path, topicFolderName));

      if (options.incremental) {
        final isRecorded = await database.isResourceDownloaded(
          idComision: subject.idComision,
          module: 'forov2',
          resourceId: topicSummary.idTema,
        );
        if (isRecorded && await topicDir.exists()) {
          _emit(_currentProgress.copyWith(
            skippedItems: _currentProgress.skippedItems + 1,
            currentItemLabel: 'Omitido (foro ya exportado): ${topicSummary.title}',
          ));
          continue;
        }
      }

      _emit(_currentProgress.copyWith(
        currentItemLabel: 'Exportando foro: ${topicSummary.title}',
      ));

      await _politeDelay(options.delayBetweenRequests);

      try {
        final threadHtml = await _withSessionRetry(
          () => client.fetchForoMensajesHtml(
            subject.idComision,
            topicSummary.idTema,
          ),
        );
        final thread = parseForoMensajesHtml(
          threadHtml,
          subject.idComision,
          topicSummary.idTema,
        );

        final writtenFiles = await saveForumTopicFiles(
          targetTopicDir: topicDir,
          thread: thread,
          subjectName: subject.name,
          commissionCode: subject.commissionCode,
          rawHtml: threadHtml,
          exportMarkdown: options.exportMarkdown,
          exportJson: options.exportJson,
          exportHtml: options.exportHtml,
          hasLocalAttachments: options.downloadForumAttachments,
        );

        var totalTopicBytes = 0;
        for (final pth in writtenFiles.values) {
          final f = File(pth);
          if (await f.exists()) {
            totalTopicBytes += await f.length();
          }
        }

        // Descarga de adjuntos si está habilitado
        if (options.downloadForumAttachments) {
          final adjuntosDir = Directory(p.join(topicDir.path, 'adjuntos'));

          for (final m in thread.messages) {
            final allAtts = [...m.fileAttachments, ...m.imageAttachments];
            for (final att in allAtts) {
              if (att.downloadUrl.isEmpty) continue;
              await _checkPauseAndCancel();

              final attName = sanitizeFileName(att.fileName);
              final attFile = File(p.join(adjuntosDir.path, attName));

              if (options.incremental && await attFile.exists()) {
                continue;
              }

              await _politeDelay(options.delayBetweenRequests);

              try {
                final attBytes = await _withSessionRetry(
                  () => client.downloadAuthenticatedBytes(att.downloadUrl),
                );
                if (!await adjuntosDir.exists()) {
                  await adjuntosDir.create(recursive: true);
                }
                await attFile.writeAsBytes(attBytes, flush: true);
                totalTopicBytes += attBytes.length;
              } catch (_) {}
            }
          }
        }

        await database.recordDownloadedResource(
          idComision: subject.idComision,
          module: 'forov2',
          resourceId: topicSummary.idTema,
          title: topicSummary.title,
          localPath: topicDir.path,
          fileSize: BigInt.from(totalTopicBytes),
        );

        _emit(_currentProgress.copyWith(
          completedItems: _currentProgress.completedItems + 1,
          totalBytesDownloaded:
              _currentProgress.totalBytesDownloaded + totalTopicBytes,
        ));
      } catch (err) {
        _emit(_currentProgress.copyWith(
          failedItems: _currentProgress.failedItems + 1,
          currentItemLabel: 'Error al exportar foro ${topicSummary.title} ($err)',
        ));
      }
    }
  }

  void dispose() {
    _progressController.close();
  }
}
