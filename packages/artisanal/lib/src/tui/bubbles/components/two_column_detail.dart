import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A two-column detail component with dot fill.
///
/// ```dart
/// TwoColumnDetailComponent(
///   left: 'Status',
///   right: 'OK',
/// ).render();
/// ```
class TwoColumnDetailComponent extends DisplayComponent {
  const TwoColumnDetailComponent({
    required this.left,
    required this.right,
    this.fillChar = '.',
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  });

  final String left;
  final String right;
  final String fillChar;
  final int indent;
  final RenderConfig renderConfig;

  @override
  String render() {
    final leftLen = Style.visibleLength(left);
    final rightLen = Style.visibleLength(right);
    final available =
        renderConfig.terminalWidth - indent - leftLen - rightLen - 2;
    final fill = available > 0 ? ' ${fillChar * available} ' : ' ';

    return '${' ' * indent}$left$fill$right';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent TwoColumnDetail Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Callback for styling the left or right column.
///
/// [text] is the column text being rendered.
/// [isLeft] indicates whether this is the left column.
///
/// Return a [Style] to apply, or `null` for no styling.
typedef TwoColumnStyleFunc = Style? Function(String text, bool isLeft);

/// A fluent builder for creating two-column detail rows.
///
/// Provides a chainable API for creating key-value style rows with
/// customizable fill characters and styling.
///
/// ```dart
/// final detail = TwoColumnDetail()
///     .left('Status')
///     .right('OK')
///     .fillChar('.')
///     .leftStyle(Style().bold())
///     .rightStyle(Style().foreground(Colors.success))
///     .render();
///
/// print(detail);
/// ```
class TwoColumnDetail extends DisplayComponent {
  /// Creates a new empty two-column detail builder.
  TwoColumnDetail({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  String _left = '';
  String _right = '';
  String _fillChar = '.';
  int _indent = 2;
  int? _width;
  Style? _leftStyle;
  Style? _rightStyle;
  Style? _fillStyle;
  TwoColumnStyleFunc? _styleFunc;

  /// Sets the left column text.
  TwoColumnDetail left(String text) {
    _left = text;
    return this;
  }

  /// Sets the right column text.
  TwoColumnDetail right(String text) {
    _right = text;
    return this;
  }

  /// Sets the fill character (default: '.').
  TwoColumnDetail fillChar(String char) {
    _fillChar = char;
    return this;
  }

  /// Sets the left indent (default: 2).
  TwoColumnDetail indent(int value) {
    _indent = value;
    return this;
  }

  /// Sets the total width for the row.
  TwoColumnDetail width(int value) {
    _width = value;
    return this;
  }

  /// Sets the left column style.
  TwoColumnDetail leftStyle(Style style) {
    _leftStyle = style;
    return this;
  }

  /// Sets the right column style.
  TwoColumnDetail rightStyle(Style style) {
    _rightStyle = style;
    return this;
  }

  /// Sets the fill character style.
  TwoColumnDetail fillStyle(Style style) {
    _fillStyle = style;
    return this;
  }

  /// Sets a style function for dynamic styling.
  TwoColumnDetail styleFunc(TwoColumnStyleFunc func) {
    _styleFunc = func;
    return this;
  }

  /// Applies left column styling.
  String _applyLeftStyle(String text) {
    if (_styleFunc != null) {
      final style = _styleFunc!(text, true);
      if (style != null) {
        return _renderConfig.configureStyle(style).render(text);
      }
    }
    if (_leftStyle != null) {
      return _renderConfig.configureStyle(_leftStyle!).render(text);
    }
    return text;
  }

  /// Applies right column styling.
  String _applyRightStyle(String text) {
    if (_styleFunc != null) {
      final style = _styleFunc!(text, false);
      if (style != null) {
        return _renderConfig.configureStyle(style).render(text);
      }
    }
    if (_rightStyle != null) {
      return _renderConfig.configureStyle(_rightStyle!).render(text);
    }
    return text;
  }

  /// Applies fill character styling.
  String _applyFillStyle(String text) {
    if (_fillStyle != null) {
      return _renderConfig.configureStyle(_fillStyle!).render(text);
    }
    return text;
  }

  @override
  String render() {
    final styledLeft = _applyLeftStyle(_left);
    final styledRight = _applyRightStyle(_right);

    final leftLen = Style.visibleLength(_left);
    final rightLen = Style.visibleLength(_right);
    final totalWidth = _width ?? _renderConfig.terminalWidth;
    final available = totalWidth - _indent - leftLen - rightLen - 2;

    String fill;
    if (available > 0) {
      final fillChars = _fillChar * available;
      fill = ' ${_applyFillStyle(fillChars)} ';
    } else {
      fill = ' ';
    }

    return '${' ' * _indent}$styledLeft$fill$styledRight';
  }

  @override
  int get lineCount => 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// TwoColumnDetail List Builder
// ─────────────────────────────────────────────────────────────────────────────

/// A fluent builder for creating multiple two-column detail rows.
///
/// ```dart
/// final details = TwoColumnDetailList()
///     .row('Name', 'John Doe')
///     .row('Email', 'john@example.com')
///     .row('Status', 'Active')
///     .leftStyle(Style().bold())
///     .render();
///
/// print(details);
/// ```
class TwoColumnDetailList extends DisplayComponent {
  /// Creates a new empty two-column detail list builder.
  TwoColumnDetailList({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  final List<(String, String)> _rows = [];
  String _fillChar = '.';
  int _indent = 2;
  int? _width;
  Style? _leftStyle;
  Style? _rightStyle;
  Style? _fillStyle;
  TwoColumnStyleFunc? _styleFunc;

  /// Adds a row to the list.
  TwoColumnDetailList row(String left, String right) {
    _rows.add((left, right));
    return this;
  }

  /// Adds multiple rows from a map.
  TwoColumnDetailList rows(Map<String, String> items) {
    for (final entry in items.entries) {
      _rows.add((entry.key, entry.value));
    }
    return this;
  }

  /// Sets the fill character (default: '.').
  TwoColumnDetailList fillChar(String char) {
    _fillChar = char;
    return this;
  }

  /// Sets the left indent (default: 2).
  TwoColumnDetailList indent(int value) {
    _indent = value;
    return this;
  }

  /// Sets the total width for rows.
  TwoColumnDetailList width(int value) {
    _width = value;
    return this;
  }

  /// Sets the left column style.
  TwoColumnDetailList leftStyle(Style style) {
    _leftStyle = style;
    return this;
  }

  /// Sets the right column style.
  TwoColumnDetailList rightStyle(Style style) {
    _rightStyle = style;
    return this;
  }

  /// Sets the fill character style.
  TwoColumnDetailList fillStyle(Style style) {
    _fillStyle = style;
    return this;
  }

  /// Sets a style function for dynamic styling.
  TwoColumnDetailList styleFunc(TwoColumnStyleFunc func) {
    _styleFunc = func;
    return this;
  }

  @override
  String render() {
    if (_rows.isEmpty) return '';

    final buffer = StringBuffer();

    for (var i = 0; i < _rows.length; i++) {
      if (i > 0) buffer.writeln();

      final (left, right) = _rows[i];
      final detail = TwoColumnDetail(renderConfig: _renderConfig)
        ..left(left)
        ..right(right)
        ..fillChar(_fillChar)
        ..indent(_indent);

      if (_width != null) detail.width(_width!);
      if (_leftStyle != null) detail.leftStyle(_leftStyle!);
      if (_rightStyle != null) detail.rightStyle(_rightStyle!);
      if (_fillStyle != null) detail.fillStyle(_fillStyle!);
      if (_styleFunc != null) detail.styleFunc(_styleFunc!);

      buffer.write(detail.render());
    }

    return buffer.toString();
  }

  @override
  int get lineCount => _rows.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common two-column detail styles.
extension TwoColumnDetailFactory on TwoColumnDetail {
  /// Creates a status-style detail row.
  static TwoColumnDetail status(
    String label,
    String value, {
    bool success = true,
  }) {
    return TwoColumnDetail()
      ..left(label)
      ..right(value)
      ..leftStyle(Style().bold())
      ..rightStyle(Style().foreground(success ? Colors.success : Colors.error));
  }

  /// Creates an info-style detail row.
  static TwoColumnDetail info(String label, String value) {
    return TwoColumnDetail()
      ..left(label)
      ..right(value)
      ..leftStyle(Style().bold().foreground(Colors.blue))
      ..fillStyle(Style().dim());
  }

  /// Creates a muted detail row.
  static TwoColumnDetail muted(String label, String value) {
    return TwoColumnDetail()
      ..left(label)
      ..right(value)
      ..leftStyle(Style().dim())
      ..rightStyle(Style().dim())
      ..fillStyle(Style().dim());
  }

  /// Creates a detail row with a space fill instead of dots.
  static TwoColumnDetail spaceFill(String label, String value) {
    return TwoColumnDetail()
      ..left(label)
      ..right(value)
      ..fillChar(' ');
  }

  /// Creates a detail row with a dash fill.
  static TwoColumnDetail dashFill(String label, String value) {
    return TwoColumnDetail()
      ..left(label)
      ..right(value)
      ..fillChar('-');
  }
}
