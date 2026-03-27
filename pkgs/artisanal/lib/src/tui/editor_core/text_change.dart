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
  if (identical(previousDocument, nextDocument) ||
      (previousDocument.storageIdentity == nextDocument.storageIdentity &&
          previousDocument.revision == nextDocument.revision)) {
    return TextDocumentChange(
      startOffset: previousDocument.length,
      oldEndOffset: previousDocument.length,
      newEndOffset: nextDocument.length,
      startPosition: previousDocument.positionForOffset(
        previousDocument.length,
      ),
      oldEndPosition: previousDocument.positionForOffset(
        previousDocument.length,
      ),
      newEndPosition: nextDocument.positionForOffset(nextDocument.length),
    );
  }

  var prefixLineCount = 0;
  final maxSharedPrefixLines =
      previousDocument.lineCount < nextDocument.lineCount
      ? previousDocument.lineCount
      : nextDocument.lineCount;
  while (prefixLineCount < maxSharedPrefixLines &&
      previousDocument.lineAt(prefixLineCount) ==
          nextDocument.lineAt(prefixLineCount)) {
    prefixLineCount += 1;
  }

  if (prefixLineCount == previousDocument.lineCount &&
      prefixLineCount == nextDocument.lineCount) {
    return TextDocumentChange(
      startOffset: previousDocument.length,
      oldEndOffset: previousDocument.length,
      newEndOffset: nextDocument.length,
      startPosition: previousDocument.positionForOffset(
        previousDocument.length,
      ),
      oldEndPosition: previousDocument.positionForOffset(
        previousDocument.length,
      ),
      newEndPosition: nextDocument.positionForOffset(nextDocument.length),
    );
  }

  var suffixLineCount = 0;
  while (previousDocument.lineCount - suffixLineCount - 1 >= prefixLineCount &&
      nextDocument.lineCount - suffixLineCount - 1 >= prefixLineCount &&
      previousDocument.lineAt(
            previousDocument.lineCount - suffixLineCount - 1,
          ) ==
          nextDocument.lineAt(nextDocument.lineCount - suffixLineCount - 1)) {
    suffixLineCount += 1;
  }

  final sharedPrefixEndsAtDocumentBoundary =
      prefixLineCount > 0 &&
      previousDocument.lineCount != nextDocument.lineCount &&
      (prefixLineCount == previousDocument.lineCount ||
          prefixLineCount == nextDocument.lineCount);
  final previousWindowStartOffset = sharedPrefixEndsAtDocumentBoundary
      ? previousDocument.lineEndOffset(prefixLineCount - 1)
      : prefixLineCount < previousDocument.lineCount
      ? previousDocument.lineStartOffset(prefixLineCount)
      : previousDocument.length;
  final nextWindowStartOffset = sharedPrefixEndsAtDocumentBoundary
      ? nextDocument.lineEndOffset(prefixLineCount - 1)
      : prefixLineCount < nextDocument.lineCount
      ? nextDocument.lineStartOffset(prefixLineCount)
      : nextDocument.length;
  final previousWindowEndLine = previousDocument.lineCount - suffixLineCount;
  final nextWindowEndLine = nextDocument.lineCount - suffixLineCount;
  final previousWindowEndOffset =
      previousWindowEndLine < previousDocument.lineCount
      ? previousDocument.lineStartOffset(previousWindowEndLine)
      : previousDocument.length;
  final nextWindowEndOffset = nextWindowEndLine < nextDocument.lineCount
      ? nextDocument.lineStartOffset(nextWindowEndLine)
      : nextDocument.length;

  final previousWindow = previousDocument.graphemesInRange(
    startOffset: previousWindowStartOffset,
    endOffset: previousWindowEndOffset,
  );
  final nextWindow = nextDocument.graphemesInRange(
    startOffset: nextWindowStartOffset,
    endOffset: nextWindowEndOffset,
  );

  var prefix = 0;
  final maxPrefix = previousWindow.length < nextWindow.length
      ? previousWindow.length
      : nextWindow.length;
  while (prefix < maxPrefix && previousWindow[prefix] == nextWindow[prefix]) {
    prefix += 1;
  }

  var previousSuffix = previousWindow.length;
  var nextSuffix = nextWindow.length;
  while (previousSuffix > prefix &&
      nextSuffix > prefix &&
      previousWindow[previousSuffix - 1] == nextWindow[nextSuffix - 1]) {
    previousSuffix -= 1;
    nextSuffix -= 1;
  }

  final startOffset = previousWindowStartOffset + prefix;
  final oldEndOffset = previousWindowStartOffset + previousSuffix;
  final newEndOffset = nextWindowStartOffset + nextSuffix;

  return TextDocumentChange(
    startOffset: startOffset,
    oldEndOffset: oldEndOffset,
    newEndOffset: newEndOffset,
    startPosition: previousDocument.positionForOffset(startOffset),
    oldEndPosition: previousDocument.positionForOffset(oldEndOffset),
    newEndPosition: nextDocument.positionForOffset(newEndOffset),
  );
}
