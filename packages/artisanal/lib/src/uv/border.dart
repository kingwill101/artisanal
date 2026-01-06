/// Renders configurable terminal borders and corners around a rectangular region.
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// [UvBorder] draws edges and corner glyphs into a [Screen] within a target
/// [Rectangle], making it easy to frame panels, dialogs, and sections. Use it
/// directly with [Canvas] (immediate-mode composition) or any buffer-backed
/// [Screen] to outline areas. Each side is a [Side] with `content`, [UvStyle],
/// and optional [Link]; apply common styling via [UvBorder.style] and
/// hyperlinks via [UvBorder.link]. For titles or badges, render a [StyledString]
/// inside or atop the border region for rich, styled labels.
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_events_overview}
/// {@macro artisanal_uv_performance_tips}
/// {@macro artisanal_uv_compatibility}
///
/// Example:
/// ```dart
/// // Compose a rounded border and a title onto a canvas.
/// final canvas = Canvas(20, 5);
/// final border = roundedBorder().style(const UvStyle(fg: UvColor.basic16(7)));
/// canvas.compose(border);
///
/// // Draw a short label near the top edge.
/// StyledString('Title').draw(canvas, rect(2, 0, 5, 1));
/// final rendered = canvas.render(); // -> use in your renderer
/// ```
library;

import 'cell.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';

/// UvBorder primitives.
///
/// Upstream: `third_party/ultraviolet/border.go`.
final class Side {
  const Side({
    this.content = '',
    this.style = const UvStyle(),
    this.link = const Link(),
  });

  final String content;
  final UvStyle style;
  final Link link;

  /// Returns a copy of this side with updated fields.
  Side copyWith({String? content, UvStyle? style, Link? link}) => Side(
    content: content ?? this.content,
    style: style ?? this.style,
    link: link ?? this.link,
  );
}

/// A drawable border composed of [Side]s and corner glyphs.
final class UvBorder implements Drawable {
  const UvBorder({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Side top;
  final Side bottom;
  final Side left;
  final Side right;
  final Side topLeft;
  final Side topRight;
  final Side bottomLeft;
  final Side bottomRight;

  /// Returns a zero-sized bounds rectangle (borders draw into provided areas).
  @override
  Rectangle bounds() => const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);

  /// Returns a new [UvBorder] with [style] applied to all sides.
  ///
  /// Upstream: `UvBorder.UvStyle`.
  UvBorder style(UvStyle style) => UvBorder(
    top: top.copyWith(style: style),
    bottom: bottom.copyWith(style: style),
    left: left.copyWith(style: style),
    right: right.copyWith(style: style),
    topLeft: topLeft.copyWith(style: style),
    topRight: topRight.copyWith(style: style),
    bottomLeft: bottomLeft.copyWith(style: style),
    bottomRight: bottomRight.copyWith(style: style),
  );

  /// Returns a new [UvBorder] with [link] applied to all sides.
  ///
  /// Upstream: `UvBorder.Link`.
  UvBorder link(Link link) => UvBorder(
    top: top.copyWith(link: link),
    bottom: bottom.copyWith(link: link),
    left: left.copyWith(link: link),
    right: right.copyWith(link: link),
    topLeft: topLeft.copyWith(link: link),
    topRight: topRight.copyWith(link: link),
    bottomLeft: bottomLeft.copyWith(link: link),
    bottomRight: bottomRight.copyWith(link: link),
  );

  /// Draws this border around the given [area].
  @override
  void draw(Screen screen, Rectangle area) {
    for (var y = area.minY; y < area.maxY; y++) {
      for (var x = area.minX; x < area.maxX; x++) {
        Side side;
        if (y == area.minY && x == area.minX) {
          side = topLeft;
        } else if (y == area.minY && x == area.maxX - 1) {
          side = topRight;
        } else if (y == area.maxY - 1 && x == area.minX) {
          side = bottomLeft;
        } else if (y == area.maxY - 1 && x == area.maxX - 1) {
          side = bottomRight;
        } else if (y == area.minY) {
          side = top;
        } else if (y == area.maxY - 1) {
          side = bottom;
        } else if (x == area.minX) {
          side = left;
        } else if (x == area.maxX - 1) {
          side = right;
        } else {
          continue;
        }

        final cell = Cell.newCell(screen.widthMethod(), side.content)
          ..style = side.style
          ..link = side.link;
        screen.setCell(x, y, cell);
      }
    }
  }
}

// Constructors (parity with Ultraviolet).

UvBorder normalBorder() => const UvBorder(
  top: Side(content: '─'),
  bottom: Side(content: '─'),
  left: Side(content: '│'),
  right: Side(content: '│'),
  topLeft: Side(content: '┌'),
  topRight: Side(content: '┐'),
  bottomLeft: Side(content: '└'),
  bottomRight: Side(content: '┘'),
);

/// Creates a rounded border style.
UvBorder roundedBorder() => const UvBorder(
  top: Side(content: '─'),
  bottom: Side(content: '─'),
  left: Side(content: '│'),
  right: Side(content: '│'),
  topLeft: Side(content: '╭'),
  topRight: Side(content: '╮'),
  bottomLeft: Side(content: '╰'),
  bottomRight: Side(content: '╯'),
);

/// Creates a solid block border style.
UvBorder blockBorder() => const UvBorder(
  top: Side(content: '█'),
  bottom: Side(content: '█'),
  left: Side(content: '█'),
  right: Side(content: '█'),
  topLeft: Side(content: '█'),
  topRight: Side(content: '█'),
  bottomLeft: Side(content: '█'),
  bottomRight: Side(content: '█'),
);

/// Creates an outer half-block border style.
UvBorder outerHalfBlockBorder() => const UvBorder(
  top: Side(content: '▀'),
  bottom: Side(content: '▄'),
  left: Side(content: '▌'),
  right: Side(content: '▐'),
  topLeft: Side(content: '▛'),
  topRight: Side(content: '▜'),
  bottomLeft: Side(content: '▙'),
  bottomRight: Side(content: '▟'),
);

/// Creates an inner half-block border style.
UvBorder innerHalfBlockBorder() => const UvBorder(
  top: Side(content: '▄'),
  bottom: Side(content: '▀'),
  left: Side(content: '▐'),
  right: Side(content: '▌'),
  topLeft: Side(content: '▗'),
  topRight: Side(content: '▖'),
  bottomLeft: Side(content: '▝'),
  bottomRight: Side(content: '▘'),
);

/// Creates a thick line border style.
UvBorder thickBorder() => const UvBorder(
  top: Side(content: '━'),
  bottom: Side(content: '━'),
  left: Side(content: '┃'),
  right: Side(content: '┃'),
  topLeft: Side(content: '┏'),
  topRight: Side(content: '┓'),
  bottomLeft: Side(content: '┗'),
  bottomRight: Side(content: '┛'),
);

/// Creates a double line border style.
UvBorder doubleBorder() => const UvBorder(
  top: Side(content: '═'),
  bottom: Side(content: '═'),
  left: Side(content: '║'),
  right: Side(content: '║'),
  topLeft: Side(content: '╔'),
  topRight: Side(content: '╗'),
  bottomLeft: Side(content: '╚'),
  bottomRight: Side(content: '╝'),
);

/// Creates an invisible border style (spaces for all sides).
UvBorder hiddenBorder() => const UvBorder(
  top: Side(content: ' '),
  bottom: Side(content: ' '),
  left: Side(content: ' '),
  right: Side(content: ' '),
  topLeft: Side(content: ' '),
  topRight: Side(content: ' '),
  bottomLeft: Side(content: ' '),
  bottomRight: Side(content: ' '),
);

/// Creates a markdown-style border using `|` for verticals.
UvBorder markdownBorder() => const UvBorder(
  top: Side(content: ''),
  bottom: Side(content: ''),
  left: Side(content: '|'),
  right: Side(content: '|'),
  topLeft: Side(content: '|'),
  topRight: Side(content: '|'),
  bottomLeft: Side(content: '|'),
  bottomRight: Side(content: '|'),
);

/// Creates a plain ASCII border style.
UvBorder asciiBorder() => const UvBorder(
  top: Side(content: '-'),
  bottom: Side(content: '-'),
  left: Side(content: '|'),
  right: Side(content: '|'),
  topLeft: Side(content: '+'),
  topRight: Side(content: '+'),
  bottomLeft: Side(content: '+'),
  bottomRight: Side(content: '+'),
);
