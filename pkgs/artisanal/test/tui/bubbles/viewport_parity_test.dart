import 'package:artisanal/src/tui/bubbles/viewport.dart';
import 'package:test/test.dart';

void main() {
  group('Viewport gutter', () {
    test('reduces render width by gutter and prefixes spaces', () {
      final vp = ViewportModel(width: 20, height: 2, gutter: 2)
        ..setContent('12345678901234567890');
      final line = vp.view().split('\n').first;
      expect(line.startsWith('  '), isTrue);
      expect(line.length, 20);
    });
  });
}
