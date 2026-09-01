import 'package:artisanal/artisanal.dart' as hosts;
import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/uv.dart' as uv;
import 'package:test/test.dart';

class _DemoModel implements runtime.Model {
  const _DemoModel();

  @override
  runtime.Cmd? init() => null;

  @override
  (runtime.Model, runtime.Cmd?) update(runtime.Msg msg) => (this, null);

  @override
  String view() => 'demo';
}

void main() {
  test('stable runtime entrypoint exposes the core TUI surface', () {
    const model = _DemoModel();
    const options = runtime.ProgramOptions();
    final noSuspendSignal = options.withoutSuspendSignal();
    final replay = runtime.ProgramReplay.script(
      const <runtime.ProgramReplayStep>[],
    );
    final terminal = runtime.StringTerminal();

    expect(model, isA<runtime.Model>());
    expect(options, isA<runtime.ProgramOptions>());
    expect(noSuspendSignal.sendSuspendSignal, isFalse);
    expect(terminal, isA<runtime.StringTerminal>());
    expect(replay.toStream(), isA<Stream<runtime.Msg>>());
    expect(runtime.runProgram, isA<Function>());
    expect(runtime.Cmd.quit, isA<Function>());
    expect(runtime.Cmd.suspend, isA<Function>());
    expect(runtime.SuspendMsg, isA<Type>());
    expect(runtime.ZoneInBoundsMsg, isA<Type>());
    expect(runtime.TuiTrace.log, isA<Function>());
  });

  test('stable hosts entrypoint exposes backend and host helpers', () {
    final bridge = hosts.TerminalBridge();
    final backend = hosts.EmbeddedTerminalBackend(output: (_) {});
    final host = hosts.ProgramHost.bridge(bridge);
    const message = hosts.TerminalBridgeMessage.output('hi');

    expect(bridge, isA<hosts.TerminalBridge>());
    expect(backend, isA<hosts.TerminalBackend>());
    expect(host, isA<hosts.ProgramHost>());
    expect(message.type, hosts.TerminalBridgeMessageType.output);
    expect(hosts.BrowserTerminalHostServer.defaultPageHtml, isA<Function>());
    expect(
      hosts.SocketTerminalHostServer.resizeControlSequence,
      isA<Function>(),
    );
  });

  test('stable UV entrypoint exposes effects primitives', () {
    final filter = uv.ColorMatrixFilter.tint(const uv.UvRgb(255, 0, 0));
    final color = filter.matrix.transformColor(const uv.UvRgb(0, 0, 255));

    expect(color, const uv.UvRgb(128, 0, 128));
    expect(uv.TerminalRenderer, isA<Type>());
    expect(uv.cutAnsiByCells('hello', 1, 4), 'ell');
    expect(uv.truncateLeftAnsiByCells('hello', 2), 'llo');
  });
}
