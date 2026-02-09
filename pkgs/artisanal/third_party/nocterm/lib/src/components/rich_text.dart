import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'render_paragraph.dart';

// Re-export text related enums and classes
export 'render_paragraph.dart' show TextOverflow, TextAlign;
export 'package:nocterm/src/painting/inline_span.dart';
export 'package:nocterm/src/painting/text_span.dart';

/// A widget that displays rich text.
///
/// The [RichText] widget displays text that uses multiple different styles. The
/// text to display is described using a tree of [TextSpan] objects, each of
/// which has an associated style that is used for that subtree.
///
/// This is a simplified version of Flutter's RichText adapted for terminal
/// rendering, without support for text direction, text scaling, or gesture
/// recognition.
class RichText extends SingleChildRenderObjectComponent {
  /// Creates a rich text widget.
  ///
  /// The [text] parameter must not be null.
  const RichText({
    super.key,
    required this.text,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  });

  /// The text to display in this widget.
  final InlineSpan text;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the text will be laid out as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is null (the default), the text will not be limited to any number
  /// of lines.
  final int? maxLines;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParagraph(
      text: text,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderParagraph renderObject) {
    renderObject
      ..text = text
      ..textAlign = textAlign
      ..softWrap = softWrap
      ..overflow = overflow
      ..maxLines = maxLines;
  }
}
