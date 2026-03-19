import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/uv/tui_adapter.dart';
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

    test('emits ColorPaletteMsg for palette report events', () {
      final p = UvTuiInputParser();
      final msgs = [
        ...p.parseAll('\x1b]4;42;rgb:1111/2222/3333\x07'.codeUnits),
        ...p.parseAll(const [], expired: true),
      ];

      expect(msgs, hasLength(1));
      expect(msgs.first, isA<ColorPaletteMsg>());
      final m = msgs.first as ColorPaletteMsg;
      expect(m.index, 42);
      expect(m.hex, '#112233');
    });

    test('emits FocusMsg for focus in and out events', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[I\x1b[O'.codeUnits);

      expect(msgs, [const FocusMsg(true), const FocusMsg(false)]);
    });

    test('emits ColorSchemeMsg for light/dark scheme reports', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[?997;1n\x1b[?997;2n'.codeUnits);

      expect(
        msgs,
        const [ColorSchemeMsg(dark: true), ColorSchemeMsg(dark: false)],
      );
    });

    test('emits PasteMsg for bracketed paste payloads', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[200~hello\nworld\x1b[201~'.codeUnits);

      expect(msgs, [const PasteMsg('hello\nworld')]);
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

    test('emits TerminalVersionMsg from DCS terminal version report', () {
      final p = UvTuiInputParser();
      final msgs = [
        ...p.parseAll('\x1bP>|Ultraviolet\x1b\\'.codeUnits),
        ...p.parseAll(const [], expired: true),
      ];

      expect(msgs, hasLength(1));
      expect(msgs.single, isA<TerminalVersionMsg>());
      expect((msgs.single as TerminalVersionMsg).version, 'Ultraviolet');
    });

    test('emits CapabilityMsg from XTGETTCAP response', () {
      final p = UvTuiInputParser();
      final msgs = [
        ...p.parseAll('\x1bP1+r524742\x1b\\'.codeUnits),
        ...p.parseAll(const [], expired: true),
      ];

      expect(msgs, hasLength(1));
      expect(msgs.single, isA<CapabilityMsg>());
      expect((msgs.single as CapabilityMsg).content, 'RGB');
    });

    test(
      'emits device-attribute and modify-other-keys messages from reports',
      () {
        final p = UvTuiInputParser();
        final msgs = [
          ...p.parseAll('\x1b[>4;1m'.codeUnits),
          ...p.parseAll('\x1b[?1;2;4c'.codeUnits),
          ...p.parseAll('\x1b[>1;2;3c'.codeUnits),
          ...p.parseAll('\x1bP!|4368726d\x1b\\'.codeUnits),
          ...p.parseAll(const [], expired: true),
        ];

        expect(msgs, hasLength(4));
        expect(msgs[0], const ModifyOtherKeysMsg(1));
        expect(msgs[1], const PrimaryDeviceAttributesMsg([1, 2, 4]));
        expect(msgs[2], const SecondaryDeviceAttributesMsg([1, 2, 3]));
        expect(msgs[3], const TertiaryDeviceAttributesMsg('Chrm'));
      },
    );

    test('emits KeyboardEnhancementsMsg from kitty keyboard report', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[?2u\x1b[?u'.codeUnits);

      expect(msgs, hasLength(2));
      expect(msgs.first, isA<KeyboardEnhancementsMsg>());
      expect((msgs.first as KeyboardEnhancementsMsg).reportEventTypes, isTrue);
      expect(msgs.last, isA<KeyboardEnhancementsMsg>());
      expect((msgs.last as KeyboardEnhancementsMsg).reportEventTypes, isFalse);
    });

    test('emits ModeReportMsg from CSI mode status replies', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[?2004;1\$y\x1b[?1004;2\$y'.codeUnits);

      expect(msgs, hasLength(2));
      expect(
        msgs.first,
        const ModeReportMsg(mode: 2004, value: ModeReportValue.set),
      );
      expect(
        msgs.last,
        const ModeReportMsg(mode: 1004, value: ModeReportValue.reset),
      );
    });

    test('emits MouseMsg press and release from SGR mouse sequences', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[<0;5;3M\x1b[<0;5;3m'.codeUnits);

      expect(msgs, hasLength(2));
      expect(
        msgs.first,
        const MouseMsg(
          x: 4,
          y: 2,
          button: MouseButton.left,
          action: MouseAction.press,
        ),
      );
      expect(
        msgs.last,
        const MouseMsg(
          x: 4,
          y: 2,
          button: MouseButton.left,
          action: MouseAction.release,
        ),
      );
    });

    test('emits MouseMsg wheel from SGR mouse wheel sequence', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[<64;7;4M'.codeUnits);

      expect(msgs, hasLength(1));
      expect(
        msgs.single,
        const MouseMsg(
          x: 6,
          y: 3,
          button: MouseButton.wheelUp,
          action: MouseAction.wheel,
        ),
      );
    });

    test('emits MouseMsg motion from SGR mouse motion sequence', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[<32;9;6M'.codeUnits);

      expect(msgs, hasLength(1));
      expect(
        msgs.single,
        const MouseMsg(
          x: 8,
          y: 5,
          button: MouseButton.left,
          action: MouseAction.motion,
        ),
      );
    });

    test('emits WindowSizeMsg from CSI t window size reports', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[8;33;120t'.codeUnits);

      expect(msgs, hasLength(1));
      expect(msgs.single, const WindowSizeMsg(120, 33));
    });

    test('emits WindowSizeMsg from in-band CSI 48 size reports', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[48;33;120;660;2400t'.codeUnits);

      expect(msgs, hasLength(2));
      expect(msgs.first, const WindowSizeMsg(120, 33));
      expect(msgs.last, const WindowPixelSizeMsg(2400, 660));
    });

    test('emits pixel and cell size messages from CSI t reports', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[4;660;2400t\x1b[6;13;7t'.codeUnits);

      expect(msgs, hasLength(2));
      expect(msgs.first, const WindowPixelSizeMsg(2400, 660));
      expect(msgs.last, const CellSizeMsg(7, 13));
    });
  });
}
