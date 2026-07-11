/// Render context for HTML-to-markdown conversion.
///
/// Tracks list state during HTML rendering, specifically ordered vs unordered
/// lists and the next item number for ordered lists.
class HtmlRenderContext {
  final List<HtmlListContext> lists = [];
}

/// Track list state within [HtmlRenderContext].
class HtmlListContext {
  HtmlListContext({required this.ordered, required this.next});

  final bool ordered;
  int next;
}

/// Context for `<details>` element rendering.
class DetailsContext {
  DetailsContext({required this.expanded});

  final bool expanded;
  bool inSummary = false;
}
