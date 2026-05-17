import 'package:artisanal_widgets/widgets.dart' show ChangeNotifier;

import '../models/dashboard_data.dart';
import '../models/display_item.dart';

/// Owns everything the work-queue pane needs to render.
final class GithubQueueNotifier extends ChangeNotifier {
  GithubQueueNotifier({int tabIndex = 2}) : _tabIndex = tabIndex;

  int _tabIndex;
  GithubOverviewFilter _overviewFilter = GithubOverviewFilter.authored;
  int _selectedIndex = 0;
  bool _navigating = false;

  GithubDashboardData? _dashboard;
  GithubPageStatus _pageStatus = const GithubPageStatus(
    loaded: 0,
    totalCount: null,
    hasNextPage: false,
    loading: false,
    error: null,
  );

  List<GithubDisplayItem>? _cachedItems;
  GithubDashboardData? _cachedDashboard;
  int _cachedTabIndex = -1;
  GithubOverviewFilter? _cachedOverviewFilter;

  String? _searchQuery;
  GithubOverviewBucket? _searchResults;
  bool _searchLoading = false;
  String? _searchError;
  int _searchPage = 1;
  bool _searchHasMore = false;
  bool _searchPageLoading = false;

  int get tabIndex => _tabIndex;
  GithubOverviewFilter get overviewFilter => _overviewFilter;
  int get selectedIndex => _selectedIndex;
  GithubPageStatus get pageStatus => _pageStatus;

  /// True while the user is scrolling rapidly and the detail pane should show
  /// a cheap placeholder instead of the full rendered content.
  bool get navigating => _navigating;

  String? get searchQuery => _searchQuery;
  GithubOverviewBucket? get searchResults => _searchResults;
  bool get searchLoading => _searchLoading;
  String? get searchError => _searchError;
  int get searchPage => _searchPage;
  bool get searchHasMore => _searchHasMore;
  bool get searchPageLoading => _searchPageLoading;

  List<GithubDisplayItem> get visibleItems {
    if (_searchQuery != null) {
      final results = _searchResults;
      if (results == null) return const <GithubDisplayItem>[];
      return githubDisplayItemsForBucket(results);
    }
    final data = _dashboard;
    if (data == null) return const <GithubDisplayItem>[];
    if (identical(data, _cachedDashboard) &&
        _tabIndex == _cachedTabIndex &&
        _overviewFilter == _cachedOverviewFilter &&
        _cachedItems != null) {
      return _cachedItems!;
    }
    _cachedDashboard = data;
    _cachedTabIndex = _tabIndex;
    _cachedOverviewFilter = _overviewFilter;
    return _cachedItems = githubDisplayItemsForTab(
      data,
      _tabIndex,
      _overviewFilter,
    );
  }

  bool get isSearchActive => _searchQuery != null;

  void openSearch(String query) {
    _searchQuery = query;
    _searchResults = null;
    _searchLoading = true;
    _searchPage = 1;
    _searchHasMore = false;
    _searchPageLoading = false;
    _searchError = null;
    _selectedIndex = 0;
    _navigating = false;
    _invalidateCache();
    notifyListeners();
  }

  void applySearchResults(String query, GithubOverviewBucket results, bool hasMore) {
    if (_searchQuery != query) return;
    if (_searchPage == 1) {
      _searchResults = results;
    } else {
      final existing = _searchResults;
      if (existing != null) {
        _searchResults = GithubOverviewBucket(
          issues: [...existing.issues, ...results.issues],
          pullRequests: [...existing.pullRequests, ...results.pullRequests],
        );
      } else {
        _searchResults = results;
      }
    }
    _searchHasMore = hasMore;
    _searchLoading = false;
    _searchPageLoading = false;
    _searchError = null;
    _invalidateCache();
    notifyListeners();
  }

  void startSearchNextPage() {
    _searchPage++;
    _searchPageLoading = true;
    notifyListeners();
  }

  void applySearchError(String query, String message) {
    if (_searchQuery != query) return;
    _searchError = message;
    _searchLoading = false;
    _invalidateCache();
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery == null) return;
    _searchQuery = null;
    _searchResults = null;
    _searchLoading = false;
    _searchPage = 1;
    _searchHasMore = false;
    _searchPageLoading = false;
    _searchError = null;
    _selectedIndex = 0;
    _navigating = false;
    _invalidateCache();
    notifyListeners();
  }

  GithubDisplayItem? get selectedItem {
    final items = visibleItems;
    if (items.isEmpty || _selectedIndex >= items.length) return null;
    return items[_selectedIndex];
  }

  bool get canLoadCurrentPage {
    if (isSearchActive) return _searchHasMore && !_searchPageLoading;
    return _tabIndex != 0 && _pageStatus.hasNextPage && !_pageStatus.loading;
  }

  void moveBy(int delta) {
    final count = visibleItems.length;
    if (count == 0) return;
    final next = (_selectedIndex + delta).clamp(0, count - 1).toInt();
    if (next == _selectedIndex) return;
    _selectedIndex = next;
    _navigating = true;
    notifyListeners();
  }

  void moveToSettled(int index) {
    final count = visibleItems.length;
    if (count == 0) return;
    final clamped = index.clamp(0, count - 1).toInt();
    final changed = clamped != _selectedIndex;
    if (changed) _selectedIndex = clamped;
    if (_navigating || changed) {
      _navigating = false;
      notifyListeners();
    }
  }

  void moveTo(int index) {
    final count = visibleItems.length;
    if (count == 0) return;
    final clamped = index.clamp(0, count - 1).toInt();
    if (clamped == _selectedIndex) return;
    _selectedIndex = clamped;
    _navigating = true;
    notifyListeners();
  }

  void settleNavigation() {
    if (!_navigating) return;
    _navigating = false;
    notifyListeners();
  }

  void switchTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index.clamp(0, githubDashboardTabCount - 1).toInt();
    _selectedIndex = 0;
    _navigating = false;
    _searchQuery = null;
    _searchResults = null;
    _searchLoading = false;
    _searchPage = 1;
    _searchHasMore = false;
    _searchPageLoading = false;
    _searchError = null;
    _invalidateCache();
    notifyListeners();
  }

  void switchOverviewFilter(GithubOverviewFilter filter) {
    if (_overviewFilter == filter) return;
    _overviewFilter = filter;
    _selectedIndex = 0;
    _navigating = false;
    _searchQuery = null;
    _searchResults = null;
    _searchLoading = false;
    _searchPage = 1;
    _searchHasMore = false;
    _searchPageLoading = false;
    _searchError = null;
    _invalidateCache();
    notifyListeners();
  }

  void applyDashboard(GithubDashboardData? dashboard) {
    _dashboard = dashboard;
    _invalidateCache();
    notifyListeners();
  }

  void resetSelection() {
    if (_selectedIndex == 0) return;
    _selectedIndex = 0;
    notifyListeners();
  }

  void applyPageStatus(GithubPageStatus status) {
    _pageStatus = status;
    notifyListeners();
  }

  /// Apply multiple queue mutations atomically, firing [notifyListeners] once.
  void batchApply({
    GithubDashboardData? Function()? dashboard,
    bool resetSelection = false,
    GithubPageStatus? pageStatus,
  }) {
    if (dashboard != null) {
      _dashboard = dashboard();
      _invalidateCache();
    }
    if (resetSelection) {
      _selectedIndex = 0;
    }
    if (pageStatus != null) {
      _pageStatus = pageStatus;
    }
    _navigating = false;
    notifyListeners();
  }

  void _invalidateCache() {
    _cachedItems = null;
    _cachedDashboard = null;
    _cachedTabIndex = -1;
    _cachedOverviewFilter = null;
  }
}
