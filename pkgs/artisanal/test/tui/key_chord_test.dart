import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

void main() {
  group('KeyChordInterceptor', () {
    test('prefix then continuation resolves to a binding', () async {
      final received = <String>[];
      final model = _Model((msg) => received.add(msg.runtimeType.toString()));
      final interceptor = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding(
            id: 'open-themes',
            prefix: tui.KeyBinding.withHelp(
              ['ctrl+x'],
              'ctrl+x',
              'prefix',
            ),
            key: tui.KeyBinding.withHelp(['t'], 't', 'themes'),
          ),
        ],
      );

      await tui.runProgram(
        model,
        options: tui.ProgramOptions(
          altScreen: false,
          interceptor: interceptor,
        ),
      );

      expect(received, contains('KeyChordPrefixMsg'));
      expect(received, contains('KeyChordResolvedMsg'));
    });

    test('unmatched key cancels pending chord and forwards original key', () async {
      final received = <String>[];
      final model = _Model((msg) => received.add(msg.runtimeType.toString()));
      final interceptor = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding(
            id: 'open-themes',
            prefix: tui.KeyBinding.withHelp(
              ['ctrl+x'],
              'ctrl+x',
              'prefix',
            ),
            key: tui.KeyBinding.withHelp(['t'], 't', 'themes'),
          ),
        ],
      );

      await tui.runProgram(
        model,
        options: tui.ProgramOptions(
          altScreen: false,
          interceptor: interceptor,
        ),
      );

      expect(received, contains('KeyChordPrefixMsg'));
      expect(received, contains('KeyChordCancelledMsg'));
      expect(received, contains('KeyMsg'));
    });

    test('timeout cancels pending chord', () async {
      final received = <String>[];
      final model = _Model((msg) => received.add(msg.runtimeType.toString()));
      final interceptor = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding(
            id: 'open-themes',
            prefix: tui.KeyBinding.withHelp(
              ['ctrl+x'],
              'ctrl+x',
              'prefix',
            ),
            key: tui.KeyBinding.withHelp(['t'], 't', 'themes'),
          ),
        ],
        timeout: const Duration(milliseconds: 100),
      );

      await tui.runProgram(
        model,
        options: tui.ProgramOptions(
          altScreen: false,
          interceptor: interceptor,
        ),
      );

      expect(received, contains('KeyChordPrefixMsg'));
      expect(received, contains('KeyChordCancelledMsg'));
    });
  });
}

class _Model implements tui.Model {
  _Model(this._onMsg);
  final void Function(tui.Msg msg) _onMsg;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    _onMsg(msg);
    return (this, null);
  }

  @override
  String view() => '';
}
