import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/dashboard_data.dart';
import '../../models/display_item.dart';
import 'detail_pane.dart';
import 'work_queue_pane.dart';

w.Widget githubDashboardBody({
  required w.Theme theme,
  required GithubDashboardData dashboard,
  required int tabIndex,
  required int selectedIndex,
  required List<GithubDisplayItem> visibleItems,
  required bool navigating,
  required w.ScrollController detailScrollController,
  required w.ScrollController queueScrollController,
  required GithubDisplayItem? commentsItem,
  required List<GithubCommentItem> comments,
  required bool commentsLoading,
  required String? commentsError,
  required GithubDisplayItem? commitsItem,
  required List<GithubPullRequestCommit> commits,
  required bool commitsLoading,
  required String? commitsError,
  required GithubDisplayItem? reviewCommentsItem,
  required List<GithubPullRequestReviewComment> reviewComments,
  required bool reviewCommentsLoading,
  required String? reviewCommentsError,
  required GithubDisplayItem? diffItem,
  required String diff,
  required List<GithubPullRequestDiffFile> diffFiles,
  required int diffFileIndex,
  required bool diffLoading,
  required String? diffError,
  required w.DiffViewMode diffViewMode,
  required GithubDisplayItem? mergeInfoItem,
  required GithubPullRequestMergeInfo? mergeInfo,
  required bool mergeInfoLoading,
  required String? mergeInfoError,
  required GithubDisplayItem? repositoryLabelsItem,
  required List<GithubRepositoryLabel> repositoryLabels,
  required bool repositoryLabelsLoading,
  required String? repositoryLabelsError,
  required GithubDisplayItem? runDetailItem,
  required GithubWorkflowRunDetail? runDetail,
  required bool runDetailLoading,
  required String? runDetailError,
  required GithubPageStatus pageStatus,
  GithubOverviewFilter overviewFilter = GithubOverviewFilter.authored,
  tui.Cmd? Function(GithubOverviewFilter filter)? onOverviewFilterChanged,
  required tui.Cmd? Function(int index) onDetailTabChanged,
  required int height,
  required int width,
  required void Function(int index) onItemSelected,
}) {
  final leftWidth = width < 100 ? (width * 0.48).floor() : 58;
  final selectedItem =
      visibleItems.isEmpty || selectedIndex >= visibleItems.length
      ? null
      : visibleItems[selectedIndex];

  return w.Row(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    children: [
      w.Container(
        width: leftWidth,
        child: githubWorkQueuePane(
          theme: theme,
          tabIndex: tabIndex,
          overviewFilter: overviewFilter,
          selectedIndex: selectedIndex,
          pageStatus: pageStatus,
          items: visibleItems,
          controller: queueScrollController,
          width: leftWidth,
          onOverviewFilterChanged:
              onOverviewFilterChanged ?? (_) => tui.Cmd.none(),
          onItemSelected: onItemSelected,
          searchQuery: null,
          searchLoading: false,
          searchError: null,
        ),
      ),
      w.VerticalDivider(
        height: height,
        style: theme.bodySmall.copy()..foreground(theme.border),
      ),
      w.Expanded(
        child: w.Container(
          padding: const w.EdgeInsets.only(left: 2),
          child: githubDetailPane(
            theme: theme,
            dashboard: dashboard,
            selectedItem: selectedItem,
            navigating: navigating,
            controller: detailScrollController,
            commentsItem: commentsItem,
            comments: comments,
            commentsLoading: commentsLoading,
            commentsError: commentsError,
            commitsItem: commitsItem,
            commits: commits,
            commitsLoading: commitsLoading,
            commitsError: commitsError,
            reviewCommentsItem: reviewCommentsItem,
            reviewComments: reviewComments,
            reviewCommentsLoading: reviewCommentsLoading,
            reviewCommentsError: reviewCommentsError,
            diffItem: diffItem,
            diff: diff,
            diffFiles: diffFiles,
            diffFileIndex: diffFileIndex,
            diffLoading: diffLoading,
            diffError: diffError,
            diffViewMode: diffViewMode,
            mergeInfoItem: mergeInfoItem,
            mergeInfo: mergeInfo,
            mergeInfoLoading: mergeInfoLoading,
            mergeInfoError: mergeInfoError,
            repositoryLabelsItem: repositoryLabelsItem,
            repositoryLabels: repositoryLabels,
            repositoryLabelsLoading: repositoryLabelsLoading,
            repositoryLabelsError: repositoryLabelsError,
            runDetailItem: runDetailItem,
            runDetail: runDetail,
            runDetailLoading: runDetailLoading,
            runDetailError: runDetailError,
            onTabChanged: onDetailTabChanged,
            height: height,
            width: width - leftWidth - 3,
          ),
        ),
      ),
    ],
  );
}
