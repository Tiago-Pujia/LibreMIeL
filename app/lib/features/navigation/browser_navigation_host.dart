import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Contenedor que envuelve la interfaz autenticada de LibreMIeL capturando
/// eventos de teclado, ratón (`Mouse 4` / `Mouse 5`), zoom con `Ctrl + Wheel`
/// y atajos estilo navegador web respetando la prioridad de inputs de texto (Fase 12).
class BrowserNavigationHost extends StatefulWidget {
  const BrowserNavigationHost({
    super.key,
    required this.child,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onEscape,
    required this.onFindInPage,
    required this.onGoHome,
    required this.onStepZoom,
    required this.onResetZoom,
    this.contentScrollController,
  });

  final Widget child;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final void Function({bool forceLive}) onReload;
  final VoidCallback onEscape;
  final VoidCallback onFindInPage;
  final VoidCallback onGoHome;
  final void Function(double delta) onStepZoom;
  final VoidCallback onResetZoom;
  final ScrollController? contentScrollController;

  @override
  State<BrowserNavigationHost> createState() => _BrowserNavigationHostState();
}

class _BrowserNavigationHostState extends State<BrowserNavigationHost> {
  final FocusNode _keyboardFocusNode = FocusNode(
    debugLabel: 'BrowserNavigationHost',
  );
  int _pressedNavButtonsMask = 0;

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  bool _isEditableFocusActive() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    return ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if ((event.buttons & kBackMouseButton) != 0 &&
        (_pressedNavButtonsMask & kBackMouseButton) == 0) {
      _pressedNavButtonsMask |= kBackMouseButton;
      widget.onBack();
    }
    if ((event.buttons & kForwardMouseButton) != 0 &&
        (_pressedNavButtonsMask & kForwardMouseButton) == 0) {
      _pressedNavButtonsMask |= kForwardMouseButton;
      widget.onForward();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pressedNavButtonsMask &= event.buttons;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pressedNavButtonsMask &= event.buttons;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      final isZoomModifierHeld =
          HardwareKeyboard.instance.isControlPressed ||
          (isMac && HardwareKeyboard.instance.isMetaPressed);

      if (isZoomModifierHeld) {
        final delta = event.scrollDelta.dy < 0 ? 0.1 : -0.1;
        widget.onStepZoom(delta);
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final isCtrlOrCmd = isMac
        ? HardwareKeyboard.instance.isMetaPressed
        : HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;

    // 1. Esc siempre tiene prioridad
    if (key == LogicalKeyboardKey.escape) {
      widget.onEscape();
      return KeyEventResult.handled;
    }

    // 2. F5 y recarga
    if (key == LogicalKeyboardKey.f5) {
      widget.onReload(forceLive: isShift || isCtrlOrCmd);
      return KeyEventResult.handled;
    }

    // 3. Ctrl+R / Cmd+R (y con Shift para forceLive)
    if (isCtrlOrCmd && key == LogicalKeyboardKey.keyR) {
      widget.onReload(forceLive: isShift);
      return KeyEventResult.handled;
    }

    // 4. Ctrl+F / Cmd+F (búsqueda en página)
    if (isCtrlOrCmd && key == LogicalKeyboardKey.keyF) {
      widget.onFindInPage();
      return KeyEventResult.handled;
    }

    // 5. Navegación Back / Forward con Alt o Cmd+[ / Cmd+]
    if (isAlt && key == LogicalKeyboardKey.arrowLeft) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    if (isAlt && key == LogicalKeyboardKey.arrowRight) {
      widget.onForward();
      return KeyEventResult.handled;
    }
    if (isMac && isCtrlOrCmd && key == LogicalKeyboardKey.bracketLeft) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    if (isMac && isCtrlOrCmd && key == LogicalKeyboardKey.bracketRight) {
      widget.onForward();
      return KeyEventResult.handled;
    }
    // En macOS, Cmd+Left/Right solo si no estamos editando texto
    if (isMac &&
        isCtrlOrCmd &&
        key == LogicalKeyboardKey.arrowLeft &&
        !_isEditableFocusActive()) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    if (isMac &&
        isCtrlOrCmd &&
        key == LogicalKeyboardKey.arrowRight &&
        !_isEditableFocusActive()) {
      widget.onForward();
      return KeyEventResult.handled;
    }

    // 6. Alt + Home
    if (isAlt && key == LogicalKeyboardKey.home) {
      widget.onGoHome();
      return KeyEventResult.handled;
    }

    // 7. Zoom por teclado
    if (isCtrlOrCmd) {
      if (key == LogicalKeyboardKey.equal ||
          key == LogicalKeyboardKey.add ||
          key == LogicalKeyboardKey.numpadAdd) {
        widget.onStepZoom(0.1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.minus ||
          key == LogicalKeyboardKey.numpadSubtract) {
        widget.onStepZoom(-0.1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit0 ||
          key == LogicalKeyboardKey.numpad0) {
        widget.onResetZoom();
        return KeyEventResult.handled;
      }
    }

    // 8. Desplazamiento por teclado (solo cuando NO hay un input de texto enfocado)
    if (!_isEditableFocusActive() && widget.contentScrollController != null) {
      final sc = widget.contentScrollController!;
      if (sc.hasClients && sc.positions.length == 1) {
        final pos = sc.position;
        if (key == LogicalKeyboardKey.home) {
          sc.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.end) {
          sc.animateTo(
            pos.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.pageUp) {
          final target = (pos.pixels - pos.viewportDimension * 0.8).clamp(
            0.0,
            pos.maxScrollExtent,
          );
          sc.animateTo(
            target,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.pageDown) {
          final target = (pos.pixels + pos.viewportDimension * 0.8).clamp(
            0.0,
            pos.maxScrollExtent,
          );
          sc.animateTo(
            target,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        onPointerSignal: _handlePointerSignal,
        child: widget.child,
      ),
    );
  }
}
