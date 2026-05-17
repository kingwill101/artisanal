import '../models/dashboard_data.dart';
import '../models/item_kind.dart';

abstract interface class GithubDashboardClient {
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  });

  Future<GithubOverviewBucket> loadOverview({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required int limit,
  });

  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  });

  Future<GithubPage<GithubPullRequestItem>> loadPullRequestsPage({
    required String repository,
    required int first,
    String? after,
  });

  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  });

  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  });

  Future<List<GithubCommentItem>> loadComments({
    required String repository,
    required GithubItemKind kind,
    required int number,
  });

  Future<List<GithubPullRequestReviewComment>> loadPullRequestReviewComments({
    required String repository,
    required int number,
  });

  Future<List<GithubPullRequestCommit>> loadPullRequestCommits({
    required String repository,
    required int number,
  });

  Future<String> loadPullRequestDiff({
    required String repository,
    required int number,
  });

  Future<GithubPullRequestMergeInfo> loadPullRequestMergeInfo({
    required String repository,
    required int number,
  });

  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  });

  Future<void> addComment({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required String body,
  });

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
  });

  Future<void> addLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  });

  Future<void> removeLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  });

  Future<void> mergePullRequest({
    required String repository,
    required int number,
    required GithubPullRequestMergeAction action,
  });

  Future<void> closePullRequest({
    required String repository,
    required int number,
  });

  Future<void> togglePullRequestDraft({
    required String repository,
    required int number,
    required bool isDraft,
  });

  Future<List<GithubRepositoryLabel>> loadRepositoryLabels({
    required String repository,
  });

  Future<({GithubOverviewBucket bucket, bool hasMore})> searchIssuesAndPrs({
    required GithubDashboardScope scope,
    required String query,
    required int limit,
    required int page,
  });
}

abstract interface class GithubPullRequestDiffStreamingClient {
  Stream<GithubPullRequestDiffChunk> loadPullRequestDiffChunks({
    required String repository,
    required int number,
  });
}

final class GhCliException implements Exception {
  const GhCliException(this.message);

  final String message;

  @override
  String toString() => message;
}

const issuesPageQuery = r'''
query RepoIssues($owner: String!, $name: String!, $first: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    issues(states: OPEN, first: $first, after: $after, orderBy: {field: UPDATED_AT, direction: DESC}) {
      totalCount
      nodes {
        number
        title
        body
        url
        author { login avatarUrl }
        labels(first: 20) { nodes { name color } }
        comments { totalCount }
        assignees(first: 20) { nodes { login } }
        updatedAt
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
''';

const pullRequestsPageQuery = r'''
query RepoPullRequests($owner: String!, $name: String!, $first: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: $first, after: $after, orderBy: {field: UPDATED_AT, direction: DESC}) {
      totalCount
      nodes {
        number
        title
        body
        url
        author { login avatarUrl }
        headRefOid
        additions
        deletions
        changedFiles
        commits { totalCount }
        labels(first: 20) { nodes { name color } }
        comments { totalCount }
        updatedAt
        reviewDecision
        statusCheckRollup {
          contexts(first: 100) {
            nodes {
              __typename
              ... on CheckRun { name status conclusion }
              ... on StatusContext { context state }
            }
          }
        }
        isDraft
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
''';

const pullRequestQuery = r'''
query PullRequest($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      number
      title
      body
      url
      author { login avatarUrl }
      headRefOid
      additions
      deletions
      changedFiles
      commits { totalCount }
      labels(first: 20) { nodes { name color } }
      comments { totalCount }
      updatedAt
      reviewDecision
      statusCheckRollup {
        contexts(first: 100) {
          nodes {
            __typename
            ... on CheckRun { name status conclusion }
            ... on StatusContext { context state }
          }
        }
      }
      isDraft
    }
  }
}
''';

const pullRequestMergeQuery = r'''
query PullRequestMerge($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      number
      title
      state
      isDraft
      mergeable
      reviewDecision
      autoMergeRequest { enabledBy { login } }
      viewerCanMergeAsAdmin
      mergeCommitAllowed
      squashMergeAllowed
      rebaseMergeAllowed
      statusCheckRollup {
        contexts(first: 100) {
          nodes {
            __typename
            ... on CheckRun { name status conclusion }
            ... on StatusContext { context state }
          }
        }
      }
    }
  }
}
''';


