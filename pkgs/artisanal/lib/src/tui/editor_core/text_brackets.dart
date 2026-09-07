library;

import 'text_document.dart';

/// Structural bracket matching over a [TextDocument].
///
/// Finds the partner of `()`, `[]`, or `{}` under (or just before) the
/// cursor with per-type depth counting. Symmetric delimiters (quotes) are
/// deliberately excluded: they are ambiguous without token context. String
/// and comment awareness is the caller's job — filter candidates through a
/// syntax tree (`syntax_tree.dart`) when the language needs it.

/// Opening brackets understood by the matcher.
const bracketOpenings = <String, String>{'(': ')', '[': ']', '{': '}'};

/// Closing brackets understood by the matcher.
const bracketClosings = <String, String>{')': '(', ']': '[', '}': '{'};

/// Returns the offset of the bracket matching the one at [offset].
///
/// The grapheme at [offset] is tried first, then the grapheme just before
/// it (so `%` works with the cursor resting after a bracket too). Returns
/// `null` when neither is a bracket or the partner cannot be found.
int? findMatchingBracket(TextDocument document, int offset) {
  final clamped = offset.clamp(0, document.length);
  final atCursor = document.graphemeAt(clamped);
  final direct = atCursor == null
      ? null
      : _matchFrom(document, clamped, atCursor);
  if (direct != null) return direct;
  if (clamped <= 0) return null;
  final before = document.graphemeAt(clamped - 1);
  if (before == null) return null;
  return _matchFrom(document, clamped - 1, before);
}

/// Returns the range covering a bracket pair and everything between the
/// brackets (end exclusive, one past the closing bracket), or `null` when
/// no pair is found at [offset].
({int startOffset, int endOffset})? bracketPairRange(
  TextDocument document,
  int offset,
) {
  final clamped = offset.clamp(0, document.length);
  for (final candidate in [clamped, if (clamped > 0) clamped - 1]) {
    final grapheme = document.graphemeAt(candidate);
    if (grapheme == null) continue;
    final partner = _matchFrom(document, candidate, grapheme);
    if (partner == null) continue;
    if (bracketOpenings.containsKey(grapheme)) {
      return (startOffset: candidate, endOffset: partner + 1);
    }
    return (startOffset: partner, endOffset: candidate + 1);
  }
  return null;
}

int? _matchFrom(TextDocument document, int offset, String grapheme) {
  final closing = bracketOpenings[grapheme];
  if (closing != null) {
    var depth = 0;
    for (var i = offset; i < document.length; i++) {
      final current = document.graphemeAt(i);
      if (current == grapheme) {
        depth++;
      } else if (current == closing) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }
  final opening = bracketClosings[grapheme];
  if (opening == null) return null;
  var depth = 0;
  for (var i = offset; i >= 0; i--) {
    final current = document.graphemeAt(i);
    if (current == grapheme) {
      depth++;
    } else if (current == opening) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return null;
}
