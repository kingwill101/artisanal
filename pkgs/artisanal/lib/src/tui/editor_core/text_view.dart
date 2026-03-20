library;

import '../../unicode/grapheme.dart' as uni;
import '../bubbles/text_layout.dart' as layout;
import '../bubbles/runeutil.dart';
import 'editor_state.dart';
import 'text_document.dart';

final class TextViewLine {
  const TextViewLine({
    required this.visualRow,
    required this.logicalLine,
    required this.charOffset,
    required this.text,
    required this.graphemeCount,
    required this.hasCursor,
  });

  final int visualRow;
  final int logicalLine;
  final int charOffset;
  final String text;
  final int graphemeCount;
  final bool hasCursor;
}

final class TextHitResult {
  const TextHitResult({
    required this.line,
    required this.column,
    required this.visualRow,
  });

  final int line;
  final int column;
  final int visualRow;
}

final class TextViewport {
  const TextViewport({
    required this.startRow,
    required this.endRow,
    required this.totalRows,
  });

  final int startRow;
  final int endRow;
  final int totalRows;
}

final class TextVisualCursorPosition {
  const TextVisualCursorPosition({
    required this.visualRow,
    required this.column,
    required this.displayColumn,
    required this.startOffset,
    required this.endOffset,
  });

  final int visualRow;
  final int column;
  final int displayColumn;
  final int startOffset;
  final int endOffset;
}

final class TextView {
  TextView({
    this.width = 0,
    this.height = 0,
    this.softWrap = true,
    this.leadingColumns = 0,
    this.viewportStartRow = 0,
  });

  int width;
  int height;
  bool softWrap;
  int leadingColumns;
  int viewportStartRow;

  int effectiveWrapWidth() {
    if (!softWrap) {
      return 0;
    }
    return width <= 0 ? 0 : width - leadingColumns;
  }

  List<TextViewLine> buildLines(TextDocument document, EditorState state) {
    final wrapWidth = effectiveWrapWidth();
    final visual = layout.buildVisualLines(
      document.lines,
      softWrap: softWrap,
      wrapWidthCells: wrapWidth,
    );

    final result = <TextViewLine>[];
    for (var i = 0; i < visual.length; i++) {
      final line = visual[i];
      final lineLength = document.lineLength(line.rowIndex);
      final cursorColumn = state.line == line.rowIndex
          ? state.column.clamp(0, lineLength)
          : -1;
      final segStart = line.charOffset;
      final segEnd = segStart + line.graphemeCount;
      final hasCursor =
          state.line == line.rowIndex &&
          cursorColumn >= segStart &&
          cursorColumn <= segEnd;

      result.add(
        TextViewLine(
          visualRow: i,
          logicalLine: line.rowIndex,
          charOffset: line.charOffset,
          text: line.text,
          graphemeCount: line.graphemeCount,
          hasCursor: hasCursor,
        ),
      );
    }

    return result;
  }

  int totalVisualRows(TextDocument document) {
    final wrapWidth = effectiveWrapWidth();
    return layout
        .buildVisualLines(
          document.lines,
          softWrap: softWrap,
          wrapWidthCells: wrapWidth,
        )
        .length;
  }

  int maxViewportStartRow(TextDocument document) {
    final totalRows = totalVisualRows(document);
    if (height <= 0 || totalRows <= height) {
      return 0;
    }
    return (totalRows - height).clamp(0, totalRows);
  }

  void scrollToRow(int row, TextDocument document) {
    viewportStartRow = row.clamp(0, maxViewportStartRow(document));
  }

  void scrollByRows(int delta, TextDocument document) {
    scrollToRow(viewportStartRow + delta, document);
  }

  void pageDown(TextDocument document) {
    final pageSize = height > 0 ? height : 1;
    scrollByRows(pageSize, document);
  }

  void pageUp(TextDocument document) {
    final pageSize = height > 0 ? height : 1;
    scrollByRows(-pageSize, document);
  }

  bool isCursorVisible(TextDocument document, EditorState state) {
    final cursorRow = cursorVisualRow(document, state);
    if (cursorRow == null) {
      return true;
    }
    final viewport = resolveViewport(document, state);
    return cursorRow >= viewport.startRow && cursorRow < viewport.endRow;
  }

  int ensureCursorVisible(TextDocument document, EditorState state) {
    final viewport = resolveViewport(document, state);
    viewportStartRow = viewport.startRow;
    return viewportStartRow;
  }

  TextViewport resolveViewport(TextDocument document, EditorState state) {
    final lines = buildLines(document, state);
    final totalRows = lines.length;
    if (height <= 0 || totalRows <= height) {
      return TextViewport(startRow: 0, endRow: totalRows, totalRows: totalRows);
    }

    final cursorRow = cursorVisualRow(document, state) ?? 0;
    final maxStart = (totalRows - height).clamp(0, totalRows);
    final clampedStart = viewportStartRow.clamp(0, maxStart);
    final visibleEnd = clampedStart + height;
    final resolvedStart = cursorRow < clampedStart
        ? cursorRow
        : cursorRow >= visibleEnd
        ? (cursorRow - height + 1).clamp(0, maxStart)
        : clampedStart;

    return TextViewport(
      startRow: resolvedStart,
      endRow: (resolvedStart + height).clamp(0, totalRows),
      totalRows: totalRows,
    );
  }

  List<TextViewLine> buildViewportLines(
    TextDocument document,
    EditorState state,
  ) {
    final lines = buildLines(document, state);
    final viewport = resolveViewport(document, state);
    viewportStartRow = viewport.startRow;
    return lines.sublist(viewport.startRow, viewport.endRow);
  }

  List<TextViewLine> buildLinesForCurrentViewport(
    TextDocument document,
    EditorState state,
  ) {
    final lines = buildLines(document, state);
    if (height <= 0 || lines.length <= height) {
      viewportStartRow = 0;
      return lines;
    }

    final startRow = viewportStartRow.clamp(0, maxViewportStartRow(document));
    final endRow = (startRow + height).clamp(0, lines.length);
    viewportStartRow = startRow;
    return lines.sublist(startRow, endRow);
  }

  TextVisualCursorPosition? resolveCursorVisualPosition(
    TextDocument document,
    EditorState state, {
    TextPosition? cursor,
  }) {
    final lines = buildLines(document, state);
    if (lines.isEmpty) {
      return null;
    }

    final resolvedCursor = document.clampPosition(cursor ?? state.cursor);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (resolvedCursor.line != line.logicalLine) {
        continue;
      }

      final segStart = line.charOffset;
      final segEnd = segStart + line.graphemeCount;
      if (resolvedCursor.column < segStart || resolvedCursor.column > segEnd) {
        continue;
      }

      if (resolvedCursor.column == segEnd && i + 1 < lines.length) {
        final next = lines[i + 1];
        if (next.logicalLine == line.logicalLine && next.charOffset == segEnd) {
          continue;
        }
      }

      return _visualCursorPositionForLine(
        document,
        lines,
        i,
        cursorColumn: resolvedCursor.column,
      );
    }

    final fallbackRow = lines.lastIndexWhere(
      (line) => line.logicalLine == resolvedCursor.line,
    );
    final resolvedRow = fallbackRow >= 0 ? fallbackRow : lines.length - 1;
    final fallbackLine = lines[resolvedRow];
    final fallbackColumn = fallbackLine.logicalLine == resolvedCursor.line
        ? resolvedCursor.column.clamp(
            fallbackLine.charOffset,
            fallbackLine.charOffset + fallbackLine.graphemeCount,
          )
        : fallbackLine.charOffset + fallbackLine.graphemeCount;

    return _visualCursorPositionForLine(
      document,
      lines,
      resolvedRow,
      cursorColumn: fallbackColumn,
    );
  }

  int offsetForDisplayColumn(
    TextDocument document,
    EditorState state, {
    required int visualRow,
    required int displayColumn,
  }) {
    final lines = buildLines(document, state);
    if (lines.isEmpty) {
      return 0;
    }

    final line = lines[visualRow.clamp(0, lines.length - 1)];
    final columnInSegment = layout.localCellXToGraphemeIndex(
      line.text,
      displayColumn,
    );

    return document.offsetForPosition(
      TextPosition(
        line: line.logicalLine,
        column: line.charOffset + columnInSegment,
      ),
    );
  }

  int cursorOffsetForVisualLineMove(
    TextDocument document,
    EditorState state, {
    required int lineDelta,
    int desiredDisplayColumn = -1,
    TextPosition? cursor,
  }) {
    final current = resolveCursorVisualPosition(
      document,
      state,
      cursor: cursor,
    );
    if (current == null) {
      return 0;
    }

    final lines = buildLines(document, state);
    if (lines.isEmpty) {
      return 0;
    }

    final targetRow = (current.visualRow + lineDelta).clamp(
      0,
      lines.length - 1,
    );
    final targetDisplayColumn = desiredDisplayColumn >= 0
        ? desiredDisplayColumn
        : current.displayColumn;

    return offsetForDisplayColumn(
      document,
      state,
      visualRow: targetRow,
      displayColumn: targetDisplayColumn,
    );
  }

  int cursorOffsetForVisualLineBoundary(
    TextDocument document,
    EditorState state, {
    required bool end,
    TextPosition? cursor,
  }) {
    final current = resolveCursorVisualPosition(
      document,
      state,
      cursor: cursor,
    );
    if (current == null) {
      return 0;
    }
    return end ? current.endOffset : current.startOffset;
  }

  int? cursorVisualRow(TextDocument document, EditorState state) {
    return resolveCursorVisualPosition(document, state)?.visualRow;
  }

  TextHitResult? hitTestContent(
    TextDocument document,
    EditorState state, {
    required int localX,
    required int visualRow,
  }) {
    final lines = buildViewportLines(document, state);
    if (visualRow < 0 || visualRow >= lines.length) {
      return null;
    }

    final line = lines[visualRow];
    final columnInSegment = layout.localCellXToGraphemeIndex(line.text, localX);
    final column = line.charOffset + columnInSegment;
    final clampedColumn = column.clamp(
      0,
      document.lineLength(line.logicalLine),
    );

    return TextHitResult(
      line: line.logicalLine,
      column: clampedColumn,
      visualRow: visualRow,
    );
  }

  TextVisualCursorPosition _visualCursorPositionForLine(
    TextDocument document,
    List<TextViewLine> lines,
    int visualRow, {
    required int cursorColumn,
  }) {
    final line = lines[visualRow];
    final column = (cursorColumn - line.charOffset).clamp(
      0,
      line.graphemeCount,
    );

    var displayColumn = 0;
    var index = 0;
    for (final grapheme in uni.graphemes(line.text)) {
      if (index >= column) {
        break;
      }
      displayColumn += runeWidth(uni.firstCodePoint(grapheme));
      index += 1;
    }

    return TextVisualCursorPosition(
      visualRow: visualRow,
      column: column,
      displayColumn: displayColumn,
      startOffset: document.offsetForPosition(
        TextPosition(line: line.logicalLine, column: line.charOffset),
      ),
      endOffset: document.offsetForPosition(
        TextPosition(
          line: line.logicalLine,
          column: line.charOffset + line.graphemeCount,
        ),
      ),
    );
  }
}
