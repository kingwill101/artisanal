library;

import 'package:characters/characters.dart';

import 'editor_state.dart';

final class TextDocument {
  TextDocument({String text = ''}) : _lines = _parseLines(text);

  List<List<String>> _lines;

  List<List<String>> get lines => _lines
      .map((line) => List<String>.unmodifiable(line))
      .toList(growable: false);

  int get lineCount => _lines.length;

  int get length {
    var total = 0;
    for (var i = 0; i < _lines.length; i++) {
      total += _lines[i].length;
      if (i < _lines.length - 1) {
        total += 1;
      }
    }
    return total;
  }

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
    var offset = 0;
    for (var index = 0; index < clamped.line; index++) {
      offset += _lines[index].length + 1;
    }
    return offset + clamped.column;
  }

  TextPosition positionForOffset(int offset) {
    var remaining = offset.clamp(0, length);
    for (var index = 0; index < _lines.length; index++) {
      final lineLength = _lines[index].length;
      if (remaining <= lineLength) {
        return TextPosition(line: index, column: remaining);
      }
      remaining -= lineLength + 1;
    }
    return TextPosition(line: _lines.length - 1, column: _lines.last.length);
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
    _lines = _parseLines(text);
  }

  void replaceLines(List<List<String>> lines) {
    _lines = lines.isEmpty
        ? <List<String>>[<String>[]]
        : lines.map((line) => List<String>.from(line)).toList(growable: false);
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

  bool _isWhitespace(String grapheme) {
    return grapheme == ' ' ||
        grapheme == '\t' ||
        grapheme == '\n' ||
        grapheme == '\r';
  }
}
