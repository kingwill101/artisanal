import 'dart:io';

import 'package:artisanal/runtime.dart' as runtime;

final class TooltipTraceReplayPlan {
  const TooltipTraceReplayPlan({
    required this.path,
    required this.name,
    required this.actionCount,
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
  final bool blockInput;
  final double speed;
  final runtime.ProgramReplay replay;
  final runtime.ProgramInterceptor interceptor;
  final bool convertOnly;
  final runtime.ReplayTraceConversionResult? traceConversion;
}

Future<TooltipTraceReplayPlan?> loadTooltipTraceReplayPlanFromArgs(
  List<String> args,
) async {
  String? scenarioArg;
  String? traceArg;
  String? traceOutArg;
  String? traceName;
  String? traceDescription;
  var loop = false;
  var keepOpen = false;
  var blockInput = false;
  var convertOnly = false;
  var speed = 1.0;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];

    if (arg.startsWith('--replay-scenario=')) {
      scenarioArg = _requiredInlineValue(arg, '--replay-scenario=');
      continue;
    }
    if (arg == '--replay-scenario') {
      scenarioArg = _requiredNextValue(args, ++i, '--replay-scenario');
      continue;
    }

    if (arg.startsWith('--replay-trace=')) {
      traceArg = _requiredInlineValue(arg, '--replay-trace=');
      continue;
    }
    if (arg == '--replay-trace') {
      traceArg = _requiredNextValue(args, ++i, '--replay-trace');
      continue;
    }

    if (arg.startsWith('--replay-trace-out=')) {
      traceOutArg = _requiredInlineValue(arg, '--replay-trace-out=');
      continue;
    }
    if (arg == '--replay-trace-out') {
      traceOutArg = _requiredNextValue(args, ++i, '--replay-trace-out');
      continue;
    }

    if (arg.startsWith('--replay-trace-name=')) {
      traceName = _requiredInlineValue(arg, '--replay-trace-name=');
      continue;
    }
    if (arg == '--replay-trace-name') {
      traceName = _requiredNextValue(args, ++i, '--replay-trace-name');
      continue;
    }

    if (arg.startsWith('--replay-trace-description=')) {
      traceDescription = _requiredInlineValue(
        arg,
        '--replay-trace-description=',
      );
      continue;
    }
    if (arg == '--replay-trace-description') {
      traceDescription = _requiredNextValue(
        args,
        ++i,
        '--replay-trace-description',
      );
      continue;
    }

    if (arg == '--replay-loop') {
      loop = true;
      continue;
    }
    if (arg == '--replay-keep-open') {
      keepOpen = true;
      continue;
    }
    if (arg == '--replay-block-input') {
      blockInput = true;
      continue;
    }
    if (arg == '--replay-convert-only') {
      convertOnly = true;
      continue;
    }
    if (arg.startsWith('--replay-speed=')) {
      speed = _parseReplaySpeed(_requiredInlineValue(arg, '--replay-speed='));
      continue;
    }
    if (arg == '--replay-speed') {
      speed = _parseReplaySpeed(_requiredNextValue(args, ++i, '--replay-speed'));
      continue;
    }
  }

  if (scenarioArg != null && traceArg != null) {
    throw const FormatException(
      'Use only one replay source: --replay-scenario or --replay-trace.',
    );
  }
  if (scenarioArg == null && traceArg == null) {
    return null;
  }
  if (convertOnly && traceArg == null) {
    throw const FormatException(
      '--replay-convert-only requires --replay-trace.',
    );
  }
  if (convertOnly && (traceOutArg == null || traceOutArg.isEmpty)) {
    throw const FormatException(
      '--replay-convert-only requires --replay-trace-out <path>.',
    );
  }

  runtime.ReplayScenario scenario;
  runtime.ReplayTraceConversionResult? traceConversion;
  String resolvedPath;

  if (traceArg != null) {
    final resolvedTrace = _resolveTracePath(traceArg);
    traceConversion = await runtime.ReplayTraceConverter.convertFile(
      resolvedTrace,
      options: runtime.ReplayTraceConversionOptions(
        name: traceName,
        description: traceDescription ?? 'Generated from tooltip trace',
        includeHoverMoves: true,
      ),
    );
    scenario = traceConversion.scenario;
    resolvedPath = resolvedTrace;
    if (traceOutArg != null && traceOutArg.isNotEmpty) {
      await scenario.save(traceOutArg);
      resolvedPath = traceOutArg;
    }
  } else {
    final scenarioPath = _resolveScenarioPath(scenarioArg!);
    scenario = await runtime.ReplayScenario.load(scenarioPath);
    resolvedPath = scenarioPath;
  }

  return TooltipTraceReplayPlan(
    path: resolvedPath,
    name: scenario.name,
    actionCount: scenario.actions.length,
    blockInput: blockInput,
    speed: speed,
    replay: scenario.toProgramReplay(
      loop: loop,
      keepOpen: keepOpen,
      speed: speed,
    ),
    interceptor: runtime.ReplayCoordinateInterceptor(
      sourceWidth: scenario.screen.width,
      sourceHeight: scenario.screen.height,
      sourceRightFixedWidth: scenario.screen.fixedRightWidth,
    ),
    convertOnly: convertOnly,
    traceConversion: traceConversion,
  );
}

double _parseReplaySpeed(String value) {
  final parsed = double.tryParse(value.trim());
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    throw FormatException('Invalid --replay-speed value: $value');
  }
  return parsed;
}

String _requiredInlineValue(String arg, String prefix) {
  final value = arg.substring(prefix.length).trim();
  if (value.isEmpty) {
    throw FormatException(
      'Missing value for ${prefix.substring(0, prefix.length - 1)}.',
    );
  }
  return value;
}

String _requiredNextValue(List<String> args, int index, String optionName) {
  if (index >= args.length) {
    throw FormatException('Missing value for $optionName.');
  }
  final value = args[index].trim();
  if (value.isEmpty) {
    throw FormatException('Missing value for $optionName.');
  }
  return value;
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
  addCandidate('pkgs/artisanal_widgets/example/tooltip_trace/scenarios/$trimmed');
  addCandidate(
    'pkgs/artisanal_widgets/example/tooltip_trace/scenarios/$withJson',
  );
  addCandidate('example/tooltip_trace/scenarios/$trimmed');
  addCandidate('example/tooltip_trace/scenarios/$withJson');

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
