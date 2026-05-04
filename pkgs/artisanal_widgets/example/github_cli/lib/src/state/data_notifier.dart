import 'package:artisanal_widgets/widgets.dart' show ChangeNotifier;

import '../models/dashboard_data.dart';
import '../models/display_item.dart';

/// Owns the raw fetched dashboard data, loading state, and pagination cursors.
final class GithubDataNotifier extends ChangeNotifier {
  GithubDashboardData? _dashboard;
  String? _repository;
  String? _owner;
  String? _error;
  bool _loading = false;

  bool _issueHasNextPage = true;
  bool _pullRequestHasNextPage = true;
  bool _workflowRunHasNextPage = true;
  String? _issueCursor;
  String? _pullRequestCursor;
  int _workflowRunNextPage = 1;
  int? _issueTotalCount;
  int? _pullRequestTotalCount;
  int? _workflowRunTotalCount;
  final _overviewTotalCounts = <GithubOverviewFilter, int>{};
  final _overviewErrors = <GithubOverviewFilter, String>{};
  bool _overviewLoading = false;
  GithubOverviewFilter? _overviewLoadingFilter;
  bool _pageLoading = false;
  int? _pageLoadingTab;
  String? _pageError;

  GithubDashboardData? get dashboard => _dashboard;
  String? get repository => _repository;
  String? get owner => _owner;
  String? get error => _error;
  bool get loading => _loading;
  bool get pageLoading => _pageLoading;
  int? get pageLoadingTab => _pageLoadingTab;
  String? get pageError => _pageError;
  bool get issueHasNextPage => _issueHasNextPage;
  bool get pullRequestHasNextPage => _pullRequestHasNextPage;
  bool get workflowRunHasNextPage => _workflowRunHasNextPage;
  String? get issueCursor => _issueCursor;
  String? get pullRequestCursor => _pullRequestCursor;
  int get workflowRunNextPage => _workflowRunNextPage;
  int? get issueTotalCount => _issueTotalCount;
  int? get pullRequestTotalCount => _pullRequestTotalCount;
  int? get workflowRunTotalCount => _workflowRunTotalCount;

  String? get targetLabel => _repository ?? _owner;

  String? get effectiveRepository {
    if (_repository != null) return _repository;
    final scope = _dashboard?.resolvedScope;
    return scope?.isRepository == true ? scope?.repository : null;
  }

  String? repositoryFor(GithubDisplayItem? item) {
    if ((item?.repository ?? '').isNotEmpty) return item!.repository;
    return effectiveRepository;
  }

  bool hasNextPageForTab(int index) => switch (index) {
    1 => _issueHasNextPage,
    2 => _pullRequestHasNextPage,
    3 => _workflowRunHasNextPage,
    _ => false,
  };

  bool hasLoadedTab(
    int index, {
    GithubOverviewFilter overviewFilter = GithubOverviewFilter.authored,
  }) {
    final data = _dashboard;
    if (data == null) return false;
    return switch (index) {
      0 => hasLoadedOverviewFilter(overviewFilter),
      1 => data.issues.isNotEmpty || _issueTotalCount != null,
      2 => data.pullRequests.isNotEmpty || _pullRequestTotalCount != null,
      3 => data.workflowRuns.isNotEmpty || _workflowRunTotalCount != null,
      _ => false,
    };
  }

  bool hasLoadedOverviewFilter(GithubOverviewFilter filter) {
    final data = _dashboard;
    if (data == null) return false;
    return _overviewTotalCounts.containsKey(filter) ||
        data.overview.bucketFor(filter).count > 0 ||
        _overviewErrors.containsKey(filter);
  }

  String? cursorForTab(int index) => switch (index) {
    1 => _issueCursor,
    2 => _pullRequestCursor,
    _ => null,
  };

  int nextPageForTab(int index) => switch (index) {
    3 => _workflowRunNextPage,
    _ => 1,
  };

  GithubPageStatus pageStatusForTab(
    int tabIndex, {
    GithubOverviewFilter overviewFilter = GithubOverviewFilter.authored,
  }) {
    final data = _dashboard;
    final loaded = switch (tabIndex) {
      0 => data?.overview.bucketFor(overviewFilter).count ?? 0,
      1 => data?.issues.length ?? 0,
      2 => data?.pullRequests.length ?? 0,
      3 => data?.workflowRuns.length ?? 0,
      _ => 0,
    };
    final total = switch (tabIndex) {
      0 => _overviewTotalCounts[overviewFilter],
      1 => _issueTotalCount,
      2 => _pullRequestTotalCount,
      3 => _workflowRunTotalCount,
      _ => null,
    };
    return GithubPageStatus(
      loaded: loaded,
      totalCount: total,
      hasNextPage: hasNextPageForTab(tabIndex),
      loading: tabIndex == 0
          ? _overviewLoading && _overviewLoadingFilter == overviewFilter
          : _pageLoading && _pageLoadingTab == tabIndex,
      error: tabIndex == 0 ? _overviewErrors[overviewFilter] : _pageError,
    );
  }

  void setRepository(String? repository) {
    _repository = repository;
    _owner = null;
  }

  void setOwner(String? owner) {
    _owner = owner;
    _repository = null;
  }

  void setTarget({String? repository, String? owner}) {
    _repository = repository;
    _owner = owner;
  }

  void startLoading({bool clearDashboard = false}) {
    _loading = true;
    _error = null;
    _pageLoading = false;
    _pageLoadingTab = null;
    _pageError = null;
    _issueCursor = null;
    _pullRequestCursor = null;
    _workflowRunNextPage = 1;
    _overviewLoading = false;
    _overviewLoadingFilter = null;
    _overviewErrors.clear();
    _overviewTotalCounts.clear();
    _issueTotalCount = null;
    _pullRequestTotalCount = null;
    _workflowRunTotalCount = null;
    _issueHasNextPage = true;
    _pullRequestHasNextPage = true;
    _workflowRunHasNextPage = true;
    if (clearDashboard) _dashboard = null;
    notifyListeners();
  }

  void applyLoaded(GithubDashboardData data) {
    _dashboard = data;
    final scope = data.resolvedScope;
    if (scope.isRepository) {
      _repository = scope.repository ?? data.repository.nameWithOwner;
      _owner = null;
    } else {
      _repository = null;
      _owner = scope.owner ?? data.repository.nameWithOwner;
    }
    _error = null;
    _loading = false;
    if (data.issues.isNotEmpty) {
      _issueTotalCount = data.issues.length;
      _issueHasNextPage = false;
    }
    if (data.pullRequests.isNotEmpty) {
      _pullRequestTotalCount = data.pullRequests.length;
      _pullRequestHasNextPage = false;
    }
    if (data.workflowRuns.isNotEmpty) {
      _workflowRunTotalCount = data.workflowRuns.length;
      _workflowRunHasNextPage = false;
    }
    notifyListeners();
  }

  void startOverviewLoading(GithubOverviewFilter filter) {
    _overviewLoading = true;
    _overviewLoadingFilter = filter;
    _overviewErrors.remove(filter);
    notifyListeners();
  }

  void applyOverview(GithubOverviewFilter filter, GithubOverviewBucket bucket) {
    final data = _dashboard;
    if (data == null) return;
    _dashboard = data.copyWith(
      overview: data.overview.copyWithBucket(filter, bucket),
      loadedAt: DateTime.now(),
    );
    _overviewTotalCounts[filter] = bucket.count;
    _overviewLoading = false;
    _overviewLoadingFilter = null;
    notifyListeners();
  }

  void applyOverviewError(GithubOverviewFilter filter, String message) {
    _overviewErrors[filter] = message;
    _overviewLoading = false;
    _overviewLoadingFilter = null;
    notifyListeners();
  }

  void applyError(String message) {
    _error = message;
    _loading = false;
    notifyListeners();
  }

  void startPageLoading(int tabIndex, {required bool replace}) {
    _pageLoading = true;
    _pageLoadingTab = tabIndex;
    _pageError = null;
    if (replace) {
      if (tabIndex == 1) {
        _issueCursor = null;
        _issueTotalCount = null;
        _issueHasNextPage = true;
      } else if (tabIndex == 2) {
        _pullRequestCursor = null;
        _pullRequestTotalCount = null;
        _pullRequestHasNextPage = true;
      } else if (tabIndex == 3) {
        _workflowRunNextPage = 1;
        _workflowRunTotalCount = null;
        _workflowRunHasNextPage = true;
      }
    }
    notifyListeners();
  }

  void applyIssuesPage(
    GithubPage<GithubIssueItem> page, {
    required bool replace,
  }) {
    final data = _dashboard;
    if (data == null) return;
    _dashboard = data.copyWith(
      issues: replace ? page.items : [...data.issues, ...page.items],
      loadedAt: DateTime.now(),
    );
    _issueTotalCount = page.totalCount;
    _issueHasNextPage = page.hasNextPage;
    _issueCursor = (page.endCursor?.isEmpty ?? true) ? null : page.endCursor;
    _finishPageLoading();
    notifyListeners();
  }

  void applyPullRequestsPage(
    GithubPage<GithubPullRequestItem> page, {
    required bool replace,
  }) {
    final data = _dashboard;
    if (data == null) return;
    _dashboard = data.copyWith(
      pullRequests: replace
          ? page.items
          : [...data.pullRequests, ...page.items],
      loadedAt: DateTime.now(),
    );
    _pullRequestTotalCount = page.totalCount;
    _pullRequestHasNextPage = page.hasNextPage;
    _pullRequestCursor = (page.endCursor?.isEmpty ?? true)
        ? null
        : page.endCursor;
    _finishPageLoading();
    notifyListeners();
  }

  void applyWorkflowRunsPage(
    GithubPage<GithubWorkflowRunItem> page, {
    required bool replace,
  }) {
    final data = _dashboard;
    if (data == null) return;
    _dashboard = data.copyWith(
      workflowRuns: replace
          ? page.items
          : [...data.workflowRuns, ...page.items],
      loadedAt: DateTime.now(),
    );
    _workflowRunTotalCount = page.totalCount;
    _workflowRunHasNextPage = page.hasNextPage;
    _workflowRunNextPage = page.nextPage ?? _workflowRunNextPage + 1;
    _finishPageLoading();
    notifyListeners();
  }

  void applyPageError(String message) {
    _pageError = message;
    _pageLoading = false;
    _pageLoadingTab = null;
    notifyListeners();
  }

  void _finishPageLoading() {
    _pageError = null;
    _pageLoading = false;
    _pageLoadingTab = null;
  }
}
