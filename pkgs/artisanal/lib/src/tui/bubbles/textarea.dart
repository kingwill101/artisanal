/// Simplified multi-line textarea bubble to satisfy examples and tests.
library;

import 'dart:math' as math;

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/tui/view.dart';
import 'package:artisanal/src/uv/cursor.dart';
import '../../uv/geometry.dart';
import '../component.dart';
import '../msg.dart';
import '../cmd.dart';
import '../key.dart';
import 'key_binding.dart';
import 'runeutil.dart';
import 'cursor.dart';
import '../../unicode/grapheme.dart' as uni;
import 'text_layout.dart' as layout;

// ─────────────────────────────────────────────────────────────────────────────
// Support types
// ─────────────────────────────────────────────────────────────────────────────

class LineInfo {
  LineInfo({
    this.width = 0,
    this.charWidth = 0,
    this.height = 0,
    this.startColumn = 0,
    this.columnOffset = 0,
    this.rowOffset = 0,
    this.charOffset = 0,
  });

  int width;
  int charWidth;
  int height;
  int startColumn;
  int columnOffset;
  int rowOffset;
  int charOffset;
}

class _DisplayLine {
  _DisplayLine(
    this.text, {
    this.hasCursor = false,
    this.rowIndex = 0,
    this.charOffset = 0,
  });

  final String text;
  final bool hasCursor;
  final int rowIndex;
  final int charOffset;
}

typedef PromptInfo = ({int lineIndex, bool isFocused, int row, int col});
typedef PromptFunc = String Function(PromptInfo info);

class TextAreaStyleState {
  TextAreaStyleState({
    Style? base,
    Style? cursorLine,
    Style? cursorLineNumber,
    Style? endOfBuffer,
    Style? lineNumber,
    Style? placeholder,
    Style? prompt,
    Style? text,
  }) : base = base ?? Style(),
       cursorLine = cursorLine ?? Style(),
       cursorLineNumber = cursorLineNumber ?? Style(),
       endOfBuffer = endOfBuffer ?? Style(),
       lineNumber = lineNumber ?? Style(),
       placeholder = placeholder ?? Style(),
       prompt = prompt ?? Style(),
       text = text ?? Style();

  Style base;
  Style cursorLine;
  Style cursorLineNumber;
  Style endOfBuffer;
  Style lineNumber;
  Style placeholder;
  Style prompt;
  Style text;

  Style get computedCursorLine => cursorLine.inherit(base).inline(true);
  Style get computedCursorLineNumber =>
      cursorLineNumber.inherit(computedCursorLine).inherit(base).inline(true);
  Style get computedEndOfBuffer => endOfBuffer.inherit(base).inline(true);
  Style get computedLineNumber => lineNumber.inherit(base).inline(true);
  Style get computedPlaceholder => placeholder.inherit(base).inline(true);
  Style get computedPrompt => prompt.inherit(base).inline(true);
  Style get computedText => text.inherit(base).inline(true);

  TextAreaStyleState copyWith({
    Style? base,
    Style? cursorLine,
    Style? cursorLineNumber,
    Style? endOfBuffer,
    Style? lineNumber,
    Style? placeholder,
    Style? prompt,
    Style? text,
  }) {
    return TextAreaStyleState(
      base: base ?? this.base,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorLineNumber: cursorLineNumber ?? this.cursorLineNumber,
      endOfBuffer: endOfBuffer ?? this.endOfBuffer,
      lineNumber: lineNumber ?? this.lineNumber,
      placeholder: placeholder ?? this.placeholder,
      prompt: prompt ?? this.prompt,
      text: text ?? this.text,
    );
  }
}

class TextAreaCursorStyle {
  TextAreaCursorStyle({
    this.color,
    this.shape = CursorShape.block,
    this.blink = true,
    this.blinkSpeed = const Duration(milliseconds: 500),
  });

  Color? color;
  CursorShape shape;
  bool blink;
  Duration blinkSpeed;
}

class TextAreaStyles {
  TextAreaStyles({
    TextAreaStyleState? focused,
    TextAreaStyleState? blurred,
    TextAreaCursorStyle? cursor,
  }) : focused = focused ?? TextAreaStyleState(),
       blurred = blurred ?? TextAreaStyleState(),
       cursor = cursor ?? TextAreaCursorStyle();

  TextAreaStyleState focused;
  TextAreaStyleState blurred;
  TextAreaCursorStyle cursor;
}

TextAreaStyles defaultTextAreaStyles() {
  return TextAreaStyles(
    focused: TextAreaStyleState(
      cursorLine: Style().background(const AnsiColor(0)),
      cursorLineNumber: Style().foreground(const AnsiColor(240)),
      endOfBuffer: Style().foreground(const AnsiColor(0)),
      lineNumber: Style().foreground(const AnsiColor(249)),
      placeholder: Style().foreground(const AnsiColor(240)),
      prompt: Style().foreground(const AnsiColor(7)),
      text: Style(),
    ),
    blurred: TextAreaStyleState(
      cursorLine: Style().foreground(const AnsiColor(245)),
      cursorLineNumber: Style().foreground(const AnsiColor(249)),
      endOfBuffer: Style().foreground(const AnsiColor(0)),
      lineNumber: Style().foreground(const AnsiColor(249)),
      placeholder: Style().foreground(const AnsiColor(240)),
      prompt: Style().foreground(const AnsiColor(7)),
      text: Style().foreground(const AnsiColor(245)),
    ),
    cursor: TextAreaCursorStyle(
      color: const AnsiColor(7),
      shape: CursorShape.block,
      blink: true,
    ),
  );
}

class TextAreaPasteMsg implements Msg {
  TextAreaPasteMsg(this.content);
  final String content;
}

class TextAreaPasteErrorMsg implements Msg {
  TextAreaPasteErrorMsg(this.error);
  final Object error;
}

class _TextAreaEditState {
  const _TextAreaEditState({
    required this.value,
    required this.row,
    required this.col,
    required this.selectionStart,
    required this.selectionEnd,
  });

  final String value;
  final int row;
  final int col;
  final (int, int)? selectionStart;
  final (int, int)? selectionEnd;

  bool sameAs(_TextAreaEditState other) {
    return value == other.value &&
        row == other.row &&
        col == other.col &&
        selectionStart == other.selectionStart &&
        selectionEnd == other.selectionEnd;
  }
}

enum _TextAreaHistoryAction {
  insert,
  deleteBackward,
  deleteForward,
  paste,
  setText,
  reset,
  transform,
}

const Map<String, String> _selectionSurroundPairs = {
  '(': ')',
  '[': ']',
  '{': '}',
  '"': '"',
  "'": "'",
  '`': '`',
};

// ─────────────────────────────────────────────────────────────────────────────
// Key map
// ─────────────────────────────────────────────────────────────────────────────

class TextAreaKeyMap implements KeyMap {
  TextAreaKeyMap({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
    KeyBinding? selectAll,
    KeyBinding? selectLine,
    KeyBinding? lineStart,
    KeyBinding? lineEnd,
    KeyBinding? lineNext,
    KeyBinding? linePrevious,
    KeyBinding? insertNewline,
    KeyBinding? deleteBeforeCursor,
    KeyBinding? deleteCharacterForward,
    KeyBinding? deleteWordBackward,
    KeyBinding? deleteWordForward,
    KeyBinding? deleteToLineStart,
    KeyBinding? deleteToLineEnd,
    KeyBinding? deleteAfterCursor,
    KeyBinding? inputBegin,
    KeyBinding? inputEnd,
    KeyBinding? transposeCharacterBackward,
    KeyBinding? uppercaseWordForward,
    KeyBinding? lowercaseWordForward,
    KeyBinding? capitalizeWordForward,
    KeyBinding? copy,
    KeyBinding? undo,
    KeyBinding? redo,
  }) : characterForward =
           characterForward ??
           KeyBinding.withHelp(['right', 'ctrl+f'], '→', 'character forward'),
       characterBackward =
           characterBackward ??
           KeyBinding.withHelp(['left', 'ctrl+b'], '←', 'character backward'),
       wordForward =
           wordForward ??
           KeyBinding.withHelp(['Alt+f'], 'alt+f', 'word forward'),
       wordBackward =
           wordBackward ??
           KeyBinding.withHelp(['Alt+b'], 'alt+b', 'word backward'),
       selectAll =
           selectAll ?? KeyBinding.withHelp(['ctrl+a'], 'ctrl+a', 'select all'),
       selectLine =
           selectLine ??
           KeyBinding.withHelp(['ctrl+l'], 'ctrl+l', 'select line'),
       lineStart =
           lineStart ?? KeyBinding.withHelp(['home'], 'home', 'line start'),
       lineEnd =
           lineEnd ?? KeyBinding.withHelp(['end', 'Ctrl+e'], 'end', 'line end'),
       lineNext =
           lineNext ??
           KeyBinding.withHelp(['down', 'ctrl+n'], '↓', 'next line'),
       linePrevious =
           linePrevious ??
           KeyBinding.withHelp(['up', 'ctrl+p'], '↑', 'previous line'),
       insertNewline =
           insertNewline ??
           KeyBinding.withHelp(['enter'], '↵', 'insert newline'),
       deleteBeforeCursor =
           deleteBeforeCursor ??
           KeyBinding.withHelp(['backspace'], '⌫', 'delete'),
       deleteCharacterForward =
           deleteCharacterForward ??
           KeyBinding.withHelp(['delete', 'ctrl+d'], 'del', 'del char forward'),
       deleteWordBackward =
           deleteWordBackward ??
           KeyBinding.withHelp(['alt+backspace'], 'alt+⌫', 'delete word'),
       deleteWordForward =
           deleteWordForward ??
           KeyBinding.withHelp(['Alt+delete', 'Alt+d'], 'alt+del', 'del word'),
       deleteToLineStart =
           deleteToLineStart ??
           KeyBinding.withHelp(['Ctrl+u'], 'ctrl+u', 'del to start'),
       deleteToLineEnd =
           deleteToLineEnd ??
           KeyBinding.withHelp(['Ctrl+k'], 'ctrl+k', 'del to end'),
       deleteAfterCursor =
           deleteAfterCursor ??
           KeyBinding.withHelp(['Ctrl+k'], 'ctrl+k', 'del after cursor'),
       inputBegin =
           inputBegin ??
           KeyBinding.withHelp(['alt+<', 'ctrl+home'], 'alt+<', 'input start'),
       inputEnd =
           inputEnd ??
           KeyBinding.withHelp(['alt+>', 'ctrl+end'], 'alt+>', 'input end'),
       transposeCharacterBackward =
           transposeCharacterBackward ??
           KeyBinding.withHelp(['Ctrl+t'], 'ctrl+t', 'transpose'),
       uppercaseWordForward =
           uppercaseWordForward ??
           KeyBinding.withHelp(['alt+u'], 'alt+u', 'uppercase word'),
       lowercaseWordForward =
           lowercaseWordForward ??
           KeyBinding.withHelp(['alt+l'], 'alt+l', 'lowercase word'),
       capitalizeWordForward =
           capitalizeWordForward ??
           KeyBinding.withHelp(['alt+c'], 'alt+c', 'capitalize word'),
       copy = copy ?? KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'copy'),
       undo = undo ?? KeyBinding.withHelp(['ctrl+z'], 'ctrl+z', 'undo'),
       redo =
           redo ??
           KeyBinding.withHelp(['ctrl+y', 'ctrl+shift+z'], 'ctrl+y', 'redo');

  final KeyBinding characterForward;
  final KeyBinding characterBackward;
  final KeyBinding wordForward;
  final KeyBinding wordBackward;
  final KeyBinding selectAll;
  final KeyBinding selectLine;
  final KeyBinding lineStart;
  final KeyBinding lineEnd;
  final KeyBinding lineNext;
  final KeyBinding linePrevious;
  final KeyBinding insertNewline;
  final KeyBinding deleteBeforeCursor;
  final KeyBinding deleteCharacterForward;
  final KeyBinding deleteWordBackward;
  final KeyBinding deleteWordForward;
  final KeyBinding deleteToLineStart;
  final KeyBinding deleteToLineEnd;
  final KeyBinding deleteAfterCursor;
  final KeyBinding inputBegin;
  final KeyBinding inputEnd;
  final KeyBinding transposeCharacterBackward;
  final KeyBinding uppercaseWordForward;
  final KeyBinding lowercaseWordForward;
  final KeyBinding capitalizeWordForward;
  final KeyBinding copy;
  final KeyBinding undo;
  final KeyBinding redo;

  TextAreaKeyMap copyWith({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
    KeyBinding? selectAll,
    KeyBinding? selectLine,
    KeyBinding? lineStart,
    KeyBinding? lineEnd,
    KeyBinding? lineNext,
    KeyBinding? linePrevious,
    KeyBinding? insertNewline,
    KeyBinding? deleteBeforeCursor,
    KeyBinding? deleteCharacterForward,
    KeyBinding? deleteWordBackward,
    KeyBinding? deleteWordForward,
    KeyBinding? deleteToLineStart,
    KeyBinding? deleteToLineEnd,
    KeyBinding? deleteAfterCursor,
    KeyBinding? inputBegin,
    KeyBinding? inputEnd,
    KeyBinding? transposeCharacterBackward,
    KeyBinding? uppercaseWordForward,
    KeyBinding? lowercaseWordForward,
    KeyBinding? capitalizeWordForward,
    KeyBinding? copy,
    KeyBinding? undo,
    KeyBinding? redo,
  }) {
    return TextAreaKeyMap(
      characterForward: characterForward ?? this.characterForward,
      characterBackward: characterBackward ?? this.characterBackward,
      wordForward: wordForward ?? this.wordForward,
      wordBackward: wordBackward ?? this.wordBackward,
      selectAll: selectAll ?? this.selectAll,
      selectLine: selectLine ?? this.selectLine,
      lineStart: lineStart ?? this.lineStart,
      lineEnd: lineEnd ?? this.lineEnd,
      lineNext: lineNext ?? this.lineNext,
      linePrevious: linePrevious ?? this.linePrevious,
      insertNewline: insertNewline ?? this.insertNewline,
      deleteBeforeCursor: deleteBeforeCursor ?? this.deleteBeforeCursor,
      deleteCharacterForward:
          deleteCharacterForward ?? this.deleteCharacterForward,
      deleteWordBackward: deleteWordBackward ?? this.deleteWordBackward,
      deleteWordForward: deleteWordForward ?? this.deleteWordForward,
      deleteToLineStart: deleteToLineStart ?? this.deleteToLineStart,
      deleteToLineEnd: deleteToLineEnd ?? this.deleteToLineEnd,
      deleteAfterCursor: deleteAfterCursor ?? this.deleteAfterCursor,
      inputBegin: inputBegin ?? this.inputBegin,
      inputEnd: inputEnd ?? this.inputEnd,
      transposeCharacterBackward:
          transposeCharacterBackward ?? this.transposeCharacterBackward,
      uppercaseWordForward: uppercaseWordForward ?? this.uppercaseWordForward,
      lowercaseWordForward: lowercaseWordForward ?? this.lowercaseWordForward,
      capitalizeWordForward:
          capitalizeWordForward ?? this.capitalizeWordForward,
      copy: copy ?? this.copy,
      undo: undo ?? this.undo,
      redo: redo ?? this.redo,
    );
  }

  @override
  List<KeyBinding> shortHelp() => [
    characterForward,
    characterBackward,
    wordForward,
    wordBackward,
    lineNext,
    linePrevious,
  ];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [characterBackward, characterForward],
    [wordBackward, wordForward],
    [selectAll, selectLine],
    [lineStart, lineEnd],
    [linePrevious, lineNext],
    [
      deleteBeforeCursor,
      deleteCharacterForward,
      deleteWordBackward,
      deleteWordForward,
      deleteToLineStart,
      deleteToLineEnd,
      deleteAfterCursor,
    ],
    [
      inputBegin,
      inputEnd,
      undo,
      redo,
      transposeCharacterBackward,
      uppercaseWordForward,
      lowercaseWordForward,
      capitalizeWordForward,
    ],
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// TextArea model (simplified)
// ─────────────────────────────────────────────────────────────────────────────

class TextAreaModel extends ViewComponent {
  TextAreaModel({
    this.prompt = '│ ',
    this.placeholder = '',
    this.showLineNumbers = true,
    this.charLimit = 0,
    this.softWrap = true,
    int width = 0,
    int height = 6,
    this.useVirtualCursor = true,
    TextAreaKeyMap? keyMap,
    CursorModel? cursor,
    TextAreaStyles? styles,
  }) : keyMap = keyMap ?? TextAreaKeyMap(),
       cursor = cursor ?? CursorModel(),
       styles = styles ?? defaultTextAreaStyles(),
       _width = width,
       _height = height {
    _lines = [[]];
    _updateVirtualCursorStyle();
  }

  String prompt;
  PromptFunc? promptFunc;
  String placeholder;
  bool showLineNumbers;
  int charLimit;
  bool softWrap;
  TextAreaKeyMap keyMap;

  /// Whether to use a virtual cursor. If false, use [terminalCursor] to return
  /// a real cursor for rendering.
  bool useVirtualCursor;

  /// Cursor model.
  CursorModel cursor;

  /// Styles for the textarea.
  TextAreaStyles styles;

  bool _focused = false;
  late List<List<String>> _lines;
  int _row = 0;
  int _col = 0;
  int _width;
  int _height;
  int? _promptWidth;
  static const int _maxHistoryEntries = 100;
  final List<_TextAreaEditState> _undoStack = <_TextAreaEditState>[];
  final List<_TextAreaEditState> _redoStack = <_TextAreaEditState>[];
  bool _editFrameActive = false;
  bool _didRecordUndoSnapshot = false;
  _TextAreaHistoryAction? _currentHistoryAction;
  _TextAreaHistoryAction? _lastHistoryAction;
  int? _lastHistoryRowAfter;
  int? _lastHistoryColAfter;
  int? _lastHistoryLengthAfter;

  (int, int)? _selectionStart;
  (int, int)? _selectionEnd;

  // Double click tracking
  DateTime? _lastClickTime;
  (int, int)? _lastClickPos;

  bool get focused => _focused;
  int get line => _row;
  int get column => _col;
  int get width => _width;
  int get height => _height;
  int get lineCount => _lines.length;
  int get length => _totalGraphemeLength();
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasSelection => _hasSelection();

  /// Anchor position of the current selection, if any.
  ({int line, int column})? get selectionBase => _selectionStart == null
      ? null
      : (line: _selectionStart!.$2, column: _selectionStart!.$1);

  /// Active extent position of the current selection, if any.
  ({int line, int column})? get selectionExtent => _selectionEnd == null
      ? null
      : (line: _selectionEnd!.$2, column: _selectionEnd!.$1);

  /// Returns the current value of the textarea.
  String get value => _lines.map((l) => l.join()).join('\n');

  /// Sets the value of the textarea.
  set value(String v) {
    setText(v);
  }

  /// Sets the value of the textarea (method form for API compatibility).
  ///
  /// This is equivalent to using the [value] setter and exists for parity with
  /// the upstream bubbletea Go library. Prefer using `model.value = v` in Dart.
  void setValue(String v) {
    setText(v);
  }

  /// Replaces the text and collapses the cursor at the end.
  void setText(String v, {bool recordHistory = true}) {
    _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.setText, breakChain: true);
      if (recordHistory) {
        _recordUndoSnapshot();
      }
      final limited = _applyCharLimit(v);
      _lines = _parseLines(limited);
      _row = _lines.length - 1;
      _col = _lines.isNotEmpty ? _lines.last.length : 0;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  /// Sets the prompt function.
  void setPromptFunc(int promptWidth, PromptFunc fn) {
    _promptWidth = promptWidth;
    promptFunc = fn;
  }

  /// Returns the text of the line at the given index.
  String lineAt(int i) {
    if (i < 0 || i >= _lines.length) return '';
    return _lines[i].join();
  }

  /// Sets the cursor position.
  void setCursor(int row, int col) {
    _row = row.clamp(0, _lines.length - 1);
    _col = col.clamp(0, _lines[_row].length);
  }

  /// Sets the current selection and places the cursor at the extent.
  void setSelection({
    required int baseLine,
    required int baseColumn,
    required int extentLine,
    required int extentColumn,
  }) {
    final clampedBaseLine = baseLine.clamp(0, _lines.length - 1);
    final clampedExtentLine = extentLine.clamp(0, _lines.length - 1);
    _selectionStart = (
      baseColumn.clamp(0, _lines[clampedBaseLine].length),
      clampedBaseLine,
    );
    _selectionEnd = (
      extentColumn.clamp(0, _lines[clampedExtentLine].length),
      clampedExtentLine,
    );
    _row = clampedExtentLine;
    _col = extentColumn.clamp(0, _lines[_row].length);
  }

  /// Clears the current selection.
  void clearSelection() {
    _selectionStart = null;
    _selectionEnd = null;
  }

  /// Selects the entire textarea contents.
  void selectAll() {
    final lastLine = _lines.length - 1;
    _selectionStart = (0, 0);
    _selectionEnd = (_lines[lastLine].length, lastLine);
    _row = lastLine;
    _col = _lines[lastLine].length;
  }

  /// Selects the current line, or expands the current selection to full lines.
  void selectCurrentLine() {
    final (startLine, endLine) = _selectedLineRange();
    _selectionStart = (0, startLine);
    _selectionEnd = (_lines[endLine].length, endLine);
    _row = endLine;
    _col = _lines[endLine].length;
  }

  /// Returns the current cursor line (0-indexed).
  int cursorLine() => _row;

  /// Returns the current cursor column (0-indexed).
  int cursorColumn() => _col;

  @override
  Cmd? init() => null;

  /// Focuses the textarea.
  Cmd? focus() {
    _focused = true;
    final (newCursor, cmd) = cursor.focus();
    cursor = newCursor;
    _updateVirtualCursorStyle();
    return cmd;
  }

  /// Blurs the textarea.
  void blur() {
    _focused = false;
    cursor = cursor.blur();
    _updateVirtualCursorStyle();
  }

  /// Returns the appropriate style state based on focus.
  TextAreaStyleState activeStyle() =>
      _focused ? styles.focused : styles.blurred;

  T _runEditFrame<T>(T Function() body) {
    final wasActive = _editFrameActive;
    _TextAreaEditState? beforeState;
    if (!wasActive) {
      _editFrameActive = true;
      _didRecordUndoSnapshot = false;
      beforeState = _captureEditState();
    }
    try {
      return body();
    } finally {
      if (!wasActive) {
        _finalizeEditFrame(beforeState!);
        _editFrameActive = false;
        _didRecordUndoSnapshot = false;
        _currentHistoryAction = null;
      }
    }
  }

  _TextAreaEditState _captureEditState() {
    return _TextAreaEditState(
      value: value,
      row: _row,
      col: _col,
      selectionStart: _selectionStart,
      selectionEnd: _selectionEnd,
    );
  }

  void _restoreEditState(_TextAreaEditState state) {
    _lines = _parseLines(state.value);
    _row = state.row.clamp(0, _lines.length - 1);
    _col = state.col.clamp(0, _lines[_row].length);
    _selectionStart = state.selectionStart;
    _selectionEnd = state.selectionEnd;
  }

  void _beginHistoryAction(
    _TextAreaHistoryAction action, {
    bool breakChain = false,
  }) {
    if (breakChain) {
      _breakHistoryCoalescing();
    }
    _currentHistoryAction = action;
  }

  void _breakHistoryCoalescing() {
    _currentHistoryAction = null;
    _lastHistoryAction = null;
    _lastHistoryRowAfter = null;
    _lastHistoryColAfter = null;
    _lastHistoryLengthAfter = null;
  }

  bool _hasSelection() =>
      _selectionStart != null &&
      _selectionEnd != null &&
      _selectionStart != _selectionEnd;

  bool _shouldCoalesceSnapshot(_TextAreaHistoryAction action) {
    if (_hasSelection()) return false;
    if (_lastHistoryAction != action) return false;
    if (_lastHistoryRowAfter != _row) return false;
    if (_lastHistoryColAfter != _col) return false;
    if (_lastHistoryLengthAfter != length) return false;
    return switch (action) {
      _TextAreaHistoryAction.insert => true,
      _TextAreaHistoryAction.deleteBackward => true,
      _TextAreaHistoryAction.deleteForward => true,
      _TextAreaHistoryAction.paste => true,
      _ => false,
    };
  }

  void _recordUndoSnapshot() {
    if (_editFrameActive && _didRecordUndoSnapshot) {
      return;
    }
    final action = _currentHistoryAction;
    if (action != null && _shouldCoalesceSnapshot(action)) {
      _didRecordUndoSnapshot = true;
      return;
    }
    final snapshot = _captureEditState();
    if (_undoStack.isNotEmpty && _undoStack.last.sameAs(snapshot)) {
      _didRecordUndoSnapshot = true;
      return;
    }
    _undoStack.add(snapshot);
    if (_undoStack.length > _maxHistoryEntries) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _didRecordUndoSnapshot = true;
  }

  void _finalizeEditFrame(_TextAreaEditState beforeState) {
    final action = _currentHistoryAction;
    final afterState = _captureEditState();
    if (beforeState.sameAs(afterState)) {
      if (action == null) {
        _breakHistoryCoalescing();
      }
      return;
    }
    if (action == null) {
      _breakHistoryCoalescing();
      return;
    }
    _lastHistoryAction = action;
    _lastHistoryRowAfter = afterState.row;
    _lastHistoryColAfter = afterState.col;
    _lastHistoryLengthAfter = uni.graphemes(afterState.value).length;
  }

  /// Returns a [Cursor] for rendering a real cursor in a TUI program.
  /// This requires that [useVirtualCursor] is set to false.
  Cursor? get terminalCursor {
    if (useVirtualCursor || !_focused) return null;

    // This is a simplified calculation. Real textarea would need to account
    // for scrolling, line numbers, and soft wrapping.
    final promptWidth = _getPromptWidth(0);
    final x = _col + promptWidth;
    final y = _row;

    return Cursor(
      position: Position(x, y),
      color: styles.cursor.color,
      shape: styles.cursor.shape,
      blink: styles.cursor.blink,
    );
  }

  void _updateVirtualCursorStyle() {
    if (!useVirtualCursor) {
      final (newCursor, _) = cursor.setMode(CursorMode.hide);
      cursor = newCursor;
      return;
    }

    cursor = cursor.copyWith(style: Style().foreground(styles.cursor.color!));

    if (styles.cursor.blink) {
      final (newCursor, _) = cursor.setMode(CursorMode.blink);
      cursor = newCursor;
    } else {
      final (newCursor, _) = cursor.setMode(CursorMode.static);
      cursor = newCursor;
    }
  }

  int _getPromptWidth(int lineIndex) {
    if (_promptWidth != null) return _promptWidth!;
    if (promptFunc != null) {
      return stringWidth(
        promptFunc!((
          lineIndex: lineIndex,
          isFocused: _focused,
          row: _row,
          col: _col,
        )),
      );
    }
    return stringWidth(prompt);
  }

  /// Returns whether the textarea is focused.
  bool isFocused() => _focused;

  void reset() {
    _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.reset, breakChain: true);
      _recordUndoSnapshot();
      _lines = [[]];
      _row = 0;
      _col = 0;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  /// Clears all undo and redo history.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _breakHistoryCoalescing();
  }

  /// Breaks the current undo coalescing chain.
  void pushHistoryBoundary() {
    _breakHistoryCoalescing();
  }

  /// Indents the selected lines, or the current line if there is no selection.
  bool indentLines({int width = 2}) {
    final indentWidth = width < 1 ? 1 : width;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final (startLine, endLine) = _selectedLineRange();
      final deltas = <int, int>{};
      final indent = List<String>.filled(indentWidth, ' ', growable: false);

      _recordUndoSnapshot();
      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        _lines[lineIndex].insertAll(0, indent);
        deltas[lineIndex] = indentWidth;
      }

      _applyLineColumnDeltas(deltas);
      return true;
    });
  }

  /// Outdents the selected lines, or the current line if there is no selection.
  bool outdentLines({int width = 2}) {
    final indentWidth = width < 1 ? 1 : width;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final (startLine, endLine) = _selectedLineRange();
      final removalCounts = <int, int>{};
      var changed = false;

      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final removalCount = _leadingIndentRemovalCount(
          _lines[lineIndex],
          indentWidth,
        );
        removalCounts[lineIndex] = removalCount;
        changed = changed || removalCount > 0;
      }

      if (!changed) {
        return false;
      }

      _recordUndoSnapshot();
      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final removalCount = removalCounts[lineIndex]!;
        if (removalCount == 0) continue;
        _lines[lineIndex].removeRange(0, removalCount);
        removalCounts[lineIndex] = -removalCount;
      }

      _applyLineColumnDeltas(removalCounts);
      return true;
    });
  }

  /// Moves the selected lines, or the current line, one row upward.
  bool moveLinesUp() {
    return _moveSelectedLines(-1);
  }

  /// Moves the selected lines, or the current line, one row downward.
  bool moveLinesDown() {
    return _moveSelectedLines(1);
  }

  /// Duplicates the selected lines, or the current line, above the current
  /// block and moves the selection/cursor to the duplicate.
  bool duplicateLinesAbove() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final (startLine, endLine) = _selectedLineRange();
      final blockHeight = endLine - startLine + 1;
      final hadSelection = _hasSelection();
      final duplicatedLines = _lines
          .sublist(startLine, endLine + 1)
          .map((line) => List<String>.from(line))
          .toList(growable: false);

      _recordUndoSnapshot();
      _lines.insertAll(startLine, duplicatedLines);

      if (hadSelection) {
        _selectionStart = _duplicateAbovePoint(
          _selectionStart,
          startLine: startLine,
          endLine: endLine,
          delta: blockHeight,
        );
        _selectionEnd = _duplicateAbovePoint(
          _selectionEnd,
          startLine: startLine,
          endLine: endLine,
          delta: blockHeight,
        );
      } else {
        _selectionStart = null;
        _selectionEnd = null;
      }

      if (_row > endLine) {
        _row = (_row + blockHeight).clamp(0, _lines.length - 1);
      }
      _col = _col.clamp(0, _lines[_row].length);
      return true;
    });
  }

  /// Duplicates the selected lines, or the current line, below the current
  /// block and moves the selection/cursor to the duplicate.
  bool duplicateLinesBelow() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final (startLine, endLine) = _selectedLineRange();
      final blockHeight = endLine - startLine + 1;
      final hadSelection = _hasSelection();
      final duplicatedLines = _lines
          .sublist(startLine, endLine + 1)
          .map((line) => List<String>.from(line))
          .toList(growable: false);

      _recordUndoSnapshot();
      _lines.insertAll(endLine + 1, duplicatedLines);

      if (hadSelection) {
        _selectionStart = _shiftPointRowRange(
          _selectionStart,
          startLine: startLine,
          endLine: endLine,
          delta: blockHeight,
        );
        _selectionEnd = _shiftPointRowRange(
          _selectionEnd,
          startLine: startLine,
          endLine: endLine,
          delta: blockHeight,
        );
      } else {
        _selectionStart = null;
        _selectionEnd = null;
      }

      if (_row >= startLine && _row <= endLine) {
        _row = (_row + blockHeight).clamp(0, _lines.length - 1);
        _col = _col.clamp(0, _lines[_row].length);
      }
      return true;
    });
  }

  /// Cleans up trailing horizontal whitespace in the selected block, or the
  /// entire buffer when there is no selection.
  ///
  /// When operating on the entire buffer, this also removes extra trailing
  /// blank lines from the end of the document while keeping at least one line.
  bool cleanupWhitespace({bool trimTrailingBlankLines = true}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final hasSelection = _hasSelection();
      final (startLine, endLine) = hasSelection
          ? _selectedLineRange()
          : (0, _lines.length - 1);
      final trimmedLengths = <int, int>{};
      var changed = false;

      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final trimmedLength = _trailingHorizontalTrimLength(_lines[lineIndex]);
        trimmedLengths[lineIndex] = trimmedLength;
        changed = changed || trimmedLength != _lines[lineIndex].length;
      }

      var removedTrailingLines = 0;
      if (!hasSelection && trimTrailingBlankLines) {
        var lineIndex = _lines.length - 1;
        while (lineIndex > 0 && trimmedLengths[lineIndex] == 0) {
          removedTrailingLines++;
          lineIndex--;
        }
        changed = changed || removedTrailingLines > 0;
      }

      if (!changed) {
        return false;
      }

      _recordUndoSnapshot();
      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final trimmedLength = trimmedLengths[lineIndex]!;
        if (trimmedLength == _lines[lineIndex].length) continue;
        _lines[lineIndex].removeRange(trimmedLength, _lines[lineIndex].length);
      }

      if (!hasSelection && removedTrailingLines > 0) {
        _lines.removeRange(_lines.length - removedTrailingLines, _lines.length);
      }

      if (_row >= _lines.length) {
        _row = _lines.length - 1;
        _col = _lines[_row].length;
      } else {
        _row = _row.clamp(0, _lines.length - 1);
        _col = _col.clamp(0, _lines[_row].length);
      }
      _selectionStart = _clampPointToBuffer(_selectionStart);
      _selectionEnd = _clampPointToBuffer(_selectionEnd);
      return true;
    });
  }

  /// Deletes the selected lines, or the current line if there is no selection.
  bool deleteLines() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final (startLine, endLine) = _selectedLineRange();
      final deletedCount = endLine - startLine + 1;

      _recordUndoSnapshot();
      if (deletedCount >= _lines.length) {
        _lines = [[]];
        _row = 0;
        _col = 0;
        _selectionStart = null;
        _selectionEnd = null;
        return true;
      }

      _lines.removeRange(startLine, endLine + 1);
      if (_row > endLine) {
        _row -= deletedCount;
      } else if (_row >= startLine) {
        _row = startLine.clamp(0, _lines.length - 1);
      }
      _col = _col.clamp(0, _lines[_row].length);
      _selectionStart = null;
      _selectionEnd = null;
      return true;
    });
  }

  /// Joins the current line with the next line, or joins the selected block
  /// into a single line.
  bool joinLines() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final (startLine, selectedEndLine) = _selectedLineRange();
      final endLine = _hasSelection()
          ? selectedEndLine
          : math.min(startLine + 1, _lines.length - 1);
      if (startLine >= endLine) {
        return false;
      }

      _recordUndoSnapshot();
      final joined = List<String>.from(_lines[startLine]);
      for (var lineIndex = startLine + 1; lineIndex <= endLine; lineIndex++) {
        final trimmed = _trimLeadingHorizontalWhitespace(_lines[lineIndex]);
        final separator = _lineJoinSeparator(joined, trimmed);
        if (separator.isNotEmpty) {
          joined.add(separator);
        }
        joined.addAll(trimmed);
      }

      _lines[startLine] = joined;
      _lines.removeRange(startLine + 1, endLine + 1);
      _row = startLine;
      _col = joined.length;
      _selectionStart = null;
      _selectionEnd = null;
      return true;
    });
  }

  /// Splits the current line at the cursor, or replaces the selected range
  /// with a newline and places the cursor at the start of the new line.
  bool splitLine() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final flat = _flattenWithNewlines();
      var start = _globalOffset();
      var end = start;
      if (_hasSelection()) {
        start = _globalOffsetForPoint(_selectionStart!);
        end = _globalOffsetForPoint(_selectionEnd!);
        if (start > end) {
          final tmp = start;
          start = end;
          end = tmp;
        }
      }

      _recordUndoSnapshot();
      flat.replaceRange(start, end, const ['\n']);
      _setValueAndCursor(flat.join(), start + 1);
      _selectionStart = null;
      _selectionEnd = null;
      return true;
    });
  }

  /// Uppercases the selected range, or the current line when there is no
  /// selection.
  bool uppercaseSelectionOrLine() {
    return _transformSelectionOrLine((text) => text.toUpperCase());
  }

  /// Lowercases the selected range, or the current line when there is no
  /// selection.
  bool lowercaseSelectionOrLine() {
    return _transformSelectionOrLine((text) => text.toLowerCase());
  }

  /// Capitalizes words in the selected range, or the current line when there
  /// is no selection.
  bool capitalizeSelectionOrLine() {
    return _transformSelectionOrLine(_capitalizeWords);
  }

  /// Sorts the selected lines, or the entire buffer when there is no
  /// selection.
  bool sortSelectedLines({
    bool descending = false,
    bool caseSensitive = false,
  }) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final hasSelection = _hasSelection();
      final (startLine, endLine) = hasSelection
          ? _selectedLineRange()
          : (0, _lines.length - 1);
      if (startLine >= endLine) {
        return false;
      }

      final originalTexts = _lines
          .sublist(startLine, endLine + 1)
          .map((line) => line.join())
          .toList(growable: false);
      final sortedLines = _lines
          .sublist(startLine, endLine + 1)
          .map((line) => List<String>.from(line))
          .toList();
      sortedLines.sort(
        (a, b) => _compareLineContent(
          a,
          b,
          descending: descending,
          caseSensitive: caseSensitive,
        ),
      );
      final sortedTexts = sortedLines
          .map((line) => line.join())
          .toList(growable: false);
      if (_listStringEquals(originalTexts, sortedTexts)) {
        return false;
      }

      _recordUndoSnapshot();
      _lines.replaceRange(startLine, endLine + 1, sortedLines);
      _row = _row.clamp(0, _lines.length - 1);
      _col = _col.clamp(0, _lines[_row].length);
      _selectionStart = _clampPointToBuffer(_selectionStart);
      _selectionEnd = _clampPointToBuffer(_selectionEnd);
      return true;
    });
  }

  /// Toggles [prefix] on the current line or selected block.
  ///
  /// The prefix is inserted after leading indentation, and a single space is
  /// added before non-empty content when [addSpaceWhenNonEmpty] is `true`.
  bool toggleLinePrefix(
    String prefix, {
    bool addSpaceWhenNonEmpty = true,
    bool skipBlankLinesWhenChecking = true,
  }) {
    if (prefix.isEmpty) return false;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final lineTexts = _lines
          .map((line) => line.join())
          .toList(growable: true);
      if (lineTexts.isEmpty) {
        return false;
      }

      final row = _row.clamp(0, lineTexts.length - 1);
      final hasSelection =
          _hasSelection() && _selectionStart != null && _selectionEnd != null;
      final startLine = hasSelection
          ? math.min(_selectionStart!.$2, _selectionEnd!.$2)
          : row;
      final endLine = hasSelection
          ? math.max(_selectionStart!.$2, _selectionEnd!.$2)
          : row;

      var hasRelevantLine = false;
      var allPrefixed = true;
      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final body = line.substring(leadingWhitespace);
        if (skipBlankLinesWhenChecking && body.trim().isEmpty) {
          continue;
        }
        hasRelevantLine = true;
        if (!body.startsWith(prefix)) {
          allPrefixed = false;
          break;
        }
      }
      if (!hasRelevantLine) {
        allPrefixed = false;
      }

      var adjustedBase = _selectionStart;
      var adjustedExtent = _selectionEnd;
      var nextColumn = _col;

      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final indent = line.substring(0, leadingWhitespace);
        final body = line.substring(leadingWhitespace);
        final wasPrefixed = body.startsWith(prefix);
        final hadTrailingSpace = wasPrefixed && body.length > prefix.length
            ? body.substring(prefix.length).startsWith(' ')
            : false;
        final removeCount = prefix.length + (hadTrailingSpace ? 1 : 0);
        final addCount =
            prefix.length + (addSpaceWhenNonEmpty && body.isNotEmpty ? 1 : 0);

        lineTexts[lineIndex] = allPrefixed && wasPrefixed
            ? '$indent${body.substring(removeCount)}'
            : '$indent$prefix${addSpaceWhenNonEmpty && body.isNotEmpty ? ' ' : ''}$body';

        if (!allPrefixed) {
          if (lineIndex == row) {
            nextColumn = _adjustLinePrefixColumn(
              column: nextColumn,
              leadingWhitespace: leadingWhitespace,
              delta: addCount,
              remove: false,
            );
          }
          adjustedBase = _adjustLinePrefixPoint(
            adjustedBase,
            line: lineIndex,
            leadingWhitespace: leadingWhitespace,
            delta: addCount,
            remove: false,
          );
          adjustedExtent = _adjustLinePrefixPoint(
            adjustedExtent,
            line: lineIndex,
            leadingWhitespace: leadingWhitespace,
            delta: addCount,
            remove: false,
          );
          continue;
        }

        if (lineIndex == row) {
          nextColumn = _adjustLinePrefixColumn(
            column: nextColumn,
            leadingWhitespace: leadingWhitespace,
            delta: removeCount,
            remove: true,
          );
        }
        adjustedBase = _adjustLinePrefixPoint(
          adjustedBase,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: removeCount,
          remove: true,
        );
        adjustedExtent = _adjustLinePrefixPoint(
          adjustedExtent,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: removeCount,
          remove: true,
        );
      }

      final nextValue = lineTexts.join('\n');
      if (nextValue == value) {
        return false;
      }

      _recordUndoSnapshot();
      _lines = _parseLines(nextValue);
      if (hasSelection && adjustedBase != null && adjustedExtent != null) {
        _selectionStart = _clampPointToBuffer(adjustedBase);
        _selectionEnd = _clampPointToBuffer(adjustedExtent);
        _row = _selectionEnd!.$2;
        _col = _selectionEnd!.$1;
      } else {
        _selectionStart = null;
        _selectionEnd = null;
        _row = row.clamp(0, _lines.length - 1);
        _col = nextColumn.clamp(0, _lines[_row].length);
      }
      return true;
    });
  }

  /// Toggles numbered list prefixes on the current line or selected block.
  ///
  /// When adding numbering, non-blank lines are numbered sequentially starting
  /// at [startAt]. Blank lines are left unchanged.
  bool toggleNumberedList({int startAt = 1}) {
    final initialNumber = startAt < 1 ? 1 : startAt;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final lineTexts = _lines
          .map((line) => line.join())
          .toList(growable: true);
      if (lineTexts.isEmpty) {
        return false;
      }

      final row = _row.clamp(0, lineTexts.length - 1);
      final hasSelection =
          _hasSelection() && _selectionStart != null && _selectionEnd != null;
      final startLine = hasSelection
          ? math.min(_selectionStart!.$2, _selectionEnd!.$2)
          : row;
      final endLine = hasSelection
          ? math.max(_selectionStart!.$2, _selectionEnd!.$2)
          : row;

      var hasRelevantLine = false;
      var allNumbered = true;
      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final body = line.substring(leadingWhitespace);
        if (body.trim().isEmpty) {
          continue;
        }
        hasRelevantLine = true;
        if (_leadingNumberedPrefixLength(body) == null) {
          allNumbered = false;
          break;
        }
      }

      var adjustedBase = _selectionStart;
      var adjustedExtent = _selectionEnd;
      var nextColumn = _col;
      var nextNumber = initialNumber;

      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final indent = line.substring(0, leadingWhitespace);
        final body = line.substring(leadingWhitespace);
        final numberedPrefixLength = _leadingNumberedPrefixLength(body);
        final isBlank = body.trim().isEmpty;
        if (isBlank && hasRelevantLine) {
          continue;
        }

        final addPrefix = '${nextNumber++}. ';
        final removeCount = numberedPrefixLength ?? 0;
        final addCount = addPrefix.length;

        lineTexts[lineIndex] = allNumbered && removeCount > 0
            ? '$indent${body.substring(removeCount)}'
            : '$indent$addPrefix$body';

        if (!allNumbered) {
          if (lineIndex == row) {
            nextColumn = _adjustLinePrefixColumn(
              column: nextColumn,
              leadingWhitespace: leadingWhitespace,
              delta: addCount,
              remove: false,
            );
          }
          adjustedBase = _adjustLinePrefixPoint(
            adjustedBase,
            line: lineIndex,
            leadingWhitespace: leadingWhitespace,
            delta: addCount,
            remove: false,
          );
          adjustedExtent = _adjustLinePrefixPoint(
            adjustedExtent,
            line: lineIndex,
            leadingWhitespace: leadingWhitespace,
            delta: addCount,
            remove: false,
          );
          continue;
        }

        if (lineIndex == row) {
          nextColumn = _adjustLinePrefixColumn(
            column: nextColumn,
            leadingWhitespace: leadingWhitespace,
            delta: removeCount,
            remove: true,
          );
        }
        adjustedBase = _adjustLinePrefixPoint(
          adjustedBase,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: removeCount,
          remove: true,
        );
        adjustedExtent = _adjustLinePrefixPoint(
          adjustedExtent,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: removeCount,
          remove: true,
        );
      }

      final nextValue = lineTexts.join('\n');
      if (nextValue == value) {
        return false;
      }

      _recordUndoSnapshot();
      _lines = _parseLines(nextValue);
      if (hasSelection && adjustedBase != null && adjustedExtent != null) {
        _selectionStart = _clampPointToBuffer(adjustedBase);
        _selectionEnd = _clampPointToBuffer(adjustedExtent);
        _row = _selectionEnd!.$2;
        _col = _selectionEnd!.$1;
      } else {
        _selectionStart = null;
        _selectionEnd = null;
        _row = row.clamp(0, _lines.length - 1);
        _col = nextColumn.clamp(0, _lines[_row].length);
      }
      return true;
    });
  }

  /// Renumbers existing numbered list items in the current line or selected
  /// block.
  ///
  /// Only lines that already begin with a numbered list prefix are rewritten.
  /// Other lines are left unchanged.
  bool renumberNumberedList({int startAt = 1}) {
    final initialNumber = startAt < 1 ? 1 : startAt;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final lineTexts = _lines
          .map((line) => line.join())
          .toList(growable: true);
      if (lineTexts.isEmpty) {
        return false;
      }

      final row = _row.clamp(0, lineTexts.length - 1);
      final hasSelection =
          _hasSelection() && _selectionStart != null && _selectionEnd != null;
      final startLine = hasSelection
          ? math.min(_selectionStart!.$2, _selectionEnd!.$2)
          : row;
      final endLine = hasSelection
          ? math.max(_selectionStart!.$2, _selectionEnd!.$2)
          : row;

      var hasNumberedLine = false;
      var adjustedBase = _selectionStart;
      var adjustedExtent = _selectionEnd;
      var nextColumn = _col;
      var nextNumber = initialNumber;

      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final indent = line.substring(0, leadingWhitespace);
        final body = line.substring(leadingWhitespace);
        final numberedPrefixLength = _leadingNumberedPrefixLength(body);
        if (numberedPrefixLength == null) {
          continue;
        }

        hasNumberedLine = true;
        final nextPrefix = '${nextNumber++}. ';
        final nextLine =
            '$indent$nextPrefix${body.substring(numberedPrefixLength)}';
        final delta = nextPrefix.length - numberedPrefixLength;
        lineTexts[lineIndex] = nextLine;

        if (delta == 0) {
          continue;
        }

        if (lineIndex == row) {
          nextColumn = _adjustLinePrefixColumnDelta(
            column: nextColumn,
            leadingWhitespace: leadingWhitespace,
            delta: delta,
          );
        }
        adjustedBase = _adjustLinePrefixPointDelta(
          adjustedBase,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: delta,
        );
        adjustedExtent = _adjustLinePrefixPointDelta(
          adjustedExtent,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: delta,
        );
      }

      if (!hasNumberedLine) {
        return false;
      }

      final nextValue = lineTexts.join('\n');
      if (nextValue == value) {
        return false;
      }

      _recordUndoSnapshot();
      _lines = _parseLines(nextValue);
      if (hasSelection && adjustedBase != null && adjustedExtent != null) {
        _selectionStart = _clampPointToBuffer(adjustedBase);
        _selectionEnd = _clampPointToBuffer(adjustedExtent);
        _row = _selectionEnd!.$2;
        _col = _selectionEnd!.$1;
      } else {
        _selectionStart = null;
        _selectionEnd = null;
        _row = row.clamp(0, _lines.length - 1);
        _col = nextColumn.clamp(0, _lines[_row].length);
      }
      return true;
    });
  }

  /// Toggles Markdown heading prefixes on the current line or selected block.
  ///
  /// When all relevant lines already use the requested heading [level], that
  /// prefix is removed. Otherwise, existing heading prefixes are normalized to
  /// the requested level and missing prefixes are added.
  bool toggleHeadingPrefix({int level = 1}) {
    final targetLevel = level.clamp(1, 6);
    final targetPrefix = '${'#' * targetLevel} ';
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final lineTexts = _lines
          .map((line) => line.join())
          .toList(growable: true);
      if (lineTexts.isEmpty) {
        return false;
      }

      final row = _row.clamp(0, lineTexts.length - 1);
      final hasSelection =
          _hasSelection() && _selectionStart != null && _selectionEnd != null;
      final startLine = hasSelection
          ? math.min(_selectionStart!.$2, _selectionEnd!.$2)
          : row;
      final endLine = hasSelection
          ? math.max(_selectionStart!.$2, _selectionEnd!.$2)
          : row;

      var hasRelevantLine = false;
      var allAtTargetLevel = true;
      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final body = line.substring(leadingWhitespace);
        final headingPrefix = _leadingHeadingPrefix(body);
        if (body.trim().isEmpty && headingPrefix == null) {
          continue;
        }
        hasRelevantLine = true;
        if (headingPrefix == null || headingPrefix.level != targetLevel) {
          allAtTargetLevel = false;
          break;
        }
      }
      if (!hasRelevantLine) {
        return false;
      }

      var adjustedBase = _selectionStart;
      var adjustedExtent = _selectionEnd;
      var nextColumn = _col;

      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final indent = line.substring(0, leadingWhitespace);
        final body = line.substring(leadingWhitespace);
        final headingPrefix = _leadingHeadingPrefix(body);
        if (body.trim().isEmpty && headingPrefix == null) {
          continue;
        }

        final removeCount = headingPrefix?.length ?? 0;
        final nextBody = removeCount > 0 ? body.substring(removeCount) : body;
        final delta = allAtTargetLevel
            ? -removeCount
            : targetPrefix.length - removeCount;
        lineTexts[lineIndex] = allAtTargetLevel
            ? '$indent$nextBody'
            : '$indent$targetPrefix$nextBody';

        if (delta == 0) {
          continue;
        }

        if (lineIndex == row) {
          nextColumn = _adjustLinePrefixColumnDelta(
            column: nextColumn,
            leadingWhitespace: leadingWhitespace,
            delta: delta,
          );
        }
        adjustedBase = _adjustLinePrefixPointDelta(
          adjustedBase,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: delta,
        );
        adjustedExtent = _adjustLinePrefixPointDelta(
          adjustedExtent,
          line: lineIndex,
          leadingWhitespace: leadingWhitespace,
          delta: delta,
        );
      }

      final nextValue = lineTexts.join('\n');
      if (nextValue == value) {
        return false;
      }

      _recordUndoSnapshot();
      _lines = _parseLines(nextValue);
      if (hasSelection && adjustedBase != null && adjustedExtent != null) {
        _selectionStart = _clampPointToBuffer(adjustedBase);
        _selectionEnd = _clampPointToBuffer(adjustedExtent);
        _row = _selectionEnd!.$2;
        _col = _selectionEnd!.$1;
      } else {
        _selectionStart = null;
        _selectionEnd = null;
        _row = row.clamp(0, _lines.length - 1);
        _col = nextColumn.clamp(0, _lines[_row].length);
      }
      return true;
    });
  }

  /// Toggles checklist completion state on the current line or selected block.
  ///
  /// When all relevant checklist items are checked, they are cleared back to
  /// unchecked state. Otherwise all relevant items are marked with
  /// [checkedMarker].
  bool toggleChecklistState({String checkedMarker = 'x'}) {
    final marker = checkedMarker.isEmpty ? 'x' : checkedMarker[0];
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final lineTexts = _lines
          .map((line) => line.join())
          .toList(growable: true);
      if (lineTexts.isEmpty) {
        return false;
      }

      final row = _row.clamp(0, lineTexts.length - 1);
      final hasSelection =
          _hasSelection() && _selectionStart != null && _selectionEnd != null;
      final startLine = hasSelection
          ? math.min(_selectionStart!.$2, _selectionEnd!.$2)
          : row;
      final endLine = hasSelection
          ? math.max(_selectionStart!.$2, _selectionEnd!.$2)
          : row;

      var hasChecklist = false;
      var allChecked = true;
      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final body = line.substring(leadingWhitespace);
        final prefixLength = _leadingChecklistPrefixLength(body);
        if (prefixLength == null) {
          continue;
        }
        hasChecklist = true;
        if (!_isChecklistChecked(body)) {
          allChecked = false;
          break;
        }
      }
      if (!hasChecklist) {
        return false;
      }

      for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
        final line = lineTexts[lineIndex];
        final leadingWhitespace = line.length - line.trimLeft().length;
        final indent = line.substring(0, leadingWhitespace);
        final body = line.substring(leadingWhitespace);
        final prefixLength = _leadingChecklistPrefixLength(body);
        if (prefixLength == null) {
          continue;
        }

        final rest = body.substring(prefixLength);
        final hasBody = rest.isNotEmpty;
        final nextPrefix = allChecked ? '- [ ]' : '- [$marker]';
        lineTexts[lineIndex] = '$indent$nextPrefix${hasBody ? ' ' : ''}$rest';
      }

      final nextValue = lineTexts.join('\n');
      if (nextValue == value) {
        return false;
      }

      _recordUndoSnapshot();
      _lines = _parseLines(nextValue);
      _selectionStart = _clampPointToBuffer(_selectionStart);
      _selectionEnd = _clampPointToBuffer(_selectionEnd);
      _row = _row.clamp(0, _lines.length - 1);
      _col = _col.clamp(0, _lines[_row].length);
      return true;
    });
  }

  /// Wraps the current selection with [before] and [after].
  ///
  /// If [after] is omitted, [before] is used for both sides.
  /// Returns `false` when there is no active selection.
  bool wrapSelection(String before, {String? after}) {
    if (!_hasSelection()) return false;
    final suffix = after ?? before;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      var start = _globalOffsetForPoint(_selectionStart!);
      var end = _globalOffsetForPoint(_selectionEnd!);
      if (start > end) {
        final tmp = start;
        start = end;
        end = tmp;
      }
      if (start == end) {
        return false;
      }

      final flat = _flattenWithNewlines();
      final prefix = uni.graphemes(before).toList(growable: false);
      final suffixGs = uni.graphemes(suffix).toList(growable: false);
      final selected = flat.sublist(start, end).toList(growable: false);

      _recordUndoSnapshot();
      flat.replaceRange(start, end, [...prefix, ...selected, ...suffixGs]);
      final nextValue = flat.join();
      final selectionStart = start + prefix.length;
      final selectionEnd = selectionStart + selected.length;

      _setValueAndCursor(nextValue, selectionEnd);
      _selectionStart = _pointFromGlobalOffset(selectionStart);
      _selectionEnd = _pointFromGlobalOffset(selectionEnd);
      _row = _selectionEnd!.$2;
      _col = _selectionEnd!.$1;
      return true;
    });
  }

  /// Removes a matching surrounding delimiter pair around the current
  /// selection and preserves the inner selection.
  ///
  /// Returns `false` when there is no active selection, the selection is
  /// empty, or the surrounding graphemes do not form a known delimiter pair.
  bool unwrapSelection() {
    if (!_hasSelection()) return false;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      var start = _globalOffsetForPoint(_selectionStart!);
      var end = _globalOffsetForPoint(_selectionEnd!);
      if (start > end) {
        final tmp = start;
        start = end;
        end = tmp;
      }
      if (start == end) {
        return false;
      }

      final flat = _flattenWithNewlines();
      if (start < 1 || end >= flat.length) {
        return false;
      }

      final before = flat[start - 1];
      final after = flat[end];
      if (_selectionSurroundPairs[before] != after) {
        return false;
      }

      _recordUndoSnapshot();
      flat.removeAt(end);
      flat.removeAt(start - 1);
      final nextValue = flat.join();
      final selectionStart = start - 1;
      final selectionEnd = end - 1;

      _setValueAndCursor(nextValue, selectionEnd);
      _selectionStart = _pointFromGlobalOffset(selectionStart);
      _selectionEnd = _pointFromGlobalOffset(selectionEnd);
      _row = _selectionEnd!.$2;
      _col = _selectionEnd!.$1;
      return true;
    });
  }

  /// Restores the most recent previous edit state.
  bool undo() {
    if (_undoStack.isEmpty) return false;
    _breakHistoryCoalescing();
    final current = _captureEditState();
    final previous = _undoStack.removeLast();
    _redoStack.add(current);
    _restoreEditState(previous);
    return true;
  }

  /// Reapplies the most recently undone edit state.
  bool redo() {
    if (_redoStack.isEmpty) return false;
    _breakHistoryCoalescing();
    final current = _captureEditState();
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _restoreEditState(next);
    return true;
  }

  /// Sets the width of the textarea.
  void setWidth(int w) {
    _width = w;
  }

  /// Sets the height of the textarea.
  void setHeight(int h) {
    _height = h;
  }

  /// Sets the placeholder text.
  void setPlaceholder(String s) {
    placeholder = s;
  }

  /// Sets the character limit.
  void setCharLimit(int n) {
    charLimit = n;
    _enforceCharLimit();
  }

  void insertString(String s) {
    if (s.isEmpty) return;
    _runEditFrame(() {
      _beginHistoryAction(
        s.contains('\n')
            ? _TextAreaHistoryAction.paste
            : _TextAreaHistoryAction.insert,
        breakChain: s.contains('\n'),
      );
      for (final g in uni.graphemes(s)) {
        if (g == '\n') {
          _newline();
        } else {
          _insertChar(g);
        }
      }
    });
  }

  void _insertChar(String ch) {
    if (ch.isEmpty) return;
    _recordUndoSnapshot();
    _lines[_row].insert(_col, ch);
    _col += 1;
    _enforceCharLimit();
  }

  void _newline() {
    _recordUndoSnapshot();
    final current = _lines[_row];
    final before = current.sublist(0, _col);
    final after = current.sublist(_col);
    _lines[_row] = before;
    _lines.insert(_row + 1, after);
    _row = (_row + 1).clamp(0, _lines.length - 1);
    _col = 0;
    _enforceCharLimit();
  }

  void _backspace() {
    if (_row == 0 && _col == 0) return;
    _recordUndoSnapshot();
    if (_col > 0) {
      _lines[_row].removeAt(_col - 1);
      _col -= 1;
    } else if (_row > 0) {
      final prev = _lines[_row - 1];
      final current = _lines.removeAt(_row);
      final prevLen = prev.length;
      prev.addAll(current);
      _row -= 1;
      _col = prevLen;
    }
  }

  String _applyCharLimit(String text) {
    if (charLimit <= 0) return text;
    final gs = uni.graphemes(text).toList(growable: false);
    if (gs.length <= charLimit) return text;
    return gs.take(charLimit).join();
  }

  void cursorStart() {
    _col = 0;
  }

  void cursorEnd() {
    _col = _lines[_row].length;
  }

  @override
  (TextAreaModel, Cmd?) update(Msg msg) {
    return _runEditFrame(() {
      switch (msg) {
        case TextAreaPasteMsg(:final content):
          _beginHistoryAction(_TextAreaHistoryAction.paste, breakChain: true);
          insertString(content);
          return (this, null);
        case PasteMsg(:final content):
          _beginHistoryAction(_TextAreaHistoryAction.paste, breakChain: true);
          insertString(content);
          return (this, null);
        case KeyMsg(key: final key):
          if (key.matchesSingle(keyMap.undo)) {
            undo();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.redo)) {
            redo();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.selectAll)) {
            selectAll();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.selectLine)) {
            selectCurrentLine();
            return (this, null);
          }

          // deletion
          if (key.matchesSingle(keyMap.deleteBeforeCursor)) {
            _beginHistoryAction(_TextAreaHistoryAction.deleteBackward);
            _backspace();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteCharacterForward)) {
            _beginHistoryAction(_TextAreaHistoryAction.deleteForward);
            _deleteCharForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteWordBackward)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteBackward,
              breakChain: true,
            );
            _deleteWordBackward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteWordForward)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteForward,
              breakChain: true,
            );
            _deleteWordForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteToLineStart)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteBackward,
              breakChain: true,
            );
            _deleteToLineStart();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteToLineEnd)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteForward,
              breakChain: true,
            );
            _deleteToLineEnd();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteAfterCursor)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteForward,
              breakChain: true,
            );
            _deleteToLineEnd();
            return (this, null);
          }

          // navigation
          if (key.matchesSingle(keyMap.wordForward)) {
            _moveWordForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.wordBackward)) {
            _moveWordBackward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.lineStart)) {
            _cursorStartOfLine();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.lineEnd)) {
            _cursorEndOfLine();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.inputBegin)) {
            _cursorStartOfInput();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.inputEnd)) {
            _cursorEndOfInput();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.characterForward)) {
            _moveRight();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.characterBackward)) {
            _moveLeft();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.lineNext)) {
            _lineNext();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.linePrevious)) {
            _linePrev();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.transposeCharacterBackward)) {
            _transposeBackward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.uppercaseWordForward)) {
            _uppercaseWordForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.lowercaseWordForward)) {
            _lowercaseWordForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.capitalizeWordForward)) {
            _capitalizeWordForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.copy)) {
            final text = getSelectedText();
            if (text.isNotEmpty) {
              return (this, Cmd.setClipboard(text));
            }
          }

          // Fallback direct modifier checks for common combos.
          if (key.type == KeyType.delete && key.alt) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteForward,
              breakChain: true,
            );
            _deleteWordForward();
            return (this, null);
          }
          if (key.ctrl && key.type == KeyType.runes && key.runes.isNotEmpty) {
            final r = key.runes.first;
            if (r == 0x74) {
              // ctrl+t
              _beginHistoryAction(
                _TextAreaHistoryAction.transform,
                breakChain: true,
              );
              _transposeBackward();
              return (this, null);
            }
          }
          if (key.alt && key.type == KeyType.runes && key.runes.isNotEmpty) {
            final r = key.runes.first;
            if (r == 0x75) {
              _beginHistoryAction(
                _TextAreaHistoryAction.transform,
                breakChain: true,
              );
              _uppercaseWordForward();
              return (this, null);
            }
            if (r == 0x6c) {
              _beginHistoryAction(
                _TextAreaHistoryAction.transform,
                breakChain: true,
              );
              _lowercaseWordForward();
              return (this, null);
            }
            if (r == 0x63) {
              _beginHistoryAction(
                _TextAreaHistoryAction.transform,
                breakChain: true,
              );
              _capitalizeWordForward();
              return (this, null);
            }
          }

          if (key.type == KeyType.space) {
            _beginHistoryAction(_TextAreaHistoryAction.insert);
            _insertChar(' ');
            return (this, null);
          }

          if (key.type == KeyType.enter && keyMap.insertNewline.enabled) {
            _beginHistoryAction(
              _TextAreaHistoryAction.insert,
              breakChain: true,
            );
            _newline();
            return (this, null);
          }

          if (key.type == KeyType.runes && key.runes.isNotEmpty) {
            _beginHistoryAction(_TextAreaHistoryAction.insert);
            final rune = key.runes.first;
            if (rune == 0x0a) {
              _newline();
            } else {
              _insertChar(String.fromCharCode(rune));
            }
            return (this, null);
          }
      }

      if (msg is MouseMsg) {
        final lineNumberDigits = showLineNumbers
            ? '${_lines.length}'.length
            : 0;
        final displayLines = _softWrappedLines(lineNumberDigits);
        final action = msg.action;
        final button = msg.button;
        final x = msg.x;
        final y = msg.y;

        if (y < 0 || y >= displayLines.length) {
          if (action == MouseAction.press && button == MouseButton.left) {
            _selectionStart = null;
            _selectionEnd = null;
            _focused = false;
          }
          return (this, null);
        }

        final dl = displayLines[y];

        if (action == MouseAction.press && button == MouseButton.left) {
          _focused = true;
          final promptW = _getPromptWidth(y);
          final lineNumberW = showLineNumbers ? (lineNumberDigits + 1) : 0;
          final localX = x - promptW - lineNumberW;
          final contentX = localX + dl.charOffset;
          final contentY = dl.rowIndex;
          final now = DateTime.now();

          if (_lastClickTime != null &&
              now.difference(_lastClickTime!) <
                  const Duration(milliseconds: 500) &&
              _lastClickPos == (contentX, contentY)) {
            // Double click: select word
            final (start, end) = _findWordAt(contentX, contentY);
            _selectionStart = (start, contentY);
            _selectionEnd = (end, contentY);
            _lastClickTime = now;
            _lastClickPos = (contentX, contentY);
            return (this, null);
          }

          // Start selection
          _selectionStart = (contentX, contentY);
          _selectionEnd = (contentX, contentY);
          _lastClickTime = now;
          _lastClickPos = (contentX, contentY);
          return (this, null);
        }

        if (action == MouseAction.motion && _selectionStart != null) {
          // Update selection
          final promptW = _getPromptWidth(y);
          final lineNumberW = showLineNumbers ? (lineNumberDigits + 1) : 0;
          final localX = x - promptW - lineNumberW;
          final contentX = localX + dl.charOffset;
          final contentY = dl.rowIndex;
          _selectionEnd = (contentX, contentY);
          return (this, null);
        }

        if (action == MouseAction.release && button == MouseButton.left) {
          // Finalize selection
          return (this, null);
        }
      }

      return (this, null);
    });
  }

  /// Returns the currently selected text.
  String getSelectedText() {
    if (_selectionStart == null || _selectionEnd == null) return '';

    final (x1, y1) = _selectionStart!;
    final (x2, y2) = _selectionEnd!;

    final startY = math.min(y1, y2);
    final endY = math.max(y1, y2);

    if (startY < 0 || endY >= _lines.length) return '';

    final sb = StringBuffer();
    for (var y = startY; y <= endY; y++) {
      final line = _lines[y];
      int startX, endX;

      if (startY == endY) {
        startX = math.min(x1, x2);
        endX = math.max(x1, x2);
      } else if (y == startY) {
        startX = y1 < y2 ? x1 : x2;
        endX = line.length;
      } else if (y == endY) {
        startX = 0;
        endX = y1 < y2 ? x2 : x1;
      } else {
        startX = 0;
        endX = line.length;
      }

      startX = startX.clamp(0, line.length);
      endX = endX.clamp(0, line.length);

      if (startX < endX) {
        sb.write(line.sublist(startX, endX).join());
      }
      if (y < endY) {
        sb.write('\n');
      }
    }

    return sb.toString();
  }

  @override
  Object view() {
    final style = activeStyle();
    final lineNumberDigits = showLineNumbers ? '${_lines.length}'.length : 0;
    final displayLines = _softWrappedLines(lineNumberDigits);
    final buffer = StringBuffer();

    if (value.isEmpty && placeholder.isNotEmpty) {
      final p =
          promptFunc?.call((
            lineIndex: 0,
            isFocused: _focused,
            row: _row,
            col: _col,
          )) ??
          prompt;
      final ph = style.computedPlaceholder.render(placeholder);
      buffer.write('${style.computedPrompt.render(p)}$ph');
    } else {
      for (var i = 0; i < displayLines.length; i++) {
        final displayLine = displayLines[i];
        final p =
            promptFunc?.call((
              lineIndex: i,
              isFocused: _focused,
              row: displayLine.rowIndex,
              col: _col,
            )) ??
            prompt;

        String lnNumber = '';
        if (showLineNumbers) {
          final lnText = displayLine.charOffset == 0
              ? '${(displayLine.rowIndex + 1).toString().padLeft(lineNumberDigits)} '
              : ' ' * (lineNumberDigits + 1);
          lnNumber = style.computedLineNumber.render(lnText);
        }
        final selectionStyle = Style()
            .background(const AnsiColor(7))
            .foreground(const AnsiColor(0));

        // Compute selection overlap for this visual segment.
        int? selStart;
        int? selEnd;
        if (_selectionStart != null && _selectionEnd != null) {
          final (x1, y1) = _selectionStart!;
          final (x2, y2) = _selectionEnd!;
          final startY = math.min(y1, y2);
          final endY = math.max(y1, y2);

          final rowIdx = displayLine.rowIndex;
          if (rowIdx >= startY && rowIdx <= endY) {
            // Selection range in the original (unwrapped) row coordinates.
            int rowStart;
            int rowEnd;
            if (startY == endY) {
              rowStart = math.min(x1, x2);
              rowEnd = math.max(x1, x2);
            } else if (rowIdx == startY) {
              rowStart = y1 < y2 ? x1 : x2;
              rowEnd = _lines[rowIdx].length;
            } else if (rowIdx == endY) {
              rowStart = 0;
              rowEnd = y1 < y2 ? x2 : x1;
            } else {
              rowStart = 0;
              rowEnd = _lines[rowIdx].length;
            }

            rowStart = rowStart.clamp(0, _lines[rowIdx].length);
            rowEnd = rowEnd.clamp(0, _lines[rowIdx].length);

            // Map to this segment via charOffset.
            final segStart = displayLine.charOffset;
            final segLen = uni.graphemes(displayLine.text).length;
            final segEnd = segStart + segLen;

            final overlapStart = math.max(rowStart, segStart);
            final overlapEnd = math.min(rowEnd, segEnd);

            if (overlapStart < overlapEnd) {
              selStart = overlapStart - segStart;
              selEnd = overlapEnd - segStart;
            }
          }
        }

        final gs = uni.graphemes(displayLine.text).toList(growable: false);
        final cursorCol = displayLine.hasCursor
            ? (_col - displayLine.charOffset)
            : -1;

        var renderedBody = '';
        for (var j = 0; j < gs.length; j++) {
          String part;
          if (displayLine.hasCursor && useVirtualCursor && j == cursorCol) {
            cursor = cursor.setChar(gs[j]);
            part = cursor.view();
          } else {
            part = style.computedText.render(gs[j]);
          }

          final isSelected =
              selStart != null && selEnd != null && j >= selStart && j < selEnd;
          if (isSelected) {
            part = selectionStyle.render(part);
          }
          renderedBody += part;
        }

        if (displayLine.hasCursor &&
            useVirtualCursor &&
            cursorCol >= gs.length) {
          cursor = cursor.setChar(' ');
          var part = cursor.view();
          // If the selection is anchored past EOL (rare), don't attempt to style it.
          renderedBody += part;
        }

        final renderedLine = displayLine.hasCursor && !useVirtualCursor
            ? style.computedCursorLine.render(renderedBody)
            : renderedBody;

        buffer.writeln(
          '${style.computedPrompt.render(p)}$lnNumber$renderedLine',
        );
      }

      // end of buffer indicator
      final remaining = (_height - displayLines.length);
      if (remaining > 0) {
        final eob = style.computedEndOfBuffer.render('~');
        for (var i = 0; i < remaining; i++) {
          buffer.writeln(eob);
        }
      }
    }

    final content = buffer.toString().trimRight();
    if (useVirtualCursor || !_focused) {
      return content;
    }

    return View(content: content, cursor: terminalCursor);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  int _effectiveWrapWidth(int lineNumberDigits) {
    var wrapWidth = _width;
    if (wrapWidth <= 0) return wrapWidth;

    wrapWidth -= _promptWidth ?? stringWidth(prompt);
    if (showLineNumbers) {
      // add a trailing space after the number
      wrapWidth -= (lineNumberDigits + 1);
    }
    return wrapWidth;
  }

  List<_DisplayLine> _softWrappedLines(int lineNumberDigits) {
    final result = <_DisplayLine>[];
    final wrapWidth = softWrap ? _effectiveWrapWidth(lineNumberDigits) : 0;

    final visual = layout.buildVisualLines(
      _lines,
      softWrap: softWrap,
      wrapWidthCells: wrapWidth,
    );

    for (final v in visual) {
      final lineLen = _lines[v.rowIndex].length;
      final cursorCol = _row == v.rowIndex ? _col.clamp(0, lineLen) : -1;
      final segStart = v.charOffset;
      final segEnd = segStart + v.graphemeCount;
      final hasCursor =
          _row == v.rowIndex && cursorCol >= segStart && cursorCol <= segEnd;

      result.add(
        _DisplayLine(
          v.text,
          hasCursor: hasCursor,
          rowIndex: v.rowIndex,
          charOffset: v.charOffset,
        ),
      );
    }

    // Respect the configured height by showing the most recent lines.
    if (_height > 0 && result.length > _height) {
      final start = (result.length - _height).clamp(0, result.length);
      return result.sublist(start);
    }

    return result;
  }

  void _deleteWordBackward() {
    final flat = _flattenWithNewlines();
    final pos = _globalOffset();
    if (pos == 0) return;
    _recordUndoSnapshot();

    var newPos = pos - 1;
    while (newPos > 0 && !_isWordGrapheme(flat[newPos])) {
      newPos--;
    }
    while (newPos > 0 && _isWordGrapheme(flat[newPos - 1])) {
      newPos--;
    }

    flat.removeRange(newPos, pos);
    _setValueAndCursor(flat.join(), newPos);
  }

  void _deleteToLineStart() {
    if (_col == 0) return;
    _recordUndoSnapshot();
    _lines[_row].removeRange(0, _col);
    _col = 0;
  }

  void _deleteToLineEnd() {
    final line = _lines[_row];
    if (_col >= line.length) return;
    _recordUndoSnapshot();
    line.removeRange(_col, line.length);
  }

  void _moveWordForward() {
    final flat = _flattenWithNewlines();
    var pos = _globalOffset();
    if (pos >= flat.length) return;

    // Skip current character and any non-word chars.
    pos++;
    while (pos < flat.length && !_isWordGrapheme(flat[pos])) {
      pos++;
    }
    while (pos < flat.length && _isWordGrapheme(flat[pos])) {
      pos++;
    }
    _setCursorFromGlobal(pos);
  }

  void _moveWordBackward() {
    final flat = _flattenWithNewlines();
    var pos = _globalOffset();
    if (pos == 0) return;

    pos--;
    while (pos > 0 && !_isWordGrapheme(flat[pos])) {
      pos--;
    }
    while (pos > 0 && _isWordGrapheme(flat[pos - 1])) {
      pos--;
    }
    _setCursorFromGlobal(pos);
  }

  void _cursorStartOfLine() {
    _col = 0;
  }

  void _cursorEndOfLine() {
    _col = _lines[_row].length;
  }

  void _cursorStartOfInput() {
    _row = 0;
    _col = 0;
  }

  void _cursorEndOfInput() {
    _row = _lines.length - 1;
    _col = _lines.last.length;
  }

  void _deleteCharForward() {
    final line = _lines[_row];
    if (_col < line.length) {
      _recordUndoSnapshot();
      line.removeAt(_col);
      return;
    }
    if (_row < _lines.length - 1) {
      _recordUndoSnapshot();
      final next = _lines.removeAt(_row + 1);
      line.addAll(next);
    }
  }

  void _deleteWordForward() {
    final flat = _flattenWithNewlines();
    final pos = _globalOffset();
    if (pos >= flat.length) return;
    _recordUndoSnapshot();

    var end = pos;
    if (_isWordGrapheme(flat[pos])) {
      while (end < flat.length && _isWordGrapheme(flat[end])) {
        end++;
      }
    } else {
      while (end < flat.length && !_isWordGrapheme(flat[end])) {
        end++;
      }
      while (end < flat.length && _isWordGrapheme(flat[end])) {
        end++;
      }
    }

    flat.removeRange(pos, end);
    _setValueAndCursor(flat.join(), pos);
  }

  void _transposeBackward() {
    final line = _lines[_row];
    if (line.isEmpty) return;
    if (_col == 0) return;
    _recordUndoSnapshot();

    // Swap char before cursor with the one at cursor (Bubble Tea behavior).
    final at = math.min(_col, line.length - 1);
    final before = at - 1;
    if (before < 0) return;
    final tmp = line[before];
    line[before] = line[at];
    line[at] = tmp;
    _col = math.min(at + 1, line.length);
  }

  void _uppercaseWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
    _recordUndoSnapshot();
    final flat = _flattenWithNewlines();
    final segment = flat.sublist(start, end).join().toUpperCase();
    final replacement = uni.graphemes(segment).toList(growable: false);
    flat.replaceRange(start, end, replacement);
    _setValueAndCursor(flat.join(), start + replacement.length);
  }

  void _lowercaseWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
    _recordUndoSnapshot();
    final flat = _flattenWithNewlines();
    final segment = flat.sublist(start, end).join().toLowerCase();
    final replacement = uni.graphemes(segment).toList(growable: false);
    flat.replaceRange(start, end, replacement);
    _setValueAndCursor(flat.join(), start + replacement.length);
  }

  void _capitalizeWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
    _recordUndoSnapshot();
    final flat = _flattenWithNewlines();
    final word = flat.sublist(start, end).join();
    if (word.isEmpty) return;
    final wordGs = uni.graphemes(word).toList(growable: false);
    if (wordGs.isEmpty) return;
    final first = wordGs.first.toUpperCase();
    final rest = wordGs.skip(1).join().toLowerCase();
    final replacement = uni.graphemes('$first$rest').toList(growable: false);
    flat.replaceRange(start, end, replacement);
    _setValueAndCursor(flat.join(), start + replacement.length);
  }

  bool _transformSelectionOrLine(String Function(String text) transform) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final hasSelection = _hasSelection();
      final originalCursorOffset = _globalOffset();
      var start = hasSelection
          ? _globalOffsetForPoint(_selectionStart!)
          : _globalOffsetForPoint((0, _row));
      var end = hasSelection
          ? _globalOffsetForPoint(_selectionEnd!)
          : _globalOffsetForPoint((_lines[_row].length, _row));
      if (start > end) {
        final tmp = start;
        start = end;
        end = tmp;
      }
      if (start == end) {
        return false;
      }

      final flat = _flattenWithNewlines();
      final original = flat.sublist(start, end).join();
      final transformed = transform(original);
      if (transformed == original) {
        return false;
      }

      _recordUndoSnapshot();
      final replacement = uni.graphemes(transformed).toList(growable: false);
      flat.replaceRange(start, end, replacement);
      final nextValue = flat.join();
      final nextExtent = start + replacement.length;

      _setValueAndCursor(nextValue, nextExtent);
      if (hasSelection) {
        _selectionStart = _pointFromGlobalOffset(start);
        _selectionEnd = _pointFromGlobalOffset(nextExtent);
      } else {
        final relativeCursor = (originalCursorOffset - start).clamp(
          0,
          replacement.length,
        );
        _selectionStart = null;
        _selectionEnd = null;
        _setCursorFromGlobal(start + relativeCursor);
      }
      return true;
    });
  }

  String _capitalizeWords(String text) {
    final graphemes = uni.graphemes(text).toList(growable: false);
    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (final grapheme in graphemes) {
      if (_isWordGrapheme(grapheme)) {
        buffer.write(
          capitalizeNext ? grapheme.toUpperCase() : grapheme.toLowerCase(),
        );
        capitalizeNext = false;
      } else {
        buffer.write(grapheme);
        capitalizeNext = true;
      }
    }
    return buffer.toString();
  }

  int _compareLineContent(
    List<String> a,
    List<String> b, {
    required bool descending,
    required bool caseSensitive,
  }) {
    final aText = a.join();
    final bText = b.join();
    final lhs = caseSensitive ? aText : aText.toLowerCase();
    final rhs = caseSensitive ? bText : bText.toLowerCase();
    final base = lhs.compareTo(rhs);
    final resolved = base != 0 ? base : aText.compareTo(bText);
    return descending ? -resolved : resolved;
  }

  bool _listStringEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  (int, int) _nextWordRange() {
    final flat = _flattenWithNewlines();
    var pos = _globalOffset();
    while (pos < flat.length && !_isWordGrapheme(flat[pos])) {
      pos++;
    }
    if (pos >= flat.length) return (-1, -1);
    var end = pos;
    while (end < flat.length && _isWordGrapheme(flat[end])) {
      end++;
    }
    return (pos, end);
  }

  (int, int) _prevWordRange() {
    final flat = _flattenWithNewlines();
    var pos = _globalOffset() - 1;
    while (pos >= 0 && !_isWordGrapheme(flat[pos])) {
      pos--;
    }
    if (pos < 0) return (-1, -1);
    var end = pos + 1;
    while (pos >= 0 && _isWordGrapheme(flat[pos])) {
      pos--;
    }
    final start = pos + 1;
    return (start, end);
  }

  /// Returns forward word range; if none forward, use previous word.
  (int, int) _wordRangeForTransform() {
    final forward = _nextWordRange();
    if (forward.$1 != -1) return forward;
    return _prevWordRange();
  }

  void _moveLeft() {
    if (_col > 0) {
      _col -= 1;
    } else if (_row > 0) {
      _row -= 1;
      _col = _lines[_row].length;
    }
  }

  void _moveRight() {
    if (_col < _lines[_row].length) {
      _col += 1;
    } else if (_row < _lines.length - 1) {
      _row += 1;
      _col = 0;
    }
  }

  void _lineNext() {
    if (_row < _lines.length - 1) {
      _row += 1;
      _col = _col.clamp(0, _lines[_row].length);
    }
  }

  void _linePrev() {
    if (_row > 0) {
      _row -= 1;
      _col = _col.clamp(0, _lines[_row].length);
    }
  }

  int _globalOffset() {
    var offset = 0;
    for (var i = 0; i < _row; i++) {
      offset += _lines[i].length + 1; // include newline
    }
    offset += _col;
    return offset;
  }

  int _globalOffsetForPoint((int, int) point) {
    var offset = 0;
    final line = point.$2.clamp(0, _lines.length - 1);
    for (var index = 0; index < line; index++) {
      offset += _lines[index].length + 1;
    }
    return offset + point.$1.clamp(0, _lines[line].length);
  }

  void _setCursorFromGlobal(int offset) {
    var remaining = offset;
    for (var i = 0; i < _lines.length; i++) {
      final lineLength = _lines[i].length;
      if (remaining <= lineLength) {
        _row = i;
        _col = remaining;
        return;
      }
      remaining -= lineLength + 1;
    }
    // fallback to end
    _row = _lines.length - 1;
    _col = _lines.last.length;
  }

  (int, int) _pointFromGlobalOffset(int offset) {
    var remaining = offset;
    for (var i = 0; i < _lines.length; i++) {
      final lineLength = _lines[i].length;
      if (remaining <= lineLength) {
        return (remaining, i);
      }
      remaining -= lineLength + 1;
    }
    return (_lines.last.length, _lines.length - 1);
  }

  void _setValueAndCursor(String newValue, int cursorPos) {
    final limited = _applyCharLimit(newValue);
    _lines = _parseLines(limited);
    _setCursorFromGlobal(cursorPos.clamp(0, _totalGraphemeLength()));
  }

  (int, int) _selectedLineRange() {
    if (!_hasSelection()) {
      return (_row, _row);
    }
    final startLine = math.min(_selectionStart!.$2, _selectionEnd!.$2);
    final endLine = math.max(_selectionStart!.$2, _selectionEnd!.$2);
    return (startLine, endLine);
  }

  (int, int)? _adjustLinePrefixPoint(
    (int, int)? point, {
    required int line,
    required int leadingWhitespace,
    required int delta,
    required bool remove,
  }) {
    if (point == null || point.$2 != line) {
      return point;
    }
    return (
      _adjustLinePrefixColumn(
        column: point.$1,
        leadingWhitespace: leadingWhitespace,
        delta: delta,
        remove: remove,
      ),
      point.$2,
    );
  }

  (int, int)? _adjustLinePrefixPointDelta(
    (int, int)? point, {
    required int line,
    required int leadingWhitespace,
    required int delta,
  }) {
    if (point == null || point.$2 != line || delta == 0) {
      return point;
    }
    return (
      _adjustLinePrefixColumnDelta(
        column: point.$1,
        leadingWhitespace: leadingWhitespace,
        delta: delta,
      ),
      point.$2,
    );
  }

  int _adjustLinePrefixColumn({
    required int column,
    required int leadingWhitespace,
    required int delta,
    required bool remove,
  }) {
    if (column <= leadingWhitespace) {
      return column;
    }
    if (!remove) {
      return column + delta;
    }
    return math.max(leadingWhitespace, column - delta);
  }

  int _adjustLinePrefixColumnDelta({
    required int column,
    required int leadingWhitespace,
    required int delta,
  }) {
    if (delta == 0 || column <= leadingWhitespace) {
      return column;
    }
    if (delta > 0) {
      return column + delta;
    }
    return math.max(leadingWhitespace, column + delta);
  }

  int? _leadingNumberedPrefixLength(String text) {
    final match = RegExp(r'^\d+\.\s?').firstMatch(text);
    return match?.group(0)?.length;
  }

  ({int level, int length})? _leadingHeadingPrefix(String text) {
    final match = RegExp(r'^(#{1,6})(?:\s+|$)').firstMatch(text);
    final hashes = match?.group(1);
    final length = match?.group(0)?.length;
    if (hashes == null || length == null) {
      return null;
    }
    return (level: hashes.length, length: length);
  }

  int? _leadingChecklistPrefixLength(String text) {
    final match = RegExp(r'^-\s\[(?:\s|x|X)\]\s?').firstMatch(text);
    return match?.group(0)?.length;
  }

  bool _isChecklistChecked(String text) {
    final match = RegExp(r'^-\s\[(.)\]').firstMatch(text);
    if (match == null) {
      return false;
    }
    final marker = match.group(1);
    return marker != null && marker.trim().isNotEmpty;
  }

  int _leadingIndentRemovalCount(List<String> line, int width) {
    if (line.isEmpty || width < 1) return 0;
    if (line.first == '\t') return 1;

    var removed = 0;
    while (removed < width && removed < line.length && line[removed] == ' ') {
      removed++;
    }
    return removed;
  }

  int _trailingHorizontalTrimLength(List<String> line) {
    var end = line.length;
    while (end > 0 && (line[end - 1] == ' ' || line[end - 1] == '\t')) {
      end--;
    }
    return end;
  }

  void _applyLineColumnDeltas(Map<int, int> deltas) {
    if (deltas.isEmpty) return;

    if (deltas.containsKey(_row)) {
      _col = (_col + deltas[_row]!).clamp(0, _lines[_row].length);
    }
    _selectionStart = _shiftPointByLineDelta(_selectionStart, deltas);
    _selectionEnd = _shiftPointByLineDelta(_selectionEnd, deltas);
  }

  (int, int)? _shiftPointByLineDelta((int, int)? point, Map<int, int> deltas) {
    if (point == null) return null;
    final delta = deltas[point.$2];
    if (delta == null) return point;
    return ((point.$1 + delta).clamp(0, _lines[point.$2].length), point.$2);
  }

  (int, int)? _clampPointToBuffer((int, int)? point) {
    if (point == null) return null;
    final row = point.$2.clamp(0, _lines.length - 1);
    if (point.$2 > _lines.length - 1) {
      return (_lines[row].length, row);
    }
    final col = point.$1.clamp(0, _lines[row].length);
    return (col, row);
  }

  (int, int)? _duplicateAbovePoint(
    (int, int)? point, {
    required int startLine,
    required int endLine,
    required int delta,
  }) {
    if (point == null) return null;
    if (point.$2 < startLine) return point;
    if (point.$2 > endLine) {
      return (point.$1, point.$2 + delta);
    }
    return (point.$1.clamp(0, _lines[point.$2].length), point.$2);
  }

  bool _moveSelectedLines(int direction) {
    if (direction != -1 && direction != 1) return false;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final (startLine, endLine) = _selectedLineRange();
      if (direction < 0 && startLine == 0) return false;
      if (direction > 0 && endLine >= _lines.length - 1) return false;

      _recordUndoSnapshot();
      final movedLines = _lines
          .sublist(startLine, endLine + 1)
          .map((line) => List<String>.from(line))
          .toList(growable: false);
      _lines.removeRange(startLine, endLine + 1);
      final insertionLine = direction < 0 ? startLine - 1 : startLine + 1;
      _lines.insertAll(insertionLine, movedLines);

      _shiftCursorAndSelectionRows(
        startLine: startLine,
        endLine: endLine,
        delta: direction,
      );
      return true;
    });
  }

  void _shiftCursorAndSelectionRows({
    required int startLine,
    required int endLine,
    required int delta,
  }) {
    if (_row >= startLine && _row <= endLine) {
      _row = (_row + delta).clamp(0, _lines.length - 1);
      _col = _col.clamp(0, _lines[_row].length);
    }
    _selectionStart = _shiftPointRowRange(
      _selectionStart,
      startLine: startLine,
      endLine: endLine,
      delta: delta,
    );
    _selectionEnd = _shiftPointRowRange(
      _selectionEnd,
      startLine: startLine,
      endLine: endLine,
      delta: delta,
    );
  }

  (int, int)? _shiftPointRowRange(
    (int, int)? point, {
    required int startLine,
    required int endLine,
    required int delta,
  }) {
    if (point == null) return null;
    if (point.$2 < startLine || point.$2 > endLine) return point;
    final row = (point.$2 + delta).clamp(0, _lines.length - 1);
    return (point.$1.clamp(0, _lines[row].length), row);
  }

  List<String> _trimLeadingHorizontalWhitespace(List<String> line) {
    var start = 0;
    while (start < line.length && (line[start] == ' ' || line[start] == '\t')) {
      start++;
    }
    return line.sublist(start);
  }

  String _lineJoinSeparator(List<String> left, List<String> right) {
    if (left.isEmpty || right.isEmpty) return '';
    final last = left.last;
    final first = right.first;
    if (_isHorizontalWhitespace(last) || _isHorizontalWhitespace(first)) {
      return '';
    }
    if (_suppressesLineJoinSpaceBefore(last) ||
        _suppressesLineJoinSpaceAfter(first)) {
      return '';
    }
    return ' ';
  }

  bool _suppressesLineJoinSpaceBefore(String grapheme) {
    return grapheme == '(' ||
        grapheme == '[' ||
        grapheme == '{' ||
        grapheme == '<';
  }

  bool _suppressesLineJoinSpaceAfter(String grapheme) {
    return grapheme == ')' ||
        grapheme == ']' ||
        grapheme == '}' ||
        grapheme == '>' ||
        grapheme == ',' ||
        grapheme == ';' ||
        grapheme == ':' ||
        grapheme == '.';
  }

  bool _isHorizontalWhitespace(String grapheme) {
    return grapheme == ' ' || grapheme == '\t';
  }

  bool _isWordChar(int rune) {
    final ch = String.fromCharCode(rune);
    return RegExp(r'[A-Za-z0-9_]').hasMatch(ch);
  }

  bool _isWordGrapheme(String grapheme) {
    if (grapheme.isEmpty || grapheme == '\n') return false;
    return _isWordChar(uni.firstCodePoint(grapheme));
  }

  int _totalGraphemeLength() {
    var total = 0;
    for (var i = 0; i < _lines.length; i++) {
      total += _lines[i].length;
      if (i < _lines.length - 1) total += 1; // newline
    }
    return total;
  }

  List<List<String>> _parseLines(String s) {
    final parts = s.split('\n');
    if (parts.isEmpty) return [[]];
    final lines = parts
        .map((p) => uni.graphemes(p).toList(growable: true))
        .toList();
    if (lines.isEmpty) return [[]];
    return lines;
  }

  List<String> _flattenWithNewlines() {
    final result = <String>[];
    for (var i = 0; i < _lines.length; i++) {
      result.addAll(_lines[i]);
      if (i < _lines.length - 1) result.add('\n');
    }
    return result;
  }

  void _enforceCharLimit() {
    if (charLimit <= 0) return;
    final cursorPos = _globalOffset();
    final limited = _applyCharLimit(value);
    if (limited == value) return;
    _lines = _parseLines(limited);
    _setCursorFromGlobal(cursorPos.clamp(0, _totalGraphemeLength()));
  }

  (int, int) _findWordAt(int x, int y) {
    if (y < 0 || y >= _lines.length) return (x, x);
    final line = _lines[y];
    if (line.isEmpty) return (0, 0);
    final pos = x.clamp(0, line.length - 1);

    if (_isWhitespace(line[pos])) {
      var start = pos;
      while (start > 0 && _isWhitespace(line[start - 1])) {
        start--;
      }
      var end = pos;
      while (end < line.length && _isWhitespace(line[end])) {
        end++;
      }
      return (start, end);
    } else {
      var start = pos;
      while (start > 0 && !_isWhitespace(line[start - 1])) {
        start--;
      }
      var end = pos;
      while (end < line.length && !_isWhitespace(line[end])) {
        end++;
      }
      return (start, end);
    }
  }

  bool _isWhitespace(String grapheme) {
    final rune = uni.firstCodePoint(grapheme);
    return rune == 0x20 || // Space
        rune == 0x09 || // Tab
        rune == 0x0A || // LF
        rune == 0x0D; // CR
  }
}
