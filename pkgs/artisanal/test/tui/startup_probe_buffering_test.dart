import 'dart:async';

import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/startup_probe.dart';
import 'package:artisanal/src/tui/terminal.dart';
import 'package:test/test.dart';

class _TestTerminal implements TuiTerminal {
  @override
  Stream<List<int>> get input => const Stream.empty();

  @override
  void write(String data) {}

  @override
  void writeln([String data = '']) {}

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async => null;

  @override
  Future<void> flush() async {}

  @override
  RawModeGuard enableRawMode() =>
      RawModeGuard(wasEchoMode: true, wasLineMode: true, restore: () {});

  @override
  void disableRawMode() {}

  @override
  bool get isRawMode => false;

  @override
  void enterAltScreen() {}

  @override
  void exitAltScreen() {}

  @override
  void hideCursor() {}

  @override
  void showCursor() {}

  @override
  void enableMouse() {}

  @override
  void enableMouseCellMotion() {}

  @override
  void enableMouseAllMotion() {}

  @override
  void disableMouse() {}

  @override
  void enableBracketedPaste() {}

  @override
  void disableBracketedPaste() {}

  @override
  void enableFocusReporting() {}

  @override
  void disableFocusReporting() {}

  @override
  void setTitle(String title) {}

  @override
  void setProgressBar(int state, int value) {}

  @override
  void bell() {}

  @override
  void saveCursor() {}

  @override
  void restoreCursor() {}

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      (useTabs: false, useBackspace: false);

  @override
  int get width => 80;

  @override
  int get height => 24;

  @override
  ({int width, int height}) get size => (width: 80, height: 24);

  @override
  bool get supportsAnsi => true;

  @override
  bool get isTerminal => true;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  bool get isAltScreen => true;

  @override
  bool get isMouseEnabled => false;

  @override
  bool get isBracketedPasteEnabled => false;

  @override
  void clearScreen() {}

  @override
  void clearToEnd() {}

  @override
  void clearToStart() {}

  @override
  void clearLine() {}

  @override
  void clearLineToEnd() {}

  @override
  void clearLineToStart() {}

  @override
  void clearPreviousLines(int lines) {}

  @override
  void scrollUp([int lines = 1]) {}

  @override
  void scrollDown([int lines = 1]) {}

  @override
  void moveCursor(int row, int col) {}

  @override
  void cursorHome() {}

  @override
  void cursorUp([int lines = 1]) {}

  @override
  void cursorDown([int lines = 1]) {}

  @override
  void cursorRight([int cols = 1]) {}

  @override
  void cursorLeft([int cols = 1]) {}

  @override
  void cursorToColumn(int col) {}

  @override
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {}
}

final class _GatingProbe implements StartupProbe {
  _GatingProbe(this._started);

  final Completer<void> _started;

  bool _active = false;

  @override
  bool get isActive => _active;

  @override
  bool get gateNonCriticalMessages => true;

  @override
  Future<void> start(StartupProbeContext ctx) async {
    _active = true;
    _started.complete();
    // Keep active until explicitly deactivated.
  }

  @override
  bool handleMsg(Msg msg, StartupProbeContext ctx) {
    // Consume nothing: runner should buffer non-critical messages.
    return false;
  }

  void deactivate() {
    _active = false;
  }
}

void main() {
  test('StartupProbeRunner buffers while active and drains in order', () async {
    final started = Completer<void>();
    final probe = _GatingProbe(started);
    final runner = StartupProbeRunner([probe]);
    final ctx = StartupProbeContext(terminal: _TestTerminal());

    unawaited(runner.runAll(ctx));
    await started.future;

    // While probe is active, non-critical messages are buffered.
    expect(runner.intercept(const WindowSizeMsg(10, 10), ctx), true);
    expect(
      runner.intercept(
        const MouseMsg(
          action: MouseAction.motion,
          button: MouseButton.none,
          x: 1,
          y: 1,
          ctrl: false,
          alt: false,
          shift: false,
        ),
        ctx,
      ),
      true,
    );

    // Critical messages are not buffered (let Program handle them immediately).
    expect(runner.intercept(const QuitMsg(), ctx), false);

    // Deactivate and drain.
    probe.deactivate();
    final drained = <Msg>[];
    runner.drain(drained.add);
    expect(drained.length, 2);
    expect(drained[0], const WindowSizeMsg(10, 10));
    expect(drained[1] is MouseMsg, true);
  });
}
