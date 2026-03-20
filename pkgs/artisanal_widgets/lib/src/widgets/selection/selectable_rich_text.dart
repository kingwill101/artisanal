part of 'selection_widgets.dart';

/// A rich-text widget that supports click-drag selection and Ctrl+C copy.
///
/// This mirrors [RichText] but participates in the shared selection system.
class SelectableRichText extends StatelessWidget {
  SelectableRichText({
    required this.text,
    super.key,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    this.controller,
  });

  final TextSpan text;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxWidth;
  final SelectionController? controller;

  @override
  Widget build(BuildContext context) {
    return _SelectableRenderedText(
      text: _renderRichSpanText(
        text,
        textAlign: textAlign,
        softWrap: softWrap,
        overflow: overflow,
        maxWidth: maxWidth,
      ),
      controller: controller,
    );
  }
}
