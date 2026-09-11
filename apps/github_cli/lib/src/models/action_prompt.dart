import 'diff_comment_target.dart';
import 'display_item.dart';

enum GithubActionPromptKind {
  addComment,
  addReviewComment,
  addLabels,
  removeLabels,
  mergePullRequest,
  closePullRequest,
}

final class GithubActionPrompt {
  const GithubActionPrompt({
    required this.kind,
    required this.item,
    this.diffTarget,
  });

  final GithubActionPromptKind kind;
  final GithubDisplayItem item;
  final GithubDiffCommentTarget? diffTarget;

  String get title {
    return switch (kind) {
      GithubActionPromptKind.addComment => 'Add comment',
      GithubActionPromptKind.addReviewComment => 'Add diff comment',
      GithubActionPromptKind.addLabels => 'Add labels',
      GithubActionPromptKind.removeLabels => 'Remove labels',
      GithubActionPromptKind.mergePullRequest => 'Merge pull request',
      GithubActionPromptKind.closePullRequest => 'Close pull request',
    };
  }

  String get description {
    return switch (kind) {
      GithubActionPromptKind.addComment =>
        'Write a comment for ${item.kind.toUpperCase()} #${item.number}.',
      GithubActionPromptKind.addReviewComment =>
        'Write a review comment for ${diffTarget?.label ?? 'the selected diff line'} on PR #${item.number}.',
      GithubActionPromptKind.addLabels =>
        'Enter comma-separated label names for ${item.kind.toUpperCase()} #${item.number}.',
      GithubActionPromptKind.removeLabels =>
        'Enter comma-separated labels to remove from PR #${item.number}.',
      GithubActionPromptKind.mergePullRequest =>
        'Enter merge, squash, rebase, auto-merge, disable-auto, or an admin-* action.',
      GithubActionPromptKind.closePullRequest =>
        'Type close to close PR #${item.number}.',
    };
  }

  String get placeholder {
    return switch (kind) {
      GithubActionPromptKind.addComment => 'Looks good from the TUI.',
      GithubActionPromptKind.addReviewComment => 'Could we adjust this line?',
      GithubActionPromptKind.addLabels => 'bug,help wanted',
      GithubActionPromptKind.removeLabels => 'needs-review',
      GithubActionPromptKind.mergePullRequest => 'squash',
      GithubActionPromptKind.closePullRequest => 'close',
    };
  }

  int get maxLines {
    return switch (kind) {
      GithubActionPromptKind.addComment ||
      GithubActionPromptKind.addReviewComment => 5,
      GithubActionPromptKind.addLabels ||
      GithubActionPromptKind.removeLabels ||
      GithubActionPromptKind.mergePullRequest ||
      GithubActionPromptKind.closePullRequest => 1,
    };
  }
}
