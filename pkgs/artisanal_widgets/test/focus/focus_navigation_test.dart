import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Focus Navigation', () {
    test('next() moves focus in tree order', () async {
      final tester = WidgetTester();
      try {
        final controller = w.FocusController();

        await tester.pumpWidget(
          w.FocusScope(
            controller: controller,
            child: w.Column(
              children: [
                w.Focusable(focusId: 'id1', child: w.Text('id1')),
                w.Focusable(focusId: 'id2', child: w.Text('id2')),
                w.Focusable(focusId: 'id3', child: w.Text('id3')),
              ],
            ),
          ),
        );

        expect(controller.focusedId, isNull);

        controller.next();
        expect(controller.focusedId, equals('id1'));

        controller.next();
        expect(controller.focusedId, equals('id2'));

        controller.next();
        expect(controller.focusedId, equals('id3'));

        // Wraps around
        controller.next();
        expect(controller.focusedId, equals('id1'));
      } finally {
        await tester.dispose();
      }
    });

    test('previous() moves focus in reverse tree order', () async {
      final tester = WidgetTester();
      try {
        final controller = w.FocusController();

        await tester.pumpWidget(
          w.FocusScope(
            controller: controller,
            child: w.Column(
              children: [
                w.Focusable(focusId: 'id1', child: w.Text('id1')),
                w.Focusable(focusId: 'id2', child: w.Text('id2')),
                w.Focusable(focusId: 'id3', child: w.Text('id3')),
              ],
            ),
          ),
        );

        controller.requestFocus('id1');

        controller.previous();
        expect(controller.focusedId, equals('id3'));

        controller.previous();
        expect(controller.focusedId, equals('id2'));

        controller.previous();
        expect(controller.focusedId, equals('id1'));
      } finally {
        await tester.dispose();
      }
    });

    test('navigation respects trap', () async {
      final tester = WidgetTester();
      try {
        final controller = w.FocusController();

        await tester.pumpWidget(
          w.FocusScope(
            controller: controller,
            child: w.Column(
              children: [
                w.Focusable(focusId: 'outside', child: w.Text('outside')),
                w.FocusScope(
                  isTrapped: true,
                  child: w.Column(
                    children: [
                      w.Focusable(focusId: 'inside1', child: w.Text('inside1')),
                      w.Focusable(focusId: 'inside2', child: w.Text('inside2')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        controller.requestFocus('inside1');
        expect(controller.focusedId, equals('inside1'));

        controller.next();
        expect(controller.focusedId, equals('inside2'));

        // Wraps around within trap
        controller.next();
        expect(controller.focusedId, equals('inside1'));

        controller.previous();
        expect(controller.focusedId, equals('inside2'));
      } finally {
        await tester.dispose();
      }
    });
  });
}
