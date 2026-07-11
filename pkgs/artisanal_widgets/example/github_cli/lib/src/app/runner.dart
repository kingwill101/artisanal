import 'dart:io' as io;

import 'package:artisanal/args.dart' show ArgResults, CommandRunner;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/artisanal.dart'
    show ProgramHost, defaultWidgetProgramOptions, runWidgetApp;
import 'package:artisanal/tui.dart' show ProgramOptions;
import 'package:artisanal_widgets/widgets.dart' show ImageAutoMode, WidgetApp;

import '../client/client_cli.dart';
import 'compile_time_flags.dart';
import 'config.dart';
import 'dashboard.dart';
import 'replay.dart';
import 'view_command.dart';

final class GithubCliRunner extends CommandRunner<void>
    with tui.HarnessCommandsMixin {
  GithubCliRunner() : super('github_cli', 'GitHub CLI TUI') {
    argParser.registerGithubCliFlags(includeHelp: false);
    addCommand(GithubCliViewCommand());
  }

  @override
  String get harnessEntrypointPath => 'bin/github_cli.dart';

  @override
  bool get enableReplayHarness => githubCliReplayCliEnabled;

  @override
  bool get enableProfileHarness => githubCliProfileCliEnabled;

  @override
  String get invocation => '$executableName [owner|org|owner/repo]';

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command != null) {
      await super.runCommand(topLevelResults);
      return;
    }

    if (topLevelResults.command?.name == 'help' ||
        topLevelResults['help'] == true) {
      printUsage();
      return;
    }

    final config = GithubCliConfig.fromArgResults(topLevelResults);
    if (config.hasError) {
      usageException(config.error!);
    }

    final replayPlan = await _loadReplayPlan(config.replay);
    if (replayPlan?.convertOnly ?? false) {
      final conversion = replayPlan!.traceConversion;
      writeOut(
        'Converted ${conversion?.eventCount ?? 0} trace events into '
        '${replayPlan.actionCount} replay actions at ${replayPlan.path}.',
      );
      return;
    }

    if (replayPlan != null) {
      writeOut(_formatReplaySummary(replayPlan));
    }

    await runGithubCli(config, replayPlan: replayPlan);
  }

  Future<tui.ResolvedReplay?> _loadReplayPlan(
    tui.ReplayHarnessConfig config,
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

Future<void> runGithubCli(
  GithubCliConfig config, {
  tui.ResolvedReplay? replayPlan,
  ProgramHost? host,
  ProgramOptions Function(ProgramOptions defaults)? options,
}) async {
  final app = WidgetApp(
    GithubCliDashboard(
      client: const GhCliClient(),
      repository: config.repository,
      owner: config.owner,
      limit: config.limit,
    ),
  );

  var resolvedOptions =
      options?.call(defaultWidgetProgramOptions) ?? defaultWidgetProgramOptions;
  if (replayPlan != null) {
    resolvedOptions = resolvedOptions.copyWith(
      replay: replayPlan.replay,
      interceptor: replayPlan.interceptor,
      blockInputWhileReplay: replayPlan.blockInput,
    );
  }

  await runWidgetApp(
    app,
    imageAutoMode: ImageAutoMode.sessionCapabilities,
    options: resolvedOptions,
    host: host,
  );
}

String _formatReplaySummary(tui.ResolvedReplay replayPlan) {
  return '[github_cli] replay=${replayPlan.name} '
      'actions=${replayPlan.actionCount} '
      'loop=${replayPlan.loop} '
      'keepOpen=${replayPlan.keepOpen} '
      'blockInput=${replayPlan.blockInput} '
      'speed=${replayPlan.speed.toStringAsFixed(2)} '
      'path=${replayPlan.path}';
}
