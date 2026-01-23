import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

// Upstream parity (scoped subset):
// - `third_party/ultraviolet/key_test.go` (TestFocus/TestBlur/TestParseSequence)

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
  group('UV key sequence parity (subset)', () {
    test('Focus / Blur', () {
      final d = EventDecoder();
      expect(_decodeAll(d, '\x1b[I'.codeUnits), [const FocusEvent()]);
      expect(_decodeAll(d, '\x1b[O'.codeUnits), [const BlurEvent()]);
    });

    test('OSC 11 background color report (BEL)', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b]11;rgb:ffff/0000/ffff\x07'.codeUnits);
      expect(evs, hasLength(1));
      expect(evs[0], isA<BackgroundColorEvent>());
      expect((evs[0] as BackgroundColorEvent).color, const UvRgb(255, 0, 255));
    });

    test('OSC 52 clipboard read responses', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, [
        ...'\x1b]52\x1b\\'.codeUnits,
        ...'\x1b]52;c;!\x1b\\'.codeUnits,
        ...'\x1b]52;c;aGk=\x1b\\'.codeUnits,
      ]);
      expect(evs, hasLength(3));

      expect(evs[0], const ClipboardEvent());

      expect(evs[1], isA<ClipboardEvent>());
      final bad = evs[1] as ClipboardEvent;
      expect(bad.selection, ClipboardSelection.none);
      expect(bad.content, '!');

      expect(evs[2], isA<ClipboardEvent>());
      final ok = evs[2] as ClipboardEvent;
      expect(ok.selection, 'c'.codeUnitAt(0));
      expect(ok.content, 'hi');
    });

    test('8-bit sequences (C1 controls)', () {
      final d = EventDecoder();
      final bytes =
          ('\x9bA' // CSI A
                  '\x8fA' // SS3 A
                  '\x90>|Ultraviolet\x1b\\' // DCS >|... ST
                  '\x9d11;#123456\x9c' // OSC 11 ; #123456 ST
                  '\x98hi\x9c' // SOS hi ST
                  '\x9fhello\x9c' // APC hello ST
                  '\x9ebye\x9c' // PM bye ST
                  )
              .codeUnits;
      final evs = _decodeAll(d, bytes);
      expect(evs, hasLength(7));

      expect(evs[0], isA<KeyPressEvent>());
      expect((evs[0] as KeyPressEvent).key().code, keyUp);

      expect(evs[1], isA<KeyPressEvent>());
      expect((evs[1] as KeyPressEvent).key().code, keyUp);

      expect(evs[2], isA<TerminalVersionEvent>());
      expect((evs[2] as TerminalVersionEvent).name, 'Ultraviolet');

      expect(evs[3], isA<BackgroundColorEvent>());
      expect(
        (evs[3] as BackgroundColorEvent).color,
        const UvRgb(0x12, 0x34, 0x56),
      );

      expect(evs[4], isA<UnknownSosEvent>());
      expect(evs[5], isA<UnknownApcEvent>());
      expect(evs[6], isA<UnknownPmEvent>());
    });

    test('Broken escape introducers are Alt-modified keys', () {
      final d = EventDecoder();

      void expectKey(String seq, int code, int mod) {
        final (n, ev) = d.decode(seq.codeUnits, allowIncompleteEsc: false);
        expect(n, seq.codeUnits.length);
        expect(ev, isA<KeyPressEvent>());
        final k = (ev as KeyPressEvent).key();
        expect(k.code, code);
        expect(k.mod, mod);
      }

      expectKey('\x1b[', 0x5b, KeyMod.alt);
      expectKey('\x1b]', 0x5d, KeyMod.alt);
      expectKey('\x1b^', 0x5e, KeyMod.alt);
      expectKey('\x1b_', 0x5f, KeyMod.alt);
      expectKey('\x1bP', 0x70, KeyMod.shift | KeyMod.alt); // 'p'
      expectKey('\x1bX', 0x78, KeyMod.shift | KeyMod.alt); // 'x'
      expectKey('\x1bO', 0x6f, KeyMod.shift | KeyMod.alt); // 'o'

      final (nEsc, evEsc) = d.decode('\x1b'.codeUnits);
      expect(nEsc, 1);
      expect(evEsc, isA<KeyPressEvent>());
      expect((evEsc as KeyPressEvent).key().code, keyEscape);
    });

    test('ESC followed by non-key sequence yields Escape then sequence', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b\x1b[?2004;1\$y'.codeUnits);
      expect(evs, hasLength(2));
      expect(evs[0], isA<KeyPressEvent>());
      expect((evs[0] as KeyPressEvent).key().code, keyEscape);
      expect(evs[1], isA<ModeReportEvent>());
      final mr = evs[1] as ModeReportEvent;
      expect(mr.mode, 2004);
      expect(mr.value, ModeSetting.set);
    });

    test('Unknown sequences (CSI/SS3/DCS) and SS3 digit modifier prefix', () {
      final d = EventDecoder();
      final bytes = '\x1b[z\x1bOz\x1bO2 \x1bP?1;2:3+zABC\x1b\\'.codeUnits;
      final evs = _decodeAll(d, bytes);
      expect(evs, hasLength(5));

      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[z');

      expect(evs[1], isA<UnknownSs3Event>());
      expect((evs[1] as UnknownSs3Event).value, '\x1bOz');

      expect(evs[2], isA<UnknownEvent>());
      expect((evs[2] as UnknownEvent).value, '\x1bO2');

      expect(evs[3], isA<KeyPressEvent>());
      expect((evs[3] as KeyPressEvent).key().code, keySpace);

      expect(evs[4], isA<UnknownDcsEvent>());
      expect((evs[4] as UnknownDcsEvent).value, '\x1bP?1;2:3+zABC\x1b\\');
    });

    test('Report mode responses (including not-recognized)', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[2;1\$y\x1b[\$y\x1b[2\$y\x1b[2;\$y'.codeUnits,
      );
      expect(evs, hasLength(4));

      expect(evs[0], isA<ModeReportEvent>());
      final ok = evs[0] as ModeReportEvent;
      expect(ok.mode, 2);
      expect(ok.value, ModeSetting.set);

      expect(evs[1], isA<UnknownCsiEvent>());
      expect((evs[1] as UnknownCsiEvent).value, '\x1b[\$y');

      expect(evs[2], isA<UnknownCsiEvent>());
      expect((evs[2] as UnknownCsiEvent).value, '\x1b[2\$y');

      expect(evs[3], isA<ModeReportEvent>());
      final nr = evs[3] as ModeReportEvent;
      expect(nr.mode, 2);
      expect(nr.value, ModeSetting.notRecognized);
    });

    test(r'Invalid report mode responses (CSI ? $y variants)', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        '\x1b[?\$y\x1b[?1049\$y\x1b[?1049;\$y'.codeUnits,
      );
      expect(evs, hasLength(3));

      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[?\$y');

      expect(evs[1], isA<UnknownCsiEvent>());
      expect((evs[1] as UnknownCsiEvent).value, '\x1b[?1049\$y');

      expect(evs[2], isA<ModeReportEvent>());
      final mr = evs[2] as ModeReportEvent;
      expect(mr.mode, 1049);
      expect(mr.value, ModeSetting.notRecognized);
    });

    test('Short X10 mouse input yields UnknownCsiEvent then continues', () {
      final d = EventDecoder();
      final evs = _decodeAll(d, '\x1b[M !'.codeUnits);
      expect(evs, hasLength(3));

      expect(evs[0], isA<UnknownCsiEvent>());
      expect((evs[0] as UnknownCsiEvent).value, '\x1b[M');

      expect(evs[1], isA<KeyPressEvent>());
      expect((evs[1] as KeyPressEvent).key().text, ' ');

      expect(evs[2], isA<KeyPressEvent>());
      expect((evs[2] as KeyPressEvent).key().text, '!');
    });

    test('Window op CSI t reports', () {
      final d = EventDecoder();
      final evs = _decodeAll(
        d,
        ('\x1b[4;24;80t'
                '\x1b[6;13;7t'
                '\x1b[8;24;80t'
                '\x1b[48;24;80;312;560t'
                '\x1b[t'
                '\x1b[999t'
                '\x1b[999;1t')
            .codeUnits,
      );

      expect(evs, hasLength(8));

      expect(evs[0], isA<WindowPixelSizeEvent>());
      final px = evs[0] as WindowPixelSizeEvent;
      expect(px.width, 80);
      expect(px.height, 24);

      expect(evs[1], isA<CellSizeEvent>());
      final cell = evs[1] as CellSizeEvent;
      expect(cell.width, 7);
      expect(cell.height, 13);

      expect(evs[2], isA<WindowSizeEvent>());
      final winCells = evs[2] as WindowSizeEvent;
      expect(winCells.width, 80);
      expect(winCells.height, 24);

      expect(evs[3], isA<WindowSizeEvent>());
      final inBandCells = evs[3] as WindowSizeEvent;
      expect(inBandCells.width, 80);
      expect(inBandCells.height, 24);

      expect(evs[4], isA<WindowPixelSizeEvent>());
      final inBandPx = evs[4] as WindowPixelSizeEvent;
      expect(inBandPx.width, 560);
      expect(inBandPx.height, 312);

      expect(evs[5], isA<UnknownCsiEvent>());
      expect((evs[5] as UnknownCsiEvent).value, '\x1b[t');

      expect(evs[6], isA<WindowOpEvent>());
      final op0 = evs[6] as WindowOpEvent;
      expect(op0.op, 999);
      expect(op0.args, isEmpty);

      expect(evs[7], isA<WindowOpEvent>());
      final op1 = evs[7] as WindowOpEvent;
      expect(op1.op, 999);
      expect(op1.args, [1]);
    });
  });
}
