library;

import 'package:characters/characters.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'editor_core_config.dart';
import 'editor_state.dart';
import 'text_change.dart';

const _TextDocumentStorageBuilder _storageBuilder =
    _ChunkedTextDocumentStorageBuilder();

final class TextDocument {
  static int get _sourceBackedReplacementTextThreshold =>
      EditorCoreConfig.current.sourceBackedReplacementTextThreshold;

  TextDocument({String text = ''}) {
    _storage = _storageBuilder.fromText(text, revision: 0);
  }

  TextDocument.fromLineTexts(List<String> lineTexts, {List<int>? lineLengths}) {
    final normalizedLineTexts = lineTexts.isEmpty
        ? const <String>['']
        : List<String>.from(lineTexts, growable: false);
    _storage = _optimizedStorageFromLineTexts(
      normalizedLineTexts,
      lineLengths: lineLengths,
      revision: 0,
    );
  }

  TextDocument.fromParsedLines(
    List<List<String>> lines, {
    bool seedLineGraphemeCaches = true,
  }) {
    final parsedLines = lines.isEmpty
        ? <List<String>>[<String>[]]
        : lines.map((line) => List<String>.from(line)).toList(growable: false);
    _storage = _storageBuilder.fromParsedLines(
      parsedLines,
      revision: 0,
      seedLineGraphemeCaches: seedLineGraphemeCaches,
    );
  }

  TextDocument.fromFlatGraphemes(Iterable<String> graphemes) {
    final parsed = _parseFlatLineTextsWithLengths(graphemes);
    _storage = _optimizedStorageFromLineTexts(
      parsed.lineTexts,
      lineLengths: parsed.lineLengths,
      revision: 0,
    );
  }

  TextDocument._raw();

  late _TextDocumentStorage _storage;
  _LineTextDocumentSource? _appendSource;

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

  @visibleForTesting
  int get debugSourceBackedLeafCount => _storage.debugSourceBackedLeafCount;

  @visibleForTesting
  int get debugPieceBackedLeafCount => _storage.debugPieceBackedLeafCount;

  @visibleForTesting
  int get debugPieceCount => _storage.debugPieceCount;

  @visibleForTesting
  int get debugDistinctSourceCount => _storage.debugDistinctSourceCount;

  @visibleForTesting
  int get debugReferencedSourceCount => _storage.debugReferencedSourceCount;

  @visibleForTesting
  int get debugJoinedSourceTextCount => _storage.debugJoinedSourceTextCount;

  @visibleForTesting
  int get debugMaterializedSourceLineTextCount =>
      _storage.debugMaterializedSourceLineTextCount;

  String? graphemeAt(int offset) {
    if (offset < 0 || offset >= length) {
      return null;
    }
    final position = positionForOffset(offset);
    if (position.column == lineLength(position.line) &&
        position.line < _storage.lineCount - 1) {
      return '\n';
    }
    return _storage.graphemeInLineAt(position.line, position.column);
  }

  TextDocument copy() {
    final next = TextDocument._raw();
    next._storage = _storage;
    next._appendSource = _appendSource;
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
    return _storage.textBetweenLines(startLine: startLine, endLine: endLine);
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

    var matched = 0;
    final startPosition = positionForOffset(start);
    var line = startPosition.line;
    var column = startPosition.column;

    while (matched < graphemes.length && line < _storage.lineCount) {
      final lineLength = this.lineLength(line);
      final takeCount = (lineLength - column).clamp(
        0,
        graphemes.length - matched,
      );
      if (takeCount > 0) {
        if (!_storage.matchesGraphemesInLineRange(
          line,
          startColumn: column,
          graphemes: graphemes,
          graphemeStart: matched,
          graphemeCount: takeCount,
        )) {
          return false;
        }
        column += takeCount;
        matched += takeCount;
      }

      if (matched < graphemes.length &&
          column == lineLength &&
          line < _storage.lineCount - 1) {
        if (graphemes[matched] != '\n') {
          return false;
        }
        matched += 1;
        line += 1;
        column = 0;
      } else if (column == lineLength) {
        line += 1;
        column = 0;
      }
    }

    return matched == graphemes.length;
  }

  ({TextPosition start, TextPosition end}) wordBoundaryAt(
    TextPosition position,
  ) {
    final clamped = clampPosition(position);
    final lineLength = this.lineLength(clamped.line);
    if (lineLength == 0) {
      return (
        start: TextPosition(line: clamped.line, column: 0),
        end: TextPosition(line: clamped.line, column: 0),
      );
    }

    final column = clamped.column.clamp(0, lineLength - 1);
    final boundary = _storage.wordBoundaryAtInLine(clamped.line, column);
    return (
      start: TextPosition(line: clamped.line, column: boundary.start),
      end: TextPosition(line: clamped.line, column: boundary.end),
    );
  }

  void replaceText(String text) {
    if (text == this.text) {
      return;
    }
    _storage = _storageBuilder.fromText(text, revision: _storage.revision + 1);
    _appendSource = null;
  }

  TextDocumentChange replaceTextRange({
    required int startOffset,
    required int endOffset,
    String replacement = '',
  }) {
    final normalizedStart = startOffset.clamp(0, length);
    final normalizedEnd = endOffset.clamp(normalizedStart, length);
    final startPosition = positionForOffset(normalizedStart);
    final oldEndPosition = positionForOffset(normalizedEnd);
    final replacementLength = replacement.characters.length;
    if (normalizedStart + replacementLength == normalizedEnd &&
        textInRange(startOffset: normalizedStart, endOffset: normalizedEnd) ==
            replacement) {
      return TextDocumentChange(
        startOffset: normalizedStart,
        oldEndOffset: normalizedEnd,
        newEndOffset: normalizedEnd,
        startPosition: startPosition,
        oldEndPosition: oldEndPosition,
        newEndPosition: oldEndPosition,
      );
    }

    final replacementLineTexts = _parseLineTexts(replacement);
    final replacementLineLengths = _computeLineTextStats(
      replacementLineTexts,
    ).lineLengths;
    final replacementStorage =
        _pieceBackedReplacementStorageFromLineTexts(
          storage: _storage,
          startPosition: startPosition,
          oldEndPosition: oldEndPosition,
          replacementLineTexts: replacementLineTexts,
          replacementLineLengths: replacementLineLengths,
        ) ??
        (() {
          final prefixText = _storage.lineTextPrefix(
            startPosition.line,
            startPosition.column,
          );
          final suffixText = _storage.lineTextSuffix(
            oldEndPosition.line,
            oldEndPosition.column,
          );
          final mergedReplacementText = prefixText.isEmpty && suffixText.isEmpty
              ? replacement
              : '$prefixText$replacement$suffixText';
          return _replacementStorageFromText(
            mergedReplacementText,
            revision: 0,
          );
        })();
    final nextSegments = <_TextDocumentStorageSegment>[
      if (startPosition.line > 0) _storage.slice(0, startPosition.line),
      replacementStorage.slice(0, replacementStorage.lineCount),
      if (oldEndPosition.line + 1 < _storage.lineCount)
        _storage.slice(oldEndPosition.line + 1, _storage.lineCount),
    ];
    _storage = _storageBuilder.fromSegments(
      nextSegments,
      revision: _storage.revision + 1,
    );

    final newEndOffset = normalizedStart + replacementLength;
    return TextDocumentChange(
      startOffset: normalizedStart,
      oldEndOffset: normalizedEnd,
      newEndOffset: newEndOffset,
      startPosition: startPosition,
      oldEndPosition: oldEndPosition,
      newEndPosition: positionForOffset(newEndOffset),
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

    final replacementLines = _parseFlatGraphemes(replacement);
    final prefixGraphemes = startPosition.column <= 0
        ? const <String>[]
        : _storage.graphemesInLineRange(
            startPosition.line,
            startColumn: 0,
            endColumn: startPosition.column,
          );
    final endLineLength = lineLength(oldEndPosition.line);
    final suffixGraphemes = oldEndPosition.column >= endLineLength
        ? const <String>[]
        : _storage.graphemesInLineRange(
            oldEndPosition.line,
            startColumn: oldEndPosition.column,
            endColumn: endLineLength,
          );
    final mergedLines = List<List<String>>.generate(
      replacementLines.length,
      (index) => List<String>.from(replacementLines[index], growable: true),
      growable: true,
    );
    mergedLines.first.insertAll(0, prefixGraphemes);
    mergedLines.last.addAll(suffixGraphemes);

    final replacementLineTexts = replacementLines
        .map((line) => line.join())
        .toList(growable: false);
    final replacementLineLengths = replacementLines
        .map((line) => line.length)
        .toList(growable: false);
    final replacementStorage = _pieceBackedReplacementStorageFromLineTexts(
      storage: _storage,
      startPosition: startPosition,
      oldEndPosition: oldEndPosition,
      replacementLineTexts: replacementLineTexts,
      replacementLineLengths: replacementLineLengths,
    );
    final nextReplacementStorage =
        replacementStorage ??
        _storageBuilder.fromParsedLines(
          mergedLines,
          revision: 0,
          seedLineGraphemeCaches: false,
        );
    final nextSegments = <_TextDocumentStorageSegment>[
      if (startPosition.line > 0) _storage.slice(0, startPosition.line),
      nextReplacementStorage.slice(0, nextReplacementStorage.lineCount),
      if (oldEndPosition.line + 1 < _storage.lineCount)
        _storage.slice(oldEndPosition.line + 1, _storage.lineCount),
    ];
    _storage = _storageBuilder.fromSegments(
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
    if (_matchesParsedLines(parsedLines)) {
      return;
    }
    _storage = _storageBuilder.fromParsedLines(
      parsedLines,
      revision: _storage.revision + 1,
    );
    _appendSource = null;
  }

  void replaceLineTexts(List<String> lineTexts) {
    final normalizedLineTexts = lineTexts.isEmpty
        ? const <String>['']
        : List<String>.from(lineTexts, growable: false);
    if (_matchesLineTextRange(
      startLine: 0,
      endLine: _storage.lineCount,
      replacementLineTexts: normalizedLineTexts,
    )) {
      return;
    }
    _storage = _optimizedStorageFromLineTexts(
      normalizedLineTexts,
      revision: _storage.revision + 1,
    );
    _appendSource = null;
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
      _storage = _optimizedStorageFromLineTexts(const <String>[
        '',
      ], revision: _storage.revision + 1);
    } else {
      final replacementStorage = normalizedReplacement.isEmpty
          ? null
          : _appendBackedStorageFromLineTexts(normalizedReplacement);
      final nextSegments = <_TextDocumentStorageSegment>[
        if (normalizedStart > 0) _storage.slice(0, normalizedStart),
        if (replacementStorage != null)
          replacementStorage.slice(0, replacementStorage.lineCount),
        if (normalizedEnd < _storage.lineCount)
          _storage.slice(normalizedEnd, _storage.lineCount),
      ];
      _storage = _storageBuilder.fromSegments(
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
      _parseFlatLineTextsWithLengths(graphemes).lineTexts;

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

  static ({List<String> lineTexts, List<int> lineLengths})
  _parseFlatLineTextsWithLengths(Iterable<String> graphemes) {
    final lines = <StringBuffer>[StringBuffer()];
    final lineLengths = <int>[0];
    for (final grapheme in graphemes) {
      if (grapheme == '\n') {
        lines.add(StringBuffer());
        lineLengths.add(0);
        continue;
      }
      lines.last.write(grapheme);
      lineLengths[lineLengths.length - 1] += 1;
    }
    return (
      lineTexts: List<String>.unmodifiable(
        lines.map((line) => line.toString()).toList(growable: false),
      ),
      lineLengths: List<int>.unmodifiable(lineLengths),
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
      final lineIndex = startLine + index;
      final replacementGraphemes = replacementLineTexts[index].characters
          .toList(growable: false);
      if (replacementGraphemes.length != lineLength(lineIndex)) {
        return false;
      }
      if (!matchesOffsetRange(
        startOffset: lineStartOffset(lineIndex),
        graphemes: replacementGraphemes,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _matchesParsedLines(List<List<String>> replacementLines) {
    if (replacementLines.length != lineCount) {
      return false;
    }
    for (var line = 0; line < replacementLines.length; line++) {
      final replacementLine = replacementLines[line];
      if (replacementLine.length != lineLength(line)) {
        return false;
      }
      if (!matchesOffsetRange(
        startOffset: lineStartOffset(line),
        graphemes: replacementLine,
      )) {
        return false;
      }
    }
    return true;
  }

  static bool _isWhitespace(String grapheme) {
    return grapheme == ' ' ||
        grapheme == '\t' ||
        grapheme == '\n' ||
        grapheme == '\r';
  }

  _TextDocumentStorage _appendBackedStorageFromLineTexts(
    List<String> lineTexts, {
    List<int>? lineLengths,
  }) {
    final normalizedLineLengths =
        lineLengths ?? _computeLineTextStats(lineTexts).lineLengths;
    final replacementSource = _appendSource ??=
        _LineTextDocumentSource._appendable();
    final replacementStartLine = replacementSource.appendLineTexts(
      lineTexts,
      lineLengths: normalizedLineLengths,
    );
    final linePieces = List<List<_TextDocumentSourcePiece>>.generate(
      lineTexts.length,
      (index) {
        final lineLength = normalizedLineLengths[index];
        if (lineLength <= 0) {
          return const <_TextDocumentSourcePiece>[];
        }
        return <_TextDocumentSourcePiece>[
          _TextDocumentSourcePiece(
            source: replacementSource,
            sourceLine: replacementStartLine + index,
            startColumn: 0,
            endColumn: lineLength,
          ),
        ];
      },
      growable: false,
    );
    return _storageBuilder.fromLinePieces(linePieces, revision: 0);
  }

  static _TextDocumentStorage _replacementStorageFromText(
    String text, {
    required int revision,
  }) {
    return _storageBuilder.optimizedFromText(text, revision: revision);
  }

  static _TextDocumentStorage _optimizedStorageFromLineTexts(
    List<String> lineTexts, {
    List<int>? lineLengths,
    required int revision,
  }) {
    return _storageBuilder.optimizedFromLineTexts(
      lineTexts,
      lineLengths: lineLengths,
      revision: revision,
    );
  }

  _TextDocumentStorage? _pieceBackedReplacementStorageFromLineTexts({
    required _TextDocumentStorage storage,
    required TextPosition startPosition,
    required TextPosition oldEndPosition,
    required List<String> replacementLineTexts,
    required List<int> replacementLineLengths,
  }) {
    if (replacementLineTexts.isEmpty ||
        replacementLineTexts.length != replacementLineLengths.length) {
      return null;
    }

    final linePieces = List<List<_TextDocumentSourcePiece>>.generate(
      replacementLineTexts.length,
      (_) => <_TextDocumentSourcePiece>[],
      growable: false,
    );

    if (startPosition.column > 0) {
      final prefixPieces = storage.sourcePiecesForLineRange(
        startPosition.line,
        startColumn: 0,
        endColumn: startPosition.column,
      );
      if (prefixPieces == null) {
        return null;
      }
      linePieces.first.addAll(prefixPieces);
    }

    final replacementSource = _appendSource ??=
        _LineTextDocumentSource._appendable();
    final replacementStartLine = replacementSource.appendLineTexts(
      replacementLineTexts,
      lineLengths: replacementLineLengths,
    );
    for (
      var lineIndex = 0;
      lineIndex < replacementLineTexts.length;
      lineIndex++
    ) {
      final lineLength = replacementLineLengths[lineIndex];
      if (lineLength <= 0) {
        continue;
      }
      linePieces[lineIndex].add(
        _TextDocumentSourcePiece(
          source: replacementSource,
          sourceLine: replacementStartLine + lineIndex,
          startColumn: 0,
          endColumn: lineLength,
        ),
      );
    }

    final endLineLength = storage.lineLength(oldEndPosition.line);
    if (oldEndPosition.column < endLineLength) {
      final suffixPieces = storage.sourcePiecesForLineRange(
        oldEndPosition.line,
        startColumn: oldEndPosition.column,
        endColumn: endLineLength,
      );
      if (suffixPieces == null) {
        return null;
      }
      linePieces.last.addAll(suffixPieces);
    }

    return _storageBuilder.fromLinePieces(
      linePieces
          .map(List<_TextDocumentSourcePiece>.unmodifiable)
          .toList(growable: false),
      revision: 0,
    );
  }

  static ({List<int> lineLengths, int totalTextLength}) _computeLineTextStats(
    List<String> lineTexts,
  ) {
    final lineLengths = List<int>.filled(lineTexts.length, 0, growable: false);
    var totalTextLength = lineTexts.length > 1 ? lineTexts.length - 1 : 0;
    for (var index = 0; index < lineTexts.length; index++) {
      final line = lineTexts[index];
      totalTextLength += line.length;
      lineLengths[index] = line.characters.length;
    }
    return (
      lineLengths: List<int>.unmodifiable(lineLengths),
      totalTextLength: totalTextLength,
    );
  }
}

abstract interface class _TextDocumentStorageBuilder {
  const _TextDocumentStorageBuilder();

  _TextDocumentStorage fromText(
    String text, {
    required int revision,
    Object? storageIdentity,
  });

  _TextDocumentStorage fromLineTexts(
    List<String> lineTexts, {
    List<int>? lineLengths,
    required int revision,
    Object? storageIdentity,
  });

  _TextDocumentStorage fromParsedLines(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
    bool seedLineGraphemeCaches = true,
  });

  _TextDocumentStorage fromLinePieces(
    List<List<_TextDocumentSourcePiece>> linePieces, {
    required int revision,
    Object? storageIdentity,
  });

  _TextDocumentStorage fromSegments(
    List<_TextDocumentStorageSegment> segments, {
    required int revision,
    Object? storageIdentity,
  });

  _TextDocumentStorage optimizedFromText(
    String text, {
    required int revision,
    Object? storageIdentity,
  });

  _TextDocumentStorage optimizedFromLineTexts(
    List<String> lineTexts, {
    List<int>? lineLengths,
    required int revision,
    Object? storageIdentity,
  });
}

final class _ChunkedTextDocumentStorageBuilder
    implements _TextDocumentStorageBuilder {
  const _ChunkedTextDocumentStorageBuilder();

  @override
  _TextDocumentStorage fromText(
    String text, {
    required int revision,
    Object? storageIdentity,
  }) {
    if (text.isEmpty) {
      return _TextDocumentStorage._leafFromLineTexts(
        const <String>[''],
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return _TextDocumentStorage._buildStorageFromText(
      text,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  @override
  _TextDocumentStorage fromLineTexts(
    List<String> lineTexts, {
    List<int>? lineLengths,
    required int revision,
    Object? storageIdentity,
  }) {
    if (lineTexts.isEmpty) {
      return _TextDocumentStorage._leafFromLineTexts(
        const <String>[''],
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return _TextDocumentStorage._buildStorageFromLineTextsSource(
      lineTexts,
      lineLengths: lineLengths,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  @override
  _TextDocumentStorage fromParsedLines(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
    bool seedLineGraphemeCaches = true,
  }) {
    if (lines.length > _TextDocumentStorage._maxLeafLineCount) {
      return _TextDocumentStorage._buildStorageFromParsedLinesSource(
        lines,
        revision: revision,
        storageIdentity: storageIdentity,
        seedLineGraphemeCaches: seedLineGraphemeCaches,
      );
    }
    return _TextDocumentStorage._leafFromParsedLines(
      lines,
      revision: revision,
      storageIdentity: storageIdentity,
      seedLineGraphemeCaches: seedLineGraphemeCaches,
    );
  }

  @override
  _TextDocumentStorage fromLinePieces(
    List<List<_TextDocumentSourcePiece>> linePieces, {
    required int revision,
    Object? storageIdentity,
  }) {
    if (linePieces.isEmpty) {
      return fromLineTexts(
        const <String>[''],
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return _TextDocumentStorage._buildStorageFromLinePiecesSource(
      linePieces,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  @override
  _TextDocumentStorage fromSegments(
    List<_TextDocumentStorageSegment> segments, {
    required int revision,
    Object? storageIdentity,
  }) {
    final nonEmpty = _TextDocumentStorage._normalizeSegments(segments);
    if (nonEmpty.isEmpty) {
      return fromLineTexts(
        const <String>[''],
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    if (nonEmpty.length == 1) {
      return _TextDocumentStorage._storageFromSingleNormalizedSegment(
        nonEmpty.single,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    final totalLineCount = nonEmpty.fold<int>(
      0,
      (total, segment) => total + segment.lineCount,
    );
    final shouldCollapseIntoPieceBacked =
        totalLineCount <= _TextDocumentStorage._maxLeafLineCount ||
        nonEmpty.length >
            _TextDocumentStorage._pieceBackedCollapseSegmentThreshold;
    if (shouldCollapseIntoPieceBacked) {
      final pieceBacked =
          _TextDocumentStorage._buildStorageFromNormalizedSegmentPieces(
            nonEmpty,
            revision: revision,
            storageIdentity: storageIdentity,
          );
      if (pieceBacked != null) {
        return pieceBacked;
      }
    }
    if (nonEmpty.length > _TextDocumentStorage._maxCompositeSegmentCount) {
      return _TextDocumentStorage._buildBalancedComposite(
        nonEmpty,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return _TextDocumentStorage._buildComposite(
      nonEmpty,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  @override
  _TextDocumentStorage optimizedFromText(
    String text, {
    required int revision,
    Object? storageIdentity,
  }) {
    if (text.length >= TextDocument._sourceBackedReplacementTextThreshold) {
      return fromText(
        text,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    final lineTexts = TextDocument._parseLineTexts(text);
    if (lineTexts.length > _TextDocumentStorage._maxLeafLineCount) {
      return fromText(
        text,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return fromLineTexts(
      lineTexts,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  @override
  _TextDocumentStorage optimizedFromLineTexts(
    List<String> lineTexts, {
    List<int>? lineLengths,
    required int revision,
    Object? storageIdentity,
  }) {
    final replacementStats = lineLengths == null
        ? TextDocument._computeLineTextStats(lineTexts)
        : null;
    final normalizedLineLengths = lineLengths ?? replacementStats!.lineLengths;
    final totalTextLength =
        replacementStats?.totalTextLength ??
        lineTexts.fold<int>(
          lineTexts.length > 1 ? lineTexts.length - 1 : 0,
          (total, line) => total + line.length,
        );
    if (lineTexts.length > _TextDocumentStorage._maxLeafLineCount ||
        totalTextLength >= TextDocument._sourceBackedReplacementTextThreshold) {
      return _TextDocumentStorage._buildStorageFromLineTextsSource(
        lineTexts,
        lineLengths: normalizedLineLengths,
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    return fromLineTexts(
      lineTexts,
      lineLengths: normalizedLineLengths,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }
}

final class _TextDocumentSourcePiece {
  const _TextDocumentSourcePiece({
    required this.source,
    required this.sourceLine,
    required this.startColumn,
    required this.endColumn,
  });

  final _TextDocumentSource source;
  final int sourceLine;
  final int startColumn;
  final int endColumn;

  int get lineLength => endColumn - startColumn;
  int get textLength => source.textLengthInLineRange(
    sourceLine,
    startColumn: startColumn,
    endColumn: endColumn,
  );

  String? graphemeAt(int localColumn) =>
      source.graphemeInLineAt(sourceLine, startColumn + localColumn);

  List<String> graphemesInRange({
    required int startColumn,
    required int endColumn,
  }) => source.graphemesInLineRange(
    sourceLine,
    startColumn: this.startColumn + startColumn,
    endColumn: this.startColumn + endColumn,
  );

  String textInRange({required int startColumn, required int endColumn}) =>
      source.textInLineRange(
        sourceLine,
        startColumn: this.startColumn + startColumn,
        endColumn: this.startColumn + endColumn,
      );

  bool matchesGraphemes({
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) => source.matchesGraphemesInLineRange(
    sourceLine,
    startColumn: this.startColumn + startColumn,
    graphemes: graphemes,
    graphemeStart: graphemeStart,
    graphemeCount: graphemeCount,
  );

  void writeTextToBuffer(StringBuffer buffer) {
    buffer.write(
      source.textInLineRange(
        sourceLine,
        startColumn: startColumn,
        endColumn: endColumn,
      ),
    );
  }
}

List<_TextDocumentSourcePiece> _flattenSourcePieceRange(
  _TextDocumentSourcePiece piece, {
  required int startColumn,
  required int endColumn,
}) {
  if (piece.source case final _PieceTableTextDocumentSource pieceSource) {
    return pieceSource.piecesInLineRange(
      piece.sourceLine,
      startColumn: piece.startColumn + startColumn,
      endColumn: piece.startColumn + endColumn,
    );
  }
  return <_TextDocumentSourcePiece>[
    _TextDocumentSourcePiece(
      source: piece.source,
      sourceLine: piece.sourceLine,
      startColumn: piece.startColumn + startColumn,
      endColumn: piece.startColumn + endColumn,
    ),
  ];
}

abstract base class _TextDocumentSource {
  const _TextDocumentSource._({
    required this.lineStarts,
    required this.lineEnds,
    required this.lineLengths,
  });

  factory _TextDocumentSource.fromText(String text) {
    final lineStarts = <int>[];
    final lineEnds = <int>[];
    final lineLengths = <int>[];
    if (text.isEmpty) {
      lineStarts.add(0);
      lineEnds.add(0);
      lineLengths.add(0);
      return _RawTextDocumentSource._(
        rawText: text,
        lineStarts: List<int>.unmodifiable(lineStarts),
        lineEnds: List<int>.unmodifiable(lineEnds),
        lineLengths: List<int>.unmodifiable(lineLengths),
      );
    }
    var lineStart = 0;
    var graphemeLength = 0;
    var offset = 0;
    for (final grapheme in text.characters) {
      final graphemeWidth = grapheme.length;
      if (grapheme == '\n') {
        lineStarts.add(lineStart);
        lineEnds.add(offset);
        lineLengths.add(graphemeLength);
        lineStart = offset + graphemeWidth;
        graphemeLength = 0;
      } else {
        graphemeLength += 1;
      }
      offset += graphemeWidth;
    }
    lineStarts.add(lineStart);
    lineEnds.add(text.length);
    lineLengths.add(graphemeLength);
    return _RawTextDocumentSource._(
      rawText: text,
      lineStarts: List<int>.unmodifiable(lineStarts),
      lineEnds: List<int>.unmodifiable(lineEnds),
      lineLengths: List<int>.unmodifiable(lineLengths),
    );
  }

  factory _TextDocumentSource.fromLineTexts(
    List<String> lineTexts, {
    List<int>? lineLengths,
  }) {
    final normalizedLineLengths = lineLengths == null
        ? List<int>.unmodifiable(
            lineTexts
                .map((line) => line.characters.length)
                .toList(growable: false),
          )
        : List<int>.unmodifiable(lineLengths);
    final lineStarts = <int>[];
    final lineEnds = <int>[];
    var offset = 0;
    for (var index = 0; index < lineTexts.length; index++) {
      final line = lineTexts[index];
      lineStarts.add(offset);
      offset += line.length;
      lineEnds.add(offset);
      if (index < lineTexts.length - 1) {
        offset += 1;
      }
    }
    return _LineTextDocumentSource._(
      lineTexts: List<String>.unmodifiable(lineTexts),
      lineStarts: List<int>.unmodifiable(lineStarts),
      lineEnds: List<int>.unmodifiable(lineEnds),
      lineLengths: normalizedLineLengths,
    );
  }

  factory _TextDocumentSource.fromParsedLines(List<List<String>> parsedLines) {
    final normalizedParsedLines = List<List<String>>.unmodifiable(
      parsedLines
          .map((line) => List<String>.unmodifiable(line))
          .toList(growable: false),
    );
    final lineStarts = <int>[];
    final lineEnds = <int>[];
    final lineLengths = <int>[];
    var offset = 0;
    for (var index = 0; index < normalizedParsedLines.length; index++) {
      final line = normalizedParsedLines[index];
      lineStarts.add(offset);
      for (final grapheme in line) {
        offset += grapheme.length;
      }
      lineEnds.add(offset);
      lineLengths.add(line.length);
      if (index < normalizedParsedLines.length - 1) {
        offset += 1;
      }
    }
    return _ParsedLineDocumentSource._(
      parsedLines: normalizedParsedLines,
      lineStarts: List<int>.unmodifiable(lineStarts),
      lineEnds: List<int>.unmodifiable(lineEnds),
      lineLengths: List<int>.unmodifiable(lineLengths),
    );
  }

  factory _TextDocumentSource.fromLinePieces(
    List<List<_TextDocumentSourcePiece>> linePieces,
  ) {
    final normalizedLinePieces =
        List<List<_TextDocumentSourcePiece>>.unmodifiable(
          linePieces
              .map((line) => List<_TextDocumentSourcePiece>.unmodifiable(line))
              .toList(growable: false),
        );
    final lineStarts = <int>[];
    final lineEnds = <int>[];
    final lineLengths = <int>[];
    var offset = 0;
    for (var index = 0; index < normalizedLinePieces.length; index++) {
      final pieces = normalizedLinePieces[index];
      lineStarts.add(offset);
      final lineLength = pieces.fold<int>(
        0,
        (total, piece) => total + piece.lineLength,
      );
      offset += pieces.fold<int>(0, (total, piece) => total + piece.textLength);
      lineEnds.add(offset);
      lineLengths.add(lineLength);
      if (index < normalizedLinePieces.length - 1) {
        offset += 1;
      }
    }
    return _PieceTableTextDocumentSource._(
      linePieces: normalizedLinePieces,
      lineStarts: List<int>.unmodifiable(lineStarts),
      lineEnds: List<int>.unmodifiable(lineEnds),
      lineLengths: List<int>.unmodifiable(lineLengths),
    );
  }

  final List<int> lineStarts;
  final List<int> lineEnds;
  final List<int> lineLengths;

  int get lineCount => lineLengths.length;

  String get text;

  bool get debugHasJoinedTextCache;

  int get debugMaterializedLineTextCount;

  int debugReferencedSourceCount(Set<_TextDocumentSource> sources) {
    if (!sources.add(this)) {
      return 0;
    }
    return 1;
  }

  String lineAt(int index);

  List<String>? parsedLineAt(int index) => null;

  String? graphemeInLineAt(int index, int column) => null;

  List<String> graphemesInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    return lineAt(index).characters
        .skip(startColumn)
        .take(endColumn - startColumn)
        .toList(growable: false);
  }

  String textInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    final line = lineAt(index);
    if (startColumn <= 0 && endColumn >= lineLengths[index]) {
      return line;
    }
    return line.characters
        .skip(startColumn)
        .take(endColumn - startColumn)
        .toString();
  }

  int textLengthInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) => textInLineRange(
    index,
    startColumn: startColumn,
    endColumn: endColumn,
  ).length;

  String lineTextPrefix(int index, int graphemeCount) {
    final line = lineAt(index);
    if (graphemeCount >= lineLengths[index]) {
      return line;
    }
    return line.characters.take(graphemeCount).toString();
  }

  String lineTextSuffix(int index, int graphemeStart) {
    if (graphemeStart <= 0) {
      return lineAt(index);
    }
    return lineAt(index).characters.skip(graphemeStart).toString();
  }

  ({int start, int end}) wordBoundaryAt(int index, int column) {
    final graphemeAtCursor = graphemeInLineAt(index, column);
    if (graphemeAtCursor == null) {
      return (start: column, end: column);
    }

    if (TextDocument._isWhitespace(graphemeAtCursor)) {
      var start = column;
      while (start > 0) {
        final previous = graphemeInLineAt(index, start - 1);
        if (previous == null || !TextDocument._isWhitespace(previous)) {
          break;
        }
        start--;
      }

      var end = column;
      while (end < lineLengths[index]) {
        final current = graphemeInLineAt(index, end);
        if (current == null || !TextDocument._isWhitespace(current)) {
          break;
        }
        end++;
      }
      return (start: start, end: end);
    }

    var start = column;
    while (start > 0) {
      final previous = graphemeInLineAt(index, start - 1);
      if (previous == null || TextDocument._isWhitespace(previous)) {
        break;
      }
      start--;
    }

    var end = column;
    while (end < lineLengths[index]) {
      final current = graphemeInLineAt(index, end);
      if (current == null || TextDocument._isWhitespace(current)) {
        break;
      }
      end++;
    }
    return (start: start, end: end);
  }

  bool matchesGraphemesInLineRange(
    int index, {
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) {
    final iterator = lineAt(index).characters.skip(startColumn).iterator;
    for (var offset = 0; offset < graphemeCount; offset++) {
      if (!iterator.moveNext() ||
          iterator.current != graphemes[graphemeStart + offset]) {
        return false;
      }
    }
    return true;
  }

  String textBetweenLines({required int startLine, required int endLine}) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return '';
    }
    if (normalizedStart == 0 && normalizedEnd == lineCount) {
      return text;
    }
    final buffer = StringBuffer();
    writeTextBetweenLinesToBuffer(
      buffer,
      startLine: normalizedStart,
      endLine: normalizedEnd,
      leadingNewline: false,
    );
    return buffer.toString();
  }

  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  });

  int textEndForLineWindow(int endLine) {
    if (endLine >= lineCount) {
      return lineEnds.last;
    }
    return lineStarts[endLine] - 1;
  }

  String joinParsedLines(List<List<String>> parsedLines) {
    final buffer = StringBuffer();
    for (var index = 0; index < parsedLines.length; index++) {
      if (index > 0) {
        buffer.write('\n');
      }
      buffer.write(lineAt(index));
    }
    return buffer.toString();
  }
}

final class _RawTextDocumentSource extends _TextDocumentSource {
  _RawTextDocumentSource._({
    required String rawText,
    required super.lineStarts,
    required super.lineEnds,
    required super.lineLengths,
  }) : _rawText = rawText,
       super._();

  final String _rawText;
  List<List<int>?>? _graphemeOffsetsByLine;

  @override
  String get text => _rawText;

  @override
  bool get debugHasJoinedTextCache => false;

  @override
  int get debugMaterializedLineTextCount => 0;

  @override
  String lineAt(int index) {
    return _rawText.substring(lineStarts[index], lineEnds[index]);
  }

  List<int> _graphemeOffsetsForLine(int index) {
    final cache = _graphemeOffsetsByLine ??= List<List<int>?>.filled(
      lineCount,
      null,
      growable: false,
    );
    final existing = cache[index];
    if (existing != null) {
      return existing;
    }
    final start = lineStarts[index];
    final end = lineEnds[index];
    final line = _rawText.substring(start, end);
    final offsets = <int>[0];
    var offset = 0;
    for (final grapheme in line.characters) {
      offset += grapheme.length;
      offsets.add(offset);
    }
    final normalized = List<int>.unmodifiable(offsets);
    cache[index] = normalized;
    return normalized;
  }

  @override
  String? graphemeInLineAt(int index, int column) {
    if (column < 0 || column >= lineLengths[index]) {
      return null;
    }
    final offsets = _graphemeOffsetsForLine(index);
    final start = lineStarts[index] + offsets[column];
    final end = lineStarts[index] + offsets[column + 1];
    return _rawText.substring(start, end);
  }

  @override
  List<String> graphemesInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    final lineStart = lineStarts[index];
    final graphemes = List<String>.filled(
      endColumn - startColumn,
      '',
      growable: false,
    );
    for (var offset = 0; offset < graphemes.length; offset++) {
      final sourceStart = lineStart + offsets[startColumn + offset];
      final sourceEnd = lineStart + offsets[startColumn + offset + 1];
      graphemes[offset] = _rawText.substring(sourceStart, sourceEnd);
    }
    return List<String>.unmodifiable(graphemes);
  }

  @override
  String textInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    final start = lineStarts[index] + offsets[startColumn];
    final end = lineStarts[index] + offsets[endColumn];
    return _rawText.substring(start, end);
  }

  @override
  int textLengthInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    return offsets[endColumn] - offsets[startColumn];
  }

  @override
  String lineTextPrefix(int index, int graphemeCount) {
    if (graphemeCount <= 0) {
      return '';
    }
    if (graphemeCount >= lineLengths[index]) {
      return lineAt(index);
    }
    final offsets = _graphemeOffsetsForLine(index);
    final end = lineStarts[index] + offsets[graphemeCount];
    return _rawText.substring(lineStarts[index], end);
  }

  @override
  String lineTextSuffix(int index, int graphemeStart) {
    if (graphemeStart <= 0) {
      return lineAt(index);
    }
    if (graphemeStart >= lineLengths[index]) {
      return '';
    }
    final offsets = _graphemeOffsetsForLine(index);
    final start = lineStarts[index] + offsets[graphemeStart];
    return _rawText.substring(start, lineEnds[index]);
  }

  @override
  bool matchesGraphemesInLineRange(
    int index, {
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    final lineStart = lineStarts[index];
    for (var offset = 0; offset < graphemeCount; offset++) {
      final sourceStart = lineStart + offsets[startColumn + offset];
      final sourceEnd = lineStart + offsets[startColumn + offset + 1];
      if (_rawText.substring(sourceStart, sourceEnd) !=
          graphemes[graphemeStart + offset]) {
        return false;
      }
    }
    return true;
  }

  @override
  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return;
    }
    if (leadingNewline) {
      buffer.write('\n');
    }
    buffer.write(
      _rawText.substring(
        lineStarts[normalizedStart],
        textEndForLineWindow(normalizedEnd),
      ),
    );
  }
}

final class _LineTextDocumentSource extends _TextDocumentSource {
  _LineTextDocumentSource._({
    required List<String> lineTexts,
    required super.lineStarts,
    required super.lineEnds,
    required super.lineLengths,
  }) : _lineTexts = lineTexts,
       super._();

  _LineTextDocumentSource._appendable()
    : _lineTexts = <String>[],
      super._(lineStarts: <int>[], lineEnds: <int>[], lineLengths: <int>[]);

  final List<String> _lineTexts;
  String? _joinedText;
  List<List<int>?>? _graphemeOffsetsByLine;

  @override
  String get text => _joinedText ??= _lineTexts.join('\n');

  @override
  bool get debugHasJoinedTextCache => _joinedText != null;

  @override
  int get debugMaterializedLineTextCount => 0;

  @override
  String lineAt(int index) => _lineTexts[index];

  List<int> _graphemeOffsetsForLine(int index) {
    final cache = _graphemeOffsetsByLine ??= List<List<int>?>.filled(
      lineCount,
      null,
      growable: true,
    );
    final existing = cache[index];
    if (existing != null) {
      return existing;
    }
    final line = _lineTexts[index];
    final offsets = <int>[0];
    var offset = 0;
    for (final grapheme in line.characters) {
      offset += grapheme.length;
      offsets.add(offset);
    }
    final normalized = List<int>.unmodifiable(offsets);
    cache[index] = normalized;
    return normalized;
  }

  int appendLineTexts(
    List<String> lineTexts, {
    required List<int> lineLengths,
  }) {
    if (lineTexts.isEmpty) {
      return _lineTexts.length;
    }
    final startLine = _lineTexts.length;
    var offset = lineEnds.isEmpty ? 0 : lineEnds.last + 1;
    for (var index = 0; index < lineTexts.length; index++) {
      final line = lineTexts[index];
      _lineTexts.add(line);
      lineStarts.add(offset);
      offset += line.length;
      lineEnds.add(offset);
      this.lineLengths.add(lineLengths[index]);
      if (index < lineTexts.length - 1) {
        offset += 1;
      }
    }
    _joinedText = null;
    _graphemeOffsetsByLine?.addAll(
      List<List<int>?>.filled(lineTexts.length, null, growable: false),
    );
    return startLine;
  }

  @override
  String? graphemeInLineAt(int index, int column) {
    if (column < 0 || column >= lineLengths[index]) {
      return null;
    }
    final offsets = _graphemeOffsetsForLine(index);
    final line = _lineTexts[index];
    return line.substring(offsets[column], offsets[column + 1]);
  }

  @override
  List<String> graphemesInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    final line = _lineTexts[index];
    final graphemes = List<String>.filled(
      endColumn - startColumn,
      '',
      growable: false,
    );
    for (var offset = 0; offset < graphemes.length; offset++) {
      graphemes[offset] = line.substring(
        offsets[startColumn + offset],
        offsets[startColumn + offset + 1],
      );
    }
    return List<String>.unmodifiable(graphemes);
  }

  @override
  String textInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    final line = _lineTexts[index];
    return line.substring(offsets[startColumn], offsets[endColumn]);
  }

  @override
  int textLengthInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    return offsets[endColumn] - offsets[startColumn];
  }

  @override
  String lineTextPrefix(int index, int graphemeCount) {
    if (graphemeCount <= 0) {
      return '';
    }
    final line = _lineTexts[index];
    if (graphemeCount >= lineLengths[index]) {
      return line;
    }
    final offsets = _graphemeOffsetsForLine(index);
    return line.substring(0, offsets[graphemeCount]);
  }

  @override
  String lineTextSuffix(int index, int graphemeStart) {
    if (graphemeStart <= 0) {
      return _lineTexts[index];
    }
    if (graphemeStart >= lineLengths[index]) {
      return '';
    }
    final offsets = _graphemeOffsetsForLine(index);
    final line = _lineTexts[index];
    return line.substring(offsets[graphemeStart]);
  }

  @override
  bool matchesGraphemesInLineRange(
    int index, {
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) {
    final offsets = _graphemeOffsetsForLine(index);
    final line = _lineTexts[index];
    for (var offset = 0; offset < graphemeCount; offset++) {
      if (line.substring(
            offsets[startColumn + offset],
            offsets[startColumn + offset + 1],
          ) !=
          graphemes[graphemeStart + offset]) {
        return false;
      }
    }
    return true;
  }

  @override
  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return;
    }
    for (var index = normalizedStart; index < normalizedEnd; index++) {
      if (leadingNewline || index > normalizedStart) {
        buffer.write('\n');
      }
      buffer.write(_lineTexts[index]);
    }
  }
}

final class _ParsedLineDocumentSource extends _TextDocumentSource {
  _ParsedLineDocumentSource._({
    required List<List<String>> parsedLines,
    required super.lineStarts,
    required super.lineEnds,
    required super.lineLengths,
  }) : _parsedLines = parsedLines,
       super._();

  final List<List<String>> _parsedLines;
  List<String?>? _materializedParsedLineTexts;
  String? _joinedText;

  @override
  String get text => _joinedText ??= joinParsedLines(_parsedLines);

  @override
  bool get debugHasJoinedTextCache => _joinedText != null;

  @override
  int get debugMaterializedLineTextCount =>
      _materializedParsedLineTexts?.whereType<String>().length ?? 0;

  @override
  String lineAt(int index) {
    final cache = _materializedParsedLineTexts ??= List<String?>.filled(
      _parsedLines.length,
      null,
      growable: false,
    );
    return cache[index] ??= _parsedLines[index].join();
  }

  @override
  List<String>? parsedLineAt(int index) => _parsedLines[index];

  @override
  int textLengthInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    var total = 0;
    for (var column = startColumn; column < endColumn; column++) {
      total += _parsedLines[index][column].length;
    }
    return total;
  }

  @override
  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return;
    }
    for (var index = normalizedStart; index < normalizedEnd; index++) {
      if (leadingNewline || index > normalizedStart) {
        buffer.write('\n');
      }
      for (final grapheme in _parsedLines[index]) {
        buffer.write(grapheme);
      }
    }
  }
}

final class _PieceTableTextDocumentSource extends _TextDocumentSource {
  _PieceTableTextDocumentSource._({
    required List<List<_TextDocumentSourcePiece>> linePieces,
    required super.lineStarts,
    required super.lineEnds,
    required super.lineLengths,
  }) : _linePieces = linePieces,
       super._();

  final List<List<_TextDocumentSourcePiece>> _linePieces;
  List<String?>? _materializedLineTexts;
  String? _joinedText;

  @override
  String get text => _joinedText ??= (() {
    final buffer = StringBuffer();
    writeTextBetweenLinesToBuffer(
      buffer,
      startLine: 0,
      endLine: lineCount,
      leadingNewline: false,
    );
    return buffer.toString();
  })();

  @override
  bool get debugHasJoinedTextCache => _joinedText != null;

  @override
  int get debugMaterializedLineTextCount =>
      _materializedLineTexts?.whereType<String>().length ?? 0;

  @override
  int debugReferencedSourceCount(Set<_TextDocumentSource> sources) {
    if (!sources.add(this)) {
      return 0;
    }
    var total = 1;
    for (final line in _linePieces) {
      for (final piece in line) {
        total += piece.source.debugReferencedSourceCount(sources);
      }
    }
    return total;
  }

  int get debugPieceCount {
    var total = 0;
    for (final line in _linePieces) {
      for (final piece in line) {
        if (piece.source case final _PieceTableTextDocumentSource pieceSource) {
          total += pieceSource.debugPieceCount;
        } else {
          total += 1;
        }
      }
    }
    return total;
  }

  List<_TextDocumentSourcePiece> piecesInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    if (startColumn >= endColumn) {
      return const <_TextDocumentSourcePiece>[];
    }
    final result = <_TextDocumentSourcePiece>[];
    var remainingStart = startColumn;
    var remainingCount = endColumn - startColumn;
    for (final piece in _linePieces[index]) {
      if (remainingCount <= 0) {
        break;
      }
      if (remainingStart >= piece.lineLength) {
        remainingStart -= piece.lineLength;
        continue;
      }
      final localStart = remainingStart;
      final localEnd = (localStart + remainingCount).clamp(0, piece.lineLength);
      result.addAll(
        _flattenSourcePieceRange(
          piece,
          startColumn: localStart,
          endColumn: localEnd,
        ),
      );
      remainingCount -= localEnd - localStart;
      remainingStart = 0;
    }
    return List<_TextDocumentSourcePiece>.unmodifiable(result);
  }

  @override
  String lineAt(int index) {
    final cache = _materializedLineTexts ??= List<String?>.filled(
      lineCount,
      null,
      growable: false,
    );
    final existing = cache[index];
    if (existing != null) {
      return existing;
    }
    final buffer = StringBuffer();
    for (final piece in _linePieces[index]) {
      piece.writeTextToBuffer(buffer);
    }
    final value = buffer.toString();
    cache[index] = value;
    return value;
  }

  @override
  String? graphemeInLineAt(int index, int column) {
    if (column < 0 || column >= lineLengths[index]) {
      return null;
    }
    var remaining = column;
    for (final piece in _linePieces[index]) {
      if (remaining < piece.lineLength) {
        return piece.graphemeAt(remaining);
      }
      remaining -= piece.lineLength;
    }
    return null;
  }

  @override
  List<String> graphemesInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    if (startColumn >= endColumn) {
      return const <String>[];
    }
    final result = <String>[];
    var remainingStart = startColumn;
    var remainingCount = endColumn - startColumn;
    for (final piece in _linePieces[index]) {
      if (remainingCount <= 0) {
        break;
      }
      if (remainingStart >= piece.lineLength) {
        remainingStart -= piece.lineLength;
        continue;
      }
      final localStart = remainingStart;
      final localEnd = (localStart + remainingCount).clamp(0, piece.lineLength);
      result.addAll(
        piece.graphemesInRange(startColumn: localStart, endColumn: localEnd),
      );
      remainingCount -= localEnd - localStart;
      remainingStart = 0;
    }
    return List<String>.unmodifiable(result);
  }

  @override
  String textInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    if (startColumn >= endColumn) {
      return '';
    }
    final buffer = StringBuffer();
    var remainingStart = startColumn;
    var remainingCount = endColumn - startColumn;
    for (final piece in _linePieces[index]) {
      if (remainingCount <= 0) {
        break;
      }
      if (remainingStart >= piece.lineLength) {
        remainingStart -= piece.lineLength;
        continue;
      }
      final localStart = remainingStart;
      final localEnd = (localStart + remainingCount).clamp(0, piece.lineLength);
      buffer.write(
        piece.textInRange(startColumn: localStart, endColumn: localEnd),
      );
      remainingCount -= localEnd - localStart;
      remainingStart = 0;
    }
    return buffer.toString();
  }

  @override
  int textLengthInLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    if (startColumn >= endColumn) {
      return 0;
    }
    var total = 0;
    var remainingStart = startColumn;
    var remainingCount = endColumn - startColumn;
    for (final piece in _linePieces[index]) {
      if (remainingCount <= 0) {
        break;
      }
      if (remainingStart >= piece.lineLength) {
        remainingStart -= piece.lineLength;
        continue;
      }
      final localStart = remainingStart;
      final localEnd = (localStart + remainingCount).clamp(0, piece.lineLength);
      total += piece.source.textLengthInLineRange(
        piece.sourceLine,
        startColumn: piece.startColumn + localStart,
        endColumn: piece.startColumn + localEnd,
      );
      remainingCount -= localEnd - localStart;
      remainingStart = 0;
    }
    return total;
  }

  @override
  bool matchesGraphemesInLineRange(
    int index, {
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) {
    var remainingStart = startColumn;
    var matched = 0;
    for (final piece in _linePieces[index]) {
      if (matched >= graphemeCount) {
        break;
      }
      if (remainingStart >= piece.lineLength) {
        remainingStart -= piece.lineLength;
        continue;
      }
      final localStart = remainingStart;
      final localCount = (piece.lineLength - localStart).clamp(
        0,
        graphemeCount - matched,
      );
      if (!piece.matchesGraphemes(
        startColumn: localStart,
        graphemes: graphemes,
        graphemeStart: graphemeStart + matched,
        graphemeCount: localCount,
      )) {
        return false;
      }
      matched += localCount;
      remainingStart = 0;
    }
    return matched == graphemeCount;
  }

  @override
  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return;
    }
    for (var index = normalizedStart; index < normalizedEnd; index++) {
      if (leadingNewline || index > normalizedStart) {
        buffer.write('\n');
      }
      for (final piece in _linePieces[index]) {
        piece.writeTextToBuffer(buffer);
      }
    }
  }
}

final class _TextDocumentSourceSlice {
  _TextDocumentSourceSlice({
    required this.source,
    required this.startLine,
    required this.endLine,
  }) : assert(startLine >= 0),
       assert(endLine >= startLine),
       assert(endLine <= source.lineCount),
       lineLengths = List<int>.unmodifiable(
         source.lineLengths.sublist(startLine, endLine),
       );

  final _TextDocumentSource source;
  final int startLine;
  final int endLine;
  final List<int> lineLengths;

  int get lineCount => endLine - startLine;

  int get length =>
      _TextDocumentStorage._documentLengthForLineLengths(lineLengths);

  String get text => startLine == 0 && endLine == source.lineCount
      ? source.text
      : source.textBetweenLines(startLine: startLine, endLine: endLine);

  String lineAt(int localIndex) => source.lineAt(startLine + localIndex);

  List<String>? parsedLineAt(int localIndex) =>
      source.parsedLineAt(startLine + localIndex);

  String? graphemeInLineAt(int localIndex, int column) =>
      source.graphemeInLineAt(startLine + localIndex, column);

  List<String> graphemesInLineRange(
    int localIndex, {
    required int startColumn,
    required int endColumn,
  }) => source.graphemesInLineRange(
    startLine + localIndex,
    startColumn: startColumn,
    endColumn: endColumn,
  );

  String textInLineRange(
    int localIndex, {
    required int startColumn,
    required int endColumn,
  }) => source.textInLineRange(
    startLine + localIndex,
    startColumn: startColumn,
    endColumn: endColumn,
  );

  String lineTextPrefix(int localIndex, int graphemeCount) =>
      source.lineTextPrefix(startLine + localIndex, graphemeCount);

  String lineTextSuffix(int localIndex, int graphemeStart) =>
      source.lineTextSuffix(startLine + localIndex, graphemeStart);

  bool matchesGraphemesInLineRange(
    int localIndex, {
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) => source.matchesGraphemesInLineRange(
    startLine + localIndex,
    startColumn: startColumn,
    graphemes: graphemes,
    graphemeStart: graphemeStart,
    graphemeCount: graphemeCount,
  );

  ({int start, int end}) wordBoundaryAt(int localIndex, int column) =>
      source.wordBoundaryAt(startLine + localIndex, column);

  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    source.writeTextBetweenLinesToBuffer(
      buffer,
      startLine: this.startLine + startLine,
      endLine: this.startLine + endLine,
      leadingNewline: leadingNewline,
    );
  }

  _TextDocumentSourceSlice slice(int startLine, int endLine) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    return _TextDocumentSourceSlice(
      source: source,
      startLine: this.startLine + normalizedStart,
      endLine: this.startLine + normalizedEnd,
    );
  }
}

abstract base class _TextDocumentLeafBacking {
  const _TextDocumentLeafBacking._();

  List<int> get lineLengths;

  int get lineCount => lineLengths.length;

  int get length =>
      _TextDocumentStorage._documentLengthForLineLengths(lineLengths);

  String get text;

  List<String>? get inlineLineTexts => null;

  _TextDocumentSourceSlice? get sourceSlice => null;

  _TextDocumentSource? get source => sourceSlice?.source;

  String lineAt(int index);

  List<String>? parsedLineAt(int index) => null;

  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  });

  _TextDocumentLeafBacking slice(int startLine, int endLine);
}

final class _InlineTextDocumentLeafBacking extends _TextDocumentLeafBacking {
  _InlineTextDocumentLeafBacking({
    required List<String> lineTexts,
    required List<int> lineLengths,
  }) : _lineTexts = List<String>.unmodifiable(lineTexts),
       _lineLengths = List<int>.unmodifiable(lineLengths),
       super._();

  final List<String> _lineTexts;
  final List<int> _lineLengths;

  @override
  List<int> get lineLengths => _lineLengths;

  @override
  String get text => _lineTexts.join('\n');

  @override
  List<String>? get inlineLineTexts => _lineTexts;

  @override
  String lineAt(int index) => _lineTexts[index];

  @override
  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return;
    }
    for (var index = normalizedStart; index < normalizedEnd; index++) {
      if (leadingNewline || index > normalizedStart) {
        buffer.write('\n');
      }
      buffer.write(_lineTexts[index]);
    }
  }

  @override
  _TextDocumentLeafBacking slice(int startLine, int endLine) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    return _InlineTextDocumentLeafBacking(
      lineTexts: _lineTexts.sublist(normalizedStart, normalizedEnd),
      lineLengths: _lineLengths.sublist(normalizedStart, normalizedEnd),
    );
  }
}

final class _SourceSliceTextDocumentLeafBacking
    extends _TextDocumentLeafBacking {
  _SourceSliceTextDocumentLeafBacking({
    required _TextDocumentSourceSlice sourceSlice,
  }) : _sourceSlice = sourceSlice,
       super._();

  final _TextDocumentSourceSlice _sourceSlice;

  @override
  List<int> get lineLengths => _sourceSlice.lineLengths;

  @override
  String get text => _sourceSlice.text;

  @override
  _TextDocumentSourceSlice? get sourceSlice => _sourceSlice;

  @override
  String lineAt(int index) => _sourceSlice.lineAt(index);

  @override
  List<String>? parsedLineAt(int index) => _sourceSlice.parsedLineAt(index);

  @override
  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    _sourceSlice.writeTextBetweenLinesToBuffer(
      buffer,
      startLine: startLine,
      endLine: endLine,
      leadingNewline: leadingNewline,
    );
  }

  @override
  _TextDocumentLeafBacking slice(int startLine, int endLine) {
    return _SourceSliceTextDocumentLeafBacking(
      sourceSlice: _sourceSlice.slice(startLine, endLine),
    );
  }
}

final class _TextDocumentCompositeBacking {
  _TextDocumentCompositeBacking({
    required List<_TextDocumentStorageSegment> segments,
  }) : _segments = List<_TextDocumentStorageSegment>.unmodifiable(segments),
       _segmentLineStarts = _TextDocumentStorage._computeSegmentLineStarts(
         segments,
       ),
       _segmentStartOffsets = _TextDocumentStorage._computeSegmentStartOffsets(
         segments,
       );

  final List<_TextDocumentStorageSegment> _segments;
  final List<int> _segmentLineStarts;
  final List<int> _segmentStartOffsets;

  List<_TextDocumentStorageSegment> get segments => _segments;

  List<int> get segmentLineStarts => _segmentLineStarts;

  List<int> get segmentStartOffsets => _segmentStartOffsets;

  (_TextDocumentStorageSegment, int) segmentForLine(int index) {
    final (segment, localIndex, _) = segmentForLineWithIndex(index);
    return (segment, localIndex);
  }

  (_TextDocumentStorageSegment, int, int) segmentForLineWithIndex(int index) {
    var low = 0;
    var high = _segments.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_segmentLineStarts[mid] <= index) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    final segmentIndex = low;
    final segment = _segments[segmentIndex];
    return (segment, index - _segmentLineStarts[segmentIndex], segmentIndex);
  }

  (_TextDocumentStorageSegment, int) segmentForOffset(int offset) {
    var low = 0;
    var high = _segments.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_segmentStartOffsets[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return (_segments[low], low);
  }

  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    final (_, _, startSegmentIndex) = segmentForLineWithIndex(startLine);
    var segmentIndex = startSegmentIndex;
    var wroteAnyLine = false;
    while (segmentIndex < _segments.length) {
      final segment = _segments[segmentIndex];
      final segmentStartLine = _segmentLineStarts[segmentIndex];
      if (segmentStartLine >= endLine) {
        break;
      }
      final segmentEndLine = segmentStartLine + segment.lineCount;
      final localStart = startLine > segmentStartLine
          ? startLine - segmentStartLine
          : 0;
      final localEnd = endLine < segmentEndLine
          ? endLine - segmentStartLine
          : segment.lineCount;
      if (localStart < localEnd) {
        segment.writeTextRangeToBuffer(
          buffer,
          startLocalLine: localStart,
          endLocalLine: localEnd,
          leadingNewline: leadingNewline || wroteAnyLine,
        );
        wroteAnyLine = true;
      }
      segmentIndex += 1;
    }
  }
}

final class _TextDocumentStorage {
  static const int _maxLeafLineCount = 256;
  static const int _maxCompositeSegmentCount = 32;
  static const int _pieceBackedCollapseSegmentThreshold = 4;

  _TextDocumentStorage._leaf({
    required _TextDocumentLeafBacking leafBacking,
    required this.length,
    required this.revision,
    required this.storageIdentity,
    Map<int, List<String>>? lineGraphemeCaches,
  }) : _leafBacking = leafBacking,
       _compositeBacking = null,
       lineCount = leafBacking.lineCount,
       _lineGraphemeCaches = lineGraphemeCaches ?? <int, List<String>>{};

  _TextDocumentStorage._composite({
    required List<_TextDocumentStorageSegment> segments,
    required this.lineCount,
    required this.length,
    required this.revision,
    required this.storageIdentity,
  }) : _leafBacking = null,
       _compositeBacking = _TextDocumentCompositeBacking(segments: segments),
       _lineGraphemeCaches = <int, List<String>>{};

  final int lineCount;
  final int length;
  final int revision;
  final Object storageIdentity;
  final _TextDocumentLeafBacking? _leafBacking;
  final _TextDocumentCompositeBacking? _compositeBacking;
  final Map<int, List<String>> _lineGraphemeCaches;
  List<String>? _cachedLineTexts;
  List<int>? _cachedLineLengths;
  List<int>? _cachedLineStartOffsets;
  String? _cachedText;
  List<String>? _cachedFlattenedGraphemes;
  List<List<String>>? _cachedLineViews;

  int get debugDepth {
    final segments = _compositeBacking?.segments;
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

  int get debugSegmentCount => _compositeBacking?.segments.length ?? 1;

  int get debugLineGraphemeCacheCount =>
      _debugLineGraphemeCacheCount(<_TextDocumentStorage>{});

  int get debugSourceBackedLeafCount =>
      _debugSourceBackedLeafCount(<_TextDocumentStorage>{});

  int get debugPieceBackedLeafCount =>
      _debugPieceBackedLeafCount(<_TextDocumentStorage>{});

  int get debugPieceCount => _debugPieceCount(<_TextDocumentStorage>{});

  int get debugDistinctSourceCount => _debugDistinctSourceCount(
    <_TextDocumentStorage>{},
    <_TextDocumentSource>{},
  );

  int get debugReferencedSourceCount => _debugReferencedSourceCount(
    <_TextDocumentStorage>{},
    <_TextDocumentSource>{},
  );

  int get debugJoinedSourceTextCount => _debugJoinedSourceTextCount(
    <_TextDocumentStorage>{},
    <_TextDocumentSource>{},
  );

  int get debugMaterializedSourceLineTextCount =>
      _debugMaterializedSourceLineTextCount(
        <_TextDocumentStorage>{},
        <_TextDocumentSource>{},
      );

  bool get debugHasMaterializedLineTextCache => _cachedLineTexts != null;

  bool get debugHasTextCache => _cachedText != null;

  List<String> get lineTexts => _cachedLineTexts ??=
      _leafBacking?.inlineLineTexts ?? _materializeLineTexts();

  List<int> get lineLengths => _cachedLineLengths ??=
      _leafBacking?.lineLengths ?? _materializeLineLengths();

  List<int> get lineStartOffsets =>
      _cachedLineStartOffsets ??= _computeLineStartOffsets(lineLengths);

  String get text => _cachedText ??= _buildText();

  String textBetweenLines({required int startLine, required int endLine}) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return '';
    }
    if (normalizedStart == 0 && normalizedEnd == lineCount) {
      return text;
    }
    final buffer = StringBuffer();
    if (_leafBacking case final leafBacking?) {
      leafBacking.writeTextBetweenLinesToBuffer(
        buffer,
        startLine: normalizedStart,
        endLine: normalizedEnd,
        leadingNewline: false,
      );
    } else {
      writeTextBetweenLinesToBuffer(
        buffer,
        startLine: normalizedStart,
        endLine: normalizedEnd,
        leadingNewline: false,
      );
    }
    return buffer.toString();
  }

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
    if (_leafBacking case final leafBacking?) {
      return leafBacking.lineAt(index);
    }
    final (segment, localIndex) = _segmentForLine(index);
    return segment.lineAt(localIndex);
  }

  int lineLength(int index) {
    if (index < 0 || index >= lineCount) {
      return 0;
    }
    if (_leafBacking case final leafBacking?) {
      return leafBacking.lineLengths[index];
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
    if (_leafBacking != null) {
      return lineStartOffsets[index];
    }
    final compositeBacking = _compositeBacking!;
    final (segment, localIndex, segmentIndex) = _segmentForLineWithIndex(index);
    return compositeBacking.segmentStartOffsets[segmentIndex] +
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
    if (_leafBacking != null) {
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

    final compositeBacking = _compositeBacking!;
    final (segment, segmentIndex) = _segmentForOffset(clamped);
    final localOffset =
        clamped - compositeBacking.segmentStartOffsets[segmentIndex];
    final localPosition = segment.positionForOffset(localOffset);
    return TextPosition(
      line:
          compositeBacking.segmentLineStarts[segmentIndex] + localPosition.line,
      column: localPosition.column,
    );
  }

  List<String> lineGraphemesAt(int index) {
    if (index < 0 || index >= lineCount) {
      return const <String>[];
    }
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.lineGraphemesAt(localIndex);
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      return _lineGraphemeCaches[index] ??= sourceParsedLine;
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return _lineGraphemeCaches[index] ??= sourceSlice.graphemesInLineRange(
        index,
        startColumn: 0,
        endColumn: lineLength(index),
      );
    }
    return _lineGraphemeCaches[index] ??= List<String>.unmodifiable(
      lineAt(index).characters.toList(growable: false),
    );
  }

  String? graphemeInLineAt(int index, int column) {
    if (index < 0 || index >= lineCount) {
      return null;
    }
    final lineLength = this.lineLength(index);
    if (column < 0 || column >= lineLength) {
      return null;
    }
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.graphemeInLineAt(localIndex, column);
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      return cached[column];
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      return sourceParsedLine[column];
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return sourceSlice.graphemeInLineAt(index, column);
    }
    return lineAt(index).characters.skip(column).first;
  }

  List<_TextDocumentSourcePiece>? sourcePiecesForLineRange(
    int index, {
    required int startColumn,
    required int endColumn,
  }) {
    if (index < 0 || index >= lineCount) {
      return null;
    }
    final lineLength = this.lineLength(index);
    final normalizedStart = startColumn.clamp(0, lineLength);
    final normalizedEnd = endColumn.clamp(normalizedStart, lineLength);
    if (normalizedStart == normalizedEnd) {
      return null;
    }
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.sourcePiecesForLineRange(
        localIndex,
        startColumn: normalizedStart,
        endColumn: normalizedEnd,
      );
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice == null) {
      return null;
    }
    final source = sourceSlice.source;
    if (source case final _PieceTableTextDocumentSource pieceSource) {
      return pieceSource.piecesInLineRange(
        sourceSlice.startLine + index,
        startColumn: normalizedStart,
        endColumn: normalizedEnd,
      );
    }
    return <_TextDocumentSourcePiece>[
      _TextDocumentSourcePiece(
        source: source,
        sourceLine: sourceSlice.startLine + index,
        startColumn: normalizedStart,
        endColumn: normalizedEnd,
      ),
    ];
  }

  String lineTextPrefix(int index, int graphemeCount) {
    if (index < 0 || index >= lineCount) {
      return '';
    }
    final totalLineLength = lineLength(index);
    final clampedCount = graphemeCount.clamp(0, totalLineLength);
    if (clampedCount <= 0) {
      return '';
    }
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.lineTextPrefix(localIndex, clampedCount);
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      if (clampedCount >= totalLineLength) {
        return cached.join();
      }
      return cached.take(clampedCount).join();
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      if (clampedCount >= totalLineLength) {
        return sourceParsedLine.join();
      }
      return sourceParsedLine.take(clampedCount).join();
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return sourceSlice.lineTextPrefix(index, clampedCount);
    }
    final line = lineAt(index);
    if (clampedCount >= totalLineLength) {
      return line;
    }
    return line.characters.take(clampedCount).toString();
  }

  String lineTextSuffix(int index, int graphemeStart) {
    if (index < 0 || index >= lineCount) {
      return '';
    }
    final totalLineLength = lineLength(index);
    final clampedStart = graphemeStart.clamp(0, totalLineLength);
    if (clampedStart <= 0) {
      final cached = _lineGraphemeCaches[index];
      if (cached != null) {
        return cached.join();
      }
      final sourceParsedLine = _sourceParsedLineAt(index);
      if (sourceParsedLine != null) {
        return sourceParsedLine.join();
      }
      return lineAt(index);
    }
    if (clampedStart >= totalLineLength) {
      return '';
    }
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.lineTextSuffix(localIndex, clampedStart);
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      return cached.skip(clampedStart).join();
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      return sourceParsedLine.skip(clampedStart).join();
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return sourceSlice.lineTextSuffix(index, clampedStart);
    }
    final line = lineAt(index);
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
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.graphemesInLineRange(
        localIndex,
        startColumn: normalizedStart,
        endColumn: normalizedEnd,
      );
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      return List<String>.unmodifiable(
        cached.sublist(normalizedStart, normalizedEnd),
      );
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      return List<String>.unmodifiable(
        sourceParsedLine.sublist(normalizedStart, normalizedEnd),
      );
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return sourceSlice.graphemesInLineRange(
        index,
        startColumn: normalizedStart,
        endColumn: normalizedEnd,
      );
    }
    return lineAt(index).characters
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
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.textInLineRange(
        localIndex,
        startColumn: normalizedStart,
        endColumn: normalizedEnd,
      );
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      if (normalizedStart == 0 && normalizedEnd == lineLength) {
        return cached.join();
      }
      return cached.sublist(normalizedStart, normalizedEnd).join();
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      if (normalizedStart == 0 && normalizedEnd == lineLength) {
        return sourceParsedLine.join();
      }
      return sourceParsedLine.sublist(normalizedStart, normalizedEnd).join();
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return sourceSlice.textInLineRange(
        index,
        startColumn: normalizedStart,
        endColumn: normalizedEnd,
      );
    }
    if (normalizedStart == 0 && normalizedEnd == lineLength) {
      return lineAt(index);
    }
    return lineAt(index).characters
        .skip(normalizedStart)
        .take(normalizedEnd - normalizedStart)
        .toString();
  }

  ({int start, int end}) wordBoundaryAtInLine(int index, int column) {
    if (index < 0 || index >= lineCount) {
      return (start: column, end: column);
    }
    final totalLineLength = lineLength(index);
    if (totalLineLength == 0) {
      return (start: 0, end: 0);
    }
    final normalizedColumn = column.clamp(0, totalLineLength - 1);
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.wordBoundaryAtInLine(localIndex, normalizedColumn);
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      if (TextDocument._isWhitespace(cached[normalizedColumn])) {
        var start = normalizedColumn;
        while (start > 0 && TextDocument._isWhitespace(cached[start - 1])) {
          start--;
        }
        var end = normalizedColumn;
        while (end < totalLineLength &&
            TextDocument._isWhitespace(cached[end])) {
          end++;
        }
        return (start: start, end: end);
      }

      var start = normalizedColumn;
      while (start > 0 && !TextDocument._isWhitespace(cached[start - 1])) {
        start--;
      }
      var end = normalizedColumn;
      while (end < totalLineLength &&
          !TextDocument._isWhitespace(cached[end])) {
        end++;
      }
      return (start: start, end: end);
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      if (TextDocument._isWhitespace(sourceParsedLine[normalizedColumn])) {
        var start = normalizedColumn;
        while (start > 0 &&
            TextDocument._isWhitespace(sourceParsedLine[start - 1])) {
          start--;
        }
        var end = normalizedColumn;
        while (end < totalLineLength &&
            TextDocument._isWhitespace(sourceParsedLine[end])) {
          end++;
        }
        return (start: start, end: end);
      }

      var start = normalizedColumn;
      while (start > 0 &&
          !TextDocument._isWhitespace(sourceParsedLine[start - 1])) {
        start--;
      }
      var end = normalizedColumn;
      while (end < totalLineLength &&
          !TextDocument._isWhitespace(sourceParsedLine[end])) {
        end++;
      }
      return (start: start, end: end);
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return sourceSlice.wordBoundaryAt(index, normalizedColumn);
    }

    final lineText = lineAt(index);
    final prefix = lineText.characters
        .take(normalizedColumn + 1)
        .toList(growable: false);
    final graphemeAtCursor = prefix.last;
    if (TextDocument._isWhitespace(graphemeAtCursor)) {
      var start = normalizedColumn;
      while (start > 0 && TextDocument._isWhitespace(prefix[start - 1])) {
        start--;
      }
      var end = normalizedColumn;
      final suffix = lineText.characters.skip(normalizedColumn).iterator;
      while (suffix.moveNext() && TextDocument._isWhitespace(suffix.current)) {
        end++;
      }
      return (start: start, end: end);
    }

    var start = normalizedColumn;
    while (start > 0 && !TextDocument._isWhitespace(prefix[start - 1])) {
      start--;
    }
    var end = normalizedColumn;
    final suffix = lineText.characters.skip(normalizedColumn).iterator;
    while (suffix.moveNext() && !TextDocument._isWhitespace(suffix.current)) {
      end++;
    }
    return (start: start, end: end);
  }

  bool matchesGraphemesInLineRange(
    int index, {
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) {
    if (index < 0 || index >= lineCount) {
      return graphemeCount == 0;
    }
    final lineLength = this.lineLength(index);
    final normalizedStart = startColumn.clamp(0, lineLength);
    final normalizedCount = graphemeCount.clamp(
      0,
      lineLength - normalizedStart,
    );
    if (normalizedCount == 0) {
      return true;
    }
    if (_compositeBacking != null) {
      final (segment, localIndex) = _segmentForLine(index);
      return segment.matchesGraphemesInLineRange(
        localIndex,
        startColumn: normalizedStart,
        graphemes: graphemes,
        graphemeStart: graphemeStart,
        graphemeCount: normalizedCount,
      );
    }
    final cached = _lineGraphemeCaches[index];
    if (cached != null) {
      for (var offset = 0; offset < normalizedCount; offset++) {
        if (cached[normalizedStart + offset] !=
            graphemes[graphemeStart + offset]) {
          return false;
        }
      }
      return true;
    }
    final sourceParsedLine = _sourceParsedLineAt(index);
    if (sourceParsedLine != null) {
      for (var offset = 0; offset < normalizedCount; offset++) {
        if (sourceParsedLine[normalizedStart + offset] !=
            graphemes[graphemeStart + offset]) {
          return false;
        }
      }
      return true;
    }
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice != null) {
      return sourceSlice.matchesGraphemesInLineRange(
        index,
        startColumn: normalizedStart,
        graphemes: graphemes,
        graphemeStart: graphemeStart,
        graphemeCount: normalizedCount,
      );
    }
    final iterator = lineAt(index).characters.skip(normalizedStart).iterator;
    for (var offset = 0; offset < normalizedCount; offset++) {
      if (!iterator.moveNext() ||
          iterator.current != graphemes[graphemeStart + offset]) {
        return false;
      }
    }
    return true;
  }

  List<List<String>> get lineViews =>
      _cachedLineViews ??= List<List<String>>.unmodifiable(
        List<List<String>>.generate(
          lineCount,
          lineGraphemesAt,
          growable: false,
        ),
      );

  List<String>? _sourceParsedLineAt(int index) {
    final sourceSlice = _leafBacking?.sourceSlice;
    if (sourceSlice == null) {
      return null;
    }
    return sourceSlice.parsedLineAt(index);
  }

  List<String> flattenWithNewlines() {
    final flattened = _cachedFlattenedGraphemes ??= List<String>.unmodifiable(
      text.characters.toList(growable: false),
    );
    return List<String>.from(flattened, growable: true);
  }

  List<String> _materializeLineTexts() {
    return List<String>.unmodifiable(
      List<String>.generate(lineCount, lineAt, growable: false),
    );
  }

  String _buildText() {
    if (_leafBacking case final leafBacking?) {
      return leafBacking.text;
    }
    final buffer = StringBuffer();
    writeTextBetweenLinesToBuffer(
      buffer,
      startLine: 0,
      endLine: lineCount,
      leadingNewline: false,
    );
    return buffer.toString();
  }

  void writeTextBetweenLinesToBuffer(
    StringBuffer buffer, {
    required int startLine,
    required int endLine,
    required bool leadingNewline,
  }) {
    final normalizedStart = startLine.clamp(0, lineCount);
    final normalizedEnd = endLine.clamp(normalizedStart, lineCount);
    if (normalizedStart == normalizedEnd) {
      return;
    }
    if (_leafBacking case final leafBacking?) {
      leafBacking.writeTextBetweenLinesToBuffer(
        buffer,
        startLine: normalizedStart,
        endLine: normalizedEnd,
        leadingNewline: leadingNewline,
      );
      return;
    }

    _compositeBacking!.writeTextBetweenLinesToBuffer(
      buffer,
      startLine: normalizedStart,
      endLine: normalizedEnd,
      leadingNewline: leadingNewline,
    );
  }

  List<int> _materializeLineLengths() {
    return List<int>.unmodifiable(
      List<int>.generate(lineCount, lineLength, growable: false),
    );
  }

  (_TextDocumentStorageSegment, int) _segmentForLine(int index) {
    return _compositeBacking!.segmentForLine(index);
  }

  (_TextDocumentStorageSegment, int, int) _segmentForLineWithIndex(int index) {
    return _compositeBacking!.segmentForLineWithIndex(index);
  }

  (_TextDocumentStorageSegment, int) _segmentForOffset(int offset) {
    return _compositeBacking!.segmentForOffset(offset);
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
    List<int>? lineLengths,
    required int revision,
    Object? storageIdentity,
  }) {
    final normalizedLineTexts = List<String>.unmodifiable(
      List<String>.from(lineTexts, growable: false),
    );
    final normalizedLineLengths = lineLengths == null
        ? normalizedLineTexts
              .map((line) => line.characters.length)
              .toList(growable: false)
        : List<int>.unmodifiable(lineLengths);
    return _TextDocumentStorage._leaf(
      leafBacking: _InlineTextDocumentLeafBacking(
        lineTexts: normalizedLineTexts,
        lineLengths: normalizedLineLengths,
      ),
      length: _TextDocumentStorage._documentLengthForLineLengths(
        normalizedLineLengths,
      ),
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
    );
  }

  static _TextDocumentStorage _leafFromParsedLines(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
    bool seedLineGraphemeCaches = true,
  }) {
    final normalizedLines = List<List<String>>.generate(
      lines.length,
      (index) => List<String>.unmodifiable(List<String>.from(lines[index])),
      growable: false,
    );
    final lineLengths = normalizedLines
        .map((line) => line.length)
        .toList(growable: false);
    final source = _TextDocumentSource.fromParsedLines(normalizedLines);
    return _TextDocumentStorage._leaf(
      leafBacking: _SourceSliceTextDocumentLeafBacking(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: 0,
          endLine: source.lineCount,
        ),
      ),
      length: _TextDocumentStorage._documentLengthForLineLengths(lineLengths),
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
      lineGraphemeCaches: seedLineGraphemeCaches
          ? <int, List<String>>{
              for (var index = 0; index < normalizedLines.length; index++)
                index: normalizedLines[index],
            }
          : null,
    );
  }

  static _TextDocumentStorage _leafFromTextSource({
    required _TextDocumentSourceSlice sourceSlice,
    required int revision,
    Object? storageIdentity,
    Map<int, List<String>>? lineGraphemeCaches,
  }) {
    return _TextDocumentStorage._leaf(
      leafBacking: _SourceSliceTextDocumentLeafBacking(
        sourceSlice: sourceSlice,
      ),
      length: sourceSlice.length,
      revision: revision,
      storageIdentity: storageIdentity ?? Object(),
      lineGraphemeCaches: lineGraphemeCaches,
    );
  }

  static _TextDocumentStorage _storageFromSingleNormalizedSegment(
    _TextDocumentStorageSegment segment, {
    required int revision,
    Object? storageIdentity,
  }) {
    final storage = segment.storage;
    final nextStorageIdentity = storageIdentity ?? Object();
    if (storage._leafBacking case final leafBacking?) {
      final slicedLeafBacking = leafBacking.slice(
        segment.startLine,
        segment.endLine,
      );
      return _TextDocumentStorage._leaf(
        leafBacking: slicedLeafBacking,
        length: slicedLeafBacking.length,
        revision: revision,
        storageIdentity: nextStorageIdentity,
      );
    }
    return _buildComposite(
      <_TextDocumentStorageSegment>[segment],
      revision: revision,
      storageIdentity: nextStorageIdentity,
    );
  }

  static _TextDocumentStorage _buildStorageFromText(
    String text, {
    required int revision,
    Object? storageIdentity,
  }) {
    final source = _TextDocumentSource.fromText(text);
    if (source.lineCount <= _maxLeafLineCount) {
      return _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: 0,
          endLine: source.lineCount,
        ),
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    final segments = <_TextDocumentStorageSegment>[];
    for (var start = 0; start < source.lineCount; start += _maxLeafLineCount) {
      final end = (start + _maxLeafLineCount).clamp(0, source.lineCount);
      final storage = _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: start,
          endLine: end,
        ),
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

  static _TextDocumentStorage _buildStorageFromLineTextsSource(
    List<String> lineTexts, {
    List<int>? lineLengths,
    required int revision,
    Object? storageIdentity,
  }) {
    final source = _TextDocumentSource.fromLineTexts(
      lineTexts,
      lineLengths: lineLengths,
    );
    if (source.lineCount <= _maxLeafLineCount) {
      return _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: 0,
          endLine: source.lineCount,
        ),
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    final segments = <_TextDocumentStorageSegment>[];
    for (var start = 0; start < source.lineCount; start += _maxLeafLineCount) {
      final end = (start + _maxLeafLineCount).clamp(0, source.lineCount);
      final storage = _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: start,
          endLine: end,
        ),
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

  static _TextDocumentStorage _buildStorageFromParsedLinesSource(
    List<List<String>> lines, {
    required int revision,
    Object? storageIdentity,
    bool seedLineGraphemeCaches = true,
  }) {
    final normalizedLines = List<List<String>>.generate(
      lines.length,
      (index) => List<String>.unmodifiable(List<String>.from(lines[index])),
      growable: false,
    );
    final source = _TextDocumentSource.fromParsedLines(normalizedLines);
    if (source.lineCount <= _maxLeafLineCount) {
      return _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: 0,
          endLine: source.lineCount,
        ),
        revision: revision,
        storageIdentity: storageIdentity,
        lineGraphemeCaches: <int, List<String>>{
          for (var index = 0; index < normalizedLines.length; index++)
            index: normalizedLines[index],
        },
      );
    }
    final segments = <_TextDocumentStorageSegment>[];
    for (
      var start = 0;
      start < normalizedLines.length;
      start += _maxLeafLineCount
    ) {
      final end = (start + _maxLeafLineCount).clamp(0, normalizedLines.length);
      final storage = _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: start,
          endLine: end,
        ),
        revision: 0,
        lineGraphemeCaches: seedLineGraphemeCaches
            ? <int, List<String>>{
                for (var index = start; index < end; index++)
                  index - start: normalizedLines[index],
              }
            : null,
      );
      segments.add(storage.slice(0, storage.lineCount));
    }
    return _buildBalancedComposite(
      segments,
      revision: revision,
      storageIdentity: storageIdentity,
    );
  }

  static _TextDocumentStorage _buildStorageFromLinePiecesSource(
    List<List<_TextDocumentSourcePiece>> linePieces, {
    required int revision,
    Object? storageIdentity,
  }) {
    final source = _TextDocumentSource.fromLinePieces(linePieces);
    if (source.lineCount <= _maxLeafLineCount) {
      return _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: 0,
          endLine: source.lineCount,
        ),
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }
    final segments = <_TextDocumentStorageSegment>[];
    for (var start = 0; start < source.lineCount; start += _maxLeafLineCount) {
      final end = (start + _maxLeafLineCount).clamp(0, source.lineCount);
      final storage = _leafFromTextSource(
        sourceSlice: _TextDocumentSourceSlice(
          source: source,
          startLine: start,
          endLine: end,
        ),
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

  static _TextDocumentStorage? _buildStorageFromNormalizedSegmentPieces(
    List<_TextDocumentStorageSegment> segments, {
    required int revision,
    Object? storageIdentity,
  }) {
    final totalLineCount = segments.fold<int>(
      0,
      (total, segment) => total + segment.lineCount,
    );
    if (totalLineCount <= 0) {
      return null;
    }

    final linePieces = <List<_TextDocumentSourcePiece>>[];
    final chunkSegments = <_TextDocumentStorageSegment>[];

    void flushChunk() {
      if (linePieces.isEmpty) {
        return;
      }
      final storage = _buildStorageFromLinePiecesSource(
        List<List<_TextDocumentSourcePiece>>.unmodifiable(linePieces),
        revision: 0,
      );
      chunkSegments.add(storage.slice(0, storage.lineCount));
      linePieces.clear();
    }

    for (final segment in segments) {
      for (var localIndex = 0; localIndex < segment.lineCount; localIndex++) {
        final lineLength = segment.lineLength(localIndex);
        if (lineLength <= 0) {
          linePieces.add(const <_TextDocumentSourcePiece>[]);
        } else {
          final pieces = segment.sourcePiecesForLineRange(
            localIndex,
            startColumn: 0,
            endColumn: lineLength,
          );
          if (pieces == null) {
            return null;
          }
          linePieces.add(List<_TextDocumentSourcePiece>.unmodifiable(pieces));
        }

        if (totalLineCount > _maxLeafLineCount &&
            linePieces.length >= _maxLeafLineCount) {
          flushChunk();
        }
      }
    }

    if (linePieces.isEmpty) {
      if (chunkSegments.isEmpty) {
        return null;
      }
    } else if (chunkSegments.isEmpty && totalLineCount <= _maxLeafLineCount) {
      return _buildStorageFromLinePiecesSource(
        List<List<_TextDocumentSourcePiece>>.unmodifiable(linePieces),
        revision: revision,
        storageIdentity: storageIdentity,
      );
    }

    flushChunk();

    return _buildBalancedComposite(
      List<_TextDocumentStorageSegment>.unmodifiable(chunkSegments),
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

    final childSegments = segment.storage._compositeBacking?.segments;
    if (childSegments == null) {
      _appendMergedLeafSegment(out, segment);
      return;
    }

    final childLineStarts =
        segment.storage._compositeBacking!.segmentLineStarts;
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

    final mergedSourceBacked = _mergeAdjacentSourceBackedLeafSegments(
      previous,
      segment,
    );
    if (mergedSourceBacked != null) {
      out[out.length - 1] = mergedSourceBacked;
      return;
    }

    out.add(segment);
  }

  static _TextDocumentStorageSegment? _mergeAdjacentSourceBackedLeafSegments(
    _TextDocumentStorageSegment previous,
    _TextDocumentStorageSegment segment,
  ) {
    final previousStorage = previous.storage;
    final nextStorage = segment.storage;
    final previousSourceSlice = previousStorage._leafBacking?.sourceSlice;
    final nextSourceSlice = nextStorage._leafBacking?.sourceSlice;
    final previousSource = previousSourceSlice?.source;
    final nextSource = nextSourceSlice?.source;
    if (previousSource == null ||
        nextSource == null ||
        !identical(previousSource, nextSource)) {
      return null;
    }

    final combinedLineCount = previous.lineCount + segment.lineCount;
    if (combinedLineCount > _maxLeafLineCount) {
      return null;
    }

    final previousSourceStart = previousSourceSlice!.startLine;
    final nextSourceStart = nextSourceSlice!.startLine;
    final mergedStartLine = previousSourceStart + previous.startLine;
    final mergedMiddleLine = previousSourceStart + previous.endLine;
    final mergedEndLine = nextSourceStart + segment.endLine;
    if (mergedMiddleLine != nextSourceStart + segment.startLine) {
      return null;
    }

    final mergedStorage = _leafFromTextSource(
      sourceSlice: _TextDocumentSourceSlice(
        source: previousSource,
        startLine: mergedStartLine,
        endLine: mergedEndLine,
      ),
      revision: 0,
    );
    return _TextDocumentStorageSegment(
      storage: mergedStorage,
      startLine: 0,
      endLine: mergedStorage.lineCount,
    );
  }

  int _debugLineGraphemeCacheCount(Set<_TextDocumentStorage> visited) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      return _lineGraphemeCaches.length;
    }
    var total = _lineGraphemeCaches.length;
    for (final segment in segments) {
      total += segment.storage._debugLineGraphemeCacheCount(visited);
    }
    return total;
  }

  int _debugSourceBackedLeafCount(Set<_TextDocumentStorage> visited) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      return _leafBacking?.sourceSlice == null ? 0 : 1;
    }
    var total = 0;
    for (final segment in segments) {
      total += segment.storage._debugSourceBackedLeafCount(visited);
    }
    return total;
  }

  int _debugPieceBackedLeafCount(Set<_TextDocumentStorage> visited) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      return _leafBacking?.source is _PieceTableTextDocumentSource ? 1 : 0;
    }
    var total = 0;
    for (final segment in segments) {
      total += segment.storage._debugPieceBackedLeafCount(visited);
    }
    return total;
  }

  int _debugPieceCount(Set<_TextDocumentStorage> visited) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      final source = _leafBacking?.source;
      return source is _PieceTableTextDocumentSource
          ? source.debugPieceCount
          : 0;
    }
    var total = 0;
    for (final segment in segments) {
      total += segment.storage._debugPieceCount(visited);
    }
    return total;
  }

  int _debugDistinctSourceCount(
    Set<_TextDocumentStorage> visited,
    Set<_TextDocumentSource> sources,
  ) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      final source = _leafBacking?.source;
      if (source == null || !sources.add(source)) {
        return 0;
      }
      return 1;
    }
    var total = 0;
    for (final segment in segments) {
      total += segment.storage._debugDistinctSourceCount(visited, sources);
    }
    return total;
  }

  int _debugReferencedSourceCount(
    Set<_TextDocumentStorage> visited,
    Set<_TextDocumentSource> sources,
  ) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      final source = _leafBacking?.source;
      if (source == null) {
        return 0;
      }
      return source.debugReferencedSourceCount(sources);
    }
    var total = 0;
    for (final segment in segments) {
      total += segment.storage._debugReferencedSourceCount(visited, sources);
    }
    return total;
  }

  int _debugJoinedSourceTextCount(
    Set<_TextDocumentStorage> visited,
    Set<_TextDocumentSource> sources,
  ) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      final source = _leafBacking?.source;
      if (source == null ||
          !source.debugHasJoinedTextCache ||
          !sources.add(source)) {
        return 0;
      }
      return 1;
    }
    var total = 0;
    for (final segment in segments) {
      total += segment.storage._debugJoinedSourceTextCount(visited, sources);
    }
    return total;
  }

  int _debugMaterializedSourceLineTextCount(
    Set<_TextDocumentStorage> visited,
    Set<_TextDocumentSource> sources,
  ) {
    if (!visited.add(this)) {
      return 0;
    }
    final segments = _compositeBacking?.segments;
    if (segments == null || segments.isEmpty) {
      final source = _leafBacking?.source;
      if (source == null || !sources.add(source)) {
        return 0;
      }
      return source.debugMaterializedLineTextCount;
    }
    var total = 0;
    for (final segment in segments) {
      total += segment.storage._debugMaterializedSourceLineTextCount(
        visited,
        sources,
      );
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

  List<String> lineGraphemesAt(int localIndex) =>
      storage.lineGraphemesAt(startLine + localIndex);

  String? graphemeInLineAt(int localIndex, int column) =>
      storage.graphemeInLineAt(startLine + localIndex, column);

  List<_TextDocumentSourcePiece>? sourcePiecesForLineRange(
    int localIndex, {
    required int startColumn,
    required int endColumn,
  }) => storage.sourcePiecesForLineRange(
    startLine + localIndex,
    startColumn: startColumn,
    endColumn: endColumn,
  );

  String lineTextPrefix(int localIndex, int graphemeCount) =>
      storage.lineTextPrefix(startLine + localIndex, graphemeCount);

  String lineTextSuffix(int localIndex, int graphemeStart) =>
      storage.lineTextSuffix(startLine + localIndex, graphemeStart);

  List<String> graphemesInLineRange(
    int localIndex, {
    required int startColumn,
    required int endColumn,
  }) => storage.graphemesInLineRange(
    startLine + localIndex,
    startColumn: startColumn,
    endColumn: endColumn,
  );

  String textInLineRange(
    int localIndex, {
    required int startColumn,
    required int endColumn,
  }) => storage.textInLineRange(
    startLine + localIndex,
    startColumn: startColumn,
    endColumn: endColumn,
  );

  bool matchesGraphemesInLineRange(
    int localIndex, {
    required int startColumn,
    required List<String> graphemes,
    required int graphemeStart,
    required int graphemeCount,
  }) => storage.matchesGraphemesInLineRange(
    startLine + localIndex,
    startColumn: startColumn,
    graphemes: graphemes,
    graphemeStart: graphemeStart,
    graphemeCount: graphemeCount,
  );

  ({int start, int end}) wordBoundaryAtInLine(int localIndex, int column) =>
      storage.wordBoundaryAtInLine(startLine + localIndex, column);

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
    writeTextRangeToBuffer(
      buffer,
      startLocalLine: 0,
      endLocalLine: lineCount,
      leadingNewline: leadingNewline,
    );
  }

  void writeTextRangeToBuffer(
    StringBuffer buffer, {
    required int startLocalLine,
    required int endLocalLine,
    required bool leadingNewline,
  }) {
    final normalizedStart = startLocalLine.clamp(0, lineCount);
    final normalizedEnd = endLocalLine.clamp(normalizedStart, lineCount);
    storage.writeTextBetweenLinesToBuffer(
      buffer,
      startLine: startLine + normalizedStart,
      endLine: startLine + normalizedEnd,
      leadingNewline: leadingNewline,
    );
  }
}
