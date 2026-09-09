import 'dart:async';

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/app/detail_loader.dart';
import 'package:github_cli/src/app/messages.dart';
import 'package:github_cli/src/client/client.dart';
import 'package:github_cli/src/models/display_item.dart';
import 'package:github_cli/src/models/review_comment.dart';
import 'package:github_cli/src/state/notifiers.dart';
import 'package:test/test.dart';

class _Client implements GithubDashboardClient {
  final requests = <Completer<List<GithubPullRequestReviewComment>>>[];

  @override
  Future<List<GithubPullRequestReviewComment>> loadPullRequestReviewComments({
    required String repository,
    required int number,
  }) {
    final request = Completer<List<GithubPullRequestReviewComment>>();
    requests.add(request);
    return request.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _item = GithubDisplayItem(
  target: GithubDisplayTarget.pullRequest,
  kind: 'pr',
  number: 9,
  title: 'Review',
  body: '',
  url: '',
  author: 'author',
  status: '',
  updatedAt: null,
  footer: '',
  repository: 'owner/repo',
);

const _comment = GithubPullRequestReviewComment(
  id: 'new',
  path: 'a.dart',
  line: 1,
  side: 'RIGHT',
  author: 'reviewer',
  body: 'Current discussion',
  url: '',
  createdAt: null,
);

void main() {
  late _Client client;
  late GithubDetailNotifier detail;
  late GithubDashboardDetailLoader loader;

  setUp(() {
    client = _Client();
    detail = GithubDetailNotifier()..openDiff(_item);
    loader = GithubDashboardDetailLoader(
      client: () => client,
      data: GithubDataNotifier(),
      queue: GithubQueueNotifier(),
      detail: detail,
      detailScrollController: w.WidgetScrollController(),
      setLayoutMode: (_) => tui.Cmd.none(),
    );
  });

  Future<tui.Msg?> refresh() => loader
      .handleMessage(
        const GithubActionCompletedMsg('Comment added.', reviewItem: _item),
      )!
      .execute();

  test('latest refresh wins when requests finish in reverse order', () async {
    final older = refresh();
    final newer = refresh();
    client.requests[1].complete([_comment]);
    loader.handleMessage((await newer)!);
    client.requests[0].complete([]);
    loader.handleMessage((await older)!);
    expect(detail.diffReviewComments, [_comment]);
  });

  test('current failure is visible and retains existing discussions', () async {
    detail.applyDiffReviewCommentsLoaded([_comment]);
    final response = refresh();
    client.requests.single.completeError(StateError('offline'));
    final message = (await response)!;
    expect(loader.handlesMessage(message), isTrue);
    loader.handleMessage(message);
    expect(detail.diffReviewComments, [_comment]);
    expect(detail.notice, contains('Could not refresh inline comments'));
    expect(detail.notice, contains('offline'));
  });

  test('stale failures do not replace a newer successful notice', () async {
    final older = refresh();
    final newer = refresh();
    client.requests[1].complete([_comment]);
    loader.handleMessage((await newer)!);
    client.requests[0].completeError(StateError('old failure'));
    loader.handleMessage((await older)!);
    expect(detail.notice, 'Comment added.');
    expect(detail.diffReviewComments, [_comment]);
  });

  test('closing the diff ignores pending refresh results', () async {
    final response = refresh();
    detail.closeDiff();
    client.requests.single.complete([_comment]);
    loader.handleMessage((await response)!);
    expect(detail.diffReviewComments, isEmpty);
  });
}
