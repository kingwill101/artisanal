library;

import 'text_change.dart';
import 'text_document.dart';

final class TextEditResult {
  const TextEditResult({required this.graphemes, required this.cursorOffset});

  final List<String> graphemes;
  final int cursorOffset;
}

final class TextDocumentEditResult {
  const TextDocumentEditResult({
    required this.change,
    required this.cursorOffset,
  });

  final TextDocumentChange change;
  final int cursorOffset;

  bool get changed => !change.isNoop;
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

TextDocumentEditResult replaceDocumentRange(
  TextDocument document, {
  required int start,
  required int end,
  List<String> replacement = const <String>[],
  int? cursorOffset,
}) {
  final change = document.replaceOffsetRange(
    startOffset: start,
    endOffset: end,
    replacement: replacement,
  );
  return TextDocumentEditResult(
    change: change,
    cursorOffset: (cursorOffset ?? change.newEndOffset).clamp(0, document.length),
  );
}

TextDocumentEditResult insertIntoDocument(
  TextDocument document,
  int cursorOffset,
  List<String> inserted,
) {
  return replaceDocumentRange(
    document,
    start: cursorOffset,
    end: cursorOffset,
    replacement: inserted,
  );
}

TextDocumentEditResult removeDocumentRange(
  TextDocument document, {
  required int start,
  required int end,
  int? cursorOffset,
}) {
  return replaceDocumentRange(
    document,
    start: start,
    end: end,
    cursorOffset: cursorOffset ?? start,
  );
}

TextDocumentEditResult deletePreviousDocumentGrapheme(
  TextDocument document,
  int cursorOffset,
) {
  if (cursorOffset <= 0) {
    return TextDocumentEditResult(
      change: TextDocumentChange(
        startOffset: 0,
        oldEndOffset: 0,
        newEndOffset: 0,
        startPosition: document.positionForOffset(0),
        oldEndPosition: document.positionForOffset(0),
        newEndPosition: document.positionForOffset(0),
      ),
      cursorOffset: 0,
    );
  }
  return removeDocumentRange(
    document,
    start: cursorOffset - 1,
    end: cursorOffset,
    cursorOffset: cursorOffset - 1,
  );
}

TextDocumentEditResult deleteNextDocumentGrapheme(
  TextDocument document,
  int cursorOffset,
) {
  if (cursorOffset >= document.length) {
    return TextDocumentEditResult(
      change: TextDocumentChange(
        startOffset: document.length,
        oldEndOffset: document.length,
        newEndOffset: document.length,
        startPosition: document.positionForOffset(document.length),
        oldEndPosition: document.positionForOffset(document.length),
        newEndPosition: document.positionForOffset(document.length),
      ),
      cursorOffset: document.length,
    );
  }
  return removeDocumentRange(
    document,
    start: cursorOffset,
    end: cursorOffset + 1,
    cursorOffset: cursorOffset,
  );
}
