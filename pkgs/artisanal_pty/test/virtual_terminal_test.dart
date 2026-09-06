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
}
