import 'dart:async';
import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart';

const _glyphRamp = ' .,:-~+=*#%@';
const _targetFrameTime = Duration(milliseconds: 33);

const _hudStyle = UvStyle(
  fg: UvColor.rgb(214, 223, 234),
  bg: UvColor.rgb(16, 20, 30),
);
const _helpStyle = UvStyle(
  fg: UvColor.rgb(146, 162, 184),
  bg: UvColor.rgb(16, 20, 30),
);
const _bgColor = UvColor.rgb(6, 8, 12);

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const zero = _Vec3(0, 0, 0);

  _Vec3 operator +(_Vec3 other) => _Vec3(x + other.x, y + other.y, z + other.z);
  _Vec3 operator -(_Vec3 other) => _Vec3(x - other.x, y - other.y, z - other.z);
  _Vec3 scaled(double scalar) => _Vec3(x * scalar, y * scalar, z * scalar);
  _Vec3 operator *(_Vec3 other) => _Vec3(x * other.x, y * other.y, z * other.z);

  double dot(_Vec3 other) => x * other.x + y * other.y + z * other.z;

  _Vec3 cross(_Vec3 other) => _Vec3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double get length => math.sqrt(x * x + y * y + z * z);

  _Vec3 normalized() {
    final len = length;
    if (len < 1e-9) return const _Vec3(0, 1, 0);
    return scaled(1 / len);
  }
}

class _SdfSample {
  const _SdfSample(this.distance, this.materialId);

  final double distance;
  final int materialId;
}

class _MarchHit {
  const _MarchHit({
    required this.hit,
    required this.distance,
    required this.steps,
    required this.materialId,
    required this.position,
    required this.closestDistance,
  });

  final bool hit;
  final double distance;
  final int steps;
  final int materialId;
  final _Vec3 position;
  final double closestDistance;
}

void _writeLine(
  Screen screen,
  int y,
  String text, {
  required UvStyle style,
  required int width,
}) {
  if (y < 0 || width <= 0) return;
  final limit = math.min(width, text.length);
  for (var x = 0; x < limit; x++) {
    screen.setCell(x, y, Cell(content: text[x], style: style));
  }
}

double _clampDouble(double value, double minValue, double maxValue) {
  if (value < minValue) return minValue;
  if (value > maxValue) return maxValue;
  return value;
}

int _toByte(double value) => (_clampDouble(value, 0.0, 1.0) * 255).round();

_Vec3 _mix(_Vec3 a, _Vec3 b, double t) => a.scaled(1 - t) + b.scaled(t);

_Vec3 _rotateY(_Vec3 p, double a) {
  final c = math.cos(a);
  final s = math.sin(a);
  return _Vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

_Vec3 _rotateX(_Vec3 p, double a) {
  final c = math.cos(a);
  final s = math.sin(a);
  return _Vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}

double _sdfSphere(_Vec3 p, double radius) => p.length - radius;

double _sdfRoundBox(_Vec3 p, _Vec3 halfExtents, double radius) {
  final q = _Vec3(
    p.x.abs() - halfExtents.x,
    p.y.abs() - halfExtents.y,
    p.z.abs() - halfExtents.z,
  );
  final outside = _Vec3(
    math.max(q.x, 0),
    math.max(q.y, 0),
    math.max(q.z, 0),
  ).length;
  final inside = math.min(math.max(q.x, math.max(q.y, q.z)), 0.0);
  return outside + inside - radius;
}

double _sdfTorus(_Vec3 p, double majorRadius, double minorRadius) {
  final qx = math.sqrt(p.x * p.x + p.z * p.z) - majorRadius;
  return math.sqrt(qx * qx + p.y * p.y) - minorRadius;
}

_SdfSample _scene(_Vec3 p, double t) {
  final floor = p.y + 1.0;
  var distance = floor;
  var material = 3;

  final orbCenter = _Vec3(
    math.sin(t * 0.9) * 1.35,
    -0.05 + math.sin(t * 1.5) * 0.25,
    math.cos(t * 0.9) * 1.35,
  );
  final orb = _sdfSphere(p - orbCenter, 0.62);
  if (orb < distance) {
    distance = orb;
    material = 1;
  }

  final boxPoint = _rotateY(p - const _Vec3(0.0, -0.08, 0.0), t * 0.7);
  final box = _sdfRoundBox(boxPoint, const _Vec3(0.58, 0.58, 0.58), 0.1);
  if (box < distance) {
    distance = box;
    material = 2;
  }

  final torusPoint = _rotateX(
    _rotateY(p - const _Vec3(0.0, 0.6, 0.0), t * -0.55),
    t * 0.35,
  );
  final torus = _sdfTorus(torusPoint, 1.0, 0.18);
  if (torus < distance) {
    distance = torus;
    material = 4;
  }

  return _SdfSample(distance, material);
}

_Vec3 _estimateNormal(_Vec3 p, double t) {
  const e = 0.0013;
  final dx =
      _scene(_Vec3(p.x + e, p.y, p.z), t).distance -
      _scene(_Vec3(p.x - e, p.y, p.z), t).distance;
  final dy =
      _scene(_Vec3(p.x, p.y + e, p.z), t).distance -
      _scene(_Vec3(p.x, p.y - e, p.z), t).distance;
  final dz =
      _scene(_Vec3(p.x, p.y, p.z + e), t).distance -
      _scene(_Vec3(p.x, p.y, p.z - e), t).distance;
  return _Vec3(dx, dy, dz).normalized();
}

_MarchHit _raymarch(
  _Vec3 rayOrigin,
  _Vec3 rayDirection,
  double t,
  int maxSteps,
  double maxDistance,
) {
  const epsilon = 0.001;
  var totalDistance = 0.0;
  var closestDistance = double.infinity;
  var materialId = 0;

  for (var step = 0; step < maxSteps; step++) {
    final p = rayOrigin + rayDirection.scaled(totalDistance);
    final sample = _scene(p, t);
    final d = sample.distance;

    if (d.abs() < closestDistance) {
      closestDistance = d.abs();
    }

    if (d < epsilon) {
      return _MarchHit(
        hit: true,
        distance: totalDistance,
        steps: step + 1,
        materialId: sample.materialId,
        position: p,
        closestDistance: closestDistance,
      );
    }

    totalDistance += d;
    materialId = sample.materialId;

    if (totalDistance > maxDistance) {
      break;
    }
  }

  return _MarchHit(
    hit: false,
    distance: totalDistance,
    steps: maxSteps,
    materialId: materialId,
    position: rayOrigin + rayDirection.scaled(totalDistance),
    closestDistance: closestDistance,
  );
}

double _softShadow(_Vec3 ro, _Vec3 rd, double t, double maxDistance) {
  var result = 1.0;
  var travel = 0.03;

  for (var i = 0; i < 28 && travel < maxDistance; i++) {
    final h = _scene(ro + rd.scaled(travel), t).distance;
    if (h < 0.0007) return 0.0;
    result = math.min(result, 14.0 * h / travel);
    travel += _clampDouble(h, 0.02, 0.30);
  }

  return _clampDouble(result, 0.0, 1.0);
}

_Vec3 _materialColor(int materialId, _Vec3 p) {
  switch (materialId) {
    case 1:
      return const _Vec3(0.94, 0.42, 0.22);
    case 2:
      return const _Vec3(0.18, 0.74, 0.86);
    case 3:
      final checker = ((p.x.floor() + p.z.floor()) & 1) == 0;
      return checker
          ? const _Vec3(0.43, 0.46, 0.50)
          : const _Vec3(0.19, 0.21, 0.24);
    case 4:
      return const _Vec3(0.88, 0.77, 0.32);
    default:
      return const _Vec3(0.65, 0.67, 0.70);
  }
}

_Vec3 _shade(_Vec3 ro, _Vec3 rd, _MarchHit hit, double t, int maxSteps) {
  final skyTop = const _Vec3(0.30, 0.42, 0.66);
  final skyBottom = const _Vec3(0.06, 0.08, 0.13);
  final skyMix = _clampDouble((rd.y + 1.0) * 0.5, 0, 1);
  final sky = _mix(skyBottom, skyTop, skyMix);

  if (!hit.hit) {
    final missGlow = math.exp(-18 * hit.closestDistance);
    return sky + const _Vec3(0.35, 0.25, 0.12).scaled(missGlow * 0.25);
  }

  final normal = _estimateNormal(hit.position, t);
  final baseColor = _materialColor(hit.materialId, hit.position);

  final lightPos = const _Vec3(2.8, 3.6, 2.4);
  final lightDir = (lightPos - hit.position).normalized();
  final lightDistance = (lightPos - hit.position).length;

  final shadow = _softShadow(
    hit.position + normal.scaled(0.01),
    lightDir,
    t,
    lightDistance,
  );
  final diffuse = math.max(0.0, normal.dot(lightDir)) * shadow;

  final viewDir = rd.scaled(-1);
  final halfDir = (lightDir + viewDir).normalized();
  final specular =
      math.pow(math.max(0.0, normal.dot(halfDir)), 44).toDouble() * shadow;

  final ao = _clampDouble(1.0 - hit.steps / maxSteps, 0.1, 1.0);
  final ambient = 0.12 + 0.25 * ao;

  var lit =
      baseColor.scaled(ambient + diffuse * 1.2) +
      const _Vec3(1.0, 0.97, 0.92).scaled(specular * 0.75);

  final fog = math.exp(-hit.distance * 0.09);
  lit = _mix(sky, lit, fog);

  final normalTint = 0.5 + 0.5 * normal.y;
  return lit.scaled(0.85 + normalTint * 0.15);
}

void main() async {
  final terminal = Terminal();
  await terminal.start();
  terminal.enterAltScreen();
  terminal.hideCursor();
  terminal.setScrollOptim(false);
  terminal.setSynchronizedOutput(true);

  var running = true;
  var paused = false;
  var hardClear = true;
  var asciiMode = true;

  var pixelScale = 2;
  var maxSteps = 84;
  const maxDistance = 28.0;

  var cameraYaw = 0.0;
  var cameraHeight = 0.55;
  const cameraRadius = 4.8;

  var terminalWidth = math.max(24, terminal.bounds().width);
  var terminalHeight = math.max(10, terminal.bounds().height);
  var playHeight = 0;
  var renderWidth = 0;
  var renderHeight = 0;

  var frameMs = 0.0;
  var sceneTime = 0.0;

  var frameBuffer = <_Vec3>[];

  final clock = Stopwatch()..start();
  var previousTick = clock.elapsed;

  void configureViewport(int width, int height) {
    terminalWidth = math.max(24, width);
    terminalHeight = math.max(10, height);
    terminal.resize(terminalWidth, terminalHeight);

    playHeight = math.max(4, terminalHeight - 2);
    renderWidth = math.max(18, terminalWidth ~/ pixelScale);
    renderHeight = math.max(10, playHeight ~/ pixelScale);

    frameBuffer = List<_Vec3>.filled(
      renderWidth * renderHeight,
      _Vec3.zero,
      growable: false,
    );
    hardClear = true;
  }

  void writeHud() {
    final status =
        'UV SDF Raymarcher  steps:$maxSteps  scale:$pixelScale  frame:${frameMs.toStringAsFixed(1)}ms  camY:${cameraHeight.toStringAsFixed(2)}';
    final controls =
        'q/esc/ctrl+c quit  p pause  a/d orbit  w/s camY  +/- quality  j/k steps  m ascii';

    _writeLine(
      terminal,
      playHeight,
      status.padRight(terminalWidth),
      style: _hudStyle,
      width: terminalWidth,
    );
    _writeLine(
      terminal,
      playHeight + 1,
      controls.padRight(terminalWidth),
      style: _helpStyle,
      width: terminalWidth,
    );
  }

  void renderScene() {
    final cameraTarget = const _Vec3(0, 0.1, 0);
    final cameraPosition = _Vec3(
      math.cos(cameraYaw) * cameraRadius,
      cameraHeight,
      math.sin(cameraYaw) * cameraRadius,
    );

    final forward = (cameraTarget - cameraPosition).normalized();
    final worldUp = const _Vec3(0, 1, 0);
    final right = forward.cross(worldUp).normalized();
    final up = right.cross(forward).normalized();

    const fov = math.pi / 2.8;
    final tanHalfFov = math.tan(fov / 2);
    final aspect = renderWidth / renderHeight;

    for (var y = 0; y < renderHeight; y++) {
      for (var x = 0; x < renderWidth; x++) {
        final u = (x + 0.5) / renderWidth;
        final v = (y + 0.5) / renderHeight;
        final px = (2 * u - 1) * tanHalfFov * aspect;
        final py = (1 - 2 * v) * tanHalfFov;
        final rayDir = (forward + right.scaled(px) + up.scaled(py))
            .normalized();

        final hit = _raymarch(
          cameraPosition,
          rayDir,
          sceneTime,
          maxSteps,
          maxDistance,
        );
        frameBuffer[y * renderWidth + x] = _shade(
          cameraPosition,
          rayDir,
          hit,
          sceneTime,
          maxSteps,
        );
      }
    }

    if (hardClear) {
      terminal.clear();
      terminal.clearScreen();
      hardClear = false;
    } else {
      terminal.clear();
    }

    for (var y = 0; y < playHeight; y++) {
      final sy = (y * renderHeight) ~/ playHeight;
      for (var x = 0; x < terminalWidth; x++) {
        final sx = (x * renderWidth) ~/ terminalWidth;
        final color = frameBuffer[sy * renderWidth + sx];

        final luminance = _clampDouble(
          color.x * 0.2126 + color.y * 0.7152 + color.z * 0.0722,
          0,
          1,
        );
        final glyphIndex = (luminance * (_glyphRamp.length - 1)).round().clamp(
          0,
          _glyphRamp.length - 1,
        );
        final glyph = asciiMode ? _glyphRamp[glyphIndex] : '█';

        terminal.setCell(
          x,
          y,
          Cell(
            content: glyph,
            style: UvStyle(
              fg: UvColor.rgb(
                _toByte(color.x),
                _toByte(color.y),
                _toByte(color.z),
              ),
              bg: _bgColor,
            ),
          ),
        );
      }
    }

    writeHud();
    terminal.draw();
  }

  configureViewport(terminalWidth, terminalHeight);

  late final StreamSubscription<Object?> eventSub;
  eventSub = terminal.events.listen((event) {
    if (event is WindowSizeEvent) {
      configureViewport(event.width, event.height);
      return;
    }

    if (event is! KeyEvent) return;

    if (event.matchString('q', 'esc', 'ctrl+c')) {
      running = false;
      return;
    }
    if (event.matchString('p')) {
      paused = !paused;
      return;
    }
    if (event.matchString('a')) {
      cameraYaw -= 0.18;
      return;
    }
    if (event.matchString('d')) {
      cameraYaw += 0.18;
      return;
    }
    if (event.matchString('w')) {
      cameraHeight = _clampDouble(cameraHeight + 0.12, -0.3, 2.4);
      return;
    }
    if (event.matchString('s')) {
      cameraHeight = _clampDouble(cameraHeight - 0.12, -0.3, 2.4);
      return;
    }
    if (event.matchString('+', '=')) {
      pixelScale = math.max(1, pixelScale - 1);
      configureViewport(terminalWidth, terminalHeight);
      return;
    }
    if (event.matchString('-')) {
      pixelScale = math.min(5, pixelScale + 1);
      configureViewport(terminalWidth, terminalHeight);
      return;
    }
    if (event.matchString('j')) {
      maxSteps = math.max(24, maxSteps - 8);
      return;
    }
    if (event.matchString('k')) {
      maxSteps = math.min(168, maxSteps + 8);
      return;
    }
    if (event.matchString('m')) {
      asciiMode = !asciiMode;
      return;
    }
  });

  try {
    while (running) {
      final now = clock.elapsed;
      final delta = now - previousTick;
      previousTick = now;

      if (!paused) {
        sceneTime += delta.inMicroseconds / 1e6;
      }

      final frameStart = clock.elapsed;

      final liveBounds = terminal.bounds();
      if (liveBounds.width != terminalWidth ||
          liveBounds.height != terminalHeight) {
        configureViewport(liveBounds.width, liveBounds.height);
      }

      renderScene();

      final frameElapsed = clock.elapsed - frameStart;
      frameMs = frameElapsed.inMicroseconds / 1000.0;
      final sleepFor = _targetFrameTime - frameElapsed;
      if (sleepFor > Duration.zero) {
        await Future.delayed(sleepFor);
      }
    }
  } finally {
    await eventSub.cancel();
    await terminal.stop();
  }
}
