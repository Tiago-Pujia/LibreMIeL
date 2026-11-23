import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/miel_theme.dart';

/// Barra flotante compacta de búsqueda en página (`Ctrl + F`) con estética MIeL.
class BrowserFindBar extends StatefulWidget {
  const BrowserFindBar({
    super.key,
    required this.onQueryChanged,
    required this.onClose,
    this.initialQuery = '',
    this.matchCount,
  });

  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClose;
  final String initialQuery;
  final int? matchCount;

  @override
  State<BrowserFindBar> createState() => _BrowserFindBarState();
}

class _BrowserFindBarState extends State<BrowserFindBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode(debugLabel: 'BrowserFindBarInput');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant BrowserFindBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: palette.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: palette.linkAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  widget.onClose();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Buscar en la página… (Esc para cerrar)',
                  hintStyle: TextStyle(
                    color: palette.textMuted,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onChanged: widget.onQueryChanged,
              ),
            ),
          ),
          if (widget.matchCount != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: palette.buttonSecondaryBackground,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Text(
                '${widget.matchCount} coincidencias',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, size: 16, color: palette.textMuted),
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () {
                _controller.clear();
                widget.onQueryChanged('');
                _focusNode.requestFocus();
              },
            ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: palette.textSecondary),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Cerrar búsqueda (Esc)',
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }
}
