part of 'layout_widgets.dart';

class TextSpan {
  const TextSpan({
    this.style,
    this.selectionHighlightStyle,
    this.text,
    this.children = const [],
  });

  final Style? style;
  final Style? selectionHighlightStyle;
  final String? text;
  final List<TextSpan> children;
}

class Text extends LeafRenderObjectWidget {
  Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
  }) : textSpan = null;

  Text.rich(
    this.textSpan, {
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
  }) : data = null;

  final String? data;
  final TextSpan? textSpan;
  final Style? style;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;

  /// Maximum width in columns for text truncation.
  ///
  /// When [overflow] is [TextOverflow.ellipsis], text lines wider than
  /// [maxWidth] are truncated with an ellipsis. Without this, ellipsis
  /// overflow has no effect because there is no width constraint to
  /// truncate against.
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
    return buildCachedView<String>(() {
      String content;
      if (textSpan != null) {
        content = _renderSpan(textSpan!, style);
      } else {
        content = data ?? '';
        if (style != null) {
          final s = style!.copy();
          s.hasDarkBackground = hasDarkBackground;
          content = s.render(content);
        }
      }

      // Note: actual soft-wrapping to constraint width is handled by
      // RenderText.layout(), not here — _render() has no access to
      // layout constraints.  The softWrap flag is forwarded to the
      // render object instead.

      if (overflow == TextOverflow.ellipsis && maxWidth != null) {
        content = Layout.truncateLines(content, maxWidth!, ellipsis: '...');
      }

      final lines = content.split('\n');
      final renderedWidth = lines.isEmpty
          ? 0
          : lines.map(Layout.visibleLength).reduce(math.max);

      final aligned = switch (textAlign) {
        TextAlign.left => lines,
        TextAlign.center => Layout.alignLines(
          lines,
          renderedWidth,
          HorizontalAlign.center,
        ),
        TextAlign.right => Layout.alignLines(
          lines,
          renderedWidth,
          HorizontalAlign.right,
        ),
        TextAlign.justify => lines,
      };

      return aligned.join('\n');
    }, _cacheKey());
  }

  Object _cacheKey() => (
    data,
    textSpan,
    style,
    textAlign,
    softWrap,
    overflow,
    maxWidth,
    hasDarkBackground,
  );
}

String _renderSpan(TextSpan span, Style? baseStyle) {
  final buffer = StringBuffer();
  Style? resolvedStyle;
  if (baseStyle != null || span.style != null) {
    resolvedStyle = (baseStyle ?? Style()).copy();
    if (span.style != null) {
      resolvedStyle.inherit(span.style!);
    }
    resolvedStyle.hasDarkBackground = hasDarkBackground;
  }

  final text = span.text;
  if (text != null && text.isNotEmpty) {
    if (resolvedStyle != null) {
      buffer.write(resolvedStyle.render(text));
    } else {
      buffer.write(text);
    }
  }

  if (span.children.isNotEmpty) {
    for (final child in span.children) {
      buffer.write(_renderSpan(child, resolvedStyle ?? baseStyle));
    }
  }

  return buffer.toString();
}
