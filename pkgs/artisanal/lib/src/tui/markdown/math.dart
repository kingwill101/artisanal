import 'package:characters/characters.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:ultraviolet/core.dart';

/// A laid-out math fragment: UV cells plus a baseline row.
final class MathFragment {
  MathFragment({
    required this.buffer,
    required this.baseline,
    required this.source,
  });

  final Buffer buffer;
  final int baseline;
  final String source;

  int get width => buffer.width();
  int get height => buffer.height();

  /// Serializes cells without dropping trailing empty columns.
  String render({bool trimTrailing = false}) =>
      buffer.render(trimTrailing: trimTrailing);

  void dispose() => buffer.dispose();
}

/// Result of rendering TeX as a display fragment.
sealed class MathRenderResult {
  const MathRenderResult();
}

final class MathRendered extends MathRenderResult {
  const MathRendered(this.fragment);
  final MathFragment fragment;
}

final class MathParseFailed extends MathRenderResult {
  const MathParseFailed(this.message, this.source);
  final String message;
  final String source;
}

/// Result of linearizing TeX to a single Unicode line.
sealed class MathInlineResult {
  const MathInlineResult();
}

final class MathInlineRendered extends MathInlineResult {
  const MathInlineRendered(this.line);
  final String line;
}

final class MathInlineParseFailed extends MathInlineResult {
  const MathInlineParseFailed(this.message, this.source);
  final String message;
  final String source;
}

const KatexOptions _safeOptions = KatexOptions(
  displayMode: false,
  throwOnError: true,
  strict: 'ignore',
  maxSize: 100,
);

const KatexOptions _safeDisplayOptions = KatexOptions(
  displayMode: true,
  throwOnError: true,
  strict: 'ignore',
  maxSize: 100,
);

const int _maxInputLength = 4096;
const int _maxCells = 80 * 40;

/// Parses [tex] and linearizes it to one Unicode line.
MathInlineResult renderMathInline(String tex) {
  if (tex.length > _maxInputLength) {
    return MathInlineParseFailed('math input exceeds length limit', tex);
  }
  try {
    final box = renderToBox(tex, options: _safeOptions);
    return MathInlineRendered(_InlineLinearizer().linearize(box).trim());
  } on ParseError catch (error) {
    return MathInlineParseFailed(error.message, tex);
  }
}

/// Parses [tex] and lays it out on a terminal cell buffer.
MathRenderResult renderMath(String tex, {bool displayMode = false}) {
  if (tex.length > _maxInputLength) {
    return MathParseFailed('math input exceeds length limit', tex);
  }
  try {
    final box = renderToBox(
      tex,
      options: displayMode ? _safeDisplayOptions : _safeOptions,
    );
    final fragment = _BoxRasterizer().rasterize(box, tex);
    if (fragment.width * fragment.height > _maxCells) {
      fragment.dispose();
      return MathParseFailed('math output exceeds cell limit', tex);
    }
    return MathRendered(fragment);
  } on ParseError catch (error) {
    return MathParseFailed(error.message, tex);
  }
}

String mathFallback(String tex, {bool pending = false}) => pending ? '…' : tex;

/// Renders a markdown math element's TeX for ANSI output.
///
/// Used by every markdown renderer so apps never call [renderMath] themselves.
String formatMarkdownMath(
  String tex, {
  required bool display,
  bool pending = false,
  int? width,
}) {
  if (width != null && width < 0) return tex;
  if (pending) return mathFallback(tex, pending: true);
  if (display) {
    final result = renderMath(tex, displayMode: true);
    switch (result) {
      case MathRendered(:final fragment):
        final pictured = fragment.render();
        fragment.dispose();
        return pictured;
      case MathParseFailed():
        return tex;
    }
  }
  final result = renderMathInline(tex);
  return switch (result) {
    MathInlineRendered(:final line) => line,
    MathInlineParseFailed() => tex,
  };
}

class _InlineLinearizer {
  String linearize(BoxNode node) => switch (node) {
    GlyphNode(:final text) => text,
    KernNode() => '',
    HBox(:final children) ||
    SpanNode(:final children) => children.map(linearize).join(),
    VList(:final positions) => _vlist(positions),
    RuleNode() => '/',
    EncloseNode(:final child) => '[${linearize(child).replaceAll('/', '')}]',
    SvgPathNode(:final pathName) => _svgFallback(pathName),
    ImageNode(:final alt) => '[${alt.isEmpty ? 'img' : alt}]',
  };

  String _vlist(List<VListPosition> positions) {
    if (positions.isEmpty) return '';
    final sorted = [...positions]..sort((a, b) => a.shift.compareTo(b.shift));
    if (sorted.any(
      (p) =>
          p.box is SvgPathNode &&
          (p.box as SvgPathNode).pathName.startsWith('sqrt'),
    )) {
      final body = sorted
          .where((p) => p.box is! SvgPathNode)
          .map((p) => linearize(p.box))
          .join();
      return '√${_wrap(body)}';
    }
    if (sorted.length == 3 && _isFraction(sorted)) {
      final num = linearize(sorted.first.box);
      final den = linearize(sorted.last.box);
      return '${_wrap(num)}/${_wrap(den)}';
    }
    if (sorted.length == 1 && sorted.first.shift < 0) {
      return _super(linearize(sorted.first.box));
    }
    if (sorted.length == 1 && sorted.first.shift > 0) {
      return _sub(linearize(sorted.first.box));
    }
    if (sorted.length == 2) {
      final first = linearize(sorted[0].box);
      final second = linearize(sorted[1].box);
      final accented = _accented(first, second) ?? _accented(second, first);
      if (accented != null) return accented;
    }
    if (sorted.length >= 2) {
      final base = linearize(sorted.first.box);
      final scripts = sorted.skip(1).map((p) => linearize(p.box)).join();
      if (scripts.isNotEmpty && sorted[1].shift < 0) {
        return '$base${_super(scripts)}';
      }
      if (scripts.isNotEmpty) return '${base}_$scripts';
    }
    return sorted.map((p) => linearize(p.box)).join();
  }

  String? _accented(String base, String mark) {
    if (base.isEmpty || mark.isEmpty) return null;
    if (mark == '^' || mark == 'ˆ' || mark == '&#x302;') return '$basê';
    if (mark == '→' || mark == '⃗') return '$base⃗';
    if (mark == '¯' || mark == '‾') return '$base̅';
    return null;
  }

  bool _isFraction(List<VListPosition> positions) =>
      positions.any((p) => p.box is RuleNode);

  String _wrap(String value) => value.length > 1 ? '($value)' : value;

  String _super(String value) {
    final trimmed = value.replaceAll(' ', '');
    if (trimmed == '1/2') return '½';
    return _mapScript(trimmed, _superscripts) ?? '^${_wrap(trimmed)}';
  }

  String _sub(String value) {
    final trimmed = value.replaceAll(' ', '');
    return _mapScript(trimmed, _subscripts) ?? '_${_wrap(trimmed)}';
  }

  String _svgFallback(String pathName) {
    if (pathName.startsWith('sqrt')) return '√';
    if (pathName.contains('vec') || pathName.contains('rightarrow')) {
      return '→';
    }
    if (pathName.contains('leftarrow')) return '←';
    return '�';
  }
}

const _superscripts = {
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '+': '⁺',
  '-': '⁻',
  '=': '⁼',
  'n': 'ⁿ',
  'i': 'ⁱ',
};

const _subscripts = {
  '0': '₀',
  '1': '₁',
  '2': '₂',
  '3': '₃',
  '4': '₄',
  '5': '₅',
  '6': '₆',
  '7': '₇',
  '8': '₈',
  '9': '₉',
  'i': 'ᵢ',
  'n': 'ₙ',
  'k': 'ₖ',
  '+': '₊',
  '-': '₋',
};

String? _mapScript(String value, Map<String, String> table) {
  final mapped = StringBuffer();
  for (final rune in value.runes) {
    final next = table[String.fromCharCode(rune)];
    if (next == null) return null;
    mapped.write(next);
  }
  return mapped.toString();
}

class _Placed {
  _Placed(
    this.canvas,
    this.baseline, {
    this.empty = false,
    this.gapAfter = false,
    this.isRule = false,
  });
  final Canvas canvas;
  final int baseline;
  final bool empty;
  final bool gapAfter;
  final bool isRule;
  Buffer get buffer => canvas.buffer;
  int get width => empty ? 0 : canvas.width();
  int get height => empty ? 0 : canvas.height();
  int get ascent => empty ? 0 : baseline;
  int get descent => empty ? 0 : height - baseline - 1;
  void dispose() => canvas.dispose();
}

class _BoxRasterizer {
  MathFragment rasterize(BoxNode box, String source) {
    final placed = _node(box);
    final fragment = MathFragment(
      buffer: placed.buffer.clone(),
      baseline: placed.baseline,
      source: source,
    );
    placed.dispose();
    return fragment;
  }

  _Placed _node(BoxNode node) {
    if (node.width <= 0 && node.height <= 0 && node.depth <= 0) {
      return _empty();
    }
    return switch (node) {
      GlyphNode(:final text) => _glyph(text, node),
      KernNode(:final width) => _kern(width),
      HBox(:final children) || SpanNode(:final children) => _row(children),
      VList(:final positions) => _vlist(positions),
      RuleNode(:final width, :final height) => _rule(width, height),
      EncloseNode(:final child) => _enclose(_node(child)),
      SvgPathNode(:final pathName, :final width, :final height, :final depth) =>
        _svg(pathName, width, height, depth),
      ImageNode(:final alt) => _glyph('[${alt.isEmpty ? 'img' : alt}]'),
    };
  }

  _Placed _glyph(String text, [BoxNode? source]) {
    if (text.isEmpty) return _empty();
    final stretch = source != null ? _stretchyGlyph(text, source) : null;
    if (stretch != null) return stretch;
    if (text == '∑' ||
        text == '∐' ||
        text == '∏' ||
        text == '∫' ||
        text == '∮') {
      return _operatorGlyph(text);
    }
    final probe = Canvas(1, 1);
    final method = probe.widthMethod();
    final cells = [
      for (final grapheme in text.characters) Cell.newCell(method, grapheme),
    ];
    probe.dispose();
    var width = 0;
    for (final cell in cells) {
      width += cell.width > 0 ? cell.width : 1;
    }
    if (width <= 0) width = 1;
    final canvas = Canvas(width, 1);
    var x = 0;
    for (final cell in cells) {
      final advance = cell.width > 0 ? cell.width : 1;
      canvas.setCellOwned(x, 0, cell);
      x += advance;
    }
    return _Placed(canvas, 0);
  }

  _Placed _space(int cols) {
    if (cols <= 0) return _empty();
    return _Placed(Canvas(cols, 1), 0);
  }

  _Placed _kern(double widthEm) {
    var cols = _cols(widthEm);
    if (cols <= 0 && widthEm >= 0.16) cols = 1;
    return _space(cols);
  }

  _Placed _empty() => _Placed(Canvas(1, 1), 0, empty: true);

  _Placed _rule(double widthEm, double heightEm) {
    var cols = _cols(widthEm);
    if (cols <= 0 && widthEm > 0) cols = 1;
    if (cols <= 0) return _empty();
    final canvas = Canvas(cols, 1);
    drawHorizontal(canvas, 0, 0, cols, glyph: heightEm > 0.2 ? '━' : '─');
    return _Placed(canvas, 0, isRule: true);
  }

  _Placed _svg(String pathName, double width, double height, double depth) {
    if (pathName.startsWith('sqrt')) {
      return _radical(width, height + depth);
    }
    if (pathName.contains('vec') || pathName.contains('rightarrow')) {
      return _glyph('→');
    }
    if (pathName.contains('leftarrow')) return _glyph('←');
    return _glyph('�');
  }

  _Placed _radical(double widthEm, double extentEm) => _radicalCells(
    _cols(widthEm).clamp(2, 80),
    _extentRows(extentEm).clamp(2, 40),
  );

  _Placed _radicalCells(int cols, int rows) {
    final canvas = Canvas(cols, rows);
    _put(canvas, 1, 0, '┌');
    if (cols > 2) {
      drawHorizontal(canvas, 2, 0, cols - 2, glyph: '─');
    }
    for (var y = 1; y < rows; y++) {
      _put(canvas, 1, y, '│');
    }
    _put(canvas, 0, rows - 1, '╲');
    return _Placed(canvas, rows - 1);
  }

  _Placed? _stretchyGlyph(String text, BoxNode source) {
    final extent = source.height + source.depth;
    if (extent < 1.1) return null;
    final rows = _extentRows(extent).clamp(2, 40);
    final (top, mid, bot) = switch (text) {
      '(' => ('⎛', '⎜', '⎝'),
      ')' => ('⎞', '⎟', '⎠'),
      '[' => ('⎡', '⎢', '⎣'),
      ']' => ('⎤', '⎥', '⎦'),
      '{' => ('⎧', '⎨', '⎩'),
      '}' => ('⎫', '⎬', '⎭'),
      '|' => ('│', '│', '│'),
      _ => ('', '', ''),
    };
    if (top.isEmpty) return null;
    final canvas = Canvas(1, rows);
    _put(canvas, 0, 0, top);
    for (var y = 1; y < rows - 1; y++) {
      _put(canvas, 0, y, mid);
    }
    _put(canvas, 0, rows - 1, bot);
    return _Placed(
      canvas,
      (source.height * rows / extent).round().clamp(0, rows - 1),
    );
  }

  _Placed _operatorGlyph(String text) {
    if (text == '∫' || text == '∮') {
      final canvas = Canvas(1, 2);
      _put(canvas, 0, 0, '⌠');
      _put(canvas, 0, 1, '⌡');
      return _Placed(canvas, 1, gapAfter: true);
    }
    final canvas = Canvas(3, 2);
    switch (text) {
      case '∑':
        _put(canvas, 0, 0, '┌');
        _put(canvas, 1, 0, '─');
        _put(canvas, 2, 1, '┘');
        _put(canvas, 0, 1, '└');
        _put(canvas, 1, 1, '─');
        _put(canvas, 2, 0, '┐');
      case '∏':
      case '∐':
        _put(canvas, 0, 0, '┬');
        _put(canvas, 1, 0, '─');
        _put(canvas, 2, 0, '┬');
        _put(canvas, 0, 1, '│');
        _put(canvas, 2, 1, '│');
      default:
        canvas.dispose();
        return _glyph(text);
    }
    return _Placed(canvas, 1, gapAfter: true);
  }

  int _extentRows(double em) {
    final rows = em.round();
    return rows < 1 ? 1 : rows;
  }

  bool _rangeOccupied(Set<int> occupied, int top, int height) {
    for (var y = top; y < top + height; y++) {
      if (occupied.contains(y)) return true;
    }
    return false;
  }

  void _put(Canvas canvas, int x, int y, String glyph) {
    final cell = Cell.newCell(canvas.widthMethod(), glyph);
    cell.width = 1;
    canvas.setCellOwned(x, y, cell);
  }

  _Placed _enclose(_Placed child) {
    final width = child.width + 2;
    final height = child.height + 2;
    final canvas = Canvas(width, height);
    drawHorizontal(canvas, 0, 0, width, glyph: '─');
    drawHorizontal(canvas, 0, height - 1, width, glyph: '─');
    drawVertical(canvas, 0, 0, height, glyph: '│');
    drawVertical(canvas, width - 1, 0, height, glyph: '│');
    _put(canvas, 0, 0, '┌');
    _put(canvas, width - 1, 0, '┐');
    _put(canvas, 0, height - 1, '└');
    _put(canvas, width - 1, height - 1, '┘');
    child.buffer.draw(
      canvas,
      rect(1, 1, child.width, child.height),
      clip: true,
      skipEmpty: true,
    );
    child.dispose();
    return _Placed(canvas, child.baseline + 1);
  }

  _Placed _row(List<BoxNode> children) {
    if (children.isEmpty) return _empty();
    final parts = List<_Placed?>.filled(children.length, null);
    var ascent = 0;
    var descent = 0;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (child.width <= 0 && child.height <= 0 && child.depth <= 0) {
        parts[i] = _empty();
        continue;
      }
      if (_stretchyDelimText(child) != null) continue;
      final placed = _node(child);
      parts[i] = placed;
      if (placed.ascent > ascent) ascent = placed.ascent;
      if (placed.descent > descent) descent = placed.descent;
    }
    var height = ascent + descent + 1;
    if (height < 1) height = 1;
    for (var i = 0; i < children.length; i++) {
      final text = _stretchyDelimText(children[i]);
      if (text == null) continue;
      parts[i] = _delimiter(text, height, ascent);
    }
    final resolved = [
      for (final part in parts)
        if (part != null && !part.empty) part,
    ];
    if (resolved.isEmpty) return _empty();
    for (final part in resolved) {
      if (part.ascent > ascent) ascent = part.ascent;
      if (part.descent > descent) descent = part.descent;
    }
    height = ascent + descent + 1;
    final width = resolved.fold<int>(0, (sum, p) {
      var next = sum + p.width;
      if (p.gapAfter) next += 1;
      return next;
    });
    final canvas = Canvas(width < 1 ? 1 : width, height < 1 ? 1 : height);
    var x = 0;
    for (final part in resolved) {
      final partWidth = part.width;
      final partHeight = part.height;
      if (partWidth > 0 && partHeight > 0) {
        part.buffer.draw(
          canvas,
          rect(x, ascent - part.ascent, partWidth, partHeight),
          clip: true,
          skipEmpty: true,
        );
      }
      x += partWidth;
      if (part.gapAfter) x += 1;
      part.dispose();
    }
    return _Placed(canvas, ascent);
  }

  String? _stretchyDelimText(BoxNode node) {
    final glyph = _unwrapGlyph(node);
    if (glyph == null) return null;
    if (glyph.height + glyph.depth < 1.1) return null;
    return switch (glyph.text) {
      '(' || ')' || '[' || ']' || '{' || '}' || '|' => glyph.text,
      _ => null,
    };
  }

  GlyphNode? _unwrapGlyph(BoxNode node) => switch (node) {
    GlyphNode() => node,
    SpanNode(:final children) when children.length == 1 => _unwrapGlyph(
      children.first,
    ),
    HBox(:final children) when children.length == 1 => _unwrapGlyph(
      children.first,
    ),
    _ => null,
  };

  _Placed _delimiter(String text, int rows, int baseline) {
    final (top, mid, bot) = switch (text) {
      '(' => ('⎛', '⎜', '⎝'),
      ')' => ('⎞', '⎟', '⎠'),
      '[' => ('⎡', '⎢', '⎣'),
      ']' => ('⎤', '⎥', '⎦'),
      '{' => ('⎧', '⎨', '⎩'),
      '}' => ('⎫', '⎬', '⎭'),
      _ => ('│', '│', '│'),
    };
    final height = rows < 2 ? 2 : rows;
    final canvas = Canvas(1, height);
    _put(canvas, 0, 0, top);
    for (var y = 1; y < height - 1; y++) {
      _put(canvas, 0, y, mid);
    }
    _put(canvas, 0, height - 1, bot);
    return _Placed(canvas, baseline.clamp(0, height - 1));
  }

  _Placed _vlist(List<VListPosition> positions) {
    if (positions.isEmpty) return _empty();
    final radical = _radicalVlist(positions);
    if (radical != null) return radical;
    final compact = _compactScript(positions);
    if (compact != null) return compact;
    final parts = [
      for (final position in positions)
        if (position.box.width > 0 ||
            position.box.height > 0 ||
            position.box.depth > 0)
          (placed: _node(position.box), shift: position.shift),
    ]..sort((a, b) => a.shift.compareTo(b.shift));
    if (parts.isEmpty) return _empty();
    var minRow = 0;
    var maxRow = 0;
    var width = 0;
    for (final part in parts) {
      final top = _rows(part.shift) - part.placed.ascent;
      final bottom = top + part.placed.height;
      if (top < minRow) minRow = top;
      if (bottom > maxRow) maxRow = bottom;
      if (part.placed.width > width) width = part.placed.width;
    }
    if (maxRow <= minRow) maxRow = minRow + 1;
    if (width < 1) width = 1;
    final sameBaseline =
        parts.length >= 2 &&
        parts.every((part) => _rows(part.shift) == _rows(parts.first.shift));
    final occupied = <int>{};
    final placements = <({int top, _Placed placed, double shift})>[];
    for (final part in parts) {
      var top = _rows(part.shift) - part.placed.ascent - minRow;
      while (_rangeOccupied(occupied, top, part.placed.height)) {
        top += sameBaseline ? -1 : 1;
      }
      for (var y = top; y < top + part.placed.height; y++) {
        occupied.add(y);
      }
      placements.add((top: top, placed: part.placed, shift: part.shift));
    }
    final minTop = placements
        .map((placement) => placement.top)
        .reduce((a, b) => a < b ? a : b);
    final maxBottom = placements
        .map((placement) => placement.top + placement.placed.height)
        .reduce((a, b) => a > b ? a : b);
    final shifted = [
      for (final placement in placements)
        (
          top: placement.top - minTop,
          placed: placement.placed,
          shift: placement.shift,
        ),
    ];
    final canvas = Canvas(width, maxBottom - minTop);
    for (final placement in shifted) {
      final top = placement.top;
      final childWidth = placement.placed.width;
      final childHeight = placement.placed.height;
      if (!placement.placed.empty && childWidth > 0 && childHeight > 0) {
        if (placement.placed.isRule) {
          drawHorizontal(canvas, 0, top, width, glyph: '─');
        } else {
          final left = ((width - childWidth) / 2).floor();
          placement.placed.buffer.draw(
            canvas,
            rect(left, top, childWidth, childHeight),
            clip: true,
            skipEmpty: true,
          );
        }
      }
      placement.placed.dispose();
    }
    final body = shifted.reduce(
      (a, b) => a.shift.abs() <= b.shift.abs() ? a : b,
    );
    return _trimEmptyRows(_Placed(canvas, body.top));
  }

  _Placed _trimEmptyRows(_Placed placed) {
    if (placed.empty || placed.height <= 1) return placed;
    var top = 0;
    var bottom = placed.height - 1;
    bool rowEmpty(int y) {
      for (var x = 0; x < placed.width; x++) {
        final cell = placed.canvas.cellAt(x, y);
        if (cell != null && !cell.isEmpty && !cell.isZero) return false;
      }
      return true;
    }

    while (top < bottom && rowEmpty(top)) {
      top++;
    }
    while (bottom > top && rowEmpty(bottom)) {
      bottom--;
    }
    if (top == 0 && bottom == placed.height - 1) return placed;
    final height = bottom - top + 1;
    final canvas = Canvas(placed.width, height);
    placed.buffer.draw(
      canvas,
      rect(0, -top, placed.width, placed.height),
      clip: true,
      skipEmpty: true,
    );
    final baseline = (placed.baseline - top).clamp(0, height - 1);
    placed.dispose();
    return _Placed(canvas, baseline);
  }

  _Placed? _compactScript(List<VListPosition> positions) {
    if (positions.length != 1) return null;
    final position = positions.first;
    final text = _InlineLinearizer().linearize(position.box).trim();
    if (text.isEmpty) return null;
    if (position.shift < 0) {
      final compact = text.replaceAll(' ', '');
      if (compact == '1/2') return _glyph('½');
      final mapped = _mapScript(compact, _superscripts);
      if (mapped != null) return _glyph(mapped);
      return _glyph('^($compact)');
    }
    if (position.shift > 0) {
      final mapped = _mapScript(text, _subscripts);
      if (mapped != null) return _glyph(mapped);
    }
    return null;
  }

  _Placed? _radicalVlist(List<VListPosition> positions) {
    SvgPathNode? surd;
    BoxNode? content;
    for (final position in positions) {
      final box = position.box;
      if (box is SvgPathNode && box.pathName.startsWith('sqrt')) {
        surd = box;
      } else {
        content ??= box;
      }
    }
    if (surd == null || content == null) return null;
    final body = _node(_stripLeadingKern(content));
    final rows = (body.height + 1).clamp(2, 40);
    final cols = (body.width + 2).clamp(2, 80);
    final radical = _radicalCells(cols, rows);
    final width = radical.width > cols ? radical.width : cols;
    final height = radical.height > rows ? radical.height : rows;
    final canvas = Canvas(width, height);
    radical.buffer.draw(
      canvas,
      rect(0, 0, radical.width, radical.height),
      clip: true,
      skipEmpty: true,
    );
    body.buffer.draw(
      canvas,
      rect(2, 1, body.width, body.height),
      clip: true,
      skipEmpty: true,
    );
    radical.dispose();
    body.dispose();
    return _Placed(canvas, height - 1);
  }

  BoxNode _stripLeadingKern(BoxNode box) {
    List<BoxNode> children;
    if (box is HBox) {
      children = box.children;
    } else if (box is SpanNode) {
      children = box.children;
    } else {
      return box;
    }
    final kept = [
      for (final child in children)
        if (child is! KernNode &&
            (child.width > 0 || child.height > 0 || child.depth > 0))
          child,
    ];
    if (kept.length == 1) return _stripLeadingKern(kept.first);
    return box;
  }

  int _cols(double em) {
    final cols = em.round();
    return cols < 0 ? 0 : cols;
  }

  int _rows(double em) {
    if (em == 0) return 0;
    final rows = em.round();
    return rows == 0 ? (em < 0 ? -1 : 1) : rows;
  }
}
