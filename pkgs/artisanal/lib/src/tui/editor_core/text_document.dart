library;

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'text_change.dart';

final class TextDocument {
  TextDocument({String text = ''}) {
    _replaceLines(_parseLines(text));
  }

  late List<List<String>> _lines;
  late List<int> _lineStartOffsets;
  late int _length;

  List<List<String>> get lines => _lines
      .map((line) => List<String>.unmodifiable(line))
      .toList(growable: false);

  int get lineCount => _lines.length;

  int get length => _length;

  String get text => _lines.map((line) => line.join()).join('\n');

  String lineAt(int index) {
    if (index < 0 || index >= _lines.length) {
      return '';
    }
    return _lines[index].join();
  }

  int lineLength(int index) {
    if (index < 0 || index >= _lines.length) {
      return 0;
    }
    return _lines[index].length;
  }

  TextPosition clampPosition(TextPosition position) {
    final line = position.line.clamp(0, _lines.length - 1);
    final column = position.column.clamp(0, _lines[line].length);
    return TextPosition(line: line, column: column);
  }

  int offsetForPosition(TextPosition position) {
    final clamped = clampPosition(position);
    return _lineStartOffsets[clamped.line] + clamped.column;
  }

  TextPosition positionForOffset(int offset) {
    final clamped = offset.clamp(0, length);
    var low = 0;
    var high = _lines.length - 1;
    while (low < high) {
      final mid = (low + high) >> 1;
      final lineEnd = _lineStartOffsets[mid] + _lines[mid].length;
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
    final result = <String>[];
    for (var index = 0; index < _lines.length; index++) {
      result.addAll(_lines[index]);
      if (index < _lines.length - 1) {
        result.add('\n');
      }
    }
    return result;
  }

  ({TextPosition start, TextPosition end}) wordBoundaryAt(
    TextPosition position,
  ) {
    final clamped = clampPosition(position);
    final line = _lines[clamped.line];
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
    _replaceLines(_parseLines(text));
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
    final nextLines = _lines
        .map((line) => List<String>.from(line, growable: true))
        .toList(growable: true);
    final prefix = List<String>.from(
      nextLines[startPosition.line].take(startPosition.column),
      growable: true,
    );
    final suffix = List<String>.from(
      nextLines[oldEndPosition.line].skip(oldEndPosition.column),
      growable: true,
    );

    final mergedLines = replacementLines
        .map((line) => List<String>.from(line, growable: true))
        .toList(growable: true);
    mergedLines.first.insertAll(0, prefix);
    mergedLines.last.addAll(suffix);

    nextLines.replaceRange(
      startPosition.line,
      oldEndPosition.line + 1,
      mergedLines,
    );
    _replaceLines(nextLines);

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
    _replaceLines(
      lines.isEmpty
          ? <List<String>>[<String>[]]
          : lines
                .map((line) => List<String>.from(line))
                .toList(growable: false),
    );
  }

  static List<List<String>> parseLines(String text) => _parseLines(text);

  static List<List<String>> _parseLines(String text) {
    if (text.isEmpty) {
      return <List<String>>[<String>[]];
    }

    return text
        .split('\n')
        .map((line) => line.characters.toList(growable: true))
        .toList(growable: true);
  }

  static List<List<String>> _parseFlatGraphemes(List<String> graphemes) {
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

  void _replaceLines(List<List<String>> lines) {
    _lines = lines;
    _lineStartOffsets = List<int>.filled(lines.length, 0, growable: false);
    var offset = 0;
    for (var index = 0; index < lines.length; index++) {
      _lineStartOffsets[index] = offset;
      offset += lines[index].length;
      if (index < lines.length - 1) {
        offset += 1;
      }
    }
    _length = offset;
  }

  bool _isWhitespace(String grapheme) {
    return grapheme == ' ' ||
        grapheme == '\t' ||
        grapheme == '\n' ||
        grapheme == '\r';
  }
}
