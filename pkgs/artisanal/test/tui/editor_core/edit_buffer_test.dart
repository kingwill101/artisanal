import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('EditBuffer', () {
    test('supports text insertion, deletion, and undo redo', () {
      final buffer = EditBuffer(text: 'abc');

      buffer.setCursorByOffset(3);
      expect(buffer.insertText('d'), isTrue);
      expect(buffer.text, 'abcd');

      expect(buffer.deleteBackward(), isTrue);
      expect(buffer.text, 'abc');
      expect(buffer.canUndo, isTrue);

      expect(buffer.undo(), isTrue);
      expect(buffer.text, 'abcd');

      expect(buffer.undo(), isTrue);
      expect(buffer.text, 'abc');

      expect(buffer.redo(), isTrue);
      expect(buffer.text, 'abcd');
    });

    test('supports replacing text and clearing history with setText', () {
      final buffer = EditBuffer(text: 'alpha');

      expect(buffer.replaceText('beta'), isTrue);
      expect(buffer.text, 'beta');
      expect(buffer.canUndo, isTrue);

      buffer.setText('gamma');
      expect(buffer.text, 'gamma');
      expect(buffer.canUndo, isFalse);
      expect(buffer.cursor, const TextPosition(line: 0, column: 5));
    });

    test('supports committed and rolled back transactions', () {
      final buffer = EditBuffer(text: 'abc');
      buffer.setCursorByOffset(3);

      buffer.beginTransaction();
      expect(buffer.insertText('d'), isTrue);
      expect(buffer.insertText('e'), isTrue);
      buffer.commitTransaction();

      expect(buffer.text, 'abcde');
      expect(buffer.canUndo, isTrue);
      expect(buffer.undo(), isTrue);
      expect(buffer.text, 'abc');

      buffer.beginTransaction();
      expect(buffer.insertText('z'), isTrue);
      buffer.rollbackTransaction();
      expect(buffer.text, 'abc');
      expect(buffer.canUndo, isFalse);
    });

    test('persists and restores journal state', () {
      final buffer = EditBuffer(text: 'abc');
      buffer.setCursorByOffset(3);
      expect(buffer.insertText('d'), isTrue);
      expect(buffer.insertText('e'), isTrue);
      expect(buffer.deleteBackward(), isTrue);

      final journal = buffer.toJournal();
      final restored = EditBuffer.fromJournal(journal);

      expect(restored.text, 'abcd');
      expect(restored.canUndo, isTrue);
      expect(restored.undo(), isTrue);
      expect(restored.text, 'abcde');
      expect(restored.undo(), isTrue);
      expect(restored.text, 'abc');
      expect(restored.redo(), isTrue);
      expect(restored.text, 'abcde');
      expect(restored.redo(), isTrue);
      expect(restored.text, 'abcd');
    });

    test('reads text ranges by offsets and coordinates', () {
      final buffer = EditBuffer(text: 'alpha\nbeta\ngamma');

      expect(buffer.getTextRange(1, 8), 'lpha\nbe');
      expect(buffer.getTextRangeByCoords(0, 2, 1, 2), 'pha\nbe');
    });

    test('deletes coordinate ranges across lines', () {
      final buffer = EditBuffer(text: 'alpha\nbeta\ngamma');

      expect(buffer.deleteRange(0, 2, 1, 2), isTrue);
      expect(buffer.text, 'alta\ngamma');
      expect(buffer.cursor, const TextPosition(line: 0, column: 2));
    });

    test('moves cursor vertically through the configured text view', () {
      final buffer = EditBuffer(
        text: 'hello world\nabc',
        width: 6,
        height: 4,
        softWrap: true,
      );

      buffer.setCursorByOffset('hello '.length);
      expect(buffer.cursor, const TextPosition(line: 0, column: 6));

      expect(buffer.moveCursorDown(), isTrue);
      expect(buffer.cursor, const TextPosition(line: 1, column: 0));

      expect(buffer.moveCursorUp(), isTrue);
      expect(buffer.cursor, const TextPosition(line: 0, column: 6));
    });
  });
}
