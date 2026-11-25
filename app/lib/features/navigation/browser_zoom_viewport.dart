import 'package:material_ui/material_ui.dart';

/// Viewport escalado inverso que ajusta armónicamente todo el layout responsivo
/// de LibreMIeL ante niveles de zoom del `80%` al `150%` sin desbordes de texto (Fase 12).
class BrowserZoomViewport extends StatelessWidget {
  const BrowserZoomViewport({
    super.key,
    required this.zoomScale,
    required this.child,
  });

  final double zoomScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if ((zoomScale - 1.0).abs() < 0.001) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return child;
        }

        final logicalW = w / zoomScale;
        final logicalH = h / zoomScale;
        final mq = MediaQuery.of(context);

        return SizedBox(
          width: w,
          height: h,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: logicalW,
                height: logicalH,
                child: MediaQuery(
                  data: mq.copyWith(size: Size(logicalW, logicalH)),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
