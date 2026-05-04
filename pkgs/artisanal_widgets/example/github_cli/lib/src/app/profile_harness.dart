import 'dart:io' as io;

import 'package:artisanal/args.dart' show ArgResults, Command;
import 'package:artisanal/tui.dart' as tui;

import '../utils/pull_request_input.dart';
import '../utils/repository_input.dart';
import 'profile_regions.dart';
import 'replay_harness.dart';

final class GithubCliProfileHarnessCommand extends Command<void> {
  GithubCliProfileHarnessCommand() {
    argParser
      ..addOption(
        'trace',
        defaultsTo: 'latest',
        help:
            'TuiTrace log to convert into replay input, or "latest" for the newest traces/*.log.',
        valueHelp: 'path',
      )
      ..addOption(
        'script-filter',
        defaultsTo: 'bin/github_cli.dart',
        help: 'Use the latest trace session whose script contains this text.',
        valueHelp: 'text',
      )
      ..addOption(
        'session-out',
        defaultsTo: '.dart_tool/github_cli/replay/issues-manual.session.log',
        help: 'Where to write the selected trace session.',
        valueHelp: 'path',
      )
      ..addOption(
        'scenario-out',
        defaultsTo: '.dart_tool/github_cli/replay/issues-manual.json',
        help: 'Where to write the converted replay scenario.',
        valueHelp: 'path',
      )
      ..addOption(
        'name',
        defaultsTo: 'issues_manual_profile',
        help: 'Replay scenario name for converted traces.',
        valueHelp: 'name',
      )
      ..addOption(
        'description',
        defaultsTo: 'Generated from github_cli profiling harness',
        help: 'Replay scenario description for converted traces.',
        valueHelp: 'text',
      )
      ..addOption(
        'limit',
        defaultsTo: '20',
        help: 'Page size passed to the dashboard.',
        valueHelp: 'count',
      )
      ..addOption(
        'view',
        help: 'Profile a single pull request view instead of dashboard.',
        valueHelp: 'owner/repo#number|url',
      )
      ..addOption(
        'speed',
        defaultsTo: '1.0',
        help: 'Replay speed multiplier.',
        valueHelp: 'factor',
      )
      ..addOption(
        'min-sleep-us',
        defaultsTo: '30000',
        help: 'Minimum trace gap preserved as replay sleep.',
        valueHelp: 'micros',
      )
      ..addOption(
        'lead-in-ms',
        defaultsTo: '3500',
        help: 'Initial wait before the first replay input.',
        valueHelp: 'ms',
      )
      ..addOption(
        'screen-width',
        defaultsTo: '0',
        help: 'Override converted replay source screen width.',
        valueHelp: 'cols',
      )
      ..addOption(
        'screen-height',
        defaultsTo: '0',
        help: 'Override converted replay source screen height.',
        valueHelp: 'rows',
      )
      ..addOption(
        'fixed-right-width',
        defaultsTo: '60',
        help: 'Keep the right pane anchored when scaling replay mouse input.',
        valueHelp: 'cols',
      )
      ..addFlag(
        'block-input',
        defaultsTo: true,
        help: 'Ignore manual terminal input while replay is active.',
      )
      ..addOption(
        'profiler-command',
        defaultsTo: 'devtools-profiler',
        help: 'Profiler executable used to launch the replay.',
        valueHelp: 'command',
      )
      ..addOption(
        'artifact-dir',
        defaultsTo: '.dart_tool/github_cli/profile/issues-replay',
        help: 'Where devtools-profiler should write the session artifacts.',
        valueHelp: 'path',
      )
      ..addFlag(
        'clean-artifact-dir',
        defaultsTo: true,
        help: 'Delete the artifact directory before profiling.',
      )
      ..addOption(
        'duration',
        defaultsTo: '',
        help: 'Optional devtools-profiler --duration value.',
        valueHelp: 'time',
      )
      ..addOption(
        'vm-service-timeout',
        defaultsTo: '180s',
        help: 'How long to wait for the replay VM service.',
        valueHelp: 'time',
      )
      ..addFlag(
        'terminal',
        defaultsTo: true,
        help: 'Run the replay with direct terminal access.',
      )
      ..addFlag(
        'forward-output',
        defaultsTo: true,
        help: 'Let devtools-profiler forward replay stdout/stderr.',
      )
      ..addFlag(
        'capture-trace',
        defaultsTo: false,
        help:
            'Also capture a lightweight TUI trace during the profiled replay.',
      )
      ..addOption(
        'trace-out',
        defaultsTo: '.dart_tool/github_cli/replay/issues-profile.log',
        help: 'Trace path used when --capture-trace is enabled.',
        valueHelp: 'path',
      )
      ..addOption(
        'trace-tags',
        defaultsTo: 'general,render,layout,paint,scroll',
        help: 'Comma-separated trace tags used for replay capture.',
        valueHelp: 'tags',
      )
      ..addFlag(
        'capture-dispatch',
        negatable: false,
        help: 'Include dispatch capture diagnostics in the replay trace.',
      )
      ..addFlag(
        'profile-region',
        defaultsTo: true,
        help: 'Mark the active replay window as a devtools profile region.',
      )
      ..addOption(
        'region-name',
        defaultsTo: 'github_cli.replay',
        help: 'Profile region name used when --profile-region is enabled.',
        valueHelp: 'name',
      )
      ..addOption(
        'timeout-seconds',
        defaultsTo: '240',
        help: 'Kill devtools-profiler if the run takes longer than this.',
        valueHelp: 'seconds',
      );
  }

  @override
  String get name => 'profile';

  @override
  String get description =>
      'Profile a deterministic github_cli replay with devtools-profiler.';

  @override
  String get invocation {
    final executable = runner?.executableName ?? 'github_cli';
    return '$executable profile [owner/repo]';
  }

  @override
  Future<void> run() async {
    final config = GithubCliProfileHarnessConfig.fromArgResults(argResults!);
    if (config.error case final error?) {
      usageException(error);
    }

    await runGithubCliProfileHarness(config);
  }

  Future<void> runGithubCliProfileHarness(
    GithubCliProfileHarnessConfig config,
  ) async {
    var prepared = await prepareGithubCliReplayHarness(config.replay);
    if (config.profileRegion) {
      final actionCount = await instrumentGithubCliReplayProfileRegion(
        prepared.plan.path,
        regionName: config.regionName,
        repository: config.replay.targetLabel,
      );
      prepared = prepared.copyWith(actionCount: actionCount);
    }
    _printReplayPreparation(prepared);
    await _prepareArtifactDir(config);

    final profilerArgs = buildGithubCliProfilerRunArgs(
      config,
      prepared.plan.path,
    );
    final env = githubCliReplayEnvironment(config.replay);

    info('Profiling replay for ${config.replay.targetLabel}.');
    comment('artifact dir: ${config.artifactDir}');
    if (config.replay.captureTrace) {
      comment('replay trace: ${config.replay.traceOut}');
    }

    final process = await io.Process.start(
      config.profilerCommand,
      profilerArgs,
      environment: env,
      mode: io.ProcessStartMode.inheritStdio,
      workingDirectory: io.Directory.current.path,
    );
    final exitCode = await waitForGithubCliHarnessProcessExit(
      process,
      config.timeoutSeconds,
    );
    if (exitCode != 0) {
      io.exitCode = exitCode;
      return;
    }

    info('Profile artifacts: ${config.artifactDir}');
  }

  void _printReplayPreparation(GithubCliPreparedReplay prepared) {
    info(
      'Selected trace session '
      '${prepared.selection.sessionIndex}/${prepared.selection.sessionCount}: '
      '${prepared.selection.sourcePath}',
    );
    if (prepared.selection.script case final script?) {
      comment('script: $script');
    }
    comment('session: ${prepared.selection.outPath}');
    info(
      'Converted ${prepared.plan.traceConversion?.eventCount ?? 0} trace events '
      'into ${prepared.actionCount} replay actions.',
    );
    comment('scenario: ${prepared.plan.path}');
  }
}

Future<int> instrumentGithubCliReplayProfileRegion(
  String scenarioPath, {
  required String regionName,
  required String repository,
}) async {
  final scenario = await tui.ReplayScenario.load(scenarioPath);
  final actions = scenario.actions
      .where(
        (action) =>
            action.eventType != githubCliProfileRegionStartEvent &&
            action.eventType != githubCliProfileRegionStopEvent,
      )
      .toList();

  final start = tui.ReplayAction(
    type: 'event',
    eventType: githubCliProfileRegionStartEvent,
    eventFields: <String, Object?>{
      'name': regionName,
      'repository': repository,
      'scenario': scenario.name,
    },
  );
  const stop = tui.ReplayAction(
    type: 'event',
    eventType: githubCliProfileRegionStopEvent,
  );

  final warmupMs = actions.isNotEmpty && actions.first.type == 'sleep'
      ? actions.removeAt(0).ms
      : 0;
  final startWithWarmup = warmupMs > 0
      ? tui.ReplayAction(
          type: start.type,
          eventType: start.eventType,
          eventFields: <String, Object?>{
            ...start.eventFields,
            'warmupMs': warmupMs,
          },
        )
      : start;
  actions.insert(0, startWithWarmup);
  actions.add(stop);

  await tui.ReplayScenario(
    name: scenario.name,
    description: scenario.description,
    screen: scenario.screen,
    actions: actions,
  ).save(scenarioPath);
  return actions.length;
}

final class GithubCliProfileHarnessConfig {
  const GithubCliProfileHarnessConfig({
    required this.replay,
    required this.profilerCommand,
    required this.artifactDir,
    required this.cleanArtifactDir,
    required this.duration,
    required this.vmServiceTimeout,
    required this.terminal,
    required this.forwardOutput,
    required this.profileRegion,
    required this.regionName,
    required this.timeoutSeconds,
    this.error,
  });

  final GithubCliReplayHarnessConfig replay;
  final String profilerCommand;
  final String artifactDir;
  final bool cleanArtifactDir;
  final String duration;
  final String vmServiceTimeout;
  final bool terminal;
  final bool forwardOutput;
  final bool profileRegion;
  final String regionName;
  final int timeoutSeconds;
  final String? error;

  static GithubCliProfileHarnessConfig fromArgResults(ArgResults parsed) {
    final rest = parsed.rest;
    if (rest.length > 1) {
      return _error('Unexpected argument: ${rest[1]}');
    }

    final rawViewTarget = (parsed['view'] as String?)?.trim();
    final viewTarget = rawViewTarget == null || rawViewTarget.isEmpty
        ? null
        : parseGithubPullRequestTarget(rawViewTarget);
    if (rawViewTarget != null &&
        rawViewTarget.isNotEmpty &&
        viewTarget == null) {
      return _error(
        '--view must be owner/repo/pull/number, owner/repo#number, or a GitHub pull URL.',
      );
    }

    if (viewTarget != null && rest.isNotEmpty) {
      return _error('Unexpected argument with --view: ${rest.first}');
    }

    final rawRepository = rest.isEmpty ? 'dart-lang/sdk' : rest.single;
    final repository = normalizeGithubRepositoryInput(rawRepository);
    if (repository == null) {
      return _error('Repository must be owner/repo or a github.com URL.');
    }

    final limit = _parsePositiveInt(parsed['limit'], '--limit');
    if (limit case (value: _, error: final error?)) return _error(error);

    final speed = _parsePositiveDouble(parsed['speed'], '--speed');
    if (speed case (value: _, error: final error?)) return _error(error);

    final minSleepUs = _parseNonNegativeInt(
      parsed['min-sleep-us'],
      '--min-sleep-us',
    );
    if (minSleepUs case (value: _, error: final error?)) return _error(error);

    final leadInMs = _parseNonNegativeInt(parsed['lead-in-ms'], '--lead-in-ms');
    if (leadInMs case (value: _, error: final error?)) return _error(error);

    final screenWidth = _parseNonNegativeInt(
      parsed['screen-width'],
      '--screen-width',
    );
    if (screenWidth case (value: _, error: final error?)) return _error(error);

    final screenHeight = _parseNonNegativeInt(
      parsed['screen-height'],
      '--screen-height',
    );
    if (screenHeight case (value: _, error: final error?)) {
      return _error(error);
    }

    final fixedRightWidth = _parseNonNegativeInt(
      parsed['fixed-right-width'],
      '--fixed-right-width',
    );
    if (fixedRightWidth case (value: _, error: final error?)) {
      return _error(error);
    }

    final timeoutSeconds = _parseNonNegativeInt(
      parsed['timeout-seconds'],
      '--timeout-seconds',
    );
    if (timeoutSeconds case (value: _, error: final error?)) {
      return _error(error);
    }

    final artifactDir = (parsed['artifact-dir'] as String).trim();
    if (artifactDir.isEmpty) {
      return _error('--artifact-dir must not be empty.');
    }

    final profilerCommand = (parsed['profiler-command'] as String).trim();
    if (profilerCommand.isEmpty) {
      return _error('--profiler-command must not be empty.');
    }

    final regionName = (parsed['region-name'] as String).trim();
    if (parsed['profile-region'] == true && regionName.isEmpty) {
      return _error('--region-name must not be empty.');
    }

    return GithubCliProfileHarnessConfig(
      replay: GithubCliReplayHarnessConfig(
        repository: repository,
        viewTarget: viewTarget,
        tracePath: parsed['trace'] as String,
        scriptFilter: parsed['script-filter'] as String,
        sessionOut: parsed['session-out'] as String,
        scenarioOut: parsed['scenario-out'] as String,
        name: parsed['name'] as String,
        description: parsed['description'] as String,
        limit: limit.value,
        speed: speed.value,
        minSleepUs: minSleepUs.value,
        leadInMs: leadInMs.value,
        screenWidth: screenWidth.value,
        screenHeight: screenHeight.value,
        fixedRightWidth: fixedRightWidth.value,
        blockInput: parsed['block-input'] == true,
        convertOnly: false,
        captureTrace: parsed['capture-trace'] == true,
        traceOut: parsed['trace-out'] as String,
        traceTags: parsed['trace-tags'] as String,
        captureDispatch: parsed['capture-dispatch'] == true,
        summaryCount: 0,
        maxSpanUs: 0,
        timeoutSeconds: timeoutSeconds.value,
      ),
      profilerCommand: profilerCommand,
      artifactDir: artifactDir,
      cleanArtifactDir: parsed['clean-artifact-dir'] == true,
      duration: parsed['duration'] as String,
      vmServiceTimeout: parsed['vm-service-timeout'] as String,
      terminal: parsed['terminal'] == true,
      forwardOutput: parsed['forward-output'] == true,
      profileRegion: parsed['profile-region'] == true,
      regionName: regionName,
      timeoutSeconds: timeoutSeconds.value,
    );
  }

  static GithubCliProfileHarnessConfig _error(String message) {
    return GithubCliProfileHarnessConfig(
      replay: GithubCliReplayHarnessConfig(
        repository: 'dart-lang/sdk',
        viewTarget: null,
        tracePath: '',
        scriptFilter: '',
        sessionOut: '',
        scenarioOut: '',
        name: '',
        description: '',
        limit: 20,
        speed: 1,
        minSleepUs: 30000,
        leadInMs: 3500,
        screenWidth: 0,
        screenHeight: 0,
        fixedRightWidth: 60,
        blockInput: true,
        convertOnly: false,
        captureTrace: false,
        traceOut: '',
        traceTags: '',
        captureDispatch: false,
        summaryCount: 0,
        maxSpanUs: 0,
        timeoutSeconds: 240,
      ),
      profilerCommand: 'devtools-profiler',
      artifactDir: '',
      cleanArtifactDir: true,
      duration: '',
      vmServiceTimeout: '180s',
      terminal: true,
      forwardOutput: true,
      profileRegion: true,
      regionName: 'github_cli.replay',
      timeoutSeconds: 240,
      error: message,
    );
  }

  static ({int value, String? error}) _parsePositiveInt(
    Object? value,
    String optionName,
  ) {
    final parsed = int.tryParse((value as String? ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return (value: 0, error: '$optionName must be a positive integer.');
    }
    return (value: parsed, error: null);
  }

  static ({int value, String? error}) _parseNonNegativeInt(
    Object? value,
    String optionName,
  ) {
    final parsed = int.tryParse((value as String? ?? '').trim());
    if (parsed == null || parsed < 0) {
      return (value: 0, error: '$optionName must be a non-negative integer.');
    }
    return (value: parsed, error: null);
  }

  static ({double value, String? error}) _parsePositiveDouble(
    Object? value,
    String optionName,
  ) {
    final parsed = double.tryParse((value as String? ?? '').trim());
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return (value: 1, error: '$optionName must be a positive number.');
    }
    return (value: parsed, error: null);
  }
}

List<String> buildGithubCliProfilerRunArgs(
  GithubCliProfileHarnessConfig config,
  String scenarioPath, {
  String? cwd,
  String? entrypoint,
}) {
  final args = <String>[
    'run',
    if (config.terminal) '--terminal',
    '--cwd',
    cwd ?? io.Directory.current.path,
    '--artifact-dir',
    config.artifactDir,
    if (config.duration.trim().isNotEmpty) ...[
      '--duration',
      config.duration.trim(),
    ],
    if (config.vmServiceTimeout.trim().isNotEmpty) ...[
      '--vm-service-timeout',
      config.vmServiceTimeout.trim(),
    ],
    if (!config.forwardOutput) '--no-forward-output',
    '--',
    'dart',
    'run',
    ...buildGithubCliReplayRunArgs(
      config.replay,
      scenarioPath,
      entrypoint: entrypoint,
    ),
  ];
  return args;
}

Future<void> _prepareArtifactDir(GithubCliProfileHarnessConfig config) async {
  final artifactDir = io.Directory(config.artifactDir);
  if (config.cleanArtifactDir && await artifactDir.exists()) {
    await artifactDir.delete(recursive: true);
  }
  final parent = artifactDir.parent;
  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }
}
