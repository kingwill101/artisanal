import '../../../style/border.dart' as style_border;
import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';
import 'panel_chars.dart';

/// Alignment for panel content.
enum PanelAlignment { left, center, right }

/// A boxed panel component with optional title.
///
/// ```dart
/// PanelComponent(
///   content: 'Hello, World!',
///   title: 'Greeting',
/// ).render();
/// ```
class PanelComponent extends DisplayComponent {
  const PanelComponent({
    required this.content,
    this.title,
    this.titleAlign = PanelAlignment.left,
    this.contentAlign = PanelAlignment.left,
    this.chars = PanelBoxChars.rounded,
    this.padding = 1,
    this.width,
    this.borderStyle,
    this.renderConfig = const RenderConfig(),
  });

  final Object content;
  final String? title;
  final PanelAlignment titleAlign;
  final PanelAlignment contentAlign;
  final PanelBoxCharSet chars;
  final int padding;
  final int? width;
  final Style? borderStyle;
  final RenderConfig renderConfig;

  @override
  String render() {
    final lines = _normalizeLines(content);
    final effectiveBorderStyle = renderConfig.configureStyle(
      borderStyle ?? Style().dim(),
    );
    final titleStyle = renderConfig.configureStyle(Style().bold());
    String border(String s) => effectiveBorderStyle.render(s);
    String titleFn(String s) => titleStyle.render(s);

    // Calculate width
    final contentWidth = lines
        .map((l) => Style.visibleLength(l))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final titleWidth = title != null ? Style.visibleLength(title!) + 4 : 0;
    final minWidth = [
      contentWidth,
      titleWidth,
      10,
    ].reduce((a, b) => a > b ? a : b);
    // Ensure minBound doesn't exceed maxBound for clamp
    final minBound = minWidth + padding * 2 + 2;
    final maxBound = renderConfig.terminalWidth;
    final boxWidth = (width ?? minBound).clamp(
      minBound < maxBound ? minBound : maxBound,
      maxBound,
    );
    final innerWidth = boxWidth - 2;

    final buffer = StringBuffer();
    final pad = ' ' * padding;

    // Top border with optional title
    if (title != null) {
      final styledTitle = ' ${titleFn(title!)} ';
      final titleLen = Style.visibleLength(styledTitle);
      final remainingWidth = innerWidth - titleLen;

      String topLine;
      switch (titleAlign) {
        case PanelAlignment.left:
          final rightFill = chars.horizontal * (remainingWidth - 1);
          topLine =
              '${chars.topLeft}${chars.horizontal}$styledTitle$rightFill${chars.topRight}';
        case PanelAlignment.center:
          final leftFill = chars.horizontal * (remainingWidth ~/ 2);
          final rightFill =
              chars.horizontal * (remainingWidth - remainingWidth ~/ 2);
          topLine =
              '${chars.topLeft}$leftFill$styledTitle$rightFill${chars.topRight}';
        case PanelAlignment.right:
          final leftFill = chars.horizontal * (remainingWidth - 1);
          topLine =
              '${chars.topLeft}$leftFill$styledTitle${chars.horizontal}${chars.topRight}';
      }
      buffer.writeln(border(topLine));
    } else {
      buffer.writeln(
        border(
          '${chars.topLeft}${chars.horizontal * innerWidth}${chars.topRight}',
        ),
      );
    }

    // Content lines
    for (final line in lines) {
      final visible = Style.visibleLength(line);
      final available = innerWidth - padding * 2;
      final fill = available - visible;

      String paddedLine;
      switch (contentAlign) {
        case PanelAlignment.left:
          paddedLine = '$pad$line${' ' * (fill > 0 ? fill : 0)}$pad';
        case PanelAlignment.center:
          final leftPad = ' ' * (fill ~/ 2);
          final rightPad = ' ' * (fill - fill ~/ 2);
          paddedLine = '$pad$leftPad$line$rightPad$pad';
        case PanelAlignment.right:
          paddedLine = '$pad${' ' * (fill > 0 ? fill : 0)}$line$pad';
      }

      buffer.writeln(
        '${border(chars.vertical)}$paddedLine${border(chars.vertical)}',
      );
    }

    // Bottom border
    buffer.write(
      border(
        '${chars.bottomLeft}${chars.horizontal * innerWidth}${chars.bottomRight}',
      ),
    );

    return buffer.toString();
  }

  List<String> _normalizeLines(Object content) {
    if (content is Iterable) {
      return content.map((e) => e.toString()).toList();
    }
    return content.toString().split('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Panel Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Callback for panel content styling.
///
/// [line] is the content line being rendered.
/// [lineIndex] is the index of the line (0-based).
///
/// Return a [Style] to apply to the line, or `null` for no styling.
typedef PanelContentStyleFunc = Style? Function(String line, int lineIndex);

/// A fluent builder for creating styled panels.
///
/// Provides a chainable API for panel configuration with support for
/// the new Style system, custom borders, and per-line content styling.
///
/// ```dart
/// final panel = Panel()
///     .title('Welcome')
///     .content('Hello, World!\nThis is a styled panel.')
///     .border(Border.rounded)
///     .titleStyle(Style().bold().foreground(Colors.cyan))
///     .borderStyle(Style().foreground(Colors.gray))
///     .padding(1, 2)
///     .width(50)
///     .render();
///
/// print(panel);
/// ```
class Panel extends DisplayComponent {
  /// Creates a new empty panel builder.
  Panel({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  String? _title;
  final List<String> _content = [];
  style_border.Border _border = style_border.Border.rounded;
  Style? _titleStyle;
  Style? _borderStyle;
  Style? _contentStyle;
  PanelContentStyleFunc? _contentStyleFunc;
  PanelAlignment _titleAlign = PanelAlignment.left;
  PanelAlignment _contentAlign = PanelAlignment.left;
  int _paddingTop = 0;
  int _paddingRight = 1;
  int _paddingBottom = 0;
  int _paddingLeft = 1;
  int? _width;
  int? _minWidth;
  int? _maxWidth;

  /// Sets the panel title.
  Panel title(String title) {
    _title = title;
    return this;
  }

  /// Sets the panel content from a string.
  ///
  /// Multi-line strings are automatically split.
  Panel content(String text) {
    _content.clear();
    _content.addAll(text.split('\n'));
    return this;
  }

  /// Sets the panel content from a list of lines.
  Panel lines(List<String> lines) {
    _content.clear();
    _content.addAll(lines);
    return this;
  }

  /// Adds a line to the panel content.
  Panel line(String text) {
    _content.add(text);
    return this;
  }

  /// Sets the border style (characters).
  Panel border(style_border.Border border) {
    _border = border;
    return this;
  }

  /// Sets the title text style.
  Panel titleStyle(Style style) {
    _titleStyle = style;
    return this;
  }

  /// Sets the border text style.
  Panel borderStyle(Style style) {
    _borderStyle = style;
    return this;
  }

  /// Sets the content text style (applied to all content).
  Panel contentStyle(Style style) {
    _contentStyle = style;
    return this;
  }

  /// Sets the content style function for per-line styling.
  ///
  /// Takes precedence over [contentStyle] when both are set.
  Panel contentStyleFunc(PanelContentStyleFunc func) {
    _contentStyleFunc = func;
    return this;
  }

  /// Sets the title alignment.
  Panel titleAlign(PanelAlignment align) {
    _titleAlign = align;
    return this;
  }

  /// Sets the content alignment.
  Panel contentAlign(PanelAlignment align) {
    _contentAlign = align;
    return this;
  }

  /// Sets uniform padding (all sides).
  Panel padding(int vertical, [int? horizontal]) {
    _paddingTop = vertical;
    _paddingBottom = vertical;
    _paddingLeft = horizontal ?? vertical;
    _paddingRight = horizontal ?? vertical;
    return this;
  }

  /// Sets individual padding values.
  Panel paddingAll({int? top, int? right, int? bottom, int? left}) {
    if (top != null) _paddingTop = top;
    if (right != null) _paddingRight = right;
    if (bottom != null) _paddingBottom = bottom;
    if (left != null) _paddingLeft = left;
    return this;
  }

  /// Sets the fixed width of the panel.
  Panel width(int value) {
    _width = value;
    return this;
  }

  /// Sets the minimum width of the panel.
  Panel minWidth(int value) {
    _minWidth = value;
    return this;
  }

  /// Sets the maximum width of the panel.
  Panel maxWidth(int value) {
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

    // Build top border
    if (_title != null) {
      final styledTitle = ' ${styleTitle(_title!)} ';
      final titleLen = Style.visibleLength(styledTitle);
      final remaining = totalInnerWidth - titleLen;

      String topLine;
      switch (_titleAlign) {
        case PanelAlignment.left:
          final rightFill = b.top * (remaining - 1);
          topLine = '${b.topLeft}${b.top}$styledTitle$rightFill${b.topRight}';
        case PanelAlignment.center:
          final leftFill = b.top * (remaining ~/ 2);
          final rightFill = b.top * (remaining - remaining ~/ 2);
          topLine = '${b.topLeft}$leftFill$styledTitle$rightFill${b.topRight}';
        case PanelAlignment.right:
          final leftFill = b.top * (remaining - 1);
          topLine = '${b.topLeft}$leftFill$styledTitle${b.top}${b.topRight}';
      }
      buffer.writeln(styleBorder(topLine));
    } else {
      buffer.writeln(
        styleBorder('${b.topLeft}${b.top * totalInnerWidth}${b.topRight}'),
      );
    }

    // Add top padding lines
    for (var i = 0; i < _paddingTop; i++) {
      buffer.writeln(
        '${styleBorder(b.left)}${' ' * totalInnerWidth}${styleBorder(b.right)}',
      );
    }

    // Content lines
    for (var i = 0; i < content.length; i++) {
      final line = content[i];
      final visible = Style.visibleLength(line);
      final fill = innerWidth - visible;

      String alignedContent;
      switch (_contentAlign) {
        case PanelAlignment.left:
          alignedContent = '$line${' ' * (fill > 0 ? fill : 0)}';
        case PanelAlignment.center:
          final leftPad = ' ' * (fill ~/ 2);
          final rightPad = ' ' * (fill - fill ~/ 2);
          alignedContent = '$leftPad$line$rightPad';
        case PanelAlignment.right:
          alignedContent = '${' ' * (fill > 0 ? fill : 0)}$line';
      }

      final styledContent = styleContent(alignedContent, i);
      final leftPad = ' ' * _paddingLeft;
      final rightPad = ' ' * _paddingRight;

      buffer.writeln(
        '${styleBorder(b.left)}$leftPad$styledContent$rightPad${styleBorder(b.right)}',
      );
    }

    // Add bottom padding lines
    for (var i = 0; i < _paddingBottom; i++) {
      buffer.writeln(
        '${styleBorder(b.left)}${' ' * totalInnerWidth}${styleBorder(b.right)}',
      );
    }

    // Bottom border
    buffer.write(
      styleBorder(
        '${b.bottomLeft}${b.bottom * totalInnerWidth}${b.bottomRight}',
      ),
    );

    return buffer.toString();
  }

  @override
  int get lineCount {
    var count = 2; // Top and bottom borders
    count += _paddingTop + _paddingBottom;
    count += _content.isEmpty ? 1 : _content.length;
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel Presets
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common panel styles.
extension PanelPresets on Panel {
  /// Creates an info-styled panel.
  static Panel info(String title, String content) {
    return Panel()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.info));
  }

  /// Creates a success-styled panel.
  static Panel success(String title, String content) {
    return Panel()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.success));
  }

  /// Creates a warning-styled panel.
  static Panel warning(String title, String content) {
    return Panel()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.warning));
  }

  /// Creates an error-styled panel.
  static Panel error(String title, String content) {
    return Panel()
      ..title(title)
      ..content(content)
      ..border(style_border.Border.rounded)
      ..titleStyle(Style().bold().foreground(Colors.error));
  }
}
