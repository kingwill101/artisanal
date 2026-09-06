/// Simplified multi-line textarea bubble to satisfy examples and tests.
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/src/tui/view.dart';
import 'package:ultraviolet/terminal.dart';
import '../component.dart';
import '../msg.dart';
import '../cmd.dart';
import '../editor_core/editor_core.dart';
import '../editor_core/editor_core.dart' as commands;
import '../key.dart';
import 'key_binding.dart';
import 'runeutil.dart';
import 'cursor.dart';
import 'package:ultraviolet/unicode.dart' as uni;

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
    Map<String, Style>? decorationStyles,
    Map<String, Style>? lineDecorationStyles,
    Style? endOfBuffer,
    Style? lineNumber,
    Style? placeholder,
    Style? prompt,
    Style? selection,
    Style? text,
  }) : base = base ?? Style(),
       cursorLine = cursorLine ?? Style(),
       cursorLineNumber = cursorLineNumber ?? Style(),
       decorationStyles = Map<String, Style>.unmodifiable(
         decorationStyles ??
             <String, Style>{
               textSearchMatchDecorationKey: Style().underline(),
               textSearchActiveMatchDecorationKey: Style()
                   .background(const AnsiColor(7))
                   .foreground(const AnsiColor(0)),
               textDiagnosticErrorDecorationKey: Style()
                   .underline()
                   .underlineColor(const AnsiColor(1)),
               textDiagnosticWarningDecorationKey: Style()
                   .underline()
                   .underlineColor(const AnsiColor(3)),
               textDiagnosticInfoDecorationKey: Style()
                   .underline()
                   .underlineColor(const AnsiColor(6)),
               textDiagnosticHintDecorationKey: Style()
                   .underline()
                   .underlineColor(const AnsiColor(4)),
             },
       ),
       lineDecorationStyles = Map<String, Style>.unmodifiable(
         lineDecorationStyles ??
             <String, Style>{
               textActiveLineDecorationKey: cursorLine ?? Style(),
               textActiveLineNumberDecorationKey: cursorLineNumber ?? Style(),
               textDiagnosticErrorLineDecorationKey: Style(),
               textDiagnosticWarningLineDecorationKey: Style(),
               textDiagnosticInfoLineDecorationKey: Style(),
               textDiagnosticHintLineDecorationKey: Style(),
               textDiagnosticErrorLineNumberDecorationKey: Style().foreground(
                 const AnsiColor(1),
               ),
               textDiagnosticWarningLineNumberDecorationKey: Style().foreground(
                 const AnsiColor(3),
               ),
               textDiagnosticInfoLineNumberDecorationKey: Style().foreground(
                 const AnsiColor(6),
               ),
               textDiagnosticHintLineNumberDecorationKey: Style().foreground(
                 const AnsiColor(4),
               ),
             },
       ),
       endOfBuffer = endOfBuffer ?? Style(),
       lineNumber = lineNumber ?? Style(),
       placeholder = placeholder ?? Style(),
       prompt = prompt ?? Style(),
       selection =
           selection ??
           Style()
               .background(const AnsiColor(7))
               .foreground(const AnsiColor(0)),
       text = text ?? Style();

  Style base;
  Style cursorLine;
  Style cursorLineNumber;
  Map<String, Style> decorationStyles;
  Map<String, Style> lineDecorationStyles;
  Style endOfBuffer;
  Style lineNumber;
  Style placeholder;
  Style prompt;
  Style selection;
  Style text;

  Style get computedCursorLine => cursorLine.inherit(base).inline(true);
  Style get computedCursorLineNumber =>
      cursorLineNumber.inherit(computedCursorLine).inherit(base).inline(true);
  Style? computedDecorationStyle(String styleKey) {
    final style = decorationStyles[styleKey];
    if (style == null) {
      return null;
    }
    return style.inherit(computedText).inline(true);
  }

  Style? computedLineDecorationStyle(String styleKey) {
    final style = lineDecorationStyles[styleKey];
    if (style == null) {
      return null;
    }
    return style.inherit(base).inline(true);
  }

  Style? computedLineNumberDecorationStyle(
    String styleKey, {
    String? lineStyleKey,
  }) {
    final style = lineDecorationStyles[styleKey];
    if (style == null) {
      return null;
    }
    final lineStyle = lineStyleKey == null
        ? null
        : lineDecorationStyles[lineStyleKey];
    var resolved = style;
    if (lineStyle != null) {
      resolved = resolved.inherit(lineStyle);
    }
    return resolved.inherit(base).inline(true);
  }

  Style get computedEndOfBuffer => endOfBuffer.inherit(base).inline(true);
  Style get computedLineNumber => lineNumber.inherit(base).inline(true);
  Style get computedPlaceholder => placeholder.inherit(base).inline(true);
  Style get computedPrompt => prompt.inherit(base).inline(true);
  Style get computedSelection => selection.inherit(base).inline(true);
  Style get computedText => text.inherit(base).inline(true);

  TextAreaStyleState copyWith({
    Style? base,
    Style? cursorLine,
    Style? cursorLineNumber,
    Map<String, Style>? decorationStyles,
    Map<String, Style>? lineDecorationStyles,
    Style? endOfBuffer,
    Style? lineNumber,
    Style? placeholder,
    Style? prompt,
    Style? selection,
    Style? text,
  }) {
    return TextAreaStyleState(
      base: base ?? this.base,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorLineNumber: cursorLineNumber ?? this.cursorLineNumber,
      decorationStyles: decorationStyles ?? this.decorationStyles,
      lineDecorationStyles: lineDecorationStyles ?? this.lineDecorationStyles,
      endOfBuffer: endOfBuffer ?? this.endOfBuffer,
      lineNumber: lineNumber ?? this.lineNumber,
      placeholder: placeholder ?? this.placeholder,
      prompt: prompt ?? this.prompt,
      selection: selection ?? this.selection,
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

  TextAreaStyles copyWith({
    TextAreaStyleState? focused,
    TextAreaStyleState? blurred,
    TextAreaCursorStyle? cursor,
  }) {
    return TextAreaStyles(
      focused: focused ?? this.focused,
      blurred: blurred ?? this.blurred,
      cursor: cursor ?? this.cursor,
    );
  }
}

TextAreaStyles defaultTextAreaStyles() {
  return TextAreaStyles(
    focused: TextAreaStyleState(
      cursorLine: Style().background(const AnsiColor(0)),
      cursorLineNumber: Style().foreground(const AnsiColor(240)),
      decorationStyles: <String, Style>{
        textSearchMatchDecorationKey: Style().underline(),
        textSearchActiveMatchDecorationKey: Style()
            .background(const AnsiColor(7))
            .foreground(const AnsiColor(0)),
        textDiagnosticErrorDecorationKey: Style().underline().underlineColor(
          const AnsiColor(1),
        ),
        textDiagnosticWarningDecorationKey: Style().underline().underlineColor(
          const AnsiColor(3),
        ),
        textDiagnosticInfoDecorationKey: Style().underline().underlineColor(
          const AnsiColor(6),
        ),
        textDiagnosticHintDecorationKey: Style().underline().underlineColor(
          const AnsiColor(4),
        ),
      },
      lineDecorationStyles: <String, Style>{
        textActiveLineDecorationKey: Style().background(const AnsiColor(0)),
        textActiveLineNumberDecorationKey: Style().foreground(
          const AnsiColor(240),
        ),
        textDiagnosticErrorLineDecorationKey: Style(),
        textDiagnosticWarningLineDecorationKey: Style(),
        textDiagnosticInfoLineDecorationKey: Style(),
        textDiagnosticHintLineDecorationKey: Style(),
        textDiagnosticErrorLineNumberDecorationKey: Style().foreground(
          const AnsiColor(1),
        ),
        textDiagnosticWarningLineNumberDecorationKey: Style().foreground(
          const AnsiColor(3),
        ),
        textDiagnosticInfoLineNumberDecorationKey: Style().foreground(
          const AnsiColor(6),
        ),
        textDiagnosticHintLineNumberDecorationKey: Style().foreground(
          const AnsiColor(4),
        ),
      },
      endOfBuffer: Style().foreground(const AnsiColor(0)),
      lineNumber: Style().foreground(const AnsiColor(249)),
      placeholder: Style().foreground(const AnsiColor(240)),
      prompt: Style().foreground(const AnsiColor(7)),
      selection: Style()
          .background(const AnsiColor(7))
          .foreground(const AnsiColor(0)),
      text: Style(),
    ),
    blurred: TextAreaStyleState(
      cursorLine: Style().foreground(const AnsiColor(245)),
      cursorLineNumber: Style().foreground(const AnsiColor(249)),
      decorationStyles: <String, Style>{
        textSearchMatchDecorationKey: Style().underline(),
        textSearchActiveMatchDecorationKey: Style()
            .background(const AnsiColor(7))
            .foreground(const AnsiColor(0)),
        textDiagnosticErrorDecorationKey: Style().underline().underlineColor(
          const AnsiColor(1),
        ),
        textDiagnosticWarningDecorationKey: Style().underline().underlineColor(
          const AnsiColor(3),
        ),
        textDiagnosticInfoDecorationKey: Style().underline().underlineColor(
          const AnsiColor(6),
        ),
        textDiagnosticHintDecorationKey: Style().underline().underlineColor(
          const AnsiColor(4),
        ),
      },
      lineDecorationStyles: <String, Style>{
        textActiveLineDecorationKey: Style().foreground(const AnsiColor(245)),
        textActiveLineNumberDecorationKey: Style().foreground(
          const AnsiColor(249),
        ),
        textDiagnosticErrorLineDecorationKey: Style(),
        textDiagnosticWarningLineDecorationKey: Style(),
        textDiagnosticInfoLineDecorationKey: Style(),
        textDiagnosticHintLineDecorationKey: Style(),
        textDiagnosticErrorLineNumberDecorationKey: Style().foreground(
          const AnsiColor(1),
        ),
        textDiagnosticWarningLineNumberDecorationKey: Style().foreground(
          const AnsiColor(3),
        ),
        textDiagnosticInfoLineNumberDecorationKey: Style().foreground(
          const AnsiColor(6),
        ),
        textDiagnosticHintLineNumberDecorationKey: Style().foreground(
          const AnsiColor(4),
        ),
      },
      endOfBuffer: Style().foreground(const AnsiColor(0)),
      lineNumber: Style().foreground(const AnsiColor(249)),
      placeholder: Style().foreground(const AnsiColor(240)),
      prompt: Style().foreground(const AnsiColor(7)),
      selection: Style()
          .background(const AnsiColor(7))
          .foreground(const AnsiColor(0)),
      text: Style().foreground(const AnsiColor(245)),
    ),
    cursor: TextAreaCursorStyle(
      color: const AnsiColor(7),
      shape: CursorShape.block,
      blink: true,
    ),
  );
}

class TextAreaPasteMsg extends Msg {
  TextAreaPasteMsg(this.content);
  final String content;
}

class TextAreaPasteErrorMsg extends Msg {
  TextAreaPasteErrorMsg(this.error);
  final Object error;
}

/// Delivers an asynchronous completion result to [TextAreaModel].
final class TextAreaCompletionMsg extends Msg {
  const TextAreaCompletionMsg(this.result);
  final EditorCompletionResult? result;
}

/// Delivers a completion provider failure to [TextAreaModel].
final class TextAreaCompletionErrorMsg extends Msg {
  const TextAreaCompletionErrorMsg(this.error);
  final Object error;
}

final class TextAreaCodeActionsMsg extends Msg {
  const TextAreaCodeActionsMsg(this.actions);
  final List<EditorCodeAction>? actions;
}

final class TextAreaCodeActionsErrorMsg extends Msg {
  const TextAreaCodeActionsErrorMsg(this.error);
  final Object error;
}

class _TextAreaPasteChunkMsg extends Msg {
  const _TextAreaPasteChunkMsg();
}

class _TextAreaEditState {
  const _TextAreaEditState({
    required this.value,
    required this.row,
    required this.col,
    required this.selectionStart,
    required this.selectionEnd,
    required this.selections,
  });

  final String value;
  final int row;
  final int col;
  final (int, int)? selectionStart;
  final (int, int)? selectionEnd;
  final TextSelectionSet? selections;

  bool sameAs(_TextAreaEditState other) {
    return value == other.value &&
        row == other.row &&
        col == other.col &&
        selectionStart == other.selectionStart &&
        selectionEnd == other.selectionEnd &&
        _sameSelectionSet(selections, other.selections);
  }

  static bool _sameSelectionSet(TextSelectionSet? a, TextSelectionSet? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.primaryIndex != b.primaryIndex) {
      return false;
    }
    if (a.ranges.length != b.ranges.length) return false;
    for (var i = 0; i < a.ranges.length; i++) {
      if (a.ranges[i] != b.ranges[i]) return false;
    }
    return true;
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

class TextAreaKeyMap extends KeyMap {
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
    KeyBinding? pageUp,
    KeyBinding? pageDown,
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
           KeyBinding.withHelp(
             ['right', 'ctrl+f'],
             Arrows.right,
             'character forward',
           ),
       characterBackward =
           characterBackward ??
           KeyBinding.withHelp(
             ['left', 'ctrl+b'],
             Arrows.left,
             'character backward',
           ),
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
           KeyBinding.withHelp(['down', 'ctrl+n'], Arrows.down, 'next line'),
       linePrevious =
           linePrevious ??
           KeyBinding.withHelp(['up', 'ctrl+p'], Arrows.up, 'previous line'),
       pageUp =
           pageUp ?? KeyBinding.withHelp(['pageup'], 'pgup', 'previous page'),
       pageDown =
           pageDown ?? KeyBinding.withHelp(['pagedown'], 'pgdown', 'next page'),
       insertNewline =
           insertNewline ??
           KeyBinding.withHelp(
             ['enter'],
             KeyboardChars.enter,
             'insert newline',
           ),
       deleteBeforeCursor =
           deleteBeforeCursor ??
           KeyBinding.withHelp(
             ['backspace'],
             KeyboardChars.backspace,
             'delete',
           ),
       deleteCharacterForward =
           deleteCharacterForward ??
           KeyBinding.withHelp(['delete', 'ctrl+d'], 'del', 'del char forward'),
       deleteWordBackward =
           deleteWordBackward ??
           KeyBinding.withHelp(
             ['alt+backspace'],
             'alt+${KeyboardChars.backspace}',
             'delete word',
           ),
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
           KeyBinding.withHelp(['ctrl+y', 'ctrl+shift+z'], 'ctrl+y', 'redo') {
    shortHelp = [
      this.characterForward,
      this.characterBackward,
      this.wordForward,
      this.wordBackward,
      this.lineNext,
      this.linePrevious,
    ];
    fullHelp = [
      [this.characterBackward, this.characterForward],
      [this.wordBackward, this.wordForward],
      [this.selectAll, this.selectLine],
      [this.lineStart, this.lineEnd],
      [this.linePrevious, this.lineNext],
      [this.pageUp, this.pageDown],
      [
        this.deleteBeforeCursor,
        this.deleteCharacterForward,
        this.deleteWordBackward,
        this.deleteWordForward,
        this.deleteToLineStart,
        this.deleteToLineEnd,
        this.deleteAfterCursor,
      ],
      [
        this.inputBegin,
        this.inputEnd,
        this.undo,
        this.redo,
        this.transposeCharacterBackward,
        this.uppercaseWordForward,
        this.lowercaseWordForward,
        this.capitalizeWordForward,
      ],
    ];
  }

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
  final KeyBinding pageUp;
  final KeyBinding pageDown;
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
    KeyBinding? pageUp,
    KeyBinding? pageDown,
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
      pageUp: pageUp ?? this.pageUp,
      pageDown: pageDown ?? this.pageDown,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// TextArea model (simplified)
// ─────────────────────────────────────────────────────────────────────────────

class TextAreaModel extends ViewComponent {
  static DateTime _defaultNowProvider() => DateTime.now();

  TextAreaModel({
    this.prompt = '│ ',
    this.placeholder = '',
    this.showLineNumbers = true,
    this.minimumLineNumberDigits = 0,
    this.charLimit = 0,
    this.softWrap = true,
    int width = 0,
    int height = 6,
    this.useVirtualCursor = true,
    TextAreaKeyMap? keyMap,
    CursorModel? cursor,
    TextAreaStyles? styles,
    DateTime Function()? nowProvider,
  }) : assert(minimumLineNumberDigits >= 0),
       keyMap = keyMap ?? TextAreaKeyMap(),
       cursor = cursor ?? CursorModel(),
       styles = styles ?? defaultTextAreaStyles(),
       _width = width,
       _height = height,
       _nowProvider = nowProvider ?? _defaultNowProvider {
    _document = TextDocument();
    _editorState = EditorState();
    _textView = TextView(width: width, height: height, softWrap: softWrap);
    _history =
        EditHistoryController<
          _TextAreaHistoryAction,
          _TextAreaEditState,
          ({int row, int col, int length})
        >(
          maxEntries: _maxHistoryEntries,
          sameState: (a, b) => a.sameAs(b),
          canCoalesce: _canCoalesceHistoryAction,
          markerForState: (action, state) => (
            row: state.row,
            col: state.col,
            length: uni.graphemes(state.value).length,
          ),
        );
    _editorStateDirty = true;
    _syncCoreState();
    _updateVirtualCursorStyle();
  }

  String prompt;
  PromptFunc? promptFunc;
  String placeholder;
  bool showLineNumbers;

  /// Minimum width reserved for line numbers.
  ///
  /// Set this when an editor should not shift horizontally as its line count
  /// crosses a power-of-ten boundary. A value of zero sizes the gutter from
  /// the current line count.
  int minimumLineNumberDigits;

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
  late TextDocument _document;
  late final EditorState _editorState;
  late final TextView _textView;
  final DateTime Function() _nowProvider;
  int _row = 0;
  int _col = 0;
  int _width;
  int _height;
  int? _promptWidth;
  static const int _maxHistoryEntries = 100;
  static const int _pasteChunkThresholdRunes = 1200;
  static const int _pasteChunkSizeRunes = 300;
  late final EditHistoryController<
    _TextAreaHistoryAction,
    _TextAreaEditState,
    ({int row, int col, int length})
  >
  _history;
  late final EditorCommandRegistry<TextAreaModel> _commandRegistry =
      _createCommandRegistry();
  final TextPasteController _pasteController = TextPasteController();
  final EditorCompletionSession _completionSession = EditorCompletionSession();
  final EditorCodeActionSession _codeActionSession = EditorCodeActionSession();
  final Map<
    String,
    ({List<TextDecorationRange> decorations, int order, int priority})
  >
  _decorationLayers =
      <
        String,
        ({List<TextDecorationRange> decorations, int order, int priority})
      >{};
  final Map<
    String,
    ({List<TextLineDecoration> decorations, int order, int priority})
  >
  _lineDecorationLayers =
      <
        String,
        ({List<TextLineDecoration> decorations, int order, int priority})
      >{};
  List<TextDiagnosticRange> _diagnostics = const [];
  TextSelectionSet? _selections;
  int _selectionGeneration = 0;
  int _verticalMotionGeneration = -1;
  bool _verticalMotionSoftWrap = false;
  Map<TextSelectionRange, int> _verticalGoalColumns = const {};
  List<TextDecorationRange> _decorations = const [];
  List<TextLineDecoration> _lineDecorations = const [];
  TextDocumentChange? _lastDocumentChange;
  int _documentVersion = 0;
  String _savedValue = '';
  List<EditorCompletionItem> _completionItems = const [];
  int _completionIndex = -1;
  Object? _completionError;
  WorkspaceEdit? _lastCompletionAdditionalEdits;
  TextSearchSession? _searchSession;
  String? _searchError;
  List<EditorCodeAction> _codeActions = const [];
  int _codeActionIndex = -1;
  Object? _codeActionError;
  EditorCodeAction? _acceptedCodeAction;
  bool _editorStateDirty = false;
  int _nextDecorationLayerOrder = 0;
  int _nextLineDecorationLayerOrder = 0;

  (int, int)? _selectionStart;
  (int, int)? _selectionEnd;
  bool _mouseSelecting = false;

  // Double click tracking
  DateTime? _lastClickTime;
  (int, int)? _lastClickPos;
  int _lastClickCount = 0;

  bool get focused => _focused;
  int get line => _row;
  int get column => _col;
  int get width => _width;
  int get height => _height;
  int get lineCount => _document.lineCount;
  int get _lineNumberDigits => showLineNumbers
      ? math.max(minimumLineNumberDigits, '$lineCount'.length)
      : 0;
  int get length => _totalGraphemeLength();
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  bool get isDirty => value != _savedValue;
  bool get hasSelection => _hasSelection();

  /// Limits for search, decorations, completions, and syntax work.
  EditorWorkBudget workBudget = const EditorWorkBudget();

  /// Fold projection applied by [TextView]. Hidden lines are not painted.
  FoldState folds = FoldState();

  /// Feature recommendations for the current document.
  EditorWorkAssessment get workAssessment => workBudget.assess(_document);

  bool _searchTruncated = false;

  /// Whether the current search stopped at [EditorWorkBudget.maxSearchResults].
  bool get searchTruncated => _searchTruncated;

  /// Active normalized selections. A single legacy cursor is returned when
  /// multi-cursor mode is inactive.
  TextSelectionSet get selections {
    final active = _selections;
    if (active != null) return active;
    final snapshot = _currentOffsetStateSnapshot();
    final baseOffset = snapshot.selectionBaseOffset;
    final extentOffset = snapshot.selectionExtentOffset;
    if (baseOffset == null || extentOffset == null) {
      return TextSelectionSet.collapsed(cursorOffset);
    }
    return TextSelectionSet([
      TextSelectionRange.directional(
        anchorOffset: baseOffset,
        activeOffset: extentOffset,
      ),
    ], primaryOffset: cursorOffset);
  }

  /// Whether more than one cursor or selection is active.
  bool get hasMultipleSelections => (_selections?.ranges.length ?? 0) > 1;

  /// Current completion candidates.
  List<EditorCompletionItem> get completionItems =>
      List<EditorCompletionItem>.unmodifiable(_completionItems);

  int get completionIndex => _completionIndex;
  EditorCompletionItem? get activeCompletion =>
      _completionIndex >= 0 && _completionIndex < _completionItems.length
      ? _completionItems[_completionIndex]
      : null;
  bool get completionVisible => _completionItems.isNotEmpty;
  Object? get completionError => _completionError;

  /// Additional edits from the last accepted completion, consumed once.
  WorkspaceEdit? consumeCompletionAdditionalEdits() {
    final edits = _lastCompletionAdditionalEdits;
    _lastCompletionAdditionalEdits = null;
    return edits;
  }

  TextSearchQuery? get searchQuery => _searchSession?.query;
  List<TextSearchMatch> get searchMatches =>
      List<TextSearchMatch>.unmodifiable(_searchSession?.matches ?? const []);
  int get searchMatchIndex => _searchSession?.index ?? -1;
  TextSearchMatch? get activeSearchMatch => _searchSession?.current;
  String? get searchError => _searchError;

  List<EditorCodeAction> get codeActions =>
      List<EditorCodeAction>.unmodifiable(_codeActions);
  int get codeActionIndex => _codeActionIndex;
  EditorCodeAction? get activeCodeAction =>
      _codeActionIndex >= 0 && _codeActionIndex < _codeActions.length
      ? _codeActions[_codeActionIndex]
      : null;
  Object? get codeActionError => _codeActionError;

  EditorCodeAction? consumeAcceptedCodeAction() {
    final action = _acceptedCodeAction;
    _acceptedCodeAction = null;
    return action;
  }

  /// Commands available to keymaps, palettes, and host integrations.
  EditorCommandRegistry<TextAreaModel> get commandRegistry => _commandRegistry;

  /// Dispatches a stable editor command against this model.
  EditorCommandDispatchResult executeCommand(
    String commandId, {
    Object? argument,
  }) => _commandRegistry.dispatch(commandId, this, argument: argument);

  TextDocument get document {
    return _document;
  }

  EditorState get editorState {
    _refreshEditorStateSnapshot();
    return _editorState;
  }

  List<TextDiagnosticRange> get diagnostics => List.unmodifiable(_diagnostics);
  TextDiagnosticRange? get activeDiagnostic => _activeDiagnostic();
  List<TextDecorationRange> get decorations => List.unmodifiable(_decorations);
  List<TextLineDecoration> get lineDecorations =>
      List.unmodifiable(_lineDecorations);
  TextDocumentChange? consumeLastDocumentChange() {
    final change = _lastDocumentChange;
    _lastDocumentChange = null;
    return change;
  }

  List<TextDecorationRange> decorationsForLayer(String layerKey) {
    return List.unmodifiable(
      _decorationLayers[layerKey]?.decorations ?? const <TextDecorationRange>[],
    );
  }

  List<TextLineDecoration> lineDecorationsForLayer(String layerKey) {
    return List.unmodifiable(
      _lineDecorationLayers[layerKey]?.decorations ??
          const <TextLineDecoration>[],
    );
  }

  /// Anchor position of the current selection, if any.
  ({int line, int column})? get selectionBase => _selectionStart == null
      ? null
      : (line: _selectionStart!.$2, column: _selectionStart!.$1);

  /// Active extent position of the current selection, if any.
  ({int line, int column})? get selectionExtent => _selectionEnd == null
      ? null
      : (line: _selectionEnd!.$2, column: _selectionEnd!.$1);

  /// Returns the current value of the textarea.
  String get value => _document.text;

  /// Marks the current value as the persisted baseline.
  void markSaved() {
    _savedValue = value;
  }

  /// Runs every edit invoked by [body] as one undoable transaction.
  ///
  /// Transactions may nest. Only the outer boundary commits history, allowing
  /// completion, formatting, snippets, and host commands to compose existing
  /// textarea operations without creating partial undo steps.
  T editTransaction<T>(T Function(TextAreaModel model) body) {
    final before = _captureEditState();
    final historyCheckpoint = _history.checkpoint();
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      _recordUndoSnapshot();
      try {
        return body(this);
      } catch (_) {
        _history.restoreCheckpoint(historyCheckpoint);
        _restoreEditState(before);
        rethrow;
      }
    });
  }

  /// Cursor offset in graphemes from the document start.
  ///
  /// Exposes the caret for overlay positioning and inline-element
  /// hit-testing (image chips, file refs) without reaching into document
  /// internals.
  int get cursorOffset => _document.offsetForPosition(_currentCursorPosition());

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
      _selections = null;
      final limited = _applyCharLimit(v);
      _replaceText(limited);
      _collapseLineState(
        TextPosition(
          line: lineCount - 1,
          column: _document.lineLength(lineCount - 1),
        ),
      );
      _lastDocumentChange = null;
    });
  }

  /// Sets the prompt function.
  void setPromptFunc(int promptWidth, PromptFunc fn) {
    _promptWidth = promptWidth;
    promptFunc = fn;
  }

  /// Returns the text of the line at the given index.
  String lineAt(int i) {
    if (i < 0 || i >= lineCount) return '';
    return _document.lineAt(i);
  }

  /// Sets the cursor position.
  void setCursor(int row, int col) {
    _selections = null;
    _moveLineCursor(TextPosition(line: row, column: col));
    _lastDocumentChange = null;
    _syncCoreState();
  }

  /// Sets the current selection and places the cursor at the extent.
  void setSelection({
    required int baseLine,
    required int baseColumn,
    required int extentLine,
    required int extentColumn,
  }) {
    _selections = null;
    _selectLineState(
      base: TextPosition(line: baseLine, column: baseColumn),
      extent: TextPosition(line: extentLine, column: extentColumn),
      cursor: TextPosition(line: extentLine, column: extentColumn),
      preserveCollapsedSelection: true,
    );
    _lastDocumentChange = null;
    _syncCoreState();
  }

  /// Clears the current selection.
  void clearSelection() {
    _selections = null;
    _clearLineSelection();
    _lastDocumentChange = null;
    _syncCoreState();
  }

  /// Selects the entire textarea contents.
  void selectAll() {
    _selections = null;
    final lastLine = lineCount - 1;
    _selectLineState(
      base: const TextPosition(line: 0, column: 0),
      extent: TextPosition(
        line: lastLine,
        column: _document.lineLength(lastLine),
      ),
    );
    _lastDocumentChange = null;
    _syncCoreState();
  }

  /// Selects the current line, or expands the current selection to full lines.
  void selectCurrentLine() {
    _selections = null;
    final (startLine, endLine) = _selectedLineRange();
    _selectLineState(
      base: TextPosition(line: startLine, column: 0),
      extent: TextPosition(
        line: endLine,
        column: _document.lineLength(endLine),
      ),
    );
    _lastDocumentChange = null;
    _syncCoreState();
  }

  /// Activates normalized multi-cursor selections in document coordinates.
  ///
  /// The primary range is mirrored to the legacy cursor and selection fields
  /// used by rendering and scrolling.
  void setSelections(TextSelectionSet value) {
    final clamped = TextSelectionSet(
      value.ranges.map(
        (range) => TextSelectionRange.directional(
          anchorOffset: range.anchorOffset.clamp(0, length),
          activeOffset: range.activeOffset.clamp(0, length),
        ),
      ),
      primaryOffset: value.primary?.activeOffset.clamp(0, length),
    );
    _selections = clamped.ranges.length > 1 ? clamped : null;
    final primary =
        clamped.primary ??
        TextSelectionRange(startOffset: cursorOffset, endOffset: cursorOffset);
    _applyLineStateSnapshot(
      lineSnapshotFromOffsets(
        _document,
        cursorOffset: primary.activeOffset,
        selectionBaseOffset: primary.isCollapsed ? null : primary.anchorOffset,
        selectionExtentOffset: primary.isCollapsed
            ? null
            : primary.activeOffset,
      ),
    );
    _lastDocumentChange = null;
    _syncCoreState();
  }

  /// Adds a collapsed cursor at [offset] and makes it primary.
  void addCursorAtOffset(int offset) {
    setSelections(
      selections.add(
        TextSelectionRange(
          startOffset: offset.clamp(0, length),
          endOffset: offset.clamp(0, length),
        ),
      ),
    );
  }

  /// Adds a cursor on the adjacent document line at the primary visual column.
  bool addCursorVertically({required bool below}) {
    final primary = selections.primary;
    if (primary == null) return false;
    final target = textOffsetOnAdjacentVisibleLine(
      document: _document,
      offset: primary.activeOffset,
      below: below,
      isLineHidden: folds.isLineHidden,
    );
    if (target == primary.activeOffset) return false;
    final before = selections.ranges.length;
    addCursorAtOffset(target);
    return selections.ranges.length > before;
  }

  /// Adds the next occurrence of the primary selected text.
  ///
  /// Search wraps once and skips ranges already represented in the set.
  bool addNextOccurrence() {
    final active = selections;
    final primary = active.primary;
    if (primary == null || primary.isCollapsed) return false;
    final query = _document.textInRange(
      startOffset: primary.startOffset,
      endOffset: primary.endOffset,
    );
    if (query.isEmpty) return false;
    final result = findTextSearchMatches(
      _document,
      TextSearchQuery(pattern: query, caseSensitive: true),
    );
    if (result.matches.isEmpty) return false;
    final ordered = [
      ...result.matches.where(
        (match) => match.startOffset >= primary.endOffset,
      ),
      ...result.matches.where((match) => match.startOffset < primary.endOffset),
    ];
    for (final match in ordered) {
      final duplicate = active.ranges.any(
        (range) =>
            range.startOffset == match.startOffset &&
            range.endOffset == match.endOffset,
      );
      if (duplicate) continue;
      setSelections(
        active.add(
          TextSelectionRange(
            startOffset: match.startOffset,
            endOffset: match.endOffset,
          ),
        ),
      );
      return true;
    }
    return false;
  }

  /// Starts or incrementally refreshes a grapheme-aware search session.
  TextSearchResult startSearch(TextSearchQuery query) {
    final result = findTextSearchMatches(
      _document,
      query,
      maxResults: workAssessment.maxSearchResults,
    );
    _searchError = result.error;
    _searchTruncated = result.truncated;
    _searchSession = TextSearchSession(query: query, matches: result.matches);
    setHighlights(
      result.matches.map(
        (match) => TextHighlightRange(
          startOffset: match.startOffset,
          endOffset: match.endOffset,
        ),
      ),
    );
    return result;
  }

  /// Closes the search session and removes only its highlight layer.
  void closeSearch() {
    _searchSession = null;
    _searchError = null;
    _searchTruncated = false;
    clearHighlights();
  }

  /// Selects the next or previous search match.
  bool selectSearchMatch({required bool forward, bool wrap = true}) {
    final session = _searchSession;
    if (session == null) return false;
    final match = forward
        ? session.next(wrap: wrap)
        : session.previous(wrap: wrap);
    if (match == null) return false;
    setSelections(
      TextSelectionSet([
        TextSelectionRange(
          startOffset: match.startOffset,
          endOffset: match.endOffset,
        ),
      ], primaryOffset: match.endOffset),
    );
    setHighlights(
      session.matches.map(
        (candidate) => TextHighlightRange(
          startOffset: candidate.startOffset,
          endOffset: candidate.endOffset,
        ),
      ),
      activeIndex: session.index,
    );
    return true;
  }

  /// Replaces the active match and refreshes the current search.
  bool replaceActiveSearchMatch(String replacementTemplate) {
    final session = _searchSession;
    final match = session?.current;
    if (session == null || match == null) return false;
    final matchedText = _document.textInRange(
      startOffset: match.startOffset,
      endOffset: match.endOffset,
    );
    final replacement = expandSearchReplacementTemplate(
      replacementTemplate,
      match,
      matchedText,
    );
    setSelections(
      TextSelectionSet([
        TextSelectionRange(
          startOffset: match.startOffset,
          endOffset: match.endOffset,
        ),
      ], primaryOffset: match.endOffset),
    );
    insertString(replacement);
    startSearch(session.query);
    return true;
  }

  /// Replaces all current matches as one undoable edit.
  bool replaceAllSearchMatches(String replacementTemplate) {
    final session = _searchSession;
    if (session == null || session.matches.isEmpty) return false;
    final graphemes = _document.flattenWithNewlines();
    final replaced = replaceTextSearchMatches(
      graphemes,
      session.matches,
      (match) => uni
          .graphemes(
            expandSearchReplacementTemplate(
              replacementTemplate,
              match,
              match.groups.isEmpty ? '' : match.groups.first ?? '',
            ),
          )
          .toList(growable: false),
    );
    setText(replaced.join());
    startSearch(session.query);
    return true;
  }

  bool setDecorations(Iterable<TextDecorationRange> decorations) {
    return setDecorationLayer(
      textDefaultDecorationLayerKey,
      decorations,
      priority: textDefaultDecorationLayerPriority,
    );
  }

  /// Incrementally synchronizes [session] and updates the dedicated syntax
  /// decoration layer without disturbing search or diagnostics.
  TextSyntaxSnapshot<State> syncSyntax<State>(
    TextSyntaxSession<State> session, {
    String? language,
    bool force = false,
  }) {
    if (!force && !workAssessment.allowSynchronousSyntax) {
      return session.snapshot ??
          TextSyntaxSnapshot<State>(
            decorations: decorationsForLayer(textSyntaxDecorationLayerKey),
            language: language ?? session.language,
            document: _document,
          );
    }
    final snapshot = session.syncDocument(
      _document,
      language: language,
      force: force,
      change: _lastDocumentChange,
    );
    setDecorationLayer(
      textSyntaxDecorationLayerKey,
      snapshot.decorations,
      priority: textSyntaxDecorationLayerPriority,
    );
    return snapshot;
  }

  /// Asynchronously synchronizes syntax without publishing stale results.
  ///
  /// The session rejects results superseded by a newer request. This method
  /// additionally verifies that the textarea still contains the requested
  /// document before updating its syntax decoration layer.
  Future<TextSyntaxSnapshot<State>?> syncSyntaxAsync<State>(
    AsyncTextSyntaxSession<State> session, {
    String? language,
    bool force = false,
  }) async {
    _refreshDocumentSnapshot();
    final requestedDocument = _document;
    final snapshot = await session.request(
      requestedDocument,
      language: language,
      force: force,
      change: _lastDocumentChange,
    );
    if (snapshot == null) return null;
    _refreshDocumentSnapshot();
    if (_document.text != requestedDocument.text) return null;
    setDecorationLayer(
      textSyntaxDecorationLayerKey,
      snapshot.decorations,
      priority: textSyntaxDecorationLayerPriority,
    );
    return snapshot;
  }

  /// Removes syntax decorations while preserving every other layer.
  bool clearSyntax() => clearDecorationLayer(textSyntaxDecorationLayerKey);

  bool setDecorationLayer(
    String layerKey,
    Iterable<TextDecorationRange> decorations, {
    int priority = textDefaultDecorationLayerPriority,
  }) {
    _refreshDocumentSnapshot();
    final maxDecorations = workAssessment.maxDecorations;
    var normalized = decorations
        .map((range) => range.normalized().clamp(_document.length))
        .where((range) => !range.isEmpty)
        .toList(growable: false);
    if (normalized.length > maxDecorations) {
      normalized = normalized.sublist(0, maxDecorations);
    }

    final existingLayer = _decorationLayers[layerKey];
    if (normalized.isEmpty) {
      if (existingLayer == null) {
        return false;
      }
      _decorationLayers.remove(layerKey);
      _rebuildDecorations();
      return true;
    }

    if (existingLayer != null &&
        existingLayer.priority == priority &&
        _decorationListsEqual(existingLayer.decorations, normalized)) {
      return false;
    }

    _decorationLayers[layerKey] = (
      decorations: normalized,
      order: existingLayer?.order ?? _nextDecorationLayerOrder++,
      priority: priority,
    );
    _rebuildDecorations();
    return true;
  }

  bool clearDecorations() {
    if (_decorationLayers.isEmpty) {
      return false;
    }
    _decorationLayers.clear();
    _rebuildDecorations();
    return true;
  }

  bool clearDecorationLayer(String layerKey) {
    if (!_decorationLayers.containsKey(layerKey)) {
      return false;
    }
    _decorationLayers.remove(layerKey);
    _rebuildDecorations();
    return true;
  }

  bool setHighlights(
    Iterable<TextHighlightRange> highlights, {
    int activeIndex = -1,
  }) {
    return setDecorationLayer(
      textSearchDecorationLayerKey,
      textSearchDecorations(highlights, activeIndex: activeIndex),
      priority: textSearchDecorationLayerPriority,
    );
  }

  bool clearHighlights() {
    return clearDecorationLayer(textSearchDecorationLayerKey);
  }

  bool setDiagnostics(Iterable<TextDiagnosticRange> diagnostics) {
    _refreshDocumentSnapshot();
    final normalizedDiagnostics = normalizeTextDiagnostics(
      diagnostics,
      maxLength: _document.length,
    );
    _diagnostics = normalizedDiagnostics;
    final changedRanges = setDecorationLayer(
      textDiagnosticsDecorationLayerKey,
      textDiagnosticDecorations(normalizedDiagnostics),
      priority: textDiagnosticsDecorationLayerPriority,
    );
    final changedLines = setLineDecorationLayer(
      textDiagnosticsLineDecorationLayerKey,
      textDiagnosticLineDecorations(
        text: value,
        diagnostics: normalizedDiagnostics,
      ),
      priority: textDiagnosticsLineDecorationLayerPriority,
    );
    return changedRanges || changedLines;
  }

  bool setDiagnosticsFromPositions(
    Iterable<TextPositionDiagnosticRange> diagnostics,
  ) {
    _refreshDocumentSnapshot();
    return setDiagnostics(
      textDiagnosticsFromPositions(
        document: _document,
        diagnostics: diagnostics,
      ),
    );
  }

  bool clearDiagnostics() {
    _diagnostics = const [];
    final clearedRanges = clearDecorationLayer(
      textDiagnosticsDecorationLayerKey,
    );
    final clearedLines = clearLineDecorationLayer(
      textDiagnosticsLineDecorationLayerKey,
    );
    return clearedRanges || clearedLines;
  }

  bool selectNextDiagnostic({bool wrap = true}) {
    return _selectRelativeDiagnostic(forward: true, wrap: wrap);
  }

  bool selectPreviousDiagnostic({bool wrap = true}) {
    return _selectRelativeDiagnostic(forward: false, wrap: wrap);
  }

  bool selectDiagnosticAtLine(int lineIndex) {
    _refreshDocumentSnapshot();
    if (_diagnostics.isEmpty) {
      return false;
    }

    final state = _currentOffsetStateSnapshot();
    final index = _diagnosticIndexForLine(
      lineIndex,
      activeIndex: _currentDiagnosticIndex(state),
    );
    if (index == null) {
      return false;
    }
    _selectDiagnosticAtIndex(index);
    return true;
  }

  bool setLineDecorations(Iterable<TextLineDecoration> decorations) {
    return setLineDecorationLayer(
      textDefaultLineDecorationLayerKey,
      decorations,
      priority: textDefaultLineDecorationLayerPriority,
    );
  }

  bool setLineDecorationLayer(
    String layerKey,
    Iterable<TextLineDecoration> decorations, {
    int priority = textDefaultLineDecorationLayerPriority,
  }) {
    final normalized = decorations
        .map((decoration) => decoration.clamp(lineCount))
        .toList(growable: false);

    final existingLayer = _lineDecorationLayers[layerKey];
    if (normalized.isEmpty) {
      if (existingLayer == null) {
        return false;
      }
      _lineDecorationLayers.remove(layerKey);
      _syncImplicitLineDecorations();
      return true;
    }

    if (existingLayer != null &&
        existingLayer.priority == priority &&
        _lineDecorationListsEqual(existingLayer.decorations, normalized)) {
      return false;
    }

    _lineDecorationLayers[layerKey] = (
      decorations: normalized,
      order: existingLayer?.order ?? _nextLineDecorationLayerOrder++,
      priority: priority,
    );
    _syncImplicitLineDecorations();
    return true;
  }

  bool clearLineDecorations() {
    if (_lineDecorationLayers.isEmpty) {
      return false;
    }
    _lineDecorationLayers.clear();
    _syncImplicitLineDecorations();
    return true;
  }

  bool clearLineDecorationLayer(String layerKey) {
    if (!_lineDecorationLayers.containsKey(layerKey)) {
      return false;
    }
    _lineDecorationLayers.remove(layerKey);
    _syncImplicitLineDecorations();
    return true;
  }

  bool _selectRelativeDiagnostic({required bool forward, bool wrap = true}) {
    _refreshDocumentSnapshot();
    if (_diagnostics.isEmpty) {
      return false;
    }

    final state = _currentOffsetStateSnapshot();
    final index = textDiagnosticNavigationIndex(
      diagnostics: _diagnostics,
      cursorOffset: state.cursorOffset,
      activeIndex: _currentDiagnosticIndex(state),
      forward: forward,
      wrap: wrap,
    );
    if (index == null) {
      return false;
    }
    return _selectDiagnosticAtIndex(index);
  }

  bool _selectDiagnosticAtIndex(int index) {
    if (index < 0 || index >= _diagnostics.length) {
      return false;
    }

    _refreshDocumentSnapshot();
    final before = _currentOffsetStateSnapshot();
    final diagnostic = _diagnostics[index];
    final startOffset = diagnostic.startOffset.clamp(0, _document.length);
    final endOffset = diagnostic.endOffset.clamp(startOffset, _document.length);
    final start = _document.positionForOffset(startOffset);

    if (endOffset > startOffset) {
      final end = _document.positionForOffset(endOffset);
      setSelection(
        baseLine: start.line,
        baseColumn: start.column,
        extentLine: end.line,
        extentColumn: end.column,
      );
    } else {
      setCursor(start.line, start.column);
    }

    final after = _currentOffsetStateSnapshot();
    return before.cursorOffset != after.cursorOffset ||
        before.selectionBaseOffset != after.selectionBaseOffset ||
        before.selectionExtentOffset != after.selectionExtentOffset;
  }

  int? _currentDiagnosticIndex(TextOffsetStateSnapshot state) {
    final selection = state.normalizedSelectionRange;
    if (selection == null) {
      return null;
    }

    for (var index = 0; index < _diagnostics.length; index++) {
      final diagnostic = _diagnostics[index];
      if (diagnostic.startOffset == selection.start &&
          diagnostic.endOffset == selection.end) {
        return index;
      }
    }
    return null;
  }

  int? _diagnosticIndexForLine(int lineIndex, {int? activeIndex}) {
    if (lineIndex < 0 || lineIndex >= lineCount) {
      return null;
    }

    if (activeIndex != null &&
        activeIndex >= 0 &&
        activeIndex < _diagnostics.length &&
        _diagnosticSpansLine(_diagnostics[activeIndex], lineIndex)) {
      return activeIndex;
    }

    int? bestIndex;
    for (var index = 0; index < _diagnostics.length; index++) {
      final diagnostic = _diagnostics[index];
      if (!_diagnosticSpansLine(diagnostic, lineIndex)) {
        continue;
      }

      if (bestIndex == null) {
        bestIndex = index;
        continue;
      }

      final best = _diagnostics[bestIndex];
      final severityComparison = _diagnosticSeverityRank(
        diagnostic.severity,
      ).compareTo(_diagnosticSeverityRank(best.severity));
      if (severityComparison > 0 ||
          (severityComparison == 0 &&
              (diagnostic.startOffset < best.startOffset ||
                  (diagnostic.startOffset == best.startOffset &&
                      diagnostic.endOffset < best.endOffset)))) {
        bestIndex = index;
      }
    }

    return bestIndex;
  }

  bool _diagnosticSpansLine(TextDiagnosticRange diagnostic, int lineIndex) {
    final normalized = diagnostic.normalized();
    final startOffset = normalized.startOffset.clamp(0, _document.length);
    final endOffset = normalized.endOffset.clamp(startOffset, _document.length);
    final startLine = _document.positionForOffset(startOffset).line;
    final endLine = endOffset <= startOffset
        ? startLine
        : _document.positionForOffset(endOffset - 1).line;
    return lineIndex >= startLine && lineIndex <= endLine;
  }

  int _diagnosticSeverityRank(TextDiagnosticSeverity severity) {
    return switch (severity) {
      TextDiagnosticSeverity.error => 4,
      TextDiagnosticSeverity.warning => 3,
      TextDiagnosticSeverity.info => 2,
      TextDiagnosticSeverity.hint => 1,
    };
  }

  TextDiagnosticRange? _activeDiagnostic() {
    _refreshDocumentSnapshot();
    if (_diagnostics.isEmpty) {
      return null;
    }

    final state = _currentOffsetStateSnapshot();
    final activeIndex = _currentDiagnosticIndex(state);
    if (activeIndex != null) {
      return _diagnostics[activeIndex];
    }

    return textDiagnosticAtOffset(
      diagnostics: _diagnostics,
      offset: state.cursorOffset,
    );
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

  Style _textCellStyle(
    TextAreaStyleState style, {
    Style? lineDecorationStyle,
    Style? decorationStyle,
    required bool isSelected,
    bool useCursorStyle = false,
  }) {
    final cellStyle = style.computedText.copy();
    if (lineDecorationStyle != null) {
      cellStyle.inherit(lineDecorationStyle);
    }
    if (decorationStyle != null) {
      cellStyle.inherit(decorationStyle);
    }
    if (isSelected) {
      cellStyle.inherit(style.computedSelection);
    }
    if (useCursorStyle && cursor.visible && cursor.mode != CursorMode.hide) {
      cellStyle
        ..inherit(cursor.style.copy()..inline(true))
        ..inverse();
    }
    return cellStyle;
  }

  T _runEditFrame<T>(T Function() body) {
    return _history.runFrame(
      captureState: _captureEditState,
      body: body,
      onCommittedChange: _syncCoreState,
    );
  }

  _TextAreaEditState _captureEditState() {
    return _TextAreaEditState(
      value: value,
      row: _row,
      col: _col,
      selectionStart: _selectionStart,
      selectionEnd: _selectionEnd,
      selections: _selections,
    );
  }

  TextLineStateSnapshot _currentLineStateSnapshot() {
    final cursor = _currentCursorPosition();
    final selectionBase = _currentSelectionBasePosition();
    final selectionExtent = _currentSelectionExtentPosition();
    if (selectionBase == null || selectionExtent == null) {
      return TextLineStateSnapshot.collapsed(cursor: cursor);
    }

    return TextLineStateSnapshot.selection(
      base: selectionBase,
      extent: selectionExtent,
      cursor: cursor,
      preserveCollapsedSelection: true,
    );
  }

  TextOffsetStateSnapshot _currentOffsetStateSnapshot() {
    _refreshDocumentSnapshot();
    final cursorOffset = _document.offsetForPosition(_currentCursorPosition());
    final selectionBase = _currentSelectionBasePosition();
    final selectionExtent = _currentSelectionExtentPosition();
    if (selectionBase == null || selectionExtent == null) {
      return TextOffsetStateSnapshot.collapsed(cursorOffset: cursorOffset);
    }

    return TextOffsetStateSnapshot(
      cursorOffset: cursorOffset,
      selectionBaseOffset: _document.offsetForPosition(selectionBase),
      selectionExtentOffset: _document.offsetForPosition(selectionExtent),
    );
  }

  void _applyLineStateSnapshot(TextLineStateSnapshot snapshot) {
    final clamped = snapshot.clamp(
      lineCount: lineCount,
      lineLength: (line) => _document.lineLength(line),
      preserveCollapsedSelection: true,
    );
    _row = clamped.cursor.line;
    _col = clamped.cursor.column;
    _selectionStart = clamped.selectionBase == null
        ? null
        : (clamped.selectionBase!.column, clamped.selectionBase!.line);
    _selectionEnd = clamped.selectionExtent == null
        ? null
        : (clamped.selectionExtent!.column, clamped.selectionExtent!.line);
    _editorStateDirty = true;
    _selectionGeneration++;
  }

  void _collapseLineState(TextPosition cursor) {
    _moveLineCursor(cursor, clearSelection: true);
  }

  void _selectLineState({
    required TextPosition base,
    required TextPosition extent,
    TextPosition? cursor,
    bool preserveCollapsedSelection = false,
  }) {
    _selections = null;
    _applyLineStateSnapshot(
      TextLineStateSnapshot.selection(
        base: base,
        extent: extent,
        cursor: cursor,
        preserveCollapsedSelection: preserveCollapsedSelection,
      ),
    );
  }

  void _clearLineSelection() {
    _applyLineStateSnapshot(_currentLineStateSnapshot().clearSelection());
  }

  TextPosition _currentCursorPosition() {
    return TextPosition(line: _row, column: _col);
  }

  TextPosition? _currentSelectionBasePosition() {
    if (_selectionStart == null) {
      return null;
    }
    return TextPosition(line: _selectionStart!.$2, column: _selectionStart!.$1);
  }

  TextPosition? _currentSelectionExtentPosition() {
    if (_selectionEnd == null) {
      return null;
    }
    return TextPosition(line: _selectionEnd!.$2, column: _selectionEnd!.$1);
  }

  void _moveLineCursor(TextPosition cursor, {bool clearSelection = false}) {
    _selections = null;
    final selectionBase = clearSelection
        ? null
        : _currentSelectionBasePosition();
    final selectionExtent = clearSelection
        ? null
        : _currentSelectionExtentPosition();
    if (selectionBase == null || selectionExtent == null) {
      _applyLineStateSnapshot(TextLineStateSnapshot.collapsed(cursor: cursor));
      return;
    }

    _applyLineStateSnapshot(
      TextLineStateSnapshot.selection(
        base: selectionBase,
        extent: selectionExtent,
        cursor: cursor,
        preserveCollapsedSelection: true,
      ),
    );
  }

  void _syncCoreState() {
    _refreshEditorStateSnapshot();
    _configureTextView();
    _textView.ensureCursorVisible(_document, _editorState);
    _syncImplicitLineDecorations();
  }

  void _configureTextView() {
    _textView
      ..width = _width
      ..height = _height
      ..softWrap = softWrap
      ..leadingColumns = _leadingColumnsForView()
      ..folds = folds;
  }

  void _refreshDocumentSnapshot() {}

  int _leadingColumnsForView() {
    final lineNumberDigits = _lineNumberDigits;
    return _getPromptWidth(_row) + (showLineNumbers ? lineNumberDigits + 1 : 0);
  }

  void _refreshEditorStateSnapshot() {
    if (!_editorStateDirty) {
      return;
    }
    syncEditorStateFromLineSnapshot(
      _editorState,
      _currentLineStateSnapshot(),
      lineCount: lineCount,
      lineLength: (line) => _document.lineLength(line),
    );
    _editorStateDirty = false;
  }

  void _applyLineCommandResult(commands.TextLineCommandResult result) {
    _document.replaceLineTexts(
      List<String>.from(result.lines, growable: false),
    );
    _lastDocumentChange = null;
    _applyLineStateSnapshot(
      TextLineStateSnapshot(
        cursor: result.cursor,
        selectionBase: result.selectionBase,
        selectionExtent: result.selectionExtent,
      ),
    );
  }

  void _applyOffsetCursorCommandResult(
    commands.TextCursorCommandResult result,
  ) {
    _lastDocumentChange = null;
    _applyLineStateSnapshot(
      lineSnapshotFromOffsets(
        _document,
        cursorOffset: result.cursorOffset,
        selectionBaseOffset: result.selectionBaseOffset,
        selectionExtentOffset: result.selectionExtentOffset,
      ),
    );
  }

  void _applyOffsetCommandResult(commands.TextCommandResult result) {
    final nextDocument = result.document;
    if (nextDocument != null) {
      _replaceDocumentSnapshot(nextDocument);
    } else {
      _document.replaceOffsetRange(
        startOffset: 0,
        endOffset: _document.length,
        replacement: result.graphemes,
      );
    }
    _lastDocumentChange = result.documentChange;
    _applyLineStateSnapshot(
      lineSnapshotFromOffsets(
        _document,
        cursorOffset: result.cursorOffset,
        selectionBaseOffset: result.selectionBaseOffset,
        selectionExtentOffset: result.selectionExtentOffset,
      ),
    );
  }

  void _restoreEditState(_TextAreaEditState state) {
    _replaceText(state.value);
    _selections = state.selections;
    _lastDocumentChange = null;
    _applyLineStateSnapshot(
      TextLineStateSnapshot(
        cursor: TextPosition(line: state.row, column: state.col),
        selectionBase: state.selectionStart == null
            ? null
            : TextPosition(
                line: state.selectionStart!.$2,
                column: state.selectionStart!.$1,
              ),
        selectionExtent: state.selectionEnd == null
            ? null
            : TextPosition(
                line: state.selectionEnd!.$2,
                column: state.selectionEnd!.$1,
              ),
      ),
    );
    _syncCoreState();
  }

  void _beginHistoryAction(
    _TextAreaHistoryAction action, {
    bool breakChain = false,
  }) {
    _history.beginAction(action, breakChain: breakChain);
  }

  bool _hasSelection() =>
      _selectionStart != null &&
      _selectionEnd != null &&
      _selectionStart != _selectionEnd;

  bool _canCoalesceHistoryAction(
    _TextAreaHistoryAction action, {
    required _TextAreaHistoryAction? lastAction,
    required ({int row, int col, int length})? lastMarker,
    required _TextAreaEditState currentState,
  }) {
    if (currentState.selectionStart != null &&
        currentState.selectionEnd != null &&
        currentState.selectionStart != currentState.selectionEnd) {
      return false;
    }
    if (lastAction != action || lastMarker == null) return false;
    if (lastMarker.row != currentState.row) return false;
    if (lastMarker.col != currentState.col) return false;
    if (lastMarker.length != uni.graphemes(currentState.value).length) {
      return false;
    }
    return switch (action) {
      _TextAreaHistoryAction.insert => true,
      _TextAreaHistoryAction.deleteBackward => true,
      _TextAreaHistoryAction.deleteForward => true,
      _TextAreaHistoryAction.paste => true,
      _ => false,
    };
  }

  void _recordUndoSnapshot() {
    _history.recordUndoSnapshot(_captureEditState);
  }

  bool _decorationListsEqual(
    List<TextDecorationRange> a,
    List<TextDecorationRange> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  bool _lineDecorationListsEqual(
    List<TextLineDecoration> a,
    List<TextLineDecoration> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  void _rebuildDecorations() {
    if (_decorationLayers.isEmpty) {
      _decorations = const [];
      return;
    }

    final sortedLayers = _decorationLayers.values.toList(growable: false)
      ..sort((a, b) {
        final priorityComparison = a.priority.compareTo(b.priority);
        if (priorityComparison != 0) {
          return priorityComparison;
        }
        return a.order.compareTo(b.order);
      });

    _decorations = List<TextDecorationRange>.unmodifiable([
      for (final layer in sortedLayers) ...layer.decorations,
    ]);
  }

  void _rebuildLineDecorations() {
    if (_lineDecorationLayers.isEmpty) {
      _lineDecorations = const [];
      return;
    }

    final sortedLayers = _lineDecorationLayers.values.toList(growable: false)
      ..sort((a, b) {
        final priorityComparison = a.priority.compareTo(b.priority);
        if (priorityComparison != 0) {
          return priorityComparison;
        }
        return a.order.compareTo(b.order);
      });

    _lineDecorations = List<TextLineDecoration>.unmodifiable([
      for (final layer in sortedLayers) ...layer.decorations,
    ]);
  }

  void _syncImplicitLineDecorations() {
    if (useVirtualCursor) {
      _lineDecorationLayers.remove(textActiveLineDecorationLayerKey);
      _rebuildLineDecorations();
      return;
    }

    _lineDecorationLayers[textActiveLineDecorationLayerKey] = (
      decorations: <TextLineDecoration>[
        TextLineDecoration(
          lineIndex: _row.clamp(0, math.max(lineCount - 1, 0)),
          styleKey: textActiveLineDecorationKey,
          lineNumberStyleKey: textActiveLineNumberDecorationKey,
        ),
      ],
      order:
          _lineDecorationLayers[textActiveLineDecorationLayerKey]?.order ??
          _nextLineDecorationLayerOrder++,
      priority: textActiveLineDecorationLayerPriority,
    );
    _rebuildLineDecorations();
  }

  List<TextLineDecoration> _lineDecorationsForRow(int rowIndex) {
    final matches = <TextLineDecoration>[];
    for (final decoration in _lineDecorations) {
      if (decoration.lineIndex == rowIndex) {
        matches.add(decoration);
      }
    }
    return List<TextLineDecoration>.unmodifiable(matches);
  }

  Style? _lineDecorationStyleForDecorations(
    TextAreaStyleState style,
    Iterable<TextLineDecoration> decorations,
  ) {
    Style? mergedStyle;
    for (final decoration in decorations) {
      final nextStyle = style.computedLineDecorationStyle(decoration.styleKey);
      if (nextStyle == null || nextStyle.isEmpty) {
        continue;
      }
      mergedStyle ??= Style();
      mergedStyle.inherit(nextStyle);
    }
    return mergedStyle;
  }

  Style? _lineNumberDecorationStyleForDecorations(
    TextAreaStyleState style,
    Iterable<TextLineDecoration> decorations,
  ) {
    Style? mergedStyle;
    for (final decoration in decorations) {
      final nextStyle = decoration.lineNumberStyleKey == null
          ? style.computedLineDecorationStyle(decoration.styleKey)
          : style.computedLineNumberDecorationStyle(
              decoration.lineNumberStyleKey!,
              lineStyleKey: decoration.styleKey,
            );
      if (nextStyle == null || nextStyle.isEmpty) {
        continue;
      }
      mergedStyle ??= Style();
      mergedStyle.inherit(nextStyle);
    }
    return mergedStyle;
  }

  String? _lineNumberMarkerForDecorations(
    Iterable<TextLineDecoration> decorations,
  ) {
    String? marker;
    for (final decoration in decorations) {
      if (decoration.lineNumberMarker != null &&
          decoration.lineNumberMarker!.isNotEmpty) {
        marker = decoration.lineNumberMarker;
      }
    }
    return marker;
  }

  String _normalizedLineNumberMarker(String? marker) {
    if (marker == null || marker.isEmpty) {
      return ' ';
    }
    final graphemes = uni.graphemes(marker).toList(growable: false);
    if (graphemes.isEmpty) {
      return ' ';
    }
    return graphemes.first;
  }

  List<({int start, int end, String styleKey})> _segmentDecorationRanges(
    int rowIndex,
    int segmentStart,
    int segmentEnd,
  ) {
    if (_decorations.isEmpty || segmentStart >= segmentEnd) {
      return const [];
    }

    final ranges = <({int start, int end, String styleKey})>[];
    for (final decoration in _decorations) {
      final range = decoration.clamp(_document.length);
      if (range.isEmpty) {
        continue;
      }
      final start = _document.positionForOffset(range.startOffset);
      final end = _document.positionForOffset(range.endOffset);
      if (rowIndex < start.line || rowIndex > end.line) {
        continue;
      }

      int rowStart;
      int rowEnd;
      if (start.line == end.line) {
        rowStart = start.column;
        rowEnd = end.column;
      } else if (rowIndex == start.line) {
        rowStart = start.column;
        rowEnd = _document.lineLength(rowIndex);
      } else if (rowIndex == end.line) {
        rowStart = 0;
        rowEnd = end.column;
      } else {
        rowStart = 0;
        rowEnd = _document.lineLength(rowIndex);
      }

      final overlapStart = math.max(rowStart, segmentStart);
      final overlapEnd = math.min(rowEnd, segmentEnd);
      if (overlapStart >= overlapEnd) {
        continue;
      }

      ranges.add((
        start: overlapStart - segmentStart,
        end: overlapEnd - segmentStart,
        styleKey: range.styleKey,
      ));
    }

    return ranges;
  }

  String? _decorationStyleKeyForColumn(
    List<({int start, int end, String styleKey})> ranges,
    int column,
  ) {
    for (var index = ranges.length - 1; index >= 0; index--) {
      final range = ranges[index];
      if (column < range.start || column >= range.end) {
        continue;
      }
      return range.styleKey;
    }
    return null;
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
      _replaceText('');
      _collapseLineState(const TextPosition(line: 0, column: 0));
      _lastDocumentChange = null;
    });
  }

  /// Clears all undo and redo history.
  void clearHistory() {
    _history.clear();
  }

  /// Breaks the current undo coalescing chain.
  void pushHistoryBoundary() {
    _history.breakCoalescing();
  }

  /// Applies an offset-based command result to the live document state.
  void applyTextCommandResult(
    commands.TextCommandResult result, {
    bool pushHistoryBoundary = false,
  }) {
    if (pushHistoryBoundary) {
      this.pushHistoryBoundary();
    }
    _applyOffsetCommandResult(result);
    _syncCoreState();
    if (pushHistoryBoundary) {
      this.pushHistoryBoundary();
    }
  }

  /// Applies an offset cursor command result to the live document state.
  void applyTextCursorCommandResult(
    commands.TextCursorCommandResult result, {
    bool pushHistoryBoundary = false,
  }) {
    if (pushHistoryBoundary) {
      this.pushHistoryBoundary();
    }
    _applyOffsetCursorCommandResult(result);
    _syncCoreState();
    if (pushHistoryBoundary) {
      this.pushHistoryBoundary();
    }
  }

  /// Applies a line-based command result to the live document state.
  void applyTextLineCommandResult(
    commands.TextLineCommandResult result, {
    bool pushHistoryBoundary = false,
  }) {
    if (pushHistoryBoundary) {
      this.pushHistoryBoundary();
    }
    _applyLineCommandResult(result);
    _syncCoreState();
    if (pushHistoryBoundary) {
      this.pushHistoryBoundary();
    }
  }

  /// Indents the selected lines, or the current line if there is no selection.
  bool indentLines({int width = 2}) => indentAtSelections(width: width);

  /// Outdents the selected lines, or the current line if there is no selection.
  bool outdentLines({int width = 2}) => outdentAtSelections(width: width);

  /// Moves the selected lines, or the current line, one row upward.
  bool moveLinesUp() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textMoveSelectedLinesDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        direction: -1,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Moves the selected lines, or the current line, one row downward.
  bool moveLinesDown() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textMoveSelectedLinesDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        direction: 1,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Duplicates the selected lines, or the current line, above the current
  /// block and moves the selection/cursor to the duplicate.
  bool duplicateLinesAbove() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textDuplicateSelectedLinesAboveDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
      );
      if (!result.changed) {
        return false;
      }
      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Duplicates the selected lines, or the current line, below the current
  /// block and moves the selection/cursor to the duplicate.
  bool duplicateLinesBelow() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textDuplicateSelectedLinesBelowDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
      );
      if (!result.changed) {
        return false;
      }
      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
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
      final result = textCleanupWhitespaceDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        trimTrailingBlankLines: trimTrailingBlankLines,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Deletes the selected lines, or the current line if there is no selection.
  bool deleteLines() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textDeleteLinesDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Joins the current line with the next line, or joins the selected block
  /// into a single line.
  bool joinLines() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textJoinLinesDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Splits the current line at the cursor, or replaces the selected range
  /// with a newline and places the cursor at the start of the new line.
  bool splitLine() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      _refreshDocumentSnapshot();
      final result = textSplitLine(
        document: _document,
        state: _currentOffsetStateSnapshot(),
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Uppercases the selected range, or the current line when there is no
  /// selection.
  bool uppercaseSelectionOrLine() {
    return _transformSelectionOrLineShared((text) => text.toUpperCase());
  }

  /// Lowercases the selected range, or the current line when there is no
  /// selection.
  bool lowercaseSelectionOrLine() {
    return _transformSelectionOrLineShared((text) => text.toLowerCase());
  }

  /// Capitalizes words in the selected range, or the current line when there
  /// is no selection.
  bool capitalizeSelectionOrLine() {
    return _transformSelectionOrLineShared(textCapitalizeWords);
  }

  /// Sorts the selected lines, or the entire buffer when there is no
  /// selection.
  bool sortSelectedLines({
    bool descending = false,
    bool caseSensitive = false,
  }) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textSortSelectedLinesDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        descending: descending,
        caseSensitive: caseSensitive,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
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
      final result = textToggleLinePrefixDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        prefix: prefix,
        addSpaceWhenNonEmpty: addSpaceWhenNonEmpty,
        skipBlankLinesWhenChecking: skipBlankLinesWhenChecking,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Toggles numbered list prefixes on the current line or selected block.
  ///
  /// When adding numbering, non-blank lines are numbered sequentially starting
  /// at [startAt]. Blank lines are left unchanged.
  bool toggleNumberedList({int startAt = 1}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textToggleNumberedListDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        startAt: startAt,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Renumbers existing numbered list items in the current line or selected
  /// block.
  ///
  /// Only lines that already begin with a numbered list prefix are rewritten.
  /// Other lines are left unchanged.
  bool renumberNumberedList({int startAt = 1}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textRenumberNumberedListDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        startAt: startAt,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Toggles Markdown heading prefixes on the current line or selected block.
  ///
  /// When all relevant lines already use the requested heading [level], that
  /// prefix is removed. Otherwise, existing heading prefixes are normalized to
  /// the requested level and missing prefixes are added.
  bool toggleHeadingPrefix({int level = 1}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textToggleHeadingPrefixDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        level: level,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Toggles checklist completion state on the current line or selected block.
  ///
  /// When all relevant checklist items are checked, they are cleared back to
  /// unchecked state. Otherwise all relevant items are marked with
  /// [checkedMarker].
  bool toggleChecklistState({String checkedMarker = 'x'}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textToggleChecklistStateDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        checkedMarker: checkedMarker,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Wraps the current selection with [before] and [after].
  ///
  /// If [after] is omitted, [before] is used for both sides.
  /// Returns `false` when there is no active selection.
  bool wrapSelection(String before, {String? after}) {
    if (!_hasSelection()) return false;
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      _refreshDocumentSnapshot();
      final result = textWrapSelection(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        before: before,
        after: after,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
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
      _refreshDocumentSnapshot();
      final result = textUnwrapSelection(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        surroundPairs: _selectionSurroundPairs,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Restores the most recent previous edit state.
  bool undo() {
    return _history.undo(
      captureState: _captureEditState,
      restoreState: _restoreEditState,
    );
  }

  /// Reapplies the most recently undone edit state.
  bool redo() {
    return _history.redo(
      captureState: _captureEditState,
      restoreState: _restoreEditState,
    );
  }

  EditorCommandRegistry<TextAreaModel> _createCommandRegistry() {
    return EditorCommandRegistry<TextAreaModel>()..registerAll([
      EditorCommand(
        id: EditorCommandIds.undo,
        label: 'Undo',
        category: 'Edit',
        isEnabled: (model) => model.canUndo,
        execute: (model) => model.undo(),
      ),
      EditorCommand(
        id: EditorCommandIds.redo,
        label: 'Redo',
        category: 'Edit',
        isEnabled: (model) => model.canRedo,
        execute: (model) => model.redo(),
      ),
      EditorCommand(
        id: EditorCommandIds.selectAll,
        label: 'Select All',
        category: 'Selection',
        isEnabled: (model) => model.length > 0,
        execute: (model) {
          model.selectAll();
          return true;
        },
      ),
      EditorCommand(
        id: EditorCommandIds.selectLine,
        label: 'Select Line',
        category: 'Selection',
        execute: (model) {
          model.selectCurrentLine();
          return true;
        },
      ),
      EditorCommand(
        id: EditorCommandIds.clearSelection,
        label: 'Clear Selection',
        category: 'Selection',
        isEnabled: (model) => model.hasSelection,
        execute: (model) {
          model.clearSelection();
          return true;
        },
      ),
      EditorCommand(
        id: EditorCommandIds.insertLineBreak,
        label: 'Insert Line Break',
        category: 'Edit',
        execute: (model) {
          model.insertString('\n');
          return true;
        },
      ),
      EditorCommand(
        id: EditorCommandIds.insertText,
        label: 'Insert Text',
        category: 'Edit',
        execute: (_) => false,
        executeWith: (model, argument) {
          if (argument is! String || argument.isEmpty) return false;
          model.insertString(argument);
          return true;
        },
      ),
      EditorCommand(
        id: EditorCommandIds.addCursorAbove,
        label: 'Add Cursor Above',
        category: 'Selection',
        execute: (model) => model.addCursorVertically(below: false),
      ),
      EditorCommand(
        id: EditorCommandIds.addCursorBelow,
        label: 'Add Cursor Below',
        category: 'Selection',
        execute: (model) => model.addCursorVertically(below: true),
      ),
      EditorCommand(
        id: EditorCommandIds.addNextOccurrence,
        label: 'Add Next Occurrence',
        category: 'Selection',
        isEnabled: (model) => model.hasSelection,
        execute: (model) => model.addNextOccurrence(),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorLeft,
        label: 'Move Cursors Left',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsHorizontally(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorRight,
        label: 'Move Cursors Right',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsHorizontally(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorWordLeft,
        label: 'Move Cursors One Word Left',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsByWord(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorWordRight,
        label: 'Move Cursors One Word Right',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsByWord(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorLineStart,
        label: 'Move Cursors to Line Start',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsToLineBoundary(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorLineEnd,
        label: 'Move Cursors to Line End',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsToLineBoundary(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorVisualLineStart,
        label: 'Move Cursors to Visual Line Start',
        category: 'Cursor',
        execute: (model) =>
            model.moveSelectionsToVisualLineBoundary(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorVisualLineEnd,
        label: 'Move Cursors to Visual Line End',
        category: 'Cursor',
        execute: (model) =>
            model.moveSelectionsToVisualLineBoundary(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.deleteLeft,
        label: 'Delete Left at Cursors',
        category: 'Edit',
        execute: (model) => model.deleteAtSelections(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.deleteRight,
        label: 'Delete Right at Cursors',
        category: 'Edit',
        execute: (model) => model.deleteAtSelections(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.deleteWordLeft,
        label: 'Delete Word Left at Cursors',
        category: 'Edit',
        execute: (model) => model.deleteWordAtSelections(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.deleteWordRight,
        label: 'Delete Word Right at Cursors',
        category: 'Edit',
        execute: (model) => model.deleteWordAtSelections(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.deleteLineLeft,
        label: 'Delete to Line Start at Cursors',
        category: 'Edit',
        execute: (model) =>
            model.deleteToLineBoundaryAtSelections(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.deleteLineRight,
        label: 'Delete to Line End at Cursors',
        category: 'Edit',
        execute: (model) =>
            model.deleteToLineBoundaryAtSelections(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.nextSearchMatch,
        label: 'Find Next',
        category: 'Find',
        isEnabled: (model) => model.searchMatches.isNotEmpty,
        execute: (model) => model.selectSearchMatch(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.previousSearchMatch,
        label: 'Find Previous',
        category: 'Find',
        isEnabled: (model) => model.searchMatches.isNotEmpty,
        execute: (model) => model.selectSearchMatch(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.nextDiagnostic,
        label: 'Go to Next Diagnostic',
        category: 'Problems',
        isEnabled: (model) => model.diagnostics.isNotEmpty,
        execute: (model) => model.selectNextDiagnostic(),
      ),
      EditorCommand(
        id: EditorCommandIds.previousDiagnostic,
        label: 'Go to Previous Diagnostic',
        category: 'Problems',
        isEnabled: (model) => model.diagnostics.isNotEmpty,
        execute: (model) => model.selectPreviousDiagnostic(),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorUp,
        label: 'Move Cursors Up',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsVertically(below: false),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorDown,
        label: 'Move Cursors Down',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsVertically(below: true),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorPageUp,
        label: 'Move Cursors One Page Up',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsByPage(below: false),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorPageDown,
        label: 'Move Cursors One Page Down',
        category: 'Cursor',
        execute: (model) => model.moveSelectionsByPage(below: true),
      ),
      EditorCommand(
        id: EditorCommandIds.selectLeft,
        label: 'Extend Selections Left',
        category: 'Selection',
        execute: (model) => model.extendSelectionsHorizontally(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.selectRight,
        label: 'Extend Selections Right',
        category: 'Selection',
        execute: (model) => model.extendSelectionsHorizontally(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.selectUp,
        label: 'Extend Selections Up',
        category: 'Selection',
        execute: (model) => model.extendSelectionsVertically(below: false),
      ),
      EditorCommand(
        id: EditorCommandIds.selectDown,
        label: 'Extend Selections Down',
        category: 'Selection',
        execute: (model) => model.extendSelectionsVertically(below: true),
      ),
      EditorCommand(
        id: EditorCommandIds.selectPageUp,
        label: 'Extend Selections One Page Up',
        category: 'Selection',
        execute: (model) => model.extendSelectionsByPage(below: false),
      ),
      EditorCommand(
        id: EditorCommandIds.selectPageDown,
        label: 'Extend Selections One Page Down',
        category: 'Selection',
        execute: (model) => model.extendSelectionsByPage(below: true),
      ),
      EditorCommand(
        id: EditorCommandIds.selectWordLeft,
        label: 'Extend Selections One Word Left',
        category: 'Selection',
        execute: (model) => model.extendSelectionsByWord(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.selectWordRight,
        label: 'Extend Selections One Word Right',
        category: 'Selection',
        execute: (model) => model.extendSelectionsByWord(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.selectLineStart,
        label: 'Extend Selections to Line Start',
        category: 'Selection',
        execute: (model) =>
            model.extendSelectionsToLineBoundary(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.selectLineEnd,
        label: 'Extend Selections to Line End',
        category: 'Selection',
        execute: (model) => model.extendSelectionsToLineBoundary(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.selectVisualLineStart,
        label: 'Extend Selections to Visual Line Start',
        category: 'Selection',
        execute: (model) =>
            model.extendSelectionsToVisualLineBoundary(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.selectVisualLineEnd,
        label: 'Extend Selections to Visual Line End',
        category: 'Selection',
        execute: (model) =>
            model.extendSelectionsToVisualLineBoundary(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.indentLines,
        label: 'Indent Lines',
        category: 'Edit',
        execute: (model) => model.indentLines(),
      ),
      EditorCommand(
        id: EditorCommandIds.outdentLines,
        label: 'Outdent Lines',
        category: 'Edit',
        execute: (model) => model.outdentLines(),
      ),
      EditorCommand(
        id: EditorCommandIds.deleteLine,
        label: 'Delete Lines',
        category: 'Edit',
        execute: (model) => model.deleteLinesAtSelections(),
      ),
      EditorCommand(
        id: EditorCommandIds.duplicateLine,
        label: 'Duplicate Lines',
        category: 'Edit',
        execute: (model) => model.duplicateLinesAtSelections(),
      ),
      EditorCommand(
        id: EditorCommandIds.moveLineUp,
        label: 'Move Lines Up',
        category: 'Edit',
        execute: (model) => model.moveLinesAtSelections(down: false),
      ),
      EditorCommand(
        id: EditorCommandIds.moveLineDown,
        label: 'Move Lines Down',
        category: 'Edit',
        execute: (model) => model.moveLinesAtSelections(down: true),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorDocumentStart,
        label: 'Move Cursor to Document Start',
        category: 'Cursor',
        execute: (model) => model.moveToDocumentStart(),
      ),
      EditorCommand(
        id: EditorCommandIds.cursorDocumentEnd,
        label: 'Move Cursor to Document End',
        category: 'Cursor',
        execute: (model) => model.moveToDocumentEnd(),
      ),
      EditorCommand(
        id: EditorCommandIds.selectDocumentStart,
        label: 'Extend Selections to Document Start',
        category: 'Selection',
        execute: (model) =>
            model.extendSelectionsToDocumentBoundary(forward: false),
      ),
      EditorCommand(
        id: EditorCommandIds.selectDocumentEnd,
        label: 'Extend Selections to Document End',
        category: 'Selection',
        execute: (model) =>
            model.extendSelectionsToDocumentBoundary(forward: true),
      ),
      EditorCommand(
        id: EditorCommandIds.toggleFold,
        label: 'Toggle Fold',
        category: 'View',
        execute: (model) => model.toggleFoldAtCursor(),
      ),
      EditorCommand(
        id: EditorCommandIds.foldAll,
        label: 'Fold All',
        category: 'View',
        execute: (model) => model.collapseAllFolds(),
      ),
      EditorCommand(
        id: EditorCommandIds.unfoldAll,
        label: 'Unfold All',
        category: 'View',
        execute: (model) => model.expandAllFolds(),
      ),
    ]);
  }

  /// Sets the width of the textarea.
  void setWidth(int w) {
    _width = w;
    _syncCoreState();
  }

  /// Sets the height of the textarea.
  void setHeight(int h) {
    _height = h;
    _syncCoreState();
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
      _insertTextShared(s);
    });
  }

  /// Starts an asynchronous completion request for the current document.
  Cmd requestCompletions(EditorCompletionProvider provider, {String? trigger}) {
    _completionError = null;
    final request = EditorCompletionRequest(
      documentText: value,
      cursorOffset: cursorOffset,
      documentVersion: _documentVersion,
      trigger: trigger,
    );
    return Cmd.perform(
      () => _completionSession.request(provider, request),
      onSuccess: TextAreaCompletionMsg.new,
      onError: (error, _) => TextAreaCompletionErrorMsg(error),
    );
  }

  /// Moves the active completion by [delta], wrapping at either end.
  bool moveCompletionSelection(int delta) {
    if (_completionItems.isEmpty || delta == 0) return false;
    _completionIndex = (_completionIndex + delta) % _completionItems.length;
    if (_completionIndex < 0) _completionIndex += _completionItems.length;
    return true;
  }

  /// Accepts the active completion as one normal undo transaction.
  bool acceptCompletion() {
    final item = activeCompletion;
    if (item == null) return false;
    final start = (item.replacementStart ?? cursorOffset).clamp(0, length);
    final end = (item.replacementEnd ?? cursorOffset).clamp(start, length);
    setSelections(
      TextSelectionSet([
        TextSelectionRange(startOffset: start, endOffset: end),
      ], primaryOffset: end),
    );
    insertString(item.insertText);
    _lastCompletionAdditionalEdits = item.additionalEdits.isEmpty
        ? null
        : item.additionalEdits;
    cancelCompletions();
    return true;
  }

  /// Hides candidates and invalidates any in-flight provider response.
  void cancelCompletions() {
    _completionSession.cancel();
    _completionItems = const [];
    _completionIndex = -1;
    _completionError = null;
  }

  void _invalidateCompletionsForDocumentChange() {
    _completionSession.cancel();
    _completionItems = const [];
    _completionIndex = -1;
    _completionError = null;
    cancelCodeActions();
  }

  /// Requests quick fixes/refactors for the current selection or cursor.
  Cmd requestCodeActions(EditorCodeActionProvider provider) {
    _codeActionError = null;
    final range = selections.primary!;
    final request = EditorCodeActionRequest(
      documentText: value,
      documentVersion: _documentVersion,
      startOffset: range.startOffset,
      endOffset: range.endOffset,
      diagnostics: _diagnostics
          .where(
            (diagnostic) =>
                diagnostic.endOffset >= range.startOffset &&
                diagnostic.startOffset <= range.endOffset,
          )
          .toList(growable: false),
    );
    return Cmd.perform(
      () => _codeActionSession.request(provider, request),
      onSuccess: TextAreaCodeActionsMsg.new,
      onError: (error, _) => TextAreaCodeActionsErrorMsg(error),
    );
  }

  bool moveCodeActionSelection(int delta) {
    if (_codeActions.isEmpty || delta == 0) return false;
    _codeActionIndex = (_codeActionIndex + delta) % _codeActions.length;
    if (_codeActionIndex < 0) _codeActionIndex += _codeActions.length;
    return true;
  }

  /// Accepts an action for the host to dispatch/apply exactly once.
  bool acceptCodeAction() {
    final action = activeCodeAction;
    if (action == null) return false;
    _acceptedCodeAction = action;
    cancelCodeActions();
    return true;
  }

  void cancelCodeActions() {
    _codeActionSession.cancel();
    _codeActions = const [];
    _codeActionIndex = -1;
    _codeActionError = null;
  }

  void _insertTextShared(String text) {
    if (text.isEmpty) return;
    _recordUndoSnapshot();
    _refreshDocumentSnapshot();
    final activeSelections = _selections;
    if (activeSelections != null && activeSelections.ranges.length > 1) {
      var insertion = uni.graphemes(text).toList(growable: false);
      if (charLimit > 0) {
        final replaced = activeSelections.ranges.fold<int>(
          0,
          (total, range) => total + range.length,
        );
        final available = charLimit - (length - replaced);
        final perSelection = available ~/ activeSelections.ranges.length;
        if (perSelection <= 0) return;
        if (insertion.length > perSelection) {
          insertion = insertion.sublist(0, perSelection);
        }
      }
      final result = insertTextAtEachSelection(
        _document.flattenWithNewlines(),
        activeSelections,
        insertion,
      );
      _replaceText(result.graphemes.join());
      _selections = result.selections;
      final primary = result.selections.primary!;
      _applyLineStateSnapshot(
        lineSnapshotFromOffsets(_document, cursorOffset: primary.activeOffset),
      );
      _lastDocumentChange = null;
      return;
    }
    final result = textInsertText(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      text: text,
    );
    if (!result.changed) return;
    _applyOffsetCommandResult(result);
    _enforceCharLimit();
  }

  String _applyCharLimit(String text) {
    if (charLimit <= 0) return text;
    final gs = uni.graphemes(text).toList(growable: false);
    if (gs.length <= charLimit) return text;
    return gs.take(charLimit).join();
  }

  Cmd _schedulePasteChunk() {
    return Cmd.tick(Duration.zero, (_) => const _TextAreaPasteChunkMsg());
  }

  void _finishPendingPaste() {
    _pasteController.clearPendingChunkedPaste();
  }

  void _applyPasteChunkStep(TextPasteChunkStep step) {
    _insertTextShared(String.fromCharCodes(step.runes));
    if (!step.hasMore) {
      _finishPendingPaste();
    }
  }

  void _applyNextPasteChunk() {
    final step = _pasteController.takeNextChunk(
      chunkSize: _pasteChunkSizeRunes,
    );
    if (step == null) {
      _finishPendingPaste();
      return;
    }

    _applyPasteChunkStep(step);
  }

  Cmd? _pasteContent(String content) {
    if (content.isEmpty) return null;

    final pastePlan = planTextPaste(
      content,
      collapseLargePaste: false,
      collapsedPasteMinChars: 0,
      collapsedPasteMinLines: 0,
      chunkThresholdRunes: _pasteChunkThresholdRunes,
    );
    if (!pastePlan.chunked) {
      _insertTextShared(content);
      return null;
    }

    final step = _pasteController.startChunked(
      content,
      chunkSize: _pasteChunkSizeRunes,
    );
    if (step == null) {
      _finishPendingPaste();
      return null;
    }

    _applyPasteChunkStep(step);
    return _pasteController.hasPendingChunkedPaste
        ? _schedulePasteChunk()
        : null;
  }

  void cursorStart() {
    _moveLineCursor(TextPosition(line: _row, column: 0));
    _syncCoreState();
  }

  void cursorEnd() {
    _moveLineCursor(
      TextPosition(line: _row, column: _document.lineLength(_row)),
    );
    _syncCoreState();
  }

  @override
  (TextAreaModel, Cmd?) update(Msg msg) {
    return _runEditFrame(() {
      switch (msg) {
        case TextAreaPasteMsg(:final content):
          _beginHistoryAction(_TextAreaHistoryAction.paste, breakChain: true);
          return (this, _pasteContent(content));
        case PasteMsg(:final content):
          _beginHistoryAction(_TextAreaHistoryAction.paste, breakChain: true);
          return (this, _pasteContent(content));
        case PasteTextMsg(:final content):
          _beginHistoryAction(_TextAreaHistoryAction.paste, breakChain: true);
          return (this, _pasteContent(content));
        case _TextAreaPasteChunkMsg():
          _beginHistoryAction(_TextAreaHistoryAction.paste);
          _applyNextPasteChunk();
          if (_pasteController.hasPendingChunkedPaste) {
            return (this, _schedulePasteChunk());
          }
          return (this, null);
        case TextAreaCompletionMsg(:final result):
          if (result == null) return (this, null);
          final maxItems = workAssessment.maxCompletionItems;
          final items = result.items.length > maxItems
              ? result.items.take(maxItems).toList(growable: false)
              : result.items;
          _completionItems = List<EditorCompletionItem>.unmodifiable(items);
          _completionIndex = _completionItems.isEmpty ? -1 : 0;
          _completionError = null;
          return (this, null);
        case TextAreaCompletionErrorMsg(:final error):
          _completionItems = const [];
          _completionIndex = -1;
          _completionError = error;
          return (this, null);
        case TextAreaCodeActionsMsg(:final actions):
          if (actions == null) return (this, null);
          _codeActions = List<EditorCodeAction>.unmodifiable(actions);
          _codeActionIndex = _codeActions.isEmpty ? -1 : 0;
          _codeActionError = null;
          return (this, null);
        case TextAreaCodeActionsErrorMsg(:final error):
          _codeActions = const [];
          _codeActionIndex = -1;
          _codeActionError = error;
          return (this, null);
        case KeyMsg(key: final key):
          if (completionVisible) {
            switch (key.type) {
              case KeyType.up:
                moveCompletionSelection(-1);
                return (this, null);
              case KeyType.down:
                moveCompletionSelection(1);
                return (this, null);
              case KeyType.tab || KeyType.enter:
                acceptCompletion();
                return (this, null);
              case KeyType.escape:
                cancelCompletions();
                return (this, null);
              default:
                break;
            }
          }
          if (key.matchesSingle(keyMap.undo)) {
            executeCommand(EditorCommandIds.undo);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.redo)) {
            executeCommand(EditorCommandIds.redo);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.selectAll)) {
            executeCommand(EditorCommandIds.selectAll);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.selectLine)) {
            executeCommand(EditorCommandIds.selectLine);
            return (this, null);
          }

          // deletion
          if (key.matchesSingle(keyMap.deleteBeforeCursor)) {
            executeCommand(EditorCommandIds.deleteLeft);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteCharacterForward)) {
            executeCommand(EditorCommandIds.deleteRight);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteWordBackward)) {
            executeCommand(EditorCommandIds.deleteWordLeft);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteWordForward)) {
            executeCommand(EditorCommandIds.deleteWordRight);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteToLineStart)) {
            executeCommand(EditorCommandIds.deleteLineLeft);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteToLineEnd)) {
            executeCommand(EditorCommandIds.deleteLineRight);
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteAfterCursor)) {
            executeCommand(EditorCommandIds.deleteLineRight);
            return (this, null);
          }

          // navigation
          if (_matchesMovementBinding(key, keyMap.wordForward)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectWordRight
                  : EditorCommandIds.cursorWordRight,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.wordBackward)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectWordLeft
                  : EditorCommandIds.cursorWordLeft,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.lineStart)) {
            final visual = key.type == KeyType.home;
            late final String commandId;
            if (key.shift) {
              commandId = visual
                  ? EditorCommandIds.selectVisualLineStart
                  : EditorCommandIds.selectLineStart;
            } else {
              commandId = visual
                  ? EditorCommandIds.cursorVisualLineStart
                  : EditorCommandIds.cursorLineStart;
            }
            executeCommand(commandId);
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.lineEnd)) {
            final visual = key.type == KeyType.end;
            late final String commandId;
            if (key.shift) {
              commandId = visual
                  ? EditorCommandIds.selectVisualLineEnd
                  : EditorCommandIds.selectLineEnd;
            } else {
              commandId = visual
                  ? EditorCommandIds.cursorVisualLineEnd
                  : EditorCommandIds.cursorLineEnd;
            }
            executeCommand(commandId);
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.inputBegin)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectDocumentStart
                  : EditorCommandIds.cursorDocumentStart,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.inputEnd)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectDocumentEnd
                  : EditorCommandIds.cursorDocumentEnd,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.characterForward)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectRight
                  : EditorCommandIds.cursorRight,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.characterBackward)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectLeft
                  : EditorCommandIds.cursorLeft,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.lineNext)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectDown
                  : EditorCommandIds.cursorDown,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.linePrevious)) {
            executeCommand(
              key.shift ? EditorCommandIds.selectUp : EditorCommandIds.cursorUp,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.pageUp)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectPageUp
                  : EditorCommandIds.cursorPageUp,
            );
            return (this, null);
          }
          if (_matchesMovementBinding(key, keyMap.pageDown)) {
            executeCommand(
              key.shift
                  ? EditorCommandIds.selectPageDown
                  : EditorCommandIds.cursorPageDown,
            );
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
              return (this, Cmd.setClipboardBestEffort(text));
            }
          }

          // Fallback direct modifier checks for common combos.
          if (key.type == KeyType.delete && key.alt) {
            executeCommand(EditorCommandIds.deleteWordRight);
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

          if (key.type == KeyType.tab) {
            if (key.shift) {
              executeCommand(EditorCommandIds.outdentLines);
            } else {
              executeCommand(EditorCommandIds.indentLines);
            }
            return (this, null);
          }

          if (key.type == KeyType.space) {
            executeCommand(EditorCommandIds.insertText, argument: ' ');
            return (this, null);
          }

          if (key.type == KeyType.enter && keyMap.insertNewline.enabled) {
            executeCommand(EditorCommandIds.insertLineBreak);
            return (this, null);
          }

          if (key.type == KeyType.runes && key.runes.isNotEmpty) {
            final rune = key.runes.first;
            if (rune == 0x0a) {
              executeCommand(EditorCommandIds.insertLineBreak);
            } else {
              executeCommand(
                EditorCommandIds.insertText,
                argument: String.fromCharCode(rune),
              );
            }
            return (this, null);
          }
      }

      if (msg is MouseMsg) {
        final lineNumberDigits = _lineNumberDigits;
        final displayLines = _softWrappedLines(lineNumberDigits);
        final action = msg.action;
        final button = msg.button;
        final x = msg.x;
        final y = msg.y;

        if (y < 0 || y >= displayLines.length) {
          if (action == MouseAction.press && button == MouseButton.left) {
            _mouseSelecting = false;
            _clearLineSelection();
            _focused = false;
            _syncCoreState();
          }
          if (action == MouseAction.release && button == MouseButton.left) {
            _mouseSelecting = false;
            if (!_hasSelection()) {
              _clearLineSelection();
              _syncCoreState();
            }
          }
          return (this, null);
        }

        if (action == MouseAction.press && button == MouseButton.left) {
          _focused = true;
          final promptW = _getPromptWidth(y);
          final lineNumberW = showLineNumbers ? (lineNumberDigits + 1) : 0;
          final displayLine = displayLines[y];
          final inLineNumberGutter =
              showLineNumbers &&
              x >= promptW &&
              x < promptW + lineNumberW &&
              displayLine.charOffset == 0;
          if (inLineNumberGutter &&
              selectDiagnosticAtLine(displayLine.rowIndex)) {
            _mouseSelecting = false;
            return (this, null);
          }
          final hit = _textView.hitTestContent(
            _document,
            _editorState,
            localX: x - promptW - lineNumberW,
            visualRow: y,
          );
          if (hit == null) {
            _mouseSelecting = false;
            return (this, null);
          }
          final contentX = hit.column;
          final contentY = hit.line;
          final now = _nowProvider();

          final clickCount =
              _lastClickTime != null &&
                  now.difference(_lastClickTime!) <
                      const Duration(milliseconds: 500) &&
                  _lastClickPos == (contentX, contentY)
              ? (_lastClickCount + 1).clamp(1, 3)
              : 1;
          _lastClickTime = now;
          _lastClickPos = (contentX, contentY);
          _lastClickCount = clickCount;

          if (clickCount == 2) {
            _mouseSelecting = false;
            final (start, end) = _findWordAt(contentX, contentY);
            _selectLineState(
              base: TextPosition(line: contentY, column: start),
              extent: TextPosition(line: contentY, column: end),
            );
            _syncCoreState();
            return (this, null);
          }
          if (clickCount >= 3) {
            _mouseSelecting = false;
            _selectLineState(
              base: TextPosition(line: contentY, column: 0),
              extent: TextPosition(
                line: contentY,
                column: _document.lineLength(contentY),
              ),
            );
            _syncCoreState();
            return (this, null);
          }

          // Start selection
          _mouseSelecting = true;
          _selectLineState(
            base: TextPosition(line: contentY, column: contentX),
            extent: TextPosition(line: contentY, column: contentX),
            preserveCollapsedSelection: true,
          );
          _syncCoreState();
          return (this, null);
        }

        if (action == MouseAction.motion &&
            _mouseSelecting &&
            _selectionStart != null) {
          final promptW = _getPromptWidth(y);
          final lineNumberW = showLineNumbers ? (lineNumberDigits + 1) : 0;
          final hit = _textView.hitTestContent(
            _document,
            _editorState,
            localX: x - promptW - lineNumberW,
            visualRow: y,
          );
          if (hit == null) {
            return (this, null);
          }
          final contentX = hit.column;
          final contentY = hit.line;
          _selectLineState(
            base: TextPosition(
              line: _selectionStart!.$2,
              column: _selectionStart!.$1,
            ),
            extent: TextPosition(line: contentY, column: contentX),
          );
          _syncCoreState();
          return (this, null);
        }

        if (action == MouseAction.release && button == MouseButton.left) {
          _mouseSelecting = false;
          if (!_hasSelection()) {
            _clearLineSelection();
            _syncCoreState();
          }
          return (this, null);
        }
      }

      return (this, null);
    });
  }

  /// Returns the currently selected text.
  String getSelectedText() {
    final multiple = _selections;
    if (multiple != null) {
      return getSelectedTexts().join('\n');
    }
    if (_selectionStart == null || _selectionEnd == null) return '';

    final (x1, y1) = _selectionStart!;
    final (x2, y2) = _selectionEnd!;

    final startY = math.min(y1, y2);
    final endY = math.max(y1, y2);

    if (startY < 0 || endY >= lineCount) return '';

    final sb = StringBuffer();
    for (var y = startY; y <= endY; y++) {
      final line = _document.lineGraphemesAt(y);
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

  /// Selected text for each non-collapsed range in document order.
  List<String> getSelectedTexts() {
    return List<String>.unmodifiable([
      for (final range in selections.ranges)
        if (!range.isCollapsed)
          _document.textInRange(
            startOffset: range.startOffset,
            endOffset: range.endOffset,
          ),
    ]);
  }

  /// Deletes all active selections as one undoable edit.
  bool deleteSelections() {
    final active = selections;
    if (active.ranges.every((range) => range.isCollapsed)) return false;
    return _runEditFrame(() {
      _beginHistoryAction(
        _TextAreaHistoryAction.deleteForward,
        breakChain: true,
      );
      _recordUndoSnapshot();
      if (active.ranges.length == 1) {
        return _deleteSelectionIfAny();
      }
      final result = insertTextAtEachSelection(
        _document.flattenWithNewlines(),
        active,
        const <String>[],
      );
      _replaceText(result.graphemes.join());
      _selections = result.selections;
      final primary = result.selections.primary!;
      _applyLineStateSnapshot(
        lineSnapshotFromOffsets(_document, cursorOffset: primary.activeOffset),
      );
      _lastDocumentChange = null;
      return true;
    });
  }

  /// Moves every active cursor left or right by one grapheme.
  bool moveSelectionsHorizontally({required bool forward}) {
    return _applyMappedEnds(
      forward: forward,
      mapEnd: (offset, _) => (offset + (forward ? 1 : -1)).clamp(0, length),
    );
  }

  /// Moves every active cursor to the next or previous word boundary.
  bool moveSelectionsByWord({required bool forward}) {
    _refreshDocumentSnapshot();
    return _applyMappedEnds(
      forward: forward,
      mapEnd: (offset, _) => textMoveByWord(
        document: _document,
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: offset),
        forward: forward,
      ).cursorOffset,
    );
  }

  /// Moves every active cursor to the start or end of its logical line.
  bool moveSelectionsToLineBoundary({required bool forward}) {
    _refreshDocumentSnapshot();
    return _applyMappedEnds(
      forward: forward,
      mapEnd: (offset, _) => _lineBoundaryOffset(offset, forward: forward),
    );
  }

  /// Moves every active cursor to its projected visual-row boundary.
  ///
  /// Without soft wrapping, the visual and logical line boundaries are equal.
  bool moveSelectionsToVisualLineBoundary({required bool forward}) {
    _refreshEditorStateSnapshot();
    _configureTextView();
    return _applyMappedEnds(
      forward: forward,
      mapEnd: (offset, _) =>
          _offsetForVisualLineBoundary(offset, forward: forward),
    );
  }

  /// Moves every active cursor up or down by one visible line.
  bool moveSelectionsVertically({required bool below}) {
    return _applyVerticalMappedEnds(below: below);
  }

  /// Moves every active cursor by one viewport page.
  bool moveSelectionsByPage({required bool below}) {
    return _applyVerticalMappedEnds(below: below, rows: _pageRowCount);
  }

  /// Extends every selection's end by one grapheme.
  bool extendSelectionsHorizontally({required bool forward}) {
    return _applyMappedEnds(
      forward: forward,
      extend: true,
      mapEnd: (offset, _) => (offset + (forward ? 1 : -1)).clamp(0, length),
    );
  }

  /// Extends every selection's end by one word.
  bool extendSelectionsByWord({required bool forward}) {
    _refreshDocumentSnapshot();
    return _applyMappedEnds(
      forward: forward,
      extend: true,
      mapEnd: (offset, _) => textMoveByWord(
        document: _document,
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: offset),
        forward: forward,
      ).cursorOffset,
    );
  }

  /// Extends every selection's end to its line boundary.
  bool extendSelectionsToLineBoundary({required bool forward}) {
    _refreshDocumentSnapshot();
    return _applyMappedEnds(
      forward: forward,
      extend: true,
      mapEnd: (offset, _) => _lineBoundaryOffset(offset, forward: forward),
    );
  }

  /// Extends every selection's active edge to a document boundary.
  bool extendSelectionsToDocumentBoundary({required bool forward}) {
    return _applyMappedEnds(
      forward: forward,
      extend: true,
      mapEnd: (_, _) => forward ? length : 0,
    );
  }

  /// Extends every selection's active edge to its visual-row boundary.
  bool extendSelectionsToVisualLineBoundary({required bool forward}) {
    _refreshEditorStateSnapshot();
    _configureTextView();
    return _applyMappedEnds(
      forward: forward,
      extend: true,
      mapEnd: (offset, _) =>
          _offsetForVisualLineBoundary(offset, forward: forward),
    );
  }

  /// Extends every selection's end up or down by one visible line.
  bool extendSelectionsVertically({required bool below}) {
    _refreshDocumentSnapshot();
    return _applyVerticalMappedEnds(below: below, extend: true);
  }

  /// Extends every selection's active edge by one viewport page.
  bool extendSelectionsByPage({required bool below}) {
    return _applyVerticalMappedEnds(
      below: below,
      extend: true,
      rows: _pageRowCount,
    );
  }

  bool _applyMappedEnds({
    required bool forward,
    bool extend = false,
    required int Function(int endOffset, TextSelectionRange range) mapEnd,
  }) {
    _invalidateVerticalMotion();
    final current = selections;
    if (_selections == null) {
      final currentOffset = cursorOffset;
      final nextOffset = mapEnd(currentOffset, current.primary!);
      if (nextOffset == currentOffset) return false;
      final nextPosition = _document.positionForOffset(nextOffset);
      if (extend) {
        _selectLineState(
          base: _currentSelectionBasePosition() ?? _currentCursorPosition(),
          extent: nextPosition,
          cursor: nextPosition,
        );
      } else {
        _moveLineCursor(nextPosition);
      }
      _lastDocumentChange = null;
      _syncCoreState();
      return true;
    }
    final next = mapSelectionEnds(
      current,
      mapEnd: mapEnd,
      forward: forward,
      extend: extend,
    );
    if (identical(next, current)) return false;
    setSelections(next);
    return true;
  }

  bool _applyVerticalMappedEnds({
    required bool below,
    bool extend = false,
    int rows = 1,
  }) {
    if (rows <= 0) return false;
    _refreshEditorStateSnapshot();
    _configureTextView();
    final current = selections;
    final previousGoals =
        _verticalMotionGeneration == _selectionGeneration &&
            _verticalMotionSoftWrap == softWrap
        ? _verticalGoalColumns
        : const <TextSelectionRange, int>{};
    if (_selections == null) {
      final currentRange = current.primary!;
      final currentOffset = cursorOffset;
      final preferredColumn =
          previousGoals[currentRange] ??
          _verticalColumnForOffset(currentOffset);
      final nextOffset = _offsetForVerticalMove(
        currentOffset,
        below: below,
        preferredColumn: preferredColumn,
        rows: rows,
      );
      if (nextOffset == currentOffset) return false;
      final nextPosition = _document.positionForOffset(nextOffset);
      if (extend) {
        _selectLineState(
          base: _currentSelectionBasePosition() ?? _currentCursorPosition(),
          extent: nextPosition,
          cursor: nextPosition,
        );
      } else {
        _moveLineCursor(nextPosition);
      }
      _lastDocumentChange = null;
      _syncCoreState();
      _verticalGoalColumns = <TextSelectionRange, int>{
        selections.primary!: preferredColumn,
      };
      _verticalMotionGeneration = _selectionGeneration;
      _verticalMotionSoftWrap = softWrap;
      return true;
    }

    final goalsByActiveOffset = <int, int>{};
    final next = mapSelectionEnds(
      current,
      forward: below,
      extend: extend,
      mapEnd: (offset, range) {
        final preferredColumn =
            previousGoals[range] ?? _verticalColumnForOffset(offset);
        final nextOffset = _offsetForVerticalMove(
          offset,
          below: below,
          preferredColumn: preferredColumn,
          rows: rows,
        );
        goalsByActiveOffset[nextOffset] = preferredColumn;
        return nextOffset;
      },
    );
    if (identical(next, current)) return false;
    setSelections(next);
    _verticalGoalColumns = Map<TextSelectionRange, int>.unmodifiable({
      for (final range in selections.ranges)
        range:
            goalsByActiveOffset[range.activeOffset] ??
            _verticalColumnForOffset(range.activeOffset),
    });
    _verticalMotionGeneration = _selectionGeneration;
    _verticalMotionSoftWrap = softWrap;
    return true;
  }

  int _verticalColumnForOffset(int offset) {
    final position = _document.positionForOffset(offset);
    if (!softWrap) return position.column;
    return _textView
            .resolveCursorVisualPosition(
              _document,
              _editorState,
              cursor: position,
            )
            ?.displayColumn ??
        position.column;
  }

  int _offsetForVerticalMove(
    int offset, {
    required bool below,
    required int preferredColumn,
    int rows = 1,
  }) {
    var result = offset;
    for (var row = 0; row < rows; row++) {
      final position = _document.positionForOffset(result);
      final next = softWrap
          ? _textView.cursorOffsetForVisualLineMove(
              _document,
              _editorState,
              lineDelta: below ? 1 : -1,
              desiredDisplayColumn: preferredColumn,
              cursor: position,
            )
          : textOffsetOnAdjacentVisibleLine(
              document: _document,
              offset: result,
              below: below,
              preferredColumn: preferredColumn,
              isLineHidden: folds.isLineHidden,
            );
      if (next == result) break;
      result = next;
    }
    return result;
  }

  int get _pageRowCount => _height > 0 ? _height : 1;

  int _offsetForVisualLineBoundary(int offset, {required bool forward}) {
    if (!softWrap) return _lineBoundaryOffset(offset, forward: forward);
    return _textView.cursorOffsetForVisualLineBoundary(
      _document,
      _editorState,
      end: forward,
      cursor: _document.positionForOffset(offset),
    );
  }

  void _invalidateVerticalMotion() {
    _verticalMotionGeneration = -1;
    _verticalMotionSoftWrap = false;
    _verticalGoalColumns = const {};
  }

  bool _matchesMovementBinding(Key key, KeyBinding binding) {
    return key.matchesSingle(binding) ||
        (key.shift && key.copyWith(shift: false).matchesSingle(binding));
  }

  /// Recomputes indent folds and keeps collapse state that still applies.
  void refreshIndentFolds({int tabWidth = 4}) {
    folds = folds.retain(
      computeIndentFolds([
        for (var i = 0; i < lineCount; i++) _document.lineAt(i),
      ], tabWidth: tabWidth),
    );
    if (!_moveHiddenCursorsToFoldHeaders()) _syncCoreState();
  }

  /// Toggles the fold at the primary cursor, moving onto the header if hidden.
  bool toggleFoldAtCursor() {
    _refreshEditorStateSnapshot();
    final line = _editorState.cursor.line;
    var range = folds.foldStartingAt(line);
    if (range == null) {
      for (final candidate in folds.ranges) {
        if (line >= candidate.startLine && line <= candidate.endLine) {
          range = candidate;
          break;
        }
      }
    }
    if (range == null) return false;
    folds.toggle(range.startLine);
    if (!_moveHiddenCursorsToFoldHeaders()) _syncCoreState();
    return true;
  }

  /// Collapses every fold range.
  bool collapseAllFolds() {
    if (folds.ranges.isEmpty) return false;
    final collapsedBefore = folds.collapsedStarts.length;
    folds.collapseAll();
    if (folds.collapsedStarts.length == collapsedBefore) return false;
    if (!_moveHiddenCursorsToFoldHeaders()) _syncCoreState();
    return true;
  }

  /// Expands every fold range.
  bool expandAllFolds() {
    if (folds.collapsedStarts.isEmpty) return false;
    folds.expandAll();
    _syncCoreState();
    return true;
  }

  bool _moveHiddenCursorsToFoldHeaders() {
    if (_selections == null) {
      final visibleLine = folds.visibleLineFor(_row);
      if (visibleLine == _row) return false;
      _collapseLineState(TextPosition(line: visibleLine, column: 0));
      _lastDocumentChange = null;
      _syncCoreState();
      return true;
    }

    final current = _selections!;
    final next = mapSelectionRanges(
      current,
      transform: (range) {
        final position = _document.positionForOffset(range.activeOffset);
        final visibleLine = folds.visibleLineFor(position.line);
        if (visibleLine == position.line) return range;
        final offset = _document.lineStartOffset(visibleLine);
        return TextSelectionRange(startOffset: offset, endOffset: offset);
      },
    );
    if (identical(next, current)) return false;
    setSelections(next);
    return true;
  }

  /// Moves the primary cursor to the start of the document.
  bool moveToDocumentStart() {
    if (cursorOffset == 0 && !hasSelection && !hasMultipleSelections) {
      return false;
    }
    setSelections(TextSelectionSet.collapsed(0));
    return true;
  }

  /// Moves the primary cursor to the end of the document.
  bool moveToDocumentEnd() {
    if (cursorOffset == length && !hasSelection && !hasMultipleSelections) {
      return false;
    }
    setSelections(TextSelectionSet.collapsed(length));
    return true;
  }

  Set<int> _selectedLineIndexes() {
    final lines = <int>{};
    for (final range in selections.ranges) {
      final start = _document.positionForOffset(range.startOffset).line;
      final endOffset = range.isCollapsed
          ? range.endOffset
          : math.max(range.startOffset, range.endOffset - 1);
      final end = _document.positionForOffset(endOffset).line;
      final from = math.min(start, end);
      final to = math.max(start, end);
      for (var line = from; line <= to; line++) {
        lines.add(line);
      }
    }
    return lines;
  }

  /// Indents every line touched by an active cursor or selection.
  bool indentAtSelections({int width = 2}) {
    final pad = List<String>.filled(width < 1 ? 1 : width, ' ');
    return _editSelectedLineStarts((lineText) => [...pad, ...lineText]);
  }

  /// Outdents every line touched by an active cursor or selection.
  bool outdentAtSelections({int width = 2}) {
    final indentWidth = width < 1 ? 1 : width;
    return _editSelectedLineStarts((lineText) {
      final removal = _leadingIndentRemovalCount(lineText, indentWidth);
      return removal == 0 ? lineText : lineText.sublist(removal);
    });
  }

  bool _editSelectedLineStarts(
    List<String> Function(List<String> lineGraphemes) transform,
  ) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      _refreshDocumentSnapshot();
      final lines = _selectedLineIndexes().toList()
        ..sort((a, b) => b.compareTo(a));
      if (lines.isEmpty) return false;
      final graphemes = _document.flattenWithNewlines();
      var next = selections;
      var changed = false;
      for (final line in lines) {
        final start = _document.lineStartOffset(line);
        final end = _document.lineEndOffset(line);
        final current = graphemes.sublist(start, end);
        final updated = transform(current);
        if (_sameGraphemes(current, updated)) continue;
        if (!changed) _recordUndoSnapshot();
        graphemes.replaceRange(start, end, updated);
        final delta = updated.length - current.length;
        next = delta > 0
            ? next.applyInsertion(offset: start, length: delta)
            : next.applyDeletion(startOffset: start, endOffset: start - delta);
        changed = true;
      }
      if (!changed) return false;
      _replaceText(graphemes.join());
      setSelections(next);
      return true;
    });
  }

  bool _sameGraphemes(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  int _leadingIndentRemovalCount(List<String> graphemes, int width) {
    var count = 0;
    var removed = 0;
    for (final grapheme in graphemes) {
      if (count >= width) break;
      if (grapheme == ' ') {
        count++;
        removed++;
      } else if (grapheme == '\t') {
        count = width;
        removed++;
      } else {
        break;
      }
    }
    return removed;
  }

  /// Deletes every line touched by an active cursor or selection.
  bool deleteLinesAtSelections() {
    return _runEditFrame(() {
      _beginHistoryAction(
        _TextAreaHistoryAction.deleteForward,
        breakChain: true,
      );
      _refreshDocumentSnapshot();
      final lines = _selectedLineIndexes().toList()
        ..sort((a, b) => b.compareTo(a));
      if (lines.isEmpty) return false;
      final graphemes = _document.flattenWithNewlines();
      var next = selections;
      var changed = false;
      for (final line in lines) {
        final start = _document.lineStartOffset(line);
        final end = _document.lineEndOffset(line, includeTrailingNewline: true);
        if (start == end) continue;
        if (!changed) _recordUndoSnapshot();
        graphemes.replaceRange(start, end, const <String>[]);
        next = next.applyDeletion(startOffset: start, endOffset: end);
        changed = true;
      }
      if (!changed) return false;
      _replaceText(graphemes.isEmpty ? '' : graphemes.join());
      setSelections(next);
      return true;
    });
  }

  /// Duplicates every touched line below the original.
  bool duplicateLinesAtSelections() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      _refreshDocumentSnapshot();
      final lines = _selectedLineIndexes().toList()
        ..sort((a, b) => b.compareTo(a));
      if (lines.isEmpty) return false;
      _recordUndoSnapshot();
      final graphemes = _document.flattenWithNewlines();
      var next = selections;
      var changed = false;
      for (final line in lines) {
        final start = _document.lineStartOffset(line);
        final end = _document.lineEndOffset(line);
        final content = graphemes.sublist(start, end);
        final insertion = ['\n', ...content];
        graphemes.replaceRange(end, end, insertion);
        next = next.applyInsertion(offset: end, length: insertion.length);
        changed = true;
      }
      if (!changed) return false;
      _replaceText(graphemes.join());
      setSelections(next);
      return true;
    });
  }

  /// Moves every touched line up or down by one row, keeping contiguous runs
  /// together.
  bool moveLinesAtSelections({required bool down}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      _refreshDocumentSnapshot();
      final indexes = _selectedLineIndexes().toList()..sort();
      if (indexes.isEmpty) return false;
      final runs = _contiguousLineRuns(indexes);
      final lines = [for (var i = 0; i < lineCount; i++) _document.lineAt(i)];
      var changed = false;
      final ordered = down ? runs.reversed : runs;
      for (final run in ordered) {
        if (down) {
          if (run.end >= lines.length - 1) continue;
          final block = lines.sublist(run.start, run.end + 1);
          lines.removeRange(run.start, run.end + 1);
          lines.insertAll(run.start + 1, block);
          changed = true;
        } else {
          if (run.start <= 0) continue;
          final block = lines.sublist(run.start, run.end + 1);
          lines.removeRange(run.start, run.end + 1);
          lines.insertAll(run.start - 1, block);
          changed = true;
        }
      }
      if (!changed) return false;
      final delta = down ? 1 : -1;
      final mapped = [
        for (final range in selections.ranges)
          (
            start: _document.positionForOffset(range.startOffset),
            end: _document.positionForOffset(range.endOffset),
            isReversed: range.isReversed,
          ),
      ];
      final primaryIndex = selections.ranges.indexOf(selections.primary!);
      _recordUndoSnapshot();
      // A trailing newline is represented by the final empty document line,
      // so joining all logical lines already preserves it.
      _replaceText(lines.join('\n'));
      TextSelectionRange relocate(
        ({TextPosition start, TextPosition end, bool isReversed}) positions,
      ) {
        final startLine = (positions.start.line + delta).clamp(
          0,
          lineCount - 1,
        );
        final endLine = (positions.end.line + delta).clamp(0, lineCount - 1);
        return TextSelectionRange(
          startOffset: _document.offsetForPosition(
            TextPosition(
              line: startLine,
              column: positions.start.column.clamp(
                0,
                _document.lineLength(startLine),
              ),
            ),
          ),
          endOffset: _document.offsetForPosition(
            TextPosition(
              line: endLine,
              column: positions.end.column.clamp(
                0,
                _document.lineLength(endLine),
              ),
            ),
          ),
          isReversed: positions.start != positions.end && positions.isReversed,
        );
      }

      final relocated = [for (final positions in mapped) relocate(positions)];
      setSelections(
        TextSelectionSet(
          relocated,
          primaryOffset: relocated.isEmpty
              ? 0
              : relocated[primaryIndex].activeOffset,
        ),
      );
      return true;
    });
  }

  List<({int start, int end})> _contiguousLineRuns(List<int> sortedLines) {
    if (sortedLines.isEmpty) return const [];
    final runs = <({int start, int end})>[];
    var start = sortedLines.first;
    var end = start;
    for (var i = 1; i < sortedLines.length; i++) {
      if (sortedLines[i] == end + 1) {
        end = sortedLines[i];
      } else {
        runs.add((start: start, end: end));
        start = sortedLines[i];
        end = start;
      }
    }
    runs.add((start: start, end: end));
    return runs;
  }

  /// Deletes one grapheme beside every cursor, or each selected range.
  bool deleteAtSelections({required bool forward}) {
    final active = selections;
    if (active.ranges.isEmpty) return false;
    var changed = false;
    final deletionRanges = <TextSelectionRange>[];
    for (final range in active.ranges) {
      if (!range.isCollapsed) {
        deletionRanges.add(range);
        changed = true;
        continue;
      }
      final start = forward
          ? range.startOffset
          : (range.startOffset - 1).clamp(0, length);
      final end = forward
          ? (range.endOffset + 1).clamp(0, length)
          : range.endOffset;
      deletionRanges.add(
        TextSelectionRange(startOffset: start, endOffset: end),
      );
      if (start != end) changed = true;
    }
    if (!changed) return false;
    setSelections(
      TextSelectionSet(
        deletionRanges,
        primaryOffset: active.primary!.activeOffset,
      ),
    );
    return deleteSelections();
  }

  /// Deletes to a word boundary beside every cursor as one undoable edit.
  bool deleteWordAtSelections({required bool forward}) {
    final active = selections;
    if (active.ranges.isEmpty) return false;
    _refreshDocumentSnapshot();
    final deletionRanges = <TextSelectionRange>[];
    var changed = false;
    for (final range in active.ranges) {
      if (!range.isCollapsed) {
        deletionRanges.add(range);
        changed = true;
        continue;
      }
      final boundary = textMoveByWord(
        document: _document,
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: range.endOffset),
        forward: forward,
      ).cursorOffset;
      deletionRanges.add(
        TextSelectionRange(
          startOffset: math.min(boundary, range.endOffset),
          endOffset: math.max(boundary, range.endOffset),
        ),
      );
      changed |= boundary != range.endOffset;
    }
    if (!changed) return false;
    setSelections(
      TextSelectionSet(
        deletionRanges,
        primaryOffset: active.primary!.activeOffset,
      ),
    );
    return deleteSelections();
  }

  /// Deletes from every cursor to its logical line boundary atomically.
  bool deleteToLineBoundaryAtSelections({required bool forward}) {
    final active = selections;
    if (active.ranges.isEmpty) return false;
    _refreshDocumentSnapshot();
    final deletionRanges = <TextSelectionRange>[];
    var changed = false;
    for (final range in active.ranges) {
      if (!range.isCollapsed) {
        deletionRanges.add(range);
        changed = true;
        continue;
      }
      final boundary = _lineBoundaryOffset(range.endOffset, forward: forward);
      deletionRanges.add(
        TextSelectionRange(
          startOffset: math.min(boundary, range.endOffset),
          endOffset: math.max(boundary, range.endOffset),
        ),
      );
      changed |= boundary != range.endOffset;
    }
    if (!changed) return false;
    setSelections(
      TextSelectionSet(
        deletionRanges,
        primaryOffset: active.primary!.activeOffset,
      ),
    );
    return deleteSelections();
  }

  int _lineBoundaryOffset(int offset, {required bool forward}) {
    final position = _document.positionForOffset(offset);
    return _document.offsetForPosition(
      TextPosition(
        line: position.line,
        column: forward ? _document.lineLength(position.line) : 0,
      ),
    );
  }

  /// Returns selected text and removes every selection atomically.
  String cutSelectedText() {
    final text = getSelectedText();
    if (text.isEmpty) return '';
    deleteSelections();
    return text;
  }

  @override
  Object view() {
    final style = activeStyle();
    final activeSelections = _selections;
    final primarySelection = activeSelections?.primary;
    final secondaryCursorOffsets = <int>{
      if (activeSelections != null)
        for (final range in activeSelections.ranges)
          if (range.isCollapsed && range != primarySelection) range.endOffset,
    };
    final additionalSelectedRanges = activeSelections == null
        ? const <TextSelectionRange>[]
        : activeSelections.ranges
              .where((range) => !range.isCollapsed && range != primarySelection)
              .toList(growable: false);
    final lineNumberDigits = _lineNumberDigits;
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
        final lineDecorations = _lineDecorationsForRow(displayLine.rowIndex);
        final lineDecorationStyle = _lineDecorationStyleForDecorations(
          style,
          lineDecorations,
        );
        final lineNumberDecorationStyle =
            _lineNumberDecorationStyleForDecorations(style, lineDecorations);
        final lineNumberMarker = _normalizedLineNumberMarker(
          displayLine.charOffset == 0
              ? _lineNumberMarkerForDecorations(lineDecorations)
              : null,
        );
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
              ? '${(displayLine.rowIndex + 1).toString().padLeft(lineNumberDigits)}$lineNumberMarker'
              : ' ' * (lineNumberDigits + 1);
          lnNumber = (lineNumberDecorationStyle ?? style.computedLineNumber)
              .render(lnText);
        }
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
              rowEnd = _document.lineLength(rowIdx);
            } else if (rowIdx == endY) {
              rowStart = 0;
              rowEnd = y1 < y2 ? x2 : x1;
            } else {
              rowStart = 0;
              rowEnd = _document.lineLength(rowIdx);
            }

            rowStart = rowStart.clamp(0, _document.lineLength(rowIdx));
            rowEnd = rowEnd.clamp(0, _document.lineLength(rowIdx));

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
        final decorationRanges = _segmentDecorationRanges(
          displayLine.rowIndex,
          displayLine.charOffset,
          displayLine.charOffset + gs.length,
        );
        final cursorCol = displayLine.hasCursor
            ? (_col - displayLine.charOffset)
            : -1;
        final segmentStart =
            _document.lineStartOffset(displayLine.rowIndex) +
            displayLine.charOffset;

        var renderedBody = '';
        for (var j = 0; j < gs.length; j++) {
          final documentOffset = segmentStart + j;
          final isSelected =
              (selStart != null &&
                  selEnd != null &&
                  j >= selStart &&
                  j < selEnd) ||
              _selectionRangesContainOffset(
                additionalSelectedRanges,
                documentOffset,
              );
          final isCursor =
              (displayLine.hasCursor && j == cursorCol) ||
              secondaryCursorOffsets.contains(documentOffset);
          final decorationStyleKey = _decorationStyleKeyForColumn(
            decorationRanges,
            j,
          );
          final decorationStyle = decorationStyleKey == null
              ? null
              : style.computedDecorationStyle(decorationStyleKey);
          final partStyle = _textCellStyle(
            style,
            lineDecorationStyle: lineDecorationStyle,
            decorationStyle: decorationStyle,
            isSelected: isSelected,
            useCursorStyle: useVirtualCursor && isCursor,
          );
          final part = partStyle.render(gs[j]);
          renderedBody += part;
        }

        final hasCursorAtEnd =
            (displayLine.hasCursor && cursorCol >= gs.length) ||
            secondaryCursorOffsets.contains(segmentStart + gs.length);
        if (useVirtualCursor && hasCursorAtEnd) {
          final partStyle = _textCellStyle(
            style,
            lineDecorationStyle: lineDecorationStyle,
            isSelected: false,
            useCursorStyle: true,
          );
          renderedBody += partStyle.render(' ');
        }

        buffer.writeln(
          '${style.computedPrompt.render(p)}$lnNumber$renderedBody',
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

    final content = _renderCompletionPopup(buffer.toString().trimRight());
    if (useVirtualCursor || !_focused) {
      return content;
    }

    return View(content: content, cursor: terminalCursor);
  }

  String _renderCompletionPopup(String content) {
    if (_completionItems.isEmpty || _height <= 0) return content;
    const maxVisible = 5;
    final visibleCount = math.min(maxVisible, _completionItems.length);
    final maxStart = math.max(0, _completionItems.length - visibleCount);
    final start = (_completionIndex - visibleCount ~/ 2).clamp(0, maxStart);
    final popup = <String>[];
    for (var i = start; i < start + visibleCount; i++) {
      final item = _completionItems[i];
      final marker = i == _completionIndex ? '› ' : '  ';
      final detail = item.detail.isEmpty ? '' : '  ${item.detail}';
      final plain = '$marker${item.label}$detail';
      final graphemes = uni.graphemes(plain).toList(growable: false);
      final clipped = _width <= 0 || graphemes.length <= _width
          ? plain
          : graphemes.take(math.max(0, _width)).join();
      popup.add(clipped);
    }
    final lines = content.isEmpty ? <String>[] : content.split('\n');
    while (lines.length < _height) {
      lines.add('');
    }
    final popupStart = math.max(0, _height - popup.length);
    for (var i = 0; i < popup.length; i++) {
      if (popupStart + i < lines.length) {
        lines[popupStart + i] = popup[i];
      } else {
        lines.add(popup[i]);
      }
    }
    return lines.join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  List<_DisplayLine> _softWrappedLines(int lineNumberDigits) {
    _textView
      ..leadingColumns =
          _getPromptWidth(_row) + (showLineNumbers ? lineNumberDigits + 1 : 0)
      ..folds = folds;
    final lines = _textView.buildViewportLines(_document, _editorState);
    return lines
        .map(
          (line) => _DisplayLine(
            line.text,
            hasCursor: line.hasCursor,
            rowIndex: line.logicalLine,
            charOffset: line.charOffset,
          ),
        )
        .toList(growable: false);
  }

  bool _deleteSelectionIfAny() {
    _refreshDocumentSnapshot();
    final result = textDeleteSelection(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    if (!result.changed) {
      _clearLineSelection();
      return false;
    }

    _recordUndoSnapshot();
    _applyOffsetCommandResult(result);
    return true;
  }

  void _transposeBackward() {
    _refreshDocumentSnapshot();
    _recordUndoSnapshot();
    final result = textTransposeBackward(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    if (!result.changed) return;
    _applyOffsetCommandResult(result);
  }

  void _uppercaseWordForward() {
    _transformWordForward((text) => text.toUpperCase());
  }

  void _lowercaseWordForward() {
    _transformWordForward((text) => text.toLowerCase());
  }

  void _capitalizeWordForward() {
    _transformWordForward(textCapitalizeWords);
  }

  void _transformWordForward(String Function(String text) transform) {
    _refreshDocumentSnapshot();
    final result = textTransformWordOrAdjacent(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      transform: transform,
    );
    if (!result.changed) {
      return;
    }

    _recordUndoSnapshot();
    _applyOffsetCommandResult(result);
  }

  bool _transformSelectionOrLineShared(String Function(String text) transform) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      _refreshDocumentSnapshot();
      final result = textTransformSelectionOrLine(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        transform: transform,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  int _globalOffset() {
    _refreshDocumentSnapshot();
    return _document.offsetForPosition(TextPosition(line: _row, column: _col));
  }

  void _setCursorFromGlobal(int offset) {
    _refreshDocumentSnapshot();
    final position = _document.positionForOffset(offset);
    _moveLineCursor(position);
  }

  (int, int) _selectedLineRange() {
    _refreshEditorStateSnapshot();
    final range = _editorState.selectedLineRange();
    return (range.startLine, range.endLine);
  }

  int _totalGraphemeLength() {
    return _document.length;
  }

  bool _selectionRangesContainOffset(
    List<TextSelectionRange> ranges,
    int offset,
  ) {
    var low = 0;
    var high = ranges.length - 1;
    while (low <= high) {
      final middle = low + ((high - low) >> 1);
      final range = ranges[middle];
      if (offset < range.startOffset) {
        high = middle - 1;
      } else if (offset >= range.endOffset) {
        low = middle + 1;
      } else {
        return true;
      }
    }
    return false;
  }

  void _replaceDocumentSnapshot(TextDocument document) {
    if (_document.text != document.text) {
      _documentVersion++;
      _invalidateCompletionsForDocumentChange();
    }
    _document = document;
  }

  void _replaceText(String text) {
    if (_document.text != text) {
      _documentVersion++;
      _invalidateCompletionsForDocumentChange();
    }
    _document.replaceText(text);
  }

  void _enforceCharLimit() {
    if (charLimit <= 0) return;
    final cursorPos = _globalOffset();
    final limited = _applyCharLimit(value);
    if (limited == value) return;
    _replaceText(limited);
    _setCursorFromGlobal(cursorPos.clamp(0, _totalGraphemeLength()));
  }

  (int, int) _findWordAt(int x, int y) {
    final boundary = _document.wordBoundaryAt(TextPosition(line: y, column: x));
    return (boundary.start.column, boundary.end.column);
  }
}
