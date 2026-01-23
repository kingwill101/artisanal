import 'dart:async';

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

import 'program_test.dart' show MockTerminal;

final class _StaticModel implements Model {
  const _StaticModel();

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  Object view() => 'HELLO';
}

void main() {
  test(
    'ClearScreenMsg forces a full redraw even if the view is unchanged',
    () async {
      final terminal = MockTerminal();
      final program = Program(
        const _StaticModel(),
        terminal: terminal,
        options: const ProgramOptions(
          altScreen: true,
          hideCursor: false,
          signalHandlers: false,
          fps: 120,
          useUltravioletInputDecoder: false,
        ),
      );

      final runFuture = program.run();

      Future<int> helloWrites() async {
        // Allow the event loop to process pending render work.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return terminal.operations
            .where((op) => op.startsWith('write: ') && op.contains('HELLO'))
            .length;
      }

      final before = await helloWrites();
      expect(before, greaterThanOrEqualTo(1));

      program.send(const ClearScreenMsg());
      final after = await helloWrites();

      // Without a forced redraw, fullscreen renderers will often skip because the
      // view string hasn't changed, leaving the cleared terminal blank.
      expect(after, greaterThanOrEqualTo(before));

      program.quit();
      await runFuture;
    },
  );
}
