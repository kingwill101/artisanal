import 'dart:collection';
import 'dart:math' as math;
import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart'
    show
        Cmd,
        Msg,
        KeyType,
        KeyMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        HitTestMouseMsg,
        View,
        TuiTrace,
        TraceTag;
import 'package:artisanal/artisanal.dart'
    show markdownToAnsi, AnsiRendererOptions;
import 'geometry.dart';
import '../core/element.dart' show elementOf;
import '../core/framework.dart'
    show BuildContext, StatefulWidget, State;
import '../rendering/render_object.dart';
import '../rendering/render_layout.dart';
import '../core/widget.dart';
import '../theme/theme.dart' show hasDarkBackground;

typedef MarkdownLinkTapCallback = Cmd? Function(String url);

final class _MarkdownLinkOpenedMsg extends Msg {
  const _MarkdownLinkOpenedMsg();
}

/// A widget that renders Markdown content as styled ANSI text.
///
/// Uses the `markdownToAnsi` renderer from the artisanal core package, which
/// supports headings, bold, italic, code blocks, blockquotes, lists, tables,
/// horizontal rules, hyperlinks, and syntax highlighting.
///
/// ```dart
/// MarkdownText(
///   data: '# Hello\n\nThis is **bold** and *italic*.',
///   maxWidth: 80,
/// )
/// ```
class MarkdownText extends StatefulWidget {
  static const int _globalCacheLimit = 512;
  static final LinkedHashMap<Object, String> _globalRenderCache =
      LinkedHashMap<Object, String>();

  MarkdownText({
    required this.data,
    this.options,
    this.textStyle,
    this.softWrap = true,
    this.maxWidth,
    this.onLinkTap,
    this.openLinksOnTap = true,
    super.key,
  });

  /// The Markdown source text to render.
  final String data;

  /// Optional rendering options for the ANSI renderer.
  ///
  /// If null, default options are used with the width set to [maxWidth]
  /// and dark background detection from the current theme.
  final AnsiRendererOptions? options;

  /// Style for normal body/paragraph text.
  ///
  /// When set, this is applied to paragraph text and list items so that
  /// body content has an explicit foreground color rather than relying on
  /// the terminal's default. This is particularly important when the app
  /// paints its own background (e.g., a dark theme on a light terminal).
  ///
  /// Typically pass a [Style] with a foreground color matching your theme's
  /// text-on-background color:
  /// ```dart
  /// MarkdownText(
  ///   data: '...',
  ///   textStyle: Style().foreground(theme.onBackground),
  /// )
  /// ```
  final Style? textStyle;

  /// Whether to soft-wrap text output.
  final bool softWrap;

  /// Maximum width in columns for rendered output.
  final int? maxWidth;

  /// Called when a rendered Markdown link is clicked.
  ///
  /// If null and [openLinksOnTap] is true, the URL is opened with
  /// [Cmd.openUrl].
  final MarkdownLinkTapCallback? onLinkTap;

  /// Whether links should open in the system browser when clicked.
  final bool openLinksOnTap;

  @override
  State createState() => _MarkdownTextState();

  @override
  Object view() => _render(maxWidth);

  String _render(int? width) {
    return MarkdownText._renderContent(
      data: data,
      options: options,
      textStyle: textStyle,
      softWrap: softWrap,
      maxWidth: maxWidth,
      hasDarkBackground: hasDarkBackground,
      width: width,
    );
  }

  static String _renderContent({
    required String data,
    required AnsiRendererOptions? options,
    required Style? textStyle,
    required bool softWrap,
    required int? maxWidth,
    required bool hasDarkBackground,
    required int? width,
  }) {
    final cacheKey = _renderCacheKey(
      data: data,
      options: options,
      textStyle: textStyle,
      softWrap: softWrap,
      maxWidth: maxWidth,
      hasDarkBackground: hasDarkBackground,
      width: width,
    );
    return _renderContentForKey(
      cacheKey,
      data: data,
      options: options,
      textStyle: textStyle,
      softWrap: softWrap,
      maxWidth: maxWidth,
      hasDarkBackground: hasDarkBackground,
      width: width,
    );
  }

  static Object _renderCacheKey({
    required String data,
    required AnsiRendererOptions? options,
    required Style? textStyle,
    required bool softWrap,
    required int? maxWidth,
    required bool hasDarkBackground,
    required int? width,
  }) {
    final baseOptions = options ?? const AnsiRendererOptions();
    final effectiveWidth = width ?? maxWidth ?? baseOptions.width;
    final effectiveTextStyle = textStyle ?? baseOptions.textStyle;
    return (
      data,
      _optionsCacheKey(
        baseOptions,
        width: effectiveWidth,
        hasDarkBackground: hasDarkBackground,
        textStyle: effectiveTextStyle,
      ),
      softWrap,
      maxWidth,
    );
  }

  static String _renderContentForKey(
    Object cacheKey, {
    required String data,
    required AnsiRendererOptions? options,
    required Style? textStyle,
    required bool softWrap,
    required int? maxWidth,
    required bool hasDarkBackground,
    required int? width,
  }) {
    final globalCached = _globalRenderCache[cacheKey];
    if (globalCached != null) {
      return globalCached;
    }

    final baseOptions = options ?? const AnsiRendererOptions();
    final effectiveOptions = baseOptions.copyWith(
      width: width ?? maxWidth ?? baseOptions.width,
      hasDarkBackground: hasDarkBackground,
      textStyle: textStyle ?? baseOptions.textStyle,
    );
    var content = markdownToAnsi(data, options: effectiveOptions);

    if (!softWrap && maxWidth != null) {
      content = Layout.truncateLines(content, maxWidth);
    }

    _cacheRender(cacheKey, content);

    return content;
  }

  static Object _optionsCacheKey(
    AnsiRendererOptions options, {
    required int? width,
    required bool hasDarkBackground,
    required Style? textStyle,
  }) {
    return (
      width,
      hasDarkBackground,
      _styleCacheKey(textStyle),
      _styleCacheKey(options.h1Style),
      _styleCacheKey(options.h2Style),
      _styleCacheKey(options.h3Style),
      _styleCacheKey(options.h4Style),
      _styleCacheKey(options.h5Style),
      _styleCacheKey(options.h6Style),
      _styleCacheKey(options.emphasisStyle),
      _styleCacheKey(options.strongStyle),
      _styleCacheKey(options.codeStyle),
      _styleCacheKey(options.codeBlockStyle),
      _styleCacheKey(options.linkStyle),
      _styleCacheKey(options.blockquoteStyle),
      options.blockquoteBorderColor,
      _styleCacheKey(options.strikethroughStyle),
      options.bulletChar,
      options.hyperlinks,
      options.hrChar,
      options.hrWidth,
      options.checkboxChecked,
      options.checkboxUnchecked,
      options.listIndent,
      options.codeBlockBorder,
      options.tableBorder,
      _styleCacheKey(options.tableHeaderStyle),
      _styleCacheKey(options.tableCellStyle),
      _styleCacheKey(options.tableBorderStyle),
      options.syntaxHighlighting,
      options.maxSyntaxHighlightCodeUnits,
      identityHashCode(options.syntaxTheme),
      options.codeBlockBorderStyle,
    );
  }

  static Object? _styleCacheKey(Style? style) {
    if (style == null) return null;
    return (
      style.colorProfile,
      style.hasDarkBackground,
      style.isBold,
      style.isItalic,
      style.isUnderline,
      style.getUnderlineStyle,
      style.isStrikethrough,
      style.isDim,
      style.isInverse,
      style.isBlink,
      style.hasHyperlink,
      style.getHyperlinkUrl,
      style.getHyperlinkParams,
      style.getTabWidth,
      style.isUnderlineSpaces,
      style.isStrikethroughSpaces,
      style.getMarginBackground,
      style.getUnderlineColor,
      style.getPaddingChar,
      style.getMarginChar,
      style.getForeground,
      style.getBackground,
      style.getWidth,
      style.getHeight,
      style.getMaxWidth,
      style.getMaxHeight,
      style.getPadding,
      style.getMargin,
      style.getAlign,
      style.getAlignVertical,
      style.getBorder,
      style.getBorderSides,
      style.getBorderForeground,
      style.getBorderBackground,
      style.getBorderTopForeground,
      style.getBorderRightForeground,
      style.getBorderBottomForeground,
      style.getBorderLeftForeground,
      style.getBorderTopBackground,
      style.getBorderRightBackground,
      style.getBorderBottomBackground,
      style.getBorderLeftBackground,
      Object.hashAll(style.getBorderForegroundBlend),
      style.getBorderForegroundBlendOffset,
      identityHashCode(style.getTransform),
      style.getValue,
    );
  }

  static void _cacheRender(Object key, String value) {
    if (_globalRenderCache.length >= _globalCacheLimit) {
      _globalRenderCache.remove(_globalRenderCache.keys.first);
    }
    _globalRenderCache[key] = value;
  }
}

class _MarkdownTextState extends State<MarkdownText> {
  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is! HitTestMouseMsg ||
        msg.event.action != MouseAction.release ||
        msg.event.button != MouseButton.left) {
      return null;
    }

    final renderObject = _renderObject();
    final url = renderObject?.linkAt(msg.localX.floor(), msg.localY.floor());
    if (url == null || url.isEmpty) return null;

    final callback = widget.onLinkTap;
    if (callback != null) {
      return callback(url) ?? Cmd.none();
    }

    if (!widget.openLinksOnTap) return null;
    return Cmd.openUrl(url, onComplete: (_) => const _MarkdownLinkOpenedMsg());
  }

  _RenderMarkdownText? _renderObject() {
    final element = elementOf(widget);
    if (element == null) return null;
    for (final child in element.children) {
      final renderObject = child.renderObject;
      if (renderObject is _RenderMarkdownText) return renderObject;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _MarkdownTextRenderObjectWidget(
      data: widget.data,
      options: widget.options,
      textStyle: widget.textStyle,
      softWrap: widget.softWrap,
      maxWidth: widget.maxWidth,
    );
  }
}

class _MarkdownTextRenderObjectWidget extends LeafRenderObjectWidget {
  _MarkdownTextRenderObjectWidget({
    required this.data,
    this.options,
    this.textStyle,
    this.softWrap = true,
    this.maxWidth,
  });

  final String data;
  final AnsiRendererOptions? options;
  final Style? textStyle;
  final bool softWrap;
  final int? maxWidth;

  @override
  RenderObject createRenderObject() {
    return _RenderMarkdownText(
      data: data,
      options: options,
      textStyle: textStyle,
      softWrapMarkdown: softWrap,
      maxWidth: maxWidth,
      hasDarkBackground: hasDarkBackground,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final rt = renderObject as _RenderMarkdownText;
    rt.update(
      data: data,
      options: options,
      textStyle: textStyle,
      softWrapMarkdown: softWrap,
      maxWidth: maxWidth,
      hasDarkBackground: hasDarkBackground,
    );
  }

  @override
  Object view() => _render(maxWidth);

  String _render(int? width) {
    return MarkdownText._renderContent(
      data: data,
      options: options,
      textStyle: textStyle,
      softWrap: softWrap,
      maxWidth: maxWidth,
      hasDarkBackground: hasDarkBackground,
      width: width,
    );
  }
}

class _RenderMarkdownText extends RenderText {
  _RenderMarkdownText({
    required String data,
    required AnsiRendererOptions? options,
    required Style? textStyle,
    required bool softWrapMarkdown,
    required int? maxWidth,
    required bool hasDarkBackground,
  }) : _data = data,
       _options = options,
       _textStyle = textStyle,
       _softWrapMarkdown = softWrapMarkdown,
       _maxWidth = maxWidth,
       _hasDarkBackground = hasDarkBackground,
       super(text: '', softWrap: false);

  String _data;
  AnsiRendererOptions? _options;
  Style? _textStyle;
  bool _softWrapMarkdown;
  int? _maxWidth;
  bool _hasDarkBackground;
  Object? _lastRenderKey;
  String? _lastRenderedContent;

  void update({
    required String data,
    required AnsiRendererOptions? options,
    required Style? textStyle,
    required bool softWrapMarkdown,
    required int? maxWidth,
    required bool hasDarkBackground,
  }) {
    _data = data;
    _options = options;
    _textStyle = textStyle;
    _softWrapMarkdown = softWrapMarkdown;
    _maxWidth = maxWidth;
    _hasDarkBackground = hasDarkBackground;
  }

  @override
  void layout(BoxConstraints constraints) {
    final width = _resolveMarkdownWidth(constraints);
    final renderKey = MarkdownText._renderCacheKey(
      data: _data,
      options: _options,
      textStyle: _textStyle,
      softWrap: _softWrapMarkdown,
      maxWidth: _maxWidth,
      hasDarkBackground: _hasDarkBackground,
      width: width,
    );
    final cachedContent = _lastRenderKey == renderKey
        ? _lastRenderedContent
        : null;
    text =
        cachedContent ??
        MarkdownText._renderContentForKey(
          renderKey,
          data: _data,
          options: _options,
          textStyle: _textStyle,
          softWrap: _softWrapMarkdown,
          maxWidth: _maxWidth,
          hasDarkBackground: _hasDarkBackground,
          width: width,
        );
    _lastRenderKey = renderKey;
    _lastRenderedContent = text;

    // Markdown must own wrapping so list, quote, and code-block context can
    // shape continuation lines. RenderText's generic wrapper would lose that
    // context and break list indentation.
    softWrap = false;
    super.layout(constraints);
  }

  String? linkAt(int x, int y) {
    if (x < 0 || y < 0) return null;

    var column = 0;
    var row = 0;
    String? activeLink;
    final source = text;

    var index = 0;
    while (index < source.length) {
      final codeUnit = source.codeUnitAt(index);

      if (codeUnit == 0x1b) {
        final parsed = _parseAnsiControl(source, index);
        if (parsed != null) {
          if (parsed.linkUrl != null) {
            activeLink = parsed.linkUrl!.isEmpty ? null : parsed.linkUrl;
          }
          index = parsed.endIndex;
          continue;
        }
      }

      if (codeUnit == 0x0a) {
        row++;
        column = 0;
        index++;
        continue;
      }
      if (codeUnit == 0x0d) {
        column = 0;
        index++;
        continue;
      }

      final (:rune, :length) = _readRuneAt(source, index);
      final char = String.fromCharCode(rune);
      final width = Style.visibleLength(char);
      if (row == y &&
          activeLink != null &&
          width > 0 &&
          x >= column &&
          x < column + width) {
        return activeLink;
      }

      column += width;
      index += length;
    }

    return null;
  }

  ({int rune, int length}) _readRuneAt(String source, int index) {
    final first = source.codeUnitAt(index);
    if (first >= 0xd800 && first <= 0xdbff && index + 1 < source.length) {
      final second = source.codeUnitAt(index + 1);
      if (second >= 0xdc00 && second <= 0xdfff) {
        return (
          rune: 0x10000 + ((first - 0xd800) << 10) + (second - 0xdc00),
          length: 2,
        );
      }
    }
    return (rune: first, length: 1);
  }

  _ParsedAnsiControl? _parseAnsiControl(String source, int index) {
    if (index + 1 >= source.length) return null;
    final next = source.codeUnitAt(index + 1);

    if (next == 0x5b) {
      var end = index + 2;
      while (end < source.length) {
        final byte = source.codeUnitAt(end);
        if (byte >= 0x40 && byte <= 0x7e) {
          return _ParsedAnsiControl(endIndex: end + 1);
        }
        end++;
      }
      return null;
    }

    if (next == 0x5d) {
      final parsed = _parseOscControl(source, index);
      if (parsed != null) return parsed;
    }

    return _ParsedAnsiControl(endIndex: math.min(index + 2, source.length));
  }

  _ParsedAnsiControl? _parseOscControl(String source, int index) {
    final start = index + 2;
    var cursor = start;
    while (cursor < source.length) {
      final byte = source.codeUnitAt(cursor);
      if (byte == 0x07) {
        return _parsedOscPayload(source.substring(start, cursor), cursor + 1);
      }
      if (byte == 0x1b &&
          cursor + 1 < source.length &&
          source.codeUnitAt(cursor + 1) == 0x5c) {
        return _parsedOscPayload(source.substring(start, cursor), cursor + 2);
      }
      cursor++;
    }
    return null;
  }

  _ParsedAnsiControl _parsedOscPayload(String payload, int endIndex) {
    if (!payload.startsWith('8;')) {
      return _ParsedAnsiControl(endIndex: endIndex);
    }

    final data = payload.substring(2);
    final separator = data.indexOf(';');
    if (separator == -1) {
      return _ParsedAnsiControl(endIndex: endIndex);
    }

    return _ParsedAnsiControl(
      endIndex: endIndex,
      linkUrl: data.substring(separator + 1),
    );
  }

  int? _resolveMarkdownWidth(BoxConstraints constraints) {
    if (!_softWrapMarkdown) return _maxWidth ?? _options?.width;

    final constraintWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth.toInt()
        : null;
    final configuredWidth = _maxWidth ?? _options?.width;

    if (constraintWidth != null && configuredWidth != null) {
      return math.min(constraintWidth, configuredWidth);
    }
    return constraintWidth ?? configuredWidth;
  }
}

class _ParsedAnsiControl {
  const _ParsedAnsiControl({required this.endIndex, this.linkUrl});

  final int endIndex;
  final String? linkUrl;
}
