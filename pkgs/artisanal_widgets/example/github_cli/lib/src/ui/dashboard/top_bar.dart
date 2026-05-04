import 'package:artisanal/style.dart' show Colors;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/dashboard_data.dart';
import '../../utils/time.dart';

w.Widget githubDashboardTopBar({
  required w.Theme theme,
  required GithubDashboardData? dashboard,
  required String? repository,
  required bool loading,
  required int tabIndex,
  required int issueCount,
  required int pullRequestCount,
  required int workflowRunCount,
  required GithubPageStatus pageStatus,
  required int width,
  required tui.Cmd? Function(int index) onTabChanged,
}) {
  final repo = dashboard?.repository;
  final title = repo?.nameWithOwner ?? repository ?? 'current gh repo';
  final updated = dashboard == null
      ? 'loading'
      : 'updated ${shortGithubTime(dashboard.loadedAt)}';
  final status = _pageStatusLabel(tabIndex, pageStatus);

  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    children: [
      w.Row(
        children: [
          w.Text(
            'GHUI',
            style: theme.titleLarge.copy()..foreground(Colors.cyan),
          ),
          w.Spacer(size: 2),
          w.Text(title, style: theme.titleMedium),
          w.Spacer(),
          if (width >= 92)
            _topTabs(
              tabIndex: tabIndex,
              issueCount: issueCount,
              pullRequestCount: pullRequestCount,
              workflowRunCount: workflowRunCount,
              onTabChanged: onTabChanged,
            ),
          if (width >= 92) w.Spacer(size: 2),
          if (loading) w.SpinnerIndicator(),
          if (loading) w.Spacer(size: 1),
          if (status != null) ...[
            w.Text(
              status,
              style: theme.bodySmall.copy()..foreground(theme.muted),
            ),
            w.Spacer(size: 2),
          ],
          w.Text(
            updated,
            style: theme.bodySmall.copy()..foreground(theme.muted),
          ),
        ],
      ),
      if (width < 92)
        _topTabs(
          tabIndex: tabIndex,
          issueCount: issueCount,
          pullRequestCount: pullRequestCount,
          workflowRunCount: workflowRunCount,
          onTabChanged: onTabChanged,
        ),
      w.Divider(
        width: width,
        style: theme.bodySmall.copy()..foreground(theme.border),
      ),
    ],
  );
}

w.Widget _topTabs({
  required int tabIndex,
  required int issueCount,
  required int pullRequestCount,
  required int workflowRunCount,
  required tui.Cmd? Function(int index) onTabChanged,
}) {
  return w.Tabs(
    index: tabIndex,
    gap: 1,
    size: w.ButtonSize.small,
    onChanged: onTabChanged,
    tabs: [
      const w.TabItem('1 Overview'),
      w.TabItem('2 Issues $issueCount'),
      w.TabItem('3 PRs $pullRequestCount'),
      w.TabItem('4 Actions $workflowRunCount'),
    ],
  );
}

String? _pageStatusLabel(int tabIndex, GithubPageStatus pageStatus) {
  if (tabIndex == 0) return null;
  if (pageStatus.loading) return 'loading page...';
  if (pageStatus.hasNextPage) return '${pageStatus.countLabel} loaded · n more';
  return '${pageStatus.countLabel} loaded';
}
