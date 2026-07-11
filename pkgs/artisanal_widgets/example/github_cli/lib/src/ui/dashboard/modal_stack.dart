// ignore_for_file: deprecated_member_use
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/action_prompt.dart';
import '../../models/dashboard_data.dart';
import '../../models/display_item.dart';
import '../dialogs/action_prompt_dialog.dart';
import '../dialogs/comments_dialog.dart';
import '../dialogs/diff_dialog.dart';
import '../dialogs/item_detail_dialog.dart';
import '../dialogs/labels_dialog.dart';
import '../dialogs/merge_dialog.dart';
import '../dialogs/repositories_dialog.dart';
import '../dialogs/repository_prompt.dart';
import '../dialogs/run_detail_dialog.dart';
import '../dialogs/search_prompt.dart';

w.Widget wrapGithubDashboardModals({
  required w.Widget child,
  required GithubDisplayItem? detailItem,
  required GithubDisplayItem? diffItem,
  required String diff,
  required bool diffLoading,
  required String? diffError,
  required GithubDisplayItem? runDetailItem,
  required GithubWorkflowRunDetail? runDetail,
  required bool runDetailLoading,
  required String? runDetailError,
  required GithubDisplayItem? commentsItem,
  required List<GithubCommentItem> comments,
  required bool commentsLoading,
  required String? commentsError,
  required GithubDisplayItem? mergeInfoItem,
  required GithubPullRequestMergeInfo? mergeInfo,
  required bool mergeInfoLoading,
  required String? mergeInfoError,
  required GithubDisplayItem? repositoryLabelsItem,
  required List<GithubRepositoryLabel> repositoryLabels,
  required bool repositoryLabelsLoading,
  required String? repositoryLabelsError,
  required GithubActionPrompt? actionPrompt,
  required String? actionPromptError,
  required bool actionRunning,
  required bool repoPromptOpen,
  required bool searchOpen,
  required bool repositoryListOpen,
  required GithubDashboardData? dashboard,
  required List<GithubRepositorySummary> repositories,
  required String? repoPromptError,
  required tui.Cmd? Function() onCloseDetail,
  required tui.Cmd? Function() onCloseDiff,
  required tui.Cmd? Function() onCloseRunDetail,
  required tui.Cmd? Function() onCloseComments,
  required tui.Cmd? Function() onCloseMergeInfo,
  required tui.Cmd? Function(GithubPullRequestMergeAction action)
  onSubmitMergeAction,
  required tui.Cmd? Function() onCloseRepositoryLabels,
  required tui.Cmd? Function(GithubRepositoryLabel label)
  onToggleRepositoryLabel,
  required tui.Cmd? Function() onCloseActionPrompt,
  required tui.Cmd? Function(String value) onSubmitActionPrompt,
  required tui.Cmd? Function() onCloseRepositoryPrompt,
  required tui.Cmd? Function(String value) onSubmitRepository,
  required tui.Cmd? Function() onCloseRepositoryList,
  required tui.Cmd? Function(String repository) onSelectRepository,
  required tui.Cmd? Function() onCloseSearch,
  required tui.Cmd? Function(String value) onSubmitSearch,
}) {
  var result = child;
  if (detailItem != null) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseDetail,
      dialog: GithubItemDetailDialog(item: detailItem, onClose: onCloseDetail),
      child: result,
    );
  }
  if (diffItem != null) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseDiff,
      dialog: GithubDiffDialog(
        item: diffItem,
        diff: diff,
        loading: diffLoading,
        error: diffError,
        onClose: onCloseDiff,
      ),
      child: result,
    );
  }
  if (runDetailItem != null) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseRunDetail,
      dialog: GithubRunDetailDialog(
        item: runDetailItem,
        detail: runDetail,
        loading: runDetailLoading,
        error: runDetailError,
        onClose: onCloseRunDetail,
      ),
      child: result,
    );
  }
  if (commentsItem != null) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseComments,
      dialog: GithubCommentsDialog(
        item: commentsItem,
        comments: comments,
        loading: commentsLoading,
        error: commentsError,
        onClose: onCloseComments,
      ),
      child: result,
    );
  }
  if (mergeInfoItem != null) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseMergeInfo,
      dialog: GithubMergeDialog(
        item: mergeInfoItem,
        info: mergeInfo,
        loading: mergeInfoLoading,
        error: mergeInfoError,
        running: actionRunning,
        actionError: actionPromptError,
        onClose: onCloseMergeInfo,
        onSubmit: onSubmitMergeAction,
      ),
      child: result,
    );
  }
  if (repositoryLabelsItem != null) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseRepositoryLabels,
      dialog: GithubLabelsDialog(
        item: repositoryLabelsItem,
        labels: repositoryLabels,
        loading: repositoryLabelsLoading,
        error: repositoryLabelsError,
        running: actionRunning,
        actionError: actionPromptError,
        onClose: onCloseRepositoryLabels,
        onToggle: onToggleRepositoryLabel,
      ),
      child: result,
    );
  }
  if (actionPrompt != null) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseActionPrompt,
      dialog: GithubActionPromptDialog(
        prompt: actionPrompt,
        error: actionPromptError,
        running: actionRunning,
        onSubmit: onSubmitActionPrompt,
        onCancel: onCloseActionPrompt,
      ),
      child: result,
    );
  }
  if (repoPromptOpen) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseRepositoryPrompt,
      dialog: GithubRepositoryPrompt(
        initialValue: '',
        currentRepository: dashboard?.repository.nameWithOwner,
        error: repoPromptError,
        onSubmit: onSubmitRepository,
        onCancel: onCloseRepositoryPrompt,
      ),
      child: result,
    );
  }
  if (searchOpen) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseSearch,
      dialog: GithubSearchPrompt(
        onSubmit: onSubmitSearch,
        onCancel: onCloseSearch,
      ),
      child: result,
    );
  }
  if (repositoryListOpen) {
    result = w.Modal(
      open: true,
      onDismiss: onCloseRepositoryList,
      dialog: GithubRepositoriesDialog(
        repositories: repositories,
        currentRepository: dashboard?.repository.nameWithOwner,
        onClose: onCloseRepositoryList,
        onSelect: onSelectRepository,
      ),
      child: result,
    );
  }
  return result;
}
