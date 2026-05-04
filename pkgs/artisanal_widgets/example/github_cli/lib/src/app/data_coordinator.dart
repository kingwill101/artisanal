import 'package:artisanal/tui.dart' as tui;

import '../client/client.dart';
import '../models/dashboard_data.dart';
import '../state/notifiers.dart';
import 'messages.dart';

final class GithubDashboardDataCoordinator {
  GithubDashboardDataCoordinator({
    required this.client,
    required this.limit,
    required this.data,
    required this.queue,
    required this.detail,
    required this.resetScroll,
    required this.keepSelectionVisible,
  });

  final GithubDashboardClient Function() client;
  final int Function() limit;
  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final GithubDetailNotifier detail;
  final void Function() resetScroll;
  final void Function() keepSelectionVisible;

  bool handlesMessage(tui.Msg msg) {
    return msg is GithubDashboardLoadedMsg ||
        msg is GithubDashboardFailedMsg ||
        msg is GithubOverviewLoadedMsg ||
        msg is GithubOverviewFailedMsg ||
        msg is GithubIssuesPageLoadedMsg ||
        msg is GithubPullRequestsPageLoadedMsg ||
        msg is GithubWorkflowRunsPageLoadedMsg ||
        msg is GithubPageFailedMsg;
  }

  tui.Cmd? handleMessage(tui.Msg msg) {
    if (msg is GithubDashboardLoadedMsg) return _applyLoaded(msg.dashboard);
    if (msg is GithubDashboardFailedMsg) return _applyError(msg.message);
    if (msg is GithubOverviewLoadedMsg) return _applyOverview(msg);
    if (msg is GithubOverviewFailedMsg) return _applyOverviewError(msg);
    if (msg is GithubIssuesPageLoadedMsg) return _applyIssuesPage(msg);
    if (msg is GithubPullRequestsPageLoadedMsg) {
      return _applyPullRequestsPage(msg);
    }
    if (msg is GithubWorkflowRunsPageLoadedMsg) {
      return _applyWorkflowRunsPage(msg);
    }
    if (msg is GithubPageFailedMsg) return _applyPageError(msg);
    return null;
  }

  tui.Cmd loadDashboard({bool clearDashboard = false}) {
    data.startLoading(clearDashboard: clearDashboard);
    queue.batchApply(
      dashboard: () => null,
      resetSelection: true,
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    detail.closeAllInlineDetails();
    final repository = data.effectiveRepository;
    return tui.Cmd(() async {
      try {
        final dashboard = await client().loadDashboard(
          repository: repository,
          owner: data.owner,
          limit: limit(),
        );
        return GithubDashboardLoadedMsg(dashboard);
      } catch (error) {
        return GithubDashboardFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd loadCurrentPage({required bool replace}) {
    final repository = data.effectiveRepository;
    final tabIndex = queue.tabIndex;
    if (tabIndex == 0) return _loadOverview(replace: replace);
    if (repository == null) return tui.Cmd.none();
    if (!replace && !data.hasNextPageForTab(tabIndex)) return tui.Cmd.none();
    final cursor = replace ? null : data.cursorForTab(tabIndex);
    final page = replace ? 1 : data.nextPageForTab(tabIndex);
    data.startPageLoading(tabIndex, replace: replace);
    queue.batchApply(
      pageStatus: data.pageStatusForTab(
        tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    return tui.Cmd(() async {
      try {
        return switch (tabIndex) {
          1 => GithubIssuesPageLoadedMsg(
            await client().loadIssuesPage(
              repository: repository,
              first: limit(),
              after: cursor,
            ),
            replace: replace,
          ),
          2 => GithubPullRequestsPageLoadedMsg(
            await client().loadPullRequestsPage(
              repository: repository,
              first: limit(),
              after: cursor,
            ),
            replace: replace,
          ),
          3 => GithubWorkflowRunsPageLoadedMsg(
            await client().loadWorkflowRunsPage(
              repository: repository,
              first: limit(),
              page: page,
            ),
            replace: replace,
          ),
          _ => const GithubOpenedUrlMsg(),
        };
      } catch (error) {
        return GithubPageFailedMsg(tabIndex, error.toString());
      }
    });
  }

  tui.Cmd? _applyLoaded(GithubDashboardData dashboard) {
    data.applyLoaded(dashboard);
    queue.batchApply(
      dashboard: () => data.dashboard,
      resetSelection: true,
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    resetScroll();
    return data.hasLoadedTab(
          queue.tabIndex,
          overviewFilter: queue.overviewFilter,
        )
        ? null
        : loadCurrentPage(replace: true);
  }

  tui.Cmd? _applyError(String message) {
    data.applyError(message);
    return null;
  }

  tui.Cmd? _applyIssuesPage(GithubIssuesPageLoadedMsg msg) {
    data.applyIssuesPage(msg.page, replace: msg.replace);
    queue.batchApply(
      dashboard: () => data.dashboard,
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    keepSelectionVisible();
    return null;
  }

  tui.Cmd? _applyPullRequestsPage(GithubPullRequestsPageLoadedMsg msg) {
    data.applyPullRequestsPage(msg.page, replace: msg.replace);
    queue.batchApply(
      dashboard: () => data.dashboard,
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    keepSelectionVisible();
    return null;
  }

  tui.Cmd? _applyWorkflowRunsPage(GithubWorkflowRunsPageLoadedMsg msg) {
    data.applyWorkflowRunsPage(msg.page, replace: msg.replace);
    queue.batchApply(
      dashboard: () => data.dashboard,
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    keepSelectionVisible();
    return null;
  }

  tui.Cmd? _applyPageError(GithubPageFailedMsg msg) {
    data.applyPageError(msg.message);
    queue.batchApply(
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    return null;
  }

  tui.Cmd _loadOverview({required bool replace}) {
    final dashboard = data.dashboard;
    if (dashboard == null) return tui.Cmd.none();
    final filter = queue.overviewFilter;
    if (!replace && data.hasLoadedOverviewFilter(filter)) {
      return tui.Cmd.none();
    }
    data.startOverviewLoading(filter);
    queue.batchApply(
      pageStatus: data.pageStatusForTab(0, overviewFilter: filter),
    );
    return tui.Cmd(() async {
      try {
        final bucket = await client().loadOverview(
          scope: dashboard.resolvedScope,
          filter: filter,
          limit: limit(),
        );
        return GithubOverviewLoadedMsg(filter, bucket);
      } catch (error) {
        return GithubOverviewFailedMsg(filter, error.toString());
      }
    });
  }

  tui.Cmd? _applyOverview(GithubOverviewLoadedMsg msg) {
    data.applyOverview(msg.filter, msg.bucket);
    queue.batchApply(
      dashboard: () => data.dashboard,
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    keepSelectionVisible();
    return null;
  }

  tui.Cmd? _applyOverviewError(GithubOverviewFailedMsg msg) {
    data.applyOverviewError(msg.filter, msg.message);
    queue.batchApply(
      pageStatus: data.pageStatusForTab(
        queue.tabIndex,
        overviewFilter: queue.overviewFilter,
      ),
    );
    return null;
  }
}
