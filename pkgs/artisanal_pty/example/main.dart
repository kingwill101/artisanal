import 'dart:io';

import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_pty/widgets.dart';
import 'package:artisanal_widgets/app.dart';
import 'package:pty2/pty2.dart';

Future<void> main() async {
  final (:executable, :arguments) = _defaultShell();
  final pty = PseudoTerminal.start(
    executable,
    arguments,
    environment: {...Platform.environment, 'TERM': 'xterm-256color'},
    workingDirectory: Directory.current.path,
    ackProcessed: true,
    raw: false,
  );

  try {
    await runWidgetApp(
      ArtisanalApp(
        title: 'Artisanal PTY',
        home: PseudoTerminalView(pty: pty),
      ),
      options: runtime.ProgramOptions().withoutInterruptMsg(),
    );
  } finally {
    pty.kill();
  }
}

({String executable, List<String> arguments}) _defaultShell() {
  if (Platform.isWindows) {
    return (
      executable: Platform.environment['COMSPEC'] ?? 'powershell.exe',
      arguments: const [],
    );
  }

  return (
    executable: Platform.environment['SHELL'] ?? '/bin/sh',
    arguments: const ['-i'],
  );
}
