import 'dart:async' show unawaited;
import 'dart:convert' show base64Encode, utf8;

import '../platform/platform.dart' show environment, isWindows;

import 'program.dart' show ScreenMode, UiAnchor;
import 'terminal.dart';
import 'terminal_native_frame.dart';
import 'terminal_render_inspector.dart';
import 'trace.dart';
import 'view.dart';
import '../uv/ansi.dart' show UvAnsi;
import '../uv/buffer.dart' as uv_buffer;
import '../uv/styled_string.dart' as uv_styled;
import '../uv/terminal_graphics.dart' as uv_graphics;
import '../uv/terminal_renderer.dart' as uv_term;

export '../uv/terminal_renderer.dart' show RenderMetrics;

/// Abstract renderer interface for TUI output.
///
/// Renderers are responsible for displaying the view string
/// to the terminal efficiently.
///
/// {@category TUI}
///
/// {@macro artisanal_tui_rendering_overview}
abstract class TuiRenderer {
  /// Initializes terminal state needed before the first render.
  ///
  /// Most renderers can keep the default no-op implementation, but fullscreen
  /// renderers should eagerly enter their terminal modes here so init-triggered
  /// quits still leave the terminal in a consistent state.
  void initialize() {}

  /// Renders the view to the terminal.
  ///
  /// [view] is the string representation of the current UI state,
  /// or a [View] object containing metadata.
  void render(Object view);

  /// Clears the rendered content.
  void clear();

  /// Resets internal diff / cache state so the next [render] call produces
  /// a full redraw, **without performing any terminal I/O**.
  ///
  /// Unlike [clear], which may write escape sequences to the terminal and
  /// trigger stdout flushes, [invalidate] only touches in-memory state.
  /// This makes it safe to call from contexts (like hot reload reassembly)
  /// where the subsequent render should go through the normal message-queue
  /// pipeline rather than rendering directly.
  void invalidate() {}

  /// Flushes any buffered output.
  Future<void> flush();

  /// Disposes of renderer resources.
  void dispose();

  /// Returns render performance metrics, or null if not supported.
  uv_term.RenderMetrics? get metrics;
}

/// Renderer that can expose a native UV cell-frame snapshot.
abstract interface class NativeFrameInspectableRenderer {
  /// Enables native frame capture during subsequent render flushes.
  ///
  /// Capture is intentionally opt-in because building native snapshots walks
  /// the entire terminal cell buffer and allocates per-cell inspection objects.
  /// Callers that need render evidence or interceptor payloads should enable
  /// this before rendering, then read the captured values after render.
  void setNativeFrameCaptureEnabled(bool enabled);

  /// Captures the renderer's current native frame, if available.
  TerminalNativeFrame? captureNativeFrame();

  /// Captures the renderer's most recent dirty-line delta, if available.
  TerminalNativeDeltaFrame? captureNativeDelta();

  /// Captures the renderer's most recent changed-cell delta, if available.
  TerminalNativeCellDeltaFrame? captureNativeCellDelta();
}

/// Options for configuring a [TuiRenderer].
///
/// These values are derived from [ProgramOptions] so the runtime can switch
/// between full-screen and inline presentation without changing renderer
/// implementations.
class TuiRendererOptions {
  /// Creates renderer options.
  ///
  /// All parameters have sensible defaults for fullscreen rendering.
  const TuiRendererOptions({
    this.fps = 60,
    this.altScreen = true,
    this.hideCursor = true,
    this.ansiCompress = false,
    this.screenMode = ScreenMode.fullScreen,
    this.inlineHeight = 4,
    this.uiAnchor = UiAnchor.bottom,
  });

  /// Maximum frames per second for rendering.
  ///
  /// Limits how often the screen can be redrawn to prevent
  /// excessive CPU usage and flickering.
  final int fps;

  /// Whether to use the alternate screen buffer.
  ///
  /// When true, the application runs in fullscreen mode and
  /// the original terminal content is restored on exit.
  final bool altScreen;

  /// Whether to hide the cursor during rendering.
  final bool hideCursor;

  /// Whether to compress redundant ANSI sequences.
  final bool ansiCompress;

  /// The effective screen mode for this renderer.
  final ScreenMode screenMode;

  /// Height of the inline UI region in rows.
  ///
  /// Only meaningful when [screenMode] is [ScreenMode.inline].
  final int inlineHeight;

  /// Which edge of the viewport this inline UI region is anchored to.
  final UiAnchor uiAnchor;

  /// Whether the renderer operates in inline (non-alt-screen) mode.
  bool get isInline =>
      screenMode == ScreenMode.inline || screenMode == ScreenMode.inlineAuto;

  /// The minimum time between renders.
  Duration get frameTime => Duration(milliseconds: 1000 ~/ fps);
}

/// Converts bare LF to CR+LF for terminals that require explicit carriage returns.
String _mapNewlines(String input) {
  if (input.isEmpty) return input;
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final code = input.codeUnitAt(i);
    if (code == 0x0A) {
      final prevIsCr = i > 0 && input.codeUnitAt(i - 1) == 0x0D;
      if (!prevIsCr) buffer.write('\r');
      buffer.write('\n');
      continue;
    }
    buffer.writeCharCode(code);
  }
  return buffer.toString();
}

/// Full-screen renderer using the alternate screen buffer.
///
/// Clears the entire screen and redraws from position (0,0) on each frame.
/// Best for fullscreen applications that own the entire terminal.
class FullScreenTuiRenderer implements TuiRenderer {
  /// Creates a fullscreen renderer targeting the given [terminal].
  FullScreenTuiRenderer({
    required this.terminal,
    TuiRendererOptions options = const TuiRendererOptions(),
  }) : _options = options;

  /// The terminal to render to.
  final TuiTerminal terminal;

  final TuiRendererOptions _options;

  /// The last rendered view (for skip-if-unchanged optimization).
  String? _lastView;
  TerminalRenderFrame? _lastFrame;

  /// Stopwatch for frame timing (immune to NTP/DST clock adjustments).
  final Stopwatch _frameStopwatch = Stopwatch();

  /// Whether the renderer has been initialized.
  bool _initialized = false;

  final uv_term.RenderMetrics _metrics = uv_term.RenderMetrics();

  @override
  uv_term.RenderMetrics? get metrics => _metrics;

  /// Initializes the renderer.
  ///
  /// Sets up the terminal for fullscreen rendering.
  @override
  void initialize() {
    if (_initialized) return;

    if (_options.altScreen) {
      terminal.enterAltScreen();
    }
    if (_options.hideCursor) {
      terminal.hideCursor();
    }
    terminal.clearScreen();
    _initialized = true;
  }

  @override
  void render(Object view) {
    _metrics.beginFrame();

    if (!_initialized) {
      initialize();
    }

    final String content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };

    // Frame rate limiting using Stopwatch (immune to clock adjustments)
    if (_frameStopwatch.isRunning) {
      if (_frameStopwatch.elapsed < _options.frameTime) {
        // Skip this frame
        _metrics.endFrame(skipped: true);
        return;
      }
    }

    // Skip if view hasn't changed
    if (content == _lastView) {
      _metrics.endFrame(skipped: true);
      return;
    }

    final output = _options.ansiCompress ? compressAnsi(content) : content;

    if (!terminal.supportsAnsi || _lastFrame == null) {
      _renderFullRedraw(output);
      _lastFrame = TerminalRenderFrame.parse(output);
    } else {
      final nextFrame = TerminalRenderFrame.parse(output);
      _renderDiffFrame(_lastFrame!, nextFrame);
      _lastFrame = nextFrame;
    }

    _lastView = content;
    // Reset and start the stopwatch for next frame timing
    _frameStopwatch.reset();
    _frameStopwatch.start();
    _metrics.endFrame();
  }

  /// Clears remaining content after the view.
  void _clearToEndOfScreen(String view) {
    if (!terminal.supportsAnsi) return;

    // Count lines in the view
    final viewLines = view.split('\n').length;
    final termHeight = terminal.size.height;

    // Clear remaining lines
    if (viewLines < termHeight) {
      final clearLine = '\x1b[2K'; // Clear entire line
      final buffer = StringBuffer();
      for (var i = viewLines; i < termHeight; i++) {
        buffer.write('$clearLine\n');
      }
      final clearOutput = _options.altScreen
          ? _mapNewlines(buffer.toString())
          : buffer.toString();
      terminal.write(clearOutput);
    }
  }

  void _renderFullRedraw(String content) {
    terminal.cursorHome();
    final mapped = _options.altScreen ? _mapNewlines(content) : content;
    terminal.write(mapped);

    // Clear any remaining content from previous render
    _clearToEndOfScreen(content);
  }

  void _renderDiffFrame(
    TerminalRenderFrame previous,
    TerminalRenderFrame next,
  ) {
    final maxLineCount = previous.lines.length > next.lines.length
        ? previous.lines.length
        : next.lines.length;
    final buffer = StringBuffer();

    for (var i = 0; i < maxLineCount; i++) {
      final oldLine = i < previous.lines.length ? previous.lines[i] : null;
      final newLine = i < next.lines.length ? next.lines[i] : null;

      if (oldLine == newLine) continue;

      buffer.write(Ansi.cursorTo(i + 1, 1));
      buffer.write(Ansi.clearLine);
      buffer.write(Ansi.reset);
      buffer.write(UvAnsi.resetHyperlink());

      if (newLine != null) {
        buffer.write(newLine.statePrefix);
        buffer.write(newLine.raw);
      }
    }

    if (buffer.isNotEmpty) {
      terminal.write(buffer.toString());
    }
  }

  @override
  void clear() {
    terminal.clearScreen();
    _lastView = null;
    _lastFrame = null;
  }

  @override
  void invalidate() {
    _lastView = null;
    _lastFrame = null;
  }

  @override
  Future<void> flush() async {
    await terminal.flush();
  }

  @override
  void dispose() {
    if (!_initialized) return;

    if (_options.hideCursor) {
      terminal.showCursor();
    }
    if (_options.altScreen) {
      terminal.exitAltScreen();
    }
    _initialized = false;
  }
}

/// Inline renderer that renders below the current cursor position.
///
/// This renderer doesn't use the alternate screen buffer, so
/// output accumulates in the terminal history. Best for
/// tools that should leave output visible after exit.
class InlineTuiRenderer implements TuiRenderer {
  /// Creates an inline renderer targeting the given [terminal].
  InlineTuiRenderer({
    required this.terminal,
    TuiRendererOptions options = const TuiRendererOptions(
      altScreen: false,
      hideCursor: false,
    ),
  }) : _options = options;

  /// The terminal to render to.
  final TuiTerminal terminal;

  final TuiRendererOptions _options;

  /// Number of lines in the last render.
  int _lastLineCount = 0;

  /// Stopwatch for frame timing (immune to NTP/DST clock adjustments).
  final Stopwatch _frameStopwatch = Stopwatch();

  /// Whether we've rendered at least once.
  bool _hasRendered = false;

  final uv_term.RenderMetrics _metrics = uv_term.RenderMetrics();

  @override
  uv_term.RenderMetrics? get metrics => _metrics;

  @override
  void initialize() {}

  @override
  void render(Object view) {
    _metrics.beginFrame();

    final String content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };

    // Frame rate limiting using Stopwatch (immune to clock adjustments)
    if (_frameStopwatch.isRunning) {
      if (_frameStopwatch.elapsed < _options.frameTime) {
        _metrics.endFrame(skipped: true);
        return;
      }
    }

    // Count new lines
    int newLineCount;
    if (content.isEmpty) {
      newLineCount = 0;
    } else {
      final segments = content.split('\n');
      newLineCount = segments.length - (content.endsWith('\n') ? 1 : 0);
    }

    // Build the entire frame in a single buffer to prevent flashing.
    // Multiple terminal.write() calls allow the terminal to flush between
    // writes, causing visible cursor movement before content appears.
    final frameBuffer = StringBuffer();

    // Hide cursor during render to prevent cursor flicker
    if (terminal.supportsAnsi) {
      frameBuffer.write('\x1b[?25l'); // Hide cursor
    }

    // Move cursor back to start position if we've rendered before
    if (_hasRendered && _lastLineCount > 0 && terminal.supportsAnsi) {
      if (_lastLineCount > 0) {
        frameBuffer.write('\x1b[${_lastLineCount}A'); // Move up N lines
      }
      frameBuffer.write('\r'); // Return to column 1
    }

    // Write content with clear-to-end-of-line after each line
    final output = _options.ansiCompress ? compressAnsi(content) : content;
    _appendContentWithClearToEol(frameBuffer, output);

    // If new content has fewer lines, clear the extra old lines
    if (_hasRendered &&
        newLineCount < _lastLineCount &&
        terminal.supportsAnsi) {
      final extraLines = _lastLineCount - newLineCount;
      for (var i = 0; i < extraLines; i++) {
        frameBuffer.write('\x1b[K'); // Clear line from cursor
        frameBuffer.write('\n'); // Move to next line
      }
      // Move back up to where content ended
      if (extraLines > 0) {
        frameBuffer.write('\x1b[${extraLines}A');
      }
    }

    // Show cursor after render (unless hideCursor option is set)
    if (terminal.supportsAnsi && !_options.hideCursor) {
      frameBuffer.write('\x1b[?25h'); // Show cursor
    }

    // Single atomic write to terminal - prevents flashing
    terminal.write(frameBuffer.toString());

    _lastLineCount = newLineCount;
    // Reset and start the stopwatch for next frame timing
    _frameStopwatch.reset();
    _frameStopwatch.start();
    _hasRendered = true;
    _metrics.endFrame();
  }

  /// Appends content to buffer, clearing to end of line after each line.
  /// This is used for atomic rendering - all content goes into a single buffer
  /// that gets written in one terminal.write() call.
  void _appendContentWithClearToEol(StringBuffer buffer, String content) {
    if (content.isEmpty) return;

    if (!terminal.supportsAnsi) {
      buffer.write(content);
      if (!content.endsWith('\n')) {
        buffer.write('\n');
      }
      return;
    }

    // Split into lines and write each with clear-to-EOL
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;

      buffer.write(line);
      buffer.write('\x1b[K'); // Clear from cursor to end of line

      if (!isLast) {
        buffer.write('\n');
      }
    }

    // Ensure we end with a newline
    if (!content.endsWith('\n')) {
      buffer.write('\n');
    }
  }

  /// Clears the previous output by moving up and clearing lines.
  void _clearPreviousLines(int lines) {
    if (!terminal.supportsAnsi) return;

    final buffer = StringBuffer();
    for (var i = 0; i < lines; i++) {
      buffer.write('\x1b[A'); // Move up
      buffer.write('\x1b[2K'); // Clear line
    }
    buffer.write('\r'); // Return to start of line
    terminal.write(buffer.toString());
  }

  @override
  void clear() {
    if (_hasRendered && _lastLineCount > 0) {
      _clearPreviousLines(_lastLineCount);
    }
    _lastLineCount = 0;
  }

  @override
  void invalidate() {
    _lastLineCount = 0;
  }

  @override
  Future<void> flush() async {
    await terminal.flush();
  }

  @override
  void dispose() {
    // Inline renderer doesn't need cleanup
  }
}

/// A renderer that buffers output for efficient writes.
///
/// Collects all output in a buffer and writes it in a single
/// operation to reduce flickering.
class BufferedTuiRenderer implements TuiRenderer {
  /// Creates a buffered renderer wrapping [inner].
  BufferedTuiRenderer({required this.inner});

  /// The underlying renderer.
  final TuiRenderer inner;

  /// Pending view to render.
  Object? _pendingView;

  /// Whether we have pending output.
  bool _dirty = false;

  @override
  void initialize() {
    inner.initialize();
  }

  @override
  uv_term.RenderMetrics? get metrics => inner.metrics;

  @override
  void render(Object view) {
    _pendingView = view;
    _dirty = true;
  }

  @override
  void clear() {
    _pendingView = null;
    inner.clear();
    _dirty = false;
  }

  @override
  void invalidate() {
    _pendingView = null;
    inner.invalidate();
    _dirty = false;
  }

  @override
  Future<void> flush() async {
    if (_dirty && _pendingView != null) {
      inner.render(_pendingView!);
      _dirty = false;
    }
    await inner.flush();
  }

  @override
  void dispose() {
    inner.dispose();
  }
}

/// Ultraviolet-inspired renderer backed by a cell buffer + diffing updates.
///
/// This renderer keeps `Model.view(): String` as the public API, but internally
/// parses ANSI-styled strings into a cell buffer and diffs frames to emit
/// minimal terminal updates.
///
/// In full-screen mode this writes UV output directly to the terminal. In
/// inline mode it captures UV output first, rewrites absolute row-addressing
/// escape sequences into the configured inline region, and then restores the
/// surrounding CLI cursor position.
///
/// Upstream references:
class UltravioletTuiRenderer
    implements TuiRenderer, NativeFrameInspectableRenderer {
  /// Creates a UV renderer targeting the given [terminal].
  ///
  /// If [movementCapsOverride] is provided, it replaces the auto-detected
  /// terminal movement capabilities (tab stops and backspace support).
  UltravioletTuiRenderer({
    required this.terminal,
    TuiRendererOptions options = const TuiRendererOptions(),
    this.movementCapsOverride,
  }) : _options = options;

  /// The terminal to render to.
  final TuiTerminal terminal;
  final TuiRendererOptions _options;

  /// Optional override for terminal movement capabilities.
  ///
  /// When non-null, bypasses auto-detection of tab-stop and backspace
  /// support, which is useful for testing or non-standard terminals.
  final ({bool useTabs, bool useBackspace})? movementCapsOverride;

  bool _initialized = false;
  bool _dirty = false;
  String _pendingView = '';

  final List<String> _printLines = <String>[];
  static const int _maxPrintLines = 2000;

  uv_buffer.ScreenBuffer? _screen;

  /// The current screen buffer, populated after each render/flush cycle.
  ///
  /// Useful for custom renderers (e.g. web canvas) that need direct access
  /// to the cell buffer without going through ANSI output.
  uv_buffer.ScreenBuffer? get screenBuffer => _screen;

  uv_term.UvTerminalRenderer? _renderer;
  int _nativeFrameRevision = 0;
  int _nativeFrameCacheRevision = -1;
  TerminalNativeFrame? _nativeFrameCache;
  TerminalNativeDeltaFrame? _nativeDeltaCache;
  TerminalNativeCellDeltaFrame? _nativeCellDeltaCache;
  TerminalNativeFrame? _previousNativeFrameForCellDelta;
  bool _captureNativeFrames = false;
  uv_graphics.TerminalGraphicsFrame _lastGraphicsFrame =
      uv_graphics.TerminalGraphicsFrame.empty;

  // Inline mode captures UV output so absolute row-addressing sequences can
  // be rewritten into the anchored region before bytes reach the terminal.
  final StringBuffer _inlineCapture = StringBuffer();
  final StringBuffer _fullscreenCapture = StringBuffer();
  _CapturingSink? _inlineSink;
  bool _inlineNeedsFullClear = false;
  bool _inlineNeedsLogReplay = false;
  int? _inlineTerminalWidth;
  int? _inlineTerminalHeight;
  final List<String> _inlineLogHistory = <String>[];

  /// Stopwatch for frame timing (immune to NTP/DST clock adjustments).
  final Stopwatch _frameStopwatch = Stopwatch();

  /// Returns the render metrics from the underlying UV renderer.
  @override
  uv_term.RenderMetrics? get metrics => _renderer?.metrics;

  /// Appends [text] as persistent log line(s) above the rendered view.
  ///
  /// Lines are stored in a bounded buffer and composited with the view
  /// content on each render.
  void printLine(String text) {
    _initialize();
    if (text.isEmpty) return;

    final lines = text.replaceAll('\r\n', '\n').split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (_options.isInline && _options.uiAnchor == UiAnchor.bottom) {
        _inlineLogHistory.add(line);
        if (_inlineLogHistory.length > _maxPrintLines) {
          _inlineLogHistory.removeAt(0);
        }
        if (TuiTrace.enabled) {
          TuiTrace.event(
            'inline.print_line',
            tag: TraceTag.render,
            fields: <String, Object?>{
              'line': line,
              'historyLength': _inlineLogHistory.length,
              'terminalWidth': terminal.width,
              'terminalHeight': terminal.height,
              'screenHeight': _screen?.height(),
              'needsLogReplay': _inlineNeedsLogReplay,
            },
          );
        }
        _ensureSize();
        if (_replayInlineLogBandIfNeeded()) {
          continue;
        }
        _printInlineLineAboveBottomUi(line);
        continue;
      }
      _printLines.add(line);
      if (_printLines.length > _maxPrintLines) {
        _printLines.removeAt(0);
      }
    }
  }

  String _composeView(String view) {
    if (_options.isInline && _options.uiAnchor == UiAnchor.bottom) {
      return view;
    }
    if (_printLines.isEmpty) return view;
    if (view.isEmpty) return '${_printLines.join('\n')}\n';
    return '${_printLines.join('\n')}\n$view';
  }

  void _printInlineLineAboveBottomUi(String text) {
    final termHeight = terminal.height;
    if (termHeight <= 1) return;

    final scr = _screen;
    final uiHeight =
        scr?.height() ?? _options.inlineHeight.clamp(1, termHeight);
    final logBottom = termHeight - uiHeight;
    if (logBottom <= 0) return;

    final width = _inlineSafeTextColumns;
    final visible = _sanitizeInlineLogLine(text, width);
    if (visible.isEmpty) return;

    final out = StringBuffer()
      ..write(Ansi.cursorSaveDec)
      ..write(UvAnsi.resetModeAutoWrap)
      ..write(Ansi.setScrollRegion(1, logBottom))
      ..write(Ansi.cursorTo(logBottom, 1))
      ..write('\r\n')
      ..write('\r')
      ..write(Ansi.clearLine)
      ..write(visible)
      ..write(Ansi.resetScrollRegion)
      ..write(UvAnsi.setModeAutoWrap)
      ..write(Ansi.cursorRestoreDec);
    final output = out.toString();
    _traceInlineAnsi('inline.ansi.print_line', output);
    terminal.write(output);
  }

  bool _replayInlineLogBandIfNeeded() {
    if (!_options.isInline ||
        _options.uiAnchor != UiAnchor.bottom ||
        !_inlineNeedsLogReplay) {
      return false;
    }

    final termHeight = terminal.height;
    final scr = _screen;
    if (scr == null) return false;
    final logBottom = termHeight - scr.height();
    if (logBottom <= 0) {
      _inlineNeedsLogReplay = false;
      return false;
    }

    if (TuiTrace.enabled) {
      TuiTrace.event(
        'inline.log_replay',
        tag: TraceTag.render,
        fields: <String, Object?>{
          'logBottom': logBottom,
          'historyLength': _inlineLogHistory.length,
          'terminalWidth': terminal.width,
          'terminalHeight': terminal.height,
          'screenHeight': scr.height(),
        },
      );
    }

    final out = StringBuffer()
      ..write(Ansi.beginSynchronizedUpdate)
      ..write(Ansi.cursorSaveDec)
      ..write(UvAnsi.resetModeAutoWrap);
    _appendInlineLogReplay(out, logBottom);
    out
      ..write(UvAnsi.setModeAutoWrap)
      ..write(Ansi.cursorRestoreDec)
      ..write(Ansi.endSynchronizedUpdate);
    final output = out.toString();
    _traceInlineAnsi('inline.ansi.log_replay', output);
    terminal.write(output);
    _inlineNeedsLogReplay = false;
    return true;
  }

  void _traceInlineAnsi(String type, String output) {
    if (!TuiTrace.captureEnabled || output.isEmpty) return;
    TuiTrace.event(
      type,
      tag: TraceTag.flush,
      fields: <String, Object?>{
        'byteLength': utf8.encode(output).length,
        'charLength': output.length,
        'terminalWidth': terminal.width,
        'terminalHeight': terminal.height,
        'base64': base64Encode(utf8.encode(output)),
      },
    );
  }

  int get _inlineSafeTextColumns {
    final width = terminal.width;
    if (width <= 1) return 0;
    return width - 1;
  }

  String _sanitizeInlineLogLine(String text, int maxColumns) {
    if (maxColumns <= 0) return '';
    final out = StringBuffer();
    var used = 0;
    for (final rune in text.runes) {
      if (rune == 0x0A || rune == 0x0D) break;
      if (rune == 0x1B) break;
      final ch = String.fromCharCode(rune);
      if (rune < 0x20 || rune == 0x7F) continue;
      if (used + 1 > maxColumns) break;
      out.write(ch);
      used++;
    }
    return out.toString();
  }

  /// Renders [view] immediately, bypassing frame-rate limiting.
  ///
  /// Use this for urgent updates that must be visible before the next
  /// regular render cycle (e.g. fatal-error screens).
  void renderImmediate(String view) {
    _initialize();
    _pendingView = _composeView(view);
    _dirty = true;
    // Stop the stopwatch to force next render to proceed
    _frameStopwatch.stop();
    _flushInternal();
    unawaited(terminal.flush());
  }

  void _initialize() {
    if (_initialized) return;

    final isInline = _options.isInline;

    if (!isInline && _options.altScreen) {
      terminal.enterAltScreen();
    }
    if (!isInline) {
      terminal.write(uv_graphics.deleteAllRetainedGraphics());
      _lastGraphicsFrame = uv_graphics.TerminalGraphicsFrame.empty;
    }
    if (_options.hideCursor) {
      terminal.hideCursor();
    }
    if (!isInline && _options.altScreen) {
      terminal.clearScreen();
    }

    final (width: w, height: h) = terminal.size;
    _inlineTerminalWidth = isInline ? w : null;
    _inlineTerminalHeight = isInline ? h : null;
    final renderHeight = isInline ? _options.inlineHeight.clamp(1, h) : h;
    _screen = uv_buffer.ScreenBuffer(w, renderHeight);

    final envMap = environment;
    final env = envMap.entries.map((e) => '${e.key}=${e.value}').toList();
    if (terminal.isTerminal && !envMap.containsKey('TTY_FORCE')) {
      env.add('TTY_FORCE=1');
    }
    if (terminal.isTerminal &&
        terminal.supportsAnsi &&
        (envMap['TERM'] == null || (envMap['TERM'] ?? '').isEmpty)) {
      env.add('TERM=xterm-256color');
    }

    // For inline mode, capture UV output into a buffer so we can offset
    // cursor positioning to the UI region.  The UV renderer runs in
    // fullscreen mode (absolute CUP) on the full-size buffer; we
    // post-process the output to shift row coordinates.
    if (isInline) {
      _inlineSink = _CapturingSink(_inlineCapture);
      _renderer = uv_term.UvTerminalRenderer(_inlineSink!, env: env);
      _renderer!.setFullscreen(true);
      _renderer!.setRelativeCursor(false);
      _renderer!.setMapNewline(false);
      _renderer!.setScrollOptim(false);
    } else {
      final sink = _CapturingSink(_fullscreenCapture);
      _renderer = uv_term.UvTerminalRenderer(sink, env: env);
      _renderer!.setFullscreen(true);
      _renderer!.setRelativeCursor(false);
      final mapNewline = !isWindows && terminal.isTerminal;
      _renderer!.setMapNewline(mapNewline);
      // Resizes invalidate row geometry. Scroll optimization can otherwise
      // emit DL/IL operations derived from the old width while the new frame
      // is being painted. Ratatui uses a plain cell diff for this path.
      _renderer!.setScrollOptim(false);
    }

    // Apply terminal movement optimizations. Allow a compatibility override so
    // callers can provide capability bits without probing the terminal.
    final caps = movementCapsOverride ?? terminal.optimizeMovements();
    _renderer!.setHasTab(caps.useTabs);
    _renderer!.setBackspace(caps.useBackspace);
    if (caps.useTabs) {
      _renderer!.setTabStops(w);
    }

    if (!isInline) {
      _renderer!.saveCursor();
      _renderer!.erase();
    } else {
      if (_options.uiAnchor == UiAnchor.bottom && terminal.isTerminal) {
        terminal.write(List.filled(renderHeight, '\r\n').join());
      }
      _inlineNeedsFullClear = true;
    }

    _initialized = true;
  }

  @override
  void initialize() => _initialize();

  void _ensureSize() {
    final (width: w, height: h) = terminal.size;
    final scr = _screen;
    if (scr == null) return;
    final targetHeight = _options.isInline
        ? _options.inlineHeight.clamp(1, h)
        : h;
    final inlineTerminalSizeChanged =
        _options.isInline &&
        (_inlineTerminalWidth != w || _inlineTerminalHeight != h);
    if (inlineTerminalSizeChanged && TuiTrace.enabled) {
      TuiTrace.event(
        'inline.terminal_size_changed',
        tag: TraceTag.render,
        fields: <String, Object?>{
          'previousWidth': _inlineTerminalWidth,
          'previousHeight': _inlineTerminalHeight,
          'width': w,
          'height': h,
          'screenWidth': scr.width(),
          'screenHeight': scr.height(),
          'targetHeight': targetHeight,
        },
      );
    }
    if (scr.width() == w &&
        scr.height() == targetHeight &&
        !inlineTerminalSizeChanged) {
      return;
    }
    final sizeChanged = scr.width() != w || scr.height() != targetHeight;
    final isShrinking = w < scr.width() || targetHeight < scr.height();
    if (sizeChanged) {
      scr.resize(w, targetHeight);
      _renderer?.resize(w, targetHeight);
      if (!_options.isInline) {
        // Ratatui resizes both screen buffers and resets the previous buffer
        // before the callback paints. Do the same at the UV boundary so the
        // diff never compares a new-width frame with old-width geometry.
        _renderer?.resetForResize(w, targetHeight);
      }
      _invalidateNativeFrameCache(resetPrevious: true);
      // Match Ratatui's resize contract: discard the previous diff state and
      // render a complete frame at the latest backend size. Horizontal shrink
      // is especially important because wrapping can leave old cells visible.
      if (isShrinking) {
        scr.clear();
      }
    }
    if (!_options.isInline) {
      // A normal resize was reset above; the initial frame is erased during
      // initialization. No second erase is needed here.
    } else {
      _renderer?.erase();
      // Discard the ESC[H ESC[2J that erase() queues into _inlineCapture.
      // In inline mode we own all screen clearing ourselves: the log band via
      // _appendInlineLogReplay and the UI rows via clearInlineRegion.  Leaving
      // stale erase output in the capture buffer would cause it to mix into the
      // next r.flush() call and destroy log history.
      _inlineCapture.clear();
      _inlineNeedsFullClear = true;
      _inlineNeedsLogReplay = _options.uiAnchor == UiAnchor.bottom;
      _inlineTerminalWidth = w;
      _inlineTerminalHeight = h;
    }
  }

  @override
  void render(Object view) {
    _initialize();

    final String content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };
    final (width: terminalWidth, height: terminalHeight) = terminal.size;
    final targetHeight = _options.isInline
        ? _options.inlineHeight.clamp(1, terminalHeight)
        : terminalHeight;
    final sizeChanged =
        _screen == null ||
        _screen!.width() != terminalWidth ||
        _screen!.height() != targetHeight ||
        (_options.isInline &&
            (_inlineTerminalWidth != terminalWidth ||
                _inlineTerminalHeight != terminalHeight));

    // Frame rate limiting using Stopwatch (immune to clock adjustments)
    if (_frameStopwatch.isRunning) {
      // Only skip if the view hasn't changed; otherwise we must render or the
      // terminal can get stuck with stale overlay content.
      if (_frameStopwatch.elapsed < _options.frameTime &&
          content == _pendingView &&
          !sizeChanged) {
        return;
      }
    }

    _pendingView = _composeView(content);
    _dirty = true;
    // Reset and start the stopwatch for next frame timing
    _frameStopwatch.reset();
    _frameStopwatch.start();

    // Unlike the other renderers, the UV renderer buffers terminal output in
    // its own writer and needs a flush step to emit bytes. Do it immediately
    // so Program doesn't need to coordinate flush ordering with control writes.
    //
    // Also schedule a terminal flush: Program doesn't call TuiRenderer.flush()
    // today, and some terminals won't paint until the underlying sink is
    // flushed.
    _flushInternal();
    unawaited(terminal.flush());
  }

  @override
  void clear() {
    _initialize();
    if (!_options.isInline) {
      terminal.write(uv_graphics.deleteAllRetainedGraphics());
    }
    _lastGraphicsFrame = uv_graphics.TerminalGraphicsFrame.empty;
    _renderer?.erase();
    // Discard any ESC[2J queued by erase() into the inline capture buffer.
    if (_options.isInline) _inlineCapture.clear();
    _dirty = true;
    _invalidateNativeFrameCache(resetPrevious: true);
    // Stop the stopwatch to force next render to proceed
    _frameStopwatch.stop();
    _pendingView = '';
    unawaited(terminal.flush());
  }

  @override
  void invalidate() {
    _initialize();
    _renderer?.erase();
    // Discard any ESC[2J queued by erase() into the inline capture buffer.
    if (_options.isInline) _inlineCapture.clear();
    _dirty = true;
    _invalidateNativeFrameCache(resetPrevious: true);
    // Stop the stopwatch to force next render to proceed past frame-rate
    // limiting, but do NOT flush the terminal — the caller will trigger a
    // render through the normal message-queue pipeline.
    _frameStopwatch.stop();
    _pendingView = '';
  }

  @override
  Future<void> flush() async {
    if (!_initialized) return;
    _flushInternal();
    await terminal.flush();
  }

  @override
  void setNativeFrameCaptureEnabled(bool enabled) {
    if (_captureNativeFrames == enabled) return;
    _captureNativeFrames = enabled;
    if (enabled) {
      _frameStopwatch.stop();
    }
    if (!enabled) {
      _invalidateNativeFrameCache(resetPrevious: true);
    }
  }

  @override
  TerminalNativeFrame? captureNativeFrame() {
    return _captureNativeFrame();
  }

  @override
  TerminalNativeDeltaFrame? captureNativeDelta() {
    final frame = _captureNativeFrame();
    if (frame == null) return null;
    return _nativeDeltaCache ??= TerminalNativeDeltaFrame.fromFrame(frame);
  }

  @override
  TerminalNativeCellDeltaFrame? captureNativeCellDelta() {
    final frame = _captureNativeFrame();
    if (frame == null) return null;
    final cached = _nativeCellDeltaCache;
    if (cached != null) return cached;
    final delta = TerminalNativeCellDeltaFrame.between(
      _previousNativeFrameForCellDelta,
      frame,
    );
    _previousNativeFrameForCellDelta = frame;
    return _nativeCellDeltaCache = delta;
  }

  TerminalNativeFrame? _captureNativeFrame() {
    final screen = _screen;
    if (screen == null) return null;
    if (_nativeFrameCacheRevision == _nativeFrameRevision) {
      return _nativeFrameCache;
    }
    _nativeFrameCache = TerminalNativeFrame.fromScreenBuffer(screen);
    _nativeDeltaCache = null;
    _nativeCellDeltaCache = null;
    _nativeFrameCacheRevision = _nativeFrameRevision;
    return _nativeFrameCache;
  }

  void _invalidateNativeFrameCache({bool resetPrevious = false}) {
    _nativeFrameRevision += 1;
    _nativeFrameCacheRevision = -1;
    _nativeFrameCache = null;
    _nativeDeltaCache = null;
    _nativeCellDeltaCache = null;
    if (resetPrevious) {
      _previousNativeFrameForCellDelta = null;
    }
  }

  void _captureCurrentNativeFrame(uv_buffer.ScreenBuffer screen) {
    final frame = TerminalNativeFrame.fromScreenBuffer(screen);
    _nativeFrameRevision += 1;
    _nativeFrameCacheRevision = _nativeFrameRevision;
    _nativeFrameCache = frame;
    _nativeDeltaCache = TerminalNativeDeltaFrame.fromFrame(frame);
    _nativeCellDeltaCache = TerminalNativeCellDeltaFrame.between(
      _previousNativeFrameForCellDelta,
      frame,
    );
    _previousNativeFrameForCellDelta = frame;
  }

  void _flushInternal() {
    if (!_initialized) return;
    if (!_dirty) return;

    final tracing = TuiTrace.enabled;
    final TraceSpan? flushSpan = tracing
        ? TuiTrace.begin('uv_flush', tag: TraceTag.render)
        : null;

    _ensureSize();
    final scr = _screen;
    final r = _renderer;
    if (scr == null || r == null) {
      flushSpan?.end();
      return;
    }

    final isInline = _options.isInline;
    final graphicsFrame = uv_graphics.TerminalGraphicsFrame.scan(_pendingView);
    final forceInlineFullRedraw = isInline && _inlineNeedsFullClear;

    // Phase 1: ANSI parse → StyledString
    final Stopwatch? parseSw = tracing ? (Stopwatch()..start()) : null;
    final ss = uv_styled.newStyledString(
      _options.ansiCompress ? compressAnsi(_pendingView) : _pendingView,
    )..wrap = !isInline;
    parseSw?.stop();

    // Phase 2: Draw styled string into screen buffer
    final Stopwatch? drawSw = tracing ? (Stopwatch()..start()) : null;
    if (forceInlineFullRedraw) {
      scr.clear();
    }
    ss.draw(scr, scr.bounds());
    drawSw?.stop();
    if (_captureNativeFrames) {
      _captureCurrentNativeFrame(scr);
    } else {
      _invalidateNativeFrameCache(resetPrevious: true);
    }

    // Phase 3: Diff buffers and compute update sequence
    final Stopwatch? diffSw = tracing ? (Stopwatch()..start()) : null;
    if (isInline) {
      // Inline mode restores the real terminal cursor after every frame, so
      // the UV renderer must not rely on its previous cursor position when
      // generating incremental updates.
      r.setPosition(-1, -1);
    }
    r.render(scr.buffer);
    diffSw?.stop();

    // Phase 4: Flush to terminal
    final Stopwatch? writeSw = tracing ? (Stopwatch()..start()) : null;
    if (isInline) {
      _flushInline();
    } else {
      // Wrap the flush in Synchronized Update markers (DEC mode 2026) so the
      // terminal buffers all changes and paints them atomically.  This prevents
      // visible flashes when scroll optimization emits DL/IL before the
      // replacement content arrives.  Terminals that don't support mode 2026
      // silently ignore these sequences.
      _fullscreenCapture.clear();
      final frame = StringBuffer()..write(UvAnsi.beginSynchronizedUpdate);
      for (final sequence in graphicsFrame.deletionSequencesSince(
        _lastGraphicsFrame,
      )) {
        frame.write(sequence);
      }
      r.flush();
      if (TuiTrace.enabled) {
        final output = r.lastFlushedOutput;
        TuiTrace.event(
          'uv.fullscreen.flush',
          tag: TraceTag.flush,
          fields: {
            'width': terminal.width,
            'height': terminal.height,
            'bytes': output.length,
            'containsEraseScreen': output.contains('\x1b[2J'),
            'containsEraseLine': output.contains('\x1b[2K'),
            'containsCursorHome': output.contains('\x1b[H'),
            'containsSyncBegin': output.contains('\x1b[?2026h'),
            'containsSyncEnd': output.contains('\x1b[?2026l'),
          },
        );
      }
      frame
        ..write(_fullscreenCapture)
        ..write(UvAnsi.endSynchronizedUpdate);
      terminal.write(frame.toString());
    }
    writeSw?.stop();
    _dirty = false;
    _lastGraphicsFrame = graphicsFrame;

    if (tracing) {
      TuiTrace.log(
        'uv_flush parse=${parseSw!.elapsedMicroseconds}us '
        'draw=${drawSw!.elapsedMicroseconds}us '
        'diff=${diffSw!.elapsedMicroseconds}us '
        'write=${writeSw!.elapsedMicroseconds}us',
        tag: TraceTag.render,
      );
      flushSpan?.end();
    }
  }

  /// Flushes the current frame in inline mode.
  ///
  /// Inline mode preserves scrollback and renders the UI within a bounded
  /// region at the top or bottom of the viewport.
  ///
  /// The UV renderer runs in fullscreen mode on the full terminal buffer,
  /// generating absolute CUP sequences.  We capture that output and offset
  /// all row coordinates so they land inside the UI region.
  void _flushInline() {
    final r = _renderer;
    final sink = _inlineSink;
    if (r == null || sink == null) return;

    final termHeight = terminal.height;
    final scr = _screen;
    if (scr == null) return;
    final uiHeight = scr.height();
    final uiStartRow = _options.uiAnchor == UiAnchor.bottom
        ? termHeight - uiHeight + 1
        : 1;
    final logBottom = uiStartRow - 1;

    // Clear the capturing buffer and let the UV renderer write into it.
    _inlineCapture.clear();
    r.flush();
    var raw = _inlineCapture.toString();

    // The UV renderer emits ESC[<n>J (Erase Display) sequences as part of its
    // full-screen erase after a resize or explicit erase() call.  In inline
    // mode these are never correct: we own all clearing ourselves — the log
    // band via _appendInlineLogReplay and the UI rows via clearInlineRegion.
    // ESC[2J erases the entire screen and destroys the log history we just
    // replayed, so strip every ED sequence from the captured output.
    if (raw.contains('\x1b[')) {
      raw = raw.replaceAll(RegExp(r'\x1b\[\d*J'), '');
    }

    // Shift all absolute row-addressing sequences into the anchored inline
    // region before replaying UV's diff output onto the real terminal.
    final offset = uiStartRow - 1;
    final shifted = offset > 0 ? _offsetInlineRows(raw, offset) : raw;

    final shouldClearInlineRegion = _inlineNeedsFullClear;
    final shouldReplayLogBand =
        _inlineNeedsLogReplay && _options.uiAnchor == UiAnchor.bottom;
    if (TuiTrace.enabled) {
      TuiTrace.event(
        'inline.flush',
        tag: TraceTag.flush,
        fields: <String, Object?>{
          'terminalWidth': terminal.width,
          'terminalHeight': termHeight,
          'uiHeight': uiHeight,
          'uiStartRow': uiStartRow,
          'logBottom': logBottom,
          'rawLength': raw.length,
          'shiftedLength': shifted.length,
          'clearInlineRegion': shouldClearInlineRegion,
          'replayLogBand': shouldReplayLogBand,
        },
      );
    }

    // Build the output.
    final out = StringBuffer();
    out.write(Ansi.beginSynchronizedUpdate);
    out.write(Ansi.cursorSaveDec);
    out.write(UvAnsi.resetModeAutoWrap);

    if (shouldReplayLogBand) {
      _appendInlineLogReplay(out, logBottom);
      _inlineNeedsLogReplay = false;
    }

    // Clear the entire inline region only on first paint or after resize.
    if (shouldClearInlineRegion) {
      for (var row = 0; row < uiHeight; row++) {
        final absRow = uiStartRow + row;
        out.write(Ansi.cursorTo(absRow, 1));
        out.write(Ansi.clearLine);
      }
      _inlineNeedsFullClear = false;
    }

    // Write the offset UV output.
    out.write(shifted);
    out.write(UvAnsi.setModeAutoWrap);
    out.write(Ansi.cursorRestoreDec);

    if (!_options.hideCursor) {
      out.write(Ansi.cursorShow);
    }
    out.write(Ansi.endSynchronizedUpdate);

    if (raw.isNotEmpty || shouldClearInlineRegion || shouldReplayLogBand) {
      final output = out.toString();
      _traceInlineAnsi('inline.ansi.flush', output);
      terminal.write(output);
    }
  }

  void _appendInlineLogReplay(StringBuffer out, int logBottom) {
    if (logBottom <= 0) return;
    for (var row = 1; row <= logBottom; row++) {
      out
        ..write(Ansi.cursorTo(row, 1))
        ..write(Ansi.clearLine);
    }
    if (_inlineLogHistory.isEmpty) return;

    final width = _inlineSafeTextColumns;
    final count = _inlineLogHistory.length < logBottom
        ? _inlineLogHistory.length
        : logBottom;
    final start = _inlineLogHistory.length - count;
    final firstRow = logBottom - count + 1;
    for (var i = 0; i < count; i++) {
      final visible = _sanitizeInlineLogLine(
        _inlineLogHistory[start + i],
        width,
      );
      if (visible.isEmpty) continue;
      out
        ..write(Ansi.cursorTo(firstRow + i, 1))
        ..write(visible);
    }
  }

  /// Offsets all absolute row-addressing escape sequences by [rowOffset].
  ///
  /// Handles:
  /// - `CUP` / `HVP`: `ESC[<row>;<col>H` and `ESC[<row>;<col>f`
  /// - home shortcuts: `ESC[H` / `ESC[f`
  /// - `VPA`: `ESC[<row>d`
  static String _offsetInlineRows(String input, int rowOffset) {
    if (input.isEmpty || rowOffset <= 0) return input;

    final cupOrHvpRe = RegExp(r'\x1b\[(?:(\d+)(?:;(\d+))?)?([Hf])');
    final vpaRe = RegExp(r'\x1b\[(\d+)d');

    var result = input;
    result = result.replaceAllMapped(cupOrHvpRe, (m) {
      final rowStr = m.group(1);
      final colStr = m.group(2);
      final finalByte = m.group(3)!;
      final row = (rowStr == null ? 1 : int.parse(rowStr)) + rowOffset;
      final col = colStr == null ? 1 : int.parse(colStr);
      return '\x1b[$row;$col$finalByte';
    });
    result = result.replaceAllMapped(vpaRe, (m) {
      final row = int.parse(m.group(1)!) + rowOffset;
      return '\x1b[${row}d';
    });

    return result;
  }

  @override
  void dispose() {
    if (!_initialized) return;

    final isInline = _options.isInline;

    if (!isInline) {
      terminal.write(uv_graphics.deleteAllRetainedGraphics());
      _lastGraphicsFrame = uv_graphics.TerminalGraphicsFrame.empty;
    } else {
      terminal.write(Ansi.resetScrollRegion);
      if (_options.uiAnchor == UiAnchor.bottom && terminal.supportsAnsi) {
        _clearInlineRegion();
        terminal.write(Ansi.cursorTo(terminal.height, 1));
      }
    }
    if (_options.hideCursor) {
      terminal.showCursor();
    }
    if (!isInline && _options.altScreen) {
      terminal.exitAltScreen();
    }
    _initialized = false;
  }

  void _clearInlineRegion() {
    final scr = _screen;
    if (scr == null) return;
    final termHeight = terminal.height;
    final uiHeight = scr.height().clamp(1, termHeight).toInt();
    final uiStartRow = _options.uiAnchor == UiAnchor.bottom
        ? termHeight - uiHeight + 1
        : 1;
    final out = StringBuffer()..write(Ansi.cursorSaveDec);
    for (var row = 0; row < uiHeight; row++) {
      out
        ..write(Ansi.cursorTo(uiStartRow + row, 1))
        ..write(Ansi.clearLine);
    }
    out
      ..write(Ansi.cursorTo(termHeight, 1))
      ..write(Ansi.clearLine)
      ..write(Ansi.cursorRestoreDec);
    terminal.write(out.toString());
  }
}

final class _TerminalStringSink implements StringSink {
  _TerminalStringSink(this.terminal);

  final TuiTerminal terminal;

  @override
  void write(Object? obj) => terminal.write(obj?.toString() ?? '');

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      write(objects.join(separator));

  @override
  void writeCharCode(int charCode) =>
      terminal.write(String.fromCharCode(charCode));

  @override
  void writeln([Object? obj = '']) => terminal.writeln(obj?.toString() ?? '');
}

/// A [StringSink] that captures all writes into a [StringBuffer].
///
/// Used by the inline-mode UV renderer so its output can be post-processed
/// (cursor-position offset) before being written to the real terminal.
final class _CapturingSink implements StringSink {
  _CapturingSink(this._target);

  final StringBuffer _target;

  @override
  void write(Object? obj) => _target.write(obj?.toString() ?? '');

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _target.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _target.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) => _target.writeln(obj?.toString() ?? '');
}

/// A renderer that does nothing (for testing).
class NullTuiRenderer implements TuiRenderer {
  /// The last view that was rendered.
  Object? lastView;

  /// All views that have been rendered.
  final List<Object> views = [];

  @override
  void initialize() {}

  @override
  uv_term.RenderMetrics? get metrics => null;

  @override
  void render(Object view) {
    lastView = view;
    views.add(view);
  }

  @override
  void clear() {
    lastView = null;
  }

  @override
  void invalidate() {
    lastView = null;
  }

  @override
  Future<void> flush() async {}

  @override
  void dispose() {}
}

/// TuiRenderer that writes output without diffing or clearing (nil renderer mode).
class SimpleTuiRenderer implements TuiRenderer {
  /// Creates a simple renderer targeting the given [terminal].
  SimpleTuiRenderer({
    required this.terminal,
    TuiRendererOptions options = const TuiRendererOptions(),
  }) : _options = options;

  /// The terminal to render to.
  final TuiTerminal terminal;
  final TuiRendererOptions _options;

  @override
  void initialize() {}

  @override
  uv_term.RenderMetrics? get metrics => null;

  @override
  void render(Object view) {
    final String content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };
    final output = _options.ansiCompress ? compressAnsi(content) : content;
    terminal.writeln(output);
  }

  @override
  void clear() {}

  @override
  void invalidate() {}

  @override
  Future<void> flush() async {
    await terminal.flush();
  }

  @override
  void dispose() {}
}

/// Removes redundant SGR sequences to reduce output size.
///
/// This intentionally removes *repeated* SGR sequences even when separated by
/// text (e.g. "\x1b[31mred\x1b[31mred" -> "\x1b[31mredred").
String compressAnsi(String input) {
  final sgr = RegExp(r'\x1B\[[0-9;:]*m');
  final out = StringBuffer();
  var lastEnd = 0;
  String? lastSgr;

  for (final m in sgr.allMatches(input)) {
    out.write(input.substring(lastEnd, m.start));
    final seq = m.group(0)!;

    // Normalize the empty-param reset to a stable form.
    final normalized = seq == '\x1B[m' ? '\x1B[0m' : seq;

    if (normalized != lastSgr) {
      out.write(seq);
      lastSgr = normalized;
    }

    lastEnd = m.end;
  }

  out.write(input.substring(lastEnd));
  return out.toString();
}

/// A renderer that writes to a StringSink (for testing).
class StringSinkTuiRenderer implements TuiRenderer {
  /// Creates a renderer that writes all output to [sink].
  StringSinkTuiRenderer(this.sink);

  /// The sink to write to.
  final StringSink sink;

  @override
  void initialize() {}

  @override
  uv_term.RenderMetrics? get metrics => null;

  @override
  void render(Object view) {
    final String content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };
    sink.write(content);
  }

  @override
  void clear() {
    // Can't clear a StringSink
  }

  @override
  void invalidate() {
    // No diff state to reset for a StringSink
  }

  @override
  Future<void> flush() async {}

  @override
  void dispose() {}
}

/// Extension to create renderers from terminals.
extension TuiTerminalRendererExtension on TuiTerminal {
  /// Creates a fullscreen renderer for this terminal.
  FullScreenTuiRenderer fullScreenRenderer({
    TuiRendererOptions options = const TuiRendererOptions(),
  }) {
    return FullScreenTuiRenderer(terminal: this, options: options);
  }

  /// Creates an inline renderer for this terminal.
  InlineTuiRenderer inlineRenderer({
    TuiRendererOptions options = const TuiRendererOptions(
      altScreen: false,
      hideCursor: false,
    ),
  }) {
    return InlineTuiRenderer(terminal: this, options: options);
  }

  /// Creates a simple renderer for this terminal.
  SimpleTuiRenderer simpleRenderer({
    TuiRendererOptions options = const TuiRendererOptions(),
  }) {
    return SimpleTuiRenderer(terminal: this, options: options);
  }

  /// Creates an Ultraviolet-backed renderer for this terminal.
  UltravioletTuiRenderer ultravioletRenderer({
    TuiRendererOptions options = const TuiRendererOptions(),
  }) {
    return UltravioletTuiRenderer(terminal: this, options: options);
  }
}
