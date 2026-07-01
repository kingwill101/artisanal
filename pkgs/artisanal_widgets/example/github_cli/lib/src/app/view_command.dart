import 'dart:io' as io;

import 'package:artisanal/args.dart' show ArgResults, Command;
import 'package:artisanal_widgets/artisanal_widgets.dart'
    show defaultWidgetProgramOptions, runWidgetApp, WidgetApp, ImageAutoMode;

import '../client/client.dart';
import '../client/client_cli.dart';
import '../utils/pull_request_input.dart';
import 'compile_time_flags.dart';
import 'pull_request_view.dart';
import 'replay.dart';
import 'replay_config.dart';

final class GithubCliViewCommand extends Command<void> {
  GithubCliViewCommand() {
    if (githubCliReplayCliEnabled) {
      argParser.registerGithubCliReplayFlags();
    }
  }

  @override
  String get name => 'view';

  @override
  String get description =>
      'Open one pull request without loading the repo dashboard.';

  @override
  String get invocation {
    final executable = runner?.executableName ?? 'github_cli';
    return '$executable view <owner/repo/pull/number|owner/repo#number|url>';
  }

  @override
  Future<void> run() async {
    final config = GithubCliViewConfig.fromArgResults(argResults!);
    if (config.error case final error?) {
      usageException(error);
    }

    final replayPlan = await _loadReplayPlan(config.replay);
    if (replayPlan?.convertOnly ?? false) {
      final conversion = replayPlan!.traceConversion;
      io.stdout.writeln(
        'Converted ${conversion?.eventCount ?? 0} trace events into '
        '${replayPlan.actionCount} replay actions at ${replayPlan.path}.',
      );
      return;
    }

    if (replayPlan != null) {
      io.stdout.writeln(_formatReplaySummary(replayPlan));
    }

    await runGithubPullRequestView(config, replayPlan: replayPlan);
  }

  Future<GithubCliReplayPlan?> _loadReplayPlan(
    GithubCliReplayConfig config,
  ) async {
    try {
      return await loadGithubCliReplayPlan(config);
    } on FormatException catch (error) {
      usageException(error.message);
    } on io.FileSystemException catch (error) {
      final path = error.path == null ? '' : ': ${error.path}';
      usageException('${error.message}$path');
    }
  }
}

final class GithubCliViewConfig {
  const GithubCliViewConfig({
    required this.target,
    this.replay = const GithubCliReplayConfig(),
    this.error,
  });

  final GithubPullRequestTarget? target;
  final GithubCliReplayConfig replay;
  final String? error;

  static GithubCliViewConfig fromArgResults(ArgResults results) {
    final replay = githubCliReplayCliEnabled
        ? GithubCliReplayConfig.fromArgResults(results)
        : (config: const GithubCliReplayConfig(), error: null);
    if (replay.error != null) {
      return GithubCliViewConfig(target: null, error: replay.error);
    }

    final rest = results.rest;
    if (rest.length != 1) {
      return const GithubCliViewConfig(
        target: null,
        error: 'Expected one pull request target.',
      );
    }
    final target = parseGithubPullRequestTarget(rest.single);
    if (target == null) {
      return const GithubCliViewConfig(
        target: null,
        error:
            'Pull request target must be owner/repo/pull/number, '
            'owner/repo/pr/number, owner/repo#number, or a GitHub pull URL.',
      );
    }
    return GithubCliViewConfig(target: target, replay: replay.config);
  }
}

Future<void> runGithubPullRequestView(
  GithubCliViewConfig config, {
  GithubDashboardClient client = const GhCliClient(),
  GithubCliReplayPlan? replayPlan,
}) async {
  final target = config.target;
  if (target == null) {
    throw ArgumentError('A pull request target is required.');
  }
  await runWidgetApp(
    WidgetApp(GithubPullRequestView(client: client, target: target)),
    imageAutoMode: ImageAutoMode.sessionCapabilities,
    options: replayPlan == null
        ? null
        : defaultWidgetProgramOptions.copyWith(
            replay: replayPlan.replay,
            interceptor: replayPlan.interceptor,
            blockInputWhileReplay: replayPlan.blockInput,
          ),
  );
}

String _formatReplaySummary(GithubCliReplayPlan replayPlan) {
  return '[github_cli] replay=${replayPlan.name} '
      'actions=${replayPlan.actionCount} '
      'loop=${replayPlan.loop} '
      'keepOpen=${replayPlan.keepOpen} '
      'blockInput=${replayPlan.blockInput} '
      'speed=${replayPlan.speed.toStringAsFixed(2)} '
      'path=${replayPlan.path}';
}
