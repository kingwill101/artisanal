import 'package:artisanal/git_diff.dart';
import 'package:github_cli/src/models/review_comment.dart';
import 'package:github_cli/src/utils/diff_review_threads.dart';
import 'package:test/test.dart';

GithubPullRequestReviewComment comment(
  int id, {
  String path = 'new.dart',
  String side = 'RIGHT',
  int? line = 21,
  int? originalLine,
  int? startLine,
  int? originalStartLine,
  String? startSide,
  int? replyTo,
}) => GithubPullRequestReviewComment.fromJson({
  'id': id,
  'path': path,
  'side': side,
  'line': line,
  'original_line': originalLine,
  'start_line': startLine,
  'original_start_line': originalStartLine,
  'start_side': startSide,
  'in_reply_to_id': replyTo,
  'body': 'comment $id',
})!;

void main() {
  final diff = GitDiffModel(width: 80, viewMode: DiffViewMode.sideBySide)
      .setDiff('''
diff --git a/old.dart b/new.dart
--- a/old.dart
+++ b/new.dart
@@ -10,3 +20,3 @@
 context
-before
+after
 ending
''');

  GithubDiffReviewThreads adapt(
    List<GithubPullRequestReviewComment> comments,
  ) => GithubDiffReviewThreads(comments, files: diff.files);

  DiffReviewModel review(GithubDiffReviewThreads adapter) => DiffReviewModel(
    documentId: 'owner/repo#42',
    revision: 'base..head',
    diff: diff,
    threads: adapter.threads,
  );

  test('preserves range, reply ID, and revision metadata from REST', () {
    final current = comment(1, startLine: 20, startSide: 'RIGHT');
    expect(current.startLine, 20);
    expect(current.startSide, 'RIGHT');
    expect(current.outdated, isFalse);
    final old = comment(
      2,
      line: null,
      originalLine: 21,
      originalStartLine: 20,
      startLine: 999,
      replyTo: 1,
    );
    expect(old.line, 21);
    expect(old.startLine, 20);
    expect(old.outdated, isTrue);
    expect(old.replyToId, '1');
  });

  test('groups replies by root, never by rendered row or source position', () {
    final adapter = adapt([
      comment(3, replyTo: 1),
      comment(1),
      comment(2),
      comment(4, side: 'LEFT', line: 11),
    ]);
    expect(adapter.threads.map((t) => t.id), ['1', '2', '4']);
    expect(adapter.bodiesByThreadId['1']!.map((c) => c.id), ['1', '3']);
    expect(
      review(adapter).threadPlacements.map((p) => p.status),
      everyElement(DiffReviewThreadStatus.attached),
    );
    expect(adapter.threads.last.range.start.path, 'old.dart');
    expect(adapter.threads.last.range.start.side, DiffCommentSide.left);
    expect(adapter.unsupportedComments, isEmpty);
  });

  test('outdated and absent positions are not reassigned to nearby code', () {
    final model = review(
      adapt([
        comment(1, line: null, originalLine: 21),
        comment(2, line: 999),
        comment(3, startLine: 20, line: 22),
      ]),
    );
    expect(model.threadPlacements.map((p) => p.status), [
      DiffReviewThreadStatus.outdated,
      DiffReviewThreadStatus.unmapped,
      DiffReviewThreadStatus.attached,
    ]);
    expect(model.threads['3']!.range.start.line, 20);
    expect(model.threads['3']!.range.end.line, 22);
  });

  test('unsupported roots and orphan replies remain available to the host', () {
    final adapter = adapt([
      comment(1, startLine: 10, startSide: 'LEFT'),
      comment(2, replyTo: 1),
      comment(3, replyTo: 999),
    ]);
    expect(adapter.threads, isEmpty);
    expect(adapter.unsupportedComments.map((c) => c.id), ['1', '2', '3']);
  });

  test('literal a/ and b/ repository directories are not stripped', () {
    final adapter = adapt([
      comment(1, path: 'a/new.dart'),
      comment(2, path: 'b/new.dart'),
    ]);
    expect(adapter.threads.map((t) => t.range.start.path), [
      'a/new.dart',
      'b/new.dart',
    ]);
    expect(
      review(adapter).threadPlacements.map((p) => p.status),
      everyElement(DiffReviewThreadStatus.unmapped),
    );
  });

  test('snapshots bodies and rejects duplicate provider identities', () {
    final input = [comment(1)];
    final adapter = adapt(input);
    input.clear();
    expect(adapter.threads.single.id, '1');
    expect(
      () => adapter.bodiesByThreadId['1']!.clear(),
      throwsUnsupportedError,
    );
    expect(() => adapter.threads.clear(), throwsUnsupportedError);
    expect(() => adapt([comment(1), comment(1)]), throwsArgumentError);
  });
}
