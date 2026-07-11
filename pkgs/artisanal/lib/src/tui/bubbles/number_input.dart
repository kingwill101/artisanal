/// Number input bubble — interactive numeric prompt with Up/Down increment.
///
/// Extends the basic text-input paradigm with Up/Down arrow handling to
/// increment or decrement the current value by [step], clamped to [min]/[max].
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import '../../unicode/grapheme.dart' as uni;
import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'key_binding.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the user submits a valid number.
class NumberSubmittedMsg extends Msg {
  /// Creates a submitted message with the final [value].
  const NumberSubmittedMsg(this.value);

  /// The submitted numeric value.
  final num value;

  @override
  String toString() => 'NumberSubmittedMsg($value)';
}

/// Emitted when the user cancels the prompt.
class NumberCancelledMsg extends Msg {
  const NumberCancelledMsg();

  @override
  String toString() => 'NumberCancelledMsg()';
}

// ─────────────────────────────────────────────────────────────────────────────
// Key map
// ─────────────────────────────────────────────────────────────────────────────

/// Key bindings for [NumberInputModel].
class NumberInputKeyMap extends KeyMap {
  /// Creates a key map with default bindings.
  NumberInputKeyMap({
    KeyBinding? increment,
    KeyBinding? decrement,
    KeyBinding? deleteBackward,
    KeyBinding? submit,
    KeyBinding? cancel,
  }) : increment =
           increment ??
           KeyBinding(
             keys: ['up', 'ctrl+p'],
             help: Help(key: Arrows.up, desc: 'increment'),
           ),
       decrement =
           decrement ??
           KeyBinding(
             keys: ['down', 'ctrl+n'],
             help: Help(key: Arrows.down, desc: 'decrement'),
           ),
       deleteBackward =
           deleteBackward ??
           KeyBinding(
             keys: ['backspace', 'ctrl+h'],
             help: Help(key: KeyboardChars.backspace, desc: 'delete'),
           ),
       submit =
           submit ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: KeyboardChars.enter, desc: 'submit'),
           ),
       cancel =
           cancel ??
           KeyBinding(
             keys: ['esc', 'ctrl+c'],
             help: Help(key: 'esc', desc: 'cancel'),
           ) {
    shortHelp = [this.increment, this.decrement, this.submit, this.cancel];
    fullHelp = [
      [this.increment, this.decrement],
      [this.deleteBackward, this.submit, this.cancel],
    ];
  }

  /// Increment the value by step.
  final KeyBinding increment;

  /// Decrement the value by step.
  final KeyBinding decrement;

  /// Delete the last typed character.
  final KeyBinding deleteBackward;

  /// Submit the current value.
  final KeyBinding submit;

  /// Cancel the prompt.
  final KeyBinding cancel;
}

// ─────────────────────────────────────────────────────────────────────────────
// Styles
// ─────────────────────────────────────────────────────────────────────────────

/// Visual styles for [NumberInputModel].
class NumberInputStyles {
  /// Creates styles with sensible defaults.
  NumberInputStyles({
    Style? prompt,
    Style? value,
    Style? placeholder,
    Style? hint,
    Style? error,
    Style? dimmed,
  }) : prompt = prompt ?? Style().foreground(AnsiColor(11)).bold(),
       value = value ?? Style(),
       placeholder = placeholder ?? Style().foreground(AnsiColor(8)),
       hint = hint ?? Style().foreground(AnsiColor(8)),
       error = error ?? Style().foreground(AnsiColor(9)).bold(),
       dimmed = dimmed ?? Style().foreground(AnsiColor(8));

  /// Style for the label/prompt.
  final Style prompt;

  /// Style for the typed value.
  final Style value;

  /// Style for placeholder text.
  final Style placeholder;

  /// Style for hint text shown below the input.
  final Style hint;

  /// Style for validation error messages.
  final Style error;

  /// Style for dimmed/secondary text.
  final Style dimmed;
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

/// Interactive numeric input component.
///
/// - Arrow-Up / Ctrl+P  → increment by [step] (clamped to [max])
/// - Arrow-Down / Ctrl+N → decrement by [step] (clamped to [min])
/// - Digit keys          → typed directly (non-digit characters ignored)
/// - Backspace           → delete last character
/// - Enter               → validate and submit
/// - Escape / Ctrl+C     → cancel
///
/// The component emits [NumberSubmittedMsg] on success or
/// [NumberCancelledMsg] on cancel.
///
/// Example:
/// ```dart
/// final model = NumberInputModel(
///   prompt: 'Port number:',
///   defaultValue: 8080,
///   min: 1,
///   max: 65535,
///   step: 1,
/// );
/// ```
class NumberInputModel extends ViewComponent {
  /// Creates a new number-input model.
  NumberInputModel({
    this.prompt = '? ',
    this.placeholder = '',
    num? defaultValue,
    this.min,
    this.max,
    this.step = 1,
    this.hint = '',
    this.showHelp = true,
    NumberInputKeyMap? keyMap,
    NumberInputStyles? styles,
    this.validate,
  }) : keyMap = keyMap ?? NumberInputKeyMap(),
       styles = styles ?? NumberInputStyles(),
       _rawInput = defaultValue != null ? _formatNum(defaultValue) : '';

  /// The label shown before the input field.
  final String prompt;

  /// Placeholder text when the input is empty.
  final String placeholder;

  /// Minimum allowed value (no lower bound if null).
  final num? min;

  /// Maximum allowed value (no upper bound if null).
  final num? max;

  /// Amount to increment/decrement per key press.
  final num step;

  /// Hint text shown below the input.
  final String hint;

  /// Whether to show the keyboard shortcut help line.
  final bool showHelp;

  /// Key bindings.
  final NumberInputKeyMap keyMap;

  /// Visual styles.
  final NumberInputStyles styles;

  /// Optional extra validator: return an error string or null.
  final String? Function(num)? validate;

  // ── internal state ────────────────────────────────────────────────────────

  String _rawInput;
  String? _error;

  // ── public accessors ──────────────────────────────────────────────────────

  /// The raw string currently shown in the input field.
  String get rawInput => _rawInput;

  /// Parses and returns the current numeric value, or null if not a valid number.
  num? get numericValue => num.tryParse(_rawInput);

  /// The current validation error, or null.
  String? get error => _error;

  // ── MVU ───────────────────────────────────────────────────────────────────

  @override
  Cmd? init() => null;

  @override
  (NumberInputModel, Cmd?) update(Msg msg) {
    if (msg is! KeyMsg) return (this, null);

    final key = msg.key;

    if (keyMatches(key, [keyMap.cancel])) {
      return (this, Cmd.message(const NumberCancelledMsg()));
    }

    if (keyMatches(key, [keyMap.submit])) {
      final err = _validateInput(_rawInput);
      if (err != null) {
        _error = err;
        return (this, null);
      }
      final parsed = num.tryParse(_rawInput);
      if (parsed == null) {
        _error = 'Must be a number.';
        return (this, null);
      }
      _error = null;
      return (this, Cmd.message(NumberSubmittedMsg(parsed)));
    }

    if (keyMatches(key, [keyMap.increment])) {
      _adjustValue(1);
      _error = null;
      return (this, null);
    }

    if (keyMatches(key, [keyMap.decrement])) {
      _adjustValue(-1);
      _error = null;
      return (this, null);
    }

    if (keyMatches(key, [keyMap.deleteBackward])) {
      if (_rawInput.isNotEmpty) {
        _rawInput = _dropLastGrapheme(_rawInput);
        _error = null;
      }
      return (this, null);
    }

    // Accept digit, minus sign, and decimal point characters.
    if (key.runes.isNotEmpty) {
      final ch = String.fromCharCodes(key.runes);
      if (_isValidInputChar(ch)) {
        _rawInput += ch;
        _error = null;
      }
      return (this, null);
    }

    return (this, null);
  }

  @override
  String view() {
    final buf = StringBuffer();

    // Prompt + value line.
    buf.write(styles.prompt.render(prompt));
    buf.write(' ');
    if (_rawInput.isEmpty) {
      buf.write(
        styles.placeholder.render(placeholder.isNotEmpty ? placeholder : '0'),
      );
    } else {
      buf.write(styles.value.render(_rawInput));
    }
    buf.writeln();

    // Error.
    if (_error != null) {
      buf.writeln(styles.error.render('  $_error'));
    }

    // Range hint.
    if (hint.isNotEmpty) {
      buf.writeln(styles.hint.render('  $hint'));
    } else {
      final parts = <String>[];
      if (min != null) parts.add('min: $min');
      if (max != null) parts.add('max: $max');
      if (step != 1) parts.add('step: $step');
      if (parts.isNotEmpty) {
        buf.writeln(styles.hint.render('  (${parts.join(', ')})'));
      }
    }

    // Help.
    if (showHelp) {
      final helpText = keyMap.shortHelp
          .where((b) => b.help.hasContent)
          .map((b) => '${b.help.key} ${b.help.desc}')
          .join('  ');
      buf.writeln(styles.dimmed.render('  $helpText'));
    }

    return buf.toString();
  }

  // ── private helpers ───────────────────────────────────────────────────────

  void _adjustValue(int direction) {
    final current = num.tryParse(_rawInput);
    if (current == null) {
      // Start from a sensible seed when the field is empty.
      if (direction > 0) {
        final seed = min ?? 0;
        _rawInput = _formatNum(seed);
      } else {
        final seed = max ?? 0;
        _rawInput = _formatNum(seed);
      }
      return;
    }
    final delta = step * direction;
    var next = current + delta;
    if (min != null) next = math.max(min!, next);
    if (max != null) next = math.min(max!, next);
    _rawInput = _formatNum(next);
  }

  String? _validateInput(String raw) {
    if (raw.isEmpty) return 'A value is required.';
    final parsed = num.tryParse(raw);
    if (parsed == null) return 'Must be a number.';
    if (min != null && parsed < min!) return 'Must be at least $min.';
    if (max != null && parsed > max!) return 'Must be at most $max.';
    return validate?.call(parsed);
  }

  static bool _isValidInputChar(String ch) {
    if (ch == '-') return true;
    if (ch == '.') return true;
    return ch.codeUnits.every((c) => c >= 48 && c <= 57); // '0'–'9'
  }

  static String _dropLastGrapheme(String s) {
    if (s.isEmpty) return '';
    final gs = uni.graphemes(s).toList();
    gs.removeLast();
    return gs.join();
  }

  static String _formatNum(num n) {
    // Show as integer if it is a whole number.
    if (n == n.truncate()) return n.truncate().toString();
    return n.toString();
  }
}
