import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_providers.dart';
import '../../../core/theme/libremiel_brand.dart';
import '../../../core/theme/miel_theme.dart';

/// Encabezado `h1` Light (`30px`, `FontWeight.w300`) fiel a los módulos de MIeL.
class MielModuleHeader extends StatelessWidget {
  const MielModuleHeader({
    super.key,
    required this.title,
    this.badgeCount = 0,
    this.trailing,
  });

  final String title;
  final int badgeCount;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              MielRedBadge(
                count: badgeCount,
                backgroundColor: palette.badgeRed,
              ),
            ],
          ],
        ),
        ?trailing,
      ],
    );
  }
}

/// Botón de acción plano (`border-radius: 3px`) fiel a `.w3-btn` de MIeL.
class MielActionButton extends StatelessWidget {
  const MielActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final bg = primary ? palette.primary : palette.buttonSecondaryBackground;
    final fg = primary ? Colors.white : palette.textPrimary;
    final hover = primary ? palette.primaryHover : palette.buttonSecondaryHover;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(3),
        hoverColor: hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista de carga unificada para módulos de Fase 2.
class MielModuleLoadingView extends StatelessWidget {
  const MielModuleLoadingView({
    super.key,
    this.message = 'Cargando desde MIeL…',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 13.5, color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de estado vacío fiel a los mensajes `<p>` de MIeL.
class MielModuleEmptyView extends StatelessWidget {
  const MielModuleEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: palette.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Vista de error con botón de reintento y apertura directa en MIeL web.
class MielModuleErrorView extends StatelessWidget {
  const MielModuleErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.mielWebUrl,
  });

  final String message;
  final VoidCallback onRetry;
  final String? mielWebUrl;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.paleRedBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.paleRedBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: palette.badgeRed, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              MielActionButton(
                label: 'Reintentar',
                icon: Icons.refresh,
                primary: true,
                onPressed: onRetry,
              ),
              if (mielWebUrl != null && mielWebUrl!.isNotEmpty)
                MielActionButton(
                  label: 'Abrir en MIeL web',
                  icon: Icons.open_in_new,
                  onPressed: () => openMielExternalUrl(mielWebUrl!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Abre una URL externa en el navegador del sistema.
Future<void> openMielExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Descarga un archivo autenticado desde MIeL mostrando feedback en `SnackBar`
/// y ofreciendo botones para abrir el archivo o la carpeta contenedora.
Future<void> triggerMielFileDownload(
  BuildContext context,
  WidgetRef ref, {
  required String url,
  String? fallbackFileName,
  VoidCallback? onDownloaded,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final label = (fallbackFileName != null && fallbackFileName.trim().isNotEmpty)
      ? fallbackFileName.trim()
      : 'archivo';

  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Text('Descargando $label…'),
      duration: const Duration(seconds: 20),
    ),
  );

  try {
    final reader = await ref.read(mielInteractiveReaderProvider.future);
    final downloadService = ref.read(fileDownloadServiceProvider);
    final result = await downloadService.downloadFromMiel(
      reader: reader,
      urlOrPath: url,
      fallbackFileName: fallbackFileName,
    );

    onDownloaded?.call();
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Guardado: ${result.fileName}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () => downloadService.openDownloadedFile(result.filePath),
        ),
      ),
    );
  } catch (e) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('No se pudo descargar el archivo: $e'),
        action: SnackBarAction(
          label: 'Abrir en web',
          onPressed: () => openMielExternalUrl(url),
        ),
      ),
    );
  }
}
