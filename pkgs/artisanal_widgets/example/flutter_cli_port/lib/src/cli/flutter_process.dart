import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal/tui.dart' as runtime;

import '../model.dart';

final class FlutterProcessSpec {
  const FlutterProcessSpec({
    required this.arguments,
    this.workingDirectory,
    this.mode = FlutterCliBuildMode.debug,
  });

  final List<String> arguments;
  final String? workingDirectory;
  final FlutterCliBuildMode mode;
}

sealed class FlutterProcessMsg extends runtime.Msg {
  const FlutterProcessMsg();
}

final class FlutterProcessStarted extends FlutterProcessMsg {
  const FlutterProcessStarted(this.commandLine);

  final String commandLine;
}

final class FlutterProcessLine extends FlutterProcessMsg {
  const FlutterProcessLine({
    required this.line,
    required this.stderr,
    required this.event,
    required this.testEvent,
  });

  final String line;
  final bool stderr;
  final FlutterCliFlutterEvent? event;
  final FlutterCliTestEvent? testEvent;
}

final class FlutterProcessExited extends FlutterProcessMsg {
  const FlutterProcessExited(this.exitCode);

  final int exitCode;
}

final class FlutterProcessFailed extends FlutterProcessMsg {
  const FlutterProcessFailed(this.message);

  final String message;
}

runtime.Cmd listenToFlutterProcess(FlutterProcessSpec spec) {
  return runtime.Cmd.listen<FlutterProcessMsg>(
    streamFlutterProcess(spec),
    onData: (msg) => msg,
    onError: (error, stack) => FlutterProcessFailed(error.toString()),
  );
}

Stream<FlutterProcessMsg> streamFlutterProcess(FlutterProcessSpec spec) {
  late StreamController<FlutterProcessMsg> controller;
  Process? process;

  controller = StreamController<FlutterProcessMsg>(
    onListen: () async {
      final flutter = resolveFlutterBinary();
      if (flutter == null) {
        controller.add(
          const FlutterProcessFailed('flutter binary not found on PATH'),
        );
        await controller.close();
        return;
      }
      controller.add(
        FlutterProcessStarted(_shellLine(flutter, spec.arguments)),
      );
      try {
        process = await Process.start(
          flutter,
          spec.arguments,
          workingDirectory: spec.workingDirectory,
          mode: ProcessStartMode.normal,
        );
      } on Object catch (error) {
        controller.add(FlutterProcessFailed('failed to start flutter: $error'));
        await controller.close();
        return;
      }

      final stdoutDone = _pipeLines(
        process!.stdout,
        stderr: false,
        sink: controller,
      );
      final stderrDone = _pipeLines(
        process!.stderr,
        stderr: true,
        sink: controller,
      );
      final code = await process!.exitCode;
      await Future.wait([stdoutDone, stderrDone]);
      controller.add(FlutterProcessExited(code));
      await controller.close();
    },
    onCancel: () {
      process?.kill(ProcessSignal.sigterm);
    },
  );
  return controller.stream;
}

Future<void> _pipeLines(
  Stream<List<int>> stream, {
  required bool stderr,
  required StreamController<FlutterProcessMsg> sink,
}) async {
  await for (final line
      in stream.transform(utf8.decoder).transform(const LineSplitter())) {
    sink.add(
      FlutterProcessLine(
        line: line,
        stderr: stderr,
        event: parseFlutterEvent(line, stderr: stderr),
        testEvent: parseFlutterTestEvent(line),
      ),
    );
  }
}

String? resolveFlutterBinary() {
  final path = Platform.environment['PATH'];
  if (path == null || path.isEmpty) return null;
  final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
  for (final dir in path.split(Platform.isWindows ? ';' : ':')) {
    final candidate = File('$dir${Platform.pathSeparator}$executable');
    if (candidate.existsSync()) return candidate.path;
  }
  return null;
}

FlutterCliFlutterEvent? parseFlutterEvent(String line, {required bool stderr}) {
  final lower = line.toLowerCase();
  if (line.startsWith('Built ')) {
    return FlutterCliBuildLogEvent(FlutterCliLogLevel.info, line);
  }
  if (stderr || lower.contains('error') || lower.contains('exception')) {
    return FlutterCliBuildLogEvent(FlutterCliLogLevel.error, line);
  }
  if (lower.contains('warning')) {
    return FlutterCliBuildLogEvent(FlutterCliLogLevel.warn, line);
  }
  final progress = _progressMessage(line);
  if (progress != null) {
    return FlutterCliProgressEvent(
      id: progress.id,
      message: progress.message,
      finished: progress.finished,
    );
  }
  return FlutterCliBuildLogEvent(FlutterCliLogLevel.info, line);
}

({String id, String message, bool finished})? _progressMessage(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower.contains('launching')) {
    return (id: 'launch', message: trimmed, finished: false);
  }
  if (lower.contains('running gradle task')) {
    return (id: 'gradle', message: trimmed, finished: false);
  }
  if (lower.contains('running xcode build')) {
    return (id: 'xcode', message: trimmed, finished: false);
  }
  if (lower.contains('installing') || lower.contains('syncing files')) {
    return (id: 'install', message: trimmed, finished: false);
  }
  if (lower.contains('flutter run key commands') ||
      lower.contains('application finished') ||
      lower.contains('built ')) {
    return (id: 'ready', message: trimmed, finished: true);
  }
  return null;
}

FlutterCliTestEvent? parseFlutterTestEvent(String line) {
  Object? decoded;
  try {
    decoded = jsonDecode(line);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  final type = decoded['type'];
  return switch (type) {
    'testStart' => _parseTestStart(decoded),
    'testDone' => _parseTestDone(decoded),
    'error' => _parseTestError(decoded),
    'done' => FlutterCliAllDone(success: decoded['success'] == true),
    _ => null,
  };
}

FlutterCliTestStarted? _parseTestStart(Map<String, Object?> event) {
  final test = event['test'];
  if (test is! Map<String, Object?>) return null;
  final id = test['id'];
  final name = test['name'];
  if (id is! int || name is! String) return null;
  return FlutterCliTestStarted(id: id, name: name);
}

FlutterCliTestDone? _parseTestDone(Map<String, Object?> event) {
  final id = event['testID'];
  if (id is! int) return null;
  final result = switch (event['result']) {
    'success' => FlutterCliTestResult.success,
    'failure' => FlutterCliTestResult.failure,
    'error' => FlutterCliTestResult.error,
    'skipped' => FlutterCliTestResult.skipped,
    _ => FlutterCliTestResult.success,
  };
  final duration = event['time'] is int ? event['time'] as int : 0;
  return FlutterCliTestDone(
    id: id,
    name: event['name']?.toString() ?? '',
    result: result,
    durationMs: duration,
  );
}

FlutterCliTestError? _parseTestError(Map<String, Object?> event) {
  final id = event['testID'];
  final error = event['error'];
  final stack = event['stackTrace'];
  return FlutterCliTestError(
    id: id is int ? id : null,
    message: error?.toString() ?? 'flutter test error',
    stack: stack?.toString(),
  );
}

String _shellLine(String executable, List<String> args) {
  return ([executable, ...args]).map(_quoteShellArg).join(' ');
}

String _quoteShellArg(String value) {
  if (RegExp(r'^[A-Za-z0-9_./:=@+-]+$').hasMatch(value)) return value;
  return "'${value.replaceAll("'", r"'\''")}'";
}
