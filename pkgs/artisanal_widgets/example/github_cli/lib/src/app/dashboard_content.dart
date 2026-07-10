import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/dashboard_data.dart';
import '../state/notifiers.dart';
import '../ui/dashboard/detail_pane.dart';
import '../ui/dashboard/footer.dart';
import '../ui/dashboard/panels.dart';
import '../ui/dashboard/splash_screen.dart';
import '../ui/dashboard/top_bar.dart';
import '../ui/dashboard/work_queue_pane.dart';
import 'command_items.dart';
import 'ui_state.dart';

final class GithubDashboardContent extends w.StatelessWidget {
  GithubDashboardContent({
    required this.queue,
    required this.data,
    required this.detail,
    required this.uiState,
    required this.commandItems,
    required this.detailScrollController,
    required this.queueScrollController,
    required this.diffController,
    required this.diffCommentHighlights,
    required this.onDiffCommentAnchorSelected,
    required this.onDiffFileSelected,
    required this.onCloseCommandPalette,
    required this.onDetailTabChanged,
    required this.onTabChanged,
    required this.onOverviewFilterChanged,
    required this.onItemSelected,
    super.key,
  });

  final GithubQueueNotifier queue;
  final GithubDataNotifier data;
  final GithubDetailNotifier detail;
  final GithubDashboardUiState uiState;
  final GithubDashboardCommandItems commandItems;
  final w.ScrollController detailScrollController;
  final w.ScrollController queueScrollController;
  final w.GitDiffController diffController;
  final List<w.DiffCommentLineHighlight> diffCommentHighlights;
  final tui.Cmd? Function(w.DiffCommentAnchor anchor)
  onDiffCommentAnchorSelected;
  final tui.Cmd? Function(int index) onDiffFileSelected;
  final tui.Cmd? Function() onCloseCommandPalette;
  final tui.Cmd? Function(int index) onDetailTabChanged;
  final tui.Cmd? Function(int index) onTabChanged;
  final tui.Cmd? Function(GithubOverviewFilter filter) onOverviewFilterChanged;
  final void Function(int index) onItemSelected;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final size = w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
    final width = size.width.toInt().clamp(60, 240);
    final height = size.height.toInt().clamp(18, 80);
    final themeChoice = uiState.themeChoice;

    return w.CommandPalette(
      open: uiState.commandPaletteOpen,
      title: 'GitHub command center',
      hint: 'target, comments, diff, actions...',
      width: 72,
      maxHeight: 24,
      items: uiState.commandPaletteOpen
          ? commandItems.build()
          : const <w.CommandPaletteItem>[],
      onDismiss: onCloseCommandPalette,
      child: w.Container(
        padding: const w.EdgeInsets.all(1),
        color: theme.background,
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            _TopBarRegion(
              data: data,
              queue: queue,
              width: width - 2,
              onTabChanged: onTabChanged,
            ),
            w.Expanded(
              child: _MainRegion(
                data: data,
                queue: queue,
                detail: detail,
                uiState: uiState,
                detailScrollController: detailScrollController,
                queueScrollController: queueScrollController,
                diffController: diffController,
                diffCommentHighlights: diffCommentHighlights,
                onDiffCommentAnchorSelected: onDiffCommentAnchorSelected,
                onDiffFileSelected: onDiffFileSelected,
                onDetailTabChanged: onDetailTabChanged,
                onOverviewFilterChanged: onOverviewFilterChanged,
                onItemSelected: onItemSelected,
                height: height - 5,
                width: width - 2,
              ),
            ),
            w.Divider(
              width: width - 2,
              style: theme.bodySmall.copy()..foreground(theme.border),
            ),
            _FooterRegion(
              detail: detail,
              uiState: uiState,
              themeName: themeChoice.label,
            ),
          ],
        ),
      ),
    );
  }
}

final class _TopBarRegion extends w.StatelessWidget {
  _TopBarRegion({
    required this.data,
    required this.queue,
    required this.width,
    required this.onTabChanged,
  });

  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final int width;
  final tui.Cmd? Function(int index) onTabChanged;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.ListenableBuilder(
      listenable: w.Listenable.merge([data, queue]),
      builder: (ctx, _) {
        final issueCount =
            data.issueTotalCount ?? data.dashboard?.openIssueCount ?? 0;
        final pullRequestCount =
            data.pullRequestTotalCount ??
            data.dashboard?.openPullRequestCount ??
            0;
        final workflowRunCount =
            data.workflowRunTotalCount ?? data.dashboard?.workflowRunCount ?? 0;
        return githubDashboardTopBar(
          theme: theme,
          dashboard: data.dashboard,
          repository: data.targetLabel,
          loading: data.loading,
          tabIndex: queue.tabIndex,
          issueCount: issueCount,
          pullRequestCount: pullRequestCount,
          workflowRunCount: workflowRunCount,
          pageStatus: data.pageStatusForTab(
            queue.tabIndex,
            overviewFilter: queue.overviewFilter,
          ),
          width: width,
          onTabChanged: onTabChanged,
        );
      },
    );
  }
}

final class _MainRegion extends w.StatelessWidget {
  _MainRegion({
    required this.data,
    required this.queue,
    required this.detail,
    required this.uiState,
    required this.detailScrollController,
    required this.queueScrollController,
    required this.diffController,
    required this.diffCommentHighlights,
    required this.onDiffCommentAnchorSelected,
    required this.onDiffFileSelected,
    required this.onDetailTabChanged,
    required this.onOverviewFilterChanged,
    required this.onItemSelected,
    required this.height,
    required this.width,
  });

  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final GithubDetailNotifier detail;
  final GithubDashboardUiState uiState;
  final w.ScrollController detailScrollController;
  final w.ScrollController queueScrollController;
  final w.GitDiffController diffController;
  final List<w.DiffCommentLineHighlight> diffCommentHighlights;
  final tui.Cmd? Function(w.DiffCommentAnchor anchor)
  onDiffCommentAnchorSelected;
  final tui.Cmd? Function(int index) onDiffFileSelected;
  final tui.Cmd? Function(int index) onDetailTabChanged;
  final tui.Cmd? Function(GithubOverviewFilter filter) onOverviewFilterChanged;
  final void Function(int index) onItemSelected;
  final int height;
  final int width;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.ListenableBuilder(
      listenable: data,
      builder: (ctx, _) {
        final dashboard = data.dashboard;
        if (_showSplash) {
          return GithubSplashScreen(repository: data.targetLabel);
        }
        if (data.error != null) return githubErrorPanel(theme, data.error!);
        if (dashboard == null) return githubEmptyPanel(theme);
        if (uiState.layoutMode.isFocused) {
          return _DetailRegion(
            data: data,
            queue: queue,
            detail: detail,
            dashboard: dashboard,
            uiState: uiState,
            controller: detailScrollController,
            diffController: diffController,
            diffCommentHighlights: diffCommentHighlights,
            onDiffCommentAnchorSelected: onDiffCommentAnchorSelected,
            onDiffFileSelected: onDiffFileSelected,
            onDetailTabChanged: onDetailTabChanged,
            height: height,
            width: width - 2,
          );
        }
        return _SplitBodyRegion(
          data: data,
          queue: queue,
          detail: detail,
          dashboard: dashboard,
          uiState: uiState,
          detailScrollController: detailScrollController,
          queueScrollController: queueScrollController,
          diffController: diffController,
          diffCommentHighlights: diffCommentHighlights,
          onDiffCommentAnchorSelected: onDiffCommentAnchorSelected,
          onDiffFileSelected: onDiffFileSelected,
          onDetailTabChanged: onDetailTabChanged,
          onOverviewFilterChanged: onOverviewFilterChanged,
          onItemSelected: onItemSelected,
          height: height,
          width: width,
        );
      },
    );
  }

  bool get _showSplash {
    if (data.error != null) return false;
    final dashboard = data.dashboard;
    if (dashboard == null) return data.loading;
    final status = data.pageStatusForTab(
      queue.tabIndex,
      overviewFilter: queue.overviewFilter,
    );
    if (!status.loading || status.error != null) return false;
    return status.loaded == 0 && queue.visibleItems.isEmpty;
  }
}

final class _SplitBodyRegion extends w.StatelessWidget {
  _SplitBodyRegion({
    required this.data,
    required this.queue,
    required this.detail,
    required this.dashboard,
    required this.uiState,
    required this.detailScrollController,
    required this.queueScrollController,
    required this.diffController,
    required this.diffCommentHighlights,
    required this.onDiffCommentAnchorSelected,
    required this.onDiffFileSelected,
    required this.onDetailTabChanged,
    required this.onOverviewFilterChanged,
    required this.onItemSelected,
    required this.height,
    required this.width,
  });

  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final GithubDetailNotifier detail;
  final GithubDashboardData dashboard;
  final GithubDashboardUiState uiState;
  final w.ScrollController detailScrollController;
  final w.ScrollController queueScrollController;
  final w.GitDiffController diffController;
  final List<w.DiffCommentLineHighlight> diffCommentHighlights;
  final tui.Cmd? Function(w.DiffCommentAnchor anchor)
  onDiffCommentAnchorSelected;
  final tui.Cmd? Function(int index) onDiffFileSelected;
  final tui.Cmd? Function(int index) onDetailTabChanged;
  final tui.Cmd? Function(GithubOverviewFilter filter) onOverviewFilterChanged;
  final void Function(int index) onItemSelected;
  final int height;
  final int width;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final leftWidth = width < 100 ? (width * 0.48).floor() : 58;
    return w.Row(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Container(
          width: leftWidth,
          child: _QueueRegion(
            data: data,
            queue: queue,
            controller: queueScrollController,
            width: leftWidth,
            onOverviewFilterChanged: onOverviewFilterChanged,
            onItemSelected: onItemSelected,
          ),
        ),
        w.VerticalDivider(
          height: height,
          style: theme.bodySmall.copy()..foreground(theme.border),
        ),
        w.Expanded(
          child: w.Container(
            padding: const w.EdgeInsets.only(left: 2),
            child: _DetailRegion(
              data: data,
              queue: queue,
              detail: detail,
              dashboard: dashboard,
              uiState: uiState,
              controller: detailScrollController,
              diffController: diffController,
              diffCommentHighlights: diffCommentHighlights,
              onDiffCommentAnchorSelected: onDiffCommentAnchorSelected,
              onDiffFileSelected: onDiffFileSelected,
              onDetailTabChanged: onDetailTabChanged,
              height: height,
              width: width - leftWidth - 3,
            ),
          ),
        ),
      ],
    );
  }
}

final class _QueueRegion extends w.StatelessWidget {
  _QueueRegion({
    required this.data,
    required this.queue,
    required this.controller,
    required this.width,
    required this.onOverviewFilterChanged,
    required this.onItemSelected,
  });

  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final w.ScrollController controller;
  final int width;
  final tui.Cmd? Function(GithubOverviewFilter filter) onOverviewFilterChanged;
  final void Function(int index) onItemSelected;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.ListenableBuilder(
      listenable: w.Listenable.merge([queue, data]),
      builder: (ctx, _) {
        return githubWorkQueuePane(
          theme: theme,
          tabIndex: queue.tabIndex,
          overviewFilter: queue.overviewFilter,
          selectedIndex: queue.selectedIndex,
          pageStatus: data.pageStatusForTab(
            queue.tabIndex,
            overviewFilter: queue.overviewFilter,
          ),
          items: queue.visibleItems,
          controller: controller,
          width: width,
          onOverviewFilterChanged: onOverviewFilterChanged,
          onItemSelected: onItemSelected,
          searchQuery: queue.searchQuery,
          searchLoading: queue.searchLoading,
          searchError: queue.searchError,
          searchPage: queue.searchPage,
          searchHasMore: queue.searchHasMore,
          searchPageLoading: queue.searchPageLoading,
        );
      },
    );
  }
}

final class _DetailRegion extends w.StatelessWidget {
  _DetailRegion({
    required this.data,
    required this.queue,
    required this.detail,
    required this.dashboard,
    required this.uiState,
    required this.controller,
    required this.diffController,
    required this.diffCommentHighlights,
    required this.onDiffCommentAnchorSelected,
    required this.onDiffFileSelected,
    required this.onDetailTabChanged,
    required this.height,
    required this.width,
  });

  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final GithubDetailNotifier detail;
  final GithubDashboardData dashboard;
  final GithubDashboardUiState uiState;
  final w.ScrollController controller;
  final w.GitDiffController diffController;
  final List<w.DiffCommentLineHighlight> diffCommentHighlights;
  final tui.Cmd? Function(w.DiffCommentAnchor anchor)
  onDiffCommentAnchorSelected;
  final tui.Cmd? Function(int index) onDiffFileSelected;
  final tui.Cmd? Function(int index) onDetailTabChanged;
  final int height;
  final int width;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.ListenableBuilder(
      listenable: w.Listenable.merge([queue, detail]),
      builder: (ctx, _) {
        return githubDetailPane(
          theme: theme,
          dashboard: dashboard,
          selectedItem: queue.selectedItem,
          navigating: queue.navigating,
          controller: controller,
          commentsItem: detail.commentsItem,
          comments: detail.comments,
          commentsLoading: detail.commentsLoading,
          commentsError: detail.commentsError,
          commitsItem: detail.commitsItem,
          commits: detail.commits,
          commitsLoading: detail.commitsLoading,
          commitsError: detail.commitsError,
          reviewCommentsItem: detail.reviewCommentsItem,
          reviewComments: detail.reviewComments,
          reviewCommentsLoading: detail.reviewCommentsLoading,
          reviewCommentsError: detail.reviewCommentsError,
          diffItem: detail.diffItem,
          diff: detail.diff,
          diffFiles: detail.diffFiles,
          diffFileIndex: detail.diffFileIndex,
          diffLoading: detail.diffLoading,
          diffError: detail.diffError,
          diffReviewComments: detail.diffReviewComments,
          diffViewMode: uiState.diffViewMode,
          diffController: diffController,
          diffCommentHighlights: diffCommentHighlights,
          onDiffCommentAnchorSelected: onDiffCommentAnchorSelected,
          onDiffFileSelected: onDiffFileSelected,
          mergeInfoItem: null,
          mergeInfo: null,
          mergeInfoLoading: detail.mergeInfoLoading,
          mergeInfoError: detail.mergeInfoError,
          repositoryLabelsItem: null,
          repositoryLabels: const <GithubRepositoryLabel>[],
          repositoryLabelsLoading: detail.repositoryLabelsLoading,
          repositoryLabelsError: detail.repositoryLabelsError,
          runDetailItem: detail.runDetailItem,
          runDetail: detail.runDetail,
          runDetailLoading: detail.runDetailLoading,
          runDetailError: detail.runDetailError,
          onTabChanged: onDetailTabChanged,
          height: height,
          width: width,
        );
      },
    );
  }
}

final class _FooterRegion extends w.StatelessWidget {
  _FooterRegion({
    required this.detail,
    required this.uiState,
    required this.themeName,
  });

  final GithubDetailNotifier detail;
  final GithubDashboardUiState uiState;
  final String themeName;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.ListenableBuilder(
      listenable: detail,
      builder: (ctx, _) {
        return githubDashboardFooter(
          theme,
          notice: detail.notice,
          layoutMode: uiState.layoutMode,
          themeName: themeName,
        );
      },
    );
  }
}
