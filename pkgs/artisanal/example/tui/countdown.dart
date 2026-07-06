/// TUI Countdown Example
///
/// This example demonstrates the basic Elm Architecture pattern
/// with a simple countdown timer. Based on the Bubble Tea tutorial.
///
/// Run with: dart run example/tui_countdown.dart
library;

import 'package:artisanal/tui.dart';

/// Custom message for timer ticks.
class TickMsg extends Msg {
  const TickMsg();
}

/// The countdown model.
class CountdownModel implements Model {
  /// Creates a countdown starting at [count].
  const CountdownModel(this.count);

  /// The current count value.
  final int count;

  @override
  Cmd? init() {
    // Start the countdown timer
    return Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg());
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      // Handle tick - decrement counter
      TickMsg() when count <= 1 => (const CountdownModel(0), Cmd.quit()),
      TickMsg() => (
        CountdownModel(count - 1),
        Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg()),
      ),

      // Handle 'q' key to quit early
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (
        this,
        Cmd.quit(),
      ),

      // Handle Ctrl+C to quit
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),

      // Handle escape to quit
      KeyMsg(key: Key(type: KeyType.escape)) => (this, Cmd.quit()),

      // Ignore other messages
      _ => (this, null),
    };
  }

  @override
  String view() {
    if (count == 0) {
      return '''

  🎉 Time's up!

  Goodbye!

''';
    }

    final countStr = count.toString().padLeft(2, '0');
    return '''

  ⏱️  Countdown Timer

  $countStr seconds remaining...

  Press q or Esc to quit early.

''';
  }
}

void main() async {
  // Start with 10 seconds
  await runProgram(
    const CountdownModel(10),
    options: const ProgramOptions(altScreen: true),
  );
}
