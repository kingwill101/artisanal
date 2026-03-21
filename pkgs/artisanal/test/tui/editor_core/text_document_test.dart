import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextDocument', () {
    test('parseLineTexts preserves empty trailing lines', () {
      expect(TextDocument.parseLineTexts(const ['alpha', '', 'beta']), const [
        ['a', 'l', 'p', 'h', 'a'],
        <String>[],
        ['b', 'e', 't', 'a'],
      ]);
    });

    test('parseFlatGraphemes preserves explicit newline boundaries', () {
      expect(
        TextDocument.parseFlatGraphemes(const ['a', '\n', '\n', 'b']),
        const [
          ['a'],
          <String>[],
          ['b'],
        ],
      );
    });

    test(
      'replaceTextRange mutates a single-line span with change metadata',
      () {
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
      },
    );

    test(
      'replaceOffsetRange supports multiline replacement without reparsing text',
      () {
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
      },
    );

    test(
      'replaceOffsetRange deletes across lines and rejoins surrounding text',
      () {
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
      },
    );

    test('lineTexts caches line projections and invalidates after edits', () {
      final document = TextDocument(text: 'alpha\nbeta');

      expect(document.lineTexts, const ['alpha', 'beta']);
      expect(document.lineTexts, same(document.lineTexts));

      document.replaceTextRange(
        startOffset: 6,
        endOffset: 10,
        replacement: 'B',
      );

      expect(document.lineTexts, const ['alpha', 'B']);
    });

    test('line boundary offset helpers expose full-line ranges', () {
      final document = TextDocument(text: 'alpha\nbeta');

      expect(document.lineStartOffset(0), 0);
      expect(document.lineEndOffset(0), 5);
      expect(document.lineEndOffset(0, includeTrailingNewline: true), 6);
      expect(document.lineStartOffset(1), 6);
      expect(document.lineEndOffset(1), 10);
      expect(document.lineStartOffset(2), 10);
      expect(document.lineEndOffset(2), 10);
    });

    test('text range helpers read direct slices without flattening first', () {
      final document = TextDocument(text: 'alpha\nbeta\ngamma');

      expect(document.textInRange(startOffset: 2, endOffset: 9), 'pha\nbet');
      expect(
        document.textBetweenLines(startLine: 1, endLine: 3),
        'beta\ngamma',
      );
    });

    test('revision is preserved on copies and increments on edits', () {
      final document = TextDocument(text: 'alpha');
      final copy = document.copy();

      expect(document.revision, 0);
      expect(copy.revision, 0);

      document.replaceTextRange(startOffset: 5, endOffset: 5, replacement: '!');

      expect(document.revision, 1);
      expect(copy.revision, 0);
    });

    test(
      'replaceLineTextRange rewrites only the targeted line window with change metadata',
      () {
      final document = TextDocument(text: 'alpha\nbeta\ngamma\ndelta');

      final change = document.replaceLineTextRange(
        startLine: 1,
        endLine: 3,
        replacementLineTexts: const ['bravo', 'charlie'],
      );

      expect(document.lineTexts, const ['alpha', 'bravo', 'charlie', 'delta']);
      expect(document.text, 'alpha\nbravo\ncharlie\ndelta');
      expect(change.startOffset, 6);
      expect(change.oldEndOffset, 17);
      expect(change.newEndOffset, 20);
      expect(change.startPosition, const TextPosition(line: 1, column: 0));
      expect(change.oldEndPosition, const TextPosition(line: 3, column: 0));
      expect(change.newEndPosition, const TextPosition(line: 3, column: 0));
    });

    test('replaceLineTextRange can delete lines down to one empty line', () {
      final document = TextDocument(text: 'alpha');

      final change = document.replaceLineTextRange(
        startLine: 0,
        endLine: 1,
        replacementLineTexts: const <String>[],
      );

      expect(document.lineTexts, const ['']);
      expect(document.text, '');
      expect(document.lineCount, 1);
      expect(document.length, 0);
      expect(change.startOffset, 0);
      expect(change.oldEndOffset, 5);
      expect(change.newEndOffset, 0);
    });

    test('chained range edits keep composite line reads and offsets coherent', () {
      final document = TextDocument(text: 'zero\none\ntwo\nthree');

      document.replaceLineTextRange(
        startLine: 1,
        endLine: 2,
        replacementLineTexts: const ['ONE'],
      );
      document.replaceTextRange(
        startOffset: document.lineStartOffset(2),
        endOffset: document.lineEndOffset(2),
        replacement: 'TWO',
      );

      expect(document.lineAt(0), 'zero');
      expect(document.lineAt(1), 'ONE');
      expect(document.lineAt(2), 'TWO');
      expect(document.lineAt(3), 'three');
      expect(document.text, 'zero\nONE\nTWO\nthree');
      expect(document.textBetweenLines(startLine: 1, endLine: 3), 'ONE\nTWO');
      expect(document.lineStartOffset(2), 9);
      expect(document.lineEndOffset(2), 12);
    });

    test('repeated edits normalize storage depth back to a flat composite', () {
      final document = TextDocument(text: 'zero\none\ntwo\nthree');

      for (var index = 0; index < 8; index++) {
        document.replaceLineTextRange(
          startLine: 1,
          endLine: 2,
          replacementLineTexts: ['ONE$index'],
        );
        document.replaceTextRange(
          startOffset: document.lineStartOffset(2),
          endOffset: document.lineEndOffset(2),
          replacement: 'TWO$index',
        );
      }

      expect(document.debugStorageDepth, lessThanOrEqualTo(2));
      expect(document.lineAt(0), 'zero');
      expect(document.lineAt(1), 'ONE7');
      expect(document.lineAt(2), 'TWO7');
      expect(document.lineAt(3), 'three');
      expect(document.text, 'zero\nONE7\nTWO7\nthree');
    });
  });
}
