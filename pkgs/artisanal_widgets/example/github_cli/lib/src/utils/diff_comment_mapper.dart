import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/review_comment.dart';

Map<int, List<GithubPullRequestReviewComment>> mapReviewCommentsToRenderLines(
  List<GithubPullRequestReviewComment> comments,
  List<w.DiffCommentAnchor> anchors,
) {
  final result = <int, List<GithubPullRequestReviewComment>>{};
  if (comments.isEmpty || anchors.isEmpty) return result;

  for (final comment in comments) {
    final commentSide = comment.side == 'LEFT'
        ? w.DiffCommentSide.left
        : w.DiffCommentSide.right;

    w.DiffCommentAnchor? exact;
    w.DiffCommentAnchor? lineOnly;
    w.DiffCommentAnchor? nearest;
    var nearestDistance = -1;

    for (final anchor in anchors) {
      if (anchor.path != comment.path) continue;
      if (anchor.line == comment.line && anchor.side == commentSide) {
        exact = anchor;
        break;
      }
      if (anchor.line == comment.line) {
        lineOnly ??= anchor;
        continue;
      }
      final distance = (anchor.line - comment.line).abs();
      if (nearest == null || distance < nearestDistance) {
        nearest = anchor;
        nearestDistance = distance;
      }
    }

    final anchor = exact ?? lineOnly ?? nearest;
    if (anchor != null) {
      result.putIfAbsent(anchor.renderLine, () => []).add(comment);
    }
  }

  return result;
}
