import 'dart:convert';
import 'dart:io';

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

    test('BackendTerminal emits ANSI sequences through embedded backend', () async {
      final writes = <String>[];
      final backend = EmbeddedTerminalBackend(output: writes.add);
      final terminal = BackendTerminal(backend);

      terminal.hideCursor();
      terminal.enterAltScreen();
      terminal.setTitle('Embedded');
      terminal.enableBracketedPaste();
      terminal.disableBracketedPaste();
      await terminal.flush();

      final output = writes.join();
      expect(output, contains(Ansi.cursorHide));
      expect(output, contains(Ansi.altScreenEnter));
      expect(output, contains(Ansi.setTitle('Embedded')));
      expect(output, contains(Ansi.bracketedPasteEnable));
      expect(output, contains(Ansi.bracketedPasteDisable));

      terminal.dispose();
    });

    test('TerminalBridge captures output and forwards input/resize', () async {
      final bridge = TerminalBridge();
      final outputChunks = <String>[];
      final outputSubscription = bridge.output.listen(outputChunks.add);
      final inputFuture = bridge.backend.inputStream!.first;
      final resizeFuture = bridge.backend.resizeStream!.first;

      bridge.terminal.setTitle('Bridge');
      await bridge.terminal.flush();
      bridge.addInputString('abc');
      bridge.resize(width: 120, height: 40);

      final input = await inputFuture;
      final resize = await resizeFuture;

      expect(outputChunks.join(), contains(Ansi.setTitle('Bridge')));
      expect(bridge.bufferedOutput, contains(Ansi.setTitle('Bridge')));
      expect(utf8.decode(input), 'abc');
      expect(resize.width, 120);
      expect(resize.height, 40);

      await outputSubscription.cancel();
      bridge.dispose();
    });

    test('SocketTerminalBackend strips OSC 9999 resize messages from input', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final accepted = server.first;
      final client = await Socket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
      );
      final serverSocket = await accepted;

      final backend = SocketTerminalBackend(serverSocket);
      final inputFuture = backend.inputStream!.first;
      final resizeFuture = backend.resizeStream!.first;

      client.add(utf8.encode('ab\x1b]9999;120;40\x07cd'));
      await client.flush();

      final input = await inputFuture;
      final resize = await resizeFuture;

      expect(utf8.decode(input), 'abcd');
      expect(resize.width, 120);
      expect(resize.height, 40);
      expect(backend.size.width, 120);
      expect(backend.size.height, 40);

      backend.dispose();
      await client.close();
      await server.close();
    });
  });
}
