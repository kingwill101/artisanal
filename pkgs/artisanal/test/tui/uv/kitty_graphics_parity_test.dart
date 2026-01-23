import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

// Upstream parity (scoped):
// - `third_party/ultraviolet/key_test.go` (Kitty Graphics response cases)

List<Event> _decodeAll(EventDecoder d, List<int> bytes) {
  final out = <Event>[];
  var buf = List<int>.from(bytes);
  while (buf.isNotEmpty) {
    final (n, ev) = d.decode(buf, allowIncompleteEsc: false);
    expect(n, greaterThan(0), reason: 'decoder made no progress');
    if (ev is MultiEvent) {
      out.addAll(ev.events);
    } else if (ev != null) {
      out.add(ev);
    }
    buf = buf.sublist(n);
  }
  return out;
}

void main() {
  group('UV decoder parity: Kitty Graphics', () {
    test('Kitty Graphics response sequences', () {
      final d = EventDecoder();

      expect(_decodeAll(d, '\x1b_Ga=t;OK\x1b\\'.codeUnits), [
        KittyGraphicsEvent(
          options: const KittyOptions(action: 't'),
          payload: 'OK'.codeUnits,
        ),
      ]);

      expect(_decodeAll(d, '\x1b_Gi=99,I=13;OK\x1b\\'.codeUnits), [
        KittyGraphicsEvent(
          options: const KittyOptions(id: 99, number: 13),
          payload: 'OK'.codeUnits,
        ),
      ]);

      expect(
        _decodeAll(d, '\x1b_Gi=1337,q=1;EINVAL:your face\x1b\\'.codeUnits),
        [
          KittyGraphicsEvent(
            options: const KittyOptions(id: 1337, quiet: 1),
            payload: 'EINVAL:your face'.codeUnits,
          ),
        ],
      );
    });
  });
}
