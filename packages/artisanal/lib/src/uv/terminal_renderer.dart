/// Diff-based terminal renderer for UV buffers with performance metrics.
///
/// [UvTerminalRenderer] computes minimal ANSI/OSC updates from a source
/// [Buffer], tracking cursor, clears, scroll-optimization, and capability
/// features detected via [TerminalCapabilities]. Use [RenderMetrics] to
/// monitor throughput, frame times, and render durations.
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final sink = StringBuffer();
/// final renderer = UvTerminalRenderer(sink);
/// final buf = Buffer.create(10, 3);
/// buf.line(1)?.set(2, Cell(content: '★'));
/// renderer.render(buf);
/// renderer.flush();
/// ```
library;
import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;

import 'ansi.dart';
import 'buffer.dart';
import 'cell.dart';
import 'drawable.dart';
import 'environ.dart';
import 'geometry.dart';
import 'screen.dart';
import 'style_ops.dart' as style_ops;
import 'tabstop.dart';
import '../unicode/width.dart';

import 'package:artisanal/src/colorprofile/detect.dart' as cp_detect;
import 'package:artisanal/src/colorprofile/profile.dart' as cp;

/// Tracks render performance metrics including FPS, frame times, and render durations.
///
/// This class maintains a rolling window of frame samples to calculate
/// accurate averages and detect performance issues.
final class RenderMetrics {
  /// Creates a new [RenderMetrics] instance.
  ///
  /// [sampleSize] determines how many frames are kept for averaging (default: 60).
  RenderMetrics({int sampleSize = 60}) : _sampleSize = sampleSize;

  final int _sampleSize;

  // Frame timing
  final List<Duration> _frameTimes = [];
  final List<Duration> _renderTimes = [];
  DateTime? _lastFrameTime;
  int _frameCount = 0;
  int _skippedFrames = 0;

  // Render timing (how long render() takes)
  Stopwatch? _renderStopwatch;
  Duration _lastRenderDuration = Duration.zero;

  /// Total number of frames rendered since creation or last reset.
  int get frameCount => _frameCount;

  /// Number of frames that were skipped (no changes to render).
  int get skippedFrames => _skippedFrames;

  /// Duration of the last frame (time between renders).
  Duration get lastFrameTime =>
      _frameTimes.isEmpty ? Duration.zero : _frameTimes.last;

  /// Duration of the last render() call.
  Duration get lastRenderDuration => _lastRenderDuration;

  /// Average frame time over the sample window.
  Duration get averageFrameTime {
    if (_frameTimes.isEmpty) return Duration.zero;
    final total = _frameTimes.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ _frameTimes.length);
  }

  /// Average render duration over the sample window.
  Duration get averageRenderDuration {
    if (_renderTimes.isEmpty) return Duration.zero;
    final total = _renderTimes.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ _renderTimes.length);
  }

  /// Current FPS based on the last frame time.
  double get currentFps {
    final ft = lastFrameTime;
    if (ft.inMicroseconds == 0) return 0.0;
    return 1000000.0 / ft.inMicroseconds;
  }

  /// Average FPS over the sample window.
  double get averageFps {
    final avg = averageFrameTime;
    if (avg.inMicroseconds == 0) return 0.0;
    return 1000000.0 / avg.inMicroseconds;
  }

  /// Minimum FPS in the sample window (slowest frame).
  double get minFps {
    if (_frameTimes.isEmpty) return 0.0;
    final maxTime = _frameTimes.reduce(
      (a, b) => a.inMicroseconds > b.inMicroseconds ? a : b,
    );
    if (maxTime.inMicroseconds == 0) return 0.0;
    return 1000000.0 / maxTime.inMicroseconds;
  }

  /// Maximum FPS in the sample window (fastest frame).
  double get maxFps {
    if (_frameTimes.isEmpty) return 0.0;
    final minTime = _frameTimes.reduce(
      (a, b) => a.inMicroseconds < b.inMicroseconds ? a : b,
    );
    if (minTime.inMicroseconds == 0) return double.infinity;
    return 1000000.0 / minTime.inMicroseconds;
  }

  /// Percentage of time spent in render() vs total frame time.
  double get renderTimePercentage {
    final avg = averageFrameTime.inMicroseconds;
    if (avg == 0) return 0.0;
    return (averageRenderDuration.inMicroseconds / avg) * 100.0;
  }

  /// Call this at the start of each frame (before render).
  void beginFrame() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!);
      _frameTimes.add(frameTime);
      if (_frameTimes.length > _sampleSize) {
        _frameTimes.removeAt(0);
      }
    }
    _lastFrameTime = now;

    _renderStopwatch = Stopwatch()..start();
  }

  /// Call this at the end of render().
  void endFrame({bool skipped = false}) {
    _frameCount++;
    if (skipped) {
      _skippedFrames++;
    }

    if (_renderStopwatch != null) {
      _renderStopwatch!.stop();
      _lastRenderDuration = _renderStopwatch!.elapsed;
      _renderTimes.add(_lastRenderDuration);
      if (_renderTimes.length > _sampleSize) {
        _renderTimes.removeAt(0);
      }
    }
  }

  /// Resets all metrics to initial state.
  void reset() {
    _frameTimes.clear();
    _renderTimes.clear();
    _lastFrameTime = null;
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
// - `third_party/ultraviolet/terminal_renderer.go`
// - `third_party/ultraviolet/terminal_renderer_hardscroll.go`
// - `third_party/ultraviolet/terminal_renderer_hashmap.go`

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
final class UvTerminalRenderer {
  // Capability bits (public for parity tests).
  static const int capVpa = _Cap.vpa;
  static const int capHpa = _Cap.hpa;
  static const int capCha = _Cap.cha;
  static const int capCht = _Cap.cht;
  static const int capCbt = _Cap.cbt;
  static const int capRep = _Cap.rep;
  static const int capEch = _Cap.ech;
  static const int capIch = _Cap.ich;
  static const int capSd = _Cap.sd;
  static const int capSu = _Cap.su;
  static const int capHt = _Cap.ht;
  static const int capBs = _Cap.bs;

  UvTerminalRenderer(this._writer, {List<String>? env, bool? isTty})
    : _env = env ?? const [],
      _term = Environ(env ?? const []).getenv('TERM'),
      _caps = _xtermCaps(Environ(env ?? const []).getenv('TERM')) {
    _cur = _Cursor(x: -1, y: -1);
    _saved = _cur.clone();
    _profile = _detectProfile(_env, isTty);
    _screen = _RendererScreen(this);
  }

  final StringSink _writer;
  final List<String> _env;
  final String _term;

  final StringBuffer _buf = StringBuffer();
  Buffer? _curbuf;
  late final Screen _screen;

  /// Render performance metrics (FPS, frame times, render durations).
  ///
  /// Access this to monitor rendering performance:
  /// ```dart
  /// print(renderer.metrics.averageFps);
  /// print(renderer.metrics.summary());
  /// ```
  final RenderMetrics metrics = RenderMetrics();

  int width() => _curbuf?.width() ?? 0;
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

  void setScrollOptim(bool v) {
    if (v) {
      _flags |= _Flag.scrollOptim;
    } else {
      _flags &= ~_Flag.scrollOptim;
    }
  }

  void setFullscreen(bool v) {
    if (v) {
      _flags |= _Flag.fullscreen;
    } else {
      _flags &= ~_Flag.fullscreen;
    }
  }

  bool fullscreen() => (_flags & _Flag.fullscreen) != 0;

  void setRelativeCursor(bool v) {
    if (v) {
      _flags |= _Flag.relativeCursor;
    } else {
      _flags &= ~_Flag.relativeCursor;
    }
  }

  void setMapNewline(bool v) {
    if (v) {
      _flags |= _Flag.mapNewline;
    } else {
      _flags &= ~_Flag.mapNewline;
    }
  }

  void saveCursor() {
    _saved = _cur.clone();
  }

  void restoreCursor() {
    _cur = _saved.clone();
  }

  void enterAltScreen() {
    saveCursor();
    _buf.write(UvAnsi.setModeAltScreenSaveCursor);
    setFullscreen(true);
    setRelativeCursor(false);
    erase();
  }

  void exitAltScreen() {
    erase();
    setRelativeCursor(true);
    setFullscreen(false);
    _buf.write(UvAnsi.resetModeAltScreenSaveCursor);
    restoreCursor();
  }

  void hideCursor() {
    _buf.write(UvAnsi.hideCursor);
  }

  void showCursor() {
    _buf.write(UvAnsi.showCursor);
  }

  void enableMouseAllEvents() {
    _buf.write(UvAnsi.enableMouseAllEvents);
    _buf.write(UvAnsi.enableMouseSgr);
  }

  void disableMouseAllEvents() {
    _buf.write(UvAnsi.disableMouseAllEvents);
    _buf.write(UvAnsi.disableMouseSgr);
  }

  void enableBracketedPaste() {
    _buf.write(UvAnsi.enableBracketedPaste);
  }

  void disableBracketedPaste() {
    _buf.write(UvAnsi.disableBracketedPaste);
  }

  void enableFocusReporting() {
    _buf.write(UvAnsi.enableFocusReporting);
  }

  void disableFocusReporting() {
    _buf.write(UvAnsi.disableFocusReporting);
  }

  /// Pushes keyboard enhancements (Kitty Keyboard Protocol).
  void pushKeyboardEnhancements(int flags) {
    _buf.write('\x1b[>${flags}u');
  }

  /// Pops keyboard enhancements (Kitty Keyboard Protocol).
  void popKeyboardEnhancements() {
    _buf.write('\x1b[<u');
  }

  /// Queries keyboard enhancements (Kitty Keyboard Protocol).
  void queryKeyboardEnhancements() {
    _buf.write('\x1b[?u');
  }

  /// Queries primary device attributes.
  void queryPrimaryDeviceAttributes() {
    _buf.write('\x1b[?c');
  }

  /// Queries Kitty Graphics support.
  void queryKittyGraphics() {
    // Use a random id=31 to query support.
    _buf.write('\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\');
  }

  /// Queries the terminal background color.
  void queryBackgroundColor() {
    _buf.write('\x1b]11;?\x1b\\');
  }

  /// Queries a color from the terminal palette.
  void queryColorPalette(int index) {
    _buf.write('\x1b]4;$index;?\x1b\\');
  }

  void erase() {
    _clear = true;
  }

  int buffered() => _buf.length;

  cp.Profile get profile => _profile;
  int get capabilities => _caps;
  bool get isRelativeCursorEnabled => (_flags & _Flag.relativeCursor) != 0;
  bool get isFullscreenEnabled => (_flags & _Flag.fullscreen) != 0;

  void flush() {
    final out = _buf.toString();
    if (out.isNotEmpty) {
      final logger = _logger;
      if (logger != null) {
        logger('output: ${jsonEncode(out)}');
      }
      _writer.write(out);
      _buf.clear();
    }
  }

  void setLogger(void Function(String message)? logger) {
    _logger = logger;
  }

  void setColorProfile(cp.Profile profile) {
    _profile = profile;
  }

  int _touched(Buffer buf) {
    if (buf.touched.isEmpty) return buf.height();
    var n = 0;
    for (final ch in buf.touched) {
      if (ch != null) n++;
    }
    return n;
  }

  int touched(Buffer buf) => _touched(buf);

  void resize(int width, int height) {
    _tabs?.resize(width);
    _scrollHeight = 0;
    // Important: resizing MUST NOT implicitly clear the screen. Upstream UV
    // keeps resize side-effect free; callers explicitly call `erase()` when
    // they want a full clear (parity tests depend on this).
  }

  ({int x, int y}) position() => (x: _cur.x, y: _cur.y);

  void setPosition(int x, int y) {
    _cur.x = x;
    _cur.y = y;
  }

  int writeString(String s) {
    _buf.write(s);
    return s.length;
  }

  int write(List<int> bytes) {
    _buf.write(String.fromCharCodes(bytes));
    return bytes.length;
  }

  void moveTo(int x, int y) {
    _move(null, x, y);
  }

  void redraw(Buffer newbuf) {
    erase();
    render(newbuf);
  }

  void setBackspace(bool v) {
    if (v) {
      _caps |= _Cap.bs;
    } else {
      _caps &= ~_Cap.bs;
    }
  }

  void setHasTab(bool v) {
    if (v) {
      _caps |= _Cap.ht;
    } else {
      _caps &= ~_Cap.ht;
    }
  }

  void setTabStops(int width) {
    if (width < 0 || _term.startsWith('linux')) {
      _caps &= ~_Cap.ht;
      _tabs = null;
      return;
    }
    _caps |= _Cap.ht;
    _tabs = TabStops.defaults(width);
  }

  void prependString(Buffer newbuf, String str) {
    // Upstream: `third_party/ultraviolet/terminal_renderer.go` (`PrependString`).
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

  void render(Buffer newbuf) {
    metrics.beginFrame();

    final touchedLines = _touched(newbuf);
    if (!_clear && touchedLines == 0) {
      metrics.endFrame(skipped: true);
      return;
    }

    _curbuf ??= Buffer.create(newbuf.width(), newbuf.height());

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
          !Platform.isWindows) {
        _scrollOptimize(newbuf);
      }

      var nonEmpty = fullscreen()
          ? (curHeight < newHeight ? curHeight : newHeight)
          : newHeight;
      nonEmpty = _clearBottom(newbuf, nonEmpty);
      for (var i = 0; i < nonEmpty && i < newHeight; i++) {
        final ld = (newbuf.touched.isEmpty || i >= newbuf.touched.length)
            ? null
            : newbuf.touched[i];
        final shouldTransform =
            newbuf.touched.isEmpty ||
            i >= newbuf.touched.length ||
            (ld != null && (ld.firstCell != -1 || ld.lastCell != -1));
        if (shouldTransform) {
          _transformLine(newbuf, i);
        }
        if (i < newbuf.touched.length) {
          newbuf.touched[i] = const LineData(firstCell: -1, lastCell: -1);
        }
        if (i < _curbuf!.touched.length) {
          _curbuf!.touched[i] = const LineData(firstCell: -1, lastCell: -1);
        }
      }
    }

    if (!fullscreen() && _scrollHeight < newHeight - 1) {
      _move(newbuf, 0, newHeight - 1);
    }

    // Sync touched markers.
    newbuf.touched = List<LineData?>.generate(
      newHeight,
      (_) => const LineData(firstCell: -1, lastCell: -1),
    );
    _curbuf!.touched = List<LineData?>.generate(
      _curbuf!.height(),
      (_) => const LineData(firstCell: -1, lastCell: -1),
    );

    if (curWidth != newWidth || curHeight != newHeight) {
      _curbuf!.resize(newWidth, newHeight);
      final start = curHeight <= 0 ? 0 : curHeight - 1;
      for (var i = start; i < newHeight; i++) {
        final srcLine = newbuf.line(i);
        final dstLine = _curbuf!.line(i);
        if (srcLine != null && dstLine != null) {
          final src = srcLine.cells;
          final dst = dstLine.cells;
          for (var x = 0; x < dst.length && x < src.length; x++) {
            dst[x] = src[x].clone();
          }
        }
      }
    }

    // Reset pen after rendering to avoid style/link bleed.
    _updatePen(null);

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
    // Upstream: `third_party/ultraviolet/terminal_renderer.go` (`updatePen`),
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

    final newStyle = style_ops.convertStyle(cell.style, _profile);
    final newLink = style_ops.convertLink(cell.link, _profile);
    final oldStyle = style_ops.convertStyle(_cur.style, _profile);
    final oldLink = style_ops.convertLink(_cur.link, _profile);

    if (newStyle != oldStyle) {
      var seq = style_ops.styleDiff(oldStyle, newStyle);
      if (newStyle.isZero && seq.length > UvAnsi.resetStyle.length) {
        seq = UvAnsi.resetStyle;
      }
      _buf.write(seq);
      _cur.style = cell.style;
    }
    if (newLink != oldLink) {
      _buf.write(UvAnsi.setHyperlink(newLink.url, newLink.params));
      _cur.link = cell.link;
    }
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
      final cellWidth = (rawWidth == null || rawWidth <= 0) ? 1 : rawWidth;
      _buf.write(cell?.content ?? ' ');

      _cur.x += cellWidth;
    }

    if (_cur.x >= (newbuf?.width() ?? width())) {
      _atPhantom = true;
    }
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
    if (c.width != 1 || c.content != ' ') return false;
    final style = c.style;
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
      _transformLine(newbuf, i);
    }
  }

  void _emitRange(Buffer newbuf, List<Cell> line, int n) {
    for (var i = 0; i < n; i++) {
      _putCell(newbuf, line[i]);
    }
  }

  void _transformLine(Buffer newbuf, int y) {
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

    // If skipping a leading blank run would require a longer cursor movement
    // sequence, prefer emitting the blanks.
    //
    // This matches upstream behavior in cases where a scrolled-in blank line
    // is overwritten with content that begins with spaces (see
    // `terminal_renderer_output_test.go` "scroll one line").
    if (firstCell > 0 && _canClearWith(blank)) {
      var allBlank = true;
      for (var x = 0; x < firstCell; x++) {
        if (!_cellEqual(newLine.at(x), blank)) {
          allBlank = false;
          break;
        }
      }
      if (allBlank) {
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
    _emitRange(newbuf, newLine.cells.sublist(firstCell), nLast - firstCell + 1);

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
      final dst = oldLine.cells;
      final src = newLine.cells;
      for (var x = firstCell; x < dst.length && x < src.length; x++) {
        dst[x] = src[x].clone();
      }
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
        newbuf.touched[i] = null;
      }
    }
  }

  void _scrollBuffer(Buffer b, int n, int top, int bot, Cell blank) {
    if (top < 0 || bot < top || bot >= b.height()) return;
    if (n < 0) {
      final limit = top - n;
      for (var line = bot; line >= limit && line >= top; line--) {
        final dst = b.line(line)!.cells;
        final src = b.line(line + n)!.cells;
        for (var x = 0; x < dst.length && x < src.length; x++) {
          dst[x] = src[x].clone();
        }
      }
      for (var line = top; line < limit && line <= bot; line++) {
        b.fillArea(blank, rect(0, line, b.width(), 1));
      }
    } else if (n > 0) {
      final limit = bot - n;
      for (var line = top; line <= limit && line <= bot; line++) {
        final dst = b.line(line)!.cells;
        final src = b.line(line + n)!.cells;
        for (var x = 0; x < dst.length && x < src.length; x++) {
          dst[x] = src[x].clone();
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
    // Upstream: `third_party/ultraviolet/terminal_renderer_hardscroll.go` and
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

const int _newIndex = -1;

int _fnv1a64(String s) {
  // 64-bit FNV-1a.
  var hash = 0xcbf29ce484222325;
  for (final cu in s.codeUnits) {
    hash ^= cu;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash;
}

int _hashLine(Line l) {
  final b = StringBuffer();
  for (final c in l.cells) {
    b.write(c.content);
  }
  return _fnv1a64(b.toString());
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

  final tab = List<_HashEntry>.generate(
    (height + 1) * 2,
    (_) => _HashEntry(
      value: 0,
      oldcount: 0,
      newcount: 0,
      oldindex: 0,
      newindex: 0,
    ),
  );

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

cp.Profile _detectProfile(List<String> env, bool? isTty) {
  final m = <String, String>{};
  for (final e in env) {
    final idx = e.indexOf('=');
    if (idx < 0) continue;
    m[e.substring(0, idx)] = e.substring(idx + 1);
  }

  final forceTty = isTty ?? _parseBool(m['TTY_FORCE']);
  // UvTerminalRenderer can be used with arbitrary sinks; default to non-TTY
  // unless explicitly forced.
  return cp_detect.detect(
    isTty: forceTty,
    env: m,
    isWindows: Platform.isWindows,
  );
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
  final seq = StringBuffer();
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
      // Overwrite optimization not implemented in this minimal port.
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
