import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/lipgloss/canvas_test.go`
// - `third_party/lipgloss/canvas.go`

void main() {
  group('Canvas parity', () {
    test('TestCanvasRender', () {
      final c = Canvas(5, 3);

      // Fill the canvas with dots.
      for (var y = 0; y < c.height(); y++) {
        for (var x = 0; x < c.width(); x++) {
          final cell = c.cellAt(x, y)!;
          cell.content = '.';
        }
      }

      // Draw a rectangle.
      for (var y = 1; y < 2; y++) {
        for (var x = 1; x < 4; x++) {
          final cell = c.cellAt(x, y)!;
          cell.content = '#';
        }
      }

      final expected = ['.....', '.###.', '.....'].join('\n');
      expect(c.render(), expected);
    });

    test('TestCanvasRenderWithTrailingSpaces', () {
      final c = Canvas(5, 2);

      // Fill the canvas with spaces and some trailing spaces.
      for (var y = 0; y < c.height(); y++) {
        for (var x = 0; x < c.width(); x++) {
          final cell = c.cellAt(x, y)!;
          if (x < 3) {
            cell.content = 'A';
          } else {
            cell.content = ' ';
          }
        }
      }

      final expected = ['AAA', 'AAA'].join('\n');
      expect(c.render(), expected);
    });
  });
}
