/// Text input component for TUI applications.
///
/// This provides a single-line text input field with cursor navigation,
/// word editing, suggestions/autocomplete, and password echo modes.
///
/// Based on the Bubble Tea textinput component.
library;

import 'dart:math' as math;

import 'package:artisanal/src/tui/tui.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';

import '../../uv/cursor.dart';
import '../../uv/geometry.dart';
import '../msg.dart' show PasteTextMsg;
import '../editor_core/editor_core.dart';
import '../editor_core/editor_core.dart' as commands;
import 'cursor.dart';
import 'key_binding.dart';
import 'runeutil.dart';
import '../../unicode/grapheme.dart' as uni;
import 'text_layout.dart' as layout;

/// Echo mode for text input display.
enum EchoMode {
  /// Display text as-is. This is the default.
  normal,

  /// Display mask character instead of actual characters (for passwords).
  password,

  /// Display nothing as characters are entered.
  none,
}

/// Validation function that returns an error message if input is invalid.
typedef ValidateFunc = String? Function(String value);

/// Style state for focused and blurred states.
///
/// Contains [Style] configurations for each visual element of a [TextInputModel].
/// Separate style states allow different appearances when the input is focused
/// vs. blurred.
class TextInputStyleState {
  /// Creates a style state with optional styles for each element.
  ///
  /// All styles default to an empty [Style] if not provided.
  TextInputStyleState({
    Style? text,
    Style? placeholder,
    Style? suggestion,
    Style? prompt,
    Style? selection,
  }) : text = text ?? Style(),
       placeholder = placeholder ?? Style(),
       suggestion = suggestion ?? Style(),
       prompt = prompt ?? Style(),
       selection =
           selection ??
           Style().background(AnsiColor(7)).foreground(AnsiColor(0));

  /// Style for the entered text.
  Style text;

  /// Style for placeholder text shown when input is empty.
  Style placeholder;

  /// Style for autocomplete suggestion text.
  Style suggestion;

  /// Style for the prompt prefix.
  Style prompt;

  /// Style for selected text.
  Style selection;
}

/// Style for the cursor.
///
/// Controls the visual appearance of the cursor in a [TextInputModel],
/// including color, shape, and blinking behavior.
class TextInputCursorStyle {
  /// Creates a cursor style with the specified options.
  ///
  /// Defaults to a blinking block cursor.
  TextInputCursorStyle({
    this.color,
    this.shape = CursorShape.block,
    this.blink = true,
    this.blinkSpeed = const Duration(milliseconds: 500),
  });

  /// Color of the cursor. If null, uses the terminal default.
  Color? color;

  /// Shape of the cursor (block, underline, or bar).
  CursorShape shape;

  /// Whether the cursor blinks.
  bool blink;

  /// Duration between blink state changes.
  Duration blinkSpeed;
}

/// Styles for the text input.
///
/// Groups all style configuration for a [TextInputModel]:
/// - [focused]: Styles applied when the input is focused
/// - [blurred]: Styles applied when the input is not focused
/// - [cursor]: Cursor appearance settings
class TextInputStyles {
  /// Creates a text input styles configuration.
  ///
  /// All style groups default to their respective defaults if not provided.
  TextInputStyles({
    TextInputStyleState? focused,
    TextInputStyleState? blurred,
    TextInputCursorStyle? cursor,
  }) : focused = focused ?? TextInputStyleState(),
       blurred = blurred ?? TextInputStyleState(),
       cursor = cursor ?? TextInputCursorStyle();

  /// Styles used when the input is focused.
  TextInputStyleState focused;

  /// Styles used when the input is blurred (not focused).
  TextInputStyleState blurred;

  /// Cursor appearance settings.
  TextInputCursorStyle cursor;
}

/// Returns the default styles for the text input.
///
/// Creates sensible defaults for both dark and light terminal backgrounds.
///
/// - [isDark]: Set to `true` (default) for dark terminals, `false` for light.
///
/// Returns a [TextInputStyles] with appropriate colors for the background type.
TextInputStyles defaultTextInputStyles({bool isDark = true}) {
  return TextInputStyles(
    focused: TextInputStyleState(
      placeholder: Style().foreground(AnsiColor(240)),
      suggestion: Style().foreground(AnsiColor(240)),
      prompt: Style().foreground(AnsiColor(7)),
      text: Style(),
    ),
    blurred: TextInputStyleState(
      placeholder: Style().foreground(AnsiColor(240)),
      suggestion: Style().foreground(AnsiColor(240)),
      prompt: Style().foreground(AnsiColor(7)),
      text: Style().foreground(isDark ? AnsiColor(7) : AnsiColor(245)),
    ),
    cursor: TextInputCursorStyle(
      color: AnsiColor(7),
      shape: CursorShape.block,
      blink: true,
    ),
  );
}

/// Key map for text input navigation and editing.
///
/// Defines all keyboard shortcuts for cursor movement, text deletion,
/// clipboard operations, and suggestion navigation. Each binding can be
/// customized by providing a custom [KeyBinding].
///
/// Default bindings follow common terminal/editor conventions:
/// - Arrow keys for navigation
/// - Ctrl+A/E for line start/end (Emacs-style)
/// - Alt+Arrow for word navigation
/// - Ctrl+W for delete word backward
/// - Ctrl+K/U for delete after/before cursor
///
/// See also:
/// - [KeyBinding] for defining custom key bindings
/// - [KeyMap] for the interface this implements
class TextInputKeyMap implements KeyMap {
  /// Creates a text input key map with default bindings.
  TextInputKeyMap({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
    KeyBinding? deleteWordBackward,
    KeyBinding? deleteWordForward,
    KeyBinding? deleteAfterCursor,
    KeyBinding? deleteBeforeCursor,
    KeyBinding? deleteCharacterBackward,
    KeyBinding? deleteCharacterForward,
    KeyBinding? lineStart,
    KeyBinding? lineEnd,
    KeyBinding? selectCharacterForward,
    KeyBinding? selectCharacterBackward,
    KeyBinding? selectWordForward,
    KeyBinding? selectWordBackward,
    KeyBinding? selectLineStart,
    KeyBinding? selectLineEnd,
    KeyBinding? selectAll,
    KeyBinding? paste,
    KeyBinding? copy,
    KeyBinding? cut,
    KeyBinding? undo,
    KeyBinding? redo,
    KeyBinding? acceptSuggestion,
    KeyBinding? nextSuggestion,
    KeyBinding? prevSuggestion,
    KeyBinding? newline,
    KeyBinding? lineUp,
    KeyBinding? lineDown,
    KeyBinding? selectLineUp,
    KeyBinding? selectLineDown,
    KeyBinding? documentStart,
    KeyBinding? documentEnd,
  }) : characterForward =
           characterForward ??
           KeyBinding(
             keys: ['right', 'ctrl+f'],
             help: Help(key: '→/^f', desc: 'Move forward'),
           ),
       characterBackward =
           characterBackward ??
           KeyBinding(
             keys: ['left', 'ctrl+b'],
             help: Help(key: '←/^b', desc: 'Move backward'),
           ),
       wordForward =
           wordForward ??
           KeyBinding(
             keys: ['alt+right', 'ctrl+right', 'alt+f'],
             help: Help(key: 'alt+→', desc: 'Move word forward'),
           ),
       wordBackward =
           wordBackward ??
           KeyBinding(
             keys: ['alt+left', 'ctrl+left', 'alt+b'],
             help: Help(key: 'alt+←', desc: 'Move word backward'),
           ),
       deleteWordBackward =
           deleteWordBackward ??
           KeyBinding(
             keys: ['alt+backspace', 'ctrl+w'],
             help: Help(key: 'alt+⌫', desc: 'Delete word backward'),
           ),
       deleteWordForward =
           deleteWordForward ??
           KeyBinding(
             keys: ['alt+delete', 'alt+d'],
             help: Help(key: 'alt+del', desc: 'Delete word forward'),
           ),
       deleteAfterCursor =
           deleteAfterCursor ??
           KeyBinding(
             keys: ['ctrl+k'],
             help: Help(key: '^k', desc: 'Delete after cursor'),
           ),
       deleteBeforeCursor =
           deleteBeforeCursor ??
           KeyBinding(
             keys: ['ctrl+u'],
             help: Help(key: '^u', desc: 'Delete before cursor'),
           ),
       deleteCharacterBackward =
           deleteCharacterBackward ??
           KeyBinding(
             keys: ['backspace', 'ctrl+h'],
             help: Help(key: '⌫', desc: 'Delete character'),
           ),
       deleteCharacterForward =
           deleteCharacterForward ??
           KeyBinding(
             keys: ['delete', 'ctrl+d'],
             help: Help(key: 'del', desc: 'Delete forward'),
           ),
       lineStart =
           lineStart ??
           KeyBinding(
             keys: ['home'],
             help: Help(key: 'home', desc: 'Go to start'),
           ),
       lineEnd =
           lineEnd ??
           KeyBinding(
             keys: ['end', 'ctrl+e'],
             help: Help(key: 'end', desc: 'Go to end'),
           ),

       selectCharacterForward =
           selectCharacterForward ??
           KeyBinding(
             keys: ['shift+right'],
             help: Help(key: 'shift+→', desc: 'Select forward'),
           ),
       selectCharacterBackward =
           selectCharacterBackward ??
           KeyBinding(
             keys: ['shift+left'],
             help: Help(key: 'shift+←', desc: 'Select backward'),
           ),
       selectWordForward =
           selectWordForward ??
           KeyBinding(
             keys: ['ctrl+shift+right', 'alt+shift+right'],
             help: Help(key: 'ctrl+shift+→', desc: 'Select word forward'),
           ),
       selectWordBackward =
           selectWordBackward ??
           KeyBinding(
             keys: ['ctrl+shift+left', 'alt+shift+left'],
             help: Help(key: 'ctrl+shift+←', desc: 'Select word backward'),
           ),
       selectLineStart =
           selectLineStart ??
           KeyBinding(
             keys: ['shift+home'],
             help: Help(key: 'shift+home', desc: 'Select to start'),
           ),
       selectLineEnd =
           selectLineEnd ??
           KeyBinding(
             keys: ['shift+end'],
             help: Help(key: 'shift+end', desc: 'Select to end'),
           ),
       selectAll =
           selectAll ??
           KeyBinding(
             keys: ['ctrl+a'],
             help: Help(key: 'ctrl+a', desc: 'Select all'),
           ),
       paste =
           paste ??
           KeyBinding(
             keys: ['ctrl+v'],
             help: Help(key: '^v', desc: 'Paste'),
           ),
       copy =
           copy ??
           KeyBinding(
             keys: ['ctrl+c', 'ctrl+shift+c'],
             help: Help(key: '^c', desc: 'Copy'),
           ),
       cut =
           cut ??
           KeyBinding(
             keys: ['ctrl+x'],
             help: Help(key: '^x', desc: 'Cut'),
           ),
       undo =
           undo ??
           KeyBinding(
             keys: ['ctrl+z'],
             help: Help(key: '^z', desc: 'Undo'),
           ),
       redo =
           redo ??
           KeyBinding(
             keys: ['ctrl+y', 'ctrl+shift+z'],
             help: Help(key: '^y', desc: 'Redo'),
           ),

       acceptSuggestion =
           acceptSuggestion ??
           KeyBinding(
             keys: ['tab'],
             help: Help(key: 'tab', desc: 'Accept suggestion'),
           ),
       nextSuggestion =
           nextSuggestion ??
           KeyBinding(
             keys: ['down', 'ctrl+n'],
             help: Help(key: '↓', desc: 'Next suggestion'),
           ),
       prevSuggestion =
           prevSuggestion ??
           KeyBinding(
             keys: ['up', 'ctrl+p'],
             help: Help(key: '↑', desc: 'Previous suggestion'),
           ),

       // Multi-line bindings
       newline =
           newline ??
           KeyBinding(
             keys: ['enter', 'shift+enter'],
             help: Help(key: '↵', desc: 'New line'),
           ),
       lineUp =
           lineUp ??
           KeyBinding(
             keys: ['up'],
             help: Help(key: '↑', desc: 'Line up'),
           ),
       lineDown =
           lineDown ??
           KeyBinding(
             keys: ['down'],
             help: Help(key: '↓', desc: 'Line down'),
           ),
       selectLineUp =
           selectLineUp ??
           KeyBinding(
             keys: ['shift+up'],
             help: Help(key: 'shift+↑', desc: 'Select line up'),
           ),
       selectLineDown =
           selectLineDown ??
           KeyBinding(
             keys: ['shift+down'],
             help: Help(key: 'shift+↓', desc: 'Select line down'),
           ),
       documentStart =
           documentStart ??
           KeyBinding(
             keys: ['ctrl+home'],
             help: Help(key: 'ctrl+home', desc: 'Go to document start'),
           ),
       documentEnd =
           documentEnd ??
           KeyBinding(
             keys: ['ctrl+end'],
             help: Help(key: 'ctrl+end', desc: 'Go to document end'),
           );

  /// Move cursor forward one character.
  final KeyBinding characterForward;

  /// Move cursor backward one character.
  final KeyBinding characterBackward;

  /// Move cursor forward one word.
  final KeyBinding wordForward;

  /// Move cursor backward one word.
  final KeyBinding wordBackward;

  /// Delete word before cursor.
  final KeyBinding deleteWordBackward;

  /// Delete word after cursor.
  final KeyBinding deleteWordForward;

  /// Delete all text after cursor.
  final KeyBinding deleteAfterCursor;

  /// Delete all text before cursor.
  final KeyBinding deleteBeforeCursor;

  /// Delete character before cursor.
  final KeyBinding deleteCharacterBackward;

  /// Delete character after cursor.
  final KeyBinding deleteCharacterForward;

  /// Move cursor to start of line.
  final KeyBinding lineStart;

  /// Move cursor to end of line.
  final KeyBinding lineEnd;

  /// Select one character forward.
  final KeyBinding selectCharacterForward;

  /// Select one character backward.
  final KeyBinding selectCharacterBackward;

  /// Select one word forward.
  final KeyBinding selectWordForward;

  /// Select one word backward.
  final KeyBinding selectWordBackward;

  /// Select to start of line.
  final KeyBinding selectLineStart;

  /// Select to end of line.
  final KeyBinding selectLineEnd;

  /// Select all text.
  final KeyBinding selectAll;

  /// Paste from clipboard.
  final KeyBinding paste;

  /// Copy to clipboard.
  final KeyBinding copy;

  /// Cut to clipboard.
  final KeyBinding cut;

  /// Undo the most recent edit.
  final KeyBinding undo;

  /// Redo the most recently undone edit.
  final KeyBinding redo;

  /// Accept current suggestion.
  final KeyBinding acceptSuggestion;

  /// Move to next suggestion.
  final KeyBinding nextSuggestion;

  /// Move to previous suggestion.
  final KeyBinding prevSuggestion;

  /// Insert a newline (multi-line mode only).
  final KeyBinding newline;

  /// Move cursor up one line (multi-line mode only).
  final KeyBinding lineUp;

  /// Move cursor down one line (multi-line mode only).
  final KeyBinding lineDown;

  /// Extend selection one line up (multi-line mode only).
  final KeyBinding selectLineUp;

  /// Extend selection one line down (multi-line mode only).
  final KeyBinding selectLineDown;

  /// Move cursor to start of document (multi-line mode only).
  final KeyBinding documentStart;

  /// Move cursor to end of document (multi-line mode only).
  final KeyBinding documentEnd;

  @override
  List<KeyBinding> shortHelp() => [
    characterForward,
    characterBackward,
    deleteCharacterBackward,
  ];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [characterForward, characterBackward, wordForward, wordBackward],
    [lineStart, lineEnd, documentStart, documentEnd],
    [
      deleteCharacterBackward,
      deleteCharacterForward,
      deleteWordBackward,
      deleteWordForward,
    ],
    [deleteBeforeCursor, deleteAfterCursor],
    [
      selectAll,
      paste,
      copy,
      cut,
      undo,
      redo,
      acceptSuggestion,
      nextSuggestion,
      prevSuggestion,
    ],
    [newline, lineUp, lineDown, selectLineUp, selectLineDown],
  ];
}

/// Message for paste events.
class PasteMsg implements Msg {
  /// Creates a paste message with the pasted content.
  PasteMsg(this.content);

  /// The pasted content.
  final String content;
}

/// Message for paste errors.
class PasteErrorMsg implements Msg {
  /// Creates a paste error message.
  PasteErrorMsg(this.error);

  /// The error that occurred.
  final Object error;
}

/// Internal message used to apply a large paste in chunks.
class _PasteChunkMsg implements Msg {
  const _PasteChunkMsg();
}

class _TextInputEditState {
  const _TextInputEditState({
    required this.value,
    required this.position,
    required this.selectionStart,
    required this.selectionEnd,
    required this.error,
  });

  final List<String> value;
  final int position;
  final int? selectionStart;
  final int? selectionEnd;
  final String? error;

  bool sameAs(_TextInputEditState other) {
    if (position != other.position ||
        selectionStart != other.selectionStart ||
        selectionEnd != other.selectionEnd ||
        error != other.error ||
        value.length != other.value.length) {
      return false;
    }
    for (var i = 0; i < value.length; i++) {
      if (value[i] != other.value[i]) return false;
    }
    return true;
  }
}

enum _TextInputHistoryAction {
  insert,
  deleteBackward,
  deleteForward,
  paste,
  replace,
  setText,
  reset,
}

/// A wrapped visual line, referencing a [start, end) range in the flat value list.
class _WrappedLine {
  const _WrappedLine(this.start, this.end);

  /// Start index (inclusive) into the flat value list.
  final int start;

  /// End index (exclusive) into the flat value list.
  final int end;

  /// Number of graphemes in this visual line.
  int get length => end - start;
}

/// Text input model for single-line or multi-line text entry.
///
/// Features:
/// - Character and word navigation
/// - Delete operations (character, word, line)
/// - Echo modes (normal, password, none)
/// - Suggestions/autocomplete
/// - Horizontal scrolling for long text (single-line mode)
/// - Soft-wrap with vertical scrolling (multi-line mode)
/// - Line navigation with up/down arrows (multi-line mode)
/// - Click-to-position cursor in multi-line mode
/// - Validation
///
/// Example:
/// ```dart
/// final input = TextInputModel(
///   prompt: 'Name: ',
///   placeholder: 'Enter your name',
/// );
///
/// // Multi-line input
/// final editor = TextInputModel(
///   multiline: true,
///   width: 60,
///   maxHeight: 10,
///   prompt: '',
/// );
/// ```
class TextInputModel extends ViewComponent {
  /// Creates a new text input model.
  TextInputModel({
    this.prompt = '> ',
    this.placeholder = '',
    this.echoMode = EchoMode.normal,
    this.echoCharacter = '*',
    this.charLimit = 0,
    this.width = 0,
    this.multiline = false,
    this.maxHeight = 0,
    this.showSuggestions = false,
    this.useVirtualCursor = true,
    this.collapseLargePaste = false,
    this.collapsedPasteMinChars = 1200,
    this.collapsedPasteMinLines = 20,
    TextInputKeyMap? keyMap,
    CursorModel? cursor,
    this.validate,
    TextInputStyles? styles,
  }) : keyMap = keyMap ?? TextInputKeyMap(),
       cursor = cursor ?? CursorModel(),
       styles = styles ?? defaultTextInputStyles() {
    _document = TextDocument();
    _editorState = EditorState();
    _textView = TextView();
    _history =
        EditHistoryController<
          _TextInputHistoryAction,
          _TextInputEditState,
          ({int cursor, int length})
        >(
          maxEntries: _maxHistoryEntries,
          sameState: (a, b) => a.sameAs(b),
          canCoalesce: _canCoalesceHistoryAction,
          markerForState: (action, state) =>
              (cursor: state.position, length: state.value.length),
        );
    _syncCoreState();
    _updateVirtualCursorStyle();
  }

  /// Prompt displayed before input.
  String prompt;

  /// Placeholder text when empty.
  String placeholder;

  /// Echo mode for displaying text.
  EchoMode echoMode;

  /// Character to show in password mode.
  String echoCharacter;

  /// Maximum characters allowed (0 = unlimited).
  int charLimit;

  /// Display width for horizontal scrolling (0 = unlimited).
  ///
  /// In multi-line mode, this controls the wrap width. Lines that exceed this
  /// width are soft-wrapped to the next visual line.
  int width;

  /// Whether to enable multi-line editing.
  ///
  /// When `true`:
  /// - Enter/Shift+Enter inserts a newline character
  /// - Text soft-wraps at [width] columns
  /// - Up/Down arrows navigate between lines instead of suggestions
  /// - Home/End move to start/end of current line (Ctrl+Home/Ctrl+End for document)
  /// - Vertical scrolling is used when content exceeds [maxHeight]
  /// - Suggestions are disabled
  ///
  /// When `false` (default), preserves existing single-line behavior.
  bool multiline;

  /// Maximum visible height in rows (0 = unlimited growth).
  ///
  /// Only used in multi-line mode. When the number of wrapped lines exceeds
  /// this value, vertical scrolling is enabled. If 0, the view grows to fit
  /// all content.
  int maxHeight;

  /// Whether to show suggestions.
  bool showSuggestions;

  /// Whether to use a virtual cursor. If false, use [terminalCursor] to return
  /// a real cursor for rendering.
  bool useVirtualCursor;

  /// Whether very large paste payloads should be collapsed into a reference
  /// token (e.g. `[Pasted ~37 lines]`) instead of inserting full text.
  bool collapseLargePaste;

  /// Minimum paste payload size in characters to trigger collapsing.
  int collapsedPasteMinChars;

  /// Minimum paste payload size in lines to trigger collapsing.
  int collapsedPasteMinLines;

  /// Key bindings.
  TextInputKeyMap keyMap;

  /// Cursor model.
  CursorModel cursor;

  /// Styles for the text input.
  TextInputStyles styles;

  /// Validation function.
  ValidateFunc? validate;

  /// Current validation error.
  String? error;

  // Internal state
  List<String> _value = <String>[];
  late TextDocument _document;
  late final EditorState _editorState;
  late final TextView _textView;
  bool _focused = false;
  int _pos = 0;
  int _offset = 0;
  int _offsetRight = 0;

  // Multi-line state
  int _scrollRow = 0; // First visible row (for vertical scrolling)
  bool _followMultilineCursor = true;
  int _desiredCol = -1; // Sticky column for up/down navigation (-1 = unset)
  List<_WrappedLine>? _wrappedLinesCache; // Cached wrapped line computation
  int _wrappedLinesCacheVersion = 0; // Invalidation counter
  int _wrappedLinesCacheWidth = -1; // Width used for last cache computation
  int _valueVersion = 0; // Bumped on every value mutation
  static const int _maxHistoryEntries = 100;
  late final EditHistoryController<
    _TextInputHistoryAction,
    _TextInputEditState,
    ({int cursor, int length})
  >
  _history;

  // Selection
  int? selectionStart;
  int? selectionEnd;
  bool _mouseSelecting = false;

  // Double click tracking
  DateTime? _lastClickTime;
  int? _lastClickPos;
  int _lastClickCount = 0;

  // Suggestions
  List<List<String>> _suggestions = <List<String>>[];
  List<List<String>> _matchedSuggestions = <List<String>>[];
  int _currentSuggestionIndex = 0;

  // Paste state.
  final TextPasteController _pasteController = TextPasteController();

  static const int _pasteChunkThresholdRunes = 1200;
  static const int _pasteChunkSizeRunes = 300;

  /// Returns the most recent paste reference URI (e.g. `paste://12`).
  String? get lastPasteRef => _pasteController.lastRef;

  /// Returns an unmodifiable view of collapsed paste payloads by URI.
  Map<String, String> get pasteBuffer => _pasteController.buffer;

  /// Gets the current value as a string.
  String get value => _value.join();
  TextDocument get document => _document;
  EditorState get editorState => _editorState;
  TextView get textView => _textView;

  /// Sets the value of the text input.
  set value(String s) {
    setText(s);
  }

  /// Sets the value of the text input (method form for API compatibility).
  ///
  /// This is equivalent to using the [value] setter and exists for parity with
  /// the upstream bubbletea Go library. Prefer using `model.value = s` in Dart.
  void setValue(String s) {
    setText(s);
  }

  /// Replaces the current text and collapses the selection at the end.
  void setText(String s, {bool recordHistory = true}) {
    _runEditFrame(() {
      _beginHistoryAction(_TextInputHistoryAction.setText, breakChain: true);
      if (recordHistory) {
        _recordUndoSnapshot();
      }
      final graphemes = textPrepareInsertedGraphemes(
        uni.codePoints(s),
        multiline: multiline,
      );
      final err = _validate(graphemes);
      _setValueInternal(graphemes, err);
      _applyOffsetStateSnapshot(
        TextOffsetStateSnapshot.collapsed(cursorOffset: _value.length),
      );
      _resetDesiredCol();
      _updateSuggestions();
    });
  }

  /// Replaces the current text and selection state.
  void setTextState({
    required String text,
    required int selectionBase,
    required int selectionExtent,
    bool recordHistory = true,
  }) {
    _runEditFrame(() {
      _beginHistoryAction(_TextInputHistoryAction.setText, breakChain: true);
      if (recordHistory) {
        _recordUndoSnapshot();
      }
      final graphemes = textPrepareInsertedGraphemes(
        uni.codePoints(text),
        multiline: multiline,
      );
      final err = _validate(graphemes);
      _setValueInternal(graphemes, err);
      final base = selectionBase.clamp(0, _value.length);
      final extent = selectionExtent.clamp(0, _value.length);
      _applyOffsetStateSnapshot(
        TextOffsetStateSnapshot.selection(
          baseOffset: base,
          extentOffset: extent,
          cursorOffset: extent,
        ),
      );
      _resetDesiredCol();
      _handleOverflow();
      _updateSuggestions();
    });
  }

  /// Gets the cursor position.
  int get position => _pos;

  /// Sets the cursor position.
  set position(int pos) {
    _pos = pos.clamp(0, _value.length);
    if (multiline) {
      _followMultilineCursor = true;
    }
    _handleOverflow();
    _syncCoreState();
  }

  /// Whether the input is focused.
  bool get focused => _focused;

  /// Whether there is an edit available to undo.
  bool get canUndo => _history.canUndo;

  /// Whether there is an undone edit available to redo.
  bool get canRedo => _history.canRedo;

  /// Sets available suggestions for autocomplete.
  set suggestions(List<String> suggestions) {
    _suggestions = suggestions.map((s) => uni.graphemes(s).toList()).toList();
    _updateSuggestions();
  }

  /// Gets available suggestions.
  List<String> get availableSuggestions =>
      _suggestions.map((s) => s.join()).toList();

  /// Gets matched suggestions.
  List<String> get matchedSuggestions =>
      _matchedSuggestions.map((s) => s.join()).toList();

  /// Gets current suggestion index.
  int get currentSuggestionIndex => _currentSuggestionIndex;

  /// Gets current suggestion.
  String get currentSuggestion {
    if (_currentSuggestionIndex >= _matchedSuggestions.length) {
      return '';
    }
    return _matchedSuggestions[_currentSuggestionIndex].join();
  }

  /// Focus the input.
  Cmd? focus() {
    _focused = true;
    final (newCursor, cmd) = cursor.focus();
    cursor = newCursor;
    _updateVirtualCursorStyle();
    return cmd;
  }

  /// Clears all undo and redo history.
  void clearHistory() {
    _history.clear();
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

  /// Selects all text in the input.
  void selectAll() {
    _applyOffsetStateSnapshot(
      TextOffsetStateSnapshot.selection(
        baseOffset: 0,
        extentOffset: _value.length,
        cursorOffset: _value.length,
      ),
    );
  }

  /// Breaks the current undo coalescing chain.
  ///
  /// Call this before a submit/save/apply action if the next edit should start
  /// a fresh undo step instead of merging with the previous contiguous burst.
  void pushHistoryBoundary() {
    _history.breakCoalescing();
  }

  /// Inserts [text] at the cursor, optionally replacing the current selection.
  void insertText(
    String text, {
    bool replaceSelection = true,
    bool coalesce = false,
  }) {
    if (text.isEmpty) return;
    _runEditFrame(() {
      final hasSelection =
          selectionStart != null &&
          selectionEnd != null &&
          selectionStart != selectionEnd;
      final action = replaceSelection && hasSelection
          ? _TextInputHistoryAction.replace
          : _TextInputHistoryAction.insert;
      _beginHistoryAction(
        action,
        breakChain: !coalesce || action == _TextInputHistoryAction.replace,
      );
      _resetDesiredCol();
      final result = textInsertText(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        text: String.fromCharCodes(uni.codePoints(text)),
        replaceSelection: replaceSelection,
      );
      if (result.changed) {
        _recordUndoSnapshot();
        _applyEditCommandResult(result);
      }
      _updateSuggestions();
      _handleOverflow();
    });
  }

  /// Replaces the current selection, or inserts at the cursor if collapsed.
  void replaceSelection(String text) {
    _runEditFrame(() {
      _beginHistoryAction(_TextInputHistoryAction.replace, breakChain: true);
      _resetDesiredCol();
      final result = textInsertText(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        text: String.fromCharCodes(uni.codePoints(text)),
      );
      if (result.changed) {
        _recordUndoSnapshot();
        _applyEditCommandResult(result);
      }
      _updateSuggestions();
      _handleOverflow();
    });
  }

  /// Deletes the current selection, returning whether anything changed.
  bool deleteSelection() {
    return _runEditFrame(() {
      _beginHistoryAction(_TextInputHistoryAction.replace, breakChain: true);
      final changed = _deleteSelection();
      if (changed) {
        _resetDesiredCol();
        _updateSuggestions();
        _handleOverflow();
      }
      return changed;
    });
  }

  /// Deletes backward from the cursor or removes the current selection.
  bool deleteBackward({bool word = false, bool coalesce = false}) {
    return _runEditFrame(() {
      final hasSelection =
          selectionStart != null &&
          selectionEnd != null &&
          selectionStart != selectionEnd;
      final action = hasSelection
          ? _TextInputHistoryAction.replace
          : _TextInputHistoryAction.deleteBackward;
      _beginHistoryAction(
        action,
        breakChain: !coalesce || action == _TextInputHistoryAction.replace,
      );
      _resetDesiredCol();
      if (_deleteSelection()) {
        _updateSuggestions();
        _handleOverflow();
        return true;
      }
      final before = _captureEditState();
      if (word) {
        _deleteWordBackward();
      } else {
        final result = textDeletePrevious(
          document: _document,
          state: _currentOffsetStateSnapshot(),
        );
        if (result.changed) {
          _recordUndoSnapshot();
          _applyEditCommandResult(result);
        }
      }
      _updateSuggestions();
      _handleOverflow();
      return !before.sameAs(_captureEditState());
    });
  }

  /// Deletes forward from the cursor or removes the current selection.
  bool deleteForward({bool word = false, bool coalesce = false}) {
    return _runEditFrame(() {
      final hasSelection =
          selectionStart != null &&
          selectionEnd != null &&
          selectionStart != selectionEnd;
      final action = hasSelection
          ? _TextInputHistoryAction.replace
          : _TextInputHistoryAction.deleteForward;
      _beginHistoryAction(
        action,
        breakChain: !coalesce || action == _TextInputHistoryAction.replace,
      );
      _resetDesiredCol();
      if (_deleteSelection()) {
        _updateSuggestions();
        _handleOverflow();
        return true;
      }
      final before = _captureEditState();
      if (word) {
        _deleteWordForward();
      } else {
        final result = textDeleteNext(
          document: _document,
          state: _currentOffsetStateSnapshot(),
        );
        if (result.changed) {
          _recordUndoSnapshot();
          _applyEditCommandResult(result);
        }
      }
      _updateSuggestions();
      _handleOverflow();
      return !before.sameAs(_captureEditState());
    });
  }

  /// Returns the currently selected text.
  String getSelectedText() {
    if (selectionStart == null || selectionEnd == null) return '';
    final start = math.min(selectionStart!, selectionEnd!);
    final end = math.max(selectionStart!, selectionEnd!);
    if (start == end) return '';
    return _value.sublist(start, end).join();
  }

  Cmd? _copySelectionCmdIfAny() {
    final selected = getSelectedText();
    if (selected.isEmpty) return null;
    return Cmd.setClipboardBestEffort(selected);
  }

  void _scrollMultilineRows(int delta) {
    if (maxHeight <= 0) return;
    _followMultilineCursor = false;
    _textView
      ..width = width
      ..height = maxHeight
      ..softWrap = true
      ..leadingColumns = 0
      ..viewportStartRow = _scrollRow;
    _textView.scrollByRows(delta, _document);
    _scrollRow = _textView.viewportStartRow;
  }

  void _scrollSingleLineBy(int delta) {
    if (delta == 0) return;
    position = (_pos + delta).clamp(0, _value.length);
  }

  /// Blur (unfocus) the input.
  void blur() {
    _focused = false;
    cursor = cursor.blur();
    _updateVirtualCursorStyle();
  }

  /// Returns the appropriate style state based on focus.
  TextInputStyleState activeStyle() =>
      _focused ? styles.focused : styles.blurred;

  Style _textCellStyle(
    TextInputStyleState styles, {
    Style? textStyle,
    required bool isSelected,
    bool useCursorStyle = false,
  }) {
    final cellStyle = (textStyle ?? styles.text).copy()..inline(true);
    if (isSelected) {
      cellStyle.inherit(styles.selection.copy()..inline(true));
    }
    if (useCursorStyle && cursor.visible && cursor.mode != CursorMode.hide) {
      cellStyle
        ..inherit(cursor.style.copy()..inline(true))
        ..inverse();
    }
    return cellStyle;
  }

  /// Returns a [Cursor] for rendering a real cursor in a TUI program.
  /// This requires that [useVirtualCursor] is set to false.
  Cursor? get terminalCursor {
    if (useVirtualCursor || !_focused) return null;

    final promptWidth = stringWidth(prompt);

    if (multiline) {
      final lines = _visibleTextViewLines();
      final cursorRow = lines.indexWhere((line) => line.hasCursor);
      if (cursorRow < 0 || cursorRow >= lines.length) return null;
      final line = lines[cursorRow];
      final cursorCol = (_pos - line.charOffset).clamp(0, line.graphemeCount);
      var xOffset = promptWidth;
      final graphemes = uni.graphemes(line.text).toList(growable: false);
      for (var i = 0; i < cursorCol && i < graphemes.length; i++) {
        xOffset += runeWidth(uni.firstCodePoint(graphemes[i]));
      }
      final yOffset = cursorRow;

      return Cursor(
        position: Position(xOffset, yOffset),
        color: styles.cursor.color,
        shape: styles.cursor.shape,
        blink: styles.cursor.blink,
      );
    }

    var xOffset = _pos - _offset + promptWidth;
    if (width > 0) {
      xOffset = math.min(xOffset, width + promptWidth);
    }

    return Cursor(
      position: Position(xOffset, 0),
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

  /// Reset the input to empty.
  void reset() {
    _runEditFrame(() {
      _beginHistoryAction(_TextInputHistoryAction.reset, breakChain: true);
      _recordUndoSnapshot();
      _replaceValueAndDocument(const <String>[]);
      error = _validate(_value);
      _applyOffsetStateSnapshot(const TextOffsetStateSnapshot(cursorOffset: 0));
      _resetDesiredCol();
      _updateSuggestions();
    });
  }

  /// Move cursor to start.
  void cursorStart() {
    _moveToDocumentBoundary(forward: false);
  }

  /// Move cursor to end.
  void cursorEnd() {
    _moveToDocumentBoundary(forward: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Multi-line: Wrapped line computation
  // ─────────────────────────────────────────────────────────────────────────

  /// Invalidates the wrapped-lines cache. Call after any mutation to _value.
  void _invalidateWrappedLines() {
    _valueVersion++;
  }

  /// Returns the current wrapped lines, computing them if needed.
  ///
  /// Each [_WrappedLine] describes a visual line: the start/end indices into
  /// the flat `_value` list. Explicit `\n` characters cause a line break.
  /// Lines wider than [width] are soft-wrapped.
  List<_WrappedLine> _getWrappedLines() {
    if (_wrappedLinesCache != null &&
        _wrappedLinesCacheVersion == _valueVersion &&
        _wrappedLinesCacheWidth == width) {
      return _wrappedLinesCache!;
    }
    _wrappedLinesCache = _computeWrappedLines();
    _wrappedLinesCacheVersion = _valueVersion;
    _wrappedLinesCacheWidth = width;
    return _wrappedLinesCache!;
  }

  List<_WrappedLine> _computeWrappedLines() {
    final lines = <_WrappedLine>[];
    final wrapWidth = width > 0 ? width : 0; // 0 = no wrapping

    var lineStart = 0;
    for (var i = 0; i <= _value.length; i++) {
      final atEnd = i == _value.length;
      final isNewline = !atEnd && _value[i] == '\n';

      if (atEnd || isNewline) {
        // We have a logical line from lineStart to i (exclusive).
        // Soft-wrap it if needed.
        _wrapSegment(lines, lineStart, i, wrapWidth);
        lineStart = i + 1; // skip the \n
      }
    }

    // If _value is empty or ends with \n, we need at least one line.
    if (lines.isEmpty) {
      lines.add(_WrappedLine(0, 0));
    }

    return lines;
  }

  /// Soft-wraps a segment of `_value[start..end]` into visual lines.
  void _wrapSegment(List<_WrappedLine> out, int start, int end, int wrapWidth) {
    if (start >= end) {
      // Empty logical line — still produces one visual line.
      out.add(_WrappedLine(start, start));
      return;
    }

    if (wrapWidth <= 0) {
      // No wrapping — the entire segment is one visual line.
      out.add(_WrappedLine(start, end));
      return;
    }

    var segStart = start;
    while (segStart < end) {
      var w = 0;
      var segEnd = segStart;
      while (segEnd < end) {
        final rw = runeWidth(uni.firstCodePoint(_value[segEnd]));
        if (w + rw > wrapWidth) break;
        w += rw;
        segEnd++;
      }
      // Avoid infinite loop if a single grapheme is wider than wrapWidth.
      if (segEnd == segStart) segEnd = segStart + 1;
      out.add(_WrappedLine(segStart, segEnd));
      segStart = segEnd;
    }
  }

  /// Returns the total number of wrapped lines.
  int get lineCount => multiline ? _getWrappedLines().length : 1;

  // ─────────────────────────────────────────────────────────────────────────
  // Multi-line: Navigation helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Inserts a newline character at the cursor position.
  void _insertNewline() {
    _recordUndoSnapshot();
    final result = textInsertText(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      text: '\n',
    );
    if (!result.changed) return;
    _applyEditCommandResult(result);
  }

  /// Moves cursor up one wrapped line, preserving the display column.
  void _lineUp({bool extendSelection = false}) {
    _moveByVisualLine(
      lineDelta: -1,
      extendSelection: extendSelection,
      clearSelection: !extendSelection,
    );
  }

  /// Moves cursor down one wrapped line, preserving the display column.
  void _lineDown({bool extendSelection = false}) {
    _moveByVisualLine(
      lineDelta: 1,
      extendSelection: extendSelection,
      clearSelection: !extendSelection,
    );
  }

  /// Moves cursor to start of current wrapped line.
  void _cursorLineStart({bool extendSelection = false}) {
    _moveToVisualLineBoundary(
      end: false,
      extendSelection: extendSelection,
      clearSelection: !extendSelection,
    );
  }

  /// Moves cursor to end of current wrapped line.
  void _cursorLineEnd({bool extendSelection = false}) {
    _moveToVisualLineBoundary(
      end: true,
      extendSelection: extendSelection,
      clearSelection: !extendSelection,
    );
  }

  /// Resets the sticky column for up/down navigation.
  void _resetDesiredCol() {
    _desiredCol = -1;
  }

  String? _validate(List<String> graphemes) {
    if (validate != null) {
      return validate!(graphemes.join());
    }
    return null;
  }

  T _runEditFrame<T>(T Function() body) {
    return _history.runFrame(
      captureState: _captureEditState,
      body: body,
      onCommittedChange: _syncCoreState,
    );
  }

  _TextInputEditState _captureEditState() {
    return _TextInputEditState(
      value: List<String>.of(_value, growable: false),
      position: _pos,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
      error: error,
    );
  }

  void _syncCoreState() {
    syncEditorStateFromOffsets(
      _document,
      _editorState,
      cursorOffset: _pos,
      selectionBaseOffset: selectionStart,
      selectionExtentOffset: selectionEnd,
    );

    _configureTextView();

    if (multiline) {
      if (_followMultilineCursor) {
        _scrollRow = _textView.ensureCursorVisible(_document, _editorState);
      } else {
        _textView.scrollToRow(_scrollRow, _document);
        _scrollRow = _textView.viewportStartRow;
      }
    } else {
      _scrollRow = 0;
      _textView.viewportStartRow = 0;
    }
  }

  void _configureTextView() {
    _textView
      ..width = width
      ..height = maxHeight
      ..softWrap = multiline
      ..leadingColumns = 0
      ..viewportStartRow = _scrollRow;
  }

  TextOffsetStateSnapshot _currentOffsetStateSnapshot() {
    return TextOffsetStateSnapshot(
      cursorOffset: _pos,
      selectionBaseOffset: selectionStart,
      selectionExtentOffset: selectionEnd,
    );
  }

  void _collapseOffsetState(int cursorOffset) {
    _applyOffsetStateSnapshot(
      TextOffsetStateSnapshot.collapsed(cursorOffset: cursorOffset),
    );
  }

  void _selectOffsetState({
    required int baseOffset,
    required int extentOffset,
    int? cursorOffset,
    bool preserveCollapsedSelection = false,
  }) {
    _applyOffsetStateSnapshot(
      TextOffsetStateSnapshot.selection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
        cursorOffset: cursorOffset,
        preserveCollapsedSelection: preserveCollapsedSelection,
      ),
    );
  }

  void _clearOffsetSelection({int? cursorOffset}) {
    _applyOffsetStateSnapshot(
      _currentOffsetStateSnapshot().clearSelection(cursorOffset: cursorOffset),
    );
  }

  void _applyOffsetStateSnapshot(TextOffsetStateSnapshot snapshot) {
    final clamped = snapshot.clamp(_value.length);
    _pos = clamped.cursorOffset;
    if (multiline) {
      _followMultilineCursor = true;
    }
    selectionStart = clamped.selectionBaseOffset;
    selectionEnd = clamped.selectionExtentOffset;
    _handleOverflow();
    _syncCoreState();
  }

  void _applyCursorCommandResult(commands.TextCursorCommandResult result) {
    _applyOffsetStateSnapshot(
      TextOffsetStateSnapshot(
        cursorOffset: result.cursorOffset,
        selectionBaseOffset: result.selectionBaseOffset,
        selectionExtentOffset: result.selectionExtentOffset,
      ),
    );
  }

  void _applyEditCommandResult(commands.TextCommandResult result) {
    final nextDocument = result.document;
    if (nextDocument != null) {
      _replaceDocumentSnapshot(
        nextDocument,
        graphemes: result.explicitGraphemes,
        change: result.documentChange,
      );
    } else {
      _replaceValueAndDocument(result.graphemes);
    }
    error = _validate(_value);
    _applyOffsetStateSnapshot(
      TextOffsetStateSnapshot(
        cursorOffset: result.cursorOffset,
        selectionBaseOffset: result.selectionBaseOffset,
        selectionExtentOffset: result.selectionExtentOffset,
      ),
    );
  }

  void _moveByCharacter({
    required bool forward,
    bool extendSelection = false,
    bool clearSelection = false,
  }) {
    _applyCursorCommandResult(
      textMoveByCharacter(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        forward: forward,
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      ),
    );
  }

  void _moveToDocumentBoundary({
    required bool forward,
    bool extendSelection = false,
    bool clearSelection = false,
  }) {
    _applyCursorCommandResult(
      textMoveToDocumentBoundary(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        forward: forward,
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      ),
    );
  }

  void _moveByVisualLine({
    required int lineDelta,
    bool extendSelection = false,
    bool clearSelection = true,
  }) {
    _configureTextView();
    final cursor = _document.positionForOffset(_pos);
    if (_desiredCol < 0) {
      _desiredCol =
          _textView
              .resolveCursorVisualPosition(
                _document,
                _editorState,
                cursor: cursor,
              )
              ?.displayColumn ??
          0;
    }
    _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveByVisualLineCommand(
        _document,
        _editorState,
        _textView,
        lineDelta: lineDelta,
        desiredDisplayColumn: _desiredCol,
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      ),
    );
  }

  void _moveToVisualLineBoundary({
    required bool end,
    bool extendSelection = false,
    bool clearSelection = true,
  }) {
    _configureTextView();
    _applyCursorCommandResult(
      _currentOffsetStateSnapshot().moveToVisualLineBoundaryCommand(
        _document,
        _editorState,
        _textView,
        end: end,
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      ),
    );
  }

  List<TextViewLine> _visibleTextViewLines() {
    _configureTextView();
    if (!multiline) {
      return _textView.buildLines(_document, _editorState);
    }
    final lines = _followMultilineCursor
        ? _textView.buildViewportLines(_document, _editorState)
        : _textView.buildLinesForCurrentViewport(_document, _editorState);
    _scrollRow = _textView.viewportStartRow;
    return lines;
  }

  void _restoreEditState(_TextInputEditState state) {
    _replaceValueAndDocument(List<String>.of(state.value));
    _pos = state.position.clamp(0, _value.length);
    selectionStart = state.selectionStart?.clamp(0, _value.length);
    selectionEnd = state.selectionEnd?.clamp(0, _value.length);
    error = state.error;
    _resetDesiredCol();
    _handleOverflow();
    _updateSuggestions();
    _syncCoreState();
  }

  void _beginHistoryAction(
    _TextInputHistoryAction action, {
    bool breakChain = false,
  }) {
    _history.beginAction(action, breakChain: breakChain);
  }

  bool _canCoalesceHistoryAction(
    _TextInputHistoryAction action, {
    required _TextInputHistoryAction? lastAction,
    required ({int cursor, int length})? lastMarker,
    required _TextInputEditState currentState,
  }) {
    if (currentState.selectionStart != null ||
        currentState.selectionEnd != null) {
      return false;
    }
    if (lastAction != action || lastMarker == null) return false;
    if (lastMarker.cursor != currentState.position) return false;
    if (lastMarker.length != currentState.value.length) return false;
    return switch (action) {
      _TextInputHistoryAction.insert => true,
      _TextInputHistoryAction.deleteBackward => true,
      _TextInputHistoryAction.deleteForward => true,
      _TextInputHistoryAction.paste => true,
      _ => false,
    };
  }

  void _recordUndoSnapshot() {
    _history.recordUndoSnapshot(_captureEditState);
  }

  void _setValueInternal(
    List<String> graphemes,
    String? err, {
    bool? wasEmpty,
  }) {
    error = err;
    final empty = wasEmpty ?? _value.isEmpty;

    final limitedGraphemes = charLimit > 0 && graphemes.length > charLimit
        ? graphemes.sublist(0, charLimit)
        : graphemes;
    _replaceValueAndDocument(limitedGraphemes);

    if ((position == 0 && empty) || position > _value.length) {
      position = _value.length;
    }
    _handleOverflow();
  }

  void _insertRunes(List<int> v) {
    final maxGraphemes = charLimit > 0 ? charLimit - _value.length : null;
    final paste = textPrepareInsertedGraphemes(
      v,
      multiline: multiline,
      maxGraphemes: maxGraphemes,
    );
    _insertLimited(paste);
  }

  Cmd _startChunkedPaste(String content) {
    final step = _pasteController.startChunked(
      content,
      chunkSize: _pasteChunkSizeRunes,
    );
    if (step == null) {
      _finishPendingPaste();
      return Cmd.none();
    }
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'paste.chunk.start chars=${content.length} runes=${step.totalRunes} '
        'chunk=$_pasteChunkSizeRunes',
        tag: TraceTag.input,
      );
    }

    _applyPasteChunkStep(step);
    return _pasteController.hasPendingChunkedPaste
        ? _schedulePasteChunk()
        : Cmd.none();
  }

  Cmd _schedulePasteChunk() {
    return Cmd.tick(Duration.zero, (_) => const _PasteChunkMsg());
  }

  void _finishPendingPaste() {
    _pasteController.clearPendingChunkedPaste();
    if (TuiTrace.enabled) {
      TuiTrace.log('paste.chunk.done', tag: TraceTag.input);
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

  void _applyPasteChunkStep(TextPasteChunkStep step) {
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'paste.chunk.apply start=${step.start} end=${step.end} total=${step.totalRunes}',
        tag: TraceTag.input,
      );
    }
    _insertRunes(step.runes);

    if (!step.hasMore) {
      _finishPendingPaste();
    }
  }

  bool _tryFastAppendWrapCache(List<String> paste, int oldLen) {
    if (!multiline) return false;
    if (paste.isEmpty) return false;
    if (_pos != oldLen) return false;
    if (paste.any((g) => g == '\n')) return false;

    final cache = _wrappedLinesCache;
    if (cache == null) return false;
    if (_wrappedLinesCacheVersion != _valueVersion) return false;
    if (_wrappedLinesCacheWidth != width) return false;

    final wrapWidth = width > 0 ? width : 0;
    if (cache.isEmpty) {
      cache.add(const _WrappedLine(0, 0));
    }

    var last = cache.last;
    var lineStart = last.start;
    var lineEnd = last.end;
    var lineWidth = 0;

    if (wrapWidth > 0) {
      for (var i = lineStart; i < lineEnd; i++) {
        lineWidth += runeWidth(uni.firstCodePoint(_value[i]));
      }
    }

    for (final grapheme in paste) {
      final rw = runeWidth(uni.firstCodePoint(grapheme));
      if (wrapWidth <= 0 || lineWidth + rw <= wrapWidth) {
        lineEnd++;
        lineWidth += rw;
      } else {
        cache[cache.length - 1] = _WrappedLine(lineStart, lineEnd);
        lineStart = lineEnd;
        lineEnd = lineStart + 1;
        lineWidth = rw;
        cache.add(_WrappedLine(lineStart, lineEnd));
      }
    }

    cache[cache.length - 1] = _WrappedLine(lineStart, lineEnd);
    return true;
  }

  void _insertLimited(List<String> paste) {
    if (paste.isEmpty) return;
    _recordUndoSnapshot();
    final wasEmpty = _value.isEmpty;
    final oldLen = _value.length;
    final fastWrapAppend = _tryFastAppendWrapCache(paste, oldLen);

    final result = textInsertGraphemes(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      graphemes: paste,
      replaceSelection: false,
    );
    final nextDocument = result.document;
    if (nextDocument != null && fastWrapAppend) {
      _document = nextDocument;
      _value = <String>[..._value, ...paste];
    } else if (nextDocument != null) {
      _replaceDocumentSnapshot(
        nextDocument,
        graphemes: result.explicitGraphemes,
        change: result.documentChange,
      );
    } else {
      _replaceValueAndDocument(result.graphemes);
    }

    final err = _validate(_value);
    if (fastWrapAppend) {
      error = err;
      _valueVersion++;
      _wrappedLinesCacheVersion = _valueVersion;
      _wrappedLinesCacheWidth = width;
      final nextOffset =
          ((position == 0 && wasEmpty) || position > _value.length)
          ? _value.length
          : result.cursorOffset;
      _applyOffsetStateSnapshot(
        TextOffsetStateSnapshot.collapsed(cursorOffset: nextOffset),
      );
      return;
    }

    _setValueInternal(_value, err, wasEmpty: wasEmpty);
    _collapseOffsetState(result.cursorOffset);
  }

  void _handleOverflow() {
    if (multiline) {
      // In multiline mode, handle vertical scrolling instead of horizontal.
      // Horizontal overflow is handled by line wrapping.
      _offset = 0;
      _offsetRight = _value.length;

      if (maxHeight <= 0) {
        // Unlimited height — no vertical scrolling needed.
        _scrollRow = 0;
        _syncCoreState();
        return;
      }

      _syncCoreState();
      return;
    }

    if (width <= 0 || stringWidth(_value.join()) <= width) {
      _offset = 0;
      _offsetRight = _value.length;
      return;
    }

    _offsetRight = math.min(_offsetRight, _value.length);

    if (_pos < _offset) {
      _offset = _pos;
      var w = 0;
      var i = 0;
      final gs = _value.sublist(_offset);

      while (i < gs.length && w <= width) {
        w += runeWidth(uni.firstCodePoint(gs[i]));
        if (w <= width + 1) i++;
      }

      _offsetRight = _offset + i;
    } else if (_pos >= _offsetRight) {
      _offsetRight = _pos;
      var w = 0;
      final gs = _value.sublist(0, _offsetRight);
      var i = gs.length - 1;

      while (i > 0 && w < width) {
        w += runeWidth(uni.firstCodePoint(gs[i]));
        if (w <= width) i--;
      }

      _offset = _offsetRight - (gs.length - 1 - i);
    }
  }

  void _replaceValueAndDocument(List<String> graphemes) {
    final normalized = List<String>.of(graphemes, growable: false);
    final nextDocument = TextDocument.fromFlatGraphemes(normalized);
    _value = normalized;
    _document = nextDocument;
    _invalidateWrappedLines();
  }

  void _replaceDocumentSnapshot(
    TextDocument document, {
    List<String>? graphemes,
    TextDocumentChange? change,
  }) {
    _document = document;
    _value = graphemes != null
        ? List<String>.of(graphemes, growable: false)
        : change != null
        ? _patchValueForDocumentChange(document, change)
        : document.flattenWithNewlines();
    _invalidateWrappedLines();
  }

  List<String> _patchValueForDocumentChange(
    TextDocument document,
    TextDocumentChange change,
  ) {
    if (change.isNoop) {
      return List<String>.of(_value, growable: false);
    }
    final start = change.startOffset.clamp(0, _value.length);
    final oldEnd = change.oldEndOffset.clamp(start, _value.length);
    final replacement = document.graphemesInRange(
      startOffset: change.startOffset,
      endOffset: change.newEndOffset,
    );
    return List<String>.unmodifiable(<String>[
      ..._value.sublist(0, start),
      ...replacement,
      ..._value.sublist(oldEnd),
    ]);
  }

  bool _deleteSelection() {
    final result = textDeleteSelection(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    if (!result.changed) {
      _applyOffsetStateSnapshot(_currentOffsetStateSnapshot().clearSelection());
      return false;
    }
    _recordUndoSnapshot();
    _applyEditCommandResult(result);
    return true;
  }

  void _deleteBeforeCursor() {
    if (_pos <= 0) return;
    _recordUndoSnapshot();
    final result = textDeletePrevious(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _offset = 0;
    _applyEditCommandResult(result);
  }

  void _deleteAfterCursor() {
    if (_pos >= _value.length) return;
    _recordUndoSnapshot();
    final result = textDeleteNext(
      document: _document,
      state: _currentOffsetStateSnapshot(),
    );
    _applyEditCommandResult(result);
  }

  void _deleteWordBackward() {
    if (_pos == 0 || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _deleteBeforeCursor();
      return;
    }

    _recordUndoSnapshot();
    final result = textDeleteWordBackward(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      isWord: (grapheme) => !_isWhitespace(grapheme),
    );
    _applyEditCommandResult(result);
  }

  void _deleteWordForward() {
    if (_pos >= _value.length || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _deleteAfterCursor();
      return;
    }

    _recordUndoSnapshot();
    final result = textDeleteWordForward(
      document: _document,
      state: _currentOffsetStateSnapshot(),
      isWord: (grapheme) => !_isWhitespace(grapheme),
    );
    _applyEditCommandResult(result);
  }

  void _wordBackward({
    bool extendSelection = false,
    bool clearSelection = false,
  }) {
    if (_pos == 0 || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _moveToDocumentBoundary(
        forward: false,
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      );
      return;
    }

    _applyCursorCommandResult(
      textMoveByWord(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        forward: false,
        isWord: (grapheme) => !_isWhitespace(grapheme),
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      ),
    );
  }

  void _wordForward({
    bool extendSelection = false,
    bool clearSelection = false,
  }) {
    if (_pos >= _value.length || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _moveToDocumentBoundary(
        forward: true,
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      );
      return;
    }

    _applyCursorCommandResult(
      textMoveByWord(
        document: _document,
        state: _currentOffsetStateSnapshot(),
        forward: true,
        isWord: (grapheme) => !_isWhitespace(grapheme),
        extendSelection: extendSelection,
        clearSelection: clearSelection,
      ),
    );
  }

  (int, int) _findWordAt(int x) {
    if (_value.isEmpty) return (0, 0);
    final boundary = _document.wordBoundaryAt(_document.positionForOffset(x));
    return (
      _document.offsetForPosition(boundary.start),
      _document.offsetForPosition(boundary.end),
    );
  }

  (int, int) _findLineAt(int offset) {
    if (_value.isEmpty) return (0, 0);
    final position = _document.positionForOffset(offset);
    final start = _document.offsetForPosition(
      TextPosition(line: position.line, column: 0),
    );
    final end = _document.offsetForPosition(
      TextPosition(
        line: position.line,
        column: _document.lineLength(position.line),
      ),
    );
    return (start, end);
  }

  bool _isWhitespace(String grapheme) {
    final rune = uni.firstCodePoint(grapheme);
    return rune == 0x20 || // Space
        rune == 0x09 || // Tab
        rune == 0x0A || // LF
        rune == 0x0D; // CR
  }

  String _echoTransform(String v) {
    switch (echoMode) {
      case EchoMode.password:
        return echoCharacter * stringWidth(v);
      case EchoMode.none:
        return '';
      case EchoMode.normal:
        return v;
    }
  }

  bool _canAcceptSuggestion() => _matchedSuggestions.isNotEmpty;

  void _updateSuggestions() {
    if (!showSuggestions) return;

    if (_value.isEmpty || _suggestions.isEmpty) {
      _matchedSuggestions = <List<String>>[];
      return;
    }

    final valueStr = _value.join().toLowerCase();
    final matches = <List<String>>[];

    for (final s in _suggestions) {
      final suggestion = s.join().toLowerCase();
      if (suggestion.startsWith(valueStr)) {
        matches.add(s);
      }
    }

    if (!_listEquals(matches, _matchedSuggestions)) {
      _currentSuggestionIndex = 0;
    }

    _matchedSuggestions = matches;
  }

  bool _listEquals(List<List<String>> a, List<List<String>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (var j = 0; j < a[i].length; j++) {
        if (a[i][j] != b[i][j]) return false;
      }
    }
    return true;
  }

  void _insertCollapsedPasteReference(
    String content, {
    required int lineCount,
  }) {
    final ref = _pasteController.storeCollapsed(content, lineCount: lineCount);
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'paste.collapse ref=${ref.uri} chars=${content.length} lines=$lineCount',
        tag: TraceTag.input,
      );
    }

    final token = ref.token;
    _deleteSelection();
    _insertLimited(uni.graphemes(token).toList(growable: false));
  }

  void _nextSuggestion() {
    _currentSuggestionIndex = (_currentSuggestionIndex + 1);
    if (_currentSuggestionIndex >= _matchedSuggestions.length) {
      _currentSuggestionIndex = 0;
    }
  }

  void _previousSuggestion() {
    _currentSuggestionIndex = (_currentSuggestionIndex - 1);
    if (_currentSuggestionIndex < 0) {
      _currentSuggestionIndex = _matchedSuggestions.length - 1;
    }
  }

  @override
  Cmd? init() => null;

  @override
  (TextInputModel, Cmd?) update(Msg msg) {
    return _runEditFrame(() {
      final cmds = <Cmd>[];

      if (msg is MouseMsg) {
        if (multiline) {
          return _handleMultilineMouse(msg);
        }
        if (msg.action == MouseAction.wheel) {
          switch (msg.button) {
            case MouseButton.wheelUp:
            case MouseButton.wheelLeft:
              _scrollSingleLineBy(-1);
              break;
            case MouseButton.wheelDown:
            case MouseButton.wheelRight:
              _scrollSingleLineBy(1);
              break;
            default:
              break;
          }
          return (this, null);
        }
        if (msg.y != 0) {
          if (msg.action == MouseAction.press &&
              msg.button == MouseButton.left) {
            _clearOffsetSelection();
            _mouseSelecting = false;
            _focused = false;
          }
          return (this, null);
        }
        final promptWidth = stringWidth(prompt);
        final localX = msg.x - promptWidth;
        final visibleValue = _value.sublist(_offset, _offsetRight);
        final visibleText = visibleValue.join();
        final idxInVisible = layout.localCellXToGraphemeIndex(
          visibleText,
          localX,
        );
        final x = _offset + idxInVisible;

        if (msg.action == MouseAction.press && msg.button == MouseButton.left) {
          _focused = true;
          _mouseSelecting = true;
          final now = DateTime.now();
          final clickCount =
              _lastClickTime != null &&
                  now.difference(_lastClickTime!) <
                      const Duration(milliseconds: 500) &&
                  _lastClickPos == x
              ? (_lastClickCount + 1).clamp(1, 3)
              : 1;
          _lastClickTime = now;
          _lastClickPos = x;
          _lastClickCount = clickCount;

          if (clickCount == 2) {
            final (start, end) = _findWordAt(x);
            _selectOffsetState(
              baseOffset: start,
              extentOffset: end,
              cursorOffset: end,
            );
          } else if (clickCount >= 3) {
            final (start, end) = _findLineAt(x);
            _selectOffsetState(
              baseOffset: start,
              extentOffset: end,
              cursorOffset: end,
            );
          } else {
            _selectOffsetState(
              baseOffset: x,
              extentOffset: x,
              cursorOffset: x,
              preserveCollapsedSelection: true,
            );
          }
        } else if (msg.action == MouseAction.motion && _mouseSelecting) {
          _selectOffsetState(
            baseOffset: selectionStart ?? _pos,
            extentOffset: x,
            cursorOffset: x,
            preserveCollapsedSelection: true,
          );
        } else if (msg.action == MouseAction.release && _mouseSelecting) {
          _mouseSelecting = false;
          if (selectionStart == selectionEnd) {
            _clearOffsetSelection();
            return (this, null);
          }
          final cmd = _copySelectionCmdIfAny();
          _clearOffsetSelection();
          return (this, cmd);
        }
        return (this, null);
      }

      if (!_focused) {
        return (this, null);
      }

      // Check for suggestion acceptance first
      if (msg is KeyMsg && keyMatches(msg.key, [keyMap.acceptSuggestion])) {
        if (_canAcceptSuggestion()) {
          _beginHistoryAction(
            _TextInputHistoryAction.replace,
            breakChain: true,
          );
          _recordUndoSnapshot();
          final suggestion = _matchedSuggestions[_currentSuggestionIndex];
          _value = [..._value, ...suggestion.sublist(_value.length)];
          _invalidateWrappedLines();
          cursorEnd();
        }
      }

      if (msg is KeyMsg) {
        if (keyMatches(msg.key, [keyMap.copy])) {
          final selected = getSelectedText();
          if (selected.isNotEmpty) {
            return (this, Cmd.setClipboardBestEffort(selected));
          }
        }

        if (keyMatches(msg.key, [keyMap.undo])) {
          undo();
          _updateSuggestions();
          return (this, null);
        }

        if (keyMatches(msg.key, [keyMap.redo])) {
          redo();
          _updateSuggestions();
          return (this, null);
        }

        if (keyMatches(msg.key, [keyMap.cut])) {
          final selected = getSelectedText();
          if (selected.isNotEmpty) {
            _beginHistoryAction(
              _TextInputHistoryAction.replace,
              breakChain: true,
            );
            _deleteSelection();
            return (this, Cmd.setClipboardBestEffort(selected));
          }
        }

        if (keyMatches(msg.key, [keyMap.selectAll])) {
          selectAll();
          return (this, null);
        }

        // Multi-line: newline insertion (Enter / Shift+Enter)
        if (multiline && keyMatches(msg.key, [keyMap.newline])) {
          _beginHistoryAction(_TextInputHistoryAction.insert);
          _deleteSelection();
          _resetDesiredCol();
          _insertNewline();
          _updateSuggestions();
          _handleOverflow();
          return (this, null);
        }

        if (msg.key.type == KeyType.space) {
          _beginHistoryAction(_TextInputHistoryAction.insert);
          _resetDesiredCol();
          _insertRunes([0x20]);
          return (this, null);
        }

        if (keyMatches(msg.key, [keyMap.deleteWordBackward])) {
          _beginHistoryAction(_TextInputHistoryAction.deleteBackward);
          _resetDesiredCol();
          if (!_deleteSelection()) {
            _deleteWordBackward();
          }
        } else if (keyMatches(msg.key, [keyMap.deleteCharacterBackward])) {
          _beginHistoryAction(_TextInputHistoryAction.deleteBackward);
          _resetDesiredCol();
          if (!_deleteSelection()) {
            _deleteBeforeCursor();
          }
        } else if (keyMatches(msg.key, [keyMap.wordBackward])) {
          _resetDesiredCol();
          _wordBackward(clearSelection: true);
        } else if (keyMatches(msg.key, [keyMap.selectWordBackward])) {
          _resetDesiredCol();
          _wordBackward(extendSelection: true);
        } else if (keyMatches(msg.key, [keyMap.characterBackward])) {
          _resetDesiredCol();
          _moveByCharacter(forward: false, clearSelection: true);
        } else if (keyMatches(msg.key, [keyMap.selectCharacterBackward])) {
          _resetDesiredCol();
          _moveByCharacter(forward: false, extendSelection: true);
        } else if (keyMatches(msg.key, [keyMap.wordForward])) {
          _resetDesiredCol();
          _wordForward(clearSelection: true);
        } else if (keyMatches(msg.key, [keyMap.selectWordForward])) {
          _resetDesiredCol();
          _wordForward(extendSelection: true);
        } else if (keyMatches(msg.key, [keyMap.characterForward])) {
          _resetDesiredCol();
          _moveByCharacter(forward: true, clearSelection: true);
        } else if (keyMatches(msg.key, [keyMap.selectCharacterForward])) {
          _resetDesiredCol();
          _moveByCharacter(forward: true, extendSelection: true);
        } else if (multiline && keyMatches(msg.key, [keyMap.documentStart])) {
          // Multi-line: Ctrl+Home — go to document start
          _resetDesiredCol();
          _moveToDocumentBoundary(forward: false, clearSelection: true);
        } else if (multiline && keyMatches(msg.key, [keyMap.documentEnd])) {
          // Multi-line: Ctrl+End — go to document end
          _resetDesiredCol();
          _moveToDocumentBoundary(forward: true, clearSelection: true);
        } else if (keyMatches(msg.key, [keyMap.lineStart])) {
          _resetDesiredCol();
          if (multiline) {
            _cursorLineStart();
          } else {
            cursorStart();
          }
        } else if (keyMatches(msg.key, [keyMap.selectLineStart])) {
          _resetDesiredCol();
          if (multiline) {
            _cursorLineStart(extendSelection: true);
          } else {
            _moveToDocumentBoundary(
              forward: false,
              extendSelection: true,
              clearSelection: false,
            );
          }
        } else if (keyMatches(msg.key, [keyMap.deleteCharacterForward])) {
          _beginHistoryAction(_TextInputHistoryAction.deleteForward);
          _resetDesiredCol();
          if (!_deleteSelection()) {
            _deleteAfterCursor();
          }
        } else if (keyMatches(msg.key, [keyMap.lineEnd])) {
          _resetDesiredCol();
          if (multiline) {
            _cursorLineEnd();
          } else {
            cursorEnd();
          }
        } else if (keyMatches(msg.key, [keyMap.selectLineEnd])) {
          _resetDesiredCol();
          if (multiline) {
            _cursorLineEnd(extendSelection: true);
          } else {
            _moveToDocumentBoundary(
              forward: true,
              extendSelection: true,
              clearSelection: false,
            );
          }
        } else if (keyMatches(msg.key, [keyMap.deleteAfterCursor])) {
          _beginHistoryAction(_TextInputHistoryAction.deleteForward);
          _resetDesiredCol();
          _clearOffsetSelection();
          _deleteAfterCursor();
        } else if (keyMatches(msg.key, [keyMap.deleteBeforeCursor])) {
          _beginHistoryAction(_TextInputHistoryAction.deleteBackward);
          _resetDesiredCol();
          _clearOffsetSelection();
          _deleteBeforeCursor();
        } else if (keyMatches(msg.key, [keyMap.paste])) {
          _beginHistoryAction(_TextInputHistoryAction.paste, breakChain: true);
          _resetDesiredCol();
          _deleteSelection();
          // Return paste command - caller handles clipboard
          return (this, _pasteCmd());
        } else if (keyMatches(msg.key, [keyMap.deleteWordForward])) {
          _beginHistoryAction(_TextInputHistoryAction.deleteForward);
          _resetDesiredCol();
          if (!_deleteSelection()) {
            _deleteWordForward();
          }
        } else if (multiline && keyMatches(msg.key, [keyMap.lineUp])) {
          // Multi-line: Up arrow — move cursor up one line
          _lineUp();
        } else if (multiline && keyMatches(msg.key, [keyMap.selectLineUp])) {
          _lineUp(extendSelection: true);
        } else if (multiline && keyMatches(msg.key, [keyMap.lineDown])) {
          // Multi-line: Down arrow — move cursor down one line
          _lineDown();
        } else if (multiline && keyMatches(msg.key, [keyMap.selectLineDown])) {
          _lineDown(extendSelection: true);
        } else if (keyMatches(msg.key, [keyMap.nextSuggestion])) {
          _nextSuggestion();
        } else if (keyMatches(msg.key, [keyMap.prevSuggestion])) {
          _previousSuggestion();
        } else if (!msg.key.alt &&
            msg.key.type == KeyType.runes &&
            msg.key.runes.length == 1 &&
            msg.key.runes.first == 0x03) {
          final selected = getSelectedText();
          if (selected.isNotEmpty) {
            return (this, Cmd.setClipboardBestEffort(selected));
          }
        } else if (msg.key.runes.isNotEmpty && !msg.key.ctrl && !msg.key.alt) {
          // Regular character input
          final insertable = <int>[];
          for (final r in msg.key.runes) {
            if (r >= 0x20 && r != 0x7F) {
              insertable.add(r);
            }
          }
          if (insertable.isEmpty) {
            _updateSuggestions();
            return (this, null);
          }
          _beginHistoryAction(_TextInputHistoryAction.insert);
          _resetDesiredCol();
          _deleteSelection();
          _insertRunes(insertable);
        }

        _updateSuggestions();
      } else if (msg is _PasteChunkMsg) {
        _beginHistoryAction(_TextInputHistoryAction.paste);
        _applyNextPasteChunk();
        if (_pasteController.hasPendingChunkedPaste) {
          cmds.add(_schedulePasteChunk());
        }
      } else if (msg is PasteMsg || msg is PasteTextMsg) {
        _beginHistoryAction(_TextInputHistoryAction.paste, breakChain: true);
        final content = msg is PasteMsg
            ? msg.content
            : (msg as PasteTextMsg).content;
        final pastePlan = planTextPaste(
          content,
          collapseLargePaste: collapseLargePaste,
          collapsedPasteMinChars: collapsedPasteMinChars,
          collapsedPasteMinLines: collapsedPasteMinLines,
          chunkThresholdRunes: _pasteChunkThresholdRunes,
        );
        if (TuiTrace.enabled) {
          final kind = msg is PasteMsg ? 'PasteMsg' : 'PasteTextMsg';
          TuiTrace.log(
            'paste.msg kind=$kind chars=${content.length} focused=$_focused',
            tag: TraceTag.input,
          );
        }
        if (pastePlan.collapse) {
          _insertCollapsedPasteReference(
            content,
            lineCount: pastePlan.lineCount,
          );
        } else if (pastePlan.chunked) {
          cmds.add(_startChunkedPaste(content));
        } else {
          if (TuiTrace.enabled) {
            TuiTrace.log(
              'paste.inline chars=${content.length} runes=${pastePlan.runeCount}',
              tag: TraceTag.input,
            );
          }
          _insertRunes(uni.codePoints(content));
        }
      } else if (msg is PasteErrorMsg) {
        error = msg.error.toString();
      }

      // Update cursor
      final (newCursor, cursorCmd) = cursor.update(msg);
      cursor = newCursor;
      if (cursorCmd != null) cmds.add(cursorCmd);

      // Avoid scheduling a blink command on every keypress. Cursor blinking is
      // already driven by its own timer loop while focused.

      _handleOverflow();
      return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
    });
  }

  @override
  Object view() {
    final span = TuiTrace.begin(
      'TextInputModel.view',
      tag: TraceTag.render,
      extra: 'len=${_value.length} offset=$_offset offsetR=$_offsetRight',
    );
    // Placeholder text
    if (_value.isEmpty && placeholder.isNotEmpty) {
      span.end(extra: 'placeholder');
      return _placeholderView();
    }

    // Multi-line rendering path.
    if (multiline) {
      final result = _multilineView();
      span.end(extra: 'multiline lines=$lineCount');
      return result;
    }

    final styles = activeStyle();
    final visibleValue = _value.sublist(_offset, _offsetRight);
    final pos = math.max(0, _pos - _offset);

    // Selection range in visible space
    int? selStart, selEnd;
    if (selectionStart != null && selectionEnd != null) {
      final start = math.min(selectionStart!, selectionEnd!);
      final end = math.max(selectionStart!, selectionEnd!);

      selStart = math.max(0, start - _offset);
      selEnd = math.min(visibleValue.length, end - _offset);

      if (selStart >= visibleValue.length || selEnd <= 0) {
        selStart = null;
        selEnd = null;
      }
    }

    final v = StringBuffer();
    final normalEcho = echoMode == EchoMode.normal;
    final hasSelection = selStart != null && selEnd != null;
    final visibleSelStart = selStart ?? -1;
    final visibleSelEnd = selEnd ?? -1;
    var valWidth = 0;

    for (var i = 0; i < visibleValue.length; i++) {
      final raw = visibleValue[i];
      final char = normalEcho ? raw : _echoTransform(raw);
      valWidth += normalEcho
          ? runeWidth(uni.firstCodePoint(raw))
          : stringWidth(char);
      final isSelected =
          hasSelection && i >= visibleSelStart && i < visibleSelEnd;

      final cellStyle = _textCellStyle(
        styles,
        isSelected: isSelected,
        useCursorStyle: i == pos,
      );
      v.write(cellStyle.render(char));
    }

    if (pos >= visibleValue.length) {
      if (_focused && _canAcceptSuggestion()) {
        final suggestion = _matchedSuggestions[_currentSuggestionIndex];
        if (_value.length < suggestion.length) {
          final cellStyle = _textCellStyle(
            styles,
            isSelected: false,
            useCursorStyle: true,
          );
          v.write(cellStyle.render(_echoTransform(suggestion[_value.length])));
          v.write(_completionView(1));
        } else {
          final cellStyle = _textCellStyle(
            styles,
            isSelected: false,
            useCursorStyle: true,
          );
          v.write(cellStyle.render(' '));
        }
      } else {
        final cellStyle = _textCellStyle(
          styles,
          isSelected: false,
          useCursorStyle: true,
        );
        v.write(cellStyle.render(' '));
      }
    }

    // Padding for fixed width
    if (width > 0 && valWidth <= width) {
      var padding = math.max(0, width - valWidth);
      if (valWidth + padding <= width && pos < visibleValue.length) {
        padding++;
      }
      v.write(_renderPadding(styles.text, styles.prompt, padding));
    }

    final styledPrompt = styles.prompt.render(prompt);
    final content = '$styledPrompt${v.toString()}';

    if (useVirtualCursor || !_focused) {
      span.end(extra: 'chars=${visibleValue.length}');
      return content;
    }

    span.end(extra: 'chars=${visibleValue.length}');
    return View(content: content, cursor: terminalCursor);
  }

  /// Handles mouse events in multi-line mode.
  ///
  /// Maps `(msg.x, msg.y)` to a flat position in `_value` using the wrapped
  /// line layout and scroll offset.
  (TextInputModel, Cmd?) _handleMultilineMouse(MouseMsg msg) {
    if (msg.action == MouseAction.wheel) {
      switch (msg.button) {
        case MouseButton.wheelUp:
          _scrollMultilineRows(-1);
          break;
        case MouseButton.wheelDown:
          _scrollMultilineRows(1);
          break;
        case MouseButton.wheelLeft:
          _scrollSingleLineBy(-1);
          break;
        case MouseButton.wheelRight:
          _scrollSingleLineBy(1);
          break;
        default:
          break;
      }
      return (this, null);
    }

    final lines = _visibleTextViewLines();
    final visibleHeight = maxHeight > 0 ? maxHeight : lines.length;
    final promptWidth = stringWidth(prompt);
    final localX = msg.x - promptWidth;
    final beforePos = _pos;

    // Click outside visible area — unfocus.
    if (msg.y < 0 || msg.y >= visibleHeight) {
      if (msg.action == MouseAction.press && msg.button == MouseButton.left) {
        _clearOffsetSelection();
        _mouseSelecting = false;
        _focused = false;
      }
      return (this, null);
    }

    final hit = _textView.hitTestContent(
      _document,
      _editorState,
      localX: localX,
      visualRow: msg.y,
    );
    if (hit == null) {
      return (this, null);
    }
    final flatPos = _document
        .offsetForPosition(TextPosition(line: hit.line, column: hit.column))
        .clamp(0, _value.length);

    if (msg.action == MouseAction.press && msg.button == MouseButton.left) {
      _focused = true;
      _mouseSelecting = true;
      _resetDesiredCol();
      final pressFlatPos = flatPos;
      final now = DateTime.now();
      final clickCount =
          _lastClickTime != null &&
              now.difference(_lastClickTime!) <
                  const Duration(milliseconds: 500) &&
              _lastClickPos == pressFlatPos
          ? (_lastClickCount + 1).clamp(1, 3)
          : 1;
      _lastClickTime = now;
      _lastClickPos = pressFlatPos;
      _lastClickCount = clickCount;

      if (clickCount == 2) {
        final (start, end) = _findWordAt(pressFlatPos);
        _selectOffsetState(
          baseOffset: start,
          extentOffset: end,
          cursorOffset: end,
        );
      } else if (clickCount >= 3) {
        final (start, end) = _findLineAt(pressFlatPos);
        _selectOffsetState(
          baseOffset: start,
          extentOffset: end,
          cursorOffset: end,
        );
      } else {
        _selectOffsetState(
          baseOffset: pressFlatPos,
          extentOffset: pressFlatPos,
          cursorOffset: pressFlatPos,
          preserveCollapsedSelection: true,
        );
      }
      if (TuiTrace.enabled) {
        TuiTrace.log(
          'mouse.multiline press x=${msg.x} y=${msg.y} localX=$localX '
          'flat=$flatPos pressFlat=$pressFlatPos '
          'before=$beforePos after=$_pos',
        );
      }
    } else if (msg.action == MouseAction.motion && _mouseSelecting) {
      _resetDesiredCol();
      _selectOffsetState(
        baseOffset: selectionStart ?? _pos,
        extentOffset: flatPos,
        cursorOffset: flatPos,
        preserveCollapsedSelection: true,
      );
      if (TuiTrace.enabled) {
        TuiTrace.log(
          'mouse.multiline motion x=${msg.x} y=${msg.y} localX=$localX '
          'flat=$flatPos before=$beforePos after=$_pos',
        );
      }
    } else if (msg.action == MouseAction.release && _mouseSelecting) {
      _mouseSelecting = false;
      if (TuiTrace.enabled) {
        TuiTrace.log(
          'mouse.multiline release x=${msg.x} y=${msg.y} localX=$localX '
          'flat=$flatPos before=$beforePos after=$_pos '
          'sel=(${selectionStart ?? -1},${selectionEnd ?? -1})',
        );
      }
      if (selectionStart == selectionEnd) {
        _clearOffsetSelection();
        return (this, null);
      }
      final cmd = _copySelectionCmdIfAny();
      _clearOffsetSelection();
      return (this, cmd);
    }
    return (this, null);
  }

  /// Renders the multi-line view.
  ///
  /// Computes wrapped lines, determines visible rows (via [_scrollRow] and
  /// [maxHeight]), renders each row with cursor/selection highlighting,
  /// and joins them with newlines.
  Object _multilineView() {
    final styles = activeStyle();
    final normalEcho = echoMode == EchoMode.normal;
    final lines = _visibleTextViewLines();
    final promptWidth = stringWidth(prompt);
    final continuationPrompt = ' ' * promptWidth;

    // Compute absolute selection range.
    int? absSelStart, absSelEnd;
    if (selectionStart != null && selectionEnd != null) {
      absSelStart = math.min(selectionStart!, selectionEnd!);
      absSelEnd = math.max(selectionStart!, selectionEnd!);
      if (absSelStart == absSelEnd) {
        absSelStart = null;
        absSelEnd = null;
      }
    }

    final rowStrings = <String>[];

    for (var row = 0; row < lines.length; row++) {
      final line = lines[row];
      final linePrompt = (row == 0 && _scrollRow == 0)
          ? prompt
          : continuationPrompt;
      final rowStr = StringBuffer();
      var rowContentWidth = 0;

      final graphemes = uni.graphemes(line.text).toList(growable: false);
      for (var i = 0; i < graphemes.length; i++) {
        final raw = graphemes[i];
        final char = normalEcho ? raw : _echoTransform(raw);
        rowContentWidth += normalEcho
            ? runeWidth(uni.firstCodePoint(raw))
            : stringWidth(char);
        final flatIndex = line.charOffset + i;
        final isSelected =
            absSelStart != null &&
            flatIndex >= absSelStart &&
            flatIndex < absSelEnd!;
        final isCursorPos = line.hasCursor && (_pos - line.charOffset) == i;

        final cellStyle = _textCellStyle(
          styles,
          isSelected: isSelected,
          useCursorStyle: isCursorPos,
        );
        rowStr.write(cellStyle.render(char));
      }

      // If cursor is at end of this line (past last char).
      final cursorAtLineEnd =
          line.hasCursor && (_pos - line.charOffset) == graphemes.length;
      if (cursorAtLineEnd) {
        final cellStyle = _textCellStyle(
          styles,
          isSelected: false,
          useCursorStyle: true,
        );
        rowStr.write(cellStyle.render(' '));
      }

      // Pad line to width.
      if (width > 0) {
        final cursorExtra = cursorAtLineEnd ? 1 : 0;
        final padAmount = math.max(0, width - rowContentWidth - cursorExtra);
        if (padAmount > 0) {
          rowStr.write(_renderPadding(styles.text, styles.prompt, padAmount));
        }
      }

      rowStrings.add(styles.prompt.render(linePrompt) + rowStr.toString());
    }

    final content = rowStrings.join('\n');

    if (useVirtualCursor || !_focused) {
      return content;
    }
    return View(content: content, cursor: terminalCursor);
  }

  Object _placeholderView() {
    final styles = activeStyle();
    final result = firstGraphemeCluster(placeholder);
    cursor = cursor.setChar(result.first);
    var v = cursor.view().toString();

    if (width < 1 && stringWidth(result.rest) <= 1) {
      final styledPrompt = styles.prompt.render(prompt);
      final content = '$styledPrompt$v';
      if (useVirtualCursor || !_focused) return content;
      return View(content: content, cursor: terminalCursor);
    }

    if (width > 0) {
      final promptWidth = stringWidth(prompt);
      final cursorWidth = stringWidth(v);
      final availWidth = width - promptWidth - cursorWidth;
      final placeholderRest = truncate(result.rest, availWidth, '…');
      final restWidth = stringWidth(placeholderRest);
      final paddingWidth = math.max(0, availWidth - restWidth);
      v +=
          styles.placeholder.render(placeholderRest) +
          _renderPadding(styles.placeholder, styles.prompt, paddingWidth);
    } else {
      v += styles.placeholder.render(result.rest);
    }

    final styledPrompt = styles.prompt.render(prompt);
    final content = '$styledPrompt$v';

    if (useVirtualCursor || !_focused) return content;
    return View(content: content, cursor: terminalCursor);
  }

  String _completionView(int offset) {
    if (_canAcceptSuggestion()) {
      final suggestion = _matchedSuggestions[_currentSuggestionIndex];
      if (_value.length < suggestion.length) {
        return activeStyle().suggestion
            .inline(true)
            .render(suggestion.sublist(_value.length + offset).join());
      }
    }
    return '';
  }

  String _renderPadding(Style primary, Style fallback, int count) {
    if (count <= 0) return '';
    final primaryInline = primary.inline(true);
    final sample = primaryInline.render(' ');
    if (sample.contains('\x1b')) {
      return primaryInline.render(' ' * count);
    }
    final fallbackInline = fallback.inline(true);
    return fallbackInline.render(' ' * count);
  }

  /// Handles the paste key binding (Ctrl+V).
  ///
  /// Returns `null` because clipboard paste is handled via bracketed paste mode
  /// at the terminal level. When bracketed paste is enabled (the default in
  /// TUI programs with `ProgramOptions.bracketedPaste = true`), the terminal
  /// intercepts Ctrl+V and sends the clipboard content as a [PasteMsg], which
  /// is handled in `update()`.
  ///
  /// If bracketed paste is not enabled, pressing Ctrl+V will do nothing.
  /// To support paste without bracketed paste mode, the caller would need to
  /// implement platform-specific clipboard access (e.g., via OSC 52 or native
  /// clipboard APIs) and send a [PasteMsg] to the model.
  Cmd? _pasteCmd() {
    return null;
  }
}
