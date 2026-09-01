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
    this.charLimit = 0,
    this.softWrap = true,
    int width = 0,
    int height = 6,
    this.useVirtualCursor = true,
    TextAreaKeyMap? keyMap,
    CursorModel? cursor,
    TextAreaStyles? styles,
    DateTime Function()? nowProvider,
  }) : keyMap = keyMap ?? TextAreaKeyMap(),
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
  final TextPasteController _pasteController = TextPasteController();
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
  List<TextDecorationRange> _decorations = const [];
  List<TextLineDecoration> _lineDecorations = const [];
  TextDocumentChange? _lastDocumentChange;
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
  int get length => _totalGraphemeLength();
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  bool get hasSelection => _hasSelection();
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
    _clearLineSelection();
    _lastDocumentChange = null;
    _syncCoreState();
  }

  /// Selects the entire textarea contents.
  void selectAll() {
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

  bool setDecorations(Iterable<TextDecorationRange> decorations) {
    return setDecorationLayer(
      textDefaultDecorationLayerKey,
      decorations,
      priority: textDefaultDecorationLayerPriority,
    );
  }

  bool setDecorationLayer(
    String layerKey,
    Iterable<TextDecorationRange> decorations, {
    int priority = textDefaultDecorationLayerPriority,
  }) {
    _refreshDocumentSnapshot();
    final normalized = decorations
        .map((range) => range.normalized().clamp(_document.length))
        .where((range) => !range.isEmpty)
        .toList(growable: false);

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

    _textView
      ..width = _width
      ..height = _height
      ..softWrap = softWrap
      ..leadingColumns = _leadingColumnsForView();
    _textView.ensureCursorVisible(_document, _editorState);
    _syncImplicitLineDecorations();
  }

  void _refreshDocumentSnapshot() {}

  int _leadingColumnsForView() {
    final lineNumberDigits = showLineNumbers ? '$lineCount'.length : 0;
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
  bool indentLines({int width = 2}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textIndentLinesDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        width: width,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

  /// Outdents the selected lines, or the current line if there is no selection.
  bool outdentLines({int width = 2}) {
    return _runEditFrame(() {
      _beginHistoryAction(_TextAreaHistoryAction.transform, breakChain: true);
      final result = textOutdentLinesDocument(
        document: _document,
        state: _currentLineStateSnapshot(),
        width: width,
      );
      if (!result.changed) {
        return false;
      }

      _recordUndoSnapshot();
      _applyOffsetCommandResult(result);
      return true;
    });
  }

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

  void _insertChar(String ch) {
    if (ch.isEmpty) return;
    _insertTextShared(ch);
  }

  void _newline() {
    _insertTextShared('\n');
  }

  void _insertTextShared(String text) {
    if (text.isEmpty) return;
    _recordUndoSnapshot();
    _refreshDocumentSnapshot();
    final result = textInsertText(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      text: text,
    );
    if (!result.changed) return;
    _applyOffsetCommandResult(result);
    _enforceCharLimit();
  }

  void _backspace() {
    if (_row == 0 && _col == 0) return;
    _recordUndoSnapshot();
    _refreshDocumentSnapshot();
    final result = textDeletePrevious(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _applyOffsetCommandResult(result);
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
            if (_deleteSelectionIfAny()) {
              return (this, null);
            }
            _backspace();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteCharacterForward)) {
            _beginHistoryAction(_TextAreaHistoryAction.deleteForward);
            if (_deleteSelectionIfAny()) {
              return (this, null);
            }
            _deleteCharForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteWordBackward)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteBackward,
              breakChain: true,
            );
            if (_deleteSelectionIfAny()) {
              return (this, null);
            }
            _deleteWordBackward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteWordForward)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteForward,
              breakChain: true,
            );
            if (_deleteSelectionIfAny()) {
              return (this, null);
            }
            _deleteWordForward();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteToLineStart)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteBackward,
              breakChain: true,
            );
            if (_deleteSelectionIfAny()) {
              return (this, null);
            }
            _deleteToLineStart();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteToLineEnd)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteForward,
              breakChain: true,
            );
            if (_deleteSelectionIfAny()) {
              return (this, null);
            }
            _deleteToLineEnd();
            return (this, null);
          }
          if (key.matchesSingle(keyMap.deleteAfterCursor)) {
            _beginHistoryAction(
              _TextAreaHistoryAction.deleteForward,
              breakChain: true,
            );
            if (_deleteSelectionIfAny()) {
              return (this, null);
            }
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
        final lineNumberDigits = showLineNumbers ? '$lineCount'.length : 0;
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

  @override
  Object view() {
    final style = activeStyle();
    final lineNumberDigits = showLineNumbers ? '$lineCount'.length : 0;
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

        var renderedBody = '';
        for (var j = 0; j < gs.length; j++) {
          final isSelected =
              selStart != null && selEnd != null && j >= selStart && j < selEnd;
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
            useCursorStyle:
                displayLine.hasCursor && useVirtualCursor && j == cursorCol,
          );
          final part = partStyle.render(gs[j]);
          renderedBody += part;
        }

        if (displayLine.hasCursor &&
            useVirtualCursor &&
            cursorCol >= gs.length) {
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

    final content = buffer.toString().trimRight();
    if (useVirtualCursor || !_focused) {
      return content;
    }

    return View(content: content, cursor: terminalCursor);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  List<_DisplayLine> _softWrappedLines(int lineNumberDigits) {
    _textView.leadingColumns =
        _getPromptWidth(_row) + (showLineNumbers ? lineNumberDigits + 1 : 0);
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

  void _deleteWordBackward() {
    if (_globalOffset() == 0) return;
    _recordUndoSnapshot();
    _refreshDocumentSnapshot();
    final result = textDeleteWordBackward(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _applyOffsetCommandResult(result);
  }

  void _deleteToLineStart() {
    if (_col == 0) return;
    _recordUndoSnapshot();
    _refreshDocumentSnapshot();
    final result = textDeleteToLineStart(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _applyOffsetCommandResult(result);
  }

  void _deleteToLineEnd() {
    if (_col >= _document.lineLength(_row)) return;
    _recordUndoSnapshot();
    _refreshDocumentSnapshot();
    final result = textDeleteToLineEnd(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _applyOffsetCommandResult(result);
  }

  void _moveWordForward() {
    _refreshDocumentSnapshot();
    final result = textMoveByWord(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      forward: true,
      clearSelection: false,
    );
    if (!result.changed) return;
    _applyOffsetCursorCommandResult(result);
  }

  void _moveWordBackward() {
    _refreshDocumentSnapshot();
    final result = textMoveByWord(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      forward: false,
      clearSelection: false,
    );
    if (!result.changed) return;
    _applyOffsetCursorCommandResult(result);
  }

  void _cursorStartOfLine() {
    cursorStart();
  }

  void _cursorEndOfLine() {
    cursorEnd();
  }

  void _cursorStartOfInput() {
    _refreshDocumentSnapshot();
    _applyOffsetCursorCommandResult(
      textMoveToDocumentBoundary(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        forward: false,
        clearSelection: false,
      ),
    );
  }

  void _cursorEndOfInput() {
    _refreshDocumentSnapshot();
    _applyOffsetCursorCommandResult(
      textMoveToDocumentBoundary(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        forward: true,
        clearSelection: false,
      ),
    );
  }

  void _deleteCharForward() {
    _refreshDocumentSnapshot();
    if (_globalOffset() >= _document.length) return;
    _recordUndoSnapshot();
    final result = textDeleteNext(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _applyOffsetCommandResult(result);
  }

  void _deleteWordForward() {
    _refreshDocumentSnapshot();
    if (_globalOffset() >= _document.length) return;
    _recordUndoSnapshot();
    final result = textDeleteWordForward(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _applyOffsetCommandResult(result);
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

  void _moveLeft() {
    _refreshDocumentSnapshot();
    final result = textMoveByCharacter(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      forward: false,
      clearSelection: false,
    );
    if (!result.changed) return;
    _applyOffsetCursorCommandResult(result);
  }

  void _moveRight() {
    _refreshDocumentSnapshot();
    final result = textMoveByCharacter(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      forward: true,
      clearSelection: false,
    );
    if (!result.changed) return;
    _applyOffsetCursorCommandResult(result);
  }

  void _lineNext() {
    if (_row < lineCount - 1) {
      _moveLineCursor(TextPosition(line: _row + 1, column: _col));
    }
  }

  void _linePrev() {
    if (_row > 0) {
      _moveLineCursor(TextPosition(line: _row - 1, column: _col));
    }
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

  void _replaceDocumentSnapshot(TextDocument document) {
    _document = document;
  }

  void _replaceText(String text) {
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
