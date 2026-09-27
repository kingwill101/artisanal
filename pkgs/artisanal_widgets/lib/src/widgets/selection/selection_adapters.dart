part of 'selection.dart';

/// Convenience adapters that let read-only text widgets opt into the shared
/// selection model without changing their layout role.
extension SelectableTextAdapter on Text {
  Widget selectable({
    SelectionController? controller,
    SelectionCallback? onSelectionChanged,
    SelectionCallback? onSelectionEnd,
    Style? selectionHighlightStyle,
  }) {
    if (textSpan != null) {
      return SelectableRichText(
        text: textSpan!,
        style: style,
        selectionHighlightStyle: selectionHighlightStyle,
        textAlign: textAlign,
        softWrap: softWrap,
        overflow: overflow,
        maxWidth: maxWidth,
        controller: controller,
        onSelectionChanged: onSelectionChanged,
        onSelectionEnd: onSelectionEnd,
      );
    }
    return SelectableText(
      data ?? '',
      style: style,
      selectionHighlightStyle: selectionHighlightStyle,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxWidth: maxWidth,
      controller: controller,
      onSelectionChanged: onSelectionChanged,
      onSelectionEnd: onSelectionEnd,
    );
  }
}

/// Convenience adapter for [RichText].
extension SelectableRichTextAdapter on RichText {
  Widget selectable({
    SelectionController? controller,
    SelectionCallback? onSelectionChanged,
    SelectionCallback? onSelectionEnd,
    Style? selectionHighlightStyle,
  }) {
    return SelectableRichText(
      text: text,
      selectionHighlightStyle: selectionHighlightStyle,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxWidth: maxWidth,
      controller: controller,
      onSelectionChanged: onSelectionChanged,
      onSelectionEnd: onSelectionEnd,
    );
  }
}

/// Convenience adapter for [MarkdownText].
extension SelectableMarkdownTextAdapter on MarkdownText {
  Widget selectable({
    SelectionController? controller,
    SelectionCallback? onSelectionChanged,
    SelectionCallback? onSelectionEnd,
    Style? selectionHighlightStyle,
  }) {
    return SelectableMarkdownText(
      data: data,
      options: options,
      textStyle: textStyle,
      selectionHighlightStyle: selectionHighlightStyle,
      softWrap: softWrap,
      maxWidth: maxWidth,
      controller: controller,
      onSelectionChanged: onSelectionChanged,
      onSelectionEnd: onSelectionEnd,
    );
  }
}

/// Convenience adapter for generic [View] content.
extension SelectableViewAdapter on View {
  Widget selectable({
    SelectionController? controller,
    SelectionCallback? onSelectionChanged,
    SelectionCallback? onSelectionEnd,
    Style? selectionHighlightStyle,
    TextAlign textAlign = TextAlign.left,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    int? maxWidth,
  }) {
    return SelectableView(
      this,
      controller: controller,
      onSelectionChanged: onSelectionChanged,
      onSelectionEnd: onSelectionEnd,
      selectionHighlightStyle: selectionHighlightStyle,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxWidth: maxWidth,
    );
  }
}
