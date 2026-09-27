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
    this.onSelectionChanged,
    this.onSelectionEnd,
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

  /// Reports this widget's selected plain text, including an empty selection.
  final SelectionCallback? onSelectionChanged;

  /// Reports nonempty selected plain text after a user completes a selection.
  ///
  /// Programmatic changes and clearing do not fire this callback.
  final SelectionCallback? onSelectionEnd;

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
      onSelectionChanged: onSelectionChanged,
      onSelectionEnd: onSelectionEnd,
      selectionHighlightStyle: selectionHighlightStyle,
      selectionHighlightRangesByLine: content.selectionHighlightRangesByLine,
    );
  }
}
