library;

final class TextEditResult {
  const TextEditResult({required this.graphemes, required this.cursorOffset});

  final List<String> graphemes;
  final int cursorOffset;
}

TextEditResult replaceRange(
  List<String> graphemes, {
  required int start,
  required int end,
  List<String> replacement = const <String>[],
  int? cursorOffset,
}) {
  final normalizedStart = start.clamp(0, graphemes.length);
  final normalizedEnd = end.clamp(normalizedStart, graphemes.length);
  final next = List<String>.from(graphemes, growable: true)
    ..replaceRange(normalizedStart, normalizedEnd, replacement);

  return TextEditResult(
    graphemes: next,
    cursorOffset: (cursorOffset ?? (normalizedStart + replacement.length))
        .clamp(0, next.length),
  );
}

TextEditResult insertAtCursor(
  List<String> graphemes,
  int cursorOffset,
  List<String> inserted,
) {
  return replaceRange(
    graphemes,
    start: cursorOffset,
    end: cursorOffset,
    replacement: inserted,
  );
}

TextEditResult removeRange(
  List<String> graphemes, {
  required int start,
  required int end,
  int? cursorOffset,
}) {
  return replaceRange(
    graphemes,
    start: start,
    end: end,
    cursorOffset: cursorOffset ?? start,
  );
}

TextEditResult deleteBeforeCursor(List<String> graphemes, int cursorOffset) {
  return removeRange(graphemes, start: 0, end: cursorOffset, cursorOffset: 0);
}

TextEditResult deleteAfterCursor(List<String> graphemes, int cursorOffset) {
  return removeRange(
    graphemes,
    start: cursorOffset,
    end: graphemes.length,
    cursorOffset: graphemes.length,
  );
}

TextEditResult deletePreviousGrapheme(
  List<String> graphemes,
  int cursorOffset,
) {
  if (cursorOffset <= 0) {
    return TextEditResult(
      graphemes: List<String>.from(graphemes),
      cursorOffset: 0,
    );
  }
  return removeRange(
    graphemes,
    start: cursorOffset - 1,
    end: cursorOffset,
    cursorOffset: cursorOffset - 1,
  );
}

TextEditResult deleteNextGrapheme(List<String> graphemes, int cursorOffset) {
  if (cursorOffset >= graphemes.length) {
    return TextEditResult(
      graphemes: List<String>.from(graphemes),
      cursorOffset: graphemes.length,
    );
  }
  return removeRange(
    graphemes,
    start: cursorOffset,
    end: cursorOffset + 1,
    cursorOffset: cursorOffset,
  );
}
