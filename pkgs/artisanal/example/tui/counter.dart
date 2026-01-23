/// TUI Counter Example
///
/// This is the simplest TUI example demonstrating the Elm Architecture.
/// A counter that can be incremented and decremented with arrow keys.
///
/// Run with: dart run example/tui_counter.dart
library;

import 'package:artisanal/tui.dart';

// #region model_example
/// The counter model.
class CounterModel implements Model {
  /// Creates a counter with the given value.
  const CounterModel([this.count = 0]);

  /// The current count value.
  final int count;

  @override
  Cmd? init() => null; // No initialization needed

  // #region update_example
  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      // Increment with up arrow or '+'
      KeyMsg(key: Key(type: KeyType.up)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2b])) => (
        // '+'
        CounterModel(count + 1),
        null,
      ),

      // Decrement with down arrow or '-'
      KeyMsg(key: Key(type: KeyType.down)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x2d])) => (
        // '-'
        CounterModel(count - 1),
        null,
      ),

      // Reset with 'r'
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x72])) => (
        const CounterModel(0),
        null,
      ),

      // Quit with 'q', Escape, or Ctrl+C
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) || // 'q'
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (
        // Ctrl+C
        this,
        Cmd.quit(),
      ),

      // Ignore other messages
      _ => (this, null),
    };
  }
  // #endregion

  // #region view_example
  @override
  String view() {
    // Create a simple visual representation
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
  // #endregion

  /// Creates a visual bar representation of the count.
  String _createBar(int value) {
    const maxWidth = 30;
    final absValue = value.abs().clamp(0, maxWidth);

    if (value == 0) {
      return '  [${'─' * maxWidth}]';
    } else if (value > 0) {
      final filled = '█' * absValue;
      final empty = '─' * (maxWidth - absValue);
      return '  [\x1b[32m$filled\x1b[0m$empty]'; // Green for positive
    } else {
      final filled = '█' * absValue;
      final empty = '─' * (maxWidth - absValue);
      return '  [$empty\x1b[31m$filled\x1b[0m]'; // Red for negative
    }
  }
}
// #endregion

// #region program_example
void main() async {
  await runProgram(
    const CounterModel(),
    options: const ProgramOptions(altScreen: true),
  );
}
// #endregion

// #region fps_optimization_usage
void runWithFpsLimit() async {
  await runProgram(
    const CounterModel(),
    options: const ProgramOptions(
      fps: 30, // Limit to 30 FPS
    ),
  );
}

// #endregion
