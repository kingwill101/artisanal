import 'dart:async' show unawaited;
import 'dart:io' as io;

import 'terminal.dart';
import 'trace.dart';
import 'view.dart';
import '../uv/ansi.dart' show UvAnsi;
import '../uv/buffer.dart' as uv_buffer;
import '../uv/styled_string.dart' as uv_styled;
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
  /// Renders the view to the terminal.
  ///
  /// [view] is the string representation of the current UI state,
  /// or a [View] object containing metadata.
  void render(Object view);

  /// Clears the rendered content.
  void clear();

  /// Flushes any buffered output.
  Future<void> flush();

  /// Disposes of renderer resources.
  void dispose();

  /// Returns render performance metrics, or null if not supported.
  uv_term.RenderMetrics? get metrics;
}

/// Options for configuring the renderer.
class TuiRendererOptions {
  /// Creates renderer options.
  ///
  /// All parameters have sensible defaults for fullscreen rendering.
  const TuiRendererOptions({
    this.fps = 60,
    this.altScreen = true,
    this.hideCursor = true,
    this.ansiCompress = false,
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

    // Full redraw (future: diff with _lastView and update only changed lines)
    terminal.cursorHome();
    final output = _options.ansiCompress ? compressAnsi(content) : content;
    final mapped = _options.altScreen ? _mapNewlines(output) : output;
    terminal.write(mapped);

    // Clear any remaining content from previous render
    _clearToEndOfScreen(content);

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

  @override
  void clear() {
    terminal.clearScreen();
    _lastView = null;
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
/// Upstream references:
/// - `third_party/ultraviolet/styled.go` (`StyledString.Draw`)
/// - `third_party/ultraviolet/terminal_renderer.go` (`UvTerminalRenderer.Render`)
class UltravioletTuiRenderer implements TuiRenderer {
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
  uv_term.UvTerminalRenderer? _renderer;

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
      _printLines.add(line);
      if (_printLines.length > _maxPrintLines) {
        _printLines.removeAt(0);
      }
    }
  }

  String _composeView(String view) {
    if (_printLines.isEmpty) return view;
    if (view.isEmpty) return '${_printLines.join('\n')}\n';
    return '${_printLines.join('\n')}\n$view';
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

    if (_options.altScreen) {
      terminal.enterAltScreen();
    }
    if (_options.hideCursor) {
      terminal.hideCursor();
    }
    if (_options.altScreen) {
      terminal.clearScreen();
    }

    final (width: w, height: h) = terminal.size;
    _screen = uv_buffer.ScreenBuffer(w, h);

    final sink = _TerminalStringSink(terminal);
    final envMap = io.Platform.environment;
    final env = envMap.entries.map((e) => '${e.key}=${e.value}').toList();
    // The UV-style renderer needs to know whether output is a TTY so it can
    // pick the correct color profile and enable terminal optimizations.
    //
    // Upstream: `third_party/ultraviolet/terminal_renderer.go` uses a real
    // terminal writer; our `StringSink` abstraction requires an explicit hint.
    if (terminal.isTerminal && !envMap.containsKey('TTY_FORCE')) {
      env.add('TTY_FORCE=1');
    }
    if (terminal.isTerminal &&
        terminal.supportsAnsi &&
        (envMap['TERM'] == null || (envMap['TERM'] ?? '').isEmpty)) {
      env.add('TERM=xterm-256color');
    }
    _renderer = uv_term.UvTerminalRenderer(sink, env: env);
    _renderer!.setFullscreen(_options.altScreen);
    _renderer!.setRelativeCursor(!_options.altScreen);
    final mapNewline =
        !io.Platform.isWindows && (terminal.isTerminal || _options.altScreen);
    _renderer!.setMapNewline(mapNewline);
    _renderer!.setScrollOptim(_options.altScreen);

    // Apply terminal movement optimizations. Allow a compatibility override so
    // callers can provide capability bits without probing the terminal.
    final caps = movementCapsOverride ?? terminal.optimizeMovements();
    _renderer!.setHasTab(caps.useTabs);
    _renderer!.setBackspace(caps.useBackspace);
    if (caps.useTabs) {
      _renderer!.setTabStops(w);
    }

    if (_options.altScreen) {
      _renderer!.saveCursor();
      _renderer!.erase();
    }

    _initialized = true;
  }

  void _ensureSize() {
    final (width: w, height: h) = terminal.size;
    final scr = _screen;
    if (scr == null) return;
    if (scr.width() == w && scr.height() == h) return;
    scr.resize(w, h);
    _renderer?.resize(w, h);
    _renderer?.erase();
  }

  @override
  void render(Object view) {
    _initialize();

    final String content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };

    // Frame rate limiting using Stopwatch (immune to clock adjustments)
    if (_frameStopwatch.isRunning) {
      // Only skip if the view hasn't changed; otherwise we must render or the
      // terminal can get stuck with stale overlay content.
      if (_frameStopwatch.elapsed < _options.frameTime &&
          content == _pendingView) {
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
    _renderer?.erase();
    _dirty = true;
    // Stop the stopwatch to force next render to proceed
    _frameStopwatch.stop();
    _pendingView = '';
    unawaited(terminal.flush());
  }

  @override
  Future<void> flush() async {
    if (!_initialized) return;
    _flushInternal();
    await terminal.flush();
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

    // Phase 1: ANSI parse → StyledString
    final Stopwatch? parseSw = tracing ? (Stopwatch()..start()) : null;
    final ss = uv_styled.newStyledString(
      _options.ansiCompress ? compressAnsi(_pendingView) : _pendingView,
    )..wrap = true;
    parseSw?.stop();

    // Phase 2: Draw styled string into screen buffer
    final Stopwatch? drawSw = tracing ? (Stopwatch()..start()) : null;
    ss.draw(scr, scr.bounds());
    drawSw?.stop();

    // Phase 3: Diff buffers and compute update sequence
    final Stopwatch? diffSw = tracing ? (Stopwatch()..start()) : null;
    r.render(scr.buffer);
    diffSw?.stop();

    // Phase 4: Flush to terminal
    final Stopwatch? writeSw = tracing ? (Stopwatch()..start()) : null;
    // Wrap the flush in Synchronized Update markers (DEC mode 2026) so the
    // terminal buffers all changes and paints them atomically.  This prevents
    // visible flashes when scroll optimization emits DL/IL before the
    // replacement content arrives.  Terminals that don't support mode 2026
    // silently ignore the sequences.
    terminal.write(UvAnsi.beginSynchronizedUpdate);
    r.flush();
    terminal.write(UvAnsi.endSynchronizedUpdate);
    writeSw?.stop();
    _dirty = false;

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

/// A renderer that does nothing (for testing).
class NullTuiRenderer implements TuiRenderer {
  /// The last view that was rendered.
  Object? lastView;

  /// All views that have been rendered.
  final List<Object> views = [];

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
