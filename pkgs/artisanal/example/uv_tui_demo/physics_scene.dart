library;

import 'dart:math' as math;

import 'package:artisanal/physics.dart';
import 'package:artisanal/style.dart';

import 'theme.dart';

final class PhysicsScene {
  PhysicsScene({
    required this.world,
    required this.worldWidth,
    required this.worldHeight,
    required this.bodies,
    required this.gravityEnabled,
    required this.seed,
  });

  factory PhysicsScene.initial({int seed = 12}) {
    final world = PhysicsWorld(gravity: Vec2(0, 12));
    final scene = PhysicsScene(
      world: world,
      worldWidth: 32,
      worldHeight: 18,
      bodies: const [],
      gravityEnabled: true,
      seed: seed,
    );
    return scene._withBounds().spawnBurst(10);
  }

  final PhysicsWorld world;
  final double worldWidth;
  final double worldHeight;
  final List<Body> bodies;
  final bool gravityEnabled;
  final int seed;

  PhysicsScene copyWith({
    PhysicsWorld? world,
    double? worldWidth,
    double? worldHeight,
    List<Body>? bodies,
    bool? gravityEnabled,
    int? seed,
  }) {
    return PhysicsScene(
      world: world ?? this.world,
      worldWidth: worldWidth ?? this.worldWidth,
      worldHeight: worldHeight ?? this.worldHeight,
      bodies: bodies ?? this.bodies,
      gravityEnabled: gravityEnabled ?? this.gravityEnabled,
      seed: seed ?? this.seed,
    );
  }

  PhysicsScene step(double dt) {
    final subSteps = math.max(1, (dt / 0.016).round());
    final stepDt = dt / subSteps;
    for (var i = 0; i < subSteps; i++) {
      world.step(stepDt);
    }
    return this;
  }

  PhysicsScene toggleGravity() {
    final next = !gravityEnabled;
    world.world.gravity = next ? Vec2(0, 12) : Vec2.zero();
    return copyWith(gravityEnabled: next);
  }

  PhysicsScene spawnBurst(int count) {
    final rng = math.Random(seed + bodies.length);
    final nextBodies = [...bodies];
    for (var i = 0; i < count; i++) {
      if (rng.nextBool()) {
        nextBodies.add(_spawnBall(rng));
      } else {
        nextBodies.add(_spawnBox(rng));
      }
    }
    return copyWith(bodies: nextBodies);
  }

  PhysicsScene reset() {
    final next = PhysicsScene.initial(seed: seed + 1);
    return next;
  }

  PhysicsScene blast() {
    final rng = math.Random(seed + bodies.length * 13);
    for (final body in bodies) {
      if (body.bodyType != BodyType.dynamic) continue;
      final impulse = Vec2(
        (rng.nextDouble() - 0.5) * 40,
        (rng.nextDouble() - 0.5) * 40,
      );
      body.applyLinearImpulse(impulse);
    }
    return this;
  }

  PhysicsScene _withBounds() {
    final ground = world.createBody(BodyDef()..type = BodyType.static);
    final shape = EdgeShape();

    void addEdge(double x1, double y1, double x2, double y2) {
      shape.set(Vec2(x1, y1), Vec2(x2, y2));
      ground.createFixture(FixtureDef(shape)..restitution = 0.6);
    }

    addEdge(0, 0, worldWidth, 0);
    addEdge(worldWidth, 0, worldWidth, worldHeight);
    addEdge(worldWidth, worldHeight, 0, worldHeight);
    addEdge(0, worldHeight, 0, 0);

    return this;
  }

  Body _spawnBall(math.Random rng) {
    final radius = 0.4 + rng.nextDouble() * 0.8;
    final shape = CircleShape(radius: radius);
    final body = world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: Vec2(
          2 + rng.nextDouble() * (worldWidth - 4),
          2 + rng.nextDouble() * (worldHeight / 2),
        ),
      ),
    );
    body.createFixture(
      FixtureDef(shape)
        ..density = 1.0
        ..restitution = 0.6
        ..friction = 0.2,
    );
    return body;
  }

  Body _spawnBox(math.Random rng) {
    final hw = 0.5 + rng.nextDouble() * 0.9;
    final hh = 0.4 + rng.nextDouble() * 0.8;
    final shape = PolygonShape()..setAsBoxXY(hw, hh);
    final body = world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: Vec2(
          2 + rng.nextDouble() * (worldWidth - 4),
          2 + rng.nextDouble() * (worldHeight / 2),
        ),
        angle: rng.nextDouble() * math.pi,
      ),
    );
    body.createFixture(
      FixtureDef(shape)
        ..density = 1.0
        ..restitution = 0.4
        ..friction = 0.4,
    );
    return body;
  }
}

List<String> renderPhysicsScene({
  required PhysicsScene scene,
  required int width,
  required int height,
  required DemoThemeData theme,
}) {
  if (width <= 2 || height <= 2) {
    return ['physics viewport too small'];
  }

  final grid = List.generate(
    height,
    (_) => List<String>.filled(width, ' ', growable: false),
    growable: false,
  );

  void setCell(int x, int y, String value) {
    if (x <= 0 || y <= 0 || x >= width - 1 || y >= height - 1) return;
    grid[y][x] = value;
  }

  final borderStyle = Style().foreground(theme.palette.border).render;
  for (var x = 0; x < width; x++) {
    grid[0][x] = borderStyle('─');
    grid[height - 1][x] = borderStyle('─');
  }
  for (var y = 0; y < height; y++) {
    grid[y][0] = borderStyle('│');
    grid[y][width - 1] = borderStyle('│');
  }
  grid[0][0] = borderStyle('┌');
  grid[0][width - 1] = borderStyle('┐');
  grid[height - 1][0] = borderStyle('└');
  grid[height - 1][width - 1] = borderStyle('┘');

  final scaleX = (width - 2) / scene.worldWidth;
  final scaleY = (height - 2) / scene.worldHeight;

  int toX(double wx) => (wx * scaleX).round() + 1;
  int toY(double wy) => (wy * scaleY).round() + 1;

  Color speedColor(double speed) {
    if (speed > 14) return theme.chartD;
    if (speed > 9) return theme.chartC;
    if (speed > 5) return theme.chartB;
    return theme.chartA;
  }

  for (final body in scene.bodies) {
    if (body.bodyType != BodyType.dynamic) continue;
    final speed = body.linearVelocity.length;
    final color = speedColor(speed);
    final glyph = speed > 12 ? '◆' : speed > 6 ? '●' : '•';

    for (final fixture in body.fixtures) {
      final shape = fixture.shape;
      if (shape is CircleShape) {
        final center = body.worldPoint(shape.position);
        final radius = shape.radius * (scaleX + scaleY) / 2;
        final samples = math.max(8, (radius * 6).round());
        for (var i = 0; i < samples; i++) {
          final angle = (math.pi * 2 * i) / samples;
          final x = toX(center.x + math.cos(angle) * shape.radius);
          final y = toY(center.y + math.sin(angle) * shape.radius);
          setCell(x, y, Style().foreground(color).render(glyph));
        }
        setCell(
          toX(center.x),
          toY(center.y),
          Style().foreground(color).bold().render('●'),
        );
      } else if (shape is PolygonShape) {
        final verts = shape.vertices;
        for (var i = 0; i < verts.length; i++) {
          final a = body.worldPoint(verts[i]);
          final b = body.worldPoint(verts[(i + 1) % verts.length]);
          _plotLine(toX(a.x), toY(a.y), toX(b.x), toY(b.y), (x, y) {
            setCell(x, y, Style().foreground(color).render('■'));
          });
        }
      }
    }

    final vel = body.linearVelocity;
    if (vel.length > 0.5) {
      final pos = body.position;
      final vx = pos.x - vel.x * 0.05;
      final vy = pos.y - vel.y * 0.05;
      _plotLine(toX(pos.x), toY(pos.y), toX(vx), toY(vy), (x, y) {
        setCell(x, y, Style().foreground(theme.palette.textDim).render('·'));
      });
    }
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
