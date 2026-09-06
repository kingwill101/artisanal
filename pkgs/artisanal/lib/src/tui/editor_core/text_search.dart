library;

import 'text_document.dart';

/// Regex-capable find/replace over a [TextDocument].
///
/// Literal search already exists (`findTextQueryHighlights`); this module
/// adds patterns, capture groups, whole-word filtering, templated
/// replacement, and a cursor session (`TextSearchSession`) for
/// find-next/previous flows. Matching runs on the document text with a
/// UTF-16 → grapheme index table, so offsets stay in document (grapheme)
/// coordinates on every platform, including web.

/// A find query.
final class TextSearchQuery {
  const TextSearchQuery({
    required this.pattern,
    this.isRegex = false,
    this.caseSensitive = false,
    this.wholeWord = false,
  });

  final String pattern;
  final bool isRegex;
  final bool caseSensitive;
  final bool wholeWord;
}

/// One match in document coordinates.
final class TextSearchMatch {
  const TextSearchMatch({
    required this.startOffset,
    required this.endOffset,
    this.groups = const <String?>[],
  });

  final int startOffset;
  final int endOffset;
  final List<String?> groups;

  int get length => endOffset - startOffset;
}

/// Result of [findTextSearchMatches].
final class TextSearchResult {
  const TextSearchResult({required this.matches, this.error});

  final List<TextSearchMatch> matches;

  /// Non-null when the pattern is empty or the regex failed to compile.
  final String? error;

  bool get isEmpty => matches.isEmpty;
}

/// Finds [query] in [document].
///
/// Never throws: an empty pattern or an invalid regex yields
/// [TextSearchResult.error] with no matches (invalid patterns are routine
/// while typing).
TextSearchResult findTextSearchMatches(
  TextDocument document,
  TextSearchQuery query,
) {
  if (query.pattern.isEmpty) {
    return const TextSearchResult(
      matches: [],
      error: 'Search pattern is empty.',
    );
  }
  final source = query.isRegex ? query.pattern : RegExp.escape(query.pattern);
  final RegExp expression;
  try {
    expression = RegExp(source, caseSensitive: query.caseSensitive);
  } on FormatException catch (error) {
    return TextSearchResult(matches: const [], error: error.message);
  }
  final graphemes = document.flattenWithNewlines();
  final text = graphemes.join();
  if (text.isEmpty) return const TextSearchResult(matches: []);
  final index = _GraphemeIndexTable(graphemes);
  final matches = <TextSearchMatch>[];
  for (final match in expression.allMatches(text)) {
    if (query.wholeWord && !_hasWordBoundaries(text, match)) continue;
    final start = index.graphemeForCodeUnit(match.start);
    final end = index.graphemeForCodeUnit(match.end, inclusiveEnd: true);
    if (end < start) continue;
    matches.add(
      TextSearchMatch(
        startOffset: start,
        endOffset: end,
        groups: List<String?>.generate(
          match.groupCount + 1,
          (group) {
            try {
              return match.group(group);
            } catch (_) {
              return null;
            }
          },
          growable: false,
        ),
      ),
    );
  }
  return TextSearchResult(
    matches: List<TextSearchMatch>.unmodifiable(matches),
  );
}

/// Expands `$&` (whole match) and `$1`–`$99` (groups) in [template].
/// Unknown references expand to `''`. `$$` is an escaped dollar.
String expandSearchReplacementTemplate(
  String template,
  TextSearchMatch match,
  String matchedText,
) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < template.length) {
    final char = template[i];
    if (char != r'$' || i + 1 >= template.length) {
      buffer.write(char);
      i++;
      continue;
    }
    final next = template[i + 1];
    if (next == r'$') {
      buffer.write(r'$');
      i += 2;
      continue;
    }
    if (next == '&') {
      buffer.write(matchedText);
      i += 2;
      continue;
    }
    var digits = '';
    var j = i + 1;
    while (j < template.length &&
        digits.length < 2 &&
        _isAsciiDigit(template.codeUnitAt(j))) {
      digits += template[j];
      j++;
    }
    if (digits.isEmpty) {
      buffer.write(char);
      i++;
      continue;
    }
    final group = int.parse(digits);
    final value = group < match.groups.length ? match.groups[group] : null;
    buffer.write(value ?? '');
    i = j;
  }
  return buffer.toString();
}

/// Replaces [matches] in [graphemes] (e.g. `document.flattenWithNewlines()`)
/// using [expand] for each match's replacement graphemes.
///
/// Applies descending so earlier offsets stay valid; overlapping matches
/// resolve by keeping the earliest-starting match and skipping the rest.
List<String> replaceTextSearchMatches(
  List<String> graphemes,
  List<TextSearchMatch> matches,
  List<String> Function(TextSearchMatch match) expand,
) {
  final ordered = matches.toList(growable: false)
    ..sort((a, b) => b.startOffset.compareTo(a.startOffset));
  final result = List<String>.from(graphemes);
  var floor = result.length + 1;
  for (final match in ordered) {
    final start = match.startOffset.clamp(0, result.length);
    final end = match.endOffset.clamp(start, result.length);
    if (end > floor) continue;
    result.replaceRange(start, end, expand(match));
    floor = start;
  }
  return result;
}

/// Stateful find-next/previous cursor over a match list.
final class TextSearchSession {
  TextSearchSession({required this.query, List<TextSearchMatch>? matches})
    : _matches = List<TextSearchMatch>.unmodifiable(matches ?? const []);

  TextSearchQuery query;
  List<TextSearchMatch> _matches;
  int _index = -1;

  List<TextSearchMatch> get matches => _matches;
  int get index => _index;
  TextSearchMatch? get current =>
      _index >= 0 && _index < _matches.length ? _matches[_index] : null;

  /// Replaces the match list (e.g. after a document change) and resets.
  void updateMatches(List<TextSearchMatch> matches) {
    _matches = List<TextSearchMatch>.unmodifiable(matches);
    _index = -1;
  }

  TextSearchMatch? next({bool wrap = true}) {
    if (_matches.isEmpty) return null;
    var next = _index + 1;
    if (next >= _matches.length) {
      if (!wrap) return null;
      next = 0;
    }
    _index = next;
    return _matches[_index];
  }

  TextSearchMatch? previous({bool wrap = true}) {
    if (_matches.isEmpty) return null;
    var previous = _index - 1;
    if (previous < 0) {
      if (!wrap) return null;
      previous = _matches.length - 1;
    }
    _index = previous;
    return _matches[_index];
  }
}

bool _isAsciiDigit(int unit) => unit >= 0x30 && unit <= 0x39;

bool _isWordUnit(int unit) {
  return (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0x41 && unit <= 0x5A) ||
      (unit >= 0x61 && unit <= 0x7A) ||
      unit == 0x5F;
}

bool _hasWordBoundaries(String text, RegExpMatch match) {
  if (match.start > 0 && _isWordUnit(text.codeUnitAt(match.start - 1))) {
    return false;
  }
  if (match.end < text.length && _isWordUnit(text.codeUnitAt(match.end))) {
    return false;
  }
  return true;
}

/// Maps UTF-16 code-unit offsets (RegExp space) to grapheme offsets
/// (document space).
final class _GraphemeIndexTable {
  _GraphemeIndexTable(List<String> graphemes) {
    var units = 0;
    for (final grapheme in graphemes) {
      units += grapheme.length;
    }
    _unitToGrapheme = List<int>.filled(units + 1, graphemes.length);
    var unit = 0;
    for (var g = 0; g < graphemes.length; g++) {
      final length = graphemes[g].length;
      for (var k = 0; k < length; k++) {
        _unitToGrapheme[unit++] = g;
      }
    }
    _unitToGrapheme[units] = graphemes.length;
    _graphemeCount = graphemes.length;
  }

  late final List<int> _unitToGrapheme;
  late final int _graphemeCount;

  int graphemeForCodeUnit(int unit, {bool inclusiveEnd = false}) {
    if (unit <= 0) return 0;
    if (unit >= _unitToGrapheme.length) return _graphemeCount;
    final grapheme = _unitToGrapheme[unit];
    // A match ending mid-grapheme still covers that grapheme.
    if (inclusiveEnd &&
        unit > 0 &&
        unit < _unitToGrapheme.length - 1 &&
        _unitToGrapheme[unit - 1] == grapheme) {
      return grapheme + 1;
    }
    return grapheme;
  }
}
