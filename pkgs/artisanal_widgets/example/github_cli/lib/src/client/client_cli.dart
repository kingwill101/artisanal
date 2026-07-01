import 'dart:convert';
import 'dart:io' as io;

import '../models/dashboard_data.dart';
import '../models/item_kind.dart';
import 'client.dart';
import 'fields.dart';
import 'json.dart';

final class GhCliClient
    implements GithubDashboardClient, GithubPullRequestDiffStreamingClient {
  const GhCliClient({this.executable = 'gh'});

  final String executable;

  @override
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  }) async {
    if ((owner ?? '').trim().isNotEmpty) {
      return _loadOwnerDashboard(owner!.trim(), limit: limit);
    }

    final repoJson = await _runJson([
      'repo',
      'view',
      if (repository != null) repository,
      '--json',
      ghRepositoryFields.join(','),
    ]);

    return GithubDashboardData.fromJson(
      repository: repoJson,
      issues: const <Object?>[],
      pullRequests: const <Object?>[],
      workflows: const <Object?>[],
      workflowRuns: const <Object?>[],
      loadedAt: DateTime.now(),
    );
  }

  @override
  Future<GithubOverviewBucket> loadOverview({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required int limit,
  }) async {
    final futures = <Future<Object?>>[];
    final parseIssues = filter != GithubOverviewFilter.reviewRequested;
    if (parseIssues) {
      futures.add(
        _runJson(
          _overviewSearchArgs(
            scope: scope,
            filter: filter,
            pullRequests: false,
            limit: limit,
          ),
        ),
      );
    }
    futures.add(
      _runJson(
        _overviewSearchArgs(
          scope: scope,
          filter: filter,
          pullRequests: true,
          limit: limit,
        ),
      ),
    );

    final results = await Future.wait(futures);
    final issueJson = parseIssues ? results.first : const <Object?>[];
    final prJson = parseIssues ? results[1] : results.first;
    return GithubOverviewBucket(
      issues: ghList(issueJson)
          .map((item) => GithubIssueItem.fromJson(ghMap(item)))
          .toList(growable: false),
      pullRequests: ghList(prJson)
          .map((item) => GithubPullRequestItem.fromJson(ghMap(item)))
          .toList(growable: false),
    );
  }

  @override
  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    final parts = _repositoryParts(repository);
    final json = await _runJson([
      'api',
      'graphql',
      '-f',
      'query=$issuesPageQuery',
      '-F',
      'owner=${parts.owner}',
      '-F',
      'name=${parts.name}',
      '-F',
      'first=$first',
      if (after != null) ...['-F', 'after=$after'],
    ]);
    final issues = ghMap(ghMap(ghMap(json)['data'])['repository'])['issues'];
    final issueMap = ghMap(issues);
    final pageInfo = ghMap(issueMap['pageInfo']);
    return GithubPage<GithubIssueItem>(
      items: ghList(issueMap['nodes'])
          .map((item) => GithubIssueItem.fromJson(ghMap(item)))
          .toList(growable: false),
      totalCount: ghInt(issueMap['totalCount']),
      hasNextPage: pageInfo['hasNextPage'] == true,
      endCursor: ghString(pageInfo['endCursor']),
    );
  }

  @override
  Future<GithubPage<GithubPullRequestItem>> loadPullRequestsPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    final parts = _repositoryParts(repository);
    final json = await _runJson([
      'api',
      'graphql',
      '-f',
      'query=$pullRequestsPageQuery',
      '-F',
      'owner=${parts.owner}',
      '-F',
      'name=${parts.name}',
      '-F',
      'first=$first',
      if (after != null) ...['-F', 'after=$after'],
    ]);
    final prs = ghMap(ghMap(ghMap(json)['data'])['repository'])['pullRequests'];
    final prMap = ghMap(prs);
    final pageInfo = ghMap(prMap['pageInfo']);
    return GithubPage<GithubPullRequestItem>(
      items: ghList(prMap['nodes'])
          .map((item) => GithubPullRequestItem.fromJson(ghMap(item)))
          .toList(growable: false),
      totalCount: ghInt(prMap['totalCount']),
      hasNextPage: pageInfo['hasNextPage'] == true,
      endCursor: ghString(pageInfo['endCursor']),
    );
  }

  @override
  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  }) async {
    final json = await _runJson([
      'pr',
      'view',
      '$number',
      '--repo',
      repository,
      '--json',
      ghPullRequestFields.join(','),
    ]);
    return GithubPullRequestItem.fromJson(ghMap(json));
  }

  @override
  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  }) async {
    final json = await _runJson([
      'api',
      'repos/$repository/actions/runs?per_page=$first&page=$page',
    ]);
    final map = ghMap(json);
    final total = ghInt(map['total_count']);
    return GithubPage<GithubWorkflowRunItem>(
      items: ghList(map['workflow_runs'])
          .map((item) => GithubWorkflowRunItem.fromJson(ghMap(item)))
          .toList(growable: false),
      totalCount: total,
      hasNextPage: page * first < total,
      nextPage: page + 1,
    );
  }

  @override
  Future<List<GithubCommentItem>> loadComments({
    required String repository,
    required GithubItemKind kind,
    required int number,
  }) async {
    final json = await _runJson([
      'api',
      '--paginate',
      '--slurp',
      'repos/$repository/issues/$number/comments',
    ]);
    return _flattenGhPages(json)
        .map((item) => GithubCommentItem.fromJson(ghMap(item)))
        .toList(growable: false);
  }

  @override
  Future<List<GithubPullRequestReviewComment>> loadPullRequestReviewComments({
    required String repository,
    required int number,
  }) async {
    final json = await _runJson([
      'api',
      '--paginate',
      '--slurp',
      'repos/$repository/pulls/$number/comments',
    ]);
    final comments = <GithubPullRequestReviewComment>[];
    for (final item in _flattenGhPages(json)) {
      final comment = GithubPullRequestReviewComment.fromJson(ghMap(item));
      if (comment != null) comments.add(comment);
    }
    return comments;
  }

  @override
  Future<List<GithubPullRequestCommit>> loadPullRequestCommits({
    required String repository,
    required int number,
  }) async {
    final json = await _runJson([
      'api',
      '--paginate',
      '--slurp',
      'repos/$repository/pulls/$number/commits?per_page=100',
    ]);
    return _flattenGhPages(json)
        .map((item) => GithubPullRequestCommit.fromJson(ghMap(item)))
        .toList(growable: false);
  }

  @override
  Future<String> loadPullRequestDiff({
    required String repository,
    required int number,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in loadPullRequestDiffChunks(
      repository: repository,
      number: number,
    )) {
      buffer.write(chunk.text);
    }
    return buffer.toString();
  }

  @override
  Stream<GithubPullRequestDiffChunk> loadPullRequestDiffChunks({
    required String repository,
    required int number,
  }) async* {
    final buffer = GithubPullRequestDiffBuffer();
    var page = 1;
    while (true) {
      final json = await _runJson([
        'api',
        'repos/$repository/pulls/$number/files?per_page=100&page=$page',
      ]);
      final files = ghList(json)
          .map((item) => GithubPullRequestDiffFile.fromJson(ghMap(item)))
          .toList(growable: false);
      if (files.isEmpty) break;

      final chunk = buffer.addFiles(files);
      if (chunk.text.isNotEmpty || chunk.files.isNotEmpty) {
        yield chunk;
      }
      if (buffer.shouldStop) break;
      if (files.length < 100) break;
      page++;
      await Future<void>.delayed(Duration.zero);
    }

    final done = buffer.finish();
    if (done.text.isNotEmpty || done.files.isNotEmpty) {
      yield done;
    }
  }

  @override
  Future<GithubPullRequestMergeInfo> loadPullRequestMergeInfo({
    required String repository,
    required int number,
  }) async {
    final json = await _runJson([
      'pr',
      'view',
      '$number',
      '--repo',
      repository,
      '--json',
      ghPullRequestMergeFields.join(','),
    ]);
    return GithubPullRequestMergeInfo.fromJson(ghMap(json));
  }

  @override
  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  }) async {
    final json = await _runJson([
      'run',
      'view',
      '$databaseId',
      '--json',
      [
        'attempt',
        'conclusion',
        'createdAt',
        'databaseId',
        'displayTitle',
        'event',
        'headBranch',
        'headSha',
        'jobs',
        'name',
        'number',
        'startedAt',
        'status',
        'updatedAt',
        'url',
        'workflowName',
      ].join(','),
      '--repo',
      repository,
    ]);
    return GithubWorkflowRunDetail.fromJson(ghMap(json));
  }

  @override
  Future<void> addComment({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required String body,
  }) {
    return _run([
      kind.ghCommand,
      'comment',
      '$number',
      '--body',
      body,
      '--repo',
      repository,
    ]);
  }

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
    if (commitId.trim().isEmpty) {
      throw const GhCliException('Cannot comment without the PR head commit.');
    }
    final args = [
      'api',
      '--method',
      'POST',
      'repos/$repository/pulls/$number/comments',
      '-f',
      'body=$body',
      '-f',
      'commit_id=$commitId',
      '-f',
      'path=$path',
      '-F',
      'line=$line',
      '-f',
      'side=$side',
    ];
    if (startLine != null) {
      args
        ..add('-F')
        ..add('start_line=$startLine');
    }
    if (startSide != null) {
      args
        ..add('-f')
        ..add('start_side=$startSide');
    }
    final json = await _runJson(args);
    final comment = GithubPullRequestReviewComment.fromJson(ghMap(json));
    if (comment == null) {
      throw const GhCliException('gh returned an invalid review comment.');
    }
    return comment;
  }

  @override
  Future<void> addLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  }) {
    if (labels.isEmpty) return Future<void>.value();
    return _run([
      kind.ghCommand,
      'edit',
      '$number',
      '--add-label',
      labels.join(','),
      '--repo',
      repository,
    ]);
  }

  @override
  Future<void> removeLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  }) {
    if (labels.isEmpty) return Future<void>.value();
    return _run([
      kind.ghCommand,
      'edit',
      '$number',
      '--remove-label',
      labels.join(','),
      '--repo',
      repository,
    ]);
  }

  @override
  Future<void> mergePullRequest({
    required String repository,
    required int number,
    required GithubPullRequestMergeAction action,
  }) {
    return _run([
      'pr',
      'merge',
      '$number',
      '--repo',
      repository,
      ...action.cliArgs,
    ]);
  }

  @override
  Future<void> closePullRequest({
    required String repository,
    required int number,
  }) {
    return _run(['pr', 'close', '$number', '--repo', repository]);
  }

  @override
  Future<void> togglePullRequestDraft({
    required String repository,
    required int number,
    required bool isDraft,
  }) {
    return _run([
      'pr',
      'ready',
      '$number',
      '--repo',
      repository,
      if (!isDraft) '--undo',
    ]);
  }

  @override
  Future<({GithubOverviewBucket bucket, bool hasMore})> searchIssuesAndPrs({
    required GithubDashboardScope scope,
    required String query,
    required int limit,
    required int page,
  }) async {
    if (query.trim().isEmpty) {
      return (
        bucket: GithubOverviewBucket(issues: const [], pullRequests: const []),
        hasMore: false,
      );
    }
    final futures = <Future<Object?>>[
      _runJson(
        _searchArgs(
          scope: scope,
          query: query,
          pullRequests: false,
          limit: limit,
          page: page,
        ),
      ),
      _runJson(
        _searchArgs(
          scope: scope,
          query: query,
          pullRequests: true,
          limit: limit,
          page: page,
        ),
      ),
    ];
    final results = await Future.wait(futures);
    final issues = ghList(results[0])
        .map((item) => GithubIssueItem.fromJson(ghMap(item)))
        .toList(growable: false);
    final prs = ghList(results[1])
        .map((item) => GithubPullRequestItem.fromJson(ghMap(item)))
        .toList(growable: false);
    return (
      bucket: GithubOverviewBucket(issues: issues, pullRequests: prs),
      hasMore: issues.length == limit || prs.length == limit,
    );
  }

  List<String> _searchArgs({
    required GithubDashboardScope scope,
    required String query,
    required bool pullRequests,
    required int limit,
    required int page,
  }) {
    final args = <String>[
      'search',
      pullRequests ? 'prs' : 'issues',
      query,
      '--state',
      'open',
      '--limit',
      '$limit',
      '--page',
      '$page',
      '--sort',
      'updated',
      '--order',
      'desc',
      '--json',
      (pullRequests ? _overviewPullRequestFields : _overviewIssueFields).join(
        ',',
      ),
    ];

    switch (scope.kind) {
      case GithubDashboardScopeKind.repository:
        args
          ..add('--repo')
          ..add(scope.repository!);
      case GithubDashboardScopeKind.organization:
        args
          ..add('--owner')
          ..add(scope.owner!);
      case GithubDashboardScopeKind.user:
        break;
    }

    return args;
  }

  @override
  Future<List<GithubRepositoryLabel>> loadRepositoryLabels({
    required String repository,
  }) async {
    final json = await _runJson([
      'label',
      'list',
      '--repo',
      repository,
      '--json',
      'name,color',
      '--limit',
      '100',
    ]);
    return ghList(json)
        .map((item) => GithubRepositoryLabel.fromJson(ghMap(item)))
        .toList(growable: false);
  }

  Future<GithubDashboardData> _loadOwnerDashboard(
    String owner, {
    required int limit,
  }) async {
    final scope = await _resolveOwnerScope(owner);
    final repositories = await _loadRepositories(scope, limit: limit);
    return GithubDashboardData(
      repository: _summaryForScope(scope),
      scope: scope,
      repositories: repositories,
      issues: const <GithubIssueItem>[],
      pullRequests: const <GithubPullRequestItem>[],
      workflows: const <GithubWorkflowItem>[],
      workflowRuns: const <GithubWorkflowRunItem>[],
      loadedAt: DateTime.now(),
    );
  }

  Future<List<GithubRepositorySummary>> _loadRepositories(
    GithubDashboardScope scope, {
    required int limit,
  }) async {
    if (scope.owner == null) return const <GithubRepositorySummary>[];
    final json = await _runJson([
      'repo',
      'list',
      scope.owner!,
      '--limit',
      '$limit',
      '--json',
      _repositoryListFields.join(','),
    ]);
    return ghList(json)
        .map((item) => GithubRepositorySummary.fromJson(ghMap(item)))
        .toList(growable: false);
  }

  Future<GithubDashboardScope> _resolveOwnerScope(String owner) async {
    final target = owner == '@me' ? 'user' : 'users/$owner';
    final json = ghMap(await _runJson(['api', target]));
    final login = ghString(json['login'], fallback: owner);
    final type = ghString(json['type']).toLowerCase();
    if (type == 'organization') {
      return GithubDashboardScope.organization(login);
    }
    return GithubDashboardScope.user(login);
  }

  GithubRepositorySummary _summaryForScope(GithubDashboardScope scope) {
    final kindLabel = switch (scope.kind) {
      GithubDashboardScopeKind.organization => 'GitHub organization overview',
      GithubDashboardScopeKind.user => 'GitHub personal overview',
      GithubDashboardScopeKind.repository => 'GitHub repository overview',
    };
    return GithubRepositorySummary(
      nameWithOwner: scope.label,
      description: kindLabel,
      url: scope.url,
      defaultBranch: '',
      stars: 0,
      forks: 0,
      isPrivate: false,
      viewerPermission: 'UNKNOWN',
      primaryLanguage: '',
      latestRelease: '',
      updatedAt: null,
    );
  }

  List<String> _overviewSearchArgs({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required bool pullRequests,
    required int limit,
  }) {
    final args = <String>[
      'search',
      pullRequests ? 'prs' : 'issues',
      '--state',
      'open',
      '--limit',
      '$limit',
      '--sort',
      'updated',
      '--order',
      'desc',
      '--json',
      (pullRequests ? _overviewPullRequestFields : _overviewIssueFields).join(
        ',',
      ),
    ];

    switch (scope.kind) {
      case GithubDashboardScopeKind.repository:
        args
          ..add('--repo')
          ..add(scope.repository!);
      case GithubDashboardScopeKind.organization:
        args
          ..add('--owner')
          ..add(scope.owner!);
      case GithubDashboardScopeKind.user:
        break;
    }

    final actor = scope.actor;
    switch (filter) {
      case GithubOverviewFilter.assigned:
        args
          ..add('--assignee')
          ..add(actor);
      case GithubOverviewFilter.mentioned:
        args
          ..add('--mentions')
          ..add(actor);
      case GithubOverviewFilter.authored:
        args
          ..add('--author')
          ..add(actor);
      case GithubOverviewFilter.reviewRequested:
        args
          ..add('--review-requested')
          ..add(actor);
    }

    return args;
  }

  Future<void> _run(List<String> arguments) async {
    final result = await io.Process.run(executable, arguments);
    if (result.exitCode != 0) {
      throw GhCliException(_failureMessage(arguments, result));
    }
  }

  Future<Object?> _runJson(List<String> arguments) async {
    final result = await io.Process.run(executable, arguments);
    if (result.exitCode != 0) {
      throw GhCliException(_failureMessage(arguments, result));
    }
    final raw = (result.stdout as Object?)?.toString() ?? '';
    try {
      return jsonDecode(raw);
    } on FormatException catch (error) {
      throw GhCliException('gh returned invalid JSON: ${error.message}');
    }
  }

  String _failureMessage(List<String> arguments, io.ProcessResult result) {
    final stderr = (result.stderr as Object?)?.toString().trim() ?? '';
    final stdout = (result.stdout as Object?)?.toString().trim() ?? '';
    final detail = _compactFailureDetail(stderr.isNotEmpty ? stderr : stdout);
    return detail.isEmpty
        ? '`$executable ${arguments.join(' ')}` failed.'
        : detail;
  }

  String _compactFailureDetail(String detail) {
    final trimmed = detail.trim();
    final firstLine = trimmed.split(RegExp(r'\r?\n')).first.trim();
    if (firstLine.startsWith('Unknown JSON field:')) return firstLine;
    return trimmed;
  }

  ({String owner, String name}) _repositoryParts(String repository) {
    final slash = repository.indexOf('/');
    if (slash <= 0 || slash == repository.length - 1) {
      throw GhCliException('Repository must be owner/repo.');
    }
    return (
      owner: repository.substring(0, slash),
      name: repository.substring(slash + 1),
    );
  }

  Iterable<Object?> _flattenGhPages(Object? json) {
    final pages = ghList(json);
    if (pages.isNotEmpty && pages.first is List) {
      return pages.expand(ghList);
    }
    return pages;
  }
}

const _overviewIssueFields = <String>[
  'number',
  'title',
  'body',
  'url',
  'author',
  'labels',
  'commentsCount',
  'updatedAt',
  'assignees',
  'repository',
];

const _overviewPullRequestFields = <String>[
  'number',
  'title',
  'body',
  'url',
  'author',
  'labels',
  'commentsCount',
  'updatedAt',
  'isDraft',
  'repository',
];

const _repositoryListFields = <String>[
  'nameWithOwner',
  'description',
  'url',
  'defaultBranchRef',
  'stargazerCount',
  'forkCount',
  'isPrivate',
  'viewerPermission',
  'primaryLanguage',
  'latestRelease',
  'updatedAt',
];
