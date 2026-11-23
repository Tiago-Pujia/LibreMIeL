import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/miel_theme.dart';
import '../../platform/updater/update_models.dart';
import '../../platform/updater/updater_controller.dart';

/// Diálogo modal que presenta los detalles de una nueva versión disponible,
/// descarga el paquete con barra de progreso interactiva y permite instalarla.
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  /// Muestra el diálogo de actualización si no está ya desplegado.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(updaterProvider);
    final controller = ref.read(updaterProvider.notifier);
    final release = state.availableRelease;

    if (release == null && state.isChecking) {
      return AlertDialog(
        backgroundColor: palette.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.cardBorder),
        ),
        title: Text(
          'Buscando actualizaciones…',
          style: TextStyle(color: palette.textPrimary),
        ),
        content: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Consultando GitHub Releases…',
                style: TextStyle(color: palette.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    if (release == null) {
      return AlertDialog(
        backgroundColor: palette.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.cardBorder),
        ),
        title: Text(
          'Actualizaciones',
          style: TextStyle(color: palette.textPrimary),
        ),
        content: Text(
          state.status == UpdateStatus.upToDate
              ? '¡Estás usando la versión más reciente de LibreMIeL (${state.currentVersion})!'
              : (state.errorMessage ?? 'No hay actualizaciones disponibles.'),
          style: TextStyle(color: palette.textPrimary),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: palette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: palette.cardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera con ícono y versiones
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.system_update_alt,
                      color: palette.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva versión disponible',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'v${state.currentVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textMuted,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: palette.linkAccent,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: palette.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'v${release.version}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detalles del archivo (nombre, tamaño)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : const Color(0xFFF7F8F9),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: palette.linkAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        release.assetName,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: palette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (release.formattedSize.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        release.formattedSize,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Notas de la versión
              Text(
                'Novedades y cambios:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.linkAccent,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black12 : Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      release.releaseNotes.trim().isNotEmpty
                          ? release.releaseNotes.trim()
                          : 'No se detallaron notas para este release.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sección de progreso y estado
              if (state.isDownloading ||
                  state.isVerifying ||
                  state.isInstalling) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.isInstalling
                              ? 'Iniciando instalador…'
                              : state.isVerifying
                              ? 'Verificando firma criptográfica SHA-256…'
                              : 'Descargando actualización…',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: palette.textPrimary,
                          ),
                        ),
                        if (state.isDownloading && state.progress != null)
                          Text(
                            '${(state.progress!.fraction * 100).toInt()}% (${state.progress!.formattedReceived} / ${state.progress!.formattedTotal})',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (state.isVerifying || state.isInstalling)
                          ? null
                          : state.progress?.fraction,
                      backgroundColor: palette.cardBorder,
                      color: palette.primary,
                      minHeight: 6,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else if (state.isReadyToInstall) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: palette.primary.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.infoMessage != null
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        color: palette.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.infoMessage ??
                              'Descarga completada y verificada contra SHA256SUMS.txt. '
                                  'Lista para instalar.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: palette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (state.status == UpdateStatus.error &&
                  state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.badgeRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: palette.badgeRed.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: palette.badgeRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.badgeRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botones de acción
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (state.isDownloading) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: controller.cancelDownload,
                      child: const Text('Cancelar descarga'),
                    ),
                  ] else if (state.isVerifying || state.isInstalling) ...[
                    TextButton(
                      onPressed: null,
                      child: Text(
                        state.isVerifying ? 'Verificando…' : 'Instalando…',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ),
                  ] else if (state.isReadyToInstall) ...[
                    TextButton(
                      onPressed: () {
                        controller.dismiss();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Más tarde',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      icon: const Icon(Icons.install_desktop, size: 18),
                      label: const Text('Instalar actualización'),
                      onPressed: controller.installUpdate,
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        controller.skipVersion(release.version);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Omitir versión',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.dismiss();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Más tarde',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(
                        state.status == UpdateStatus.error
                            ? 'Reintentar'
                            : 'Actualizar ahora',
                      ),
                      onPressed: controller.downloadUpdate,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
