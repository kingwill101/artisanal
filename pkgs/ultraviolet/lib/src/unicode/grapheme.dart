import 'package:characters/characters.dart';

/// Returns a lazy grapheme-cluster iterable.
Iterable<String> graphemes(String s) => s.characters;

/// Decodes a Dart String (UTF-16) into Unicode scalar values (code points).
///
List<int> codePoints(String s) => s.runes.toList(growable: false);

/// Reads the grapheme cluster starting at [index] and returns it along with the
/// next UTF-16 code-unit index.
///
/// This is useful when scanning strings with embedded ANSI escape sequences
/// (where we still need index-based parsing for the ASCII control bytes).
({String grapheme, int nextIndex}) readGraphemeAt(String s, int index) {
  if (index < 0) index = 0;
  if (index >= s.length) return (grapheme: '', nextIndex: s.length);

  final r = CharacterRange.at(s, index);
  if (!r.moveNext()) return (grapheme: '', nextIndex: s.length);

  final g = r.current;
  final start = r.stringBeforeLength;
  return (grapheme: g, nextIndex: start + g.length);
}

int firstCodePoint(String s) {
  final cps = codePoints(s);
  return cps.isEmpty ? 0 : cps.first;
}

bool isSingleCodePoint(String s) => codePoints(s).length == 1;
