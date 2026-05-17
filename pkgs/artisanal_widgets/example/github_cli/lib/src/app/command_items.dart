import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/action_prompt.dart';
import '../models/display_item.dart';
import '../state/notifiers.dart';
import 'ui_state.dart';

final class GithubDashboardCommandItems {
  GithubDashboardCommandItems({
    required this.uiState,
    required this.queue,
    required this.data,
    required this.paletteAction,
    required this.openRepositoryPrompt,
    required this.openRepositoryList,
    required this.loadDashboard,
    required this.loadCurrentPage,
    required this.openSelectedUrl,
    required this.toggleFocusedView,
    required this.cycleTheme,
    required this.switchTab,
    required this.openSelectedDetail,
    required this.openSelectedComments,
    required this.openSelectedCommits,
    required this.openSelectedReviewComments,
    required this.openSelectedDiff,
    required this.openSelectedMergeInfo,
    required this.openSelectedRunDetail,
    required this.openSelectedRepositoryLabels,
    required this.openActionPrompt,
    required this.toggleSelectedPullRequestDraft,
    required this.openSearch,
  });

  final GithubDashboardUiState uiState;
  final GithubQueueNotifier queue;
  final GithubDataNotifier data;
  final tui.Cmd? Function(tui.Cmd? Function() action) paletteAction;
  final tui.Cmd Function() openRepositoryPrompt;
  final tui.Cmd Function() openRepositoryList;
  final tui.Cmd Function({bool clearDashboard}) loadDashboard;
  final tui.Cmd Function({required bool replace}) loadCurrentPage;
  final tui.Cmd Function() openSelectedUrl;
  final tui.Cmd Function() toggleFocusedView;
  final tui.Cmd Function() cycleTheme;
  final tui.Cmd Function(int index) switchTab;
  final tui.Cmd Function() openSelectedDetail;
  final tui.Cmd Function() openSelectedComments;
  final tui.Cmd Function() openSelectedCommits;
  final tui.Cmd Function() openSelectedReviewComments;
  final tui.Cmd Function() openSelectedDiff;
  final tui.Cmd Function() openSelectedMergeInfo;
  final tui.Cmd Function({bool focus}) openSelectedRunDetail;
  final tui.Cmd Function() openSelectedRepositoryLabels;
  final tui.Cmd Function(GithubActionPromptKind kind) openActionPrompt;
  final tui.Cmd Function() toggleSelectedPullRequestDraft;
  final tui.Cmd Function() openSearch;

  List<w.CommandPaletteItem> build() {
    final item = queue.selectedItem;
    final hasSelection = item != null;
    final supportsIssueActions = item?.supportsIssueActions ?? false;
    final isPullRequest = item?.target == GithubDisplayTarget.pullRequest;
    final isRun = item?.target == GithubDisplayTarget.workflowRun;
    final canOpen =
        (item?.url ?? data.dashboard?.repository.url ?? '').isNotEmpty;
    final pageStatus = data.pageStatusForTab(
      queue.tabIndex,
      overviewFilter: queue.overviewFilter,
    );
    final hasRepositories =
        (data.dashboard?.repositories ?? const []).isNotEmpty;

    return [
      w.CommandPaletteItem(
        label: 'Switch target',
        description: 'Open @me, owner/org, repo, or URL.',
        shortcut: 'ctrl+o',
        group: 'Target',
        tags: const ['me', 'owner', 'org', 'repo', 'project', 'remote'],
        onSelect: () => paletteAction(openRepositoryPrompt),
      ),
      w.CommandPaletteItem(
        label: 'Browse repos',
        description: 'Choose from loaded owner/org repos.',
        group: 'Target',
        tags: const ['repository', 'repositories', 'owner', 'org', 'browse'],
        enabled: hasRepositories,
        onSelect: () => paletteAction(openRepositoryList),
      ),
      w.CommandPaletteItem(
        label: 'Refresh dashboard',
        description: 'Reload the active target.',
        shortcut: 'r',
        group: 'Target',
        tags: const ['reload', 'sync', 'gh'],
        onSelect: () => paletteAction(() => loadDashboard()),
      ),
      w.CommandPaletteItem(
        label: 'Load next page',
        description: 'Fetch more for the active list.',
        shortcut: 'n',
        group: 'Target',
        tags: const ['page', 'more', 'browse'],
        enabled:
            queue.tabIndex != 0 &&
            pageStatus.hasNextPage &&
            !pageStatus.loading,
        onSelect: () => paletteAction(() => loadCurrentPage(replace: false)),
      ),
      w.CommandPaletteItem(
        label: 'Open in browser',
        description: 'Open selected item or target URL.',
        shortcut: 'o',
        group: 'Navigation',
        tags: const ['browser', 'url', 'github'],
        enabled: canOpen,
        onSelect: () => paletteAction(openSelectedUrl),
      ),
      w.CommandPaletteItem(
        label: uiState.layoutMode.isFocused
            ? 'Return to split view'
            : 'Focus item',
        description: uiState.layoutMode.isFocused
            ? 'Restore the work queue and detail split layout.'
            : 'Use the full viewport for this item.',
        shortcut: 'f',
        group: 'Navigation',
        tags: const ['focus', 'layout', 'single pane'],
        enabled: hasSelection,
        onSelect: () => paletteAction(toggleFocusedView),
      ),
      w.CommandPaletteItem(
        label: 'Cycle theme',
        description: 'Switch between GitHub dashboard color themes.',
        shortcut: 't',
        group: 'Appearance',
        tags: const ['theme', 'color', 'skin'],
        onSelect: () => paletteAction(cycleTheme),
      ),
      w.CommandPaletteItem(
        label: 'Overview tab',
        shortcut: '1',
        group: 'Navigation',
        tags: const ['home', 'summary'],
        onSelect: () => paletteAction(() => switchTab(0)),
      ),
      w.CommandPaletteItem(
        label: 'Issues tab',
        shortcut: '2',
        group: 'Navigation',
        tags: const ['bugs', 'tickets'],
        onSelect: () => paletteAction(() => switchTab(1)),
      ),
      w.CommandPaletteItem(
        label: 'Pull requests tab',
        shortcut: '3',
        group: 'Navigation',
        tags: const ['prs', 'reviews', 'diff'],
        onSelect: () => paletteAction(() => switchTab(2)),
      ),
      w.CommandPaletteItem(
        label: 'Actions tab',
        shortcut: '4',
        group: 'Navigation',
        tags: const ['runs', 'workflows', 'ci'],
        onSelect: () => paletteAction(() => switchTab(3)),
      ),
      w.CommandPaletteItem(
        label: 'Search PRs & Issues',
        description: 'Search across open PRs and issues with a free-text query.',
        shortcut: '/',
        group: 'Navigation',
        tags: const ['search', 'find', 'query', 'filter'],
        onSelect: () => paletteAction(openSearch),
      ),
      w.CommandPaletteItem(
        label: 'View details',
        description: 'Focus the selected issue or PR in the full viewport.',
        shortcut: 'enter',
        group: 'Selection',
        tags: const ['body', 'description'],
        enabled: hasSelection && !isRun,
        onSelect: () => paletteAction(openSelectedDetail),
      ),
      w.CommandPaletteItem(
        label: 'Show comments',
        description: 'Load all comments into the right conversation pane.',
        shortcut: 'c',
        group: 'Selection',
        tags: const ['conversation', 'discussion', 'thread'],
        enabled: supportsIssueActions,
        onSelect: () => paletteAction(openSelectedComments),
      ),
      w.CommandPaletteItem(
        label: 'Show commits',
        description: 'Load pull request commits into the detail pane.',
        group: 'Selection',
        tags: const ['commit', 'commits', 'history', 'sha'],
        enabled: isPullRequest,
        onSelect: () => paletteAction(openSelectedCommits),
      ),
      w.CommandPaletteItem(
        label: 'Show review comments',
        description: 'Load PR file review comments from the GitHub API.',
        shortcut: 'v',
        group: 'Selection',
        tags: const ['review', 'diff', 'comments'],
        enabled: isPullRequest,
        onSelect: () => paletteAction(openSelectedReviewComments),
      ),
      w.CommandPaletteItem(
        label: 'Show pull request diff',
        description: 'Load the PR diff into the right diff pane.',
        shortcut: 'd',
        group: 'Selection',
        tags: const ['files', 'patch', 'changes'],
        enabled: isPullRequest,
        onSelect: () => paletteAction(openSelectedDiff),
      ),
      w.CommandPaletteItem(
        label: 'Show merge readiness',
        description: 'Open mergeability, methods, and checks in a modal.',
        shortcut: 'm',
        group: 'Selection',
        tags: const ['merge', 'checks', 'review'],
        enabled: isPullRequest,
        onSelect: () => paletteAction(openSelectedMergeInfo),
      ),
      w.CommandPaletteItem(
        label: 'Show run info',
        description: 'Load workflow jobs and steps into the right pane.',
        shortcut: 'i',
        group: 'Selection',
        tags: const ['actions', 'jobs', 'steps', 'ci'],
        enabled: isRun,
        onSelect: () => paletteAction(() => openSelectedRunDetail()),
      ),
      w.CommandPaletteItem(
        label: 'Manage labels',
        description: 'Filter repository labels and toggle them on this item.',
        shortcut: 'l',
        group: 'Selection',
        tags: const ['labels', 'repo', 'metadata'],
        enabled: supportsIssueActions,
        onSelect: () => paletteAction(openSelectedRepositoryLabels),
      ),
      w.CommandPaletteItem(
        label: 'Add comment',
        shortcut: 'a',
        group: 'Mutate',
        tags: const ['reply', 'discussion'],
        enabled: supportsIssueActions,
        onSelect: () => paletteAction(
          () => openActionPrompt(GithubActionPromptKind.addComment),
        ),
      ),
      w.CommandPaletteItem(
        label: 'Toggle labels',
        shortcut: 'l',
        group: 'Mutate',
        tags: const ['label', 'metadata'],
        enabled: supportsIssueActions,
        onSelect: () => paletteAction(openSelectedRepositoryLabels),
      ),
      w.CommandPaletteItem(
        label: 'Remove labels',
        shortcut: 'x',
        group: 'Mutate',
        tags: const ['label', 'metadata'],
        enabled: supportsIssueActions,
        onSelect: () => paletteAction(openSelectedRepositoryLabels),
      ),
      w.CommandPaletteItem(
        label: 'Merge pull request',
        shortcut: 'm',
        group: 'Mutate',
        tags: const ['merge', 'auto-merge', 'squash', 'rebase'],
        enabled: isPullRequest,
        onSelect: () => paletteAction(openSelectedMergeInfo),
      ),
      w.CommandPaletteItem(
        label: 'Toggle ready/draft',
        group: 'Mutate',
        tags: const ['draft', 'ready'],
        enabled: isPullRequest,
        onSelect: () => paletteAction(toggleSelectedPullRequestDraft),
      ),
      w.CommandPaletteItem(
        label: 'Close pull request',
        group: 'Mutate',
        tags: const ['close', 'danger'],
        enabled: isPullRequest,
        onSelect: () => paletteAction(
          () => openActionPrompt(GithubActionPromptKind.closePullRequest),
        ),
      ),
      w.CommandPaletteItem(
        label: 'Quit',
        shortcut: 'q',
        group: 'Application',
        tags: const ['exit', 'close'],
        onSelect: () => paletteAction(tui.Cmd.quit),
      ),
    ];
  }
}
