import 'dart:async';
import 'dart:io' as io;

import '../terminal/terminal_base.dart' show Terminal, SplitTerminal;
import '../terminal/backend.dart' show BackendTerminal;
import '../terminal/terminal_io_impl.dart' show StdioTerminal, TtyTerminal;

Map<String, String> get environment => io.Platform.environment;
bool get isWindows => io.Platform.isWindows;
bool get isLinux => io.Platform.isLinux;
bool get isMacOS => io.Platform.isMacOS;
String get lineTerminator => io.Platform.lineTerminator;
void stderrWriteln(String message) => io.stderr.writeln(message);
bool get stderrSupportsAnsi => io.stderr.supportsAnsiEscapes;
int get processId => io.pid;

typedef ProcessSignalWatcher = StreamSubscription<io.ProcessSignal>?;
ProcessSignalWatcher watchSigwinch(void Function() handler) {
  try {
    return io.ProcessSignal.sigwinch.watch().listen((_) => handler());
  } catch (_) {
    return null;
  }
}

ProcessSignalWatcher watchSigint(void Function() handler) {
  try {
    return io.ProcessSignal.sigint.watch().listen((_) => handler());
  } catch (_) {
    return null;
  }
}

void killProcess(int pid) {
  try {
    io.Process.killPid(pid, io.ProcessSignal.sigtstp);
  } catch (_) {}
}

Future<bool> executeProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  try {
    final result = await io.Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: isWindows,
    );
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<({int exitCode, String stdout, String stderr})?> runProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  try {
    final result = await io.Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: isWindows,
    );
    return (
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  } catch (_) {
    return null;
  }
}

Terminal createDefaultTerminal({bool inputTTY = false}) {
  if (inputTTY) {
    final control = TtyTerminal.tryOpen();
    if (control != null) {
      return SplitTerminal(control: control, output: StdioTerminal());
    }
  }
  return StdioTerminal();
}

Stream<List<int>>? ttyOpenRead() {
  try {
    if (io.Platform.isWindows) return null;
    final tty = io.File('/dev/tty');
    if (tty.existsSync()) {
      return tty.openRead();
    }
  } catch (_) {}
  return null;
}

bool canProbeTerminal(Object terminal) =>
    terminal is StdioTerminal ||
    terminal is SplitTerminal ||
    terminal is TtyTerminal ||
    terminal is BackendTerminal;
