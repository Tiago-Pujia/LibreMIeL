import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_providers.dart';
import '../../../core/network/miel_client.dart';
import '../../../core/theme/libremiel_brand.dart';
import '../../../core/theme/miel_theme.dart';
import '../module_providers.dart';

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

/// Avatar circular autenticado fiel a `.fotoPerfil`, `.fotoRemitente` y `.foro-fotoPerfil` de MIeL.
class MielAvatar extends ConsumerWidget {
  const MielAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20,
    this.fallbackBackgroundColor,
    this.fallbackIconColor = Colors.white,
    this.fallbackIconSize,
  });

  final String avatarUrl;
  final double radius;
  final Color? fallbackBackgroundColor;
  final Color fallbackIconColor;
  final double? fallbackIconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final bg =
        fallbackBackgroundColor ?? palette.textMuted.withValues(alpha: 0.45);
    final iconSz = fallbackIconSize ?? (radius * 1.15);

    Widget buildFallback() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Icon(Icons.person, size: iconSz, color: fallbackIconColor),
      );
    }

    final cleanUrl = avatarUrl.trim();
    if (cleanUrl.isEmpty) {
      return buildFallback();
    }

    final bytesAsync = ref.watch(authenticatedImageBytesProvider(cleanUrl));
    return bytesAsync.maybeWhen(
      data: (bytes) {
        if (bytes.isEmpty) {
          return buildFallback();
        }
        final diameter = radius * 2;
        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            bytes,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => buildFallback(),
          ),
        );
      },
      orElse: buildFallback,
    );
  }
}

/// Enlace interactivo con cursor `SystemMouseCursors.click` y subrayado en hover,
/// fiel a `a.link:hover` y `.tabla-mensajes tr a:hover` de MIeL.
class MielHoverLink extends StatefulWidget {
  const MielHoverLink({
    super.key,
    required this.text,
    required this.onTap,
    this.color,
    this.hoverColor,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w400,
    this.leadingIcon,
    this.leadingIconSize = 17,
    this.leadingIconColor,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final VoidCallback? onTap;
  final Color? color;
  final Color? hoverColor;
  final double fontSize;
  final FontWeight fontWeight;
  final IconData? leadingIcon;
  final double leadingIconSize;
  final Color? leadingIconColor;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<MielHoverLink> createState() => _MielHoverLinkState();
}

class _MielHoverLinkState extends State<MielHoverLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final baseColor = widget.color ?? palette.linkAccent;
    final activeColor = _hovered ? (widget.hoverColor ?? baseColor) : baseColor;

    final textWidget = Text(
      widget.text,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        color: activeColor,
        decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
        decorationColor: activeColor,
      ),
    );

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.leadingIcon == null
            ? textWidget
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.leadingIcon,
                    size: widget.leadingIconSize,
                    color: widget.leadingIconColor ?? palette.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(child: textWidget),
                ],
              ),
      ),
    );
  }
}

/// Fila de tabla con resaltado de fondo en hover (`.w3-hoverable`) pero manteniendo
/// el cursor normal en la fila para que solo los botones/enlaces cambien a mano (`click`).
class MielHoverRow extends StatefulWidget {
  const MielHoverRow({
    super.key,
    required this.child,
    this.backgroundColor = Colors.transparent,
    this.hoverColor,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  });

  final Widget child;
  final Color backgroundColor;
  final Color? hoverColor;
  final BoxBorder? border;
  final EdgeInsetsGeometry padding;

  @override
  State<MielHoverRow> createState() => _MielHoverRowState();
}

class _MielHoverRowState extends State<MielHoverRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final effectiveHover =
        widget.hoverColor ?? palette.cardHover.withValues(alpha: 0.45);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _hovered ? effectiveHover : widget.backgroundColor,
          border:
              widget.border ??
              Border(bottom: BorderSide(color: palette.divider)),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Campo de búsqueda unificado (`36px` exactos de alto) con botón `Buscar` acoplado,
/// perfectamente alineado en vertical y expandible al ancho máximo disponible.
class MielSearchBarField extends StatefulWidget {
  const MielSearchBarField({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
    this.buttonLabel = 'Buscar',
  });

  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onCleared;
  final String buttonLabel;

  @override
  State<MielSearchBarField> createState() => _MielSearchBarFieldState();
}

class _MielSearchBarFieldState extends State<MielSearchBarField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);

    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 10, right: 4),
              decoration: BoxDecoration(
                color: palette.inputBackground,
                border: Border.all(
                  color: _focused ? palette.primary : palette.inputBorder,
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      onChanged: widget.onChanged,
                      onSubmitted: (_) => widget.onSubmitted(),
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                  ),
                  if (widget.query.isNotEmpty)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: widget.onCleared,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.clear,
                            size: 16,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Material(
            color: const Color(0xFF616161),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(2),
            ),
            child: InkWell(
              onTap: widget.onSubmitted,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, size: 16, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      widget.buttonLabel,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
        mouseCursor: onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
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

SnackBar _buildMielDownloadSnackBar({
  required Widget leading,
  required String message,
  required VoidCallback onClose,
  List<Widget> actions = const [],
  Color borderColor = const Color(0xFF009688),
  Duration duration = const Duration(seconds: 4),
}) {
  return SnackBar(
    backgroundColor: const Color(0xFF1F2421),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    elevation: 6,
    duration: duration,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(color: borderColor, width: 1.2),
    ),
    content: Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        for (final action in actions) ...[const SizedBox(width: 6), action],
        const SizedBox(width: 4),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 17, color: Colors.white70),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Descarga un archivo autenticado desde MIeL mostrando una notificación flotante
/// oscura con cierre automático garantizado y botón manual de cierre (`✕`).
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

  messenger?.clearSnackBars();
  final progressCtrl = messenger?.showSnackBar(
    _buildMielDownloadSnackBar(
      leading: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF4DB6AC),
        ),
      ),
      message: 'Descargando $label…',
      onClose: () => messenger.clearSnackBars(),
    ),
  );

  try {
    final reader = await ref.read(mielInteractiveReaderProvider.future);
    final downloadService = ref.read(fileDownloadServiceProvider);
    DownloadedFileResult result;
    try {
      result = await downloadService.downloadFromMiel(
        reader: reader,
        urlOrPath: url,
        fallbackFileName: fallbackFileName,
      );
    } on MielSessionExpiredException {
      final ok = await ref
          .read(appSessionProvider.notifier)
          .ensureActiveSession(forceRelogin: true);
      if (!ok) rethrow;
      result = await downloadService.downloadFromMiel(
        reader: reader,
        urlOrPath: url,
        fallbackFileName: fallbackFileName,
      );
    }

    onDownloaded?.call();
    try {
      progressCtrl?.close();
    } catch (_) {}
    messenger?.clearSnackBars();

    if (messenger != null) {
      final doneCtrl = messenger.showSnackBar(
        _buildMielDownloadSnackBar(
          leading: const Icon(
            Icons.check_circle_outline,
            size: 19,
            color: Color(0xFF4DB6AC),
          ),
          message: 'Guardado: ${result.fileName}',
          onClose: messenger.clearSnackBars,
          actions: [
            TextButton(
              onPressed: () {
                messenger.clearSnackBars();
                downloadService.openDownloadedFile(result.filePath);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4DB6AC),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Abrir',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                messenger.clearSnackBars();
                downloadService.openContainingFolder(result.filePath);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Carpeta', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
      );
      Timer(const Duration(seconds: 4), () {
        try {
          doneCtrl.close();
        } catch (_) {}
      });
    }
  } catch (e) {
    try {
      progressCtrl?.close();
    } catch (_) {}
    messenger?.clearSnackBars();

    if (messenger != null) {
      final errCtrl = messenger.showSnackBar(
        _buildMielDownloadSnackBar(
          leading: const Icon(
            Icons.error_outline,
            size: 19,
            color: Color(0xFFEF5350),
          ),
          borderColor: const Color(0xFFEF5350),
          message: 'No se pudo descargar el archivo: $e',
          onClose: messenger.clearSnackBars,
          actions: [
            TextButton(
              onPressed: () {
                messenger.clearSnackBars();
                openMielExternalUrl(url);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF9A9A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Abrir en web',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
      Timer(const Duration(seconds: 5), () {
        try {
          errCtrl.close();
        } catch (_) {}
      });
    }
  }
}

/// Muestra un aviso flotante estilizado con auto-cierre y botón cerrar.
void showMielStatusToast(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.clearSnackBars();
  final ctrl = messenger.showSnackBar(
    _buildMielDownloadSnackBar(
      leading: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        size: 19,
        color: isError ? const Color(0xFFEF5350) : const Color(0xFF4DB6AC),
      ),
      borderColor: isError
          ? const Color(0xFFEF5350)
          : const Color(0xFF009688),
      message: message,
      onClose: messenger.clearSnackBars,
      duration: duration,
    ),
  );
  Timer(duration, () {
    try {
      ctrl.close();
    } catch (_) {}
  });
}

/// Abre el selector nativo de archivos (`file_selector`) y valida extensión y tamaño
/// contra las reglas oficiales de MIeL (`helpers.js`).
Future<({String path, String name})?> pickValidatedMielAttachment(
  BuildContext context, {
  required int maxSizeMb,
}) async {
  final file = await openFile();
  if (file == null || file.path.isEmpty) return null;

  final error = validateMielUploadFile(
    filePath: file.path,
    maxSizeMb: maxSizeMb,
  );
  if (error != null) {
    if (context.mounted) {
      showMielStatusToast(context, message: error, isError: true);
    }
    return null;
  }
  return (path: file.path, name: file.name);
}
