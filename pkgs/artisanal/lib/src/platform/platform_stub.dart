import 'dart:async';

import '../terminal/terminal_base.dart' show Terminal;

Map<String, String> get environment => const {};
bool get isWindows => false;
bool get isLinux => false;
bool get isMacOS => false;
String get lineTerminator => '\n';
void stderrWriteln(String message) {}
bool get stderrSupportsAnsi => false;
int get processId => 0;

typedef ProcessSignalWatcher = StreamSubscription<void>?;
ProcessSignalWatcher watchSigwinch(void Function() handler) => null;
ProcessSignalWatcher watchSigint(void Function() handler) => null;
void killProcess(int pid) {}

Future<bool> executeProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async => false;

Future<({int exitCode, String stdout, String stderr})?> runProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async => null;

Terminal createDefaultTerminal({bool inputTTY = false}) =>
    throw UnsupportedError('Default terminal requires dart:io');

Stream<List<int>>? ttyOpenRead() => null;

bool canProbeTerminal(Object terminal) => false;
