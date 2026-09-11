import 'package:args/args.dart' show ArgParser, ArgParserException, ArgResults;
import 'package:artisanal/tui.dart'
    show ReplayHarnessConfig, ReplayFlagsArgParser;

import '../utils/repository_input.dart';
import 'compile_time_flags.dart';

final class GithubCliConfig {
  const GithubCliConfig({
    this.repository,
    this.owner,
    this.limit = 20,
    this.replay = const ReplayHarnessConfig(
      scenarioPath: null,
      tracePath: null,
      scriptFilter: '',
      sessionOut: '',
      scenarioOut: null,
      scenarioName: '',
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
    this.help = false,
    this.error,
  });

  final String? repository;
  final String? owner;
  final int limit;
  final ReplayHarnessConfig replay;
  final bool help;
  final String? error;

  bool get hasError => error != null;
  GithubDashboardTarget? get target {
    if (repository != null) {
      return GithubDashboardTarget.repository(repository!);
    }
    if (owner != null) return GithubDashboardTarget.owner(owner!);
    return null;
  }

  static GithubCliConfig parse(List<String> arguments) {
    final parser = ArgParser()..registerGithubCliFlags();
    final results = _parseArguments(parser, arguments);
    if (results case (error: final error?, results: _)) {
      return GithubCliConfig(error: error);
    }
    return fromArgResults(results.results!);
  }

  static GithubCliConfig fromArgResults(ArgResults parsed) {
    if (parsed['help'] == true) {
      return const GithubCliConfig(help: true);
    }

    final replay = githubCliReplayCliEnabled
        ? ReplayHarnessConfig.fromArgResults(parsed)
        : const ReplayHarnessConfig(
            scenarioPath: null,
            tracePath: null,
            scriptFilter: '',
            sessionOut: '',
            scenarioOut: null,
            scenarioName: '',
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
          );
    if (replay.error != null) return GithubCliConfig(error: replay.error);

    final repositoryOption = parsed['repo'] as String?;
    final rest = parsed.rest;
    if (repositoryOption != null && rest.isNotEmpty) {
      return GithubCliConfig(error: 'Unexpected argument: ${rest.first}');
    }
    if (rest.length > 1) {
      return GithubCliConfig(error: 'Unexpected argument: ${rest[1]}');
    }

    final limit = int.tryParse(parsed['limit'] as String? ?? '');
    if (limit == null || limit <= 0) {
      return const GithubCliConfig(
        error: '--limit must be a positive integer.',
      );
    }

    final targetInput =
        repositoryOption ?? (rest.isEmpty ? '@me' : rest.single);
    final target = parseGithubDashboardTarget(targetInput);
    if (target == null) {
      return const GithubCliConfig(
        error: 'Target must be owner, owner/repo, or a github.com URL.',
      );
    }

    return GithubCliConfig(
      repository: target.repository,
      owner: target.owner,
      limit: limit,
      replay: replay,
    );
  }

  static ({String? error, ArgResults? results}) _parseArguments(
    ArgParser parser,
    List<String> arguments,
  ) {
    try {
      return (error: null, results: parser.parse(arguments));
    } on ArgParserException catch (error) {
      return (error: error.message, results: null);
    }
  }
}

extension GithubCliArgumentRegistration on ArgParser {
  void registerGithubCliFlags({bool includeHelp = true}) {
    addOption(
      'repo',
      abbr: 'R',
      help: 'Repository, owner, or organization to inspect. Defaults to @me.',
      valueHelp: 'target',
    );
    addOption(
      'limit',
      abbr: 'L',
      defaultsTo: '20',
      help: 'Page size for issues, PRs, and runs.',
      valueHelp: 'count',
    );
    if (githubCliReplayCliEnabled) {
      registerReplayFlags();
    }
    if (includeHelp) {
      addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');
    }
  }
}
