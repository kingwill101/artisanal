import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  test('setting visibility is idempotent and preserves diagnostics', () {
    final controller = ProgramDevToolsController(
      ProgramDiagnosticsOptions(captureOutput: false),
    );
    controller.handle(const WindowSizeMsg(80, 24));
    controller.diagnostics.recordMessage(
      const CustomMsg('kept'),
      Duration.zero,
    );
    expect(controller.setVisible(true), isTrue);
    final revision = controller.revision;
    expect(controller.setVisible(true), isFalse);
    expect(controller.revision, revision);
    expect(controller.visible, isTrue);
    expect(controller.setVisible(false), isTrue);
    expect(controller.diagnostics.messages, hasLength(1));
    expect(controller.diagnostics.output, isEmpty);
  });

  for (final available in [false, true]) {
    test('runtime reports visibility and availability: $available', () async {
      final model = _VisibilityModel([
        Cmd.requestDevToolsState(),
        Cmd.setDevToolsVisible(true),
        Cmd.setDevToolsVisible(true),
        Cmd.setDevToolsVisible(false),
        if (available) Cmd(() async => const KeyMsg(Key(KeyType.f12))),
      ]);
      final program = Program(
        model,
        options: ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
          diagnostics: available
              ? ProgramDiagnosticsOptions(captureOutput: false)
              : null,
        ),
        terminal: StringTerminal(terminalWidth: 80, terminalHeight: 24),
      );
      await program.run().timeout(const Duration(seconds: 5));
      expect(
        model.states.map((state) => state.available),
        everyElement(available),
      );
      expect(
        model.states.map((state) => state.visible),
        available
            ? [false, true, true, false, true]
            : [false, false, false, false],
      );
      expect(model.leakedRequests, 0);
      expect(model.states.map((state) => state.isCommandResponse), [
        true,
        true,
        true,
        true,
        if (available) false,
      ]);
    });
  }

  test('startup visibility can be queried and restored explicitly', () async {
    final model = _VisibilityModel([
      Cmd.requestDevToolsState(),
      Cmd.setDevToolsVisible(false),
    ]);
    await Program(
      model,
      options: ProgramOptions(
        altScreen: false,
        hideCursor: false,
        startupProbes: false,
        frameTick: false,
        useUltravioletRenderer: false,
        diagnostics: ProgramDiagnosticsOptions(
          initiallyVisible: true,
          captureOutput: false,
        ),
      ),
      terminal: StringTerminal(terminalWidth: 80, terminalHeight: 24),
    ).run().timeout(const Duration(seconds: 5));
    expect(model.states.map((state) => state.visible), [true, false]);
  });
}

class _VisibilityModel implements Model {
  _VisibilityModel(this.commands);

  final List<Cmd> commands;
  final List<DevToolsStateMsg> states = [];
  int leakedRequests = 0;

  @override
  Cmd init() => commands.first;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is SetDevToolsVisibleMsg || msg is RequestDevToolsStateMsg) {
      leakedRequests++;
    }
    if (msg is DevToolsStateMsg) {
      states.add(msg);
      return (
        this,
        states.length < commands.length ? commands[states.length] : Cmd.quit(),
      );
    }
    return (this, null);
  }

  @override
  String view() => 'Application';
}
