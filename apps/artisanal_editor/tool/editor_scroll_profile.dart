import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal/args.dart' show ArgParser;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_editor/src/ui/editor_app.dart' show EditorScreen;
import 'package:artisanal_editor/src/workspace/editor_file_repository.dart';
import 'package:artisanal_editor/src/workspace/editor_workspace.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:devtools_region_profiler/devtools_region_profiler.dart'
    as profiler;

/// Runs a deterministic, production-renderer editor scrolling workload.
Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  final sandbox = await Directory.systemTemp.createTemp(
    'artisanal-editor-scroll-',
  );
  try {
    final source = File('${sandbox.path}/editor_scroll_fixture.dart');
    await source.writeAsString(_fixtureSource(options.documentLines));

    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    final buffer = await workspace.open(files.single);
    buffer.controller.setCursor(0, 0);

    late Map<String, Object?> result;
    // WidgetTester emits startup diagnostics. Preserve stdout for the JSON
    // report so the command is easy to automate.
    await runZoned(
      () async {
        final tester = WidgetTester(
          screenWidth: options.columns,
          screenHeight: options.rows,
          enableRenderer: true,
          altScreen: true,
        );
        try {
          await tester.pumpWidget(EditorScreen(workspace: workspace));
          final target = tester.locateText('benchmark line 0000');
          if (target == null) {
            throw StateError('Could not locate the editor scroll target.');
          }
          _drain(tester);

          _sendWheel(tester, x: target.x, y: target.y, down: true);
          final movement = buffer.controller.line > 0;
          _drain(tester);
          _sendWheel(tester, x: target.x, y: target.y, down: false);
          _drain(tester);
          if (!movement || buffer.controller.line != 0) {
            throw StateError(
              'Wheel input did not move and restore the editor viewport.',
            );
          }

          for (var i = 0; i < options.warmupRounds; i++) {
            _scrollRound(tester, buffer, target.x, target.y, options.steps);
          }

          final samplesUs = List<int>.filled(options.rounds, 0);
          final wheelSamplesUs = List<int>.filled(
            options.rounds * options.steps * 2,
            0,
          );
          final region = options.profile
              ? await profiler.startProfileRegion(
                  'artisanal_editor.scroll',
                  attributes: {
                    'columns': '${options.columns}',
                    'rows': '${options.rows}',
                    'documentLines': '${options.documentLines}',
                    'rounds': '${options.rounds}',
                    'stepsEachDirection': '${options.steps}',
                  },
                  options: const profiler.ProfileRegionOptions(
                    captureKinds: [profiler.ProfileCaptureKind.cpu],
                  ),
                )
              : null;
          final total = Stopwatch();
          try {
            total.start();
            for (var i = 0; i < options.rounds; i++) {
              final sample = Stopwatch()..start();
              final trace = _beginScrollRoundTrace(i + 1, options.steps);
              try {
                _scrollRound(
                  tester,
                  buffer,
                  target.x,
                  target.y,
                  options.steps,
                  wheelSamplesUs: wheelSamplesUs,
                  sampleOffset: i * options.steps * 2,
                );
              } finally {
                trace?.end();
              }
              sample.stop();
              samplesUs[i] = sample.elapsedMicroseconds;
            }
            total.stop();
          } finally {
            await region?.stop();
          }

          if (buffer.controller.line != 0) {
            throw StateError('Measured scrolling did not return to line 0.');
          }

          result = <String, Object?>{
            'benchmark': 'artisanal_editor_scroll',
            'documentLines': options.documentLines,
            'terminalDimensions': {
              'width': options.columns,
              'height': options.rows,
            },
            'scrollMovementAssertion': movement,
            'warmupRounds': options.warmupRounds,
            'rounds': options.rounds,
            'stepsEachDirection': options.steps,
            'wheelEventsPerRound': options.steps * 2,
            'profiled': options.profile,
            'samplesUs': samplesUs,
            'totalUs': total.elapsedMicroseconds,
            'meanUs': total.elapsedMicroseconds / options.rounds,
            'meanUsPerWheel':
                total.elapsedMicroseconds /
                (options.rounds * options.steps * 2),
            'wheelLatencyUs': _latencies(wheelSamplesUs),
          };
        } finally {
          await tester.dispose();
          workspace.dispose();
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {},
      ),
    );

    final encoded = jsonEncode(result);
    final outputPath = options.outputPath;
    if (outputPath == null) {
      stdout.writeln(encoded);
    } else {
      final output = File(outputPath);
      output.parent.createSync(recursive: true);
      output.writeAsStringSync('$encoded\n');
      stdout.writeln('wrote $outputPath');
    }
  } finally {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  }
}

void _scrollRound(
  WidgetTester tester,
  EditorBuffer buffer,
  int x,
  int y,
  int steps, {
  List<int>? wheelSamplesUs,
  int sampleOffset = 0,
}) {
  final timer = wheelSamplesUs == null ? null : Stopwatch();
  for (final down in [true, false]) {
    for (var i = 0; i < steps; i++) {
      timer
        ?..reset()
        ..start();
      _sendWheel(tester, x: x, y: y, down: down);
      _drain(tester);
      if (timer != null) {
        timer.stop();
        wheelSamplesUs![sampleOffset++] = timer.elapsedMicroseconds;
      }
    }
  }
  if (buffer.controller.line != 0) {
    throw StateError('Scroll round did not restore the starting cursor line.');
  }
}

void _sendWheel(
  WidgetTester tester, {
  required int x,
  required int y,
  required bool down,
}) {
  tester.sendMsg(
    runtime.MouseMsg(
      action: runtime.MouseAction.wheel,
      button: down
          ? runtime.MouseButton.wheelDown
          : runtime.MouseButton.wheelUp,
      x: x,
      y: y,
    ),
  );
}

void _drain(WidgetTester tester) => tester.clearRendererOutput();

runtime.TraceSpan? _beginScrollRoundTrace(int round, int steps) {
  if (!runtime.TuiTrace.enabled ||
      !runtime.TuiTrace.isTagEnabled(runtime.TraceTag.scroll)) {
    return null;
  }
  return runtime.TuiTrace.begin(
    'editor_scroll_round',
    tag: runtime.TraceTag.scroll,
    extra: 'round=$round steps=$steps',
  );
}

Map<String, int> _latencies(List<int> samples) {
  final sorted = [...samples]..sort();
  int percentile(double fraction) =>
      sorted[(sorted.length * fraction).ceil() - 1];
  return {
    'p50': percentile(0.50),
    'p95': percentile(0.95),
    'p99': percentile(0.99),
    'max': sorted.last,
  };
}

String _fixtureSource(int lines) {
  return List<String>.generate(
    lines,
    (index) => '// benchmark line ${index.toString().padLeft(4, '0')}',
    growable: false,
  ).join('\n');
}

final class _Options {
  const _Options({
    required this.rounds,
    required this.warmupRounds,
    required this.columns,
    required this.rows,
    required this.steps,
    required this.documentLines,
    required this.profile,
    required this.outputPath,
  });

  final int rounds;
  final int warmupRounds;
  final int columns;
  final int rows;
  final int steps;
  final int documentLines;
  final bool profile;
  final String? outputPath;

  static _Options parse(List<String> arguments) {
    final parser = ArgParser()
      ..addOption('rounds', defaultsTo: '10')
      ..addOption('warmup', defaultsTo: '3')
      ..addOption('columns', defaultsTo: '120')
      ..addOption('rows', defaultsTo: '32')
      ..addOption('steps', defaultsTo: '40')
      ..addOption('document-lines', defaultsTo: '2000')
      ..addFlag('profile', negatable: false)
      ..addOption('out');
    final parsed = parser.parse(arguments);
    if (parsed.rest.isNotEmpty) {
      throw ArgumentError('Unexpected positional arguments.');
    }

    int positive(String name) {
      final value = int.tryParse(parsed[name] as String? ?? '');
      if (value == null || value < 1) {
        throw ArgumentError('--$name must be a positive integer.');
      }
      return value;
    }

    final warmup = int.tryParse(parsed['warmup'] as String? ?? '');
    if (warmup == null || warmup < 0) {
      throw ArgumentError('--warmup must be a non-negative integer.');
    }

    return _Options(
      rounds: positive('rounds'),
      warmupRounds: warmup,
      columns: positive('columns'),
      rows: positive('rows'),
      steps: positive('steps'),
      documentLines: positive('document-lines'),
      profile: parsed['profile'] as bool,
      outputPath: parsed['out'] as String?,
    );
  }
}
