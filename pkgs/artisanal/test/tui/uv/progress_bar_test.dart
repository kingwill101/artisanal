import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

void main() {
  group('ProgressBar', () {
    test('clamps value to 0..100 for normal states', () {
      expect(ProgressBar(ProgressBarState.normal, -1).value, equals(0));
      expect(ProgressBar(ProgressBarState.normal, 101).value, equals(100));
    });

    test('value is ignored for none/indeterminate', () {
      expect(ProgressBar(ProgressBarState.none, 50).value, equals(0));
      expect(ProgressBar(ProgressBarState.indeterminate, 50).value, equals(0));
    });

    test('toString matches upstream names', () {
      expect(ProgressBar(ProgressBarState.none, 0).toString(), equals('None'));
      expect(
        ProgressBar(ProgressBarState.normal, 0).toString(),
        equals('Default'),
      );
      expect(
        ProgressBar(ProgressBarState.error, 0).toString(),
        equals('Error'),
      );
      expect(
        ProgressBar(ProgressBarState.indeterminate, 0).toString(),
        equals('Indeterminate'),
      );
      expect(
        ProgressBar(ProgressBarState.warning, 0).toString(),
        equals('Warning'),
      );
    });
  });
}
