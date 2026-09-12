import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal_widgets/src/widgets/layout/constrained_box.dart';
import 'package:artisanal_widgets/src/widgets/layout/sized_box.dart';
import 'package:artisanal_widgets/widgets.dart'
    show BoxConstraints, RenderText, Size;
import 'package:test/test.dart';

void main() {
  group('SizedBox parent constraints', () {
    test('clamps explicit dimensions before child layout and paint', () {
      final child = RenderText(text: 'x' * 60);
      final box = RenderSizedBox(width: 40, height: 8)..attach(child);
      box.layout(BoxConstraints(maxWidth: 28, maxHeight: 6));

      expect(child.constraints, BoxConstraints.tight(const Size(28, 6)));
      expect(box.size, const Size(28, 6));
      expect(Layout.getWidth(box.paint()), 28);
      expect(Layout.getHeight(box.paint()), 6);
    });

    test('parent minima also apply to explicit smaller dimensions', () {
      final child = RenderText(text: 'x');
      final box = RenderSizedBox(width: 2, height: 1)..attach(child);
      box.layout(
        BoxConstraints(minWidth: 10, maxWidth: 20, minHeight: 4, maxHeight: 6),
      );

      expect(child.constraints, BoxConstraints.tight(const Size(10, 4)));
      expect(box.size, const Size(10, 4));
      expect(Layout.getWidth(box.paint()), 10);
      expect(Layout.getHeight(box.paint()), 4);
    });

    test('recomputes child constraints and paint after shrinking', () {
      final child = RenderText(text: 'abcdefghij' * 4);
      final box = RenderSizedBox(width: 30, height: 4)..attach(child);
      box.layout(BoxConstraints(maxWidth: 40, maxHeight: 8));
      box.layout(BoxConstraints(maxWidth: 12, maxHeight: 3));

      expect(child.constraints, BoxConstraints.tight(const Size(12, 3)));
      expect(box.size, const Size(12, 3));
      expect(Layout.getWidth(box.paint()), 12);
      expect(Layout.getHeight(box.paint()), 3);
    });
  });

  group('ConstrainedBox interval composition', () {
    test('bounded maxima limit the child without forcing it to fill', () {
      final child = RenderText(text: 'x');
      final box = RenderConstrainedBox(
        additionalConstraints: BoxConstraints(maxWidth: 20, maxHeight: 10),
      )..attach(child);
      box.layout(BoxConstraints(maxWidth: 80, maxHeight: 24));
      expect(box.size, const Size(1, 1));
      expect(box.paint(), 'x');
    });

    test('minimum extents still pad a smaller child', () {
      final child = RenderText(text: 'x');
      final box = RenderConstrainedBox(
        additionalConstraints: BoxConstraints(
          minWidth: 5,
          maxWidth: 20,
          minHeight: 3,
          maxHeight: 10,
        ),
      )..attach(child);
      box.layout(BoxConstraints(maxWidth: 80, maxHeight: 24));
      expect(box.size, const Size(5, 3));
      expect(Layout.getWidth(box.paint()), 5);
      expect(Layout.getHeight(box.paint()), 3);
    });

    test('additional minima above parent maxima resolve to parent maxima', () {
      final child = RenderText(text: 'x');
      final box = RenderConstrainedBox(
        additionalConstraints: BoxConstraints(
          minWidth: 50,
          maxWidth: 60,
          minHeight: 20,
          maxHeight: 30,
        ),
      )..attach(child);
      final parent = BoxConstraints(maxWidth: 28, maxHeight: 8);
      box.layout(parent);

      expect(child.constraints, BoxConstraints.tight(const Size(28, 8)));
      expect(box.constraints, parent);
      expect(box.size, const Size(28, 8));
    });

    test('additional maxima below parent minima resolve to parent minima', () {
      final child = RenderText(text: 'x');
      final box = RenderConstrainedBox(
        additionalConstraints: BoxConstraints(maxWidth: 5, maxHeight: 2),
      )..attach(child);
      box.layout(
        BoxConstraints(minWidth: 12, maxWidth: 20, minHeight: 6, maxHeight: 10),
      );

      expect(child.constraints, BoxConstraints.tight(const Size(12, 6)));
      expect(box.size, const Size(12, 6));
      expect(Layout.getWidth(box.paint()), 12);
    });

    test('expand under finite constraints produces finite tight children', () {
      final child = RenderText(text: 'x');
      final box = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.expand(),
      )..attach(child);
      box.layout(BoxConstraints(maxWidth: 20, maxHeight: 5));

      expect(child.constraints, BoxConstraints.tight(const Size(20, 5)));
    });
  });
}
