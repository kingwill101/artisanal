// Runs the benchmark under devtools-profiler and enriches its JSON report with
// observed allocation bytes and instances per operation.

import 'dart:convert';
import 'dart:io';

import 'src/allocation_accounting.dart';

Future<void> main(List<String> arguments) async {
  String? outputPath;
  String? artifactPath;
  final benchmarkArguments = <String>[];
  for (final argument in arguments) {
    if (argument.startsWith('--output=')) {
      outputPath = argument.substring('--output='.length);
    } else if (argument.startsWith('--artifact-dir=')) {
      artifactPath = argument.substring('--artifact-dir='.length);
    } else if (argument == '--help' || argument == '-h') {
      stdout.writeln(
        'Usage: allocation_profile [--output=path] [--artifact-dir=path] '
        '[baseline options]',
      );
      return;
    } else {
      benchmarkArguments.add(argument);
    }
  }

  final packageDirectory = File.fromUri(Platform.script).parent.parent;
  final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final artifactDirectory = Directory(
    artifactPath ??
        '${packageDirectory.path}/.dart_tool/devtools_profiler/'
            'uv_allocations_$timestamp',
  ).absolute;
  final temporaryDirectory = await Directory.systemTemp.createTemp(
    'ultraviolet_allocations_',
  );
  final timingFile = File('${temporaryDirectory.path}/timings.json');

  try {
    final profiler = await Process.run('devtools-profiler', <String>[
      'run',
      '--no-forward-output',
      '--hide-sdk',
      '--hide-runtime-helpers',
      '--include-package',
      'ultraviolet',
      '--artifact-dir',
      artifactDirectory.path,
      '--',
      'dart',
      'run',
      'benchmark/baseline.dart',
      '--json-output=${timingFile.path}',
      ...benchmarkArguments,
    ], workingDirectory: packageDirectory.path);
    if (profiler.exitCode != 0) {
      stderr
        ..write(profiler.stdout)
        ..write(profiler.stderr);
      exitCode = profiler.exitCode;
      return;
    }
    if (!timingFile.existsSync()) {
      stderr.writeln('The benchmark did not produce its timing JSON report.');
      exitCode = 1;
      return;
    }

    final timingJson =
        (jsonDecode(await timingFile.readAsString()) as Map<Object?, Object?>)
            .cast<String, Object?>();
    final report = await addAllocationAccounting(
      report: timingJson,
      sessionDirectory: artifactDirectory,
    );
    final encoded = const JsonEncoder.withIndent('  ').convert(report);
    if (outputPath == null) {
      stdout.writeln(encoded);
    } else {
      final output = File(outputPath);
      output.parent.createSync(recursive: true);
      await output.writeAsString('$encoded\n');
      stderr.writeln('Allocation report: ${output.absolute.path}');
    }
    stderr.writeln('Profiler artifacts: ${artifactDirectory.path}');
  } on ProcessException catch (error) {
    stderr.writeln('Unable to launch devtools-profiler: $error');
    exitCode = 127;
  } finally {
    await temporaryDirectory.delete(recursive: true);
  }
}
