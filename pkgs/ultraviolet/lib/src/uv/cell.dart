/// Cell model: glyph content, style, link, and display width.
///
/// A [Cell] holds a single grapheme (`content`), its `width`, a [UvStyle]
/// (foreground/background color, underline, attributes), and an optional
/// [Link] for terminals that support hyperlinks. Colors are represented by
/// [UvColor] with palette variants [UvBasic16], [UvIndexed256], and true color
/// [UvRgb].
///
/// {@category Ultraviolet}
/// {@subCategory Cells & Colors}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final cell = Cell(
///   content: 'A',
///   style: const UvStyle(fg: UvColor.rgb(255, 0, 0)),
///   link: const Link(url: 'https://example.com'),
/// );
/// ```
library;

import '../unicode/width.dart';

/// Underline style for terminal cells.
enum UnderlineStyle { none, single, double, curly, dotted, dashed }

/// Upstream: `third_party/ultraviolet/cell.go` (`Link`).
/// Terminal hyperlink metadata (OSC 8).
///
/// Carries a target [url] and optional [params] for terminals supporting
/// OSC 8 hyperlinks.
final class Link {
  const Link({this.url = '', this.params = ''});

  final String url;
  final String params;

  /// Whether this link has no URL or parameters.
  bool get isZero => url.isEmpty && params.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Link && other.url == url && other.params == params;

  @override
  int get hashCode => Object.hash(url, params);
}

/// Color representation sufficient for Ultraviolet parity tests.
///
/// Upstream: `third_party/ultraviolet/cell.go` stores `color.Color` values and
/// uses `x/ansi` helpers for named/indexed colors.
/// Unified UV color representation across palettes and true color.
///
/// Use [UvBasic16] for 16-color palette, [UvIndexed256] for 256-color
/// indexed palette, and [UvRgb] for 24-bit RGB.
sealed class UvColor {
  const UvColor();

  const factory UvColor.basic16(int index, {bool bright}) = UvBasic16;
  const factory UvColor.indexed256(int index) = UvIndexed256;
  const factory UvColor.rgb(int r, int g, int b, {int a}) = UvRgb;
}

/// 16-color palette index (optionally bright).
final class UvBasic16 extends UvColor {
  const UvBasic16(this.index, {this.bright = false});

  final int index; // 0..7
  final bool bright;

  @override
  bool operator ==(Object other) =>
      other is UvBasic16 && other.index == index && other.bright == bright;

  @override
  int get hashCode => Object.hash(index, bright);
}

/// 256-color indexed palette entry.
final class UvIndexed256 extends UvColor {
  const UvIndexed256(this.index);

  final int index; // 0..255

  @override
  bool operator ==(Object other) =>
      other is UvIndexed256 && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

/// 24-bit RGBA color.
final class UvRgb extends UvColor {
  const UvRgb(this.r, this.g, this.b, {this.a = 255});

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) =>
      other is UvRgb &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.a == a;

  @override
  int get hashCode => Object.hash(r, g, b, a);
}

/// Text attributes (bitmask).
///
/// Upstream: `third_party/ultraviolet/cell.go` (AttrBold, AttrFaint, ...).
abstract final class Attr {
  static const int bold = 1 << 0;
  static const int faint = 1 << 1;
  static const int italic = 1 << 2;
  static const int blink = 1 << 3;
  static const int rapidBlink = 1 << 4;
  static const int reverse = 1 << 5;
  static const int conceal = 1 << 6;
  static const int strikethrough = 1 << 7;
}

/// Upstream: `third_party/ultraviolet/cell.go` (`UvStyle`).
/// Style attributes for a terminal [Cell].
final class UvStyle {
  const UvStyle({
    this.fg,
    this.bg,
    this.underlineColor,
    this.underline = UnderlineStyle.none,
    this.attrs = 0,
  });

  final UvColor? fg;
  final UvColor? bg;
  final UvColor? underlineColor;
  final UnderlineStyle underline;
  final int attrs;

  /// A packed metadata key for this style.
  ///
  /// This folds colors, underline mode, and attributes into one stable integer
  /// so callers can cheaply compare and cache style state.
  int get packedKey => Object.hash(fg, bg, underlineColor, underline, attrs);

  /// Whether this style has no attributes or colors set.
  bool get isZero =>
      fg == null &&
      bg == null &&
      underlineColor == null &&
      underline == UnderlineStyle.none &&
      attrs == 0;

  /// Returns a copy of this style with selected fields updated.
  UvStyle copyWith({
    UvColor? fg,
    bool clearFg = false,
    UvColor? bg,
    bool clearBg = false,
    UvColor? underlineColor,
    bool clearUnderlineColor = false,
    UnderlineStyle? underline,
    int? attrs,
  }) {
    return UvStyle(
      fg: clearFg ? null : (fg ?? this.fg),
      bg: clearBg ? null : (bg ?? this.bg),
      underlineColor: clearUnderlineColor
          ? null
          : (underlineColor ?? this.underlineColor),
      underline: underline ?? this.underline,
      attrs: attrs ?? this.attrs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UvStyle &&
      other.packedKey == packedKey &&
      other.fg == fg &&
      other.bg == bg &&
      other.underlineColor == underlineColor &&
      other.underline == underline &&
      other.attrs == attrs;

  @override
  int get hashCode => packedKey.hashCode;
}

/// A single cell in a terminal [Buffer].
///
/// A cell contains one grapheme, a [UvStyle], an optional [Link], and its
/// display width. This Dart port keeps the public mutable API but also caches a
/// packed metadata signature so equality and hashing stay fast for the common
/// case of plain single-rune cells.
///
/// Upstream: `third_party/ultraviolet/cell.go` (`Cell`, `EmptyCell`).
final class Cell {
  Cell({
    String content = '',
    UvStyle style = const UvStyle(),
    Link link = const Link(),
    this.drawable,
    int? width,
  }) {
    _width = width ?? (content.isEmpty ? 0 : 1);
    _setContent(content);
    _setStyle(style);
    _setLink(link);
  }

  Cell._packed({
    required String content,
    required UvStyle style,
    required Link link,
    required int width,
    required int contentKind,
    required int contentValue,
    required int styleId,
    required int linkId,
    this.drawable,
  }) : _content = content,
       _style = style,
       _link = link,
       _width = width,
       _contentKind = contentKind,
       _contentValue = contentValue,
       _styleId = styleId,
       _linkId = linkId;

  String _content = '';
  UvStyle _style = const UvStyle();
  Link _link = const Link();
  int _width = 0;
  int _contentKind = _CellContentKind.empty;
  int _contentValue = 0;
  int _styleId = 0;
  int _linkId = 0;

  /// The grapheme content stored in this cell.
  String get content => _content;
  set content(String value) => _setContent(value);

  /// The canonicalized style for this cell.
  UvStyle get style => _style;
  set style(UvStyle value) => _setStyle(value);

  /// The canonicalized hyperlink metadata for this cell.
  Link get link => _link;
  set link(Link value) => _setLink(value);

  /// The display width of this cell in terminal columns.
  int get width => _width;
  set width(int value) {
    _width = value;
    _updatePackedContent();
  }

  Object? drawable;

  /// Whether this cell has no content, style, link, or drawable.
  bool get isZero =>
      _contentKind == _CellContentKind.empty &&
      _width == 0 &&
      _styleId == 0 &&
      _linkId == 0 &&
      drawable == null;

  /// Whether this cell represents a plain space with no attributes.
  bool get isEmpty =>
      _contentKind == _CellContentKind.space &&
      _width == 1 &&
      _styleId == 0 &&
      _linkId == 0 &&
      drawable == null;

  /// Returns a copy of this cell.
  Cell clone() => Cell._packed(
    content: _content,
    style: _style,
    link: _link,
    width: _width,
    contentKind: _contentKind,
    contentValue: _contentValue,
    styleId: _styleId,
    linkId: _linkId,
    drawable: drawable,
  );

  /// Sets this cell to a space with width 1.
  void empty() {
    _content = ' ';
    _width = 1;
    _updatePackedContent();
  }

  /// Creates a space cell with width 1.
  static Cell emptyCell() => Cell(content: ' ', width: 1);

  /// Creates a new cell from a grapheme, computing its display width.
  static Cell newCell(WidthMethod method, String grapheme) {
    if (grapheme.isEmpty) return Cell();
    if (grapheme == ' ') return Cell.emptyCell();
    return Cell(content: grapheme, width: method.stringWidth(grapheme));
  }

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      other._contentKind == _contentKind &&
      other._contentValue == _contentValue &&
      other._width == _width &&
      other._styleId == _styleId &&
      other._linkId == _linkId &&
      (_contentKind != _CellContentKind.complex || other._content == _content);

  @override
  int get hashCode => Object.hash(
    _contentKind,
    _contentValue,
    _width,
    _styleId,
    _linkId,
    _contentKind == _CellContentKind.complex ? _content : null,
  );

  void _setContent(String value) {
    _content = value;
    _updatePackedContent();
  }

  void _setStyle(UvStyle value) {
    final interned = _stylePool.intern(value);
    _style = interned.value;
    _styleId = interned.id;
  }

  void _setLink(Link value) {
    final interned = _linkPool.intern(value);
    _link = interned.value;
    _linkId = interned.id;
  }

  void _updatePackedContent() {
    if (_content.isEmpty) {
      _contentKind = _CellContentKind.empty;
      _contentValue = 0;
      return;
    }
    if (_content == ' ' && _width == 1) {
      _contentKind = _CellContentKind.space;
      _contentValue = 0;
      return;
    }
    final scalar = _trySingleScalar(_content);
    if (scalar != null) {
      _contentKind = _CellContentKind.singleScalar;
      _contentValue = scalar;
      return;
    }
    _contentKind = _CellContentKind.complex;
    _contentValue = 0;
  }
}

abstract final class _CellContentKind {
  static const int empty = 0;
  static const int space = 1;
  static const int singleScalar = 2;
  static const int complex = 3;
}

final class _CanonicalPool<T> {
  _CanonicalPool(T zero) {
    _ids[zero] = 0;
    _values.add(zero);
  }

  final Map<T, int> _ids = <T, int>{};
  final List<T> _values = <T>[];

  ({T value, int id}) intern(T value) {
    final existing = _ids[value];
    if (existing != null) {
      return (value: _values[existing], id: existing);
    }
    final id = _values.length;
    _ids[value] = id;
    _values.add(value);
    return (value: value, id: id);
  }
}

final _CanonicalPool<UvStyle> _stylePool = _CanonicalPool<UvStyle>(
  const UvStyle(),
);
final _CanonicalPool<Link> _linkPool = _CanonicalPool<Link>(const Link());

int? _trySingleScalar(String value) {
  if (value.isEmpty) return null;
  final iterator = value.runes.iterator;
  if (!iterator.moveNext()) return null;
  final scalar = iterator.current;
  return iterator.moveNext() ? null : scalar;
}
