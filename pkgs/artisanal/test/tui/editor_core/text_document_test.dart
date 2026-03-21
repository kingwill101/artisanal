import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextDocument', () {
    test('replaceTextRange mutates a single-line span with change metadata', () {
      final document = TextDocument(text: 'alpha beta');

      final change = document.replaceTextRange(
        startOffset: 6,
        endOffset: 10,
        replacement: 'gamma',
      );

      expect(document.text, 'alpha gamma');
      expect(change.startOffset, 6);
      expect(change.oldEndOffset, 10);
      expect(change.newEndOffset, 11);
      expect(change.startPosition, const TextPosition(line: 0, column: 6));
      expect(change.oldEndPosition, const TextPosition(line: 0, column: 10));
      expect(change.newEndPosition, const TextPosition(line: 0, column: 11));
    });

    test('replaceOffsetRange supports multiline replacement without reparsing text', () {
      final document = TextDocument(text: 'ab\ncdef\ngh');

      final change = document.replaceOffsetRange(
        startOffset: 1,
        endOffset: 7,
        replacement: const ['X', '\n', 'Y', 'Z'],
      );

      expect(document.text, 'aX\nYZ\ngh');
      expect(document.lines, const [
        ['a', 'X'],
        ['Y', 'Z'],
        ['g', 'h'],
      ]);
      expect(change.startOffset, 1);
      expect(change.oldEndOffset, 7);
      expect(change.newEndOffset, 5);
      expect(change.startPosition, const TextPosition(line: 0, column: 1));
      expect(change.oldEndPosition, const TextPosition(line: 1, column: 4));
      expect(change.newEndPosition, const TextPosition(line: 1, column: 2));
    });

    test('replaceOffsetRange deletes across lines and rejoins surrounding text', () {
      final document = TextDocument(text: 'hello\nworld\n!');

      final change = document.replaceOffsetRange(
        startOffset: 3,
        endOffset: 12,
      );

      expect(document.text, 'hel!');
      expect(document.lines, const [
        ['h', 'e', 'l', '!'],
      ]);
      expect(change.startOffset, 3);
      expect(change.oldEndOffset, 12);
      expect(change.newEndOffset, 3);
      expect(change.startPosition, const TextPosition(line: 0, column: 3));
      expect(change.oldEndPosition, const TextPosition(line: 2, column: 0));
      expect(change.newEndPosition, const TextPosition(line: 0, column: 3));
    });
  });
}
