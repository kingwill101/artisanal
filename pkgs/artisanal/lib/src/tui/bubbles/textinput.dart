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

  @override
  List<KeyBinding> shortHelp() => [
    characterForward,
    characterBackward,
    deleteCharacterBackward,
  ];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [characterForward, characterBackward, wordForward, wordBackward],
    [lineStart, lineEnd],
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

/// Text input model for single-line text entry.
///
/// Features:
/// - Character and word navigation
/// - Delete operations (character, word, line)
/// - Echo modes (normal, password, none)
/// - Suggestions/autocomplete
/// - Horizontal scrolling for long text
/// - Validation
///
/// Example:
/// ```dart
/// final input = TextInputModel(
///   prompt: 'Name: ',
///   placeholder: 'Enter your name',
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
  int width;

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
    _sanitizer ??= createSanitizer(
      SanitizerOptions(tabReplacement: ' ', newlineReplacement: ' '),
    );
    return _sanitizer!(runes);
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
    position = start;
    _selectionStart = null;
    _selectionEnd = null;
    error = _validate(_value);
    return true;
  }

  void _deleteBeforeCursor() {
    _value = _value.sublist(_pos);
    error = _validate(_value);
    _offset = 0;
    position = 0;
  }

  void _deleteAfterCursor() {
    _value = _value.sublist(0, _pos);
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

      if (msg.key.type == KeyType.space) {
        _insertRunes([0x20]);
        return (this, null);
      }

      if (keyMatches(msg.key, [keyMap.deleteWordBackward])) {
        if (!_deleteSelection()) {
          _deleteWordBackward();
        }
      } else if (keyMatches(msg.key, [keyMap.deleteCharacterBackward])) {
        if (!_deleteSelection()) {
          error = null;
          if (_value.isNotEmpty && _pos > 0) {
            _value = [
              ..._value.sublist(0, math.max(0, _pos - 1)),
              ..._value.sublist(_pos),
            ];
            error = _validate(_value);
            if (_pos > 0) position = _pos - 1;
          }
        }
      } else if (keyMatches(msg.key, [keyMap.wordBackward])) {
        _selectionStart = null;
        _selectionEnd = null;
        _wordBackward();
      } else if (keyMatches(msg.key, [keyMap.selectWordBackward])) {
        _selectionStart ??= _pos;
        _wordBackward();
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.characterBackward])) {
        _selectionStart = null;
        _selectionEnd = null;
        if (_pos > 0) position = _pos - 1;
      } else if (keyMatches(msg.key, [keyMap.selectCharacterBackward])) {
        _selectionStart ??= _pos;
        if (_pos > 0) position = _pos - 1;
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.wordForward])) {
        _selectionStart = null;
        _selectionEnd = null;
        _wordForward();
      } else if (keyMatches(msg.key, [keyMap.selectWordForward])) {
        _selectionStart ??= _pos;
        _wordForward();
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.characterForward])) {
        _selectionStart = null;
        _selectionEnd = null;
        if (_pos < _value.length) position = _pos + 1;
      } else if (keyMatches(msg.key, [keyMap.selectCharacterForward])) {
        _selectionStart ??= _pos;
        if (_pos < _value.length) position = _pos + 1;
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.lineStart])) {
        _selectionStart = null;
        _selectionEnd = null;
        cursorStart();
      } else if (keyMatches(msg.key, [keyMap.selectLineStart])) {
        _selectionStart ??= _pos;
        cursorStart();
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.deleteCharacterForward])) {
        if (!_deleteSelection()) {
          if (_value.isNotEmpty && _pos < _value.length) {
            _value = [..._value.sublist(0, _pos), ..._value.sublist(_pos + 1)];
            error = _validate(_value);
          }
        }
      } else if (keyMatches(msg.key, [keyMap.lineEnd])) {
        _selectionStart = null;
        _selectionEnd = null;
        cursorEnd();
      } else if (keyMatches(msg.key, [keyMap.selectLineEnd])) {
        _selectionStart ??= _pos;
        cursorEnd();
        _selectionEnd = _pos;
      } else if (keyMatches(msg.key, [keyMap.deleteAfterCursor])) {
        _selectionStart = null;
        _selectionEnd = null;
        _deleteAfterCursor();
      } else if (keyMatches(msg.key, [keyMap.deleteBeforeCursor])) {
        _selectionStart = null;
        _selectionEnd = null;
        _deleteBeforeCursor();
      } else if (keyMatches(msg.key, [keyMap.paste])) {
        _deleteSelection();
        // Return paste command - caller handles clipboard
        return (this, _pasteCmd());
      } else if (keyMatches(msg.key, [keyMap.deleteWordForward])) {
        if (!_deleteSelection()) {
          _deleteWordForward();
        }
      } else if (keyMatches(msg.key, [keyMap.nextSuggestion])) {
        _nextSuggestion();
      } else if (keyMatches(msg.key, [keyMap.prevSuggestion])) {
        _previousSuggestion();
      } else if (msg.key.runes.isNotEmpty && !msg.key.ctrl && !msg.key.alt) {
        // Regular character input
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
    // Placeholder text
    if (_value.isEmpty && placeholder.isNotEmpty) {
      return _placeholderView();
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
