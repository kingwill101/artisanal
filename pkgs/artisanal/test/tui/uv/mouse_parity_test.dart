import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

Event _decodeOne(EventDecoder d, List<int> bytes) {
  final (n, ev) = d.decode(bytes, allowIncompleteEsc: true);
  expect(n, bytes.length, reason: 'decoder did not consume full sequence');
  expect(ev, isNotNull);
  return ev!;
}

Mouse _mouseOf(Event ev) => switch (ev) {
  MouseClickEvent() => (ev).mouse(),
  MouseReleaseEvent() => (ev).mouse(),
  MouseWheelEvent() => (ev).mouse(),
  MouseMotionEvent() => (ev).mouse(),
  _ => throw StateError('expected MouseEvent, got $ev'),
};

void main() {
  group('UV parity: MouseEvent String()', () {
    test('string formatting matches upstream', () {
      final tt = <({String name, Event event, String expected})>[
        (
          name: 'unknown',
          event: MouseClickEvent(const Mouse(x: 0, y: 0, button: 0xff)),
          expected: 'unknown',
        ),
        (
          name: 'left',
          event: MouseClickEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.left),
          ),
          expected: 'left',
        ),
        (
          name: 'right',
          event: MouseClickEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.right),
          ),
          expected: 'right',
        ),
        (
          name: 'middle',
          event: MouseClickEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.middle),
          ),
          expected: 'middle',
        ),
        (
          name: 'release',
          event: MouseReleaseEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.none),
          ),
          expected: '',
        ),
        (
          name: 'wheelup',
          event: MouseWheelEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.wheelUp),
          ),
          expected: 'wheelup',
        ),
        (
          name: 'wheeldown',
          event: MouseWheelEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.wheelDown),
          ),
          expected: 'wheeldown',
        ),
        (
          name: 'wheelleft',
          event: MouseWheelEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.wheelLeft),
          ),
          expected: 'wheelleft',
        ),
        (
          name: 'wheelright',
          event: MouseWheelEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.wheelRight),
          ),
          expected: 'wheelright',
        ),
        (
          name: 'motion',
          event: MouseMotionEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.none),
          ),
          expected: 'motion',
        ),
        (
          name: 'shift+left',
          event: MouseReleaseEvent(
            const Mouse(
              x: 0,
              y: 0,
              button: MouseButton.left,
              mod: KeyMod.shift,
            ),
          ),
          expected: 'shift+left',
        ),
        (
          name: 'shift+left click',
          event: MouseClickEvent(
            const Mouse(
              x: 0,
              y: 0,
              button: MouseButton.left,
              mod: KeyMod.shift,
            ),
          ),
          expected: 'shift+left',
        ),
        (
          name: 'ctrl+shift+left',
          event: MouseClickEvent(
            const Mouse(
              x: 0,
              y: 0,
              button: MouseButton.left,
              mod: KeyMod.ctrl | KeyMod.shift,
            ),
          ),
          expected: 'ctrl+shift+left',
        ),
        (
          name: 'alt+left',
          event: MouseClickEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.left, mod: KeyMod.alt),
          ),
          expected: 'alt+left',
        ),
        (
          name: 'ctrl+left',
          event: MouseClickEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.left, mod: KeyMod.ctrl),
          ),
          expected: 'ctrl+left',
        ),
        (
          name: 'ctrl+alt+left',
          event: MouseClickEvent(
            const Mouse(
              x: 0,
              y: 0,
              button: MouseButton.left,
              mod: KeyMod.alt | KeyMod.ctrl,
            ),
          ),
          expected: 'ctrl+alt+left',
        ),
        (
          name: 'ctrl+alt+shift+left',
          event: MouseClickEvent(
            const Mouse(
              x: 0,
              y: 0,
              button: MouseButton.left,
              mod: KeyMod.alt | KeyMod.ctrl | KeyMod.shift,
            ),
          ),
          expected: 'ctrl+alt+shift+left',
        ),
        (
          name: 'ignore coordinates',
          event: MouseClickEvent(
            const Mouse(x: 100, y: 200, button: MouseButton.left),
          ),
          expected: 'left',
        ),
        (
          name: 'broken type',
          event: MouseClickEvent(const Mouse(x: 0, y: 0, button: 120)),
          expected: 'unknown',
        ),
      ];

      for (final tc in tt) {
        expect(tc.event.toString(), tc.expected, reason: tc.name);
      }
    });
  });

  group('UV parity: parse X10 mouse events', () {
    test('X10 mouse table', () {
      List<int> encode(int b, int x, int y) => <int>[
        0x1b,
        0x5b,
        0x4d,
        (32 + b) & 0xff,
        (x + 32 + 1) & 0xff,
        (y + 32 + 1) & 0xff,
      ];

      final tt = <({String name, List<int> buf, Event expected})>[
        (
          name: 'zero position',
          buf: encode(0x00, 0, 0),
          expected: MouseClickEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.left),
          ),
        ),
        (
          name: 'max position',
          buf: encode(0x00, 222, 222),
          expected: MouseClickEvent(
            const Mouse(x: 222, y: 222, button: MouseButton.left),
          ),
        ),
        (
          name: 'left',
          buf: encode(0x00, 32, 16),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.left),
          ),
        ),
        (
          name: 'left in motion',
          buf: encode(0x20, 32, 16),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.left),
          ),
        ),
        (
          name: 'middle',
          buf: encode(0x01, 32, 16),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.middle),
          ),
        ),
        (
          name: 'middle in motion',
          buf: encode(0x21, 32, 16),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.middle),
          ),
        ),
        (
          name: 'right',
          buf: encode(0x02, 32, 16),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.right),
          ),
        ),
        (
          name: 'right in motion',
          buf: encode(0x22, 32, 16),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.right),
          ),
        ),
        (
          name: 'motion',
          buf: encode(0x23, 32, 16),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.none),
          ),
        ),
        (
          name: 'wheel up',
          buf: encode(0x40, 32, 16),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelUp),
          ),
        ),
        (
          name: 'wheel down',
          buf: encode(0x41, 32, 16),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelDown),
          ),
        ),
        (
          name: 'wheel left',
          buf: encode(0x42, 32, 16),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelLeft),
          ),
        ),
        (
          name: 'wheel right',
          buf: encode(0x43, 32, 16),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelRight),
          ),
        ),
        (
          name: 'release',
          buf: encode(0x03, 32, 16),
          expected: MouseReleaseEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.none),
          ),
        ),
        (
          name: 'backward',
          buf: encode(0x80, 32, 16),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.backward),
          ),
        ),
        (
          name: 'forward',
          buf: encode(0x81, 32, 16),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.forward),
          ),
        ),
        (
          name: 'button 10',
          buf: encode(0x82, 32, 16),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.button10),
          ),
        ),
        (
          name: 'button 11',
          buf: encode(0x83, 32, 16),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.button11),
          ),
        ),
        (
          name: 'alt+right',
          buf: encode(0x0a, 32, 16),
          expected: MouseClickEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.alt,
            ),
          ),
        ),
        (
          name: 'ctrl+right',
          buf: encode(0x12, 32, 16),
          expected: MouseClickEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'alt+right in motion',
          buf: encode(0x2a, 32, 16),
          expected: MouseMotionEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.alt,
            ),
          ),
        ),
        (
          name: 'ctrl+right in motion',
          buf: encode(0x32, 32, 16),
          expected: MouseMotionEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'ctrl+alt+right',
          buf: encode(0x1a, 32, 16),
          expected: MouseClickEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.alt | KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'ctrl+wheel up',
          buf: encode(0x50, 32, 16),
          expected: MouseWheelEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.wheelUp,
              mod: KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'alt+wheel down',
          buf: encode(0x49, 32, 16),
          expected: MouseWheelEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.wheelDown,
              mod: KeyMod.alt,
            ),
          ),
        ),
        (
          name: 'ctrl+alt+wheel down',
          buf: encode(0x59, 32, 16),
          expected: MouseWheelEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.wheelDown,
              mod: KeyMod.alt | KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'overflow position',
          buf: encode(0x20, 250, 223),
          expected: MouseMotionEvent(
            const Mouse(x: -6, y: -33, button: MouseButton.left),
          ),
        ),
      ];

      final d = EventDecoder();
      for (final tc in tt) {
        final ev = _decodeOne(d, tc.buf);
        expect(ev.runtimeType, tc.expected.runtimeType, reason: tc.name);
        expect(_mouseOf(ev), _mouseOf(tc.expected), reason: tc.name);
      }
    });
  });

  group('UV parity: parse SGR mouse events', () {
    test('SGR mouse table', () {
      String encode(int b, int x, int y, bool release) =>
          '\x1b[<$b;${x + 1};${y + 1}${release ? 'm' : 'M'}';

      final tt = <({String name, String seq, Event expected})>[
        (
          name: 'zero position',
          seq: encode(0, 0, 0, false),
          expected: MouseClickEvent(
            const Mouse(x: 0, y: 0, button: MouseButton.left),
          ),
        ),
        (
          name: '225 position',
          seq: encode(0, 225, 225, false),
          expected: MouseClickEvent(
            const Mouse(x: 225, y: 225, button: MouseButton.left),
          ),
        ),
        (
          name: 'left',
          seq: encode(0, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.left),
          ),
        ),
        (
          name: 'left in motion',
          seq: encode(32, 32, 16, false),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.left),
          ),
        ),
        (
          name: 'left release',
          seq: encode(0, 32, 16, true),
          expected: MouseReleaseEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.left),
          ),
        ),
        (
          name: 'middle',
          seq: encode(1, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.middle),
          ),
        ),
        (
          name: 'middle in motion',
          seq: encode(33, 32, 16, false),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.middle),
          ),
        ),
        (
          name: 'middle release',
          seq: encode(1, 32, 16, true),
          expected: MouseReleaseEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.middle),
          ),
        ),
        (
          name: 'right',
          seq: encode(2, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.right),
          ),
        ),
        (
          name: 'right release',
          seq: encode(2, 32, 16, true),
          expected: MouseReleaseEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.right),
          ),
        ),
        (
          name: 'motion',
          seq: encode(35, 32, 16, false),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.none),
          ),
        ),
        (
          name: 'wheel up',
          seq: encode(64, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelUp),
          ),
        ),
        (
          name: 'wheel down',
          seq: encode(65, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelDown),
          ),
        ),
        (
          name: 'wheel left',
          seq: encode(66, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelLeft),
          ),
        ),
        (
          name: 'wheel right',
          seq: encode(67, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.wheelRight),
          ),
        ),
        (
          name: 'backward',
          seq: encode(128, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.backward),
          ),
        ),
        (
          name: 'backward in motion',
          seq: encode(160, 32, 16, false),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.backward),
          ),
        ),
        (
          name: 'forward',
          seq: encode(129, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.forward),
          ),
        ),
        (
          name: 'forward in motion',
          seq: encode(161, 32, 16, false),
          expected: MouseMotionEvent(
            const Mouse(x: 32, y: 16, button: MouseButton.forward),
          ),
        ),
        (
          name: 'alt+right',
          seq: encode(10, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.alt,
            ),
          ),
        ),
        (
          name: 'ctrl+right',
          seq: encode(18, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'ctrl+alt+right',
          seq: encode(26, 32, 16, false),
          expected: MouseClickEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.right,
              mod: KeyMod.alt | KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'alt+wheel',
          seq: encode(73, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.wheelDown,
              mod: KeyMod.alt,
            ),
          ),
        ),
        (
          name: 'ctrl+wheel',
          seq: encode(81, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.wheelDown,
              mod: KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'ctrl+alt+wheel',
          seq: encode(89, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.wheelDown,
              mod: KeyMod.alt | KeyMod.ctrl,
            ),
          ),
        ),
        (
          name: 'ctrl+alt+shift+wheel',
          seq: encode(93, 32, 16, false),
          expected: MouseWheelEvent(
            const Mouse(
              x: 32,
              y: 16,
              button: MouseButton.wheelDown,
              mod: KeyMod.alt | KeyMod.shift | KeyMod.ctrl,
            ),
          ),
        ),
      ];

      final d = EventDecoder();
      for (final tc in tt) {
        final ev = _decodeOne(d, tc.seq.codeUnits);
        expect(ev.runtimeType, tc.expected.runtimeType, reason: tc.name);
        expect(_mouseOf(ev), _mouseOf(tc.expected), reason: tc.name);
      }
    });
  });
}
