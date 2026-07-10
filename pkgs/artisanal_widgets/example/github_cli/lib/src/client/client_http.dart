import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard_data.dart';
import '../models/item_kind.dart';
import 'client.dart';
import 'json.dart';

final class GithubHttpClient
    implements GithubDashboardClient, GithubPullRequestDiffStreamingClient {
  GithubHttpClient({required this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String token;
  final http.Client _client;

  String? _authUser;

  static const _graphqlUrl = 'https://api.github.com/graphql';
  static const _restBase = 'https://api.github.com';

  Map<String, String> get _headers => <String, String>{
    'Authorization': 'Bearer $token',
    'Accept': 'application/vnd.github.v3+json',
  };

  Future<Object?> _get(String path) async {
    final uri = Uri.parse('$_restBase$path');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw GhCliException(
        'GitHub API GET $path failed: ${response.statusCode} ${response.body}',
      );
    }
    return jsonDecode(response.body) as Object?;
  }

  Future<Object?> _post(
    String path, {
    Object? body,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$_restBase$path');
    final http.Response response;
    if (fields != null) {
      response = await _client.post(
        uri,
        headers: {
          ..._headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: fields,
      );
    } else {
      response = await _client.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
    }
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw GhCliException(
        'GitHub API POST $path failed: ${response.statusCode} ${response.body}',
      );
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body) as Object?;
  }

  Future<Object?> _patch(String path, Object? body) async {
    final uri = Uri.parse('$_restBase$path');
    final response = await _client.patch(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw GhCliException(
        'GitHub API PATCH $path failed: ${response.statusCode} ${response.body}',
      );
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body) as Object?;
  }

  Future<Object?> _put(String path, Object? body) async {
    final uri = Uri.parse('$_restBase$path');
    final response = await _client.put(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw GhCliException(
        'GitHub API PUT $path failed: ${response.statusCode} ${response.body}',
      );
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body) as Object?;
  }

  Future<void> _delete(String path) async {
    final uri = Uri.parse('$_restBase$path');
    final response = await _client.delete(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw GhCliException(
        'GitHub API DELETE $path failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Object?>> _getAllPages(String path) async {
    final all = <Object?>[];
    var nextPath = path;
    while (nextPath.isNotEmpty) {
      final uri = Uri.parse('$_restBase$nextPath');
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) {
        throw GhCliException(
          'GitHub API GET $nextPath failed: '
          '${response.statusCode} ${response.body}',
        );
      }
      final json = jsonDecode(response.body);
      if (json is List) {
        all.addAll(json.cast<Object?>());
      } else if (json is Map) {
        final items = json['items'] ?? json['workflow_runs'] ?? json['jobs'];
        if (items is List) all.addAll(items.cast<Object?>());
      }
      nextPath = _nextPageUrl(response);
    }
    return all;
  }

  String _nextPageUrl(http.Response response) {
    final link = response.headers['link'];
    if (link == null) return '';
    final match = RegExp(r'<([^>]+)>;\s*rel="next"').firstMatch(link);
    if (match == null) return '';
    final url = match.group(1)!;
    final uri = Uri.parse(url);
    return '${uri.path}?${uri.query}';
  }

  Future<Object?> _graphql(String query, Map<String, Object?> variables) async {
    final uri = Uri.parse(_graphqlUrl);
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'query': query,
        'variables': variables,
      }),
    );
    if (response.statusCode != 200) {
      throw GhCliException(
        'GitHub GraphQL query failed: ${response.statusCode} ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final errors = json['errors'];
    if (errors != null) {
      throw GhCliException(_formatGraphQlErrors(errors, variables));
    }
    return json;
  }

  String _formatGraphQlErrors(Object? errors, Map<String, Object?> variables) {
    final errorList = ghList(errors);
    for (final error in errorList) {
      final map = ghMap(error);
      if (ghString(map['type']) == 'NOT_FOUND') {
        final path = ghList(
          map['path'],
        ).map((item) => item.toString()).toList();
        if (path.length >= 2 &&
            path[0] == 'repository' &&
            path[1] == 'pullRequest') {
          final repo = ghString(variables['name']);
          final owner = ghString(variables['owner']);
          final number = ghInt(variables['number']);
          final target = owner.isEmpty || repo.isEmpty
              ? 'the selected repository'
              : '$owner/$repo';
          return number > 0
              ? 'Pull request #$number was not found in $target.'
              : 'The requested pull request was not found in $target.';
        }
      }
    }
    return 'GitHub GraphQL errors: ${errors.toString()}';
  }

  Future<String> _getAuthenticatedUser() async {
    if (_authUser != null) return _authUser!;
    final json = ghMap(await _get('/user'));
    _authUser = ghString(json['login']);
    return _authUser ?? '';
  }

  @override
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  }) async {
    if ((owner ?? '').trim().isNotEmpty) {
      return _loadOwnerDashboard(owner!.trim(), limit: limit);
    }
    final repoJson = ghMap(await _get('/repos/$repository'));
    return GithubDashboardData.fromJson(
      repository: _repoToGhStyle(repoJson),
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
    final futures = <Future<List<Object?>>>[];
    final parseIssues = filter != GithubOverviewFilter.reviewRequested;
    if (parseIssues) {
      futures.add(
        _searchIssues(
          scope: scope,
          filter: filter,
          pullRequests: false,
          limit: limit,
        ),
      );
    }
    futures.add(
      _searchIssues(
        scope: scope,
        filter: filter,
        pullRequests: true,
        limit: limit,
      ),
    );

    final results = await Future.wait(futures);
    final issueItems = parseIssues ? results.first : const <Object?>[];
    final prItems = parseIssues ? results[1] : results.first;
    return GithubOverviewBucket(
      issues: issueItems
          .map((item) => GithubIssueItem.fromJson(ghMap(item)))
          .toList(growable: false),
      pullRequests: prItems
          .map((item) => GithubPullRequestItem.fromJson(ghMap(item)))
          .toList(growable: false),
    );
  }

  Future<List<Object?>> _searchIssues({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required bool pullRequests,
    required int limit,
  }) async {
    if (scope.kind == GithubDashboardScopeKind.user &&
        filter == GithubOverviewFilter.authored) {
      return const <Object?>[];
    }

    final query = StringBuffer();
    query.write(pullRequests ? 'is:pr' : 'is:issue');
    query.write(' state:open');

    switch (scope.kind) {
      case GithubDashboardScopeKind.repository:
        query.write(' repo:${scope.repository}');
      case GithubDashboardScopeKind.organization:
        query.write(' org:${scope.owner}');
      case GithubDashboardScopeKind.user:
        break;
    }

    final user = await _getAuthenticatedUser();
    final actor = scope.actor == '@me' ? user : scope.actor;
    switch (filter) {
      case GithubOverviewFilter.assigned:
        query.write(' assignee:$actor');
      case GithubOverviewFilter.mentioned:
        query.write(' mentions:$actor');
      case GithubOverviewFilter.authored:
        query.write(' author:$actor');
      case GithubOverviewFilter.reviewRequested:
        query.write(' review-requested:$actor');
    }

    query.write('&per_page=$limit');
    final json = ghMap(
      await _get('/search/issues?q=${Uri.encodeComponent(query.toString())}'),
    );
    final items = ghList(json['items']);
    return items
        .map((item) => _searchItemToGhStyle(ghMap(item)))
        .toList(growable: false);
  }

  @override
  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    final parts = _repositoryParts(repository);
    final json = ghMap(
      await _graphql(issuesPageQuery, <String, Object?>{
        'owner': parts.owner,
        'name': parts.name,
        'first': first,
        ?'after': after,
      }),
    );
    final issues = ghMap(ghMap(ghMap(json['data'])['repository'])['issues']);
    final pageInfo = ghMap(issues['pageInfo']);
    return GithubPage<GithubIssueItem>(
      items: ghList(issues['nodes'])
          .map((item) => GithubIssueItem.fromJson(ghMap(item)))
          .toList(growable: false),
      totalCount: ghInt(issues['totalCount']),
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
    final json = ghMap(
      await _graphql(pullRequestsPageQuery, <String, Object?>{
        'owner': parts.owner,
        'name': parts.name,
        'first': first,
        ?'after': after,
      }),
    );
    final prs = ghMap(ghMap(ghMap(json['data'])['repository'])['pullRequests']);
    final pageInfo = ghMap(prs['pageInfo']);
    return GithubPage<GithubPullRequestItem>(
      items: ghList(prs['nodes'])
          .map((item) => GithubPullRequestItem.fromJson(ghMap(item)))
          .toList(growable: false),
      totalCount: ghInt(prs['totalCount']),
      hasNextPage: pageInfo['hasNextPage'] == true,
      endCursor: ghString(pageInfo['endCursor']),
    );
  }

  @override
  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  }) async {
    final parts = _repositoryParts(repository);
    final json = ghMap(
      await _graphql(pullRequestQuery, <String, Object?>{
        'owner': parts.owner,
        'name': parts.name,
        'number': number,
      }),
    );
    final pr = ghMap(ghMap(ghMap(json['data'])['repository'])['pullRequest']);
    return GithubPullRequestItem.fromJson(pr);
  }

  @override
  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  }) async {
    final json = ghMap(
      await _get('/repos/$repository/actions/runs?per_page=$first&page=$page'),
    );
    final total = ghInt(json['total_count']);
    return GithubPage<GithubWorkflowRunItem>(
      items: ghList(json['workflow_runs'])
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
    final items = await _getAllPages(
      '/repos/$repository/issues/$number/comments?per_page=100',
    );
    return items
        .map((item) => GithubCommentItem.fromJson(ghMap(item)))
        .toList(growable: false);
  }

  @override
  Future<List<GithubPullRequestReviewComment>> loadPullRequestReviewComments({
    required String repository,
    required int number,
  }) async {
    final items = await _getAllPages(
      '/repos/$repository/pulls/$number/comments?per_page=100',
    );
    final comments = <GithubPullRequestReviewComment>[];
    for (final item in items) {
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
    final items = await _getAllPages(
      '/repos/$repository/pulls/$number/commits?per_page=100',
    );
    return items
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
      final raw = await _get(
        '/repos/$repository/pulls/$number/files?per_page=100&page=$page',
      );
      final files = ghList(raw)
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
    final parts = _repositoryParts(repository);
    final json = ghMap(
      await _graphql(pullRequestMergeQuery, <String, Object?>{
        'owner': parts.owner,
        'name': parts.name,
        'number': number,
      }),
    );
    final pr = ghMap(ghMap(ghMap(json['data'])['repository'])['pullRequest']);
    return GithubPullRequestMergeInfo.fromJson(pr);
  }

  @override
  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  }) async {
    final runJson = ghMap(
      await _get('/repos/$repository/actions/runs/$databaseId'),
    );
    final jobsJson = ghMap(
      await _get('/repos/$repository/actions/runs/$databaseId/jobs'),
    );
    // Merge jobs into the run JSON for GithubWorkflowRunDetail.fromJson
    runJson['jobs'] = jobsJson['jobs'];
    return GithubWorkflowRunDetail.fromJson(runJson);
  }

  @override
  Future<void> addComment({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required String body,
  }) async {
    await _post(
      '/repos/$repository/issues/$number/comments',
      body: <String, Object?>{'body': body},
    );
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
    final payload = <String, Object?>{
      'body': body,
      'commit_id': commitId,
      'path': path,
      'line': line,
      'side': side,
    };
    if (startLine != null) payload['start_line'] = startLine;
    if (startSide != null) payload['start_side'] = startSide;
    final json = ghMap(
      await _post('/repos/$repository/pulls/$number/comments', body: payload),
    );
    final comment = GithubPullRequestReviewComment.fromJson(json);
    if (comment == null) {
      throw const GhCliException(
        'GitHub API returned an invalid review comment.',
      );
    }
    return comment;
  }

  @override
  Future<void> addLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  }) async {
    if (labels.isEmpty) return;
    await _post(
      '/repos/$repository/issues/$number/labels',
      body: <String, Object?>{'labels': labels},
    );
  }

  @override
  Future<void> removeLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  }) async {
    if (labels.isEmpty) return;
    // Delete each label individually (REST requires one call per label)
    for (final label in labels) {
      try {
        await _delete(
          '/repos/$repository/issues/$number/labels/${Uri.encodeComponent(label)}',
        );
      } on GhCliException {
        // Ignore 404s for labels that don't exist on the issue
      }
    }
  }

  @override
  Future<void> mergePullRequest({
    required String repository,
    required int number,
    required GithubPullRequestMergeAction action,
  }) async {
    final mergeMethod = switch (action) {
      GithubPullRequestMergeAction.merge ||
      GithubPullRequestMergeAction.autoMerge ||
      GithubPullRequestMergeAction.adminMerge => 'merge',
      GithubPullRequestMergeAction.squash ||
      GithubPullRequestMergeAction.autoSquash ||
      GithubPullRequestMergeAction.adminSquash => 'squash',
      GithubPullRequestMergeAction.rebase ||
      GithubPullRequestMergeAction.autoRebase ||
      GithubPullRequestMergeAction.adminRebase => 'rebase',
      GithubPullRequestMergeAction.disableAuto => 'merge', // N/A for REST
    };
    await _put('/repos/$repository/pulls/$number/merge', <String, Object?>{
      'merge_method': mergeMethod,
    });
  }

  @override
  Future<void> closePullRequest({
    required String repository,
    required int number,
  }) async {
    await _patch('/repos/$repository/pulls/$number', <String, Object?>{
      'state': 'closed',
    });
  }

  @override
  Future<void> togglePullRequestDraft({
    required String repository,
    required int number,
    required bool isDraft,
  }) async {
    await _patch('/repos/$repository/pulls/$number', <String, Object?>{
      'draft': isDraft,
    });
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
    final futures = <Future<({List<Object?> items, int totalCount})>>[
      _searchHttp(
        scope: scope,
        query: query,
        pullRequests: false,
        limit: limit,
        page: page,
      ),
      _searchHttp(
        scope: scope,
        query: query,
        pullRequests: true,
        limit: limit,
        page: page,
      ),
    ];
    final results = await Future.wait(futures);
    final hasMore = results.any((r) => r.totalCount > page * limit);
    return (
      bucket: GithubOverviewBucket(
        issues: results[0].items
            .map((item) => GithubIssueItem.fromJson(ghMap(item)))
            .toList(growable: false),
        pullRequests: results[1].items
            .map((item) => GithubPullRequestItem.fromJson(ghMap(item)))
            .toList(growable: false),
      ),
      hasMore: hasMore,
    );
  }

  Future<({List<Object?> items, int totalCount})> _searchHttp({
    required GithubDashboardScope scope,
    required String query,
    required bool pullRequests,
    required int limit,
    required int page,
  }) async {
    final q = StringBuffer();
    q.write(pullRequests ? 'is:pr' : 'is:issue');
    q.write(' state:open');
    q.write(' $query');

    switch (scope.kind) {
      case GithubDashboardScopeKind.repository:
        q.write(' repo:${scope.repository}');
      case GithubDashboardScopeKind.organization:
        q.write(' org:${scope.owner}');
      case GithubDashboardScopeKind.user:
        break;
    }

    q.write('&per_page=$limit');
    q.write('&page=$page');
    final json = ghMap(
      await _get('/search/issues?q=${Uri.encodeComponent(q.toString())}'),
    );
    final items = ghList(json['items']);
    final totalCount = ghInt(json['total_count']);
    return (
      items: items
          .map((item) => _searchItemToGhStyle(ghMap(item)))
          .toList(growable: false),
      totalCount: totalCount,
    );
  }

  @override
  Future<List<GithubRepositoryLabel>> loadRepositoryLabels({
    required String repository,
  }) async {
    final raw = await _get('/repos/$repository/labels?per_page=100');
    return ghList(raw)
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
    final raw = await _get(
      '/${scope.kind == GithubDashboardScopeKind.organization ? 'orgs' : 'users'}/${scope.owner}/repos?per_page=$limit&sort=updated&type=all',
    );
    return ghList(raw)
        .map(
          (item) =>
              GithubRepositorySummary.fromJson(_repoToGhStyle(ghMap(item))),
        )
        .toList(growable: false);
  }

  Future<GithubDashboardScope> _resolveOwnerScope(String owner) async {
    if (owner == '@me') {
      final json = ghMap(await _get('/user'));
      final login = ghString(json['login'], fallback: owner);
      final type = ghString(json['type']).toLowerCase();
      if (type == 'organization') {
        return GithubDashboardScope.organization(login);
      }
      return GithubDashboardScope.user(login);
    }
    final json = ghMap(await _get('/users/$owner'));
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

  Map<String, Object?> _searchItemToGhStyle(Map<String, Object?> item) {
    final user = ghMap(item['user']);
    final repoUrl = ghString(item['repository_url']);
    final repoName = repoUrl.replaceFirst('https://api.github.com/repos/', '');
    return <String, Object?>{
      'number': item['number'],
      'title': item['title'],
      'body': item['body'],
      'url': item['html_url'],
      'author': <String, Object?>{
        'login': user['login'],
        'avatarUrl': user['avatar_url'],
      },
      'labels': item['labels'],
      'assignees': item['assignees'],
      'comments': item['comments'],
      'updatedAt': item['updated_at'],
      'repository': <String, Object?>{'nameWithOwner': repoName},
      if (item['draft'] == true) 'isDraft': true,
    };
  }

  Map<String, Object?> _repoToGhStyle(Map<String, Object?> rest) {
    final defaultBranch = ghString(rest['default_branch']);
    final language = ghString(rest['language']);
    return <String, Object?>{
      'nameWithOwner': ghString(rest['full_name']),
      'description': rest['description'],
      'url': rest['html_url'],
      if (defaultBranch.isNotEmpty)
        'defaultBranchRef': <String, Object?>{'name': defaultBranch},
      'stargazerCount': ghInt(
        rest['stargazers_count'] ?? rest['stargazerCount'],
      ),
      'forkCount': ghInt(rest['forks_count'] ?? rest['forks'] ?? 0),
      'isPrivate': rest['private'] == true,
      'viewerPermission': _permissionToViewerPermission(rest['permissions']),
      if (language.isNotEmpty)
        'primaryLanguage': <String, Object?>{'name': language},
      'latestRelease': null,
      'updatedAt': rest['updated_at'],
    };
  }

  String _permissionToViewerPermission(Object? permissions) {
    final perms = ghMap(permissions);
    if (perms['admin'] == true) return 'ADMIN';
    if (perms['push'] == true) return 'WRITE';
    if (perms['pull'] == true) return 'READ';
    return 'UNKNOWN';
  }
}
