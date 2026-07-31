// Responsive inline build monitor.
//
// The dashboard stays pinned to the bottom of the primary screen while build
// output flows into native terminal scrollback through Cmd.println.
//
// Run from `pkgs/artisanal_widgets`:
//   dart run example/inline_build_monitor/main.dart

import 'dart:math' as math;

import 'package:artisanal/style.dart' hide Align, Padding;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

Future<void> main() async {
  await tui.runProgram(
    InlineBuildMonitorApp(),
    options: const tui.ProgramOptions(
      screenMode: tui.ScreenMode.inline,
      inlineHeight: 11,
      uiAnchor: tui.UiAnchor.bottom,
      mouseMode: tui.MouseMode.none,
      fps: 30,
      startupProbes: false,
    ),
  );
}

enum BuildRunState { running, paused, failed, succeeded }

final class BuildStage {
  const BuildStage(this.label, this.command, this.ticks);

  final String label;
  final String command;
  final int ticks;
}

const buildStages = <BuildStage>[
  BuildStage('resolve', 'dart pub get', 7),
  BuildStage('analyze', 'dart analyze', 11),
  BuildStage('test', 'dart test --concurrency=8', 17),
  BuildStage('compile', 'dart compile exe bin/artisan.dart', 13),
  BuildStage('package', 'package release artifact', 8),
];

final class BuildMonitorSnapshot {
  const BuildMonitorSnapshot({
    required this.buildNumber,
    required this.stageIndex,
    required this.stageTick,
    required this.elapsedTicks,
    required this.state,
    required this.throughput,
  });

  factory BuildMonitorSnapshot.initial() => const BuildMonitorSnapshot(
    buildNumber: 1842,
    stageIndex: 0,
    stageTick: 0,
    elapsedTicks: 0,
    state: BuildRunState.running,
    throughput: <double>[
      38,
      41,
      39,
      45,
      48,
      46,
      52,
      55,
      51,
      57,
      61,
      58,
      64,
      67,
      65,
      70,
    ],
  );

  final int buildNumber;
  final int stageIndex;
  final int stageTick;
  final int elapsedTicks;
  final BuildRunState state;
  final List<double> throughput;

  BuildStage get stage =>
      buildStages[stageIndex.clamp(0, buildStages.length - 1)];

  int get completedTicks {
    var value = 0;
    for (var index = 0; index < stageIndex; index++) {
      value += buildStages[index].ticks;
    }
    return value;
  }

  int get totalTicks => buildStages.fold(0, (sum, stage) => sum + stage.ticks);

  double get overallProgress {
    if (state == BuildRunState.succeeded) return 1;
    return ((completedTicks + stageTick) / totalTicks).clamp(0, 1);
  }

  double get stageProgress => (stageTick / stage.ticks).clamp(0, 1);

  String get elapsedLabel {
    final tenths = elapsedTicks * 25;
    return '${tenths ~/ 100}.${(tenths % 100) ~/ 10}s';
  }
}

class InlineBuildMonitorApp extends w.WidgetApp {
  InlineBuildMonitorApp() : super(InlineBuildMonitor());
}

class InlineBuildMonitor extends w.StatefulWidget {
  InlineBuildMonitor({super.key});

  @override
  w.State createState() => _InlineBuildMonitorState();
}

class _InlineBuildMonitorState extends w.State<InlineBuildMonitor> {
  var _buildNumber = 1842;
  var _stageIndex = 0;
  var _stageTick = 0;
  var _elapsedTicks = 0;
  var _cooldownTicks = 0;
  var _state = BuildRunState.running;
  final List<double> _throughput = List<double>.of(
    BuildMonitorSnapshot.initial().throughput,
  );

  @override
  tui.Cmd? handleInit() {
    return tui.ParallelCmd([
      tui.every(const Duration(milliseconds: 250), (_) => const _BuildTick()),
      tui.Cmd.println(
        '[build #1842] queued for linux-x64 · branch main · revision 7ac12e4',
      ),
      tui.Cmd.println('[resolve] ${buildStages.first.command}'),
    ]);
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key.char;
      if (key == 'q' || msg.key.type == tui.KeyType.escape) {
        return tui.Cmd.quit();
      }
      if (key == 'p' || key == ' ') return _togglePause();
      if (key == 'r') return _restart(manual: true);
      if (key == 'e') return _failBuild();
    }

    if (msg is _BuildTick) return _advanceBuild();
    return null;
  }

  tui.Cmd? _togglePause() {
    if (_state == BuildRunState.failed || _state == BuildRunState.succeeded) {
      return null;
    }
    _state = _state == BuildRunState.paused
        ? BuildRunState.running
        : BuildRunState.paused;
    setState(() {});
    final action = _state == BuildRunState.paused ? 'paused' : 'resumed';
    return tui.Cmd.println('[build #$_buildNumber] $action by user');
  }

  tui.Cmd _restart({required bool manual}) {
    _buildNumber++;
    _stageIndex = 0;
    _stageTick = 0;
    _elapsedTicks = 0;
    _cooldownTicks = 0;
    _state = BuildRunState.running;
    setState(() {});
    final trigger = manual ? 'manual rebuild' : 'watch change';
    return tui.Cmd.println(
      '[build #$_buildNumber] started · $trigger\n'
      '[resolve] ${buildStages.first.command}',
    );
  }

  tui.Cmd? _failBuild() {
    if (_state != BuildRunState.running && _state != BuildRunState.paused) {
      return null;
    }
    _state = BuildRunState.failed;
    setState(() {});
    return tui.Cmd.println(
      '[${buildStages[_stageIndex].label}] ERROR: simulated failure '
      '(press r to rebuild)',
    );
  }

  tui.Cmd? _advanceBuild() {
    if (_state == BuildRunState.paused || _state == BuildRunState.failed) {
      return null;
    }
    if (_state == BuildRunState.succeeded) {
      _cooldownTicks++;
      if (_cooldownTicks >= 12) return _restart(manual: false);
      setState(() {});
      return null;
    }

    _elapsedTicks++;
    _stageTick++;
    _recordThroughput();

    final current = buildStages[_stageIndex];
    tui.Cmd? output;
    if (_stageTick >= current.ticks) {
      final duration = (_stageTick * 250 / 1000).toStringAsFixed(2);
      final details = _completionDetails(_stageIndex);
      _stageIndex++;
      _stageTick = 0;

      if (_stageIndex >= buildStages.length) {
        _stageIndex = buildStages.length - 1;
        _state = BuildRunState.succeeded;
        output = tui.Cmd.println(
          '[${current.label}] done in ${duration}s · $details\n'
          '[build #$_buildNumber] SUCCESS · artifact ready · '
          '${_elapsedLabel()} total',
        );
      } else {
        final next = buildStages[_stageIndex];
        output = tui.Cmd.println(
          '[${current.label}] done in ${duration}s · $details\n'
          '[${next.label}] ${next.command}',
        );
      }
    } else if (_stageTick % 5 == 0) {
      output = tui.Cmd.println(_progressLog(current));
    }

    setState(() {});
    return output;
  }

  void _recordThroughput() {
    final wave = math.sin(_elapsedTicks / 3) * 9;
    final stageBoost = _stageIndex * 4;
    _throughput
      ..removeAt(0)
      ..add(58 + wave + stageBoost);
  }

  String _completionDetails(int stageIndex) => switch (stageIndex) {
    0 => '126 dependencies locked',
    1 => '214 files · 0 issues',
    2 => '486 tests passed',
    3 => '18.4 MB executable',
    _ => 'sha256 91c7…f32a',
  };

  String _progressLog(BuildStage stage) {
    final percentage = ((_stageTick / stage.ticks) * 100).round();
    return '[${stage.label}] $percentage% · ${_progressDetails(_stageIndex)}';
  }

  String _progressDetails(int stageIndex) => switch (stageIndex) {
    0 => 'fetching package metadata',
    1 => '${63 + _stageTick * 11} files checked',
    2 => '${120 + _stageTick * 19}/486 tests passed',
    3 => '${(_stageTick * 1.4).toStringAsFixed(1)} MB linked',
    _ => 'compressing release bundle',
  };

  String _elapsedLabel() {
    final tenths = _elapsedTicks * 25;
    return '${tenths ~/ 100}.${(tenths % 100) ~/ 10}s';
  }

  @override
  w.Widget build(w.BuildContext context) {
    return InlineBuildMonitorView(
      snapshot: BuildMonitorSnapshot(
        buildNumber: _buildNumber,
        stageIndex: _stageIndex,
        stageTick: _stageTick,
        elapsedTicks: _elapsedTicks,
        state: _state,
        throughput: List<double>.unmodifiable(_throughput),
      ),
    );
  }
}

class InlineBuildMonitorView extends w.StatelessWidget {
  InlineBuildMonitorView({required this.snapshot, super.key});

  final BuildMonitorSnapshot snapshot;

  @override
  w.Widget build(w.BuildContext context) {
    return w.LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth.toInt()
            : 90;
        return _buildDashboard(context, width.clamp(36, 140));
      },
    );
  }

  w.Widget _buildDashboard(w.BuildContext context, int width) {
    final theme = context.theme;
    final compact = width < 72;
    final contentWidth = math.max(28, width - 6);
    final barWidth = (contentWidth - (compact ? 14 : 24)).clamp(12, 72);
    final stateColor = switch (snapshot.state) {
      BuildRunState.running => theme.primary,
      BuildRunState.paused => theme.warning,
      BuildRunState.failed => theme.error,
      BuildRunState.succeeded => theme.success,
    };
    final stateLabel = snapshot.state.name.toUpperCase();
    final bodyStyle = theme.bodySmall.copy()..foreground(theme.onBackground);
    final mutedStyle = theme.labelSmall.copy()..foreground(theme.muted);

    return w.Container(
      color: theme.background,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.SizedBox(
        height: 10,
        child: w.Frame(
          border: Border.rounded,
          borderColor: stateColor,
          background: theme.background,
          padding: const w.EdgeInsets.symmetric(horizontal: 1),
          child: w.Column(
            gap: 0,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.StatusLine(
                background: theme.surface,
                left: [
                  if (snapshot.state == BuildRunState.running)
                    w.StatusItem.spinner(snapshot.elapsedTicks),
                  w.StatusItem.text(' BUILD #${snapshot.buildNumber}'),
                  w.StatusItem.text(stateLabel),
                ],
                center: compact
                    ? const []
                    : const [w.StatusItem.text('main → linux-x64')],
                right: compact
                    ? [w.StatusItem.keyHint('q', 'quit')]
                    : [
                        w.StatusItem.keyHint('p', 'pause'),
                        w.StatusItem.keyHint('r', 'rebuild'),
                        w.StatusItem.keyHint('e', 'error'),
                        w.StatusItem.keyHint('q', 'quit'),
                      ],
              ),
              w.Text(
                _fit(_stageSummary(compact), contentWidth),
                style: bodyStyle,
              ),
              if (compact)
                w.ProgressIndicator(
                  value: snapshot.overallProgress,
                  width: barWidth,
                  progressStyle: w.ProgressStyle.block,
                  color: stateColor,
                  trackColor: theme.muted,
                  showLabel: true,
                  labelFormat: (_) =>
                      '${(snapshot.overallProgress * 100).round()}% overall',
                )
              else
                w.Row(
                  gap: 1,
                  children: [
                    w.Badge(
                      snapshot.stage.label.toUpperCase(),
                      background: stateColor,
                      foreground: Colors.black,
                    ),
                    w.ProgressIndicator(
                      value: snapshot.overallProgress,
                      width: barWidth,
                      progressStyle: w.ProgressStyle.block,
                      color: stateColor,
                      trackColor: theme.muted,
                      showLabel: true,
                      labelFormat: (_) =>
                          '${(snapshot.overallProgress * 100).round()}% overall',
                    ),
                  ],
                ),
              w.Text(
                _fit('command  ${snapshot.stage.command}', contentWidth),
                style: mutedStyle,
              ),
              w.Divider(width: contentWidth, style: mutedStyle),
              w.Text(
                _fit(
                  compact
                      ? 'elapsed ${snapshot.elapsedLabel} · '
                            'stage ${(snapshot.stageProgress * 100).round()}%'
                      : 'elapsed ${snapshot.elapsedLabel}   '
                            'stage ${(snapshot.stageProgress * 100).round()}%   '
                            'tests 486   cache 94%   workers 8',
                  contentWidth,
                ),
                style: bodyStyle,
              ),
              w.Text(
                _fit(
                  'throughput ${_sparkline(snapshot.throughput)} '
                  '${snapshot.throughput.last.round()} jobs/s',
                  contentWidth,
                ),
                style: bodyStyle,
              ),
              w.Text(
                _fit(
                  compact
                      ? 'p pause · r rebuild · e error · q quit'
                      : 'Logs stream above this panel into native scrollback.  '
                            'p pause · r rebuild · e simulate error · q quit',
                  contentWidth,
                ),
                style: mutedStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stageSummary(bool compact) {
    if (compact) {
      return 'stage ${snapshot.stageIndex + 1}/${buildStages.length} · '
          '${snapshot.stage.label}';
    }
    return buildStages.indexed
        .map((entry) {
          final (index, stage) = entry;
          if (snapshot.state == BuildRunState.failed &&
              index == snapshot.stageIndex) {
            return '× ${stage.label}';
          }
          if (index < snapshot.stageIndex ||
              snapshot.state == BuildRunState.succeeded) {
            return '✓ ${stage.label}';
          }
          if (index == snapshot.stageIndex) return '▶ ${stage.label}';
          return '· ${stage.label}';
        })
        .join('   ');
  }

  static String _sparkline(List<double> values) {
    const blocks = '▁▂▃▄▅▆▇█';
    if (values.isEmpty) return '';
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final range = math.max(1, high - low);
    return values.map((value) {
      final index = (((value - low) / range) * (blocks.length - 1)).round();
      return blocks[index.clamp(0, blocks.length - 1)];
    }).join();
  }

  static String _fit(String value, int width) {
    if (value.length <= width) return value;
    if (width <= 1) return value.substring(0, width);
    return '${value.substring(0, width - 1)}…';
  }
}

class _BuildTick extends tui.Msg {
  const _BuildTick();
}
