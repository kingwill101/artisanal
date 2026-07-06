/// TUI Text Input Example
///
/// This example demonstrates a text input field with cursor movement,
/// editing capabilities, and form submission.
///
/// Run with: dart run example/tui_input.dart
library;

import 'package:artisanal/tui.dart';

/// Message for when the form is submitted.
class SubmitMsg extends Msg {
  const SubmitMsg();
}

/// The text input model.
class TextInputModel implements Model {
  /// Creates a text input model.
  const TextInputModel({
    this.value = '',
    this.cursor = 0,
    this.placeholder = 'Type something...',
    this.submitted = false,
    this.cancelled = false,
    this.label = 'Input',
  });

  /// The current text value.
  final String value;

  /// The cursor position (0 = before first char).
  final int cursor;

  /// Placeholder text shown when empty.
  final String placeholder;

  /// Whether the form has been submitted.
  final bool submitted;

  /// Whether the form has been cancelled.
  final bool cancelled;

  /// The label for the input field.
  final String label;

  /// Creates a copy with the given fields replaced.
  TextInputModel copyWith({
    String? value,
    int? cursor,
    String? placeholder,
    bool? submitted,
    bool? cancelled,
    String? label,
  }) {
    return TextInputModel(
      value: value ?? this.value,
      cursor: cursor ?? this.cursor,
      placeholder: placeholder ?? this.placeholder,
      submitted: submitted ?? this.submitted,
      cancelled: cancelled ?? this.cancelled,
      label: label ?? this.label,
    );
  }

  /// Inserts a character at the cursor position.
  TextInputModel insertChar(String char) {
    final newValue =
        value.substring(0, cursor) + char + value.substring(cursor);
    return copyWith(value: newValue, cursor: cursor + char.length);
  }

  /// Deletes the character before the cursor (backspace).
  TextInputModel deleteBackward() {
    if (cursor == 0) return this;
    final newValue = value.substring(0, cursor - 1) + value.substring(cursor);
    return copyWith(value: newValue, cursor: cursor - 1);
  }

  /// Deletes the character at the cursor (delete).
  TextInputModel deleteForward() {
    if (cursor >= value.length) return this;
    final newValue = value.substring(0, cursor) + value.substring(cursor + 1);
    return copyWith(value: newValue);
  }

  /// Moves cursor left.
  TextInputModel moveCursorLeft() {
    return copyWith(cursor: (cursor - 1).clamp(0, value.length));
  }

  /// Moves cursor right.
  TextInputModel moveCursorRight() {
    return copyWith(cursor: (cursor + 1).clamp(0, value.length));
  }

  /// Moves cursor to start.
  TextInputModel moveCursorStart() {
    return copyWith(cursor: 0);
  }

  /// Moves cursor to end.
  TextInputModel moveCursorEnd() {
    return copyWith(cursor: value.length);
  }

  /// Clears all text.
  TextInputModel clear() {
    return copyWith(value: '', cursor: 0);
  }

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    final finished = submitted || cancelled;
    if (finished) {
      return switch (msg) {
        KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) || // 'q'
        KeyMsg(key: Key(type: KeyType.escape)) ||
        KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),
        _ => (this, null),
      };
    }

    return switch (msg) {
      // Submit on Enter
      KeyMsg(key: Key(type: KeyType.enter)) => (
        copyWith(submitted: true),
        null,
      ),

      // Quit without submit on Escape or Ctrl+C
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(
        key: Key(ctrl: true, runes: [0x63]),
      ) => (copyWith(cancelled: true), null),

      // Backspace - delete backward
      KeyMsg(key: Key(type: KeyType.backspace)) => (deleteBackward(), null),

      // Delete - delete forward
      KeyMsg(key: Key(type: KeyType.delete)) => (deleteForward(), null),

      // Left arrow - move cursor left
      KeyMsg(key: Key(type: KeyType.left)) => (moveCursorLeft(), null),

      // Right arrow - move cursor right
      KeyMsg(key: Key(type: KeyType.right)) => (moveCursorRight(), null),

      // Home or Ctrl+A - move to start
      KeyMsg(key: Key(type: KeyType.home)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x61])) => (moveCursorStart(), null),

      // End or Ctrl+E - move to end
      KeyMsg(key: Key(type: KeyType.end)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x65])) => (moveCursorEnd(), null),

      // Ctrl+U - clear line
      KeyMsg(key: Key(ctrl: true, runes: [0x75])) => (clear(), null),

      // Ctrl+K - delete from cursor to end
      KeyMsg(key: Key(ctrl: true, runes: [0x6b])) => (
        copyWith(value: value.substring(0, cursor)),
        null,
      ),

      // Ctrl+W - delete word backward
      KeyMsg(key: Key(ctrl: true, runes: [0x77])) => (
        _deleteWordBackward(),
        null,
      ),

      // Regular character input
      KeyMsg(key: Key(type: KeyType.runes, runes: final runes))
          when !msg.key.ctrl && !msg.key.alt =>
        (insertChar(String.fromCharCodes(runes)), null),

      // Space key
      KeyMsg(key: Key(type: KeyType.space)) => (insertChar(' '), null),

      // Ignore other messages
      _ => (this, null),
    };
  }

  /// Deletes the word before the cursor.
  TextInputModel _deleteWordBackward() {
    if (cursor == 0) return this;

    // Find start of previous word
    var pos = cursor - 1;

    // Skip trailing spaces
    while (pos > 0 && value[pos] == ' ') {
      pos--;
    }

    // Skip word characters
    while (pos > 0 && value[pos - 1] != ' ') {
      pos--;
    }

    final newValue = value.substring(0, pos) + value.substring(cursor);
    return copyWith(value: newValue, cursor: pos);
  }

  @override
  String view() {
    if (submitted || cancelled) {
      final headline = submitted
          ? (value.isEmpty ? 'No name entered.' : 'Hello, $value!')
          : 'Input cancelled.';
      return '''

  $headline

  Press q to quit.

''';
    }

    final buffer = StringBuffer();

    buffer.writeln();
    buffer.writeln('  ╔═══════════════════════════════════════════╗');
    buffer.writeln('  ║           Text Input Example              ║');
    buffer.writeln('  ╚═══════════════════════════════════════════╝');
    buffer.writeln();

    // Label
    buffer.writeln('  $label:');
    buffer.writeln();

    // Input field with cursor
    buffer.write('  ┌');
    buffer.write('─' * 40);
    buffer.writeln('┐');

    buffer.write('  │ ');
    if (value.isEmpty) {
      // Show placeholder with cursor at start
      buffer.write('\x1b[7m \x1b[0m'); // Inverted space for cursor
      buffer.write('\x1b[2m${placeholder.substring(0, 37)}\x1b[0m');
    } else {
      // Show value with cursor
      final displayValue = _getDisplayValue();
      buffer.write(displayValue);
    }
    // Pad to fill the box
    final contentLen = value.isEmpty
        ? placeholder.length + 1
        : value.length + 1;
    if (contentLen < 38) {
      buffer.write(' ' * (38 - contentLen.clamp(0, 38)));
    }
    buffer.writeln(' │');

    buffer.write('  └');
    buffer.write('─' * 40);
    buffer.writeln('┘');

    buffer.writeln();

    // Character count
    buffer.writeln('  \x1b[2m${value.length} characters\x1b[0m');
    buffer.writeln();

    // Help text
    buffer.writeln('  \x1b[2mControls:\x1b[0m');
    buffer.writeln('  \x1b[2m  ←/→       Move cursor\x1b[0m');
    buffer.writeln('  \x1b[2m  Home/End  Jump to start/end\x1b[0m');
    buffer.writeln('  \x1b[2m  Ctrl+U    Clear line\x1b[0m');
    buffer.writeln('  \x1b[2m  Ctrl+W    Delete word\x1b[0m');
    buffer.writeln('  \x1b[2m  Enter     Submit\x1b[0m');
    buffer.writeln('  \x1b[2m  Esc       Cancel\x1b[0m');
    buffer.writeln();

    return buffer.toString();
  }

  /// Gets the display value with cursor visualization.
  String _getDisplayValue() {
    final buffer = StringBuffer();

    // Text before cursor
    if (cursor > 0) {
      final before = value.substring(0, cursor);
      buffer.write(
        before.length > 36
            ? '…${before.substring(before.length - 35)}'
            : before,
      );
    }

    // Cursor (inverted character or space)
    if (cursor < value.length) {
      buffer.write('\x1b[7m${value[cursor]}\x1b[0m');
    } else {
      buffer.write('\x1b[7m \x1b[0m'); // Cursor at end
    }

    // Text after cursor
    if (cursor < value.length - 1) {
      final after = value.substring(cursor + 1);
      buffer.write(after.length > 20 ? '${after.substring(0, 19)}…' : after);
    }

    return buffer.toString();
  }
}

void main() async {
  final model = TextInputModel(
    label: 'Enter your name',
    placeholder: 'Type your name here...',
  );

  await runProgram(model, options: const ProgramOptions(altScreen: true));
}
