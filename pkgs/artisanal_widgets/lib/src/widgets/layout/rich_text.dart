import 'dart:math' as math;
import '../rendering/rendering.dart';
import '../theme.dart';
import '../style.dart';
import 'enums.dart';
import 'text.dart';

/// A widget that displays styled text using a [TextSpan] tree.
///
/// This is the lower-level API for styled text. For simple strings use [Text];
/// for rich styled text you can also use `Text.rich(TextSpan(...))`. This
/// class provides a named, standalone widget for Flutter API parity.
///
/// ```dart
/// RichText(
///   text: TextSpan(
///     text: 'Hello ',
///     style: Style()..bold(true),
///     children: [
///       TextSpan(text: 'world', style: Style()..foreground(Colors.red)),
///     ],
///   ),
/// )
/// ```
class RichText extends LeafRenderObjectWidget {
  RichText({
    required this.text,
    super.key,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
  });

  /// The styled text span tree to render.
  final TextSpan text;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the text should break at soft line breaks.
  final bool softWrap;

  /// How visual overflow should be handled.
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
    return RenderText(text: _render());
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderText).text = _render();
  }

  @override
  Object view() => _render();

  String _render() {
    return buildCachedView<String>(() {
      var content = renderSpan(text, null);

      if (softWrap) {
        final wrapWidth = Layout.getWidth(content);
        content = Layout.wrapLines(content, wrapWidth);
      }

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

  Object _cacheKey() =>
      (text, textAlign, softWrap, overflow, maxWidth, hasDarkBackground);
}
