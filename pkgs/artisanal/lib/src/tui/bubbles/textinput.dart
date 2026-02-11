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
    KeyBinding? acceptSuggestion,
    KeyBinding? nextSuggestion,
    KeyBinding? prevSuggestion,
    KeyBinding? newline,
    KeyBinding? lineUp,
    KeyBinding? lineDown,
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
             keys: ['ctrl+c'],
             help: Help(key: '^c', desc: 'Copy'),
           ),
       cut =
           cut ??
           KeyBinding(
             keys: ['ctrl+x'],
             help: Help(key: '^x', desc: 'Cut'),
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
      acceptSuggestion,
      nextSuggestion,
      prevSuggestion,
    ],
    [newline, lineUp, lineDown],
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
    TextInputKeyMap? keyMap,
    CursorModel? cursor,
    this.validate,
    TextInputStyles? styles,
  }) : keyMap = keyMap ?? TextInputKeyMap(),
       cursor = cursor ?? CursorModel(),
       styles = styles ?? defaultTextInputStyles() {
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
  bool _focused = false;
  int _pos = 0;
  int _offset = 0;
  int _offsetRight = 0;

  // Multi-line state
  int _scrollRow = 0; // First visible row (for vertical scrolling)
  int _desiredCol = -1; // Sticky column for up/down navigation (-1 = unset)
  List<_WrappedLine>? _wrappedLinesCache; // Cached wrapped line computation
  int _wrappedLinesCacheVersion = 0; // Invalidation counter
  int _wrappedLinesCacheWidth = -1; // Width used for last cache computation
  int _valueVersion = 0; // Bumped on every value mutation

  // Selection
  int? _selectionStart;
  int? _selectionEnd;

  // Double click tracking
  DateTime? _lastClickTime;
  int? _lastClickPos;

  // Suggestions
  List<List<String>> _suggestions = <List<String>>[];
  List<List<String>> _matchedSuggestions = <List<String>>[];
  int _currentSuggestionIndex = 0;

  // Rune sanitizer
  RuneSanitizer? _sanitizer;
  bool? _sanitizerMultiline;

  /// Gets the current value as a string.
  String get value => _value.join();

  /// Sets the value of the text input.
  set value(String s) {
    final runes = _san(uni.codePoints(s));
    final graphemes = uni.graphemes(String.fromCharCodes(runes)).toList();
    final err = _validate(graphemes);
    _setValueInternal(graphemes, err);
  }

  /// Sets the value of the text input (method form for API compatibility).
  ///
  /// This is equivalent to using the [value] setter and exists for parity with
  /// the upstream bubbletea Go library. Prefer using `model.value = s` in Dart.
  void setValue(String s) {
    value = s;
  }

  /// Gets the cursor position.
  int get position => _pos;

  /// Sets the cursor position.
  set position(int pos) {
    _pos = pos.clamp(0, _value.length);
    _handleOverflow();
  }

  /// Whether the input is focused.
  bool get focused => _focused;

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

  /// Gets the selection start position.
  int? get selectionStart => _selectionStart;

  /// Sets the selection start position.
  set selectionStart(int? value) {
    _selectionStart = value;
  }

  /// Gets the selection end position.
  int? get selectionEnd => _selectionEnd;

  /// Sets the selection end position.
  set selectionEnd(int? value) {
    _selectionEnd = value;
  }

  /// Focus the input.
  Cmd? focus() {
    _focused = true;
    final (newCursor, cmd) = cursor.focus();
    cursor = newCursor;
    _updateVirtualCursorStyle();
    return cmd;
  }

  /// Selects all text in the input.
  void selectAll() {
    _selectionStart = 0;
    _selectionEnd = _value.length;
    position = _value.length;
  }

  /// Returns the currently selected text.
  String getSelectedText() {
    if (_selectionStart == null || _selectionEnd == null) return '';
    final start = math.min(_selectionStart!, _selectionEnd!);
    final end = math.max(_selectionStart!, _selectionEnd!);
    if (start == end) return '';
    return _value.sublist(start, end).join();
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

  /// Returns a [Cursor] for rendering a real cursor in a TUI program.
  /// This requires that [useVirtualCursor] is set to false.
  Cursor? get terminalCursor {
    if (useVirtualCursor || !_focused) return null;

    final promptWidth = stringWidth(prompt);

    if (multiline) {
      final (cursorRow, cursorCol) = _cursorRowCol();
      // Compute display x: count cell widths of chars before cursor on this line.
      final lines = _getWrappedLines();
      final line = lines[cursorRow.clamp(0, lines.length - 1)];
      var xOffset = promptWidth;
      for (
        var i = line.start;
        i < line.start + cursorCol && i < line.end;
        i++
      ) {
        if (_value[i] != '\n') {
          xOffset += runeWidth(uni.firstCodePoint(_value[i]));
        }
      }
      final yOffset = cursorRow - _scrollRow;

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
    _value = <String>[];
    _invalidateWrappedLines();
    position = 0;
  }

  /// Move cursor to start.
  void cursorStart() {
    position = 0;
  }

  /// Move cursor to end.
  void cursorEnd() {
    position = _value.length;
  }

  List<int> _san(List<int> runes) {
    // Recreate sanitizer if multiline mode changed.
    if (_sanitizer == null || _sanitizerMultiline != multiline) {
      _sanitizerMultiline = multiline;
      if (multiline) {
        _sanitizer = createSanitizer(
          SanitizerOptions(tabReplacement: '    ', newlineReplacement: '\n'),
        );
      } else {
        _sanitizer = createSanitizer(
          SanitizerOptions(tabReplacement: ' ', newlineReplacement: ' '),
        );
      }
    }
    return _sanitizer!(runes);
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

  /// Returns (row, col) of `_pos` within the wrapped lines.
  ///
  /// `row` is the wrapped-line index, `col` is the offset within that line.
  (int row, int col) _cursorRowCol() {
    final lines = _getWrappedLines();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_pos >= line.start && _pos <= line.end) {
        // If this is not the last line and _pos == line.end, the cursor
        // belongs to the *start* of the next line (unless this line ends
        // at an explicit newline boundary, in which case it stays here).
        if (_pos == line.end && i + 1 < lines.length) {
          // Check if the next line continues from the same position
          // (soft wrap) vs starts after a newline.
          final next = lines[i + 1];
          if (next.start == line.end) {
            // Soft-wrap continuation — cursor is at start of next line.
            continue;
          }
        }
        return (i, _pos - line.start);
      }
    }
    // Fallback: cursor at end of last line.
    final last = lines.last;
    return (lines.length - 1, _pos - last.start);
  }

  /// Converts a (row, col) position to a flat index into `_value`.
  int _rowColToPos(int row, int col) {
    final lines = _getWrappedLines();
    final r = row.clamp(0, lines.length - 1);
    final line = lines[r];
    final lineLen = line.end - line.start;
    final c = col.clamp(0, lineLen);
    return line.start + c;
  }

  /// Returns the total number of wrapped lines.
  int get lineCount => multiline ? _getWrappedLines().length : 1;

  // ─────────────────────────────────────────────────────────────────────────
  // Multi-line: Navigation helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Inserts a newline character at the cursor position.
  void _insertNewline() {
    _deleteSelection();
    final head = _value.sublist(0, _pos);
    final tail = _value.sublist(_pos);
    _value = [...head, '\n', ...tail];
    _pos++;
    _invalidateWrappedLines();
    error = _validate(_value);
    _handleOverflow();
  }

  /// Computes the display column (in cells) of the cursor within a wrapped line.
  int _cursorDisplayCol() {
    final (_, col) = _cursorRowCol();
    final lines = _getWrappedLines();
    final (row, _) = _cursorRowCol();
    final line = lines[row];
    // Count display width of characters before cursor on this line.
    var displayCol = 0;
    for (var i = line.start; i < line.start + col; i++) {
      displayCol += runeWidth(uni.firstCodePoint(_value[i]));
    }
    return displayCol;
  }

  /// Converts a display column (cells) to a character offset within a wrapped line.
  int _displayColToCharOffset(int targetRow, int displayCol) {
    final lines = _getWrappedLines();
    final r = targetRow.clamp(0, lines.length - 1);
    final line = lines[r];
    var cellCount = 0;
    var charOffset = 0;
    for (var i = line.start; i < line.end; i++) {
      final w = runeWidth(uni.firstCodePoint(_value[i]));
      if (cellCount + w > displayCol) break;
      cellCount += w;
      charOffset++;
    }
    return charOffset;
  }

  /// Moves cursor up one wrapped line, preserving the display column.
  void _lineUp() {
    final (row, _) = _cursorRowCol();
    if (row == 0) return; // Already at top.

    // Compute or use sticky display column.
    if (_desiredCol < 0) {
      _desiredCol = _cursorDisplayCol();
    }

    final targetCol = _displayColToCharOffset(row - 1, _desiredCol);
    position = _rowColToPos(row - 1, targetCol);
  }

  /// Moves cursor down one wrapped line, preserving the display column.
  void _lineDown() {
    final lines = _getWrappedLines();
    final (row, _) = _cursorRowCol();
    if (row >= lines.length - 1) return; // Already at bottom.

    // Compute or use sticky display column.
    if (_desiredCol < 0) {
      _desiredCol = _cursorDisplayCol();
    }

    final targetCol = _displayColToCharOffset(row + 1, _desiredCol);
    position = _rowColToPos(row + 1, targetCol);
  }

  /// Moves cursor to start of current wrapped line.
  void _cursorLineStart() {
    final (row, _) = _cursorRowCol();
    final lines = _getWrappedLines();
    position = lines[row].start;
  }

  /// Moves cursor to end of current wrapped line.
  void _cursorLineEnd() {
    final (row, _) = _cursorRowCol();
    final lines = _getWrappedLines();
    position = lines[row].end;
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

  void _setValueInternal(List<String> graphemes, String? err) {
    error = err;
    final empty = _value.isEmpty;

    if (charLimit > 0 && graphemes.length > charLimit) {
      _value = graphemes.sublist(0, charLimit);
    } else {
      _value = graphemes;
    }
    _invalidateWrappedLines();

    if ((position == 0 && empty) || position > _value.length) {
      position = _value.length;
    }
    _handleOverflow();
  }

  void _insertRunes(List<int> v) {
    final pasteRunes = _san(v);
    final paste = uni.graphemes(String.fromCharCodes(pasteRunes)).toList();

    int availSpace;
    if (charLimit > 0) {
      availSpace = charLimit - _value.length;
      if (availSpace <= 0) return;

      if (availSpace < paste.length) {
        _insertLimited(paste.sublist(0, availSpace));
        return;
      }
    }

    _insertLimited(paste);
  }

  void _insertLimited(List<String> paste) {
    final head = _value.sublist(0, _pos);
    final tail = _value.sublist(_pos);

    final newValue = [...head, ...paste, ...tail];
    _pos += paste.length;

    final err = _validate(newValue);
    _setValueInternal(newValue, err);
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
        return;
      }

      final (cursorRow, _) = _cursorRowCol();

      // Ensure cursor row is visible within the scroll window.
      if (cursorRow < _scrollRow) {
        _scrollRow = cursorRow;
      } else if (cursorRow >= _scrollRow + maxHeight) {
        _scrollRow = cursorRow - maxHeight + 1;
      }

      // Clamp scrollRow to valid range.
      final totalLines = _getWrappedLines().length;
      final maxScroll = math.max(0, totalLines - maxHeight);
      _scrollRow = _scrollRow.clamp(0, maxScroll);
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

  bool _deleteSelection() {
    if (_selectionStart == null || _selectionEnd == null) return false;
    final start = math.min(_selectionStart!, _selectionEnd!);
    final end = math.max(_selectionStart!, _selectionEnd!);
    if (start == end) {
      _selectionStart = null;
      _selectionEnd = null;
      return false;
    }
    _value.removeRange(start, end);
    _invalidateWrappedLines();
    position = start;
    _selectionStart = null;
    _selectionEnd = null;
    error = _validate(_value);
    return true;
  }

  void _deleteBeforeCursor() {
    _value = _value.sublist(_pos);
    _invalidateWrappedLines();
    error = _validate(_value);
    _offset = 0;
    position = 0;
  }

  void _deleteAfterCursor() {
    _value = _value.sublist(0, _pos);
    _invalidateWrappedLines();
    error = _validate(_value);
    position = _value.length;
  }

  void _deleteWordBackward() {
    if (_pos == 0 || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _deleteBeforeCursor();
      return;
    }

    var i = _pos - 1;
    while (i >= 0 && _isWhitespace(_value[i])) {
      i--;
    }
    while (i >= 0 && !_isWhitespace(_value[i])) {
      i--;
    }
    final start = (i + 1).clamp(0, _pos);

    _value = [..._value.sublist(0, start), ..._value.sublist(_pos)];
    _invalidateWrappedLines();
    error = _validate(_value);
    position = start;
  }

  void _deleteWordForward() {
    if (_pos >= _value.length || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _deleteAfterCursor();
      return;
    }

    var i = _pos;
    while (i < _value.length && _isWhitespace(_value[i])) {
      i++;
    }
    while (i < _value.length && !_isWhitespace(_value[i])) {
      i++;
    }

    _value = [..._value.sublist(0, _pos), ..._value.sublist(i)];
    _invalidateWrappedLines();
    error = _validate(_value);
    _handleOverflow();
  }

  void _wordBackward() {
    if (_pos == 0 || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      cursorStart();
      return;
    }

    var i = _pos - 1;
    while (i >= 0 && _isWhitespace(_value[i])) {
      i--;
    }
    while (i >= 0 && !_isWhitespace(_value[i])) {
      i--;
    }
    position = (i + 1).clamp(0, _value.length);
  }

  void _wordForward() {
    if (_pos >= _value.length || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      cursorEnd();
      return;
    }

    var i = _pos;
    while (i < _value.length && _isWhitespace(_value[i])) {
      i++;
    }
    while (i < _value.length && !_isWhitespace(_value[i])) {
      i++;
    }
    position = i;
  }

  (int, int) _findWordAt(int x) {
    if (_value.isEmpty) return (0, 0);
    final pos = x.clamp(0, _value.length - 1);

    if (_isWhitespace(_value[pos])) {
      var start = pos;
      while (start > 0 && _isWhitespace(_value[start - 1])) {
        start--;
      }
      var end = pos;
      while (end < _value.length && _isWhitespace(_value[end])) {
        end++;
      }
      return (start, end);
    } else {
      var start = pos;
      while (start > 0 && !_isWhitespace(_value[start - 1])) {
        start--;
      }
      var end = pos;
      while (end < _value.length && !_isWhitespace(_value[end])) {
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
    final oldPos = _pos;
    final cmds = <Cmd>[];

    if (msg is MouseMsg) {
      if (multiline) {
        return _handleMultilineMouse(msg);
      }
      if (msg.y != 0) {
        if (msg.action == MouseAction.press && msg.button == MouseButton.left) {
          _selectionStart = null;
          _selectionEnd = null;
          _focused = false;
        }
        return (this, null);
      }
      final promptWidth = stringWidth(prompt);
      final localX = msg.x - promptWidth;
      final visibleValue = _value.sublist(_offset, _offsetRight);
      final idxInVisible = layout.localCellXToGraphemeIndex(
        visibleValue.join(),
        localX,
      );
      final x = _offset + idxInVisible;

      if (msg.action == MouseAction.press && msg.button == MouseButton.left) {
        _focused = true;
        final now = DateTime.now();
        if (_lastClickTime != null &&
            now.difference(_lastClickTime!) <
                const Duration(milliseconds: 500) &&
            _lastClickPos == x) {
          // Double click: select word
          final (start, end) = _findWordAt(x);
          _selectionStart = start;
          _selectionEnd = end;
          _pos = end;
          _lastClickTime = now;
          _lastClickPos = x;
        } else {
          position = x;
          _selectionStart = _pos;
          _selectionEnd = _pos;
          _lastClickTime = now;
          _lastClickPos = x;
        }
      } else if (msg.action == MouseAction.motion &&
          msg.button == MouseButton.left) {
        position = x;
        _selectionEnd = _pos;
      } else if (msg.action == MouseAction.release) {
        if (_selectionStart == _selectionEnd) {
          _selectionStart = null;
          _selectionEnd = null;
        }
      }
      return (this, null);
    }

    if (!_focused) {
      return (this, null);
    }

    // Check for suggestion acceptance first
    if (msg is KeyMsg && keyMatches(msg.key, [keyMap.acceptSuggestion])) {
      if (_canAcceptSuggestion()) {
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
          return (this, Cmd.setClipboard(selected));
        }
      }

      if (keyMatches(msg.key, [keyMap.cut])) {
        final selected = getSelectedText();
        if (selected.isNotEmpty) {
          _deleteSelection();
          return (this, Cmd.setClipboard(selected));
        }
      }

      if (keyMatches(msg.key, [keyMap.selectAll])) {
        _selectionStart = 0;
        _selectionEnd = _value.length;
        position = _value.length;
        return (this, null);
      }

      // Multi-line: newline insertion (Enter / Shift+Enter)
      if (multiline && keyMatches(msg.key, [keyMap.newline])) {
        _deleteSelection();
        _resetDesiredCol();
        _insertNewline();
        _updateSuggestions();
        _handleOverflow();
        return (this, null);
      }

      if (msg.key.type == KeyType.space) {
        _resetDesiredCol();
        _insertRunes([0x20]);
        return (this, null);
      }

      if (keyMatches(msg.key, [keyMap.deleteWordBackward])) {
        _resetDesiredCol();
        if (!_deleteSelection()) {
          _deleteWordBackward();
        }
      } else if (keyMatches(msg.key, [keyMap.deleteCharacterBackward])) {
        _resetDesiredCol();
        if (!_deleteSelection()) {
          error = null;
          if (_value.isNotEmpty && _pos > 0) {
            _value = [
              ..._value.sublist(0, math.max(0, _pos - 1)),
              ..._value.sublist(_pos),
            ];
            _invalidateWrappedLines();
            error = _validate(_value);
            if (_pos > 0) position = _pos - 1;
          }
        }
      } else if (keyMatches(msg.key, [keyMap.wordBackward])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        _wordBackward();
      } else if (keyMatches(msg.key, [keyMap.selectWordBackward])) {
        _resetDesiredCol();
        _selectionStart ??= _pos;
        _wordBackward();
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.characterBackward])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        if (_pos > 0) position = _pos - 1;
      } else if (keyMatches(msg.key, [keyMap.selectCharacterBackward])) {
        _resetDesiredCol();
        _selectionStart ??= _pos;
        if (_pos > 0) position = _pos - 1;
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.wordForward])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        _wordForward();
      } else if (keyMatches(msg.key, [keyMap.selectWordForward])) {
        _resetDesiredCol();
        _selectionStart ??= _pos;
        _wordForward();
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.characterForward])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        if (_pos < _value.length) position = _pos + 1;
      } else if (keyMatches(msg.key, [keyMap.selectCharacterForward])) {
        _resetDesiredCol();
        _selectionStart ??= _pos;
        if (_pos < _value.length) position = _pos + 1;
        _selectionEnd = _pos;
      } else if (multiline && keyMatches(msg.key, [keyMap.documentStart])) {
        // Multi-line: Ctrl+Home — go to document start
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        cursorStart();
      } else if (multiline && keyMatches(msg.key, [keyMap.documentEnd])) {
        // Multi-line: Ctrl+End — go to document end
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        cursorEnd();
      } else if (keyMatches(msg.key, [keyMap.lineStart])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        if (multiline) {
          _cursorLineStart();
        } else {
          cursorStart();
        }
      } else if (keyMatches(msg.key, [keyMap.selectLineStart])) {
        _resetDesiredCol();
        _selectionStart ??= _pos;
        if (multiline) {
          _cursorLineStart();
        } else {
          cursorStart();
        }
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.deleteCharacterForward])) {
        _resetDesiredCol();
        if (!_deleteSelection()) {
          if (_value.isNotEmpty && _pos < _value.length) {
            _value = [..._value.sublist(0, _pos), ..._value.sublist(_pos + 1)];
            _invalidateWrappedLines();
            error = _validate(_value);
          }
        }
      } else if (keyMatches(msg.key, [keyMap.lineEnd])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        if (multiline) {
          _cursorLineEnd();
        } else {
          cursorEnd();
        }
      } else if (keyMatches(msg.key, [keyMap.selectLineEnd])) {
        _resetDesiredCol();
        _selectionStart ??= _pos;
        if (multiline) {
          _cursorLineEnd();
        } else {
          cursorEnd();
        }
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.deleteAfterCursor])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        _deleteAfterCursor();
      } else if (keyMatches(msg.key, [keyMap.deleteBeforeCursor])) {
        _resetDesiredCol();
        _selectionStart = null;
        _selectionEnd = null;
        _deleteBeforeCursor();
      } else if (keyMatches(msg.key, [keyMap.paste])) {
        _resetDesiredCol();
        _deleteSelection();
        // Return paste command - caller handles clipboard
        return (this, _pasteCmd());
      } else if (keyMatches(msg.key, [keyMap.deleteWordForward])) {
        _resetDesiredCol();
        if (!_deleteSelection()) {
          _deleteWordForward();
        }
      } else if (multiline && keyMatches(msg.key, [keyMap.lineUp])) {
        // Multi-line: Up arrow — move cursor up one line
        _selectionStart = null;
        _selectionEnd = null;
        _lineUp();
      } else if (multiline && keyMatches(msg.key, [keyMap.lineDown])) {
        // Multi-line: Down arrow — move cursor down one line
        _selectionStart = null;
        _selectionEnd = null;
        _lineDown();
      } else if (keyMatches(msg.key, [keyMap.nextSuggestion])) {
        _nextSuggestion();
      } else if (keyMatches(msg.key, [keyMap.prevSuggestion])) {
        _previousSuggestion();
      } else if (msg.key.runes.isNotEmpty && !msg.key.ctrl && !msg.key.alt) {
        // Regular character input
        _resetDesiredCol();
        _deleteSelection();
        _insertRunes(msg.key.runes);
      }

      _updateSuggestions();
    } else if (msg is PasteMsg) {
      _insertRunes(uni.codePoints(msg.content));
    } else if (msg is PasteErrorMsg) {
      error = msg.error.toString();
    }

    // Update cursor
    final (newCursor, cursorCmd) = cursor.update(msg);
    cursor = newCursor;
    if (cursorCmd != null) cmds.add(cursorCmd);

    // Reset blink if position changed - use focus() to restart blink
    if (oldPos != _pos && cursor.mode == CursorMode.blink) {
      final (refocusedCursor, blinkCmd) = cursor.focus();
      cursor = refocusedCursor;
      if (blinkCmd != null) cmds.add(blinkCmd);
    }

    _handleOverflow();
    return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
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
    String styleText(String s) => styles.text.inline(true).render(s);

    final visibleValue = _value.sublist(_offset, _offsetRight);
    final pos = math.max(0, _pos - _offset);

    // Selection range in visible space
    int? selStart, selEnd;
    if (_selectionStart != null && _selectionEnd != null) {
      final start = math.min(_selectionStart!, _selectionEnd!);
      final end = math.max(_selectionStart!, _selectionEnd!);

      selStart = math.max(0, start - _offset);
      selEnd = math.min(visibleValue.length, end - _offset);

      if (selStart >= visibleValue.length || selEnd <= 0) {
        selStart = null;
        selEnd = null;
      }
    }

    var v = '';
    final selectionStyle = styles.selection;

    for (var i = 0; i < visibleValue.length; i++) {
      final char = _echoTransform(visibleValue[i]);
      final isSelected = selStart != null && i >= selStart && i < selEnd!;

      if (i == pos) {
        cursor = cursor.setChar(char);
        var cv = cursor.view();
        if (isSelected) {
          cv = selectionStyle.render(cv);
        }
        v += cv;
      } else {
        final rendered = styleText(char);
        v += isSelected ? selectionStyle.render(rendered) : rendered;
      }
    }

    if (pos >= visibleValue.length) {
      if (_focused && _canAcceptSuggestion()) {
        final suggestion = _matchedSuggestions[_currentSuggestionIndex];
        if (_value.length < suggestion.length) {
          cursor = cursor.setChar(_echoTransform(suggestion[_value.length]));
          v += cursor.view();
          v += _completionView(1);
        } else {
          cursor = cursor.setChar(' ');
          v += cursor.view();
        }
      } else {
        cursor = cursor.setChar(' ');
        v += cursor.view();
      }
    }

    // Padding for fixed width
    final valWidth = stringWidth(visibleValue.join());
    if (width > 0 && valWidth <= width) {
      var padding = math.max(0, width - valWidth);
      if (valWidth + padding <= width && pos < visibleValue.length) {
        padding++;
      }
      v += _renderPadding(styles.text, styles.prompt, padding);
    }

    final styledPrompt = styles.prompt.render(prompt);
    final content = '$styledPrompt$v';

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
    final lines = _getWrappedLines();
    final visibleHeight = maxHeight > 0 ? maxHeight : lines.length;
    final row = msg.y + _scrollRow;
    final promptWidth = stringWidth(prompt);
    final localX = msg.x - promptWidth;

    // Click outside visible area — unfocus.
    if (msg.y < 0 || msg.y >= visibleHeight) {
      if (msg.action == MouseAction.press && msg.button == MouseButton.left) {
        _selectionStart = null;
        _selectionEnd = null;
        _focused = false;
      }
      return (this, null);
    }

    // Clamp row to valid range.
    final clampedRow = row.clamp(0, lines.length - 1);
    final line = lines[clampedRow];

    // Convert cell x to character offset within this line.
    final lineText = _value
        .sublist(line.start, line.end)
        .join()
        .replaceAll('\n', '');
    final charOffset = layout.localCellXToGraphemeIndex(lineText, localX);
    // Map back to flat position.
    // Count non-newline chars to find actual position.
    var flatPos = line.start;
    var counted = 0;
    for (var i = line.start; i < line.end && counted < charOffset; i++) {
      if (_value[i] != '\n') counted++;
      flatPos = i + 1;
    }
    flatPos = flatPos.clamp(0, _value.length);

    if (msg.action == MouseAction.press && msg.button == MouseButton.left) {
      _focused = true;
      _resetDesiredCol();
      final now = DateTime.now();
      if (_lastClickTime != null &&
          now.difference(_lastClickTime!) < const Duration(milliseconds: 500) &&
          _lastClickPos == flatPos) {
        // Double click: select word
        final (start, end) = _findWordAt(flatPos);
        _selectionStart = start;
        _selectionEnd = end;
        _pos = end;
        _lastClickTime = now;
        _lastClickPos = flatPos;
      } else {
        position = flatPos;
        _selectionStart = _pos;
        _selectionEnd = _pos;
        _lastClickTime = now;
        _lastClickPos = flatPos;
      }
    } else if (msg.action == MouseAction.motion &&
        msg.button == MouseButton.left) {
      _resetDesiredCol();
      position = flatPos;
      _selectionEnd = _pos;
    } else if (msg.action == MouseAction.release) {
      if (_selectionStart == _selectionEnd) {
        _selectionStart = null;
        _selectionEnd = null;
      }
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
    String styleText(String s) => styles.text.inline(true).render(s);
    final selectionStyle = styles.selection;
    final lines = _getWrappedLines();
    final (cursorRow, cursorCol) = _cursorRowCol();

    // Determine visible row range.
    final totalLines = lines.length;
    int firstVisible = _scrollRow;
    int lastVisible; // exclusive
    if (maxHeight > 0) {
      lastVisible = math.min(firstVisible + maxHeight, totalLines);
    } else {
      firstVisible = 0;
      lastVisible = totalLines;
    }

    // Compute absolute selection range.
    int? absSelStart, absSelEnd;
    if (_selectionStart != null && _selectionEnd != null) {
      absSelStart = math.min(_selectionStart!, _selectionEnd!);
      absSelEnd = math.max(_selectionStart!, _selectionEnd!);
      if (absSelStart == absSelEnd) {
        absSelStart = null;
        absSelEnd = null;
      }
    }

    final rowStrings = <String>[];

    for (var row = firstVisible; row < lastVisible; row++) {
      final line = lines[row];
      final linePrompt = (row == 0) ? prompt : ' ' * stringWidth(prompt);
      var rowStr = '';

      for (var i = line.start; i < line.end; i++) {
        // Skip newline characters — they are line boundaries, not displayed.
        if (_value[i] == '\n') continue;

        final char = _echoTransform(_value[i]);
        final isSelected =
            absSelStart != null && i >= absSelStart && i < absSelEnd!;
        final isCursorPos = row == cursorRow && (i - line.start) == cursorCol;

        if (isCursorPos) {
          cursor = cursor.setChar(char);
          var cv = cursor.view();
          if (isSelected) {
            cv = selectionStyle.render(cv);
          }
          rowStr += cv;
        } else {
          final rendered = styleText(char);
          rowStr += isSelected ? selectionStyle.render(rendered) : rendered;
        }
      }

      // If cursor is at end of this line (past last char).
      final cursorAtLineEnd =
          row == cursorRow && cursorCol == line.end - line.start;
      if (cursorAtLineEnd) {
        cursor = cursor.setChar(' ');
        rowStr += cursor.view();
      }

      // Pad line to width.
      if (width > 0) {
        final lineContentWidth = _lineDisplayWidth(line);
        final cursorExtra = cursorAtLineEnd ? 1 : 0;
        final padAmount = math.max(0, width - lineContentWidth - cursorExtra);
        if (padAmount > 0) {
          rowStr += _renderPadding(styles.text, styles.prompt, padAmount);
        }
      }

      rowStrings.add(styles.prompt.render(linePrompt) + rowStr);
    }

    final content = rowStrings.join('\n');

    if (useVirtualCursor || !_focused) {
      return content;
    }
    return View(content: content, cursor: terminalCursor);
  }

  /// Returns the display width (cells) of a wrapped line's content,
  /// excluding newline characters.
  int _lineDisplayWidth(_WrappedLine line) {
    var w = 0;
    for (var i = line.start; i < line.end; i++) {
      if (_value[i] == '\n') continue;
      w += runeWidth(uni.firstCodePoint(_value[i]));
    }
    return w;
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
