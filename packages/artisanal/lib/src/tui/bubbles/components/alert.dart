import '../../../style/border.dart' as style_border;
import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// Alert types.
enum AlertType { info, success, warning, error, note }

/// An alert/notice block component.
///
/// ```dart
/// AlertComponent(
///   message: 'This is important!',
///   type: AlertType.warning,
/// ).render();
/// ```
class AlertComponent extends DisplayComponent {
  const AlertComponent({
    required this.message,
    this.type = AlertType.info,
    this.renderConfig = const RenderConfig(),
  });

  final String message;
  final AlertType type;
  final RenderConfig renderConfig;

  @override
  String render() {
    final style = renderConfig.configureStyle(Style());
    final (prefix, renderPrefix) = switch (type) {
      AlertType.info => (
        '[INFO]',
        (String s) => style.foreground(Colors.info).bold().render(s),
      ),
      AlertType.success => (
        '[OK]',
        (String s) => style.foreground(Colors.success).bold().render(s),
      ),
      AlertType.warning => (
        '[WARN]',
        (String s) => style.foreground(Colors.warning).bold().render(s),
      ),
      AlertType.error => (
        '[ERROR]',
        (String s) => style.foreground(Colors.error).bold().render(s),
      ),
      AlertType.note => ('[NOTE]', (String s) => style.dim().render(s)),
    };

    return '${renderPrefix(prefix)} $message';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Alert Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Alert display style.
enum AlertDisplayStyle {
  /// Simple inline alert: [PREFIX] message
  inline,

  /// Block alert with border
  block,

  /// Large block with padding
  large,
}

/// Callback for alert message styling.
///
/// [line] is the message line being rendered.
/// [lineIndex] is the index of the line (0-based).
///
/// Return a [Style] to apply to the line, or `null` for no styling.
typedef AlertStyleFunc = Style? Function(String line, int lineIndex);

/// A fluent builder for creating styled alerts.
///
/// Provides a chainable API for alert configuration with support for
/// the new Style system, custom borders, and multiple display styles.
///
/// ```dart
/// final alert = Alert()
///     .info()
///     .message('Operation completed successfully!')
///     .displayStyle(AlertDisplayStyle.block)
///     .render();
///
/// print(alert);
///
/// // Or with custom styling
/// final customAlert = Alert()
///     .message('Custom alert')
///     .prefix('[CUSTOM]')
///     .prefixStyle(Style().bold().foreground(Colors.magenta))
///     .messageStyle(Style().italic())
///     .render();
/// ```
class Alert extends DisplayComponent {
  /// Creates a new empty alert builder.
  Alert({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  String _message = '';
  String? _prefix;
  AlertType _type = AlertType.info;
  AlertDisplayStyle _displayStyle = AlertDisplayStyle.inline;
  Style? _prefixStyle;
  Style? _messageStyle;
  AlertStyleFunc? _messageStyleFunc;
  style_border.Border _border = style_border.Border.rounded;
  Style? _borderStyle;
  int _padding = 1;
  int? _width;

  /// Sets the alert message.
  Alert message(String text) {
    _message = text;
    return this;
  }

  /// Sets the alert type.
  Alert type(AlertType type) {
    _type = type;
    return this;
  }

  /// Sets the alert to info type.
  Alert info() {
    _type = AlertType.info;
    return this;
  }

  /// Sets the alert to success type.
  Alert success() {
    _type = AlertType.success;
    return this;
  }

  /// Sets the alert to warning type.
  Alert warning() {
    _type = AlertType.warning;
    return this;
  }

  /// Sets the alert to error type.
  Alert error() {
    _type = AlertType.error;
    return this;
  }

  /// Sets the alert to note type.
  Alert note() {
    _type = AlertType.note;
    return this;
  }

  /// Sets the display style.
  Alert displayStyle(AlertDisplayStyle style) {
    _displayStyle = style;
    return this;
  }

  /// Sets the alert to inline display.
  Alert inline() {
    _displayStyle = AlertDisplayStyle.inline;
    return this;
  }

  /// Sets the alert to block display.
  Alert block() {
    _displayStyle = AlertDisplayStyle.block;
    return this;
  }

  /// Sets the alert to large display.
  Alert large() {
    _displayStyle = AlertDisplayStyle.large;
    return this;
  }

  /// Sets a custom prefix (overrides type prefix).
  Alert prefix(String prefix) {
    _prefix = prefix;
    return this;
  }

  /// Sets the prefix style (overrides type default).
  Alert prefixStyle(Style style) {
    _prefixStyle = style;
    return this;
  }

  /// Sets the message style.
  Alert messageStyle(Style style) {
    _messageStyle = style;
    return this;
  }

  /// Sets the message style function for per-line styling.
  Alert messageStyleFunc(AlertStyleFunc func) {
    _messageStyleFunc = func;
    return this;
  }

  /// Sets the border style (for block/large display).
  Alert border(style_border.Border border) {
    _border = border;
    return this;
  }

  /// Sets the border text style.
  Alert borderStyle(Style style) {
    _borderStyle = style;
    return this;
  }

  /// Sets the padding (for block/large display).
  Alert padding(int value) {
    _padding = value;
    return this;
  }

  /// Sets the width (for block/large display).
  Alert width(int value) {
    _width = value;
    return this;
  }

  /// Gets the default prefix for the alert type.
  String get _defaultPrefix => switch (_type) {
    AlertType.info => '[INFO]',
    AlertType.success => '[OK]',
    AlertType.warning => '[WARNING]',
    AlertType.error => '[ERROR]',
    AlertType.note => '[NOTE]',
  };

  /// Gets the default color for the alert type.
  Color get _defaultColor => switch (_type) {
    AlertType.info => Colors.blue,
    AlertType.success => Colors.success,
    AlertType.warning => Colors.warning,
    AlertType.error => Colors.error,
    AlertType.note => Colors.gray,
  };

  /// Applies prefix styling.
  String _stylePrefix(String text) {
    final style = _prefixStyle ?? Style().bold().foreground(_defaultColor);
    return _renderConfig.configureStyle(style).render(text);
  }

  /// Applies message styling.
  String _styleMessage(String text, int lineIndex) {
    if (_messageStyleFunc != null) {
      final style = _messageStyleFunc!(text, lineIndex);
      if (style != null) {
        return _renderConfig.configureStyle(style).render(text);
      }
      return text;
    }
    if (_messageStyle != null) {
      return _renderConfig.configureStyle(_messageStyle!).render(text);
    }
    return text;
  }

  /// Applies border styling.
  String _styleBorder(String text) {
    if (_borderStyle == null) return text;
    return _renderConfig.configureStyle(_borderStyle!).render(text);
  }

  @override
  String render() {
    final prefix = _prefix ?? _defaultPrefix;
    final lines = _message.split('\n');

    return switch (_displayStyle) {
      AlertDisplayStyle.inline => _renderInline(prefix, lines),
      AlertDisplayStyle.block => _renderBlock(prefix, lines),
      AlertDisplayStyle.large => _renderLarge(prefix, lines),
    };
  }

  String _renderInline(String prefix, List<String> lines) {
    final buffer = StringBuffer();
    final styledPrefix = _stylePrefix(prefix);

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) buffer.writeln();
      final styledMessage = _styleMessage(lines[i], i);
      if (i == 0) {
        buffer.write('$styledPrefix $styledMessage');
      } else {
        // Indent continuation lines
        final indent = ' ' * (Style.visibleLength(prefix) + 1);
        buffer.write('$indent$styledMessage');
      }
    }

    return buffer.toString();
  }

  String _renderBlock(String prefix, List<String> lines) {
    final buffer = StringBuffer();
    final b = _border;

    // Calculate width
    var maxLen = Style.visibleLength(prefix);
    for (final line in lines) {
      final len = Style.visibleLength(line);
      if (len > maxLen) maxLen = len;
    }
    final innerWidth = (_width ?? (maxLen + _padding * 2 + 2)) - 2;

    // Top border
    buffer.writeln(
      _styleBorder('${b.topLeft}${b.top * innerWidth}${b.topRight}'),
    );

    // Prefix line
    final styledPrefix = _stylePrefix(prefix);
    final prefixLen = Style.visibleLength(styledPrefix);
    final prefixFill = innerWidth - prefixLen;
    buffer.writeln(
      '${_styleBorder(b.left)}$styledPrefix${' ' * prefixFill}${_styleBorder(b.right)}',
    );

    // Message lines
    for (var i = 0; i < lines.length; i++) {
      final styledLine = _styleMessage(lines[i], i);
      final lineLen = Style.visibleLength(styledLine);
      final fill = innerWidth - lineLen;
      buffer.writeln(
        '${_styleBorder(b.left)}$styledLine${' ' * fill}${_styleBorder(b.right)}',
      );
    }

    // Bottom border
    buffer.write(
      _styleBorder('${b.bottomLeft}${b.bottom * innerWidth}${b.bottomRight}'),
    );

    return buffer.toString();
  }

  String _renderLarge(String prefix, List<String> lines) {
    final buffer = StringBuffer();
    final b = _border;

    // Calculate width
    var maxLen = Style.visibleLength(prefix);
    for (final line in lines) {
      final len = Style.visibleLength(line);
      if (len > maxLen) maxLen = len;
    }
    final innerWidth = (_width ?? (maxLen + _padding * 2 + 4)) - 2;
    final pad = ' ' * _padding;

    // Top border
    buffer.writeln();
    buffer.writeln(
      _styleBorder('${b.topLeft}${b.top * innerWidth}${b.topRight}'),
    );

    // Top padding
    buffer.writeln(
      '${_styleBorder(b.left)}${' ' * innerWidth}${_styleBorder(b.right)}',
    );

    // Prefix line
    final styledPrefix = _stylePrefix(prefix);
    final prefixLen = Style.visibleLength(styledPrefix);
    final prefixFill = innerWidth - prefixLen - _padding * 2;
    buffer.writeln(
      '${_styleBorder(b.left)}$pad$styledPrefix${' ' * prefixFill}$pad${_styleBorder(b.right)}',
    );

    // Empty line after prefix
    buffer.writeln(
      '${_styleBorder(b.left)}${' ' * innerWidth}${_styleBorder(b.right)}',
    );

    // Message lines
    for (var i = 0; i < lines.length; i++) {
      final styledLine = _styleMessage(lines[i], i);
      final lineLen = Style.visibleLength(styledLine);
      final fill = innerWidth - lineLen - _padding * 2;
      buffer.writeln(
        '${_styleBorder(b.left)}$pad$styledLine${' ' * fill}$pad${_styleBorder(b.right)}',
      );
    }

    // Bottom padding
    buffer.writeln(
      '${_styleBorder(b.left)}${' ' * innerWidth}${_styleBorder(b.right)}',
    );

    // Bottom border
    buffer.write(
      _styleBorder('${b.bottomLeft}${b.bottom * innerWidth}${b.bottomRight}'),
    );

    return buffer.toString();
  }

  @override
  int get lineCount {
    final lines = _message.split('\n').length;

    return switch (_displayStyle) {
      AlertDisplayStyle.inline => lines,
      AlertDisplayStyle.block => lines + 3, // 2 borders + prefix
      AlertDisplayStyle.large =>
        lines + 7, // 2 borders + 2 padding + prefix + empty + extra newline
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common alert styles.
extension AlertFactory on Alert {
  /// Creates an info alert.
  static Alert infoAlert(String message) => Alert()
    ..info()
    ..message(message);

  /// Creates a success alert.
  static Alert successAlert(String message) => Alert()
    ..success()
    ..message(message);

  /// Creates a warning alert.
  static Alert warningAlert(String message) => Alert()
    ..warning()
    ..message(message);

  /// Creates an error alert.
  static Alert errorAlert(String message) => Alert()
    ..error()
    ..message(message);

  /// Creates a note alert.
  static Alert noteAlert(String message) => Alert()
    ..note()
    ..message(message);

  /// Creates a block info alert.
  static Alert infoBlock(String message) => Alert()
    ..info()
    ..block()
    ..message(message);

  /// Creates a block success alert.
  static Alert successBlock(String message) => Alert()
    ..success()
    ..block()
    ..message(message);

  /// Creates a block warning alert.
  static Alert warningBlock(String message) => Alert()
    ..warning()
    ..block()
    ..message(message);

  /// Creates a block error alert.
  static Alert errorBlock(String message) => Alert()
    ..error()
    ..block()
    ..message(message);

  /// Creates a large info alert.
  static Alert infoLarge(String message) => Alert()
    ..info()
    ..large()
    ..message(message);

  /// Creates a large success alert.
  static Alert successLarge(String message) => Alert()
    ..success()
    ..large()
    ..message(message);

  /// Creates a large warning alert.
  static Alert warningLarge(String message) => Alert()
    ..warning()
    ..large()
    ..message(message);

  /// Creates a large error alert.
  static Alert errorLarge(String message) => Alert()
    ..error()
    ..large()
    ..message(message);
}
