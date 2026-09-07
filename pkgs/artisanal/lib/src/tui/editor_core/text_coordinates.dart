library;

import 'dart:convert';

import 'editor_state.dart';
import 'text_document.dart';

/// A zero-based UTF-8 row and byte-column pair.
///
/// Native parsers commonly use this coordinate system, while [TextDocument]
/// uses grapheme columns. Conversion helpers in this library round byte
/// positions inside a grapheme down to that grapheme's leading boundary.
final class TextUtf8Point {
  const TextUtf8Point({required this.row, required this.byteColumn});

  final int row;
  final int byteColumn;

  @override
  bool operator ==(Object other) =>
      other is TextUtf8Point &&
      other.row == row &&
      other.byteColumn == byteColumn;

  @override
  int get hashCode => Object.hash(row, byteColumn);

  @override
  String toString() => 'TextUtf8Point(row: $row, byteColumn: $byteColumn)';
}

/// Reusable UTF-8/grapheme coordinate index for a document snapshot.
///
/// Create one index per parser request and reuse it for every node and capture.
/// Line byte starts are computed once and grapheme byte boundaries are cached
/// lazily per accessed line.
final class TextUtf8CoordinateIndex {
  TextUtf8CoordinateIndex(this.document)
    : _lineByteStarts = List<int>.filled(document.lineCount, 0),
      _lineByteLengths = List<int>.filled(document.lineCount, 0),
      _lineBoundaries = List<List<int>?>.filled(document.lineCount, null) {
    var start = 0;
    for (var row = 0; row < document.lineCount; row++) {
      _lineByteStarts[row] = start;
      final length = utf8.encode(document.lineAt(row)).length;
      _lineByteLengths[row] = length;
      start += length;
      if (row < document.lineCount - 1) start += 1;
    }
    byteLength = start;
  }

  final TextDocument document;
  final List<int> _lineByteStarts;
  final List<int> _lineByteLengths;
  final List<List<int>?> _lineBoundaries;

  /// Total UTF-8 byte length, including newline bytes.
  late final int byteLength;

  /// Converts a UTF-8 parser point into a grapheme-based document position.
  TextPosition positionForPoint(TextUtf8Point point) {
    final row = point.row.clamp(0, document.lineCount - 1);
    final target = point.byteColumn.clamp(0, _lineByteLengths[row]);
    final boundaries = _boundariesForLine(row);
    return TextPosition(
      line: row,
      column: _floorBoundaryIndex(boundaries, target),
    );
  }

  /// Converts a UTF-8 parser point into a grapheme offset.
  int offsetForPoint(TextUtf8Point point) =>
      document.offsetForPosition(positionForPoint(point));

  /// Converts a grapheme-based document position into a UTF-8 parser point.
  TextUtf8Point pointForPosition(TextPosition position) {
    final clamped = document.clampPosition(position);
    return TextUtf8Point(
      row: clamped.line,
      byteColumn: _boundariesForLine(clamped.line)[clamped.column],
    );
  }

  /// Converts a grapheme offset into a UTF-8 parser point.
  TextUtf8Point pointForOffset(int offset) => pointForPosition(
    document.positionForOffset(offset.clamp(0, document.length)),
  );

  /// Converts a whole-document UTF-8 byte offset into a grapheme offset.
  int offsetForByteOffset(int byteOffset) {
    final target = byteOffset.clamp(0, byteLength);
    var low = 0;
    var high = _lineByteStarts.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (_lineByteStarts[middle] <= target) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final row = (low - 1).clamp(0, document.lineCount - 1);
    return offsetForPoint(
      TextUtf8Point(
        row: row,
        byteColumn: (target - _lineByteStarts[row]).clamp(
          0,
          _lineByteLengths[row],
        ),
      ),
    );
  }

  /// Converts a grapheme offset into a whole-document UTF-8 byte offset.
  int byteOffsetForOffset(int offset) {
    final point = pointForOffset(offset);
    return _lineByteStarts[point.row] + point.byteColumn;
  }

  List<int> _boundariesForLine(int row) {
    final cached = _lineBoundaries[row];
    if (cached != null) return cached;
    final boundaries = <int>[0];
    var byteColumn = 0;
    for (final grapheme in document.lineGraphemesAt(row)) {
      byteColumn += utf8.encode(grapheme).length;
      boundaries.add(byteColumn);
    }
    return _lineBoundaries[row] = List<int>.unmodifiable(boundaries);
  }

  int _floorBoundaryIndex(List<int> boundaries, int target) {
    var low = 0;
    var high = boundaries.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (boundaries[middle] <= target) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low - 1;
  }
}

/// Converts a UTF-8 parser point into a grapheme-based document position.
///
/// Rows and byte columns are clamped to the document. A byte column that falls
/// inside a multi-byte grapheme resolves to the start of that grapheme.
TextPosition textPositionForUtf8Point(
  TextDocument document,
  TextUtf8Point point,
) => TextUtf8CoordinateIndex(document).positionForPoint(point);

/// Converts a UTF-8 parser point into a grapheme offset.
int textOffsetForUtf8Point(TextDocument document, TextUtf8Point point) =>
    TextUtf8CoordinateIndex(document).offsetForPoint(point);

/// Converts a document position into a zero-based UTF-8 parser point.
TextUtf8Point textUtf8PointForPosition(
  TextDocument document,
  TextPosition position,
) => TextUtf8CoordinateIndex(document).pointForPosition(position);

/// Converts a grapheme offset into a zero-based UTF-8 parser point.
TextUtf8Point textUtf8PointForOffset(TextDocument document, int offset) =>
    TextUtf8CoordinateIndex(document).pointForOffset(offset);

/// Converts a UTF-8 byte offset from the document start into a grapheme offset.
///
/// Newlines count as one UTF-8 byte. Positions inside a multi-byte grapheme
/// resolve to the grapheme's leading boundary.
int textOffsetForUtf8ByteOffset(TextDocument document, int byteOffset) =>
    TextUtf8CoordinateIndex(document).offsetForByteOffset(byteOffset);

/// Converts a grapheme offset from the document start into a UTF-8 byte offset.
int textUtf8ByteOffsetForOffset(TextDocument document, int offset) =>
    TextUtf8CoordinateIndex(document).byteOffsetForOffset(offset);
