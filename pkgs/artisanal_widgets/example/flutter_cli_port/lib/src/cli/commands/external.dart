import 'dart:io';

import '../flutter_process.dart';

Future<void> runExternalCommand(
  List<String> args, {
  String? workingDirectory,
}) async {
  final flutter = resolveFlutterBinary();
  if (flutter == null) {
    stderr.writeln('flutter binary not found on PATH');
    exitCode = 1;
    return;
  }
  final process = await Process.start(
    flutter,
    args,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) exitCode = code;
}
