import '../../../style/border.dart' as style_border;
import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A styled block component (Symfony-style).
///
/// ```dart
/// StyledBlockComponent(
///   message: 'This is an important message!',
///   blockStyle: BlockStyleType.error,
/// ).render();
/// ```
class StyledBlockComponent extends DisplayComponent {
  const StyledBlockComponent({
    required this.message,
    this.blockStyle = BlockStyleType.info,
    this.prefix,
    this.large = false,
    this.padding = 1,
    this.renderConfig = const RenderConfig(),
  });

  final Object message;
  final BlockStyleType blockStyle;
  final String? prefix;
  final bool large;
  final int padding;
  final RenderConfig renderConfig;

  @override
  String render() {
    final lines = _normalizeLines(message);
    final buffer = StringBuffer();

    final blockColor = switch (blockStyle) {
      BlockStyleType.info =>
        (String s) => renderConfig
            .configureStyle(Style().foreground(Colors.info))
            .render(s),
      BlockStyleType.success =>
        (String s) => renderConfig
            .configureStyle(Style().foreground(Colors.success))
            .render(s),
      BlockStyleType.warning =>
        (String s) => renderConfig
            .configureStyle(Style().foreground(Colors.warning))
            .render(s),
      BlockStyleType.error =>
        (String s) => renderConfig
            .configureStyle(Style().foreground(Colors.error))
            .render(s),
      BlockStyleType.note =>
        (String s) => renderConfig.configureStyle(Style().dim()).render(s),
    };

    final prefixText =
        prefix ??
        switch (blockStyle) {
          BlockStyleType.info => '[INFO]',
          BlockStyleType.success => '[OK]',
          BlockStyleType.warning => '[WARNING]',
          BlockStyleType.error => '[ERROR]',
          BlockStyleType.note => '[NOTE]',
        };

    final pad = ' ' * padding;

    if (large) {
      final prefixWidth = Style.visibleLength(prefixText);
      final maxWidth = lines
          .map((l) => Style.visibleLength(l))
          .fold<int>(0, (m, v) => v > m ? v : m);
      final blockWidth = (maxWidth + padding * 2 + prefixWidth + 2).clamp(
        40,
        renderConfig.terminalWidth - 4,
      );

      buffer.writeln();
      buffer.writeln(blockColor(' ' * blockWidth));
      buffer.writeln(
        blockColor(
          '$pad$prefixText${' ' * (blockWidth - prefixWidth - padding)}',
        ),
      );
      for (final line in lines) {
        final fill = blockWidth - Style.visibleLength(line) - padding * 2;
        buffer.writeln(
          blockColor('$pad$line${' ' * (fill > 0 ? fill : 0)}$pad'),
        );
      }
      buffer.writeln(blockColor(' ' * blockWidth));
      buffer.write('');
    } else {
      buffer.writeln();
      for (final line in lines) {
        buffer.writeln('${blockColor(prefixText)} $line');
      }
    }

    return buffer.toString();
  }

  List<String> _normalizeLines(Object message) {
    if (message is Iterable) {
      return message.map((e) => e.toString()).toList();
    }
    return message.toString().split('\n');
  }
}

/// Block style types.
enum BlockStyleType { info, success, warning, error, note }

/// A comment component (dimmed text with // prefix).
///
/// ```dart
/// CommentComponent(
///   text: 'This is a comment',
/// ).render();
/// ```
class CommentComponent extends DisplayComponent {
  const CommentComponent({
    required this.text,
    this.renderConfig = const RenderConfig(),
  });

  final Object text;
  final RenderConfig renderConfig;

  @override
  String render() {
    final lines = text is Iterable
        ? (text as Iterable).map((e) => e.toString()).toList()
        : text.toString().split('\n');

    final buffer = StringBuffer();
    final dim = renderConfig.configureStyle(Style().dim());
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) buffer.writeln();
      buffer.write(dim.render('// ${lines[i]}'));
    }

    return buffer.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent StyledBlock Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Display style for styled blocks.
enum StyledBlockDisplayStyle {
  /// Simple inline: [PREFIX] message
  inline,

  /// Full-width background block
  fullWidth,

  /// Block with border
  bordered,
}

/// Callback for block content styling.
///
/// [line] is the content line being rendered.
/// [lineIndex] is the index of the line (0-based).
///
/// Return a [Style] to apply to the line, or `null` for no styling.
typedef StyledBlockStyleFunc = Style? Function(String line, int lineIndex);

/// A fluent builder for creating styled blocks (Symfony-style).
///
/// Provides a chainable API for styled block configuration with support for
/// the new Style system and multiple display styles.
///
/// ```dart
/// final block = StyledBlock()
///     .info()
///     .message('Operation completed successfully!')
///     .displayStyle(StyledBlockDisplayStyle.fullWidth)
///     .render();
///
/// print(block);
///
/// // Or with custom styling
/// final customBlock = StyledBlock()
///     .message('Custom block')
///     .prefix('[CUSTOM]')
///     .backgroundColor(Colors.magenta)
///     .foregroundColor(Colors.white)
///     .render();
/// ```
class StyledBlock extends DisplayComponent {
  /// Creates a new empty styled block builder.
  StyledBlock({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  String _message = '';
  String? _prefix;
  BlockStyleType _type = BlockStyleType.info;
  StyledBlockDisplayStyle _displayStyle = StyledBlockDisplayStyle.inline;
  Color? _backgroundColor;
  Color? _foregroundColor;
  Style? _prefixStyle;
  Style? _contentStyle;
  StyledBlockStyleFunc? _contentStyleFunc;
  style_border.Border _border = style_border.Border.rounded;
  Style? _borderStyle;
  int _padding = 1;
  int? _width;
  int? _maxWidth;

  /// Sets the block message.
  StyledBlock message(String text) {
    _message = text;
    return this;
  }

  /// Sets the block type.
  StyledBlock type(BlockStyleType type) {
    _type = type;
    return this;
  }

  /// Sets the block to info type.
  StyledBlock info() {
    _type = BlockStyleType.info;
    return this;
  }

  /// Sets the block to success type.
  StyledBlock success() {
    _type = BlockStyleType.success;
    return this;
  }

  /// Sets the block to warning type.
  StyledBlock warning() {
    _type = BlockStyleType.warning;
    return this;
  }

  /// Sets the block to error type.
  StyledBlock error() {
    _type = BlockStyleType.error;
    return this;
  }

  /// Sets the block to note type.
  StyledBlock note() {
    _type = BlockStyleType.note;
    return this;
  }

  /// Sets the display style.
  StyledBlock displayStyle(StyledBlockDisplayStyle style) {
    _displayStyle = style;
    return this;
  }

  /// Sets the block to inline display.
  StyledBlock inline() {
    _displayStyle = StyledBlockDisplayStyle.inline;
    return this;
  }

  /// Sets the block to full-width background display.
  StyledBlock fullWidth() {
    _displayStyle = StyledBlockDisplayStyle.fullWidth;
    return this;
  }

  /// Sets the block to bordered display.
  StyledBlock bordered() {
    _displayStyle = StyledBlockDisplayStyle.bordered;
    return this;
  }

  /// Sets a custom prefix (overrides type prefix).
  StyledBlock prefix(String prefix) {
    _prefix = prefix;
    return this;
  }

  /// Sets the background color (for fullWidth display).
  StyledBlock backgroundColor(Color color) {
    _backgroundColor = color;
    return this;
  }

  /// Sets the foreground (text) color.
  StyledBlock foregroundColor(Color color) {
    _foregroundColor = color;
    return this;
  }

  /// Sets the prefix style.
  StyledBlock prefixStyle(Style style) {
    _prefixStyle = style;
    return this;
  }

  /// Sets the content style.
  StyledBlock contentStyle(Style style) {
    _contentStyle = style;
    return this;
  }

  /// Sets the content style function for per-line styling.
  StyledBlock contentStyleFunc(StyledBlockStyleFunc func) {
    _contentStyleFunc = func;
    return this;
  }

  /// Sets the border style (for bordered display).
  StyledBlock border(style_border.Border border) {
    _border = border;
    return this;
  }

  /// Sets the border text style.
  StyledBlock borderStyle(Style style) {
    _borderStyle = style;
    return this;
  }

  /// Sets the padding.
  StyledBlock padding(int value) {
    _padding = value;
    return this;
  }

  /// Sets the width.
  StyledBlock width(int value) {
    _width = value;
    return this;
  }

  /// Sets the maximum width.
  StyledBlock maxWidth(int value) {
    _maxWidth = value;
    return this;
  }

  /// Gets the default prefix for the block type.
  String get _defaultPrefix => switch (_type) {
    BlockStyleType.info => '[INFO]',
    BlockStyleType.success => '[OK]',
    BlockStyleType.warning => '[WARNING]',
    BlockStyleType.error => '[ERROR]',
    BlockStyleType.note => '[NOTE]',
  };

  /// Gets the default background color for the block type.
  Color get _defaultBackgroundColor => switch (_type) {
    BlockStyleType.info => Colors.info,
    BlockStyleType.success => Colors.success,
    BlockStyleType.warning => Colors.warning,
    BlockStyleType.error => Colors.error,
    BlockStyleType.note => Colors.brightBlack,
  };

  /// Gets the default foreground color for the block type.
  Color get _defaultForegroundColor => Colors.white;

  /// Applies prefix styling.
  String _stylePrefix(String text) {
    if (_prefixStyle != null) {
      return _renderConfig.configureStyle(_prefixStyle!).render(text);
    }
    final style = Style().bold().foreground(
      _foregroundColor ?? _defaultForegroundColor,
    );
    return _renderConfig.configureStyle(style).render(text);
  }

  /// Applies content styling.
  String _styleContent(String text, int lineIndex) {
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

  /// Applies full-width background styling to a line.
  String _styleFullWidthLine(String text) {
    final bg = _backgroundColor ?? _defaultBackgroundColor;
    final fg = _foregroundColor ?? _defaultForegroundColor;
    final style = Style().foreground(fg).background(bg);
    return _renderConfig.configureStyle(style).render(text);
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
      StyledBlockDisplayStyle.inline => _renderInline(prefix, lines),
      StyledBlockDisplayStyle.fullWidth => _renderFullWidth(prefix, lines),
      StyledBlockDisplayStyle.bordered => _renderBordered(prefix, lines),
    };
  }

  String _renderInline(String prefix, List<String> lines) {
    final buffer = StringBuffer();
    final styledPrefix = _stylePrefix(prefix);

    buffer.writeln();
    for (var i = 0; i < lines.length; i++) {
      final styledContent = _styleContent(lines[i], i);
      buffer.writeln('$styledPrefix $styledContent');
    }

    return buffer.toString().trimRight();
  }

  String _renderFullWidth(String prefix, List<String> lines) {
    final buffer = StringBuffer();

    // Calculate width
    var maxLen = Style.visibleLength(prefix);
    for (final line in lines) {
      final len = Style.visibleLength(line);
      if (len > maxLen) maxLen = len;
    }

    var blockWidth = maxLen + _padding * 2 + 2;
    if (_width != null) blockWidth = _width!;
    if (_maxWidth != null && blockWidth > _maxWidth!) {
      blockWidth = _maxWidth!;
    }
    blockWidth = blockWidth.clamp(40, 120);

    final pad = ' ' * _padding;

    // Empty line before
    buffer.writeln();

    // Top padding line
    buffer.writeln(_styleFullWidthLine(' ' * blockWidth));

    // Prefix line
    final prefixContent = '$pad$prefix';
    final prefixFill = blockWidth - Style.visibleLength(prefixContent);
    buffer.writeln(_styleFullWidthLine('$prefixContent${' ' * prefixFill}'));

    // Content lines
    for (var i = 0; i < lines.length; i++) {
      final lineContent = '$pad${lines[i]}';
      final lineFill = blockWidth - Style.visibleLength(lineContent);
      buffer.writeln(
        _styleFullWidthLine(
          '$lineContent${' ' * (lineFill > 0 ? lineFill : 0)}$pad',
        ),
      );
    }

    // Bottom padding line
    buffer.writeln(_styleFullWidthLine(' ' * blockWidth));

    return buffer.toString().trimRight();
  }

  String _renderBordered(String prefix, List<String> lines) {
    final buffer = StringBuffer();
    final b = _border;

    // Calculate width
    var maxLen = Style.visibleLength(prefix);
    for (final line in lines) {
      final len = Style.visibleLength(line);
      if (len > maxLen) maxLen = len;
    }

    var innerWidth = maxLen + _padding * 2;
    if (_width != null) innerWidth = _width! - 2;
    if (_maxWidth != null && innerWidth > _maxWidth! - 2) {
      innerWidth = _maxWidth! - 2;
    }

    final pad = ' ' * _padding;

    // Top border
    buffer.writeln(
      _styleBorder('${b.topLeft}${b.top * innerWidth}${b.topRight}'),
    );

    // Prefix line
    final styledPrefix = _stylePrefix(prefix);
    final prefixLen = Style.visibleLength(styledPrefix);
    final prefixFill = innerWidth - prefixLen - _padding;
    buffer.writeln(
      '${_styleBorder(b.left)}$pad$styledPrefix${' ' * prefixFill}${_styleBorder(b.right)}',
    );

    // Empty line after prefix
    buffer.writeln(
      '${_styleBorder(b.left)}${' ' * innerWidth}${_styleBorder(b.right)}',
    );

    // Content lines
    for (var i = 0; i < lines.length; i++) {
      final styledContent = _styleContent(lines[i], i);
      final contentLen = Style.visibleLength(styledContent);
      final fill = innerWidth - contentLen - _padding * 2;
      buffer.writeln(
        '${_styleBorder(b.left)}$pad$styledContent${' ' * (fill > 0 ? fill : 0)}$pad${_styleBorder(b.right)}',
      );
    }

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
      StyledBlockDisplayStyle.inline => lines + 1, // +1 for leading newline
      StyledBlockDisplayStyle.fullWidth =>
        lines + 4, // top padding + prefix + bottom padding + leading newline
      StyledBlockDisplayStyle.bordered =>
        lines + 4, // 2 borders + prefix + empty line
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StyledBlock Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common styled block styles.
extension StyledBlockFactory on StyledBlock {
  /// Creates an info styled block.
  static StyledBlock infoBlock(String message) => StyledBlock()
    ..info()
    ..message(message);

  /// Creates a success styled block.
  static StyledBlock successBlock(String message) => StyledBlock()
    ..success()
    ..message(message);

  /// Creates a warning styled block.
  static StyledBlock warningBlock(String message) => StyledBlock()
    ..warning()
    ..message(message);

  /// Creates an error styled block.
  static StyledBlock errorBlock(String message) => StyledBlock()
    ..error()
    ..message(message);

  /// Creates a note styled block.
  static StyledBlock noteBlock(String message) => StyledBlock()
    ..note()
    ..message(message);

  /// Creates a full-width info block.
  static StyledBlock infoFullWidth(String message) => StyledBlock()
    ..info()
    ..fullWidth()
    ..message(message);

  /// Creates a full-width success block.
  static StyledBlock successFullWidth(String message) => StyledBlock()
    ..success()
    ..fullWidth()
    ..message(message);

  /// Creates a full-width warning block.
  static StyledBlock warningFullWidth(String message) => StyledBlock()
    ..warning()
    ..fullWidth()
    ..message(message);

  /// Creates a full-width error block.
  static StyledBlock errorFullWidth(String message) => StyledBlock()
    ..error()
    ..fullWidth()
    ..message(message);

  /// Creates a bordered info block.
  static StyledBlock infoBordered(String message) => StyledBlock()
    ..info()
    ..bordered()
    ..message(message);

  /// Creates a bordered success block.
  static StyledBlock successBordered(String message) => StyledBlock()
    ..success()
    ..bordered()
    ..message(message);

  /// Creates a bordered warning block.
  static StyledBlock warningBordered(String message) => StyledBlock()
    ..warning()
    ..bordered()
    ..message(message);

  /// Creates a bordered error block.
  static StyledBlock errorBordered(String message) => StyledBlock()
    ..error()
    ..bordered()
    ..message(message);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Comment Builder
// ─────────────────────────────────────────────────────────────────────────────

/// A fluent builder for creating styled comments.
///
/// ```dart
/// final comment = Comment()
///     .text('This is a comment')
///     .style(Style().foreground(Colors.gray).italic())
///     .render();
///
/// print(comment);
/// ```
class Comment extends DisplayComponent {
  /// Creates a new empty comment builder.
  Comment({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  String _text = '';
  String _prefix = '//';
  Style? _style;

  /// Sets the comment text.
  Comment text(String text) {
    _text = text;
    return this;
  }

  /// Sets the comment prefix (default: '//').
  Comment prefix(String prefix) {
    _prefix = prefix;
    return this;
  }

  /// Sets the comment style.
  Comment style(Style style) {
    _style = style;
    return this;
  }

  @override
  String render() {
    final lines = _text.split('\n');
    final buffer = StringBuffer();

    final style = _style ?? Style().dim();

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) buffer.writeln();
      final line = '$_prefix ${lines[i]}';
      buffer.write(_renderConfig.configureStyle(style).render(line));
    }

    return buffer.toString();
  }

  @override
  int get lineCount => _text.split('\n').length;
}
