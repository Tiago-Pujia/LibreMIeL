import 'dart:convert';
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
    this.infoMessage,
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
  final String? infoMessage;
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
      availableRelease != null &&
      (status == UpdateStatus.updateAvailable ||
          status == UpdateStatus.downloading ||
          status == UpdateStatus.verifyingChecksum ||
          status == UpdateStatus.readyToInstall ||
          status == UpdateStatus.installing);

  UpdaterState copyWith({
    UpdateStatus? status,
    ReleaseInfo? availableRelease,
    bool clearRelease = false,
    UpdateProgress? progress,
    File? downloadedFile,
    bool clearDownloadedFile = false,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
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
      downloadedFile: clearDownloadedFile
          ? null
          : (downloadedFile ?? this.downloadedFile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
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

/// Proveedor inyectable del ejecutor de instalación (facilita tests).
final updateInstallerCallbackProvider =
    Provider<
      Future<InstallLaunchResult> Function({
        required File downloadedFile,
        required ReleaseInfo release,
        Future<void> Function()? beforeExit,
      })
    >((ref) {
      return ({
        required File downloadedFile,
        required ReleaseInfo release,
        Future<void> Function()? beforeExit,
      }) => UpdateInstaller.install(
        downloadedFile: downloadedFile,
        release: release,
        beforeExit: beforeExit,
      );
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

    SemVer? currentVer;
    String curVerStr = '';
    try {
      currentVer = await checker.getCurrentVersion();
      curVerStr = currentVer.toString();
    } catch (_) {}

    final autoCheck = await db.getAutoCheckUpdates();
    final lastCheck = await db.getLastUpdateCheckAt();
    final skipped = await db.getSkippedReleaseVersion();

    // Restaurar release cacheado si sigue siendo más nuevo que la versión instalada
    ReleaseInfo? cachedRelease;
    final rawCached = await db.getCachedReleaseJson();
    if (rawCached != null && rawCached.isNotEmpty) {
      cachedRelease = _parseAndValidateCachedRelease(
        rawCached,
        currentVer: currentVer,
        skippedVersion: skipped,
      );
      if (cachedRelease == null && currentVer != null) {
        await db.clearCachedReleaseJson();
      }
    }

    state = state.copyWith(
      currentVersion: curVerStr,
      isAutoCheckEnabled: autoCheck,
      lastCheckedAt: lastCheck,
      skippedVersion: skipped,
      availableRelease: cachedRelease,
      status: cachedRelease != null ? UpdateStatus.updateAvailable : null,
    );
  }

  ReleaseInfo? _parseAndValidateCachedRelease(
    String rawJson, {
    required SemVer? currentVer,
    required String? skippedVersion,
  }) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return null;
      final info = ReleaseInfo.fromJson(decoded);
      if (info.version.isEmpty ||
          !Sha256Verifier.isValidSha256(info.expectedSha256) ||
          !isTrustedGitHubDownloadUrl(info.downloadUrl)) {
        return null;
      }
      final relVer = SemVer.tryParse(info.version);
      if (relVer == null) return null;
      if (currentVer != null && !relVer.isGreaterThan(currentVer)) {
        return null;
      }
      if (skippedVersion != null &&
          skippedVersion.isNotEmpty &&
          (skippedVersion == relVer.toString() ||
              skippedVersion == info.tagName ||
              skippedVersion == 'v${relVer.toString()}')) {
        return null;
      }
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Comprueba si hay una nueva versión disponible.
  /// Si [manual] es `false`, respeta la frecuencia mínima de 24 horas y [isAutoCheckEnabled].
  Future<void> checkForUpdates({bool manual = false}) async {
    if (state.isChecking || state.isDownloading || state.isVerifying) return;

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
          return;
        }
      }
    }

    state = state.copyWith(
      status: UpdateStatus.checking,
      clearError: true,
      clearInfo: true,
    );

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

      if (result.notModified) {
        // 304 Not Modified: conservar release cacheado si todavía es aplicable
        SemVer? currentVer;
        try {
          currentVer = await checker.getCurrentVersion();
        } catch (_) {}

        ReleaseInfo? restored = state.availableRelease;
        if (restored == null) {
          final rawCached = await db.getCachedReleaseJson();
          if (rawCached != null && rawCached.isNotEmpty) {
            restored = _parseAndValidateCachedRelease(
              rawCached,
              currentVer: currentVer,
              skippedVersion: manual ? null : skipped,
            );
          }
        }

        if (restored != null) {
          state = state.copyWith(
            status: UpdateStatus.updateAvailable,
            availableRelease: restored,
            lastCheckedAt: now,
          );
          if (!manual) {
            await _notifyReleaseOnce(db, notifService, restored);
          }
        } else {
          state = state.copyWith(
            status: manual ? UpdateStatus.upToDate : UpdateStatus.idle,
            clearRelease: true,
            clearDownloadedFile: true,
            lastCheckedAt: now,
          );
        }
        return;
      }

      if (result.isNewVersionAvailable && result.releaseInfo != null) {
        final info = result.releaseInfo!;
        await db.setCachedReleaseJson(jsonEncode(info.toJson()));

        final isSameDownloaded =
            state.downloadedFile != null &&
            state.availableRelease?.version == info.version &&
            state.downloadedFile!.existsSync();

        state = state.copyWith(
          status: isSameDownloaded
              ? UpdateStatus.readyToInstall
              : UpdateStatus.updateAvailable,
          availableRelease: info,
          clearDownloadedFile: !isSameDownloaded,
          lastCheckedAt: now,
        );

        if (!manual) {
          await _notifyReleaseOnce(db, notifService, info);
        }
      } else {
        await db.clearCachedReleaseJson();
        state = state.copyWith(
          status: manual ? UpdateStatus.upToDate : UpdateStatus.idle,
          clearRelease: true,
          clearDownloadedFile: true,
          lastCheckedAt: now,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e is GitHubRateLimitException
            ? 'Límite de consultas de GitHub API alcanzado. Probá más tarde.'
            : e is MissingChecksumException
            ? e.toString()
            : 'Error al comprobar actualizaciones: $e',
      );
    }
  }

  /// Emite una notificación nativa única por versión (`app_update_<version>`).
  Future<void> _notifyReleaseOnce(
    dynamic db,
    dynamic notifService,
    ReleaseInfo info,
  ) async {
    final lastNotified = await db.getLastNotifiedReleaseVersion() as String?;
    if (lastNotified == info.version) return;
    await notifService.showUpdateNotification(
      version: info.version,
      releaseNotes: info.releaseNotes,
      assetName: info.assetName,
    );
    await db.setLastNotifiedReleaseVersion(info.version);
  }

  /// Descarga el artefacto y verifica su integridad SHA-256.
  Future<void> downloadUpdate() async {
    final release = state.availableRelease;
    if (release == null || state.isDownloading || state.isVerifying) return;

    final downloader = ref.read(updateDownloaderProvider);

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(
      status: UpdateStatus.downloading,
      progress: const UpdateProgress(receivedBytes: 0, totalBytes: 0),
      clearError: true,
      clearInfo: true,
    );

    try {
      final file = await downloader.downloadAndVerify(
        release: release,
        cancelToken: _cancelToken,
        onProgress: (p) {
          state = state.copyWith(progress: p);
        },
        onVerifying: () {
          state = state.copyWith(status: UpdateStatus.verifyingChecksum);
        },
      );

      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        downloadedFile: file,
        clearError: true,
        clearInfo: true,
      );
    } catch (e) {
      if (_cancelToken?.isCancelled == true) {
        state = state.copyWith(status: UpdateStatus.updateAvailable);
        return;
      }

      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage:
            (e is ChecksumMismatchException || e is MissingChecksumException)
            ? e.toString()
            : 'Error al descargar la actualización: $e',
      );
    }
  }

  /// Ejecuta el instalador del release descargado.
  Future<void> installUpdate() async {
    final file = state.downloadedFile;
    final release = state.availableRelease;
    if (file == null || release == null || state.isInstalling) return;

    state = state.copyWith(
      status: UpdateStatus.installing,
      clearError: true,
      clearInfo: true,
    );

    try {
      final installer = ref.read(updateInstallerCallbackProvider);
      final result = await installer(
        downloadedFile: file,
        release: release,
        beforeExit: () async {
          try {
            await ref.read(appSessionProvider.notifier).prepareForAppExit();
          } catch (_) {}
        },
      );

      switch (result) {
        case InstallLaunchResult.launchedAndExiting:
          break;
        case InstallLaunchResult.needsAndroidInstallPermission:
          state = state.copyWith(
            status: UpdateStatus.readyToInstall,
            infoMessage: 'Habilitá el permiso "Instalar apps desconocidas" para LibreMIeL en Ajustes y luego volvé a tocar "Instalar actualización".',
          );
          break;
        case InstallLaunchResult.launchedExternalInstaller:
          state = state.copyWith(
            status: UpdateStatus.readyToInstall,
            infoMessage: 'Se abrió el instalador del sistema. Seguí los pasos en pantalla para completar la actualización.',
          );
          break;
      }
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
    await db.clearCachedReleaseJson();
    state = state.copyWith(
      status: UpdateStatus.idle,
      clearRelease: true,
      clearDownloadedFile: true,
      clearInfo: true,
      skippedVersion: version,
    );
  }

  /// Descarta el aviso actual de actualización (sin olvidar que existe si vuelve a abrir Ajustes).
  void dismiss() {
    if (state.isReadyToInstall || state.availableRelease != null) {
      state = state.copyWith(clearInfo: true);
    } else {
      state = state.copyWith(status: UpdateStatus.idle, clearInfo: true);
    }
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
