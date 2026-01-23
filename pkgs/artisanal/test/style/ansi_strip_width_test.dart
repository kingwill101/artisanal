import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  group('ANSI stripping + width', () {
    test('Layout.stripAnsi removes OSC 8 hyperlinks (ST terminated)', () {
      const s = '\x1b]8;;https://example.com\x1b\\Hello\x1b]8;;\x1b\\';
      expect(Layout.stripAnsi(s), equals('Hello'));
    });

    test('Layout.visibleLength ignores OSC 8 hyperlinks', () {
      const s = '\x1b]8;;https://example.com\x1b\\Hello\x1b]8;;\x1b\\';
      expect(Layout.visibleLength(s), equals(5));
    });

    test('Layout.visibleLength ignores non-SGR CSI sequences', () {
      const s = '\x1b[2CHi\x1b[1D!';
      expect(Layout.visibleLength(s), equals(3));
      expect(Layout.stripAnsi(s), equals('Hi!'));
    });

    test('Style.stripAnsi removes OSC 8 hyperlinks (BEL terminated)', () {
      const s = '\x1b]8;;https://example.com\x07Hello\x1b]8;;\x07';
      expect(Style.stripAnsi(s), equals('Hello'));
    });

    test('Style.visibleLength ignores OSC 8 hyperlinks', () {
      const s = '\x1b]8;;https://example.com\x07Hello\x1b]8;;\x07';
      expect(Style.visibleLength(s), equals(5));
    });

    test('Layout.stripAnsi removes APC/PM/SOS (ST terminated)', () {
      const s =
          '\x1b_ignored apc\x1b\\'
          '\x1b^ignored pm\x1b\\'
          '\x1bXignored sos\x1b\\'
          'Hello';
      expect(Layout.stripAnsi(s), equals('Hello'));
      expect(Layout.visibleLength(s), equals(5));
    });

    test('Layout.visibleLength ignores 8-bit CSI sequences', () {
      const s = '\x9b2CHi\x9b1D!';
      expect(Layout.stripAnsi(s), equals('Hi!'));
      expect(Layout.visibleLength(s), equals(3));
    });

    test('Style.stripAnsi removes 8-bit OSC sequences (ST terminated)', () {
      const s = '\x9d8;;https://example.com\x9cHello\x9d8;;\x9c';
      expect(Style.stripAnsi(s), equals('Hello'));
      expect(Style.visibleLength(s), equals(5));
    });
  });
}
