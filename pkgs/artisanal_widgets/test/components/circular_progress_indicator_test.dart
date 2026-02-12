import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
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

      expect(tester.find.text('◜'), isTrue);
    });

    test('indeterminate advances frames over time', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        CircularProgressIndicator(
          value: null,
          interval: const Duration(milliseconds: 40),
        ),
      );

      expect(tester.find.text('◜'), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 65));
      tester.pump();

      final advanced = tester.find.text('◠') || tester.find.text('◝');
      expect(advanced, isTrue);
    });
  });
}
