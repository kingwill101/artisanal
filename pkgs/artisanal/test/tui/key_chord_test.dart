import 'dart:async';

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/bubbles.dart';
import 'package:test/test.dart';

void main() {
  group('KeyChordInterceptor', () {
    test('prefix then continuation resolves to a binding', () async {
      final received = <String>[];
      final input = StreamController<List<int>>();
      tui.Program<tui.Model>? program;
      final model = _Model(
        (msg) => received.add(msg.runtimeType.toString()),
        onQuit: () => program?.send(const tui.QuitMsg()),
      );
      final interceptor = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding(
            id: 'open-themes',
            prefix: KeyBinding.withHelp(
              ['ctrl+x'],
              'ctrl+x',
              'prefix',
            ),
            key: KeyBinding.withHelp(['t'], 't', 'themes'),
          ),
        ],
      );

      program = tui.Program(
        model,
        options: tui.ProgramOptions(
          altScreen: false,
          interceptor: interceptor,
          input: input.stream,
          frameTick: false,
        ),
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      input.add([0x18]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      input.add([0x74]);
      await runFuture;
      await input.close();

      expect(received, contains('KeyChordPrefixMsg'));
      expect(received, contains('KeyChordResolvedMsg'));
    });

    test('unmatched key cancels pending chord and forwards original key', () async {
      final received = <String>[];
      final input = StreamController<List<int>>();
      tui.Program<tui.Model>? program;
      final model = _Model(
        (msg) => received.add(msg.runtimeType.toString()),
        onQuit: () => program?.send(const tui.QuitMsg()),
      );
      final interceptor = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding(
            id: 'open-themes',
            prefix: KeyBinding.withHelp(
              ['ctrl+x'],
              'ctrl+x',
              'prefix',
            ),
            key: KeyBinding.withHelp(['t'], 't', 'themes'),
          ),
        ],
      );

      program = tui.Program(
        model,
        options: tui.ProgramOptions(
          altScreen: false,
          interceptor: interceptor,
          input: input.stream,
          frameTick: false,
        ),
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      input.add([0x18]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      input.add([0x61]);
      await runFuture;
      await input.close();

      expect(received, contains('KeyChordPrefixMsg'));
      expect(received, contains('KeyChordCancelledMsg'));
      expect(received, contains('KeyMsg'));
    });

    test('timeout cancels pending chord', () async {
      final received = <String>[];
      final input = StreamController<List<int>>();
      tui.Program<tui.Model>? program;
      final model = _Model(
        (msg) => received.add(msg.runtimeType.toString()),
        onQuit: () => program?.send(const tui.QuitMsg()),
      );
      final interceptor = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding(
            id: 'open-themes',
            prefix: KeyBinding.withHelp(
              ['ctrl+x'],
              'ctrl+x',
              'prefix',
            ),
            key: KeyBinding.withHelp(['t'], 't', 'themes'),
          ),
        ],
        timeout: const Duration(milliseconds: 100),
      );

      program = tui.Program(
        model,
        options: tui.ProgramOptions(
          altScreen: false,
          interceptor: interceptor,
          input: input.stream,
          frameTick: false,
        ),
      );

      final runFuture = program.run();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      input.add([0x18]);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await runFuture;
      await input.close();

      expect(received, contains('KeyChordPrefixMsg'));
      expect(received, contains('KeyChordCancelledMsg'));
    });
  });
}

class _Model implements tui.Model {
  _Model(this._onMsg, {this.onQuit});
  final void Function(tui.Msg msg) _onMsg;
  final void Function()? onQuit;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    _onMsg(msg);
    if (onQuit != null &&
        (msg is tui.KeyChordResolvedMsg || msg is tui.KeyChordCancelledMsg)) {
      onQuit!();
    }
    return (this, null);
  }

  @override
  String view() => '';
}
