/// Dart port of TUI (Bubble Tea) examples.
///
/// Demonstrates various TUI patterns: counter, countdown, input, list, UV,
/// and key chords.
///
/// Run with: dart run example/lipgloss_tui.dart [demo]
///
/// Demos: counter, countdown, input, list, uv, chord
library;

import 'dart:io' show stdout;

import 'package:artisanal/tui.dart';

void main(List<String> args) async {
  final demo = args.isNotEmpty ? args.first : 'counter';
  await switch (demo) {
    'counter'   => _runCounter(),
    'countdown' => _runCountdown(),
    'input'     => _runInput(),
    'list'      => _runList(),
    'uv'        => _runUv(),
    'chord'     => _runChord(),
    _           => _printUsage(),
  };
}

Future<void> _printUsage() async {
  stdout.writeln('Usage: dart run example/lipgloss_tui.dart [demo]');
  stdout.writeln('Demos: counter, countdown, input, list, uv, chord');
}

// ═════════════════════════════════════════════════════════════════════════════
// Counter
// ═════════════════════════════════════════════════════════════════════════════

class CounterModel implements Model {
  const CounterModel([this.count = 0]);
  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2b])) => (
        CounterModel(count + 1),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.down)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2d])) => (
        CounterModel(count - 1),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x72])) => (
        const CounterModel(0),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() {
    final bar = _createBar(count);
    return '''

  ╔═══════════════════════════════════╗
  ║         Simple Counter            ║
  ╚═══════════════════════════════════╝

  Count: $count

  $bar

  Controls:
    ↑ / +   Increment
    ↓ / -   Decrement
    r       Reset to 0
    q       Quit

''';
  }

  String _createBar(int value) {
    const maxWidth = 30;
    final absValue = value.abs().clamp(0, maxWidth);
    if (value == 0) return '  [${'─' * maxWidth}]';
    final filled = '█' * absValue;
    final empty = '─' * (maxWidth - absValue);
    if (value > 0) return '  [\x1b[32m$filled\x1b[0m$empty]';
    return '  [$empty\x1b[31m$filled\x1b[0m]';
  }
}

Future<void> _runCounter() async {
  await runProgram(const CounterModel(), options: ProgramOptions(altScreen: true));
}

// ═════════════════════════════════════════════════════════════════════════════
// Countdown
// ═════════════════════════════════════════════════════════════════════════════

class TickMsg extends Msg {
  const TickMsg();
}

class CountdownModel implements Model {
  const CountdownModel(this.count);
  final int count;

  @override
  Cmd? init() => Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg());

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      TickMsg() when count <= 1 => (const CountdownModel(0), Cmd.quit()),
      TickMsg() => (
        CountdownModel(count - 1),
        Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg()),
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) ||
      KeyMsg(key: Key(type: KeyType.escape)) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() {
    if (count == 0) return '\n  🎉 Time\'s up!\n\n  Goodbye!\n\n';
    return '''

  ⏱️  Countdown Timer

  ${count.toString().padLeft(2, '0')} seconds remaining...

  Press q or Esc to quit early.

''';
  }
}

Future<void> _runCountdown() async {
  await runProgram(
    const CountdownModel(10),
    options: const ProgramOptions(altScreen: true),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Text Input
// ═════════════════════════════════════════════════════════════════════════════

class SubmitMsg extends Msg {
  const SubmitMsg();
}

class TextInputModel implements Model {
  const TextInputModel({
    this.value = '',
    this.cursor = 0,
    this.placeholder = 'Type something...',
    this.submitted = false,
    this.cancelled = false,
    this.label = 'Input',
  });

  final String value;
  final int cursor;
  final String placeholder;
  final bool submitted;
  final bool cancelled;
  final String label;

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

  TextInputModel insertChar(String char) {
    final newValue = value.substring(0, cursor) + char + value.substring(cursor);
    return copyWith(value: newValue, cursor: cursor + char.length);
  }

  TextInputModel deleteBackward() {
    if (cursor == 0) return this;
    final newValue = value.substring(0, cursor - 1) + value.substring(cursor);
    return copyWith(value: newValue, cursor: cursor - 1);
  }

  TextInputModel deleteForward() {
    if (cursor >= value.length) return this;
    final newValue = value.substring(0, cursor) + value.substring(cursor + 1);
    return copyWith(value: newValue);
  }

  TextInputModel moveCursorLeft() => copyWith(cursor: (cursor - 1).clamp(0, value.length));
  TextInputModel moveCursorRight() => copyWith(cursor: (cursor + 1).clamp(0, value.length));
  TextInputModel moveCursorStart() => copyWith(cursor: 0);
  TextInputModel moveCursorEnd() => copyWith(cursor: value.length);
  TextInputModel clear() => copyWith(value: '', cursor: 0);

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (submitted || cancelled) {
      return switch (msg) {
        KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
        KeyMsg(key: Key(type: KeyType.escape)) ||
        KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),
        _ => (this, null),
      };
    }
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.enter)) => (copyWith(submitted: true), null),
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (copyWith(cancelled: true), null),
      KeyMsg(key: Key(type: KeyType.backspace)) => (deleteBackward(), null),
      KeyMsg(key: Key(type: KeyType.delete)) => (deleteForward(), null),
      KeyMsg(key: Key(type: KeyType.left)) => (moveCursorLeft(), null),
      KeyMsg(key: Key(type: KeyType.right)) => (moveCursorRight(), null),
      KeyMsg(key: Key(type: KeyType.home)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x61])) => (moveCursorStart(), null),
      KeyMsg(key: Key(type: KeyType.end)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x65])) => (moveCursorEnd(), null),
      KeyMsg(key: Key(ctrl: true, runes: [0x75])) => (clear(), null),
      KeyMsg(key: Key(ctrl: true, runes: [0x6b])) => (
        copyWith(value: value.substring(0, cursor)),
        null,
      ),
      KeyMsg(key: Key(ctrl: true, runes: [0x77])) => (_deleteWordBackward(), null),
      KeyMsg(key: Key(type: KeyType.runes, runes: final r))
          when !msg.key.ctrl && !msg.key.alt =>
        (insertChar(String.fromCharCodes(r)), null),
      KeyMsg(key: Key(type: KeyType.space)) => (insertChar(' '), null),
      _ => (this, null),
    };
  }

  TextInputModel _deleteWordBackward() {
    if (cursor == 0) return this;
    var pos = cursor - 1;
    while (pos > 0 && value[pos] == ' ') { pos--; }
    while (pos > 0 && value[pos - 1] != ' ') { pos--; }
    return copyWith(value: value.substring(0, pos) + value.substring(cursor), cursor: pos);
  }

  @override
  String view() {
    if (submitted || cancelled) {
      final headline = submitted
          ? (value.isEmpty ? 'No name entered.' : 'Hello, $value!')
          : 'Input cancelled.';
      return '\n  $headline\n\n  Press q to quit.\n\n';
    }
    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln('  ╔═══════════════════════════════════════════╗');
    buffer.writeln('  ║           Text Input Example              ║');
    buffer.writeln('  ╚═══════════════════════════════════════════╝');
    buffer.writeln();
    buffer.writeln('  $label:');
    buffer.writeln();
    buffer.writeln('  ┌${'─' * 40}┐');
    buffer.write('  │ ');
    if (value.isEmpty) {
      buffer.write('\x1b[7m \x1b[0m');
      buffer.write('\x1b[2m${placeholder.substring(0, 37)}\x1b[0m');
    } else {
      buffer.write(_getDisplayValue());
    }
    final contentLen = value.isEmpty ? placeholder.length + 1 : value.length + 1;
    if (contentLen < 38) buffer.write(' ' * (38 - contentLen.clamp(0, 38)));
    buffer.writeln(' │');
    buffer.writeln('  └${'─' * 40}┘');
    buffer.writeln();
    buffer.writeln('  \x1b[2m${value.length} characters\x1b[0m');
    buffer.writeln();
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

  String _getDisplayValue() {
    final buffer = StringBuffer();
    if (cursor > 0) {
      final before = value.substring(0, cursor);
      buffer.write(before.length > 36 ? '…${before.substring(before.length - 35)}' : before);
    }
    if (cursor < value.length) {
      buffer.write('\x1b[7m${value[cursor]}\x1b[0m');
    } else {
      buffer.write('\x1b[7m \x1b[0m');
    }
    if (cursor < value.length - 1) {
      final after = value.substring(cursor + 1);
      buffer.write(after.length > 20 ? '${after.substring(0, 19)}…' : after);
    }
    return buffer.toString();
  }
}

Future<void> _runInput() async {
  await runProgram(
    TextInputModel(label: 'Enter your name', placeholder: 'Type your name here...'),
    options: const ProgramOptions(altScreen: true),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// List Selection
// ═════════════════════════════════════════════════════════════════════════════

class ListModel implements Model {
  const ListModel({required this.items, this.cursor = 0, this.selected});
  final List<String> items;
  final int cursor;
  final String? selected;

  ListModel copyWith({List<String>? items, int? cursor, String? selected}) {
    return ListModel(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      selected: selected ?? this.selected,
    );
  }

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: final k) when k.isChar('q') || k.isEscape || k.isCtrlC =>
        (this, Cmd.quit()),
      KeyMsg(key: final k) when k.isEnterLike || k.isSpaceLike => (
        copyWith(selected: items[cursor]),
        Cmd.quit(),
      ),
      KeyMsg(key: final k) when k.type == KeyType.up || k.isChar('k') => (
        copyWith(cursor: (cursor - 1).clamp(0, items.length - 1)),
        null,
      ),
      KeyMsg(key: final k) when k.type == KeyType.down || k.isChar('j') => (
        copyWith(cursor: (cursor + 1).clamp(0, items.length - 1)),
        null,
      ),
      KeyMsg(key: final k) when k.type == KeyType.home || k.char == 'g' =>
        (copyWith(cursor: 0), null),
      KeyMsg(key: final k) when k.type == KeyType.end || k.char == 'G' =>
        (copyWith(cursor: items.length - 1), null),
      _ => (this, null),
    };
  }

  @override
  String view() {
    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln('  What would you like to have for lunch?');
    buffer.writeln();
    for (var i = 0; i < items.length; i++) {
      final prefix = i == cursor ? '▸ ' : '  ';
      if (i == cursor) {
        buffer.writeln('  \x1b[36m$prefix${items[i]}\x1b[0m');
      } else {
        buffer.writeln('  $prefix${items[i]}');
      }
    }
    buffer.writeln();
    buffer.writeln('  \x1b[2m↑/k: up • ↓/j: down • Enter: select • q: quit\x1b[0m');
    buffer.writeln();
    return buffer.toString();
  }
}

Future<void> _runList() async {
  final model = ListModel(items: [
    '🍕 Pizza', '🍔 Burger', '🌮 Tacos', '🍜 Ramen',
    '🥗 Salad', '🍣 Sushi', '🥪 Sandwich', '🍝 Pasta',
  ]);
  final result = await runProgramWithResult(
    model,
    options: const ProgramOptions(
      altScreen: true,
      useUltravioletRenderer: true,
      useUltravioletInputDecoder: true,
    ),
  );
  // ignore: avoid_print
  print(result.selected == null
      ? 'No selection made. Maybe next time!'
      : 'You selected: ${result.selected}');
}

// ═════════════════════════════════════════════════════════════════════════════
// UV Renderer Demo
// ═════════════════════════════════════════════════════════════════════════════

class UvDemoModel implements Model {
  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg && msg.key.type == KeyType.runes && msg.key.runes.isNotEmpty) {
      if (String.fromCharCode(msg.key.runes.first) == 'q') return (this, Cmd.quit());
    }
    return (this, null);
  }

  @override
  String view() => 'Ultraviolet TuiRenderer Demo\n\nPress q to quit.';
}

Future<void> _runUv() async {
  await runProgram(
    UvDemoModel(),
    options: const ProgramOptions(
      useUltravioletRenderer: true,
      altScreen: true,
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Key Chords
// ═════════════════════════════════════════════════════════════════════════════

class KeyChordModel implements Model {
  const KeyChordModel({this.status = 'Ready', this.lastChord});

  final String status;
  final String? lastChord;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyChordResolvedMsg(:final id) => (
        copyWith(status: 'Chord activated!', lastChord: id),
        null,
      ),
      KeyChordPrefixMsg() => (
        copyWith(status: 'Waiting for second key...'),
        null,
      ),
      KeyChordCancelledMsg(:final timedOut) => (
        copyWith(status: timedOut ? 'Chord timed out' : 'Chord cancelled'),
        null,
      ),
      KeyMsg(key: final k) when k.rune == 0x71 => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() {
    final buffer = StringBuffer();
    buffer.writeln('\n  ╔═══ Key Chord Demo ═══╗\n');
    buffer.writeln('  Status: $status');
    if (lastChord != null) {
      buffer.writeln('  Last chord: $lastChord');
    }
    buffer.writeln('');
    buffer.writeln('  Bindings:');
    buffer.writeln('    Ctrl+X then t  → open themes');
    buffer.writeln('    Ctrl+X then m  → switch model');
    buffer.writeln('');
    buffer.writeln('  Press q to quit');
    return buffer.toString();
  }

  KeyChordModel copyWith({String? status, String? lastChord}) => KeyChordModel(
    status: status ?? this.status,
    lastChord: lastChord ?? this.lastChord,
  );
}

Future<void> _runChord() async {
  final interceptor = KeyChordInterceptor(
    bindings: [
      KeyChordBinding(
        id: 'open-themes',
        prefix: KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
        key: KeyBinding.withHelp(['t'], 't', 'themes'),
      ),
      KeyChordBinding(
        id: 'switch-model',
        prefix: KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
        key: KeyBinding.withHelp(['m'], 'm', 'model'),
      ),
      KeyChordBinding(
        id: 'toggle-sidebar',
        prefix: KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
        key: KeyBinding.withHelp(['b'], 'b', 'sidebar'),
      ),
    ],
    timeout: const Duration(seconds: 3),
  );

  await runProgram(
    const KeyChordModel(),
    options: ProgramOptions(altScreen: true, interceptor: interceptor),
  );
}
