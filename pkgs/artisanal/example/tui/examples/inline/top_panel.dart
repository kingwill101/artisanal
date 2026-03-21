/// Top-Anchored Inline Info Panel
///
/// Renders a TUI info panel at the top of the terminal while preserving
/// scrollback below it. Useful for status dashboards that shouldn't
/// take over the full screen.
///
/// Run: dart run example/tui/examples/inline/top_panel.dart
///
/// Press q to quit, r to refresh info.
library;

import 'dart:io';

import 'package:artisanal/runtime.dart';

class TopPanelModel implements Model {
  const TopPanelModel({this.tick = 0});

  final int tick;

  @override
  Cmd? init() {
    return every(const Duration(seconds: 1), (_) => const _Tick());
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      _Tick() => (TopPanelModel(tick: tick + 1), null),

      // Quit.
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) ||
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),

      _ => (this, null),
    };
  }

  @override
  View view() {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final mem = ProcessInfo.currentRss ~/ (1024 * 1024);

    return View(
      content:
          '''
\x1b[1;36m ┌─ System Monitor ──────────────────────────────────────┐\x1b[0m
\x1b[1;36m │\x1b[0m \x1b[33m$time\x1b[0m   RSS: ${mem}MB   Uptime: ${tick}s
\x1b[1;36m │\x1b[0m Press \x1b[2mq\x1b[0m to quit
\x1b[1;36m └──────────────────────────────────────────────────────┘\x1b[0m
''',
    );
  }
}

class _Tick extends Msg {
  const _Tick();
}

void main() async {
  // Print some initial log lines to demonstrate scrollback preservation.
  print('Starting system monitor...');
  print('Scrollback is preserved below the info panel.');
  for (var i = 1; i <= 12; i++) {
    print(
      'seed log line $i: visible content should remain below the top panel',
    );
  }
  print('');

  await runProgram(
    const TopPanelModel(),
    options: const ProgramOptions(
      screenMode: ScreenMode.inline,
      inlineHeight: 4,
      uiAnchor: UiAnchor.top,
      fps: 5,
      hideCursor: true,
      startupProbes: false,
    ),
  );

  print('');
  print('Monitor exited. Scrollback is still visible!');
}
