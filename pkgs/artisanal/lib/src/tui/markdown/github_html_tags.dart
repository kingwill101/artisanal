/// Source spans of HTML tags which can participate in GitHub disclosures.
///
/// This scanner does not render or normalize HTML. It keeps original offsets
/// for the interactive details splitter while skipping opaque Markdown/HTML
/// regions (comments, fenced/indented/inline code, and raw code/script elements).
/// [startsInHtmlBlock] is used for a details body beginning immediately after
/// its opening tag, so an indented HTML summary is not mistaken for code.
Iterable<Match> githubHtmlTags(
  String source, {
  bool startsInHtmlBlock = false,
}) sync* {
  String? fence;
  var fenceLength = 0;
  var fenceQuoteDepth = 0;
  var fenceIndent = 0;
  var inHtmlBlock = startsInHtmlBlock;
  final listIndents = <int>[];
  var index = 0;
  while (index < source.length) {
    if (index == 0 || source.codeUnitAt(index - 1) == 10) {
      final newline = source.indexOf('\n', index);
      final end = newline < 0 ? source.length : newline;
      var line = source.substring(index, end);
      final quote = _quotePrefix.matchAsPrefix(line);
      final quoteDepth = quote == null
          ? 0
          : quote.group(0)!.split('>').length - 1;
      line = quote == null ? line : line.substring(quote.end);
      line = _expandTabs(line);
      final indent = line.length - line.trimLeft().length;
      final blank = line.trim().isEmpty;
      if (fence != null &&
          (quoteDepth < fenceQuoteDepth || (!blank && indent < fenceIndent))) {
        fence = null; // The containing quote/list ended before its fence.
      }
      if (fence == null && !blank) {
        while (listIndents.isNotEmpty && indent < listIndents.last) {
          listIndents.removeLast();
        }
      }
      final baseIndent = listIndents.isEmpty ? 0 : listIndents.last;
      if (blank && (!startsInHtmlBlock || index > 0)) inHtmlBlock = false;
      if (fence == null && !inHtmlBlock && indent - baseIndent >= 4) {
        index = end < source.length ? end + 1 : end;
        continue; // Indented literal code, including tags that look interactive.
      }
      final list = _listPrefix.matchAsPrefix(line);
      if (fence == null && list != null) {
        listIndents.add(list.end);
        line = line.substring(list.end);
      } else if (baseIndent > 0 && line.length >= baseIndent) {
        line = line.substring(baseIndent);
      }
      if (_blockHtml.matchAsPrefix(line.trimLeft()) != null) inHtmlBlock = true;
      final match = _fence.matchAsPrefix(line);
      if (fence != null) {
        if (match != null &&
            match.group(1)![0] == fence &&
            match.group(1)!.length >= fenceLength &&
            match.group(2)!.trim().isEmpty) {
          fence = null;
        }
        index = end < source.length ? end + 1 : end;
        continue;
      }
      if (match != null &&
          !(match.group(1)!.startsWith('`') && match.group(2)!.contains('`'))) {
        fence = match.group(1)![0];
        fenceLength = match.group(1)!.length;
        fenceQuoteDepth = quoteDepth;
        fenceIndent = listIndents.isEmpty ? 0 : listIndents.last;
        index = end < source.length ? end + 1 : end;
        continue;
      }
    }
    final character = source.codeUnitAt(index);
    if (character == 92 && index + 1 < source.length) {
      // Escaped punctuation cannot open an HTML tag or code span.
      index += 2;
      continue;
    }
    if (character == 96) {
      var end = index + 1;
      while (end < source.length && source.codeUnitAt(end) == 96) {
        end++;
      }
      final run = source.substring(index, end);
      var close = source.indexOf(run, end);
      while (close >= 0) {
        final after = close + run.length;
        if (source.codeUnitAt(close - 1) != 96 &&
            (after == source.length || source.codeUnitAt(after) != 96)) {
          break;
        }
        close = source.indexOf(run, after);
      }
      index = close < 0 ? end : close + run.length;
      continue;
    }
    if (source.startsWith('<!--', index)) {
      final close = source.indexOf('-->', index + 4);
      if (close < 0) return;
      index = close + 3;
      continue;
    }
    if (character == 60) {
      final match = _tag.matchAsPrefix(source, index);
      if (match != null) {
        final name = match.group(1)!.toLowerCase();
        final closing = match.group(0)!.startsWith('</');
        final closingPattern = _opaqueClosingPatterns[name];
        if (!closing && closingPattern != null) {
          final matches = closingPattern.allMatches(source, match.end).iterator;
          if (!matches.moveNext()) return;
          index = matches.current.end;
          continue;
        }
        yield match;
        index = match.end;
        continue;
      }
    }
    index++;
  }
}

final _opaqueClosingPatterns = {
  for (final name in ['pre', 'code', 'script', 'style', 'textarea'])
    name: RegExp('</$name\\s*>', caseSensitive: false),
};

final _tag = RegExp(
  r'''</?([a-zA-Z][a-zA-Z0-9:-]*)(?:[^"'<>]|"[^"]*"|'[^']*')*>''',
);
final _quotePrefix = RegExp(r'^(?: {0,3}> ?)+');
final _listPrefix = RegExp(r'^ *(?:[-+*]|[0-9]{1,9}[.)]) +');
final _fence = RegExp(r'^ *(`{3,}|~{3,})(.*)$');
final _blockHtml = RegExp(
  r'^</?(?:details|summary|blockquote|div|section|article|ul|ol|li|p|table|thead|tbody|tr|td|th)\b',
  caseSensitive: false,
);

String _expandTabs(String line) {
  if (!line.contains('\t')) return line;
  final result = StringBuffer();
  var column = 0;
  for (final rune in line.runes) {
    if (rune == 9) {
      final count = 4 - column % 4;
      result.write(' ' * count);
      column += count;
    } else {
      result.writeCharCode(rune);
      column++;
    }
  }
  return result.toString();
}
