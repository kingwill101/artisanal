import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:ultraviolet/web.dart' show CanvasTerminalRenderer;
import 'package:web/web.dart' as web;

import '../terminal/backend.dart' show BackendTerminal;
import '../tui/program.dart' show runProgram;
import '../tui/renderer.dart' show TuiRendererOptions;
import 'backend_web.dart' show WebTerminalBackend;
import 'renderer_web.dart' show WebUltravioletRenderer;

/// Default terminal dimensions when no canvas size has been computed yet.
const _defaultCols = 80;
const _defaultRows = 24;

({int width, int height}) _viewportTerminalSize(
  CanvasTerminalRenderer canvasRenderer,
) {
  final width = web.window.innerWidth;
  final height = web.window.innerHeight;
  final cols = (width / canvasRenderer.cellWidth).floor();
  final rows = (height / canvasRenderer.cellHeight).floor();
  return (
    width: cols < 1 ? _defaultCols : cols,
    height: rows < 1 ? _defaultRows : rows,
  );
}

void _resizeCanvasToTerminal(
  web.HTMLCanvasElement canvas,
  CanvasTerminalRenderer canvasRenderer,
  ({int width, int height}) size,
) {
  final viewportWidth = web.window.innerWidth.toDouble();
  final viewportHeight = web.window.innerHeight.toDouble();
  final devicePixelRatio = web.window.devicePixelRatio;
  final scale = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;

  canvasRenderer.resize(size.width, size.height);
  canvasRenderer.configureViewport(
    width: viewportWidth,
    height: viewportHeight,
    devicePixelRatio: scale,
  );
  canvas.width = (viewportWidth * scale).ceil();
  canvas.height = (viewportHeight * scale).ceil();
  canvas.style.width = '${viewportWidth.ceil()}px';
  canvas.style.height = '${viewportHeight.ceil()}px';
  canvas.style.display = 'block';
}

int _clampMouseCell(int value, int max) {
  if (max <= 0) return 1;
  return math.max(1, math.min(value, max));
}

({int col, int row}) _mouseCellPosition(
  web.MouseEvent event,
  web.HTMLCanvasElement canvas,
  CanvasTerminalRenderer canvasRenderer,
) {
  final rect = canvas.getBoundingClientRect();
  final localX = event.clientX - rect.left;
  final localY = event.clientY - rect.top;
  return (
    col: _clampMouseCell(
      (localX / canvasRenderer.cellWidth).floor() + 1,
      canvasRenderer.width(),
    ),
    row: _clampMouseCell(
      (localY / canvasRenderer.cellHeight).floor() + 1,
      canvasRenderer.height(),
    ),
  );
}

int _mouseModifiers(web.MouseEvent event) {
  final shift = event.shiftKey ? 4 : 0;
  final alt = event.altKey ? 8 : 0;
  final ctrl = event.ctrlKey ? 16 : 0;
  return shift + alt + ctrl;
}

int _mouseButtonCode(int button) {
  return switch (button) {
    0 => 0,
    1 => 1,
    2 => 2,
    _ => 0,
  };
}

List<int> _encodeMouseEvent({
  required int cb,
  required int col,
  required int row,
  required bool release,
}) {
  final suffix = release ? 'm' : 'M';
  return utf8.encode('\x1b[<$cb;$col;$row$suffix');
}

List<int> _encodeWheelEvent(
  web.WheelEvent event,
  web.HTMLCanvasElement canvas,
  CanvasTerminalRenderer canvasRenderer,
) {
  final position = _mouseCellPosition(event, canvas, canvasRenderer);
  final direction = event.deltaY < 0 ? 64 : 65;
  final cb = direction + _mouseModifiers(event);
  return _encodeMouseEvent(
    cb: cb,
    col: position.col,
    row: position.row,
    release: false,
  );
}

/// Options for configuring [runWidgetAppInBrowser].
final class BrowserRunOptions {
  const BrowserRunOptions({
    this.fontSize = 14,
    this.fontFamily = 'monospace',
    this.canvasId,
    this.appendToBody = true,
  });

  /// Font size in pixels for the canvas renderer.
  final double fontSize;

  /// Font family for the canvas renderer.
  final String fontFamily;

  /// Optional id of an existing canvas element.
  ///
  /// When null, a new canvas is created and appended to the document body
  /// (if [appendToBody] is true).
  final String? canvasId;

  /// Whether to append the created canvas to `document.body`.
  final bool appendToBody;
}

/// Runs a TUI [app] (or any [Model]-based program) in the browser, rendering
/// to an HTML5 canvas element.
///
/// This is the primary web/WASM entry point. It:
/// 1. Creates or finds a canvas element
/// 2. Sets up a [CanvasTerminalRenderer] for cell rendering
/// 3. Creates a [WebTerminalBackend] with DOM event wiring
/// 4. Creates a [WebUltravioletRenderer] that bridges UV rendering to the canvas
/// 5. Runs the program
Future<void> runWidgetAppInBrowser<M extends /* Model */ Object>(
  M app, {
  BrowserRunOptions options = const BrowserRunOptions(),
}) async {
  // 1. Set up canvas
  final canvas = options.canvasId != null
      ? (web.document.getElementById(options.canvasId!)
            as web.HTMLCanvasElement)
      : web.document.createElement('canvas') as web.HTMLCanvasElement;

  if (options.appendToBody && canvas.parentNode == null) {
    web.document.body!.appendChild(canvas);
  }

  final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;

  final canvasRenderer = CanvasTerminalRenderer(
    context,
    fontSize: options.fontSize,
    fontFamily: options.fontFamily,
  );
  canvasRenderer.measureFont();
  final initialSize = _viewportTerminalSize(canvasRenderer);
  _resizeCanvasToTerminal(canvas, canvasRenderer, initialSize);

  // 2. Set up backend
  final backend = WebTerminalBackend(initialSize: initialSize);
  final terminal = BackendTerminal(backend);

  // 3. Create the UV->canvas renderer
  final renderer = WebUltravioletRenderer(
    terminal: terminal,
    options: const TuiRendererOptions(
      fps: 60,
      altScreen: false,
      hideCursor: true,
    ),
    canvasRenderer: canvasRenderer,
  );

  // 4. Wire DOM keyboard input
  final onKeyDown = ((web.Event event) {
    final ke = event as web.KeyboardEvent;
    event.preventDefault();

    if (ke.key.length == 1) {
      backend.addInput(utf8.encode(ke.key));
    } else {
      _handleSpecialKey(ke, backend);
    }
  }).toJS;

  web.document.addEventListener('keydown', onKeyDown);

  var activeMouseButton = -1;

  final onMouseDown = ((web.Event event) {
    final mouse = event as web.MouseEvent;
    event.preventDefault();
    activeMouseButton = mouse.button;
    final position = _mouseCellPosition(mouse, canvas, canvasRenderer);
    final cb = _mouseButtonCode(mouse.button) + _mouseModifiers(mouse);
    backend.addInput(
      _encodeMouseEvent(
        cb: cb,
        col: position.col,
        row: position.row,
        release: false,
      ),
    );
  }).toJS;

  final onMouseUp = ((web.Event event) {
    final mouse = event as web.MouseEvent;
    event.preventDefault();
    final position = _mouseCellPosition(mouse, canvas, canvasRenderer);
    final cb = 3 + _mouseModifiers(mouse);
    activeMouseButton = -1;
    backend.addInput(
      _encodeMouseEvent(
        cb: cb,
        col: position.col,
        row: position.row,
        release: true,
      ),
    );
  }).toJS;

  final onMouseMove = ((web.Event event) {
    final mouse = event as web.MouseEvent;
    if (activeMouseButton < 0) return;
    event.preventDefault();
    final position = _mouseCellPosition(mouse, canvas, canvasRenderer);
    final cb =
        32 + _mouseButtonCode(activeMouseButton) + _mouseModifiers(mouse);
    backend.addInput(
      _encodeMouseEvent(
        cb: cb,
        col: position.col,
        row: position.row,
        release: false,
      ),
    );
  }).toJS;

  canvas.addEventListener('mousedown', onMouseDown);
  canvas.addEventListener('mouseup', onMouseUp);
  canvas.addEventListener('mousemove', onMouseMove);

  final onWheel = ((web.Event event) {
    final wheel = event as web.WheelEvent;
    event.preventDefault();
    if (wheel.deltaY == 0) return;
    final ticks = math.max(1, (wheel.deltaY.abs() / 40).round());
    for (var i = 0; i < ticks; i++) {
      backend.addInput(_encodeWheelEvent(wheel, canvas, canvasRenderer));
    }
  }).toJS;

  canvas.addEventListener('wheel', onWheel);

  // 5. Wire resize
  final onResize = ((web.Event _) {
    final size = _viewportTerminalSize(canvasRenderer);
    _resizeCanvasToTerminal(canvas, canvasRenderer, size);
    backend.notifySizeChanged(size);
  }).toJS;

  web.window.addEventListener('resize', onResize);

  // 6. Wire page close
  final onBeforeUnload = ((web.Event _) {
    backend.requestShutdown();
  }).toJS;

  web.window.addEventListener('beforeunload', onBeforeUnload);

  // 7. Run the program
  try {
    await runProgram(
      app as dynamic,
      host: null,
      terminal: terminal,
      renderer: renderer,
    );
  } finally {
    web.document.removeEventListener('keydown', onKeyDown);
    canvas.removeEventListener('mousedown', onMouseDown);
    canvas.removeEventListener('mouseup', onMouseUp);
    canvas.removeEventListener('mousemove', onMouseMove);
    canvas.removeEventListener('wheel', onWheel);
    web.window.removeEventListener('resize', onResize);
    web.window.removeEventListener('beforeunload', onBeforeUnload);
    backend.dispose();
  }
}

void _handleSpecialKey(web.KeyboardEvent event, WebTerminalBackend backend) {
  // Map common special keys to their ANSI escape sequences.
  // Extend this as needed for function keys, modifiers, etc.
  switch (event.key) {
    case 'Enter':
      backend.addInput([0x0D]); // CR
    case 'Backspace':
      backend.addInput([0x7F]); // DEL
    case 'Escape':
      backend.addInput([0x1B]); // ESC
    case 'Tab':
      backend.addInput([0x09]); // TAB
    case 'ArrowUp':
      backend.addInput([0x1B, 0x5B, 0x41]); // CSI A
    case 'ArrowDown':
      backend.addInput([0x1B, 0x5B, 0x42]); // CSI B
    case 'ArrowRight':
      backend.addInput([0x1B, 0x5B, 0x43]); // CSI C
    case 'ArrowLeft':
      backend.addInput([0x1B, 0x5B, 0x44]); // CSI D
    case 'Delete':
      backend.addInput([0x1B, 0x5B, 0x33, 0x7E]); // CSI 3 ~
    case 'Home':
      backend.addInput([0x1B, 0x5B, 0x48]); // CSI H
    case 'End':
      backend.addInput([0x1B, 0x5B, 0x46]); // CSI F
    case 'PageUp':
      backend.addInput([0x1B, 0x5B, 0x35, 0x7E]); // CSI 5 ~
    case 'PageDown':
      backend.addInput([0x1B, 0x5B, 0x36, 0x7E]); // CSI 6 ~
    case 'Control':
    case 'Shift':
    case 'Alt':
    case 'Meta':
      // Modifier-only presses are ignored.
      break;
    default:
      // Unrecognized key — ignore.
      break;
  }
}
