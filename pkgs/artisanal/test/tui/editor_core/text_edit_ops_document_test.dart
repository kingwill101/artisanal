import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextDocumentEditOps', () {
    test(
      'replaceDocumentRange mutates the document and reports change metadata',
      () {
        final document = TextDocument(text: 'alpha beta');

        final result = replaceDocumentRange(
          document,
          start: 6,
          end: 10,
          replacement: 'gamma'.split(''),
        );

        expect(document.text, 'alpha gamma');
        expect(result.cursorOffset, 11);
        expect(result.changed, isTrue);
        expect(result.change.startOffset, 6);
        expect(result.change.oldEndOffset, 10);
        expect(result.change.newEndOffset, 11);
      },
    );

    test(
      'insertIntoDocument inserts at the cursor without flattening first',
      () {
        final document = TextDocument(text: 'ab\ncd');

        final result = insertIntoDocument(document, 3, const ['X', 'Y']);

        expect(document.text, 'ab\nXYcd');
        expect(result.cursorOffset, 5);
        expect(
          result.change.startPosition,
          const TextPosition(line: 1, column: 0),
        );
        expect(
          result.change.newEndPosition,
          const TextPosition(line: 1, column: 2),
        );
      },
    );

    test(
      'replaceDocumentTextRange mutates the document through the string path',
      () {
        final document = TextDocument(text: 'alpha beta');

        final result = replaceDocumentTextRange(
          document,
          start: 6,
          end: 10,
          replacement: 'gamma',
        );

        expect(document.text, 'alpha gamma');
        expect(result.cursorOffset, 11);
        expect(result.changed, isTrue);
        expect(result.change.startOffset, 6);
        expect(result.change.oldEndOffset, 10);
        expect(result.change.newEndOffset, 11);
      },
    );

    test(
      'insertTextIntoDocument inserts text at the cursor through the string path',
      () {
        final document = TextDocument(text: 'ab\ncd');

        final result = insertTextIntoDocument(document, 3, 'XY');

        expect(document.text, 'ab\nXYcd');
        expect(result.cursorOffset, 5);
        expect(
          result.change.startPosition,
          const TextPosition(line: 1, column: 0),
        );
        expect(
          result.change.newEndPosition,
          const TextPosition(line: 1, column: 2),
        );
      },
    );

    test(
      'deletePreviousDocumentGrapheme removes one grapheme and rewinds the cursor',
      () {
        final document = TextDocument(text: 'a\nb');

        final result = deletePreviousDocumentGrapheme(document, 2);

        expect(document.text, 'ab');
        expect(result.cursorOffset, 1);
        expect(result.change.startOffset, 1);
        expect(result.change.oldEndOffset, 2);
        expect(result.change.newEndOffset, 1);
      },
    );

    test('deleteNextDocumentGrapheme is a no-op at end of document', () {
      final document = TextDocument(text: 'abc');

      final result = deleteNextDocumentGrapheme(document, document.length);

      expect(document.text, 'abc');
      expect(result.cursorOffset, 3);
      expect(result.changed, isFalse);
      expect(result.change.isNoop, isTrue);
    });
  });
}
