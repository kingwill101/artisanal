library;

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'text_change.dart';

final class TextDocument {
  TextDocument({String text = ''}) {
    _replaceLineTexts(_parseLineTexts(text));
  }

  TextDocument._raw();

  late List<String> _lineTexts;
  late List<int> _lineLengths;
  late List<int> _lineStartOffsets;
  late int _length;
  String? _cachedText;
  List<String>? _cachedFlattenedGraphemes;
  late List<List<String>?> _lineGraphemeCaches;
  List<List<String>>? _cachedLineViews;

  List<List<String>> get lines => lineViews
      .map((line) => List<String>.unmodifiable(line))
      .toList(growable: false);

  List<List<String>> get lineViews =>
      _cachedLineViews ??= List<List<String>>.unmodifiable(
        List<List<String>>.generate(
          _lineTexts.length,
          lineGraphemesAt,
          growable: false,
        ),
      );

  List<String> get lineTexts => _lineTexts;

  int get lineCount => _lineTexts.length;

  int get length => _length;

  String get text => _cachedText ??= _lineTexts.join('\n');

  String? graphemeAt(int offset) {
    if (offset < 0 || offset >= length) {
      return null;
    }
    final position = positionForOffset(offset);
    if (position.column == _lineLengths[position.line] &&
        position.line < _lineTexts.length - 1) {
      return '\n';
    }
    return lineGraphemesAt(position.line)[position.column];
  }

  TextDocument copy() {
    final next = TextDocument._raw();
    next._lineTexts = _lineTexts;
    next._lineLengths = _lineLengths;
    next._lineStartOffsets = _lineStartOffsets;
    next._length = _length;
    next._cachedText = _cachedText;
    next._cachedFlattenedGraphemes = _cachedFlattenedGraphemes;
    next._lineGraphemeCaches = _lineGraphemeCaches;
    next._cachedLineViews = _cachedLineViews;
    return next;
  }

  String lineAt(int index) {
    if (index < 0 || index >= _lineTexts.length) {
      return '';
    }
    return _lineTexts[index];
  }

  List<String> lineGraphemesAt(int index) {
    if (index < 0 || index >= _lineTexts.length) {
      return const <String>[];
    }
    return _lineGraphemeCaches[index] ??= List<String>.unmodifiable(
      _lineTexts[index].characters.toList(growable: false),
    );
  }

  int lineLength(int index) {
    if (index < 0 || index >= _lineLengths.length) {
      return 0;
    }
    return _lineLengths[index];
  }

  int lineStartOffset(int index) {
    if (index <= 0) {
      return 0;
    }
    if (index >= _lineStartOffsets.length) {
      return length;
    }
    return _lineStartOffsets[index];
  }

  int lineEndOffset(int index, {bool includeTrailingNewline = false}) {
    if (index < 0) {
      return 0;
    }
    if (index >= _lineLengths.length) {
      return length;
    }
    final end = _lineStartOffsets[index] + _lineLengths[index];
    if (includeTrailingNewline && index < _lineLengths.length - 1) {
      return end + 1;
    }
    return end;
  }

  TextPosition clampPosition(TextPosition position) {
    final line = position.line.clamp(0, _lineTexts.length - 1);
    final column = position.column.clamp(0, _lineLengths[line]);
    return TextPosition(line: line, column: column);
  }

  int offsetForPosition(TextPosition position) {
    final clamped = clampPosition(position);
    return _lineStartOffsets[clamped.line] + clamped.column;
  }

  TextPosition positionForOffset(int offset) {
    final clamped = offset.clamp(0, length);
    var low = 0;
    var high = _lineTexts.length - 1;
    while (low < high) {
      final mid = (low + high) >> 1;
      final lineEnd = _lineStartOffsets[mid] + _lineLengths[mid];
      if (clamped <= lineEnd) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    final line = low;
    return TextPosition(line: line, column: clamped - _lineStartOffsets[line]);
  }

  List<String> flattenWithNewlines() {
    final flattened = _cachedFlattenedGraphemes ??= () {
      final result = <String>[];
      for (var index = 0; index < _lineTexts.length; index++) {
        result.addAll(lineGraphemesAt(index));
        if (index < _lineTexts.length - 1) {
          result.add('\n');
        }
      }
      return List<String>.unmodifiable(result);
    }();
    return List<String>.from(flattened, growable: true);
  }

  List<String> graphemesInRange({
    required int startOffset,
    required int endOffset,
  }) {
    final normalizedStart = startOffset.clamp(0, length);
    final normalizedEnd = endOffset.clamp(normalizedStart, length);
    if (normalizedStart == normalizedEnd) {
      return const <String>[];
    }

    final result = <String>[];
    var remaining = normalizedEnd - normalizedStart;
    final start = positionForOffset(normalizedStart);
    var line = start.line;
    var column = start.column;

    while (remaining > 0 && line < _lineTexts.length) {
      final lineLength = _lineLengths[line];
      final takeCount = (lineLength - column).clamp(0, remaining);
      if (takeCount > 0) {
        result.addAll(
          lineGraphemesAt(line).sublist(column, column + takeCount),
        );
        remaining -= takeCount;
        column += takeCount;
      }

      if (remaining > 0 &&
          column == lineLength &&
          line < _lineTexts.length - 1) {
        result.add('\n');
        remaining -= 1;
        line += 1;
        column = 0;
      }
    }

    return result;
  }

  bool matchesOffsetRange({
    required int startOffset,
    required List<String> graphemes,
  }) {
    if (graphemes.isEmpty) {
      return true;
    }

    final start = startOffset.clamp(0, length);
    if (start + graphemes.length > length) {
      return false;
    }

    for (var index = 0; index < graphemes.length; index++) {
      if (graphemeAt(start + index) != graphemes[index]) {
        return false;
      }
    }
    return true;
  }

  ({TextPosition start, TextPosition end}) wordBoundaryAt(
    TextPosition position,
  ) {
    final clamped = clampPosition(position);
    final line = lineGraphemesAt(clamped.line);
    if (line.isEmpty) {
      return (
        start: TextPosition(line: clamped.line, column: 0),
        end: TextPosition(line: clamped.line, column: 0),
      );
    }

    final column = clamped.column.clamp(0, line.length - 1);
    if (_isWhitespace(line[column])) {
      var start = column;
      while (start > 0 && _isWhitespace(line[start - 1])) {
        start--;
      }
      var end = column;
      while (end < line.length && _isWhitespace(line[end])) {
        end++;
      }
      return (
        start: TextPosition(line: clamped.line, column: start),
        end: TextPosition(line: clamped.line, column: end),
      );
    }

    var start = column;
    while (start > 0 && !_isWhitespace(line[start - 1])) {
      start--;
    }
    var end = column;
    while (end < line.length && !_isWhitespace(line[end])) {
      end++;
    }
    return (
      start: TextPosition(line: clamped.line, column: start),
      end: TextPosition(line: clamped.line, column: end),
    );
  }

  void replaceText(String text) {
    _replaceLineTexts(_parseLineTexts(text));
  }

  TextDocumentChange replaceTextRange({
    required int startOffset,
    required int endOffset,
    String replacement = '',
  }) {
    return replaceOffsetRange(
      startOffset: startOffset,
      endOffset: endOffset,
      replacement: replacement.characters.toList(growable: false),
    );
  }

  TextDocumentChange replaceOffsetRange({
    required int startOffset,
    required int endOffset,
    List<String> replacement = const <String>[],
  }) {
    final normalizedStart = startOffset.clamp(0, length);
    final normalizedEnd = endOffset.clamp(normalizedStart, length);
    final startPosition = positionForOffset(normalizedStart);
    final oldEndPosition = positionForOffset(normalizedEnd);

    final replacementLines = _parseFlatGraphemes(replacement);
    final prefix = List<String>.from(
      lineGraphemesAt(startPosition.line).take(startPosition.column),
      growable: true,
    );
    final suffix = List<String>.from(
      lineGraphemesAt(oldEndPosition.line).skip(oldEndPosition.column),
      growable: true,
    );

    final mergedLines = replacementLines
        .map((line) => List<String>.from(line, growable: true))
        .toList(growable: true);
    mergedLines.first.insertAll(0, prefix);
    mergedLines.last.addAll(suffix);

    final nextLineTexts = <String>[
      ..._lineTexts.take(startPosition.line),
      ...mergedLines.map((line) => line.join()),
      ..._lineTexts.skip(oldEndPosition.line + 1),
    ];
    final nextLineLengths = <int>[
      ..._lineLengths.take(startPosition.line),
      ...mergedLines.map((line) => line.length),
      ..._lineLengths.skip(oldEndPosition.line + 1),
    ];
    final nextLineGraphemeCaches = <List<String>?>[
      ..._lineGraphemeCaches.take(startPosition.line),
      ...mergedLines.map(
        (line) => List<String>.unmodifiable(List<String>.from(line)),
      ),
      ..._lineGraphemeCaches.skip(oldEndPosition.line + 1),
    ];
    final offsetDelta = replacement.length - (normalizedEnd - normalizedStart);
    final nextLineStartOffsets = <int>[
      ..._lineStartOffsets.take(startPosition.line),
    ];
    var nextOffset = _lineStartOffsets[startPosition.line];
    for (var index = 0; index < mergedLines.length; index++) {
      nextLineStartOffsets.add(nextOffset);
      nextOffset += nextLineLengths[startPosition.line + index];
      if (index < mergedLines.length - 1) {
        nextOffset += 1;
      }
    }
    nextLineStartOffsets.addAll(
      _lineStartOffsets
          .skip(oldEndPosition.line + 1)
          .map((offset) => offset + offsetDelta),
    );
    _replaceState(
      lineTexts: nextLineTexts,
      lineLengths: nextLineLengths,
      lineStartOffsets: nextLineStartOffsets,
      length: _length + offsetDelta,
      lineGraphemeCaches: nextLineGraphemeCaches,
    );

    final newEndOffset = normalizedStart + replacement.length;
    return TextDocumentChange(
      startOffset: normalizedStart,
      oldEndOffset: normalizedEnd,
      newEndOffset: newEndOffset,
      startPosition: startPosition,
      oldEndPosition: oldEndPosition,
      newEndPosition: positionForOffset(newEndOffset),
    );
  }

  void replaceLines(List<List<String>> lines) {
    _replaceParsedLines(
      lines.isEmpty
          ? <List<String>>[<String>[]]
          : lines
                .map((line) => List<String>.from(line))
                .toList(growable: false),
    );
  }

  static List<List<String>> parseLines(String text) => _parseLines(text);

  static List<List<String>> parseLineTexts(Iterable<String> lines) {
    final parsed = lines
        .map((line) => line.characters.toList(growable: true))
        .toList(growable: true);
    if (parsed.isEmpty) {
      return <List<String>>[<String>[]];
    }
    return parsed;
  }

  static List<List<String>> parseFlatGraphemes(Iterable<String> graphemes) =>
      _parseFlatGraphemes(graphemes);

  static List<String> _parseLineTexts(String text) {
    if (text.isEmpty) {
      return const <String>[''];
    }
    return text.split('\n').toList(growable: false);
  }

  static List<List<String>> _parseLines(String text) {
    return _parseLineTexts(text)
        .map((line) => line.characters.toList(growable: true))
        .toList(growable: true);
  }

  static List<List<String>> _parseFlatGraphemes(Iterable<String> graphemes) {
    final lines = <List<String>>[<String>[]];
    for (final grapheme in graphemes) {
      if (grapheme == '\n') {
        lines.add(<String>[]);
        continue;
      }
      lines.last.add(grapheme);
    }
    return lines;
  }

  void _replaceLineTexts(List<String> lineTexts) {
    final lineLengths = lineTexts
        .map((line) => line.characters.length)
        .toList(growable: false);
    final lineStartOffsets = List<int>.filled(
      lineTexts.length,
      0,
      growable: false,
    );
    var offset = 0;
    for (var index = 0; index < lineTexts.length; index++) {
      lineStartOffsets[index] = offset;
      offset += lineLengths[index];
      if (index < lineTexts.length - 1) {
        offset += 1;
      }
    }
    _replaceState(
      lineTexts: lineTexts,
      lineLengths: lineLengths,
      lineStartOffsets: lineStartOffsets,
      length: offset,
    );
  }

  void _replaceParsedLines(List<List<String>> lines) {
    _replaceState(
      lineTexts: List<String>.unmodifiable(lines.map((line) => line.join())),
      lineLengths: List<int>.unmodifiable(lines.map((line) => line.length)),
      lineStartOffsets: _computeLineStartOffsetsFromLengths(
        lines.map((line) => line.length).toList(growable: false),
      ),
      length:
          lines.fold<int>(0, (total, line) => total + line.length) +
          (lines.length > 1 ? lines.length - 1 : 0),
      lineGraphemeCaches: List<List<String>?>.unmodifiable(
        lines.map((line) => List<String>.unmodifiable(List<String>.from(line))),
      ),
    );
  }

  List<int> _computeLineStartOffsetsFromLengths(List<int> lineLengths) {
    final lineStartOffsets = List<int>.filled(
      lineLengths.length,
      0,
      growable: false,
    );
    var offset = 0;
    for (var index = 0; index < lineLengths.length; index++) {
      lineStartOffsets[index] = offset;
      offset += lineLengths[index];
      if (index < lineLengths.length - 1) {
        offset += 1;
      }
    }
    return lineStartOffsets;
  }

  void _replaceState({
    required List<String> lineTexts,
    required List<int> lineLengths,
    required List<int> lineStartOffsets,
    required int length,
    List<List<String>?>? lineGraphemeCaches,
  }) {
    _lineTexts = List<String>.unmodifiable(lineTexts);
    _lineLengths = List<int>.unmodifiable(lineLengths);
    _lineStartOffsets = List<int>.unmodifiable(lineStartOffsets);
    _lineGraphemeCaches = lineGraphemeCaches == null
        ? List<List<String>?>.filled(lineTexts.length, null, growable: false)
        : List<List<String>?>.from(lineGraphemeCaches, growable: false);
    _length = length;
    _cachedText = null;
    _cachedFlattenedGraphemes = null;
    _cachedLineViews = null;
  }

  bool _isWhitespace(String grapheme) {
    return grapheme == ' ' ||
        grapheme == '\t' ||
        grapheme == '\n' ||
        grapheme == '\r';
  }
}
