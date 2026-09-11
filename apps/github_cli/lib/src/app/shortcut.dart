import 'package:artisanal/tui.dart' as tui;

enum GithubDashboardShortcut {
  quit,
  refresh,
  overviewTab,
  issuesTab,
  pullRequestsTab,
  actionsTab,
  nextItem,
  previousItem,
  nextPage,
  previousPage,
  nextTab,
  previousTab,
  loadNextPage,
  openBrowser,
  viewDetails,
  viewDiff,
  viewRunInfo,
  viewComments,
  viewReviewComments,
  viewMergeInfo,
  viewRepositoryLabels,
  addComment,
  addLabels,
  removeLabels,
  commandPalette,
  switchRepository,
  toggleFocusedView,
  cycleTheme,
  search,
}

GithubDashboardShortcut? githubDashboardShortcutFor(tui.KeyMsg msg) {
  final key = msg.key;
  if (key.isChar('o', requireNoModifiers: false) && key.ctrl) {
    return GithubDashboardShortcut.switchRepository;
  }
  if (key.isChar('p', requireNoModifiers: false) && key.ctrl) {
    return GithubDashboardShortcut.commandPalette;
  }
  if (key.isChar('q')) return GithubDashboardShortcut.quit;
  if (key.isChar('r')) return GithubDashboardShortcut.refresh;
  if (key.isChar('f')) return GithubDashboardShortcut.toggleFocusedView;
  if (key.isChar('t')) return GithubDashboardShortcut.cycleTheme;
  if (key.isChar('n')) return GithubDashboardShortcut.loadNextPage;
  if (key.isChar('1')) return GithubDashboardShortcut.overviewTab;
  if (key.isChar('2')) return GithubDashboardShortcut.issuesTab;
  if (key.isChar('3')) return GithubDashboardShortcut.pullRequestsTab;
  if (key.isChar('4')) return GithubDashboardShortcut.actionsTab;
  if (key.isChar('j') || key.type == tui.KeyType.down) {
    return GithubDashboardShortcut.nextItem;
  }
  if (key.isChar('k') || key.type == tui.KeyType.up) {
    return GithubDashboardShortcut.previousItem;
  }
  if (key.type == tui.KeyType.pageDown ||
      key.isChar('d', requireNoModifiers: false) && key.ctrl) {
    return GithubDashboardShortcut.nextPage;
  }
  if (key.type == tui.KeyType.pageUp ||
      key.isChar('u', requireNoModifiers: false) && key.ctrl) {
    return GithubDashboardShortcut.previousPage;
  }
  if (key.type == tui.KeyType.tab || key.type == tui.KeyType.right) {
    return GithubDashboardShortcut.nextTab;
  }
  if (key.type == tui.KeyType.left) {
    return GithubDashboardShortcut.previousTab;
  }
  if (key.isChar('o')) {
    return GithubDashboardShortcut.openBrowser;
  }
  if (key.isChar('d')) {
    return GithubDashboardShortcut.viewDiff;
  }
  if (key.isChar('i')) {
    return GithubDashboardShortcut.viewRunInfo;
  }
  if (key.isChar('c')) {
    return GithubDashboardShortcut.viewComments;
  }
  if (key.isChar('v')) {
    return GithubDashboardShortcut.viewReviewComments;
  }
  if (key.isChar('m')) {
    return GithubDashboardShortcut.viewMergeInfo;
  }
  if (key.isChar('b')) {
    return GithubDashboardShortcut.viewRepositoryLabels;
  }
  if (key.isChar('a')) {
    return GithubDashboardShortcut.addComment;
  }
  if (key.isChar('l')) {
    return GithubDashboardShortcut.addLabels;
  }
  if (key.isChar('x')) {
    return GithubDashboardShortcut.removeLabels;
  }
  if (key.isChar('p')) {
    return GithubDashboardShortcut.commandPalette;
  }
  if (key.isChar('/') && !key.shift) {
    return GithubDashboardShortcut.search;
  }
  if (key.type == tui.KeyType.enter) {
    return GithubDashboardShortcut.viewDetails;
  }
  return null;
}
