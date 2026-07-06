/// Bottom-Anchored Inline Status Bar
// tui:allow-stdout — print() used outside TUI lifecycle to seed scrollback.
///
/// Renders a small TUI at the bottom of the terminal while preserving
/// scrollback above it. Log lines scroll naturally above the UI region.
///
/// Run: dart run example/tui/examples/inline/bottom_status.dart
///
/// Type to add log lines, press q to quit.
library;

import 'dart:math';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';

final _rng = Random();

const _logMessages = [
  'Compiling lib/main.dart...',
  'Linking assets...',
  'Running analyzer...',
  'Generating code...',
  'Building kernel snapshot...',
  'Optimizing bundle...',
  'Resolving dependencies...',
  'Transpiling sources...',
  'Copying resources...',
  'Writing manifest...',
];

class InlineStatusModel implements Model {
  const InlineStatusModel({this.count = 0, this.running = true});

  final int count;
  final bool running;

  @override
  Cmd? init() {
    // Start a timer that prints fake log lines.
    return every(const Duration(milliseconds: 800), (_) {
      final msg = _logMessages[_rng.nextInt(_logMessages.length)];
      return _LogMsg(msg);
    });
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is _LogMsg && !running) {
      return (this, null);
    }

    return switch (msg) {
      // Timer tick: increment activity counter and print a real line above the
      // pinned bottom UI. This exercises the inline scrollback path.
      _LogMsg() => (
        InlineStatusModel(count: count + 1, running: running),
        Cmd.println('[${(count + 1).toString().padLeft(3, '0')}] ${msg.text}'),
      ),

      // Space toggles running state.
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x20])) => (
        InlineStatusModel(count: count, running: !running),
        null,
      ),

      // Quit.
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),

      _ => (this, null),
    };
  }

  @override
  View view() {
    final status = running
        ? '\x1b[32m${Circles.filled} RUNNING\x1b[0m'
        : '\x1b[33m${Circles.filled} PAUSED\x1b[0m';
    final content =
        '''
\x1b[1m Inline Status Bar\x1b[0m ───────────────────────
 $status   Events: $count

 \x1b[2mSpace\x1b[0m toggle   \x1b[2mq\x1b[0m quit
''';

    return View(content: content);
  }
}

class _LogMsg extends Msg {
  const _LogMsg(this.text);
  final String text;

  @override
  String toString() => 'LogMsg($text)';
}

void main() async {
  print('Preparing inline status demo...');
  print('These lines should remain visible above the bottom status bar.');
  print('If inline mode is working, only the bottom 4 rows become the UI.');
  for (var i = 1; i <= 12; i++) {
    print('seed log line $i: preserved visible content above the inline UI');
  }
  print('');

  await runProgram(
    const InlineStatusModel(),
    options: const ProgramOptions(
      screenMode: ScreenMode.inline,
      inlineHeight: 4,
      uiAnchor: UiAnchor.bottom,
      fps: 30,
      startupProbes: false,
    ),
  );

  print('');
  print('Inline status demo exited. Scrollback above should still be intact.');
}
