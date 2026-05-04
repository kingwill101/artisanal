import '../client/json.dart';
import 'issue.dart';
import 'overview.dart';
import 'pull_request.dart';
import 'repository_summary.dart';
import 'workflow.dart';
import 'workflow_run.dart';

export 'check_summary.dart';
export 'comment.dart';
export 'diff_comment_target.dart';
export 'issue.dart';
export 'overview.dart';
export 'page.dart';
export 'pull_request_diff.dart';
export 'pull_request_commit.dart';
export 'pull_request.dart';
export 'merge_info.dart';
export 'review_comment.dart';
export 'repository_label.dart';
export 'repository_summary.dart';
export 'workflow.dart';
export 'workflow_run_detail.dart';
export 'workflow_run.dart';

final class GithubDashboardData {
  const GithubDashboardData({
    required this.repository,
    required this.issues,
    required this.pullRequests,
    required this.loadedAt,
    this.scope,
    this.overview = const GithubOverviewData(),
    this.repositories = const <GithubRepositorySummary>[],
    this.workflows = const <GithubWorkflowItem>[],
    this.workflowRuns = const <GithubWorkflowRunItem>[],
  });

  final GithubRepositorySummary repository;
  final GithubDashboardScope? scope;
  final GithubOverviewData overview;
  final List<GithubRepositorySummary> repositories;
  final List<GithubIssueItem> issues;
  final List<GithubPullRequestItem> pullRequests;
  final List<GithubWorkflowItem> workflows;
  final List<GithubWorkflowRunItem> workflowRuns;
  final DateTime loadedAt;

  int get openIssueCount => issues.length;
  int get openPullRequestCount => pullRequests.length;
  int get workflowCount => workflows.length;
  int get workflowRunCount => workflowRuns.length;
  GithubDashboardScope get resolvedScope =>
      scope ?? GithubDashboardScope.repository(repository.nameWithOwner);

  GithubDashboardData copyWith({
    GithubRepositorySummary? repository,
    GithubDashboardScope? scope,
    GithubOverviewData? overview,
    List<GithubRepositorySummary>? repositories,
    List<GithubIssueItem>? issues,
    List<GithubPullRequestItem>? pullRequests,
    List<GithubWorkflowItem>? workflows,
    List<GithubWorkflowRunItem>? workflowRuns,
    DateTime? loadedAt,
  }) {
    return GithubDashboardData(
      repository: repository ?? this.repository,
      scope: scope ?? this.scope,
      overview: overview ?? this.overview,
      repositories: repositories ?? this.repositories,
      issues: issues ?? this.issues,
      pullRequests: pullRequests ?? this.pullRequests,
      workflows: workflows ?? this.workflows,
      workflowRuns: workflowRuns ?? this.workflowRuns,
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }

  static GithubDashboardData fromJson({
    required Object? repository,
    required Object? issues,
    required Object? pullRequests,
    required DateTime loadedAt,
    Object? workflows = const <Object?>[],
    Object? workflowRuns = const <Object?>[],
  }) {
    return GithubDashboardData(
      repository: GithubRepositorySummary.fromJson(ghMap(repository)),
      scope: null,
      overview: const GithubOverviewData(),
      repositories: const <GithubRepositorySummary>[],
      issues: ghList(issues)
          .map((item) => GithubIssueItem.fromJson(ghMap(item)))
          .toList(growable: false),
      pullRequests: ghList(pullRequests)
          .map((item) => GithubPullRequestItem.fromJson(ghMap(item)))
          .toList(growable: false),
      workflows: ghList(workflows)
          .map((item) => GithubWorkflowItem.fromJson(ghMap(item)))
          .toList(growable: false),
      workflowRuns: ghList(workflowRuns)
          .map((item) => GithubWorkflowRunItem.fromJson(ghMap(item)))
          .toList(growable: false),
      loadedAt: loadedAt,
    );
  }
}
