import 'package:artisanal/artisanal.dart' as hosts;
import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/artisanal.dart' as testing;
import 'package:artisanal/widgets.dart' as widgets;
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

class _DemoKeyMap extends widgets.KeyMap {
  _DemoKeyMap() {
    shortHelp = [help, quit];
    fullHelp = [
      [help],
      [quit],
    ];
  }

  final help = widgets.KeyBinding.withHelp(['?'], '?', 'help');
  final quit = widgets.KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'quit');
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

  test(
    'stable plugins entrypoint exposes the remote plugin protocol surface',
    () async {
      const validator = plugins.RemotePluginProtocolValidator();
      const message = plugins.RemotePluginBlurInput(surfaceId: 'sidebar');

      final errors = await validator.validateMessage(message);

      expect(plugins.remotePluginProtocolVersion, isNotEmpty);
      expect(
        plugins.RemotePluginProtocolSchemas.schemaForType(
          plugins.RemotePluginMessageType.hostInputBlur,
        ),
        isA<plugins.Schema>(),
      );
      expect(plugins.RemotePluginJsonChannel, isA<Type>());
      expect(plugins.RemotePluginGuestSession, isA<Type>());
      expect(plugins.RemotePluginSession, isA<Type>());
      expect(plugins.RemotePluginProcess, isA<Type>());
      expect(plugins.RemotePluginSurfaceStore, isA<Type>());
      expect(plugins.RemotePluginJsonTransport.encodeLine, isA<Function>());
      expect(errors, isEmpty);
    },
  );

  test('stable widget re-export entrypoints stay available from artisanal', () {
    final shell = widgets.ArtisanalApp(
      title: 'Demo',
      home: widgets.Text('hello'),
    );
    final textField = widgets.TextField(
      controller: widgets.TextEditingController(text: 'hello'),
    );
    final tester = testing.WidgetTester();

    expect(shell, isA<widgets.ArtisanalApp>());
    expect(textField, isA<widgets.TextField>());
    expect(tester, isA<testing.WidgetTester>());
  });

  test('stable widgets entrypoint exposes the high-level widget surface', () {
    final keyMap = _DemoKeyMap();
    final shell = widgets.ArtisanalApp(
      title: 'Demo',
      home: widgets.HelpView(keyMap: keyMap),
    );

    expect(shell, isA<widgets.ArtisanalApp>());
    expect(keyMap, isA<widgets.KeyMap>());
    expect(keyMap.shortHelp, hasLength(2));
    expect(widgets.ZoneInBoundsMsg, isA<Type>());
  });
}
