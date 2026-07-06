/// Minimal hot reload test app.
///
/// Run with: dart --enable-vm-service run example/tui/examples/hot_reload_test/main.dart
/// Then edit the `_greeting` string below and save to trigger hot reload.
library;

import 'package:artisanal/tui.dart';

// ── Change this string and save to test hot reload ──────────────────────
const _greeting = 'Hello from hot reload test! (v1)';
// ────────────────────────────────────────────────────────────────────────

class _HotReloadTestModel implements Model {
  const _HotReloadTestModel({this.reloadCount = 0, this.lastStatus});

  final int reloadCount;
  final HotReloadStatus? lastStatus;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])): // q
      case KeyMsg(key: Key(type: KeyType.escape)):
      case KeyMsg(key: Key(ctrl: true, runes: [0x63])): // Ctrl+C
        return (this, Cmd.quit());

      case HotReloadStatusMsg(:final status):
        final count = status == HotReloadStatus.succeeded
            ? reloadCount + 1
            : reloadCount;
        return (
          _HotReloadTestModel(reloadCount: count, lastStatus: status),
          null,
        );

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    final statusLine = lastStatus != null
        ? 'Last status: ${lastStatus!.name}'
        : 'Waiting for hot reload...';
    return '\n'
        '  ┌─────────────────────────────────────────┐\n'
        '  │  HOT RELOAD TEST                        │\n'
        '  │                                         │\n'
        '  │  $_greeting\n'
        '  │                                         │\n'
        '  │  Reload count: $reloadCount                       \n'
        '  │  $statusLine\n'
        '  │                                         │\n'
        '  │  Press q to quit                        │\n'
        '  └─────────────────────────────────────────┘\n';
  }
}

Future<void> main() async {
  await runProgram(
    const _HotReloadTestModel(),
    options: const ProgramOptions(
      altScreen: true,
      hideCursor: true,
      hotReload: true,
    ),
  );
}
