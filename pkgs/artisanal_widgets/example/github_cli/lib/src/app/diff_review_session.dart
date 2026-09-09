import 'package:artisanal/git_diff.dart' as d;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/diff_comment_target.dart';
import '../models/display_item.dart';
import '../models/review_comment.dart';
import '../utils/diff_review_threads.dart';

/// Application-owned review state; comment bodies outlive lazy thread widgets.
final class GithubDiffReviewSession {
  final controller = w.DiffReviewController(
    d.DiffReviewModel(documentId: '', revision: '', diff: d.GitDiffModel()),
  );

  String? _patch;
  List<GithubPullRequestReviewComment>? _comments;
  GithubDiffReviewThreads? _threads;

  GithubDiffReviewThreads? get threads => _threads;

  /// Parses only when the source changes, never on selection or scrolling.
  void synchronize({
    required GithubDisplayItem item,
    required String patch,
    required String fileIdentity,
    required List<GithubPullRequestReviewComment> comments,
    required d.DiffViewMode viewMode,
  }) {
    final id = '${item.repository}#${item.number}:$fileIdentity';
    final previous = controller.model;
    final reload =
        previous.document.id != id ||
        previous.document.revision != item.headRefOid ||
        _patch != patch;
    if (reload) {
      final diff = d.GitDiffModel(
        width: previous.diff.width,
        height: previous.diff.height,
        viewMode: viewMode,
        wrapLines: true,
      ).setDiff(patch);
      _threads = _adapt(comments, diff, fileIdentity);
      controller.update(
        d.DiffReviewLoadMsg(
          documentId: id,
          revision: item.headRefOid,
          diff: diff,
          threads: _threads!.threads,
        ),
      );
      _patch = patch;
      _comments = comments;
    } else if (!identical(_comments, comments)) {
      _threads = _adapt(comments, previous.diff, fileIdentity);
      controller.update(
        d.DiffReviewThreadsMsg(
          documentId: id,
          revision: item.headRefOid,
          threads: _threads!.threads,
        ),
      );
      _comments = comments;
    }
    controller.update(d.DiffReviewPresentationMsg(viewMode: viewMode));
  }

  GithubDiffReviewThreads _adapt(
    List<GithubPullRequestReviewComment> comments,
    d.GitDiffModel diff,
    String fileIdentity,
  ) {
    final paths = {
      fileIdentity,
      for (final file in diff.files) ...[file.oldPath, file.newPath],
    };
    return GithubDiffReviewThreads(
      fileIdentity.isEmpty
          ? comments
          : comments.where((comment) => paths.contains(comment.path)),
      files: diff.files,
    );
  }

  void reset() {
    _patch = null;
    _comments = null;
    _threads = null;
    controller.update(
      d.DiffReviewLoadMsg(documentId: '', revision: '', diff: d.GitDiffModel()),
    );
  }

  void ensureSelection() {
    if (controller.model.selected != null) return;
    final key = controller.firstVisibleSource();
    if (key != null) controller.update(d.DiffReviewSelectMsg(key));
  }

  void move(int delta) {
    ensureSelection();
    controller.update(d.DiffReviewMoveMsg(delta));
    controller.revealSelection();
  }

  void scrollBy(int delta) {
    controller.scrollController.scrollBy(delta);
    final key = controller.firstVisibleSource(
      preferredSide: controller.model.selected?.side,
    );
    if (key == null) {
      controller.update(const d.DiffReviewClearSelectionMsg());
    } else {
      controller.update(d.DiffReviewSelectMsg(key));
    }
  }

  GithubDiffCommentTarget? get commentTarget {
    ensureSelection();
    final model = controller.model;
    final range = model.commentTarget;
    if (range == null) return null;
    // GitHub's REST path is the current filename, even for LEFT rename lines.
    final file = model.document.files
        .where(
          (file) => range.end.side == d.DiffCommentSide.left
              ? file.oldPath == range.end.path
              : file.newPath == range.end.path,
        )
        .firstOrNull;
    return GithubDiffCommentTarget(
      path: file == null || file.newPath == '/dev/null'
          ? range.end.path
          : file.newPath,
      line: range.end.line,
      side: range.end.side.githubApiValue,
      startLine: range.isRange ? range.start.line : null,
      startSide: range.isRange ? range.start.side.githubApiValue : null,
    );
  }
}
