import 'dart:collection';
import 'dart:math' as math;

import 'package:artisanal/style.dart' as style;

import 'model.dart';
import 'theme.dart';

const minWidth = 50;
const minHeight = 8;
const narrowWidth = 90;
const sparkBlocks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

String formatElapsed(Duration duration) {
  final total = duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String truncate(String value, int max) {
  if (max <= 0) return '';
  final runes = value.runes.toList();
  if (runes.length <= max) return value;
  if (max == 1) return '…';
  return '${String.fromCharCodes(runes.take(max - 1))}…';
}

String sparkline(Iterable<double> samples, double max, int width) {
  if (width <= 0) return '';
  final values = samples.toList();
  if (values.isEmpty || max <= 0) return ' ' * width;
  final visible = values.length <= width
      ? values
      : values.sublist(values.length - width);
  final out = StringBuffer();
  for (var i = visible.length; i < width; i++) {
    out.write(' ');
  }
  for (final value in visible) {
    final t = (value / max).clamp(0.0, 1.0);
    final idx = (t * (sparkBlocks.length - 1)).round();
    out.write(sparkBlocks[idx]);
  }
  return out.toString();
}

String buildBar(int width, int pct) {
  if (width <= 0) return '';
  final filled = width * pct.clamp(0, 100) ~/ 100;
  return '${'█' * filled}${'░' * (width - filled)}';
}

int estimatedPercentage(FlutterCliState state) {
  if (state.appReady) return 100;
  if (state.progressPhases.isEmpty) {
    return math.min(3, DateTime.now().difference(state.startedAt).inSeconds);
  }
  var pct = 0.0;
  for (final phase in state.progressPhases) {
    final weight = phaseWeight(phase).toDouble();
    if (phase.finishedAt != null) {
      pct += weight;
      continue;
    }
    final inside =
        phase.xcodeSubSteps > 0 &&
            phase.message.toLowerCase().contains('xcode build')
        ? math.min(0.95, phase.xcodeSubSteps / 120.0)
        : math.min(
            0.95,
            DateTime.now().difference(phase.startedAt).inSeconds /
                phaseEstimatedSeconds(phase),
          );
    pct += weight * inside;
    break;
  }
  return pct.clamp(0, 99).round();
}

int phaseWeight(FlutterCliProgressPhase phase) {
  final message = phase.message.toLowerCase();
  if (message.contains('xcode build')) return 65;
  if (message.contains('gradle')) return 60;
  if (message.contains('installing and launching')) return 20;
  if (message.contains('pod install')) return 8;
  if (message.contains('resolving dependencies') ||
      message.contains('running pub get')) {
    return 3;
  }
  if (message.contains('waiting for connection') ||
      message.contains('vm service')) {
    return 4;
  }
  return 8;
}

int phaseEstimatedSeconds(FlutterCliProgressPhase phase) {
  final message = phase.message.toLowerCase();
  if (message.contains('xcode build')) return 90;
  if (message.contains('gradle')) return 45;
  if (message.contains('installing and launching')) return 15;
  if (message.contains('pod install')) return 30;
  return 10;
}

style.Color statusColor(int? status, FlutterCliTheme theme) {
  if (status == null) return theme.dim;
  if (status >= 200 && status < 300) return theme.success;
  if (status >= 300 && status < 400) return theme.fg;
  if (status >= 400 && status < 500) return theme.warn;
  return theme.error;
}

double average(ListQueue<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

double maxOrZero(ListQueue<double> values) =>
    values.isEmpty ? 0 : values.reduce(math.max);
