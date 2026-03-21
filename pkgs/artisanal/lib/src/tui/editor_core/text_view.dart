library;

import 'dart:math' as math;

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
    required this.startColumn,
    required this.endColumn,
    required this.totalColumns,
  });

  final int startRow;
  final int endRow;
  final int totalRows;
  final int startColumn;
  final int endColumn;
  final int totalColumns;
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
    this.viewportStartColumn = 0,
    this.scrollMargin = 0,
  });

  int width;
  int height;
  bool softWrap;
  int leadingColumns;
  int viewportStartRow;
  int viewportStartColumn;
  double scrollMargin;

  int effectiveContentWidth() {
    if (width <= 0) {
      return 0;
    }
    return math.max(0, width - leadingColumns);
  }

  int effectiveWrapWidth() {
    if (!softWrap) {
      return 0;
    }
    return effectiveContentWidth();
  }

  List<TextViewLine> buildLines(TextDocument document, EditorState state) {
    final visual = _buildVisualLines(document);

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
    return _buildVisualLines(document).length;
  }

  int maxViewportStartRow(TextDocument document) {
    final totalRows = totalVisualRows(document);
    if (height <= 0 || totalRows <= height) {
      return 0;
    }
    return (totalRows - height).clamp(0, totalRows);
  }

  int totalVisualColumns(TextDocument document, EditorState state) {
    final lines = buildLines(document, state);
    if (lines.isEmpty) {
      return 0;
    }
    return lines.map((line) => _displayWidth(line.text)).fold<int>(0, math.max);
  }

  int maxViewportStartColumn(TextDocument document, EditorState state) {
    if (softWrap) {
      return 0;
    }
    final viewportWidth = effectiveContentWidth();
    final totalColumns = totalVisualColumns(document, state);
    if (viewportWidth <= 0 || totalColumns <= viewportWidth) {
      return 0;
    }
    return (totalColumns - viewportWidth).clamp(0, totalColumns);
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

  void scrollToColumn(int column, TextDocument document, EditorState state) {
    viewportStartColumn = column.clamp(
      0,
      maxViewportStartColumn(document, state),
    );
  }

  void scrollByColumns(int delta, TextDocument document, EditorState state) {
    scrollToColumn(viewportStartColumn + delta, document, state);
  }

  bool isCursorVisible(TextDocument document, EditorState state) {
    final cursor = resolveCursorVisualPosition(document, state);
    if (cursor == null) {
      return true;
    }
    final viewport = resolveViewport(document, state);
    final rowVisible =
        cursor.visualRow >= viewport.startRow &&
        cursor.visualRow < viewport.endRow;
    if (!rowVisible) {
      return false;
    }
    if (softWrap || effectiveContentWidth() <= 0) {
      return true;
    }
    return cursor.displayColumn >= viewport.startColumn &&
        cursor.displayColumn < viewport.endColumn;
  }

  int ensureCursorVisible(TextDocument document, EditorState state) {
    final viewport = resolveViewport(document, state);
    viewportStartRow = viewport.startRow;
    viewportStartColumn = viewport.startColumn;
    return viewportStartRow;
  }

  TextViewport resolveViewport(TextDocument document, EditorState state) {
    final lines = buildLines(document, state);
    final totalRows = lines.length;
    final totalColumns = totalVisualColumns(document, state);
    final viewportWidth = effectiveContentWidth();
    final cursor = resolveCursorVisualPosition(document, state);
    final cursorRow = cursor?.visualRow ?? 0;
    final cursorColumn = cursor?.displayColumn ?? 0;
    final verticalMargin = _resolvedScrollMargin(height);
    final horizontalMargin = softWrap
        ? 0
        : _resolvedScrollMargin(viewportWidth);

    final resolvedStartColumn = switch ((softWrap, viewportWidth > 0)) {
      (true, _) || (_, false) => 0,
      _ => _resolveViewportStart(
        currentStart: viewportStartColumn,
        cursorOffset: cursorColumn,
        viewportExtent: viewportWidth,
        totalExtent: totalColumns,
        margin: horizontalMargin,
      ),
    };
    final resolvedEndColumn = switch ((softWrap, viewportWidth > 0)) {
      (true, _) || (_, false) => totalColumns,
      _ => (resolvedStartColumn + viewportWidth).clamp(0, totalColumns),
    };

    if (height <= 0 || totalRows <= height) {
      return TextViewport(
        startRow: 0,
        endRow: totalRows,
        totalRows: totalRows,
        startColumn: resolvedStartColumn,
        endColumn: resolvedEndColumn,
        totalColumns: totalColumns,
      );
    }

    final resolvedStart = _resolveViewportStart(
      currentStart: viewportStartRow,
      cursorOffset: cursorRow,
      viewportExtent: height,
      totalExtent: totalRows,
      margin: verticalMargin,
    );

    return TextViewport(
      startRow: resolvedStart,
      endRow: (resolvedStart + height).clamp(0, totalRows),
      totalRows: totalRows,
      startColumn: resolvedStartColumn,
      endColumn: resolvedEndColumn,
      totalColumns: totalColumns,
    );
  }

  List<TextViewLine> buildViewportLines(
    TextDocument document,
    EditorState state,
  ) {
    final lines = buildLines(document, state);
    final viewport = resolveViewport(document, state);
    viewportStartRow = viewport.startRow;
    viewportStartColumn = viewport.startColumn;
    return lines
        .sublist(viewport.startRow, viewport.endRow)
        .map((line) => _applyViewportColumnWindow(line, viewport))
        .toList(growable: false);
  }

  List<TextViewLine> buildLinesForCurrentViewport(
    TextDocument document,
    EditorState state,
  ) {
    final lines = buildLines(document, state);
    final viewport = _resolveCurrentViewport(document, state);
    viewportStartRow = viewport.startRow;
    viewportStartColumn = viewport.startColumn;
    return lines
        .sublist(viewport.startRow, viewport.endRow)
        .map((line) => _applyViewportColumnWindow(line, viewport))
        .toList(growable: false);
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
    final lines = softWrap
        ? buildViewportLines(document, state)
        : buildLinesForCurrentViewport(document, state);
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

  TextViewLine _applyViewportColumnWindow(
    TextViewLine line,
    TextViewport viewport,
  ) {
    if (softWrap || effectiveContentWidth() <= 0) {
      return line;
    }

    final clipped = _clipLineToViewport(
      line.text,
      startColumn: viewport.startColumn,
      width: viewport.endColumn - viewport.startColumn,
    );
    return TextViewLine(
      visualRow: line.visualRow,
      logicalLine: line.logicalLine,
      charOffset: line.charOffset + clipped.skippedGraphemes,
      text: clipped.text,
      graphemeCount: clipped.graphemeCount,
      hasCursor: line.hasCursor,
    );
  }

  ({String text, int skippedGraphemes, int graphemeCount}) _clipLineToViewport(
    String text, {
    required int startColumn,
    required int width,
  }) {
    if (width <= 0 || text.isEmpty) {
      final graphemes = uni.graphemes(text).toList(growable: false);
      return (
        text: width <= 0 ? '' : text,
        skippedGraphemes: 0,
        graphemeCount: width <= 0 ? 0 : graphemes.length,
      );
    }

    final graphemes = uni.graphemes(text).toList(growable: false);
    var skippedGraphemes = 0;
    var skippedColumns = 0;
    while (skippedGraphemes < graphemes.length) {
      final widthDelta = runeWidth(
        uni.firstCodePoint(graphemes[skippedGraphemes]),
      );
      if (skippedColumns + widthDelta > startColumn) {
        break;
      }
      skippedColumns += widthDelta;
      skippedGraphemes += 1;
    }

    var visibleColumns = 0;
    var visibleEnd = skippedGraphemes;
    while (visibleEnd < graphemes.length) {
      final widthDelta = runeWidth(uni.firstCodePoint(graphemes[visibleEnd]));
      if (visibleColumns + widthDelta > width) {
        break;
      }
      visibleColumns += widthDelta;
      visibleEnd += 1;
    }

    final visible = graphemes.sublist(skippedGraphemes, visibleEnd);
    return (
      text: visible.join(),
      skippedGraphemes: skippedGraphemes,
      graphemeCount: visible.length,
    );
  }

  int _displayWidth(String text) {
    var width = 0;
    for (final grapheme in uni.graphemes(text)) {
      width += runeWidth(uni.firstCodePoint(grapheme));
    }
    return width;
  }

  int _resolvedScrollMargin(int viewportExtent) {
    if (viewportExtent <= 0 || scrollMargin <= 0) {
      return 0;
    }
    final margin = scrollMargin < 1
        ? (viewportExtent * scrollMargin).floor()
        : scrollMargin.floor();
    return margin.clamp(0, math.max(0, viewportExtent - 1));
  }

  int _resolveViewportStart({
    required int currentStart,
    required int cursorOffset,
    required int viewportExtent,
    required int totalExtent,
    required int margin,
  }) {
    if (viewportExtent <= 0 || totalExtent <= viewportExtent) {
      return 0;
    }

    final maxStart = (totalExtent - viewportExtent).clamp(0, totalExtent);
    final clampedStart = currentStart.clamp(0, maxStart);
    final visibleEnd = clampedStart + viewportExtent;
    if (cursorOffset < clampedStart + margin) {
      return (cursorOffset - margin).clamp(0, maxStart);
    }
    if (cursorOffset >= visibleEnd - margin) {
      return (cursorOffset - viewportExtent + margin + 1).clamp(0, maxStart);
    }
    return clampedStart;
  }

  TextViewport _resolveCurrentViewport(
    TextDocument document,
    EditorState state,
  ) {
    final lines = buildLines(document, state);
    final totalRows = lines.length;
    final totalColumns = totalVisualColumns(document, state);
    final viewportWidth = effectiveContentWidth();
    final startRow = height <= 0 || totalRows <= height
        ? 0
        : viewportStartRow.clamp(0, maxViewportStartRow(document));
    final endRow = height <= 0 || totalRows <= height
        ? totalRows
        : (startRow + height).clamp(0, totalRows);
    final startColumn = switch ((softWrap, viewportWidth > 0)) {
      (true, _) || (_, false) => 0,
      _ => viewportStartColumn.clamp(
        0,
        maxViewportStartColumn(document, state),
      ),
    };
    final endColumn = switch ((softWrap, viewportWidth > 0)) {
      (true, _) || (_, false) => totalColumns,
      _ => (startColumn + viewportWidth).clamp(0, totalColumns),
    };

    return TextViewport(
      startRow: startRow,
      endRow: endRow,
      totalRows: totalRows,
      startColumn: startColumn,
      endColumn: endColumn,
      totalColumns: totalColumns,
    );
  }

  List<layout.VisualLine> _buildVisualLines(TextDocument document) {
    return layout.buildVisualLinesFromReader(
      lineCount: document.lineCount,
      lineTextAt: document.lineAt,
      lineLengthAt: document.lineLength,
      lineGraphemesAt: softWrap ? document.lineGraphemesAt : null,
      softWrap: softWrap,
      wrapWidthCells: effectiveWrapWidth(),
    );
  }
}
