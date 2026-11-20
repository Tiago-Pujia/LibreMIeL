import 'package:material_ui/material_ui.dart';

/// Emblema de LibreMIEL usando la imagen personalizada (`assets/icons/libremiel.png`).
class LibreMielMark extends StatelessWidget {
  const LibreMielMark({
    super.key,
    this.size = 36,
    this.showWordmark = true,
    this.lightText = false,
  });

  final double size;
  final bool showWordmark;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordColor = lightText || isDark
        ? Colors.white
        : const Color(0xFF1F2925);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset(
            'assets/icons/libremiel.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 9),
          Text(
            'LibreMIEL',
            style: TextStyle(
              fontSize: size * 0.56,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: wordColor,
              height: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

/// Píldora roja de notificación fiel a `.w3-badge.w3-red.w3-small`.
class MielRedBadge extends StatelessWidget {
  const MielRedBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.compact = false,
  });

  final int count;
  final Color? backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? const Color(0xFFEA4A3E) : const Color(0xFFF44336));
    final label = count > 999 ? '999+' : count.toString();

    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 18 : 20,
        minHeight: compact ? 16 : 18,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: label.length > 1 ? 6 : 5,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}
