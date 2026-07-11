import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/widgets.dart' as w;

import 'cli/flutter_process.dart';
import 'model.dart';
import 'render.dart';
import 'theme.dart';

class FlutterCliDashboard extends w.StatefulWidget {
  FlutterCliDashboard({
    FlutterCliState? initialState,
    this.process,
    this.flTheme = FlutterCliTheme.tokyoNight,
    super.key,
  }) : initialState = initialState ?? FlutterCliState.demo();

  final FlutterCliState initialState;
  final FlutterProcessSpec? process;
  final FlutterCliTheme flTheme;

  @override
  w.State createState() => _FlutterCliDashboardState();
}

class _FlutterCliDashboardState extends w.State<FlutterCliDashboard> {
  late FlutterCliState state;
  int brightnessMode = 0;
  bool debugPaint = false;
  bool perfOverlay = false;
  bool platformIsIos = false;

  @override
  void initState() {
    super.initState();
    state = widget.initialState;
  }

  @override
  runtime.Cmd? handleInit() {
    final process = widget.process;
    if (process == null) return null;
    return listenToFlutterProcess(process);
  }

  @override
  w.Widget build(w.BuildContext context) {
    return FlutterCliRender(
      state: state,
      flTheme: widget.flTheme,
      brightnessMode: brightnessMode,
    );
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is FlutterProcessStarted) {
      setState(() {
        state.banner = FlutterCliBanner(
          kind: FlutterCliBannerKind.info,
          message: 'Running ${msg.commandLine}',
        );
        state.progressPhases.add(
          FlutterCliProgressPhase(
            id: 'start',
            message: 'Starting flutter run',
            startedAt: DateTime.now(),
          ),
        );
      });
      return runtime.Cmd.println('\$ ${msg.commandLine}');
    }
    if (msg is FlutterProcessLine) {
      final event = msg.event;
      setState(() {
        final level = msg.stderr
            ? FlutterCliLogLevel.error
            : FlutterCliLogLevel.info;
        state.logs.add(FlutterCliLogLine(level, msg.line));
        if (state.logs.length > 200) state.logs.removeFirst();
        if (event is FlutterCliProgressEvent) {
          _applyProgress(event);
        }
        _recordActivity(msg.line);
        if (msg.line.contains('Flutter run key commands') ||
            msg.line.contains('An Observatory debugger') ||
            msg.line.contains('The Flutter DevTools debugger') ||
            msg.line.contains('Dart VM Service')) {
          state.vmConnected = true;
          state.compileFinished ??= DateTime.now().difference(state.startedAt);
          for (final session in state.activeSessions) {
            session.state = FlutterCliSessionState.ready;
          }
        }
      });
      return runtime.Cmd.println(msg.line);
    }
    if (msg is FlutterProcessExited) {
      setState(() {
        state.banner = FlutterCliBanner(
          kind: msg.exitCode == 0
              ? FlutterCliBannerKind.success
              : FlutterCliBannerKind.error,
          message: 'flutter run exited with code ${msg.exitCode}',
          persistent: true,
        );
        for (final session in state.activeSessions) {
          session.state = msg.exitCode == 0
              ? FlutterCliSessionState.stopped
              : FlutterCliSessionState.failed;
        }
      });
      return runtime.Cmd.println(
        'flutter run exited with code ${msg.exitCode}',
      );
    }
    if (msg is FlutterProcessFailed) {
      setState(() {
        state.banner = FlutterCliBanner(
          kind: FlutterCliBannerKind.error,
          message: msg.message,
          persistent: true,
        );
      });
      return runtime.Cmd.println(msg.message);
    }
    if (msg is! runtime.KeyMsg) return null;
    final key = msg.key;
    final char = key.char;
    if (char == 'q' || key.type == KeyType.escape) {
      return runtime.Cmd.quit();
    }
    if (char == 'n') {
      setState(() => state.showNetwork = !state.showNetwork);
      return null;
    }
    if (char == 'b') {
      setState(() => brightnessMode = (brightnessMode + 1) % 3);
      return null;
    }
    if (char == 'p') {
      setState(() => debugPaint = !debugPaint);
      return null;
    }
    if (char == 'P') {
      setState(() => perfOverlay = !perfOverlay);
      return null;
    }
    if (char == 'o') {
      setState(() => platformIsIos = !platformIsIos);
      return null;
    }
    if (char == 'r' || char == 'R') {
      setState(() {
        state.banner = FlutterCliBanner(
          kind: FlutterCliBannerKind.info,
          message: char == 'R' ? 'Hot restart requested' : 'Hot reload sent',
        );
      });
    }
    return null;
  }

  void _applyProgress(FlutterCliProgressEvent event) {
    for (var i = 0; i < state.progressPhases.length; i++) {
      final phase = state.progressPhases[i];
      if (phase.id == event.id) {
        state.progressPhases[i] = FlutterCliProgressPhase(
          id: phase.id,
          message: event.message,
          startedAt: phase.startedAt,
          finishedAt: event.finished
              ? (phase.finishedAt ?? DateTime.now())
              : phase.finishedAt,
          xcodeSubSteps: phase.xcodeSubSteps,
        );
        return;
      }
    }
    state.progressPhases.add(
      FlutterCliProgressPhase(
        id: event.id,
        message: event.message,
        startedAt: DateTime.now(),
        finishedAt: event.finished ? DateTime.now() : null,
      ),
    );
  }

  void _recordActivity(String line) {
    final elapsedMs = DateTime.now().difference(state.startedAt).inMilliseconds;
    final pulse = (elapsedMs ~/ 500) % 8;
    final fps = state.vmConnected ? 120.0 : 48.0 + pulse * 3;
    final mem = 180.0 + (state.logs.length % 70);
    state.fpsSamples.add(fps);
    state.memSamples.add(mem);
    while (state.fpsSamples.length > 60) {
      state.fpsSamples.removeFirst();
    }
    while (state.memSamples.length > 60) {
      state.memSamples.removeFirst();
    }
    state.frameUiMs = state.vmConnected ? 0.5 : 6.0 + pulse / 2;
    state.frameRasterMs = state.vmConnected ? 0.5 : 4.0 + pulse / 3;
    state.heapCapacityMb = state.heapCapacityMb <= 0
        ? 240
        : state.heapCapacityMb;

    final lower = line.toLowerCase();
    for (final session in state.activeSessions) {
      if (session.platform == null || session.platform!.isEmpty) {
        if (lower.contains('linux')) {
          session.platform = 'linux';
          session.displayName = session.displayName == 'auto device'
              ? 'linux'
              : session.displayName;
        } else if (lower.contains('android') || lower.contains('gradle')) {
          session.platform = 'android';
        } else if (lower.contains('xcode') || lower.contains('ios')) {
          session.platform = 'ios';
        }
      }
      if (lower.contains('syncing files') ||
          lower.contains('hot reload') ||
          lower.contains('hot restart')) {
        session.state = FlutterCliSessionState.reloading;
      } else if (state.vmConnected ||
          lower.contains('flutter run key commands')) {
        session.state = FlutterCliSessionState.ready;
      }
    }
  }
}
