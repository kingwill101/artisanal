part of 'selection.dart';

/// A rich-text widget that supports click-drag selection and Ctrl+C copy.
///
/// This mirrors [RichText] but participates in the shared selection system.
class SelectableRichText extends StatelessWidget {
  SelectableRichText({
    required this.text,
    super.key,
    this.style,
    this.textStyle,
    this.selectionHighlightStyle,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    this.controller,
  });

  final TextSpan text;

  /// Complete Artisanal base style inherited by the span tree.
  final Style? style;

  /// Immutable text-only declarations applied after [style].
  final TextStyle? textStyle;

  final Style? selectionHighlightStyle;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxWidth;
  final SelectionController? controller;

  @override
  Widget build(BuildContext context) {
    final content = _renderRichSpanContent(
      text,
      baseStyle: style,
      baseTextStyle: textStyle,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxWidth: maxWidth,
    );
    return _SelectableRenderedText(
      text: content.text,
      controller: controller,
      selectionHighlightStyle: selectionHighlightStyle,
      selectionHighlightRangesByLine: content.selectionHighlightRangesByLine,
    );
  }
}
