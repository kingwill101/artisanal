import 'dart:async';

import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

final class _Provider implements EditorCompletionProvider {
  _Provider(this.result);
  final FutureOr<EditorCompletionResult> result;

  @override
  FutureOr<EditorCompletionResult> provide(EditorCompletionRequest request) =>
      result;
}

void main() {
  test('completion filtering is fuzzy and deterministic', () {
    const items = [
      EditorCompletionItem(label: 'print', insertText: 'print'),
      EditorCompletionItem(label: 'private', insertText: 'private'),
      EditorCompletionItem(label: 'parseInt', insertText: 'parseInt'),
    ];

    expect(filterEditorCompletions(items, 'pri').map((item) => item.label), [
      'print',
      'private',
      'parseInt',
    ]);
  });

  test('completion session rejects stale asynchronous responses', () async {
    final first = Completer<EditorCompletionResult>();
    final session = EditorCompletionSession();
    final stale = session.request(
      _Provider(first.future),
      const EditorCompletionRequest(
        documentText: 'a',
        cursorOffset: 1,
        documentVersion: 1,
      ),
    );
    final current = session.request(
      _Provider(
        const EditorCompletionResult(
          items: [EditorCompletionItem(label: 'new', insertText: 'new')],
        ),
      ),
      const EditorCompletionRequest(
        documentText: 'ab',
        cursorOffset: 2,
        documentVersion: 2,
      ),
    );
    first.complete(
      const EditorCompletionResult(
        items: [EditorCompletionItem(label: 'old', insertText: 'old')],
      ),
    );

    expect(await stale, isNull);
    expect((await current)?.items.single.label, 'new');
  });

  test('cancelling invalidates an in-flight response', () async {
    final result = Completer<EditorCompletionResult>();
    final session = EditorCompletionSession();
    final pending = session.request(
      _Provider(result.future),
      const EditorCompletionRequest(
        documentText: '',
        cursorOffset: 0,
        documentVersion: 1,
      ),
    );

    session.cancel();
    result.complete(const EditorCompletionResult());

    expect(await pending, isNull);
    expect(session.isActive, isFalse);
  });
}
