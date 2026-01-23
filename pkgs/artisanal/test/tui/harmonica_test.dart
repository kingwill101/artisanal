import 'package:artisanal/src/tui/harmonica.dart';
import 'package:test/test.dart';

void main() {
  group('Spring (harmonica parity)', () {
    test('approaches target smoothly', () {
      final spring = Spring(1 / 60, 18 * 2 * 3.1415926535, 1.0);
      var pos = 0.0;
      var vel = 0.0;
      for (var i = 0; i < 5; i++) {
        final res = spring.update(pos, vel, 1.0);
        pos = res.$1;
        vel = res.$2;
      }
      expect(pos, greaterThan(0));
      expect(pos, lessThan(1));
    });
  });

  group('Projectile (harmonica parity)', () {
    test('updates position with velocity and acceleration', () {
      final projectile = Projectile(
        1 / 60,
        const Point(0, 0, 0),
        const Vector(1, 2, 0),
        gravity,
      );
      final p1 = projectile.update();
      expect(p1.x, closeTo(1 / 60, 1e-9));
      expect(p1.y, closeTo(2 / 60, 1e-9));
      // after first update, velocity should have changed by gravity * dt
      expect(projectile.velocity.y, closeTo(2 + gravity.y / 60, 1e-6));
    });
  });
}
