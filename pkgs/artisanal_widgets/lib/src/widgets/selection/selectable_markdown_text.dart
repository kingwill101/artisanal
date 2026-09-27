part of 'selection.dart';

/// A markdown widget that supports click-drag selection and Ctrl+C copy.
///
/// This mirrors [MarkdownText] but participates in the shared selection
/// system used by [SelectionArea].
///
/// Wrapped content follows the parent's available width and reflows on resize.
/// [maxWidth] can impose a smaller limit without exceeding the parent.
class SelectableMarkdownText extends StatelessWidget {
  SelectableMarkdownText({
    required this.data,
    super.key,
    this.options,
    this.textStyle,
    this.selectionHighlightStyle,
    this.softWrap = true,
    this.maxWidth,
    this.controller,
    this.onSelectionChanged,
    this.onSelectionEnd,
  });

  final String data;
  final AnsiRendererOptions? options;
  final Style? textStyle;
  final Style? selectionHighlightStyle;
  final bool softWrap;
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
      builder: (context, constraints) {
        final width = _selectionLayoutWidth(constraints, maxWidth);
        final rendered = MarkdownText(
          data: data,
          options: options,
          textStyle: textStyle,
          softWrap: softWrap,
          maxWidth: softWrap ? width : math.max(1, Layout.getWidth(data)),
        ).view().toString();
        return _SelectableRenderedText(
          text: !softWrap && width != null
              ? Layout.truncateLines(rendered, width)
              : rendered,
          controller: controller,
          onSelectionChanged: onSelectionChanged,
          onSelectionEnd: onSelectionEnd,
          selectionHighlightStyle: selectionHighlightStyle,
        );
      },
    );
  }
}
