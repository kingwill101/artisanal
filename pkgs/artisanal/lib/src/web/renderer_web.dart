import 'dart:async';

import 'package:ultraviolet/web.dart' show CanvasTerminalRenderer;

import '../tui/renderer.dart';

/// A UV renderer that bridges the screen buffer to an HTML5 canvas.
///
/// [WebUltravioletRenderer] extends [UltravioletTuiRenderer] to perform the
/// full ANSI→StyledString→ScreenBuffer pipeline, then renders the resulting
/// cell buffer to a [CanvasTerminalRenderer] instead of (or in addition to)
/// flushing ANSI output to a terminal.
final class WebUltravioletRenderer extends UltravioletTuiRenderer {
  WebUltravioletRenderer({
    required super.terminal,
    super.options,
    required this.canvasRenderer,
  });

  /// The canvas renderer that draws cell frames to a 2D canvas context.
  final CanvasTerminalRenderer canvasRenderer;

  @override
  Future<void> flush() async {
    await super.flush();
    final buf = screenBuffer;
    if (buf != null) {
      canvasRenderer.render(buf.buffer);
    }
  }
}
