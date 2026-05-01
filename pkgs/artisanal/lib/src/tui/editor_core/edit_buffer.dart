library;

import 'editor_state.dart';
import 'state_bridge.dart';
import 'text_commands.dart';
import 'text_document.dart';
import 'text_edit_ops.dart' as edit_ops;
import 'text_editing.dart';
import 'text_view.dart';

enum _EditBufferHistoryAction {
  replaceText,
  insert,
  deleteBackward,
  deleteForward,
  deleteRange,
  newLine,
}

final class EditBuffer {
  EditBuffer({
    String text = '',
    int width = 0,
    int height = 0,
    bool softWrap = true,
    int historyLimit = 100,
  }) : _document = TextDocument(text: text),
       _view = TextView(width: width, height: height, softWrap: softWrap),
       _historyLimit = historyLimit {
    syncEditorStateFromOffsets(_document, _state, cursorOffset: 0);
  }

  factory EditBuffer.fromJournal(Map<String, Object?> journal) {
    final snapshot = _EditBufferSnapshot.fromJson(
      (journal['current'] as Map<Object?, Object?>?)?.cast<String, Object?>() ??
          const <String, Object?>{},
    );
    final buffer = EditBuffer(
      text: snapshot.document.text,
      width: snapshot.width,
      height: snapshot.height,
      softWrap: snapshot.softWrap,
      historyLimit: (journal['historyLimit'] as int?) ?? 100,
    );
    buffer._restoreSnapshot(snapshot);
    buffer.loadJournal(journal);
    return buffer;
  }

  TextDocument _document;
  final EditorState _state = EditorState();
  final TextView _view;
  final int _historyLimit;
  final List<_EditBufferSnapshot> _undoStack = <_EditBufferSnapshot>[];
  final List<_EditBufferSnapshot> _redoStack = <_EditBufferSnapshot>[];
  final List<_EditBufferTransaction> _transactions = <_EditBufferTransaction>[];
  _EditBufferHistoryAction? _lastAction;
  ({int cursor, int length})? _lastMarker;
  int _desiredDisplayColumn = -1;

  TextDocument get document => _document;
  EditorState get state => _state;
  TextView get view => _view;

  String get text => _document.text;
  int get length => _document.length;
  int get lineCount => _document.lineCount;
  TextPosition get cursor => _state.cursor;
  TextSelection? get selection => _state.selection;
  bool get hasSelection => _state.hasSelection;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get transactionDepth => _transactions.length;

  int get width => _view.width;
  set width(int value) => _view.width = value;

  int get height => _view.height;
  set height(int value) => _view.height = value;

  bool get softWrap => _view.softWrap;
  set softWrap(bool value) => _view.softWrap = value;

  int get viewportStartRow => _view.viewportStartRow;
  set viewportStartRow(int value) => _view.viewportStartRow = value;

  int get viewportStartColumn => _view.viewportStartColumn;
  set viewportStartColumn(int value) => _view.viewportStartColumn = value;

  void setText(String text, {bool placeCursorAtEnd = true}) {
    _document = TextDocument(text: text);
    final cursorOffset = placeCursorAtEnd ? _document.length : 0;
    syncEditorStateFromOffsets(_document, _state, cursorOffset: cursorOffset);
    _view.ensureCursorVisible(_document, _state);
    clearHistory();
    _resetDesiredDisplayColumn();
  }

  bool replaceText(String text, {bool placeCursorAtEnd = true}) {
    return _runEditAction(_EditBufferHistoryAction.replaceText, () {
      _recordUndoSnapshot();
      final nextDocument = TextDocument(text: text);
      final nextOffset = placeCursorAtEnd
          ? nextDocument.length
          : _document
                .offsetForPosition(_state.cursor)
                .clamp(0, nextDocument.length);
      _document = nextDocument;
      syncEditorStateFromOffsets(_document, _state, cursorOffset: nextOffset);
      _view.ensureCursorVisible(_document, _state);
      _resetDesiredDisplayColumn();
      return true;
    }, breakChain: true);
  }

  String getText() => text;

  int getLineCount() => lineCount;

  String getTextRange(int startOffset, int endOffset) {
    return _document.textInRange(
      startOffset: startOffset,
      endOffset: endOffset,
    );
  }

  String getTextRangeByCoords(
    int startLine,
    int startColumn,
    int endLine,
    int endColumn,
  ) {
    final start = _document.offsetForPosition(
      TextPosition(line: startLine, column: startColumn),
    );
    final end = _document.offsetForPosition(
      TextPosition(line: endLine, column: endColumn),
    );
    return getTextRange(start, end);
  }

  void setCursor(int line, int column) {
    final clamped = _document.clampPosition(
      TextPosition(line: line, column: column),
    );
    _state.moveCursorTo(clamped);
    _view.ensureCursorVisible(_document, _state);
    _resetDesiredDisplayColumn();
  }

  void gotoLine(int line) {
    final nextLine = line.clamp(0, _document.lineCount - 1);
    setCursor(nextLine, 0);
  }

  void setCursorByOffset(int offset) {
    syncEditorStateFromOffsets(
      _document,
      _state,
      cursorOffset: offset.clamp(0, _document.length),
    );
    _view.ensureCursorVisible(_document, _state);
    _resetDesiredDisplayColumn();
  }

  void setSelection({
    required TextPosition base,
    required TextPosition extent,
    TextPosition? cursor,
  }) {
    final clampedBase = _document.clampPosition(base);
    final clampedExtent = _document.clampPosition(extent);
    _state.setSelection(
      base: clampedBase,
      extent: clampedExtent,
      cursor: cursor == null ? null : _document.clampPosition(cursor),
    );
    _view.ensureCursorVisible(_document, _state);
    _resetDesiredDisplayColumn();
  }

  void clearSelection() {
    _state.clearSelection();
    _resetDesiredDisplayColumn();
  }

  bool insertText(String text) {
    return _runEditAction(_EditBufferHistoryAction.insert, () {
      _recordUndoSnapshot();
      return _applyEditCommandResult(
        _currentOffsetStateSnapshot().insertTextDocumentCommand(
          _document,
          text: text,
        ),
      );
    });
  }

  bool newLine() {
    return _runEditAction(_EditBufferHistoryAction.newLine, () {
      _recordUndoSnapshot();
      return _applyEditCommandResult(
        _currentOffsetStateSnapshot().splitLineDocumentCommand(_document),
      );
    }, breakChain: true);
  }

  bool deleteBackward() {
    return _runEditAction(_EditBufferHistoryAction.deleteBackward, () {
      _recordUndoSnapshot();
      return _applyEditCommandResult(
        _currentOffsetStateSnapshot().deletePreviousDocumentCommand(_document),
      );
    });
  }

  bool deleteForward() {
    return _runEditAction(_EditBufferHistoryAction.deleteForward, () {
      _recordUndoSnapshot();
      return _applyEditCommandResult(
        _currentOffsetStateSnapshot().deleteNextDocumentCommand(_document),
      );
    });
  }

  bool deleteRange(int startLine, int startColumn, int endLine, int endColumn) {
    return _runEditAction(_EditBufferHistoryAction.deleteRange, () {
      final start = _document.offsetForPosition(
        TextPosition(line: startLine, column: startColumn),
      );
      final end = _document.offsetForPosition(
        TextPosition(line: endLine, column: endColumn),
      );
      if (start == end) {
        return false;
      }
      _recordUndoSnapshot();
      final working = _document.copy();
      final result = edit_ops.replaceDocumentTextRange(
        working,
        start: start,
        end: end,
        replacement: '',
      );
      return _applyEditCommandResult(
        TextCommandResult(
          document: working,
          documentChange: result.change,
          cursorOffset: result.change.startOffset,
          changed: result.changed,
        ),
      );
    }, breakChain: true);
  }

  bool moveCursorLeft({bool extendSelection = false}) {
    return _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveByCharacterDocumentCommand(
        _document,
        forward: false,
        extendSelection: extendSelection,
        clearSelection: !extendSelection,
      ),
    );
  }

  bool moveCursorRight({bool extendSelection = false}) {
    return _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveByCharacterDocumentCommand(
        _document,
        forward: true,
        extendSelection: extendSelection,
        clearSelection: !extendSelection,
      ),
    );
  }

  bool moveCursorUp({bool extendSelection = false}) {
    _configureDesiredDisplayColumn();
    return _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveByVisualLineCommand(
        _document,
        _state,
        _view,
        lineDelta: -1,
        desiredDisplayColumn: _desiredDisplayColumn,
        extendSelection: extendSelection,
        clearSelection: !extendSelection,
      ),
    );
  }

  bool moveCursorDown({bool extendSelection = false}) {
    _configureDesiredDisplayColumn();
    return _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveByVisualLineCommand(
        _document,
        _state,
        _view,
        lineDelta: 1,
        desiredDisplayColumn: _desiredDisplayColumn,
        extendSelection: extendSelection,
        clearSelection: !extendSelection,
      ),
    );
  }

  bool moveToDocumentStart({bool extendSelection = false}) {
    return _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveToDocumentBoundaryDocumentCommand(
        _document,
        forward: false,
        extendSelection: extendSelection,
        clearSelection: !extendSelection,
      ),
    );
  }

  bool moveToDocumentEnd({bool extendSelection = false}) {
    return _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveToDocumentBoundaryDocumentCommand(
        _document,
        forward: true,
        extendSelection: extendSelection,
        clearSelection: !extendSelection,
      ),
    );
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _transactions.clear();
    _breakCoalescing();
  }

  void pushHistoryBoundary() {
    _breakCoalescing();
  }

  void beginTransaction() {
    _transactions.add(_EditBufferTransaction(before: _captureSnapshot()));
    _breakCoalescing();
  }

  void commitTransaction() {
    if (_transactions.isEmpty) {
      throw StateError('No active transaction to commit');
    }
    final transaction = _transactions.removeLast();
    if (!transaction.changed) {
      return;
    }
    if (_transactions.isNotEmpty) {
      _transactions.last.changed = true;
      return;
    }
    _pushUndoSnapshot(transaction.before);
    _redoStack.clear();
    _breakCoalescing();
  }

  void rollbackTransaction() {
    if (_transactions.isEmpty) {
      throw StateError('No active transaction to rollback');
    }
    final transaction = _transactions.removeLast();
    _restoreSnapshot(transaction.before);
    _breakCoalescing();
  }

  Map<String, Object?> toJournal() {
    return <String, Object?>{
      'version': 1,
      'historyLimit': _historyLimit,
      'current': _captureSnapshot().toJson(),
      'undo': _undoStack.map((snapshot) => snapshot.toJson()).toList(),
      'redo': _redoStack.map((snapshot) => snapshot.toJson()).toList(),
    };
  }

  void loadJournal(Map<String, Object?> journal) {
    _undoStack
      ..clear()
      ..addAll(_decodeSnapshotStack(journal['undo']));
    _redoStack
      ..clear()
      ..addAll(_decodeSnapshotStack(journal['redo']));
    _transactions.clear();
    _breakCoalescing();
  }

  bool undo() {
    if (_undoStack.isEmpty) {
      return false;
    }
    _redoStack.add(_captureSnapshot());
    final previous = _undoStack.removeLast();
    _restoreSnapshot(previous);
    _view.ensureCursorVisible(_document, _state);
    _resetDesiredDisplayColumn();
    _breakCoalescing();
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) {
      return false;
    }
    _undoStack.add(_captureSnapshot());
    _trimUndoStack();
    final next = _redoStack.removeLast();
    _restoreSnapshot(next);
    _view.ensureCursorVisible(_document, _state);
    _resetDesiredDisplayColumn();
    _breakCoalescing();
    return true;
  }

  TextOffsetStateSnapshot _currentOffsetStateSnapshot() {
    return offsetSnapshotFromEditorState(
      _document,
      _state,
      textLength: _document.length,
    );
  }

  void _recordUndoSnapshot() {
    if (_transactions.isNotEmpty) {
      _transactions.last.changed = true;
    }
  }

  bool _runEditAction(
    _EditBufferHistoryAction action,
    bool Function() body, {
    bool breakChain = false,
  }) {
    if (breakChain) {
      _breakCoalescing();
    }
    final before = _captureSnapshot();
    final changed = body();
    final after = _captureSnapshot();
    if (!_sameSnapshot(before, after)) {
      _recordHistoryChange(before, after, action);
      _view.ensureCursorVisible(_document, _state);
      _resetDesiredDisplayColumn();
    }
    return changed;
  }

  bool _applyEditCommandResult(TextCommandResult result) {
    if (!result.changed) {
      return false;
    }
    _document =
        result.document ?? TextDocument.fromFlatGraphemes(result.graphemes);
    syncEditorStateFromOffsets(
      _document,
      _state,
      cursorOffset: result.cursorOffset,
      selectionBaseOffset: result.selectionBaseOffset,
      selectionExtentOffset: result.selectionExtentOffset,
    );
    return true;
  }

  bool _applyCursorCommandResult(TextCursorCommandResult result) {
    if (!result.changed) {
      return false;
    }
    syncEditorStateFromOffsets(
      _document,
      _state,
      cursorOffset: result.cursorOffset,
      selectionBaseOffset: result.selectionBaseOffset,
      selectionExtentOffset: result.selectionExtentOffset,
    );
    _view.ensureCursorVisible(_document, _state);
    return true;
  }

  void _configureDesiredDisplayColumn() {
    if (_desiredDisplayColumn >= 0) {
      return;
    }
    final cursorOffset = _document.offsetForPosition(_state.cursor);
    final cursor = _document.positionForOffset(cursorOffset);
    _desiredDisplayColumn =
        _view
            .resolveCursorVisualPosition(_document, _state, cursor: cursor)
            ?.displayColumn ??
        0;
  }

  void _restoreSnapshot(_EditBufferSnapshot snapshot) {
    _document = snapshot.document.copy();
    _view
      ..width = snapshot.width
      ..height = snapshot.height
      ..softWrap = snapshot.softWrap
      ..leadingColumns = snapshot.leadingColumns
      ..viewportStartRow = snapshot.viewportStartRow
      ..viewportStartColumn = snapshot.viewportStartColumn
      ..scrollMargin = snapshot.scrollMargin;
    syncEditorStateFromLineSnapshot(
      _state,
      snapshot.state,
      lineCount: _document.lineCount,
      lineLength: _document.lineLength,
    );
  }

  _EditBufferSnapshot _captureSnapshot() {
    return _EditBufferSnapshot(
      document: _document.copy(),
      state: lineSnapshotFromEditorState(
        _state,
        lineCount: _document.lineCount,
        lineLength: _document.lineLength,
      ),
      width: _view.width,
      height: _view.height,
      softWrap: _view.softWrap,
      leadingColumns: _view.leadingColumns,
      viewportStartRow: _view.viewportStartRow,
      viewportStartColumn: _view.viewportStartColumn,
      scrollMargin: _view.scrollMargin,
    );
  }

  void _resetDesiredDisplayColumn() {
    _desiredDisplayColumn = -1;
  }

  void _recordHistoryChange(
    _EditBufferSnapshot before,
    _EditBufferSnapshot after,
    _EditBufferHistoryAction action,
  ) {
    if (_transactions.isNotEmpty) {
      _transactions.last.changed = true;
      return;
    }

    final coalesced = _canCoalesceHistoryAction(
      action,
      lastAction: _lastAction,
      lastMarker: _lastMarker,
      currentState: before,
    );
    if (!coalesced) {
      _pushUndoSnapshot(before);
    }
    _redoStack.clear();
    _lastAction = action;
    _lastMarker = (cursor: after.cursorOffset, length: after.document.length);
  }

  void _pushUndoSnapshot(_EditBufferSnapshot snapshot) {
    if (_undoStack.isNotEmpty && _sameSnapshot(_undoStack.last, snapshot)) {
      return;
    }
    _undoStack.add(snapshot);
    _trimUndoStack();
  }

  void _trimUndoStack() {
    if (_historyLimit <= 0) {
      _undoStack.clear();
      return;
    }
    if (_undoStack.length <= _historyLimit) {
      return;
    }
    _undoStack.removeRange(0, _undoStack.length - _historyLimit);
  }

  void _breakCoalescing() {
    _lastAction = null;
    _lastMarker = null;
  }

  List<_EditBufferSnapshot> _decodeSnapshotStack(Object? raw) {
    if (raw is! List) {
      return const <_EditBufferSnapshot>[];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(
          (json) => _EditBufferSnapshot.fromJson(json.cast<String, Object?>()),
        )
        .toList(growable: false);
  }
}

final class _EditBufferSnapshot {
  const _EditBufferSnapshot({
    required this.document,
    required this.state,
    required this.width,
    required this.height,
    required this.softWrap,
    required this.leadingColumns,
    required this.viewportStartRow,
    required this.viewportStartColumn,
    required this.scrollMargin,
  });

  final TextDocument document;
  final TextLineStateSnapshot state;
  final int width;
  final int height;
  final bool softWrap;
  final int leadingColumns;
  final int viewportStartRow;
  final int viewportStartColumn;
  final double scrollMargin;

  int get cursorOffset => document.offsetForPosition(state.cursor);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'text': document.text,
      'cursorLine': state.cursor.line,
      'cursorColumn': state.cursor.column,
      'selectionBaseLine': state.selectionBase?.line,
      'selectionBaseColumn': state.selectionBase?.column,
      'selectionExtentLine': state.selectionExtent?.line,
      'selectionExtentColumn': state.selectionExtent?.column,
      'width': width,
      'height': height,
      'softWrap': softWrap,
      'leadingColumns': leadingColumns,
      'viewportStartRow': viewportStartRow,
      'viewportStartColumn': viewportStartColumn,
      'scrollMargin': scrollMargin,
    };
  }

  factory _EditBufferSnapshot.fromJson(Map<String, Object?> json) {
    final cursor = TextPosition(
      line: (json['cursorLine'] as int?) ?? 0,
      column: (json['cursorColumn'] as int?) ?? 0,
    );
    final baseLine = json['selectionBaseLine'] as int?;
    final baseColumn = json['selectionBaseColumn'] as int?;
    final extentLine = json['selectionExtentLine'] as int?;
    final extentColumn = json['selectionExtentColumn'] as int?;
    final selectionBase = baseLine == null || baseColumn == null
        ? null
        : TextPosition(line: baseLine, column: baseColumn);
    final selectionExtent = extentLine == null || extentColumn == null
        ? null
        : TextPosition(line: extentLine, column: extentColumn);
    return _EditBufferSnapshot(
      document: TextDocument(text: (json['text'] as String?) ?? ''),
      state: TextLineStateSnapshot(
        cursor: cursor,
        selectionBase: selectionBase,
        selectionExtent: selectionExtent,
      ),
      width: (json['width'] as int?) ?? 0,
      height: (json['height'] as int?) ?? 0,
      softWrap: (json['softWrap'] as bool?) ?? true,
      leadingColumns: (json['leadingColumns'] as int?) ?? 0,
      viewportStartRow: (json['viewportStartRow'] as int?) ?? 0,
      viewportStartColumn: (json['viewportStartColumn'] as int?) ?? 0,
      scrollMargin: (json['scrollMargin'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

final class _EditBufferTransaction {
  _EditBufferTransaction({required this.before});

  final _EditBufferSnapshot before;
  bool changed = false;
}

bool _sameSnapshot(_EditBufferSnapshot a, _EditBufferSnapshot b) {
  final selectionA = a.state.selection;
  final selectionB = b.state.selection;
  return a.document.text == b.document.text &&
      a.state.cursor == b.state.cursor &&
      selectionA?.base == selectionB?.base &&
      selectionA?.extent == selectionB?.extent &&
      a.width == b.width &&
      a.height == b.height &&
      a.softWrap == b.softWrap &&
      a.leadingColumns == b.leadingColumns &&
      a.viewportStartRow == b.viewportStartRow &&
      a.viewportStartColumn == b.viewportStartColumn &&
      a.scrollMargin == b.scrollMargin;
}

bool _canCoalesceHistoryAction(
  _EditBufferHistoryAction action, {
  required _EditBufferHistoryAction? lastAction,
  required ({int cursor, int length})? lastMarker,
  required _EditBufferSnapshot currentState,
}) {
  if (currentState.state.hasSelection) {
    return false;
  }
  if (lastAction != action || lastMarker == null) {
    return false;
  }
  if (lastMarker.cursor != currentState.cursorOffset ||
      lastMarker.length != currentState.document.length) {
    return false;
  }
  return switch (action) {
    _EditBufferHistoryAction.insert => true,
    _EditBufferHistoryAction.deleteBackward => true,
    _EditBufferHistoryAction.deleteForward => true,
    _ => false,
  };
}
