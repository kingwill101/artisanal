import 'dart:convert';

import 'package:github_cli/src/client/client.dart';
import 'package:github_cli/src/client/client_http.dart';
import 'package:github_cli/src/state/notifiers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test(
    'initial counts use open connection totals without loading tab pages',
    () async {
      final requests = <String>[];
      final transport = MockClient((request) async {
        requests.add(request.url.path);
        if (request.url.path == '/repos/owner/repo') {
          return http.Response(
            jsonEncode({
              'full_name': 'owner/repo',
              'open_issues_count': 9999, // REST combines issues and PRs.
            }),
            200,
          );
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['query'], repositoryCountsQuery);
        expect(body['variables'], {'owner': 'owner', 'name': 'repo'});
        return http.Response(
          jsonEncode({
            'data': {
              'repository': {
                'issues': {'totalCount': 8412},
                'pullRequests': {'totalCount': 30},
              },
            },
          }),
          200,
        );
      });
      addTearDown(transport.close);
      final dashboard = await GithubHttpClient(
        token: 'test',
        client: transport,
      ).loadDashboard(repository: 'owner/repo');
      expect(dashboard.openIssueCount, 8412);
      expect(dashboard.openPullRequestCount, 30);
      expect(dashboard.issues, isEmpty);
      expect(dashboard.pullRequests, isEmpty);
      expect(dashboard.copyWith().openIssueCount, 8412);
      final data = GithubDataNotifier()..applyLoaded(dashboard);
      expect(data.hasLoadedTab(1), isFalse);
      expect(data.hasLoadedTab(2), isFalse);
      expect(requests, ['/repos/owner/repo', '/graphql']);
    },
  );
}
