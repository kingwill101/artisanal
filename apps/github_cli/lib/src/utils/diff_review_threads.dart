import 'package:artisanal/git_diff.dart';

import '../models/review_comment.dart';

/// Source-anchored GitHub threads plus host-owned bodies for the review viewport.
///
/// This adapter never consults rendered rows or chooses a nearest source line.
/// GitHub paths are repository-relative: literal `a/` and `b/` directories must
/// not be stripped. Old-side rename paths are translated using the patch files.
final class GithubDiffReviewThreads {
  factory GithubDiffReviewThreads(
    Iterable<GithubPullRequestReviewComment> comments, {
    required Iterable<DiffFile> files,
  }) {
    final byId = <String, GithubPullRequestReviewComment>{};
    for (final comment in comments) {
      if (comment.id.isEmpty || byId.containsKey(comment.id)) {
        throw ArgumentError('Review comment IDs must be nonempty and unique.');
      }
      byId[comment.id] = comment;
    }
    final oldPaths = <String, String>{
      for (final file in files) file.newPath: file.oldPath,
    };
    final grouped = <String, List<GithubPullRequestReviewComment>>{};
    final unsupported = <GithubPullRequestReviewComment>[];
    for (final comment in byId.values) {
      final rootId = comment.replyToId ?? comment.id;
      final root = byId[rootId];
      // REST in_reply_to_id identifies the root comment. Do not invent a
      // location when that root is missing from a partial response.
      if (root == null ||
          root.replyToId != null ||
          root.path.isEmpty ||
          root.line <= 0 ||
          (root.side != 'LEFT' && root.side != 'RIGHT') ||
          (root.startLine != null &&
              (root.startLine! <= 0 ||
                  (root.startSide != null && root.startSide != root.side)))) {
        unsupported.add(comment);
        continue;
      }
      grouped.putIfAbsent(rootId, () => []).add(comment);
    }
    final threads = <DiffReviewThread>[];
    final bodies = <String, List<GithubPullRequestReviewComment>>{};
    for (final entry in grouped.entries) {
      final root = byId[entry.key]!;
      final side = root.side == 'LEFT'
          ? DiffCommentSide.left
          : DiffCommentSide.right;
      final path = side == DiffCommentSide.left
          ? oldPaths[root.path] ?? root.path
          : root.path;
      threads.add(
        DiffReviewThread(
          id: root.id,
          range: DiffReviewRange(
            DiffCommentLineKey(
              path: path,
              side: side,
              line: root.startLine ?? root.line,
            ),
            DiffCommentLineKey(path: path, side: side, line: root.line),
          ),
          outdated: root.outdated,
        ),
      );
      // Keep the root first even when a paginated response lists replies first.
      // Replies retain provider order; bodies survive viewport child eviction.
      bodies[root.id] = List.unmodifiable([
        root,
        ...entry.value.where((comment) => comment.id != root.id),
      ]);
    }
    return GithubDiffReviewThreads._(
      List.unmodifiable(threads),
      Map.unmodifiable(bodies),
      List.unmodifiable(unsupported),
    );
  }

  const GithubDiffReviewThreads._(
    this.threads,
    this.bodiesByThreadId,
    this.unsupportedComments,
  );

  /// Independent root IDs remain independent even on the same source row.
  final List<DiffReviewThread> threads;

  /// Root and replies, keyed by the same IDs used by [threads].
  final Map<String, List<GithubPullRequestReviewComment>> bodiesByThreadId;

  /// Partial replies or invalid/cross-side attachments requiring host display.
  ///
  /// These must remain visible in the review list, not be attached approximately
  /// to code. Valid but absent source lines instead become core unmapped threads.
  final List<GithubPullRequestReviewComment> unsupportedComments;
}
