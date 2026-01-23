import '../cmd.dart';
import '../key.dart';
import '../component.dart';
import '../msg.dart';
import '../../style/style.dart';
import '../../style/color.dart';
import '../../unicode/grapheme.dart' as uni;
import 'key_binding.dart';

/// Message sent when confirmation is made.
class ConfirmResultMsg extends Msg {
  const ConfirmResultMsg(this.confirmed);

  /// Whether the user confirmed (true) or denied (false).
  final bool confirmed;

  @override
  String toString() => 'ConfirmResultMsg($confirmed)';
}

/// Message sent when confirmation is cancelled.
class ConfirmCancelledMsg extends Msg {
  const ConfirmCancelledMsg();

  @override
  String toString() => 'ConfirmCancelledMsg()';
}

/// Key bindings for the confirm component.
class ConfirmKeyMap implements KeyMap {
  ConfirmKeyMap({
    KeyBinding? yes,
    KeyBinding? no,
    KeyBinding? confirm,
    KeyBinding? cancel,
    KeyBinding? toggleLeft,
    KeyBinding? toggleRight,
  }) : yes =
           yes ??
           KeyBinding(
             keys: ['y', 'Y'],
             help: Help(key: 'y', desc: 'yes'),
           ),
       no =
           no ??
           KeyBinding(
             keys: ['n', 'N'],
             help: Help(key: 'n', desc: 'no'),
           ),
       confirm =
           confirm ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: '↵', desc: 'confirm'),
           ),
       cancel =
           cancel ??
           KeyBinding(
             keys: ['esc', 'ctrl+c'],
             help: Help(key: 'esc', desc: 'cancel'),
           ),
       toggleLeft =
           toggleLeft ??
           KeyBinding(
             keys: ['left', 'h'],
             help: Help(key: '←', desc: 'yes'),
           ),
       toggleRight =
           toggleRight ??
           KeyBinding(
             keys: ['right', 'l'],
             help: Help(key: '→', desc: 'no'),
           );

  /// Confirm with 'y'.
  final KeyBinding yes;

  /// Deny with 'n'.
  final KeyBinding no;

  /// Confirm current selection with Enter.
  final KeyBinding confirm;

  /// Cancel the confirmation.
  final KeyBinding cancel;

  /// Toggle selection left (to Yes).
  final KeyBinding toggleLeft;

  /// Toggle selection right (to No).
  final KeyBinding toggleRight;

  @override
  List<KeyBinding> shortHelp() {
    return [yes, no, confirm, cancel];
  }

  @override
  List<List<KeyBinding>> fullHelp() {
    return [
      [yes, no],
      [toggleLeft, toggleRight, confirm, cancel],
    ];
  }
}

/// Styles for the confirm component.
class ConfirmStyles {
  ConfirmStyles({
    Style? prompt,
    Style? activeChoice,
    Style? inactiveChoice,
    Style? hint,
    Style? dimmed,
    String? yesText,
    String? noText,
    String? separator,
  }) : prompt = prompt ?? Style().bold().foreground(AnsiColor(11)),
       activeChoice = activeChoice ?? Style().bold().foreground(AnsiColor(14)),
       inactiveChoice = inactiveChoice ?? Style().foreground(AnsiColor(8)),
       hint = hint ?? Style().foreground(AnsiColor(8)),
       dimmed = dimmed ?? Style().foreground(AnsiColor(8)),
       yesText = yesText ?? 'Yes',
       noText = noText ?? 'No',
       separator = separator ?? ' / ';

  /// Style for the prompt text.
  final Style prompt;

  /// Style for the active (selected) choice.
  final Style activeChoice;

  /// Style for the inactive choice.
  final Style inactiveChoice;

  /// Style for the hint text.
  final Style hint;

  /// Style for dimmed elements.
  final Style dimmed;

  /// Text for the "yes" option.
  final String yesText;

  /// Text for the "no" option.
  final String noText;

  /// Separator between yes and no options.
  final String separator;

  /// Creates default styles.
  factory ConfirmStyles.defaults() => ConfirmStyles();
}

/// Display mode for the confirm component.
enum ConfirmDisplayMode {
  /// Show as Yes/No toggle: "Delete file? [Yes] / No"
  toggle,

  /// Show as hint: "Delete file? (y/n)"
  hint,

  /// Show as inline options: "Delete file? (Y)es / (N)o"
  inline,
}

/// A confirmation (yes/no) component following the Model architecture.
///
/// Displays a prompt and allows the user to confirm or deny.
///
/// ## Example
///
/// ```dart
/// final confirm = ConfirmModel(
///   prompt: 'Delete this file?',
///   defaultValue: false,
/// );
///
/// // In your update function:
/// switch (msg) {
///   case ConfirmResultMsg(:final confirmed):
///     if (confirmed) {
///       deleteFile();
///     }
///     return (this, Cmd.quit());
///   case ConfirmCancelledMsg():
///     return (this, Cmd.quit());
/// }
/// ```
class ConfirmModel extends ViewComponent {
  /// Creates a new confirm model.
  ConfirmModel({
    required this.prompt,
    this.defaultValue = true,
    this.displayMode = ConfirmDisplayMode.toggle,
    this.showHelp = false,
    ConfirmKeyMap? keyMap,
    ConfirmStyles? styles,
  }) : keyMap = keyMap ?? ConfirmKeyMap(),
       styles = styles ?? ConfirmStyles.defaults(),
       _value = defaultValue;

  /// The prompt to display.
  final String prompt;

  /// The default value (true = yes, false = no).
  final bool defaultValue;

  /// How to display the options.
  final ConfirmDisplayMode displayMode;

  /// Whether to show help text.
  final bool showHelp;

  /// Key bindings.
  final ConfirmKeyMap keyMap;

  /// Styles.
  final ConfirmStyles styles;

  // Internal state
  bool _value;

  /// Gets the current selected value.
  bool get value => _value;

  /// Sets the current value.
  void setValue(bool value) {
    _value = value;
  }

  /// Toggle the current value.
  void toggle() {
    _value = !_value;
  }

  @override
  Cmd? init() => null;

  @override
  (ConfirmModel, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      final key = msg.key;

      if (keyMatches(key, [keyMap.cancel])) {
        return (this, Cmd.message(const ConfirmCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.yes])) {
        _value = true;
        return (this, Cmd.message(const ConfirmResultMsg(true)));
      }

      if (keyMatches(key, [keyMap.no])) {
        _value = false;
        return (this, Cmd.message(const ConfirmResultMsg(false)));
      }

      if (keyMatches(key, [keyMap.confirm])) {
        return (this, Cmd.message(ConfirmResultMsg(_value)));
      }

      if (keyMatches(key, [keyMap.toggleLeft])) {
        _value = true;
        return (this, null);
      }

      if (keyMatches(key, [keyMap.toggleRight])) {
        _value = false;
        return (this, null);
      }
    }

    return (this, null);
  }

  @override
  String view() {
    final buffer = StringBuffer();

    // Prompt
    buffer.write(styles.prompt.render(prompt));
    buffer.write(' ');

    // Options based on display mode
    switch (displayMode) {
      case ConfirmDisplayMode.toggle:
        _renderToggleMode(buffer);
      case ConfirmDisplayMode.hint:
        _renderHintMode(buffer);
      case ConfirmDisplayMode.inline:
        _renderInlineMode(buffer);
    }

    buffer.writeln();

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

  /// Renders toggle mode: [Yes] / No or Yes / [No]
  void _renderToggleMode(StringBuffer buffer) {
    if (_value) {
      buffer.write('[');
      buffer.write(styles.activeChoice.render(styles.yesText));
      buffer.write(']');
      buffer.write(styles.separator);
      buffer.write(styles.inactiveChoice.render(styles.noText));
    } else {
      buffer.write(styles.inactiveChoice.render(styles.yesText));
      buffer.write(styles.separator);
      buffer.write('[');
      buffer.write(styles.activeChoice.render(styles.noText));
      buffer.write(']');
    }
  }

  /// Renders hint mode: (y/n) or (Y/n) or (y/N)
  void _renderHintMode(StringBuffer buffer) {
    final yChar = _value ? 'Y' : 'y';
    final nChar = _value ? 'n' : 'N';
    buffer.write(styles.hint.render('($yChar/$nChar)'));
  }

  /// Renders inline mode: (Y)es / (N)o
  void _renderInlineMode(StringBuffer buffer) {
    final (yesFirst, yesRest) = _splitFirstGrapheme(
      styles.yesText,
      fallback: 'Y',
    );
    final (noFirst, noRest) = _splitFirstGrapheme(styles.noText, fallback: 'N');

    if (_value) {
      buffer.write(styles.activeChoice.render('($yesFirst)$yesRest'));
      buffer.write(styles.separator);
      buffer.write(styles.inactiveChoice.render('($noFirst)$noRest'));
    } else {
      buffer.write(styles.inactiveChoice.render('($yesFirst)$yesRest'));
      buffer.write(styles.separator);
      buffer.write(styles.activeChoice.render('($noFirst)$noRest'));
    }
  }

  static (String, String) _splitFirstGrapheme(
    String text, {
    required String fallback,
  }) {
    if (text.isEmpty) return (fallback, '');
    final (:grapheme, :nextIndex) = uni.readGraphemeAt(text, 0);
    if (grapheme.isEmpty) return (fallback, text);
    return (grapheme, text.substring(nextIndex));
  }
}

/// A destructive confirmation component that requires typing to confirm.
///
/// Used for dangerous operations where accidental confirmation should be prevented.
///
/// ## Example
///
/// ```dart
/// final confirm = DestructiveConfirmModel(
///   prompt: 'This will delete all data. Type "DELETE" to confirm:',
///   confirmText: 'DELETE',
/// );
/// ```
class DestructiveConfirmModel extends ViewComponent {
  /// Creates a new destructive confirm model.
  DestructiveConfirmModel({
    required this.prompt,
    required this.confirmText,
    this.caseSensitive = true,
    this.showHelp = true,
    ConfirmKeyMap? keyMap,
    ConfirmStyles? styles,
  }) : keyMap = keyMap ?? ConfirmKeyMap(),
       styles = styles ?? ConfirmStyles.defaults();

  /// The prompt to display.
  final String prompt;

  /// The text the user must type to confirm.
  final String confirmText;

  /// Whether the confirmation is case-sensitive.
  final bool caseSensitive;

  /// Whether to show help text.
  final bool showHelp;

  /// Key bindings.
  final ConfirmKeyMap keyMap;

  /// Styles.
  final ConfirmStyles styles;

  // Internal state
  final List<String> _input = [];
  String? _error;

  /// Gets the current input value.
  String get value => _input.join();

  /// Gets whether the current input matches the confirm text.
  bool get isMatch {
    final input = value;
    if (caseSensitive) {
      return input == confirmText;
    } else {
      return input.toLowerCase() == confirmText.toLowerCase();
    }
  }

  /// Gets the current error message.
  String? get error => _error;

  @override
  Cmd? init() => null;

  @override
  (DestructiveConfirmModel, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      final key = msg.key;

      if (keyMatches(key, [keyMap.cancel])) {
        return (this, Cmd.message(const ConfirmCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.confirm])) {
        if (isMatch) {
          return (this, Cmd.message(const ConfirmResultMsg(true)));
        } else if (_input.isNotEmpty) {
          _error = 'Input does not match "$confirmText"';
        }
        return (this, null);
      }

      // Handle backspace
      if (key.type == KeyType.backspace) {
        if (_input.isNotEmpty) {
          _input.removeLast();
          _error = null;
        }
        return (this, null);
      }

      // Handle character input
      if (key.runes.isNotEmpty) {
        final text = String.fromCharCodes(key.runes);
        for (final g in uni.graphemes(text)) {
          final cp = uni.firstCodePoint(g);
          if (cp >= 32 && cp != 127) {
            _input.add(g);
            _error = null;
          }
        }
        return (this, null);
      }
    }

    return (this, null);
  }

  @override
  String view() {
    final buffer = StringBuffer();

    // Prompt
    buffer.writeln(styles.prompt.render(prompt));

    // Input line
    buffer.write('  Type "');
    buffer.write(styles.activeChoice.render(confirmText));
    buffer.write('": ');

    // Current input with match highlighting
    final expected = uni.graphemes(confirmText).toList(growable: false);
    for (var i = 0; i < _input.length; i++) {
      final typed = _input[i];
      final exp = i < expected.length ? expected[i] : '';

      final matches = caseSensitive
          ? typed == exp
          : typed.toLowerCase() == exp.toLowerCase();

      buffer.write(
        (matches ? styles.activeChoice : Style().foreground(AnsiColor(9)))
            .render(typed),
      );
    }

    buffer.writeln();

    // Error message
    if (_error != null) {
      buffer.writeln(Style().foreground(AnsiColor(9)).render('  $_error'));
    }

    // Help
    if (showHelp) {
      buffer.writeln(
        styles.dimmed.render('  Press Enter to confirm, Esc to cancel'),
      );
    }

    return buffer.toString();
  }
}
