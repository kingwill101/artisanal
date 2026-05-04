final class GithubPage<T> {
  const GithubPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
    this.endCursor,
    this.nextPage,
  });

  final List<T> items;
  final int? totalCount;
  final bool hasNextPage;
  final String? endCursor;
  final int? nextPage;
}

final class GithubPageStatus {
  const GithubPageStatus({
    required this.loaded,
    required this.totalCount,
    required this.hasNextPage,
    required this.loading,
    required this.error,
  });

  final int loaded;
  final int? totalCount;
  final bool hasNextPage;
  final bool loading;
  final String? error;

  String get countLabel {
    final total = totalCount;
    if (total == null) return hasNextPage ? '$loaded+' : '$loaded';
    return '$loaded/$total';
  }
}
