import 'package:artisanal/runtime.dart' show MouseAction, MouseButton, MouseMsg;
import 'package:artisanal/terminal.dart';
import 'package:artisanal_pty/artisanal_pty.dart';
import 'package:test/test.dart';

void main() {
  test('interprets cursor movement and erase sequences', () {
    final terminal = VirtualTerminal(width: 5, height: 2);
    terminal.writeText('hello\x1b[2J\x1b[2;2HX');

    expect(terminal.render(), '     \n X   ');
  });

  test('scrolls at the bottom of the screen', () {
    final terminal = VirtualTerminal(width: 3, height: 2);
    terminal.writeText('one\r\ntwo\r\nend');

    expect(terminal.render(), 'two\nend');
  });

  test('retains and navigates primary-screen scrollback', () {
    final terminal = VirtualTerminal(width: 5, height: 2);
    terminal.writeText('a\r\nb\r\nc');

    expect(terminal.scrollbackLength, 1);
    expect(terminal.render(), 'b    \nc    ');
    expect(terminal.scrollBy(1), isTrue);
    expect(terminal.render(), 'a    \nb    ');
    expect(terminal.scrollToBottom(), isTrue);
    expect(terminal.render(), 'b    \nc    ');
  });

  test('encodes keys for a PTY', () {
    expect(TerminalInputEncoder.encode(const Key(KeyType.up)), '\x1b[A');
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.runes, runes: [99], ctrl: true),
      ),
      '\x03',
    );
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.runes, runes: [32], ctrl: true),
      ),
      '\x00',
    );
    expect(TerminalInputEncoder.encode(const Key(KeyType.space)), ' ');
  });

  test('preserves split UTF-8 characters and consumes OSC strings', () {
    final terminal = VirtualTerminal(width: 5, height: 1);
    terminal.write([0xc3]);
    terminal.write([0xa9]);
    terminal.writeText('\x1b]0;title\x07x');

    expect(terminal.render(), startsWith('éx'));
  });

  test('preserves cumulative styles and wide character cell width', () {
    final terminal = VirtualTerminal(width: 4, height: 1);
    terminal.writeText('\x1b[31mA\x1b[1m界B');

    expect(terminal.cursorX, 4);
    expect(terminal.render(), contains('\x1b[31m\x1b[1m界'));
  });

  test('renders the emulated cursor and respects visibility mode', () {
    final terminal = VirtualTerminal(width: 2, height: 1);

    expect(terminal.render(showCursor: true), '\x1b[7m \x1b[27m ');
    terminal.writeText('\x1b[?25l');
    expect(terminal.render(showCursor: true), '  ');
  });

  test('tracks application cursor mode for input encoding', () {
    final terminal = VirtualTerminal();

    terminal.writeText('\x1b[?1h');
    expect(terminal.applicationCursorKeys, isTrue);
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.up),
        applicationCursorKeys: terminal.applicationCursorKeys,
      ),
      '\x1bOA',
    );

    terminal.writeText('\x1b[?1l');
    expect(terminal.applicationCursorKeys, isFalse);
  });

  test('answers device status and cursor position reports', () {
    final terminal = VirtualTerminal(width: 20, height: 5);
    terminal.writeText('abc\x1b[5n\x1b[6n');

    expect(terminal.takePendingResponses(), '\x1b[0n\x1b[1;4R');
    expect(terminal.takePendingResponses(), isEmpty);
  });

  test('uses and restores the alternate screen buffer', () {
    final terminal = VirtualTerminal(width: 8, height: 2);
    terminal.writeText('primary\x1b[>1u');

    terminal.writeText('\x1b[?1049halt');
    expect(terminal.alternateScreen, isTrue);
    expect(terminal.keyboardEnhancementFlags, 0);
    expect(terminal.render(), startsWith('alt'));
    expect(terminal.render(), isNot(contains('primary')));

    terminal.writeText('\x1b[>13u');
    terminal.writeText('\x1b[?1049l');
    expect(terminal.alternateScreen, isFalse);
    expect(terminal.keyboardEnhancementFlags, 1);
    expect(terminal.render(), startsWith('primary'));
  });

  test('tracks Kitty keyboard enhancement flags as a stack', () {
    final terminal = VirtualTerminal();
    terminal.writeText('\x1b[>13;1u');

    expect(terminal.keyboardEnhancementFlags, 9);
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.down),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      '\x1b[B',
    );
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.runes, runes: [0x63], ctrl: true),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      '\x1b[99;5u',
    );

    terminal.writeText('\x1b[<1u');
    expect(terminal.keyboardEnhancementFlags, 0);

    terminal.writeText('\x1b[=1;1u\x1b[?u');
    expect(terminal.keyboardEnhancementFlags, 1);
    expect(terminal.takePendingResponses(), '\x1b[?1u');
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.runes, runes: [0x69], ctrl: true),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      '\x1b[105;5u',
    );
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.runes, runes: [0x69]),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      'i',
    );
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.space),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      ' ',
    );
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.space, ctrl: true),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      '\x1b[32;5u',
    );

    terminal.writeText('\x1b[=2;2u');
    expect(terminal.keyboardEnhancementFlags, 3);
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.enter, isRelease: true),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      isEmpty,
    );
    expect(
      TerminalInputEncoder.encode(
        const Key(KeyType.up, isRepeat: true),
        keyboardEnhancementFlags: terminal.keyboardEnhancementFlags,
      ),
      '\x1b[1;1:2A',
    );

    terminal.writeText('\x1b[=31;1u\x1b[?u');
    expect(terminal.keyboardEnhancementFlags, 11);
    expect(terminal.takePendingResponses(), '\x1b[?11u');
  });

  test('tracks and encodes SGR mouse reporting', () {
    final terminal = VirtualTerminal();
    terminal.writeText('\x1b[?1000h\x1b[?1002h\x1b[?1006h');

    expect(terminal.mouseTracking, TerminalMouseTracking.drag);
    expect(terminal.sgrMouseCoordinates, isTrue);
    expect(
      TerminalInputEncoder.encodeMouse(
        const MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 0,
          y: 0,
        ),
        x: 4,
        y: 2,
        tracking: terminal.mouseTracking,
        sgrCoordinates: terminal.sgrMouseCoordinates,
        urxvtCoordinates: terminal.urxvtMouseCoordinates,
      ),
      '\x1b[<0;5;3M',
    );
  });
}
