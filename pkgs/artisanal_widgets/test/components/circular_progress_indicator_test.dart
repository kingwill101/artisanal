import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

Future<bool> _waitForAnyText(
  WidgetTester tester,
  Iterable<String> values, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    tester.pump();
    if (values.any(tester.find.text)) return true;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  tester.pump();
  return values.any(tester.find.text);
}

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

      final advanced = await _waitForAnyText(tester, const ['◠', '◝']);
      expect(advanced, isTrue);
    });
  });
}
