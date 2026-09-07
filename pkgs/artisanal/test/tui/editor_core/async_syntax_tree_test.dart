import 'dart:async';

import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

final class _ParseRequest {
  _ParseRequest({
    required this.document,
    required this.languageId,
    required this.previousDocument,
    required this.previous,
    required this.edits,
    required this.revision,
  });

  final TextDocument document;
  final String? languageId;
  final TextDocument? previousDocument;
  final EditorSyntaxTree? previous;
  final List<SyntaxTreeEdit>? edits;
  final int? revision;
  final completer = Completer<EditorSyntaxTree>();
}

final class _AsyncTreeProvider extends AsyncSyntaxTreeProvider {
  _AsyncTreeProvider({this.incremental = true});

  final bool incremental;
  final List<_ParseRequest> requests = [];

  @override
  String get languageId => 'test';

  @override
  bool get supportsIncremental => incremental;

  @override
  Future<EditorSyntaxTree> parse({
    required TextDocument document,
    String? languageId,
    TextDocument? previousDocument,
    EditorSyntaxTree? previous,
    List<SyntaxTreeEdit>? edits,
    int? revision,
  }) {
    final request = _ParseRequest(
      document: document,
      languageId: languageId,
      previousDocument: previousDocument,
      previous: previous,
      edits: edits,
      revision: revision,
    );
    requests.add(request);
    return request.completer.future;
  }
}

EditorSyntaxTree _treeFor(_ParseRequest request) {
  return EditorSyntaxTree(
    languageId: request.languageId!,
    revision: request.revision!,
    nodes: const [],
  );
}

void main() {
  group('AsyncSyntaxTreeSession', () {
    test('retains accepted snapshots and reuses unchanged documents', () async {
      final provider = _AsyncTreeProvider();
      final session = AsyncSyntaxTreeSession(provider: provider);
      final document = TextDocument(text: 'alpha');

      final pending = session.request(document);
      provider.requests.single.document.replaceOffsetRange(
        startOffset: 0,
        endOffset: 5,
        replacement: const ['m', 'u', 't', 'a', 't', 'e', 'd'],
      );
      provider.requests.single.completer.complete(
        _treeFor(provider.requests.single),
      );
      final tree = await pending;

      expect(tree, same(session.snapshot));
      expect(session.document?.text, 'alpha');
      expect(await session.request(document), same(tree));
      expect(provider.requests, hasLength(1));
    });

    test(
      'passes previous snapshots and edits to incremental providers',
      () async {
        final provider = _AsyncTreeProvider();
        final session = AsyncSyntaxTreeSession(provider: provider);
        final document = TextDocument(text: 'alpha');

        final firstPending = session.request(document);
        provider.requests[0].completer.complete(_treeFor(provider.requests[0]));
        final first = await firstPending;
        final change = document.replaceOffsetRange(
          startOffset: 5,
          endOffset: 5,
          replacement: const ['!'],
        );

        final secondPending = session.request(document, change: change);
        final secondRequest = provider.requests[1];
        expect(secondRequest.previous, same(first));
        expect(secondRequest.previousDocument?.text, 'alpha');
        expect(secondRequest.document.text, 'alpha!');
        expect(secondRequest.edits, hasLength(1));
        expect(secondRequest.edits!.single.startOffset, 5);
        expect(secondRequest.edits!.single.oldEndOffset, 5);
        expect(secondRequest.edits!.single.newEndOffset, 6);

        secondRequest.completer.complete(_treeFor(secondRequest));
        expect(await secondPending, same(session.snapshot));
      },
    );

    test('does not reuse state for non-incremental providers', () async {
      final provider = _AsyncTreeProvider(incremental: false);
      final session = AsyncSyntaxTreeSession(provider: provider);
      final document = TextDocument(text: 'alpha');

      final firstPending = session.request(document);
      provider.requests[0].completer.complete(_treeFor(provider.requests[0]));
      await firstPending;
      document.replaceOffsetRange(
        startOffset: 5,
        endOffset: 5,
        replacement: const ['!'],
      );

      final secondPending = session.request(document);
      final secondRequest = provider.requests[1];
      expect(secondRequest.previous, isNull);
      expect(secondRequest.previousDocument, isNull);
      expect(secondRequest.edits, isNull);
      secondRequest.completer.complete(_treeFor(secondRequest));
      await secondPending;
    });

    test('rejects a result superseded by a newer request', () async {
      final provider = _AsyncTreeProvider();
      final session = AsyncSyntaxTreeSession(provider: provider);

      final firstPending = session.request(TextDocument(text: 'old'));
      final secondPending = session.request(TextDocument(text: 'new'));
      provider.requests[1].completer.complete(_treeFor(provider.requests[1]));
      final second = await secondPending;
      provider.requests[0].completer.complete(_treeFor(provider.requests[0]));

      expect(await firstPending, isNull);
      expect(session.snapshot, same(second));
      expect(session.document?.text, 'new');
    });

    test('cancel and reset invalidate pending work', () async {
      final provider = _AsyncTreeProvider();
      final session = AsyncSyntaxTreeSession(provider: provider);

      final cancelled = session.request(TextDocument(text: 'cancelled'));
      session.cancel();
      provider.requests[0].completer.complete(_treeFor(provider.requests[0]));
      expect(await cancelled, isNull);

      final accepted = session.request(TextDocument(text: 'accepted'));
      provider.requests[1].completer.complete(_treeFor(provider.requests[1]));
      await accepted;
      session.reset();
      expect(session.snapshot, isNull);
      expect(session.document, isNull);
    });
  });
}
