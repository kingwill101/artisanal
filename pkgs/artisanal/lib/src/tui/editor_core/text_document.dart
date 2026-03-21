library;

import 'dart:collection';

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'text_change.dart';

final class TextDocument {
  TextDocument({String text = ''}) {
    _replaceLines(_parseLines(text));
  }

  TextDocument._raw();

  late List<List<String>> _lines;
  late List<int> _lineStartOffsets;
  late int _length;
  String? _cachedText;
  List<String>? _cachedFlattenedGraphemes;
  List<String>? _cachedLineTexts;
  List<List<String>>? _cachedLineViews;

  List<List<String>> get lines => _lines
      .map((line) => List<String>.unmodifiable(line))
      .toList(growable: false);

  List<List<String>> get lineViews => _cachedLineViews ??= _lines;

  List<String> get lineTexts => _cachedLineTexts ??= List<String>.unmodifiable(
    _lines.map((line) => line.join()),
  );

  int get lineCount => _lines.length;

  int get length => _length;

  String get text =>
      _cachedText ??= _lines.map((line) => line.join()).join('\n');

  String? graphemeAt(int offset) {
    if (offset < 0 || offset >= length) {
      return null;
    }
    final position = positionForOffset(offset);
    if (position.column == _lines[position.line].length &&
        position.line < _lines.length - 1) {
      return '\n';
    }
    return _lines[position.line][position.column];
  }

  TextDocument copy() {
    final next = TextDocument._raw();
    next._lines = _lines;
    next._lineStartOffsets = _lineStartOffsets;
    next._length = _length;
    next._cachedText = _cachedText;
    next._cachedFlattenedGraphemes = _cachedFlattenedGraphemes;
    next._cachedLineTexts = _cachedLineTexts;
    next._cachedLineViews = _cachedLineViews;
    return next;
  }

  String lineAt(int index) {
    if (index < 0 || index >= _lines.length) {
      return '';
    }
    return _lines[index].join();
  }

  List<String> lineGraphemesAt(int index) {
    if (index < 0 || index >= _lines.length) {
      return const <String>[];
    }
    return lineViews[index];
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
    final flattened = _cachedFlattenedGraphemes ??= () {
      final result = <String>[];
      for (var index = 0; index < _lines.length; index++) {
        result.addAll(_lines[index]);
        if (index < _lines.length - 1) {
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

    while (remaining > 0 && line < _lines.length) {
      final lineLength = _lines[line].length;
      final takeCount = (lineLength - column).clamp(0, remaining);
      if (takeCount > 0) {
        result.addAll(_lines[line].sublist(column, column + takeCount));
        remaining -= takeCount;
        column += takeCount;
      }

      if (remaining > 0 && column == lineLength && line < _lines.length - 1) {
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
    final prefix = List<String>.from(
      _lines[startPosition.line].take(startPosition.column),
      growable: true,
    );
    final suffix = List<String>.from(
      _lines[oldEndPosition.line].skip(oldEndPosition.column),
      growable: true,
    );

    final mergedLines = replacementLines
        .map((line) => List<String>.from(line, growable: true))
        .toList(growable: true);
    mergedLines.first.insertAll(0, prefix);
    mergedLines.last.addAll(suffix);

    final nextLines = <List<String>>[
      ..._lines.take(startPosition.line),
      ...mergedLines,
      ..._lines.skip(oldEndPosition.line + 1),
    ];
    final offsetDelta = replacement.length - (normalizedEnd - normalizedStart);
    final nextLineStartOffsets = <int>[
      ..._lineStartOffsets.take(startPosition.line),
    ];
    var nextOffset = _lineStartOffsets[startPosition.line];
    for (var index = 0; index < mergedLines.length; index++) {
      nextLineStartOffsets.add(nextOffset);
      nextOffset += mergedLines[index].length;
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
      lines: nextLines,
      lineStartOffsets: nextLineStartOffsets,
      length: _length + offsetDelta,
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
    _replaceLines(
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

  static List<List<String>> _parseLines(String text) {
    if (text.isEmpty) {
      return <List<String>>[<String>[]];
    }

    return text
        .split('\n')
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

  void _replaceLines(List<List<String>> lines) {
    final lineStartOffsets = List<int>.filled(lines.length, 0, growable: false);
    var offset = 0;
    for (var index = 0; index < lines.length; index++) {
      lineStartOffsets[index] = offset;
      offset += lines[index].length;
      if (index < lines.length - 1) {
        offset += 1;
      }
    }
    _replaceState(
      lines: lines,
      lineStartOffsets: lineStartOffsets,
      length: offset,
    );
  }

  void _replaceState({
    required List<List<String>> lines,
    required List<int> lineStartOffsets,
    required int length,
  }) {
    _lines = List<List<String>>.unmodifiable(
      lines.map((line) => UnmodifiableListView(line)),
    );
    _lineStartOffsets = List<int>.unmodifiable(lineStartOffsets);
    _length = length;
    _cachedText = null;
    _cachedFlattenedGraphemes = null;
    _cachedLineTexts = null;
    _cachedLineViews = null;
  }

  bool _isWhitespace(String grapheme) {
    return grapheme == ' ' ||
        grapheme == '\t' ||
        grapheme == '\n' ||
        grapheme == '\r';
  }
}
