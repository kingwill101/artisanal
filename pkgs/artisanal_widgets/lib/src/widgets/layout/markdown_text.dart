part of 'layout_widgets.dart';

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
class MarkdownText extends LeafRenderObjectWidget {
  static const int _globalCacheLimit = 512;
  static final LinkedHashMap<Object, String> _globalRenderCache =
      LinkedHashMap<Object, String>();

  MarkdownText({
    required this.data,
    this.options,
    this.textStyle,
    this.softWrap = true,
    this.maxWidth,
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

  @override
  RenderObject createRenderObject() {
    return RenderText(text: _render(), softWrap: softWrap);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final rt = renderObject as RenderText;
    rt.text = _render();
    rt.softWrap = softWrap;
  }

  @override
  Object view() => _render();

  String _render() {
    final cacheKey = _cacheKey();
    final globalCached = _globalRenderCache[cacheKey];
    if (globalCached != null) {
      return buildCachedView<String>(() => globalCached, cacheKey);
    }

    return buildCachedView<String>(() {
      final baseOptions = options ?? const AnsiRendererOptions();
      final effectiveOptions = baseOptions.copyWith(
        width: maxWidth ?? baseOptions.width,
        hasDarkBackground: hasDarkBackground,
        textStyle: textStyle ?? baseOptions.textStyle,
      );
      var content = markdownToAnsi(data, options: effectiveOptions);

      if (!softWrap && maxWidth != null) {
        content = Layout.truncateLines(content, maxWidth!);
      }

      _cacheRender(cacheKey, content);

      return content;
    }, cacheKey);
  }

  static void _cacheRender(Object key, String value) {
    if (_globalRenderCache.length >= _globalCacheLimit) {
      _globalRenderCache.remove(_globalRenderCache.keys.first);
    }
    _globalRenderCache[key] = value;
  }

  Object _cacheKey() =>
      (data, options, textStyle, softWrap, maxWidth, hasDarkBackground);
}
