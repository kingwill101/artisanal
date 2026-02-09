import 'dart:async';
import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm_cli/src/deps/fs.dart';
import 'package:nocterm_cli/src/deps/log.dart';
import 'package:nocterm_cli/utils/cli_command.dart';

/// A broadcast stream of the stdin stream.
// ignore: unnecessary_late
late final Stream<List<int>> _stdinStream = stdin.asBroadcastStream();
StreamSubscription? _clientSubscription;

class ShellCommand extends CliCommand {
  ShellCommand();

  @override
  String get description => '''
Start a nocterm shell server that nocterm apps can render into. This allows running nocterm apps from IDEs with debugger support.

This allows running nocterm apps from IDEs with debugger support.''';

  @override
  String get name => 'shell';

  @override
  Future<int> run() async {
    log('Starting nocterm shell server...');

    // Create global nocterm directory for this project
    await ensureNoctermDirectoryExists();

    // Create a Unix domain socket
    final socketPath = getShellSocketPath();
    final socketFile = fs.file(socketPath);
    if (await socketFile.exists()) {
      await socketFile.delete(); // Remove stale socket
    }

    final server = await ServerSocket.bind(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );

    // Write socket path to handle file
    final handleFile = fs.file(getShellHandlePath());
    await handleFile.writeAsString(socketPath);

    log('Shell server ready at: $socketPath');
    log('Waiting for nocterm app to connect...');
    log('Press Ctrl+C to stop the shell.');

    try {
      if (stdin.echoMode) stdin.echoMode = false;
      if (stdin.lineMode) stdin.lineMode = false;
    } catch (_) {}

    _cleanUpOnQuit();

    try {
      _clientSubscription = server.listen((client) async {
        await _handleClient(client);

        // exit alternate screen
        stdout.write(EscapeCodes.mainBuffer);

        // TODO(mrgnhnt): User is required to ctrl+c twice to exit the program.. why?
      });

      await _clientSubscription?.asFuture();
    } finally {
      await server.close();
      if (await handleFile.exists()) {
        await handleFile.delete();
      }
      if (await socketFile.exists()) {
        await socketFile.delete();
      }
    }

    return 0;
  }

  void _cleanUpOnQuit() {
    StreamSubscription? sigintSubscription;
    StreamSubscription? sigtermSubscription;

    void clean() {
      _clientSubscription?.cancel();
      sigintSubscription?.cancel();
      sigtermSubscription?.cancel();

      // IMPORTANT: Disable mouse tracking and bracketed paste BEFORE leaving alternate screen
      // This ensures the terminal properly processes the disable commands
      stdout.write(EscapeCodes.disable.motionTracking);
      stdout.write(EscapeCodes.disable.sgrMouseMode);
      stdout.write(EscapeCodes.disable.buttonEventTracking);
      stdout.write(EscapeCodes.disable.basicMouseTracking);

      stdout.write(EscapeCodes.showCursor);

      try {
        if (!stdin.echoMode) stdin.echoMode = true;
        if (!stdin.lineMode) stdin.lineMode = true;
      } catch (_) {}
    }

    // Forward signals to child process
    sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
      clean();
    });

    if (Platform.isMacOS || Platform.isLinux) {
      sigtermSubscription = ProcessSignal.sigterm.watch().listen((_) {
        clean();
      });
    }
  }

  Future<void> _handleClient(Socket client) async {
    StreamSubscription? stdinSubscription;
    StreamSubscription? sigwinchSubscription;

    try {
      // Put terminal in raw mode to pass through all input
      if (stdin.echoMode) stdin.echoMode = false;
      if (stdin.lineMode) stdin.lineMode = false;

      // Send initial terminal size to client using a custom OSC sequence
      // Format: ESC ] 9999 ; <cols> ; <rows> BEL
      _sendTerminalSize(client);

      // Forward stdin to client app (input events)
      stdinSubscription = _stdinStream.listen((data) {
        client.add(data);
      });

      // Forward client output to stdout (terminal rendering)
      final clientSubscription = client.listen(
        (data) {
          stdout.add(data);
        },
        onDone: () {
          // Client disconnected
        },
      );

      // Send terminal size changes to client on SIGWINCH
      if (Platform.isMacOS || Platform.isLinux) {
        sigwinchSubscription = ProcessSignal.sigwinch.watch().listen((_) {
          _sendTerminalSize(client);
        });
      }

      // Wait for client to disconnect
      await clientSubscription.asFuture();
    } finally {
      await stdinSubscription?.cancel();
      await sigwinchSubscription?.cancel();
    }
  }

  /// Send terminal size to client using custom OSC sequence
  /// Format: ESC ] 9999 ; `<cols>` ; `<rows>` BEL
  void _sendTerminalSize(Socket client) {
    if (stdout.hasTerminal) {
      final cols = stdout.terminalColumns;
      final rows = stdout.terminalLines;

      // Use OSC 9999 as our custom sequence for terminal size
      // This won't interfere with normal terminal output
      final sizeSequence = '\x1b]9999;$cols;$rows\x07';
      client.add(sizeSequence.codeUnits);
    }
  }
}
