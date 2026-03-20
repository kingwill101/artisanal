part of 'components_widgets.dart';

final class _TextAreaControllerCoreBridge {
  _TextAreaControllerCoreBridge(this._controller);

  final TextAreaController _controller;

  TextOffsetStateSnapshot currentOffsetStateSnapshot({TextDocument? document}) {
    final resolvedDocument = document ?? TextDocument(text: _controller.text);
    final cursorOffset = resolvedDocument.offsetForPosition(
      TextPosition(line: _controller.line, column: _controller.column),
    );
    final selectionBase = _controller.selectionBase;
    final selectionExtent = _controller.selectionExtent;
    final hasSelection =
        _controller.hasSelection &&
        selectionBase != null &&
        selectionExtent != null;

    if (!hasSelection) {
      return TextOffsetStateSnapshot.collapsed(cursorOffset: cursorOffset);
    }

    return TextOffsetStateSnapshot.selection(
      baseOffset: resolvedDocument.offsetForPosition(
        TextPosition(line: selectionBase.line, column: selectionBase.column),
      ),
      extentOffset: resolvedDocument.offsetForPosition(
        TextPosition(
          line: selectionExtent.line,
          column: selectionExtent.column,
        ),
      ),
      cursorOffset: cursorOffset,
    );
  }

  TextLineStateSnapshot currentLineStateSnapshot() {
    final selectionBase = _controller.selectionBase;
    final selectionExtent = _controller.selectionExtent;
    final hasSelection =
        _controller.hasSelection &&
        selectionBase != null &&
        selectionExtent != null;
    final cursor = TextPosition(
      line: _controller.line,
      column: _controller.column,
    );

    if (!hasSelection) {
      return TextLineStateSnapshot.collapsed(cursor: cursor);
    }

    return TextLineStateSnapshot.selection(
      base: TextPosition(
        line: selectionBase.line,
        column: selectionBase.column,
      ),
      extent: TextPosition(
        line: selectionExtent.line,
        column: selectionExtent.column,
      ),
      cursor: cursor,
    );
  }

  void applyTextCommandResult(
    TextCommandResult result, {
    bool pushHistoryBoundary = true,
  }) {
    applyOffsets(
      text: result.graphemes.join(),
      cursorOffset: result.cursorOffset,
      selectionBaseOffset: result.selectionBaseOffset,
      selectionExtentOffset: result.selectionExtentOffset,
      pushHistoryBoundary: pushHistoryBoundary,
    );
  }

  void applyTextLineCommandResult(
    TextLineCommandResult result, {
    bool pushHistoryBoundary = true,
  }) {
    applyLineState(
      lines: result.lines,
      cursor: result.cursor,
      selectionBase: result.selectionBase,
      selectionExtent: result.selectionExtent,
      pushHistoryBoundary: pushHistoryBoundary,
    );
  }

  void applyOffsets({
    required String text,
    required int cursorOffset,
    int? selectionBaseOffset,
    int? selectionExtentOffset,
    bool pushHistoryBoundary = false,
  }) {
    final document = TextDocument(text: text);
    final nextState = TextOffsetStateSnapshot(
      cursorOffset: cursorOffset,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    ).clamp(document.length);

    if (pushHistoryBoundary) {
      _controller.pushHistoryBoundary();
    }

    _controller.text = text;
    if (nextState.hasSelection) {
      final base = document.positionForOffset(nextState.selectionBaseOffset!);
      final extent = document.positionForOffset(
        nextState.selectionExtentOffset!,
      );
      _controller.setSelection(
        baseLine: base.line,
        baseColumn: base.column,
        extentLine: extent.line,
        extentColumn: extent.column,
      );
    } else {
      final cursor = document.positionForOffset(nextState.cursorOffset);
      _controller.clearSelection();
      _controller.setCursor(cursor.line, cursor.column);
    }

    if (pushHistoryBoundary) {
      _controller.pushHistoryBoundary();
    }
  }

  void applyLineState({
    required List<String> lines,
    required TextPosition cursor,
    TextPosition? selectionBase,
    TextPosition? selectionExtent,
    bool pushHistoryBoundary = false,
  }) {
    final nextLines = lines.isEmpty
        ? const <String>['']
        : List<String>.from(lines);
    final nextState =
        TextLineStateSnapshot(
          cursor: cursor,
          selectionBase: selectionBase,
          selectionExtent: selectionExtent,
        ).clamp(
          lineCount: nextLines.length,
          lineLength: (line) => nextLines[line].length,
        );

    if (pushHistoryBoundary) {
      _controller.pushHistoryBoundary();
    }

    _controller.text = nextLines.join('\n');
    if (nextState.hasSelection) {
      _controller.setSelection(
        baseLine: nextState.selectionBase!.line,
        baseColumn: nextState.selectionBase!.column,
        extentLine: nextState.selectionExtent!.line,
        extentColumn: nextState.selectionExtent!.column,
      );
    } else {
      _controller.clearSelection();
      _controller.setCursor(nextState.cursor.line, nextState.cursor.column);
    }

    if (pushHistoryBoundary) {
      _controller.pushHistoryBoundary();
    }
  }
}
