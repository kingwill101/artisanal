import 'package:html/parser.dart' as html;

import 'github_html_tags.dart';

final class GithubImageReference {
  const GithubImageReference({required this.url, required this.alt});

  final String url;
  final String alt;
}

sealed class GithubMarkdownSegment {
  const GithubMarkdownSegment();
}

final class GithubMarkdownTextSegment extends GithubMarkdownSegment {
  const GithubMarkdownTextSegment(this.markdown);

  final String markdown;
}

final class GithubMarkdownDetailsSegment extends GithubMarkdownSegment {
  const GithubMarkdownDetailsSegment({
    required this.summary,
    required this.markdown,
    required this.initiallyExpanded,
    required this.quoted,
  });

  final String summary;
  final String markdown;
  final bool initiallyExpanded;
  final bool quoted;
}

String githubDisplayMarkdown(String input) {
  final lines = input
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  var start = 0;
  var end = lines.length;
  while (start < end && lines[start].trim().isEmpty) {
    start++;
  }
  while (end > start && lines[end - 1].trim().isEmpty) {
    end--;
  }
  // Indentation and trailing spaces are Markdown syntax, not display noise.
  return lines.sublist(start, end).join('\n');
}

String githubStripBlockquoteMarkers(String input) {
  return githubDisplayMarkdown(
    input
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) {
          if (!line.startsWith('>')) return line;
          final remainder = line.substring(1);
          return remainder.startsWith(' ') ? remainder.substring(1) : remainder;
        })
        .join('\n'),
  );
}

List<GithubMarkdownSegment> githubDisplayMarkdownSegments(String input) {
  final source = githubDisplayMarkdown(input);
  if (source.isEmpty) return const <GithubMarkdownSegment>[];

  final segments = <GithubMarkdownSegment>[];
  final tags = githubHtmlTags(
    source,
  ).where((tag) => tag.group(1)!.toLowerCase() == 'details').toList();
  var cursor = 0;
  for (var index = 0; index < tags.length; index++) {
    final openMatch = tags[index];
    if (openMatch.group(0)!.startsWith('</')) continue;
    final openStart = openMatch.start;
    final openEnd = openMatch.end;
    _addTextSegment(segments, source.substring(cursor, openStart));

    var depth = 1;
    var closeIndex = index + 1;
    for (; closeIndex < tags.length; closeIndex++) {
      depth += tags[closeIndex].group(0)!.startsWith('</') ? -1 : 1;
      if (depth == 0) break;
    }
    if (closeIndex == tags.length) {
      cursor = openStart;
      break;
    }
    final closeMatch = tags[closeIndex];
    final openTag = source.substring(openStart, openEnd);
    final detailsBody = source.substring(openEnd, closeMatch.start);
    segments.add(
      _detailsSegment(
        openTag,
        detailsBody,
        quoted: _isQuotedDetailsTag(source, openStart),
      ),
    );
    cursor = closeMatch.end;
    index = closeIndex;
  }
  _addTextSegment(segments, source.substring(cursor));
  return segments;
}

List<GithubImageReference> githubImageReferences(String input) {
  final images = <GithubImageReference>[];
  final seen = <String>{};

  void add(String url, String alt) {
    final normalized = _decodeHtml(url.trim());
    if (!_isRenderableImageUrl(normalized) || !seen.add(normalized)) return;
    images.add(
      GithubImageReference(url: normalized, alt: _decodeHtml(alt.trim())),
    );
  }

  for (final match in RegExp(
    r'!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)',
  ).allMatches(input)) {
    add(match.group(2) ?? '', match.group(1) ?? 'image');
  }

  for (final match in RegExp(
    r'<img\b[^>]*>',
    caseSensitive: false,
  ).allMatches(input)) {
    final tag = match.group(0) ?? '';
    add(_htmlAttribute(tag, 'src'), _htmlAttribute(tag, 'alt'));
  }

  return images;
}

void _addTextSegment(List<GithubMarkdownSegment> segments, String source) {
  final markdown = githubDisplayMarkdown(source);
  if (markdown.trim().isEmpty) return;
  segments.add(GithubMarkdownTextSegment(markdown));
}

GithubMarkdownDetailsSegment _detailsSegment(
  String openTag,
  String body, {
  required bool quoted,
}) {
  Match? summaryStart;
  Match? summaryEnd;
  var nestedDetails = 0;
  for (final tag in githubHtmlTags(body, startsInHtmlBlock: true)) {
    final name = tag.group(1)!.toLowerCase();
    final closing = tag.group(0)!.startsWith('</');
    if (name == 'details') nestedDetails += closing ? -1 : 1;
    if (nestedDetails != 0 || name != 'summary') continue;
    if (!closing) {
      summaryStart ??= tag;
    } else if (summaryStart != null) {
      summaryEnd = tag;
      break;
    }
  }
  final hasSummary = summaryStart != null && summaryEnd != null;
  final summary =
      html
          .parseFragment(
            hasSummary
                ? body.substring(summaryStart.end, summaryEnd.start)
                : 'Details',
          )
          .text
          ?.trim() ??
      '';
  final title = summary.isEmpty ? 'Details' : summary;
  final content = hasSummary
      ? body.replaceRange(summaryStart.start, summaryEnd.end, '')
      : body;
  final markdown = quoted
      ? githubStripBlockquoteMarkers(githubDisplayMarkdown(content))
      : githubDisplayMarkdown(content);

  return GithubMarkdownDetailsSegment(
    summary: title,
    markdown: markdown,
    initiallyExpanded: _hasOpenAttribute(openTag),
    quoted: quoted,
  );
}

bool _isQuotedDetailsTag(String source, int tagStart) {
  if (tagStart == 0) return false;
  final lineStart = source.lastIndexOf('\n', tagStart - 1) + 1;
  final prefix = source.substring(lineStart, tagStart);
  final consumed = _consumeBlockquoteMarkersLocal(prefix);
  return consumed.depth > 0 && consumed.remainder.trim().isEmpty;
}

_BlockquoteMarker _consumeBlockquoteMarkersLocal(String text) {
  var index = 0;
  var depth = 0;

  while (index < text.length && text[index] == ' ') {
    index++;
  }

  while (index < text.length && text[index] == '>') {
    depth++;
    index++;
    if (index < text.length && text[index] == ' ') {
      index++;
    }
  }

  return _BlockquoteMarker(depth, text.substring(index));
}

final class _BlockquoteMarker {
  const _BlockquoteMarker(this.depth, this.remainder);

  final int depth;
  final String remainder;
}

bool _hasOpenAttribute(String value) {
  return html
          .parseFragment(value)
          .querySelector('details')
          ?.attributes
          .containsKey('open') ??
      false;
}

String _decodeHtml(String input) {
  return input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
        final value = int.tryParse(match.group(1) ?? '', radix: 16);
        return value == null ? match.group(0)! : String.fromCharCode(value);
      })
      .replaceAllMapped(RegExp(r'&#([0-9]+);'), (match) {
        final value = int.tryParse(match.group(1) ?? '');
        return value == null ? match.group(0)! : String.fromCharCode(value);
      });
}

String _htmlAttribute(String tag, String name) {
  final pattern = RegExp(
    "$name\\s*=\\s*([\"'])(.*?)\\1",
    caseSensitive: false,
    dotAll: true,
  );
  return pattern.firstMatch(tag)?.group(2) ?? '';
}

bool _isRenderableImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
    return false;
  }
  final path = uri.path.toLowerCase();
  return path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      uri.host.endsWith('githubusercontent.com') ||
      uri.host == 'github.com';
}
