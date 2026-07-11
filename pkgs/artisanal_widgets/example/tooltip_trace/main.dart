import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/widgets.dart' as w;

import 'replay_driver.dart';

/// Tooltip trace + replay demo.
///
/// Record a trace:
/// `ARTISANAL_TUI_TRACE=1 dart run pkgs/artisanal_widgets/example/tooltip_trace/main.dart`
///
/// Convert a trace to a replay scenario:
/// `dart run pkgs/artisanal_widgets/example/tooltip_trace/main.dart --replay-trace traces/your-trace.log --replay-trace-out /tmp/tooltip.json --replay-convert-only`
///
/// Replay a scenario:
/// `dart run pkgs/artisanal_widgets/example/tooltip_trace/main.dart --replay-scenario /tmp/tooltip.json --replay-block-input`
Future<void> main(List<String> args) async {
  try {
    await runTooltipTraceDemo(args);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage);
    exitCode = 66;
  }
}

Future<void> runTooltipTraceDemo(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }

  final replayPlan = await loadTooltipTraceReplayPlanFromArgs(args);
  if (replayPlan?.convertOnly ?? false) {
    final conversion = replayPlan!.traceConversion;
    stdout.writeln(
      'Converted ${conversion?.eventCount ?? 0} trace events into '
      '${replayPlan.actionCount} replay actions at ${replayPlan.path}.',
    );
    return;
  }

  final shell = createTooltipTraceDemoApp(replayPlan: replayPlan);
  final options = runtime.ProgramOptions(
    altScreen: true,
    mouseMode: runtime.MouseMode.allMotion,
    startupProbes: false,
    replay: replayPlan?.replay,
    blockInputWhileReplay: replayPlan?.blockInput ?? false,
    interceptor: replayPlan?.interceptor,
  );

  if (replayPlan != null) {
    stdout.writeln(
      'Replaying "${replayPlan.name}" '
      '(${replayPlan.actionCount} actions, speed ${replayPlan.speed}x)',
    );
  }

  await runtime.runProgram(shell, options: options);
}

app.ArtisanalApp createTooltipTraceDemoApp({
  TooltipTraceReplayPlan? replayPlan,
}) {
  return app.ArtisanalApp(
    title: 'Tooltip Trace Demo',
    home: TooltipTraceDemoRoot(replayPlan: replayPlan),
  );
}

class TooltipTraceDemoRoot extends w.StatelessWidget {
  TooltipTraceDemoRoot({this.replayPlan, super.key});

  final TooltipTraceReplayPlan? replayPlan;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Overlay(
      initialEntries: [
        w.OverlayEntry(
          builder: (_) => TooltipTraceDemoScreen(replayPlan: replayPlan),
        ),
      ],
    );
  }
}

enum TooltipVisibilityMode { hover, forcedVisible, forcedHidden }

class TooltipTraceDemoScreen extends w.StatefulWidget {
  TooltipTraceDemoScreen({this.replayPlan, super.key});

  final TooltipTraceReplayPlan? replayPlan;

  @override
  w.State createState() => _TooltipTraceDemoScreenState();
}

class _TooltipTraceDemoScreenState extends w.State<TooltipTraceDemoScreen> {
  w.TooltipPosition _position = w.TooltipPosition.above;
  TooltipVisibilityMode _visibilityMode = TooltipVisibilityMode.hover;
  w.ReplayEventHistoryState _replayHistory = const w.ReplayEventHistoryState(
    mode: w.ReplayEventHistoryMode.grouped,
  );
  bool _enabled = true;
  bool _hovered = false;
  int _hoverEnterCount = 0;
  int _hoverExitCount = 0;
  int _clickCount = 0;
  String _lastPointer = 'none';
  String _lastReplayEvent = 'none';
  runtime.ReplayEventPresentation? _lastReplayPresentation;
  final List<runtime.ReplayEventPresentation> _recentReplayPresentations =
      <runtime.ReplayEventPresentation>[];
  final List<String> _recentEvents = <String>[];

  bool? get _tooltipShow => switch (_visibilityMode) {
    TooltipVisibilityMode.hover => null,
    TooltipVisibilityMode.forcedVisible => true,
    TooltipVisibilityMode.forcedHidden => false,
  };

  String get _visibilityLabel => switch (_visibilityMode) {
    TooltipVisibilityMode.hover => 'hover',
    TooltipVisibilityMode.forcedVisible => 'forced visible',
    TooltipVisibilityMode.forcedHidden => 'forced hidden',
  };

  void _recordUiEvent(
    String type, {
    String? summary,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    runtime.TuiTrace.log('TOOLTIP_DEMO $type ${fields.isEmpty ? '' : fields}');
    runtime.TuiTrace.event(
      'tooltip_demo.$type',
      tag: runtime.TraceTag.general,
      fields: fields,
    );
    final line = summary ?? '$type ${fields.isEmpty ? '' : fields}';
    _recentEvents.insert(0, line.trim());
    if (_recentEvents.length > 8) {
      _recentEvents.removeRange(8, _recentEvents.length);
    }
  }

  void _cycleVisibilityMode() {
    _visibilityMode = switch (_visibilityMode) {
      TooltipVisibilityMode.hover => TooltipVisibilityMode.forcedVisible,
      TooltipVisibilityMode.forcedVisible => TooltipVisibilityMode.forcedHidden,
      TooltipVisibilityMode.forcedHidden => TooltipVisibilityMode.hover,
    };
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is runtime.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') {
        _recordUiEvent('quit.requested', summary: 'quit requested');
        return runtime.Cmd.quit();
      }
      if (key.char == 'p') {
        setState(() {
          _position = _position == w.TooltipPosition.above
              ? w.TooltipPosition.below
              : w.TooltipPosition.above;
          _recordUiEvent(
            'toggle.position',
            summary: 'position -> ${_position.name}',
            fields: <String, Object?>{'position': _position.name},
          );
        });
        return runtime.Cmd.repaint();
      }
      if (key.char == 's') {
        setState(() {
          _cycleVisibilityMode();
          _recordUiEvent(
            'toggle.visibility',
            summary: 'visibility -> $_visibilityLabel',
            fields: <String, Object?>{'visibility': _visibilityLabel},
          );
        });
        return runtime.Cmd.repaint();
      }
      if (key.char == 'e') {
        setState(() {
          _enabled = !_enabled;
          _recordUiEvent(
            'toggle.enabled',
            summary: 'enabled -> $_enabled',
            fields: <String, Object?>{'enabled': _enabled},
          );
        });
        return runtime.Cmd.repaint();
      }
      if (key.char == 'c') {
        setState(() {
          _recentEvents.clear();
          _recordUiEvent('events.cleared', summary: 'event list cleared');
        });
        return runtime.Cmd.repaint();
      }
    }

    if (msg is runtime.MouseMsg) {
      setState(() {
        _lastPointer =
            '${msg.action.name}:${msg.button.name} @ ${msg.x},${msg.y}';
      });
      runtime.TuiTrace.event(
        'tooltip_demo.mouse',
        tag: runtime.TraceTag.input,
        fields: <String, Object?>{
          'action': msg.action.name,
          'button': msg.button.name,
          'x': msg.x,
          'y': msg.y,
        },
      );
      return null;
    }

    if (msg is runtime.ReplayEventMsg) {
      final replayPresentation = msg.event.presentation;
      setState(() {
        _lastReplayEvent = msg.event.type;
        _lastReplayPresentation = replayPresentation;
        _recentReplayPresentations.insert(0, replayPresentation);
        if (_recentReplayPresentations.length > 5) {
          _recentReplayPresentations.removeRange(
            5,
            _recentReplayPresentations.length,
          );
        }
        _recordUiEvent(
          msg.event.renderCapture == null
              ? 'replay.event'
              : 'replay.render_capture',
          summary: replayPresentation.summary,
          fields: replayPresentation.fields,
        );
      });
      return runtime.Cmd.repaint();
    }

    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final media = w.MediaQuery.of(context);
    final width = math.min(92, math.max(56, media.size.width.toInt() - 4));

    final tooltipTarget = w.Tooltip(
      message: 'Tooltip hover count: $_hoverEnterCount',
      position: _position,
      enabled: _enabled,
      show: _tooltipShow,
      child: w.MouseRegion(
        onEnter: (event) {
          setState(() {
            _hovered = true;
            _hoverEnterCount++;
            _lastPointer = 'enter @ ${event.x},${event.y}';
            _recordUiEvent(
              'hover.enter',
              summary: 'hover enter @ ${event.x},${event.y}',
              fields: <String, Object?>{'x': event.x, 'y': event.y},
            );
          });
          return runtime.Cmd.repaint();
        },
        onExit: (event) {
          setState(() {
            _hovered = false;
            _hoverExitCount++;
            _lastPointer = 'exit @ ${event.x},${event.y}';
            _recordUiEvent(
              'hover.exit',
              summary: 'hover exit @ ${event.x},${event.y}',
              fields: <String, Object?>{'x': event.x, 'y': event.y},
            );
          });
          return runtime.Cmd.repaint();
        },
        child: w.Button(
          label: 'Hover target',
          size: w.ButtonSize.small,
          onPressed: () {
            setState(() {
              _clickCount++;
              _recordUiEvent(
                'button.press',
                summary: 'button pressed ($_clickCount)',
                fields: <String, Object?>{'clicks': _clickCount},
              );
            });
            return runtime.Cmd.repaint();
          },
        ),
      ),
    );

    return w.Center(
      child: w.SizedBox(
        width: width,
        child: w.Padding(
          padding: const w.EdgeInsets.all(1),
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text('Tooltip Trace Demo', style: theme.titleLarge),
              w.Text(
                'Hover the target and record with ARTISANAL_TUI_TRACE=1. '
                'Keys: p position | s visibility | e enabled | c clear | q quit',
                style: theme.bodySmall,
              ),
              if (widget.replayPlan != null)
                w.Text(
                  'Replay loaded: ${widget.replayPlan!.name} '
                  '(${widget.replayPlan!.actionCount} actions)',
                  style: theme.labelMedium,
                ),
              w.Divider(width: width - 2),
              w.Card(
                child: w.Column(
                  gap: 1,
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  children: [
                    w.Text('State', style: theme.titleMedium),
                    w.Text('hovered: $_hovered'),
                    w.Text('enabled: $_enabled'),
                    w.Text('visibility: $_visibilityLabel'),
                    w.Text('position: ${_position.name}'),
                    w.Text('hover enters: $_hoverEnterCount'),
                    w.Text('hover exits: $_hoverExitCount'),
                    w.Text('clicks: $_clickCount'),
                    w.Text('last pointer: $_lastPointer'),
                    w.Text('last replay event: $_lastReplayEvent'),
                  ],
                ),
              ),
              if (_lastReplayPresentation != null)
                w.ReplayEventPanel(
                  presentation: _lastReplayPresentation!,
                  title: 'Replay Summary',
                ),
              w.ReplayEventHistoryBrowser.interactive(
                events: _recentReplayPresentations,
                state: _replayHistory,
                onStateChanged: (state) {
                  setState(() {
                    if (state.filter != _replayHistory.filter) {
                      _recordUiEvent(
                        'replay.filter',
                        summary: 'replay filter -> ${state.filter.name}',
                        fields: <String, Object?>{'filter': state.filter.name},
                      );
                    }
                    if (state.mode != _replayHistory.mode) {
                      _recordUiEvent(
                        'replay.mode',
                        summary: 'replay mode -> ${state.mode.name}',
                        fields: <String, Object?>{'mode': state.mode.name},
                      );
                    }
                    if (state.expanded != _replayHistory.expanded) {
                      _recordUiEvent(
                        'replay.expand',
                        summary: 'replay expand -> ${state.expanded}',
                        fields: <String, Object?>{'expanded': state.expanded},
                      );
                    }
                    _replayHistory = state;
                  });
                  return runtime.Cmd.repaint();
                },
                title: 'Replay History',
              ),
              w.Card(
                child: w.Column(
                  gap: 1,
                  children: [
                    w.Text('Tooltip target', style: theme.titleMedium),
                    w.Text(
                      'When an Overlay ancestor is present, the tooltip should float '
                      'without shifting this layout.',
                      style: theme.bodySmall,
                    ),
                    w.SizedBox(
                      height: 5,
                      child: w.Center(child: tooltipTarget),
                    ),
                  ],
                ),
              ),
              w.Card(
                child: w.Column(
                  gap: 1,
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  children: [
                    w.Text('Recent events', style: theme.titleMedium),
                    if (_recentEvents.isEmpty)
                      w.Text('No events yet.', style: theme.bodySmall)
                    else
                      ..._recentEvents.map(
                        (event) => w.Text(event, style: theme.bodySmall),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const String _usage = '''
Tooltip Trace Demo

Run live with tracing:
  ARTISANAL_TUI_TRACE=1 dart run pkgs/artisanal_widgets/example/tooltip_trace/main.dart

Replay options:
  --replay-scenario <path>     Load a replay scenario JSON file.
  --replay-trace <path>        Convert a TuiTrace log into a replay scenario.
  --replay-trace-out <path>    Write the converted scenario JSON to a file.
  --replay-convert-only        Convert the trace and exit.
  --replay-speed <value>       Replay speed multiplier (default: 1.0).
  --replay-loop                Loop the replay stream.
  --replay-keep-open           Do not append QuitMsg after replay.
  --replay-block-input         Ignore live input while replay is active.
''';
