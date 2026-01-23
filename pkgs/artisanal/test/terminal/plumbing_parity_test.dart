import 'package:artisanal/src/terminal/terminal.dart';
import 'package:test/test.dart';

class _OverrideTerminal extends StringTerminal {
  _OverrideTerminal({
    super.terminalWidth = 80,
    super.terminalHeight = 24,
    bool supportsAnsi = true,
    bool isTerminal = true,
    ({bool useTabs, bool useBackspace})? movementCaps,
  }) : _isTerminal = isTerminal,
       _movementCaps = movementCaps,
       super(ansiSupport: supportsAnsi);

  final bool _isTerminal;
  final ({bool useTabs, bool useBackspace})? _movementCaps;

  @override
  bool get isTerminal => _isTerminal;

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      _movementCaps ?? super.optimizeMovements();
}

void main() {
  group('Terminal Plumbing Parity', () {
    test('StdioTerminal optimizeMovements returns safe defaults', () {
      final terminal = StdioTerminal();
      final caps = terminal.optimizeMovements();
      expect(caps.useTabs, isFalse);
      expect(caps.useBackspace, isTrue);
    });

    test('StringTerminal optimizeMovements returns safe defaults', () {
      final terminal = StringTerminal();
      final caps = terminal.optimizeMovements();
      expect(caps.useTabs, isFalse);
      expect(caps.useBackspace, isTrue);
    });

    test('TtyTerminal.tryOpen with custom output sink', () {
      // We can't easily test real /dev/tty in unit tests without side effects,
      // but we can verify the API exists and handles null/custom sinks.
      // On non-Linux/macOS this will return null anyway.
      TtyTerminal.tryOpen(path: '/dev/null');
      // /dev/null is not a TTY, so it might return null or fail stty.
      // This is just a smoke test for the parameter.
    });

    test('SplitTerminal delegates output vs control correctly', () async {
      final control = _OverrideTerminal(terminalWidth: 111, terminalHeight: 22);
      final output = _OverrideTerminal(
        terminalWidth: 80,
        terminalHeight: 24,
        supportsAnsi: false,
        isTerminal: false,
      );

      final t = SplitTerminal(control: control, output: output);

      // Size is taken from control.
      expect(t.size.width, 111);
      expect(t.size.height, 22);

      // ANSI/TTY capabilities reflect output.
      expect(t.supportsAnsi, isFalse);
      expect(t.isTerminal, isFalse);

      // Writing goes to output.
      t.write('X');
      expect(output.output, contains('X'));
      expect(control.output, isNot(contains('X')));

      // Input-mode toggles go to control.
      t.enableBracketedPaste();
      expect(control.operations, contains('enableBracketedPaste'));

      // Display-mode toggles go to output.
      t.enterAltScreen();
      expect(output.operations, contains('enterAltScreen'));

      // Raw mode toggles go to control.
      expect(t.isRawMode, isFalse);
      t.enableRawMode();
      expect(t.isRawMode, isTrue);

      await t.flush();
      expect(output.operations, contains('flush'));
    });

    test('SplitTerminal optimizeMovements comes from control', () {
      final control = _OverrideTerminal(
        movementCaps: (useTabs: true, useBackspace: false),
      );
      final output = _OverrideTerminal(
        movementCaps: (useTabs: false, useBackspace: true),
      );

      final t = SplitTerminal(control: control, output: output);
      final caps = t.optimizeMovements();
      expect(caps.useTabs, isTrue);
      expect(caps.useBackspace, isFalse);
    });
  });
}
