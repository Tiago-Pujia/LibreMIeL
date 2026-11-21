import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/parsers/text_normalizer.dart';
import '../../../core/theme/miel_theme.dart';
import '../module_providers.dart';
import 'module_state_views.dart';

/// Callback al hacer clic en una `@mención` (`strong.tagUsuario`) dentro de un mensaje de Foro.
typedef MentionTapCallback = void Function(
  String mentionedUserId,
  String mentionedMessageId,
);

/// Renderizador nativo de fragmentos HTML de MIeL (`div.contrastify` en Mensajería y Foros)
/// usando `SelectableText.rich`, adaptable automáticamente a modo claro y oscuro.
class MielRichText extends StatefulWidget {
  const MielRichText({
    super.key,
    required this.htmlContent,
    this.fallbackPlainText = '',
    this.highlightQuery = '',
    this.onTapMention,
    this.baseFontSize = 13.5,
  });

  final String htmlContent;
  final String fallbackPlainText;
  final String highlightQuery;
  final MentionTapCallback? onTapMention;
  final double baseFontSize;

  @override
  State<MielRichText> createState() => _MielRichTextState();
}

class _MielRichTextState extends State<MielRichText> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();
    final palette = MielPalette.of(context);
    final baseStyle = TextStyle(
      fontSize: widget.baseFontSize,
      height: 1.5,
      color: palette.textPrimary,
    );

    if (widget.htmlContent.trim().isEmpty) {
      return SelectableText.rich(
        _buildHighlightedTextSpan(widget.fallbackPlainText, baseStyle, palette),
      );
    }

    final fragment = html_parser.parseFragment(widget.htmlContent);
    final spans = <InlineSpan>[];
    _walkNodes(
      fragment.nodes,
      spans: spans,
      currentStyle: baseStyle,
      palette: palette,
    );

    // Recortar saltos de línea finales sobrantes
    while (spans.isNotEmpty) {
      final last = spans.last;
      if (last is TextSpan &&
          (last.text == '\n' || last.text == '\n\n') &&
          (last.children == null || last.children!.isEmpty)) {
        spans.removeLast();
      } else {
        break;
      }
    }

    return SelectableText.rich(TextSpan(style: baseStyle, children: spans));
  }

  void _walkNodes(
    List<dom.Node> nodes, {
    required List<InlineSpan> spans,
    required TextStyle currentStyle,
    required MielPalette palette,
  }) {
    for (final node in nodes) {
      if (node is dom.Text) {
        final text = node.text
            .replaceAll('\r\n', '\n')
            .replaceAll(RegExp(r'[ \t]+'), ' ');
        if (text.trim().isEmpty && !text.contains(' ')) continue;
        spans.add(_buildHighlightedTextSpan(text, currentStyle, palette));
      } else if (node is dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        if (tag == 'br') {
          spans.add(const TextSpan(text: '\n'));
          continue;
        }

        // @Mención en Foros (strong.tagUsuario)
        if (node.classes.contains('tagUsuario')) {
          final uid =
              node.attributes['data-idusuario']?.trim() ??
              node.attributes['data-idUsuario']?.trim() ??
              '';
          final msgId =
              node.attributes['data-idmensaje']?.trim() ??
              node.attributes['data-idMensaje']?.trim() ??
              '';
          final label = cleanWhitespace(node.text);
          final mentionStyle = currentStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.linkAccent,
          );
          TapGestureRecognizer? recognizer;
          if (widget.onTapMention != null && msgId.isNotEmpty) {
            recognizer = TapGestureRecognizer()
              ..onTap = () => widget.onTapMention!(uid, msgId);
            _recognizers.add(recognizer);
          }
          spans.add(
            TextSpan(
              text: '$label ',
              style: mentionStyle,
              recognizer: recognizer,
            ),
          );
          continue;
        }

        // Enlaces <a href="...">
        if (tag == 'a') {
          final rawHref = node.attributes['href'] ?? '';
          final url = resolveMielUrl(rawHref);
          final label = cleanWhitespace(node.text);
          final linkStyle = currentStyle.copyWith(
            color: palette.linkAccent,
            decoration: TextDecoration.underline,
            decorationColor: palette.linkAccent,
          );
          TapGestureRecognizer? recognizer;
          if (url.isNotEmpty) {
            recognizer = TapGestureRecognizer()
              ..onTap = () {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              };
            _recognizers.add(recognizer);
          }
          spans.add(
            TextSpan(
              text: label.isEmpty ? url : label,
              style: linkStyle,
              recognizer: recognizer,
            ),
          );
          continue;
        }

        var nextStyle = currentStyle;
        if (tag == 'strong' || tag == 'b') {
          nextStyle = nextStyle.copyWith(fontWeight: FontWeight.w700);
        } else if (tag == 'em' || tag == 'i') {
          nextStyle = nextStyle.copyWith(fontStyle: FontStyle.italic);
        } else if (tag == 'u') {
          nextStyle = nextStyle.copyWith(decoration: TextDecoration.underline);
        } else if (tag == 'code' || tag == 'pre') {
          nextStyle = nextStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: palette.cardBackground,
          );
        }

        final isBlock =
            tag == 'p' ||
            tag == 'div' ||
            tag == 'blockquote' ||
            tag == 'h1' ||
            tag == 'h2' ||
            tag == 'h3' ||
            tag == 'h4';

        if (tag == 'li') {
          spans.add(TextSpan(text: '• ', style: nextStyle));
        }

        _walkNodes(
          node.nodes,
          spans: spans,
          currentStyle: nextStyle,
          palette: palette,
        );

        if (tag == 'li') {
          spans.add(const TextSpan(text: '\n'));
        } else if (isBlock && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n\n'));
        }
      }
    }
  }

  TextSpan _buildHighlightedTextSpan(
    String text,
    TextStyle style,
    MielPalette palette,
  ) {
    final q = widget.highlightQuery.trim();
    if (q.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQ = q.toLowerCase();
    final children = <InlineSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQ, start);
      if (index < 0) {
        if (start < text.length) {
          children.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }
      if (index > start) {
        children.add(
          TextSpan(text: text.substring(start, index), style: style),
        );
      }
      children.add(
        TextSpan(
          text: text.substring(index, index + q.length),
          style: style.copyWith(
            backgroundColor: palette.paleYellowBackground,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + q.length;
    }

    return TextSpan(style: style, children: children);
  }
}

/// Miniatura de imagen adjunta autenticada en Foros (`img.foroImgAdjuntos`)
/// con visor modal de zoom (`InteractiveViewer`) y descarga.
class MielAuthenticatedImage extends ConsumerWidget {
  const MielAuthenticatedImage({
    super.key,
    required this.imageUrl,
    required this.fileName,
  });

  final String imageUrl;
  final String fileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final bytesAsync = ref.watch(authenticatedImageBytesProvider(imageUrl));

    return bytesAsync.when(
      loading: () => Container(
        width: 240,
        height: 140,
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: palette.cardBorder),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => OutlinedButton.icon(
        onPressed: () => triggerMielFileDownload(
          context,
          ref,
          url: imageUrl,
          fallbackFileName: fileName,
        ),
        icon: const Icon(Icons.broken_image_outlined, size: 18),
        label: Text('Descargar imagen ($fileName)'),
      ),
      data: (bytes) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openZoomDialog(context, ref, bytes, palette),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 310, maxHeight: 260),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: palette.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    fileName,
                    style: TextStyle(fontSize: 12, color: palette.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openZoomDialog(
    BuildContext context,
    WidgetRef ref,
    Uint8List bytes,
    MielPalette palette,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: palette.cardBackground,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 740),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => triggerMielFileDownload(
                        context,
                        ref,
                        url: imageUrl,
                        fallbackFileName: fileName,
                      ),
                      icon: const Icon(
                        Icons.file_download,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Descargar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
