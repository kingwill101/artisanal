import 'dart:async';

import 'package:artisanal/bubbles.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

final class _CompletionProvider implements EditorCompletionProvider {
  const _CompletionProvider(this.items);
  final List<EditorCompletionItem> items;

  @override
  EditorCompletionResult provide(EditorCompletionRequest request) =>
      EditorCompletionResult(items: items);
}

final class _PendingCompletionProvider implements EditorCompletionProvider {
  final result = Completer<EditorCompletionResult>();

  @override
  Future<EditorCompletionResult> provide(EditorCompletionRequest request) =>
      result.future;
}

final class _CodeActionProvider implements EditorCodeActionProvider {
  @override
  List<EditorCodeAction> provide(EditorCodeActionRequest request) => [
    const EditorCodeAction(
      title: 'Replace typo',
      commandId: 'app.fixTypo',
      edit: WorkspaceEdit(
        files: {
          'main.dart': [
            FileTextEdit(startOffset: 0, endOffset: 4, replacement: 'good'),
          ],
        },
      ),
    ),
  ];
}

final class _SyntaxProvider extends TextSyntaxProvider<int> {
  @override
  TextSyntaxBuildResult<int> build(
    String text, {
    TextDocument? document,
    String? language,
    TextSyntaxSnapshot<int>? previous,
    TextDocumentChange? change,
  }) {
    return TextSyntaxBuildResult(
      decorations: text.isEmpty
          ? const []
          : const [
              TextDecorationRange(
                startOffset: 0,
                endOffset: 1,
                styleKey: 'syntax.keyword',
              ),
            ],
      state: (previous?.state ?? 0) + 1,
    );
  }
}

void main() {
  group('TextAreaModel commands', () {
    test('exposes discoverable builtin commands', () {
      final model = TextAreaModel();
      final ids = model.commandRegistry.commands
          .map((command) => command.id)
          .toSet();

      expect(
        ids,
        containsAll([
          EditorCommandIds.undo,
          EditorCommandIds.redo,
          EditorCommandIds.selectAll,
          EditorCommandIds.selectLine,
          EditorCommandIds.clearSelection,
          EditorCommandIds.insertLineBreak,
          EditorCommandIds.nextDiagnostic,
          EditorCommandIds.previousDiagnostic,
        ]),
      );
    });

    test('dispatch observes contextual availability', () {
      final model = TextAreaModel();

      expect(
        model.executeCommand(EditorCommandIds.undo),
        EditorCommandDispatchResult.disabled,
      );
      expect(
        model.executeCommand(EditorCommandIds.selectAll),
        EditorCommandDispatchResult.disabled,
      );

      model.insertString('hello');
      expect(
        model.executeCommand(EditorCommandIds.selectAll),
        EditorCommandDispatchResult.handled,
      );
      expect(model.hasSelection, isTrue);
      expect(
        model.executeCommand(EditorCommandIds.clearSelection),
        EditorCommandDispatchResult.handled,
      );
      expect(model.hasSelection, isFalse);
      expect(
        model.executeCommand(EditorCommandIds.undo),
        EditorCommandDispatchResult.handled,
      );
      expect(model.value, isEmpty);
    });

    test('host commands can extend and explicitly override the registry', () {
      final model = TextAreaModel();
      model.commandRegistry.register(
        EditorCommand(
          id: 'app.insertGreeting',
          label: 'Insert Greeting',
          execute: (model) {
            model.insertString('hello');
            return true;
          },
        ),
      );

      expect(
        model.executeCommand('app.insertGreeting'),
        EditorCommandDispatchResult.handled,
      );
      expect(model.value, 'hello');
    });

    test('multi-cursor insertion is atomic and restored by history', () {
      final model = TextAreaModel()..setText('one two', recordHistory: false);
      model.setSelections(
        TextSelectionSet([
          const TextSelectionRange(startOffset: 0, endOffset: 3),
          const TextSelectionRange(startOffset: 4, endOffset: 7),
        ], primaryOffset: 7),
      );

      model.insertString('x');

      expect(model.value, 'x x');
      expect(model.hasMultipleSelections, isTrue);
      expect(model.selections.ranges, [
        const TextSelectionRange(startOffset: 1, endOffset: 1),
        const TextSelectionRange(startOffset: 3, endOffset: 3),
      ]);

      expect(model.undo(), isTrue);
      expect(model.value, 'one two');
      expect(model.hasMultipleSelections, isTrue);
      expect(model.selections.ranges.first.endOffset, 3);

      expect(model.redo(), isTrue);
      expect(model.value, 'x x');
      expect(model.hasMultipleSelections, isTrue);
    });

    test('single-cursor navigation exits multi-cursor mode', () {
      final model = TextAreaModel()..setText('abc', recordHistory: false);
      model
        ..addCursorAtOffset(0)
        ..addCursorAtOffset(2);
      expect(model.hasMultipleSelections, isTrue);

      model.setCursor(0, 1);

      expect(model.hasMultipleSelections, isFalse);
      expect(model.cursorOffset, 1);
    });

    test('adds cursors vertically and edits every line atomically', () {
      final model = TextAreaModel()
        ..setText('aa\naa\naa', recordHistory: false);
      model.setCursor(0, 1);

      expect(
        model.executeCommand(EditorCommandIds.addCursorBelow),
        EditorCommandDispatchResult.handled,
      );
      expect(
        model.executeCommand(EditorCommandIds.addCursorBelow),
        EditorCommandDispatchResult.handled,
      );
      model.insertString('!');

      expect(model.value, 'a!a\na!a\na!a');
      expect(model.selections.ranges, hasLength(3));
    });

    test('adds matching selections in document order with wrap', () {
      final model = TextAreaModel()
        ..setText('cat dog cat cat', recordHistory: false)
        ..setSelection(
          baseLine: 0,
          baseColumn: 0,
          extentLine: 0,
          extentColumn: 3,
        );

      expect(model.addNextOccurrence(), isTrue);
      expect(model.addNextOccurrence(), isTrue);
      expect(model.selections.ranges, hasLength(3));
      expect(model.addNextOccurrence(), isFalse);

      model.insertString('fox');
      expect(model.value, 'fox dog fox fox');
      expect(model.undo(), isTrue);
      expect(model.value, 'cat dog cat cat');
      expect(model.selections.ranges, hasLength(3));
    });

    test(
      'requests, navigates, and atomically accepts completion edits',
      () async {
        var model = TextAreaModel()..setText('pri', recordHistory: false);
        final cmd = model.requestCompletions(
          const _CompletionProvider([
            EditorCompletionItem(label: 'print', insertText: 'print'),
            EditorCompletionItem(
              label: 'private',
              insertText: 'private',
              replacementStart: 0,
              replacementEnd: 3,
              additionalEdits: WorkspaceEdit(
                files: {
                  'main.dart': [
                    FileTextEdit(
                      startOffset: 0,
                      endOffset: 0,
                      replacement: 'import "x";\n',
                    ),
                  ],
                },
              ),
            ),
          ]),
        );

        final msg = await cmd.execute();
        final (next, _) = model.update(msg!);
        model = next;
        expect(model.completionItems, hasLength(2));
        expect(model.view().toString(), contains('print'));
        expect(model.view().toString(), contains('private'));
        var (afterKey, _) = model.update(
          tui.KeyMsg(const tui.Key(tui.KeyType.down)),
        );
        model = afterKey;
        expect(model.activeCompletion?.label, 'private');

        (afterKey, _) = model.update(
          tui.KeyMsg(const tui.Key(tui.KeyType.enter)),
        );
        model = afterKey;
        expect(model.value, 'private');
        expect(model.completionVisible, isFalse);
        expect(
          model.consumeCompletionAdditionalEdits()?.files,
          contains('main.dart'),
        );
        expect(model.consumeCompletionAdditionalEdits(), isNull);

        expect(model.undo(), isTrue);
        expect(model.value, 'pri');
      },
    );

    test('typing rejects an in-flight completion response', () async {
      var model = TextAreaModel()..setText('a', recordHistory: false);
      final provider = _PendingCompletionProvider();
      final pending = model.requestCompletions(provider).execute();

      model.insertString('b');
      provider.result.complete(
        const EditorCompletionResult(
          items: [EditorCompletionItem(label: 'old', insertText: 'old')],
        ),
      );
      final msg = await pending;
      final (next, _) = model.update(msg!);
      model = next;

      expect(model.value, 'ab');
      expect(model.completionItems, isEmpty);
    });

    test('search navigates, highlights, and replaces as one transaction', () {
      final model = TextAreaModel()
        ..setText('cat dog cat', recordHistory: false);
      final result = model.startSearch(
        const TextSearchQuery(pattern: 'cat', caseSensitive: true),
      );

      expect(result.matches, hasLength(2));
      expect(model.decorations, hasLength(2));
      expect(
        model.executeCommand(EditorCommandIds.nextSearchMatch),
        EditorCommandDispatchResult.handled,
      );
      expect(model.activeSearchMatch?.startOffset, 0);
      expect(model.replaceAllSearchMatches('fox'), isTrue);
      expect(model.value, 'fox dog fox');
      expect(model.searchMatches, isEmpty);

      expect(model.undo(), isTrue);
      expect(model.value, 'cat dog cat');
    });

    test('invalid incremental regex is reported without throwing', () {
      final model = TextAreaModel()..setText('text', recordHistory: false);

      final result = model.startSearch(
        const TextSearchQuery(pattern: '[', isRegex: true),
      );

      expect(result.error, isNotNull);
      expect(model.searchError, isNotNull);
      expect(model.searchMatches, isEmpty);
      expect(model.decorations, isEmpty);
    });

    test('requests and delivers a selected code action to the host', () async {
      var model = TextAreaModel()
        ..setText('bad!', recordHistory: false)
        ..setSelection(
          baseLine: 0,
          baseColumn: 0,
          extentLine: 0,
          extentColumn: 4,
        );
      final msg = await model
          .requestCodeActions(_CodeActionProvider())
          .execute();
      final (next, _) = model.update(msg!);
      model = next;

      expect(model.activeCodeAction?.title, 'Replace typo');
      expect(model.acceptCodeAction(), isTrue);
      expect(model.codeActions, isEmpty);
      expect(model.consumeAcceptedCodeAction()?.commandId, 'app.fixTypo');
      expect(model.consumeAcceptedCodeAction(), isNull);
    });

    test('syntax synchronization preserves search and diagnostic layers', () {
      final model = TextAreaModel()..setText('class Cat', recordHistory: false);
      final session = TextSyntaxSession<int>(provider: _SyntaxProvider());
      model
        ..startSearch(const TextSearchQuery(pattern: 'Cat'))
        ..setDiagnostics([
          const TextDiagnosticRange(
            startOffset: 6,
            endOffset: 9,
            severity: TextDiagnosticSeverity.warning,
          ),
        ]);

      final snapshot = model.syncSyntax(session, language: 'dart');

      expect(snapshot.state, 1);
      expect(
        model.decorationsForLayer(textSyntaxDecorationLayerKey),
        hasLength(1),
      );
      expect(
        model.decorationsForLayer(textSearchDecorationLayerKey),
        isNotEmpty,
      );
      expect(
        model.decorationsForLayer(textDiagnosticsDecorationLayerKey),
        isNotEmpty,
      );

      expect(model.clearSyntax(), isTrue);
      expect(model.decorationsForLayer(textSyntaxDecorationLayerKey), isEmpty);
      expect(
        model.decorationsForLayer(textSearchDecorationLayerKey),
        isNotEmpty,
      );
    });

    test('compound edits commit and undo as one transaction', () {
      final model = TextAreaModel();

      model.editTransaction((editor) {
        editor.insertString('first');
        editor.insertString('\n');
        editor.insertString('second');
      });

      expect(model.value, 'first\nsecond');
      expect(model.undo(), isTrue);
      expect(model.value, isEmpty);
      expect(model.canUndo, isFalse);
      expect(model.redo(), isTrue);
      expect(model.value, 'first\nsecond');
    });

    test('failed transactions roll back text, selection, and history', () {
      final model = TextAreaModel()..setText('safe', recordHistory: false);

      expect(
        () => model.editTransaction<void>((editor) {
          editor
            ..selectAll()
            ..insertString('partial');
          throw StateError('abort');
        }),
        throwsStateError,
      );

      expect(model.value, 'safe');
      expect(model.hasSelection, isFalse);
      expect(model.canUndo, isFalse);
    });

    test('saved state tracks edits through undo and redo', () {
      final model = TextAreaModel()
        ..setText('saved', recordHistory: false)
        ..markSaved();
      expect(model.isDirty, isFalse);

      model.insertString('!');
      expect(model.isDirty, isTrue);
      expect(model.undo(), isTrue);
      expect(model.isDirty, isFalse);
      expect(model.redo(), isTrue);
      expect(model.isDirty, isTrue);

      model.markSaved();
      expect(model.isDirty, isFalse);
    });

    test('copies and cuts multiple selections in document order', () {
      final model = TextAreaModel()
        ..setText('one two three', recordHistory: false);
      model.setSelections(
        TextSelectionSet([
          const TextSelectionRange(startOffset: 0, endOffset: 3),
          const TextSelectionRange(startOffset: 8, endOffset: 13),
        ], primaryOffset: 13),
      );

      expect(model.getSelectedTexts(), ['one', 'three']);
      expect(model.getSelectedText(), 'one\nthree');
      expect(model.cutSelectedText(), 'one\nthree');
      expect(model.value, ' two ');
      expect(model.selections.ranges, [
        const TextSelectionRange(startOffset: 0, endOffset: 0),
        const TextSelectionRange(startOffset: 5, endOffset: 5),
      ]);

      expect(model.undo(), isTrue);
      expect(model.value, 'one two three');
      expect(model.getSelectedTexts(), ['one', 'three']);
    });

    test('renders every active cursor instead of only the primary cursor', () {
      final model =
          TextAreaModel(
              showLineNumbers: false,
              useVirtualCursor: true,
              width: 20,
            )
            ..setText('abc', recordHistory: false)
            ..setSelections(
              TextSelectionSet([
                const TextSelectionRange(startOffset: 0, endOffset: 0),
                const TextSelectionRange(startOffset: 2, endOffset: 2),
              ], primaryOffset: 2),
            )
            ..focus();

      final rendered = model.view().toString();

      expect(
        RegExp(r'\x1b\[[0-9;]*7[0-9;]*m').allMatches(rendered).length,
        greaterThanOrEqualTo(2),
      );
    });

    test('moves and deletes at every cursor through stable commands', () {
      final model = TextAreaModel()..setText('abc def', recordHistory: false);
      model.setSelections(
        TextSelectionSet([
          const TextSelectionRange(startOffset: 1, endOffset: 1),
          const TextSelectionRange(startOffset: 5, endOffset: 5),
        ], primaryOffset: 5),
      );

      expect(
        model.executeCommand(EditorCommandIds.cursorRight),
        EditorCommandDispatchResult.handled,
      );
      expect(model.selections.ranges.map((range) => range.endOffset), [2, 6]);
      expect(
        model.executeCommand(EditorCommandIds.deleteLeft),
        EditorCommandDispatchResult.handled,
      );
      expect(model.value, 'ac df');
      expect(model.selections.ranges.map((range) => range.endOffset), [1, 4]);

      expect(model.undo(), isTrue);
      expect(model.value, 'abc def');
      expect(model.selections.ranges.map((range) => range.endOffset), [2, 6]);
    });

    test('moves and deletes by word at every cursor atomically', () {
      final model = TextAreaModel()
        ..setText('one two three four', recordHistory: false)
        ..setSelections(
          TextSelectionSet([
            const TextSelectionRange(startOffset: 4, endOffset: 4),
            const TextSelectionRange(startOffset: 14, endOffset: 14),
          ], primaryOffset: 14),
        );

      expect(
        model.executeCommand(EditorCommandIds.cursorWordRight),
        EditorCommandDispatchResult.handled,
      );
      expect(model.selections.ranges.map((range) => range.endOffset), [7, 18]);
      expect(
        model.executeCommand(EditorCommandIds.deleteWordLeft),
        EditorCommandDispatchResult.handled,
      );
      expect(model.value, 'one  three ');
      expect(model.undo(), isTrue);
      expect(model.value, 'one two three four');
    });

    test('moves and deletes to line boundaries at every cursor', () {
      final model = TextAreaModel()
        ..setText('first line\nsecond line\nthird', recordHistory: false)
        ..setSelections(
          TextSelectionSet([
            const TextSelectionRange(startOffset: 3, endOffset: 3),
            const TextSelectionRange(startOffset: 15, endOffset: 15),
          ], primaryOffset: 15),
        );

      expect(
        model.executeCommand(EditorCommandIds.cursorLineEnd),
        EditorCommandDispatchResult.handled,
      );
      expect(model.selections.ranges.map((range) => range.endOffset), [10, 22]);
      expect(
        model.executeCommand(EditorCommandIds.deleteLineLeft),
        EditorCommandDispatchResult.handled,
      );
      expect(model.value, '\n\nthird');
      expect(model.undo(), isTrue);
      expect(model.value, 'first line\nsecond line\nthird');
    });
  });
}
