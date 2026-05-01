import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextOffsetStateDocumentEditingExtensions', () {
    test('insertTextDocumentCommand inserts text at the cursor', () {
      final document = TextDocument(text: 'hello');
      final state = TextOffsetStateSnapshot.collapsed(cursorOffset: 5);

      final result = state.insertTextDocumentCommand(document, text: '!');

      expect(result.changed, isTrue);
      expect(result.cursorOffset, 6);
      expect(result.document, isNotNull);
      expect(result.document!.text, 'hello!');
      expect(result.documentChange, isNotNull);
      expect(result.documentChange!.startOffset, 5);
      expect(result.documentChange!.newEndOffset, 6);
    });

    test(
      'splitLineDocumentCommand inserts a newline through the document path',
      () {
        final document = TextDocument(text: 'helloWorld');
        final state = TextOffsetStateSnapshot.collapsed(cursorOffset: 5);

        final result = state.splitLineDocumentCommand(document);

        expect(result.document, isNotNull);
        expect(result.document!.text, 'hello\nWorld');
        expect(result.cursorOffset, 6);
      },
    );

    test(
      'wrap and unwrap selection document commands preserve the selection',
      () {
        final document = TextDocument(text: 'alpha beta');
        final state = TextOffsetStateSnapshot.selection(
          baseOffset: 6,
          extentOffset: 10,
        );

        final wrapped = state.wrapSelectionDocumentCommand(
          document,
          before: '(',
          after: ')',
        );

        expect(wrapped.document, isNotNull);
        expect(wrapped.document!.text, 'alpha (beta)');
        expect(wrapped.selectionBaseOffset, 7);
        expect(wrapped.selectionExtentOffset, 11);

        final unwrapped =
            TextOffsetStateSnapshot.selection(
              baseOffset: wrapped.selectionBaseOffset!,
              extentOffset: wrapped.selectionExtentOffset!,
            ).unwrapSelectionDocumentCommand(
              wrapped.document!,
              surroundPairs: const {'(': ')'},
            );

        expect(unwrapped.document, isNotNull);
        expect(unwrapped.document!.text, 'alpha beta');
        expect(unwrapped.selectionBaseOffset, 6);
        expect(unwrapped.selectionExtentOffset, 10);
      },
    );

    test('moveByWordDocumentCommand uses document readers', () {
      final document = TextDocument(text: 'alpha beta gamma');
      final state = TextOffsetStateSnapshot.collapsed(cursorOffset: 0);

      final result = state.moveByWordDocumentCommand(document, forward: true);

      expect(result.changed, isTrue);
      expect(result.cursorOffset, greaterThan(0));
      expect(result.cursorOffset, lessThanOrEqualTo(document.length));
    });
  });

  group('document-backed line transforms', () {
    test(
      'toggleLinePrefixDocument rewrites the document and keeps selection',
      () {
        final document = TextDocument(text: 'alpha\nbeta');
        final state = TextLineStateSnapshot.selection(
          base: TextPosition(line: 0, column: 0),
          extent: TextPosition(line: 1, column: 4),
        );

        final result = textToggleLinePrefixDocument(
          document: document,
          state: state,
          prefix: '>',
        );

        expect(result.changed, isTrue);
        expect(result.document, isNotNull);
        expect(result.document!.text, '> alpha\n> beta');
        expect(result.documentChange, isNotNull);
        expect(
          result.documentChange!.startPosition,
          const TextPosition(line: 0, column: 0),
        );
        expect(result.selectionBaseOffset, 0);
        expect(result.selectionExtentOffset, result.document!.length);
      },
    );

    test('moveSelectedLinesDocument reorders the backing document', () {
      final document = TextDocument(text: 'one\ntwo\nthree');
      final state = TextLineStateSnapshot.collapsed(
        cursor: TextPosition(line: 1, column: 0),
      );

      final result = textMoveSelectedLinesDocument(
        document: document,
        state: state,
        direction: -1,
      );

      expect(result.changed, isTrue);
      expect(result.document, isNotNull);
      expect(result.document!.text, 'two\none\nthree');
      expect(result.cursorOffset, 0);
    });

    test('cleanupWhitespaceDocument trims the live document in place', () {
      final document = TextDocument(text: 'alpha  \nbeta\t\n\n');
      final state = TextLineStateSnapshot.collapsed(
        cursor: TextPosition(line: 0, column: 0),
      );

      final result = textCleanupWhitespaceDocument(
        document: document,
        state: state,
      );

      expect(result.changed, isTrue);
      expect(result.document, isNotNull);
      expect(result.document!.text, 'alpha\nbeta');
    });
  });
}
