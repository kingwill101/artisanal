library;

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'text_change.dart';

final class TextDocument {
  TextDocument({String text = ''}) {
    _storage = _TextDocumentStorage.fromLineTexts(
      _parseLineTexts(text),
      revision: 0,
    );
  }

  TextDocument._raw();

  late _TextDocumentStorage _storage;

  List<List<String>> get lines => lineViews
      .map((line) => List<String>.unmodifiable(line))
      .toList(growable: false);

  List<List<String>> get lineViews => _storage.lineViews;

  List<String> get lineTexts => _storage.lineTexts;

  int get lineCount => _storage.lineCount;

  int get length => _storage.length;

  int get revision => _storage.revision;

  Object get storageIdentity => _storage.storageIdentity;

  String get text => _storage.text;

  String? graphemeAt(int offset) {
    if (offset < 0 || offset >= length) {
      return null;
    }
    final position = positionForOffset(offset);
    if (position.column == _storage.lineLengths[position.line] &&
        position.line < _storage.lineCount - 1) {
      return '\n';
    }
    return lineGraphemesAt(position.line)[position.column];
  }

  TextDocument copy() {
    final next = TextDocument._raw();
    next._storage = _storage;
    return next;
  }

  String lineAt(int index) {
    return _storage.lineAt(index);
  }

  List<String> lineGraphemesAt(int index) {
    return _storage.lineGraphemesAt(index);
  }

  int lineLength(int index) {
    return _storage.lineLength(index);
  }

  int lineStartOffset(int index) {
    if (index <= 0) {
      return 0;
    }
    if (index >= _storage.lineStartOffsets.length) {
      return length;
    }
    return _storage.lineStartOffsets[index];
  }

  int lineEndOffset(int index, {bool includeTrailingNewline = false}) {
    if (index < 0) {
      return 0;
    }
    if (index >= _storage.lineLengths.length) {
      return length;
    }
    final end = _storage.lineStartOffsets[index] + _storage.lineLengths[index];
    if (includeTrailingNewline && index < _storage.lineLengths.length - 1) {
      return end + 1;
    }
    return end;
  }

  TextPosition clampPosition(TextPosition position) {
    final line = position.line.clamp(0, _storage.lineCount - 1);
    final column = position.column.clamp(0, _storage.lineLengths[line]);
    return TextPosition(line: line, column: column);
  }

  int offsetForPosition(TextPosition position) {
    final clamped = clampPosition(position);
    return _storage.lineStartOffsets[clamped.line] + clamped.column;
  }

  TextPosition positionForOffset(int offset) {
    final clamped = offset.clamp(0, length);
    var low = 0;
    var high = _storage.lineCount - 1;
    while (low < high) {
      final mid = (low + high) >> 1;
      final lineEnd = _storage.lineStartOffsets[mid] + _storage.lineLengths[mid];
      if (clamped <= lineEnd) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    final line = low;
    return TextPosition(
      line: line,
      column: clamped - _storage.lineStartOffsets[line],
    );
  }

  List<String> flattenWithNewlines() => _storage.flattenWithNewlines();

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

    while (remaining > 0 && line < _storage.lineCount) {
      final lineLength = _storage.lineLengths[line];
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
          line < _storage.lineCount - 1) {
        result.add('\n');
        remaining -= 1;
        line += 1;
        column = 0;
      }
    }

    return result;
  }

  String textInRange({required int startOffset, required int endOffset}) {
    final start = startOffset.clamp(0, length);
    final end = endOffset.clamp(start, length);
    if (start == end) {
      return '';
    }

    final startPosition = positionForOffset(start);
    final endPosition = positionForOffset(end);
    final buffer = StringBuffer();
    for (var line = startPosition.line; line <= endPosition.line; line++) {
      final lineStart = line == startPosition.line ? startPosition.column : 0;
      final lineEnd = line == endPosition.line
          ? endPosition.column
          : lineLength(line);
      if (lineEnd > lineStart) {
        buffer.write(lineGraphemesAt(line).sublist(lineStart, lineEnd).join());
      }
      if (line < endPosition.line) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  String textBetweenLines({required int startLine, required int endLine}) {
    final start = startLine.clamp(0, lineCount);
    final end = endLine.clamp(start, lineCount);
    if (start == end) {
      return '';
    }
    return _storage.lineTexts.sublist(start, end).join('\n');
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
    _storage = _TextDocumentStorage.fromLineTexts(
      _parseLineTexts(text),
      revision: _storage.revision + 1,
    );
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
      ..._storage.lineTexts.take(startPosition.line),
      ...mergedLines.map((line) => line.join()),
      ..._storage.lineTexts.skip(oldEndPosition.line + 1),
    ];
    final nextLineLengths = <int>[
      ..._storage.lineLengths.take(startPosition.line),
      ...mergedLines.map((line) => line.length),
      ..._storage.lineLengths.skip(oldEndPosition.line + 1),
    ];
    final nextLineGraphemeCaches = <List<String>?>[
      ..._storage.lineGraphemeCaches.take(startPosition.line),
      ...mergedLines.map(
        (line) => List<String>.unmodifiable(List<String>.from(line)),
      ),
      ..._storage.lineGraphemeCaches.skip(oldEndPosition.line + 1),
    ];
    final offsetDelta = replacement.length - (normalizedEnd - normalizedStart);
    final nextLineStartOffsets = <int>[
      ..._storage.lineStartOffsets.take(startPosition.line),
    ];
    var nextOffset = _storage.lineStartOffsets[startPosition.line];
    for (var index = 0; index < mergedLines.length; index++) {
      nextLineStartOffsets.add(nextOffset);
      nextOffset += nextLineLengths[startPosition.line + index];
      if (index < mergedLines.length - 1) {
        nextOffset += 1;
      }
    }
    nextLineStartOffsets.addAll(
      _storage.lineStartOffsets
          .skip(oldEndPosition.line + 1)
          .map((offset) => offset + offsetDelta),
    );
    _storage = _TextDocumentStorage(
      lineTexts: nextLineTexts,
      lineLengths: nextLineLengths,
      lineStartOffsets: nextLineStartOffsets,
      length: _storage.length + offsetDelta,
      revision: _storage.revision + 1,
      storageIdentity: Object(),
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
    final parsedLines = lines.isEmpty
        ? <List<String>>[<String>[]]
        : lines
              .map((line) => List<String>.from(line))
              .toList(growable: false);
    _storage = _TextDocumentStorage.fromParsedLines(
      parsedLines,
      revision: _storage.revision + 1,
    );
  }

  void replaceLineTexts(List<String> lineTexts) {
    final normalizedLineTexts = lineTexts.isEmpty
        ? const <String>['']
        : List<String>.from(lineTexts, growable: false);
    _storage = _TextDocumentStorage.fromLineTexts(
      normalizedLineTexts,
      revision: _storage.revision + 1,
    );
  }

  void replaceLineTextRange({
    required int startLine,
    required int endLine,
    required List<String> replacementLineTexts,
  }) {
    final normalizedStart = startLine.clamp(0, _storage.lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, _storage.lineCount);
    final normalizedReplacement = replacementLineTexts.isEmpty
        ? const <String>[]
        : List<String>.from(replacementLineTexts, growable: false);

    var nextLineTexts = <String>[
      ..._storage.lineTexts.take(normalizedStart),
      ...normalizedReplacement,
      ..._storage.lineTexts.skip(normalizedEnd),
    ];
    if (nextLineTexts.isEmpty) {
      nextLineTexts = <String>[''];
    }

    final replacementLineLengths = normalizedReplacement
        .map((line) => line.characters.length)
        .toList(growable: false);
    var nextLineLengths = <int>[
      ..._storage.lineLengths.take(normalizedStart),
      ...replacementLineLengths,
      ..._storage.lineLengths.skip(normalizedEnd),
    ];
    if (nextLineLengths.isEmpty) {
      nextLineLengths = <int>[0];
    }

    var nextLineGraphemeCaches = <List<String>?>[
      ..._storage.lineGraphemeCaches.take(normalizedStart),
      ...List<List<String>?>.filled(
        normalizedReplacement.length,
        null,
        growable: false,
      ),
      ..._storage.lineGraphemeCaches.skip(normalizedEnd),
    ];
    if (nextLineGraphemeCaches.isEmpty) {
      nextLineGraphemeCaches = <List<String>?>[null];
    }

    _storage = _TextDocumentStorage(
      lineTexts: nextLineTexts,
      lineLengths: nextLineLengths,
      lineStartOffsets: _TextDocumentStorage._computeLineStartOffsets(
        nextLineLengths,
      ),
      length: _TextDocumentStorage._documentLengthForLineLengths(
        nextLineLengths,
      ),
      revision: _storage.revision + 1,
      storageIdentity: Object(),
      lineGraphemeCaches: nextLineGraphemeCaches,
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

  bool _isWhitespace(String grapheme) {
    return grapheme == ' ' ||
        grapheme == '\t' ||
        grapheme == '\n' ||
        grapheme == '\r';
  }
}

final class _TextDocumentStorage {
  _TextDocumentStorage({
    required List<String> lineTexts,
    required List<int> lineLengths,
    required List<int> lineStartOffsets,
    required this.length,
    required this.revision,
    required this.storageIdentity,
    List<List<String>?>? lineGraphemeCaches,
  }) : lineTexts = List<String>.unmodifiable(lineTexts),
       lineLengths = List<int>.unmodifiable(lineLengths),
       lineStartOffsets = List<int>.unmodifiable(lineStartOffsets),
       lineGraphemeCaches = lineGraphemeCaches == null
           ? List<List<String>?>.filled(lineTexts.length, null, growable: false)
           : List<List<String>?>.from(lineGraphemeCaches, growable: false);

  factory _TextDocumentStorage.fromLineTexts(
    List<String> lineTexts, {
    required int revision,
    Object? storageIdentity,
  }) {
    final lineLengths = lineTexts
        .map((line) => line.characters.length)
        .toList(growable: false);
    return _TextDocumentStorage(
      lineTexts: lineTexts,
      lineLengths: lineLengths,
      lineStartOffsets: _TextDocumentStorage._computeLineStartOffsets(
        lineLengths,
      ),
      length: _TextDocumentStorage._documentLengthForLineLengths(lineLengths),
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
    );
  }

  factory _TextDocumentStorage.fromParsedLines(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
  }) {
    final lineLengths = lines.map((line) => line.length).toList(growable: false);
    return _TextDocumentStorage(
      lineTexts: lines.map((line) => line.join()).toList(growable: false),
      lineLengths: lineLengths,
      lineStartOffsets: _TextDocumentStorage._computeLineStartOffsets(
        lineLengths,
      ),
      length: _TextDocumentStorage._documentLengthForLineLengths(lineLengths),
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
      lineGraphemeCaches: lines
          .map((line) => List<String>.unmodifiable(List<String>.from(line)))
          .toList(growable: false),
    );
  }

  final List<String> lineTexts;
  final List<int> lineLengths;
  final List<int> lineStartOffsets;
  final int length;
  final int revision;
  final Object storageIdentity;
  final List<List<String>?> lineGraphemeCaches;
  String? _cachedText;
  List<String>? _cachedFlattenedGraphemes;
  List<List<String>>? _cachedLineViews;

  int get lineCount => lineTexts.length;

  String get text => _cachedText ??= lineTexts.join('\n');

  String lineAt(int index) {
    if (index < 0 || index >= lineTexts.length) {
      return '';
    }
    return lineTexts[index];
  }

  int lineLength(int index) {
    if (index < 0 || index >= lineLengths.length) {
      return 0;
    }
    return lineLengths[index];
  }

  List<String> lineGraphemesAt(int index) {
    if (index < 0 || index >= lineTexts.length) {
      return const <String>[];
    }
    return lineGraphemeCaches[index] ??= List<String>.unmodifiable(
      lineTexts[index].characters.toList(growable: false),
    );
  }

  List<List<String>> get lineViews =>
      _cachedLineViews ??= List<List<String>>.unmodifiable(
        List<List<String>>.generate(
          lineTexts.length,
          lineGraphemesAt,
          growable: false,
        ),
      );

  List<String> flattenWithNewlines() {
    final flattened = _cachedFlattenedGraphemes ??= () {
      final result = <String>[];
      for (var index = 0; index < lineTexts.length; index++) {
        result.addAll(lineGraphemesAt(index));
        if (index < lineTexts.length - 1) {
          result.add('\n');
        }
      }
      return List<String>.unmodifiable(result);
    }();
    return List<String>.from(flattened, growable: true);
  }

  static List<int> _computeLineStartOffsets(List<int> lineLengths) {
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

  static int _documentLengthForLineLengths(List<int> lineLengths) {
    return lineLengths.fold<int>(0, (total, line) => total + line) +
        (lineLengths.length > 1 ? lineLengths.length - 1 : 0);
  }
}
