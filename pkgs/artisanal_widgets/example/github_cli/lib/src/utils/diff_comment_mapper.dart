import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/review_comment.dart';

/// Strips the `a/` / `b/` prefixes that `git diff --git` emits and collapses
/// `/dev/null` so a GitHub review comment's `path` can be matched against the
/// diff model's anchor paths regardless of how either side was normalized.
String _normalizePath(String path) {
  var normalized = path.trim();
  if (normalized.isEmpty || normalized == '/dev/null') return '/dev/null';
  if (normalized.startsWith('a/')) normalized = normalized.substring(2);
  if (normalized.startsWith('b/')) normalized = normalized.substring(2);
  return normalized;
}

Map<int, List<GithubPullRequestReviewComment>> mapReviewCommentsToRenderLines(
  List<GithubPullRequestReviewComment> comments,
  List<w.DiffCommentAnchor> anchors,
) {
  final result = <int, List<GithubPullRequestReviewComment>>{};
  if (comments.isEmpty || anchors.isEmpty) return result;

  final normalizedAnchors = anchors
      .map((anchor) => (anchor: anchor, path: _normalizePath(anchor.path)))
      .toList();

  for (final comment in comments) {
    final commentSide = comment.side == 'LEFT'
        ? w.DiffCommentSide.left
        : w.DiffCommentSide.right;
    final commentPath = _normalizePath(comment.path);

    w.DiffCommentAnchor? exact;
    w.DiffCommentAnchor? lineOnly;
    w.DiffCommentAnchor? nearest;
    var nearestDistance = -1;

    for (final entry in normalizedAnchors) {
      if (entry.path != commentPath) continue;
      final anchor = entry.anchor;
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
      } else if (distance == nearestDistance &&
          nearest.side != commentSide &&
          anchor.side == commentSide) {
        // Tie-break: prefer the anchor on the same side as the comment.
        nearest = anchor;
      }
    }

    final anchor = exact ?? lineOnly ?? nearest;
    if (anchor != null) {
      result.putIfAbsent(anchor.renderLine, () => []).add(comment);
    }
  }

  return result;
}
