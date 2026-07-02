library;

import 'dart:math' as math;

import 'package:artisanal/bubbles.dart' show Panel;
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

import 'data.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Rendering helpers
// ─────────────────────────────────────────────────────────────────────────────

String renderBar(
  double value,
  int width,
  Color color, {
  String fillChar = BlockShades.full,
  String emptyChar = BlockShades.light,
}) {
  final clamped = value.clamp(0.0, 1.0);
  final filled = (clamped * width).round().clamp(0, width);
  final empty = width - filled;
  final fill = Style().foreground(color).render(fillChar * filled);
  final rest = Style().foreground(Colors.gray).render(emptyChar * empty);
  return '$fill$rest';
}

String renderSparkline(List<double> values, int width, Color color) {
  if (values.isEmpty) return ' ' * width;
  final chars = SparkBars.levels;
  final maxValue = values.reduce(math.max);
  final buffer = StringBuffer();
  final step = values.length > width ? values.length / width : 1.0;

  for (var i = 0; i < width; i++) {
    final idx = (i * step).floor().clamp(0, values.length - 1);
    final value = values[idx];
    final normalized = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final charIdx = 1 + (normalized * (chars.length - 2)).round();
    buffer.write(chars[charIdx]);
  }

  return Style().foreground(color).render(buffer.toString());
}

List<String> padLines(List<String> lines, int height, {String filler = ''}) {
  if (lines.length >= height) {
    return lines.take(height).toList();
  }
  final padded = [...lines];
  while (padded.length < height) {
    padded.add(filler);
  }
  return padded;
}

List<String> fitChartLines(List<String> lines, int width, int height) {
  final paddedWidth = lines
      .map((line) => Layout.pad(line, width))
      .toList(growable: false);
  return padLines(paddedWidth, height, filler: ' ' * width);
}

String panelBox({
  required String title,
  required List<String> lines,
  required int width,
  required int height,
  required Style borderStyle,
  Style? titleStyle,
}) {
  final innerHeight = math.max(1, height - 2);
  final padded = padLines(lines, innerHeight);
  return Panel()
      .title(title)
      .border(Border.rounded)
      .borderStyle(borderStyle)
      .titleStyle(titleStyle ?? Style().bold())
      .width(width)
      .lines(padded)
      .render();
}

String truncatePlain(String text, int width) {
  if (width <= 0) return '';
  final visible = Style.visibleLength(text);
  if (visible <= width) return text;
  final stripped = Layout.stripAnsi(text);
  if (stripped.length <= width) return stripped;
  return '${stripped.substring(0, math.max(0, width - 1))}…';
}

// ─────────────────────────────────────────────────────────────────────────────
// Node list delegate
// ─────────────────────────────────────────────────────────────────────────────

final class NodeItem implements tui.ListItem {
  NodeItem(this.node);

  final ServiceNode node;

  @override
  String filterValue() => '${node.name} ${node.region}';
}

final class NodeDelegate implements tui.ItemDelegate {
  NodeDelegate(this.theme);

  DemoThemeData theme;

  void updateTheme(DemoThemeData data) {
    theme = data;
  }

  @override
  int get height => 2;

  @override
  int get spacing => 0;

  @override
  String render(tui.ListModel model, int index, tui.ListItem item) {
    final node = (item as NodeItem).node;
    final selected = model.index == index;

    final statusColor = switch (node.status) {
      ServiceStatus.online => theme.palette.success,
      ServiceStatus.warming => theme.palette.warning,
      ServiceStatus.degraded => theme.palette.error,
      ServiceStatus.offline => Colors.gray,
    };
    final statusIcon = switch (node.status) {
      ServiceStatus.online => Circles.filled,
      ServiceStatus.warming => ArcSegments.leftHalf,
      ServiceStatus.degraded => ArcSegments.lowerHalfCircle,
      ServiceStatus.offline => Circles.empty,
    };

    final prefix = selected
        ? Style().foreground(theme.palette.accentBold).render(Triangles.right)
        : Style().foreground(theme.palette.textDim).render(DotChars.bullet);

    final name = node.name.padRight(8);
    final region = Style()
        .foreground(theme.palette.textDim)
        .render(node.region);
    final bar = renderBar(node.cpu / 100, 10, theme.chartA);
    final cpuLabel = '${node.cpu.toStringAsFixed(0).padLeft(3)}%';
    final memLabel = '${node.memory.toStringAsFixed(0).padLeft(3)}%';

    final line1 =
        '$prefix ${Style().foreground(statusColor).render(statusIcon)} '
        '${Style().foreground(theme.palette.textBold).render(name)} '
        '$region  $bar $cpuLabel';

    final line2 =
        '  latency ${node.latency.toStringAsFixed(0).padLeft(3)}ms '
        'mem $memLabel  err ${node.errors.toString().padLeft(2)}';

    final width = model.width;
    return '${truncatePlain(line1, width)}\n${truncatePlain(line2, width)}';
  }

  @override
  tui.Cmd? update(tui.Msg msg, tui.ListModel model) => null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Topology rendering
// ─────────────────────────────────────────────────────────────────────────────

List<String> renderTopology({
  required TopologyLayout layout,
  required int width,
  required int height,
  required int selectedIndex,
  required double phase,
  required DemoThemeData theme,
}) {
  if (width <= 0 || height <= 0) return const [''];
  final grid = List.generate(
    height,
    (_) => List<String>.filled(width, ' ', growable: false),
    growable: false,
  );

  void setCell(int x, int y, String value) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    grid[y][x] = value;
  }

  // Background noise.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final noise = math.sin(x * 0.18 + y * 0.32 + phase);
      if (noise > 0.92) {
        setCell(x, y, Style().foreground(theme.palette.textDim).render(DotChars.middle));
      }
    }
  }

  // Links.
  for (final link in layout.links) {
    final a = layout.nodes[link.from];
    final b = layout.nodes[link.to];
    final x0 = (a.x * (width - 1)).round();
    final y0 = (a.y * (height - 1)).round();
    final x1 = (b.x * (width - 1)).round();
    final y1 = (b.y * (height - 1)).round();
    _plotLine(x0, y0, x1, y1, (x, y) {
      final pulse = math.sin(phase + (x + y) * 0.3);
      final char = pulse > 0.6 ? DotChars.bullet : DotChars.middle;
      final color = pulse > 0.6 ? theme.palette.accent : theme.palette.border;
      setCell(x, y, Style().foreground(color).render(char));
    });
  }

  // Nodes.
  for (var i = 0; i < layout.nodes.length; i++) {
    final node = layout.nodes[i];
    final x = (node.x * (width - 1)).round();
    final y = (node.y * (height - 1)).round();
    final isSelected = i == selectedIndex;
    final glyph = isSelected ? '◆' : Circles.filled;
    final color = isSelected ? theme.palette.accentBold : theme.palette.info;
    setCell(x, y, Style().foreground(color).bold().render(glyph));
  }

  return grid.map((row) => row.join()).toList(growable: false);
}

void _plotLine(int x0, int y0, int x1, int y1, void Function(int, int) plot) {
  var dx = (x1 - x0).abs();
  var dy = -(y1 - y0).abs();
  var sx = x0 < x1 ? 1 : -1;
  var sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;

  while (true) {
    plot(x0, y0);
    if (x0 == x1 && y0 == y1) break;
    final e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x0 += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y0 += sy;
    }
  }
}
