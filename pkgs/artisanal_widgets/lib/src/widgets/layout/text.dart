import 'dart:math' as math;

import '../rendering/rendering.dart';
import '../theme.dart';
import '../style.dart';
import 'enums.dart';

class TextSpan {
  const TextSpan({
    this.style,
    this.textStyle,
    this.selectionHighlightStyle,
    this.text,
    this.children = const [],
  });

  /// Complete Artisanal style applied to this span.
  final Style? style;

  /// Immutable text-only declarations applied after [style].
  final TextStyle? textStyle;

  /// Style used when this span is selected.
  final Style? selectionHighlightStyle;

  /// Text owned by this span.
  final String? text;

  /// Child spans that inherit this span's resolved presentation.
  final List<TextSpan> children;
}

class Text extends LeafRenderObjectWidget {
  Text(
    this.data, {
    super.key,
    this.style,
    this.textStyle,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
  }) : textSpan = null;

  Text.rich(
    this.textSpan, {
    super.key,
    this.style,
    this.textStyle,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
  }) : data = null;

  final String? data;
  final TextSpan? textSpan;

  /// Complete Artisanal style applied to the text.
  final Style? style;

  /// Immutable text-only declarations applied after [style].
  final TextStyle? textStyle;

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
    return RenderText(
      text: _render(),
      softWrap: softWrap,
      constrainedTextBuilder: _usesConstraintAwareBoxStyle
          ? _renderWithin
          : null,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final rt = renderObject as RenderText;
    rt
      ..text = _render()
      ..softWrap = softWrap
      ..constrainedTextBuilder = _usesConstraintAwareBoxStyle
          ? _renderWithin
          : null;
  }

  @override
  Object view() => _render();

  String _render() {
    return buildCachedView<String>(() {
      final resolvedStyle = _resolveTextPresentation(
        style: style,
        textStyle: textStyle,
      );
      String content;
      if (textSpan != null) {
        if (_hasBoxLayout(resolvedStyle)) {
          final richContent = renderSpan(
            textSpan!,
            _withoutBoxLayout(resolvedStyle!),
          );
          resolvedStyle.hasDarkBackground = hasDarkBackground;
          content = resolvedStyle.render(richContent);
        } else {
          content = renderSpan(textSpan!, resolvedStyle);
        }
      } else {
        content = data ?? '';
        if (resolvedStyle != null) {
          final s = resolvedStyle.copy();
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

      if (textAlign == TextAlign.left) {
        return content;
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
    textStyle,
    textAlign,
    softWrap,
    overflow,
    maxWidth,
    hasDarkBackground,
  );

  bool get _usesConstraintAwareBoxStyle {
    if (style == null || !softWrap) return false;
    final resolved = _resolveTextPresentation(
      style: style,
      textStyle: textStyle,
    );
    return _hasBoxLayout(resolved);
  }

  String _renderWithin(int maxWidth) {
    final unconstrained = _render();
    if (maxWidth <= 0 || Layout.getWidth(unconstrained) <= maxWidth) {
      return unconstrained;
    }

    final resolved = _resolveTextPresentation(
      style: style,
      textStyle: textStyle,
    )!;
    final borderWidth =
        resolved.getHorizontalFrameSize - resolved.getHorizontalPadding;
    final styleWidth = maxWidth - resolved.getHorizontalMargins - borderWidth;
    if (styleWidth <= 0) {
      return Layout.truncateLines(unconstrained, maxWidth, ellipsis: '');
    }

    final constrained = resolved.copy()..width(styleWidth);
    constrained.hasDarkBackground = hasDarkBackground;
    final content = textSpan == null
        ? data ?? ''
        : renderSpan(textSpan!, _withoutBoxLayout(resolved));
    return constrained.render(content);
  }
}

bool _hasBoxLayout(Style? style) {
  if (style == null) return false;
  return style.getHorizontalFrameSize > 0 ||
      style.getVerticalFrameSize > 0 ||
      style.getHorizontalMargins > 0 ||
      style.getVerticalMargins > 0 ||
      style.getWidth > 0 ||
      style.getHeight > 0 ||
      style.getMaxWidth > 0 ||
      style.getMaxHeight > 0;
}

Style _withoutBoxLayout(Style style) => style.copy()
  ..unsetWidth()
  ..unsetHeight()
  ..unsetMaxWidth()
  ..unsetMaxHeight()
  ..unsetPadding()
  ..unsetMargin()
  ..unsetBorder()
  ..unsetAlignHorizontal()
  ..unsetAlignVertical();

String renderSpan(TextSpan span, Style? baseStyle) {
  final buffer = StringBuffer();
  final resolvedStyle = _resolveTextPresentation(
    inheritedStyle: baseStyle,
    style: span.style,
    textStyle: span.textStyle,
  );
  if (resolvedStyle != null) {
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
      buffer.write(renderSpan(child, resolvedStyle ?? baseStyle));
    }
  }

  return buffer.toString();
}

Style? _resolveTextPresentation({
  Style? inheritedStyle,
  Style? style,
  TextStyle? textStyle,
}) {
  if (inheritedStyle == null && style == null && textStyle == null) {
    return null;
  }

  final resolved = inheritedStyle?.copy() ?? Style();
  if (style != null) {
    resolved.inherit(style);
  }
  if (textStyle != null) {
    textStyle.applyTo(resolved);
  }
  return resolved;
}
