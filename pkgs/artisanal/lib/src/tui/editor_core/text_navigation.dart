library;

typedef GraphemePredicate = bool Function(String grapheme);
typedef GraphemeReader = String? Function(int offset);

int moveWordBackward(
  List<String> graphemes,
  int offset, {
  required GraphemePredicate isWord,
}) {
  if (offset <= 0 || graphemes.isEmpty) {
    return 0;
  }

  var position = offset - 1;
  while (position > 0 && !isWord(graphemes[position])) {
    position--;
  }
  while (position > 0 && isWord(graphemes[position - 1])) {
    position--;
  }
  return position.clamp(0, graphemes.length);
}

int moveWordForward(
  List<String> graphemes,
  int offset, {
  required GraphemePredicate isWord,
}) {
  if (offset >= graphemes.length || graphemes.isEmpty) {
    return graphemes.length;
  }

  var position = offset + 1;
  while (position < graphemes.length && !isWord(graphemes[position])) {
    position++;
  }
  while (position < graphemes.length && isWord(graphemes[position])) {
    position++;
  }
  return position.clamp(0, graphemes.length);
}

({int start, int end})? nextWordRange(
  List<String> graphemes,
  int offset, {
  required GraphemePredicate isWord,
}) {
  if (graphemes.isEmpty) {
    return null;
  }

  var position = offset.clamp(0, graphemes.length);
  while (position < graphemes.length && !isWord(graphemes[position])) {
    position++;
  }
  if (position >= graphemes.length) {
    return null;
  }

  var end = position;
  while (end < graphemes.length && isWord(graphemes[end])) {
    end++;
  }
  return (start: position, end: end);
}

({int start, int end})? previousWordRange(
  List<String> graphemes,
  int offset, {
  required GraphemePredicate isWord,
}) {
  if (offset <= 0 || graphemes.isEmpty) {
    return null;
  }

  var position = offset.clamp(0, graphemes.length) - 1;
  while (position >= 0 && !isWord(graphemes[position])) {
    position--;
  }
  if (position < 0) {
    return null;
  }

  final end = position + 1;
  while (position >= 0 && isWord(graphemes[position])) {
    position--;
  }
  return (start: position + 1, end: end);
}

({int start, int end})? wordRangeForTransform(
  List<String> graphemes,
  int offset, {
  required GraphemePredicate isWord,
}) {
  return nextWordRange(graphemes, offset, isWord: isWord) ??
      previousWordRange(graphemes, offset, isWord: isWord);
}

({int start, int end})? nextWordRangeFromReader(
  int length,
  int offset, {
  required GraphemePredicate isWord,
  required GraphemeReader graphemeAt,
}) {
  if (length <= 0) {
    return null;
  }

  var position = offset.clamp(0, length);
  while (position < length) {
    final grapheme = graphemeAt(position);
    if (grapheme != null && isWord(grapheme)) {
      break;
    }
    position++;
  }
  if (position >= length) {
    return null;
  }

  var end = position;
  while (end < length) {
    final grapheme = graphemeAt(end);
    if (grapheme == null || !isWord(grapheme)) {
      break;
    }
    end++;
  }
  return (start: position, end: end);
}

({int start, int end})? previousWordRangeFromReader(
  int length,
  int offset, {
  required GraphemePredicate isWord,
  required GraphemeReader graphemeAt,
}) {
  if (offset <= 0 || length <= 0) {
    return null;
  }

  var position = offset.clamp(0, length) - 1;
  while (position >= 0) {
    final grapheme = graphemeAt(position);
    if (grapheme != null && isWord(grapheme)) {
      break;
    }
    position--;
  }
  if (position < 0) {
    return null;
  }

  final end = position + 1;
  while (position >= 0) {
    final grapheme = graphemeAt(position);
    if (grapheme == null || !isWord(grapheme)) {
      break;
    }
    position--;
  }
  return (start: position + 1, end: end);
}

({int start, int end})? wordRangeForTransformFromReader(
  int length,
  int offset, {
  required GraphemePredicate isWord,
  required GraphemeReader graphemeAt,
}) {
  return nextWordRangeFromReader(
        length,
        offset,
        isWord: isWord,
        graphemeAt: graphemeAt,
      ) ??
      previousWordRangeFromReader(
        length,
        offset,
        isWord: isWord,
        graphemeAt: graphemeAt,
      );
}

({int start, int end}) deleteWordBackwardRange(
  List<String> graphemes,
  int offset, {
  required GraphemePredicate isWord,
}) {
  final start = moveWordBackward(graphemes, offset, isWord: isWord);
  return (start: start, end: offset.clamp(0, graphemes.length));
}

({int start, int end}) deleteWordForwardRange(
  List<String> graphemes,
  int offset, {
  required GraphemePredicate isWord,
}) {
  if (offset < 0 || offset >= graphemes.length) {
    final clamped = offset.clamp(0, graphemes.length);
    return (start: clamped, end: clamped);
  }

  var end = offset;
  if (isWord(graphemes[offset])) {
    while (end < graphemes.length && isWord(graphemes[end])) {
      end++;
    }
  } else {
    while (end < graphemes.length && !isWord(graphemes[end])) {
      end++;
    }
    while (end < graphemes.length && isWord(graphemes[end])) {
      end++;
    }
  }

  return (start: offset, end: end.clamp(0, graphemes.length));
}
