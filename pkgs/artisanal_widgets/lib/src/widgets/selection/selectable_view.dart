part of 'selection.dart';

/// A generic string/View wrapper that participates in text selection.
///
/// Use this for lower-level `view()`-style string content that is not already
/// represented as [SelectableText] or [SelectableRichText].
/// Wrapped content follows the parent's available width and reflows on resize;
/// [maxWidth] can impose a smaller limit.
class SelectableView extends StatelessWidget {
  SelectableView(
    this.content, {
    super.key,
    this.selectionHighlightStyle,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    this.controller,
    this.onSelectionChanged,
    this.onSelectionEnd,
  });

  final Object content;
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
    return LayoutBuilder(
      builder: (context, constraints) => _SelectableRenderedText(
        text: _renderSelectableView(
          content,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxWidth: _selectionLayoutWidth(constraints, maxWidth),
        ),
        controller: controller,
        onSelectionChanged: onSelectionChanged,
        onSelectionEnd: onSelectionEnd,
        selectionHighlightStyle: selectionHighlightStyle,
      ),
    );
  }
}
