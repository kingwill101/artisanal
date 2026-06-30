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

    for (final anchor in anchors) {
      if (anchor.path == comment.path &&
          anchor.line == comment.line &&
          anchor.side == commentSide) {
        result.putIfAbsent(anchor.renderLine, () => []).add(comment);
        break;
      }
    }
  }

  return result;
}
