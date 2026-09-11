import 'package:artisanal/style.dart' show Border, Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/artisanal.dart'
    show AnsiRendererOptions, renderSequenceDiagram;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'dart:math' as math;

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
    final theme = w.ThemeScope.of(context);
    final hasDarkBackground = w.hasDarkBackground;
    final content = _segments.isEmpty
        ? _markdownText(theme, _fallbackMarkdown, hasDarkBackground)
        : w.Column(
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            gap: 1,
            children: [
              for (var i = 0; i < _segments.length; i++)
                _segmentWidget(theme, hasDarkBackground, _segments[i], i),
            ],
          );
    return content;
  }

  w.Widget _segmentWidget(
    w.Theme theme,
    bool hasDarkBackground,
    GithubMarkdownSegment segment,
    int index,
  ) {
    switch (segment) {
      case GithubMarkdownTextSegment(:final markdown):
        return _markdownText(theme, markdown, hasDarkBackground);
      case GithubMarkdownDetailsSegment(
        :final summary,
        :final markdown,
        :final initiallyExpanded,
        :final quoted,
      ):
        final details = w.Accordion(
          title: summary,
          expanded: _expandedDetails[index] ?? initiallyExpanded,
          onChanged: (expanded) {
            setState(() {
              _expandedDetails[index] = expanded;
            });
            return null;
          },
          child: _markdownText(
            theme,
            markdown.trim().isEmpty ? '_No details provided._' : markdown,
            hasDarkBackground,
            maxWidth: widget.maxWidth == null
                ? null
                : math.max(1, widget.maxWidth! - 2),
          ),
        );

        if (!quoted) return details;

        return w.DecoratedBox(
          decoration: w.BoxDecoration(
            border: Border.normal.copyWith(
              top: '',
              bottom: '',
              right: '',
              topLeft: '',
              topRight: '',
              bottomLeft: '',
              bottomRight: '',
            ),
          ),
          child: w.Padding(
            padding: const w.EdgeInsets.only(left: 1),
            child: details,
          ),
        );
    }
  }

  w.Widget _markdownText(
    w.Theme theme,
    String markdown,
    bool hasDarkBackground, {
    int? maxWidth,
  }) {
    return w.MarkdownText(
      data: markdown,
      options: githubMarkdownOptions(
        theme,
        hasDarkBackground: hasDarkBackground,
      ),
      softWrap: true,
      maxWidth: maxWidth ?? widget.maxWidth,
      textStyle: _bodyTextStyle(theme, hasDarkBackground),
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

Style _bodyTextStyle(w.Theme theme, bool hasDarkBackground) {
  final style = widgetTextStyleBase(hasDarkBackground);
  return style..foreground(theme.onBackground);
}

Style widgetTextStyleBase(bool hasDarkBackground) {
  return Style()..hasDarkBackground = hasDarkBackground;
}

AnsiRendererOptions githubMarkdownOptions(
  w.Theme theme, {
  required bool hasDarkBackground,
}) {
  final codeSurface = theme.surfaceVariant ?? theme.surface;
  Style themedStyle() => Style()..hasDarkBackground = hasDarkBackground;
  return AnsiRendererOptions(
    textStyle: themedStyle()..foreground(theme.onBackground),
    h1Style: themedStyle()
      ..bold()
      ..foreground(theme.primary),
    h2Style: themedStyle()
      ..bold()
      ..foreground(theme.primary),
    h3Style: themedStyle()
      ..bold()
      ..foreground(theme.primary),
    h4Style: themedStyle()
      ..bold()
      ..foreground(theme.primary),
    h5Style: themedStyle()
      ..bold()
      ..foreground(theme.primary),
    h6Style: themedStyle()
      ..bold()
      ..foreground(theme.primary),
    emphasisStyle: themedStyle()
      ..italic()
      ..foreground(theme.warning),
    strongStyle: themedStyle()
      ..bold()
      ..foreground(theme.onBackground),
    codeStyle: themedStyle()
      ..foreground(theme.primary)
      ..background(codeSurface),
    codeBlockStyle: themedStyle()
      ..foreground(theme.onBackground)
      ..background(codeSurface),
    linkStyle: themedStyle()
      ..foreground(theme.primary)
      ..underline(),
    blockquoteStyle: themedStyle()..foreground(theme.warning),
    blockquoteBorderColor: theme.warning,
    tableHeaderStyle: themedStyle()
      ..bold()
      ..foreground(theme.primary),
    tableCellStyle: themedStyle()..foreground(theme.onBackground),
    tableBorderStyle: themedStyle()..foreground(theme.border),
    blockHandlers: [
      (context) {
        if (context.tag != 'pre' || context.language != 'mermaid') return null;
        return renderSequenceDiagram(
          context.text.trim(),
          maxWidth: context.options.width,
        );
      },
    ],
    codeBlockBorderStyle: Border.rounded,
    syntaxHighlighting: false,
  );
}
