import 'dart:async';
import 'package:artisanal/src/tui/program.dart';
import 'package:artisanal/src/tui/terminal.dart';
import 'package:artisanal/src/tui/model.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:test/test.dart';

class MockTerminal extends StringTerminal {
  MockTerminal({int width = 80, int height = 24})
    : _width = width,
      _height = height,
      super(terminalWidth: width, terminalHeight: height);

  int _width;
  int _height;

  @override
  int get width => _width;
  @override
  int get height => _height;
  @override
  ({int width, int height}) get size => (width: _width, height: _height);

  set width(int v) => _width = v;
  set height(int v) => _height = v;
}

class SimpleModel implements Model {
  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg &&
        msg.key.type == KeyType.runes &&
        msg.key.runes.isNotEmpty) {
      if (String.fromCharCode(msg.key.runes.first) == 'q') {
        return (this, Cmd.quit());
      }
    }
    return (this, null);
  }

  @override
  String view() => 'Hello UV';
}

Future<void> waitForRender(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
  String? reason,
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail(reason ?? 'Timed out waiting for render');
}

void main() {
  test('UltravioletTuiRenderer emits output on first render', () async {
    final terminal = MockTerminal(width: 80, height: 24);
    final program = Program(
      SimpleModel(),
      options: const ProgramOptions(
        useUltravioletRenderer: true,
        altScreen: false,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();
    await waitForRender(
      () => terminal.output.contains('Hello UV'),
      reason: 'Initial render did not contain Hello UV',
    );

    expect(terminal.output, contains('Hello UV'));
    expect(terminal.operations, contains('flush'));

    terminal.simulateTyping('q');
    await runFuture;
  });

  test(
    'UltravioletTuiRenderer emits output on first render (altScreen)',
    () async {
      final terminal = MockTerminal(width: 80, height: 24);
      final program = Program(
        SimpleModel(),
        options: const ProgramOptions(
          useUltravioletRenderer: true,
          altScreen: true,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await waitForRender(
        () => terminal.output.contains('Hello UV'),
        reason: 'Initial alt-screen render did not contain Hello UV',
      );

      expect(terminal.output, contains('Hello UV'));
      expect(terminal.operations, contains('flush'));

      terminal.simulateTyping('q');
      await runFuture;
    },
  );

  test('UltravioletTuiRenderer handles resize correctly', () async {
    final terminal = MockTerminal(width: 80, height: 24);
    final program = Program(
      SimpleModel(),
      options: const ProgramOptions(
        useUltravioletRenderer: true,
        altScreen: true,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();
    await waitForRender(
      () => terminal.output.contains('Hello UV'),
      reason: 'Initial render before resize did not contain Hello UV',
    );

    expect(terminal.output, contains('Hello UV'));
    expect(terminal.operations, contains('flush'));
    terminal.clear();

    // Simulate resize
    terminal.width = 40;
    terminal.height = 10;
    program.send(WindowSizeMsg(40, 10));

    await waitForRender(
      () => terminal.output.contains('Hello UV'),
      reason: 'Render after resize did not contain Hello UV',
    );

    // Should have re-rendered because _ensureSize detected size change
    expect(terminal.output, contains('Hello UV'));
    expect(terminal.operations, contains('flush'));

    terminal.simulateTyping('q');
    await runFuture;
  });
}
