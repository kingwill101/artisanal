/// Cellbuffer ellipse animation (mouse spring) ported from Bubble Tea.
library;

import 'dart:math' as math;

import 'package:artisanal/tui.dart' as tui;

const _fps = 60;
const _frequency = 7.5;
const _damping = 0.15;
const _char = '*';

class FrameMsg extends tui.Msg {
  const FrameMsg();
}

tui.Cmd _animate() => tui.Cmd.tick(
  const Duration(milliseconds: 1000 ~/ _fps),
  (_) => const FrameMsg(),
);

class Spring {
  Spring({required this.frequency, required this.damping});

  final double frequency;
  final double damping;

  (double, double) update(double current, double velocity, double target) {
    final dt = 1.0 / _fps;
    final omega = frequency * 2 * math.pi;
    final displacement = current - target;
    final springForce = -omega * omega * displacement;
    final dampingForce = -2 * damping * omega * velocity;
    final accel = springForce + dampingForce;
    final newVel = velocity + accel * dt;
    final newVal = current + newVel * dt;
    return (newVal, newVel);
  }
}

class CellBuffer {
  List<String> cells = [];
  int stride = 0;

  void init(int w, int h) {
    if (w <= 0 || h <= 0) return;
    stride = w;
    cells = List.filled(w * h, ' ');
  }

  bool get ready => cells.isNotEmpty;
  int get width => stride;
  int get height => stride == 0 ? 0 : (cells.length / stride).ceil();

  void set(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final i = y * stride + x;
    if (i < 0 || i >= cells.length) return;
    cells[i] = _char;
  }

  void wipe() {
    for (var i = 0; i < cells.length; i++) {
      cells[i] = ' ';
    }
  }

  @override
  String toString() {
    final b = StringBuffer();
    for (var i = 0; i < cells.length; i++) {
      if (i > 0 && i % stride == 0 && i < cells.length) b.writeln();
      b.write(cells[i]);
    }
    return b.toString();
  }
}

void _drawEllipse(CellBuffer cb, double xc, double yc, double rx, double ry) {
  var dx = 0.0, dy = 0.0;
  var x = 0.0;
  var y = ry;
  var d1 = ry * ry - rx * rx * ry + 0.25 * rx * rx;
  dx = 2 * ry * ry * x;
  dy = 2 * rx * rx * y;

  while (dx < dy) {
    cb.set((x + xc).toInt(), (y + yc).toInt());
    cb.set((-x + xc).toInt(), (y + yc).toInt());
    cb.set((x + xc).toInt(), (-y + yc).toInt());
    cb.set((-x + xc).toInt(), (-y + yc).toInt());
    if (d1 < 0) {
      x++;
      dx = dx + (2 * ry * ry);
      d1 = d1 + dx + (ry * ry);
    } else {
      x++;
      y--;
      dx = dx + (2 * ry * ry);
      dy = dy - (2 * rx * rx);
      d1 = d1 + dx - dy + (ry * ry);
    }
  }

  var d2 =
      (ry * ry) * ((x + 0.5) * (x + 0.5)) +
      (rx * rx) * ((y - 1) * (y - 1)) -
      (rx * rx * ry * ry);

  while (y >= 0) {
    cb.set((x + xc).toInt(), (y + yc).toInt());
    cb.set((-x + xc).toInt(), (y + yc).toInt());
    cb.set((x + xc).toInt(), (-y + yc).toInt());
    cb.set((-x + xc).toInt(), (-y + yc).toInt());
    if (d2 > 0) {
      y--;
      dy = dy - (2 * rx * rx);
      d2 = d2 + (rx * rx) - dy;
    } else {
      y--;
      x++;
      dx = dx + (2 * ry * ry);
      dy = dy - (2 * rx * rx);
      d2 = d2 + dx - dy + (rx * rx);
    }
  }
}

class CellbufferModel implements tui.Model {
  CellbufferModel({
    CellBuffer? cells,
    Spring? spring,
    double? targetX,
    double? targetY,
    double? x,
    double? y,
    this.xVelocity = 0,
    this.yVelocity = 0,
  }) : cells = cells ?? CellBuffer(),
       spring = spring ?? Spring(frequency: _frequency, damping: _damping),
       targetX = targetX ?? 0,
       targetY = targetY ?? 0,
       x = x ?? 0,
       y = y ?? 0;

  final CellBuffer cells;
  final Spring spring;
  final double targetX;
  final double targetY;
  final double x;
  final double y;
  final double xVelocity;
  final double yVelocity;

  CellbufferModel copyWith({
    CellBuffer? cells,
    Spring? spring,
    double? targetX,
    double? targetY,
    double? x,
    double? y,
    double? xVelocity,
    double? yVelocity,
  }) {
    return CellbufferModel(
      cells: cells ?? this.cells,
      spring: spring ?? this.spring,
      targetX: targetX ?? this.targetX,
      targetY: targetY ?? this.targetY,
      x: x ?? this.x,
      y: y ?? this.y,
      xVelocity: xVelocity ?? this.xVelocity,
      yVelocity: yVelocity ?? this.yVelocity,
    );
  }

  @override
  tui.Cmd? init() => _animate();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (this, tui.Cmd.quit());

      case tui.WindowSizeMsg(:final width, :final height):
        final ready = cells.ready;
        cells.init(width, height);
        if (!ready) {
          return (
            copyWith(
              targetX: width / 2,
              targetY: height / 2,
              x: width / 2,
              y: height / 2,
            ),
            null,
          );
        }
        return (this, null);

      case tui.MouseMsg(:final x, :final y):
        if (!cells.ready) return (this, null);
        return (copyWith(targetX: x.toDouble(), targetY: y.toDouble()), null);

      case FrameMsg():
        if (!cells.ready) return (this, null);

        cells.wipe();
        final (nx, nvx) = spring.update(x, xVelocity, targetX);
        final (ny, nvy) = spring.update(y, yVelocity, targetY);
        _drawEllipse(cells, nx, ny, 16, 8);
        return (
          copyWith(x: nx, y: ny, xVelocity: nvx, yVelocity: nvy),
          _animate(),
        );
    }
    return (this, null);
  }

  @override
  String view() => cells.toString();
}

Future<void> main() async {
  await tui.runProgram(
    CellbufferModel(),
    options: const tui.ProgramOptions(
      altScreen: true,
      hideCursor: true,
      mouse: true,
    ),
  );
}
