import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

// Behavior parity reference:
// - `third_party/lipgloss/layer.go` (`Layer`, `Compositor`, `Hit`, `Render`)

void main() {
  group('Compositor behavior', () {
    test('renders layers in z-index order (top-most wins)', () {
      final bottom = newLayer('A')
        ..setId('a')
        ..setZ(0);
      final top = newLayer('B')
        ..setId('b')
        ..setZ(1);
      final compositor = Compositor([bottom, top]);

      expect(compositor.render(), 'B');
      expect(compositor.hit(0, 0).id, 'b');
    });

    test('hit ignores layers with empty IDs', () {
      final bottom = newLayer('A')
        ..setId('a')
        ..setZ(0);
      final top = newLayer('B')
        ..setZ(1); // empty ID, should be ignored by hit test
      final compositor = Compositor([bottom, top]);

      expect(compositor.hit(0, 0).id, 'a');
    });

    test('bounds include positioned layers and render respects offsets', () {
      final a = newLayer('AA')..setId('a');
      final b = newLayer('B')
        ..setId('b')
        ..setX(3)
        ..setY(1);
      final compositor = Compositor([a, b]);

      expect(
        compositor.bounds(),
        const Rectangle(minX: 0, minY: 0, maxX: 4, maxY: 2),
      );
      expect(compositor.render(), ['AA', '   B'].join('\n'));
      expect(compositor.getLayer('b'), same(b));
    });

    test('refresh recomputes bounds after content changes', () {
      final layer = newLayer('A')..setId('a');
      final compositor = Compositor([layer]);
      expect(compositor.render(), 'A');

      layer.drawable = StyledString('AA');
      compositor.refresh();
      expect(compositor.render(), 'AA');
    });
  });
}
