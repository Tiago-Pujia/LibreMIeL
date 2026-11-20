import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Emblema hexagonal libre de LibreMIEL (sin marcas registradas de UNLaM/MIeL).
class LibreMielMark extends StatelessWidget {
  const LibreMielMark({
    super.key,
    this.size = 34,
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
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _HexMarkPainter()),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 9),
          Text(
            'LibreMIEL',
            style: TextStyle(
              fontSize: size * 0.58,
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

class _HexMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.shortestSide * 0.48;

    final path = Path();
    for (var i = 0; i < 6; i++) {
      // Hexágono con vértices arriba/abajo (estilo panal / MIeL)
      final angle = (math.pi / 180) * (60 * i - 90);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00A882), Color(0xFF008566)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fillPaint);

    // Borde sutil blanco
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.045
      ..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawPath(path, borderPaint);

    // Letra "L" + acento limpio en el centro
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'L',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.shortestSide * 0.52,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
