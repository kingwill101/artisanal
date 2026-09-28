import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('CircularProgressIndicator', () {
    test('determinate maps min/max values to glyphs', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            CircularProgressIndicator(value: 0.0),
            CircularProgressIndicator(value: 1.0),
          ],
        ),
      );

      expect(tester.find.text('○'), isTrue);
      expect(tester.find.text('●'), isTrue);
    });

    test('indeterminate renders spinner frame', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(CircularProgressIndicator(value: null));

      const frames = ['◜', '◠', '◝', '◞', '◡', '◟'];
      final before = frames.indexWhere(tester.find.text);
      expect(before, isNonNegative);
    });

    test('indeterminate advances on a spinner tick', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        CircularProgressIndicator(
          value: null,
          interval: const Duration(milliseconds: 40),
        ),
      );

      const frames = ['◜', '◠', '◝', '◞', '◡', '◟'];
      final before = frames.indexWhere(tester.find.text);
      expect(before, isNonNegative);

      final deadline = DateTime.now().add(const Duration(seconds: 1));
      var after = before;
      while (DateTime.now().isBefore(deadline) && after == before) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        tester.pump();
        after = frames.indexWhere(tester.find.text);
      }

      expect(after, isNot(before));
    });
  });
}
