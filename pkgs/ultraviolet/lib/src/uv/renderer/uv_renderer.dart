import 'dart:convert' show jsonEncode;
import 'dart:typed_data' show Int32List;

import '../ansi.dart';
import '../buffer.dart';
import '../cell.dart';
import '../color_utils.dart' as color_utils;
import '../drawable.dart';
import '../environ.dart';
import '../geometry.dart';
import '../screen.dart';
import '../style_ops.dart' as style_ops;
import '../tabstop.dart';
import '../terminal_graphics.dart' as terminal_graphics;
import '../../unicode/width.dart';

import '../../colorprofile/detect.dart' as cp_detect;
import '../../colorprofile/profile.dart' as cp;

import 'renderer.dart';

/// Tracks render performance metrics including FPS, frame times, and render durations.
///
/// This class maintains a rolling window of frame samples to calculate
/// accurate averages and detect performance issues.
final class RenderMetrics {
  /// Creates a new [RenderMetrics] instance.
  ///
  /// [sampleSize] determines how many frames are kept for averaging (default: 60).
  RenderMetrics({int sampleSize = 60}) : _sampleSize = sampleSize {
    _frameTimes = List<Duration>.filled(sampleSize, Duration.zero);
    _renderTimes = List<Duration>.filled(sampleSize, Duration.zero);
    _clock.start();
  }

  final int _sampleSize;

  // Circular buffers for frame/render timing — O(1) insert, no allocations.
  late final List<Duration> _frameTimes;
  late final List<Duration> _renderTimes;
  int _frameTimeCount = 0; // total items written to _frameTimes
  int _renderTimeCount = 0; // total items written to _renderTimes
  int _frameTimeIndex = 0; // next write position in _frameTimes
  int _renderTimeIndex = 0; // next write position in _renderTimes

  // Monotonic clock — immune to wall-clock adjustments / NTP jumps.
  final Stopwatch _clock = Stopwatch();
  Duration? _lastFrameElapsed;

  int _frameCount = 0;
  int _skippedFrames = 0;

  // Render timing (how long render() takes)
  Stopwatch? _renderStopwatch;
  Duration _lastRenderDuration = Duration.zero;

  /// When true, the next [beginFrame]/[endFrame] cycle is treated as a
  /// bookkeeping render (e.g. triggered by the metrics timer) and will **not**
  /// record inter-frame timing or increment the frame count.  The flag is
  /// automatically reset at the end of [endFrame].
  bool metricsOnlyFrame = false;

  /// Duration after the last real frame beyond which FPS is reported as 0.
  static const _idleTimeout = Duration(seconds: 2);

  /// Whether there has been any real (non-metrics-only) rendering activity
  /// within the idle timeout window.
  bool get _isIdle {
    if (_lastFrameElapsed == null) return true;
    return (_clock.elapsed - _lastFrameElapsed!) > _idleTimeout;
  }

  /// Total number of frames rendered since creation or last reset.
  int get frameCount => _frameCount;

  /// Number of frames that were skipped (no changes to render).
  int get skippedFrames => _skippedFrames;

  /// Duration of the last frame (time between renders).
  Duration get lastFrameTime {
    if (_frameTimeCount == 0) return Duration.zero;
    // Last written entry is at (_frameTimeIndex - 1) wrapped.
    final idx = (_frameTimeIndex - 1 + _sampleSize) % _sampleSize;
    return _frameTimes[idx];
  }

  /// Number of valid entries in the frame-time circular buffer.
  int get _frameTimeLength =>
      _frameTimeCount < _sampleSize ? _frameTimeCount : _sampleSize;

  /// Number of valid entries in the render-time circular buffer.
  int get _renderTimeLength =>
      _renderTimeCount < _sampleSize ? _renderTimeCount : _sampleSize;

  /// Duration of the last render() call.
  Duration get lastRenderDuration => _lastRenderDuration;

  /// Average frame time over the sample window.
  Duration get averageFrameTime {
    final n = _frameTimeLength;
    if (n == 0) return Duration.zero;
    int total = 0;
    for (int i = 0; i < n; i++) {
      total += _frameTimes[i].inMicroseconds;
    }
    return Duration(microseconds: total ~/ n);
  }

  /// Average render duration over the sample window.
  Duration get averageRenderDuration {
    final n = _renderTimeLength;
    if (n == 0) return Duration.zero;
    int total = 0;
    for (int i = 0; i < n; i++) {
      total += _renderTimes[i].inMicroseconds;
    }
    return Duration(microseconds: total ~/ n);
  }

  /// Current FPS based on the last frame time.
  /// Returns 0.0 when the application is idle (no real frames within the
  /// timeout window).
  double get currentFps {
    if (_isIdle) return 0.0;
    final ft = lastFrameTime;
    if (ft.inMicroseconds == 0) return 0.0;
    return 1000000.0 / ft.inMicroseconds;
  }

  /// Average FPS over the sample window.
  /// Returns 0.0 when the application is idle (no real frames within the
  /// timeout window).
  double get averageFps {
    if (_isIdle) return 0.0;
    final avg = averageFrameTime;
    if (avg.inMicroseconds == 0) return 0.0;
    return 1000000.0 / avg.inMicroseconds;
  }

  /// Minimum FPS in the sample window (slowest frame).
  double get minFps {
    final n = _frameTimeLength;
    if (n == 0) return 0.0;
    int maxUs = 0;
    for (int i = 0; i < n; i++) {
      final us = _frameTimes[i].inMicroseconds;
      if (us > maxUs) maxUs = us;
    }
    if (maxUs == 0) return 0.0;
    return 1000000.0 / maxUs;
  }

  /// Maximum FPS in the sample window (fastest frame).
  double get maxFps {
    final n = _frameTimeLength;
    if (n == 0) return 0.0;
    int minUs = _frameTimes[0].inMicroseconds;
    for (int i = 1; i < n; i++) {
      final us = _frameTimes[i].inMicroseconds;
      if (us < minUs) minUs = us;
    }
    if (minUs == 0) return double.infinity;
    return 1000000.0 / minUs;
  }

  /// Percentage of time spent in render() vs total frame time.
  double get renderTimePercentage {
    final avg = averageFrameTime.inMicroseconds;
    if (avg == 0) return 0.0;
    return (averageRenderDuration.inMicroseconds / avg) * 100.0;
  }

  /// Call this at the start of each frame (before render).
  void beginFrame() {
    final now = _clock.elapsed;
    if (!metricsOnlyFrame && _lastFrameElapsed != null) {
      final frameTime = now - _lastFrameElapsed!;
      _frameTimes[_frameTimeIndex] = frameTime;
      _frameTimeIndex = (_frameTimeIndex + 1) % _sampleSize;
      _frameTimeCount++;
    }
    // Only update the baseline timestamp for real frames so that the next
    // real frame measures the gap from the previous real frame, not from
    // the metrics-only render.
    if (!metricsOnlyFrame) {
      _lastFrameElapsed = now;
    }

    _renderStopwatch = Stopwatch()..start();
  }

  /// Call this at the end of render().
  void endFrame({bool skipped = false}) {
    if (!metricsOnlyFrame) {
      _frameCount++;
      if (skipped) {
        _skippedFrames++;
      }
    }

    if (_renderStopwatch != null) {
      _renderStopwatch!.stop();
      _lastRenderDuration = _renderStopwatch!.elapsed;
      if (!metricsOnlyFrame) {
        _renderTimes[_renderTimeIndex] = _lastRenderDuration;
        _renderTimeIndex = (_renderTimeIndex + 1) % _sampleSize;
        _renderTimeCount++;
      }
    }

    // Auto-reset so callers don't need to remember to clear it.
    metricsOnlyFrame = false;
  }

  /// Resets all metrics to initial state.
  void reset() {
    _frameTimes.fillRange(0, _sampleSize, Duration.zero);
    _renderTimes.fillRange(0, _sampleSize, Duration.zero);
    _frameTimeIndex = 0;
    _renderTimeIndex = 0;
    _frameTimeCount = 0;
    _renderTimeCount = 0;
    _lastFrameElapsed = null;
    _frameCount = 0;
    _skippedFrames = 0;
    _lastRenderDuration = Duration.zero;
  }

  /// Returns a summary string of current metrics.
  String summary() {
    return 'FPS: ${averageFps.toStringAsFixed(1)} '
        '(${minFps.toStringAsFixed(1)}-${maxFps.toStringAsFixed(1)}) | '
        'Frame: ${averageFrameTime.inMilliseconds}ms | '
        'Render: ${averageRenderDuration.inMicroseconds}µs '
        '(${renderTimePercentage.toStringAsFixed(1)}%) | '
        'Frames: $_frameCount (skipped: $_skippedFrames)';
  }

  @override
  String toString() =>
      'RenderMetrics(fps: ${averageFps.toStringAsFixed(1)}, '
      'frameTime: ${averageFrameTime.inMilliseconds}ms, '
      'renderTime: ${averageRenderDuration.inMicroseconds}µs)';
}

// Upstream references:

// Capabilities mask (subset).
abstract final class _Cap {
  static const int vpa = 1 << 0;
  static const int hpa = 1 << 1;
  static const int cha = 1 << 2;
  static const int cht = 1 << 3;
  static const int cbt = 1 << 4;
  static const int rep = 1 << 5;
  static const int ech = 1 << 6;
  static const int ich = 1 << 7;
  static const int sd = 1 << 8;
  static const int su = 1 << 9;
  // These depend on terminal settings and are not enabled by default.
  static const int ht = 1 << 10;
  static const int bs = 1 << 11;

  static const int noCaps = 0;
  static const int allCaps =
      vpa | hpa | cha | cht | cbt | rep | ech | ich | sd | su;
}

abstract final class _Flag {
  static const int relativeCursor = 1 << 0;
  static const int fullscreen = 1 << 1;
  static const int mapNewline = 1 << 2;
  static const int scrollOptim = 1 << 3;
  static const int synchronizedOutput = 1 << 4;
}

final class _Cursor {
  _Cursor({
    required this.x,
    required this.y,
    this.style = const UvStyle(),
    this.link = const Link(),
  });

  int x;
  int y;
  UvStyle style;
  Link link;

  _Cursor clone() => _Cursor(x: x, y: y, style: style, link: link);
}

/// Low-level terminal renderer for the Ultraviolet engine.
///
/// This renderer is responsible for efficiently updating the terminal screen
/// by diffing buffers and sending minimal ANSI escape sequences.
final class UvTerminalRenderer extends TerminalRenderer {
  /// Capability bit for Vertical Position Absolute (VPA).
  static const int capVpa = _Cap.vpa;

  /// Capability bit for Horizontal Position Absolute (HPA).
  static const int capHpa = _Cap.hpa;

  /// Capability bit for Cursor Horizontal Absolute (CHA).
  static const int capCha = _Cap.cha;

  /// Capability bit for Cursor Horizontal Tab (CHT).
  static const int capCht = _Cap.cht;

  /// Capability bit for Cursor Backward Tab (CBT).
  static const int capCbt = _Cap.cbt;

  /// Capability bit for Repeat Character (REP).
  static const int capRep = _Cap.rep;

  /// Capability bit for Erase Character (ECH).
  static const int capEch = _Cap.ech;

  /// Capability bit for Insert Character (ICH).
  static const int capIch = _Cap.ich;

  /// Capability bit for Scroll Down (SD).
  static const int capSd = _Cap.sd;

  /// Capability bit for Scroll Up (SU).
  static const int capSu = _Cap.su;

  /// Capability bit for Horizontal Tab (HT).
  ///
  /// Depends on terminal settings and is not enabled by default.
  static const int capHt = _Cap.ht;

  /// Capability bit for Backspace (BS).
  ///
  /// Depends on terminal settings and is not enabled by default.
  static const int capBs = _Cap.bs;

  /// Creates a terminal renderer writing to [_writer].
  ///
  /// Optional [env] provides environment variables for capability detection.
  /// Set [isTty] to force TTY mode when the sink is not a real terminal.
  UvTerminalRenderer(
    this._writer, {
    List<String>? env,
    bool? isTty,
    bool isWindows = false,
  }) : _isWindows = isWindows,
       _env = env ?? const [],
       _term = Environ(env ?? const []).getenv('TERM'),
       _caps = _xtermCaps(Environ(env ?? const []).getenv('TERM')) {
    _cur = _Cursor(x: -1, y: -1);
    _saved = _cur.clone();
    _profile = _detectProfile(_env, isTty, isWindows);
    _screen = _RendererScreen(this);
    final environ = Environ(_env);
    _isTmuxSession =
        environ.getenv('TMUX').isNotEmpty ||
        environ.getenv('TERM').startsWith('tmux');
  }

  final StringSink _writer;
  final List<String> _env;
  final String _term;
  late final bool _isTmuxSession;
  final bool _isWindows;

  final StringBuffer _buf = StringBuffer();
  final _FrameArena _arena = _FrameArena();
  final List<_DeferredRetainedGraphic> _deferredRetainedGraphics =
      <_DeferredRetainedGraphic>[];
  final List<_DeferredDisplayPayload> _deferredDisplayPayloads =
      <_DeferredDisplayPayload>[];
  Buffer? _curbuf;
  String _lastFlushedOutput = '';
  late final Screen _screen;

  /// Render performance metrics (FPS, frame times, render durations).
  ///
  /// Access this to monitor rendering performance:
  /// ```dart
  /// print(renderer.metrics.averageFps);
  /// print(renderer.metrics.summary());
  /// ```
  final RenderMetrics metrics = RenderMetrics();

  /// Returns the current terminal width in columns.
  @override
  int width() => _curbuf?.width() ?? 0;

  /// Returns the current terminal height in rows.
  @override
  int height() => _curbuf?.height() ?? 0;

  int _flags = 0;
  int _caps;
  TabStops? _tabs;
  late cp.Profile _profile;
  void Function(String message)? _logger;

  late _Cursor _cur;
  late _Cursor _saved;

  bool _clear = false;
  int _scrollHeight = 0;
  bool _atPhantom = false;

  // Scroll optimization state.
  List<int> _oldhash = const [];
  List<int> _newhash = const [];
  List<_HashEntry> _hashtab = const [];
  List<int> _oldnum = const [];

  /// Enables or disables scroll region optimization.
  ///
  /// When enabled, the renderer uses hash-based line matching to minimize
  /// redraws during scrolling in fullscreen mode.
  @override
  void setScrollOptim(bool v) {
    if (v) {
      _flags |= _Flag.scrollOptim;
    } else {
      _flags &= ~_Flag.scrollOptim;
    }
  }

  /// Enables or disables synchronized terminal updates (DECSET 2026).
  ///
  /// When enabled, each rendered frame is wrapped between
  /// [UvAnsi.beginSynchronizedUpdate] and [UvAnsi.endSynchronizedUpdate] so
  /// compatible terminals present the frame atomically.
  ///
  /// This is opt-in and disabled by default for parity with upstream outputs.
  @override
  void setSynchronizedOutput(bool v) {
    if (v) {
      _flags |= _Flag.synchronizedOutput;
    } else {
      _flags &= ~_Flag.synchronizedOutput;
    }
  }

  /// Whether synchronized frame output is enabled.
  bool synchronizedOutput() => (_flags & _Flag.synchronizedOutput) != 0;

  /// Enables or disables fullscreen (alternate screen) mode.
  @override
  void setFullscreen(bool v) {
    if (v) {
      _flags |= _Flag.fullscreen;
    } else {
      _flags &= ~_Flag.fullscreen;
    }
  }

  /// Whether fullscreen mode is enabled.
  bool fullscreen() => (_flags & _Flag.fullscreen) != 0;

  /// Enables or disables relative cursor positioning.
  ///
  /// When enabled, the renderer uses relative movement sequences instead of
  /// absolute cursor positioning.
  @override
  void setRelativeCursor(bool v) {
    if (v) {
      _flags |= _Flag.relativeCursor;
    } else {
      _flags &= ~_Flag.relativeCursor;
    }
  }

  /// Enables or disables LF to CR+LF newline mapping.
  void setMapNewline(bool v) {
    if (v) {
      _flags |= _Flag.mapNewline;
    } else {
      _flags &= ~_Flag.mapNewline;
    }
  }

  /// Saves the current cursor position.
  void saveCursor() {
    _saved = _cur.clone();
  }

  /// Restores the previously saved cursor position.
  void restoreCursor() {
    _cur = _saved.clone();
  }

  /// Enters the alternate screen buffer.
  ///
  /// Saves the cursor, enables fullscreen mode, and erases the screen.
  @override
  void enterAltScreen() {
    saveCursor();
    _buf.write(UvAnsi.setModeAltScreenSaveCursor);
    setFullscreen(true);
    setRelativeCursor(false);
    erase();
  }

  /// Exits the alternate screen buffer.
  ///
  /// Restores the previous screen content and cursor position.
  @override
  void exitAltScreen() {
    erase();
    setRelativeCursor(true);
    setFullscreen(false);
    _buf.write(UvAnsi.resetModeAltScreenSaveCursor);
    restoreCursor();
  }

  /// Hides the cursor.
  @override
  void hideCursor() {
    _buf.write(UvAnsi.hideCursor);
  }

  /// Shows the cursor.
  @override
  void showCursor() {
    _buf.write(UvAnsi.showCursor);
  }

  /// Enables mouse event reporting for all events (motion, buttons, scroll).
  @override
  void enableMouseAllEvents() {
    _buf.write(UvAnsi.enableMouseAllEvents);
    _buf.write(UvAnsi.enableMouseSgr);
  }

  /// Disables mouse event reporting.
  @override
  void disableMouseAllEvents() {
    _buf.write(UvAnsi.disableMouseAllEvents);
    _buf.write(UvAnsi.disableMouseSgr);
  }

  /// Enables bracketed paste mode.
  ///
  /// Pasted text is wrapped in escape sequences so it can be distinguished
  /// from typed input.
  @override
  void enableBracketedPaste() {
    _buf.write(UvAnsi.enableBracketedPaste);
  }

  /// Disables bracketed paste mode.
  @override
  void disableBracketedPaste() {
    _buf.write(UvAnsi.disableBracketedPaste);
  }

  /// Enables focus event reporting.
  ///
  /// The terminal sends escape sequences when the window gains or loses focus.
  @override
  void enableFocusReporting() {
    _buf.write(UvAnsi.enableFocusReporting);
  }

  /// Disables focus event reporting.
  @override
  void disableFocusReporting() {
    _buf.write(UvAnsi.disableFocusReporting);
  }

  /// Pushes keyboard enhancements (Kitty Keyboard Protocol).
  @override
  void pushKeyboardEnhancements(int flags) {
    _buf.write('\x1b[>${flags}u');
  }

  /// Pops keyboard enhancements (Kitty Keyboard Protocol).
  @override
  void popKeyboardEnhancements() {
    _buf.write('\x1b[<u');
  }

  /// Queries keyboard enhancements (Kitty Keyboard Protocol).
  @override
  void queryKeyboardEnhancements() {
    _buf.write('\x1b[?u');
  }

  /// Queries primary device attributes.
  @override
  void queryPrimaryDeviceAttributes() {
    _buf.write('\x1b[?c');
  }

  /// Queries secondary device attributes.
  @override
  void querySecondaryDeviceAttributes() {
    _buf.write('\x1b[>c');
  }

  /// Queries tertiary device attributes.
  @override
  void queryTertiaryDeviceAttributes() {
    _buf.write('\x1b[=c');
  }

  /// Queries the terminal version string.
  @override
  void queryTerminalVersion() {
    _buf.write('\x1b[>0q');
  }

  /// Queries Kitty Graphics support.
  @override
  void queryKittyGraphics() {
    // Use a random id=31 to query support.
    _buf.write('\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\');
  }

  /// Queries the terminal background color.
  @override
  void queryBackgroundColor() {
    _buf.write('\x1b]11;?\x1b\\');
  }

  /// Queries the terminal foreground color.
  @override
  void queryForegroundColor() {
    _buf.write('\x1b]10;?\x1b\\');
  }

  /// Queries the terminal cursor color.
  @override
  void queryCursorColor() {
    _buf.write('\x1b]12;?\x1b\\');
  }

  /// Queries the terminal light/dark color-scheme preference.
  @override
  void queryColorScheme() {
    _buf.write('\x1b[?996n');
  }

  /// Queries a color from the terminal palette.
  void queryColorPalette(int index) {
    _buf.write('\x1b]4;$index;?\x1b\\');
  }

  /// Marks the screen as needing a full erase on the next render.
  @override
  void erase() {
    _clear = true;
  }

  /// Returns the number of bytes currently buffered for output.
  int buffered() => _buf.length;

  /// The current color profile used for output.
  cp.Profile get profile => _profile;

  /// The detected terminal capabilities as a bitmask.
  int get capabilities => _caps;

  /// Whether relative cursor positioning mode is active.
  bool get isRelativeCursorEnabled => (_flags & _Flag.relativeCursor) != 0;

  /// Whether fullscreen mode is active.
  bool get isFullscreenEnabled => (_flags & _Flag.fullscreen) != 0;

  /// Flushes buffered output to the terminal sink.
  ///
  /// Writes all pending escape sequences and content, then clears the buffer.
  @override
  void flush() {
    final out = _buf.toString();
    _lastFlushedOutput = out;
    if (out.isNotEmpty) {
      final logger = _logger;
      if (logger != null) {
        logger('output: ${jsonEncode(out)}');
      }
      _writer.write(out);
      _buf.clear();
    }
  }

  /// The exact ANSI/content string emitted by the most recent [flush].
  @override
  String get lastFlushedOutput => _lastFlushedOutput;

  /// Sets the debug logger callback.
  ///
  /// When set, all output sequences are logged via [logger] before writing.
  @override
  void setLogger(void Function(String message)? logger) {
    _logger = logger;
  }

  /// Sets the color profile for output.
  ///
  /// Controls how colors are downsampled (e.g. true color, 256-color, ANSI).
  @override
  void setColorProfile(cp.Profile profile) {
    _profile = profile;
  }

  /// Marks cells in [newbuf] as dirty wherever [_curbuf] disagrees.
  ///
  /// When content is removed between frames (e.g. an overlay disappears), the
  /// new buffer's default empty cells are never explicitly written via
  /// `setCell()`, so they carry no dirty bits. This method walks the previous
  /// frame's buffer ([_curbuf]) and, for every cell that differs from the
  /// corresponding cell in [newbuf] but is not already dirty in [newbuf],
  /// marks it dirty with `newbuf.touch()`.
  void _markStaleCells(Buffer newbuf) {
    final cur = _curbuf;
    if (cur == null) return;
    // Only mark stale cells when buffer dimensions haven't changed. Size
    // changes already trigger different handling in render() (resize +
    // _clearBottom / _clearUpdate), and injecting extra dirty bits here would
    // interfere with the cursor-movement optimizations used during those
    // transitions.
    if (cur.width() != newbuf.width() || cur.height() != newbuf.height()) {
      return;
    }
    final w = cur.width();
    final h = cur.height();
    final empty = Cell.emptyCell();
    for (var y = 0; y < h; y++) {
      final curLine = cur.line(y);
      if (curLine == null) continue;
      final newLine = newbuf.line(y);
      if (newLine == null) continue;
      for (var x = 0; x < w; x++) {
        // Skip cells already tracked as dirty in newbuf.
        if (newbuf.isCellDirty(x, y)) continue;
        final curCell = curLine.at(x);
        // Skip cells in _curbuf that are already empty — nothing stale.
        if (curCell == null || curCell == empty) continue;
        final newCell = newLine.at(x);
        if (!_cellEqual(curCell, newCell)) {
          newbuf.touch(x, y);
        }
      }
    }
  }

  int _touched(Buffer buf) {
    if (buf.dirtyRows.isEmpty) return buf.height();
    var n = 0;
    for (final dirty in buf.dirtyRows) {
      if (dirty) n++;
    }
    return n;
  }

  int _dirtyTouched(Buffer buf) {
    if (buf.dirtyRows.isEmpty) return buf.height();
    var n = 0;
    for (final dirty in buf.dirtyRows) {
      if (dirty) n++;
    }
    return n;
  }

  /// Returns the number of touched (dirty) lines in [buf].
  ///
  /// If dirty line tracking has been explicitly cleared by the renderer, the
  /// buffer uses `LineData.clean` markers on all rows. In that state we treat
  /// the buffer as fully touched for parity visibility, matching upstream
  /// UV's historical semantics for the public `touched` accessor.
  int touched(Buffer buf) {
    if (buf.touched.isNotEmpty) {
      var allClean = true;
      for (final lineData in buf.touched) {
        if (lineData != LineData.clean) {
          allClean = false;
          break;
        }
      }
      if (allClean) {
        return buf.height();
      }
    }
    return _touched(buf);
  }

  /// Updates the terminal dimensions.
  ///
  /// Resizes internal tab stops and resets the scroll height.
  /// Does not implicitly clear the screen; call [erase] separately if needed.
  @override
  void resize(int width, int height) {
    _tabs?.resize(width);
    _scrollHeight = 0;
    // Important: resizing MUST NOT implicitly clear the screen. Upstream UV
    // keeps resize side-effect free; callers explicitly call `erase()` when
    // they want a full clear (parity tests depend on this).
  }

  /// Returns the current cursor position as `(x, y)`.
  ({int x, int y}) position() => (x: _cur.x, y: _cur.y);

  /// Sets the cursor position to ([x], [y]).
  void setPosition(int x, int y) {
    _cur.x = x;
    _cur.y = y;
  }

  /// Writes a raw string to the output buffer and returns its length.
  @override
  int writeString(String s) {
    _buf.write(s);
    return s.length;
  }

  /// Writes raw bytes to the output buffer and returns the byte count.
  int write(List<int> bytes) {
    _buf.write(String.fromCharCodes(bytes));
    return bytes.length;
  }

  /// Moves the cursor to column [x], row [y].
  @override
  void moveTo(int x, int y) {
    _move(null, x, y);
  }

  /// Forces a complete screen redraw by erasing and re-rendering [newbuf].
  void redraw(Buffer newbuf) {
    erase();
    render(newbuf);
  }

  /// Configures whether backspace can be used for cursor movement.
  @override
  void setBackspace(bool v) {
    if (v) {
      _caps |= _Cap.bs;
    } else {
      _caps &= ~_Cap.bs;
    }
  }

  /// Configures whether horizontal tab can be used for cursor movement.
  @override
  void setHasTab(bool v) {
    if (v) {
      _caps |= _Cap.ht;
    } else {
      _caps &= ~_Cap.ht;
    }
  }

  /// Sets tab stop positions based on the given terminal [width].
  ///
  /// Pass a negative value to disable tab stops. On Linux consoles,
  /// tab stops are always disabled.
  @override
  void setTabStops(int width) {
    if (width < 0 || _term.startsWith('linux')) {
      _caps &= ~_Cap.ht;
      _tabs = null;
      return;
    }
    _caps |= _Cap.ht;
    _tabs = TabStops.defaults(width);
  }

  /// Prepends raw escape sequences to the output buffer.
  ///
  /// Scrolls the screen content in [newbuf] to make room for [str], which is
  /// inserted at the top of the visible area.
  @override
  void prependString(Buffer newbuf, String str) {
    if (str.isEmpty) return;

    final w = newbuf.width();
    final h = newbuf.height();
    _move(newbuf, 0, h - 1);

    final lines = str.split('\n');
    var offset = 0;
    for (final line in lines) {
      final lineWidth = WidthMethod.wcwidth.stringWidth(line);
      if (w > 0 && lineWidth > w) {
        offset += (lineWidth ~/ w);
      }
      if (lineWidth == 0 || (w > 0 && lineWidth % w != 0)) {
        offset++;
      }
    }

    if (offset <= 0) return;

    _buf.write(List.filled(offset, '\n').join());
    _cur.y += offset;

    // Move to top and insert new lines.
    _moveCursor(newbuf, 0, 0, false);
    _buf.write(UvAnsi.insertLine(offset));
    for (final line in lines) {
      _buf.write(line);
      _buf.write('\r\n');
    }
  }

  /// Renders the screen buffer to the terminal.
  ///
  /// Diffs [newbuf] against the previously rendered buffer and emits the
  /// minimal ANSI escape sequences needed to update the terminal. Skipped
  /// frames (no dirty lines and no pending clear) are recorded as such in
  /// [metrics].
  @override
  void render(Buffer newbuf) {
    metrics.beginFrame();
    _arena.reset();
    _deferredRetainedGraphics.clear();
    _deferredDisplayPayloads.clear();

    _curbuf ??= Buffer.create(newbuf.width(), newbuf.height());

    if (_bufferContainsSixelDisplay(newbuf) ||
        (_curbuf != null && _bufferContainsSixelDisplay(_curbuf!))) {
      erase();
    }

    // Detect stale content: cells that exist in _curbuf from a previous frame
    // but are not marked dirty in newbuf. This happens when content (e.g. an
    // overlay) is removed — the new buffer has default empty cells at those
    // positions but never explicitly wrote them, so they lack dirty bits.
    // Without this pass the tile-based diff would skip those cells, leaving
    // artifacts on screen.
    _markStaleCells(newbuf);

    final touchedLines = _dirtyTouched(newbuf);
    if (!_clear && touchedLines == 0) {
      metrics.endFrame(skipped: true);
      return;
    }

    final useSync = synchronizedOutput();
    if (useSync) {
      _buf.write(UvAnsi.beginSynchronizedUpdate);
    }

    final newWidth = newbuf.width();
    final newHeight = newbuf.height();
    final curWidth = _curbuf!.width();
    final curHeight = _curbuf!.height();
    final sameSize = curWidth == newWidth && curHeight == newHeight;

    if (!sameSize) {
      _oldhash = const [];
      _newhash = const [];
    }

    final partialClear =
        !fullscreen() &&
        _cur.x != -1 &&
        _cur.y != -1 &&
        curWidth == newWidth &&
        curHeight > 0 &&
        curHeight > newHeight;

    if (!_clear && partialClear) {
      _clearBelow(newbuf, _clearBlank(), newHeight - 1);
    }

    if (_clear) {
      _clearUpdate(newbuf);
      _clear = false;
    } else if (touchedLines > 0) {
      if ((_flags & _Flag.scrollOptim) != 0 &&
          fullscreen() &&
          sameSize &&
          !_isWindows) {
        _scrollOptimize(newbuf);
      }

      var nonEmpty = fullscreen()
          ? (curHeight < newHeight ? curHeight : newHeight)
          : newHeight;
      nonEmpty = _clearBottom(newbuf, nonEmpty);
      final density = _tileDensityForTransform(newbuf, touchedLines, nonEmpty);
      if (density != null) {
        _transformDirtyTiles(newbuf, nonEmpty, density);
      } else {
        for (var i = 0; i < nonEmpty && i < newHeight; i++) {
          final ld = (newbuf.touched.isEmpty || i >= newbuf.touched.length)
              ? null
              : newbuf.touched[i];
          final shouldTransform =
              newbuf.touched.isEmpty ||
              i >= newbuf.touched.length ||
              (ld?.isDirty ?? false) ||
              (i < newbuf.dirtyRows.length && newbuf.dirtyRows[i]);
          if (shouldTransform) {
            _transformLine(newbuf, i);
          }
          newbuf.clearDirtyLine(i);
          _curbuf!.clearDirtyLine(i);
        }
      }
    }

    if (!fullscreen() && _scrollHeight < newHeight - 1) {
      _move(newbuf, 0, newHeight - 1);
    }

    // Sync dirty markers.
    newbuf.clearDirtyTracking();
    _curbuf!.clearDirtyTracking();

    if (curWidth != newWidth || curHeight != newHeight) {
      _curbuf!.resize(newWidth, newHeight);
      final start = curHeight <= 0 ? 0 : curHeight - 1;
      for (var i = start; i < newHeight; i++) {
        final srcLine = newbuf.line(i);
        final dstLine = _curbuf!.line(i);
        if (srcLine != null && dstLine != null) {
          final src = srcLine.cells;
          for (var x = 0; x < dstLine.length && x < src.length; x++) {
            dstLine.replaceWithClone(x, src[x]);
          }
        }
      }
    }

    // Reset pen after rendering to avoid style/link bleed.
    _updatePen(null);
    _flushDeferredRetainedGraphics(newbuf);
    _flushDeferredDisplayPayloads();
    if (useSync) {
      _buf.write(UvAnsi.endSynchronizedUpdate);
    }

    metrics.endFrame();
  }

  // --- Cursor movement ------------------------------------------------------

  void _moveCursor(Buffer? newbuf, int x, int y, bool overwrite) {
    if (!fullscreen() &&
        (_flags & _Flag.relativeCursor) != 0 &&
        _cur.x == -1 &&
        _cur.y == -1) {
      _buf.write('\r');
      _cur.x = 0;
      _cur.y = 0;
    }

    final (:seq, :scrollHeight) = _moveCursorSeq(this, newbuf, x, y, overwrite);
    _scrollHeight = _scrollHeight > scrollHeight ? _scrollHeight : scrollHeight;
    if (seq.contains('\n')) {
      final activeStyle = style_ops.convertStyle(_cur.style, _profile);
      final activeLink = style_ops.convertLink(_cur.link, _profile);
      if (!activeStyle.isZero || !activeLink.isZero) {
        _updatePen(null);
      }
    }
    _buf.write(seq);
    _cur.x = x;
    _cur.y = y;
  }

  void _move(Buffer? newbuf, int x, int y) {
    var width = 0;
    var height = 0;
    if (_curbuf != null) {
      width = _curbuf!.width();
      height = _curbuf!.height();
    }
    if (newbuf != null) {
      width = width > newbuf.width() ? width : newbuf.width();
      height = height > newbuf.height() ? height : newbuf.height();
    }

    if (width > 0 && x >= width) {
      y += (x ~/ width);
      x %= width;
    }

    // Reset phantom wrap state.
    if (_atPhantom) {
      _cur.x = 0;
      _buf.write('\r');
      _atPhantom = false;
    }

    if (height > 0) {
      if (_cur.y > height - 1) _cur.y = height - 1;
      if (y > height - 1) y = height - 1;
    }

    if (x == _cur.x && y == _cur.y) return;

    _moveCursor(newbuf, x, y, true);
  }

  // --- Pen / cell writing ---------------------------------------------------

  Cell _clearBlank() =>
      Cell(content: ' ', width: 1, style: _cur.style, link: _cur.link);

  void _updatePen(Cell? cell) {
    // with profile downsampling.
    if (cell == null) {
      if (!_cur.style.isZero) {
        _buf.write(UvAnsi.resetStyle);
        _cur.style = const UvStyle();
      }
      if (!_cur.link.isZero) {
        _buf.write(UvAnsi.resetHyperlink());
        _cur.link = const Link();
      }
      return;
    }

    final newStyle = _profile == cp.Profile.trueColor
        ? cell.style
        : style_ops.convertStyle(cell.style, _profile);
    final newLink = _profile == cp.Profile.trueColor
        ? cell.link
        : style_ops.convertLink(cell.link, _profile);
    final oldStyle = _profile == cp.Profile.trueColor
        ? _cur.style
        : style_ops.convertStyle(_cur.style, _profile);
    final oldLink = _profile == cp.Profile.trueColor
        ? _cur.link
        : style_ops.convertLink(_cur.link, _profile);

    if (newStyle != oldStyle) {
      if (!_writeSimpleRgbTransitionDirect(oldStyle, newStyle)) {
        final seq = style_ops.styleTransitionSgr(oldStyle, newStyle);
        _buf.write(seq);
      }
      _cur.style = cell.style;
    }
    if (newLink != oldLink) {
      _buf.write(UvAnsi.setHyperlink(newLink.url, newLink.params));
      _cur.link = cell.link;
    }
  }

  bool _writeSimpleRgbTransitionDirect(UvStyle oldStyle, UvStyle newStyle) {
    if (!_isSimpleRgbStyle(oldStyle) || !_isSimpleRgbStyle(newStyle)) {
      return false;
    }

    final oldFg = oldStyle.fg as UvRgb?;
    final oldBg = oldStyle.bg as UvRgb?;
    final newFg = newStyle.fg as UvRgb?;
    final newBg = newStyle.bg as UvRgb?;
    final fgChanged = oldFg != newFg;
    final bgChanged = oldBg != newBg;
    if (!fgChanged && !bgChanged) {
      return true;
    }

    _buf.write('\x1b[');
    var wrote = false;
    if (fgChanged) {
      _writeSimpleRgbDiffCode(newFg, true);
      wrote = true;
    }
    if (bgChanged) {
      if (wrote) _buf.write(';');
      _writeSimpleRgbDiffCode(newBg, false);
      wrote = true;
    }
    _buf.write('m');
    return true;
  }

  void _writeSimpleRgbDiffCode(UvRgb? color, bool fg) {
    if (color == null) {
      _buf.write(fg ? '39' : '49');
      return;
    }
    _buf.write(fg ? '38;2;' : '48;2;');
    _buf.write(_sgrByte[color_utils.clampRgbChannel(color.r)]);
    _buf.write(';');
    _buf.write(_sgrByte[color_utils.clampRgbChannel(color.g)]);
    _buf.write(';');
    _buf.write(_sgrByte[color_utils.clampRgbChannel(color.b)]);
  }

  void _wrapCursor() {
    _cur.x = 0;
    _cur.y++;
  }

  void _putCell(Buffer? newbuf, Cell? cell) {
    final w = newbuf?.width() ?? width();
    final h = newbuf?.height() ?? height();
    if (w > 0 && h > 0 && fullscreen() && _cur.x == w - 1 && _cur.y == h - 1) {
      _putCellLR(newbuf, cell);
    } else {
      _putAttrCell(newbuf, cell);
    }
  }

  void _putAttrCell(Buffer? newbuf, Cell? cell) {
    if (cell != null && cell.isZero) return;

    if (_atPhantom) {
      _wrapCursor();
      _atPhantom = false;
    }

    _updatePen(cell);

    if (cell?.drawable != null) {
      final drawable = cell!.drawable as Drawable;
      drawable.draw(_screen, rect(_cur.x, _cur.y, cell.width, 1));
    } else {
      final rawWidth = cell?.width;
      if (rawWidth == 0) return;

      final cellWidth = (rawWidth == null || rawWidth < 0) ? 1 : rawWidth;
      final asciiCodeUnit = cell?.asciiCodeUnit;
      if (asciiCodeUnit != null) {
        _buf.writeCharCode(asciiCodeUnit);
      } else {
        final content = cell?.content ?? ' ';
        if (!terminal_graphics.mayContainTerminalGraphics(content)) {
          _buf.write(content);
        } else if (terminal_graphics.containsRetainedTerminalGraphics(
          content,
        )) {
          _deferredRetainedGraphics.add(
            _DeferredRetainedGraphic(_cur.x, _cur.y, content, cellWidth),
          );
          _buf.write(UvAnsi.cursorForward(cellWidth));
        } else if (terminal_graphics.containsSixelDisplay(content)) {
          _deferredDisplayPayloads.add(
            _DeferredDisplayPayload(_cur.x, _cur.y, content, cellWidth),
          );
          _buf.write(UvAnsi.cursorForward(cellWidth));
        } else {
          _buf.write(content);
          if (terminal_graphics.terminalGraphicsSuppressesCursorMovement(
            content,
          )) {
            _buf.write(UvAnsi.cursorForward(cellWidth));
          }
        }
      }

      _cur.x += cellWidth;
    }

    if (_cur.x >= (newbuf?.width() ?? width())) {
      _atPhantom = true;
    }
  }

  void _flushDeferredRetainedGraphics(Buffer newbuf) {
    if (_deferredRetainedGraphics.isEmpty) return;

    _updatePen(null);
    final restoreX = _cur.x;
    final restoreY = _cur.y;
    for (final graphic in _deferredRetainedGraphics) {
      _move(newbuf, graphic.x, graphic.y);
      _buf.write(_wrapDisplayPayloadForTransport(graphic.content));
      if (terminal_graphics.terminalGraphicsSuppressesCursorMovement(
        graphic.content,
      )) {
        _buf.write(UvAnsi.cursorForward(graphic.width));
      }
      _cur.x = graphic.x + graphic.width;
      _cur.y = graphic.y;
    }
    if (restoreX >= 0 && restoreY >= 0) {
      _move(newbuf, restoreX, restoreY);
    }
    _deferredRetainedGraphics.clear();
  }

  void _flushDeferredDisplayPayloads() {
    if (_deferredDisplayPayloads.isEmpty) return;

    _updatePen(null);
    final restoreX = _cur.x;
    final restoreY = _cur.y;
    for (final payload in _deferredDisplayPayloads) {
      _writeAbsoluteCursorPosition(payload.x, payload.y);
      _buf.write(_wrapDisplayPayloadForTransport(payload.content));
    }
    if (restoreX >= 0 && restoreY >= 0) {
      _writeAbsoluteCursorPosition(restoreX, restoreY);
    }
    _deferredDisplayPayloads.clear();
  }

  void _writeAbsoluteCursorPosition(int x, int y) {
    _buf.write(UvAnsi.cursorPosition(x + 1, y + 1));
    _cur.x = x;
    _cur.y = y;
    _atPhantom = false;
  }

  String _wrapDisplayPayloadForTransport(String content) {
    if (!_isTmuxSession) return content;
    final escaped = content.replaceAll('\x1b', '\x1b\x1b');
    return '\x1bPtmux;$escaped\x1b\\';
  }

  void _putCellLR(Buffer? newbuf, Cell? cell) {
    final curX = _cur.x;
    if (cell == null || !cell.isZero) {
      _buf.write(UvAnsi.resetModeAutoWrap);
      _putAttrCell(newbuf, cell);
      _atPhantom = false;
      _cur.x = curX;
      _buf.write(UvAnsi.setModeAutoWrap);
    }
  }

  // --- Line transform / clearing -------------------------------------------

  static bool _cellEqual(Cell? a, Cell? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a == b;
  }

  static bool _canClearWith(Cell? c) {
    if (c == null) return true;
    if (c.width != 1) return false;
    if (c.asciiCodeUnit != 0x20 && c.content != ' ') return false;
    final style = c.style;
    // Cells with an explicit foreground or background color must be written
    // individually — EL (erase line) would replace them with the terminal's
    // default colors, losing the intended bg/fg fill.
    if (style.fg != null || style.bg != null) return false;
    final okAttrs =
        style.attrs &
            ~(Attr.bold |
                Attr.faint |
                Attr.italic |
                Attr.blink |
                Attr.rapidBlink) ==
        0;
    return style.underline == UnderlineStyle.none && okAttrs && c.link.isZero;
  }

  static bool _hasStyledLeadingPrefix(Line line, int uptoExclusive) {
    if (uptoExclusive <= 0) return false;
    var sawStyledCell = false;
    for (var x = 0; x < uptoExclusive && x < line.length; x++) {
      final cell = line.at(x);
      if (cell == null || cell.width != 1) {
        return false;
      }
      final style = cell.style;
      if (style.fg == null &&
          style.bg == null &&
          style.underlineColor == null &&
          style.underline == UnderlineStyle.none &&
          style.attrs == 0 &&
          cell.link.isZero) {
        return false;
      }
      sawStyledCell = true;
    }
    return sawStyledCell;
  }

  int _el0Cost() => 0; // prefer EL in xterm-like terminals

  void _clearToEnd(Buffer newbuf, Cell blank, bool force) {
    final width = newbuf.width();
    var startX = _cur.x;
    if (startX < 0) startX = 0;
    if (startX > width) startX = width;

    if (_cur.y >= 0 && _curbuf != null) {
      final curLine = _curbuf!.line(_cur.y);
      if (curLine == null) {
        // During a resize, the cursor may briefly point outside the current
        // buffer. Upstream returns a nil line in this case; treat it as empty.
      } else {
        for (var j = startX; j < width; j++) {
          final c = curLine.at(j);
          if (!_cellEqual(c, blank)) {
            curLine.set(j, blank);
            force = true;
          }
        }
      }
    }

    if (!force) return;
    _updatePen(blank);
    final count = width - startX;
    if (count < 0) return;
    if (_el0Cost() <= count) {
      _buf.write(UvAnsi.eraseLineRight);
    } else {
      for (var i = 0; i < count; i++) {
        _putCell(newbuf, blank);
      }
    }
  }

  void _clearToBottom(Cell blank) {
    var row = _cur.y;
    var col = _cur.x;
    if (row < 0) row = 0;
    if (col < 0) col = 0;
    if (_curbuf != null) {
      final h = _curbuf!.height();
      final w = _curbuf!.width();
      if (row > h) row = h;
      if (col > w) col = w;
    }

    _updatePen(blank);
    _buf.write(UvAnsi.eraseScreenBelow);
    _curbuf?.clearArea(rect(col, row, _curbuf!.width() - col, 1));
    _curbuf?.clearArea(
      rect(0, row + 1, _curbuf!.width(), _curbuf!.height() - row - 1),
    );
  }

  void _clearScreen(Cell blank) {
    _updatePen(blank);
    _buf.write(UvAnsi.cursorHomePosition);
    _buf.write(UvAnsi.eraseEntireScreen);
    _cur.x = 0;
    _cur.y = 0;
    _curbuf?.fill(blank);
  }

  void _clearBelow(Buffer newbuf, Cell blank, int row) {
    _move(newbuf, 0, row);
    _clearToBottom(blank);
  }

  int _clearBottom(Buffer newbuf, int total) {
    if (total <= 0 || _curbuf == null) return 0;

    var top = total;
    final last = _curbuf!.width() < newbuf.width()
        ? _curbuf!.width()
        : newbuf.width();
    final blank = _clearBlank();
    if (_canClearWith(blank)) {
      for (var row = total - 1; row >= 0; row--) {
        final oldLine = row < _curbuf!.height() ? _curbuf!.line(row) : null;
        final newLine = row < newbuf.height() ? newbuf.line(row) : null;
        var ok = true;
        for (var col = 0; ok && col < last; col++) {
          ok = _cellEqual(newLine?.at(col), blank);
        }
        if (!ok) break;
        for (var col = 0; ok && col < last; col++) {
          ok = _cellEqual(oldLine?.at(col), blank);
        }
        if (!ok) top = row;
      }

      if (top < total) {
        _move(newbuf, 0, top - 1 < 0 ? 0 : top - 1);
        _clearToBottom(blank);
      }
    }

    return top;
  }

  void _clearUpdate(Buffer newbuf) {
    final blank = _clearBlank();
    int nonEmpty;
    if (fullscreen()) {
      nonEmpty = (_curbuf!.height() > newbuf.height())
          ? _curbuf!.height()
          : newbuf.height();
      _clearScreen(blank);
    } else {
      nonEmpty = newbuf.height();
      _clearBelow(newbuf, blank, 0);
    }
    nonEmpty = _clearBottom(newbuf, nonEmpty);
    for (var i = 0; i < nonEmpty && i < newbuf.height(); i++) {
      _transformLine(newbuf, i, segmented: false);
    }
  }

  void _emitRange(Buffer newbuf, List<Cell> line, int n, {int start = 0}) {
    for (var i = 0; i < n; i++) {
      _putCell(newbuf, line[start + i]);
    }
  }

  DirtyDensityMap? _tileDensityForTransform(
    Buffer newbuf,
    int touchedLines,
    int nonEmpty,
  ) {
    if (_clear) return null;
    if (newbuf.width() < 32 || nonEmpty < 8) return null;
    if (touchedLines < 4) return null;
    final maxY = nonEmpty < newbuf.height() ? nonEmpty : newbuf.height();
    final density = DirtyDensityMap.fromBuffer(
      newbuf,
      scratch: _arena.acquireInt32List(
        (newbuf.width() + 1) * (newbuf.height() + 1),
      ),
    );
    final dirtyCells = density.count(rect(0, 0, newbuf.width(), maxY));
    final totalCells = newbuf.width() * maxY;
    if (dirtyCells <= 0 || totalCells <= 0) return null;
    // Tile traversal only helps when the dirty surface is sparse.
    if (dirtyCells * 4 >= totalCells) return null;
    return density;
  }

  void _transformDirtyTiles(
    Buffer newbuf,
    int nonEmpty,
    DirtyDensityMap density,
  ) {
    const tileWidth = 16;
    const tileHeight = 8;
    final maxY = nonEmpty < newbuf.height() ? nonEmpty : newbuf.height();
    final wholeRowHandled = _arena.acquireBoolList(maxY);

    for (var tileY = 0; tileY < maxY; tileY += tileHeight) {
      final height = (tileY + tileHeight) > maxY ? maxY - tileY : tileHeight;
      for (var tileX = 0; tileX < newbuf.width(); tileX += tileWidth) {
        final width = (tileX + tileWidth) > newbuf.width()
            ? newbuf.width() - tileX
            : tileWidth;
        final tile = rect(tileX, tileY, width, height);
        if (!density.hasAny(tile)) continue;
        for (var y = tile.minY; y < tile.maxY; y++) {
          if (wholeRowHandled[y]) continue;
          if (y >= newbuf.dirtyRows.length || !newbuf.dirtyRows[y]) continue;
          if (_shouldTransformWholeRowInTile(newbuf, density, y)) {
            _transformLine(newbuf, y, segmented: false);
            wholeRowHandled[y] = true;
            continue;
          }
          final spans = newbuf.dirtyBitSpans(y);
          if (spans.isEmpty) {
            _transformLine(newbuf, y, segmented: false);
            wholeRowHandled[y] = true;
            continue;
          }
          for (final span in spans) {
            final start = span.start > tile.minX ? span.start : tile.minX;
            final end = span.end < tile.maxX ? span.end : tile.maxX;
            if (start >= end) continue;
            _transformLineRange(
              newbuf,
              y,
              start,
              end,
              allowClearToEnd: span.end >= newbuf.width(),
            );
          }
        }
      }
    }

    for (var i = 0; i < maxY; i++) {
      newbuf.clearDirtyLine(i);
      _curbuf!.clearDirtyLine(i);
    }
  }

  bool _shouldTransformWholeRowInTile(
    Buffer newbuf,
    DirtyDensityMap density,
    int y,
  ) {
    final lineData = y < newbuf.touched.length ? newbuf.touched[y] : null;
    if (lineData?.overflowed ?? false) return true;
    final dirtyInRow = density.count(rect(0, y, newbuf.width(), 1));
    if (dirtyInRow * 2 >= newbuf.width()) return true;
    return false;
  }

  void _transformLine(Buffer newbuf, int y, {bool segmented = true}) {
    final spans = segmented ? newbuf.dirtyBitSpans(y) : const <DirtySpan>[];
    if (spans.length > 1) {
      if (_canMergeAdjacentDirtySpans(newbuf, y, spans)) {
        _transformLineRange(
          newbuf,
          y,
          spans.first.start,
          spans.last.end,
          allowClearToEnd: spans.last.end >= newbuf.width(),
        );
        return;
      }
      for (final span in spans) {
        _transformLineRange(
          newbuf,
          y,
          span.start,
          span.end,
          allowClearToEnd: span.end >= newbuf.width(),
        );
      }
      return;
    }

    _transformWholeLine(newbuf, y);
  }

  bool _canMergeAdjacentDirtySpans(
    Buffer newbuf,
    int y,
    List<DirtySpan> spans,
  ) {
    if (spans.length <= 1) return false;
    if (y < 0 || y >= newbuf.height()) return false;
    final newLine = newbuf.line(y);
    final oldLine = _curbuf != null && y < _curbuf!.height()
        ? _curbuf!.line(y)
        : null;
    if (newLine == null || oldLine == null) return false;

    for (var i = 0; i + 1 < spans.length; i++) {
      final gapStart = spans[i].end;
      final gapEnd = spans[i + 1].start;
      for (var x = gapStart; x < gapEnd; x++) {
        final oldCell = oldLine.at(x);
        final newCell = newLine.at(x);
        if (!_cellEqual(oldCell, newCell)) return false;
        if (newCell == null ||
            newCell.width != 1 ||
            newCell.content != ' ' ||
            newCell.style != const UvStyle()) {
          return false;
        }
      }
    }

    return true;
  }

  void _transformWholeLine(Buffer newbuf, int y) {
    if (_curbuf == null) return;
    var firstCell = 0;
    final Line? oldLine = y < _curbuf!.height() ? _curbuf!.line(y) : null;
    final newLine = newbuf.line(y);
    if (newLine == null) return;

    var blank = newLine.at(0) ?? Cell.emptyCell();
    if (_canClearWith(blank)) {
      var oFirstCell = 0;
      for (; oFirstCell < _curbuf!.width(); oFirstCell++) {
        if (!_cellEqual(oldLine?.at(oFirstCell), blank)) break;
      }
      var nFirstCell = 0;
      for (; nFirstCell < newbuf.width(); nFirstCell++) {
        if (!_cellEqual(newLine.at(nFirstCell), blank)) break;
      }

      if (nFirstCell == oFirstCell) {
        firstCell = nFirstCell;
        for (
          ;
          firstCell < newbuf.width() &&
              _cellEqual(oldLine?.at(firstCell), newLine.at(firstCell));
          firstCell++
        ) {}
      } else if (oFirstCell > nFirstCell) {
        firstCell = nFirstCell;
      } else {
        firstCell = oFirstCell;
      }
    } else {
      for (
        ;
        firstCell < newbuf.width() &&
            _cellEqual(newLine.at(firstCell), oldLine?.at(firstCell));
        firstCell++
      ) {}
    }

    if (firstCell >= newbuf.width()) return;

    if (firstCell <= 4 && _hasStyledLeadingPrefix(newLine, firstCell)) {
      firstCell = 0;
    }

    // If skipping a leading blank run would require a longer cursor movement
    // sequence, prefer emitting the blanks.
    //
    // This matches upstream behavior in cases where a scrolled-in blank line
    // is overwritten with content that begins with spaces (see
    // `terminal_renderer_output_test.go` "scroll one line").
    if (firstCell > 0 && _canClearWith(blank)) {
      var allBlank = true;
      var oldBlank = true;
      for (var x = 0; x < firstCell; x++) {
        if (!_cellEqual(newLine.at(x), blank)) {
          allBlank = false;
          break;
        }
        if (!_cellEqual(oldLine?.at(x), blank)) {
          oldBlank = false;
          break;
        }
      }
      if (allBlank && oldBlank && _cellEqual(oldLine?.at(firstCell), blank)) {
        final isRelative = (_flags & _Flag.relativeCursor) != 0;
        final assumeHomeForInlineRelative =
            isRelative &&
            !fullscreen() &&
            _cur.x == -1 &&
            _cur.y == -1 &&
            y == 0;

        if (!assumeHomeForInlineRelative && (_cur.x == -1 || _cur.y == -1)) {
          // If the cursor position is unknown (absolute mode), prefer moving
          // directly to the changed cell rather than printing leading blanks.
        } else {
          final moveCost = assumeHomeForInlineRelative
              ? UvAnsi.cursorForward(firstCell).length
              : _moveCursorSeq(this, newbuf, firstCell, y, false).seq.length;
          if (moveCost > firstCell) {
            firstCell = 0;
          }
        }
      }
    }

    // Find last non-blank in new line.
    var nLast = newbuf.width() - 1;
    final lastBlank = newLine.at(newbuf.width() - 1);
    if (lastBlank != null && _canClearWith(lastBlank)) {
      for (
        ;
        nLast > firstCell && _cellEqual(newLine.at(nLast), lastBlank);
        nLast--
      ) {}
    }

    // Special-case: first differing cell is now blank and the rest of the
    // line can be cleared with EL, so prefer EL over writing a space.
    if (lastBlank != null &&
        _canClearWith(lastBlank) &&
        nLast == firstCell &&
        _cellEqual(newLine.at(firstCell), lastBlank)) {
      _move(newbuf, firstCell, y);
      _clearToEnd(newbuf, lastBlank, true);
      return;
    }

    _move(newbuf, firstCell, y);
    _emitRange(newbuf, newLine.cells, nLast - firstCell + 1, start: firstCell);

    // Clear the rest of the line if it can be cleared with EL.
    if (lastBlank != null && _canClearWith(lastBlank)) {
      // Ensure the cursor is positioned at the first trailing blank cell before
      // issuing EL. Relying on the cursor position after emitting cells is
      // incorrect when wide-cell placeholders or phantom-wrap handling affects
      // cursor advancement, and can leave stale content behind (e.g. when
      // hiding an overlay).
      final width = newbuf.width();
      if (nLast + 1 < width) {
        _move(newbuf, nLast + 1, y);
      }
      _clearToEnd(newbuf, lastBlank, false);
    }

    // Update old line.
    if (oldLine != null) {
      final src = newLine.cells;
      for (var x = firstCell; x < oldLine.length && x < src.length; x++) {
        oldLine.replaceWithClone(x, src[x]);
      }
    }
  }

  void _transformLineRange(
    Buffer newbuf,
    int y,
    int start,
    int end, {
    required bool allowClearToEnd,
  }) {
    if (_curbuf == null || start >= end) return;
    final Line? oldLine = y < _curbuf!.height() ? _curbuf!.line(y) : null;
    final newLine = newbuf.line(y);
    if (newLine == null) return;

    var firstCell = _skipEqualQuadsForward(oldLine, newLine, start, end);
    while (firstCell < end &&
        _cellEqual(newLine.at(firstCell), oldLine?.at(firstCell))) {
      firstCell++;
    }
    if (firstCell >= end) return;

    if (start == 0 &&
        firstCell <= 4 &&
        _hasStyledLeadingPrefix(newLine, firstCell)) {
      firstCell = 0;
    }

    var nLast = _skipEqualQuadsBackward(oldLine, newLine, firstCell, end) - 1;
    while (nLast > firstCell &&
        _cellEqual(newLine.at(nLast), oldLine?.at(nLast))) {
      nLast--;
    }

    final trailingBlank = allowClearToEnd
        ? newLine.at(newbuf.width() - 1)
        : null;
    if (allowClearToEnd &&
        trailingBlank != null &&
        _canClearWith(trailingBlank)) {
      while (nLast > firstCell &&
          _cellEqual(newLine.at(nLast), trailingBlank)) {
        nLast--;
      }
      if (nLast == firstCell &&
          _cellEqual(newLine.at(firstCell), trailingBlank)) {
        _move(newbuf, firstCell, y);
        _clearToEnd(newbuf, trailingBlank, true);
        _syncRenderedRange(oldLine, newLine, firstCell, newbuf.width());
        return;
      }
    }

    _move(newbuf, firstCell, y);
    _emitRange(newbuf, newLine.cells, nLast - firstCell + 1, start: firstCell);

    if (allowClearToEnd &&
        trailingBlank != null &&
        _canClearWith(trailingBlank)) {
      if (nLast + 1 < newbuf.width()) {
        _move(newbuf, nLast + 1, y);
      }
      _clearToEnd(newbuf, trailingBlank, false);
      _syncRenderedRange(oldLine, newLine, firstCell, newbuf.width());
      return;
    }

    _syncRenderedRange(oldLine, newLine, firstCell, nLast + 1);
  }

  int _skipEqualQuadsForward(Line? oldLine, Line newLine, int start, int end) {
    var x = start;
    while (x + 4 <= end) {
      var equal = true;
      for (var i = 0; i < 4; i++) {
        if (!_cellEqual(oldLine?.at(x + i), newLine.at(x + i))) {
          equal = false;
          break;
        }
      }
      if (!equal) break;
      x += 4;
    }
    return x;
  }

  int _skipEqualQuadsBackward(Line? oldLine, Line newLine, int start, int end) {
    var x = end;
    while (x - 4 >= start) {
      var equal = true;
      for (var i = 1; i <= 4; i++) {
        if (!_cellEqual(oldLine?.at(x - i), newLine.at(x - i))) {
          equal = false;
          break;
        }
      }
      if (!equal) break;
      x -= 4;
    }
    return x;
  }

  void _syncRenderedRange(Line? oldLine, Line newLine, int start, int end) {
    if (oldLine == null) return;
    final src = newLine.cells;
    for (var x = start; x < end && x < oldLine.length && x < src.length; x++) {
      oldLine.replaceWithClone(x, src[x]);
    }
  }

  // --- Scroll optimization (ported minimally) -------------------------------

  void _touchLine(Buffer newbuf, int y, int n, {required bool changed}) {
    if (n < 0 || y < 0 || y >= newbuf.height()) return;
    final width = newbuf.width();
    for (var i = y; i < y + n && i < newbuf.height(); i++) {
      if (changed) {
        newbuf.touchLine(0, i, width);
      } else {
        newbuf.clearDirtyLine(i);
      }
    }
  }

  void _scrollBuffer(Buffer b, int n, int top, int bot, Cell blank) {
    if (top < 0 || bot < top || bot >= b.height()) return;
    if (n < 0) {
      final limit = top - n;
      for (var line = bot; line >= limit && line >= top; line--) {
        final src = b.line(line + n)!.cells;
        final dstLine = b.line(line)!;
        for (var x = 0; x < dstLine.length && x < src.length; x++) {
          dstLine.replaceWithClone(x, src[x]);
        }
      }
      for (var line = top; line < limit && line <= bot; line++) {
        b.fillArea(blank, rect(0, line, b.width(), 1));
      }
    } else if (n > 0) {
      final limit = bot - n;
      for (var line = top; line <= limit && line <= bot; line++) {
        final src = b.line(line + n)!.cells;
        final dstLine = b.line(line)!;
        for (var x = 0; x < dstLine.length && x < src.length; x++) {
          dstLine.replaceWithClone(x, src[x]);
        }
      }
      for (var line = bot; line > limit && line >= top; line--) {
        b.fillArea(blank, rect(0, line, b.width(), 1));
      }
    }
    _touchLine(b, top, bot - top + 1, changed: true);
  }

  void _scrollOptimize(Buffer newbuf) {
    // Minimal port of UV scroll optimization sufficient for upstream output tests.
    //
    // `terminal_renderer_hashmap.go`.
    final height = newbuf.height();
    if (_oldnum.length < height) {
      _oldnum = [
        ..._oldnum,
        ...List<int>.filled(height - _oldnum.length, _newIndex),
      ];
    }

    // Fast-path: detect a single inserted blank line (Lip Gloss/UV output test
    // "insert line in the middle"). If we can transform the screen using
    // `IL`, do so and let normal line diffing finish the rest (which should be
    // a no-op when the shift matches).
    final insertedAt = _detectInsertedBlankLine(newbuf);
    if (insertedAt != null) {
      _move(newbuf, 0, insertedAt);
      _buf.write(UvAnsi.insertLine(1));
      _scrollBuffer(_curbuf!, -1, insertedAt, height - 1, _clearBlank());
      return;
    }

    _updateHashmap(this, newbuf);
    if (_hashtab.length < height) return;

    // Pass 1 (scroll up).
    for (var i = 0; i < height;) {
      while (i < height && (_oldnum[i] == _newIndex || _oldnum[i] <= i)) {
        i++;
      }
      if (i >= height) break;
      final shift = _oldnum[i] - i;
      final start = i;
      i++;
      while (i < height && _oldnum[i] != _newIndex && _oldnum[i] - i == shift) {
        i++;
      }
      final end = i - 1 + shift;
      if (!_scrolln(newbuf, shift, start, end, height - 1)) {
        continue;
      }
    }

    // Pass 2 (scroll down).
    for (var i = height - 1; i >= 0;) {
      while (i >= 0 && (_oldnum[i] == _newIndex || _oldnum[i] >= i)) {
        i--;
      }
      if (i < 0) break;
      final shift = _oldnum[i] - i;
      final end = i;
      i--;
      while (i >= 0 && _oldnum[i] != _newIndex && _oldnum[i] - i == shift) {
        i--;
      }
      final start = i + 1 - (-shift);
      if (!_scrolln(newbuf, shift, start, end, height - 1)) {
        continue;
      }
    }
  }

  int? _detectInsertedBlankLine(Buffer newbuf) {
    if (_curbuf == null) return null;
    if (newbuf.width() != _curbuf!.width() ||
        newbuf.height() != _curbuf!.height()) {
      return null;
    }

    final blank = _clearBlank();
    final h = newbuf.height();
    final curHeight = _curbuf?.height() ?? 0;

    for (var i = 0; i < h - 1; i++) {
      final oldLine = i < curHeight ? _curbuf!.line(i) : null;
      final newLine = newbuf.line(i);
      if (oldLine != null &&
          newLine != null &&
          _lineIsBlank(newLine, blank) &&
          !_lineIsBlank(oldLine, blank)) {
        var ok = true;
        for (var j = i; j < h - 1; j++) {
          final cl = j < curHeight ? _curbuf!.line(j) : null;
          final nl = newbuf.line(j + 1);
          if (cl == null || nl == null || !_linesEqual(cl, nl)) {
            ok = false;
            break;
          }
        }
        if (ok) return i;
      }
    }
    return null;
  }

  bool _lineIsBlank(Line line, Cell blank) {
    for (final c in line.cells) {
      if (!_cellEqual(c, blank)) return false;
    }
    return true;
  }

  bool _linesEqual(Line a, Line b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_cellEqual(a.at(i), b.at(i))) return false;
    }
    return true;
  }

  bool _scrolln(Buffer newbuf, int n, int top, int bot, int maxY) {
    final blank = _clearBlank();
    if (n > 0) {
      final ok = _scrollUp(newbuf, n, top, bot, 0, maxY, blank);
      if (!ok) return false;
    } else if (n < 0) {
      final ok = _scrollDown(newbuf, -n, top, bot, 0, maxY, blank);
      if (!ok) return false;
    } else {
      return false;
    }

    _scrollBuffer(_curbuf!, n, top, bot, blank);
    return true;
  }

  bool _scrollUp(
    Buffer newbuf,
    int n,
    int top,
    int bot,
    int minY,
    int maxY,
    Cell blank,
  ) {
    if (n == 1 && top == minY && bot == maxY) {
      _move(newbuf, 0, bot);
      _buf.write('\n');
    } else if (n == 1 && bot == maxY) {
      _move(newbuf, 0, top);
      _buf.write(UvAnsi.deleteLine(1));
    } else if (top == minY && bot == maxY) {
      _move(newbuf, 0, bot);
      if ((_caps & _Cap.su) != 0) {
        _buf.write(UvAnsi.scrollUp(n));
      } else {
        _buf.write(List.filled(n, '\n').join());
      }
    } else if (bot == maxY) {
      _move(newbuf, 0, top);
      _buf.write(UvAnsi.deleteLine(n));
    } else {
      return false;
    }
    return true;
  }

  bool _scrollDown(
    Buffer newbuf,
    int n,
    int top,
    int bot,
    int minY,
    int maxY,
    Cell blank,
  ) {
    if (n == 1 && top == minY && bot == maxY) {
      _move(newbuf, 0, top);
      _buf.write(UvAnsi.reverseIndex);
    } else if (n == 1 && bot == maxY) {
      _move(newbuf, 0, top);
      _buf.write(UvAnsi.insertLine(1));
    } else if (top == minY && bot == maxY) {
      _move(newbuf, 0, top);
      if ((_caps & _Cap.sd) != 0) {
        _buf.write(UvAnsi.scrollDown(n));
      } else {
        _buf.write(List.filled(n, UvAnsi.reverseIndex).join());
      }
    } else if (bot == maxY) {
      _move(newbuf, 0, top);
      _buf.write(UvAnsi.insertLine(n));
    } else {
      return false;
    }
    return true;
  }
}

// --- Hash map / hunks --------------------------------------------------------

final class _HashEntry {
  _HashEntry({
    required this.value,
    required this.oldcount,
    required this.newcount,
    required this.oldindex,
    required this.newindex,
  });

  int value;
  int oldcount;
  int newcount;
  int oldindex;
  int newindex;
}

bool _isSimpleRgbStyle(UvStyle style) =>
    style.attrs == 0 &&
    style.underline == UnderlineStyle.none &&
    style.underlineColor == null &&
    (style.fg == null || style.fg is UvRgb) &&
    (style.bg == null || style.bg is UvRgb);

final List<String> _sgrByte = List<String>.generate(256, (i) => '$i');

final class _FrameArena {
  final List<List<bool>> _boolLists = <List<bool>>[];
  final List<StringBuffer> _stringBuffers = <StringBuffer>[];
  final List<List<_HashEntry>> _hashTables = <List<_HashEntry>>[];
  final List<Int32List> _int32Lists = <Int32List>[];

  int _boolIndex = 0;
  int _stringIndex = 0;
  int _hashIndex = 0;
  int _int32Index = 0;

  void reset() {
    _boolIndex = 0;
    _stringIndex = 0;
    _hashIndex = 0;
    _int32Index = 0;
  }

  List<bool> acquireBoolList(int length) {
    if (_boolIndex >= _boolLists.length) {
      _boolLists.add(List<bool>.filled(length, false));
    }
    final list = _boolLists[_boolIndex++];
    if (list.length < length) {
      final replacement = List<bool>.filled(length, false);
      _boolLists[_boolIndex - 1] = replacement;
      return replacement;
    }
    list.fillRange(0, length, false);
    return list;
  }

  StringBuffer acquireStringBuffer() {
    if (_stringIndex >= _stringBuffers.length) {
      _stringBuffers.add(StringBuffer());
    }
    final buffer = _stringBuffers[_stringIndex++];
    buffer.clear();
    return buffer;
  }

  List<_HashEntry> acquireHashTable(int length) {
    if (_hashIndex >= _hashTables.length) {
      _hashTables.add(_newHashTable(length));
    }
    var table = _hashTables[_hashIndex++];
    if (table.length < length) {
      table = _newHashTable(length);
      _hashTables[_hashIndex - 1] = table;
    } else {
      for (var i = 0; i < length; i++) {
        final entry = table[i];
        entry.value = 0;
        entry.oldcount = 0;
        entry.newcount = 0;
        entry.oldindex = 0;
        entry.newindex = 0;
      }
    }
    return table;
  }

  Int32List acquireInt32List(int length) {
    if (_int32Index >= _int32Lists.length) {
      _int32Lists.add(Int32List(length));
    }
    var list = _int32Lists[_int32Index++];
    if (list.length < length) {
      list = Int32List(length);
      _int32Lists[_int32Index - 1] = list;
    } else {
      list.fillRange(0, length, 0);
    }
    return list;
  }

  static List<_HashEntry> _newHashTable(int length) =>
      List<_HashEntry>.generate(
        length,
        (_) => _HashEntry(
          value: 0,
          oldcount: 0,
          newcount: 0,
          oldindex: 0,
          newindex: 0,
        ),
      );
}

const int _newIndex = -1;

int _hashLine(Line l) {
  return l.renderHash();
}

void _updateHashmap(UvTerminalRenderer s, Buffer newbuf) {
  final height = newbuf.height();
  final curHeight = s._curbuf?.height() ?? 0;

  if (s._oldhash.length == height && s._newhash.length == height) {
    for (var i = 0; i < height; i++) {
      if (newbuf.touched.isEmpty || newbuf.touched[i] != null) {
        final oldLine = i < curHeight ? s._curbuf!.line(i) : null;
        s._oldhash[i] = oldLine != null ? _hashLine(oldLine) : 0;
        s._newhash[i] = _hashLine(newbuf.line(i)!);
      }
    }
  } else {
    s._oldhash = List<int>.filled(height, 0);
    s._newhash = List<int>.filled(height, 0);
    for (var i = 0; i < height; i++) {
      final oldLine = i < curHeight ? s._curbuf!.line(i) : null;
      s._oldhash[i] = oldLine != null ? _hashLine(oldLine) : 0;
      s._newhash[i] = _hashLine(newbuf.line(i)!);
    }
  }

  final tab = s._arena.acquireHashTable((height + 1) * 2);

  for (var i = 0; i < height; i++) {
    final hashval = s._oldhash[i];
    var idx = 0;
    while (idx < tab.length && tab[idx].value != 0) {
      if (tab[idx].value == hashval) break;
      idx++;
    }
    tab[idx].value = hashval;
    tab[idx].oldcount++;
    tab[idx].oldindex = i;
  }

  for (var i = 0; i < height; i++) {
    final hashval = s._newhash[i];
    var idx = 0;
    while (idx < tab.length && tab[idx].value != 0) {
      if (tab[idx].value == hashval) break;
      idx++;
    }
    tab[idx].value = hashval;
    tab[idx].newcount++;
    tab[idx].newindex = i;
    s._oldnum[i] = _newIndex;
  }

  for (var i = 0; i < tab.length && tab[i].value != 0; i++) {
    final h = tab[i];
    if (h.oldcount == 1 && h.newcount == 1 && h.oldindex != h.newindex) {
      s._oldnum[h.newindex] = h.oldindex;
    }
  }

  s._hashtab = tab;
}

// --- Cursor movement sequences ----------------------------------------------

// NOTE: environment variable lookups are handled by [Environ].

int _xtermCaps(String termtype) {
  final parts = termtype.split('-');
  if (parts.isEmpty || parts[0].isEmpty) return _Cap.noCaps;

  switch (parts[0]) {
    case 'contour':
    case 'foot':
    case 'ghostty':
    case 'kitty':
    case 'rio':
    case 'st':
    case 'tmux':
    case 'wezterm':
      return _Cap.allCaps;
    case 'xterm':
      if (parts.length > 1 &&
          (parts[1] == 'ghostty' || parts[1] == 'kitty' || parts[1] == 'rio')) {
        return _Cap.allCaps;
      }
      // Exclude HPA, CHT and REP by default for xterm-like compatibility.
      return _Cap.allCaps & ~_Cap.hpa & ~_Cap.cht & ~_Cap.rep;
    case 'alacritty':
      return _Cap.allCaps & ~_Cap.cht;
    case 'screen':
      return _Cap.allCaps & ~_Cap.rep;
    case 'linux':
      return _Cap.vpa | _Cap.cha | _Cap.hpa | _Cap.ech | _Cap.ich;
    default:
      return _Cap.noCaps;
  }
}

cp.Profile _detectProfile(List<String> env, bool? isTty, bool isWindows) {
  final m = <String, String>{};
  for (final e in env) {
    final idx = e.indexOf('=');
    if (idx < 0) continue;
    m[e.substring(0, idx)] = e.substring(idx + 1);
  }

  final forceTty = isTty ?? _parseBool(m['TTY_FORCE']);
  // UvTerminalRenderer can be used with arbitrary sinks; default to non-TTY
  // unless explicitly forced.
  return cp_detect.detect(isTty: forceTty, env: m, isWindows: isWindows);
}

bool _parseBool(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return false;
  return switch (v) {
    '1' || 't' || 'true' || 'y' || 'yes' || 'on' => true,
    _ => false,
  };
}

bool _notLocal(int cols, int fx, int fy, int tx, int ty) {
  const longDist = 7;
  return (tx > longDist) &&
      (tx < cols - 1 - longDist) &&
      ((ty - fy).abs() + (tx - fx).abs() > longDist);
}

String? _overwriteMoveSeq(
  UvTerminalRenderer s,
  Buffer? newbuf,
  int fx,
  int fy,
  int tx,
  int ty,
) {
  if (newbuf == null || fy != ty || tx <= fx) return null;
  if (ty < 0 || ty >= newbuf.height()) return null;

  final line = newbuf.line(ty);
  if (line == null) return null;
  if (tx >= line.cells.length) return null;
  if (tx - 1 >= line.cells.length - 1) return null;

  final seq = s._arena.acquireStringBuffer();
  for (var x = fx; x < tx; x++) {
    if (x < 0 || x >= line.cells.length) return null;

    final cell = line.cells[x];
    if (cell.width != 1) return null;
    if (cell.content.isEmpty) return null;
    if (cell.content.trim().isEmpty) return null;
    if (stringWidth(cell.content) != 1) return null;
    if (cell.content.contains('\x1b') ||
        cell.content.contains('\n') ||
        cell.content.contains('\r')) {
      return null;
    }

    final style = style_ops.convertStyle(cell.style, s._profile);
    final link = style_ops.convertLink(cell.link, s._profile);
    if (style != s._cur.style || link != s._cur.link) return null;

    seq.write(cell.content);
  }

  return seq.toString();
}

String? _overwritableCellText(
  UvTerminalRenderer s,
  Buffer? newbuf,
  int x,
  int y,
) {
  if (newbuf == null || y < 0 || y >= newbuf.height()) return null;
  final line = newbuf.line(y);
  if (line == null || x < 0 || x >= line.cells.length) return null;

  final cell = line.cells[x];
  if (cell.width != 1) return null;
  if (cell.content.isEmpty) return null;
  if (cell.content.trim().isEmpty) return null;
  if (stringWidth(cell.content) != 1) return null;
  if (cell.content.contains('\n') ||
      cell.content.contains('\r') ||
      cell.content.contains('\x1b')) {
    return null;
  }

  final style = style_ops.convertStyle(cell.style, s._profile);
  final link = style_ops.convertLink(cell.link, s._profile);
  if (style != s._cur.style || link != s._cur.link) return null;
  return cell.content;
}

String? _overwriteMoveDpSeq(
  UvTerminalRenderer s,
  Buffer? newbuf,
  int fx,
  int fy,
  int tx,
  int ty,
  bool useTabs,
  bool useBackspace,
) {
  if (newbuf == null || fy != ty || tx <= fx) return null;
  final line = newbuf.line(ty);
  if (line == null) return null;
  if (tx >= line.cells.length) return null;
  if (tx - 1 >= line.cells.length - 1) return null;
  final span = tx - fx;
  final costs = List<int>.filled(span + 1, 0);
  final seqs = List<String>.filled(span + 1, '');

  costs[span] = 0;
  seqs[span] = '';
  for (var pos = tx - 1; pos >= fx; pos--) {
    final idx = pos - fx;
    final direct = _relativeCursorMove(
      s,
      newbuf,
      pos,
      fy,
      tx,
      ty,
      false,
      useTabs,
      useBackspace,
    ).seq;
    var bestCost = direct.length;
    var bestSeq = direct;

    final overwrite = _overwritableCellText(s, newbuf, pos, ty);
    if (overwrite != null) {
      final candidateCost = overwrite.length + costs[idx + 1];
      if (candidateCost < bestCost) {
        bestCost = candidateCost;
        bestSeq = '$overwrite${seqs[idx + 1]}';
      }
    }

    costs[idx] = bestCost;
    seqs[idx] = bestSeq;
  }

  return seqs[0];
}

/// Returns the same-row DP overwrite/move sequence used by the renderer.
///
/// This exists for regression tests that validate cursor-planning behavior.
String? debugDpOverwriteMoveSeq(
  UvTerminalRenderer renderer,
  Buffer newbuf,
  int fx,
  int fy,
  int tx,
  int ty, {
  bool useTabs = false,
  bool useBackspace = false,
}) {
  return _overwriteMoveDpSeq(
    renderer,
    newbuf,
    fx,
    fy,
    tx,
    ty,
    useTabs,
    useBackspace,
  );
}

/// Returns the direct relative move sequence used as the DP baseline.
String debugDirectRelativeMoveSeq(
  UvTerminalRenderer renderer,
  Buffer newbuf,
  int fx,
  int fy,
  int tx,
  int ty, {
  bool useTabs = false,
  bool useBackspace = false,
}) {
  return _relativeCursorMove(
    renderer,
    newbuf,
    fx,
    fy,
    tx,
    ty,
    false,
    useTabs,
    useBackspace,
  ).seq;
}

({String seq, int scrollHeight}) _relativeCursorMove(
  UvTerminalRenderer s,
  Buffer? newbuf,
  int fx,
  int fy,
  int tx,
  int ty,
  bool overwrite,
  bool useTabs,
  bool useBackspace,
) {
  final seq = s._arena.acquireStringBuffer();
  var scrollHeight = 0;

  if (ty != fy) {
    var yseq = '';
    if ((s._caps & _Cap.vpa) != 0 && (s._flags & _Flag.relativeCursor) == 0) {
      yseq = UvAnsi.verticalPositionAbsolute(ty + 1);
    }

    if (ty > fy) {
      final n = ty - fy;
      final cud = UvAnsi.cursorDown(n);
      if (yseq.isEmpty || cud.length < yseq.length) yseq = cud;

      final shouldScroll =
          (s._flags & _Flag.fullscreen) == 0 && ty > s._scrollHeight;
      if (shouldScroll || n < yseq.length) {
        yseq = List.filled(n, '\n').join();
        scrollHeight = ty;
        if ((s._flags & _Flag.mapNewline) != 0) {
          fx = 0;
        }
      }
    } else {
      final n = fy - ty;
      final cuu = UvAnsi.cursorUp(n);
      if (yseq.isEmpty || cuu.length < yseq.length) yseq = cuu;
      // For a single-line upward move, `RI` can be shorter than `CUU`.
      // Use it only when we're not at the top margin.
      if (n == 1 && fy > 0 && UvAnsi.reverseIndex.length < yseq.length) {
        yseq = UvAnsi.reverseIndex;
      }
    }

    seq.write(yseq);
    fy = ty;
  }

  if (tx != fx) {
    var xseq = '';
    if ((s._flags & _Flag.relativeCursor) == 0) {
      if ((s._caps & _Cap.hpa) != 0) {
        xseq = UvAnsi.horizontalPositionAbsolute(tx + 1);
      } else if ((s._caps & _Cap.cha) != 0) {
        xseq = UvAnsi.horizontalPositionAbsolute(tx + 1);
      }
    }

    if (tx > fx) {
      var n = tx - fx;
      if (useTabs && s._tabs != null) {
        var tabs = 0;
        var col = fx;
        while (s._tabs!.next(col) <= tx) {
          final next = s._tabs!.next(col);
          tabs++;
          if (next == col || next >= s._tabs!.getWidth() - 1) break;
          col = next;
        }

        if (tabs > 0) {
          seq.write(List.filled(tabs, '\t').join());
          n = tx - col;
          fx = col;
        }
      }

      final cuf = UvAnsi.cursorForward(n);
      if (xseq.isEmpty || cuf.length < xseq.length) xseq = cuf;
      if (overwrite) {
        final overwriteSeq = _overwriteMoveSeq(s, newbuf, fx, fy, tx, ty);
        if (overwriteSeq != null &&
            (xseq.isEmpty || overwriteSeq.length < xseq.length)) {
          xseq = overwriteSeq;
        }
      }
    } else {
      var n = fx - tx;
      if (useTabs && s._tabs != null && (s._caps & _Cap.cbt) != 0) {
        var col = fx;
        var cbt = 0;
        while (s._tabs!.prev(col) >= tx) {
          final prev = s._tabs!.prev(col);
          col = prev;
          cbt++;
          if (col == s._tabs!.prev(col) || col <= 0) break;
        }
        if (cbt > 0) {
          seq.write(UvAnsi.cursorBackwardTab(cbt));
          n = col - tx;
        }
      }

      final cub = UvAnsi.cursorBackward(n);
      if (xseq.isEmpty || cub.length < xseq.length) xseq = cub;
      if (useBackspace && n < xseq.length) {
        xseq = List.filled(n, '\b').join();
      }
    }

    seq.write(xseq);
  }

  return (seq: seq.toString(), scrollHeight: scrollHeight);
}

({String seq, int scrollHeight}) _moveCursorSeq(
  UvTerminalRenderer s,
  Buffer? newbuf,
  int x,
  int y,
  bool overwrite,
) {
  final fx = s._cur.x;
  final fy = s._cur.y;

  var seq = '';
  var scrollHeight = 0;

  if ((s._flags & _Flag.relativeCursor) == 0) {
    var width = -1;
    if (s._tabs != null) width = s._tabs!.getWidth();
    if (newbuf != null && width == -1) width = newbuf.width();
    seq = UvAnsi.cursorPosition(x + 1, y + 1);
    if (fx == -1 || fy == -1 || width == -1 || _notLocal(width, fx, fy, x, y)) {
      return (seq: seq, scrollHeight: 0);
    }
  }

  var trials = 0;
  if ((s._caps & _Cap.ht) != 0) trials |= 2;
  if ((s._caps & _Cap.bs) != 0) trials |= 1;

  for (var i = 0; i <= trials; i++) {
    if ((i & ~trials) != 0) continue;
    final useTabs = (i & 2) != 0;
    final useBackspace = (i & 1) != 0;

    final m1 = _relativeCursorMove(
      s,
      newbuf,
      fx,
      fy,
      x,
      y,
      overwrite,
      useTabs,
      useBackspace,
    );
    if ((i == 0 && seq.isEmpty) || m1.seq.length < seq.length) {
      seq = m1.seq;
      scrollHeight = scrollHeight > m1.scrollHeight
          ? scrollHeight
          : m1.scrollHeight;
    }

    final m2 = _relativeCursorMove(
      s,
      newbuf,
      0,
      fy,
      x,
      y,
      overwrite,
      useTabs,
      useBackspace,
    );
    final nseq2 = '\r${m2.seq}';
    if (nseq2.length < seq.length) {
      seq = nseq2;
      scrollHeight = scrollHeight > m2.scrollHeight
          ? scrollHeight
          : m2.scrollHeight;
    }

    if ((s._flags & _Flag.relativeCursor) == 0) {
      final m3 = _relativeCursorMove(
        s,
        newbuf,
        0,
        0,
        x,
        y,
        overwrite,
        useTabs,
        useBackspace,
      );
      final nseq3 = '${UvAnsi.cursorHomePosition}${m3.seq}';
      if (nseq3.length < seq.length) {
        seq = nseq3;
        scrollHeight = scrollHeight > m3.scrollHeight
            ? scrollHeight
            : m3.scrollHeight;
      }
    }
  }

  return (seq: seq, scrollHeight: scrollHeight);
}

/// Cache: the same buffer object is reused across frames and its graphics
/// content rarely changes.  Avoids re-scanning every cell on every frame.
Buffer? _lastSixelCheckBuffer;
bool _lastSixelCheckResult = false;

bool _bufferContainsSixelDisplay(Buffer buffer) {
  if (_lastSixelCheckBuffer == buffer) return _lastSixelCheckResult;
  _lastSixelCheckBuffer = buffer;
  _lastSixelCheckResult = _scanBufferForSixel(buffer);
  return _lastSixelCheckResult;
}

bool _scanBufferForSixel(Buffer buffer) {
  for (var y = 0; y < buffer.height(); y++) {
    final line = buffer.line(y);
    if (line == null) continue;
    for (final cell in line.cells) {
      // Printable ASCII cells can never contain terminal graphics sequences.
      if (cell.asciiCodeUnit != null) continue;
      if (!terminal_graphics.mayContainTerminalGraphics(cell.content)) {
        continue;
      }
      if (terminal_graphics.containsSixelDisplay(cell.content)) return true;
    }
  }
  return false;
}

final class _DeferredRetainedGraphic {
  const _DeferredRetainedGraphic(this.x, this.y, this.content, this.width);

  final int x;
  final int y;
  final String content;
  final int width;
}

final class _DeferredDisplayPayload {
  const _DeferredDisplayPayload(this.x, this.y, this.content, this.width);

  final int x;
  final int y;
  final String content;
  final int width;
}

final class _RendererScreen implements Screen {
  _RendererScreen(this.renderer);
  final UvTerminalRenderer renderer;

  @override
  Rectangle bounds() => rect(0, 0, renderer.width(), renderer.height());

  @override
  Cell? cellAt(int x, int y) => null;

  @override
  void setCell(int x, int y, Cell? cell) {
    renderer._move(null, x, y);
    renderer._putCell(null, cell);
  }

  @override
  WidthMethod widthMethod() => WidthMethod.grapheme;
}
