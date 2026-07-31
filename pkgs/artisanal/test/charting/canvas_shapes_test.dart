import 'package:artisanal/artisanal.dart';
import 'package:artisanal/uv.dart';
import 'package:test/test.dart';

void main() {
  group('CanvasPainter', () {
    test('projects mathematical world coordinates into terminal dot space', () {
      final painter = CanvasPainter(
        BrailleCanvas(5, 2),
        xBounds: const CanvasRange(-1, 1),
        yBounds: const CanvasRange(-1, 1),
      );

      expect(painter.project(-1, -1), const Position(0, 7));
      expect(painter.project(1, 1), const Position(9, 0));
      expect(painter.project(2, 0), isNull);
    });

    test('clips lines that cross the visible world', () {
      final canvas = Canvas(5, 2);

      drawCanvasShapes(
        canvas,
        canvas.bounds(),
        const [CanvasLine(x1: -5, y1: 5, x2: 15, y2: 5)],
        xBounds: const CanvasRange(0, 10),
        yBounds: const CanvasRange(0, 10),
      );

      expect(
        canvas.render().split('\n').any((line) => line.length == 5),
        isTrue,
      );
    });

    test('draws built-in and custom shapes through one protocol', () {
      final canvas = Canvas(10, 4);
      const red = UvStyle(fg: UvColor.rgb(255, 0, 0));

      drawCanvasShapes(canvas, canvas.bounds(), const [
        CanvasRectangle(x: 5, y: 5, width: 40, height: 40, style: red),
        CanvasCircle(x: 70, y: 50, radius: 20, style: red),
        CanvasPoints([CanvasPoint(50, 90)], style: red),
      ]);

      expect(canvas.render(), isNotEmpty);
      expect(
        canvas.buffer.lines
            .expand((line) => line.cells)
            .where((cell) => cell.content.isNotEmpty)
            .any((cell) => cell.style == red),
        isTrue,
      );
    });
  });
}
