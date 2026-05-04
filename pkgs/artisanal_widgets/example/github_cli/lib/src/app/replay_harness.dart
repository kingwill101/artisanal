import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:artisanal/args.dart' show ArgResults, Command;
import 'package:artisanal/tui.dart' as tui;

import '../utils/pull_request_input.dart';
import '../utils/repository_input.dart';
import 'compile_time_flags.dart';
import 'replay.dart';
import 'replay_config.dart';

final class GithubCliReplayHarnessCommand extends Command<void> {
  GithubCliReplayHarnessCommand() {
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
        defaultsTo: 'issues_manual',
        help: 'Replay scenario name for converted traces.',
        valueHelp: 'name',
      )
      ..addOption(
        'description',
        defaultsTo: 'Generated from github_cli trace harness',
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
        help: 'Replay against a single pull request view instead of dashboard.',
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
      ..addFlag(
        'convert-only',
        negatable: false,
        help: 'Only select and convert the trace; do not run the app.',
      )
      ..addFlag(
        'capture-trace',
        defaultsTo: true,
        help: 'Capture a lightweight trace while replay runs.',
      )
      ..addOption(
        'trace-out',
        defaultsTo: '.dart_tool/github_cli/replay/issues-replay.log',
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
      ..addOption(
        'summary-count',
        defaultsTo: '12',
        help: 'Number of slow trace spans to print after replay.',
        valueHelp: 'count',
      )
      ..addOption(
        'max-span-us',
        defaultsTo: '0',
        help: 'Fail when the slowest captured span exceeds this duration.',
        valueHelp: 'micros',
      )
      ..addOption(
        'timeout-seconds',
        defaultsTo: '180',
        help: 'Kill the replay child process if it runs longer than this.',
        valueHelp: 'seconds',
      );
  }

  @override
  String get name => 'replay';

  @override
  String get description =>
      'Convert a captured trace into replay input and run it.';

  @override
  String get invocation {
    final executable = runner?.executableName ?? 'github_cli';
    return '$executable replay [owner/repo]';
  }

  @override
  Future<void> run() async {
    final config = GithubCliReplayHarnessConfig.fromArgResults(argResults!);
    if (config.error case final error?) {
      usageException(error);
    }

    await runGithubCliReplayHarness(config);
  }

  Future<void> runGithubCliReplayHarness(
    GithubCliReplayHarnessConfig config,
  ) async {
    final prepared = await prepareGithubCliReplayHarness(config);
    _printReplayPreparation(prepared);

    if (config.convertOnly) return;

    if (config.captureTrace) {
      final traceOut = io.File(config.traceOut);
      if (await traceOut.exists()) {
        await traceOut.delete();
      }
      if (!await traceOut.parent.exists()) {
        await traceOut.parent.create(recursive: true);
      }
    }

    final childArgs = <String>[
      ...buildGithubCliReplayRunArgs(config, prepared.plan.path),
    ];

    final env = githubCliReplayEnvironment(config);
    info('Running replay for ${config.targetLabel}.');
    if (config.captureTrace) {
      comment('replay trace: ${config.traceOut}');
    }

    final process = await io.Process.start(
      io.Platform.resolvedExecutable,
      childArgs,
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

    if (config.captureTrace && config.summaryCount > 0) {
      final summary = await summarizeGithubCliReplayTrace(
        config.traceOut,
        limit: config.summaryCount,
      );
      _printSummary(summary);
      if (config.maxSpanUs > 0 && summary.maxDurationUs > config.maxSpanUs) {
        error(
          'Replay trace exceeded --max-span-us: '
          '${summary.maxDurationUs}us > ${config.maxSpanUs}us.',
        );
        io.exitCode = 1;
      }
    }
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

  void _printSummary(GithubCliReplayTraceSummary summary) {
    if (summary.spans.isEmpty) {
      warn('Replay trace had no duration spans to summarize.');
      return;
    }

    info(
      'Replay trace max span: ${_formatMicros(summary.maxDurationUs)} '
      'across ${summary.spanCount} timed spans.',
    );
    for (var i = 0; i < summary.spans.length; i++) {
      final span = summary.spans[i];
      line(
        '${i + 1}. ${_formatMicros(span.durationUs)} '
        '[${span.tag}] ${span.message} '
        '(${span.path}:${span.lineNumber})',
      );
    }
  }
}

final class GithubCliPreparedReplay {
  const GithubCliPreparedReplay({
    required this.selection,
    required this.plan,
    required this.actionCount,
  });

  final GithubCliTraceSessionSelection selection;
  final GithubCliReplayPlan plan;
  final int actionCount;

  GithubCliPreparedReplay copyWith({int? actionCount}) {
    return GithubCliPreparedReplay(
      selection: selection,
      plan: plan,
      actionCount: actionCount ?? this.actionCount,
    );
  }
}

Future<GithubCliPreparedReplay> prepareGithubCliReplayHarness(
  GithubCliReplayHarnessConfig config,
) async {
  final tracePath = resolveGithubCliTracePath(config.tracePath);
  final selection = await selectGithubCliTraceSession(
    tracePath,
    scriptFilter: config.scriptFilter,
    outPath: config.sessionOut,
  );

  final plan = await loadGithubCliReplayPlan(
    GithubCliReplayConfig(
      trace: selection.outPath,
      traceOut: config.scenarioOut,
      traceName: config.name,
      traceDescription: config.description,
      traceMinSleepUs: config.minSleepUs,
      traceScreenWidth: config.screenWidth,
      traceScreenHeight: config.screenHeight,
      traceFixedRightWidth: config.fixedRightWidth,
      blockInput: config.blockInput,
      convertOnly: true,
      speed: config.speed,
    ),
  );

  if (plan == null) {
    throw FormatException(
      'No replay actions were generated from ${selection.outPath}.',
    );
  }

  final actionCount = await _applyLeadInSleep(
    config.scenarioOut,
    config.leadInMs,
  );

  return GithubCliPreparedReplay(
    selection: selection,
    plan: plan,
    actionCount: actionCount,
  );
}

final class GithubCliReplayHarnessConfig {
  const GithubCliReplayHarnessConfig({
    required this.repository,
    required this.viewTarget,
    required this.tracePath,
    required this.scriptFilter,
    required this.sessionOut,
    required this.scenarioOut,
    required this.name,
    required this.description,
    required this.limit,
    required this.speed,
    required this.minSleepUs,
    required this.leadInMs,
    required this.screenWidth,
    required this.screenHeight,
    required this.fixedRightWidth,
    required this.blockInput,
    required this.convertOnly,
    required this.captureTrace,
    required this.traceOut,
    required this.traceTags,
    required this.captureDispatch,
    required this.summaryCount,
    required this.maxSpanUs,
    required this.timeoutSeconds,
    this.error,
  });

  final String repository;
  final GithubPullRequestTarget? viewTarget;
  final String tracePath;
  final String scriptFilter;
  final String sessionOut;
  final String scenarioOut;
  final String name;
  final String description;
  final int limit;
  final double speed;
  final int minSleepUs;
  final int leadInMs;
  final int screenWidth;
  final int screenHeight;
  final int fixedRightWidth;
  final bool blockInput;
  final bool convertOnly;
  final bool captureTrace;
  final String traceOut;
  final String traceTags;
  final bool captureDispatch;
  final int summaryCount;
  final int maxSpanUs;
  final int timeoutSeconds;
  final String? error;

  bool get usesView => viewTarget != null;

  String get targetLabel => viewTarget?.url ?? repository;

  static GithubCliReplayHarnessConfig fromArgResults(ArgResults parsed) {
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

    final summaryCount = _parseNonNegativeInt(
      parsed['summary-count'],
      '--summary-count',
    );
    if (summaryCount case (value: _, error: final error?)) {
      return _error(error);
    }

    final maxSpanUs = _parseNonNegativeInt(
      parsed['max-span-us'],
      '--max-span-us',
    );
    if (maxSpanUs case (value: _, error: final error?)) return _error(error);

    final timeoutSeconds = _parseNonNegativeInt(
      parsed['timeout-seconds'],
      '--timeout-seconds',
    );
    if (timeoutSeconds case (value: _, error: final error?)) {
      return _error(error);
    }

    return GithubCliReplayHarnessConfig(
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
      convertOnly: parsed['convert-only'] == true,
      captureTrace: parsed['capture-trace'] == true,
      traceOut: parsed['trace-out'] as String,
      traceTags: parsed['trace-tags'] as String,
      captureDispatch: parsed['capture-dispatch'] == true,
      summaryCount: summaryCount.value,
      maxSpanUs: maxSpanUs.value,
      timeoutSeconds: timeoutSeconds.value,
    );
  }

  static GithubCliReplayHarnessConfig _error(String message) {
    return GithubCliReplayHarnessConfig(
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
      captureTrace: true,
      traceOut: '',
      traceTags: '',
      captureDispatch: false,
      summaryCount: 0,
      maxSpanUs: 0,
      timeoutSeconds: 180,
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

final class GithubCliTraceSessionSelection {
  const GithubCliTraceSessionSelection({
    required this.sourcePath,
    required this.outPath,
    required this.sessionIndex,
    required this.sessionCount,
    required this.startLine,
    required this.endLine,
    required this.script,
  });

  final String sourcePath;
  final String outPath;
  final int sessionIndex;
  final int sessionCount;
  final int startLine;
  final int endLine;
  final String? script;
}

Future<GithubCliTraceSessionSelection> selectGithubCliTraceSession(
  String sourcePath, {
  required String scriptFilter,
  required String outPath,
}) async {
  final file = io.File(sourcePath);
  final lines = await file.readAsLines();
  final sessions = _splitTraceSessions(lines);
  if (sessions.isEmpty) {
    await _writeLines(outPath, lines);
    return GithubCliTraceSessionSelection(
      sourcePath: sourcePath,
      outPath: outPath,
      sessionIndex: 1,
      sessionCount: 1,
      startLine: 1,
      endLine: lines.length,
      script: null,
    );
  }

  final normalizedFilter = scriptFilter.trim();
  final selected = sessions.lastWhere(
    (session) =>
        normalizedFilter.isEmpty ||
        (session.script?.contains(normalizedFilter) ?? false),
    orElse: () => sessions.last,
  );
  await _writeLines(outPath, selected.lines);
  return GithubCliTraceSessionSelection(
    sourcePath: sourcePath,
    outPath: outPath,
    sessionIndex: selected.index,
    sessionCount: sessions.length,
    startLine: selected.startLine,
    endLine: selected.endLine,
    script: selected.script,
  );
}

final class GithubCliReplayTraceSummary {
  const GithubCliReplayTraceSummary({
    required this.path,
    required this.spanCount,
    required this.maxDurationUs,
    required this.spans,
  });

  final String path;
  final int spanCount;
  final int maxDurationUs;
  final List<GithubCliReplayTraceSpan> spans;
}

final class GithubCliReplayTraceSpan {
  const GithubCliReplayTraceSpan({
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

Future<GithubCliReplayTraceSummary> summarizeGithubCliReplayTrace(
  String path, {
  int limit = 12,
}) async {
  final file = io.File(path);
  if (!await file.exists()) {
    return GithubCliReplayTraceSummary(
      path: path,
      spanCount: 0,
      maxDurationUs: 0,
      spans: const <GithubCliReplayTraceSpan>[],
    );
  }

  final spans = <GithubCliReplayTraceSpan>[];
  final lines = await file.readAsLines();
  for (var i = 0; i < lines.length; i++) {
    final parsed = _parseTimedTraceLine(path, i + 1, lines[i]);
    if (parsed != null) spans.add(parsed);
  }
  spans.sort((a, b) => b.durationUs.compareTo(a.durationUs));
  final top = spans.take(math.max(0, limit)).toList(growable: false);
  return GithubCliReplayTraceSummary(
    path: path,
    spanCount: spans.length,
    maxDurationUs: spans.isEmpty ? 0 : spans.first.durationUs,
    spans: top,
  );
}

Future<int> _applyLeadInSleep(String scenarioPath, int leadInMs) async {
  final scenario = await tui.ReplayScenario.load(scenarioPath);
  final actions = scenario.actions.toList();
  if (leadInMs <= 0) {
    if (actions.isNotEmpty && actions.first.type == 'sleep') {
      actions.removeAt(0);
    }
  } else if (actions.isNotEmpty && actions.first.type == 'sleep') {
    actions[0] = tui.ReplayAction(type: 'sleep', ms: leadInMs);
  } else {
    actions.insert(0, tui.ReplayAction(type: 'sleep', ms: leadInMs));
  }

  await tui.ReplayScenario(
    name: scenario.name,
    description: scenario.description,
    screen: scenario.screen,
    actions: actions,
  ).save(scenarioPath);
  return actions.length;
}

GithubCliReplayTraceSpan? _parseTimedTraceLine(
  String path,
  int lineNumber,
  String line,
) {
  final durationMatch = RegExp(r' (\d+)us$').firstMatch(line);
  if (durationMatch == null) return null;
  final durationUs = int.tryParse(durationMatch.group(1)!);
  if (durationUs == null) return null;

  final tagMatch = RegExp(r'^\[\+\d+us\] \[([^\]]+)\] (.*)$').firstMatch(line);
  if (tagMatch == null) return null;
  final message = tagMatch.group(2)!;
  return GithubCliReplayTraceSpan(
    path: path,
    lineNumber: lineNumber,
    tag: tagMatch.group(1)!,
    message: message,
    durationUs: durationUs,
  );
}

List<_TraceSession> _splitTraceSessions(List<String> lines) {
  final sessions = <_TraceSession>[];
  var current = <String>[];
  var startLine = 0;

  void finish(int endLine) {
    if (current.isEmpty) return;
    sessions.add(
      _TraceSession(
        index: sessions.length + 1,
        startLine: startLine,
        endLine: endLine,
        lines: List<String>.unmodifiable(current),
      ),
    );
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

final class _TraceSession {
  const _TraceSession({
    required this.index,
    required this.startLine,
    required this.endLine,
    required this.lines,
  });

  final int index;
  final int startLine;
  final int endLine;
  final List<String> lines;

  String? get script {
    for (final line in lines) {
      if (line.startsWith('# script:')) {
        return line.substring('# script:'.length).trim();
      }
    }
    return null;
  }
}

Future<void> _writeLines(String path, List<String> lines) async {
  final file = io.File(path);
  if (!await file.parent.exists()) {
    await file.parent.create(recursive: true);
  }
  await file.writeAsString('${lines.join('\n')}\n');
}

String resolveGithubCliTracePath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    throw const io.FileSystemException('Trace path is empty');
  }

  if (_isLatestTraceAlias(trimmed)) {
    final latest = _latestTraceFileInDefaultDirs();
    if (latest != null) return latest.path;
    throw const io.FileSystemException('No trace files found', 'traces');
  }

  final candidates = <String>[
    trimmed,
    'pkgs/artisanal_widgets/example/github_cli/$trimmed',
  ];
  for (final candidate in candidates) {
    final file = io.File(candidate);
    if (file.existsSync()) return candidate;

    final directory = io.Directory(candidate);
    if (directory.existsSync()) {
      final latest = _latestTraceFile(directory);
      if (latest != null) return latest.path;
    }
  }
  throw io.FileSystemException('Trace file not found', path);
}

bool _isLatestTraceAlias(String value) =>
    value == 'latest' ||
    value == 'traces/latest' ||
    value == 'traces/latest.log';

io.File? _latestTraceFileInDefaultDirs() {
  for (final path in const <String>[
    'traces',
    'pkgs/artisanal_widgets/example/github_cli/traces',
  ]) {
    final directory = io.Directory(path);
    if (!directory.existsSync()) continue;
    final latest = _latestTraceFile(directory);
    if (latest != null) return latest;
  }
  return null;
}

io.File? _latestTraceFile(io.Directory directory) {
  io.File? latest;
  DateTime? latestModified;
  for (final entity in directory.listSync(followLinks: false)) {
    if (entity is! io.File || !entity.path.endsWith('.log')) continue;
    final modified = entity.lastModifiedSync();
    if (latestModified == null || modified.isAfter(latestModified)) {
      latest = entity;
      latestModified = modified;
    }
  }
  return latest;
}

Map<String, String> githubCliReplayEnvironment(
  GithubCliReplayHarnessConfig config,
) {
  final env = Map<String, String>.of(io.Platform.environment)
    ..remove('ARTISANAL_TUI_TRACE')
    ..remove('ARTISANAL_TUI_TRACE_CAPTURE')
    ..remove('ARTISANAL_TUI_TRACE_PATH')
    ..remove('ARTISANAL_TUI_TRACE_TAGS');

  if (!config.captureTrace) return env;

  env['ARTISANAL_TUI_TRACE'] = '1';
  env['ARTISANAL_TUI_TRACE_PATH'] = config.traceOut;
  if (config.traceTags.trim().isNotEmpty) {
    env['ARTISANAL_TUI_TRACE_TAGS'] = config.traceTags;
  }
  if (config.captureDispatch) {
    env['ARTISANAL_TUI_TRACE_CAPTURE'] = '1';
  }
  return env;
}

List<String> buildGithubCliReplayRunArgs(
  GithubCliReplayHarnessConfig config,
  String scenarioPath, {
  String? entrypoint,
}) {
  final args = <String>[
    githubCliReplayCliDartDefineArgument,
    entrypoint ?? githubCliEntrypointPath(),
  ];

  if (config.viewTarget case final viewTarget?) {
    args.add('view');
    args.addAll([
      '--replay-scenario',
      scenarioPath,
      '--replay-speed',
      config.speed.toString(),
      if (config.blockInput) '--replay-block-input',
      viewTarget.url,
    ]);
    return args;
  }

  args.addAll([
    '--replay-scenario',
    scenarioPath,
    '--replay-speed',
    config.speed.toString(),
    if (config.blockInput) '--replay-block-input',
    '--limit',
    config.limit.toString(),
    config.repository,
  ]);
  return args;
}

Future<int> waitForGithubCliHarnessProcessExit(
  io.Process process,
  int timeoutSeconds,
) async {
  if (timeoutSeconds <= 0) return process.exitCode;
  try {
    return await process.exitCode.timeout(Duration(seconds: timeoutSeconds));
  } on TimeoutException {
    process.kill();
    return 124;
  }
}

String githubCliEntrypointPath() {
  try {
    final path = io.Platform.script.toFilePath();
    if (io.File(path).existsSync()) return path;
  } catch (_) {
    // Fall through to the package-local development path.
  }
  return 'bin/github_cli.dart';
}

String _formatMicros(int micros) {
  if (micros >= 1000000) {
    return '${(micros / 1000000).toStringAsFixed(2)}s';
  }
  if (micros >= 1000) {
    return '${(micros / 1000).toStringAsFixed(1)}ms';
  }
  return '${micros}us';
}
