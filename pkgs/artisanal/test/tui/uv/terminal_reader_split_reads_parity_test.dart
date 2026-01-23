import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity (scoped):
// - `third_party/ultraviolet/key_test.go` (TestSplitReads)
void main() {
  group('UV TerminalReader parity (split reads)', () {
    test('split reads across ESC sequences', () {
      final inputs = <String>[
        'abc',
        '\x1b[A',
        '\x1b[<0;33',
        ';17M',
        '\x1b[I',
        '\x1b',
        '[',
        '<',
        '0',
        ';',
        '3',
        '3',
        ';',
        '1',
        '7',
        'M',
        '\x1b[O',
        '\x1b',
        ']',
        '2',
        ';',
        'a',
        'b',
        'c',
        '\x1b',
        '\x1b[',
        '<0;3',
        '3;17M',
        '\x1b[A\x1b[',
        '<0;33;17M\x1b[',
        '<0;33;17M\x1b[I',
        '\x1b[12;34;9',
      ];

      final bytes = inputs.join().codeUnits;
      final parser = UvEventStreamParser();

      final events = <Event>[];
      const chunkSize = 8; // matches upstream LimitedReader(..., 8)
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final chunk = bytes.sublist(i, (i + chunkSize).clamp(0, bytes.length));
        events.addAll(parser.parseAll(chunk, expired: false));
      }
      events.addAll(parser.flush());

      expect(events, hasLength(14));

      Key keyAt(int idx) => (events[idx] as KeyPressEvent).key();

      expect(events[0], isA<KeyPressEvent>());
      expect(keyAt(0).text, 'a');
      expect(events[1], isA<KeyPressEvent>());
      expect(keyAt(1).text, 'b');
      expect(events[2], isA<KeyPressEvent>());
      expect(keyAt(2).text, 'c');

      expect(events[3], isA<KeyPressEvent>());
      expect(keyAt(3).code, keyUp);

      expect(events[4], isA<MouseClickEvent>());
      final m0 = (events[4] as MouseClickEvent).mouse();
      expect(m0, const Mouse(x: 32, y: 16, button: MouseButton.left));

      expect(events[5], isA<FocusEvent>());

      expect(events[6], isA<MouseClickEvent>());
      final m1 = (events[6] as MouseClickEvent).mouse();
      expect(m1, const Mouse(x: 32, y: 16, button: MouseButton.left));

      expect(events[7], isA<BlurEvent>());

      expect(events[8], isA<MouseClickEvent>());
      final m2 = (events[8] as MouseClickEvent).mouse();
      expect(m2, const Mouse(x: 32, y: 16, button: MouseButton.left));

      expect(events[9], isA<KeyPressEvent>());
      expect(keyAt(9).code, keyUp);

      expect(events[10], isA<MouseClickEvent>());
      final m3 = (events[10] as MouseClickEvent).mouse();
      expect(m3, const Mouse(x: 32, y: 16, button: MouseButton.left));

      expect(events[11], isA<MouseClickEvent>());
      final m4 = (events[11] as MouseClickEvent).mouse();
      expect(m4, const Mouse(x: 32, y: 16, button: MouseButton.left));

      expect(events[12], isA<FocusEvent>());

      expect(events[13], isA<UnknownEvent>());
      expect((events[13] as UnknownEvent).value, '\x1b[12;34;9');
    });
  });
}
