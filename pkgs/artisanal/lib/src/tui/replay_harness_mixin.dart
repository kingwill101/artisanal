import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:artisanal/args.dart';
import 'program.dart';
import 'replay_protocol.dart';

/// Mixin providing replay harness functionality for Command subclasses.
///
/// Apps override [harnessEntrypointPath] and optionally customize behavior through
/// hook methods. The mixin supports trace-to-scenario conversion, coordinate
/// scaling, and can be extended via [ProfileHarnessMixin] for profiler integration.
///
/// Example usage:
/// ```dart
/// class MyReplayCommand extends Command<void> with ReplayHarnessMixin<void> {
///   MyReplayCommand() { registerHarnessFlags(); }
///
///   @override
///   String get harnessEntrypointPath => 'bin/my_app.dart';
///
///   @override
///   Future<void> run() async {
///     final config = ReplayHarnessConfig.fromArgResults(argResults!);
///     await executeReplay(config);
///   }
/// }
/// ```
mixin ReplayHarnessMixin<T> on Command<T> {
  /// Path to the entrypoint Dart file to run for replay.
  String get harnessEntrypointPath;

  /// Override to add app-specific arguments after the entrypoint.
  List<String> buildAppSpecificReplayArgs(ReplayHarnessConfig config, String scenarioPath) => <String>[];

  /// Override to customize environment variables for the child process.
  Map<String, String>? customizeReplayEnvironment(ReplayHarnessConfig config) => null;

  /// Override to transform the replay scenario before execution.
  ///
  /// Return a modified [ReplayScenario] to persist it and use it for replay,
  /// or `null` to leave the scenario unchanged. This hook is invoked after
  /// lead-in sleep has been applied and after trace-to-scenario conversion.
  Future<ReplayScenario?> customizeReplayScenario(
    ReplayScenario scenario,
    String scenarioPath,
  ) async => null;

  /// Override to resolve special trace path values (e.g. `latest`).
  /// Return a file system path, or throw if resolution fails.
  String resolveTracePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) throw const io.FileSystemException('Trace path is empty');
    if (io.File(trimmed).existsSync()) return trimmed;
    throw io.FileSystemException('Trace file not found', path);
  }

  /// Override to resolve special scenario path values.
  /// Return a file system path, or throw if resolution fails.
  /// The default implementation checks the path directly and
  /// also searches candidates like `scenarios/<name>.json`.
  String resolveScenarioPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) throw const io.FileSystemException('Scenario path is empty');
    if (io.File(trimmed).existsSync()) return trimmed;

    final withJson = trimmed.endsWith('.json') ? trimmed : '$trimmed.json';
    final candidates = <String>[trimmed, withJson];
    candidates.add('scenarios/$trimmed');
    candidates.add('scenarios/$withJson');
    for (final candidate in candidates) {
      if (io.File(candidate).existsSync()) return candidate;
    }
    throw io.FileSystemException('Replay scenario file not found', path);
  }

  /// Override to resolve `--trace latest` or other special trace path values.
  /// Return a file system path, or null if not handled.
  ///
  /// The default implementation recognizes `latest`, `traces/latest`, and
  /// `traces/latest.log` and searches `./traces/` for the newest `.log` file.
  Future<String?> tryResolveTracePath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final latestAlias = trimmed == 'latest' ||
        trimmed == 'traces/latest' ||
        trimmed == 'traces/latest.log';
    if (!latestAlias) {
      if (io.File(trimmed).existsSync()) return trimmed;
      return null;
    }

    final candidates = <io.File>[];
    final dir = io.Directory('traces');
    if (await dir.exists()) {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is io.File && entity.path.endsWith('.log')) {
          candidates.add(entity);
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return candidates.first.path;
  }

  /// Override to resolve special scenario path values.
  /// Return a file system path, or null to fall back to [resolveScenarioPath].
  Future<String?> tryResolveScenarioPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (io.File(trimmed).existsSync()) return trimmed;
    return null;
  }

  /// Override to customize trace session selection (script filtering, etc).
  /// Return the selected session index or let the mixin pick the last matching.
  int? selectTraceSessionIndex(List<TraceSessionSplit> sessions, String scriptFilter) => null;

  /// Override to customize lead-in sleep handling.
  /// Return the final action count or use the mixin default.
  Future<int>? customizeLeadInSleep(ReplayHarnessConfig config, String scenarioPath, int actionCount) => null;

  /// Called after replay preparation but before execution.
  /// Use to print custom status or perform app-specific setup.
  void onReplayPrepared(PreparedReplay prepared) {}

  /// Called after replay execution completes.
  /// Use to analyze trace output or report custom status.
  void onReplayCompleted(PreparedReplay prepared, int exitCode, {String? tracePath, int summaryCount = 0}) {}

  // ===== Argument Registration =====

  /// Register the standard harness flags on the argParser.
  /// Override to add app-specific flags alongside standard ones.
  void registerHarnessFlags() {
    argParser.registerReplayFlags();
  }

  // ===== Execution =====

  /// Execute replay using the provided configuration.
  Future<void> executeReplay(ReplayHarnessConfig config) async {
    if (config.error case final error?) {
      usageException(error);
    }

    var prepared = await _prepare(config);
    onReplayPrepared(prepared);

    if (config.convertOnly) {
      onReplayCompleted(prepared, 0);
      return;
    }

    final customized = await customizeReplayScenario(prepared.scenario, prepared.scenarioPath);
    if (customized != null) {
      await customized.save(prepared.scenarioPath);
      prepared = PreparedReplay(
        selection: prepared.selection,
        scenario: customized,
        actionCount: customized.actions.length,
      );
    }

    if (config.captureTrace) {
      final traceOut = io.File(config.traceOut);
      if (await traceOut.exists()) {
        await traceOut.delete();
      }
      if (!await traceOut.parent.exists()) {
        await traceOut.parent.create(recursive: true);
      }
    }

    final childArgs = <String>['dart', 'run', harnessEntrypointPath, ...buildAppSpecificReplayArgs(config, prepared.scenarioPath)];
    final env = customizeReplayEnvironment(config) ?? io.Platform.environment;

    final process = await io.Process.start(
      io.Platform.resolvedExecutable, childArgs,
      environment: env, mode: io.ProcessStartMode.inheritStdio,
      workingDirectory: io.Directory.current.path,
    );

    final exitCode = await _waitForExit(process, config.timeoutSeconds);
    onReplayCompleted(prepared, exitCode, tracePath: config.traceOut, summaryCount: config.summaryCount);
    if (exitCode != 0) {
      io.exitCode = exitCode;
    }
  }

  // ===== Internals =====

  Future<PreparedReplay> _prepare(ReplayHarnessConfig config) async {
    if (config.scenarioPath != null && config.tracePath == null) {
      final resolved = await tryResolveScenarioPath(config.scenarioPath!) ?? config.scenarioPath!;
      final actionCount = await _applyLeadInSleep(resolved, config.leadInMs);
      final finalScenario = await ReplayScenario.load(resolved);
      return PreparedReplay(
        selection: TraceSessionSelection(
          sourcePath: resolved, outPath: resolved,
          sessionIndex: 1, sessionCount: 1, startLine: 1, endLine: 0,
          script: null,
        ),
        scenario: finalScenario, actionCount: actionCount,
      );
    }

    final resolvedPath = await tryResolveTracePath(config.tracePath!);
    final tracePath = resolvedPath ?? resolveTracePath(config.tracePath!);
    final selection = await _selectSession(
      tracePath, scriptFilter: config.scriptFilter, outPath: config.sessionOut,
    );
    final scenarioPath = config.scenarioOut ?? selection.outPath;
    final actionCount = await _applyLeadInSleep(scenarioPath, config.leadInMs);
    final finalScenario = await ReplayScenario.load(scenarioPath);
    return PreparedReplay(selection: selection, scenario: finalScenario, actionCount: actionCount);
  }

  Future<TraceSessionSelection> _selectSession(String sourcePath, {required String scriptFilter, required String outPath}) async {
    final file = io.File(sourcePath);
    final lines = await file.readAsLines();
    final sessions = splitTraceSessions(lines);
    if (sessions.isEmpty) {
      await writeLines(outPath, lines);
      return TraceSessionSelection(sourcePath: sourcePath, outPath: outPath, sessionIndex: 1, sessionCount: 1, startLine: 1, endLine: lines.length, script: null);
    }
    final selected = selectTraceSession(sessions, scriptFilter);
    await writeLines(outPath, selected.lines);
    return TraceSessionSelection(
      sourcePath: sourcePath, outPath: outPath, sessionIndex: selected.index,
      sessionCount: sessions.length, startLine: selected.startLine,
      endLine: selected.endLine, script: selected.script,
    );
  }

  TraceSessionSplit selectTraceSession(List<TraceSessionSplit> sessions, String scriptFilter) {
    final normalizedFilter = scriptFilter.trim();
    if (selectTraceSessionIndex(sessions, scriptFilter) case final index?) {
      return sessions[index];
    }
    return sessions.lastWhere(
      (session) => normalizedFilter.isEmpty || (session.script?.contains(normalizedFilter) ?? false),
      orElse: () => sessions.last,
    );
  }

  Future<int> _applyLeadInSleep(String scenarioPath, int leadInMs) async {
    final actionCount = await loadReplayScenarioActionCount(scenarioPath);
    if (customizeLeadInSleep(
      ReplayHarnessConfig(
        scenarioPath: null, tracePath: null, scriptFilter: '', sessionOut: '', scenarioOut: null,
        scenarioName: '', scenarioDescription: '', speed: 1, minSleepUs: 0, leadInMs: leadInMs,
        screenWidth: 0, screenHeight: 0, fixedRightWidth: 0,
        blockInput: false, loop: false, keepOpen: false, timeoutSeconds: 180,
        convertOnly: false, captureTrace: false, traceOut: '', traceTags: '',
        captureDispatch: false, summaryCount: 0, maxSpanUs: 0,
        traceFromUs: null, traceToUs: null, traceIncludeHoverMoves: false,
      ),
      scenarioPath,
      actionCount,
    ) case final count?) {
      return count;
    }

    final scenario = await ReplayScenario.load(scenarioPath);
    final actions = scenario.actions.toList();
    if (leadInMs > 0) {
      if (actions.isNotEmpty && actions.first.type == 'sleep') {
        actions[0] = ReplayAction(type: 'sleep', ms: leadInMs);
      } else {
        actions.insert(0, ReplayAction(type: 'sleep', ms: leadInMs));
      }
      await ReplayScenario(
        name: scenario.name, description: scenario.description, screen: scenario.screen, actions: actions,
      ).save(scenarioPath);
    }
    return actions.length;
  }

  /// Load a replay scenario and return its action count.
  Future<int> loadReplayScenarioActionCount(String scenarioPath) async {
    final scenario = await ReplayScenario.load(scenarioPath);
    return scenario.actions.length;
  }

  Future<int> _waitForExit(io.Process process, int timeoutSeconds) async {
    if (timeoutSeconds <= 0) return process.exitCode;
    try {
      return await process.exitCode.timeout(Duration(seconds: timeoutSeconds));
    } on TimeoutException {
      process.kill();
      return 124;
    }
  }
}

// ===== Trace Analysis =====

/// One timed span in a trace summary.
final class ReplayTraceSummarySpan {
  const ReplayTraceSummarySpan({
    required this.path,
    required this.lineNumber,
    required this.tag,
    required this.message,
    required this.durationUs,
  });

  final String path;
  final int lineNumber;
  final String tag;
  final String message;
  final int durationUs;
}

/// Summarizes the slowest spans in a trace file.
final class ReplayTraceSummary {
  const ReplayTraceSummary({
    required this.path,
    required this.spanCount,
    required this.maxDurationUs,
    required this.spans,
  });

  final String path;
  final int spanCount;
  final int maxDurationUs;
  final List<ReplayTraceSummarySpan> spans;
}

/// Try to parse a single trace line as a timed span.
///
/// Returns null if the line does not match the expected format:
/// `[+123us] [tag] message 456us`
ReplayTraceSummarySpan? tryParseTraceSpan(String path, int lineNumber, String line) {
  final durationMatch = RegExp(r' (\d+)us$').firstMatch(line);
  if (durationMatch == null) return null;
  final durationUs = int.tryParse(durationMatch.group(1)!);
  if (durationUs == null) return null;

  final tagMatch = RegExp(r'^\[\+\d+us\] \[([^\]]+)\] (.*)$').firstMatch(line);
  if (tagMatch == null) return null;
  final message = tagMatch.group(2)!;
  return ReplayTraceSummarySpan(
    path: path,
    lineNumber: lineNumber,
    tag: tagMatch.group(1)!,
    message: message,
    durationUs: durationUs,
  );
}

/// Analyze a trace file and return the slowest spans.
Future<ReplayTraceSummary> analyzeReplayTrace(String path, {int limit = 12}) async {
  final file = io.File(path);
  if (!await file.exists()) {
    return ReplayTraceSummary(path: path, spanCount: 0, maxDurationUs: 0, spans: const <ReplayTraceSummarySpan>[]);
  }

  final spans = <ReplayTraceSummarySpan>[];
  final lines = await file.readAsLines();
  for (var i = 0; i < lines.length; i++) {
    final parsed = tryParseTraceSpan(path, i + 1, lines[i]);
    if (parsed != null) spans.add(parsed);
  }
  spans.sort((a, b) => b.durationUs.compareTo(a.durationUs));
  final top = spans.take(math.max(0, limit)).toList(growable: false);
  return ReplayTraceSummary(
    path: path,
    spanCount: spans.length,
    maxDurationUs: spans.isEmpty ? 0 : spans.first.durationUs,
    spans: top,
  );
}

// ===== Data Classes =====

/// Resolved replay plan ready for inline use in a Program command.
final class ResolvedReplay {
  const ResolvedReplay({
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
  final ProgramReplay replay;
  final ProgramInterceptor interceptor;
  final bool convertOnly;
  final ReplayTraceConversionResult? traceConversion;

  String get scenarioPath => path;
}

/// Load a replay plan from configuration for inline use.
///
/// Returns `null` when no replay source (trace or scenario) is configured.
/// Handles both trace-to-scenario conversion and direct scenario loading.
///
/// [eventHook] is optional and called for each custom `event` action in the
/// replay scenario.
Future<ResolvedReplay?> loadReplayPlan(
  ReplayHarnessConfig config, {
  ReplayEventHook? eventHook,
}) async {
  if (config.scenarioPath == null && config.tracePath == null) return null;

  ReplayScenario scenario;
  ReplayTraceConversionResult? traceConversion;
  String resolvedPath;

  if (config.tracePath != null) {
    final resolvedTrace = _resolveTracePath(config.tracePath!);
    traceConversion = await ReplayTraceConverter.convertFile(
      resolvedTrace,
      options: ReplayTraceConversionOptions(
        name: config.scenarioName,
        description: config.scenarioDescription,
        screenWidth: config.screenWidth,
        screenHeight: config.screenHeight,
        fixedRightWidth: config.fixedRightWidth,
        fromUs: config.traceFromUs,
        toUs: config.traceToUs,
        minSleepUs: config.minSleepUs,
        includeHoverMoves: config.traceIncludeHoverMoves,
      ),
    );
    scenario = traceConversion.scenario;
    resolvedPath = resolvedTrace;
    final scenarioOut = config.scenarioOut;
    if (scenarioOut != null && scenarioOut.isNotEmpty) {
      await scenario.save(scenarioOut);
      resolvedPath = scenarioOut;
    }
  } else {
    resolvedPath = config.scenarioPath!;
    scenario = await ReplayScenario.load(resolvedPath);
  }

  return ResolvedReplay(
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
      eventHook: eventHook,
    ),
    interceptor: ReplayCoordinateInterceptor(
      sourceWidth: scenario.screen.width,
      sourceHeight: scenario.screen.height,
      sourceRightFixedWidth: scenario.screen.fixedRightWidth,
    ),
    convertOnly: config.convertOnly,
    traceConversion: traceConversion,
  );
}

String _resolveTracePath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) throw const io.FileSystemException('Trace path is empty');
  if (io.File(trimmed).existsSync()) return trimmed;
  throw io.FileSystemException('Trace file not found', path);
}

/// Prepared replay data including session selection and scenario.
final class PreparedReplay {
  const PreparedReplay({required this.selection, required this.scenario, required this.actionCount});
  final TraceSessionSelection selection;
  final ReplayScenario scenario;
  final int actionCount;

  String get scenarioPath => selection.outPath;
}

/// Selected trace session information.
final class TraceSessionSelection {
  const TraceSessionSelection({
    required this.sourcePath, required this.outPath, required this.sessionIndex,
    required this.sessionCount, required this.startLine, required this.endLine, required this.script,
  });

  final String sourcePath;
  final String outPath;
  final int sessionIndex;
  final int sessionCount;
  final int startLine;
  final int endLine;
  final String? script;
}

/// Session data from splitting trace logs.
final class TraceSessionSplit {
  const TraceSessionSplit({required this.index, required this.startLine, required this.endLine, required this.lines});
  final int index;
  final int startLine;
  final int endLine;
  final List<String> lines;
  String? get script {
    for (final line in lines) {
      if (line.startsWith('# script:')) return line.substring('# script:'.length).trim();
    }
    return null;
  }
}

/// Writes lines to a file, creating parent directories if needed.
Future<void> writeLines(String path, List<String> lines) async {
  final file = io.File(path);
  if (!await file.parent.exists()) await file.parent.create(recursive: true);
  await file.writeAsString('${lines.join('\n')}\n');
}

/// Splits trace lines into sessions based on `# trace start:` markers.
List<TraceSessionSplit> splitTraceSessions(List<String> lines) {
  final sessions = <TraceSessionSplit>[];
  var current = <String>[];
  var startLine = 0;

  void finish(int endLine) {
    if (current.isEmpty) return;
    sessions.add(TraceSessionSplit(index: sessions.length + 1, startLine: startLine, endLine: endLine, lines: List<String>.unmodifiable(current)));
    current = <String>[];
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('# trace start:')) {
      finish(i);
      startLine = i + 1;
    }
    if (startLine > 0) current.add(line);
  }
  finish(lines.length);
  return sessions;
}

// ===== Profile Harness Mixin =====

/// Mixin that adds profile harness functionality on top of ReplayHarnessMixin.
///
/// Apps override [profileProfilerCommand], [profileArtifactDir], and [profileRegionName].
mixin ProfileHarnessMixin<T> on ReplayHarnessMixin<T> {
  String get profileProfilerCommand;

  String get profileArtifactDir;

  String get profileRegionName;

  bool get profileCaptureRegions => true;

  String get profileEventPrefix => 'profile.harness';

  Map<String, Object?> profileRegionMetadata(String? scenarioPath) => const <String, Object?>{};

  ReplayHarnessConfig defaultProfileReplayConfig() => ReplayHarnessConfig(
    scenarioPath: null, tracePath: null, scriptFilter: '', sessionOut: '', scenarioOut: null,
    scenarioName: 'profile', scenarioDescription: 'Profile replay',
    speed: 1, minSleepUs: 30000, leadInMs: 3500,
    screenWidth: 0, screenHeight: 0, fixedRightWidth: 60,
    blockInput: false, loop: false, keepOpen: false, timeoutSeconds: 180,
    convertOnly: false, captureTrace: false, traceOut: '',
    traceTags: '', captureDispatch: false, summaryCount: 0, maxSpanUs: 0,
    traceFromUs: null, traceToUs: null, traceIncludeHoverMoves: false,
  );

  /// Override to prepare the artifact directory before profiling.
  Future<void> prepareProfileArtifactDir(String artifactDir) async {
    final dir = io.Directory(artifactDir);
    final config = profileConfig;
    if (config?.cleanArtifactDir != true) return;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    final parent = dir.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
  }

  /// Override to build profiler-specific arguments.
  List<String> buildProfileArgs(ProfileHarnessConfig config, String scenarioPath) =>
      buildDevtoolsProfilerRunArgs(config, scenarioPath);

  List<String> buildDevtoolsProfilerRunArgs(ProfileHarnessConfig config, String scenarioPath) => <String>[
    'run', '--cwd', io.Directory.current.path,
    '--artifact-dir', config.artifactDir,
    '--terminal', '--', 'dart', 'run', harnessEntrypointPath,
    ...buildAppSpecificReplayArgs(defaultProfileReplayConfig(), scenarioPath),
  ];

  ProfileHarnessConfig? get profileConfig => null;

  void registerProfileHarnessFlags() {
    argParser.registerProfileFlags(
      profilerCommand: profileProfilerCommand,
      artifactDir: profileArtifactDir,
      regionName: profileRegionName,
    );
  }

  /// Override to log profile completion.
  void onProfileCompleted(ProfileHarnessConfig config, int exitCode) {}

  /// Inject profile region start/stop events into the replay scenario.
  @override
  Future<ReplayScenario?> customizeReplayScenario(
    ReplayScenario scenario,
    String scenarioPath,
  ) async {
    if (!profileCaptureRegions) return null;
    return _instrumentProfileRegion(scenario, profileRegionName, scenarioPath);
  }

  Future<void> executeProfile(ReplayHarnessConfig replayConfig, ProfileHarnessConfig config) async {
    if (config.error case final error?) {
      usageException(error);
    }

    var prepared = await _prepare(replayConfig);
    final customized = await customizeReplayScenario(prepared.scenario, prepared.scenarioPath);
    if (customized != null) {
      await customized.save(prepared.scenarioPath);
      prepared = PreparedReplay(
        selection: prepared.selection,
        scenario: customized,
        actionCount: customized.actions.length,
      );
    }

    await prepareProfileArtifactDir(config.artifactDir);

    final profilerArgs = buildProfileArgs(config, prepared.scenarioPath);
    final env = customizeReplayEnvironment(replayConfig) ?? io.Platform.environment;

    final process = await io.Process.start(
      config.profilerCommand, profilerArgs,
      environment: env, mode: io.ProcessStartMode.inheritStdio,
      workingDirectory: io.Directory.current.path,
    );

    final exitCode = await _waitForExit(process, config.timeoutSeconds);
    onProfileCompleted(config, exitCode);
    if (exitCode != 0) {
      io.exitCode = exitCode;
    }
  }

  Future<ReplayScenario> _instrumentProfileRegion(
    ReplayScenario scenario,
    String regionName,
    String outPath,
  ) async {
    final actions = scenario.actions.toList();
    final metadata = profileRegionMetadata(outPath);
    final start = ReplayAction(
      type: 'event', eventType: '$profileEventPrefix.start',
      eventFields: <String, Object?>{
        'name': regionName,
        'source': 'profile_harness',
        ...metadata,
      },
    );
    final stop = ReplayAction(type: 'event', eventType: '$profileEventPrefix.stop');

    final warmupMs = actions.isNotEmpty && actions.first.type == 'sleep' ? actions.removeAt(0).ms : 0;
    final startWithWarmup = warmupMs > 0
        ? ReplayAction(type: start.type, eventType: start.eventType,
            eventFields: <String, Object?>{...start.eventFields, 'warmupMs': warmupMs})
        : start;

    actions.insert(0, startWithWarmup);
    actions.add(stop);

    return ReplayScenario(
      name: scenario.name, description: scenario.description, screen: scenario.screen, actions: actions,
    );
  }
}

/// Configuration for profile harness commands.
final class ProfileHarnessConfig {
  const ProfileHarnessConfig({
    required this.replay,
    required this.profilerCommand,
    required this.artifactDir,
    required this.cleanArtifactDir,
    required this.timeoutSeconds,
    required this.profileRegion,
    required this.regionName,
    this.error,
  });

  final ReplayHarnessConfig replay;
  final String profilerCommand;
  final String artifactDir;
  final bool cleanArtifactDir;
  final int timeoutSeconds;
  final bool profileRegion;
  final String regionName;
  final String? error;

  static ProfileHarnessConfig fromArgResults(ReplayHarnessConfig replay, ArgResults parsed) {
    final profilerCommand = (parsed['profile-profiler-command'] as String?)?.trim() ?? 'devtools-profiler';
    final artifactDir = (parsed['profile-artifact-dir'] as String?)?.trim() ?? '.dart_tool/profile';
    final regionName = (parsed['profile-region-name'] as String?)?.trim() ?? 'app.replay';
    final timeoutSeconds = int.tryParse((parsed['profile-timeout-seconds'] as String?) ?? '240') ?? 240;

    return ProfileHarnessConfig(
      replay: replay, profilerCommand: profilerCommand, artifactDir: artifactDir,
      cleanArtifactDir: parsed['profile-clean-artifact-dir'] != false,
      timeoutSeconds: timeoutSeconds, profileRegion: parsed['profile-region'] != false,
      regionName: regionName, error: null,
    );
  }
}

// ===== CommandRunner Mixin =====

/// Mixin that adds replay and profile subcommands to a CommandRunner.
///
/// Apps provide [harnessEntrypointPath] and the mixin auto-adds `replay` and
/// `profile` subcommands on first invocation.
///
/// Example:
/// ```dart
/// class MyRunner extends CommandRunner<void> with HarnessCommandsMixin {
///   MyRunner() : super('myapp', 'My TUI app') {}
///
///   @override
///   String get harnessEntrypointPath => 'bin/my_app.dart';
/// }
/// ```
mixin HarnessCommandsMixin on CommandRunner<void> {
  /// Path to the entrypoint Dart file to run for replay.
  String get harnessEntrypointPath;

  /// Whether to auto-add the replay subcommand.
  bool get enableReplayHarness => true;

  /// Whether to auto-add the profile subcommand.
  bool get enableProfileHarness => true;

  @override
  Future<void> run(Iterable<String> args) async {
    if (!_initialized) {
      _addHarnessCommands();
      _initialized = true;
    }
    await super.run(args);
  }

  bool _initialized = false;

  void _addHarnessCommands() {
    if (enableReplayHarness) {
      addCommand(ReplayHarnessCommand(harnessEntrypointPath));
    }
    if (enableProfileHarness) {
      addCommand(ProfileHarnessCommand(harnessEntrypointPath));
    }
  }
}

// ===== Concrete Command Classes =====

/// Replay subcommand provided by [HarnessCommandsMixin].
class ReplayHarnessCommand extends Command<void> with ReplayHarnessMixin<void> {
  ReplayHarnessCommand(this.entrypointPath) {
    registerHarnessFlags();
  }

  final String entrypointPath;

  @override
  String get name => 'replay';

  @override
  String get description => 'Run a replay scenario';

  @override
  String get invocation {
    final executable = runner?.executableName ?? 'app';
    return '$executable replay';
  }

  @override
  String get harnessEntrypointPath => entrypointPath;

  @override
  Future<void> run() async {
    final config = ReplayHarnessConfig.fromArgResults(argResults!);
    await executeReplay(config);
  }
}

/// Profile subcommand provided by [HarnessCommandsMixin].
class ProfileHarnessCommand extends Command<void> with ReplayHarnessMixin<void>, ProfileHarnessMixin<void> {
  ProfileHarnessCommand(this.entrypointPath) {
    registerHarnessFlags();
    registerProfileHarnessFlags();
  }

  final String entrypointPath;

  @override
  String get name => 'profile';

  @override
  String get description => 'Profile a replay with devtools-profiler';

  @override
  String get invocation {
    final executable = runner?.executableName ?? 'app';
    return '$executable profile';
  }

  @override
  String get harnessEntrypointPath => entrypointPath;

  @override
  String get profileProfilerCommand => 'devtools-profiler';

  @override
  String get profileArtifactDir => '.dart_tool/profile';

  @override
  String get profileRegionName => 'app.replay';

  @override
  Future<void> run() async {
    final replayConfig = ReplayHarnessConfig.fromArgResults(argResults!);
    final profileConfig = ProfileHarnessConfig.fromArgResults(replayConfig, argResults!);
    await executeProfile(replayConfig, profileConfig);
  }
}

// ===== Configuration =====

/// Configuration for replay harness commands.
final class ReplayHarnessConfig {
  const ReplayHarnessConfig({
    this.scenarioPath,
    required this.tracePath,
    required this.scriptFilter,
    required this.sessionOut,
    required this.scenarioOut,
    required this.scenarioName,
    required this.scenarioDescription,
    required this.speed,
    required this.minSleepUs,
    required this.leadInMs,
    required this.screenWidth,
    required this.screenHeight,
    required this.fixedRightWidth,
    required this.blockInput,
    required this.loop,
    required this.keepOpen,
    required this.timeoutSeconds,
    required this.convertOnly,
    required this.captureTrace,
    required this.traceOut,
    required this.traceTags,
    required this.captureDispatch,
    required this.summaryCount,
    required this.maxSpanUs,
    required this.traceFromUs,
    required this.traceToUs,
    required this.traceIncludeHoverMoves,
    this.error,
  });

  final String? scenarioPath;
  final String? tracePath;
  final String scriptFilter;
  final String sessionOut;
  final String? scenarioOut;
  final String scenarioName;
  final String scenarioDescription;
  final double speed;
  final int minSleepUs;
  final int leadInMs;
  final int screenWidth;
  final int screenHeight;
  final int fixedRightWidth;
  final bool blockInput;
  final bool loop;
  final bool keepOpen;
  final int timeoutSeconds;
  final bool convertOnly;
  final bool captureTrace;
  final String traceOut;
  final String traceTags;
  final bool captureDispatch;
  final int summaryCount;
  final int maxSpanUs;
  final int? traceFromUs;
  final int? traceToUs;
  final bool traceIncludeHoverMoves;
  final String? error;

  static ReplayHarnessConfig fromArgResults(ArgResults parsed) {
    final trace = parsed['replay-trace'] as String?;
    final scenario = parsed['replay-scenario'] as String?;
    if (trace != null && scenario != null) {
      return const ReplayHarnessConfig(
        scenarioPath: null, tracePath: null, scriptFilter: '', sessionOut: '', scenarioOut: null,
        scenarioName: 'replay', scenarioDescription: 'Generated from trace',
        speed: 1, minSleepUs: 30000, leadInMs: 3500,
        screenWidth: 0, screenHeight: 0, fixedRightWidth: 0,
        blockInput: false, loop: false, keepOpen: false,
        timeoutSeconds: 180, convertOnly: false, captureTrace: false,
        traceOut: '', traceTags: '', captureDispatch: false, summaryCount: 0, maxSpanUs: 0,
        traceFromUs: null, traceToUs: null, traceIncludeHoverMoves: false,
        error: 'Use only one: --replay-scenario or --replay-trace.',
      );
    }

    final speed = _parseDouble(parsed['replay-speed'], '--replay-speed');
    if (speed case (value: _, error: final err?)) {
      return ReplayHarnessConfig._error(err);
    }

    final minSleep = _parseInt(parsed['replay-trace-min-sleep-us'], '--replay-trace-min-sleep-us');
    final leadInMs = _parseOptionalInt(parsed['replay-lead-in-ms'], 3500);
    final screenWidth = _parseInt(parsed['replay-trace-screen-width'], '--replay-trace-screen-width');
    final screenHeight = _parseInt(parsed['replay-trace-screen-height'], '--replay-trace-screen-height');
    final fixedRightWidth = _parseInt(parsed['replay-trace-fixed-right-width'], '--replay-trace-fixed-right-width');
    final timeoutSeconds = _parseInt(parsed['replay-timeout-seconds'], '--replay-timeout-seconds');

    final normalizedTrace = _blankToNull(trace);
    final normalizedScenario = _blankToNull(scenario);
    final scenarioOut = _blankToNull(parsed['replay-scenario-out'] as String?);
    final scenarioName = parsed['replay-scenario-name'] as String?;
    final scenarioDesc = parsed['replay-scenario-description'] as String?;

    String resolveName(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? 'replay' : trimmed;
    }

    String resolveDesc(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? 'Generated from trace' : trimmed;
    }

    final traceFromUs = _parseOptionalIntOrNull(parsed['replay-trace-from-us']);
    final traceToUs = _parseOptionalIntOrNull(parsed['replay-trace-to-us']);

    return ReplayHarnessConfig(
      scenarioPath: normalizedScenario.isEmpty ? null : normalizedScenario,
      tracePath: normalizedTrace.isEmpty ? null : normalizedTrace,
      scriptFilter: (parsed['replay-script-filter'] as String?) ?? 'bin/*.dart',
      sessionOut: (parsed['replay-session-out'] as String?) ?? '.dart_tool/replay/session.log',
      scenarioOut: scenarioOut.isEmpty ? null : scenarioOut,
      scenarioName: resolveName(scenarioName),
      scenarioDescription: resolveDesc(scenarioDesc),
      speed: speed.value, minSleepUs: minSleep.value, leadInMs: leadInMs,
      screenWidth: screenWidth.value, screenHeight: screenHeight.value, fixedRightWidth: fixedRightWidth.value,
      blockInput: parsed['replay-block-input'] == true,
      loop: parsed['replay-loop'] == true, keepOpen: parsed['replay-keep-open'] == true,
      timeoutSeconds: timeoutSeconds.value,
      convertOnly: parsed['replay-convert-only'] == true,
      captureTrace: parsed['replay-capture-trace'] != false,
      traceOut: (parsed['replay-trace-out'] as String?) ?? '.dart_tool/replay/trace.log',
      traceTags: (parsed['replay-trace-tags'] as String?) ?? 'general,render,layout,paint,scroll',
      captureDispatch: parsed['replay-capture-dispatch'] == true,
      summaryCount: int.tryParse((parsed['replay-summary-count'] as String?) ?? '12') ?? 12,
      maxSpanUs: int.tryParse((parsed['replay-max-span-us'] as String?) ?? '0') ?? 0,
      traceFromUs: traceFromUs,
      traceToUs: traceToUs,
      traceIncludeHoverMoves: parsed['replay-trace-include-hover'] == true,
      error: null,
    );
  }

  factory ReplayHarnessConfig._error(String message) {
    return ReplayHarnessConfig(
      scenarioPath: null, tracePath: null, scriptFilter: '', sessionOut: '', scenarioOut: null,
      scenarioName: 'replay', scenarioDescription: 'Generated from trace',
      speed: 1, minSleepUs: 30000, leadInMs: 3500,
      screenWidth: 0, screenHeight: 0, fixedRightWidth: 0,
      blockInput: false, loop: false, keepOpen: false, timeoutSeconds: 180,
      convertOnly: false, captureTrace: false, traceOut: '',
      traceTags: '', captureDispatch: false, summaryCount: 0, maxSpanUs: 0,
      traceFromUs: null, traceToUs: null, traceIncludeHoverMoves: false,
      error: message,
    );
  }

  static ({double value, String? error}) _parseDouble(Object? value, String optionName) {
    final raw = (value as String? ?? '').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return (value: 1.0, error: '$optionName must be a positive number.');
    }
    return (value: parsed, error: null);
  }

  static ({int value, String? error}) _parseInt(Object? value, String optionName) {
    final raw = (value as String? ?? '').trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      return (value: 0, error: '$optionName must be a non-negative integer.');
    }
    return (value: parsed, error: null);
  }

  static int _parseOptionalInt(Object? value, int defaultValue) {
    final raw = (value as String? ?? '').trim();
    return int.tryParse(raw) ?? defaultValue;
  }

  static int? _parseOptionalIntOrNull(Object? value) {
    final raw = (value as String? ?? '').trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  static String _blankToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed;
  }
}

// ===== Standalone ArgParser Extensions =====

/// Extension to register replay flags on any [ArgParser] (standalone usage).
extension ReplayFlagsArgParser on ArgParser {
  void registerReplayFlags() {
    addOption('replay-trace', help: 'Convert a TuiTrace log into a replay scenario.', valueHelp: 'path');
    addOption('replay-scenario', help: 'Load a replay scenario JSON file.', valueHelp: 'name|path');
    addOption('replay-scenario-out', help: 'Write converted scenario.', valueHelp: 'path');
    addOption('replay-scenario-name', help: 'Name for converted scenario.', valueHelp: 'name');
    addOption('replay-scenario-description', help: 'Description for converted scenario.', valueHelp: 'text');
    addOption('replay-speed', defaultsTo: '1.0', help: 'Replay speed.', valueHelp: 'factor');
    addOption('replay-trace-min-sleep-us', defaultsTo: '30000', help: 'Min sleep.', valueHelp: 'micros');
    addOption('replay-trace-from-us', help: 'First trace timestamp to include.', valueHelp: 'micros');
    addOption('replay-trace-to-us', help: 'Last trace timestamp to include.', valueHelp: 'micros');
    addOption('replay-lead-in-ms', defaultsTo: '3500', help: 'Initial wait before first replay input.', valueHelp: 'ms');
    addOption('replay-trace-screen-width', defaultsTo: '0', help: 'Override source screen width.', valueHelp: 'cols');
    addOption('replay-trace-screen-height', defaultsTo: '0', help: 'Override source screen height.', valueHelp: 'rows');
    addOption('replay-trace-fixed-right-width', defaultsTo: '60', help: 'Right pane anchor width.', valueHelp: 'cols');
    addFlag('replay-trace-include-hover', negatable: false, help: 'Preserve hover move events when converting traces.');
    addOption('replay-script-filter', defaultsTo: 'bin/*.dart', help: 'Script filter for session selection.', valueHelp: 'text');
    addOption('replay-session-out', defaultsTo: '.dart_tool/replay/session.log', help: 'Session output path.', valueHelp: 'path');
    addFlag('replay-block-input', negatable: false, help: 'Block manual input.');
    addFlag('replay-loop', negatable: false, help: 'Loop replay.');
    addFlag('replay-keep-open', negatable: false, help: 'Keep app open.');
    addFlag('replay-convert-only', negatable: false, help: 'Only convert, do not run.');
    addFlag('replay-capture-trace', defaultsTo: true, help: 'Capture trace during replay.');
    addOption('replay-trace-out', defaultsTo: '.dart_tool/replay/trace.log', help: 'Trace output path.', valueHelp: 'path');
    addOption('replay-trace-tags', defaultsTo: 'general,render,layout,paint,scroll', help: 'Trace tags.', valueHelp: 'tags');
    addFlag('replay-capture-dispatch', negatable: false, help: 'Include dispatch capture.');
    addOption('replay-summary-count', defaultsTo: '12', help: 'Summary span count.', valueHelp: 'count');
    addOption('replay-max-span-us', defaultsTo: '0', help: 'Fail on span exceeding this.', valueHelp: 'micros');
    addOption('replay-timeout-seconds', defaultsTo: '180', help: 'Timeout.', valueHelp: 'seconds');
  }
}

/// Extension to register profile flags on any [ArgParser] (standalone usage).
extension ProfileFlagsArgParser on ArgParser {
  void registerProfileFlags({
    String profilerCommand = 'devtools-profiler',
    String artifactDir = '.dart_tool/profile',
    String regionName = 'app.replay',
  }) {
    addOption('profile-profiler-command', defaultsTo: profilerCommand, help: 'Profiler executable.', valueHelp: 'cmd');
    addOption('profile-artifact-dir', defaultsTo: artifactDir, help: 'Artifact directory.', valueHelp: 'path');
    addFlag('profile-clean-artifact-dir', defaultsTo: true, help: 'Clean artifact dir first.');
    addFlag('profile-region', defaultsTo: true, help: 'Mark the active replay window as a devtools profile region.');
    addOption('profile-region-name', defaultsTo: regionName, help: 'Profile region name.', valueHelp: 'name');
    addOption('profile-timeout-seconds', defaultsTo: '240', help: 'Timeout.', valueHelp: 'seconds');
  }
}
