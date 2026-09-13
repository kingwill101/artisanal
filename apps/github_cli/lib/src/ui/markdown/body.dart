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
  // A flat segment index is not unique once a disclosure contains another
  // disclosure. The full path also keeps sibling and nested toggles
  // independent when their visible heights change.
  final Map<String, bool> _expandedDetails = <String, bool>{};
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
                _segmentWidget(theme, hasDarkBackground, _segments[i], <int>[
                  i,
                ], maxWidth: widget.maxWidth),
            ],
          );
    return content;
  }

  w.Widget _segmentWidget(
    w.Theme theme,
    bool hasDarkBackground,
    GithubMarkdownSegment segment,
    List<int> path, {
    required int? maxWidth,
  }) {
    switch (segment) {
      case GithubMarkdownTextSegment(:final markdown):
        return _markdownText(
          theme,
          markdown,
          hasDarkBackground,
          maxWidth: maxWidth,
        );
      case GithubMarkdownDetailsSegment(
        :final summary,
        :final markdown,
        :final initiallyExpanded,
        :final quoted,
        :final children,
      ):
        final key = path.join('.');
        final bodyWidth = maxWidth == null ? null : math.max(1, maxWidth - 2);
        final detailsBody = children.isEmpty
            ? _markdownText(
                theme,
                markdown.trim().isEmpty ? '_No details provided._' : markdown,
                hasDarkBackground,
                maxWidth: bodyWidth,
              )
            : w.Column(
                crossAxisAlignment: w.CrossAxisAlignment.stretch,
                gap: 1,
                children: [
                  for (var i = 0; i < children.length; i++)
                    _segmentWidget(theme, hasDarkBackground, children[i], <int>[
                      ...path,
                      i,
                    ], maxWidth: bodyWidth),
                ],
              );
        final details = w.Accordion(
          title: summary,
          expanded: _expandedDetails[key] ?? initiallyExpanded,
          onChanged: (expanded) {
            setState(() {
              _expandedDetails[key] = expanded;
            });
            return null;
          },
          child: detailsBody,
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
        final source = context.text.trim();
        try {
          final rendered = renderSequenceDiagram(
            source,
            maxWidth: context.options.width,
          );
          // Other Mermaid diagram types still have a useful literal fallback.
          return rendered.isEmpty ? null : rendered;
        } on FormatException catch (error) {
          // Invalid or unsupported input is comment content, not an app failure.
          // Indented code keeps both diagnostics and source literal and cannot
          // re-enter this Mermaid handler through a source-provided fence.
          final literal = '${error.message}\n\n$source'
              .split('\n')
              .map((line) => '    $line')
              .join('\n');
          return context.renderMarkdown(
            'Sequence diagram could not be rendered:\n\n$literal',
          );
        }
      },
    ],
    codeBlockBorderStyle: Border.rounded,
    syntaxHighlighting: false,
  );
}
