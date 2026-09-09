import 'package:artisanal/git_diff.dart';
import 'package:artisanal_widgets/src/widgets/components/diff_review_extents.dart';
import 'package:test/test.dart';

void main() {
  test(
    'sparse extents agree with a dense oracle through growth and shrink',
    () {
      final diff = GitDiffModel().setDiff('''
diff --git a/a b/a
--- a/a
+++ b/a
@@ -0,0 +1,100 @@
${List.generate(100, (i) => '+line$i').join('\n')}
''');
      final model = DiffReviewModel(
        documentId: 'pr',
        revision: '1',
        diff: diff,
        threads: [
          for (var i = 1; i < 100; i += 10)
            DiffReviewThread(
              id: '$i',
              range: DiffReviewRange(
                DiffCommentLineKey(
                  path: 'a',
                  line: i,
                  side: DiffCommentSide.right,
                ),
              ),
            ),
        ],
      );
      final blocks = DiffReviewBlocks(model);
      final index = ReviewExtents(blocks);
      final heights = List.filled(blocks.length, 1);
      for (final multiplier in [5, 1, 7, 0]) {
        for (var i = 0; i < blocks.threadCount; i++) {
          final height = 1 + i * multiplier;
          index.setThreadHeight(i, height);
          heights[blocks.indexOfThread(
                blocks.threadAt(i).placement.thread.id,
              )!] =
              height;
        }
        var offset = 0;
        for (var i = 0; i < blocks.length; i++) {
          expect(index.offsetOf(i), offset);
          expect(index.heightAt(i), heights[i]);
          for (var row = 0; row < heights[i]; row++) {
            expect(index.resolve(offset + row), (index: i, intraRow: row));
          }
          offset += heights[i];
        }
        expect(index.totalHeight, offset);
        expect(index.resolve(-1), (index: 0, intraRow: 0));
        expect(index.resolve(offset + 100), index.resolve(offset - 1));
      }
    },
  );
}
