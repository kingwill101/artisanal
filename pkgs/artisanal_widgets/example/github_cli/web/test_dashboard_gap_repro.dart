import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/widgets.dart' show WidgetApp;
import 'package:github_cli/src/app/dashboard.dart';
import 'package:github_cli/src/client/client.dart';
import 'package:github_cli/src/models/dashboard_data.dart';
import 'package:github_cli/src/models/item_kind.dart';

void main() async {
  await runWidgetApp(
    WidgetApp(
      GithubCliDashboard(
        client: _FakeDashboardClient(),
        repository: 'dart-lang/sdk',
      ),
    ),
  );
}

final class _FakeDashboardClient implements GithubDashboardClient {
  static const _pullRequest = GithubPullRequestItem(
    number: 63358,
    title: '[vm/io] Range check SynchronousSocket_WriteList arguments',
    body: 'Pull request body from fake client.',
    url: 'https://github.com/dart-lang/sdk/pull/63358',
    repository: 'dart-lang/sdk',
    author: 'LemonTeatw1',
    headRefOid: 'head-63358',
    labels: <String>['vm/io'],
    labelDetails: <GithubRepositoryLabel>[
      GithubRepositoryLabel(name: 'vm/io', color: '#808080'),
    ],
    commentCount: 46,
    commitCount: 2,
    updatedAt: null,
    reviewDecision: 'PENDING',
    isDraft: false,
    checks: GithubCheckSummary(
      total: 2,
      passed: 2,
      failed: 0,
      pending: 0,
      items: <GithubCheckItem>[
        GithubCheckItem(
          name: 'analyze',
          status: 'completed',
          conclusion: 'success',
        ),
        GithubCheckItem(
          name: 'test',
          status: 'completed',
          conclusion: 'success',
        ),
      ],
    ),
  );

  static final _dashboard = GithubDashboardData(
    loadedAt: DateTime.utc(2026, 5, 1, 12),
    repository: const GithubRepositorySummary(
      nameWithOwner: 'dart-lang/sdk',
      description: 'The Dart SDK, including the VM, JS and Wasm compilers.',
      url: 'https://github.com/dart-lang/sdk',
      defaultBranch: 'main',
      stars: 9999,
      forks: 1200,
      isPrivate: false,
      viewerPermission: 'WRITE',
      primaryLanguage: 'Dart',
      latestRelease: '3.10.0',
      updatedAt: null,
    ),
    issues: <GithubIssueItem>[],
    pullRequests: const <GithubPullRequestItem>[_pullRequest],
    workflows: <GithubWorkflowItem>[],
    workflowRuns: <GithubWorkflowRunItem>[],
  );

  @override
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  }) async {
    return _dashboard;
  }

  @override
  Future<GithubOverviewBucket> loadOverview({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required int limit,
  }) async {
    return GithubOverviewBucket(
      issues: _dashboard.issues,
      pullRequests: _dashboard.pullRequests,
    );
  }

  @override
  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    return const GithubPage<GithubIssueItem>(
      items: <GithubIssueItem>[],
      totalCount: 0,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPage<GithubPullRequestItem>> loadPullRequestsPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    return const GithubPage<GithubPullRequestItem>(
      items: <GithubPullRequestItem>[_pullRequest],
      totalCount: 1,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  }) async {
    return _dashboard.pullRequests.single;
  }

  @override
  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  }) async {
    return const GithubPage<GithubWorkflowRunItem>(
      items: <GithubWorkflowRunItem>[],
      totalCount: 0,
      hasNextPage: false,
    );
  }

  @override
  Future<List<GithubCommentItem>> loadComments({
    required String repository,
    required GithubItemKind kind,
    required int number,
  }) async {
    return const <GithubCommentItem>[];
  }

  @override
  Future<List<GithubPullRequestReviewComment>> loadPullRequestReviewComments({
    required String repository,
    required int number,
  }) async {
    return const <GithubPullRequestReviewComment>[];
  }

  @override
  Future<List<GithubPullRequestCommit>> loadPullRequestCommits({
    required String repository,
    required int number,
  }) async {
    return const <GithubPullRequestCommit>[];
  }

  @override
  Future<String> loadPullRequestDiff({
    required String repository,
    required int number,
  }) async {
    return '';
  }

  @override
  Future<GithubPullRequestMergeInfo> loadPullRequestMergeInfo({
    required String repository,
    required int number,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addComment({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required String body,
  }) async {}

  @override
  Future<GithubPullRequestReviewComment> addPullRequestReviewComment({
    required String repository,
    required int number,
    required String commitId,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  }) async {}

  @override
  Future<void> removeLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  }) async {}

  @override
  Future<void> mergePullRequest({
    required String repository,
    required int number,
    required GithubPullRequestMergeAction action,
  }) async {}

  @override
  Future<void> closePullRequest({
    required String repository,
    required int number,
  }) async {}

  @override
  Future<void> togglePullRequestDraft({
    required String repository,
    required int number,
    required bool isDraft,
  }) async {}

  @override
  Future<List<GithubRepositoryLabel>> loadRepositoryLabels({
    required String repository,
  }) async {
    return const <GithubRepositoryLabel>[
      GithubRepositoryLabel(name: 'vm/io', color: '#808080'),
    ];
  }

  @override
  Future<({GithubOverviewBucket bucket, bool hasMore})> searchIssuesAndPrs({
    required GithubDashboardScope scope,
    required String query,
    required int limit,
    required int page,
  }) async {
    return (
      bucket: GithubOverviewBucket(issues: const [], pullRequests: const []),
      hasMore: false,
    );
  }
}
