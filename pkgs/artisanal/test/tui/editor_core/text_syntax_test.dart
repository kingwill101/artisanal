import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('computeTextDocumentChange', () {
    test('tracks offset and line ranges for a replacement', () {
      final change = computeTextDocumentChange(
        'alpha\nbeta\ngamma',
        'alpha\nbetter\ngamma',
      );

      expect(change.startOffset, 9);
      expect(change.oldEndOffset, 10);
      expect(change.newEndOffset, 12);
      expect(change.startPosition, const TextPosition(line: 1, column: 3));
      expect(change.oldEndPosition, const TextPosition(line: 1, column: 4));
      expect(change.newEndPosition, const TextPosition(line: 1, column: 6));
      expect(change.deletedLength, 1);
      expect(change.insertedLength, 3);
      expect(change.isNoop, isFalse);
    });

    test('returns a no-op change for identical text', () {
      final change = computeTextDocumentChange('same', 'same');

      expect(change.startOffset, 4);
      expect(change.oldEndOffset, 4);
      expect(change.newEndOffset, 4);
      expect(change.isNoop, isTrue);
    });

    test('supports document-aware change computation', () {
      final previousDocument = TextDocument(text: 'alpha\nbeta\ngamma');
      final nextDocument = TextDocument(text: 'alpha\nbetter\ngamma');

      final change = computeTextDocumentChangeForDocuments(
        previousDocument: previousDocument,
        nextDocument: nextDocument,
      );

      expect(change.startOffset, 9);
      expect(change.oldEndOffset, 10);
      expect(change.newEndOffset, 12);
      expect(change.startPosition, const TextPosition(line: 1, column: 3));
      expect(change.oldEndPosition, const TextPosition(line: 1, column: 4));
      expect(change.newEndPosition, const TextPosition(line: 1, column: 6));
    });
  });

  group('TextSyntaxSession', () {
    test('builds an initial snapshot and reuses it for unchanged text', () {
      final provider = _RecordingSyntaxProvider();
      final session = TextSyntaxSession<int>(provider: provider);

      final first = session.sync('alpha');
      final second = session.sync('alpha');

      expect(first.decorations, const [
        TextDecorationRange(
          startOffset: 0,
          endOffset: 5,
          styleKey: 'syntax.token',
        ),
      ]);
      expect(identical(first, second), isTrue);
      expect(provider.calls, hasLength(1));
      expect(provider.calls.single.change, isNull);
      expect(provider.calls.single.previousText, isNull);
    });

    test('passes previous snapshot and change metadata on updates', () {
      final provider = _RecordingSyntaxProvider();
      final session = TextSyntaxSession<int>(provider: provider);

      session.sync('alpha\nbeta');
      final updated = session.sync('alpha\nbetter');

      expect(provider.calls, hasLength(2));
      expect(provider.calls.last.previousText, 'alpha\nbeta');
      expect(provider.calls.last.change, isNotNull);
      expect(
        provider.calls.last.change!.startPosition,
        const TextPosition(line: 1, column: 3),
      );
      expect(updated.change, isNotNull);
      expect(updated.state, 2);
    });

    test('accepts explicit change metadata from callers', () {
      final provider = _RecordingSyntaxProvider();
      final session = TextSyntaxSession<int>(provider: provider);
      const explicitChange = TextDocumentChange(
        startOffset: 6,
        oldEndOffset: 10,
        newEndOffset: 12,
        startPosition: TextPosition(line: 1, column: 0),
        oldEndPosition: TextPosition(line: 1, column: 4),
        newEndPosition: TextPosition(line: 1, column: 6),
      );

      session.sync('alpha\nbeta');
      final updated = session.sync('alpha\nbetter', change: explicitChange);

      expect(provider.calls, hasLength(2));
      expect(identical(provider.calls.last.change, explicitChange), isTrue);
      expect(identical(updated.change, explicitChange), isTrue);
    });

    test('syncDocument reuses explicit document changes', () {
      final provider = _RecordingSyntaxProvider();
      final session = TextSyntaxSession<int>(provider: provider);
      final document = TextDocument(text: 'alpha\nbeta');

      session.syncDocument(document);
      final change = document.replaceTextRange(
        startOffset: 6,
        endOffset: 10,
        replacement: 'better',
      );
      final updated = session.syncDocument(document, change: change);

      expect(provider.calls, hasLength(2));
      expect(identical(provider.calls.last.change, change), isTrue);
      expect(updated.text, 'alpha\nbetter');
      expect(updated.change, same(change));
    });

    test('syncDocument computes document-aware changes from snapshots', () {
      final provider = _RecordingSyntaxProvider();
      final session = TextSyntaxSession<int>(provider: provider);
      final document = TextDocument(text: 'alpha\nbeta');

      session.syncDocument(document);
      document.replaceTextRange(
        startOffset: 6,
        endOffset: 10,
        replacement: 'better',
      );
      final updated = session.syncDocument(document);

      expect(provider.calls, hasLength(2));
      expect(provider.calls.last.previousText, 'alpha\nbeta');
      expect(provider.calls.last.change, isNotNull);
      expect(
        provider.calls.last.change!.startPosition,
        const TextPosition(line: 1, column: 3),
      );
      expect(updated.document!.text, 'alpha\nbetter');
      expect(updated.change, isNotNull);
    });

    test('rebuilds when the language changes even if text does not', () {
      final provider = _RecordingSyntaxProvider();
      final session = TextSyntaxSession<int>(provider: provider);

      session.sync('alpha', language: 'dart');
      final rebuilt = session.sync('alpha', language: 'yaml');

      expect(provider.calls, hasLength(2));
      expect(provider.calls.last.language, 'yaml');
      expect(provider.calls.last.change, isNull);
      expect(rebuilt.language, 'yaml');
    });

    test('clear resets the previous snapshot', () {
      final provider = _RecordingSyntaxProvider();
      final session = TextSyntaxSession<int>(provider: provider);

      session.sync('alpha');
      session.clear();
      session.sync('alphabet');

      expect(provider.calls, hasLength(2));
      expect(provider.calls.last.previousText, isNull);
      expect(provider.calls.last.change, isNull);
    });
  });
}

final class _RecordingSyntaxProvider implements TextSyntaxProvider<int> {
  final List<_RecordingSyntaxCall> calls = <_RecordingSyntaxCall>[];

  @override
  TextSyntaxBuildResult<int> build(
    String text, {
    String? language,
    TextSyntaxSnapshot<int>? previous,
    TextDocumentChange? change,
  }) {
    calls.add(
      _RecordingSyntaxCall(
        text: text,
        language: language,
        previousText: previous?.text,
        change: change,
      ),
    );
    return TextSyntaxBuildResult<int>(
      decorations: text.isEmpty
          ? const <TextDecorationRange>[]
          : <TextDecorationRange>[
              TextDecorationRange(
                startOffset: 0,
                endOffset: text.length,
                styleKey: 'syntax.token',
              ),
            ],
      state: calls.length,
    );
  }
}

final class _RecordingSyntaxCall {
  const _RecordingSyntaxCall({
    required this.text,
    required this.language,
    required this.previousText,
    required this.change,
  });

  final String text;
  final String? language;
  final String? previousText;
  final TextDocumentChange? change;
}
