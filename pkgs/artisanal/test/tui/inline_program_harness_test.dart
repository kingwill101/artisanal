import 'package:artisanal/src/terminal/terminal_base.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/model.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/program.dart';
import 'package:test/test.dart';

import 'inline_terminal_harness.dart';

void main() {
  test(
    'inline program keeps the view pinned while Cmd.println fills logs',
    () async {
      final terminal = StringTerminal(terminalWidth: 24, terminalHeight: 8);
      final program = Program(
        const _InlineLoggingProgram(),
        terminal: terminal,
        options: const ProgramOptions(
          screenMode: ScreenMode.inline,
          inlineHeight: 3,
          uiAnchor: UiAnchor.bottom,
          useUltravioletRenderer: true,
          startupProbes: false,
          fps: 120,
        ),
      );

      final runFuture = program.run();
      await _waitUntil(() => terminal.output.contains('program-log-8'));

      final vt = InlineVirtualTerminal(width: 24, height: 8)
        ..feed(terminal.output);

      expect(vt.line(6), contains('PIN A'));
      expect(vt.line(7), contains('PIN B'));
      expect(vt.line(8), contains('PIN C'));
      expect(vt.visibleLines.take(5).join('\n'), isNot(contains('PIN')));
      expect(vt.line(5), contains('program-log-8'));
      expect(vt.scrollback, contains('program-log-3'));
      expect(vt.scrollback.join('\n'), isNot(contains('PIN')));

      program.quit();
      await runFuture;
    },
  );
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < timeout) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('timed out waiting for inline program output');
}

final class _InlineLoggingProgram implements Model {
  const _InlineLoggingProgram();

  @override
  Cmd? init() =>
      Cmd.batch([for (var i = 1; i <= 8; i++) Cmd.println('program-log-$i')]);

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  String view() => 'PIN A\nPIN B\nPIN C';
}
