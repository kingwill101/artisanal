import 'package:artisanal/git_diff.dart' as d;
import 'package:github_cli/src/app/diff_review_session.dart';
import 'package:github_cli/src/models/display_item.dart';
import 'package:github_cli/src/models/review_comment.dart';
import 'package:test/test.dart';

const patch = '''
diff --git a/old.dart b/new.dart
--- a/old.dart
+++ b/new.dart
@@ -10,3 +20,3 @@
 context
-before
+after
 ending
''';

GithubDisplayItem item(String revision) => GithubDisplayItem(
  target: GithubDisplayTarget.pullRequest,
  kind: 'pr',
  number: 42,
  title: '',
  body: '',
  url: '',
  repository: 'owner/repo',
  author: '',
  status: '',
  updatedAt: null,
  footer: '',
  headRefOid: revision,
);

GithubPullRequestReviewComment comment(String id, {String path = 'new.dart'}) =>
    GithubPullRequestReviewComment(
      id: id,
      path: path,
      line: 21,
      side: 'RIGHT',
      author: 'reviewer',
      body: 'body $id',
      url: '',
      createdAt: null,
    );

void main() {
  test(
    'presentation and body refresh reuse parsed patch and preserve expansion',
    () {
      final session = GithubDiffReviewSession();
      final comments = [comment('root')];
      void sync({
        d.DiffViewMode mode = d.DiffViewMode.unified,
        List<GithubPullRequestReviewComment>? bodies,
        String revision = 'head',
      }) => session.synchronize(
        item: item(revision),
        patch: patch,
        fileIdentity: 'new.dart',
        comments: bodies ?? comments,
        viewMode: mode,
      );
      sync();
      final layout = session.controller.model.diff.layout;
      session.controller.update(
        const d.DiffReviewExpandMsg('root', expanded: true),
      );
      sync();
      expect(session.controller.model.diff.layout, same(layout));
      final document = session.controller.model.document;
      sync(mode: d.DiffViewMode.sideBySide);
      expect(session.controller.model.document, same(document));
      sync(bodies: [comment('root'), comment('new')]);
      expect(session.controller.model.expandedThreadIds, {'root'});
      expect(session.threads!.bodiesByThreadId.keys, ['root', 'new']);
      sync(revision: 'new-head');
      expect(session.controller.model.expandedThreadIds, isEmpty);
      expect(session.controller.scrollController.offset, 0);
    },
  );

  test(
    'selected-file review omits other files without guessing their anchors',
    () {
      final session = GithubDiffReviewSession();
      session.synchronize(
        item: item('head'),
        patch: patch,
        fileIdentity: 'new.dart',
        comments: [
          comment('here'),
          comment('elsewhere', path: 'other.dart'),
        ],
        viewMode: d.DiffViewMode.unified,
      );
      expect(session.controller.model.threads.keys, ['here']);
      session.controller.update(
        const d.DiffReviewSelectMsg(
          d.DiffCommentLineKey(
            path: 'old.dart',
            line: 11,
            side: d.DiffCommentSide.left,
          ),
        ),
      );
      expect(session.commentTarget!.path, 'new.dart');
      expect(session.commentTarget!.side, 'LEFT');
      expect(session.commentTarget!.line, 11);
      session.reset();
      expect(session.commentTarget, isNull);
      expect(session.threads, isNull);
    },
  );
}
