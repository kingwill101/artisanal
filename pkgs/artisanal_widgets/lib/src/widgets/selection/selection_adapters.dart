part of 'selection_widgets.dart';

/// Convenience adapters that let read-only text widgets opt into the shared
/// selection model without changing their layout role.
extension SelectableTextAdapter on Text {
  Widget selectable({SelectionController? controller}) {
    if (textSpan != null) {
      return SelectableRichText(
        text: textSpan!,
        style: style,
        textAlign: textAlign,
        softWrap: softWrap,
        overflow: overflow,
        maxWidth: maxWidth,
        controller: controller,
      );
    }
    return SelectableText(
      data ?? '',
      style: style,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxWidth: maxWidth,
      controller: controller,
    );
  }
}

/// Convenience adapter for [RichText].
extension SelectableRichTextAdapter on RichText {
  Widget selectable({SelectionController? controller}) {
    return SelectableRichText(
      text: text,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxWidth: maxWidth,
      controller: controller,
    );
  }
}

/// Convenience adapter for [MarkdownText].
extension SelectableMarkdownTextAdapter on MarkdownText {
  Widget selectable({SelectionController? controller}) {
    return SelectableMarkdownText(
      data: data,
      options: options,
      textStyle: textStyle,
      softWrap: softWrap,
      maxWidth: maxWidth,
      controller: controller,
    );
  }
}

/// Convenience adapter for generic [View] content.
extension SelectableViewAdapter on View {
  Widget selectable({
    SelectionController? controller,
    TextAlign textAlign = TextAlign.left,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    int? maxWidth,
  }) {
    return SelectableView(
      this,
      controller: controller,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxWidth: maxWidth,
    );
  }
}
