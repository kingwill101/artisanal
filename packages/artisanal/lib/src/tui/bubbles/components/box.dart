import '../../../style/border.dart' as style_border;
import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A key-value pair component with dot fill.
class KeyValue extends DisplayComponent {
  const KeyValue({
    required this.key,
    required this.value,
    this.fillChar = '.',
    this.width,
    this.renderConfig = const RenderConfig(),
  });

  final String key;
  final String value;
  final String fillChar;
  final int? width;
  final RenderConfig renderConfig;

  @override
  String render() {
    final totalWidth = width ?? renderConfig.terminalWidth;
    final keyLen = Style.visibleLength(key);
    final valueLen = Style.visibleLength(value);
    final fillLen = totalWidth - keyLen - valueLen - 2;
    final fill = fillLen > 0 ? ' ${fillChar * fillLen} ' : ' ';

    return '$key$fill$value';
  }
}

/// A boxed message component.
class Box extends DisplayComponent {
  const Box({
    required this.content,
    this.title,
    this.borderStyle = BorderStyle.rounded,
    this.padding = 1,
    this.renderConfig = const RenderConfig(),
  });

  final String content;
  final String? title;
  final BorderStyle borderStyle;
  final int padding;
  final RenderConfig renderConfig;

  @override
  String render() {
    final chars = borderStyle.chars;
    final lines = content.split('\n');
    final maxLen = lines
        .map((l) => Style.visibleLength(l))
        .reduce((a, b) => a > b ? a : b);
    final innerWidth = maxLen + (padding * 2);

    final buffer = StringBuffer();

    // Top border
    if (title != null) {
      final titlePart = '${chars.horizontal} $title ';
      final remaining = innerWidth - titlePart.length;
      buffer.writeln(
        '${chars.topLeft}$titlePart${chars.horizontal * remaining}${chars.topRight}',
      );
    } else {
      buffer.writeln(
        '${chars.topLeft}${chars.horizontal * innerWidth}${chars.topRight}',
      );
    }

    // Content
    final pad = ' ' * padding;
    for (final line in lines) {
      final lineLen = Style.visibleLength(line);
      final rightPad = ' ' * (maxLen - lineLen);
      buffer.writeln(
        '${chars.vertical}$pad$line$rightPad$pad${chars.vertical}',
      );
    }

    // Bottom border
    buffer.write(
      '${chars.bottomLeft}${chars.horizontal * innerWidth}${chars.bottomRight}',
    );

    return buffer.toString();
  }
}

/// Border styles for boxes.
enum BorderStyle {
  rounded,
  single,
  double,
  heavy,
  ascii;

  ComponentBoxChars get chars => switch (this) {
    BorderStyle.rounded => ComponentBoxChars.rounded,
    BorderStyle.single => ComponentBoxChars.single,
    BorderStyle.double => ComponentBoxChars.double,
    BorderStyle.heavy => ComponentBoxChars.heavy,
    BorderStyle.ascii => ComponentBoxChars.ascii,
  };
}

/// Box drawing characters for component system.
class ComponentBoxChars {
  const ComponentBoxChars({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.horizontal,
    required this.vertical,
  });

  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String horizontal;
  final String vertical;

  static const rounded = ComponentBoxChars(
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    horizontal: '─',
    vertical: '│',
  );

  static const single = ComponentBoxChars(
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
    horizontal: '─',
    vertical: '│',
  );

  static const double = ComponentBoxChars(
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
    horizontal: '═',
    vertical: '║',
  );

  static const heavy = ComponentBoxChars(
    topLeft: '┏',
    topRight: '┓',
    bottomLeft: '┗',
    bottomRight: '┛',
    horizontal: '━',
    vertical: '┃',
  );

  static const ascii = ComponentBoxChars(
    topLeft: '+',
    topRight: '+',
    bottomLeft: '+',
    bottomRight: '+',
    horizontal: '-',
    vertical: '|',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Box Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Alignment for box content.
enum BoxAlign { left, center, right }

/// Callback for box content styling.
///
/// [line] is the content line being rendered.
/// [lineIndex] is the index of the line (0-based).
///
/// Return a [Style] to apply to the line, or `null` for no styling.
typedef BoxContentStyleFunc = Style? Function(String line, int lineIndex);

/// A fluent builder for creating styled boxes.
///
/// Provides a chainable API for box configuration with support for
/// the new Style system, custom borders, and per-line content styling.
///
/// ```dart
/// final box = BoxBuilder()
///     .title('Welcome')
///     .content('Hello, World!\nThis is a styled box.')
///     .border(Border.rounded)
///     .titleStyle(Style().bold().foreground(Colors.cyan))
///     .borderStyle(Style().foreground(Colors.gray))
///     .padding(1, 2)
///     .width(50)
///     .render();
///
/// print(box);
/// ```
class BoxBuilder extends DisplayComponent {
  /// Creates a new empty box builder.
  BoxBuilder({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  String? _title;
  final List<String> _content = [];
  style_border.Border _border = style_border.Border.rounded;
  Style? _titleStyle;
  Style? _borderStyle;
  Style? _contentStyle;
  BoxContentStyleFunc? _contentStyleFunc;
  BoxAlign _titleAlign = BoxAlign.left;
  BoxAlign _contentAlign = BoxAlign.left;
  int _paddingTop = 0;
  int _paddingRight = 1;
  int _paddingBottom = 0;
  int _paddingLeft = 1;
  int _marginTop = 0;
  // ignore: unused_field - reserved for future use with layout primitives
  int _marginRight = 0;
  int _marginBottom = 0;
  int _marginLeft = 0;
  int? _width;
  int? _minWidth;
  int? _maxWidth;

  /// Sets the box title.
  BoxBuilder title(String title) {
    _title = title;
    return this;
  }

  /// Sets the box content from a string.
  ///
  /// Multi-line strings are automatically split.
  BoxBuilder content(String text) {
    _content.clear();
    _content.addAll(text.split('\n'));
    return this;
  }

  /// Sets the box content from a list of lines.
  BoxBuilder lines(List<String> lines) {
    _content.clear();
    _content.addAll(lines);
    return this;
  }

  /// Adds a line to the box content.
  BoxBuilder line(String text) {
    _content.add(text);
    return this;
  }

  /// Sets the border style (characters).
  BoxBuilder border(style_border.Border border) {
    _border = border;
    return this;
  }

  /// Sets the title text style.
  BoxBuilder titleStyle(Style style) {
    _titleStyle = style;
    return this;
  }

  /// Sets the border text style.
  BoxBuilder borderStyle(Style style) {
    _borderStyle = style;
    return this;
  }

  /// Sets the content text style (applied to all content).
  BoxBuilder contentStyle(Style style) {
    _contentStyle = style;
    return this;
  }

  /// Sets the content style function for per-line styling.
  ///
  /// Takes precedence over [contentStyle] when both are set.
  BoxBuilder contentStyleFunc(BoxContentStyleFunc func) {
    _contentStyleFunc = func;
    return this;
  }

  /// Sets the title alignment.
  BoxBuilder titleAlign(BoxAlign align) {
    _titleAlign = align;
    return this;
  }

  /// Sets the content alignment.
  BoxBuilder contentAlign(BoxAlign align) {
    _contentAlign = align;
    return this;
  }

  /// Sets uniform padding (all sides).
  BoxBuilder padding(int vertical, [int? horizontal]) {
    _paddingTop = vertical;
    _paddingBottom = vertical;
    _paddingLeft = horizontal ?? vertical;
    _paddingRight = horizontal ?? vertical;
    return this;
  }

  /// Sets individual padding values.
  BoxBuilder paddingAll({int? top, int? right, int? bottom, int? left}) {
    if (top != null) _paddingTop = top;
    if (right != null) _paddingRight = right;
    if (bottom != null) _paddingBottom = bottom;
    if (left != null) _paddingLeft = left;
    return this;
  }

  /// Sets uniform margin (all sides).
  BoxBuilder margin(int vertical, [int? horizontal]) {
    _marginTop = vertical;
    _marginBottom = vertical;
    _marginLeft = horizontal ?? vertical;
    _marginRight = horizontal ?? vertical;
    return this;
  }

  /// Sets individual margin values.
  BoxBuilder marginAll({int? top, int? right, int? bottom, int? left}) {
    if (top != null) _marginTop = top;
    if (right != null) _marginRight = right;
    if (bottom != null) _marginBottom = bottom;
    if (left != null) _marginLeft = left;
    return this;
  }

  /// Sets the fixed width of the box.
  BoxBuilder width(int value) {
    _width = value;
    return this;
  }

  /// Sets the minimum width of the box.
  BoxBuilder minWidth(int value) {
    _minWidth = value;
    return this;
  }

  /// Sets the maximum width of the box.
  BoxBuilder maxWidth(int value) {
    _maxWidth = value;
    return this;
  }

  @override
  String render() {
    final content = _content.isEmpty ? [''] : _content;

    // Calculate content width
    var contentWidth = 0;
    for (final line in content) {
      final len = Style.visibleLength(line);
      if (len > contentWidth) contentWidth = len;
    }

    // Account for title width
    var titleWidth = 0;
    if (_title != null) {
      titleWidth = Style.visibleLength(_title!) + 4; // spaces and padding
    }

    // Calculate inner width
    var innerWidth = contentWidth;
    if (titleWidth > innerWidth) innerWidth = titleWidth;

    // Apply width constraints
    if (_minWidth != null && innerWidth < _minWidth!) {
      innerWidth = _minWidth!;
    }
    if (_maxWidth != null && innerWidth > _maxWidth!) {
      innerWidth = _maxWidth!;
    }
    if (_width != null) {
      innerWidth = _width! - 2 - _paddingLeft - _paddingRight;
    }

    // Total inner width including padding
    final totalInnerWidth = innerWidth + _paddingLeft + _paddingRight;

    final buffer = StringBuffer();
    final b = _border;

    // Helper to style border characters
    String styleBorder(String text) {
      if (_borderStyle == null) return text;
      return _renderConfig.configureStyle(_borderStyle!).render(text);
    }

    // Helper to style title
    String styleTitle(String text) {
      if (_titleStyle == null) return text;
      return _renderConfig.configureStyle(_titleStyle!).render(text);
    }

    // Helper to style content
    String styleContent(String text, int lineIndex) {
      if (_contentStyleFunc != null) {
        final style = _contentStyleFunc!(text, lineIndex);
        if (style != null) {
          return _renderConfig.configureStyle(style).render(text);
        }
        return text;
      }
      if (_contentStyle != null) {
        return _renderConfig.configureStyle(_contentStyle!).render(text);
      }
      return text;
    }

    // Add top margin
    for (var i = 0; i < _marginTop; i++) {
      buffer.writeln();
    }

    final leftMargin = ' ' * _marginLeft;

    // Build top border
    if (_title != null) {
      final styledTitle = ' ${styleTitle(_title!)} ';
      final titleLen = Style.visibleLength(styledTitle);
      final remaining = totalInnerWidth - titleLen;

      String topLine;
      switch (_titleAlign) {
        case BoxAlign.left:
          final rightFill = b.top * (remaining - 1);
          topLine = '${b.topLeft}${b.top}$styledTitle$rightFill${b.topRight}';
        case BoxAlign.center:
          final leftFill = b.top * (remaining ~/ 2);
          final rightFill = b.top * (remaining - remaining ~/ 2);
          topLine = '${b.topLeft}$leftFill$styledTitle$rightFill${b.topRight}';
        case BoxAlign.right:
          final leftFill = b.top * (remaining - 1);
          topLine = '${b.topLeft}$leftFill$styledTitle${b.top}${b.topRight}';
      }
      buffer.writeln('$leftMargin${styleBorder(topLine)}');
    } else {
      buffer.writeln(
        '$leftMargin${styleBorder('${b.topLeft}${b.top * totalInnerWidth}${b.topRight}')}',
      );
    }

    // Add top padding lines
    for (var i = 0; i < _paddingTop; i++) {
      buffer.writeln(
        '$leftMargin${styleBorder(b.left)}${' ' * totalInnerWidth}${styleBorder(b.right)}',
      );
    }

    // Content lines
    for (var i = 0; i < content.length; i++) {
      final line = content[i];
      final visible = Style.visibleLength(line);
      final fill = innerWidth - visible;

      String alignedContent;
      switch (_contentAlign) {
        case BoxAlign.left:
          alignedContent = '$line${' ' * (fill > 0 ? fill : 0)}';
        case BoxAlign.center:
          final leftPad = ' ' * (fill ~/ 2);
          final rightPad = ' ' * (fill - fill ~/ 2);
          alignedContent = '$leftPad$line$rightPad';
        case BoxAlign.right:
          alignedContent = '${' ' * (fill > 0 ? fill : 0)}$line';
      }

      final styledContent = styleContent(alignedContent, i);
      final leftPad = ' ' * _paddingLeft;
      final rightPad = ' ' * _paddingRight;

      buffer.writeln(
        '$leftMargin${styleBorder(b.left)}$leftPad$styledContent$rightPad${styleBorder(b.right)}',
      );
    }

    // Add bottom padding lines
    for (var i = 0; i < _paddingBottom; i++) {
      buffer.writeln(
        '$leftMargin${styleBorder(b.left)}${' ' * totalInnerWidth}${styleBorder(b.right)}',
      );
    }

    // Bottom border
    buffer.write(
      '$leftMargin${styleBorder('${b.bottomLeft}${b.bottom * totalInnerWidth}${b.bottomRight}')}',
    );

    // Add bottom margin (only if needed)
    for (var i = 0; i < _marginBottom; i++) {
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  int get lineCount {
    var count = 2; // Top and bottom borders
    count += _paddingTop + _paddingBottom;
    count += _marginTop + _marginBottom;
    count += _content.isEmpty ? 1 : _content.length;
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Box Presets
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common box styles.
extension BoxPresets on BoxBuilder {
  /// Creates an info-styled box.
  static BoxBuilder info(String title, String content) {
    return BoxBuilder()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.blue));
  }

  /// Creates a success-styled box.
  static BoxBuilder success(String title, String content) {
    return BoxBuilder()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.success));
  }

  /// Creates a warning-styled box.
  static BoxBuilder warning(String title, String content) {
    return BoxBuilder()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.warning));
  }

  /// Creates an error-styled box.
  static BoxBuilder error(String title, String content) {
    return BoxBuilder()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.error));
  }

  /// Creates a simple box without title.
  static BoxBuilder simple(String content) {
    return BoxBuilder()
      ..content(content)
      ..border(style_border.Border.rounded);
  }

  /// Creates a double-bordered box.
  static BoxBuilder doubleBorder(String title, String content) {
    return BoxBuilder()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.double);
  }

  /// Creates an ASCII-compatible box.
  static BoxBuilder ascii(String content, {String? title}) {
    final box = BoxBuilder()
      ..content(content)
      ..border(style_border.Border.ascii);
    if (title != null) box.title(title);
    return box;
  }
}
