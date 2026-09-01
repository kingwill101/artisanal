// ignore_for_file: unused_element

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:artisanal/args.dart' show ArgParser;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/app/app_io.dart';
import 'package:github_cli/src/app/theme.dart';
import 'package:github_cli/src/client/fields.dart';
import 'package:github_cli/src/ui/markdown/body.dart';
import 'package:github_cli/src/utils/diff_comment_mapper.dart';
import 'package:image/image.dart' as img;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    tester.pump();
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for GitHub CLI dashboard\n${tester.view}');
}

Uint8List _encodeAvatarImage() {
  final image = img.Image(width: 8, height: 8);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, 20 + x * 20, 140 + y * 8, 220, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

({tui.ReplayHarnessConfig config, String? error}) _parseReplayConfig(
  List<String> arguments,
) {
  final parsed = (ArgParser()..registerReplayFlags()).parse(arguments);
  final config = tui.ReplayHarnessConfig.fromArgResults(parsed);
  return (config: config, error: config.error);
}

void main() {
  test('GithubCliConfig defaults to the authenticated user overview', () {
    final config = GithubCliConfig.parse([]);

    expect(config.repository, isNull);
    expect(config.owner, '@me');
    expect(config.hasError, isFalse);
  });

  test('GithubCliConfig parses repo and limit', () {
    final config = GithubCliConfig.parse([
      '--repo',
      'owner/project',
      '--limit',
      '10',
    ]);

    expect(config.repository, 'owner/project');
    expect(config.limit, 10);
    expect(config.hasError, isFalse);
  });

  test('GithubCliConfig accepts GitHub repository URLs', () {
    final config = GithubCliConfig.parse([
      'https://github.com/bytecodealliance/wasm-pkg-tools',
    ]);

    expect(config.repository, 'bytecodealliance/wasm-pkg-tools');
    expect(config.hasError, isFalse);
  });

  test('GithubCliConfig accepts owner and organization targets', () {
    final owner = GithubCliConfig.parse(['kingwill101']);
    final ownerUrl = GithubCliConfig.parse(['https://github.com/dart-lang']);

    expect(owner.repository, isNull);
    expect(owner.owner, 'kingwill101');
    expect(owner.hasError, isFalse);
    expect(ownerUrl.repository, isNull);
    expect(ownerUrl.owner, 'dart-lang');
    expect(ownerUrl.hasError, isFalse);
  });

  test('parseGithubPullRequestTarget accepts URLs and shorthand forms', () {
    final url = parseGithubPullRequestTarget(
      'https://github.com/dart-lang/sdk/pull/63254',
    );
    final prPath = parseGithubPullRequestTarget('dart-lang/sdk/pr/63254');
    final pullPath = parseGithubPullRequestTarget('dart-lang/sdk/pull/63254');
    final shorthand = parseGithubPullRequestTarget('dart-lang/sdk#63254');
    final hostPath = parseGithubPullRequestTarget(
      'github.com/dart-lang/sdk/pull/63254',
    );

    for (final target in [url, prPath, pullPath, shorthand, hostPath]) {
      expect(target?.repository, 'dart-lang/sdk');
      expect(target?.number, 63254);
    }
    expect(parseGithubPullRequestTarget('dart-lang/sdk'), isNull);
  });

  test('GithubCliViewConfig parses a pull request target', () {
    final command = GithubCliViewCommand();
    final parsed = command.argParser.parse([
      'https://github.com/dart-lang/sdk/pull/63254',
    ]);
    final config = GithubCliViewConfig.fromArgResults(parsed);

    expect(config.error, isNull);
    expect(config.target?.repository, 'dart-lang/sdk');
    expect(config.target?.number, 63254);
  });

  test(
    'githubPullRequestFilesToPatch builds unified diff from files API data',
    () {
      final patch = githubPullRequestFilesToPatch(
        const <GithubPullRequestDiffFile>[
          GithubPullRequestDiffFile(
            filename: 'src/one.dart',
            status: 'modified',
            patch: '@@ -1,2 +1,2 @@\n const a = 1\n-const b = 2\n+const b = 3',
          ),
          GithubPullRequestDiffFile(
            filename: 'src/two.dart',
            status: 'added',
            patch: '@@ -0,0 +1 @@\n+const c = 4',
          ),
        ],
      );

      expect(patch, contains('diff --git a/src/one.dart b/src/one.dart'));
      expect(patch, contains('--- /dev/null'));
      expect(patch, contains('+++ b/src/two.dart'));
      expect(patch, contains('+const c = 4'));
    },
  );

  test('GithubPullRequestDiffBuffer truncates large API diffs', () {
    final buffer = GithubPullRequestDiffBuffer(maxFiles: 1, maxBytes: 1024);
    final first = buffer.addFiles(const <GithubPullRequestDiffFile>[
      GithubPullRequestDiffFile(
        filename: 'src/one.dart',
        patch: '@@ -1 +1 @@\n-old\n+new',
      ),
      GithubPullRequestDiffFile(
        filename: 'src/two.dart',
        patch: '@@ -1 +1 @@\n-old\n+new',
      ),
    ]);
    final done = buffer.finish();

    expect(first.text, contains('src/one.dart'));
    expect(first.text, isNot(contains('src/two.dart')));
    expect(first.files, hasLength(2));
    expect(first.files.last.filename, 'src/two.dart');
    expect(first.files.last.isCollapsed, isTrue);
    expect(done.text, contains('Diff preview truncated'));
    expect(done.files.single.filename, '.github-cli-diff-limit');
    expect(done.omittedFiles, 1);
  });

  test('GithubPullRequestDiffBuffer collapses large file bodies', () {
    final buffer = GithubPullRequestDiffBuffer(maxFiles: 10, maxBytes: 1024);
    final chunk = buffer.addFiles([
      GithubPullRequestDiffFile(
        filename: 'assets/large.txt',
        patch: '@@ -1 +1 @@\n-${'a' * 140000}\n+${'b' * 140000}',
      ),
    ]);

    expect(chunk.files.single.isCollapsed, isTrue);
    expect(chunk.files.single.patch, isNull);
    expect(chunk.text, contains('Diff body collapsed'));
    expect(chunk.text, isNot(contains('a' * 2000)));
  });

  test('GithubCliConfig hides replay flags by default', () {
    final config = GithubCliConfig.parse([
      '--replay-scenario',
      'issues_scroll_detail',
    ]);

    expect(config.hasError, isTrue);
    expect(config.error, contains('replay-scenario'));
  });

  test('GithubCliRunner hides automation commands by default', () {
    final commands = GithubCliRunner().commands.keys;

    expect(commands, contains('view'));
    expect(commands, isNot(contains('profile')));
    expect(commands, isNot(contains('replay')));
  });

  test('ReplayHarnessConfig parses replay flags', () {
    final replay = _parseReplayConfig([
      '--replay-scenario',
      'issues_scroll_detail',
      '--replay-speed',
      '6',
      '--replay-block-input',
    ]);

    expect(replay.error, isNull);
    expect(replay.config.scenarioPath, 'issues_scroll_detail');
    expect(replay.config.speed, 6);
    expect(replay.config.blockInput, isTrue);
  });

  test('ReplayHarnessConfig rejects multiple replay sources', () {
    final replay = _parseReplayConfig([
      '--replay-scenario',
      'issues_scroll_detail',
      '--replay-trace',
      'trace.log',
    ]);

    expect(replay.error, contains('Use only one'));
  });

  test('loadGithubCliReplayPlan resolves built-in scenarios', () async {
    final plan = await loadGithubCliReplayPlan(
      const tui.ReplayHarnessConfig(
        scenarioPath: 'issues_scroll_detail',
        tracePath: null,
        scriptFilter: '',
        sessionOut: '',
        scenarioOut: null,
        scenarioName: 'replay',
        scenarioDescription: '',
        speed: 1,
        minSleepUs: 30000,
        leadInMs: 3500,
        screenWidth: 0,
        screenHeight: 0,
        fixedRightWidth: 0,
        blockInput: false,
        loop: false,
        keepOpen: false,
        timeoutSeconds: 180,
        convertOnly: false,
        captureTrace: false,
        traceOut: '',
        traceTags: '',
        captureDispatch: false,
        summaryCount: 0,
        maxSpanUs: 0,
        traceFromUs: null,
        traceToUs: null,
        traceIncludeHoverMoves: false,
      ),
    );

    expect(plan, isNotNull);
    expect(plan!.name, 'issues_scroll_detail');
    expect(plan.actionCount, greaterThan(10));
  });

  test('loadGithubCliReplayPlan converts trace files', () async {
    final dir = await Directory.systemTemp.createTemp(
      'github-cli-replay-test-',
    );
    addTearDown(() => dir.delete(recursive: true));
    final trace = File('${dir.path}/manual.log');
    final out = File('${dir.path}/manual.json');
    await trace.writeAsString(
      '[+10us] [input] @event '
      '{"v":1,"type":"window.size","width":120,"height":40}\n'
      '[+20us] [input] @event '
      '{"v":1,"type":"input.batch","messages":['
      '{"kind":"key","keyType":"runes","runes":[50]}]}\n',
    );

    final plan = await loadGithubCliReplayPlan(
      tui.ReplayHarnessConfig(
        scenarioPath: null,
        tracePath: trace.path,
        scriptFilter: '',
        sessionOut: '',
        scenarioOut: out.path,
        scenarioName: 'replay',
        scenarioDescription: '',
        speed: 1,
        minSleepUs: 30000,
        leadInMs: 3500,
        screenWidth: 0,
        screenHeight: 0,
        fixedRightWidth: 0,
        blockInput: false,
        loop: false,
        keepOpen: false,
        timeoutSeconds: 180,
        convertOnly: true,
        captureTrace: false,
        traceOut: '',
        traceTags: '',
        captureDispatch: false,
        summaryCount: 0,
        maxSpanUs: 0,
        traceFromUs: null,
        traceToUs: null,
        traceIncludeHoverMoves: false,
      ),
    );

    expect(plan, isNotNull);
    expect(plan!.convertOnly, isTrue);
    expect(plan.traceConversion?.eventCount, 1);
    expect(out.existsSync(), isTrue);
  });

  test('GithubDashboardData parses gh JSON payloads', () {
    final dashboard = GithubDashboardData.fromJson(
      loadedAt: DateTime.utc(2026, 5, 1, 12),
      repository: const <String, Object?>{
        'nameWithOwner': 'kingwill101/artisanal',
        'description': 'Terminal toolkit',
        'url': 'https://github.com/kingwill101/artisanal',
        'defaultBranchRef': <String, Object?>{'name': 'main'},
        'stargazerCount': 2,
        'forkCount': 1,
        'isPrivate': false,
        'viewerPermission': 'ADMIN',
        'primaryLanguage': <String, Object?>{'name': 'Dart'},
        'latestRelease': <String, Object?>{'tagName': 'v0.3.0'},
      },
      issues: const [
        <String, Object?>{
          'number': 7,
          'title': 'Wire dashboard',
          'body': 'Issue body from gh.',
          'url': 'https://example.test/issues/7',
          'author': <String, Object?>{'login': 'octo'},
          'labels': [
            <String, Object?>{'name': 'feature', 'color': '5319e7'},
          ],
          'comments': [
            <String, Object?>{'body': 'first'},
          ],
          'assignees': [
            <String, Object?>{'login': 'dev'},
          ],
          'updatedAt': '2026-05-01T11:00:00Z',
        },
      ],
      pullRequests: const [
        <String, Object?>{
          'number': 9,
          'title': 'Add gh tui',
          'body': 'Pull request body from gh.',
          'url': 'https://example.test/pull/9',
          'author': <String, Object?>{'login': 'octo'},
          'labels': [
            <String, Object?>{'name': 'cli', 'color': '#0e8a16'},
          ],
          'comments': [
            <String, Object?>{'body': 'first'},
            <String, Object?>{'body': 'second'},
          ],
          'updatedAt': '2026-05-01T11:30:00Z',
          'reviewDecision': 'APPROVED',
          'isDraft': false,
          'statusCheckRollup': <String, Object?>{
            'contexts': <String, Object?>{
              'nodes': [
                <String, Object?>{
                  '__typename': 'CheckRun',
                  'name': 'test',
                  'status': 'COMPLETED',
                  'conclusion': 'SUCCESS',
                },
              ],
            },
          },
        },
      ],
      workflows: const [
        <String, Object?>{
          'id': 101,
          'name': 'CI',
          'path': '.github/workflows/ci.yml',
          'state': 'active',
        },
      ],
      workflowRuns: const [
        <String, Object?>{
          'databaseId': 9001,
          'number': 12,
          'attempt': 1,
          'workflowName': 'CI',
          'displayTitle': 'Validate widgets',
          'status': 'completed',
          'conclusion': 'success',
          'event': 'push',
          'headBranch': 'main',
          'url': 'https://example.test/actions/runs/9001',
          'updatedAt': '2026-05-01T11:45:00Z',
        },
      ],
    );

    expect(dashboard.repository.nameWithOwner, 'kingwill101/artisanal');
    expect(dashboard.repository.primaryLanguage, 'Dart');
    expect(dashboard.issues.single.labels, ['feature']);
    expect(dashboard.issues.single.labelDetails.single.color, '#5319e7');
    expect(dashboard.issues.single.commentCount, 1);
    expect(dashboard.pullRequests.single.labels, ['cli']);
    expect(dashboard.pullRequests.single.labelDetails.single.color, '#0e8a16');
    expect(dashboard.pullRequests.single.checks.label, 'checks 1/1');
    expect(dashboard.pullRequests.single.checks.items.single.name, 'test');
    expect(dashboard.workflowCount, 1);
    expect(dashboard.workflowRuns.single.statusLabel, 'success');
  });

  test('merge info fields avoid unsupported gh pr view fields', () {
    expect(ghPullRequestMergeFields, contains('mergeable'));
    expect(ghPullRequestMergeFields, contains('statusCheckRollup'));
    expect(ghPullRequestMergeFields, isNot(contains('viewerCanMergeAsAdmin')));
    expect(ghPullRequestMergeFields, isNot(contains('mergeCommitAllowed')));
    expect(ghPullRequestMergeFields, isNot(contains('squashMergeAllowed')));
    expect(ghPullRequestMergeFields, isNot(contains('rebaseMergeAllowed')));
  });

  test('issue fields avoid pull request-only fields', () {
    expect(ghIssueFields, isNot(contains('headRefOid')));
    expect(ghPullRequestFields, contains('headRefOid'));
  });

  test('merge info keeps default CLI merge methods when gh omits policy', () {
    final info = GithubPullRequestMergeInfo.fromJson(const <String, Object?>{
      'number': 9,
      'title': 'Add gh tui',
      'state': 'OPEN',
      'isDraft': false,
      'mergeable': 'MERGEABLE',
      'reviewDecision': 'APPROVED',
      'statusCheckRollup': <String, Object?>{
        'contexts': <String, Object?>{'nodes': <Object?>[]},
      },
    });

    expect(info.mergeMethodPolicyKnown, isFalse);
    expect(info.allowedMethods, ['merge', 'squash', 'rebase']);
    expect(
      info.availableActions.map((action) => action.name),
      containsAll(['merge', 'squash', 'rebase']),
    );
  });

  test('dashboard renders loaded repository and switches tabs', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 30);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      GithubCliDashboard(
        client: _FakeGithubClient(_sampleDashboard()),
        repository: 'kingwill101/artisanal',
      ),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));

    expect(tester.find.text('GHUI'), isTrue);
    expect(tester.find.text('PULL REQUESTS'), isTrue);

    tester.tap(tester.find.textLocation('2 Issues 1'));
    await _pumpUntil(tester, () => tester.view.contains('#7 Wire dashboard'));

    tester.tap(tester.find.textLocation('3 PRs 1'));
    await _pumpUntil(tester, () => tester.view.contains('#9 Add gh tui'));
    expect(tester.view, contains('@octo'));
    expect(tester.view, contains('checks 1/1'));
    expect(tester.view, contains('Checks'));
    expect(tester.view, contains('test'));
    expect(tester.view, contains('Conversation 2'));
    expect(tester.view, contains('Commits 2'));
    expect(tester.view, contains('Files changed'));

    tester.tap(tester.find.textLocation('Commits 2'));
    await _pumpUntil(tester, () => tester.view.contains('abc1234'));
    expect(tester.view, contains('Add gh tui'));
    expect(tester.view, contains('abc1234'));

    tester.sendKey('4');
    expect(tester.view, contains('#12 Validate widgets'));
    expect(tester.view, contains('success'));
    expect(tester.view, contains('Run info'));
  });

  test('initial load shows animated splash while gh is pending', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 30);
    addTearDown(() => tester.dispose());
    final loadGate = Completer<void>();

    await tester.pumpWidget(
      GithubCliDashboard(
        client: _FakeGithubClient(
          _sampleDashboard(),
          loadGate: loadGate.future,
        ),
        repository: 'kingwill101/artisanal',
      ),
    );

    expect(tester.view, contains('GHUI'));
    expect(tester.view, contains('GitHub from inside your terminal'));
    expect(tester.view, contains('Loading kingwill101/artisanal'));
    expect(tester.view, contains('issues'));
    expect(tester.view, contains('checks'));
    expect(tester.view, contains('Running gh commands...'));

    loadGate.complete();
    await _pumpUntil(tester, () => tester.view.contains('PULL REQUESTS'));
  });

  test(
    'initial splash remains until active tab page content appears',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 34);
      addTearDown(() => tester.dispose());
      final pageGate = Completer<void>();
      final client = _LazyPagingGithubClient(
        pullRequestPageGate: pageGate.future,
      );

      await tester.pumpWidget(
        GithubCliDashboard(
          client: client,
          repository: 'kingwill101/artisanal',
          limit: 1,
        ),
      );

      await _pumpUntil(
        tester,
        () =>
            client.pullRequestPageCalls == 1 &&
            tester.view.contains('Running gh commands...'),
      );
      expect(tester.view, contains('Loading kingwill101/artisanal'));
      expect(tester.view, isNot(contains('#1 Paged PR 1')));

      pageGate.complete();
      await _pumpUntil(tester, () => tester.view.contains('#1 Paged PR 1'));
      expect(tester.view, contains('PULL REQUESTS'));
      expect(tester.view, isNot(contains('Running gh commands...')));
    },
  );

  test('ctrl+o switches repositories from a GitHub URL', skip: true, () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 32);
    addTearDown(() => tester.dispose());
    final client = _RecordingGithubClient();

    await tester.pumpWidget(GithubCliDashboard(client: client));
    await _pumpUntil(tester, () => tester.find.text('current/repo'));

    tester.sendMsg(tui.KeyMsg(tui.Key.char('o', ctrl: true)));
    expect(tester.view, contains('Switch target'));
    expect(tester.view, contains('@me'));

    tester.typeText('https://github.com/bytecodealliance/wasm-pkg-tools');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));

    await _pumpUntil(
      tester,
      () => tester.find.text('bytecodealliance/wasm-pkg-tools'),
    );
    expect(client.repositories, [null, 'bytecodealliance/wasm-pkg-tools']);
  });

  test('overview mode loads owner work and switches filters', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _RecordingGithubClient();

    await tester.pumpWidget(
      GithubCliDashboard(client: client, owner: 'kingwill101'),
    );

    await _pumpUntil(
      tester,
      () => tester.view.contains('OVERVIEW') && tester.view.contains('Add gh'),
    );

    expect(client.owners, ['kingwill101']);
    expect(client.overviewFilters, [GithubOverviewFilter.authored]);
    expect(tester.view, contains('authored'));
    expect(tester.view, isNot(contains('REPOSITORIES')));

    tester.tap(tester.find.textLocation('mentioned'));
    await _pumpUntil(
      tester,
      () => client.overviewFilters.contains(GithubOverviewFilter.mentioned),
    );

    expect(client.overviewFilters, [
      GithubOverviewFilter.authored,
      GithubOverviewFilter.mentioned,
    ]);

    tester.sendKey('p');
    tester.typeText('browse');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(
      tester,
      () =>
          tester.view.contains('Repositories') &&
          tester.view.contains('kingwill101/lualike'),
    );

    tester.typeText('lualike');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(tester, () => tester.find.text('kingwill101/lualike'));

    expect(client.repositories, [null, 'kingwill101/lualike']);
  });

  test('p opens the command palette with dashboard actions', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      GithubCliDashboard(
        client: _FakeGithubClient(_sampleDashboard()),
        repository: 'kingwill101/artisanal',
      ),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('p');

    expect(tester.view, contains('GitHub command center'));
    expect(tester.view, contains('Switch target'));
    expect(tester.view, contains('Browse repos'));
    expect(tester.view, contains('Open @me'));
    expect(tester.view, contains('Cycle theme'));
    expect(tester.view, contains('Focus'));
  });

  test('t cycles dashboard themes', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      GithubCliDashboard(
        client: _FakeGithubClient(_sampleDashboard()),
        repository: 'kingwill101/artisanal',
      ),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));

    expect(tester.view, contains('opencode'));

    tester.sendKey('t');
    expect(tester.view, contains('github'));

    tester.sendKey('t');
    expect(tester.view, contains('tokyonight'));
  });

  test('enter focuses issue and pull request details', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      GithubCliDashboard(
        client: _FakeGithubClient(_sampleDashboard()),
        repository: 'kingwill101/artisanal',
      ),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));

    tester.sendKey('2');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    expect(tester.view, isNot(contains('ISSUES')));
    expect(tester.view, contains('#7'));
    expect(tester.view, contains('Wire dashboard'));
    expect(tester.view, contains('Issue body from gh.'));
    expect(tester.view, contains('f/esc'));

    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.escape)));
    expect(tester.view, contains('ISSUES'));

    tester.sendKey('3');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    expect(tester.view, isNot(contains('PULL REQUESTS')));
    expect(tester.view, contains('#9'));
    expect(tester.view, contains('Add gh tui'));
    expect(tester.view, contains('Pull request body from gh.'));
  });

  test(
    'detail pane renders GitHub HTML bodies through MarkdownText',
    skip: true,
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        GithubCliDashboard(
          client: _FakeGithubClient(
            _sampleDashboard(),
            reviewComments: const [
              GithubPullRequestReviewComment(
                id: 'review-1',
                path: 'lib/main.dart',
                line: 2,
                side: 'RIGHT',
                author: 'reviewer',
                body: 'Inline review note.',
                url: 'https://example.test/review/1',
                createdAt: null,
              ),
            ],
          ),
          repository: 'kingwill101/artisanal',
        ),
      );

      await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
      tester.sendKey('3');
      await _pumpUntil(tester, () => tester.view.contains('Test plan'));
      final plainView = Style.stripAnsi(tester.view);

      expect(plainView, contains('[x] PoC'));
      expect(plainView, contains('[ ] After the fix'));
      expect(plainView, isNot(contains('\u2022 [x]')));
      expect(plainView, isNot(contains('\u2022 [ ]')));
    },
  );

  test('GitHub text formatter extracts markdown and HTML images', () {
    final images = githubImageReferences(
      '![diagram](https://user-images.githubusercontent.com/1/demo.png)'
      '<img alt="screenshot" src="https://github.com/org/repo/assets/123">',
    );

    expect(images, hasLength(2));
    expect(images.first.alt, 'diagram');
    expect(images.first.url, endsWith('/demo.png'));
    expect(images.last.alt, 'screenshot');
    expect(images.last.url, 'https://github.com/org/repo/assets/123');
    expect(
      githubDisplayMarkdown('![diagram](https://example.test/a.png)'),
      '![diagram](https://example.test/a.png)',
    );
  });

  test('GitHub text formatter leaves HTML for markdown renderer', () {
    final rendered = githubDisplayMarkdown('''
Updates `actions/upload-artifact` from 7.0.0 to 7.0.1
<details>
<summary>Release notes</summary>
<p>Hidden release body</p>
<ul><li>Hidden item</li></ul>
</details>
<details>
<summary>Commits</summary>
<ul><li>Hidden commit</li></ul>
</details>
''');

    expect(rendered, contains('<details>'));
    expect(rendered, contains('<summary>Release notes</summary>'));
    expect(rendered, contains('Hidden release body'));
    expect(rendered, contains('Hidden item'));
    expect(rendered, contains('Hidden commit'));
  });

  test('GitHub text formatter returns details segments', () {
    final segments = githubDisplayMarkdownSegments('''
Intro paragraph.
<details>
<summary>Release notes</summary>
<p>Hidden release body</p>
</details>
Outro paragraph.
''');

    expect(segments, hasLength(3));
    expect(segments[0], isA<GithubMarkdownTextSegment>());
    expect(segments[1], isA<GithubMarkdownDetailsSegment>());
    expect(segments[2], isA<GithubMarkdownTextSegment>());

    final details = segments[1] as GithubMarkdownDetailsSegment;
    expect(details.summary, 'Release notes');
    expect(details.markdown, contains('<p>Hidden release body</p>'));
    expect(details.initiallyExpanded, isFalse);
  });

  test('GitHub text formatter keeps HTML list links compact', () {
    final markdown = githubDisplayMarkdown('''
<ul>
<li><a href="https://github.com/actions/upload-artifact/commit/043fb46d1a93c77aae656e7c1c64a875d1fc6a0a"><code>043fb46</code></a> Merge pull request <a href="https://redirect.github.com/actions/upload-artifact/issues/797">#797</a> from actions/yacaovsnc/update-dependency</li>
</ul>
''');
    final plain = Style.stripAnsi(markdownToAnsi(markdown));

    expect(
      plain,
      contains(
        '043fb46 Merge pull request #797 from actions/yacaovsnc/update-dependency',
      ),
    );
    expect(plain, isNot(contains('github.com/actions/upload-artifact/commit')));
    expect(plain, isNot(contains('redirect.github.com')));
  });

  test(
    'GitHub markdown body keeps CodeRabbit summary bullets attached to their headings',
    () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.ThemeScope(
          theme: w.Theme.dark(),
          child: GithubMarkdownBody(
            data: '''
<!-- This is an auto-generated comment: release notes by coderabbit.ai -->
## Summary by CodeRabbit

* **New Features**
  * Improved Windows terminal raw-mode input handling by automatically enabling virtual-terminal input when entering raw mode, and restoring the previous console input settings when exiting.
  * Enhances compatibility for advanced console interactions (including mouse input), with changes applied only to the standard input stream.

* **Bug Fixes**
  * Fixed raw-mode lifecycle to preserve and restore Windows console settings correctly, including safe behavior for nested enable/restore scenarios and non-Windows platforms.
<!-- end of auto-generated comment: release notes by coderabbit.ai -->
''',
            maxWidth: 80,
          ),
        ),
        width: 80,
        height: 24,
      );

      final plain = Style.stripAnsi(tester.view);

      expect(plain, contains('• New Features'));
      expect(plain, contains('• Bug Fixes'));
      expect(plain, isNot(contains('•\nNew Features')));
      expect(plain, isNot(contains('•\nBug Fixes')));
    },
  );

  test(
    'GitHub markdown body keeps walkthrough details outside the quote',
    () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 18);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.ThemeScope(
          theme: w.Theme.dark(),
          child: GithubMarkdownBody(
            data: '''
> [!WARNING]
> Review limit reached
> `@elana-voss`, you've reached your PR review limit, so we couldn't start this review.
>
<details open>
<summary>Walkthrough</summary>
This is a long walkthrough line that should wrap cleanly outside the quote border and stay aligned with the disclosure body.
</details>
''',
            maxWidth: 60,
          ),
        ),
        width: 60,
        height: 18,
      );

      final plain = Style.stripAnsi(tester.view);
      final lines = plain.split('\n');

      expect(plain, contains('│ [!WARNING]'));
      expect(plain, contains('│ Review limit reached'));
      expect(plain, contains('▾ Walkthrough'));
      expect(
        plain,
        contains('  This is a long walkthrough line that should wrap'),
      );
      expect(
        lines
            .where((line) => line.contains('Walkthrough'))
            .single
            .startsWith('│'),
        isFalse,
      );
    },
  );

  test(
    'GitHub markdown body keeps quoted details inside the quote border',
    () async {
      final tester = WidgetTester(screenWidth: 72, screenHeight: 20);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.ThemeScope(
          theme: w.Theme.dark(),
          child: GithubMarkdownBody(
            data: '''
> [!WARNING]
> Review limit reached
> `@elana-voss`, you've reached your PR review limit, so we couldn't start this review.
>
> <details open>
> <summary>Walkthrough</summary>
> This is a long walkthrough line that should stay inside the quote border and wrap cleanly with the disclosure body.
> </details>
''',
            maxWidth: 72,
          ),
        ),
        width: 72,
        height: 20,
      );

      final plain = Style.stripAnsi(tester.view);
      final lines = plain.split('\n');

      expect(plain, contains('│ [!WARNING]'));
      expect(plain, contains('│ Review limit reached'));
      expect(plain, contains('│ ▾ Walkthrough'));
      expect(
        lines
            .where((line) => line.contains('Walkthrough'))
            .single
            .startsWith('│'),
        isTrue,
      );
      expect(
        lines
            .where((line) => line.contains('stay inside the quote'))
            .every((line) => line.startsWith('│')),
        isTrue,
      );
      expect(
        lines
            .where((line) => line.contains('border and wrap cleanly'))
            .every((line) => line.startsWith('│')),
        isTrue,
      );
    },
  );

  test('GitHub markdown body renders mermaid fences as diagrams', () async {
    final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.ThemeScope(
        theme: w.Theme.dark(),
        child: GithubMarkdownBody(
          data: '''
```mermaid
sequenceDiagram
  participant A as Alice
  participant B as Bob
  A->>B: Hello
```
''',
          maxWidth: 80,
        ),
      ),
      width: 80,
      height: 24,
    );

    final plain = Style.stripAnsi(tester.view);
    expect(plain, contains('Alice'));
    expect(plain, contains('Bob'));
    expect(plain, isNot(contains('sequenceDiagram')));
  });

  test('markdown probe prints rendered ANSI output', () {
    const markdown = '''
Fixes #63435

`dart build cli` currently produces a separate executable with an appended AOT snapshot for each entrypoint. On Linux, this keeps the snapshot opaque to native symbolizers and duplicates the runtime in bundles with multiple executables.

This implements the BusyBox-style layout discussed in the issue:

- adds a Linux `dartcliruntime` that resolves `../lib/dartaotsnapshot<executable-name>` from `argv[0]`
- falls back to the resolved executable name so invoking a bundle executable through an external symlink still works
- distributes normal and ASan/MSan/TSan variants of `dartcliruntime` in the SDK
- changes Linux `dart build cli` bundles to contain one runtime, symlink additional entrypoints to it, and keep each AOT snapshot under `bundle/lib/`
- leaves the existing bundle behavior unchanged on other platforms

The native-assets tests cover the new layout, execution through symlinks, custom entrypoints, and sanitizer runtimes.

Tested with:

```text
python3 tools/test.py -n unittest-asserts-release-linux-x64 pkg/dartdev/test/native_assets/build_test.dart
```
''';
    final theme = githubDashboardThemes
        .firstWhere((choice) => choice.label == 'github')
        .theme();
    final renderedDark = markdownToAnsi(
      markdown,
      options: githubMarkdownOptions(theme, hasDarkBackground: true),
    );
    final renderedLight = markdownToAnsi(
      markdown,
      options: githubMarkdownOptions(theme, hasDarkBackground: false),
    );

    print('--- plain ---');
    print(Style.stripAnsi(renderedLight));
    print('--- ansi light ---');
    print(renderedLight);
    print('--- ansi dark ---');
    print(renderedDark);

    expect(renderedLight, contains('dart build cli'));
  });

  test('detail pane expands GitHub details blocks', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      GithubCliDashboard(
        client: _FakeGithubClient(_dashboardWithDetailsBody()),
        repository: 'kingwill101/artisanal',
      ),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('3');
    await _pumpUntil(tester, () => tester.find.text('Release notes'));
    final plainCollapsed = Style.stripAnsi(tester.view);

    expect(plainCollapsed, contains('▸ Release notes'));
    expect(plainCollapsed, isNot(contains('Hidden release body')));

    tester.tap(tester.find.textLocation('Release notes'));
    final plainExpanded = Style.stripAnsi(tester.view);

    expect(plainExpanded, contains('▾ Release notes'));
    expect(plainExpanded, contains('Hidden release body'));
  });

  test('comment parsers keep GitHub avatar URLs', () {
    final comment = GithubCommentItem.fromJson(const <String, Object?>{
      'body': 'Thanks for the update.',
      'html_url': 'https://example.test/comment/1',
      'created_at': '2026-05-01T11:00:00Z',
      'user': <String, Object?>{
        'login': 'octo',
        'avatar_url': 'https://avatars.githubusercontent.com/u/1?v=4',
      },
    });

    final reviewComment = GithubPullRequestReviewComment.fromJson(
      const <String, Object?>{
        'id': 1,
        'path': 'lib/main.dart',
        'line': 8,
        'side': 'RIGHT',
        'body': 'Inline note.',
        'html_url': 'https://example.test/review/1',
        'created_at': '2026-05-01T11:10:00Z',
        'user': <String, Object?>{
          'login': 'reviewer',
          'avatar_url': 'https://avatars.githubusercontent.com/u/2?v=4',
        },
      },
    );

    expect(comment.author, 'octo');
    expect(comment.avatarUrl, 'https://avatars.githubusercontent.com/u/1?v=4');
    expect(reviewComment?.author, 'reviewer');
    expect(
      reviewComment?.avatarUrl,
      'https://avatars.githubusercontent.com/u/2?v=4',
    );
  });

  test('c opens comments for the selected issue or pull request', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard(),
      comments: [
        for (var index = 0; index < 12; index++)
          GithubCommentItem(
            author: 'reviewer',
            body: 'Needs a regression test $index.',
            url: 'https://example.test/comment/$index',
            createdAt: null,
          ),
      ],
    );

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('c');
    await _pumpUntil(
      tester,
      () => tester.view.contains('Needs a regression test 0.'),
    );

    expect(tester.view, contains('All comments PR #9'));
    expect(tester.view, contains('reviewer'));
    expect(tester.view, contains('█'));

    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.escape)));
    tester.sendKey('2');
    tester.sendKey('c');
    await _pumpUntil(
      tester,
      () =>
          tester.view.contains('All comments ISSUE #7') &&
          tester.view.contains('Needs a regression test 0.'),
    );

    expect(tester.view, contains('Needs a regression test 0.'));
    expect(tester.view, contains('█'));
  });

  test('v opens review comments with a scrollbar', skip: true, () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard(),
      reviewComments: [
        for (var index = 0; index < 12; index++)
          GithubPullRequestReviewComment(
            id: 'review-$index',
            author: 'reviewer',
            body: 'Review note $index.',
            path: 'lib/example_$index.dart',
            line: index + 1,
            side: 'RIGHT',
            url: 'https://example.test/comment/$index',
            createdAt: null,
          ),
      ],
    );

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('v');
    await _pumpUntil(tester, () => tester.view.contains('Review note 0.'));

    expect(tester.view, contains('Review comments PR #9'));
    expect(tester.view, contains('reviewer'));
    expect(tester.view, contains('█'));
  });

  test('single pull request view loads only the PR and comments', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard('dart-lang/sdk'),
      comments: const [
        GithubCommentItem(
          author: 'reviewer',
          body: 'Focused profile comment.',
          url: 'https://example.test/comment/1',
          createdAt: null,
        ),
      ],
    );

    await tester.pumpWidget(
      GithubPullRequestView(
        client: client,
        target: const GithubPullRequestTarget(
          repository: 'dart-lang/sdk',
          number: 9,
        ),
      ),
    );

    await _pumpUntil(
      tester,
      () => tester.view.contains('Focused profile comment.'),
    );

    expect(tester.view, contains('All comments PR #9'));
    expect(tester.view, contains('Add gh tui'));
    expect(tester.view, isNot(contains('PULL REQUESTS')));
    expect(client.dashboardLoads, isZero);
    expect(client.pullRequestLoads, 1);
    expect(client.commentLoads, 1);
  });

  test('single pull request view adds review comments from the diff', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard('dart-lang/sdk'),
      diff: _sampleDiff,
    );

    await tester.pumpWidget(
      GithubPullRequestView(
        client: client,
        target: const GithubPullRequestTarget(
          repository: 'dart-lang/sdk',
          number: 9,
        ),
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('Add gh tui'));
    tester.sendKey('d');
    await _pumpUntil(tester, () => tester.view.contains('lib/main.dart'));

    tester.sendKey('a');
    await _pumpUntil(tester, () => tester.view.contains('Add diff comment'));
    tester.typeText('Please tighten this line.');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(tester, () => client.addedReviewComments.isNotEmpty);

    final comment = client.addedReviewComments.single;
    expect(comment.number, 9);
    expect(comment.commitId, 'head-9');
    expect(comment.path, 'lib/main.dart');
    expect(comment.side, 'RIGHT');
    expect(comment.body, 'Please tighten this line.');
  });

  test(
    'inline review comments render between diff lines',
    skip: true,
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      addTearDown(() => tester.dispose());
      final client = _FakeGithubClient(
        _sampleDashboard('dart-lang/sdk'),
        diff: _sampleDiff,
        reviewComments: const [
          GithubPullRequestReviewComment(
            id: 'r1',
            path: 'lib/main.dart',
            line: 2,
            side: 'RIGHT',
            author: 'reviewer',
            body: 'INLINE_REVIEW_BODY_SHOULD_APPEAR',
            url: 'https://example.test/r1',
            createdAt: null,
          ),
        ],
      );

      await tester.pumpWidget(
        GithubPullRequestView(
          client: client,
          target: const GithubPullRequestTarget(
            repository: 'dart-lang/sdk',
            number: 9,
          ),
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('Add gh tui'));
      tester.sendKey('d');
      await _pumpUntil(
        tester,
        () => tester.view.contains('INLINE_REVIEW_BODY_SHOULD_APPEAR'),
        timeout: const Duration(seconds: 5),
      );
    },
  );

  test('mapReviewCommentsToRenderLines tolerates side/line mismatches', () {
    final anchors = [
      const w.DiffCommentAnchor(
        path: 'lib/main.dart',
        line: 2,
        side: w.DiffCommentSide.right,
        kind: w.DiffCommentKind.addition,
        renderLine: 5,
        content: "+  print('new');",
      ),
      const w.DiffCommentAnchor(
        path: 'lib/main.dart',
        line: 4,
        side: w.DiffCommentSide.right,
        kind: w.DiffCommentKind.context,
        renderLine: 7,
        content: '  }',
      ),
    ];

    // Exact match.
    final exact = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'a',
        path: 'lib/main.dart',
        line: 2,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(exact[5], hasLength(1));

    // Wrong side but correct line still maps (fallback).
    final wrongSide = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'b',
        path: 'lib/main.dart',
        line: 2,
        side: 'LEFT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(wrongSide[5], hasLength(1));

    // Off-by-one line maps to nearest anchor.
    final offByOne = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'c',
        path: 'lib/main.dart',
        line: 3,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(offByOne[5], hasLength(1));

    // Unrelated path maps to nothing.
    final noMatch = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'd',
        path: 'lib/other.dart',
        line: 2,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(noMatch, isEmpty);
  });

  test('mapReviewCommentsToRenderLines normalizes a/b path prefixes', () {
    final anchors = const [
      w.DiffCommentAnchor(
        path: 'lib/main.dart',
        line: 2,
        side: w.DiffCommentSide.right,
        kind: w.DiffCommentKind.addition,
        renderLine: 5,
        content: "+  print('new');",
      ),
    ];

    // GitHub reports the diff path with an `a/` / `b/` prefix; previously this
    // skipped every anchor for the file and fell back to `nearest`, dropping
    // the comment onto the wrong line (e.g. under a hunk header).
    final mapped = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'a',
        path: 'b/lib/main.dart',
        line: 2,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(mapped[5], hasLength(1));
  });

  test(
    'inline review comments render between diff lines',
    skip: true,
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      addTearDown(() => tester.dispose());
      final client = _FakeGithubClient(
        _sampleDashboard('dart-lang/sdk'),
        diff: _sampleDiff,
        reviewComments: const [
          GithubPullRequestReviewComment(
            id: 'r1',
            path: 'lib/main.dart',
            line: 2,
            side: 'RIGHT',
            author: 'reviewer',
            body: 'INLINE_REVIEW_BODY_SHOULD_APPEAR',
            url: 'https://example.test/r1',
            createdAt: null,
          ),
        ],
      );

      await tester.pumpWidget(
        GithubPullRequestView(
          client: client,
          target: const GithubPullRequestTarget(
            repository: 'dart-lang/sdk',
            number: 9,
          ),
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('Add gh tui'));
      tester.sendKey('d');
      await _pumpUntil(
        tester,
        () => tester.view.contains('INLINE_REVIEW_BODY_SHOULD_APPEAR'),
        timeout: const Duration(seconds: 5),
      );
    },
  );

  test('mapReviewCommentsToRenderLines tolerates side/line mismatches', () {
    final anchors = [
      const w.DiffCommentAnchor(
        path: 'lib/main.dart',
        line: 2,
        side: w.DiffCommentSide.right,
        kind: w.DiffCommentKind.addition,
        renderLine: 5,
        content: "+  print('new');",
      ),
      const w.DiffCommentAnchor(
        path: 'lib/main.dart',
        line: 4,
        side: w.DiffCommentSide.right,
        kind: w.DiffCommentKind.context,
        renderLine: 7,
        content: '  }',
      ),
    ];

    // Exact match.
    final exact = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'a',
        path: 'lib/main.dart',
        line: 2,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(exact[5], hasLength(1));

    // Wrong side but correct line still maps (fallback).
    final wrongSide = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'b',
        path: 'lib/main.dart',
        line: 2,
        side: 'LEFT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(wrongSide[5], hasLength(1));

    // Off-by-one line maps to nearest anchor.
    final offByOne = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'c',
        path: 'lib/main.dart',
        line: 3,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(offByOne[5], hasLength(1));

    // Unrelated path maps to nothing.
    final noMatch = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'd',
        path: 'lib/other.dart',
        line: 2,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(noMatch, isEmpty);
  });

  test('mapReviewCommentsToRenderLines normalizes a/b path prefixes', () {
    final anchors = const [
      w.DiffCommentAnchor(
        path: 'lib/main.dart',
        line: 2,
        side: w.DiffCommentSide.right,
        kind: w.DiffCommentKind.addition,
        renderLine: 5,
        content: "+  print('new');",
      ),
    ];

    // GitHub reports the diff path with an `a/` / `b/` prefix; previously this
    // skipped every anchor for the file and fell back to `nearest`, dropping
    // the comment onto the wrong line (e.g. under a hunk header).
    final mapped = mapReviewCommentsToRenderLines([
      const GithubPullRequestReviewComment(
        id: 'a',
        path: 'b/lib/main.dart',
        line: 2,
        side: 'RIGHT',
        author: 'x',
        body: 'b',
        url: 'u',
        createdAt: null,
      ),
    ], anchors);
    expect(mapped[5], hasLength(1));
  });

  test(
    'single pull request view adds range review comments from the diff',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
      addTearDown(() => tester.dispose());
      final client = _FakeGithubClient(
        _sampleDashboard('dart-lang/sdk'),
        diff: _sampleDiff,
      );

      await tester.pumpWidget(
        GithubPullRequestView(
          client: client,
          target: const GithubPullRequestTarget(
            repository: 'dart-lang/sdk',
            number: 9,
          ),
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('Add gh tui'));
      tester.sendKey('d');
      await _pumpUntil(tester, () => tester.view.contains('lib/main.dart'));

      tester.sendKey('v');
      tester.sendKey('j');
      tester.sendKey('a');
      await _pumpUntil(tester, () => tester.view.contains('Add diff comment'));
      tester.typeText('This range needs another look.');
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
      await _pumpUntil(tester, () => client.addedReviewComments.isNotEmpty);

      final comment = client.addedReviewComments.single;
      expect(comment.line, 2);
      expect(comment.startLine, 1);
      expect(comment.side, 'RIGHT');
      expect(comment.startSide, 'RIGHT');
    },
  );

  test('single pull request diff page keys scroll the full viewport', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 24);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard('dart-lang/sdk'),
      diff: _longSampleDiff,
    );

    await tester.pumpWidget(
      GithubPullRequestView(
        client: client,
        target: const GithubPullRequestTarget(
          repository: 'dart-lang/sdk',
          number: 9,
        ),
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('Add gh tui'));
    tester.sendKey('d');
    await _pumpUntil(tester, () => tester.view.contains('Files changed PR #9'));
    expect(tester.view, contains('long change line 001'));
    expect(tester.view, isNot(contains('long change line 040')));

    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.pageDown)));
    await _pumpUntil(tester, () => _containsLongDiffLine(tester.view, 15, 45));
    expect(tester.view, isNot(contains('long change line 001')));

    tester.sendKey('a');
    await _pumpUntil(tester, () => tester.view.contains('Add diff comment'));
    tester.typeText('Comment after paging.');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(tester, () => client.addedReviewComments.isNotEmpty);
    expect(client.addedReviewComments.single.line, greaterThanOrEqualTo(8));
  });

  test(
    'single pull request view shares dashboard shortcuts and dialogs',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 38);
      addTearDown(() => tester.dispose());
      final client = _FakeGithubClient(_sampleDashboard('dart-lang/sdk'));

      await tester.pumpWidget(
        GithubPullRequestView(
          client: client,
          target: const GithubPullRequestTarget(
            repository: 'dart-lang/sdk',
            number: 9,
          ),
        ),
      );

      await _pumpUntil(
        tester,
        () => tester.view.contains('All comments PR #9'),
      );

      tester.sendKey('a');
      await _pumpUntil(tester, () => tester.view.contains('Add comment'));
      tester.typeText('Single PR comment.');
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
      await _pumpUntil(tester, () => client.addedComments.isNotEmpty);
      expect(client.addedComments.single.body, 'Single PR comment.');

      await _pumpUntil(
        tester,
        () => tester.view.contains('All comments PR #9'),
      );
      tester.sendKey('m');
      await _pumpUntil(tester, () => tester.view.contains('Merge  #9'));
      await _pumpUntil(tester, () => tester.view.contains('Squash and merge'));
      expect(tester.view, contains('Squash and merge'));
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.escape)));

      tester.sendKey('l');
      await _pumpUntil(tester, () => tester.view.contains('Labels  PR #9'));
      await _pumpUntil(tester, () => tester.view.contains('enhancement'));
      expect(tester.view, contains('enhancement'));
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
      await _pumpUntil(tester, () => client.addedLabels.isNotEmpty);
      expect(client.addedLabels.single.labels, ['bug']);
    },
  );

  test('comment avatars request network images by default', () async {
    expect(githubCliNetworkImagesEnabled, isTrue);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final avatarBytes = _encodeAvatarImage();
    var avatarRequests = 0;
    server.listen((request) async {
      avatarRequests++;
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(avatarBytes);
      await request.response.close();
    });

    final avatarUrl =
        'http://${server.address.address}:${server.port}/avatar.png';
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard(),
      comments: [
        GithubCommentItem(
          author: 'reviewer',
          body: 'Avatar-backed comment.',
          url: 'https://example.test/comment/1',
          createdAt: null,
          avatarUrl: avatarUrl,
        ),
      ],
    );

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
      imageAutoMode: w.ImageAutoMode.sessionCapabilities,
    );

    tester.sendMsg(const tui.TerminalVersionMsg('xterm-kitty 0.40.0'));
    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('c');
    await _pumpUntil(
      tester,
      () => tester.view.contains('Avatar-backed comment.'),
    );
    await _pumpUntil(tester, () => avatarRequests > 0);

    expect(avatarRequests, greaterThan(0));
  });

  test('d opens a pull request diff inside the TUI', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(_sampleDashboard(), diff: _sampleDiff);

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('3');
    tester.sendKey('d');
    await _pumpUntil(tester, () => tester.view.contains('lib/main.dart'));

    expect(tester.view, contains('Files changed PR #9'));
    expect(tester.view, contains('Conversation 2'));
    expect(tester.view, contains('Files changed'));
    expect(tester.view, contains('lib/main.dart'));
    expect(tester.view, contains('new terminal dashboard'));

    tester.sendKey('c');
    await _pumpUntil(tester, () => tester.view.contains('All comments PR #9'));
    expect(tester.view, contains('Conversation 2'));
  });

  test('files changed view renders one selected file at a time', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard(),
      diffFiles: const <GithubPullRequestDiffFile>[
        GithubPullRequestDiffFile(
          filename: 'lib/one.dart',
          status: 'modified',
          additions: 1,
          changes: 1,
          patch: "@@ -1 +1,2 @@\n void one() {}\n+print('one change');",
        ),
        GithubPullRequestDiffFile(
          filename: 'lib/two.dart',
          status: 'modified',
          additions: 1,
          changes: 1,
          patch: "@@ -1 +1,2 @@\n void two() {}\n+print('two change');",
        ),
      ],
    );

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('3');
    tester.sendKey('d');
    await _pumpUntil(tester, () => tester.view.contains('lib/one.dart'));

    expect(tester.view, contains('Files changed PR #9'));
    expect(tester.view, contains('Files'));
    expect(tester.view, contains('print(\'one change\')'));
    expect(tester.view, isNot(contains('print(\'two change\')')));

    tester.sendKey(']');
    await _pumpUntil(
      tester,
      () => tester.view.contains('print(\'two change\')'),
    );
    expect(tester.view, contains('lib/two.dart'));
    expect(tester.view, isNot(contains('print(\'one change\')')));
  });

  test('files changed sidebar keeps bracket-selected file visible', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 24);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard(),
      diffFiles: [
        for (var i = 1; i <= 30; i++)
          GithubPullRequestDiffFile(
            filename: 'lib/file_${i.toString().padLeft(2, '0')}.dart',
            status: i == 30 ? 'selected-end' : 'modified',
            additions: 1,
            changes: 1,
            patch:
                "@@ -1 +1,2 @@\n void file$i() {}\n+print('file $i change');",
          ),
      ],
    );

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('3');
    tester.sendKey('d');
    await _pumpUntil(tester, () => tester.view.contains('lib/file_01.dart'));

    for (var i = 0; i < 29; i++) {
      tester.sendKey(']');
    }
    await _pumpUntil(
      tester,
      () => Style.stripAnsi(tester.view).contains('selected-end'),
    );

    final plainView = Style.stripAnsi(tester.view);
    expect(plainView, contains('30/30'));
    expect(plainView, contains('selected-end'));
  });

  test(
    'files changed sidebar wheel scrolls without stealing arrow keys',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 24);
      addTearDown(() => tester.dispose());
      final client = _FakeGithubClient(
        _sampleDashboard(),
        diffFiles: [
          for (var i = 1; i <= 30; i++)
            GithubPullRequestDiffFile(
              filename: 'lib/file_${i.toString().padLeft(2, '0')}.dart',
              status: 'modified',
              additions: 1,
              changes: 1,
              patch:
                  "@@ -1 +1,2 @@\n void file$i() {}\n+print('file $i change');",
            ),
        ],
      );

      await tester.pumpWidget(
        GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
      );

      await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
      tester.sendKey('3');
      tester.sendKey('d');
      await _pumpUntil(tester, () => tester.view.contains('lib/file_01.dart'));

      for (var i = 0; i < 6; i++) {
        tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.down)));
      }
      tester.pump();
      var plainView = Style.stripAnsi(tester.view);
      expect(plainView, contains('lib/file_01.dart'));
      expect(plainView, isNot(contains('lib/file_15.dart')));

      final wheelTarget = tester.locateText('lib/file_02.dart');
      expect(wheelTarget, isNotNull);
      for (var i = 0; i < 3; i++) {
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: wheelTarget!.x,
            y: wheelTarget.y,
          ),
        );
      }
      await _pumpUntil(
        tester,
        () => Style.stripAnsi(tester.view).contains('lib/file_14.dart'),
      );
    },
  );

  test('a adds a review comment when the diff tab is active', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(_sampleDashboard(), diff: _sampleDiff);

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('3');
    tester.sendKey('d');
    await _pumpUntil(tester, () => tester.view.contains('lib/main.dart'));

    tester.sendKey('a');
    await _pumpUntil(tester, () => tester.view.contains('Add diff comment'));
    tester.typeText('Inline note from the terminal.');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(tester, () => client.addedReviewComments.isNotEmpty);

    final comment = client.addedReviewComments.single;
    expect(comment.commitId, 'head-9');
    expect(comment.path, 'lib/main.dart');
    expect(comment.side, 'RIGHT');
    expect(comment.body, 'Inline note from the terminal.');
  });

  test(
    'focused view gives the selected PR full-width scrollable diff',
    skip: true,
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 24);
      addTearDown(() => tester.dispose());
      final client = _FakeGithubClient(
        _sampleDashboard(),
        diff: _longSampleDiff,
      );

      await tester.pumpWidget(
        GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
      );

      await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
      tester.sendKey('3');
      tester.sendKey('f');

      expect(tester.view, isNot(contains('PULL REQUESTS')));
      expect(tester.view, contains('Pull request body from gh.'));
      expect(tester.view, contains('f/esc'));
      expect(tester.view, contains('scroll'));

      tester.sendKey('d');
      await _pumpUntil(
        tester,
        () => tester.view.contains('Files changed PR #9'),
      );
      expect(tester.view, contains('unified'));
      expect(tester.view, contains('long change line 001'));
      expect(tester.view, isNot(contains('long change line 040')));

      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.left)));
      await _pumpUntil(
        tester,
        () => tester.view.contains('Review comments PR #9'),
      );
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.left)));
      await _pumpUntil(tester, () => tester.view.contains('Commits PR #9'));
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.left)));
      await _pumpUntil(
        tester,
        () => tester.view.contains('All comments PR #9'),
      );
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.right)));
      await _pumpUntil(tester, () => tester.view.contains('Commits PR #9'));
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.right)));
      await _pumpUntil(
        tester,
        () => tester.view.contains('Review comments PR #9'),
      );
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.right)));
      await _pumpUntil(
        tester,
        () => tester.view.contains('Files changed PR #9'),
      );

      tester.sendKey('s');
      expect(tester.view, contains('side-by-side'));
      tester.sendKey('s');
      expect(tester.view, contains('pretty'));
      tester.sendKey('s');
      expect(tester.view, contains('unified'));

      for (var i = 0; i < 2; i++) {
        tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.pageDown)));
      }
      await _pumpUntil(
        tester,
        () => _containsLongDiffLine(tester.view, 15, 45),
      );
      expect(tester.view, isNot(contains('long change line 001')));

      tester.sendKey('v');
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.escape)));
      expect(tester.view, contains('PULL REQUESTS'));
    },
  );

  test(
    'v, m, and b load PR review comments, merge info, and labels',
    skip: true,
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 38);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        GithubCliDashboard(
          client: _FakeGithubClient(_sampleDashboard()),
          repository: 'kingwill101/artisanal',
        ),
      );

      await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));

      tester.sendKey('v');
      await _pumpUntil(
        tester,
        () => tester.view.contains('Inline review note.'),
      );
      expect(tester.view, contains('Review comments PR #9'));
      expect(tester.view, contains('lib/main.dart:2'));

      tester.sendKey('m');
      await _pumpUntil(tester, () => tester.view.contains('Squash and merge'));
      expect(tester.view, contains('Merge  #9'));
      expect(tester.view, contains('manual'));

      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.escape)));
      tester.sendKey('b');
      await _pumpUntil(tester, () => tester.view.contains('enhancement'));
      expect(tester.view, contains('Labels  PR #9'));
      expect(tester.view, contains('bug'));
      expect(tester.view, contains('enhancement'));
    },
  );

  test('initial load is lazy and n pages through large PR lists', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _LazyPagingGithubClient();

    await tester.pumpWidget(
      GithubCliDashboard(
        client: client,
        repository: 'kingwill101/artisanal',
        limit: 1,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('#1 Paged PR 1'));
    expect(client.dashboardCalls, 1);
    expect(client.pullRequestPageCalls, 1);
    expect(client.issuePageCalls, 0);
    expect(client.workflowRunPageCalls, 0);
    expect(tester.view, contains('1/2 loaded'));
    expect(tester.view, contains('n more'));

    tester.sendKey('n');
    await _pumpUntil(tester, () => tester.view.contains('#2 Paged PR 2'));
    expect(client.pullRequestPageCalls, 2);
    expect(client.lastPullRequestAfter, 'cursor-1');
    expect(tester.view, contains('2/2 loaded'));
  });

  test('enter opens workflow run jobs and steps inside the TUI', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(
      _sampleDashboard(),
      runDetail: _sampleRunDetail(),
    );

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('4');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(tester, () => tester.view.contains('analyze'));

    expect(tester.view, contains('Run #12'));
    expect(tester.view, contains('analyze'));
    expect(tester.view, contains('Install dependencies'));
    expect(tester.view, contains('jobs 1/1 passing'));
  });

  test('a adds comments through the gh client', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(_sampleDashboard());

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));

    tester.sendKey('a');
    expect(tester.view, contains('Add comment'));
    tester.typeText('Adding this from the terminal.');
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(tester, () => client.addedComments.isNotEmpty);
    expect(client.addedComments.single.body, 'Adding this from the terminal.');
  });

  test('l toggles labels through the gh client', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(() => tester.dispose());
    final client = _FakeGithubClient(_sampleDashboard());

    await tester.pumpWidget(
      GithubCliDashboard(client: client, repository: 'kingwill101/artisanal'),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('l');
    await _pumpUntil(tester, () => tester.view.contains('Labels  PR #9'));
    await _pumpUntil(tester, () => tester.view.contains('bug'));
    tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    await _pumpUntil(tester, () => client.addedLabels.isNotEmpty);
    expect(client.addedLabels.single.labels, ['bug']);
  });

  test('work queue scrolls as selection moves through many items', () async {
    final tester = WidgetTester(screenWidth: 96, screenHeight: 18);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      GithubCliDashboard(
        client: _FakeGithubClient(_dashboardWithPullRequests(24)),
        repository: 'kingwill101/artisanal',
      ),
    );

    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    tester.sendKey('3');
    for (var i = 0; i < 20; i++) {
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.down)));
    }

    expect(tester.view, contains('#21 PR item 21'));
    await _pumpUntil(tester, () => tester.view.contains('PR body 21.'));
    expect(tester.view, contains('PR body 21.'));
  });

  test('dashboard renders gh errors and can retry', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 24);
    addTearDown(() => tester.dispose());
    final client = _FlakyGithubClient();

    await tester.pumpWidget(GithubCliDashboard(client: client));

    await _pumpUntil(tester, () => tester.view.contains('gh error'));
    expect(tester.view, contains('gh auth failed'));

    tester.sendKey('r');
    await _pumpUntil(tester, () => tester.find.text('kingwill101/artisanal'));
    expect(client.calls, 2);
  });
}

GithubDashboardData _sampleDashboard([
  String repository = 'kingwill101/artisanal',
]) {
  return GithubDashboardData(
    loadedAt: DateTime.utc(2026, 5, 1, 12),
    repository: _sampleRepositorySummary(repository),
    repositories: [
      _sampleRepositorySummary(repository),
      _sampleRepositorySummary('kingwill101/lualike', stars: 18),
    ],
    issues: [
      GithubIssueItem(
        number: 7,
        title: 'Wire dashboard',
        body: 'Issue body from gh.',
        url: 'https://example.test/issues/7',
        repository: repository,
        author: 'octo',
        labels: const ['feature'],
        assignees: const ['dev'],
        commentCount: 1,
        updatedAt: DateTime.utc(2026, 5, 1, 11),
      ),
    ],
    pullRequests: [
      GithubPullRequestItem(
        number: 9,
        title: 'Add gh tui',
        body: 'Pull request body from gh.',
        url: 'https://example.test/pull/9',
        repository: repository,
        author: 'octo',
        headRefOid: 'head-9',
        labels: const [],
        commentCount: 2,
        commitCount: 2,
        updatedAt: DateTime.utc(2026, 5, 1, 11, 30),
        reviewDecision: 'APPROVED',
        isDraft: false,
        checks: const GithubCheckSummary(
          total: 1,
          passed: 1,
          failed: 0,
          pending: 0,
          items: [
            GithubCheckItem(
              name: 'test',
              status: 'completed',
              conclusion: 'success',
            ),
          ],
        ),
      ),
    ],
    workflows: const [
      GithubWorkflowItem(
        id: 101,
        name: 'CI',
        path: '.github/workflows/ci.yml',
        state: 'active',
      ),
    ],
    workflowRuns: [
      GithubWorkflowRunItem(
        databaseId: 9001,
        number: 12,
        attempt: 1,
        workflowName: 'CI',
        displayTitle: 'Validate widgets',
        status: 'completed',
        conclusion: 'success',
        event: 'push',
        headBranch: 'main',
        url: 'https://example.test/actions/runs/9001',
        createdAt: DateTime.utc(2026, 5, 1, 11, 40),
        updatedAt: DateTime.utc(2026, 5, 1, 11, 45),
      ),
    ],
  );
}

GithubRepositorySummary _sampleRepositorySummary(
  String repository, {
  int stars = 2,
}) {
  return GithubRepositorySummary(
    nameWithOwner: repository,
    description: 'Terminal toolkit',
    url: 'https://github.com/$repository',
    defaultBranch: 'main',
    stars: stars,
    forks: 0,
    isPrivate: false,
    viewerPermission: 'ADMIN',
    primaryLanguage: 'Dart',
    latestRelease: 'v0.3.0',
    updatedAt: DateTime.utc(2026, 5, 1, 10),
  );
}

GithubOverviewBucket _sampleOverviewBucket(GithubDashboardData dashboard) {
  return GithubOverviewBucket(
    issues: dashboard.issues,
    pullRequests: dashboard.pullRequests,
  );
}

GithubDashboardData _dashboardWithHtmlBody() {
  return GithubDashboardData(
    loadedAt: DateTime.utc(2026, 5, 1, 12),
    repository: GithubRepositorySummary(
      nameWithOwner: 'kingwill101/artisanal',
      description: 'Terminal toolkit',
      url: 'https://github.com/kingwill101/artisanal',
      defaultBranch: 'main',
      stars: 2,
      forks: 0,
      isPrivate: false,
      viewerPermission: 'ADMIN',
      primaryLanguage: 'Dart',
      latestRelease: 'v0.3.0',
    ),
    issues: const [],
    pullRequests: [
      GithubPullRequestItem(
        number: 9,
        title: 'HTML body',
        body:
            '<p>Upcoming change: use <code>true</code>.</p><ul><li>First item</li></ul>',
        url: 'https://example.test/pull/9',
        author: 'octo',
        labels: const [],
        commentCount: 0,
        updatedAt: DateTime.utc(2026, 5, 1, 11, 30),
        reviewDecision: 'PENDING',
        isDraft: false,
        checks: GithubCheckSummary.empty,
      ),
    ],
  );
}

GithubDashboardData _dashboardWithTaskListBody() {
  return GithubDashboardData(
    loadedAt: DateTime.utc(2026, 5, 1, 12),
    repository: GithubRepositorySummary(
      nameWithOwner: 'kingwill101/artisanal',
      description: 'Terminal toolkit',
      url: 'https://github.com/kingwill101/artisanal',
      defaultBranch: 'main',
      stars: 2,
      forks: 0,
      isPrivate: false,
      viewerPermission: 'ADMIN',
      primaryLanguage: 'Dart',
      latestRelease: 'v0.3.0',
    ),
    issues: const [],
    pullRequests: [
      GithubPullRequestItem(
        number: 9,
        title: 'Cap websocket frame payloads',
        body: '''
## Test plan

- [x] PoC `ws_uncompressed_oom_server.py` reproduces OOM kill on unpatched `dart:stable`.
- [ ] After the fix: parser throws `WebSocketException("Frame payload length 209715200 exceeds maximum 16777216. ...")` immediately after parsing the 64-bit length header.
''',
        url: 'https://example.test/pull/9',
        author: 'octo',
        labels: const [],
        commentCount: 0,
        updatedAt: DateTime.utc(2026, 5, 1, 11, 30),
        reviewDecision: 'PENDING',
        isDraft: false,
        checks: GithubCheckSummary.empty,
      ),
    ],
  );
}

GithubDashboardData _dashboardWithDetailsBody() {
  return GithubDashboardData(
    loadedAt: DateTime.utc(2026, 5, 1, 12),
    repository: GithubRepositorySummary(
      nameWithOwner: 'kingwill101/artisanal',
      description: 'Terminal toolkit',
      url: 'https://github.com/kingwill101/artisanal',
      defaultBranch: 'main',
      stars: 2,
      forks: 0,
      isPrivate: false,
      viewerPermission: 'ADMIN',
      primaryLanguage: 'Dart',
      latestRelease: 'v0.3.0',
    ),
    issues: const [],
    pullRequests: [
      GithubPullRequestItem(
        number: 9,
        title: 'Dependabot update',
        body: '''
Bumps the github-actions group with 2 updates.

<details>
<summary>Release notes</summary>
<p>Hidden release body</p>
</details>
''',
        url: 'https://example.test/pull/9',
        author: 'dependabot',
        labels: const [],
        commentCount: 0,
        updatedAt: DateTime.utc(2026, 5, 1, 11, 30),
        reviewDecision: 'PENDING',
        isDraft: false,
        checks: GithubCheckSummary.empty,
      ),
    ],
  );
}

GithubDashboardData _dashboardWithPullRequests(int count) {
  return GithubDashboardData(
    loadedAt: DateTime.utc(2026, 5, 1, 12),
    repository: GithubRepositorySummary(
      nameWithOwner: 'kingwill101/artisanal',
      description: 'Terminal toolkit',
      url: 'https://github.com/kingwill101/artisanal',
      defaultBranch: 'main',
      stars: 2,
      forks: 0,
      isPrivate: false,
      viewerPermission: 'ADMIN',
      primaryLanguage: 'Dart',
      latestRelease: 'v0.3.0',
    ),
    issues: const [],
    pullRequests: [
      for (var i = 1; i <= count; i++)
        GithubPullRequestItem(
          number: i,
          title: 'PR item $i',
          body: 'PR body $i.',
          url: 'https://example.test/pull/$i',
          author: 'octo$i',
          labels: const [],
          commentCount: 0,
          updatedAt: DateTime.utc(
            2026,
            5,
            1,
            12,
          ).subtract(Duration(minutes: i)),
          reviewDecision: 'PENDING',
          isDraft: false,
          checks: GithubCheckSummary.empty,
        ),
    ],
  );
}

GithubPullRequestItem _pagedPullRequest(int number) {
  return GithubPullRequestItem(
    number: number,
    title: 'Paged PR $number',
    body: 'Paged PR body $number.',
    url: 'https://example.test/pull/$number',
    author: 'octo$number',
    labels: const <String>[],
    commentCount: 0,
    updatedAt: DateTime.utc(2026, 5, 1, 12).subtract(Duration(minutes: number)),
    reviewDecision: 'PENDING',
    isDraft: false,
    checks: GithubCheckSummary.empty,
  );
}

List<GithubPullRequestCommit> _sampleCommits() {
  return [
    GithubPullRequestCommit(
      sha: 'abc1234567890',
      messageHeadline: 'Add gh tui',
      messageBody: '',
      authorName: 'Octo Dev',
      authorLogin: 'octo',
      authorAvatarUrl: '',
      committedAt: DateTime.utc(2026, 5, 1, 10),
      url: 'https://example.test/commit/abc1234',
      verified: true,
    ),
    GithubPullRequestCommit(
      sha: 'def9876543210',
      messageHeadline: 'Wire widgets',
      messageBody: '',
      authorName: 'Octo Dev',
      authorLogin: 'octo',
      authorAvatarUrl: '',
      committedAt: DateTime.utc(2026, 5, 1, 11),
      url: 'https://example.test/commit/def9876',
      verified: false,
    ),
  ];
}

const _sampleDiff = '''
diff --git a/lib/main.dart b/lib/main.dart
index 1111111..2222222 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,3 +1,4 @@
 void main() {
+  print('new terminal dashboard');
}
''';

final _longSampleDiff =
    '''
diff --git a/lib/main.dart b/lib/main.dart
index 1111111..2222222 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,3 +1,83 @@
 void main() {
${List<String>.generate(80, (index) {
      final line = (index + 1).toString().padLeft(3, '0');
      return "+  print('long change line $line');";
    }).join('\n')}
 }
''';

bool _containsLongDiffLine(String view, int start, int end) {
  for (var line = start; line <= end; line++) {
    final padded = line.toString().padLeft(3, '0');
    if (view.contains('long change line $padded')) return true;
  }
  return false;
}

GithubWorkflowRunDetail _sampleRunDetail() {
  return GithubWorkflowRunDetail(
    run: GithubWorkflowRunItem(
      databaseId: 9001,
      number: 12,
      attempt: 1,
      workflowName: 'CI',
      displayTitle: 'Validate widgets',
      status: 'completed',
      conclusion: 'success',
      event: 'push',
      headBranch: 'main',
      url: 'https://example.test/actions/runs/9001',
      createdAt: DateTime.utc(2026, 5, 1, 11, 40),
      updatedAt: DateTime.utc(2026, 5, 1, 11, 45),
    ),
    jobs: [
      GithubWorkflowJobItem(
        name: 'analyze',
        status: 'completed',
        conclusion: 'success',
        startedAt: DateTime.utc(2026, 5, 1, 11, 40),
        completedAt: DateTime.utc(2026, 5, 1, 11, 42),
        steps: const [
          GithubWorkflowStepItem(
            number: 1,
            name: 'Install dependencies',
            status: 'completed',
            conclusion: 'success',
          ),
          GithubWorkflowStepItem(
            number: 2,
            name: 'Run analyzer',
            status: 'completed',
            conclusion: 'success',
          ),
        ],
      ),
    ],
    headSha: 'abc123456789def',
    startedAt: DateTime.utc(2026, 5, 1, 11, 40),
  );
}

GithubPullRequestMergeInfo _sampleMergeInfo(int number) {
  return GithubPullRequestMergeInfo(
    number: number,
    title: 'Add gh tui',
    state: 'OPEN',
    isDraft: false,
    mergeable: 'MERGEABLE',
    reviewDecision: 'APPROVED',
    autoMergeEnabled: false,
    viewerCanMergeAsAdmin: true,
    mergeCommitAllowed: true,
    squashMergeAllowed: true,
    rebaseMergeAllowed: false,
    checks: const GithubCheckSummary(
      total: 1,
      passed: 1,
      failed: 0,
      pending: 0,
      items: [
        GithubCheckItem(
          name: 'test',
          status: 'completed',
          conclusion: 'success',
        ),
      ],
    ),
  );
}

final class _RecordedComment {
  const _RecordedComment({
    required this.kind,
    required this.number,
    required this.body,
  });

  final GithubItemKind kind;
  final int number;
  final String body;
}

final class _RecordedReviewComment {
  const _RecordedReviewComment({
    required this.number,
    required this.commitId,
    required this.path,
    required this.line,
    required this.side,
    required this.body,
    this.startLine,
    this.startSide,
  });

  final int number;
  final String commitId;
  final String path;
  final int line;
  final String side;
  final String body;
  final int? startLine;
  final String? startSide;
}

final class _RecordedLabels {
  const _RecordedLabels({
    required this.kind,
    required this.number,
    required this.labels,
  });

  final GithubItemKind kind;
  final int number;
  final List<String> labels;
}

final class _RecordingGithubClient implements GithubDashboardClient {
  final repositories = <String?>[];
  final owners = <String?>[];
  final overviewFilters = <GithubOverviewFilter>[];

  @override
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  }) async {
    repositories.add(repository);
    owners.add(owner);
    if (owner != null) {
      final ownerName = owner == '@me' ? 'kingwill101' : owner;
      final dashboard = _sampleDashboard('$ownerName/artisanal');
      return GithubDashboardData(
        loadedAt: dashboard.loadedAt,
        repository: GithubRepositorySummary(
          nameWithOwner: ownerName,
          description: 'GitHub personal overview',
          url: 'https://github.com/$ownerName',
          defaultBranch: '',
          stars: 0,
          forks: 0,
          isPrivate: false,
          viewerPermission: 'UNKNOWN',
          primaryLanguage: '',
          latestRelease: '',
        ),
        scope: GithubDashboardScope.user(owner),
        repositories: dashboard.repositories,
        issues: const <GithubIssueItem>[],
        pullRequests: const <GithubPullRequestItem>[],
        workflowRuns: const <GithubWorkflowRunItem>[],
      );
    }
    return _sampleDashboard(repository ?? 'current/repo');
  }

  @override
  Future<GithubOverviewBucket> loadOverview({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required int limit,
  }) async {
    overviewFilters.add(filter);
    return _sampleOverviewBucket(
      _sampleDashboard(scope.repository ?? 'kingwill101/artisanal'),
    );
  }

  @override
  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    final dashboard = _sampleDashboard(repository);
    return GithubPage(
      items: dashboard.issues.take(first).toList(growable: false),
      totalCount: dashboard.issues.length,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPage<GithubPullRequestItem>> loadPullRequestsPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    final dashboard = _sampleDashboard(repository);
    return GithubPage(
      items: dashboard.pullRequests.take(first).toList(growable: false),
      totalCount: dashboard.pullRequests.length,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  }) async {
    return _sampleDashboard(repository).pullRequests.first;
  }

  @override
  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  }) async {
    final dashboard = _sampleDashboard(repository);
    return GithubPage(
      items: dashboard.workflowRuns.take(first).toList(growable: false),
      totalCount: dashboard.workflowRuns.length,
      hasNextPage: false,
      nextPage: page + 1,
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
    return _sampleCommits();
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
    return _sampleMergeInfo(number);
  }

  @override
  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  }) async {
    return _sampleRunDetail();
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
    return GithubPullRequestReviewComment(
      id: 'review-created',
      path: path,
      line: line,
      side: side,
      author: 'you',
      body: body,
      url: '',
      createdAt: null,
    );
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
    return const <GithubRepositoryLabel>[];
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

final class _FakeGithubClient
    implements GithubDashboardClient, GithubPullRequestDiffStreamingClient {
  _FakeGithubClient(
    this.dashboard, {
    this.comments = const <GithubCommentItem>[],
    this.reviewComments = const <GithubPullRequestReviewComment>[],
    this.diff = '',
    this.diffFiles = const <GithubPullRequestDiffFile>[],
    this.loadGate,
    GithubPullRequestItem? pullRequest,
    GithubWorkflowRunDetail? runDetail,
  }) : pullRequest = pullRequest ?? dashboard.pullRequests.first,
       runDetail = runDetail ?? _sampleRunDetail();

  final GithubDashboardData dashboard;
  final GithubPullRequestItem pullRequest;
  final List<GithubCommentItem> comments;
  final List<GithubPullRequestReviewComment> reviewComments;
  final String diff;
  final List<GithubPullRequestDiffFile> diffFiles;
  final Future<void>? loadGate;
  final GithubWorkflowRunDetail runDetail;
  var dashboardLoads = 0;
  var pullRequestLoads = 0;
  var commentLoads = 0;
  final addedComments = <_RecordedComment>[];
  final addedReviewComments = <_RecordedReviewComment>[];
  final addedLabels = <_RecordedLabels>[];

  @override
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  }) async {
    dashboardLoads++;
    await loadGate;
    return dashboard;
  }

  @override
  Future<GithubOverviewBucket> loadOverview({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required int limit,
  }) async {
    await loadGate;
    return _sampleOverviewBucket(dashboard);
  }

  @override
  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    return GithubPage(
      items: dashboard.issues.take(first).toList(growable: false),
      totalCount: dashboard.issues.length,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPage<GithubPullRequestItem>> loadPullRequestsPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    return GithubPage(
      items: dashboard.pullRequests.take(first).toList(growable: false),
      totalCount: dashboard.pullRequests.length,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  }) async {
    pullRequestLoads++;
    return pullRequest;
  }

  @override
  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  }) async {
    return GithubPage(
      items: dashboard.workflowRuns.take(first).toList(growable: false),
      totalCount: dashboard.workflowRuns.length,
      hasNextPage: false,
      nextPage: page + 1,
    );
  }

  @override
  Future<List<GithubCommentItem>> loadComments({
    required String repository,
    required GithubItemKind kind,
    required int number,
  }) async {
    commentLoads++;
    return comments;
  }

  @override
  Future<List<GithubPullRequestReviewComment>> loadPullRequestReviewComments({
    required String repository,
    required int number,
  }) async {
    return reviewComments;
  }

  @override
  Future<List<GithubPullRequestCommit>> loadPullRequestCommits({
    required String repository,
    required int number,
  }) async {
    return _sampleCommits();
  }

  @override
  Future<String> loadPullRequestDiff({
    required String repository,
    required int number,
  }) async {
    return diff;
  }

  @override
  Stream<GithubPullRequestDiffChunk> loadPullRequestDiffChunks({
    required String repository,
    required int number,
  }) async* {
    if (diffFiles.isNotEmpty) {
      final buffer = GithubPullRequestDiffBuffer();
      final chunk = buffer.addFiles(diffFiles);
      if (chunk.text.isNotEmpty || chunk.files.isNotEmpty) yield chunk;
      final done = buffer.finish();
      if (done.text.isNotEmpty || done.files.isNotEmpty) yield done;
      return;
    }
    if (diff.isNotEmpty) {
      yield GithubPullRequestDiffChunk(
        text: diff,
        loadedFiles: 0,
        renderedFiles: 0,
        omittedFiles: 0,
        truncated: false,
      );
    }
  }

  @override
  Future<GithubPullRequestMergeInfo> loadPullRequestMergeInfo({
    required String repository,
    required int number,
  }) async {
    return _sampleMergeInfo(number);
  }

  @override
  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  }) async {
    return runDetail;
  }

  @override
  Future<void> addComment({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required String body,
  }) async {
    addedComments.add(_RecordedComment(kind: kind, number: number, body: body));
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
    addedReviewComments.add(
      _RecordedReviewComment(
        number: number,
        commitId: commitId,
        path: path,
        line: line,
        side: side,
        body: body,
        startLine: startLine,
        startSide: startSide,
      ),
    );
    return GithubPullRequestReviewComment(
      id: 'created-review-${addedReviewComments.length}',
      path: path,
      line: line,
      side: side,
      author: 'you',
      body: body,
      url: '',
      createdAt: null,
    );
  }

  @override
  Future<void> addLabels({
    required String repository,
    required GithubItemKind kind,
    required int number,
    required List<String> labels,
  }) async {
    addedLabels.add(
      _RecordedLabels(kind: kind, number: number, labels: labels),
    );
  }

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
      GithubRepositoryLabel(name: 'bug', color: '#d73a4a'),
      GithubRepositoryLabel(name: 'enhancement', color: '#a2eeef'),
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

final class _LazyPagingGithubClient implements GithubDashboardClient {
  _LazyPagingGithubClient({this.pullRequestPageGate});

  final Future<void>? pullRequestPageGate;
  var dashboardCalls = 0;
  var issuePageCalls = 0;
  var pullRequestPageCalls = 0;
  var workflowRunPageCalls = 0;
  String? lastPullRequestAfter;

  @override
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  }) async {
    dashboardCalls++;
    return _sampleDashboard(repository ?? 'current/repo').copyWith(
      issues: const <GithubIssueItem>[],
      pullRequests: const <GithubPullRequestItem>[],
      workflowRuns: const <GithubWorkflowRunItem>[],
    );
  }

  @override
  Future<GithubOverviewBucket> loadOverview({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required int limit,
  }) async {
    return _sampleOverviewBucket(
      _sampleDashboard(scope.repository ?? 'current/repo'),
    );
  }

  @override
  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    issuePageCalls++;
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
    pullRequestPageCalls++;
    await pullRequestPageGate;
    lastPullRequestAfter = after;
    final firstPage = after == null;
    return GithubPage<GithubPullRequestItem>(
      items: <GithubPullRequestItem>[_pagedPullRequest(firstPage ? 1 : 2)],
      totalCount: 2,
      hasNextPage: firstPage,
      endCursor: firstPage ? 'cursor-1' : null,
    );
  }

  @override
  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  }) async {
    return _pagedPullRequest(number);
  }

  @override
  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  }) async {
    workflowRunPageCalls++;
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
    return _sampleCommits();
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
    return _sampleMergeInfo(number);
  }

  @override
  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  }) async {
    return _sampleRunDetail();
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
    return GithubPullRequestReviewComment(
      id: 'review-created',
      path: path,
      line: line,
      side: side,
      author: 'you',
      body: body,
      url: '',
      createdAt: null,
    );
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
    return const <GithubRepositoryLabel>[];
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

final class _FlakyGithubClient implements GithubDashboardClient {
  var calls = 0;

  @override
  Future<GithubDashboardData> loadDashboard({
    String? repository,
    String? owner,
    int limit = 20,
  }) async {
    calls++;
    if (calls == 1) {
      throw const GhCliException('gh auth failed');
    }
    return _sampleDashboard();
  }

  @override
  Future<GithubOverviewBucket> loadOverview({
    required GithubDashboardScope scope,
    required GithubOverviewFilter filter,
    required int limit,
  }) async {
    return _sampleOverviewBucket(
      _sampleDashboard(scope.repository ?? 'kingwill101/artisanal'),
    );
  }

  @override
  Future<GithubPage<GithubIssueItem>> loadIssuesPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    final dashboard = _sampleDashboard(repository);
    return GithubPage(
      items: dashboard.issues.take(first).toList(growable: false),
      totalCount: dashboard.issues.length,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPage<GithubPullRequestItem>> loadPullRequestsPage({
    required String repository,
    required int first,
    String? after,
  }) async {
    final dashboard = _sampleDashboard(repository);
    return GithubPage(
      items: dashboard.pullRequests.take(first).toList(growable: false),
      totalCount: dashboard.pullRequests.length,
      hasNextPage: false,
    );
  }

  @override
  Future<GithubPullRequestItem> loadPullRequest({
    required String repository,
    required int number,
  }) async {
    return _sampleDashboard(repository).pullRequests.first;
  }

  @override
  Future<GithubPage<GithubWorkflowRunItem>> loadWorkflowRunsPage({
    required String repository,
    required int first,
    required int page,
  }) async {
    final dashboard = _sampleDashboard(repository);
    return GithubPage(
      items: dashboard.workflowRuns.take(first).toList(growable: false),
      totalCount: dashboard.workflowRuns.length,
      hasNextPage: false,
      nextPage: page + 1,
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
  Future<String> loadPullRequestDiff({
    required String repository,
    required int number,
  }) async {
    return '';
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
    return _sampleCommits();
  }

  @override
  Future<GithubPullRequestMergeInfo> loadPullRequestMergeInfo({
    required String repository,
    required int number,
  }) async {
    return _sampleMergeInfo(number);
  }

  @override
  Future<GithubWorkflowRunDetail> loadWorkflowRunDetail({
    required String repository,
    required int databaseId,
  }) async {
    return _sampleRunDetail();
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
    return GithubPullRequestReviewComment(
      id: 'review-created',
      path: path,
      line: line,
      side: side,
      author: 'you',
      body: body,
      url: '',
      createdAt: null,
    );
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
    return const <GithubRepositoryLabel>[];
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
