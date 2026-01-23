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

import 'dart:math' as math;

import '../terminal/ansi.dart';
import '../style/properties.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../unicode/grapheme.dart' as uni;
import '../unicode/width.dart' show maxLineWidth;

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
      final glyphWidth = Layout.visibleLength(glyph);

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
    return maxLineWidth(Ansi.stripAnsi(text));
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
    final visible = visibleLength(text);
    if (visible >= width) return text;
    return '$text${char * (width - visible)}';
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
    if (blocks.isEmpty) return '';
    if (blocks.length == 1) return blocks.first;

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

    return result.join('\n');
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

    return result.join('\n');
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
    final ws = whitespace ?? WhitespaceOptions(chars: ' ');
    // First place horizontally, then vertically (like Go)
    final horizontalPlaced = _placeHorizontal(width, horizontal, content, ws);
    return _placeVertical(height, vertical, horizontalPlaced, ws);
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
    final lines = content.split('\n');
    if (lines.isEmpty) return 0;
    return lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
  }

  /// Gets the height of a block of text (number of lines).
  static int getHeight(String content) {
    return content.split('\n').length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Truncation
  // ─────────────────────────────────────────────────────────────────────────────

  /// Truncates text to a maximum width, adding an ellipsis if needed.
  ///
  /// Handles ANSI codes properly (though imperfectly for mid-sequence truncation).
  static String truncate(String text, int maxWidth, {String ellipsis = '…'}) {
    final visible = visibleLength(text);
    if (visible <= maxWidth) return text;

    final ellipsisLen = ellipsis.length;
    final targetLen = maxWidth - ellipsisLen;
    if (targetLen <= 0) {
      return ellipsis.substring(0, maxWidth);
    }

    // Simple truncation - doesn't perfectly handle mid-ANSI truncation
    // For proper handling, we'd need to track ANSI state
    var currentLen = 0;
    var result = StringBuffer();
    var i = 0;

    while (i < text.length && currentLen < targetLen) {
      if (text[i] == '\x1B') {
        // Find end of ANSI sequence
        final end = text.indexOf('m', i);
        if (end != -1) {
          result.write(text.substring(i, end + 1));
          i = end + 1;
          continue;
        }
      }
      result.write(text[i]);
      currentLen++;
      i++;
    }

    // Add reset and ellipsis
    result.write('\x1B[0m$ellipsis');
    return result.toString();
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
  /// Simple word wrapping that breaks on spaces.
  static String wrap(String text, int maxWidth) {
    if (maxWidth <= 0) return text;

    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = StringBuffer();
    var currentWidth = 0;

    for (final word in words) {
      final wordWidth = visibleLength(word);

      if (currentWidth == 0) {
        // Start of line
        currentLine.write(word);
        currentWidth = wordWidth;
      } else if (currentWidth + 1 + wordWidth <= maxWidth) {
        // Word fits on current line
        currentLine.write(' $word');
        currentWidth += 1 + wordWidth;
      } else {
        // Start new line
        lines.add(currentLine.toString());
        currentLine = StringBuffer(word);
        currentWidth = wordWidth;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString());
    }

    return lines.join('\n');
  }

  /// Wraps each line of text to a maximum width.
  static String wrapLines(String content, int maxWidth) {
    return content.split('\n').map((l) => wrap(l, maxWidth)).join('\n');
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
}
