import 'package:artisanal/git_diff.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:github_cli/src/models/review_comment.dart';
import 'package:github_cli/src/utils/diff_review_threads.dart';
import 'package:test/test.dart';

void main() {
  test('end-to-end: review comments map to comment blocks', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    final controller = GitDiffController();
    final scroll = WidgetScrollController();

    const multiDiff = '''
diff --git a/lib/a.dart b/lib/a.dart
index 1111111..2222222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,3 +1,4 @@
 class A {
+  int x = 1;
   void foo() {}
 }
diff --git a/lib/b.dart b/lib/b.dart
index 3333333..4444444 100644
--- a/lib/b.dart
+++ b/lib/b.dart
@@ -1,3 +1,4 @@
 class B {
+  int y = 2;
   void bar() {}
 }''';

    controller.setDiff(multiDiff);
    controller.setSize(80, 40);
    final comment = GithubPullRequestReviewComment.fromJson({
      'id': 42,
      'path': 'lib/b.dart',
      'line': 2,
      'side': 'RIGHT',
      'body': 'MAPPED_COMMENT_BODY',
    })!;

    // Use the app's provider adapter and the core's source-to-row placement
    // rather than duplicating the mapping algorithm in this regression.
    final adapter = GithubDiffReviewThreads([
      comment,
    ], files: controller.model.files);
    final review = DiffReviewModel(
      documentId: 'owner/repo#42',
      revision: 'base..head',
      diff: controller.model,
      threads: adapter.threads,
    );
    final placement = review.threadPlacements.single;
    expect(placement.status, DiffReviewThreadStatus.attached);
    expect(
      placement.afterRow,
      controller.model.commentAnchors
          .firstWhere(
            (anchor) =>
                anchor.path == 'lib/b.dart' &&
                anchor.line == 2 &&
                anchor.side == DiffCommentSide.right,
          )
          .renderLine,
      reason: 'comment should map to the added line in the second file',
    );

    await tester.pumpWidget(
      GitDiffViewer(
        diff: multiDiff,
        width: 80,
        height: 40,
        controller: controller,
        scrollController: scroll,
        commentBlocks: [
          DiffCommentBlock(
            renderLine: placement.afterRow!,
            height: 1,
            child: Text(
              adapter.bodiesByThreadId[placement.thread.id]!.single.body,
            ),
          ),
        ],
      ),
    );

    expect(
      tester.find.text('MAPPED_COMMENT_BODY'),
      isTrue,
      reason: 'mapped review comment must render inline',
    );
  });
}
