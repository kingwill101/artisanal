import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:devtools_region_profiler/devtools_region_profiler.dart'
    as profiler;
import 'package:github_cli/src/app/pull_request_view.dart';
import 'package:github_cli/src/client/client.dart';
import 'package:github_cli/src/models/comment.dart';
import 'package:github_cli/src/models/pull_request.dart';
import 'package:github_cli/src/ui/markdown/body.dart';
import 'package:github_cli/src/utils/pull_request_input.dart';

/// Offline, production-renderer benchmark for `github_cli view` PR #49.
///
/// Each timed round scrolls down and back up. Fixture loading,
/// widget mounting, warmup, assertions, and JSON encoding are outside it.
Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final fixture = jsonDecode(
    File('tool/fixtures/pr49_scroll.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final pullRequest = GithubPullRequestItem.fromJson(
    _withAuthorObject(fixture['pullRequest']! as Map<String, Object?>),
  );
  final comments = (fixture['comments']! as List<Object?>)
      .map(
        (item) => GithubCommentItem.fromJson(
          _withAuthorObject(item! as Map<String, Object?>),
        ),
      )
      .toList(growable: false);

  late Map<String, Object?> result;
  // WidgetTester has diagnostic startup prints. Keep stdout a machine-readable
  // JSON stream while retaining the normal tool's one-line result.
  await runZoned(
    () async {
      final tester = WidgetTester(
        screenWidth: options.columns,
        screenHeight: options.rows,
        enableRenderer: true,
        altScreen: true,
      );
      try {
        await tester.pumpWidget(
          GithubPullRequestView(
            client: _FixtureClient(pullRequest, comments),
            target: const GithubPullRequestTarget(
              repository: 'kingwill101/artisanal',
              number: 49,
            ),
          ),
        );
        await _waitForLoaded(tester, comments.length + 1);
        if (options.overlay) {
          tester.sendSpecialKey(tui.KeyType.f12);
        }
        final top = tester.view;
        _drain(tester);

        _sendScroll(tester, down: true, overlay: options.overlay);
        final movement = tester.view != top;
        _drain(tester);
        _sendScroll(tester, down: false, overlay: options.overlay);
        _drain(tester);
        if (!movement || tester.view != top) {
          throw StateError('down/up did not move and restore the PR viewport');
        }
        for (var i = 0; i < options.warmupRounds; i++) {
          _scrollRound(tester, options.steps, overlay: options.overlay);
        }
        if (tester.view != top) {
          throw StateError('up key did not restore the PR detail viewport');
        }

        final samplesUs = List<int>.filled(options.rounds, 0);
        final keySamplesUs = List<int>.filled(
          options.rounds * options.steps * 2,
          0,
        );
        if (options.heapDirectory != null) {
          await _recordHeap(options.heapDirectory!, 'warmup');
        }
        final region = options.profile
            ? await profiler.startProfileRegion(
                'github_cli.conversation_scroll',
                attributes: {
                  'columns': '${options.columns}',
                  'rows': '${options.rows}',
                  'rounds': '${options.rounds}',
                  'stepsEachDirection': '${options.steps}',
                  'overlay': '${options.overlay}',
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
            _scrollRound(
              tester,
              options.steps,
              overlay: options.overlay,
              keySamplesUs: keySamplesUs,
              sampleOffset: i * options.steps * 2,
            );
            sample.stop();
            samplesUs[i] = sample.elapsedMicroseconds;
            if (options.heapDirectory != null) {
              total.stop();
              await _recordHeap(options.heapDirectory!, 'round-${i + 1}');
              total.start();
            }
          }
          total.stop();
        } finally {
          await region?.stop();
        }
        if (tester.view != top ||
            tester.find.byType<GithubMarkdownBody>().length !=
                comments.length + 1) {
          throw StateError(
            'benchmark lost the loaded conversation or scroll position',
          );
        }
        result = <String, Object?>{
          'benchmark': 'github_pull_request_view_scroll',
          'fixture': fixture['source'],
          'sourceSha256': fixture['sourceSha256'],
          'terminalDimensions': {
            'width': options.columns,
            'height': options.rows,
          },
          'loadedComments': comments.length,
          'scrollMovementAssertion': movement,
          'warmupRounds': options.warmupRounds,
          'rounds': options.rounds,
          'stepsEachDirection': options.steps,
          'keysPerRound': options.steps * 2,
          'profiled': options.profile,
          'overlay': options.overlay,
          'scrollKeys': options.overlay ? 'j/k' : 'down/up',
          'heapDirectory': options.heapDirectory,
          'samplesUs': samplesUs,
          'totalUs': total.elapsedMicroseconds,
          'meanUs': total.elapsedMicroseconds / options.rounds,
          'meanUsPerKey':
              total.elapsedMicroseconds / (options.rounds * options.steps * 2),
          'keyLatencyUs': _keyLatencies(keySamplesUs),
        };
      } finally {
        await tester.dispose();
        if (options.heapDirectory != null) {
          await _recordHeap(options.heapDirectory!, 'teardown');
        }
      }
    },
    zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {}),
  );
  final encoded = jsonEncode(result);
  if (options.outputPath == null) {
    stdout.writeln(encoded);
  } else {
    File(options.outputPath!).parent.createSync(recursive: true);
    File(options.outputPath!).writeAsStringSync('$encoded\n');
    stdout.writeln('wrote ${options.outputPath}');
  }
}

void _scrollRound(
  WidgetTester tester,
  int steps, {
  required bool overlay,
  List<int>? keySamplesUs,
  int sampleOffset = 0,
}) {
  final timer = keySamplesUs == null ? null : Stopwatch();
  for (final down in [true, false]) {
    for (var i = 0; i < steps; i++) {
      timer
        ?..reset()
        ..start();
      _sendScroll(tester, down: down, overlay: overlay);
      _drain(tester);
      if (timer != null) {
        timer.stop();
        keySamplesUs![sampleOffset++] = timer.elapsedMicroseconds;
      }
    }
  }
}

void _sendScroll(
  WidgetTester tester, {
  required bool down,
  required bool overlay,
}) {
  if (overlay) {
    // Use bindings that also work with older or keyboard-interactive DevTools
    // overlays, keeping before/after conversation benchmarks comparable.
    tester.sendKey(down ? 'j' : 'k');
  } else {
    tester.sendSpecialKey(down ? tui.KeyType.down : tui.KeyType.up);
  }
}

Map<String, int> _keyLatencies(List<int> samples) {
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

void _drain(WidgetTester tester) {
  // The tester has already consumed the write for its rendered view. Release
  // the transport history without joining it into another discarded string.
  tester.clearRendererOutput();
}

Future<void> _waitForLoaded(WidgetTester tester, int expectedBodies) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    // The PR title appears before the asynchronous comments response arrives.
    // Wait for every actual Markdown body, not just the initial description.
    if (tester.find.byType<GithubMarkdownBody>().length == expectedBodies) {
      return;
    }
    tester.pump();
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('timed out loading PR #49 fixture');
}

Map<String, Object?> _withAuthorObject(Map<String, Object?> json) => {
  ...json,
  if (json['author'] is String) 'author': {'login': json['author']},
};

Future<void> _recordHeap(String directory, String phase) async {
  final uri = (await developer.Service.getInfo()).serverUri;
  final isolate = developer.Service.getIsolateId(Isolate.current);
  if (uri == null || isolate == null) {
    throw StateError('--heap-dir requires --enable-vm-service=0');
  }
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:artisanal_widgets/widgets.dart'),
  );
  if (library == null) throw StateError('Cannot locate the heap collector');
  final collector = library.resolve('../tool/memory_soak_snapshot.dart');
  final ws = uri.replace(
    scheme: uri.scheme == 'https' ? 'wss' : 'ws',
    path: '${uri.path}ws',
  );
  Directory(directory).createSync(recursive: true);
  // The existing collector uses two GCs with an event-loop yield and writes
  // class counts from a separate process. No profile maps accumulate here.
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    collector.toFilePath(),
    ws.toString(),
    isolate,
    '$directory/$phase.json',
    phase,
    '${ProcessInfo.currentRss}',
    '0',
  ]);
  if (result.exitCode != 0) {
    throw StateError('Heap collector failed: ${result.stderr}');
  }
}

final class _FixtureClient implements GithubDashboardClient {
  _FixtureClient(this.pullRequest, this.comments);

  final GithubPullRequestItem pullRequest;
  final List<GithubCommentItem> comments;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #loadPullRequest) {
      return Future<GithubPullRequestItem>.value(pullRequest);
    }
    if (invocation.memberName == #loadComments) {
      return Future<List<GithubCommentItem>>.value(comments);
    }
    throw UnsupportedError('offline benchmark called ${invocation.memberName}');
  }
}

final class _Options {
  const _Options(
    this.rounds,
    this.warmupRounds,
    this.outputPath,
    this.columns,
    this.rows,
    this.steps,
    this.profile,
    this.heapDirectory,
    this.overlay,
  );

  final int rounds;
  final int warmupRounds;
  final String? outputPath;
  final int columns;
  final int rows;
  final int steps;
  final bool profile;
  final String? heapDirectory;
  final bool overlay;

  static _Options parse(List<String> args) {
    final parser = ArgParser()
      ..addOption('rounds', defaultsTo: '10')
      ..addOption('warmup', defaultsTo: '3')
      ..addOption('columns', defaultsTo: '110')
      ..addOption('rows', defaultsTo: '34')
      ..addOption('steps', defaultsTo: '40')
      ..addFlag('profile', negatable: false)
      ..addFlag('overlay', negatable: false)
      ..addOption('heap-dir')
      ..addOption('out');
    final parsed = parser.parse(args);
    if (parsed.rest.isNotEmpty) {
      throw ArgumentError('Unexpected positional arguments');
    }
    if (parsed['profile'] == true && parsed['heap-dir'] != null) {
      throw ArgumentError(
        'Run CPU profiling and forced-GC measurements separately',
      );
    }
    int value(String name, int fallback) {
      final number = int.tryParse(parsed[name] as String? ?? '$fallback');
      if (number == null || number < (name == 'warmup' ? 0 : 1)) {
        throw ArgumentError('Invalid --$name');
      }
      return number;
    }

    return _Options(
      value('rounds', 10),
      value('warmup', 3),
      parsed['out'] as String?,
      value('columns', 110),
      value('rows', 34),
      value('steps', 40),
      parsed['profile'] as bool,
      parsed['heap-dir'] as String?,
      parsed['overlay'] as bool,
    );
  }
}
