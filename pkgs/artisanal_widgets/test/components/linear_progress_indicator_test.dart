import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('LinearProgressIndicator', () {
    test('determinate renders filled and track cells', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(LinearProgressIndicator(value: 0.5, width: 8));

      expect(tester.find.text('████░░░░'), isTrue);
    });

    test('indeterminate renders animated bar segment frame', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(LinearProgressIndicator(value: null, width: 10));

      expect(tester.find.text('████'), isTrue);
      expect(tester.find.text('░'), isTrue);
    });
  });
}
