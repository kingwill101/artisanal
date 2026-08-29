/// Layout utilities for composing styled content blocks.
///
/// Provides functions for joining blocks horizontally or vertically,
/// and positioning content within containers.
///
/// ```dart
/// // Join blocks side by side
/// final dashboard = Layout.joinHorizontal(
///   VerticalAlign.top,
///   [leftPanel.render(), rightPanel.render()],
/// );
///
/// // Stack blocks vertically
/// final page = Layout.joinVertical(
///   HorizontalAlign.left,
///   [header.render(), content.render(), footer.render()],
/// );
///
/// // Center content in a container
/// final centered = Layout.place(
///   width: 80,
///   height: 24,
///   horizontal: HorizontalAlign.center,
///   vertical: VerticalAlign.center,
///   content: 'Welcome!',
/// );
/// ```
library;

import '../style/chars.dart';

import 'dart:collection';
import 'dart:math' as math;

import '../terminal/ansi.dart';
import '../style/properties.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../unicode/grapheme.dart' as uni;
import '../unicode/width.dart' show runeWidth;
import '../tui/trace.dart';
import '../uv/wrap.dart' as uv_wrap;

const int _layoutTraceThresholdUs = 1000;

void _traceLayout(String message, Stopwatch? sw) {
  if (sw == null) return;
  sw.stop();
  if (sw.elapsedMicroseconds < _layoutTraceThresholdUs) return;
  TuiTrace.log('$message ${sw.elapsedMicroseconds}us', tag: TraceTag.render);
}

/// Breakpoint names for responsive terminal layouts.
enum LayoutBreakpoint {
  /// Extra-small viewport bucket.
  xs,

  /// Small viewport bucket.
  sm,

  /// Medium viewport bucket.
  md,

  /// Large viewport bucket.
  lg,

  /// Extra-large viewport bucket.
  xl,
}

/// Configurable responsive thresholds with helpers for breakpoint branching.
final class ResponsiveBreakpoints {
  /// Default thresholds for the xs/sm/md/lg/xl breakpoints.
  ///
  /// Thresholds are interpreted as minimum widths in terminal cells:
  /// - [xs] is the minimum width for xs mode.
  /// - [sm] is the minimum width for sm mode (and above).
  /// - [md] is the minimum width for md mode (and above).
  /// - [lg] is the minimum width for lg mode (and above).
  /// - [xl] is the minimum width for xl mode.
  ///
  /// Defaults are tuned for compact terminal UIs where `md` is a safe wide
  /// single-pane-to-two-column handoff at 80 columns.
  static const ResponsiveBreakpoints defaults = ResponsiveBreakpoints(
    xs: 0,
    sm: 40,
    md: 80,
    lg: 120,
    xl: 160,
  );

  const ResponsiveBreakpoints({
    this.xs = 0,
    this.sm = 40,
    this.md = 80,
    this.lg = 120,
    this.xl = 160,
  }) : assert(xs >= 0),
       assert(sm >= xs),
       assert(md >= sm),
       assert(lg >= md),
       assert(xl >= lg);

  /// Minimum width for the extra-small bucket.
  final int xs;

  /// Minimum width for the small bucket.
  final int sm;

  /// Minimum width for the medium bucket.
  final int md;

  /// Minimum width for the large bucket.
  final int lg;

  /// Minimum width for the extra-large bucket.
  final int xl;

  /// Returns the current named breakpoint for a given terminal width.
  LayoutBreakpoint resolve(int width) {
    if (width >= xl) return LayoutBreakpoint.xl;
    if (width >= lg) return LayoutBreakpoint.lg;
    if (width >= md) return LayoutBreakpoint.md;
    if (width >= sm) return LayoutBreakpoint.sm;
    return LayoutBreakpoint.xs;
  }

  /// Whether [width] has reached at least the provided [breakpoint].
  bool isAtLeast(int width, LayoutBreakpoint breakpoint) {
    return width >= _threshold(breakpoint);
  }

  /// Whether [width] is below the provided [breakpoint].
  bool isBelow(int width, LayoutBreakpoint breakpoint) {
    return !isAtLeast(width, breakpoint);
  }

  int _threshold(LayoutBreakpoint breakpoint) {
    return switch (breakpoint) {
      LayoutBreakpoint.xs => xs,
      LayoutBreakpoint.sm => sm,
      LayoutBreakpoint.md => md,
      LayoutBreakpoint.lg => lg,
      LayoutBreakpoint.xl => xl,
    };
  }
}

/// Options for rendering whitespace in layout functions.
///
/// Used with [Layout.place] to customize how empty space is filled.
class WhitespaceOptions {
  /// Characters to cycle through when filling whitespace.
  final String chars;

  /// Foreground color for the whitespace characters.
  final Color? foreground;

  /// Background color for the whitespace.
  final Color? background;

  /// Creates whitespace processing options.
  ///
  /// [chars] specifies characters to cycle through when filling space.
  /// [foreground] and [background] apply optional styling.
  const WhitespaceOptions({this.chars = ' ', this.foreground, this.background});

  /// Renders whitespace of the given width using these options.
  String render(int width) {
    if (width <= 0) return '';

    final glyphs = uni.graphemes(chars).toList(growable: false);
    if (glyphs.isEmpty) return ' ' * width;

    final buffer = StringBuffer();
    var j = 0;
    var currentWidth = 0;

    // Cycle through grapheme clusters to fill the width
    while (currentWidth < width) {
      final glyph = glyphs[j];
      var glyphWidth = Layout.visibleLength(glyph);

      // Treat zero-width graphemes as having minimum width 1 so we always
      // make progress and avoid infinite loops (e.g. with combining marks).
      if (glyphWidth == 0) glyphWidth = 1;

      // Don't exceed width
      if (currentWidth + glyphWidth > width) break;

      buffer.write(glyph);
      currentWidth += glyphWidth;

      j = (j + 1) % glyphs.length;
    }

    // Fill any remaining gap with spaces
    if (currentWidth < width) {
      buffer.write(' ' * (width - currentWidth));
    }

    var result = buffer.toString();

    // Apply styling if needed
    if (foreground != null || background != null) {
      var style = Style();
      if (foreground != null) {
        style = style.foreground(foreground!);
      }
      if (background != null) {
        style = style.background(background!);
      }
      result = style.render(result);
    }

    return result;
  }
}

/// Layout utilities for composing rendered blocks.
class Layout {
  Layout._();

  static const int _maxCacheEntries = 4096;
  static final LinkedHashMap<String, int> _visibleLengthCache =
      LinkedHashMap<String, int>();
  static final LinkedHashMap<String, int> _getWidthCache =
      LinkedHashMap<String, int>();
  static final LinkedHashMap<String, int> _getHeightCache =
      LinkedHashMap<String, int>();

  // ─────────────────────────────────────────────────────────────────────────────
  // Per-frame counters for high-frequency operations
  // ─────────────────────────────────────────────────────────────────────────────

  /// Call count and total microseconds for [getWidth] in the current frame.
  static int _getWidthCount = 0;
  static int _getWidthUs = 0;

  /// Call count and total microseconds for [getHeight] in the current frame.
  static int _getHeightCount = 0;
  static int _getHeightUs = 0;

  /// Call count and total microseconds for [visibleLength] in the current frame.
  static int _visibleLengthCount = 0;
  static int _visibleLengthUs = 0;

  /// Call count and total microseconds for [pad] in the current frame.
  static int _padCount = 0;
  static int _padUs = 0;

  /// Emits per-frame counter summary to [TuiTrace] and resets all counters.
  ///
  /// Call this at frame boundaries (e.g. after render completes) to get
  /// aggregate stats for high-frequency Layout operations without the
  /// overhead of per-call tracing.
  static void emitFrameCounters() {
    if (!TuiTrace.enabled) {
      _resetCounters();
      return;
    }
    if (_getWidthCount + _getHeightCount + _visibleLengthCount + _padCount ==
        0) {
      return;
    }
    TuiTrace.log(
      'layout.counters '
      'getWidth=$_getWidthCount/${_getWidthUs}us '
      'getHeight=$_getHeightCount/${_getHeightUs}us '
      'visibleLength=$_visibleLengthCount/${_visibleLengthUs}us '
      'pad=$_padCount/${_padUs}us',
      tag: TraceTag.layout,
    );
    _resetCounters();
  }

  static void _resetCounters() {
    _getWidthCount = 0;
    _getWidthUs = 0;
    _getHeightCount = 0;
    _getHeightUs = 0;
    _visibleLengthCount = 0;
    _visibleLengthUs = 0;
    _padCount = 0;
    _padUs = 0;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Constants
  // ─────────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────────
  // String Utilities
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns the visible length of a string, ignoring ANSI escape codes.
  ///
  /// Accounts for double-width characters (CJK, emoji, etc.).
  static int visibleLength(String text) {
    final cached = _visibleLengthCache[text];
    if (cached != null) return cached;

    final asciiFast = _asciiVisibleLengthOrNull(text);
    if (asciiFast != null) {
      _cachePut(_visibleLengthCache, text, asciiFast);
      return asciiFast;
    }

    final Stopwatch? sw = TuiTrace.enabled ? (Stopwatch()..start()) : null;
    final result = Ansi.visibleLength(text);
    _cachePut(_visibleLengthCache, text, result);
    if (sw != null) {
      sw.stop();
      _visibleLengthCount++;
      _visibleLengthUs += sw.elapsedMicroseconds;
    }
    return result;
  }

  /// Returns the cell width of characters in the string.
  ///
  /// This is an alias for [visibleLength] to match lipgloss v2 naming.
  static int width(String text) => visibleLength(text);

  /// Returns the height of a string in cells.
  ///
  /// This is done by counting newline characters.
  static int height(String text) {
    if (text.isEmpty) return 1; // Match lipgloss v2 behavior
    return text.split('\n').length;
  }

  /// Returns the width and height of a string in cells.
  static (int width, int height) size(String text) {
    return (width(text), height(text));
  }

  /// Strips all ANSI escape codes from a string.
  static String stripAnsi(String text) {
    return Ansi.stripAnsi(text);
  }

  /// Pads a string to a given width, respecting ANSI codes.
  ///
  /// The padding is added to the right by default.
  static String pad(String text, int width, [String char = ' ']) {
    final Stopwatch? sw = TuiTrace.enabled ? (Stopwatch()..start()) : null;
    final visible = visibleLength(text);
    if (visible >= width) {
      sw?.stop();
      if (sw != null) {
        _padCount++;
        _padUs += sw.elapsedMicroseconds;
      }
      return text;
    }
    final result = '$text${char * (width - visible)}';
    if (sw != null) {
      sw.stop();
      _padCount++;
      _padUs += sw.elapsedMicroseconds;
    }
    return result;
  }

  /// Pads a string to a given width on the left.
  static String padLeft(String text, int width, [String char = ' ']) {
    final visible = visibleLength(text);
    if (visible >= width) return text;
    return '${char * (width - visible)}$text';
  }

  /// Centers a string within a given width.
  static String center(String text, int width, [String char = ' ']) {
    final visible = visibleLength(text);
    if (visible >= width) return text;
    final total = width - visible;
    final left = total ~/ 2;
    final right = total - left;
    return '${char * left}$text${char * right}';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alignment
  // ─────────────────────────────────────────────────────────────────────────────

  /// Aligns text within a given width.
  static String alignText(String text, int width, HorizontalAlign align) {
    switch (align) {
      case HorizontalAlign.left:
        return pad(text, width);
      case HorizontalAlign.center:
        return center(text, width);
      case HorizontalAlign.right:
        return padLeft(text, width);
    }
  }

  /// Aligns a list of lines within a given width.
  static List<String> alignLines(
    List<String> lines,
    int width,
    HorizontalAlign align,
  ) {
    return lines.map((line) => alignText(line, width, align)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Joining
  // ─────────────────────────────────────────────────────────────────────────────

  /// Joins multiple blocks horizontally with vertical alignment.
  ///
  /// Each block is a multi-line string. Blocks are placed side by side
  /// and aligned according to [align].
  ///
  /// ```dart
  /// final result = Layout.joinHorizontal(
  ///   VerticalAlign.top,
  ///   [leftBlock, middleBlock, rightBlock],
  ///   gap: 2,  // Optional gap between blocks
  /// );
  /// ```
  static String joinHorizontal(
    VerticalAlign align,
    List<String> blocks, {
    int gap = 0,
    String gapChar = ' ',
  }) {
    final Stopwatch? sw = TuiTrace.enabled ? Stopwatch() : null;
    sw?.start();
    if (blocks.isEmpty) return '';
    if (blocks.length == 1) return blocks.first;
    if (align == VerticalAlign.top) {
      return _joinHorizontalTop(blocks, gap: gap, gapChar: gapChar, sw: sw);
    }

    // Split each block into lines
    final blockLines = blocks.map((b) => b.split('\n')).toList();

    // Find the maximum height
    final maxHeight = blockLines
        .map((b) => b.length)
        .reduce((a, b) => a > b ? a : b);

    // Find the width of each block
    final widths = blockLines.map((lines) {
      if (lines.isEmpty) return 0;
      return lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
    }).toList();

    // Pad each block to have the same height
    final paddedBlocks = <List<String>>[];
    for (var i = 0; i < blockLines.length; i++) {
      final lines = blockLines[i];
      final width = widths[i];
      final padded = _padBlockHeight(lines, maxHeight, width, align);
      paddedBlocks.add(padded);
    }

    // Ensure each line has consistent width
    final normalizedBlocks = <List<String>>[];
    for (var i = 0; i < paddedBlocks.length; i++) {
      final lines = paddedBlocks[i];
      final width = widths[i];
      normalizedBlocks.add(lines.map((l) => pad(l, width)).toList());
    }

    // Build the gap string
    final gapStr = gapChar * gap;

    // Join lines horizontally
    final result = <String>[];
    for (var row = 0; row < maxHeight; row++) {
      final rowParts = <String>[];
      for (var col = 0; col < normalizedBlocks.length; col++) {
        rowParts.add(normalizedBlocks[col][row]);
      }
      result.add(rowParts.join(gapStr));
    }

    final output = result.join('\n');
    final maxWidth = widths.isEmpty
        ? 0
        : widths.reduce((a, b) => a > b ? a : b);
    _traceLayout(
      'layout.joinHorizontal blocks=${blocks.length} '
      'maxWidth=$maxWidth maxHeight=$maxHeight',
      sw,
    );
    return output;
  }

  static String _joinHorizontalTop(
    List<String> blocks, {
    required int gap,
    required String gapChar,
    required Stopwatch? sw,
  }) {
    final blockLines = <List<String>>[];
    final lineWidths = <List<int>>[];
    final widths = <int>[];
    var maxHeight = 0;
    var maxWidth = 0;

    for (final block in blocks) {
      final lines = block.split('\n');
      blockLines.add(lines);
      if (lines.length > maxHeight) maxHeight = lines.length;

      final widthsForBlock = <int>[];
      var width = 0;
      for (final line in lines) {
        final lineWidth = visibleLength(line);
        widthsForBlock.add(lineWidth);
        if (lineWidth > width) width = lineWidth;
      }
      lineWidths.add(widthsForBlock);
      widths.add(width);
      if (width > maxWidth) maxWidth = width;
    }

    final gapStr = gap > 0 ? gapChar * gap : '';
    final buffer = StringBuffer();
    for (var row = 0; row < maxHeight; row++) {
      if (row > 0) buffer.write('\n');
      for (var col = 0; col < blockLines.length; col++) {
        if (col > 0 && gapStr.isNotEmpty) buffer.write(gapStr);

        final lines = blockLines[col];
        final width = widths[col];
        if (row >= lines.length) {
          if (width > 0) buffer.write(' ' * width);
          continue;
        }

        final line = lines[row];
        buffer.write(line);
        final padding = width - lineWidths[col][row];
        if (padding > 0) buffer.write(' ' * padding);
      }
    }

    final output = buffer.toString();
    _traceLayout(
      'layout.joinHorizontal blocks=${blocks.length} '
      'maxWidth=$maxWidth maxHeight=$maxHeight',
      sw,
    );
    return output;
  }

  /// Joins multiple blocks vertically with horizontal alignment.
  ///
  /// Each block is a multi-line string. Blocks are stacked vertically
  /// and aligned according to [align].
  ///
  /// ```dart
  /// final result = Layout.joinVertical(
  ///   HorizontalAlign.center,
  ///   [header, content, footer],
  ///   gap: 1,  // Optional gap between blocks
  /// );
  /// ```
  static String joinVertical(
    HorizontalAlign align,
    List<String> blocks, {
    int gap = 0,
  }) {
    final Stopwatch? sw = TuiTrace.enabled ? Stopwatch() : null;
    sw?.start();
    if (blocks.isEmpty) return '';
    if (blocks.length == 1) return blocks.first;

    // Split each block into lines
    final allLines = <List<String>>[];
    for (final block in blocks) {
      allLines.add(block.split('\n'));
    }

    // Find the maximum width
    var maxWidth = 0;
    for (final lines in allLines) {
      for (final line in lines) {
        final w = visibleLength(line);
        if (w > maxWidth) maxWidth = w;
      }
    }

    // Build result with aligned lines
    final result = <String>[];
    for (var i = 0; i < allLines.length; i++) {
      if (i > 0 && gap > 0) {
        // Add gap lines
        for (var g = 0; g < gap; g++) {
          result.add(' ' * maxWidth);
        }
      }

      // Add aligned lines from this block
      for (final line in allLines[i]) {
        result.add(alignText(line, maxWidth, align));
      }
    }

    final output = result.join('\n');
    _traceLayout(
      'layout.joinVertical blocks=${blocks.length} '
      'maxWidth=$maxWidth height=${result.length}',
      sw,
    );
    return output;
  }

  /// Pads a block to a given height with vertical alignment.
  static List<String> _padBlockHeight(
    List<String> lines,
    int targetHeight,
    int width,
    VerticalAlign align,
  ) {
    if (lines.length >= targetHeight) {
      return lines.take(targetHeight).toList();
    }

    final diff = targetHeight - lines.length;
    final emptyLine = ' ' * width;

    switch (align) {
      case VerticalAlign.top:
        return [...lines, ...List.filled(diff, emptyLine)];
      case VerticalAlign.center:
        final top = diff ~/ 2;
        final bottom = diff - top;
        return [
          ...List.filled(top, emptyLine),
          ...lines,
          ...List.filled(bottom, emptyLine),
        ];
      case VerticalAlign.bottom:
        return [...List.filled(diff, emptyLine), ...lines];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Placement
  // ─────────────────────────────────────────────────────────────────────────────

  /// Places content at a position within a container.
  ///
  /// Creates a box of the given [width] and [height], and positions
  /// the [content] according to the alignment parameters.
  ///
  /// Use [whitespace] to customize how empty space is filled with
  /// custom characters and colors.
  ///
  /// ```dart
  /// final centered = Layout.place(
  ///   width: 80,
  ///   height: 24,
  ///   horizontal: HorizontalAlign.center,
  ///   vertical: VerticalAlign.center,
  ///   content: 'Hello, World!',
  ///   whitespace: WhitespaceOptions(
  ///     chars: '猫咪',
  ///     foreground: Color(0x383838),
  ///   ),
  /// );
  /// ```
  static String place({
    required int width,
    required int height,
    required HorizontalAlign horizontal,
    required VerticalAlign vertical,
    required String content,
    WhitespaceOptions? whitespace,
  }) {
    final Stopwatch? sw = TuiTrace.enabled ? Stopwatch() : null;
    sw?.start();
    final ws = whitespace ?? WhitespaceOptions(chars: ' ');
    // First place horizontally, then vertically (like Go)
    final horizontalPlaced = _placeHorizontal(width, horizontal, content, ws);
    final output = _placeVertical(height, vertical, horizontalPlaced, ws);
    _traceLayout('layout.place width=$width height=$height', sw);
    return output;
  }

  /// Places content horizontally within a given width.
  static String _placeHorizontal(
    int width,
    HorizontalAlign pos,
    String str,
    WhitespaceOptions ws,
  ) {
    final lines = str.split('\n');
    final contentWidth = lines.isEmpty
        ? 0
        : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);

    final gap = width - contentWidth;
    if (gap <= 0) return str;

    final buffer = StringBuffer();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Is this line shorter than the longest line?
      final short = contentWidth - visibleLength(line);
      final totalGap = gap + (short > 0 ? short : 0);

      switch (pos) {
        case HorizontalAlign.left:
          buffer.write(line);
          buffer.write(ws.render(totalGap));

        case HorizontalAlign.right:
          buffer.write(ws.render(totalGap));
          buffer.write(line);

        case HorizontalAlign.center:
          final left = totalGap ~/ 2;
          final right = totalGap - left;
          buffer.write(ws.render(left));
          buffer.write(line);
          buffer.write(ws.render(right));
      }

      if (i < lines.length - 1) {
        buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  /// Places content vertically within a given height.
  static String _placeVertical(
    int height,
    VerticalAlign pos,
    String str,
    WhitespaceOptions ws,
  ) {
    final lines = str.split('\n');
    final contentHeight = lines.length;
    final gap = height - contentHeight;

    if (gap <= 0) return str;

    // Get width from content
    final width = lines.isEmpty
        ? 0
        : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);

    final emptyLine = ws.render(width);
    final buffer = StringBuffer();

    switch (pos) {
      case VerticalAlign.top:
        buffer.write(str);
        for (var i = 0; i < gap; i++) {
          buffer.write('\n');
          buffer.write(emptyLine);
        }

      case VerticalAlign.bottom:
        for (var i = 0; i < gap; i++) {
          buffer.write(emptyLine);
          buffer.write('\n');
        }
        buffer.write(str);

      case VerticalAlign.center:
        final top = gap ~/ 2;
        final bottom = gap - top;

        for (var i = 0; i < top; i++) {
          buffer.write(emptyLine);
          buffer.write('\n');
        }
        buffer.write(str);
        for (var i = 0; i < bottom; i++) {
          buffer.write('\n');
          buffer.write(emptyLine);
        }
    }

    return buffer.toString();
  }

  /// Places content within a width, respecting the given alignment.
  ///
  /// This is a simpler version of [place] that only handles width.
  static String placeWidth({
    required int width,
    required HorizontalAlign align,
    required String content,
  }) {
    final lines = content.split('\n');
    return lines.map((l) => alignText(l, width, align)).join('\n');
  }

  /// Places content within a height, respecting the given alignment.
  ///
  /// This is a simpler version of [place] that only handles height.
  static String placeHeight({
    required int height,
    required VerticalAlign align,
    required String content,
    String fillChar = ' ',
  }) {
    final lines = content.split('\n');
    final width = lines.isEmpty
        ? 0
        : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);

    final padded = _padBlockHeight(lines, height, width, align);
    return padded.join('\n');
  }

  /// Places a string or text block horizontally in an unstyled block of a given
  /// width.
  ///
  /// If the given [width] is shorter than the max width of the string
  /// (measured by its longest line) this will be a noop.
  ///
  /// ```dart
  /// final centered = Layout.placeHorizontal(
  ///   80,
  ///   HorizontalAlign.center,
  ///   'Hello!',
  /// );
  /// ```
  static String placeHorizontal(
    int width,
    HorizontalAlign pos,
    String str, {
    WhitespaceOptions? whitespace,
  }) {
    final ws = whitespace ?? const WhitespaceOptions();
    return _placeHorizontal(width, pos, str, ws);
  }

  /// Places a string or text block vertically in an unstyled block of a given
  /// height.
  ///
  /// If the given [height] is shorter than the height of the string
  /// (measured by its newlines) then this will be a noop.
  ///
  /// ```dart
  /// final centered = Layout.placeVertical(
  ///   24,
  ///   VerticalAlign.center,
  ///   'Hello!',
  /// );
  /// ```
  static String placeVertical(
    int height,
    VerticalAlign pos,
    String str, {
    WhitespaceOptions? whitespace,
  }) {
    final ws = whitespace ?? const WhitespaceOptions();
    return _placeVertical(height, pos, str, ws);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Sizing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Gets the dimensions of a block of text.
  ///
  /// Returns a record with width and height.
  static ({int width, int height}) getSize(String content) {
    final lines = content.split('\n');
    final height = lines.length;
    final width = lines.isEmpty
        ? 0
        : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
    return (width: width, height: height);
  }

  /// Gets the width of a block of text (maximum line width).
  static int getWidth(String content) {
    final cached = _getWidthCache[content];
    if (cached != null) return cached;
    final Stopwatch? sw = TuiTrace.enabled ? (Stopwatch()..start()) : null;
    final result = visibleLength(content);
    _cachePut(_getWidthCache, content, result);
    if (sw != null) {
      sw.stop();
      _getWidthCount++;
      _getWidthUs += sw.elapsedMicroseconds;
    }
    return result;
  }

  /// Gets the height of a block of text (number of lines).
  static int getHeight(String content) {
    final cached = _getHeightCache[content];
    if (cached != null) return cached;
    final Stopwatch? sw = TuiTrace.enabled ? (Stopwatch()..start()) : null;
    var result = 1;
    for (var i = 0; i < content.length; i++) {
      if (content.codeUnitAt(i) == 10) {
        result++;
      }
    }
    _cachePut(_getHeightCache, content, result);
    if (sw != null) {
      sw.stop();
      _getHeightCount++;
      _getHeightUs += sw.elapsedMicroseconds;
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Truncation
  // ─────────────────────────────────────────────────────────────────────────────

  /// Truncates text to a maximum width, adding an ellipsis if needed.
  ///
  /// Handles ANSI codes properly (though imperfectly for mid-sequence
  /// truncation). Uses grapheme-cluster iteration and proper display-width
  /// accounting so that CJK, emoji, and variation-selector characters are
  /// measured correctly.
  static String truncate(
    String text,
    int maxWidth, {
    String ellipsis = EllipsisChars.horizontal,
  }) {
    final visible = visibleLength(text);
    if (visible <= maxWidth) return text;

    final ellipsisWidth = visibleLength(ellipsis);
    final targetLen = maxWidth - ellipsisWidth;
    if (targetLen <= 0) {
      // Even the ellipsis doesn't fit — return as much of it as we can.
      return ellipsis.substring(0, maxWidth);
    }

    // Walk through the text by UTF-16 index, but measure grapheme clusters
    // for display-width. ANSI escape sequences are passed through without
    // consuming any display budget.
    var currentLen = 0;
    var result = StringBuffer();
    var i = 0;

    while (i < text.length && currentLen < targetLen) {
      // Pass through ANSI escape/control sequences without consuming width.
      if (text[i] == '\x1B') {
        final end = _ansiSequenceEnd(text, i);
        if (end >= i) {
          result.write(text.substring(i, end + 1));
          i = end + 1;
          continue;
        }
      }

      // Read the next grapheme cluster starting at position i.
      final (:grapheme, :nextIndex) = uni.readGraphemeAt(text, i);
      if (grapheme.isEmpty) break;

      var w = runeWidth(uni.firstCodePoint(grapheme));
      // FE0F (emoji presentation selector) upgrades a narrow base to width 2,
      // matching the logic in stringWidth().
      if (w == 1 && grapheme.length > 1 && grapheme.contains('\uFE0F')) {
        w = 2;
      }

      // Don't exceed the target width.
      if (currentLen + w > targetLen) break;

      result.write(grapheme);
      currentLen += w;
      i = nextIndex;
    }

    // Add reset and ellipsis.
    result.write('\x1B[0m$ellipsis');
    return result.toString();
  }

  static int _ansiSequenceEnd(String text, int start) {
    if (start < 0 || start >= text.length) return -1;
    if (text.codeUnitAt(start) != 0x1B) return -1;
    if (start + 1 >= text.length) return start;

    final next = text.codeUnitAt(start + 1);

    // CSI: ESC [ ... final-byte(@-~)
    if (next == 0x5B) {
      for (var i = start + 2; i < text.length; i++) {
        final c = text.codeUnitAt(i);
        if (c >= 0x40 && c <= 0x7E) return i;
      }
      return text.length - 1;
    }

    // OSC: ESC ] ... BEL or ST(ESC \)
    if (next == 0x5D) {
      for (var i = start + 2; i < text.length; i++) {
        final c = text.codeUnitAt(i);
        if (c == 0x07) return i;
        if (c == 0x1B &&
            i + 1 < text.length &&
            text.codeUnitAt(i + 1) == 0x5C) {
          return i + 1;
        }
      }
      return text.length - 1;
    }

    // Simple 2-byte escape sequence fallback.
    return start + 1;
  }

  /// Truncates each line of text to a maximum width.
  static String truncateLines(
    String content,
    int maxWidth, {
    String ellipsis = '…',
  }) {
    return content
        .split('\n')
        .map((l) => truncate(l, maxWidth, ellipsis: ellipsis))
        .join('\n');
  }

  /// Truncates text to a maximum height (number of lines).
  static String truncateHeight(
    String content,
    int maxHeight, {
    String? lastLineIndicator,
  }) {
    final lines = content.split('\n');
    if (lines.length <= maxHeight) return content;

    final truncated = lines.take(maxHeight).toList();
    if (lastLineIndicator != null && truncated.isNotEmpty) {
      truncated[truncated.length - 1] = lastLineIndicator;
    }
    return truncated.join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Wrapping
  // ─────────────────────────────────────────────────────────────────────────────

  /// Wraps text to a maximum width.
  ///
  /// Wraps at spaces when possible and hard-breaks text that cannot otherwise
  /// fit. ANSI style and hyperlink state are preserved on continuation lines.
  static String wrap(String text, int maxWidth) {
    if (maxWidth <= 0) return text;
    return uv_wrap.wrapAnsiPreserving(text, maxWidth);
  }

  /// Wraps text to a maximum width while preserving ANSI state across both
  /// inserted and existing line breaks.
  static String wrapLines(String content, int maxWidth) {
    return wrap(content, maxWidth);
  }

  /// Stacks multiple blocks of text on top of each other.
  ///
  /// Higher layers (later in the list) overlay lower layers. Spaces in higher
  /// layers are treated as transparent, allowing the layer below to show through.
  ///
  /// ```dart
  /// final result = Layout.stack([background, foreground]);
  /// ```
  static String stack(List<String> blocks) {
    if (blocks.isEmpty) return '';
    if (blocks.length == 1) return blocks.first;

    // Split each block into lines
    final allLines = blocks.map((b) => b.split('\n')).toList();

    // Find the maximum dimensions
    var maxWidth = 0;
    var maxHeight = 0;
    for (final lines in allLines) {
      if (lines.length > maxHeight) maxHeight = lines.length;
      for (final line in lines) {
        final w = visibleLength(line);
        if (w > maxWidth) maxWidth = w;
      }
    }

    // Initialize the result buffer with the first block (padded)
    final resultLines = List<String>.filled(maxHeight, '');
    for (var i = 0; i < maxHeight; i++) {
      final line = i < allLines[0].length ? allLines[0][i] : '';
      resultLines[i] = pad(line, maxWidth);
    }

    // Overlay subsequent blocks
    for (var b = 1; b < allLines.length; b++) {
      final lines = allLines[b];
      for (var i = 0; i < maxHeight; i++) {
        if (i >= lines.length) continue;
        resultLines[i] = _overlayLine(resultLines[i], lines[i]);
      }
    }

    return resultLines.join('\n');
  }

  /// Overlays [top] onto [bottom]. Spaces in [top] are transparent.
  static String _overlayLine(String bottom, String top) {
    final bottomGraphemes = uni.graphemes(bottom).toList();
    final topGraphemes = uni.graphemes(top).toList();

    final result = <String>[];
    final len = math.max(bottomGraphemes.length, topGraphemes.length);

    for (var i = 0; i < len; i++) {
      final b = i < bottomGraphemes.length ? bottomGraphemes[i] : ' ';
      final t = i < topGraphemes.length ? topGraphemes[i] : ' ';

      // If top is a space (and not part of an ANSI sequence), use bottom
      // Note: This is a simplified check. Proper ANSI-aware stacking is complex.
      if (t == ' ' || t == '\t') {
        result.add(b);
      } else {
        result.add(t);
      }
    }

    return result.join('');
  }

  static void _cachePut(
    LinkedHashMap<String, int> cache,
    String key,
    int value,
  ) {
    if (cache.length >= _maxCacheEntries) {
      cache.remove(cache.keys.first);
    }
    cache[key] = value;
  }

  static int? _asciiVisibleLengthOrNull(String text) {
    var lineWidth = 0;
    var maxWidth = 0;

    for (var i = 0; i < text.length; i++) {
      final cu = text.codeUnitAt(i);

      if (cu == 10) {
        if (lineWidth > maxWidth) maxWidth = lineWidth;
        lineWidth = 0;
        continue;
      }

      if (cu == 0x1B || cu > 0x7F) {
        return null;
      }

      lineWidth++;
    }

    if (lineWidth > maxWidth) maxWidth = lineWidth;
    return maxWidth;
  }
}
