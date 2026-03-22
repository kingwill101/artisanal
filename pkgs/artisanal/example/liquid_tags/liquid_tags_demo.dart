import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal/liquid.dart';
import 'package:liquify/liquify.dart' as liquify;

int _terminalColumns() {
  if (stdout.hasTerminal) {
    final cols = stdout.terminalColumns;
    if (cols > 0) return cols;
  }
  return 90;
}

int _terminalLines() {
  if (stdout.hasTerminal) {
    final lines = stdout.terminalLines;
    if (lines > 0) return lines;
  }
  return 30;
}

String _truncateCell(String value, int width) {
  if (width <= 0) return '';
  if (value.length <= width) return value;
  if (width <= 3) return value.substring(0, width);
  return '${value.substring(0, width - 3)}...';
}

void main() {
  final rng = math.Random(7);
  final cpu = 55 + rng.nextInt(35);
  final mem = 40 + rng.nextInt(50);
  final gpu = 10 + rng.nextInt(80);
  final temp = 48 + rng.nextInt(30);

  final viewportWidth = _terminalColumns();
  final viewportHeight = _terminalLines();
  final frameWidth = math.max(40, viewportWidth - 1);
  final frameHeight = math.max(24, viewportHeight - 1);
  final innerWidth = math.max(40, frameWidth - 2);
  final innerHeight = math.max(16, frameHeight - 2);
  final colGap = innerWidth >= 160 ? 3 : 2;
  final rowGap = innerWidth >= 160 ? 2 : 1;
  final panelPadding = innerWidth >= 180
      ? 2
      : innerWidth >= 140
      ? 1
      : 0;

  final availableHeight = innerHeight - rowGap * 2;
  const topMin = 10;
  const midMin = 7;
  const bottomMin = 6;
  final minSum = topMin + midMin + bottomMin;

  int topHeight;
  int midHeight;
  int bottomHeight;

  if (availableHeight <= minSum) {
    final scale = availableHeight / minSum;
    topHeight = math.max(5, (topMin * scale).floor());
    midHeight = math.max(5, (midMin * scale).floor());
    bottomHeight = availableHeight - topHeight - midHeight;
    if (bottomHeight < 4) {
      bottomHeight = 4;
      final remaining = availableHeight - bottomHeight;
      topHeight = math.max(5, remaining ~/ 2);
      midHeight = remaining - topHeight;
    }
  } else {
    topHeight = math.max(topMin, (availableHeight * 0.34).floor());
    midHeight = math.max(midMin, (availableHeight * 0.33).floor());
    bottomHeight = availableHeight - topHeight - midHeight;
    if (bottomHeight < bottomMin) {
      bottomHeight = bottomMin;
      final remaining = availableHeight - bottomHeight;
      topHeight = math.max(topMin, remaining ~/ 2);
      midHeight = remaining - topHeight;
    }
  }

  var teleWidth = math.max(24, (innerWidth * 0.32).floor());
  var linePanelWidth = innerWidth - teleWidth - colGap;
  if (linePanelWidth < 28) {
    linePanelWidth = 28;
    teleWidth = innerWidth - linePanelWidth - colGap;
  }

  final midTotal = innerWidth - colGap * 2;
  final midBase = math.max(20, midTotal ~/ 3);
  final midRemainder = math.max(0, midTotal - midBase * 3);
  final histoWidth = midBase + (midRemainder > 0 ? 1 : 0);
  final piePanelWidth = midBase + (midRemainder > 1 ? 1 : 0);
  final nodePanelWidth = midTotal - histoWidth - piePanelWidth;

  final teleInnerWidth = math.max(12, teleWidth - 2 - panelPadding * 2);
  final lineInnerWidth = math.max(20, linePanelWidth - 2 - panelPadding * 2);
  final lineInnerHeight = math.max(3, topHeight - 2 - panelPadding * 2);
  final histoInnerWidth = math.max(12, histoWidth - 2 - panelPadding * 2);
  final histoInnerHeight = math.max(3, midHeight - 2 - panelPadding * 2);
  final pieInnerWidth = math.max(8, piePanelWidth - 2 - panelPadding * 2);
  final pieInnerHeight = math.max(4, midHeight - 2 - panelPadding * 2);
  final pieSize = math.max(4, math.min(pieInnerWidth, pieInnerHeight));

  final nodeInnerWidth = math.max(10, nodePanelWidth - 2 - panelPadding * 2);
  final nodeColumns = nodeInnerWidth >= 30 ? 2 : 1;
  final nodeGap = 1;
  final nodeCellWidth = math.max(
    6,
    (nodeInnerWidth - nodeGap * (nodeColumns - 1)) ~/ nodeColumns,
  );

  final data = <String, Object?>{
    'cpu': cpu,
    'mem': mem,
    'gpu': gpu,
    'temp': temp,
    'columns': [
      'Telemetry\nCPU $cpu%\nMEM $mem%\nGPU $gpu%\nTMP ${temp}C',
      'Network\nIN  148 mb/s\nOUT 305 mb/s\nPPS 1.2m\nLAT 18ms',
    ],
    'metrics': ['CPU $cpu%', 'MEM $mem%', 'GPU $gpu%', 'TMP ${temp}C'],
    'cpuSeries': List<double>.generate(
      24,
      (i) => 40 + 20 * math.sin(i / 3) + rng.nextInt(12),
    ),
    'lineSeries': List<double>.generate(
      60,
      (i) => 55 + 18 * math.sin(i / 4) + rng.nextInt(10),
    ),
    'histoValues': List<double>.generate(
      32,
      (i) => 50 + 30 * math.sin(i / 6) + rng.nextInt(20),
    ),
    'pieValues': [
      cpu.toDouble(),
      mem.toDouble(),
      gpu.toDouble(),
      temp.toDouble(),
    ],
    'pieColors': ['#9b5de5', '#00bbf9', '#00f5d4', '#f15bb5'],
    'nodes': [
      'edge-1 us-e 72%',
      'edge-2 us-w 65%',
      'edge-3 eu-n 48%',
      'edge-4 ap-s 39%',
      'edge-5 sa-e 54%',
      'edge-6 ap-e 33%',
    ].map((item) => _truncateCell(item, nodeCellWidth)).toList(),
    'tableHeaders': ['node', 'region', 'lat', 'err', 'qps'],
    'tableRows': [
      ['edge-1', 'us-east', '170ms', '3', '1.2k'],
      ['edge-2', 'us-west', '158ms', '1', '1.0k'],
      ['edge-3', 'eu-north', '213ms', '7', '780'],
      ['edge-4', 'ap-south', '269ms', '2', '610'],
      ['edge-5', 'sa-east', '321ms', '9', '480'],
      ['edge-6', 'ap-east', '198ms', '4', '520'],
    ],
    'tableAlign': ['left', 'left', 'right', 'right', 'right'],
    'progress': (cpu + mem) / 2.0,
    'frameWidth': frameWidth,
    'frameHeight': frameHeight,
    'colGap': colGap,
    'rowGap': rowGap,
    'topHeight': topHeight,
    'midHeight': midHeight,
    'bottomHeight': bottomHeight,
    'teleWidth': teleWidth,
    'linePanelWidth': linePanelWidth,
    'histoWidth': histoWidth,
    'piePanelWidth': piePanelWidth,
    'nodePanelWidth': nodePanelWidth,
    'teleInnerWidth': teleInnerWidth,
    'lineInnerWidth': lineInnerWidth,
    'lineInnerHeight': lineInnerHeight,
    'histoInnerWidth': histoInnerWidth,
    'histoInnerHeight': histoInnerHeight,
    'pieSize': pieSize,
    'nodeColumns': nodeColumns,
    'nodeGap': nodeGap,
    'tablePanelWidth': innerWidth,
    'panelPadding': panelPadding,
    'tableWidth': math.max(20, innerWidth - 2 - panelPadding * 2),
  };

  // Register tags globally before parsing so the custom parser picks them up.
  registerLiquidUiTags();
  final scriptDir = File.fromUri(Platform.script).parent;
  final root = liquify.FileSystemRoot(scriptDir.path, throwOnMissing: true);
  final liquid = liquify.Liquid(root: root);
  final template = liquid.parseFile('dashboard.liquid');
  final buffer = template.renderTo(
    UvBufferTarget(width: frameWidth, height: frameHeight),
    data,
    null,
    (env) => registerLiquidUiTags(environment: env),
  );

  stdout.write('\x1B[2J\x1B[H');
  stdout.write(buffer.render());
}
