import 'package:html/parser.dart' as html;

import 'github_html_tags.dart';

/// Maximum number of nested GitHub disclosures that are made interactive.
///
/// Disclosures below this depth remain available through their parent's
/// [GithubMarkdownDetailsSegment.markdown] and are represented in
/// [GithubMarkdownDetailsSegment.children] by a literal source fallback.
const githubMaxInteractiveDetailsDepth = 32;

/// Maximum nesting depth for interactive quote containers.
const githubMaxInteractiveQuoteDepth = 32;

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
    this.children = const <GithubMarkdownSegment>[],
  });

  final String summary;
  final String markdown;
  final bool initiallyExpanded;
  final bool quoted;

  /// The disclosure body split into text and nested disclosures.
  ///
  /// [markdown] remains available as the original body for callers that do
  /// not render interactive disclosures. Consumers that support disclosures
  /// should render these segments recursively.
  final List<GithubMarkdownSegment> children;
}

/// A block quote and all of its content, including interactive disclosures.
final class GithubMarkdownQuoteSegment extends GithubMarkdownSegment {
  const GithubMarkdownQuoteSegment(this.children);

  final List<GithubMarkdownSegment> children;
}

/// A GitHub-flavoured block quote alert.
final class GithubMarkdownAlertSegment extends GithubMarkdownSegment {
  const GithubMarkdownAlertSegment({
    required this.kind,
    required this.markdown,
    this.children = const <GithubMarkdownSegment>[],
  });

  final String kind;
  final String markdown;
  final List<GithubMarkdownSegment> children;
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
  return _githubDisplayMarkdownSegments(input, depth: 0, allowAlerts: false);
}

List<GithubMarkdownSegment> _githubDisplayMarkdownSegments(
  String input, {
  required int depth,
  required bool allowAlerts,
}) {
  final source = githubDisplayMarkdown(input);
  if (source.isEmpty) return const <GithubMarkdownSegment>[];

  final alert = allowAlerts ? _alertSegment(source, depth: depth) : null;
  if (alert != null) return <GithubMarkdownSegment>[alert];

  // Extract quote runs before scanning HTML. This keeps one semantic parent
  // around text and disclosures, instead of giving every child its own rail.
  final lines = source.split('\n');
  final quoteLines = _quoteLineMask(lines);
  if (quoteLines.any((value) => value)) {
    final segments = <GithubMarkdownSegment>[];
    var cursor = 0;
    var line = 0;
    while (line < lines.length) {
      if (!quoteLines[line] || !_hasBlockquoteMarker(lines[line])) {
        line++;
        continue;
      }
      final start = lines.take(line).join('\n').length + (line == 0 ? 0 : 1);
      var end = line;
      var sawBlank = false;
      while (end < lines.length) {
        final continues =
            (quoteLines[end] && _hasBlockquoteMarker(lines[end])) ||
            (end > line &&
                lines[end].trim().isNotEmpty &&
                !sawBlank &&
                !_startsBlockMarkdown(lines[end])) ||
            (lines[end].trim().isEmpty &&
                end + 1 < lines.length &&
                _hasBlockquoteMarker(lines[end + 1]));
        if (!continues) break;
        if (_stripOneBlockquoteMarker(lines[end]).trim().isEmpty) {
          sawBlank = true;
        }
        end++;
      }
      segments.addAll(
        _githubDisplayMarkdownSegments(
          source.substring(cursor, start),
          depth: depth,
          allowAlerts: allowAlerts,
        ),
      );
      final quoted = lines
          .sublist(line, end)
          .map(_stripOneBlockquoteMarker)
          .join('\n');
      final quoteChildren = depth + 1 < githubMaxInteractiveQuoteDepth
          ? _githubDisplayMarkdownSegments(
              quoted,
              depth: depth + 1,
              allowAlerts: true,
            )
          : <GithubMarkdownSegment>[
              GithubMarkdownTextSegment(
                'Nested quote depth limit reached; remaining source is shown '
                'literally:\n\n$quoted',
              ),
            ];
      segments.add(GithubMarkdownQuoteSegment(quoteChildren));
      cursor = end == lines.length
          ? source.length
          : lines.take(end).join('\n').length;
      line = end;
    }
    segments.addAll(
      _githubDisplayMarkdownSegments(
        source.substring(cursor),
        depth: depth,
        allowAlerts: allowAlerts,
      ),
    );
    return segments;
  }

  final segments = <GithubMarkdownSegment>[];
  final tags = githubHtmlTags(source)
      .where((tag) => tag.group(1)!.toLowerCase() == 'details')
      .toList();
  var cursor = 0;
  for (var index = 0; index < tags.length; index++) {
    final openMatch = tags[index];
    if (openMatch.group(0)!.startsWith('</')) continue;
    final openStart = openMatch.start;
    final openEnd = openMatch.end;
    _addTextSegment(segments, source.substring(cursor, openStart));

    var nestingDepth = 1;
    var closeIndex = index + 1;
    for (; closeIndex < tags.length; closeIndex++) {
      nestingDepth += tags[closeIndex].group(0)!.startsWith('</') ? -1 : 1;
      if (nestingDepth == 0) break;
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
        depth: depth,
      ),
    );
    cursor = closeMatch.end;
    index = closeIndex;
  }
  _addTextSegment(segments, source.substring(cursor));
  return segments;
}

bool _hasBlockquoteMarker(String line) {
  var index = 0;
  while (index < line.length && index < 3 && line[index] == ' ') {
    index++;
  }
  return index < line.length && line[index] == '>';
}

List<bool> _quoteLineMask(List<String> lines) {
  final result = List<bool>.filled(lines.length, false);
  String? fence;
  var fenceLength = 0;
  var fenceIsQuoted = false;
  var inPre = false;
  var preIsQuoted = false;
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final hasQuote = _hasBlockquoteMarker(raw);
    final logical = hasQuote ? _stripOneBlockquoteMarker(raw) : raw;
    final trimmed = logical.trimLeft();
    if (inPre) {
      if (preIsQuoted && hasQuote) result[i] = true;
      if (RegExp(r'^</pre\s*>', caseSensitive: false).hasMatch(trimmed)) {
        inPre = false;
      }
      continue;
    }
    if (fence != null) {
      if (fenceIsQuoted && hasQuote) result[i] = true;
      if (trimmed.startsWith(fence) &&
          trimmed.length >= fenceLength &&
          RegExp('^${RegExp.escape(fence)}{$fenceLength,}\\s*\$')
              .hasMatch(trimmed)) {
        fence = null;
      }
      continue;
    }
    if (RegExp(r'^<pre(?:\s|>)', caseSensitive: false).hasMatch(trimmed)) {
      inPre = true;
      preIsQuoted = hasQuote;
      if (hasQuote) result[i] = true;
      continue;
    }
    final fenceMatch = RegExp(r'^(`{3,}|~{3,})').firstMatch(trimmed);
    if (fenceMatch != null) {
      fence = fenceMatch.group(1)![0];
      fenceLength = fenceMatch.group(1)!.length;
      fenceIsQuoted = hasQuote;
      if (hasQuote) result[i] = true;
      continue;
    }
    if (hasQuote) result[i] = true;
  }
  return result;
}

bool _startsBlockMarkdown(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('<') ||
      trimmed.startsWith('```') ||
      trimmed.startsWith('~~~') ||
      RegExp(r'^(?:#{1,6}\s|[-*_]{3,}\s*$|[-+*]\s|\d+[.)]\s)')
          .hasMatch(trimmed);
}

String _stripOneBlockquoteMarker(String line) {
  var index = 0;
  while (index < line.length && index < 3 && line[index] == ' ') {
    index++;
  }
  if (index == line.length || line[index] != '>') return line;
  index++;
  if (index < line.length && line[index] == ' ') index++;
  return line.substring(index);
}

GithubMarkdownAlertSegment? _alertSegment(String source, {required int depth}) {
  final lines = source.split('\n');
  final match = RegExp(
    r'^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*$',
    caseSensitive: false,
  ).firstMatch(lines.first);
  if (match == null) return null;
  final markdown = lines.skip(1).join('\n');
  final children = markdown.trim().isEmpty
      ? const <GithubMarkdownSegment>[]
      : _githubDisplayMarkdownSegments(
          markdown,
          depth: depth + 1,
          allowAlerts: false,
        );
  return GithubMarkdownAlertSegment(
    kind: match.group(1)!.toUpperCase(),
    markdown: markdown,
    children: children,
  );
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
  required int depth,
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
  final children = depth + 1 < githubMaxInteractiveDetailsDepth
      ? _githubDisplayMarkdownSegments(
          markdown,
          depth: depth + 1,
          allowAlerts: false,
        )
      : <GithubMarkdownSegment>[_literalDetailsFallback(markdown)];

  return GithubMarkdownDetailsSegment(
    summary: title,
    markdown: markdown,
    initiallyExpanded: _hasOpenAttribute(openTag),
    quoted: quoted,
    children: children,
  );
}

GithubMarkdownTextSegment _literalDetailsFallback(String source) {
  final maxBackticks = RegExp(r'`+')
      .allMatches(source)
      .map((match) => match.group(0)!.length)
      .fold<int>(0, (longest, length) => length > longest ? length : longest);
  final fence = '`' * (maxBackticks < 3 ? 3 : maxBackticks + 1);
  return GithubMarkdownTextSegment(
    'Nested GitHub disclosure depth limit reached; '
    'remaining source is shown literally:\n\n'
    '$fence\n$source\n$fence',
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
