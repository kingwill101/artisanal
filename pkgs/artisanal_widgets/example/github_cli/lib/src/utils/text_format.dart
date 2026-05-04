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
  });

  final String summary;
  final String markdown;
  final bool initiallyExpanded;
}

String githubDisplayMarkdown(String input) {
  return input
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((line) => line.trimRight())
      .join('\n')
      .trim();
}

List<GithubMarkdownSegment> githubDisplayMarkdownSegments(String input) {
  final source = input.trim();
  if (source.isEmpty) return const <GithubMarkdownSegment>[];

  final segments = <GithubMarkdownSegment>[];
  var cursor = 0;
  while (cursor < source.length) {
    final openMatch = _detailsOpenPattern.firstMatch(source.substring(cursor));
    if (openMatch == null) {
      _addTextSegment(segments, source.substring(cursor));
      break;
    }

    final openStart = cursor + openMatch.start;
    final openEnd = cursor + openMatch.end;
    _addTextSegment(segments, source.substring(cursor, openStart));

    final closeMatch = _findClosingDetailsTag(source, openEnd);
    if (closeMatch == null) {
      _addTextSegment(segments, source.substring(openStart));
      break;
    }

    final openTag = source.substring(openStart, openEnd);
    final detailsBody = source.substring(openEnd, closeMatch.start);
    segments.add(_detailsSegment(openTag, detailsBody));
    cursor = closeMatch.end;
  }

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

final _detailsOpenPattern = RegExp(r'<details\b[^>]*>', caseSensitive: false);

final _detailsTagPattern = RegExp(r'</?details\b[^>]*>', caseSensitive: false);

void _addTextSegment(List<GithubMarkdownSegment> segments, String source) {
  final markdown = githubDisplayMarkdown(source);
  if (markdown.trim().isEmpty) return;
  segments.add(GithubMarkdownTextSegment(markdown));
}

RegExpMatch? _findClosingDetailsTag(String source, int start) {
  var depth = 1;
  for (final match in _detailsTagPattern.allMatches(source, start)) {
    final tag = match.group(0) ?? '';
    if (tag.startsWith(RegExp(r'</', caseSensitive: false))) {
      depth--;
      if (depth == 0) return match;
    } else {
      depth++;
    }
  }
  return null;
}

GithubMarkdownDetailsSegment _detailsSegment(String openTag, String body) {
  final summaryPattern = RegExp(
    r'<summary\b[^>]*>(.*?)</summary>',
    caseSensitive: false,
    dotAll: true,
  );
  final summaryMatch = summaryPattern.firstMatch(body);
  final summary = _decodeHtml(
    _stripTags(summaryMatch?.group(1) ?? 'Details'),
  ).trim();
  final title = summary.isEmpty ? 'Details' : summary;
  final content = summaryMatch == null
      ? body
      : body.replaceRange(summaryMatch.start, summaryMatch.end, '');

  return GithubMarkdownDetailsSegment(
    summary: title,
    markdown: githubDisplayMarkdown(content),
    initiallyExpanded: _hasOpenAttribute(openTag),
  );
}

String _stripTags(String input) {
  return input.replaceAll(RegExp(r'<[^>]+>', dotAll: true), '');
}

bool _hasOpenAttribute(String value) {
  return RegExp(
    r'(^|[\s<])open(?:\s|=|>|/|$)',
    caseSensitive: false,
  ).hasMatch(value);
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
