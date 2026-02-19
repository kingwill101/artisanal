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
const _bgStyle = UvStyle(bg: UvColor.rgb(8, 10, 14));

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const zero = _Vec3(0, 0, 0);
  static const one = _Vec3(1, 1, 1);

  _Vec3 operator +(_Vec3 other) => _Vec3(x + other.x, y + other.y, z + other.z);
  _Vec3 operator -(_Vec3 other) => _Vec3(x - other.x, y - other.y, z - other.z);
  _Vec3 operator *(_Vec3 other) => _Vec3(x * other.x, y * other.y, z * other.z);
  _Vec3 scaled(double scalar) => _Vec3(x * scalar, y * scalar, z * scalar);
  _Vec3 operator /(double scalar) => _Vec3(x / scalar, y / scalar, z / scalar);

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
    return this / len;
  }

  double get maxComponent => math.max(x, math.max(y, z));
}

class _Material {
  const _Material({
    required this.albedo,
    this.emission = _Vec3.zero,
    this.metalness = 0.0,
    this.roughness = 0.6,
  });

  final _Vec3 albedo;
  final _Vec3 emission;
  final double metalness;
  final double roughness;

  bool get isEmissive => emission.maxComponent > 0.0;
}

class _Sphere {
  const _Sphere({
    required this.center,
    required this.radius,
    required this.material,
  });

  final _Vec3 center;
  final double radius;
  final _Material material;
}

class _Ray {
  const _Ray(this.origin, this.direction);

  final _Vec3 origin;
  final _Vec3 direction;
}

class _Hit {
  const _Hit({
    required this.distance,
    required this.position,
    required this.normal,
    required this.material,
  });

  final double distance;
  final _Vec3 position;
  final _Vec3 normal;
  final _Material material;
}

const _floorLight = _Material(albedo: _Vec3(0.74, 0.74, 0.78));
const _floorDark = _Material(albedo: _Vec3(0.22, 0.26, 0.30));

final _sceneSpheres = <_Sphere>[
  const _Sphere(
    center: _Vec3(-1.2, 0.45, 0.0),
    radius: 0.45,
    material: _Material(
      albedo: _Vec3(0.92, 0.30, 0.24),
      metalness: 0.1,
      roughness: 0.8,
    ),
  ),
  const _Sphere(
    center: _Vec3(0.0, 0.6, -0.7),
    radius: 0.6,
    material: _Material(
      albedo: _Vec3(0.93, 0.94, 0.96),
      metalness: 0.92,
      roughness: 0.12,
    ),
  ),
  const _Sphere(
    center: _Vec3(1.1, 0.4, 0.4),
    radius: 0.4,
    material: _Material(
      albedo: _Vec3(0.22, 0.70, 0.95),
      metalness: 0.05,
      roughness: 0.55,
    ),
  ),
  const _Sphere(
    center: _Vec3(0.0, 3.7, 0.0),
    radius: 1.05,
    material: _Material(albedo: _Vec3.zero, emission: _Vec3(10.5, 9.9, 8.9)),
  ),
];

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

int _toByte(double linear) => (_clampDouble(linear, 0.0, 1.0) * 255).round();

_Vec3 _mix(_Vec3 a, _Vec3 b, double t) => a.scaled(1 - t) + b.scaled(t);

_Vec3 _reflect(_Vec3 v, _Vec3 n) => v - n.scaled(2 * v.dot(n));

_Vec3 _randomInUnitSphere(math.Random rng) {
  while (true) {
    final p = _Vec3(
      rng.nextDouble() * 2 - 1,
      rng.nextDouble() * 2 - 1,
      rng.nextDouble() * 2 - 1,
    );
    if (p.dot(p) <= 1.0) return p;
  }
}

_Vec3 _randomCosineHemisphere(math.Random rng, _Vec3 normal) {
  final r1 = rng.nextDouble();
  final r2 = rng.nextDouble();
  final phi = 2 * math.pi * r1;
  final x = math.cos(phi) * math.sqrt(r2);
  final y = math.sin(phi) * math.sqrt(r2);
  final z = math.sqrt(1 - r2);

  final helper = normal.x.abs() > 0.2
      ? const _Vec3(0, 1, 0)
      : const _Vec3(1, 0, 0);
  final tangent = normal.cross(helper).normalized();
  final bitangent = tangent.cross(normal).normalized();

  return (tangent.scaled(x) + bitangent.scaled(y) + normal.scaled(z))
      .normalized();
}

_Vec3 _sky(_Vec3 direction) {
  final t = _clampDouble((direction.y + 1.0) * 0.5, 0, 1);
  final horizon = const _Vec3(0.06, 0.07, 0.11);
  final zenith = const _Vec3(0.30, 0.42, 0.74);
  return _mix(horizon, zenith, t).scaled(0.65);
}

_Hit? _intersectScene(_Ray ray) {
  const minDistance = 0.0008;
  var nearest = double.infinity;
  _Hit? closest;

  if (ray.direction.y.abs() > 1e-5) {
    final planeT = -ray.origin.y / ray.direction.y;
    if (planeT > minDistance && planeT < nearest) {
      final p = ray.origin + ray.direction.scaled(planeT);
      final checker = ((p.x.floor() + p.z.floor()) & 1) == 0;
      final material = checker ? _floorLight : _floorDark;
      nearest = planeT;
      closest = _Hit(
        distance: planeT,
        position: p,
        normal: const _Vec3(0, 1, 0),
        material: material,
      );
    }
  }

  for (final sphere in _sceneSpheres) {
    final oc = ray.origin - sphere.center;
    final a = ray.direction.dot(ray.direction);
    final b = 2.0 * oc.dot(ray.direction);
    final c = oc.dot(oc) - sphere.radius * sphere.radius;
    final discriminant = b * b - 4 * a * c;
    if (discriminant <= 0) continue;

    final sqrtDisc = math.sqrt(discriminant);
    final nearRoot = (-b - sqrtDisc) / (2 * a);
    final farRoot = (-b + sqrtDisc) / (2 * a);

    var root = nearRoot;
    if (root <= minDistance) root = farRoot;
    if (root <= minDistance || root >= nearest) continue;

    final pos = ray.origin + ray.direction.scaled(root);
    final normal = (pos - sphere.center).normalized();
    nearest = root;
    closest = _Hit(
      distance: root,
      position: pos,
      normal: normal,
      material: sphere.material,
    );
  }

  return closest;
}

_Vec3 _tracePath(_Ray primaryRay, int maxBounces, math.Random rng) {
  var ray = primaryRay;
  var throughput = _Vec3.one;
  var radiance = _Vec3.zero;

  for (var bounce = 0; bounce < maxBounces; bounce++) {
    final hit = _intersectScene(ray);
    if (hit == null) {
      radiance = radiance + throughput * _sky(ray.direction);
      break;
    }

    radiance = radiance + throughput * hit.material.emission;
    if (hit.material.isEmissive) break;

    final diffuse = _randomCosineHemisphere(rng, hit.normal);
    final reflected =
        (_reflect(ray.direction, hit.normal) +
                _randomInUnitSphere(rng).scaled(hit.material.roughness))
            .normalized();
    final nextDir = _mix(
      diffuse,
      reflected,
      hit.material.metalness,
    ).normalized();

    final cosine = math.max(0.0, nextDir.dot(hit.normal));
    throughput = throughput * hit.material.albedo;
    throughput = throughput.scaled(0.35 + 0.65 * cosine);

    if (bounce >= 2) {
      final survival = _clampDouble(throughput.maxComponent, 0.10, 0.95);
      if (rng.nextDouble() > survival) break;
      throughput = throughput / survival;
    }

    if (throughput.maxComponent < 0.001) break;
    ray = _Ray(hit.position + hit.normal.scaled(0.0012), nextDir);
  }

  return radiance;
}

_Vec3 _toneMap(_Vec3 color) {
  final reinhard = _Vec3(
    color.x / (1 + color.x),
    color.y / (1 + color.y),
    color.z / (1 + color.z),
  );
  return _Vec3(
    math.pow(reinhard.x, 1 / 2.2).toDouble(),
    math.pow(reinhard.y, 1 / 2.2).toDouble(),
    math.pow(reinhard.z, 1 / 2.2).toDouble(),
  );
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
  var colorEnabled = true;

  var samplesPerFrame = 1;
  var maxBounces = 5;
  var pixelScale = 2;

  var terminalWidth = math.max(24, terminal.bounds().width);
  var terminalHeight = math.max(10, terminal.bounds().height);
  var playHeight = 0;
  var renderWidth = 0;
  var renderHeight = 0;

  var samplesAccumulated = 0;
  var frameMs = 0.0;

  var accumR = <double>[];
  var accumG = <double>[];
  var accumB = <double>[];

  final rng = math.Random();
  final frameClock = Stopwatch()..start();

  void resetAccumulation() {
    final pixelCount = renderWidth * renderHeight;
    accumR = List<double>.filled(pixelCount, 0.0, growable: false);
    accumG = List<double>.filled(pixelCount, 0.0, growable: false);
    accumB = List<double>.filled(pixelCount, 0.0, growable: false);
    samplesAccumulated = 0;
  }

  void configureViewport(int width, int height) {
    terminalWidth = math.max(24, width);
    terminalHeight = math.max(10, height);
    terminal.resize(terminalWidth, terminalHeight);

    playHeight = math.max(4, terminalHeight - 2);
    renderWidth = math.max(16, terminalWidth ~/ pixelScale);
    renderHeight = math.max(10, playHeight ~/ pixelScale);

    resetAccumulation();
    hardClear = true;
  }

  void writeHud() {
    final hudLine =
        'UV Path Tracer  samples:$samplesAccumulated  spp/frame:$samplesPerFrame  bounces:$maxBounces  frame:${frameMs.toStringAsFixed(1)}ms';
    final controls =
        'q/esc/ctrl+c quit  r reset  p pause  +/- spp  [ ] bounces  1/2/3 quality  c color';

    _writeLine(
      terminal,
      playHeight,
      hudLine.padRight(terminalWidth),
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

  void accumulate() {
    if (renderWidth <= 0 || renderHeight <= 0) return;

    const cameraPos = _Vec3(0.0, 1.2, 4.0);
    const cameraTarget = _Vec3(0.0, 0.8, 0.0);
    const worldUp = _Vec3(0.0, 1.0, 0.0);
    const fov = math.pi / 3;

    final forward = (cameraTarget - cameraPos).normalized();
    final right = forward.cross(worldUp).normalized();
    final up = right.cross(forward).normalized();
    final tanHalfFov = math.tan(fov * 0.5);
    final aspect = renderWidth / renderHeight;

    for (var y = 0; y < renderHeight; y++) {
      for (var x = 0; x < renderWidth; x++) {
        final index = y * renderWidth + x;
        var sampleColor = _Vec3.zero;
        for (var s = 0; s < samplesPerFrame; s++) {
          final u = (x + rng.nextDouble()) / renderWidth;
          final v = (y + rng.nextDouble()) / renderHeight;
          final px = (2 * u - 1) * tanHalfFov * aspect;
          final py = (1 - 2 * v) * tanHalfFov;
          final direction = (forward + right.scaled(px) + up.scaled(py))
              .normalized();
          sampleColor =
              sampleColor +
              _tracePath(_Ray(cameraPos, direction), maxBounces, rng);
        }
        sampleColor = sampleColor / samplesPerFrame.toDouble();
        accumR[index] += sampleColor.x;
        accumG[index] += sampleColor.y;
        accumB[index] += sampleColor.z;
      }
    }

    samplesAccumulated++;
  }

  void render() {
    if (hardClear) {
      terminal.clear();
      terminal.clearScreen();
      hardClear = false;
    } else {
      terminal.clear();
    }

    if (samplesAccumulated <= 0 || playHeight <= 0 || terminalWidth <= 0) {
      terminal.fillArea(
        Cell(content: ' ', style: _bgStyle),
        rect(0, 0, terminalWidth, math.max(0, playHeight)),
      );
      writeHud();
      terminal.draw();
      return;
    }

    for (var y = 0; y < playHeight; y++) {
      final sy = (y * renderHeight) ~/ playHeight;
      for (var x = 0; x < terminalWidth; x++) {
        final sx = (x * renderWidth) ~/ terminalWidth;
        final index = sy * renderWidth + sx;

        var color = _Vec3(
          accumR[index] / samplesAccumulated,
          accumG[index] / samplesAccumulated,
          accumB[index] / samplesAccumulated,
        );
        color = _toneMap(color);

        final luminance = _clampDouble(
          color.x * 0.2126 + color.y * 0.7152 + color.z * 0.0722,
          0.0,
          1.0,
        );
        final glyphIndex = (luminance * (_glyphRamp.length - 1)).round().clamp(
          0,
          _glyphRamp.length - 1,
        );
        final glyph = _glyphRamp[glyphIndex];

        final displayColor = colorEnabled
            ? color
            : _Vec3(luminance, luminance, luminance);

        terminal.setCell(
          x,
          y,
          Cell(
            content: glyph,
            style: UvStyle(
              fg: UvColor.rgb(
                _toByte(displayColor.x),
                _toByte(displayColor.y),
                _toByte(displayColor.z),
              ),
              bg: const UvColor.rgb(6, 8, 12),
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
    if (event.matchString('r')) {
      resetAccumulation();
      return;
    }
    if (event.matchString('p')) {
      paused = !paused;
      return;
    }
    if (event.matchString('+', '=')) {
      samplesPerFrame = math.min(8, samplesPerFrame + 1);
      return;
    }
    if (event.matchString('-')) {
      samplesPerFrame = math.max(1, samplesPerFrame - 1);
      return;
    }
    if (event.matchString('[')) {
      maxBounces = math.max(1, maxBounces - 1);
      resetAccumulation();
      return;
    }
    if (event.matchString(']')) {
      maxBounces = math.min(12, maxBounces + 1);
      resetAccumulation();
      return;
    }
    if (event.matchString('1')) {
      pixelScale = 4;
      configureViewport(terminalWidth, terminalHeight);
      return;
    }
    if (event.matchString('2')) {
      pixelScale = 2;
      configureViewport(terminalWidth, terminalHeight);
      return;
    }
    if (event.matchString('3')) {
      pixelScale = 1;
      configureViewport(terminalWidth, terminalHeight);
      return;
    }
    if (event.matchString('c')) {
      colorEnabled = !colorEnabled;
      return;
    }
  });

  try {
    while (running) {
      final loopStart = frameClock.elapsed;

      final liveBounds = terminal.bounds();
      if (liveBounds.width != terminalWidth ||
          liveBounds.height != terminalHeight) {
        configureViewport(liveBounds.width, liveBounds.height);
      }

      if (!paused) {
        accumulate();
      }
      render();

      final elapsed = frameClock.elapsed - loopStart;
      frameMs = elapsed.inMicroseconds / 1000.0;
      final sleepFor = _targetFrameTime - elapsed;
      if (sleepFor > Duration.zero) {
        await Future.delayed(sleepFor);
      }
    }
  } finally {
    await eventSub.cancel();
    await terminal.stop();
  }
}
