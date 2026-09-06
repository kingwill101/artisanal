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
  });
}
