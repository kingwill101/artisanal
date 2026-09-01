import 'package:artisanal/text_editing.dart'
    show
        TextDocument,
        TextPosition,
        TextOffsetStateSnapshot,
        TextLineStateSnapshot,
        TextCommandResult,
        TextLineCommandResult;
import '_component_foundation.dart';

final class TextAreaControllerCoreBridge {
  TextAreaControllerCoreBridge(this._controller);

  final TextAreaController _controller;

  TextOffsetStateSnapshot currentOffsetStateSnapshot({TextDocument? document}) {
    final resolvedDocument = document ?? _controller.document;
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
    _controller.applyTextCommandResult(
      result,
      pushHistoryBoundary: pushHistoryBoundary,
    );
  }

  void applyTextLineCommandResult(
    TextLineCommandResult result, {
    bool pushHistoryBoundary = true,
  }) {
    _controller.applyTextLineCommandResult(
      result,
      pushHistoryBoundary: pushHistoryBoundary,
    );
  }
}
