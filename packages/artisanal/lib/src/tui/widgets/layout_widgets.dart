/// Layout widgets for composing UI.
///
/// Provides Row, Column, and other layout primitives that use
/// the Layout API internally.
///
/// ```dart
/// Column(
///   gap: 1,
///   children: [
///     Text('Title'),
///     Row(children: [button1, button2]),
///   ],
/// )
/// ```
library;

import '../../layout/layout.dart';
import '../../style/properties.dart';
import '../../style/style.dart';
import '../../style/color.dart';
import '../../uv/canvas.dart';
import '../../uv/cell.dart';
import '../../uv/geometry.dart';
import '../../uv/styled_string.dart';
import 'widget.dart';
import 'theme.dart' show currentTheme;

/// Converts a style [Color] to a UV [UvColor].
///
/// Parses the hex representation of the color to extract RGB values.
UvColor? _colorToUvColor(Color? color) {
  if (color == null || color is NoColor) return null;

  final hex = color.toHex();
  if (hex.isEmpty) {
    // For ANSI colors, try to get the ANSI code
    if (color is AnsiColor) {
      return UvColor.indexed256(color.code);
    }
    return null;
  }

  // Parse hex color (#rrggbb or rrggbb)
  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  if (normalized.length != 6) return null;

  final r = int.tryParse(normalized.substring(0, 2), radix: 16) ?? 0;
  final g = int.tryParse(normalized.substring(2, 4), radix: 16) ?? 0;
  final b = int.tryParse(normalized.substring(4, 6), radix: 16) ?? 0;

  return UvColor.rgb(r, g, b);
}

/// A widget that arranges children horizontally.
///
/// Uses [Layout.joinHorizontal] to compose child views side by side.
///
/// ```dart
/// HBox(
///   gap: 2,
///   align: VerticalAlign.center,
///   children: [icon, label, spacer, button],
/// )
/// ```
class HBox extends Widget {
  HBox({
    required this.children,
    this.gap = 1,
    this.align = VerticalAlign.top,
    String? id,
  }) : _id = id ?? 'hbox-${_counter++}';

  static int _counter = 0;

  final String _id;

  @override
  final List<Widget> children;

  /// Gap between children in characters.
  final int gap;

  /// Vertical alignment of children.
  final VerticalAlign align;

  @override
  String get id => _id;

  @override
  Object view() {
    if (children.isEmpty) return '';

    final rendered = children.map((c) {
      final v = c.view();
      return v is String ? v : v.toString();
    }).toList();

    return Layout.joinHorizontal(align, rendered, gap: gap);
  }
}

/// A widget that arranges children vertically.
///
/// Uses [Layout.joinVertical] to stack child views.
///
/// ```dart
/// VBox(
///   gap: 1,
///   align: HorizontalAlign.left,
///   children: [header, content, footer],
/// )
/// ```
class VBox extends Widget {
  VBox({
    required this.children,
    this.gap = 0,
    this.align = HorizontalAlign.left,
    String? id,
  }) : _id = id ?? 'vbox-${_counter++}';

  static int _counter = 0;

  final String _id;

  @override
  final List<Widget> children;

  /// Gap between children in lines.
  final int gap;

  /// Horizontal alignment of children.
  final HorizontalAlign align;

  @override
  String get id => _id;

  @override
  Object view() {
    if (children.isEmpty) return '';

    final rendered = children.map((c) {
      final v = c.view();
      return v is String ? v : v.toString();
    }).toList();

    return Layout.joinVertical(align, rendered, gap: gap);
  }
}

/// A widget that displays styled text.
///
/// ```dart
/// Label('Hello', style: theme.titleLarge)
/// Label.styled('Error!', style: Style().foreground(Colors.error))
/// ```
class Label extends Widget {
  Label(this.content, {this.style, String? id})
    : _id = id ?? 'label-${_counter++}';

  /// Create text with a specific style.
  Label.styled(this.content, {required Style this.style, String? id})
    : _id = id ?? 'label-${_counter++}';

  static int _counter = 0;

  final String _id;

  /// The text content.
  final String content;

  /// Optional style to apply.
  final Style? style;

  @override
  String get id => _id;

  @override
  List<Widget> get children => const [];

  @override
  Object view() {
    if (style != null) {
      return style!.render(content);
    }
    return content;
  }
}

/// A widget that adds padding, margin, or background to a child.
///
/// ```dart
/// Container(
///   padding: EdgeInsets.all(1),
///   background: theme.surface,
///   child: Text('Content'),
/// )
/// ```
class Container extends Widget {
  Container({
    this.child,
    this.padding,
    this.width,
    this.height,
    this.background,
    this.foreground,
    this.align = HorizontalAlign.left,
    this.verticalAlign = VerticalAlign.top,
    String? id,
  }) : _id = id ?? 'container-${_counter++}';

  static int _counter = 0;

  final String _id;

  /// The child widget.
  final Widget? child;

  /// Padding around the child.
  final EdgeInsets? padding;

  /// Fixed width in characters.
  final int? width;

  /// Fixed height in lines.
  final int? height;

  /// Background color.
  final Color? background;

  /// Foreground (text) color.
  final Color? foreground;

  /// Horizontal alignment when width is set.
  final HorizontalAlign align;

  /// Vertical alignment when height is set.
  final VerticalAlign verticalAlign;

  @override
  String get id => _id;

  @override
  List<Widget> get children => child != null ? [child!] : const [];

  @override
  Object view() {
    final contentStr = child != null ? _viewToString(child!.view()) : '';

    // Calculate content dimensions
    final contentWidth = Layout.getWidth(contentStr);
    final contentHeight = Layout.getHeight(contentStr);

    // Calculate padding offsets
    final padLeft = padding?.left ?? 0;
    final padRight = padding?.right ?? 0;
    final padTop = padding?.top ?? 0;
    final padBottom = padding?.bottom ?? 0;

    // Calculate target dimensions (with padding)
    final paddedWidth = contentWidth + padLeft + padRight;
    final paddedHeight = contentHeight + padTop + padBottom;

    // Use explicit size if provided, otherwise use padded content size
    final targetWidth = width ?? paddedWidth;
    final targetHeight = height ?? paddedHeight;

    // Empty container
    if (targetWidth == 0 || targetHeight == 0) return '';

    // Use Canvas-based rendering for consistent ANSI handling
    final canvas = Canvas(targetWidth, targetHeight);

    // Create background style
    final bgColor = _colorToUvColor(background);
    final fgColor = _colorToUvColor(foreground);
    final bgStyle = UvStyle(bg: bgColor, fg: fgColor);

    // Fill entire canvas with background (or spaces if no style)
    final bgCell = Cell(content: ' ', width: 1, style: bgStyle);
    for (var y = 0; y < targetHeight; y++) {
      for (var x = 0; x < targetWidth; x++) {
        canvas.setCell(x, y, bgCell.clone());
      }
    }

    // Calculate content offset based on alignment within target size
    final offsetX = width != null
        ? switch (align) {
            HorizontalAlign.left => padLeft,
            HorizontalAlign.center => (targetWidth - contentWidth) ~/ 2,
            HorizontalAlign.right => targetWidth - contentWidth - padRight,
          }
        : padLeft;

    final offsetY = height != null
        ? switch (verticalAlign) {
            VerticalAlign.top => padTop,
            VerticalAlign.center => (targetHeight - contentHeight) ~/ 2,
            VerticalAlign.bottom => targetHeight - contentHeight - padBottom,
          }
        : padTop;

    // Draw child content at the offset position
    if (contentStr.isNotEmpty) {
      _drawStyledContent(canvas, contentStr, offsetX, offsetY, bgStyle);
    }

    var result = canvas.render();

    // Canvas.render() trims trailing spaces. If explicit width was set,
    // pad lines to maintain the requested width for proper layout alignment.
    if (width != null) {
      result = _padToWidth(result, targetWidth, targetHeight);
    }

    return result;
  }

  /// Pads output lines to maintain explicit width (Canvas trims trailing spaces).
  String _padToWidth(String content, int targetWidth, int targetHeight) {
    final lines = content.split('\n');
    final result = <String>[];

    for (var i = 0; i < targetHeight; i++) {
      final line = i < lines.length ? lines[i] : '';
      final lineWidth = Layout.visibleLength(line);
      if (lineWidth < targetWidth) {
        result.add('$line${' ' * (targetWidth - lineWidth)}');
      } else {
        result.add(line);
      }
    }

    return result.join('\n');
  }

  /// Draws styled content onto canvas, merging with background style.
  void _drawStyledContent(
    Canvas canvas,
    String content,
    int startX,
    int startY,
    UvStyle bgStyle,
  ) {
    final styledBounds = StyledString(content).bounds();
    final tempCanvas = Canvas(styledBounds.width, styledBounds.height);
    StyledString(content).draw(tempCanvas, tempCanvas.bounds());

    for (var y = 0; y < styledBounds.height; y++) {
      for (var x = 0; x < styledBounds.width; x++) {
        final destX = startX + x;
        final destY = startY + y;

        if (destX >= canvas.width() || destY >= canvas.height()) continue;

        final srcCell = tempCanvas.cellAt(x, y);
        if (srcCell == null || srcCell.isZero) continue;

        // Merge background into cell if cell has no background
        final mergedStyle = srcCell.style.bg == null && bgStyle.bg != null
            ? srcCell.style.copyWith(bg: bgStyle.bg)
            : srcCell.style;

        canvas.setCell(
          destX,
          destY,
          Cell(
            content: srcCell.content,
            width: srcCell.width,
            style: mergedStyle,
            link: srcCell.link,
          ),
        );
      }
    }
  }

  String _viewToString(Object v) => v is String ? v : v.toString();
}

/// Edge insets for padding/margin.
class EdgeInsets {
  const EdgeInsets.all(int value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  const EdgeInsets.symmetric({int vertical = 0, int horizontal = 0})
    : top = vertical,
      right = horizontal,
      bottom = vertical,
      left = horizontal;

  const EdgeInsets.only({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  static const EdgeInsets zero = EdgeInsets.all(0);

  final int top;
  final int right;
  final int bottom;
  final int left;
}

/// A flexible spacer widget.
///
/// In a Row, takes up horizontal space. In a Column, takes up vertical space.
/// The actual space is determined by the fill character count.
class Spacer extends Widget {
  Spacer({this.size = 1, this.fill = ' ', String? id})
    : _id = id ?? 'spacer-${_counter++}';

  static int _counter = 0;

  final String _id;

  /// Number of fill characters.
  final int size;

  /// Character to fill with.
  final String fill;

  @override
  String get id => _id;

  @override
  Object view() => fill * size;
}

/// A widget that takes up empty space.
///
/// Useful for centering or pushing content to edges in flex layouts.
class Expanded extends Widget {
  Expanded({required this.child, this.flex = 1, String? id})
    : _id = id ?? 'expanded-${_counter++}';

  static int _counter = 0;

  final String _id;
  final Widget child;
  final int flex;

  @override
  String get id => _id;

  @override
  List<Widget> get children => [child];

  @override
  Object view() => child.view();
}

/// A divider line widget.
///
/// ```dart
/// Divider()          // ────────────
/// Divider(char: '═') // ════════════
/// ```
class Divider extends Widget {
  Divider({this.width = 40, this.char = '─', this.style, String? id})
    : _id = id ?? 'divider-${_counter++}';

  static int _counter = 0;

  final String _id;

  /// Width of the divider.
  final int width;

  /// Character to use.
  final String char;

  /// Optional style.
  final Style? style;

  @override
  String get id => _id;

  @override
  Object view() {
    var content = char * width;
    if (style != null) {
      content = style!.render(content);
    } else {
      content = Style().foreground(currentTheme.border).render(content);
    }
    return content;
  }
}
