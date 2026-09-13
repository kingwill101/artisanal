// Deterministic, headless production-UV memory-soak workload.
//
// This intentionally lives outside lib/: it is a diagnostic consumer of the
// public widget/testing APIs, not a second widget lifecycle implementation.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:artisanal/runtime.dart' show Cmd, KeyMsg, Msg;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;

const _markdown = '''
# Linked release notes

This is a deterministic production-like document. It contains a
[stable link](https://example.invalid/artisanal), headings, lists, and enough
text to exercise wrapping and scrolling without network access.

* one
* two
* three
''';

Future<void> main(List<String> args) async {
  final options = SoakOptions.parse(args);
  if (options.help) {
    stdout.writeln(SoakOptions.usage);
    return;
  }

  final directory = await Directory.systemTemp.createTemp('artisanal-soak-');
  try {
    await _runWorkload(options, directory);
    // The workload function has returned, dropping its tester and root.
    await _recordSample('teardown', directory, null);
    final samples = <Map<String, Object?>>[];
    for (final phase in [
      'warmup',
      for (var i = 0; i < options.batches; i++) 'batch-$i',
      'teardown',
    ]) {
      samples.add(
        (jsonDecode(await File('${directory.path}/$phase.json').readAsString())
                as Map)
            .cast<String, Object?>(),
      );
    }
    await _writeReport(options, samples);
  } finally {
    await directory.delete(recursive: true);
  }
}

Future<void> _runWorkload(SoakOptions options, Directory directory) async {
  final tester = WidgetTester(
    screenWidth: options.width,
    screenHeight: options.height,
    enableRenderer: true,
    altScreen: false,
  );
  try {
    await tester.pumpWidget(
      _SoakScreen(varyContent: options.varyContent),
      width: options.width,
      height: options.height,
    );
    // Warmup is deliberately not sampled: parser caches, VM startup, and UV
    // renderer initialization are not retained-heap measurements.
    await _runBatches(tester, options.warmup, options.iterations);
    await _recordSample('warmup', directory, tester);
    for (var batch = 0; batch < options.batches; batch++) {
      await _runBatches(tester, 1, options.iterations);
      await _recordSample('batch-$batch', directory, tester);
    }
    _assertWorkload(tester);
  } finally {
    await tester.dispose();
  }
}

Future<void> _writeReport(
  SoakOptions options,
  List<Map<String, Object?>> samples,
) async {
  final report = <String, Object?>{
    'schema': 'artisanal_widgets.memory_soak.v1',
    'options': options.toJson(),
    'methodology': {
      'samples': 'post-GC allocation profile when VM service is available',
      'rss': 'ProcessInfo.currentRss (capacity/RSS, not retained Dart heap)',
      'warmupExcluded': true,
      'frameHistory': 'none; renderer output is drained after every frame',
      'slope': 'fit of liveBytes against equal batch index; no absolute gate',
      'gc':
          'two allocation-profile GC requests separated by an event-loop yield',
      'collector': 'separate process; sample history read only after teardown',
    },
    'samples': samples,
    'slope': calculateSoakSlope(samples),
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  if (options.output == null) {
    stdout.writeln(encoded);
  } else {
    final file = File(options.output!)..parent.createSync(recursive: true);
    await file.writeAsString('$encoded\n');
    stderr.writeln('Memory soak report: ${file.absolute.path}');
  }
}

Future<void> _runBatches(
  WidgetTester tester,
  int batches,
  int iterations,
) async {
  for (var batch = 0; batch < batches; batch++) {
    for (var i = 0; i < iterations; i++) {
      // Scroll and redraw the linked Markdown document.
      tester.sendSpecialKey(KeyType.down);
      tester.sendSpecialKey(KeyType.up);
      tester.pump();
      tester.clearRendererOutput();
      // Open, type in, and close a modal-like subtree. The screen handles
      // these keys synchronously, so this remains deterministic and headless.
      tester.sendKey('m');
      tester.typeText('soak');
      tester.sendSpecialKey(KeyType.escape);
      tester.pump();
      tester.clearRendererOutput();
      _assertWorkload(tester);
    }
  }
}

Future<void> _recordSample(
  String phase,
  Directory directory,
  WidgetTester? tester,
) async {
  final info = await developer.Service.getInfo();
  final uri = info.serverUri;
  if (uri == null) {
    throw StateError(
      'VM service is required for a trustworthy soak report. '
      'Use memory_soak_profile.dart or --enable-vm-service.',
    );
  }
  final wsUri = uri.replace(
    scheme: uri.scheme == 'https' ? 'wss' : 'ws',
    path: '${uri.path}ws',
  );
  final targetId = developer.Service.getIsolateId(Isolate.current);
  if (targetId == null) throw StateError('No VM isolate found');
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    Platform.script.resolve('memory_soak_snapshot.dart').toFilePath(),
    wsUri.toString(),
    targetId,
    '${directory.path}/$phase.json',
    phase,
    '${ProcessInfo.currentRss}',
    '${tester?.rendererOutput.length ?? 0}',
  ]);
  if (result.exitCode != 0) {
    throw StateError('Heap collector failed: ${result.stderr}');
  }
}

Map<String, Object?> calculateSoakSlope(List<Map<String, Object?>> samples) {
  final points = samples
      .asMap()
      .entries
      .where((entry) => '${entry.value['phase']}'.startsWith('batch-'))
      .where((entry) => entry.value['liveBytes'] is num)
      .map(
        (entry) =>
            (x: entry.key, y: (entry.value['liveBytes']! as num).toDouble()),
      )
      .toList();
  if (points.length < 2) return {'available': false};
  final xMean = points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
  final yMean = points.map((p) => p.y).reduce((a, b) => a + b) / points.length;
  final denominator = points.fold<double>(
    0,
    (sum, p) => sum + (p.x - xMean) * (p.x - xMean),
  );
  final numerator = points.fold<double>(
    0,
    (sum, p) => sum + (p.x - xMean) * (p.y - yMean),
  );
  return {'available': true, 'liveBytesPerBatch': numerator / denominator};
}

class _SoakScreen extends w.StatefulWidget {
  _SoakScreen({required this.varyContent});
  final bool varyContent;
  @override
  w.State createState() => _SoakScreenState();
}

class _SoakScreenState extends w.State<_SoakScreen> {
  final _scroll = w.WidgetScrollController();
  final _input = w.TextFieldController();
  bool _modal = false;
  bool _scrollMoved = false;
  int _opens = 0;
  int _closes = 0;
  int _scrollEvents = 0;

  @override
  void initState() {
    super.initState();
    var previousOffset = _scroll.offset;
    _scroll.addListener(() {
      if (_scroll.offset != previousOffset) _scrollMoved = true;
      previousOffset = _scroll.offset;
    });
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (_modal && msg is KeyMsg && msg.key.type == KeyType.escape) {
      if (_input.text != 'soak') {
        throw StateError('Modal input did not receive the expected text');
      }
      setState(() {
        _modal = false;
        _closes++;
      });
      return Cmd.none();
    }
    return null;
  }

  @override
  handleUpdate(Msg msg) {
    if (msg is KeyMsg &&
        (msg.key.type == KeyType.down || msg.key.type == KeyType.up)) {
      _scrollEvents++;
    }
    if (msg is KeyMsg && msg.key.type == KeyType.runes) {
      final text = String.fromCharCodes(msg.key.runes);
      if (text == 'm') {
        setState(() {
          _input.clear();
          _modal = true;
          _opens++;
        });
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    int shown(int count) => widget.varyContent ? count : (count > 0 ? 1 : 0);
    final content = w.Column(
      children: [
        w.Text('Artisanal memory soak'),
        w.Text(
          'opens=${shown(_opens)} closes=${shown(_closes)} '
          'scrolls=${shown(_scrollEvents)} moved=$_scrollMoved',
        ),
        w.Expanded(
          child: w.SingleChildScrollView(
            controller: _scroll,
            child: w.Column(
              children: List<w.Widget>.generate(
                8,
                (_) => w.MarkdownText(data: _markdown, maxWidth: 70),
              ),
            ),
          ),
        ),
      ],
    );
    return w.Modal(
      open: _modal,
      child: content,
      dialog: w.Column(
        children: [
          w.Text('MODAL'),
          w.TextField(controller: _input, autofocus: true, width: 24),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }
}

class SoakOptions {
  SoakOptions({
    required this.warmup,
    required this.batches,
    required this.iterations,
    required this.width,
    required this.height,
    required this.output,
    required this.help,
    this.varyContent = true,
  });
  final int warmup, batches, iterations, width, height;
  final String? output;
  final bool help;
  final bool varyContent;
  static const usage =
      'Usage: dart run tool/memory_soak.dart '
      '[--warmup=N] [--batches=N] [--iterations=N] [--width=N] [--height=N] '
      '[--vary-content=0|1] [--json-output=PATH]';
  static SoakOptions parse(List<String> args) {
    var values = <String, String>{};
    var help = false;
    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg.startsWith('--') && arg.contains('=')) {
        final pair = arg.substring(2).split('=');
        const known = {
          'warmup',
          'batches',
          'iterations',
          'width',
          'height',
          'json-output',
          'vary-content',
        };
        final key = pair.first;
        if (!known.contains(key)) {
          throw FormatException('Unknown option: --$key\n$usage');
        }
        values[key] = pair.skip(1).join('=');
      } else {
        throw FormatException('Unknown option: $arg\n$usage');
      }
    }
    int value(String key, int fallback, int max) {
      final raw = values[key];
      final parsed = raw == null ? fallback : int.tryParse(raw);
      if (parsed == null) throw FormatException('$key must be an integer');
      if (parsed < 0 || parsed > max) {
        throw FormatException('$key must be 0..$max');
      }
      return parsed;
    }

    return SoakOptions(
      warmup: value('warmup', 2, 1000),
      batches: value('batches', 5, 1000),
      iterations: value('iterations', 10, 10000),
      width: value('width', 80, 300),
      height: value('height', 24, 200),
      output: values['json-output'],
      help: help,
      varyContent: value('vary-content', 1, 1) == 1,
    );
  }

  Map<String, Object?> toJson() => {
    'warmup': warmup,
    'batches': batches,
    'iterations': iterations,
    'width': width,
    'height': height,
    'jsonOutput': output,
    'varyContent': varyContent,
  };
}

void _assertWorkload(WidgetTester tester) {
  if (tester.find.text('opens=0') ||
      tester.find.text('closes=0') ||
      tester.find.text('scrolls=0') ||
      tester.find.text('moved=false') ||
      tester.find.textMatching(
        RegExp('Flutter error|Exception|Unhandled exception|Fatal render'),
      )) {
    throw StateError(
      'Soak workload did not exercise interactions or showed an error:\n'
      '${tester.view}',
    );
  }
}
