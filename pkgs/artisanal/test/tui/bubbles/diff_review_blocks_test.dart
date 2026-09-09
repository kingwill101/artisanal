import 'package:artisanal/git_diff.dart';
import 'package:test/test.dart';

const _patch = '''
diff --git a/a b/a
--- a/a
+++ b/a
@@ -1,2 +1,2 @@
-old
+new
 context
''';

DiffReviewThread _thread(String id, int line, {bool outdated = false}) =>
    DiffReviewThread(
      id: id,
      range: DiffReviewRange(
        DiffCommentLineKey(path: 'a', line: line, side: DiffCommentSide.right),
      ),
      outdated: outdated,
    );

DiffReviewModel _model(Iterable<DiffReviewThread> threads) => DiffReviewModel(
  documentId: 'pr',
  revision: '1',
  diff: GitDiffModel(viewMode: DiffViewMode.sideBySide).setDiff(_patch),
  threads: threads,
);

void main() {
  test(
    'code-only sequence reuses layout and maps every row without insertions',
    () {
      final model = _model([]);
      final blocks = DiffReviewBlocks(model);
      expect(blocks.layout, same(model.diff.layout));
      expect(blocks.length, model.diff.renderedLines.length);
      for (var i = 0; i < blocks.length; i++) {
        expect((blocks[i] as DiffReviewCodeBlock).renderRow, i);
        expect(blocks.indexOfRow(i), i);
        expect(blocks.threadsBefore(i), 0);
      }
      expect(() => blocks[-1], throwsRangeError);
      expect(() => blocks[blocks.length], throwsRangeError);
    },
  );

  test(
    'inserts same-row threads in provider order and retains every code row',
    () {
      final model = _model([
        _thread('later', 2),
        _thread('a', 1),
        _thread('b', 1),
      ]);
      final blocks = DiffReviewBlocks(model);
      expect(blocks.threadCount, 3);
      final ids = <String>[];
      final code = <int>[];
      for (var i = 0; i < blocks.length; i++) {
        switch (blocks[i]) {
          case DiffReviewCodeBlock(:final renderRow):
            code.add(renderRow);
            expect(blocks.indexOfRow(renderRow), i);
          case DiffReviewThreadBlock(:final placement):
            ids.add(placement.thread.id);
            expect(blocks.indexOfThread(placement.thread.id), i);
            expect(code.last, placement.afterRow);
        }
      }
      expect(ids, ['a', 'b', 'later']);
      expect(code, List.generate(model.diff.renderedLines.length, (i) => i));
      expect(blocks.threadsBefore(blocks.length), 3);
      expect(blocks.indexOfThread('missing'), isNull);
    },
  );

  test(
    'unmapped and outdated threads remain explicit after all patch rows',
    () {
      final blocks = DiffReviewBlocks(
        _model([
          _thread('missing', 999),
          _thread('old', 1, outdated: true),
          _thread('valid', 1),
        ]),
      );
      expect(
        (blocks[blocks.length - 2] as DiffReviewThreadBlock).placement.status,
        DiffReviewThreadStatus.unmapped,
      );
      expect(
        (blocks[blocks.length - 1] as DiffReviewThreadBlock).placement.status,
        DiffReviewThreadStatus.outdated,
      );
    },
  );

  test('empty patches can still show unmapped threads', () {
    final blocks = DiffReviewBlocks(
      DiffReviewModel(
        documentId: 'pr',
        revision: '1',
        diff: GitDiffModel(),
        threads: [_thread('missing', 1)],
      ),
    );
    expect(blocks.length, 1);
    expect(blocks.indexOfThread('missing'), 0);
    expect(blocks[0], isA<DiffReviewThreadBlock>());
  });

  test(
    'row lookup respects both split sides, continuation rows and padding',
    () {
      final model = GitDiffModel(
        width: 40,
        viewMode: DiffViewMode.sideBySide,
      ).setDiff(_patch.replaceFirst('+new', '+${'x' * 60}'));
      final first = model.commentAnchors.firstWhere((a) => a.line == 1);
      expect(model.layout.anchorsAtRow(first.renderLine), hasLength(2));
      final continuation = model.layout.anchorsAtRow(first.renderLine + 1);
      expect(continuation, hasLength(1));
      expect(continuation.single.side, DiffCommentSide.right);
      expect(model.layout.anchorsAtRow(0), isEmpty);
      expect(model.layout.anchorsAtRow(-1), isEmpty);
      expect(model.layout.anchorsAtRow(999), isEmpty);
    },
  );
}
