import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import 'sha256_verifier.dart';
import 'update_checker.dart';
import 'update_downloader.dart';
import 'update_installer.dart';
import 'update_models.dart';

/// Estado global reactivo del actualizador automático.
class UpdaterState {
  const UpdaterState({
    this.status = UpdateStatus.idle,
    this.availableRelease,
    this.progress,
    this.downloadedFile,
    this.errorMessage,
    this.currentVersion = '',
    this.lastCheckedAt,
    this.isAutoCheckEnabled = true,
    this.skippedVersion,
  });

  final UpdateStatus status;
  final ReleaseInfo? availableRelease;
  final UpdateProgress? progress;
  final File? downloadedFile;
  final String? errorMessage;
  final String currentVersion;
  final DateTime? lastCheckedAt;
  final bool isAutoCheckEnabled;
  final String? skippedVersion;

  bool get isChecking => status == UpdateStatus.checking;
  bool get isDownloading => status == UpdateStatus.downloading;
  bool get isVerifying => status == UpdateStatus.verifyingChecksum;
  bool get isReadyToInstall => status == UpdateStatus.readyToInstall;
  bool get isInstalling => status == UpdateStatus.installing;
  bool get hasUpdate =>
      status == UpdateStatus.updateAvailable && availableRelease != null;

  UpdaterState copyWith({
    UpdateStatus? status,
    ReleaseInfo? availableRelease,
    bool clearRelease = false,
    UpdateProgress? progress,
    File? downloadedFile,
    String? errorMessage,
    bool clearError = false,
    String? currentVersion,
    DateTime? lastCheckedAt,
    bool? isAutoCheckEnabled,
    String? skippedVersion,
  }) {
    return UpdaterState(
      status: status ?? this.status,
      availableRelease: clearRelease
          ? null
          : (availableRelease ?? this.availableRelease),
      progress: progress ?? this.progress,
      downloadedFile: downloadedFile ?? this.downloadedFile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentVersion: currentVersion ?? this.currentVersion,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      isAutoCheckEnabled: isAutoCheckEnabled ?? this.isAutoCheckEnabled,
      skippedVersion: skippedVersion ?? this.skippedVersion,
    );
  }
}

/// Proveedor del comprobador de actualizaciones.
final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  return UpdateChecker();
});

/// Proveedor del descargador de actualizaciones.
final updateDownloaderProvider = Provider<UpdateDownloader>((ref) {
  return UpdateDownloader();
});

/// Controlador del actualizador automático.
class UpdaterNotifier extends Notifier<UpdaterState> {
  CancelToken? _cancelToken;

  @override
  UpdaterState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
    });
    Future.microtask(_loadInitialSettings);
    return const UpdaterState();
  }

  Future<void> _loadInitialSettings() async {
    final db = ref.read(databaseProvider);
    final checker = ref.read(updateCheckerProvider);

    String curVerStr = '';
    try {
      final curVer = await checker.getCurrentVersion();
      curVerStr = curVer.toString();
    } catch (_) {}

    final autoCheck = await db.getAutoCheckUpdates();
    final lastCheck = await db.getLastUpdateCheckAt();
    final skipped = await db.getSkippedReleaseVersion();

    state = state.copyWith(
      currentVersion: curVerStr,
      isAutoCheckEnabled: autoCheck,
      lastCheckedAt: lastCheck,
      skippedVersion: skipped,
    );
  }

  /// Comprueba si hay una nueva versión disponible.
  /// Si [manual] es `false`, respeta la frecuencia mínima de 24 horas y [isAutoCheckEnabled].
  Future<void> checkForUpdates({bool manual = false}) async {
    if (state.isChecking || state.isDownloading) return;

    final db = ref.read(databaseProvider);
    final checker = ref.read(updateCheckerProvider);
    final notifService = ref.read(notificationServiceProvider);

    if (!manual) {
      final autoEnabled = await db.getAutoCheckUpdates();
      if (!autoEnabled) return;

      final lastCheck = await db.getLastUpdateCheckAt();
      if (lastCheck != null) {
        final elapsed = DateTime.now().difference(lastCheck);
        if (elapsed.inHours < 24) {
          // Aún no transcurrieron 24 horas desde la última comprobación
          return;
        }
      }
    }

    state = state.copyWith(status: UpdateStatus.checking, clearError: true);

    try {
      final cachedEtag = await db.getLastUpdateEtag();
      final skipped = await db.getSkippedReleaseVersion();

      final result = await checker.checkForUpdate(
        cachedEtag: manual
            ? null
            : cachedEtag, // Búsqueda manual fuerza consulta sin 304
        skippedReleaseVersion: manual ? null : skipped,
      );

      final now = DateTime.now();
      await db.setLastUpdateCheckAt(now);
      if (result.etag != null && result.etag!.isNotEmpty) {
        await db.setLastUpdateEtag(result.etag!);
      }

      if (result.isNewVersionAvailable && result.releaseInfo != null) {
        state = state.copyWith(
          status: UpdateStatus.updateAvailable,
          availableRelease: result.releaseInfo,
          lastCheckedAt: now,
        );

        if (!manual) {
          await notifService.showUpdateNotification(
            version: result.releaseInfo!.version,
            releaseNotes: result.releaseInfo!.releaseNotes,
            assetName: result.releaseInfo!.assetName,
          );
        }
      } else {
        state = state.copyWith(
          status: manual ? UpdateStatus.upToDate : UpdateStatus.idle,
          clearRelease: true,
          lastCheckedAt: now,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e is GitHubRateLimitException
            ? 'Límite de consultas de GitHub API alcanzado. Probá más tarde.'
            : 'Error al comprobar actualizaciones: $e',
      );
    }
  }

  /// Descarga el artefacto y verifica su integridad SHA-256.
  Future<void> downloadUpdate() async {
    final release = state.availableRelease;
    if (release == null || state.isDownloading) return;

    final downloader = ref.read(updateDownloaderProvider);

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(
      status: UpdateStatus.downloading,
      progress: const UpdateProgress(receivedBytes: 0, totalBytes: 0),
      clearError: true,
    );

    try {
      final file = await downloader.downloadAndVerify(
        release: release,
        cancelToken: _cancelToken,
        onProgress: (p) {
          state = state.copyWith(progress: p);
        },
      );

      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        downloadedFile: file,
      );
    } catch (e) {
      if (_cancelToken?.isCancelled == true) {
        state = state.copyWith(status: UpdateStatus.updateAvailable);
        return;
      }

      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e is ChecksumMismatchException
            ? e.toString()
            : 'Error al descargar la actualización: $e',
      );
    }
  }

  /// Ejecuta el instalador del release descargado.
  Future<void> installUpdate() async {
    final file = state.downloadedFile;
    final release = state.availableRelease;
    if (file == null || release == null) return;

    state = state.copyWith(status: UpdateStatus.installing);

    try {
      await UpdateInstaller.install(downloadedFile: file, release: release);
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Error al ejecutar la instalación: $e',
      );
    }
  }

  /// Cancela una descarga en curso.
  void cancelDownload() {
    _cancelToken?.cancel();
    state = state.copyWith(
      status: state.availableRelease != null
          ? UpdateStatus.updateAvailable
          : UpdateStatus.idle,
    );
  }

  /// Omite la versión indicada para no volver a notificarla automáticamente.
  Future<void> skipVersion(String version) async {
    final db = ref.read(databaseProvider);
    await db.setSkippedReleaseVersion(version);
    state = state.copyWith(
      status: UpdateStatus.idle,
      clearRelease: true,
      skippedVersion: version,
    );
  }

  /// Descarta el aviso actual de actualización.
  void dismiss() {
    state = state.copyWith(status: UpdateStatus.idle);
  }

  /// Modifica la preferencia de comprobación automática.
  Future<void> setAutoCheckEnabled(bool enabled) async {
    final db = ref.read(databaseProvider);
    await db.setAutoCheckUpdates(enabled);
    state = state.copyWith(isAutoCheckEnabled: enabled);
  }
}

/// Proveedor del estado del actualizador de LibreMIeL.
final updaterProvider = NotifierProvider<UpdaterNotifier, UpdaterState>(
  UpdaterNotifier.new,
);
