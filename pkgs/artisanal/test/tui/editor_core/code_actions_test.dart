import 'dart:async';

import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

final class _Provider implements EditorCodeActionProvider {
  _Provider(this.result);
  final FutureOr<List<EditorCodeAction>> result;

  @override
  FutureOr<List<EditorCodeAction>> provide(EditorCodeActionRequest request) =>
      result;
}

void main() {
  test('code action session returns immutable provider results', () async {
    final session = EditorCodeActionSession();
    final result = await session.request(
      _Provider([const EditorCodeAction(title: 'Fix')]),
      const EditorCodeActionRequest(
        documentText: 'x',
        documentVersion: 1,
        startOffset: 0,
        endOffset: 1,
      ),
    );

    expect(result?.single.title, 'Fix');
    expect(
      () => result?.add(const EditorCodeAction(title: 'Other')),
      throwsUnsupportedError,
    );
  });

  test('new requests invalidate older asynchronous results', () async {
    final pending = Completer<List<EditorCodeAction>>();
    final session = EditorCodeActionSession();
    final stale = session.request(
      _Provider(pending.future),
      const EditorCodeActionRequest(
        documentText: 'x',
        documentVersion: 1,
        startOffset: 0,
        endOffset: 1,
      ),
    );
    final current = session.request(
      _Provider([const EditorCodeAction(title: 'Current')]),
      const EditorCodeActionRequest(
        documentText: 'xy',
        documentVersion: 2,
        startOffset: 0,
        endOffset: 2,
      ),
    );
    pending.complete([const EditorCodeAction(title: 'Stale')]);

    expect(await stale, isNull);
    expect((await current)?.single.title, 'Current');
  });
}
