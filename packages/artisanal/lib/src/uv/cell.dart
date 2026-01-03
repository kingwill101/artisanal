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

/// Underline styles (subset).
///
/// Upstream: `third_party/ultraviolet/cell.go` uses `ansi.Underline`.
enum UnderlineStyle { none, single, double, curly, dotted, dashed }

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
      other.fg == fg &&
      other.bg == bg &&
      other.underlineColor == underlineColor &&
      other.underline == underline &&
      other.attrs == attrs;

  @override
  int get hashCode => Object.hash(fg, bg, underlineColor, underline, attrs);
}

/// A single cell in a terminal [Buffer].
///
/// A cell contains a character (or string for multi-byte characters), a [UvStyle],
/// an optional [Link], and its display width. It can also hold a [drawable]
/// for rendering images or complex graphics.
///
/// Upstream: `third_party/ultraviolet/cell.go` (`Cell`, `EmptyCell`).
/// A single cell in a terminal [Buffer].
final class Cell {
  Cell({
    this.content = '',
    this.style = const UvStyle(),
    this.link = const Link(),
    this.drawable,
    int? width,
  }) : width = width ?? (content.isEmpty ? 0 : 1);

  String content;
  UvStyle style;
  Link link;
  int width;
  Object? drawable;

  /// Whether this cell has no content, style, link, or drawable.
  bool get isZero =>
      content.isEmpty &&
      width == 0 &&
      style.isZero &&
      link.isZero &&
      drawable == null;

  /// Whether this cell represents a plain space with no attributes.
  bool get isEmpty =>
      content == ' ' &&
      width == 1 &&
      style.isZero &&
      link.isZero &&
      drawable == null;

  /// Returns a copy of this cell.
  Cell clone() => Cell(
    content: content,
    style: style,
    link: link,
    width: width,
    drawable: drawable,
  );

  /// Sets this cell to a space with width 1.
  void empty() {
    content = ' ';
    width = 1;
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
      other.content == content &&
      other.width == width &&
      other.style == style &&
      other.link == link;

  @override
  int get hashCode => Object.hash(content, width, style, link);
}
