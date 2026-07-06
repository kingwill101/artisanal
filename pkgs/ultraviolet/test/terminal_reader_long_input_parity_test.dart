import 'package:ultraviolet/src/uv/uv.dart';
import 'package:test/test.dart';

void main() {
  group('UV TerminalReader parity (long input)', () {
    test('streams 1000 printable runes', () {
      final parser = UvEventStreamParser();
      final bytes = List<int>.filled(1000, 'a'.codeUnitAt(0));

      final events = <Event>[
        ...parser.parseAll(bytes, expired: false),
        ...parser.flush(),
      ];

      expect(events, hasLength(1000));
      for (final ev in events) {
        expect(ev, isA<KeyPressEvent>());
        expect((ev as KeyPressEvent).key().text, 'a');
      }
    });
  });
}
