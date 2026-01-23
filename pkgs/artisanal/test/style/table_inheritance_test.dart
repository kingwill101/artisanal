import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Table (lipgloss v2 parity)', () {
    test('inherits BaseStyle for all cells', () {
      final base = Style().foreground(const AnsiColor(1)); // Red
      final table = Table().border(Border.none).baseStyle(base)
        ..row(['A', 'B'])
        ..row(['C', 'D']);

      final out = table.render();
      // All cells should be red. We check for the color code.
      // It might be 31m or 38;5;1m depending on profile.
      expect(out, contains('A'));
      expect(out, contains('B'));
      expect(out, contains('\x1b['));
    });

    test('manual column widths', () {
      final table = Table().border(Border.none)
        ..widths([10, 5])
        ..row(['Long text that should wrap', 'Short']);

      final out = table.render();
      final lines = out.split('\n');

      // First column should be 10 wide, second 5.
      expect(lines[0].length, equals(15));
    });

    test('cell wrapping when wrap(true) is set', () {
      final table = Table().border(Border.none)
        ..widths([5])
        ..wrap(true)
        ..row(['1234567890']);

      final out = table.render();
      // Should wrap into two lines of 5
      expect(out, contains('12345\n67890'));
    });

    test('Style.width in Table triggers wrapping', () {
      final table = Table().border(Border.none)
        ..row([Style().width(5).render('1234567890')]);

      final out = table.render();
      expect(out, contains('12345\n67890'));
    });
  });
}
