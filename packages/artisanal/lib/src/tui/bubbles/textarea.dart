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

// ─────────────────────────────────────────────────────────────────────────────
// Key map
// ─────────────────────────────────────────────────────────────────────────────

class TextAreaKeyMap implements KeyMap {
  TextAreaKeyMap({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
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
       lineStart =
           lineStart ??
           KeyBinding.withHelp(['home', 'Ctrl+a'], 'home', 'line start'),
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
       copy = copy ?? KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'copy');

  final KeyBinding characterForward;
  final KeyBinding characterBackward;
  final KeyBinding wordForward;
  final KeyBinding wordBackward;
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

  TextAreaKeyMap copyWith({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
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
  }) {
    return TextAreaKeyMap(
      characterForward: characterForward ?? this.characterForward,
      characterBackward: characterBackward ?? this.characterBackward,
      wordForward: wordForward ?? this.wordForward,
      wordBackward: wordBackward ?? this.wordBackward,
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

  /// Returns the current value of the textarea.
  String get value => _lines.map((l) => l.join()).join('\n');

  /// Sets the value of the textarea.
  set value(String v) {
    final limited = _applyCharLimit(v);
    _lines = _parseLines(limited);
    _row = _lines.length - 1;
    _col = _lines.isNotEmpty ? _lines.last.length : 0;
  }

  /// Sets the value of the textarea (parity with bubbles).
  void setValue(String v) {
    value = v;
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
    _lines = [[]];
    _row = 0;
    _col = 0;
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
    for (final g in uni.graphemes(s)) {
      if (g == '\n') {
        _newline();
      } else {
        _insertChar(g);
      }
    }
  }

  void _insertChar(String ch) {
    if (ch.isEmpty) return;
    _lines[_row].insert(_col, ch);
    _col += 1;
    _enforceCharLimit();
  }

  void _newline() {
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
    switch (msg) {
      case TextAreaPasteMsg(:final content):
        insertString(content);
        return (this, null);
      case PasteMsg(:final content):
        insertString(content);
        return (this, null);
      case KeyMsg(key: final key):
        // deletion
        if (key.matchesSingle(keyMap.deleteBeforeCursor)) {
          _backspace();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteCharacterForward)) {
          _deleteCharForward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteWordBackward)) {
          _deleteWordBackward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteWordForward)) {
          _deleteWordForward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteToLineStart)) {
          _deleteToLineStart();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteToLineEnd)) {
          _deleteToLineEnd();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteAfterCursor)) {
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
          _deleteWordForward();
          return (this, null);
        }
        if (key.ctrl && key.type == KeyType.runes && key.runes.isNotEmpty) {
          final r = key.runes.first;
          if (r == 0x74) {
            // ctrl+t
            _transposeBackward();
            return (this, null);
          }
        }
        if (key.alt && key.type == KeyType.runes && key.runes.isNotEmpty) {
          final r = key.runes.first;
          if (r == 0x75) {
            _uppercaseWordForward();
            return (this, null);
          }
          if (r == 0x6c) {
            _lowercaseWordForward();
            return (this, null);
          }
          if (r == 0x63) {
            _capitalizeWordForward();
            return (this, null);
          }
        }

        if (key.type == KeyType.space) {
          _insertChar(' ');
          return (this, null);
        }

        if (key.type == KeyType.enter && keyMap.insertNewline.enabled) {
          _newline();
          return (this, null);
        }

        if (key.type == KeyType.runes && key.runes.isNotEmpty) {
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
      final lineNumberDigits = showLineNumbers ? '${_lines.length}'.length : 0;
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
    _lines[_row].removeRange(0, _col);
    _col = 0;
  }

  void _deleteToLineEnd() {
    final line = _lines[_row];
    if (_col >= line.length) return;
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
      line.removeAt(_col);
      return;
    }
    if (_row < _lines.length - 1) {
      final next = _lines.removeAt(_row + 1);
      line.addAll(next);
    }
  }

  void _deleteWordForward() {
    final flat = _flattenWithNewlines();
    final pos = _globalOffset();
    if (pos >= flat.length) return;

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
    final flat = _flattenWithNewlines();
    final segment = flat.sublist(start, end).join().toUpperCase();
    final replacement = uni.graphemes(segment).toList(growable: false);
    flat.replaceRange(start, end, replacement);
    _setValueAndCursor(flat.join(), start + replacement.length);
  }

  void _lowercaseWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
    final flat = _flattenWithNewlines();
    final segment = flat.sublist(start, end).join().toLowerCase();
    final replacement = uni.graphemes(segment).toList(growable: false);
    flat.replaceRange(start, end, replacement);
    _setValueAndCursor(flat.join(), start + replacement.length);
  }

  void _capitalizeWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
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

  void _setValueAndCursor(String newValue, int cursorPos) {
    final limited = _applyCharLimit(newValue);
    _lines = _parseLines(limited);
    _setCursorFromGlobal(cursorPos.clamp(0, _totalGraphemeLength()));
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
