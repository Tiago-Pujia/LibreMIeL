import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/miel_theme.dart';

/// Envoltorio reutilizable para tarjetas, filas de mensajes, enlaces y temas
/// de foro que añade menú contextual (clic derecho), apertura externa directa
/// con Middle Click y Shift + Click sin efectos colaterales (Fase 12).
class MielWebActionTarget extends StatelessWidget {
  const MielWebActionTarget({
    super.key,
    required this.child,
    this.resolveUrl,
    this.url,
    this.title,
    this.onOpenInApp,
    this.onTrigger,
    this.enableMiddleClick = true,
    this.enableShiftClick = true,
  });

  final String Function()? resolveUrl;
  final String? url;
  final String? title;
  final VoidCallback? onOpenInApp;
  final VoidCallback? onTrigger;
  final Widget child;
  final bool enableMiddleClick;
  final bool enableShiftClick;

  String _effectiveUrl() {
    if (resolveUrl != null) return resolveUrl!();
    return url ?? '';
  }

  VoidCallback? get _effectiveInAppCallback => onOpenInApp ?? onTrigger;

  Future<void> _openExternal(String targetUrl) async {
    if (targetUrl.isEmpty) return;
    final uri = Uri.tryParse(targetUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showContextMenu(BuildContext context, Offset globalPos) {
    final palette = MielPalette.of(context);
    final targetUrl = _effectiveUrl();
    if (targetUrl.isEmpty) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final inAppAction = _effectiveInAppCallback;

    showMenu<String>(
      context: context,
      color: palette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: palette.cardBorder),
      ),
      position: RelativeRect.fromRect(
        globalPos & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        if (inAppAction != null)
          PopupMenuItem<String>(
            value: 'open_in_app',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.open_in_new, size: 16, color: palette.linkAccent),
                const SizedBox(width: 8),
                Text(
                  'Abrir en LibreMIeL',
                  style: TextStyle(color: palette.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'open_external',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.language, size: 16, color: palette.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Abrir en navegador web',
                style: TextStyle(color: palette.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy_link',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.link, size: 16, color: palette.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Copiar enlace de MIeL',
                style: TextStyle(color: palette.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (value == 'open_in_app') {
        inAppAction?.call();
      } else if (value == 'open_external') {
        _openExternal(targetUrl);
      } else if (value == 'copy_link') {
        Clipboard.setData(ClipboardData(text: targetUrl));
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          SnackBar(
            content: const Text('Enlace copiado al portapapeles'),
            duration: const Duration(seconds: 2),
            backgroundColor: palette.primary,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (enableMiddleClick && event.buttons == kMiddleMouseButton) {
          _openExternal(_effectiveUrl());
        }
      },
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: child,
      ),
    );
  }
}
