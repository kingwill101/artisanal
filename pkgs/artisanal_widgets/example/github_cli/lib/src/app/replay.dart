import 'dart:io';

import 'package:artisanal/tui.dart' as tui;

import 'profile_regions.dart';
import 'replay_config.dart';

final class GithubCliReplayPlan {
  const GithubCliReplayPlan({
    required this.path,
    required this.name,
    required this.actionCount,
    required this.loop,
    required this.keepOpen,
    required this.blockInput,
    required this.speed,
    required this.replay,
    required this.interceptor,
    required this.convertOnly,
    this.traceConversion,
  });

  final String path;
  final String name;
  final int actionCount;
  final bool loop;
  final bool keepOpen;
  final bool blockInput;
  final double speed;
  final tui.ProgramReplay replay;
  final tui.ProgramInterceptor interceptor;
  final bool convertOnly;
  final tui.ReplayTraceConversionResult? traceConversion;
}

Future<GithubCliReplayPlan?> loadGithubCliReplayPlan(
  GithubCliReplayConfig config,
) async {
  if (!config.hasReplaySource) return null;

  tui.ReplayScenario scenario;
  tui.ReplayTraceConversionResult? traceConversion;
  String resolvedPath;

  if (config.trace != null) {
    final resolvedTrace = _resolveTracePath(config.trace!);
    traceConversion = await tui.ReplayTraceConverter.convertFile(
      resolvedTrace,
      options: tui.ReplayTraceConversionOptions(
        name: config.traceName,
        description:
            config.traceDescription ?? 'Generated from github_cli trace',
        screenWidth: config.traceScreenWidth,
        screenHeight: config.traceScreenHeight,
        fixedRightWidth: config.traceFixedRightWidth,
        fromUs: config.traceFromUs,
        toUs: config.traceToUs,
        minSleepUs: config.traceMinSleepUs,
        includeHoverMoves: config.traceIncludeHoverMoves,
      ),
    );
    scenario = traceConversion.scenario;
    resolvedPath = resolvedTrace;
    final traceOut = config.traceOut;
    if (traceOut != null && traceOut.isNotEmpty) {
      await scenario.save(traceOut);
      resolvedPath = traceOut;
    }
  } else {
    final scenarioPath = _resolveScenarioPath(config.scenario!);
    scenario = await tui.ReplayScenario.load(scenarioPath);
    resolvedPath = scenarioPath;
  }

  final profileRegions = GithubCliReplayProfileRegionHook();

  return GithubCliReplayPlan(
    path: resolvedPath,
    name: scenario.name,
    actionCount: scenario.actions.length,
    loop: config.loop,
    keepOpen: config.keepOpen,
    blockInput: config.blockInput,
    speed: config.speed,
    replay: scenario.toProgramReplay(
      loop: config.loop,
      keepOpen: config.keepOpen,
      speed: config.speed,
      eventHook: profileRegions.call,
    ),
    interceptor: tui.ReplayCoordinateInterceptor(
      sourceWidth: scenario.screen.width,
      sourceHeight: scenario.screen.height,
      sourceRightFixedWidth: scenario.screen.fixedRightWidth,
    ),
    convertOnly: config.convertOnly,
    traceConversion: traceConversion,
  );
}

String _resolveScenarioPath(String scenarioArg) {
  final trimmed = scenarioArg.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Missing value for --replay-scenario.');
  }

  final withJson = trimmed.endsWith('.json') ? trimmed : '$trimmed.json';
  final candidates = <String>[];

  void addCandidate(String value) {
    if (value.isEmpty || candidates.contains(value)) return;
    candidates.add(value);
  }

  addCandidate(trimmed);
  addCandidate(withJson);
  addCandidate('scenarios/$trimmed');
  addCandidate('scenarios/$withJson');
  addCandidate('example/github_cli/scenarios/$trimmed');
  addCandidate('example/github_cli/scenarios/$withJson');
  addCandidate('pkgs/artisanal_widgets/example/github_cli/scenarios/$trimmed');
  addCandidate('pkgs/artisanal_widgets/example/github_cli/scenarios/$withJson');

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) return candidate;
  }

  throw FileSystemException('Replay scenario file not found', scenarioArg);
}

String _resolveTracePath(String traceArg) {
  final trimmed = traceArg.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Missing value for --replay-trace.');
  }
  if (File(trimmed).existsSync()) return trimmed;
  throw FileSystemException('Replay trace file not found', traceArg);
}
