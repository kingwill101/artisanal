library;

import 'package:characters/characters.dart';
import 'package:meta/meta.dart' show visibleForTesting;

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

  @visibleForTesting
  int get debugStorageDepth => _storage.debugDepth;

  @visibleForTesting
  int get debugStorageSegmentCount => _storage.debugSegmentCount;

  @visibleForTesting
  int get debugLineGraphemeCacheCount => _storage.debugLineGraphemeCacheCount;

  @visibleForTesting
  bool get debugHasMaterializedLineTextCache =>
      _storage.debugHasMaterializedLineTextCache;

  @visibleForTesting
  bool get debugHasTextCache => _storage.debugHasTextCache;

  String? graphemeAt(int offset) {
    if (offset < 0 || offset >= length) {
      return null;
    }
    final position = positionForOffset(offset);
    if (position.column == lineLength(position.line) &&
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
    return _storage.lineStartOffset(index);
  }

  int lineEndOffset(int index, {bool includeTrailingNewline = false}) {
    return _storage.lineEndOffset(
      index,
      includeTrailingNewline: includeTrailingNewline,
    );
  }

  TextPosition clampPosition(TextPosition position) {
    final line = position.line.clamp(0, _storage.lineCount - 1);
    final column = position.column.clamp(0, lineLength(line));
    return TextPosition(line: line, column: column);
  }

  int offsetForPosition(TextPosition position) {
    final clamped = clampPosition(position);
    return _storage.offsetForPosition(clamped);
  }

  TextPosition positionForOffset(int offset) {
    return _storage.positionForOffset(offset.clamp(0, length));
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
      final lineLength = this.lineLength(line);
      final takeCount = (lineLength - column).clamp(0, remaining);
      if (takeCount > 0) {
        result.addAll(
          _storage.graphemesInLineRange(
            line,
            startColumn: column,
            endColumn: column + takeCount,
          ),
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
        buffer.write(
          _storage.textInLineRange(
            line,
            startColumn: lineStart,
            endColumn: lineEnd,
          ),
        );
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
    final buffer = StringBuffer();
    for (var line = start; line < end; line++) {
      if (line > start) {
        buffer.write('\n');
      }
      buffer.write(lineAt(line));
    }
    return buffer.toString();
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
    if (matchesOffsetRange(
          startOffset: normalizedStart,
          graphemes: replacement,
        ) &&
        normalizedStart + replacement.length == normalizedEnd) {
      return TextDocumentChange(
        startOffset: normalizedStart,
        oldEndOffset: normalizedEnd,
        newEndOffset: normalizedEnd,
        startPosition: startPosition,
        oldEndPosition: oldEndPosition,
        newEndPosition: oldEndPosition,
      );
    }

    final replacementLineTexts = _parseFlatLineTexts(replacement);
    final prefixText = _storage.lineTextPrefix(
      startPosition.line,
      startPosition.column,
    );
    final suffixText = _storage.lineTextSuffix(
      oldEndPosition.line,
      oldEndPosition.column,
    );
    final mergedLineTexts = List<String>.from(
      replacementLineTexts,
      growable: true,
    );
    mergedLineTexts[0] = '$prefixText${mergedLineTexts.first}';
    mergedLineTexts[mergedLineTexts.length - 1] =
        '${mergedLineTexts.last}$suffixText';

    final replacementStorage = _TextDocumentStorage.fromLineTexts(
      mergedLineTexts,
      revision: 0,
    );
    final nextSegments = <_TextDocumentStorageSegment>[
      if (startPosition.line > 0) _storage.slice(0, startPosition.line),
      replacementStorage.slice(0, replacementStorage.lineCount),
      if (oldEndPosition.line + 1 < _storage.lineCount)
        _storage.slice(oldEndPosition.line + 1, _storage.lineCount),
    ];
    _storage = _TextDocumentStorage.fromSegments(
      nextSegments,
      revision: _storage.revision + 1,
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
        : lines.map((line) => List<String>.from(line)).toList(growable: false);
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

  TextDocumentChange replaceLineTextRange({
    required int startLine,
    required int endLine,
    required List<String> replacementLineTexts,
  }) {
    final normalizedStart = startLine.clamp(0, _storage.lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, _storage.lineCount);
    final normalizedReplacement = replacementLineTexts.isEmpty
        ? const <String>[]
        : List<String>.from(replacementLineTexts, growable: false);

    final startOffset = lineStartOffset(normalizedStart);
    final oldEndOffset = lineStartOffset(normalizedEnd);
    final startPosition = positionForOffset(startOffset);
    final oldEndPosition = positionForOffset(oldEndOffset);
    if (_matchesLineTextRange(
      startLine: normalizedStart,
      endLine: normalizedEnd,
      replacementLineTexts: normalizedReplacement,
    )) {
      return TextDocumentChange(
        startOffset: startOffset,
        oldEndOffset: oldEndOffset,
        newEndOffset: oldEndOffset,
        startPosition: startPosition,
        oldEndPosition: oldEndPosition,
        newEndPosition: oldEndPosition,
      );
    }
    if (_storage.lineCount -
            (normalizedEnd - normalizedStart) +
            normalizedReplacement.length ==
        0) {
      _storage = _TextDocumentStorage.fromLineTexts(const <String>[
        '',
      ], revision: _storage.revision + 1);
    } else {
      final replacementStorage = normalizedReplacement.isEmpty
          ? null
          : _TextDocumentStorage.fromLineTexts(
              normalizedReplacement,
              revision: 0,
            );
      final nextSegments = <_TextDocumentStorageSegment>[
        if (normalizedStart > 0) _storage.slice(0, normalizedStart),
        if (replacementStorage != null)
          replacementStorage.slice(0, replacementStorage.lineCount),
        if (normalizedEnd < _storage.lineCount)
          _storage.slice(normalizedEnd, _storage.lineCount),
      ];
      _storage = _TextDocumentStorage.fromSegments(
        nextSegments,
        revision: _storage.revision + 1,
      );
    }

    final newEndOffset = lineStartOffset(
      normalizedStart + normalizedReplacement.length,
    );
    return TextDocumentChange(
      startOffset: startOffset,
      oldEndOffset: oldEndOffset,
      newEndOffset: newEndOffset,
      startPosition: startPosition,
      oldEndPosition: oldEndPosition,
      newEndPosition: positionForOffset(newEndOffset),
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

  static List<String> parseFlatLineTexts(Iterable<String> graphemes) =>
      _parseFlatLineTexts(graphemes);

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

  static List<String> _parseFlatLineTexts(Iterable<String> graphemes) {
    final lines = <StringBuffer>[StringBuffer()];
    for (final grapheme in graphemes) {
      if (grapheme == '\n') {
        lines.add(StringBuffer());
        continue;
      }
      lines.last.write(grapheme);
    }
    return List<String>.unmodifiable(
      lines.map((line) => line.toString()).toList(growable: false),
    );
  }

  bool _matchesLineTextRange({
    required int startLine,
    required int endLine,
    required List<String> replacementLineTexts,
  }) {
    final expectedLength = endLine - startLine;
    if (replacementLineTexts.length != expectedLength) {
      return false;
    }
    for (var index = 0; index < expectedLength; index++) {
      if (lineAt(startLine + index) != replacementLineTexts[index]) {
        return false;
      }
    }
    return true;
  }

  bool _isWhitespace(String grapheme) {
    return grapheme == ' ' ||
        grapheme == '\t' ||
        grapheme == '\n' ||
        grapheme == '\r';
  }
}

final class _TextDocumentStorage {
  static const int _maxLeafLineCount = 256;
  static const int _maxCompositeSegmentCount = 32;

  _TextDocumentStorage._leaf({
    required List<String> lineTexts,
    required List<int> lineLengths,
    required this.length,
    required this.revision,
    required this.storageIdentity,
    Map<int, List<String>>? lineGraphemeCaches,
  }) : _baseLineTexts = List<String>.unmodifiable(lineTexts),
       _baseLineLengths = List<int>.unmodifiable(lineLengths),
       _segments = null,
       _segmentLineStarts = null,
       _segmentStartOffsets = null,
       lineCount = lineTexts.length,
       _lineGraphemeCaches = lineGraphemeCaches ?? <int, List<String>>{};

  _TextDocumentStorage._composite({
    required List<_TextDocumentStorageSegment> segments,
    required this.lineCount,
    required this.length,
    required this.revision,
    required this.storageIdentity,
  }) : _baseLineTexts = null,
       _baseLineLengths = null,
       _segments = List<_TextDocumentStorageSegment>.unmodifiable(segments),
       _segmentLineStarts = _computeSegmentLineStarts(segments),
       _segmentStartOffsets = _computeSegmentStartOffsets(segments),
       _lineGraphemeCaches = <int, List<String>>{};

  factory _TextDocumentStorage.fromLineTexts(
    List<String> lineTexts, {
    required int revision,
    Object? storageIdentity,
  }) {
    if (lineTexts.length > _maxLeafLineCount) {
      return _buildChunkedLeafCompositeFromLineTexts(
        lineTexts,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return _leafFromLineTexts(
      lineTexts,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  factory _TextDocumentStorage.fromParsedLines(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
  }) {
    if (lines.length > _maxLeafLineCount) {
      return _buildChunkedLeafCompositeFromParsedLines(
        lines,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return _leafFromParsedLines(
      lines,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  factory _TextDocumentStorage.fromSegments(
    List<_TextDocumentStorageSegment> segments, {
    required int revision,
    Object? storageIdentity,
  }) {
    final nonEmpty = _normalizeSegments(segments);
    if (nonEmpty.isEmpty) {
      return _TextDocumentStorage.fromLineTexts(
        const <String>[''],
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    if (nonEmpty.length > _maxCompositeSegmentCount) {
      return _buildBalancedComposite(
        nonEmpty,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return _buildComposite(
      nonEmpty,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  final int lineCount;
  final int length;
  final int revision;
  final Object storageIdentity;
  final List<String>? _baseLineTexts;
  final List<int>? _baseLineLengths;
  final List<_TextDocumentStorageSegment>? _segments;
  final List<int>? _segmentLineStarts;
  final List<int>? _segmentStartOffsets;
  final Map<int, List<String>> _lineGraphemeCaches;
  List<String>? _cachedLineTexts;
  List<int>? _cachedLineLengths;
  List<int>? _cachedLineStartOffsets;
  String? _cachedText;
  List<String>? _cachedFlattenedGraphemes;
  List<List<String>>? _cachedLineViews;

  int get debugDepth {
    final segments = _segments;
    if (segments == null || segments.isEmpty) {
      return 1;
    }
    var maxChildDepth = 0;
    for (final segment in segments) {
      final childDepth = segment.storage.debugDepth;
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }
    return maxChildDepth + 1;
  }

  int get debugSegmentCount => _segments?.length ?? 1;

  int get debugLineGraphemeCacheCount =>
      _debugLineGraphemeCacheCount(<_TextDocumentStorage>{});

  bool get debugHasMaterializedLineTextCache => _cachedLineTexts != null;

  bool get debugHasTextCache => _cachedText != null;

  List<String> get lineTexts =>
      _cachedLineTexts ??= _baseLineTexts ?? _materializeLineTexts();

  List<int> get lineLengths =>
      _cachedLineLengths ??= _baseLineLengths ?? _materializeLineLengths();

  List<int> get lineStartOffsets =>
      _cachedLineStartOffsets ??= _computeLineStartOffsets(lineLengths);

  String get text => _cachedText ??= _buildText();

  _TextDocumentStorageSegment slice(int startLine, int endLine) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    return _TextDocumentStorageSegment(
      storage: this,
      startLine: normalizedStart,
      endLine: normalizedEnd,
    );
  }

  String lineAt(int index) {
    if (index < 0 || index >= lineCount) {
      return '';
    }
    if (_baseLineTexts != null) {
      return _baseLineTexts[index];
    }
    final (segment, localIndex) = _segmentForLine(index);
    return segment.lineAt(localIndex);
  }

  int lineLength(int index) {
    if (index < 0 || index >= lineCount) {
      return 0;
    }
    if (_baseLineLengths != null) {
      return _baseLineLengths[index];
    }
    final (segment, localIndex) = _segmentForLine(index);
    return segment.lineLength(localIndex);
  }

  int lineStartOffset(int index) {
    if (index <= 0) {
      return 0;
    }
    if (index >= lineCount) {
      return length;
    }
    if (_baseLineLengths != null) {
      return lineStartOffsets[index];
    }
    final (segment, localIndex, segmentIndex) = _segmentForLineWithIndex(index);
    return _segmentStartOffsets![segmentIndex] +
        segment.lineStartOffset(localIndex);
  }

  int lineEndOffset(int index, {bool includeTrailingNewline = false}) {
    if (index < 0) {
      return 0;
    }
    if (index >= lineCount) {
      return length;
    }
    final end = lineStartOffset(index) + lineLength(index);
    if (includeTrailingNewline && index < lineCount - 1) {
      return end + 1;
    }
    return end;
  }

  int offsetForPosition(TextPosition position) {
    final line = position.line.clamp(0, lineCount - 1);
    final column = position.column.clamp(0, lineLength(line));
    return lineStartOffset(line) + column;
  }

  TextPosition positionForOffset(int offset) {
    final clamped = offset.clamp(0, length);
    if (clamped == length) {
      return TextPosition(
        line: lineCount - 1,
        column: lineLength(lineCount - 1),
      );
    }
    if (_baseLineLengths != null) {
      var low = 0;
      var high = lineCount - 1;
      while (low < high) {
        final mid = (low + high) >> 1;
        final lineEnd = lineStartOffsets[mid] + lineLengths[mid];
        if (clamped <= lineEnd) {
          high = mid;
        } else {
          low = mid + 1;
        }
      }
      final line = low;
      return TextPosition(line: line, column: clamped - lineStartOffsets[line]);
    }

    final (segment, segmentIndex) = _segmentForOffset(clamped);
    final localOffset = clamped - _segmentStartOffsets![segmentIndex];
    final localPosition = segment.positionForOffset(localOffset);
    return TextPosition(
      line: _segmentLineStarts![segmentIndex] + localPosition.line,
      column: localPosition.column,
    );
  }

  List<String> lineGraphemesAt(int index) {
    if (index < 0 || index >= lineCount) {
      return const <String>[];
    }
    return _lineGraphemeCaches[index] ??= List<String>.unmodifiable(
      lineAt(index).characters.toList(growable: false),
    );
  }

  String lineTextPrefix(int index, int graphemeCount) {
    if (index < 0 || index >= lineCount) {
      return '';
    }
    final line = lineAt(index);
    final clampedCount = graphemeCount.clamp(0, lineLength(index));
    if (clampedCount <= 0) {
      return '';
    }
    if (clampedCount >= lineLength(index)) {
      return line;
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      return cached.take(clampedCount).join();
    }
    return line.characters.take(clampedCount).toString();
  }

  String lineTextSuffix(int index, int graphemeStart) {
    if (index < 0 || index >= lineCount) {
      return '';
    }
    final line = lineAt(index);
    final clampedStart = graphemeStart.clamp(0, lineLength(index));
    if (clampedStart <= 0) {
      return line;
    }
    if (clampedStart >= lineLength(index)) {
      return '';
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      return cached.skip(clampedStart).join();
    }
    return line.characters.skip(clampedStart).toString();
  }

  List<String> graphemesInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    if (index < 0 || index >= lineCount) {
      return const <String>[];
    }
    final lineLength = this.lineLength(index);
    final normalizedStart = startColumn.clamp(0, lineLength);
    final normalizedEnd = endColumn.clamp(normalizedStart, lineLength);
    if (normalizedStart == normalizedEnd) {
      return const <String>[];
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      return List<String>.unmodifiable(
        cached.sublist(normalizedStart, normalizedEnd),
      );
    }
    return lineAt(index)
        .characters
        .skip(normalizedStart)
        .take(normalizedEnd - normalizedStart)
        .toList(growable: false);
  }

  String textInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    if (index < 0 || index >= lineCount) {
      return '';
    }
    final lineLength = this.lineLength(index);
    final normalizedStart = startColumn.clamp(0, lineLength);
    final normalizedEnd = endColumn.clamp(normalizedStart, lineLength);
    if (normalizedStart == normalizedEnd) {
      return '';
    }
    if (normalizedStart == 0 && normalizedEnd == lineLength) {
      return lineAt(index);
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      return cached.sublist(normalizedStart, normalizedEnd).join();
    }
    return lineAt(index)
        .characters
        .skip(normalizedStart)
        .take(normalizedEnd - normalizedStart)
        .toString();
  }

  List<List<String>> get lineViews =>
      _cachedLineViews ??= List<List<String>>.unmodifiable(
        List<List<String>>.generate(
          lineCount,
          lineGraphemesAt,
          growable: false,
        ),
      );

  List<String> flattenWithNewlines() {
    final flattened = _cachedFlattenedGraphemes ??= () {
      final result = <String>[];
      for (var index = 0; index < lineCount; index++) {
        result.addAll(lineGraphemesAt(index));
        if (index < lineCount - 1) {
          result.add('\n');
        }
      }
      return List<String>.unmodifiable(result);
    }();
    return List<String>.from(flattened, growable: true);
  }

  List<String> _materializeLineTexts() {
    return List<String>.unmodifiable(
      List<String>.generate(lineCount, lineAt, growable: false),
    );
  }

  String _buildText() {
    if (_baseLineTexts case final baseLineTexts?) {
      return baseLineTexts.join('\n');
    }
    final buffer = StringBuffer();
    var wroteAnyLine = false;
    for (final segment in _segments!) {
      if (segment.lineCount <= 0) {
        continue;
      }
      segment.writeTextToBuffer(buffer, leadingNewline: wroteAnyLine);
      wroteAnyLine = true;
    }
    return buffer.toString();
  }

  List<int> _materializeLineLengths() {
    return List<int>.unmodifiable(
      List<int>.generate(lineCount, lineLength, growable: false),
    );
  }

  (_TextDocumentStorageSegment, int) _segmentForLine(int index) {
    final (segment, localIndex, _) = _segmentForLineWithIndex(index);
    return (segment, localIndex);
  }

  (_TextDocumentStorageSegment, int, int) _segmentForLineWithIndex(int index) {
    final segments = _segments!;
    final segmentLineStarts = _segmentLineStarts!;
    var low = 0;
    var high = segments.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (segmentLineStarts[mid] <= index) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    final segmentIndex = low;
    final segment = segments[segmentIndex];
    return (segment, index - segmentLineStarts[segmentIndex], segmentIndex);
  }

  (_TextDocumentStorageSegment, int) _segmentForOffset(int offset) {
    final segments = _segments!;
    final segmentStartOffsets = _segmentStartOffsets!;
    var low = 0;
    var high = segments.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (segmentStartOffsets[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return (segments[low], low);
  }

  static List<int> _computeSegmentLineStarts(
    List<_TextDocumentStorageSegment> segments,
  ) {
    final starts = List<int>.filled(segments.length, 0, growable: false);
    var lineIndex = 0;
    for (var index = 0; index < segments.length; index++) {
      starts[index] = lineIndex;
      lineIndex += segments[index].lineCount;
    }
    return starts;
  }

  static List<int> _computeSegmentStartOffsets(
    List<_TextDocumentStorageSegment> segments,
  ) {
    final starts = List<int>.filled(segments.length, 0, growable: false);
    var offset = 0;
    for (var index = 0; index < segments.length; index++) {
      starts[index] = offset;
      offset += segments[index].length;
      if (index < segments.length - 1) {
        offset += 1;
      }
    }
    return starts;
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

  static _TextDocumentStorage _leafFromLineTexts(
    List<String> lineTexts, {
    required int revision,
    Object? storageIdentity,
  }) {
    final normalizedLineTexts = List<String>.unmodifiable(
      List<String>.from(lineTexts, growable: false),
    );
    final lineLengths = normalizedLineTexts
        .map((line) => line.characters.length)
        .toList(growable: false);
    return _TextDocumentStorage._leaf(
      lineTexts: normalizedLineTexts,
      lineLengths: lineLengths,
      length: _TextDocumentStorage._documentLengthForLineLengths(lineLengths),
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
    );
  }

  static _TextDocumentStorage _leafFromParsedLines(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
  }) {
    final normalizedLines = List<List<String>>.generate(
      lines.length,
      (index) => List<String>.unmodifiable(List<String>.from(lines[index])),
      growable: false,
    );
    final lineLengths = normalizedLines
        .map((line) => line.length)
        .toList(growable: false);
    return _TextDocumentStorage._leaf(
      lineTexts: normalizedLines
          .map((line) => line.join())
          .toList(growable: false),
      lineLengths: lineLengths,
      length: _TextDocumentStorage._documentLengthForLineLengths(lineLengths),
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
      lineGraphemeCaches: <int, List<String>>{
        for (var index = 0; index < normalizedLines.length; index++)
          index: normalizedLines[index],
      },
    );
  }

  static _TextDocumentStorage _buildChunkedLeafCompositeFromLineTexts(
    List<String> lineTexts, {
    required int revision,
    Object? storageIdentity,
  }) {
    final segments = <_TextDocumentStorageSegment>[];
    for (var start = 0; start < lineTexts.length; start += _maxLeafLineCount) {
      final end = (start + _maxLeafLineCount).clamp(0, lineTexts.length);
      final storage = _leafFromLineTexts(
        lineTexts.sublist(start, end),
        revision: 0,
      );
      segments.add(storage.slice(0, storage.lineCount));
    }
    return _buildBalancedComposite(
      segments,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  static _TextDocumentStorage _buildChunkedLeafCompositeFromParsedLines(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
  }) {
    final segments = <_TextDocumentStorageSegment>[];
    for (var start = 0; start < lines.length; start += _maxLeafLineCount) {
      final end = (start + _maxLeafLineCount).clamp(0, lines.length);
      final storage = _leafFromParsedLines(
        lines.sublist(start, end),
        revision: 0,
      );
      segments.add(storage.slice(0, storage.lineCount));
    }
    return _buildBalancedComposite(
      segments,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  static _TextDocumentStorage _buildComposite(
    List<_TextDocumentStorageSegment> segments, {
    required int revision,
    Object? storageIdentity,
  }) {
    final lineCount = segments.fold<int>(
      0,
      (total, segment) => total + segment.lineCount,
    );
    final length =
        segments.fold<int>(0, (total, segment) => total + segment.length) +
        (segments.length > 1 ? segments.length - 1 : 0);
    return _TextDocumentStorage._composite(
      segments: segments,
      lineCount: lineCount,
      length: length,
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
    );
  }

  static _TextDocumentStorage _buildBalancedComposite(
    List<_TextDocumentStorageSegment> segments, {
    required int revision,
    Object? storageIdentity,
  }) {
    if (segments.length <= _maxCompositeSegmentCount) {
      return _buildComposite(
        segments,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }

    final grouped = <_TextDocumentStorageSegment>[];
    for (
      var start = 0;
      start < segments.length;
      start += _maxCompositeSegmentCount
    ) {
      final end = (start + _maxCompositeSegmentCount).clamp(0, segments.length);
      final childStorage = _buildComposite(
        segments.sublist(start, end),
        revision: 0,
      );
      grouped.add(childStorage.slice(0, childStorage.lineCount));
    }

    return _buildBalancedComposite(
      grouped,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  static List<_TextDocumentStorageSegment> _normalizeSegments(
    List<_TextDocumentStorageSegment> segments,
  ) {
    final normalized = <_TextDocumentStorageSegment>[];
    for (final segment in segments) {
      _appendNormalizedSegment(normalized, segment);
    }
    return List<_TextDocumentStorageSegment>.unmodifiable(normalized);
  }

  static void _appendNormalizedSegment(
    List<_TextDocumentStorageSegment> out,
    _TextDocumentStorageSegment segment,
  ) {
    if (segment.lineCount <= 0) {
      return;
    }

    final childSegments = segment.storage._segments;
    if (childSegments == null) {
      _appendMergedLeafSegment(out, segment);
      return;
    }

    final childLineStarts = segment.storage._segmentLineStarts!;
    for (var index = 0; index < childSegments.length; index++) {
      final child = childSegments[index];
      final childGlobalStart = childLineStarts[index];
      final childGlobalEnd = childGlobalStart + child.lineCount;
      final overlapStart = segment.startLine > childGlobalStart
          ? segment.startLine
          : childGlobalStart;
      final overlapEnd = segment.endLine < childGlobalEnd
          ? segment.endLine
          : childGlobalEnd;
      if (overlapStart >= overlapEnd) {
        continue;
      }
      final localStart = child.startLine + (overlapStart - childGlobalStart);
      final localEnd = child.startLine + (overlapEnd - childGlobalStart);
      _appendNormalizedSegment(
        out,
        _TextDocumentStorageSegment(
          storage: child.storage,
          startLine: localStart,
          endLine: localEnd,
        ),
      );
    }
  }

  static void _appendMergedLeafSegment(
    List<_TextDocumentStorageSegment> out,
    _TextDocumentStorageSegment segment,
  ) {
    if (out.isEmpty) {
      out.add(segment);
      return;
    }

    final previous = out.last;
    if (identical(previous.storage, segment.storage) &&
        previous.endLine == segment.startLine) {
      out[out.length - 1] = _TextDocumentStorageSegment(
        storage: previous.storage,
        startLine: previous.startLine,
        endLine: segment.endLine,
      );
      return;
    }

    out.add(segment);
  }

  int _debugLineGraphemeCacheCount(Set<_TextDocumentStorage> visited) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _segments;
    if (segments == null || segments.isEmpty) {
      return _lineGraphemeCaches.length;
    }
    var total = _lineGraphemeCaches.length;
    for (final segment in segments) {
      total += segment.storage._debugLineGraphemeCacheCount(visited);
    }
    return total;
  }
}

final class _TextDocumentStorageSegment {
  const _TextDocumentStorageSegment({
    required this.storage,
    required this.startLine,
    required this.endLine,
  });

  final _TextDocumentStorage storage;
  final int startLine;
  final int endLine;

  int get lineCount => endLine - startLine;

  int get length {
    if (lineCount <= 0) {
      return 0;
    }
    return storage.lineEndOffset(endLine - 1) -
        storage.lineStartOffset(startLine);
  }

  String lineAt(int localIndex) => storage.lineAt(startLine + localIndex);

  int lineLength(int localIndex) => storage.lineLength(startLine + localIndex);

  int lineStartOffset(int localIndex) {
    if (localIndex <= 0) {
      return 0;
    }
    return storage.lineStartOffset(startLine + localIndex) -
        storage.lineStartOffset(startLine);
  }

  TextPosition positionForOffset(int offset) {
    final clamped = offset.clamp(0, length);
    if (clamped == length) {
      return TextPosition(
        line: lineCount - 1,
        column: lineLength(lineCount - 1),
      );
    }
    final absoluteOffset = storage.lineStartOffset(startLine) + clamped;
    final position = storage.positionForOffset(absoluteOffset);
    return TextPosition(
      line: position.line - startLine,
      column: position.column,
    );
  }

  void writeTextToBuffer(StringBuffer buffer, {required bool leadingNewline}) {
    for (var localIndex = 0; localIndex < lineCount; localIndex++) {
      if (leadingNewline || localIndex > 0) {
        buffer.write('\n');
      }
      buffer.write(lineAt(localIndex));
    }
  }
}
