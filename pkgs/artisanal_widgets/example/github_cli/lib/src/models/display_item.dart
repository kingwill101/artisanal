import 'dashboard_data.dart';

const githubDisplayItemRowExtent = 4;
const githubDashboardTabCount = 4;

enum GithubDisplayTarget { issue, pullRequest, workflowRun }

final class GithubDisplayItem {
  const GithubDisplayItem({
    required this.target,
    required this.kind,
    required this.number,
    required this.title,
    required this.body,
    required this.url,
    required this.author,
    required this.status,
    required this.updatedAt,
    required this.footer,
    this.repository = '',
    this.authorAvatarUrl = '',
    this.labels = const <String>[],
    this.labelDetails = const <GithubRepositoryLabel>[],
    this.commentCount = 0,
    this.workflowRunDatabaseId,
    this.hasWarning = false,
    this.checks = GithubCheckSummary.empty,
    this.headRefOid = '',
    this.additions = 0,
    this.deletions = 0,
    this.changedFiles = 0,
    this.commitCount = 0,
  });

  factory GithubDisplayItem.issue(
    GithubIssueItem issue, {
    String repository = '',
  }) {
    return GithubDisplayItem(
      target: GithubDisplayTarget.issue,
      kind: 'issue',
      number: issue.number,
      title: issue.title,
      body: issue.body,
      url: issue.url,
      repository: issue.repository.isEmpty ? repository : issue.repository,
      author: issue.author,
      authorAvatarUrl: issue.authorAvatarUrl,
      status: issue.labels.isEmpty ? 'unlabeled' : issue.labels.first,
      updatedAt: issue.updatedAt,
      footer: [
        '${issue.commentCount} comments',
        if (issue.assignees.isEmpty)
          'no assignee'
        else
          'assigned ${issue.assignees.join(', ')}',
      ].join(' / '),
      labels: issue.labels,
      labelDetails: issue.labelDetails,
      commentCount: issue.commentCount,
    );
  }

  factory GithubDisplayItem.pullRequest(
    GithubPullRequestItem pullRequest, {
    String repository = '',
  }) {
    return GithubDisplayItem(
      target: GithubDisplayTarget.pullRequest,
      kind: pullRequest.isDraft ? 'draft' : 'pr',
      number: pullRequest.number,
      title: pullRequest.title,
      body: pullRequest.body,
      url: pullRequest.url,
      repository: pullRequest.repository.isEmpty
          ? repository
          : pullRequest.repository,
      author: pullRequest.author,
      authorAvatarUrl: pullRequest.authorAvatarUrl,
      status: pullRequest.checks.label,
      updatedAt: pullRequest.updatedAt,
      footer:
          '${pullRequest.commentCount} comments / review ${pullRequest.reviewDecision.toLowerCase()}',
      labels: pullRequest.labels,
      labelDetails: pullRequest.labelDetails,
      commentCount: pullRequest.commentCount,
      hasWarning: pullRequest.checks.hasFailures,
      checks: pullRequest.checks,
      headRefOid: pullRequest.headRefOid,
      additions: pullRequest.additions,
      deletions: pullRequest.deletions,
      changedFiles: pullRequest.changedFiles,
      commitCount: pullRequest.commitCount,
    );
  }

  factory GithubDisplayItem.workflowRun(GithubWorkflowRunItem run) {
    final number = run.number == 0 ? run.databaseId : run.number;
    return GithubDisplayItem(
      target: GithubDisplayTarget.workflowRun,
      kind: 'run',
      number: number,
      title: run.displayTitle,
      body: [
        '**Workflow:** ${run.workflowName}',
        '**Status:** ${run.statusLabel}',
        '**Branch:** ${run.headBranch}',
        '**Event:** ${run.event}',
        if (run.attempt > 0) '**Attempt:** ${run.attempt}',
        if (run.url.isNotEmpty) '**URL:** ${run.url}',
      ].join('\n\n'),
      url: run.url,
      author: run.workflowName,
      status: run.statusLabel,
      updatedAt: run.updatedAt ?? run.createdAt,
      footer: '${run.event} / ${run.headBranch}',
      workflowRunDatabaseId: run.databaseId,
      hasWarning: run.hasFailures,
    );
  }

  final GithubDisplayTarget target;
  final String kind;
  final int number;
  final String title;
  final String body;
  final String url;
  final String repository;
  final String author;
  final String authorAvatarUrl;
  final String status;
  final DateTime? updatedAt;
  final String footer;
  final List<String> labels;
  final List<GithubRepositoryLabel> labelDetails;
  final int commentCount;
  final int? workflowRunDatabaseId;
  final bool hasWarning;
  final GithubCheckSummary checks;
  final String headRefOid;
  final int additions;
  final int deletions;
  final int changedFiles;
  final int commitCount;

  bool get supportsIssueActions =>
      target == GithubDisplayTarget.issue ||
      target == GithubDisplayTarget.pullRequest;
}

List<GithubDisplayItem> githubDisplayItemsForTab(
  GithubDashboardData dashboard,
  int tabIndex,
  GithubOverviewFilter overviewFilter,
) {
  final repository = dashboard.resolvedScope.repository ?? '';
  if (tabIndex == 0) {
    final bucket = dashboard.overview.bucketFor(overviewFilter);
    final items = <GithubDisplayItem>[
      ...bucket.pullRequests.map(
        (pullRequest) =>
            GithubDisplayItem.pullRequest(pullRequest, repository: repository),
      ),
      ...bucket.issues.map(
        (issue) => GithubDisplayItem.issue(issue, repository: repository),
      ),
    ];
    items.sort((left, right) {
      final leftUpdated =
          left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightUpdated =
          right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightUpdated.compareTo(leftUpdated);
    });
    return items;
  }
  if (tabIndex == 1) {
    return dashboard.issues
        .map((issue) => GithubDisplayItem.issue(issue, repository: repository))
        .toList(growable: false);
  }
  if (tabIndex == 2) {
    return dashboard.pullRequests
        .map(
          (pullRequest) => GithubDisplayItem.pullRequest(
            pullRequest,
            repository: repository,
          ),
        )
        .toList(growable: false);
  }
  if (tabIndex == 3) {
    return dashboard.workflowRuns
        .map(GithubDisplayItem.workflowRun)
        .toList(growable: false);
  }
  return <GithubDisplayItem>[
    ...dashboard.pullRequests
        .take(6)
        .map(
          (pullRequest) => GithubDisplayItem.pullRequest(
            pullRequest,
            repository: repository,
          ),
        ),
    ...dashboard.issues
        .take(6)
        .map((issue) => GithubDisplayItem.issue(issue, repository: repository)),
    ...dashboard.workflowRuns.take(4).map(GithubDisplayItem.workflowRun),
  ];
}
