/// Physics helpers built on top of forge2d.
///
/// This module provides lightweight adapters and convenience helpers so
/// demos can integrate physics without pulling forge2d directly into
/// application code. It intentionally keeps the surface minimal and
/// exposes the underlying forge2d types for advanced usage.
library;

import 'package:forge2d/forge2d.dart' as f2d;

/// Global physics settings (Forge2D uses module-level settings).
final class PhysicsSettings {
  const PhysicsSettings({
    this.velocityIterations = 10,
    this.positionIterations = 10,
  });

  /// Number of velocity iterations per step.
  final int velocityIterations;

  /// Number of position iterations per step.
  final int positionIterations;

  /// Applies these settings to the global forge2d configuration.
  void apply() {
    f2d.velocityIterations = velocityIterations;
    f2d.positionIterations = positionIterations;
  }
}

/// Convenience wrapper around a Forge2D [World].
final class PhysicsWorld {
  PhysicsWorld({f2d.Vector2? gravity, PhysicsSettings? settings})
    : world = f2d.World(gravity ?? f2d.Vector2(0, 9.8)) {
    settings?.apply();
  }

  /// The underlying forge2d world.
  final f2d.World world;

  /// Step the world by [dt] seconds.
  void step(double dt) => world.stepDt(dt);

  /// Creates a new body from the given [def].
  f2d.Body createBody(f2d.BodyDef def) => world.createBody(def);

  /// Removes a [body] from the world.
  void destroyBody(f2d.Body body) => world.destroyBody(body);

  /// All bodies currently in the world.
  List<f2d.Body> get bodies => world.bodies;
}

/// Re-export common forge2d types for convenience.

/// Alias for forge2d's 2-D vector.
typedef Vec2 = f2d.Vector2;

/// Alias for a forge2d physics body.
typedef Body = f2d.Body;

/// Alias for a forge2d body definition.
typedef BodyDef = f2d.BodyDef;

/// Alias for forge2d body types (static, dynamic, kinematic).
typedef BodyType = f2d.BodyType;

/// Alias for a forge2d fixture definition.
typedef FixtureDef = f2d.FixtureDef;

/// Alias for the forge2d shape base class.
typedef Shape = f2d.Shape;

/// Alias for a forge2d circle shape.
typedef CircleShape = f2d.CircleShape;

/// Alias for a forge2d convex polygon shape.
typedef PolygonShape = f2d.PolygonShape;

/// Alias for a forge2d edge (line segment) shape.
typedef EdgeShape = f2d.EdgeShape;
