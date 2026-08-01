# Add simple physics

These lightweight Forge2D helpers are useful for playful demos and interactive
terminal experiments. The API is experimental and exported by
`package:artisanal/artisanal.dart`.

## Quick Start

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  const PhysicsSettings(velocityIterations: 8, positionIterations: 3).apply();

  final world = PhysicsWorld(gravity: Vec2(0, 9.8));

  final bodyDef = BodyDef()
    ..type = BodyType.dynamic
    ..position = Vec2(0, 10);

  final body = world.createBody(bodyDef);
  final shape = CircleShape()..radius = 0.5;
  final fixture = FixtureDef(shape)..density = 1.0;
  body.createFixture(fixture);

  for (var i = 0; i < 60; i++) {
    world.step(1 / 60.0);
  }

  final pos = body.position;
  print('Body position: (${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)})');
}
```

## Things to keep in mind

- This module is `@experimental` and may change in minor releases.
- For advanced usage, access the underlying Forge2D types directly.

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [uv.md](uv.md)
