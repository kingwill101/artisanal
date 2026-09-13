// Launches the soak under devtools-profiler and preserves its artifacts.
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.any((arg) => arg == '--help' || arg == '-h')) {
    stdout.writeln('Runs memory_soak.dart under devtools-profiler.');
    stdout.writeln(
      'Options are forwarded; --artifact-dir=PATH controls artifacts.',
    );
    return;
  }
  final artifact =
      _value(args, '--artifact-dir') ??
      '.dart_tool/devtools_profiler/artisanal_widgets_memory_soak';
  final forwarded = args
      .where((arg) => !arg.startsWith('--artifact-dir='))
      .toList();
  try {
    final result = await Process.run('devtools-profiler', [
      'run',
      '--no-forward-output',
      '--hide-sdk',
      '--hide-runtime-helpers',
      '--include-package',
      'artisanal_widgets',
      '--include-package',
      'artisanal',
      '--include-package',
      'ultraviolet',
      '--artifact-dir',
      artifact,
      '--',
      'dart',
      'run',
      Platform.script.resolve('memory_soak.dart').toFilePath(),
      ...forwarded,
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      stderr.writeln('devtools-profiler failed (${result.exitCode})');
      exitCode = result.exitCode;
      return;
    }
  } on ProcessException catch (error) {
    stderr.writeln('Unable to launch devtools-profiler: $error');
    exitCode = 127;
    return;
  }
  stderr.writeln('Profiler artifacts: ${Directory(artifact).absolute.path}');
}

String? _value(List<String> args, String name) {
  final prefix = '$name=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
