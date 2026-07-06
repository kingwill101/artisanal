part of 'selection.dart';

/// A markdown widget that supports click-drag selection and Ctrl+C copy.
///
/// This mirrors [MarkdownText] but participates in the shared selection
/// system used by [SelectionArea].
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
  });

  final String data;
  final AnsiRendererOptions? options;
  final Style? textStyle;
  final Style? selectionHighlightStyle;
  final bool softWrap;
  final int? maxWidth;
  final SelectionController? controller;

  @override
  Widget build(BuildContext context) {
    return _SelectableRenderedText(
      text: MarkdownText(
        data: data,
        options: options,
        textStyle: textStyle,
        softWrap: softWrap,
        maxWidth: maxWidth,
      ).view().toString(),
      controller: controller,
      selectionHighlightStyle: selectionHighlightStyle,
    );
  }
}
