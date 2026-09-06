import 'dart:io';

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
  );

  try {
    await runWidgetApp(PseudoTerminalView(pty: pty));
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
