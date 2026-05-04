import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import 'body.dart';
import '../../models/dashboard_data.dart';
import '../../models/display_item.dart';
import 'footer.dart';
import '../../app/layout_mode.dart';
import 'panels.dart';
import 'top_bar.dart';
import 'focused_body.dart';
import 'splash_screen.dart';

final class GithubDashboardView extends w.StatelessWidget {
  GithubDashboardView({
    required this.repository,
    required this.dashboard,
    required this.loading,
    required this.error,
    required this.layoutMode,
    required this.themeName,
    required this.tabIndex,
    required this.selectedIndex,
    required this.visibleItems,
    required this.navigating,
    required this.notice,
    required this.detailScrollController,
    required this.queueScrollController,
    required this.commentsItem,
    required this.comments,
    required this.commentsLoading,
    required this.commentsError,
    required this.commitsItem,
    required this.commits,
    required this.commitsLoading,
    required this.commitsError,
    required this.reviewCommentsItem,
    required this.reviewComments,
    required this.reviewCommentsLoading,
    required this.reviewCommentsError,
    required this.diffItem,
    required this.diff,
    required this.diffFiles,
    required this.diffFileIndex,
    required this.diffLoading,
    required this.diffError,
    required this.diffViewMode,
    required this.mergeInfoItem,
    required this.mergeInfo,
    required this.mergeInfoLoading,
    required this.mergeInfoError,
    required this.repositoryLabelsItem,
    required this.repositoryLabels,
    required this.repositoryLabelsLoading,
    required this.repositoryLabelsError,
    required this.runDetailItem,
    required this.runDetail,
    required this.runDetailLoading,
    required this.runDetailError,
    required this.pageStatus,
    required this.onDetailTabChanged,
    required this.onTabChanged,
    required this.onItemSelected,
    super.key,
  });

  final String? repository;
  final GithubDashboardData? dashboard;
  final bool loading;
  final String? error;
  final GithubDashboardLayoutMode layoutMode;
  final String themeName;
  final int tabIndex;
  final int selectedIndex;
  final List<GithubDisplayItem> visibleItems;
  final bool navigating;
  final String? notice;
  final w.ScrollController detailScrollController;
  final w.ScrollController queueScrollController;
  final GithubDisplayItem? commentsItem;
  final List<GithubCommentItem> comments;
  final bool commentsLoading;
  final String? commentsError;
  final GithubDisplayItem? commitsItem;
  final List<GithubPullRequestCommit> commits;
  final bool commitsLoading;
  final String? commitsError;
  final GithubDisplayItem? reviewCommentsItem;
  final List<GithubPullRequestReviewComment> reviewComments;
  final bool reviewCommentsLoading;
  final String? reviewCommentsError;
  final GithubDisplayItem? diffItem;
  final String diff;
  final List<GithubPullRequestDiffFile> diffFiles;
  final int diffFileIndex;
  final bool diffLoading;
  final String? diffError;
  final w.DiffViewMode diffViewMode;
  final GithubDisplayItem? mergeInfoItem;
  final GithubPullRequestMergeInfo? mergeInfo;
  final bool mergeInfoLoading;
  final String? mergeInfoError;
  final GithubDisplayItem? repositoryLabelsItem;
  final List<GithubRepositoryLabel> repositoryLabels;
  final bool repositoryLabelsLoading;
  final String? repositoryLabelsError;
  final GithubDisplayItem? runDetailItem;
  final GithubWorkflowRunDetail? runDetail;
  final bool runDetailLoading;
  final String? runDetailError;
  final GithubPageStatus pageStatus;
  final tui.Cmd? Function(int index) onDetailTabChanged;
  final tui.Cmd? Function(int index) onTabChanged;
  final void Function(int index) onItemSelected;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final size = w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
    final width = size.width.toInt().clamp(60, 240);
    final height = size.height.toInt().clamp(18, 80);
    final showSplash = _showSplash;

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          githubDashboardTopBar(
            theme: theme,
            dashboard: dashboard,
            repository: repository,
            loading: loading,
            tabIndex: tabIndex,
            issueCount: dashboard?.openIssueCount ?? 0,
            pullRequestCount: dashboard?.openPullRequestCount ?? 0,
            workflowRunCount: dashboard?.workflowRunCount ?? 0,
            pageStatus: pageStatus,
            width: width - 2,
            onTabChanged: onTabChanged,
          ),
          w.Expanded(
            child: showSplash
                ? GithubSplashScreen(repository: repository)
                : error != null
                ? githubErrorPanel(theme, error!)
                : dashboard == null
                ? githubEmptyPanel(theme)
                : layoutMode.isFocused
                ? githubFocusedBody(
                    theme: theme,
                    dashboard: dashboard!,
                    selectedIndex: selectedIndex,
                    visibleItems: visibleItems,
                    navigating: navigating,
                    detailScrollController: detailScrollController,
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
                    onDetailTabChanged: onDetailTabChanged,
                    height: height - 5,
                    width: width - 2,
                  )
                : githubDashboardBody(
                    theme: theme,
                    dashboard: dashboard!,
                    tabIndex: tabIndex,
                    selectedIndex: selectedIndex,
                    visibleItems: visibleItems,
                    navigating: navigating,
                    detailScrollController: detailScrollController,
                    queueScrollController: queueScrollController,
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
                    pageStatus: pageStatus,
                    onDetailTabChanged: onDetailTabChanged,
                    height: height - 5,
                    width: width - 2,
                    onItemSelected: onItemSelected,
                  ),
          ),
          w.Divider(
            width: width - 2,
            style: theme.bodySmall.copy()..foreground(theme.border),
          ),
          githubDashboardFooter(
            theme,
            notice: notice,
            layoutMode: layoutMode,
            themeName: themeName,
          ),
        ],
      ),
    );
  }

  bool get _showSplash {
    if (error != null) return false;
    if (dashboard == null) return loading;
    if (!pageStatus.loading || pageStatus.error != null) return false;
    return pageStatus.loaded == 0 && visibleItems.isEmpty;
  }
}
