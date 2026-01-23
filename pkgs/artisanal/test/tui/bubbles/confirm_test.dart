import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/tui/bubbles/confirm.dart';
import 'package:test/test.dart';

void main() {
  group('ConfirmModel', () {
    test('inline mode splits labels by grapheme (combining marks)', () {
      final confirm = ConfirmModel(
        prompt: 'Really?',
        displayMode: ConfirmDisplayMode.inline,
        styles: ConfirmStyles(
          yesText: 'e\u0301s', // "és" using combining mark
          noText: 'No',
        ),
      );

      final view = Style.stripAnsi(confirm.view());
      expect(view, contains('(e\u0301)s'));
      expect(view, contains('(N)o'));
    });
  });
}
