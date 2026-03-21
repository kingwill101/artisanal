library;

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'text_document.dart';

final class TextDocumentChange {
  const TextDocumentChange({
    required this.startOffset,
    required this.oldEndOffset,
    required this.newEndOffset,
    required this.startPosition,
    required this.oldEndPosition,
    required this.newEndPosition,
  });

  final int startOffset;
  final int oldEndOffset;
  final int newEndOffset;
  final TextPosition startPosition;
  final TextPosition oldEndPosition;
  final TextPosition newEndPosition;

  int get deletedLength => oldEndOffset - startOffset;
  int get insertedLength => newEndOffset - startOffset;
  bool get isNoop => deletedLength == 0 && insertedLength == 0;
}

TextDocumentChange computeTextDocumentChange(String previousText, String nextText) {
  final previous = previousText.characters.toList(growable: false);
  final next = nextText.characters.toList(growable: false);

  var prefix = 0;
  final maxPrefix = previous.length < next.length ? previous.length : next.length;
  while (prefix < maxPrefix && previous[prefix] == next[prefix]) {
    prefix += 1;
  }

  var previousSuffix = previous.length;
  var nextSuffix = next.length;
  while (previousSuffix > prefix &&
      nextSuffix > prefix &&
      previous[previousSuffix - 1] == next[nextSuffix - 1]) {
    previousSuffix -= 1;
    nextSuffix -= 1;
  }

  final previousDocument = TextDocument(text: previousText);
  final nextDocument = TextDocument(text: nextText);
  return TextDocumentChange(
    startOffset: prefix,
    oldEndOffset: previousSuffix,
    newEndOffset: nextSuffix,
    startPosition: previousDocument.positionForOffset(prefix),
    oldEndPosition: previousDocument.positionForOffset(previousSuffix),
    newEndPosition: nextDocument.positionForOffset(nextSuffix),
  );
}
