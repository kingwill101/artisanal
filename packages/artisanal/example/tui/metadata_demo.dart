import 'dart:async';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

/// This example demonstrates using the [View] object to control terminal metadata
/// like window title and progress bars, as well as using [compressAnsi] to
/// optimize terminal output.
void main() async {
  // Demonstrate ANSI compression
  final redundant =
      '\x1b[31mRed\x1b[31m Still Red\x1b[31m More Red\x1b[0m Reset';
  final compressed = compressAnsi(redundant);

  Println('--- ANSI Compression Demo ---');
  Println('Original:   "$redundant" (length: ${redundant.length})');
  Println('Compressed: "$compressed" (length: ${compressed.length})');
  Println('Saved ${redundant.length - compressed.length} bytes.');
  Println('-----------------------------\n');

  Println('Starting TUI Metadata Demo in 2 seconds...');
  await Future.delayed(const Duration(seconds: 2));

  await runProgram(
    MetadataModel(),
    options: const ProgramOptions(
      altScreen: true,
      // You can also use SimpleTuiRenderer for non-diffing, scrolling output:
      // disableRenderer: true,
    ),
  );
}

class MetadataModel implements Model {
  int progress = 0;

  @override
  Cmd? init() => every(const Duration(milliseconds: 50), (t) => TickMsg(t));

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      TickMsg() => _onTick(),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (
        this,
        Cmd.quit(),
      ),
      _ => (this, null),
    };
  }

  (Model, Cmd?) _onTick() {
    if (progress < 100) {
      progress++;
      return (this, null);
    }
    return (this, Cmd.quit());
  }

  @override
  Object view() {
    // Returning a View object instead of a String allows us to provide metadata
    // that the Program runtime will apply to the terminal.
    return View(
      content:
          '''
  Artisanal Metadata Demo
  =======================
  
  Progress: $progress%
  
  This model's view() method returns a [View] object instead of a [String].
  This allows declarative control over:
  
  1. Window Title:  "Artisanal: $progress% complete"
  2. Progress Bar:  OSC 9;4 sequence (supported by Windows Terminal, etc.)
  3. Colors:        Background/Foreground overrides (OSC 10/11)
  
  Press 'q' to quit.
''',
      windowTitle: 'Artisanal: $progress% complete',
      progressBar: TerminalProgressBar(
        state: progress < 100
            ? TerminalProgressBarState.defaultState
            : TerminalProgressBarState.none,
        value: progress,
      ),
    );
  }
}
