part of 'selection_widgets.dart';

/// A generic string/View wrapper that participates in text selection.
///
/// Use this for lower-level `view()`-style string content that is not already
/// represented as [SelectableText] or [SelectableRichText].
class SelectableView extends StatelessWidget {
  SelectableView(
    this.content, {
    super.key,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    this.controller,
  });

  final Object content;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxWidth;
  final SelectionController? controller;

  @override
  Widget build(BuildContext context) {
    return _SelectableRenderedText(
      text: _renderSelectableView(
        content,
        textAlign: textAlign,
        softWrap: softWrap,
        overflow: overflow,
        maxWidth: maxWidth,
      ),
      controller: controller,
    );
  }
}
