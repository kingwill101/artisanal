import '../models/action_prompt.dart';
import '../models/dashboard_data.dart';
import '../models/display_item.dart';
import '../utils/repository_input.dart';

final class GithubDashboardSession {
  GithubDashboardSession({String? repository})
    : repository = normalizeGithubRepositoryInput(repository);

  GithubDashboardData? dashboard;
  String? repository;
  String? error;
  String? repoPromptError;
  String? notice;
  GithubDisplayItem? detailItem;
  GithubDisplayItem? diffItem;
  String diff = '';
  bool diffLoading = false;
  String? diffError;
  GithubDisplayItem? runDetailItem;
  GithubWorkflowRunDetail? runDetail;
  bool runDetailLoading = false;
  String? runDetailError;
  GithubDisplayItem? reviewCommentsItem;
  List<GithubPullRequestReviewComment> reviewComments =
      const <GithubPullRequestReviewComment>[];
  bool reviewCommentsLoading = false;
  String? reviewCommentsError;
  GithubDisplayItem? mergeInfoItem;
  GithubPullRequestMergeInfo? mergeInfo;
  bool mergeInfoLoading = false;
  String? mergeInfoError;
  GithubDisplayItem? repositoryLabelsItem;
  List<GithubRepositoryLabel> repositoryLabels =
      const <GithubRepositoryLabel>[];
  bool repositoryLabelsLoading = false;
  String? repositoryLabelsError;
  GithubDisplayItem? commentsItem;
  List<GithubCommentItem> comments = const <GithubCommentItem>[];
  bool commentsLoading = false;
  String? commentsError;
  GithubActionPrompt? actionPrompt;
  String? actionPromptError;
  bool actionRunning = false;
  bool loading = false;
  bool repoPromptOpen = false;
  bool commandPaletteOpen = false;
  int tabIndex = 2;
  GithubOverviewFilter overviewFilter = GithubOverviewFilter.authored;
  int selectedIndex = 0;
  bool pageLoading = false;
  int? pageLoadingTab;
  String? pageError;
  String? issueCursor;
  String? pullRequestCursor;
  int workflowRunNextPage = 1;
  int? issueTotalCount;
  int? pullRequestTotalCount;
  int? workflowRunTotalCount;
  bool issueHasNextPage = true;
  bool pullRequestHasNextPage = true;
  bool workflowRunHasNextPage = true;

  List<GithubDisplayItem> get visibleItems {
    final data = dashboard;
    if (data == null) return const <GithubDisplayItem>[];
    return githubDisplayItemsForTab(data, tabIndex, overviewFilter);
  }

  GithubDisplayItem? get selectedItem {
    final items = visibleItems;
    if (items.isEmpty || selectedIndex >= items.length) return null;
    return items[selectedIndex];
  }

  String? get selectedUrl {
    return selectedItem?.url ?? dashboard?.repository.url;
  }

  void setRepositoryInput(String? input) {
    repository = normalizeGithubRepositoryInput(input);
  }

  void startLoading({bool clearDashboard = false}) {
    loading = true;
    error = null;
    detailItem = null;
    diffItem = null;
    diff = '';
    diffError = null;
    diffLoading = false;
    runDetailItem = null;
    runDetail = null;
    runDetailError = null;
    runDetailLoading = false;
    commentsItem = null;
    comments = const <GithubCommentItem>[];
    commentsError = null;
    commentsLoading = false;
    reviewCommentsItem = null;
    reviewComments = const <GithubPullRequestReviewComment>[];
    reviewCommentsError = null;
    reviewCommentsLoading = false;
    mergeInfoItem = null;
    mergeInfo = null;
    mergeInfoError = null;
    mergeInfoLoading = false;
    repositoryLabelsItem = null;
    repositoryLabels = const <GithubRepositoryLabel>[];
    repositoryLabelsError = null;
    repositoryLabelsLoading = false;
    pageLoading = false;
    pageLoadingTab = null;
    pageError = null;
    issueCursor = null;
    pullRequestCursor = null;
    workflowRunNextPage = 1;
    issueTotalCount = null;
    pullRequestTotalCount = null;
    workflowRunTotalCount = null;
    issueHasNextPage = true;
    pullRequestHasNextPage = true;
    workflowRunHasNextPage = true;
    if (clearDashboard) dashboard = null;
  }

  void applyLoaded(GithubDashboardData data) {
    dashboard = data;
    repository = data.repository.nameWithOwner;
    error = null;
    loading = false;
    if (data.issues.isNotEmpty) {
      issueTotalCount = data.issues.length;
      issueHasNextPage = false;
    }
    if (data.pullRequests.isNotEmpty) {
      pullRequestTotalCount = data.pullRequests.length;
      pullRequestHasNextPage = false;
    }
    if (data.workflowRuns.isNotEmpty) {
      workflowRunTotalCount = data.workflowRuns.length;
      workflowRunHasNextPage = false;
    }
    selectedIndex = 0;
    closeInlineDetails();
  }

  bool get canLoadCurrentPage {
    return tabIndex != 0 && hasNextPageForTab(tabIndex) && !pageLoading;
  }

  bool hasLoadedTab(int index) {
    final data = dashboard;
    if (data == null) return false;
    return switch (index) {
      1 => data.issues.isNotEmpty || issueTotalCount != null,
      2 => data.pullRequests.isNotEmpty || pullRequestTotalCount != null,
      3 => data.workflowRuns.isNotEmpty || workflowRunTotalCount != null,
      _ => true,
    };
  }

  bool hasNextPageForTab(int index) {
    return switch (index) {
      1 => issueHasNextPage,
      2 => pullRequestHasNextPage,
      3 => workflowRunHasNextPage,
      _ => false,
    };
  }

  String? cursorForTab(int index) {
    return switch (index) {
      1 => issueCursor,
      2 => pullRequestCursor,
      _ => null,
    };
  }

  int nextPageForTab(int index) {
    return switch (index) {
      3 => workflowRunNextPage,
      _ => 1,
    };
  }

  GithubPageStatus pageStatusForTab(int index) {
    final data = dashboard;
    final loaded = switch (index) {
      1 => data?.issues.length ?? 0,
      2 => data?.pullRequests.length ?? 0,
      3 => data?.workflowRuns.length ?? 0,
      _ => visibleItems.length,
    };
    final total = switch (index) {
      1 => issueTotalCount,
      2 => pullRequestTotalCount,
      3 => workflowRunTotalCount,
      _ => null,
    };
    return GithubPageStatus(
      loaded: loaded,
      totalCount: total,
      hasNextPage: hasNextPageForTab(index),
      loading: pageLoading && pageLoadingTab == index,
      error: pageError,
    );
  }

  void startPageLoading(int index, {required bool replace}) {
    pageLoading = true;
    pageLoadingTab = index;
    pageError = null;
    if (replace) {
      closeInlineDetails();
      selectedIndex = 0;
      if (index == 1) {
        issueCursor = null;
        issueTotalCount = null;
        issueHasNextPage = true;
      } else if (index == 2) {
        pullRequestCursor = null;
        pullRequestTotalCount = null;
        pullRequestHasNextPage = true;
      } else if (index == 3) {
        workflowRunNextPage = 1;
        workflowRunTotalCount = null;
        workflowRunHasNextPage = true;
      }
    }
  }

  void applyIssuesPage(
    GithubPage<GithubIssueItem> page, {
    required bool replace,
  }) {
    final data = dashboard;
    if (data == null) return;
    dashboard = data.copyWith(
      issues: replace ? page.items : [...data.issues, ...page.items],
      loadedAt: DateTime.now(),
    );
    issueTotalCount = page.totalCount;
    issueHasNextPage = page.hasNextPage;
    issueCursor = (page.endCursor?.isEmpty ?? true) ? null : page.endCursor;
    _finishPageLoading();
  }

  void applyPullRequestsPage(
    GithubPage<GithubPullRequestItem> page, {
    required bool replace,
  }) {
    final data = dashboard;
    if (data == null) return;
    dashboard = data.copyWith(
      pullRequests: replace
          ? page.items
          : [...data.pullRequests, ...page.items],
      loadedAt: DateTime.now(),
    );
    pullRequestTotalCount = page.totalCount;
    pullRequestHasNextPage = page.hasNextPage;
    pullRequestCursor = (page.endCursor?.isEmpty ?? true)
        ? null
        : page.endCursor;
    _finishPageLoading();
  }

  void applyWorkflowRunsPage(
    GithubPage<GithubWorkflowRunItem> page, {
    required bool replace,
  }) {
    final data = dashboard;
    if (data == null) return;
    dashboard = data.copyWith(
      workflowRuns: replace
          ? page.items
          : [...data.workflowRuns, ...page.items],
      loadedAt: DateTime.now(),
    );
    workflowRunTotalCount = page.totalCount;
    workflowRunHasNextPage = page.hasNextPage;
    workflowRunNextPage = page.nextPage ?? workflowRunNextPage + 1;
    _finishPageLoading();
  }

  void applyPageError(String message) {
    pageError = message;
    pageLoading = false;
    pageLoadingTab = null;
  }

  void _finishPageLoading() {
    pageError = null;
    pageLoading = false;
    pageLoadingTab = null;
  }

  void applyError(String message) {
    error = message;
    loading = false;
  }

  void switchTab(int index) {
    tabIndex = index.clamp(0, githubDashboardTabCount - 1).toInt();
    selectedIndex = 0;
    closeInlineDetails();
  }

  void moveSelection(int delta) {
    final count = visibleItems.length;
    if (count == 0) return;
    selectedIndex = (selectedIndex + delta).clamp(0, count - 1).toInt();
    closeInlineDetails();
  }

  void selectItem(int index) {
    final count = visibleItems.length;
    if (count == 0) return;
    selectedIndex = index.clamp(0, count - 1).toInt();
    closeInlineDetails();
  }

  void openSelectedDetail() {
    final item = selectedItem;
    if (item?.target == GithubDisplayTarget.workflowRun) {
      openSelectedRunDetail();
      return;
    }
    detailItem = item;
  }

  void closeDetail() {
    detailItem = null;
  }

  void openSelectedDiff() {
    final item = selectedItem;
    if (item == null || item.target != GithubDisplayTarget.pullRequest) return;
    closeInlineDetails();
    diffItem = item;
    diff = '';
    diffError = null;
    diffLoading = true;
  }

  void applyDiffLoaded(String loadedDiff) {
    diff = loadedDiff;
    diffError = null;
    diffLoading = false;
  }

  void applyDiffError(String message) {
    diffError = message;
    diffLoading = false;
  }

  void closeDiff() {
    diffItem = null;
    diff = '';
    diffError = null;
    diffLoading = false;
  }

  void openSelectedRunDetail() {
    final item = selectedItem;
    if (item == null || item.target != GithubDisplayTarget.workflowRun) return;
    closeInlineDetails();
    runDetailItem = item;
    runDetail = null;
    runDetailError = null;
    runDetailLoading = true;
  }

  void applyRunDetailLoaded(GithubWorkflowRunDetail detail) {
    runDetail = detail;
    runDetailError = null;
    runDetailLoading = false;
  }

  void applyRunDetailError(String message) {
    runDetailError = message;
    runDetailLoading = false;
  }

  void closeRunDetail() {
    runDetailItem = null;
    runDetail = null;
    runDetailError = null;
    runDetailLoading = false;
  }

  void openSelectedReviewComments() {
    final item = selectedItem;
    if (item == null || item.target != GithubDisplayTarget.pullRequest) return;
    closeInlineDetails();
    reviewCommentsItem = item;
    reviewComments = const <GithubPullRequestReviewComment>[];
    reviewCommentsError = null;
    reviewCommentsLoading = true;
  }

  void applyReviewCommentsLoaded(
    List<GithubPullRequestReviewComment> loadedComments,
  ) {
    reviewComments = loadedComments;
    reviewCommentsError = null;
    reviewCommentsLoading = false;
  }

  void applyReviewCommentsError(String message) {
    reviewCommentsError = message;
    reviewCommentsLoading = false;
  }

  void closeReviewComments() {
    reviewCommentsItem = null;
    reviewComments = const <GithubPullRequestReviewComment>[];
    reviewCommentsError = null;
    reviewCommentsLoading = false;
  }

  void openSelectedMergeInfo() {
    final item = selectedItem;
    if (item == null || item.target != GithubDisplayTarget.pullRequest) return;
    closeInlineDetails();
    mergeInfoItem = item;
    mergeInfo = null;
    mergeInfoError = null;
    mergeInfoLoading = true;
    actionPromptError = null;
    actionRunning = false;
  }

  void applyMergeInfoLoaded(GithubPullRequestMergeInfo info) {
    mergeInfo = info;
    mergeInfoError = null;
    mergeInfoLoading = false;
  }

  void applyMergeInfoError(String message) {
    mergeInfoError = message;
    mergeInfoLoading = false;
  }

  void closeMergeInfo() {
    mergeInfoItem = null;
    mergeInfo = null;
    mergeInfoError = null;
    mergeInfoLoading = false;
    actionPromptError = null;
    actionRunning = false;
  }

  void openSelectedRepositoryLabels() {
    final item = selectedItem;
    if (item == null || !item.supportsIssueActions) return;
    closeInlineDetails();
    repositoryLabelsItem = item;
    repositoryLabels = const <GithubRepositoryLabel>[];
    repositoryLabelsError = null;
    repositoryLabelsLoading = true;
    actionPromptError = null;
    actionRunning = false;
  }

  void applyRepositoryLabelsLoaded(List<GithubRepositoryLabel> labels) {
    repositoryLabels = labels;
    repositoryLabelsError = null;
    repositoryLabelsLoading = false;
  }

  void applyRepositoryLabelsError(String message) {
    repositoryLabelsError = message;
    repositoryLabelsLoading = false;
  }

  void closeRepositoryLabels() {
    repositoryLabelsItem = null;
    repositoryLabels = const <GithubRepositoryLabel>[];
    repositoryLabelsError = null;
    repositoryLabelsLoading = false;
    actionPromptError = null;
    actionRunning = false;
  }

  void openRepositoryPrompt() {
    repoPromptOpen = true;
    repoPromptError = null;
  }

  void closeRepositoryPrompt() {
    repoPromptOpen = false;
    repoPromptError = null;
  }

  void openCommandPalette() {
    commandPaletteOpen = true;
  }

  void closeCommandPalette() {
    commandPaletteOpen = false;
  }

  bool submitRepository(String input) {
    final normalized = normalizeGithubRepositoryInput(input);
    if (input.trim().isNotEmpty && normalized == null) {
      repoPromptError = 'Use owner/repo or a github.com URL.';
      return false;
    }
    repository = normalized;
    repoPromptOpen = false;
    repoPromptError = null;
    selectedIndex = 0;
    return true;
  }

  void openSelectedComments() {
    final item = selectedItem;
    if (item == null || !item.supportsIssueActions) return;
    closeInlineDetails();
    commentsItem = item;
    comments = const <GithubCommentItem>[];
    commentsError = null;
    commentsLoading = true;
  }

  void applyCommentsLoaded(List<GithubCommentItem> loadedComments) {
    comments = loadedComments;
    commentsError = null;
    commentsLoading = false;
  }

  void applyCommentsError(String message) {
    commentsError = message;
    commentsLoading = false;
  }

  void closeComments() {
    commentsItem = null;
    comments = const <GithubCommentItem>[];
    commentsError = null;
    commentsLoading = false;
  }

  void openActionPrompt(GithubActionPromptKind kind) {
    final item = selectedItem;
    if (item == null || !item.supportsIssueActions) return;
    actionPrompt = GithubActionPrompt(kind: kind, item: item);
    actionPromptError = null;
    actionRunning = false;
  }

  void closeActionPrompt() {
    actionPrompt = null;
    actionPromptError = null;
    actionRunning = false;
  }

  void startAction() {
    actionRunning = true;
    actionPromptError = null;
  }

  void applyActionCompleted(String message) {
    notice = message;
    closeActionPrompt();
    closeMergeInfo();
    closeRepositoryLabels();
  }

  void applyActionError(String message) {
    actionPromptError = message;
    actionRunning = false;
  }

  void closeInlineDetails() {
    closeDiff();
    closeRunDetail();
    closeComments();
    closeReviewComments();
    closeMergeInfo();
    closeRepositoryLabels();
  }
}
