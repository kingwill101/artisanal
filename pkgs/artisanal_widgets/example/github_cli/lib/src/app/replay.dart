import 'dart:io' as io;

import 'package:artisanal/tui.dart' as tui;

import 'profile_regions.dart';

export 'package:artisanal/tui.dart' show ReplayHarnessConfig, loadReplayPlan;

Future<tui.ResolvedReplay?> loadGithubCliReplayPlan(
  tui.ReplayHarnessConfig config,
) async {
  final resolved = config.scenarioPath != null && config.tracePath == null
      ? config.copyWith(scenarioPath: _resolveScenarioPath(config.scenarioPath!))
      : config;

  final profileRegions = GithubCliReplayProfileRegionHook(
    eventPrefix: 'github_cli.profile',
  );
  return tui.loadReplayPlan(
    resolved,
    eventHook: profileRegions.call,
  );
}

String _resolveScenarioPath(String scenarioArg) {
  final trimmed = scenarioArg.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Missing value for --replay-scenario.');
  }

  if (io.File(trimmed).existsSync()) return trimmed;

  final withJson = trimmed.endsWith('.json') ? trimmed : '$trimmed.json';
  final candidates = <String>[];
  void add(String value) {
    if (value.isNotEmpty && !candidates.contains(value)) candidates.add(value);
  }

  add(trimmed);
  add(withJson);
  add('scenarios/$trimmed');
  add('scenarios/$withJson');
  add('example/github_cli/scenarios/$trimmed');
  add('example/github_cli/scenarios/$withJson');
  add('pkgs/artisanal_widgets/example/github_cli/scenarios/$trimmed');
  add('pkgs/artisanal_widgets/example/github_cli/scenarios/$withJson');

  for (final candidate in candidates) {
    if (io.File(candidate).existsSync()) return candidate;
  }

  throw io.FileSystemException('Replay scenario file not found', scenarioArg);
}

extension on tui.ReplayHarnessConfig {
  tui.ReplayHarnessConfig copyWith({String? scenarioPath}) {
    return tui.ReplayHarnessConfig(
      scenarioPath: scenarioPath ?? this.scenarioPath,
      tracePath: tracePath,
      scriptFilter: scriptFilter,
      sessionOut: sessionOut,
      scenarioOut: scenarioOut,
      scenarioName: scenarioName,
      scenarioDescription: scenarioDescription,
      speed: speed,
      minSleepUs: minSleepUs,
      leadInMs: leadInMs,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      fixedRightWidth: fixedRightWidth,
      blockInput: blockInput,
      loop: loop,
      keepOpen: keepOpen,
      timeoutSeconds: timeoutSeconds,
      convertOnly: convertOnly,
      captureTrace: captureTrace,
      traceOut: traceOut,
      traceTags: traceTags,
      captureDispatch: captureDispatch,
      summaryCount: summaryCount,
      maxSpanUs: maxSpanUs,
      traceFromUs: traceFromUs,
      traceToUs: traceToUs,
      traceIncludeHoverMoves: traceIncludeHoverMoves,
      error: error,
    );
  }
}
