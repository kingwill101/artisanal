/// Shared text layout helpers for Bubbles components.
///
/// This module centralizes logic for:
/// - soft-wrapping grapheme-cluster lines into visual segments
/// - mapping terminal cell X positions into grapheme indices
///
/// It is intentionally UI-agnostic: prompts, gutters, and borders are handled
/// by the calling component.
library;

import 'package:ultraviolet/unicode.dart' as uni;
import 'runeutil.dart';

/// A visual segment of an underlying content line.
final class VisualLine {
  const VisualLine({
    required this.rowIndex,
    required this.charOffset,
    required this.text,
    required this.graphemeCount,
  });

  /// Index of the underlying (unwrapped) line.
  final int rowIndex;

  /// Grapheme offset into the underlying line where this segment begins.
  final int charOffset;

  /// Segment text (no prompt/gutter prefixes).
  final String text;

  /// Grapheme count in [text].
  final int graphemeCount;

  bool get isContinuation => charOffset > 0;
}

/// Returns visual lines for the given content.
///
/// [lines] MUST be grapheme-cluster tokenized (`List<List<String>>`).
List<VisualLine> buildVisualLines(
  List<List<String>> lines, {
  required bool softWrap,
  required int wrapWidthCells,
}) {
  return buildVisualLinesFromReader(
    lineCount: lines.length,
    lineTextAt: (index) => lines[index].join(),
    lineLengthAt: (index) => lines[index].length,
    lineGraphemesAt: (index) => lines[index],
    softWrap: softWrap,
    wrapWidthCells: wrapWidthCells,
  );
}

List<VisualLine> buildVisualLinesFromReader({
  required int lineCount,
  required String Function(int index) lineTextAt,
  required int Function(int index) lineLengthAt,
  List<String> Function(int index)? lineGraphemesAt,
  required bool softWrap,
  required int wrapWidthCells,
}) {
  final out = <VisualLine>[];

  for (var rowIndex = 0; rowIndex < lineCount; rowIndex++) {
    if (!softWrap || wrapWidthCells <= 0) {
      final text = lineTextAt(rowIndex);
      out.add(
        VisualLine(
          rowIndex: rowIndex,
          charOffset: 0,
          text: text,
          graphemeCount: lineLengthAt(rowIndex),
        ),
      );
      continue;
    }

    final line = lineGraphemesAt!(rowIndex);
    var start = 0;
    while (start < line.length) {
      var width = 0;
      var end = start;
      while (end < line.length) {
        final w = runeWidth(uni.firstCodePoint(line[end]));
        if (width + w > wrapWidthCells) break;
        width += w;
        end += 1;
      }

      // Avoid infinite loop if the wrap width is too small.
      if (end == start) end = start + 1;

      final segment = line.sublist(start, end).join();
      out.add(
        VisualLine(
          rowIndex: rowIndex,
          charOffset: start,
          text: segment,
          graphemeCount: end - start,
        ),
      );

      start = end;
    }

    if (line.isEmpty) {
      out.add(
        VisualLine(
          rowIndex: rowIndex,
          charOffset: 0,
          text: '',
          graphemeCount: 0,
        ),
      );
    }
  }

  return out;
}

/// Maps a local X position (cells within a visual segment) to a grapheme index.
///
/// Returns a value in `[0, graphemeCount]` where `graphemeCount` means “past end”.
int localCellXToGraphemeIndex(String segmentText, int localXCells) {
  if (localXCells <= 0) return 0;

  var cell = 0;
  var idx = 0;
  for (final g in uni.graphemes(segmentText)) {
    final w = runeWidth(uni.firstCodePoint(g));
    if (cell + w > localXCells) break;
    cell += w;
    idx += 1;
  }
  return idx;
}
