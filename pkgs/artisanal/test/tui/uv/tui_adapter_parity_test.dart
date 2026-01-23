import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/uv/uv.dart' hide ClipboardSelection;
import 'package:artisanal/terminal.dart';
import 'package:test/test.dart';

void main() {
  group('UV → TUI adapter parity', () {
    test('emits BackgroundColorMsg for color report events', () {
      final p = UvTuiInputParser();
      final msgs = [
        ...p.parseAll('\x1b]11;rgb:1a1a/1b1b/2c2c\x07'.codeUnits),
        ...p.parseAll(const [], expired: true),
      ];

      expect(msgs, hasLength(1));
      expect(msgs.first, isA<BackgroundColorMsg>());
      final m = msgs.first as BackgroundColorMsg;
      expect(m.hex, '#1a1b2c');
    });

    test('maps UnknownEvent to KeyMsg via key table on timeout flush', () {
      final p = UvTuiInputParser();

      // ESC [ 1 $ is a valid legacy key sequence in the UV key table (shift+home),
      // but it's not a complete CSI sequence, so the decoder yields UnknownEvent
      // when flushed after the ESC timeout.
      final early = p.parseAll('\x1b[1\$'.codeUnits, expired: false);
      expect(early, isEmpty);

      final flushed = p.parseAll(const [], expired: true);
      expect(flushed, hasLength(1));

      final msg = flushed.first;
      expect(msg, isA<KeyMsg>());
      final key = (msg as KeyMsg).key;
      expect(key.type, KeyType.home);
      expect(key.shift, isTrue);
    });

    test('emits ClipboardMsg from OSC 52 clipboard response', () {
      final p = UvTuiInputParser();
      final msgs = [
        ...p.parseAll('\x1b]52;c;SGVsbG8=\x07'.codeUnits),
        ...p.parseAll(const [], expired: true),
      ];

      expect(msgs, hasLength(1));
      expect(msgs.single, isA<ClipboardMsg>());
      final m = msgs.single as ClipboardMsg;
      expect(m.selection, ClipboardSelection.system);
      expect(m.content, 'Hello');
    });
  });
}
