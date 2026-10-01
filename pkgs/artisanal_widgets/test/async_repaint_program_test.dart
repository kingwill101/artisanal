import 'dart:async';

import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  test('async state changes repaint without input or frame ticks', () async {
    final terminal = MockTerminal();
    final changed = Completer<void>();
    final app = WidgetApp(_AsyncStateProbe(changed.future));
    final program = Program(
      app,
      terminal: terminal,
      options: const ProgramOptions(
        altScreen: false,
        frameTick: false,
        startupProbes: false,
        useUltravioletRenderer: true,
      ),
    );
    final running = program.run();
    try {
      await _waitForOutput(terminal, 'AAAAA');
      terminal.output.clear();
      changed.complete();
      await _waitForOutput(terminal, 'ZZZZZ');
    } finally {
      program.quit();
      await running;
      app.dispose();
    }
  });
}

Future<void> _waitForOutput(MockTerminal terminal, String text) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!terminal.output.join().contains(text)) {
    if (DateTime.now().isAfter(deadline)) {
      fail('No repaint containing $text: ${terminal.output}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _AsyncStateProbe extends StatefulWidget {
  _AsyncStateProbe(this.changed);

  final Future<void> changed;

  @override
  State<_AsyncStateProbe> createState() => _AsyncStateProbeState();
}

class _AsyncStateProbeState extends State<_AsyncStateProbe> {
  var _text = 'AAAAA';

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.changed.then((_) {
        if (mounted) setState(() => _text = 'ZZZZZ');
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Text(_text);
}
