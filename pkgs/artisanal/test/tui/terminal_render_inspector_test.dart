import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('TerminalRenderFrame', () {
    test('parses plain content into visible lines', () {
      final frame = TerminalRenderFrame.parse('hello\nworld');

      expect(frame.lines, hasLength(2));
      expect(frame.lines[0].plainText, equals('hello'));
      expect(frame.lines[1].plainText, equals('world'));
      expect(frame.lines[0].visibleWidth, equals(5));
      expect(frame.plainText, equals('hello\nworld'));
    });

    test('carries ANSI state across line boundaries', () {
      const content = '\x1b[31mred\ncarry';
      final frame = TerminalRenderFrame.parse(content);

      expect(frame.lines, hasLength(2));
      expect(frame.lines[0].statePrefix, isEmpty);
      expect(frame.lines[1].statePrefix, contains('[31m'));
      expect(frame.lines[1].rendered, contains('carry'));
      expect(frame.lines[1].plainText, equals('carry'));
      expect(frame.lines[1].visibleWidth, equals(5));
    });

    test('tracks hyperlink state prefixes for following lines', () {
      const open = '\x1b]8;;https://example.com\x07';
      const close = '\x1b]8;;\x07';
      final frame = TerminalRenderFrame.parse('${open}link\ncarry$close');

      expect(frame.lines, hasLength(2));
      expect(frame.lines[1].statePrefix, contains('https://example.com'));
      expect(frame.lines[1].plainText, equals('carry'));
    });

    test('can inspect View objects directly', () {
      final frame = TerminalRenderFrame.inspect(
        const View(content: 'status: ok'),
      );

      expect(frame.lines.single.plainText, equals('status: ok'));
      expect(frame.content, equals('status: ok'));
    });

    test('empty content still yields a single empty line', () {
      final frame = TerminalRenderFrame.parse('');

      expect(frame.lines, hasLength(1));
      expect(frame.lines.single.plainText, isEmpty);
      expect(frame.lines.single.visibleWidth, equals(0));
    });
  });
}
