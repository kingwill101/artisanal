import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

const _nodeStyle = UvStyle(
  fg: UvColor.rgb(236, 242, 250),
  bg: UvColor.rgb(26, 36, 50),
  attrs: Attr.bold,
);
const _nodeWarnStyle = UvStyle(
  fg: UvColor.rgb(255, 220, 148),
  bg: UvColor.rgb(56, 36, 18),
  attrs: Attr.bold,
);
const _linkUpStyle = UvStyle(
  fg: UvColor.rgb(104, 212, 148),
  bg: UvColor.rgb(8, 18, 18),
);
const _linkDownStyle = UvStyle(
  fg: UvColor.rgb(212, 92, 92),
  bg: UvColor.rgb(30, 10, 10),
);
const _hudStyle = UvStyle(
  fg: UvColor.rgb(219, 230, 240),
  bg: UvColor.rgb(18, 24, 32),
);
const _helpStyle = UvStyle(
  fg: UvColor.rgb(152, 170, 188),
  bg: UvColor.rgb(12, 18, 24),
);

class _Node {
  const _Node(this.label, this.nx, this.ny);
  final String label;
  final double nx;
  final double ny;
}

class _Link {
  _Link({required this.a, required this.b, required this.latencySeconds});

  final int a;
  final int b;
  final double latencySeconds;

  bool up = true;
  double recoveryInSeconds = 0.0;
}

class _Packet {
  _Packet({required this.path, required this.colorSeed});

  final List<int> path;
  final int colorSeed;
  int hop = 0;
  double progress = 0.0;
}

void _writeLine(
  Screen screen,
  int x,
  int y,
  String text, {
  required int maxWidth,
  required UvStyle style,
}) {
  final limit = math.min(text.length, math.max(0, maxWidth));
  for (var i = 0; i < limit; i++) {
    screen.setCell(x + i, y, Cell(content: text[i], style: style));
  }
}

String _edgeKey(int a, int b) => a < b ? '$a-$b' : '$b-$a';

List<int>? _findRoute(int source, int target, List<_Link> links) {
  if (source == target) return <int>[source];

  final adjacency = <int, List<int>>{};
  for (final link in links) {
    if (!link.up) continue;
    (adjacency[link.a] ??= <int>[]).add(link.b);
    (adjacency[link.b] ??= <int>[]).add(link.a);
  }

  final prev = <int, int>{};
  final visited = <int>{source};
  final queue = ListQueue<int>()..add(source);

  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
    if (cur == target) break;
    for (final next in adjacency[cur] ?? const <int>[]) {
      if (!visited.add(next)) continue;
      prev[next] = cur;
      queue.add(next);
    }
  }

  if (!visited.contains(target)) return null;
  final path = <int>[target];
  var cursor = target;
  while (cursor != source) {
    final p = prev[cursor];
    if (p == null) return null;
    path.add(p);
    cursor = p;
  }
  return path.reversed.toList();
}

void _drawLine(
  Terminal terminal,
  int x0,
  int y0,
  int x1,
  int y1, {
  required Cell cell,
}) {
  var x = x0;
  var y = y0;
  final dx = (x1 - x0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final dy = -(y1 - y0).abs();
  final sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;

  while (true) {
    terminal.setCell(x, y, cell);
    if (x == x1 && y == y1) break;
    final e2 = err * 2;
    if (e2 >= dy) {
      err += dy;
      x += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y += sy;
    }
  }
}

({int x, int y}) _nodePosition(
  _Node node, {
  required int width,
  required int height,
}) {
  final xSpan = math.max(1, width - 1);
  final ySpan = math.max(1, height - 1);
  final x = (node.nx * xSpan).round().clamp(0, math.max(0, width - 1)).toInt();
  final y = (node.ny * ySpan).round().clamp(0, math.max(0, height - 1)).toInt();
  return (x: x, y: y);
}

void main() async {
  final terminal = Terminal();
  Timer? ticker;

  var started = false;
  var inAltScreen = false;
  var cursorHidden = false;

  final random = math.Random();
  final nodes = <_Node>[
    const _Node('A', 0.08, 0.18),
    const _Node('B', 0.34, 0.10),
    const _Node('C', 0.64, 0.14),
    const _Node('D', 0.90, 0.30),
    const _Node('E', 0.82, 0.72),
    const _Node('F', 0.56, 0.88),
    const _Node('G', 0.26, 0.78),
    const _Node('H', 0.10, 0.46),
  ];

  final links = <_Link>[
    _Link(a: 0, b: 1, latencySeconds: 0.42),
    _Link(a: 1, b: 2, latencySeconds: 0.46),
    _Link(a: 2, b: 3, latencySeconds: 0.52),
    _Link(a: 3, b: 4, latencySeconds: 0.56),
    _Link(a: 4, b: 5, latencySeconds: 0.50),
    _Link(a: 5, b: 6, latencySeconds: 0.44),
    _Link(a: 6, b: 7, latencySeconds: 0.40),
    _Link(a: 7, b: 0, latencySeconds: 0.45),
    _Link(a: 1, b: 7, latencySeconds: 0.36),
    _Link(a: 1, b: 6, latencySeconds: 0.48),
    _Link(a: 2, b: 5, latencySeconds: 0.62),
    _Link(a: 2, b: 4, latencySeconds: 0.58),
    _Link(a: 0, b: 2, latencySeconds: 0.66),
  ];

  final linkLookup = <String, _Link>{
    for (final link in links) _edgeKey(link.a, link.b): link,
  };

  final packets = <_Packet>[];

  var startedAt = DateTime.now();
  var paused = false;
  var autoFailure = true;
  var hardClear = true;
  var packetRate = 3.8;
  var spawnBudget = 0.0;
  var delivered = 0;
  var dropped = 0;
  var outages = 0;
  var smoothedFps = 0.0;

  final clock = Stopwatch()..start();
  var lastElapsed = clock.elapsed;

  void failLink(_Link link, {required double downFor}) {
    if (!link.up) return;
    link.up = false;
    link.recoveryInSeconds = downFor;
    outages++;
  }

  void recoverAllLinks() {
    for (final link in links) {
      link.up = true;
      link.recoveryInSeconds = 0;
    }
  }

  void spawnPacket({bool burst = false}) {
    final source = random.nextInt(nodes.length);
    var target = random.nextInt(nodes.length);
    if (target == source) {
      target = (target + 1 + random.nextInt(nodes.length - 1)) % nodes.length;
    }
    final route = _findRoute(source, target, links);
    if (route == null || route.length < 2) {
      dropped++;
      return;
    }
    packets.add(_Packet(path: route, colorSeed: burst ? 1 : source));
  }

  void updateSimulation(double dt) {
    if (paused) return;

    for (final link in links) {
      if (!link.up) {
        link.recoveryInSeconds -= dt;
        if (link.recoveryInSeconds <= 0) {
          link.up = true;
          link.recoveryInSeconds = 0;
        }
      } else if (autoFailure && random.nextDouble() < 0.08 * dt) {
        failLink(link, downFor: 1.4 + random.nextDouble() * 4.2);
      }
    }

    spawnBudget += packetRate * dt;
    while (spawnBudget >= 1.0) {
      spawnBudget -= 1.0;
      spawnPacket();
    }

    final survivors = <_Packet>[];
    for (final packet in packets) {
      if (packet.hop >= packet.path.length - 1) {
        delivered++;
        continue;
      }
      final from = packet.path[packet.hop];
      final to = packet.path[packet.hop + 1];
      final link = linkLookup[_edgeKey(from, to)];
      if (link == null || !link.up) {
        dropped++;
        continue;
      }

      final jitter = 0.85 + random.nextDouble() * 0.35;
      packet.progress += (dt / link.latencySeconds) * jitter;

      while (packet.progress >= 1.0) {
        packet.progress -= 1.0;
        packet.hop++;
        if (packet.hop >= packet.path.length - 1) {
          delivered++;
          break;
        }

        final nextFrom = packet.path[packet.hop];
        final nextTo = packet.path[packet.hop + 1];
        final nextLink = linkLookup[_edgeKey(nextFrom, nextTo)];
        if (nextLink == null || !nextLink.up) {
          dropped++;
          packet.hop = packet.path.length;
          break;
        }
      }

      if (packet.hop < packet.path.length - 1) {
        survivors.add(packet);
      }
    }
    packets
      ..clear()
      ..addAll(survivors);
  }

  void renderFrame() {
    final bounds = terminal.bounds();
    final width = bounds.width;
    final height = bounds.height;

    if (hardClear) {
      terminal.clear();
      terminal.clearScreen();
      hardClear = false;
    } else {
      terminal.clear();
    }

    if (width <= 0 || height <= 0) {
      terminal.draw();
      return;
    }

    final plotHeight = math.max(1, height - 3);
    final nodePositions = <int, ({int x, int y})>{};
    for (var i = 0; i < nodes.length; i++) {
      nodePositions[i] = _nodePosition(
        nodes[i],
        width: width,
        height: plotHeight,
      );
    }

    for (final link in links) {
      final a = nodePositions[link.a]!;
      final b = nodePositions[link.b]!;
      final isDiagonal = (a.x - b.x).abs() > 1 && (a.y - b.y).abs() > 1;
      final glyph = link.up ? (isDiagonal ? '·' : '─') : 'x';
      final style = link.up ? _linkUpStyle : _linkDownStyle;
      _drawLine(
        terminal,
        a.x,
        a.y,
        b.x,
        b.y,
        cell: Cell(content: glyph, style: style),
      );
    }

    for (final packet in packets) {
      if (packet.hop >= packet.path.length - 1) continue;
      final from = nodePositions[packet.path[packet.hop]]!;
      final to = nodePositions[packet.path[packet.hop + 1]]!;
      final px = (from.x + (to.x - from.x) * packet.progress).round();
      final py = (from.y + (to.y - from.y) * packet.progress).round();
      if (px < 0 || py < 0 || px >= width || py >= plotHeight) continue;

      final hueShift = packet.colorSeed % 3;
      final packetColor = switch (hueShift) {
        0 => const UvStyle(
          fg: UvColor.rgb(120, 230, 255),
          bg: UvColor.rgb(6, 18, 22),
          attrs: Attr.bold,
        ),
        1 => const UvStyle(
          fg: UvColor.rgb(184, 255, 154),
          bg: UvColor.rgb(10, 22, 12),
          attrs: Attr.bold,
        ),
        _ => const UvStyle(
          fg: UvColor.rgb(255, 214, 120),
          bg: UvColor.rgb(24, 16, 10),
          attrs: Attr.bold,
        ),
      };

      terminal.setCell(px, py, Cell(content: '•', style: packetColor));
    }

    for (var i = 0; i < nodes.length; i++) {
      final pos = nodePositions[i]!;
      final incidentDown = links.any(
        (link) => (link.a == i || link.b == i) && !link.up,
      );
      terminal.setCell(
        pos.x,
        pos.y,
        Cell(
          content: nodes[i].label,
          style: incidentDown ? _nodeWarnStyle : _nodeStyle,
        ),
      );
    }

    final downLinks = links.where((l) => !l.up).length;
    final uptime = links.isEmpty
        ? 100.0
        : ((links.length - downLinks) / links.length) * 100;
    final uptimeText = uptime.toStringAsFixed(1);
    final hud =
        'network-topology  packets:${packets.length}  delivered:$delivered  dropped:$dropped  link-up:$uptimeText%  fps:${smoothedFps.toStringAsFixed(1)}';
    final help =
        'p pause  a auto-fail:${autoFailure ? "on" : "off"}  f fail-one  r recover  j/k traffic:${packetRate.toStringAsFixed(1)}/s  b burst  q esc ctrl+c quit';
    final ageSeconds =
        DateTime.now().difference(startedAt).inMilliseconds / 1000.0;
    final footer =
        'outages:$outages  elapsed:${ageSeconds.toStringAsFixed(1)}s  latency model: per-link transit delay + jitter';

    if (height >= 3) {
      terminal.fillArea(
        Cell(content: ' ', style: _hudStyle),
        rect(0, height - 3, width, 1),
      );
      _writeLine(
        terminal,
        0,
        height - 3,
        hud,
        maxWidth: width,
        style: _hudStyle,
      );
    }
    if (height >= 2) {
      terminal.fillArea(
        Cell(content: ' ', style: _helpStyle),
        rect(0, height - 2, width, 1),
      );
      _writeLine(
        terminal,
        0,
        height - 2,
        help,
        maxWidth: width,
        style: _helpStyle,
      );
    }
    if (height >= 1) {
      terminal.fillArea(
        Cell(content: ' ', style: _helpStyle),
        rect(0, height - 1, width, 1),
      );
      _writeLine(
        terminal,
        0,
        height - 1,
        footer,
        maxWidth: width,
        style: _helpStyle,
      );
    }

    terminal.draw();
  }

  try {
    await terminal.start();
    started = true;
    terminal.enterAltScreen();
    inAltScreen = true;
    terminal.hideCursor();
    cursorHidden = true;
    terminal.setScrollOptim(false);
    terminal.setSynchronizedOutput(true);

    ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final now = clock.elapsed;
      final dt = (now - lastElapsed).inMicroseconds / 1000000.0;
      lastElapsed = now;

      if (dt > 0) {
        final fps = 1.0 / dt;
        smoothedFps = smoothedFps == 0 ? fps : smoothedFps * 0.9 + fps * 0.1;
      }

      updateSimulation(dt.clamp(0.0, 0.2));
      renderFrame();
    });

    renderFrame();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
        hardClear = true;
        renderFrame();
        continue;
      }
      if (event is! KeyEvent) continue;

      if (event.matchString('q', 'esc', 'ctrl+c')) {
        break;
      } else if (event.matchString('p', ' ')) {
        paused = !paused;
      } else if (event.matchString('a')) {
        autoFailure = !autoFailure;
      } else if (event.matchString('f')) {
        final upLinks = links.where((l) => l.up).toList();
        if (upLinks.isNotEmpty) {
          failLink(
            upLinks[random.nextInt(upLinks.length)],
            downFor: 1.2 + random.nextDouble() * 4.5,
          );
        }
      } else if (event.matchString('r')) {
        recoverAllLinks();
      } else if (event.matchString('j')) {
        packetRate = (packetRate * 0.84).clamp(0.4, 24.0);
      } else if (event.matchString('k')) {
        packetRate = (packetRate * 1.2).clamp(0.4, 24.0);
      } else if (event.matchString('b')) {
        for (var i = 0; i < 5; i++) {
          spawnPacket(burst: true);
        }
      } else if (event.matchString('c')) {
        packets.clear();
        hardClear = true;
      }
      renderFrame();
    }
  } finally {
    ticker?.cancel();
    if (cursorHidden) {
      terminal.showCursor();
    }
    if (inAltScreen) {
      terminal.exitAltScreen();
    }
    if (started) {
      await terminal.stop();
    }
  }
}
