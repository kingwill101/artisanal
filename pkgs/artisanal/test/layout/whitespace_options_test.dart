import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  group('WhitespaceOptions.render', () {
    test('renders without hanging on zero-width graphemes', () async {
      final opts = WhitespaceOptions(chars: '\u0301'); // combining acute, width 0

      final result = await _withTimeout(() => opts.render(5));

      expect(result.length, greaterThanOrEqualTo(5));
    });

    test('renders without hanging on mixed zero-width and normal graphemes',
        () async {
      final opts = WhitespaceOptions(chars: 'a\u0301'); // 'a' + combining acute

      final result = await _withTimeout(() => opts.render(5));

      expect(result.length, greaterThanOrEqualTo(5));
    });
  });
}

Future<T> _withTimeout<T>(T Function() fn) {
  return Future(fn).timeout(const Duration(seconds: 2));
}
