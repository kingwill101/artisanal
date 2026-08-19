import 'dart:math' as math;

import 'package:artisanal_widgets/widgets.dart' as w;

import '../model.dart';
import '../theme.dart';
import '../utils.dart';
import 'panel.dart';

class PerformancePanel extends w.StatelessWidget {
  PerformancePanel({
    required this.state,
    required this.flTheme,
    required this.panelWidth,
    super.key,
  });

  final FlutterCliState state;
  final FlutterCliTheme flTheme;
  final int panelWidth;

  @override
  w.Widget build(w.BuildContext context) {
    final width = panelWidth;
    final innerWidth = math.max(12, width - 8);
    final curFps = state.fpsSamples.isEmpty ? 0.0 : state.fpsSamples.last;
    final avgFps = average(state.fpsSamples);
    final peak = maxOrZero(state.fpsSamples);
    final curMem = state.memSamples.isEmpty ? 0.0 : state.memSamples.last;
    final memMax = math.max(
      state.heapCapacityMb,
      state.memSamples.isEmpty ? 64.0 : state.memSamples.reduce(math.max),
    );
    final memLabel = state.heapCapacityMb > 0
        ? '${curMem.toStringAsFixed(0)}/${state.heapCapacityMb.toStringAsFixed(0)}MB'
        : '${curMem.toStringAsFixed(0)}MB';
    final fpsColor = curFps >= 55
        ? flTheme.success
        : curFps >= 30
        ? flTheme.warn
        : flTheme.error;

    return FlutterCliPanel(
      title: 'Performance',
      flTheme: flTheme,
      child: w.Column(
        gap: 0,
        children: [
          w.Text(
            'FPS    ${sparkline(state.fpsSamples, 60, innerWidth - 13)} '
            '${curFps.toStringAsFixed(1).padLeft(5)}',
            style: flTheme.fgStyle(fpsColor),
            softWrap: false,
          ),
          w.Text(
            'Frame  ui ${state.frameUiMs.toStringAsFixed(1).padLeft(4)}ms  '
            'raster ${state.frameRasterMs.toStringAsFixed(1).padLeft(4)}ms',
            style: flTheme.dimmed,
            softWrap: false,
          ),
          w.Text(
            'Memory ${sparkline(state.memSamples, memMax, innerWidth - memLabel.length - 8)} '
            '$memLabel',
            style: flTheme.base,
            softWrap: false,
          ),
          w.Text(
            'Avg  ${avgFps.toStringAsFixed(1).padLeft(4)}fps  '
            'rate ${state.fpsSamples.length.toString().padLeft(3)}/s  '
            'peak ${peak.toStringAsFixed(1).padLeft(4)}',
            style: flTheme.dimmed,
            softWrap: false,
          ),
        ],
      ),
    );
  }
}
