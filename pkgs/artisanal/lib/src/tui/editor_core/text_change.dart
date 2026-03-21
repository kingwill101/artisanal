library;

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

TextDocumentChange computeTextDocumentChange(
  String previousText,
  String nextText,
) {
  final previousDocument = TextDocument(text: previousText);
  final nextDocument = TextDocument(text: nextText);
  return computeTextDocumentChangeForDocuments(
    previousDocument: previousDocument,
    nextDocument: nextDocument,
  );
}

TextDocumentChange computeTextDocumentChangeForDocuments({
  required TextDocument previousDocument,
  required TextDocument nextDocument,
}) {
  var prefix = 0;
  final maxPrefix = previousDocument.length < nextDocument.length
      ? previousDocument.length
      : nextDocument.length;
  while (prefix < maxPrefix &&
      previousDocument.graphemeAt(prefix) == nextDocument.graphemeAt(prefix)) {
    prefix += 1;
  }

  var previousSuffix = previousDocument.length;
  var nextSuffix = nextDocument.length;
  while (previousSuffix > prefix &&
      nextSuffix > prefix &&
      previousDocument.graphemeAt(previousSuffix - 1) ==
          nextDocument.graphemeAt(nextSuffix - 1)) {
    previousSuffix -= 1;
    nextSuffix -= 1;
  }

  return TextDocumentChange(
    startOffset: prefix,
    oldEndOffset: previousSuffix,
    newEndOffset: nextSuffix,
    startPosition: previousDocument.positionForOffset(prefix),
    oldEndPosition: previousDocument.positionForOffset(previousSuffix),
    newEndPosition: nextDocument.positionForOffset(nextSuffix),
  );
}
