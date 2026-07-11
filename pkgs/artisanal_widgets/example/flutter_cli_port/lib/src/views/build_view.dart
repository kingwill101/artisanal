import 'dart:math' as math;

import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../cli/flutter_process.dart';
import '../model.dart';
import '../theme.dart';
import '../utils.dart';

class BuildView extends w.StatefulWidget {
  BuildView({
    required this.target,
    this.mode = FlutterCliBuildMode.debug,
    this.process,
    this.flTheme = FlutterCliTheme.tokyoNight,
    super.key,
  });

  final String target;
  final FlutterCliBuildMode mode;
  final FlutterProcessSpec? process;
  final FlutterCliTheme flTheme;

  @override
  w.State createState() => BuildViewState();
}

class BuildViewState extends w.State<BuildView> {
  final steps = <FlutterCliBuildStep>[];
  final logTail = <({FlutterCliLogLevel level, String message})>[];
  String? finalPath;
  int? finalSize;
  bool quitting = false;
  late DateTime startedAt;
  var elapsed = Duration.zero;
  int? exitCode;
  Duration? linger;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
  }

  @override
  runtime.Cmd? handleInit() {
    final process = widget.process;
    if (process == null) return null;
    return listenToFlutterProcess(process);
  }

  void apply(FlutterCliFlutterEvent input) {
    switch (input) {
      case FlutterCliProgressEvent(:final id, :final message, :final finished):
        final existing = _findStep(id);
        if (existing != null) {
          existing.message = message;
          if (finished && existing.status == FlutterCliStepStatus.running) {
            existing
              ..status = FlutterCliStepStatus.done
              ..finishedAt = DateTime.now();
          }
        } else {
          steps.add(
            FlutterCliBuildStep(
              id: id,
              message: message,
              status: finished
                  ? FlutterCliStepStatus.done
                  : FlutterCliStepStatus.running,
              startedAt: DateTime.now(),
              finishedAt: finished ? DateTime.now() : null,
            ),
          );
        }
      case FlutterCliBuildLogEvent(:final level, :final message):
        if (level == FlutterCliLogLevel.error && steps.isNotEmpty) {
          final last = steps.last;
          if (last.status == FlutterCliStepStatus.running) {
            last
              ..status = FlutterCliStepStatus.failed
              ..finishedAt = DateTime.now();
          }
        }
        if (message.startsWith('Built ')) {
          final parsed = parseBuiltLine(message.substring('Built '.length));
          if (parsed != null) {
            finalPath = parsed.path;
            finalSize = parsed.bytes;
          }
        }
        logTail.add((level: level, message: message));
        if (logTail.length > 200) logTail.removeAt(0);
      case FlutterCliStoppedEvent(:final exitCode):
        this.exitCode = exitCode;
        linger = Duration.zero;
        if ((exitCode ?? 0) != 0 && steps.isNotEmpty) {
          final last = steps.last;
          if (last.status == FlutterCliStepStatus.running) {
            last
              ..status = FlutterCliStepStatus.failed
              ..finishedAt = DateTime.now();
          }
        }
        if ((exitCode ?? 0) == 0) quitting = true;
    }
  }

  FlutterCliBuildStep? _findStep(String id) {
    for (final step in steps) {
      if (step.id == id) return step;
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.flTheme;
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();
    final height = media.size.height.round();
    final bodyHeight = math.max(1, height - 7);
    return w.Container(
      width: width,
      height: height,
      background: theme.bg,
      child: w.Column(
        width: width,
        height: height,
        children: [
          _BuildHeader(
            target: widget.target,
            mode: widget.mode,
            elapsed: elapsed,
            flTheme: theme,
          ),
          w.Expanded(
            child: _BuildStepsPanel(
              steps: steps,
              logTail: logTail,
              heightHint: bodyHeight,
              flTheme: theme,
            ),
          ),
          _BuildStatus(
            finalPath: finalPath,
            finalSize: finalSize,
            exitCode: exitCode,
            flTheme: theme,
          ),
          w.Text(' [c] copy logs 📋   [q] quit ', style: theme.dimmed),
        ],
      ),
    );
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is FlutterProcessStarted) {
      setState(() {
        apply(
          FlutterCliBuildLogEvent(
            FlutterCliLogLevel.info,
            '\$ ${msg.commandLine}',
          ),
        );
      });
      return runtime.Cmd.println('\$ ${msg.commandLine}');
    }
    if (msg is FlutterProcessLine) {
      setState(() {
        final event =
            msg.event ??
            FlutterCliBuildLogEvent(
              msg.stderr ? FlutterCliLogLevel.error : FlutterCliLogLevel.info,
              msg.line,
            );
        apply(event);
      });
      return runtime.Cmd.println(msg.line);
    }
    if (msg is FlutterProcessExited) {
      setState(() => apply(FlutterCliStoppedEvent(msg.exitCode)));
      return runtime.Cmd.println(
        'flutter build exited with code ${msg.exitCode}',
      );
    }
    if (msg is FlutterProcessFailed) {
      setState(() {
        apply(FlutterCliBuildLogEvent(FlutterCliLogLevel.error, msg.message));
        apply(const FlutterCliStoppedEvent(1));
      });
      return runtime.Cmd.println(msg.message);
    }
    if (msg is! runtime.KeyMsg) return null;
    final key = msg.key;
    if (key.char == 'q' || key.ctrlC) {
      setState(() => quitting = true);
      return null;
    }
    if (key.char == 'c') {
      setState(() {
        logTail.add((
          level: FlutterCliLogLevel.info,
          message: '📋 Copied ${logTail.length} log lines to clipboard',
        ));
      });
    }
    return null;
  }
}

class _BuildHeader extends w.StatelessWidget {
  _BuildHeader({
    required this.target,
    required this.mode,
    required this.elapsed,
    required this.flTheme,
  });

  final String target;
  final FlutterCliBuildMode mode;
  final Duration elapsed;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final ms = elapsed.inMilliseconds;
    final text =
        ' flutter-cli build ── $target · ${mode.name} · ${(ms ~/ 1000).toString().padLeft(4)}.${(ms % 1000) ~/ 100}s ';
    return w.Frame(
      border: style.Border.normal,
      borderColor: flTheme.accent,
      background: flTheme.bg,
      foreground: flTheme.fg,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.Text(text, style: flTheme.header, softWrap: false),
    );
  }
}

class _BuildStepsPanel extends w.StatelessWidget {
  _BuildStepsPanel({
    required this.steps,
    required this.logTail,
    required this.heightHint,
    required this.flTheme,
  });

  final List<FlutterCliBuildStep> steps;
  final List<({FlutterCliLogLevel level, String message})> logTail;
  final int heightHint;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final width = w.MediaQuery.of(context).size.width.round();
    final lines = <w.Widget>[];
    for (final step in steps) {
      final (marker, color) = switch (step.status) {
        FlutterCliStepStatus.running => ('⠋ ', flTheme.warn),
        FlutterCliStepStatus.done => ('✓ ', flTheme.success),
        FlutterCliStepStatus.failed => ('✗ ', flTheme.error),
      };
      final finished = step.finishedAt ?? DateTime.now();
      final elapsedMs = finished.difference(step.startedAt).inMilliseconds;
      lines.add(
        w.Text(
          '$marker${step.message.padRight(40)} ${elapsedMs.toString().padLeft(5)}ms',
          style: flTheme.fgStyle(color),
          softWrap: false,
        ),
      );
    }
    final cap = math.max(0, heightHint - lines.length - 2);
    final start = logTail.length > cap ? logTail.length - cap : 0;
    for (final entry in logTail.skip(start)) {
      final color =
          entry.message.startsWith('✓ Built ') ||
              entry.message.startsWith('Built ') ||
              entry.message.startsWith('📋 ')
          ? flTheme.success
          : switch (entry.level) {
              FlutterCliLogLevel.error => flTheme.error,
              FlutterCliLogLevel.warn => flTheme.warn,
              FlutterCliLogLevel.debug ||
              FlutterCliLogLevel.trace => flTheme.dim,
              FlutterCliLogLevel.info => flTheme.fg,
            };
      lines.add(
        w.Text(
          truncate(entry.message, width - 4),
          style: flTheme.fgStyle(color),
          softWrap: false,
        ),
      );
    }
    return w.PanelBox(
      title: 'Steps',
      border: style.Border.normal,
      borderColor: flTheme.dim,
      background: flTheme.bg,
      foreground: flTheme.fg,
      titleStyle: flTheme.bold(flTheme.accent),
      bodyStyle: flTheme.base,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(children: lines),
    );
  }
}

class _BuildStatus extends w.StatelessWidget {
  _BuildStatus({
    required this.finalPath,
    required this.finalSize,
    required this.exitCode,
    required this.flTheme,
  });

  final String? finalPath;
  final int? finalSize;
  final int? exitCode;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    late final String text;
    late final style.Color color;
    if (finalPath != null && finalSize != null) {
      text = 'Built $finalPath · ${humanSize(finalSize!)}';
      color = flTheme.success;
    } else if (exitCode case final code? when code != 0) {
      text = '✗ flutter build exited with code $code — see log above';
      color = flTheme.error;
    } else if (exitCode != null) {
      text = '✓ done';
      color = flTheme.success;
    } else {
      text = ' ';
      color = flTheme.dim;
    }
    return w.Frame(
      border: style.Border.normal,
      borderColor: flTheme.dim,
      background: flTheme.bg,
      foreground: flTheme.fg,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.Text(text, style: flTheme.fgStyle(color), softWrap: false),
    );
  }
}

({String path, int bytes})? parseBuiltLine(String rest) {
  final idx = rest.lastIndexOf(' (');
  if (idx < 0) return null;
  final path = rest.substring(0, idx);
  final size = rest.substring(idx + 2).replaceAll(RegExp(r'[).]+$'), '');
  final bytes = parseSizeToBytes(size);
  if (bytes == null) return null;
  return (path: path, bytes: bytes);
}

int? parseSizeToBytes(String value) {
  final match = RegExp(r'^\s*([0-9.]+)\s*([KMGT]?B|b)\s*$').firstMatch(value);
  if (match == null) return null;
  final amount = double.tryParse(match.group(1)!);
  if (amount == null) return null;
  final multiplier = switch (match.group(2)) {
    'B' || 'b' => 1,
    'KB' => 1024,
    'MB' => 1024 * 1024,
    'GB' => 1024 * 1024 * 1024,
    'TB' => 1024 * 1024 * 1024 * 1024,
    _ => 1,
  };
  return (amount * multiplier).round();
}

String humanSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  final mb = bytes / (1024 * 1024);
  if (mb < 1024) return '${mb.toStringAsFixed(1)}MB';
  return '${(mb / 1024).toStringAsFixed(1)}GB';
}

extension on runtime.Key {
  bool get ctrlC => ctrl && runes.length == 1 && runes.first == 0x63;
}
