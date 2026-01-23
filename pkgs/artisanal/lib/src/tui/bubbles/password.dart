import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import '../../style/style.dart';
import '../../style/color.dart';
import '../../unicode/grapheme.dart' as uni;
import 'key_binding.dart';
import 'cursor.dart';

/// Message sent when password input is submitted.
class PasswordSubmittedMsg extends Msg {
  const PasswordSubmittedMsg(this.password);

  /// The submitted password.
  final String password;

  @override
  String toString() => 'PasswordSubmittedMsg(****)';
}

/// Message sent when password input is cancelled.
class PasswordCancelledMsg extends Msg {
  const PasswordCancelledMsg();

  @override
  String toString() => 'PasswordCancelledMsg()';
}

/// Echo mode for password display.
enum PasswordEchoMode {
  /// Show nothing (completely hidden).
  none,

  /// Show mask characters (e.g., asterisks).
  mask,

  /// Show a fixed number of mask characters regardless of length.
  fixed,
}

/// Key bindings for the password component.
class PasswordKeyMap implements KeyMap {
  PasswordKeyMap({
    KeyBinding? submit,
    KeyBinding? cancel,
    KeyBinding? deleteBackward,
    KeyBinding? deleteForward,
    KeyBinding? deleteAll,
    KeyBinding? cursorLeft,
    KeyBinding? cursorRight,
    KeyBinding? cursorStart,
    KeyBinding? cursorEnd,
  }) : submit =
           submit ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: '↵', desc: 'submit'),
           ),
       cancel =
           cancel ??
           KeyBinding(
             keys: ['esc'],
             help: Help(key: 'esc', desc: 'cancel'),
           ),
       deleteBackward =
           deleteBackward ??
           KeyBinding(
             keys: ['backspace', 'ctrl+h'],
             help: Help(key: '⌫', desc: 'delete'),
           ),
       deleteForward =
           deleteForward ??
           KeyBinding(
             keys: ['delete', 'ctrl+d'],
             help: Help(key: 'del', desc: 'delete forward'),
           ),
       deleteAll =
           deleteAll ??
           KeyBinding(
             keys: ['ctrl+u'],
             help: Help(key: '^u', desc: 'clear'),
           ),
       cursorLeft =
           cursorLeft ??
           KeyBinding(
             keys: ['left', 'ctrl+b'],
             help: Help(key: '←', desc: 'left'),
           ),
       cursorRight =
           cursorRight ??
           KeyBinding(
             keys: ['right', 'ctrl+f'],
             help: Help(key: '→', desc: 'right'),
           ),
       cursorStart =
           cursorStart ??
           KeyBinding(
             keys: ['home', 'ctrl+a'],
             help: Help(key: 'home', desc: 'start'),
           ),
       cursorEnd =
           cursorEnd ??
           KeyBinding(
             keys: ['end', 'ctrl+e'],
             help: Help(key: 'end', desc: 'end'),
           );

  /// Submit the password.
  final KeyBinding submit;

  /// Cancel input.
  final KeyBinding cancel;

  /// Delete character before cursor.
  final KeyBinding deleteBackward;

  /// Delete character after cursor.
  final KeyBinding deleteForward;

  /// Delete all characters.
  final KeyBinding deleteAll;

  /// Move cursor left.
  final KeyBinding cursorLeft;

  /// Move cursor right.
  final KeyBinding cursorRight;

  /// Move cursor to start.
  final KeyBinding cursorStart;

  /// Move cursor to end.
  final KeyBinding cursorEnd;

  @override
  List<KeyBinding> shortHelp() {
    return [submit, cancel];
  }

  @override
  List<List<KeyBinding>> fullHelp() {
    return [
      [submit, cancel],
      [deleteBackward, deleteAll],
    ];
  }
}

/// Styles for the password component.
class PasswordStyles {
  PasswordStyles({
    Style? prompt,
    Style? text,
    Style? cursor,
    Style? dimmed,
    Style? error,
  }) : prompt = prompt ?? Style().bold().foreground(AnsiColor(11)),
       text = text ?? Style(),
       cursor = cursor ?? Style(),
       dimmed = dimmed ?? Style().foreground(AnsiColor(8)),
       error = error ?? Style().foreground(AnsiColor(9));

  /// Style for the prompt.
  final Style prompt;

  /// Style for the masked text.
  final Style text;

  /// Style for the cursor.
  final Style cursor;

  /// Style for dimmed elements (placeholder, help).
  final Style dimmed;

  /// Style for error messages.
  final Style error;

  /// Creates default styles.
  factory PasswordStyles.defaults() => PasswordStyles();
}

/// A password input component following the Model architecture.
///
/// Displays a password prompt with masked input.
///
/// ## Example
///
/// ```dart
/// final password = PasswordModel(
///   prompt: 'Enter password: ',
/// );
///
/// // In your update function:
/// switch (msg) {
///   case PasswordSubmittedMsg(:final password):
///     print('Password entered');
///     return (this, Cmd.quit());
///   case PasswordCancelledMsg():
///     return (this, Cmd.quit());
/// }
/// ```
class PasswordModel extends ViewComponent {
  /// Creates a new password model.
  PasswordModel({
    this.prompt = 'Password: ',
    this.placeholder = '',
    this.echoMode = PasswordEchoMode.mask,
    this.maskChar = '*',
    this.fixedMaskLength = 6,
    this.minLength = 0,
    this.maxLength = 0,
    this.showHelp = false,
    this.validate,
    PasswordKeyMap? keyMap,
    PasswordStyles? styles,
    CursorModel? cursor,
  }) : keyMap = keyMap ?? PasswordKeyMap(),
       styles = styles ?? PasswordStyles.defaults(),
       cursor = cursor ?? CursorModel();

  /// The prompt to display.
  final String prompt;

  /// Placeholder text when empty.
  final String placeholder;

  /// How to display the password.
  final PasswordEchoMode echoMode;

  /// Character used to mask input.
  final String maskChar;

  /// Fixed length for mask display (when echoMode is fixed).
  final int fixedMaskLength;

  /// Minimum password length (0 = no minimum).
  final int minLength;

  /// Maximum password length (0 = no maximum).
  final int maxLength;

  /// Whether to show help text.
  final bool showHelp;

  /// Validation function.
  final String? Function(String)? validate;

  /// Key bindings.
  final PasswordKeyMap keyMap;

  /// Styles.
  final PasswordStyles styles;

  /// Cursor model.
  CursorModel cursor;

  // Internal state
  List<String> _value = [];
  int _pos = 0;
  bool _focused = true;
  String? _error;

  /// Gets the current password value.
  String get value => _value.join();

  /// Gets the cursor position.
  int get position => _pos;

  /// Gets whether the input is focused.
  bool get focused => _focused;

  /// Gets the current error message.
  String? get error => _error;

  /// Gets the password length.
  int get length => _value.length;

  /// Focus the input.
  Cmd? focus() {
    _focused = true;
    final (newCursor, cmd) = cursor.focus();
    cursor = newCursor;
    return cmd;
  }

  /// Blur the input.
  void blur() {
    _focused = false;
    cursor = cursor.blur();
  }

  /// Reset the input.
  void reset() {
    _value = [];
    _pos = 0;
    _error = null;
  }

  /// Set the cursor position.
  void _setCursorPosition(int pos) {
    _pos = pos.clamp(0, _value.length);
  }

  /// Insert user input at current position, split by grapheme cluster.
  void _insertRunes(List<int> runes) {
    if (runes.isEmpty) return;

    final text = String.fromCharCodes(runes);
    final clusters = <String>[];
    for (final g in uni.graphemes(text)) {
      final cp = uni.firstCodePoint(g);
      if (cp == 0xFFFD) continue;
      if (cp < 32 || cp == 127) continue;
      clusters.add(g);
    }
    if (clusters.isEmpty) return;

    if (maxLength > 0 && _value.length + clusters.length > maxLength) {
      final remaining = maxLength - _value.length;
      if (remaining <= 0) return;
      clusters.removeRange(remaining, clusters.length);
    }

    _value = [..._value.sublist(0, _pos), ...clusters, ..._value.sublist(_pos)];
    _pos += clusters.length;
    _error = null;
  }

  /// Delete character before cursor.
  void _deleteBackward() {
    if (_pos > 0) {
      _value = [..._value.sublist(0, _pos - 1), ..._value.sublist(_pos)];
      _pos--;
      _error = null;
    }
  }

  /// Delete character after cursor.
  void _deleteForward() {
    if (_pos < _value.length) {
      _value = [..._value.sublist(0, _pos), ..._value.sublist(_pos + 1)];
      _error = null;
    }
  }

  /// Delete all characters.
  void _deleteAll() {
    _value = [];
    _pos = 0;
    _error = null;
  }

  /// Validate the password.
  String? _validate() {
    if (minLength > 0 && _value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (validate != null) {
      return validate!(value);
    }
    return null;
  }

  /// Get the masked display text.
  String _getMaskedText() {
    if (_value.isEmpty) return '';

    switch (echoMode) {
      case PasswordEchoMode.none:
        return '';
      case PasswordEchoMode.mask:
        return maskChar * _value.length;
      case PasswordEchoMode.fixed:
        return maskChar * fixedMaskLength;
    }
  }

  @override
  Cmd? init() => focus();

  @override
  (PasswordModel, Cmd?) update(Msg msg) {
    if (!_focused) {
      return (this, null);
    }

    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      final key = msg.key;

      // Check for Ctrl+C
      if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63) {
        return (this, Cmd.message(const PasswordCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.cancel])) {
        return (this, Cmd.message(const PasswordCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.submit])) {
        final validationError = _validate();
        if (validationError != null) {
          _error = validationError;
          return (this, null);
        }
        return (this, Cmd.message(PasswordSubmittedMsg(value)));
      }

      if (keyMatches(key, [keyMap.deleteBackward])) {
        _deleteBackward();
      } else if (keyMatches(key, [keyMap.deleteForward])) {
        _deleteForward();
      } else if (keyMatches(key, [keyMap.deleteAll])) {
        _deleteAll();
      } else if (keyMatches(key, [keyMap.cursorLeft])) {
        _setCursorPosition(_pos - 1);
      } else if (keyMatches(key, [keyMap.cursorRight])) {
        _setCursorPosition(_pos + 1);
      } else if (keyMatches(key, [keyMap.cursorStart])) {
        _setCursorPosition(0);
      } else if (keyMatches(key, [keyMap.cursorEnd])) {
        _setCursorPosition(_value.length);
      } else if (key.runes.isNotEmpty) {
        // Regular character input
        _insertRunes(key.runes);
      }
    }

    // Update cursor
    final (newCursor, cursorCmd) = cursor.update(msg);
    cursor = newCursor;
    if (cursorCmd != null) cmds.add(cursorCmd);

    return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
  }

  @override
  String view() {
    final buffer = StringBuffer();

    // Prompt
    buffer.write(styles.prompt.render(prompt));

    // Value or placeholder
    if (_value.isEmpty && placeholder.isNotEmpty) {
      buffer.write(styles.dimmed.render(placeholder));
    } else {
      final maskedText = _getMaskedText();
      buffer.write(styles.text.render(maskedText));
    }

    // Cursor
    if (_focused && cursor.visible) {
      // The cursor is handled by the terminal, but we can show indicator
    }

    buffer.writeln();

    // Error message
    if (_error != null) {
      buffer.writeln(styles.error.render('  $_error'));
    }

    // Help
    if (showHelp) {
      final helpItems = keyMap.shortHelp();
      final helpText = helpItems
          .where((b) => b.help.hasContent)
          .map((b) => '${b.help.key} ${b.help.desc}')
          .join('  ');
      buffer.writeln(styles.dimmed.render(helpText));
    }

    return buffer.toString();
  }
}

/// A password confirmation component that asks for password twice.
///
/// ## Example
///
/// ```dart
/// final confirm = PasswordConfirmModel(
///   prompt: 'Enter password: ',
///   confirmPrompt: 'Confirm password: ',
/// );
/// ```
class PasswordConfirmModel extends ViewComponent {
  /// Creates a new password confirmation model.
  PasswordConfirmModel({
    this.prompt = 'Password: ',
    this.confirmPrompt = 'Confirm password: ',
    this.mismatchError = 'Passwords do not match',
    this.minLength = 0,
    this.maxLength = 0,
    this.validate,
    PasswordKeyMap? keyMap,
    PasswordStyles? styles,
  }) : keyMap = keyMap ?? PasswordKeyMap(),
       styles = styles ?? PasswordStyles.defaults() {
    _passwordInput = PasswordModel(
      prompt: prompt,
      minLength: minLength,
      maxLength: maxLength,
      validate: validate,
      keyMap: keyMap,
      styles: styles,
    );
    _confirmInput = PasswordModel(
      prompt: confirmPrompt,
      minLength: minLength,
      maxLength: maxLength,
      keyMap: keyMap,
      styles: styles,
    );
  }

  /// The prompt for the first password.
  final String prompt;

  /// The prompt for confirmation.
  final String confirmPrompt;

  /// Error message when passwords don't match.
  final String mismatchError;

  /// Minimum password length.
  final int minLength;

  /// Maximum password length.
  final int maxLength;

  /// Validation function.
  final String? Function(String)? validate;

  /// Key bindings.
  final PasswordKeyMap keyMap;

  /// Styles.
  final PasswordStyles styles;

  // Internal state
  late PasswordModel _passwordInput;
  late PasswordModel _confirmInput;
  bool _inConfirmPhase = false;
  String? _error;

  /// Gets whether we're in the confirmation phase.
  bool get inConfirmPhase => _inConfirmPhase;

  /// Gets the current error.
  String? get error => _error;

  @override
  Cmd? init() => _passwordInput.init();

  @override
  (PasswordConfirmModel, Cmd?) update(Msg msg) {
    if (msg is PasswordSubmittedMsg) {
      if (!_inConfirmPhase) {
        // First password entered, move to confirmation
        _inConfirmPhase = true;
        _error = null;
        return (this, _confirmInput.init());
      } else {
        // Confirmation entered, check match
        if (_passwordInput.value == _confirmInput.value) {
          return (
            this,
            Cmd.message(PasswordSubmittedMsg(_passwordInput.value)),
          );
        } else {
          _error = mismatchError;
          _confirmInput.reset();
          return (this, null);
        }
      }
    }

    if (msg is PasswordCancelledMsg) {
      if (_inConfirmPhase) {
        // Go back to first password
        _inConfirmPhase = false;
        _confirmInput.reset();
        _error = null;
        return (this, _passwordInput.focus());
      } else {
        return (this, Cmd.message(const PasswordCancelledMsg()));
      }
    }

    // Delegate to appropriate input
    if (_inConfirmPhase) {
      final (_, cmd) = _confirmInput.update(msg);
      return (this, cmd);
    } else {
      final (_, cmd) = _passwordInput.update(msg);
      return (this, cmd);
    }
  }

  @override
  String view() {
    final buffer = StringBuffer();

    if (!_inConfirmPhase) {
      buffer.write(_passwordInput.view());
    } else {
      // Show first password as completed
      buffer.write(styles.prompt.render(prompt));
      buffer.writeln(styles.dimmed.render('********'));

      // Show confirmation input
      buffer.write(_confirmInput.view());
    }

    // Error message
    if (_error != null) {
      buffer.writeln(styles.error.render('  $_error'));
    }

    return buffer.toString();
  }
}
