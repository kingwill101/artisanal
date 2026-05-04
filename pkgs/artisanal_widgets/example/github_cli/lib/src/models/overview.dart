import 'issue.dart';
import 'pull_request.dart';

enum GithubDashboardScopeKind { repository, user, organization }

enum GithubOverviewFilter { assigned, mentioned, authored, reviewRequested }

extension GithubOverviewFilterLabels on GithubOverviewFilter {
  String get label => switch (this) {
    GithubOverviewFilter.assigned => 'assigned',
    GithubOverviewFilter.mentioned => 'mentioned',
    GithubOverviewFilter.authored => 'authored',
    GithubOverviewFilter.reviewRequested => 'review requested',
  };

  String get tabLabel => switch (this) {
    GithubOverviewFilter.assigned => 'assigned',
    GithubOverviewFilter.mentioned => 'mentioned',
    GithubOverviewFilter.authored => 'authored',
    GithubOverviewFilter.reviewRequested => 'review',
  };
}

final class GithubDashboardScope {
  const GithubDashboardScope.repository(String repository)
    : this._(
        kind: GithubDashboardScopeKind.repository,
        repository: repository,
        owner: null,
        actor: '@me',
        label: repository,
      );

  const GithubDashboardScope.user(String owner)
    : this._(
        kind: GithubDashboardScopeKind.user,
        repository: null,
        owner: owner,
        actor: owner,
        label: owner,
      );

  const GithubDashboardScope.organization(String owner)
    : this._(
        kind: GithubDashboardScopeKind.organization,
        repository: null,
        owner: owner,
        actor: '@me',
        label: owner,
      );

  const GithubDashboardScope._({
    required this.kind,
    required this.repository,
    required this.owner,
    required this.actor,
    required this.label,
  });

  final GithubDashboardScopeKind kind;
  final String? repository;
  final String? owner;
  final String actor;
  final String label;

  bool get isRepository => kind == GithubDashboardScopeKind.repository;

  String get url => switch (kind) {
    GithubDashboardScopeKind.repository => 'https://github.com/$repository',
    GithubDashboardScopeKind.user ||
    GithubDashboardScopeKind.organization => 'https://github.com/$owner',
  };
}

final class GithubOverviewBucket {
  const GithubOverviewBucket({
    this.issues = const <GithubIssueItem>[],
    this.pullRequests = const <GithubPullRequestItem>[],
  });

  static const empty = GithubOverviewBucket();

  final List<GithubIssueItem> issues;
  final List<GithubPullRequestItem> pullRequests;

  int get count => issues.length + pullRequests.length;
}

final class GithubOverviewData {
  const GithubOverviewData({
    this.assigned = GithubOverviewBucket.empty,
    this.mentioned = GithubOverviewBucket.empty,
    this.authored = GithubOverviewBucket.empty,
    this.reviewRequested = GithubOverviewBucket.empty,
  });

  final GithubOverviewBucket assigned;
  final GithubOverviewBucket mentioned;
  final GithubOverviewBucket authored;
  final GithubOverviewBucket reviewRequested;

  GithubOverviewBucket bucketFor(GithubOverviewFilter filter) {
    return switch (filter) {
      GithubOverviewFilter.assigned => assigned,
      GithubOverviewFilter.mentioned => mentioned,
      GithubOverviewFilter.authored => authored,
      GithubOverviewFilter.reviewRequested => reviewRequested,
    };
  }

  GithubOverviewData copyWithBucket(
    GithubOverviewFilter filter,
    GithubOverviewBucket bucket,
  ) {
    return switch (filter) {
      GithubOverviewFilter.assigned => GithubOverviewData(
        assigned: bucket,
        mentioned: mentioned,
        authored: authored,
        reviewRequested: reviewRequested,
      ),
      GithubOverviewFilter.mentioned => GithubOverviewData(
        assigned: assigned,
        mentioned: bucket,
        authored: authored,
        reviewRequested: reviewRequested,
      ),
      GithubOverviewFilter.authored => GithubOverviewData(
        assigned: assigned,
        mentioned: mentioned,
        authored: bucket,
        reviewRequested: reviewRequested,
      ),
      GithubOverviewFilter.reviewRequested => GithubOverviewData(
        assigned: assigned,
        mentioned: mentioned,
        authored: authored,
        reviewRequested: bucket,
      ),
    };
  }
}
