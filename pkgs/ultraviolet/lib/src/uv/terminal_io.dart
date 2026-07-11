import 'dart:async';
import 'dart:io';

Stream<List<int>> get defaultInput => stdin;

StringSink get defaultOutput => stdout;

List<String> get defaultEnv =>
    Platform.environment.entries.map((e) => '${e.key}=${e.value}').toList();

bool get defaultIsWindows => Platform.isWindows;

bool get defaultIsTty => stdout.hasTerminal;

StreamSubscription<Object?>? watchSigint(void Function() handler) =>
    ProcessSignal.sigint.watch().listen((_) => handler());

void exitProcess() => exit(0);

bool isStdin(Stream<List<int>> input) => input == stdin;

bool get stdinHasTerminal => stdin.hasTerminal;

void enterRawMode() {
  stdin.echoMode = false;
  stdin.lineMode = false;
}

void exitRawMode() {
  stdin.echoMode = true;
  stdin.lineMode = true;
}
