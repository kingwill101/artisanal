library;

import 'package:characters/characters.dart';

import 'text_document.dart';

final class TextHighlightRange {
  const TextHighlightRange({
    required this.startOffset,
    required this.endOffset,
  });

  final int startOffset;
  final int endOffset;

  int get length => endOffset - startOffset;
  bool get isEmpty => startOffset >= endOffset;

  TextHighlightRange normalized() {
    if (startOffset <= endOffset) {
      return this;
    }
    return TextHighlightRange(startOffset: endOffset, endOffset: startOffset);
  }

  TextHighlightRange clamp(int maxLength) {
    final normalizedRange = normalized();
    return TextHighlightRange(
      startOffset: normalizedRange.startOffset.clamp(0, maxLength),
      endOffset: normalizedRange.endOffset.clamp(0, maxLength),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TextHighlightRange &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset;
  }

  @override
  int get hashCode => Object.hash(startOffset, endOffset);

  @override
  String toString() {
    return 'TextHighlightRange($startOffset, $endOffset)';
  }
}

List<TextHighlightRange> findTextQueryHighlights({
  required TextDocument document,
  required String query,
  bool caseSensitive = false,
}) {
  final needle = query.characters.toList(growable: false);
  if (needle.isEmpty) {
    return const [];
  }

  final normalizedNeedle = needle
      .map((token) => _normalizeHighlightToken(token, caseSensitive))
      .toList(growable: false);
  final ranges = <TextHighlightRange>[];
  var lineOffset = 0;

  for (var lineIndex = 0; lineIndex < document.lineCount; lineIndex++) {
    final line = document.lines[lineIndex];
    final normalizedLine = line
        .map((token) => _normalizeHighlightToken(token, caseSensitive))
        .toList(growable: false);

    var cursor = 0;
    while (cursor <= normalizedLine.length - normalizedNeedle.length) {
      var matched = true;
      for (var index = 0; index < normalizedNeedle.length; index++) {
        if (normalizedLine[cursor + index] != normalizedNeedle[index]) {
          matched = false;
          break;
        }
      }

      if (!matched) {
        cursor++;
        continue;
      }

      ranges.add(
        TextHighlightRange(
          startOffset: lineOffset + cursor,
          endOffset: lineOffset + cursor + normalizedNeedle.length,
        ),
      );
      cursor += normalizedNeedle.length;
    }

    lineOffset += line.length;
    if (lineIndex < document.lineCount - 1) {
      lineOffset += 1;
    }
  }

  return List<TextHighlightRange>.unmodifiable(ranges);
}

String _normalizeHighlightToken(String token, bool caseSensitive) {
  if (caseSensitive) {
    return token;
  }
  return token.toLowerCase();
}
