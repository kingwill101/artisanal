import 'dart:math' as math;

import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity (scoped):
// - `third_party/ultraviolet/key_test.go` (TestSplitSequences)

void _expectEvent(Event actual, Event expected, {required String reason}) {
  expect(actual.runtimeType, expected.runtimeType, reason: reason);

  switch ((actual, expected)) {
    case (KeyPressEvent(), KeyPressEvent()):
      expect(
        (actual as KeyPressEvent).key(),
        (expected as KeyPressEvent).key(),
        reason: reason,
      );
    case (UnknownEvent(value: final v), UnknownEvent(value: final exp)):
      expect(v, exp, reason: reason);
    case (UnknownDcsEvent(value: final v), UnknownDcsEvent(value: final exp)):
      expect(v, exp, reason: reason);
    case (UnknownApcEvent(value: final v), UnknownApcEvent(value: final exp)):
      expect(v, exp, reason: reason);
    case (
      ForegroundColorEvent(color: final c),
      ForegroundColorEvent(color: final exp),
    ):
      expect(c, exp, reason: reason);
    case (
      BackgroundColorEvent(color: final c),
      BackgroundColorEvent(color: final exp),
    ):
      expect(c, exp, reason: reason);
    case (CursorColorEvent(color: final c), CursorColorEvent(color: final exp)):
      expect(c, exp, reason: reason);
    default:
      fail('unhandled event pair: ($actual, $expected) [$reason]');
  }
}

List<Event> _streamChunks(
  List<List<int>> chunks, {
  int limit = 32,
  bool timeoutAfterFirstRead = false,
}) {
  final parser = UvEventStreamParser();
  final out = <Event>[];

  var readIndex = 0;
  for (final chunk in chunks) {
    for (var i = 0; i < chunk.length; i += limit) {
      final slice = chunk.sublist(i, math.min(i + limit, chunk.length));
      out.addAll(parser.parseAll(slice, expired: false));
      readIndex++;
      if (timeoutAfterFirstRead && readIndex == 1) {
        out.addAll(parser.parseAll(const [], expired: true));
      }
    }
  }

  out.addAll(parser.flush());
  return out;
}

void main() {
  group('UV TerminalReader parity (split sequences)', () {
    test('string-terminated sequences split across reads', () {
      final a250 = ''.padRight(250, 'a');

      final tests =
          <
            ({
              String name,
              List<List<int>> chunks,
              List<Event> expected,
              int limit,
              bool timeout,
            })
          >[
            (
              name: 'OSC 11 background color with ST terminator',
              chunks: [
                '\x1b]11;rgb:1a1a/1b1b/2c2c'.codeUnits,
                '\x1b\\'.codeUnits,
              ],
              expected: const [BackgroundColorEvent(UvRgb(26, 27, 44))],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'OSC 11 background color with BEL terminator',
              chunks: [
                '\x1b]11;rgb:1a1a/1b1b/2c2c'.codeUnits,
                '\x07'.codeUnits,
              ],
              expected: const [BackgroundColorEvent(UvRgb(26, 27, 44))],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'OSC 10 foreground color split',
              chunks: [
                '\x1b]10;rgb:ffff/0000/'.codeUnits,
                '0000\x1b\\'.codeUnits,
              ],
              expected: const [ForegroundColorEvent(UvRgb(255, 0, 0))],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'OSC 12 cursor color split',
              chunks: [
                '\x1b]12;rgb:'.codeUnits,
                '8080/8080/8080\x07'.codeUnits,
              ],
              expected: const [CursorColorEvent(UvRgb(128, 128, 128))],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'DCS sequence split',
              chunks: ['\x1bP1\$r'.codeUnits, 'test\x1b\\'.codeUnits],
              expected: const [UnknownDcsEvent('\x1bP1\$rtest\x1b\\')],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'long DCS sequence split',
              chunks: [
                '\x1bP1\$r${a250}abcdef'.codeUnits,
                'test\x1b\\'.codeUnits,
              ],
              expected: [UnknownDcsEvent('\x1bP1\$r${a250}abcdeftest\x1b\\')],
              limit: 256,
              timeout: false,
            ),
            (
              name: 'APC sequence split',
              chunks: ['\x1b_T'.codeUnits, 'test\x1b\\'.codeUnits],
              expected: const [UnknownApcEvent('\x1b_Ttest\x1b\\')],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'Multiple chunks OSC',
              chunks: [
                '\x1b]11;'.codeUnits,
                'rgb:1234/'.codeUnits,
                '5678/9abc\x07'.codeUnits,
              ],
              expected: const [BackgroundColorEvent(UvRgb(18, 86, 154))],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'OSC followed by regular key',
              chunks: [
                '\x1b]11;rgb:1111/2222/3333'.codeUnits,
                '\x07a'.codeUnits,
              ],
              expected: const [
                BackgroundColorEvent(UvRgb(17, 34, 51)),
                KeyPressEvent(Key(code: 0x61 /* a */, text: 'a')),
              ],
              limit: 32,
              timeout: false,
            ),
            (
              name: 'unknown sequence after timeout',
              chunks: [
                '\x1b]11;rgb:1111/2222/3333'.codeUnits,
                'abc'.codeUnits,
                'x'.codeUnits,
                'x'.codeUnits,
                'x'.codeUnits,
                'x'.codeUnits,
              ],
              expected: const [
                UnknownEvent('\x1b]11;rgb:1111/2222/3333'),
                KeyPressEvent(Key(code: 0x61 /* a */, text: 'a')),
                KeyPressEvent(Key(code: 0x62 /* b */, text: 'b')),
                KeyPressEvent(Key(code: 0x63 /* c */, text: 'c')),
                KeyPressEvent(Key(code: 0x78 /* x */, text: 'x')),
                KeyPressEvent(Key(code: 0x78 /* x */, text: 'x')),
                KeyPressEvent(Key(code: 0x78 /* x */, text: 'x')),
                KeyPressEvent(Key(code: 0x78 /* x */, text: 'x')),
              ],
              limit: 32,
              timeout: true,
            ),
            (
              name: 'multiple broken down sequences',
              chunks: [
                '\x1b[B'.codeUnits,
                '\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B'
                    .codeUnits,
                '\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b['
                    .codeUnits,
                'B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b'
                    .codeUnits,
                '[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B\x1b[B'
                    .codeUnits,
              ],
              expected: List<Event>.generate(
                43,
                (_) => const KeyPressEvent(Key(code: keyDown)),
                growable: false,
              ),
              limit: 32,
              timeout: false,
            ),
          ];

      for (final tc in tests) {
        final events = _streamChunks(
          tc.chunks,
          limit: tc.limit,
          timeoutAfterFirstRead: tc.timeout,
        );

        expect(events, hasLength(tc.expected.length), reason: tc.name);
        for (var i = 0; i < tc.expected.length; i++) {
          _expectEvent(events[i], tc.expected[i], reason: '${tc.name} [$i]');
        }
      }
    });
  });
}
