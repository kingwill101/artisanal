
import 'package:artisanal/style.dart' hide Padding, Align;
import 'ascii_font.dart';
import 'enums.dart';
import '../core/framework.dart'
    show BuildContext, StatelessWidget;
import '../rendering/render_object.dart';
import '../rendering/render_layout.dart';
import '../core/widget.dart';
import 'text.dart';


/// A widget that renders text using large ASCII art font glyphs.
///
/// Each character is rendered using multi-line glyph art from an [AsciiFont].
/// Characters are placed side by side with [AsciiFont.letterSpacing] columns
/// between them. Words are separated by the space glyph width.
///
/// ```dart
/// AsciiText(
///   data: 'HELLO',
///   font: AsciiFont.standard,
/// )
/// ```
class AsciiText extends LeafRenderObjectWidget {
  AsciiText({
    required this.data,
    this.font = const StandardFont(),
    this.textAlign = TextAlign.left,
    this.maxWidth,
    super.key,
  });

  /// The text to render in ASCII art.
  final String data;

  /// The ASCII font to use for rendering.
  final AsciiFont font;

  /// How to align the rendered text.
  final TextAlign textAlign;

  /// Maximum width in columns. If set, words wrap to fit.
  final int? maxWidth;

  @override
  RenderObject createRenderObject() {
    // ASCII art must never be word-wrapped — Layout.wrapLines splits on
    // spaces which destroys the carefully laid-out glyph spacing.
    return RenderText(text: _render(), softWrap: false);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderText).text = _render();
  }

  @override
  Object view() => _render();

  String _render() {
    return buildCachedView<String>(() {
      return _renderAsciiText(data, font, textAlign, maxWidth);
    }, _cacheKey());
  }

  Object _cacheKey() => (data, textAlign, maxWidth);
}

/// A convenience wrapper that applies a [Style] to [AsciiText].
///
/// ```dart
/// StyledAsciiText(
///   data: 'HI',
///   font: AsciiFont.banner,
///   style: Style()..foreground(Colors.cyan)..bold(true),
/// )
/// ```
class StyledAsciiText extends StatelessWidget {
  StyledAsciiText({
    required this.data,
    this.font = const StandardFont(),
    this.style,
    this.textAlign = TextAlign.left,
    this.maxWidth,
    super.key,
  });

  /// The text to render in ASCII art.
  final String data;

  /// The ASCII font to use for rendering.
  final AsciiFont font;

  /// Optional style to apply (foreground color, bold, etc.).
  final Style? style;

  /// How to align the rendered text.
  final TextAlign textAlign;

  /// Maximum width in columns. If set, words wrap to fit.
  final int? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (style == null) {
      return AsciiText(
        data: data,
        font: font,
        textAlign: textAlign,
        maxWidth: maxWidth,
      );
    }
    // Render the ASCII art, then apply the style per-line to avoid
    // Style.render()'s _alignLines() padding all lines to equal width.
    // This preserves each line's exact spacing (important for ASCII art
    // glyphs that may have different visible widths, e.g. trailing
    // empty lines in slim font).
    final rendered = _renderAsciiText(data, font, textAlign, maxWidth);
    final inlineStyle = style!.copy()..inline();
    final styledLines = rendered
        .split('\n')
        .map((line) => line.isEmpty ? line : inlineStyle.render(line))
        .join('\n');
    return Text(styledLines, softWrap: false);
  }
}

/// Renders text using ASCII font glyphs.
///
/// The algorithm:
/// 1. Split text into words.
/// 2. For each word, lay out character glyphs side by side.
/// 3. Join words with space-glyph-width gaps.
/// 4. Optionally wrap lines if [maxWidth] is set.
/// 5. Apply text alignment.
String _renderAsciiText(
  String text,
  AsciiFont font,
  TextAlign textAlign,
  int? maxWidth,
) {
  if (text.isEmpty) return '';

  final words = text.split(' ');
  final wordLayouts = words.map((w) => _layoutAsciiWord(w, font)).toList();

  // Calculate space glyph width.
  final spaceGlyph = font.getGlyph(' ');
  final spaceWidth = spaceGlyph.width + font.letterSpacing;

  List<List<String>> rows;
  if (maxWidth != null && maxWidth > 0) {
    rows = _wrapAsciiWords(wordLayouts, spaceWidth, maxWidth, font.height);
  } else {
    rows = [_joinAsciiWords(wordLayouts, spaceWidth, font.height)];
  }

  // Find the max row width for alignment.
  final allLines = <String>[];
  int maxLineWidth = 0;
  for (final row in rows) {
    for (final line in row) {
      final w = Layout.getWidth(line);
      if (w > maxLineWidth) maxLineWidth = w;
    }
  }

  // Flatten rows and apply alignment.
  for (final row in rows) {
    for (final line in row) {
      final lineWidth = Layout.getWidth(line);
      final alignedLine = _alignAsciiLine(
        line,
        lineWidth,
        maxLineWidth,
        textAlign,
      );
      allLines.add(alignedLine);
    }
  }

  return allLines.join('\n');
}

/// Lays out a single word as [fontHeight] horizontal strings.
List<String> _layoutAsciiWord(String word, AsciiFont font) {
  final height = font.height;
  final buffers = List.generate(height, (_) => StringBuffer());

  var isFirst = true;
  for (var i = 0; i < word.length; i++) {
    final char = word[i];
    final glyph = font.getGlyph(char);
    if (!isFirst) {
      // Add letter spacing.
      final spacing = ' ' * font.letterSpacing;
      for (var i = 0; i < height; i++) {
        buffers[i].write(spacing);
      }
    }
    for (var i = 0; i < height; i++) {
      if (i < glyph.lines.length) {
        buffers[i].write(glyph.lines[i]);
      } else {
        buffers[i].write(' ' * glyph.width);
      }
    }
    isFirst = false;
  }

  return buffers.map((b) => b.toString()).toList();
}

/// Joins multiple word layouts horizontally with space gaps.
List<String> _joinAsciiWords(
  List<List<String>> wordLayouts,
  int spaceWidth,
  int fontHeight,
) {
  if (wordLayouts.isEmpty) {
    return List.generate(fontHeight, (_) => '');
  }
  if (wordLayouts.length == 1) return wordLayouts.first;

  final buffers = List.generate(fontHeight, (_) => StringBuffer());
  final spacing = ' ' * spaceWidth;

  for (var w = 0; w < wordLayouts.length; w++) {
    if (w > 0) {
      for (var i = 0; i < fontHeight; i++) {
        buffers[i].write(spacing);
      }
    }
    final wordLines = wordLayouts[w];
    for (var i = 0; i < fontHeight; i++) {
      if (i < wordLines.length) {
        buffers[i].write(wordLines[i]);
      }
    }
  }

  return buffers.map((b) => b.toString()).toList();
}

/// Wraps word layouts into rows that fit within [maxWidth].
List<List<String>> _wrapAsciiWords(
  List<List<String>> wordLayouts,
  int spaceWidth,
  int maxWidth,
  int fontHeight,
) {
  final rows = <List<String>>[];
  var currentRow = <List<String>>[];
  var currentWidth = 0;

  for (final wordLayout in wordLayouts) {
    final wordWidth = wordLayout.isEmpty
        ? 0
        : Layout.getWidth(wordLayout.first);

    if (currentRow.isEmpty) {
      currentRow.add(wordLayout);
      currentWidth = wordWidth;
    } else {
      final neededWidth = currentWidth + spaceWidth + wordWidth;
      if (neededWidth <= maxWidth) {
        currentRow.add(wordLayout);
        currentWidth = neededWidth;
      } else {
        rows.add(_joinAsciiWords(currentRow, spaceWidth, fontHeight));
        currentRow = [wordLayout];
        currentWidth = wordWidth;
      }
    }
  }

  if (currentRow.isNotEmpty) {
    rows.add(_joinAsciiWords(currentRow, spaceWidth, fontHeight));
  }

  return rows;
}

/// Aligns a single line of ASCII text within [maxWidth].
String _alignAsciiLine(
  String line,
  int lineWidth,
  int maxWidth,
  TextAlign textAlign,
) {
  if (lineWidth >= maxWidth) return line;

  switch (textAlign) {
    case TextAlign.left:
    case TextAlign.justify:
      return line;
    case TextAlign.right:
      final pad = ' ' * (maxWidth - lineWidth);
      return '$pad$line';
    case TextAlign.center:
      final pad = ' ' * ((maxWidth - lineWidth) ~/ 2);
      return '$pad$line';
  }
}
