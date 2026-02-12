import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show MouseAction, MouseButton, MouseMsg;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/main.dart' as opencode;

const int _warmupCycles = 2;

void main() {
  test(
    'OpenCode baseline replay scenario is repeatable',
    () async => _runScenarioProfile(
      'baseline_scroll.json',
      const _PerfBudget(p95Ms: 75, maxMs: 150),
    ),
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'OpenCode heavy replay scenario surfaces hotspots',
    () async => _runScenarioProfile(
      'heavy_scroll.json',
      const _PerfBudget(p95Ms: 65, maxMs: 140),
    ),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

Future<void> _runScenarioProfile(
  String scenarioFile,
  _PerfBudget budget,
) async {
  final scenario = _ReplayScenario.load(scenarioFile);
  final tester = WidgetTester(
    screenWidth: scenario.screenWidth,
    screenHeight: scenario.screenHeight,
  );

  try {
    for (var cycle = 0; cycle < _warmupCycles; cycle++) {
      await tester.pumpWidget(opencode.OpenCodeApp());
      final warmupDurations = <int>[];
      final warmupByAction = <String, List<int>>{};
      final warmupSamples = <_EventSample>[];
      for (var i = 0; i < scenario.actions.length; i++) {
        final action = scenario.actions[i];
        await _runAction(
          tester,
          action,
          i + 1,
          warmupDurations,
          warmupByAction,
          warmupSamples,
        );
      }
    }

    // Reset UI state and measure after warm-up cycles.
    await tester.pumpWidget(opencode.OpenCodeApp());

    final durationsUs = <int>[];
    final byAction = <String, List<int>>{};
    final samples = <_EventSample>[];

    for (var i = 0; i < scenario.actions.length; i++) {
      final action = scenario.actions[i];
      await _runAction(tester, action, i + 1, durationsUs, byAction, samples);
    }

    expect(durationsUs, isNotEmpty);
    expect(tester.view, isNotEmpty);

    final stats = _LatencyStats.from(durationsUs);
    print('Replay scenario: ${scenario.name}');
    print('Action events: ${durationsUs.length}');
    print(
      'Latency (ms): avg=${_asMs(stats.avgUs)} '
      'p95=${_asMs(stats.p95Us)} max=${_asMs(stats.maxUs)}',
    );

    final actionNames = byAction.keys.toList()..sort();
    for (final actionName in actionNames) {
      final actionStats = _LatencyStats.from(byAction[actionName]!);
      print(
        '  $actionName n=${byAction[actionName]!.length} '
        'avg=${_asMs(actionStats.avgUs)} '
        'p95=${_asMs(actionStats.p95Us)} '
        'max=${_asMs(actionStats.maxUs)}',
      );
    }

    final topSlow = List<_EventSample>.of(samples)
      ..sort((a, b) => b.durationUs.compareTo(a.durationUs));
    final topN = math.min(12, topSlow.length);
    if (topN > 0) {
      print('  slowest_events:');
      for (var i = 0; i < topN; i++) {
        final sample = topSlow[i];
        print(
          '    #${sample.eventIndex} [a${sample.actionBlockIndex}] '
          '${sample.action} (${sample.actionBlockSummary}) '
          '${_asMs(sample.durationUs.toDouble())}ms',
        );
      }
    }

    expect(stats.p95Us / 1000, lessThan(budget.p95Ms));
    expect(stats.maxUs / 1000, lessThan(budget.maxMs));
  } finally {
    await tester.dispose();
  }
}

class _PerfBudget {
  const _PerfBudget({required this.p95Ms, required this.maxMs});

  final double p95Ms;
  final double maxMs;
}

Future<void> _runAction(
  WidgetTester tester,
  _ReplayAction action,
  int actionBlockIndex,
  List<int> durationsUs,
  Map<String, List<int>> byAction,
  List<_EventSample> samples,
) async {
  final repeat = math.max(1, action.repeat);
  switch (action.type) {
    case 'sleep':
      await Future<void>.delayed(Duration(milliseconds: action.ms));
      return;
    case 'text':
      for (var r = 0; r < repeat; r++) {
        for (final rune in action.value.runes) {
          _record(
            durationsUs,
            byAction,
            samples,
            actionBlockIndex,
            action.summary,
            'text',
            _timeUs(() => tester.sendKey(String.fromCharCode(rune))),
          );
        }
      }
      return;
    case 'special':
      final keyType = _parseKeyType(action.key);
      for (var i = 0; i < repeat; i++) {
        _record(
          durationsUs,
          byAction,
          samples,
          actionBlockIndex,
          action.summary,
          'special:${action.key}',
          _timeUs(() => tester.sendSpecialKey(keyType)),
        );
      }
      return;
    case 'wheel':
      final button = _parseWheelButton(action.direction);
      for (var i = 0; i < repeat; i++) {
        _record(
          durationsUs,
          byAction,
          samples,
          actionBlockIndex,
          action.summary,
          'wheel:${action.direction}',
          _timeUs(
            () => tester.sendMsg(
              MouseMsg(
                action: MouseAction.wheel,
                button: button,
                x: action.x,
                y: action.y,
              ),
            ),
          ),
        );
      }
      return;
    case 'tap':
      for (var i = 0; i < repeat; i++) {
        _record(
          durationsUs,
          byAction,
          samples,
          actionBlockIndex,
          action.summary,
          'tap',
          _timeUs(() => tester.tapAt(action.x, action.y)),
        );
      }
      return;
    case 'move':
      for (var i = 0; i < repeat; i++) {
        _record(
          durationsUs,
          byAction,
          samples,
          actionBlockIndex,
          action.summary,
          'move',
          _timeUs(() => tester.mouseMove(action.x, action.y)),
        );
      }
      return;
    default:
      throw ArgumentError('Unsupported action type: ${action.type}');
  }
}

void _record(
  List<int> all,
  Map<String, List<int>> byAction,
  List<_EventSample> samples,
  int actionBlockIndex,
  String actionBlockSummary,
  String action,
  int durationUs,
) {
  final eventIndex = all.length + 1;
  all.add(durationUs);
  byAction.putIfAbsent(action, () => <int>[]).add(durationUs);
  samples.add(
    _EventSample(
      eventIndex: eventIndex,
      actionBlockIndex: actionBlockIndex,
      actionBlockSummary: actionBlockSummary,
      action: action,
      durationUs: durationUs,
    ),
  );
}

class _EventSample {
  _EventSample({
    required this.eventIndex,
    required this.actionBlockIndex,
    required this.actionBlockSummary,
    required this.action,
    required this.durationUs,
  });

  final int eventIndex;
  final int actionBlockIndex;
  final String actionBlockSummary;
  final String action;
  final int durationUs;
}

int _timeUs(void Function() fn) {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  return sw.elapsedMicroseconds;
}

double _percentileUs(List<int> sortedValues, double p) {
  if (sortedValues.isEmpty) return 0;
  if (sortedValues.length == 1) return sortedValues.first.toDouble();
  final idx = (sortedValues.length - 1) * p;
  final low = idx.floor();
  final high = idx.ceil();
  if (low == high) return sortedValues[low].toDouble();
  final lowValue = sortedValues[low];
  final highValue = sortedValues[high];
  return lowValue * (high - idx) + highValue * (idx - low);
}

String _asMs(double us) => (us / 1000).toStringAsFixed(2);

terminal_keys.KeyType _parseKeyType(String key) {
  return switch (key) {
    'enter' => terminal_keys.KeyType.enter,
    'tab' => terminal_keys.KeyType.tab,
    'backspace' => terminal_keys.KeyType.backspace,
    'delete' => terminal_keys.KeyType.delete,
    'escape' => terminal_keys.KeyType.escape,
    'space' => terminal_keys.KeyType.space,
    'up' => terminal_keys.KeyType.up,
    'down' => terminal_keys.KeyType.down,
    'left' => terminal_keys.KeyType.left,
    'right' => terminal_keys.KeyType.right,
    'home' => terminal_keys.KeyType.home,
    'end' => terminal_keys.KeyType.end,
    'pageUp' => terminal_keys.KeyType.pageUp,
    'pageDown' => terminal_keys.KeyType.pageDown,
    _ => throw ArgumentError('Unsupported special key: $key'),
  };
}

MouseButton _parseWheelButton(String direction) {
  return switch (direction) {
    'up' => MouseButton.wheelUp,
    'down' => MouseButton.wheelDown,
    'left' => MouseButton.wheelLeft,
    'right' => MouseButton.wheelRight,
    _ => throw ArgumentError('Unsupported wheel direction: $direction'),
  };
}

class _LatencyStats {
  _LatencyStats({
    required this.avgUs,
    required this.p95Us,
    required this.maxUs,
  });

  final double avgUs;
  final double p95Us;
  final double maxUs;

  factory _LatencyStats.from(List<int> valuesUs) {
    final ordered = List<int>.of(valuesUs)..sort();
    final avg =
        ordered.fold<int>(0, (sum, next) => sum + next) / ordered.length;
    return _LatencyStats(
      avgUs: avg,
      p95Us: _percentileUs(ordered, 0.95),
      maxUs: ordered.last.toDouble(),
    );
  }
}

class _ReplayScenario {
  _ReplayScenario({
    required this.name,
    required this.screenWidth,
    required this.screenHeight,
    required this.actions,
  });

  final String name;
  final int screenWidth;
  final int screenHeight;
  final List<_ReplayAction> actions;

  static _ReplayScenario load(String fileName) {
    final path = _resolveScenarioPath(fileName);
    final raw =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final screen = raw['screen'] as Map<String, dynamic>? ?? const {};
    final actions = (raw['actions'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_ReplayAction.fromJson)
        .toList(growable: false);
    return _ReplayScenario(
      name: (raw['name'] as String?) ?? fileName,
      screenWidth: (screen['width'] as int?) ?? 120,
      screenHeight: (screen['height'] as int?) ?? 40,
      actions: actions,
    );
  }
}

class _ReplayAction {
  _ReplayAction({
    required this.type,
    this.repeat = 1,
    this.ms = 0,
    this.value = '',
    this.key = '',
    this.direction = 'down',
    this.x = 0,
    this.y = 0,
  });

  final String type;
  final int repeat;
  final int ms;
  final String value;
  final String key;
  final String direction;
  final int x;
  final int y;

  String get summary {
    return switch (type) {
      'sleep' => 'sleep ms=$ms',
      'text' => 'text len=${value.length} repeat=$repeat',
      'special' => 'special key=$key repeat=$repeat',
      'wheel' => 'wheel dir=$direction x=$x y=$y repeat=$repeat',
      'tap' => 'tap x=$x y=$y repeat=$repeat',
      'move' => 'move x=$x y=$y repeat=$repeat',
      _ => '$type repeat=$repeat',
    };
  }

  factory _ReplayAction.fromJson(Map<String, dynamic> json) {
    return _ReplayAction(
      type: (json['type'] as String?) ?? '',
      repeat: (json['repeat'] as int?) ?? 1,
      ms: (json['ms'] as int?) ?? 0,
      value: (json['value'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      direction: (json['direction'] as String?) ?? 'down',
      x: (json['x'] as int?) ?? 0,
      y: (json['y'] as int?) ?? 0,
    );
  }
}

String _resolveScenarioPath(String fileName) {
  final candidates = <String>[
    'pkgs/artisanal_widgets/example/opencode/scenarios/$fileName',
    'example/opencode/scenarios/$fileName',
  ];
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) return candidate;
  }
  throw FileSystemException('Scenario file not found', fileName);
}
