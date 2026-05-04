import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/markdown.dart' as markdown;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../utils/text_format.dart';

final class GithubMarkdownBody extends w.StatefulWidget {
  GithubMarkdownBody({
    required this.data,
    this.fallbackMarkdown,
    this.textStyle,
    this.maxWidth,
    super.key,
  });

  final String data;
  final String? fallbackMarkdown;
  final Style? textStyle;
  final int? maxWidth;

  @override
  w.State<GithubMarkdownBody> createState() => _GithubMarkdownBodyState();
}

final class _GithubMarkdownBodyState extends w.State<GithubMarkdownBody> {
  static const _markdownOptions = markdown.AnsiRendererOptions(
    syntaxHighlighting: false,
  );

  final Map<int, bool> _expandedDetails = <int, bool>{};
  late List<GithubMarkdownSegment> _segments;
  late String _fallbackMarkdown;

  @override
  void initState() {
    super.initState();
    _refreshMarkdownCache();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant GithubMarkdownBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _expandedDetails.clear();
    }
    if (oldWidget.data != widget.data ||
        oldWidget.fallbackMarkdown != widget.fallbackMarkdown) {
      _refreshMarkdownCache();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    if (_segments.isEmpty) {
      return _markdownText(_fallbackMarkdown);
    }

    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      gap: 1,
      children: [
        for (var i = 0; i < _segments.length; i++)
          _segmentWidget(_segments[i], i),
      ],
    );
  }

  w.Widget _segmentWidget(GithubMarkdownSegment segment, int index) {
    return switch (segment) {
      GithubMarkdownTextSegment(:final markdown) => _markdownText(markdown),
      GithubMarkdownDetailsSegment(
        :final summary,
        :final markdown,
        :final initiallyExpanded,
      ) =>
        w.Accordion(
          title: summary,
          expanded: _expandedDetails[index] ?? initiallyExpanded,
          onChanged: (expanded) {
            setState(() {
              _expandedDetails[index] = expanded;
            });
            return null;
          },
          child: _markdownText(
            markdown.trim().isEmpty ? '_No details provided._' : markdown,
          ),
        ),
    };
  }

  w.Widget _markdownText(String markdown) {
    return w.MarkdownText(
      data: markdown,
      options: _markdownOptions,
      softWrap: true,
      maxWidth: widget.maxWidth,
      textStyle: widget.textStyle,
    );
  }

  void _refreshMarkdownCache() {
    _segments = githubDisplayMarkdownSegments(widget.data);
    _fallbackMarkdown = _computeFallbackMarkdown();
  }

  String _computeFallbackMarkdown() {
    final fallback = widget.fallbackMarkdown?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    final markdown = githubDisplayMarkdown(widget.data).trim();
    return markdown.isEmpty ? '_No description provided._' : markdown;
  }
}
