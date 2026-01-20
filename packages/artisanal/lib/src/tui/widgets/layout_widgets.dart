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
import 'widget.dart';
import 'theme.dart' show currentTheme;

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
    var content = child != null ? _viewToString(child!.view()) : '';

    // Apply padding
    if (padding != null) {
      content = _applyPadding(content, padding!);
    }

    // Apply size constraints and alignment
    if (width != null || height != null) {
      content = Layout.place(
        width: width ?? Layout.getWidth(content),
        height: height ?? Layout.getHeight(content),
        horizontal: align,
        vertical: verticalAlign,
        content: content,
      );
    }

    // Apply colors
    if (background != null || foreground != null) {
      var style = Style();
      if (background != null) style = style.background(background!);
      if (foreground != null) style = style.foreground(foreground!);
      content = style.render(content);
    }

    return content;
  }

  String _applyPadding(String content, EdgeInsets padding) {
    final lines = content.split('\n');
    final contentWidth = Layout.getWidth(content);
    final paddedWidth = contentWidth + padding.left + padding.right;

    final result = <String>[];

    // Top padding
    for (var i = 0; i < padding.top; i++) {
      result.add(' ' * paddedWidth);
    }

    // Content with left/right padding
    for (final line in lines) {
      final lineWidth = Layout.visibleLength(line);
      final rightPad = contentWidth - lineWidth + padding.right;
      result.add('${' ' * padding.left}$line${' ' * rightPad}');
    }

    // Bottom padding
    for (var i = 0; i < padding.bottom; i++) {
      result.add(' ' * paddedWidth);
    }

    return result.join('\n');
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
