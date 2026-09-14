import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal/args.dart' show ArgParser;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_editor/src/ui/editor_app.dart' show EditorScreen;
import 'package:artisanal_editor/src/workspace/editor_file_repository.dart';
import 'package:artisanal_editor/src/workspace/editor_workspace.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart' show Element;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:devtools_region_profiler/devtools_region_profiler.dart'
    as profiler;

/// Profiles real scrollbar-thumb drags in the Markdown preview and editor.
Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  final sandbox = await Directory.systemTemp.createTemp(
    'artisanal-editor-scrollbar-drag-',
  );
  try {
    final source = File('${sandbox.path}/README.md');
    await source.writeAsString(_markdownFixture(options.documentLines));

    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    final buffer = await workspace.open(files.single);
    final canonicalPath = buffer.file.path;

    late Map<String, Object?> result;
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
          _drain(tester);
          final sgrMatches = RegExp('\u001b\\[([0-9:;]*)m')
              .allMatches(tester.view)
              .toList(growable: false);
          final uniqueSgrParams = sgrMatches
              .map((match) => match.group(1)!)
              .toSet();

          final previewBounds = _boundsForKey(
            tester,
            w.ValueKey('markdown-preview:$canonicalPath'),
          );
          final editorBounds = _boundsForKey(
            tester,
            w.ValueKey('editor-scrollbar:$canonicalPath'),
          );

          for (var i = 0; i < options.warmupRounds; i++) {
            _dragRound(tester, previewBounds, options.steps);
            _dragRound(tester, editorBounds, options.steps);
          }

          final preview = await _measureSurface(
            tester: tester,
            surface: 'markdown_preview',
            regionName: 'artisanal_editor.markdown_scrollbar_drag',
            bounds: previewBounds,
            options: options,
          );
          if (tester.locateText('Benchmark heading 0000') == null) {
            throw StateError(
              'Markdown preview drag did not restore the first heading.',
            );
          }

          final editor = await _measureSurface(
            tester: tester,
            surface: 'text_editor',
            regionName: 'artisanal_editor.editor_scrollbar_drag',
            bounds: editorBounds,
            options: options,
          );
          if (buffer.controller.line != 0) {
            throw StateError('Editor drag did not restore cursor line 0.');
          }

          result = <String, Object?>{
            'benchmark': 'artisanal_editor_scrollbar_drag',
            'documentLines': options.documentLines,
            'terminalDimensions': {
              'width': options.columns,
              'height': options.rows,
            },
            'warmupRounds': options.warmupRounds,
            'rounds': options.rounds,
            'motionsEachDirection': options.steps,
            'profiled': options.profile,
            'initialFrameSgrSequences': sgrMatches.length,
            'initialFrameUniqueSgrParams': uniqueSgrParams.length,
            'markdownPreview': preview,
            'textEditor': editor,
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
    if (options.outputPath case final path?) {
      final output = File(path)..parent.createSync(recursive: true);
      output.writeAsStringSync('$encoded\n');
      stdout.writeln('wrote $path');
    } else {
      stdout.writeln(encoded);
    }
  } finally {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  }
}

Future<Map<String, Object?>> _measureSurface({
  required WidgetTester tester,
  required String surface,
  required String regionName,
  required _Bounds bounds,
  required _Options options,
}) async {
  final roundSamples = List<int>.filled(options.rounds, 0);
  final motionSamples = <int>[];
  final region = options.profile
      ? await profiler.startProfileRegion(
          regionName,
          attributes: {
            'surface': surface,
            'rounds': '${options.rounds}',
            'motionsEachDirection': '${options.steps}',
          },
          options: const profiler.ProfileRegionOptions(
            captureKinds: [profiler.ProfileCaptureKind.cpu],
          ),
        )
      : null;
  final total = Stopwatch()..start();
  try {
    for (var round = 0; round < options.rounds; round++) {
      final sample = Stopwatch()..start();
      final trace = _beginDragTrace(surface, round + 1, options.steps);
      try {
        _dragRound(tester, bounds, options.steps, motionSamples: motionSamples);
      } finally {
        trace?.end();
      }
      sample.stop();
      roundSamples[round] = sample.elapsedMicroseconds;
    }
  } finally {
    total.stop();
    await region?.stop();
  }
  return {
    'bounds': bounds.toJson(),
    'samplesUs': roundSamples,
    'totalUs': total.elapsedMicroseconds,
    'meanRoundUs': total.elapsedMicroseconds / options.rounds,
    'roundLatencyUs': _latencies(roundSamples),
    'motionLatencyUs': _latencies(motionSamples),
  };
}

void _dragRound(
  WidgetTester tester,
  _Bounds bounds,
  int steps, {
  List<int>? motionSamples,
}) {
  final x = bounds.right - 1;
  final top = bounds.top;
  final bottom = bounds.bottom - 1;
  _drag(
    tester,
    x: x,
    fromY: top,
    toY: bottom,
    steps: steps,
    samples: motionSamples,
  );
  _drag(
    tester,
    x: x,
    fromY: bottom,
    toY: top,
    steps: steps,
    samples: motionSamples,
  );
}

void _drag(
  WidgetTester tester, {
  required int x,
  required int fromY,
  required int toY,
  required int steps,
  List<int>? samples,
}) {
  tester.mouseDown(x, fromY);
  _drain(tester);
  for (var step = 1; step <= steps; step++) {
    final y = fromY + ((toY - fromY) * step / steps).round();
    final timer = Stopwatch()..start();
    tester.sendMsg(
      runtime.MouseMsg(
        action: runtime.MouseAction.motion,
        button: runtime.MouseButton.left,
        x: x,
        y: y,
      ),
    );
    _drain(tester);
    timer.stop();
    samples?.add(timer.elapsedMicroseconds);
  }
  tester.mouseUp(x, toY);
  _drain(tester);
}

_Bounds _boundsForKey(WidgetTester tester, w.Key key) {
  final element = tester.find.firstByKey(key);
  if (element == null) throw StateError('Could not find widget key $key.');
  final renderObject = element.renderObject ?? _firstRenderObject(element);
  if (renderObject == null) {
    throw StateError('Widget key $key has no render object.');
  }
  var left = 0.0;
  var top = 0.0;
  w.RenderObject? current = renderObject;
  while (current != null) {
    left += current.offset.dx;
    top += current.offset.dy;
    current = current.parent;
  }
  return _Bounds(
    left: left.floor(),
    top: top.floor(),
    right: (left + renderObject.size.width).ceil(),
    bottom: (top + renderObject.size.height).ceil(),
  );
}

w.RenderObject? _firstRenderObject(Element element) {
  if (element.renderObject case final renderObject?) return renderObject;
  for (final child in element.children) {
    if (_firstRenderObject(child) case final renderObject?) return renderObject;
  }
  return null;
}

void _drain(WidgetTester tester) => tester.clearRendererOutput();

runtime.TraceSpan? _beginDragTrace(String surface, int round, int steps) {
  if (!runtime.TuiTrace.enabled ||
      !runtime.TuiTrace.isTagEnabled(runtime.TraceTag.scroll)) {
    return null;
  }
  return runtime.TuiTrace.begin(
    'editor_scrollbar_drag_round',
    tag: runtime.TraceTag.scroll,
    extra: 'surface=$surface round=$round motions=$steps',
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

String _markdownFixture(int lines) => List<String>.generate(
  lines,
  (index) => switch (index % 5) {
    0 => '## Benchmark heading ${index.toString().padLeft(4, '0')}',
    1 => '',
    2 =>
      'Paragraph $index with **bold text**, `inline code`, and a [link](https://example.com).',
    3 => '- list item $index with enough text to exercise Markdown wrapping',
    _ => '> quoted benchmark line $index',
  },
  growable: false,
).join('\n');

final class _Bounds {
  const _Bounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  Map<String, int> toJson() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };
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
      ..addOption('rounds', defaultsTo: '8')
      ..addOption('warmup', defaultsTo: '2')
      ..addOption('columns', defaultsTo: '140')
      ..addOption('rows', defaultsTo: '40')
      ..addOption('steps', defaultsTo: '12')
      ..addOption('document-lines', defaultsTo: '1000')
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
