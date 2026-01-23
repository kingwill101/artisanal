import 'dart:async';

import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

void main() {
  group('UV TerminalReader parity (timeout + mapping)', () {
    test('ESC is emitted only after escTimeout', () async {
      final src = StreamController<List<int>>();
      addTearDown(src.close);

      final reader = TerminalReader(
        CancelReader(src.stream),
        escTimeout: const Duration(milliseconds: 5),
      )..start();
      addTearDown(reader.close);

      final events = <Event>[];
      final sub = reader.events.listen(events.add);
      addTearDown(sub.cancel);

      // Send a single ESC byte. The streaming parser should hold it until the
      // ESC timeout elapses.
      src.add(const [0x1b]);
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, hasLength(1));
      expect(events.single, isA<KeyPressEvent>());
      expect((events.single as KeyPressEvent).key().code, keyEscape);
    });

    test(
      'UnknownEvent is mapped to KeyPressEvent after escTimeout flush',
      () async {
        final src = StreamController<List<int>>();
        addTearDown(src.close);

        final reader = TerminalReader(
          CancelReader(src.stream),
          escTimeout: const Duration(milliseconds: 5),
        )..start();
        addTearDown(reader.close);

        final events = <Event>[];
        final sub = reader.events.listen(events.add);
        addTearDown(sub.cancel);

        // ESC [ 1 $ is a legacy key-table sequence (shift+home). It is not a
        // complete CSI sequence (no final byte), so the decoder yields UnknownEvent
        // when flushed after timeout, and TerminalReader maps it via the key table.
        src.add('\x1b[1\$'.codeUnits);
        await Future<void>.delayed(Duration.zero);
        expect(events, isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(events, hasLength(1));
        final ev = events.single;
        expect(ev, isA<KeyPressEvent>());
        final k = (ev as KeyPressEvent).key();
        expect(k.code, keyHome);
        expect(KeyMod.contains(k.mod, KeyMod.shift), isTrue);
      },
    );
  });
}
