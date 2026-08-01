# Physics Helpers (Experimental)

Artisanal provides lightweight adapters around Forge2D for demos and interactive UI experiments. This API is experimental.

## Quick Start

```dart
import 'package:artisanal/physics.dart';

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

## Gotchas

- This module is `@experimental` and may change in minor releases.
- For advanced usage, access the underlying Forge2D types directly.

## Related Docs

- [docs_index.md](docs_index.md) - Full documentation index
- [uv.md](uv.md)
