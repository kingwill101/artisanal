import 'dart:io';

import 'package:artisanal/tui.dart' as tui;

class OpenCodeReplayPlan {
  const OpenCodeReplayPlan({
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

Future<OpenCodeReplayPlan?> loadOpenCodeReplayPlanFromArgs(
  List<String> args,
) async {
  String? scenarioArg;
  String? traceArg;
  String? traceOutArg;
  String? traceName;
  String? traceDescription;
  int? traceFromUs;
  int? traceToUs;
  var traceMinSleepUs = 30000;
  var traceScreenWidth = 0;
  var traceScreenHeight = 0;
  var traceFixedRightWidth = 0;
  var traceIncludeHoverMoves = false;
  var loop = false;
  var keepOpen = false;
  var blockInput = false;
  var speed = 1.0;
  var convertOnly = false;

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

    if (arg.startsWith('--replay-trace-from-us=')) {
      traceFromUs = _parseRequiredInt(
        _requiredInlineValue(arg, '--replay-trace-from-us='),
        '--replay-trace-from-us',
      );
      continue;
    }
    if (arg == '--replay-trace-from-us') {
      traceFromUs = _parseRequiredInt(
        _requiredNextValue(args, ++i, '--replay-trace-from-us'),
        '--replay-trace-from-us',
      );
      continue;
    }

    if (arg.startsWith('--replay-trace-to-us=')) {
      traceToUs = _parseRequiredInt(
        _requiredInlineValue(arg, '--replay-trace-to-us='),
        '--replay-trace-to-us',
      );
      continue;
    }
    if (arg == '--replay-trace-to-us') {
      traceToUs = _parseRequiredInt(
        _requiredNextValue(args, ++i, '--replay-trace-to-us'),
        '--replay-trace-to-us',
      );
      continue;
    }

    if (arg.startsWith('--replay-trace-min-sleep-us=')) {
      traceMinSleepUs = _parseRequiredInt(
        _requiredInlineValue(arg, '--replay-trace-min-sleep-us='),
        '--replay-trace-min-sleep-us',
      );
      continue;
    }
    if (arg == '--replay-trace-min-sleep-us') {
      traceMinSleepUs = _parseRequiredInt(
        _requiredNextValue(args, ++i, '--replay-trace-min-sleep-us'),
        '--replay-trace-min-sleep-us',
      );
      continue;
    }

    if (arg.startsWith('--replay-trace-screen-width=')) {
      traceScreenWidth = _parseRequiredInt(
        _requiredInlineValue(arg, '--replay-trace-screen-width='),
        '--replay-trace-screen-width',
      );
      continue;
    }
    if (arg == '--replay-trace-screen-width') {
      traceScreenWidth = _parseRequiredInt(
        _requiredNextValue(args, ++i, '--replay-trace-screen-width'),
        '--replay-trace-screen-width',
      );
      continue;
    }

    if (arg.startsWith('--replay-trace-screen-height=')) {
      traceScreenHeight = _parseRequiredInt(
        _requiredInlineValue(arg, '--replay-trace-screen-height='),
        '--replay-trace-screen-height',
      );
      continue;
    }
    if (arg == '--replay-trace-screen-height') {
      traceScreenHeight = _parseRequiredInt(
        _requiredNextValue(args, ++i, '--replay-trace-screen-height'),
        '--replay-trace-screen-height',
      );
      continue;
    }

    if (arg.startsWith('--replay-trace-fixed-right-width=')) {
      traceFixedRightWidth = _parseRequiredInt(
        _requiredInlineValue(arg, '--replay-trace-fixed-right-width='),
        '--replay-trace-fixed-right-width',
      );
      continue;
    }
    if (arg == '--replay-trace-fixed-right-width') {
      traceFixedRightWidth = _parseRequiredInt(
        _requiredNextValue(args, ++i, '--replay-trace-fixed-right-width'),
        '--replay-trace-fixed-right-width',
      );
      continue;
    }

    if (arg == '--replay-trace-include-hover') {
      traceIncludeHoverMoves = true;
      continue;
    }

    if (arg == '--replay-convert-only') {
      convertOnly = true;
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
    if (arg.startsWith('--replay-speed=')) {
      speed = _parseReplaySpeed(_requiredInlineValue(arg, '--replay-speed='));
      continue;
    }
    if (arg == '--replay-speed') {
      speed = _parseReplaySpeed(
        _requiredNextValue(args, ++i, '--replay-speed'),
      );
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

  tui.ReplayScenario scenario;
  tui.ReplayTraceConversionResult? traceConversion;
  String resolvedPath;

  if (traceArg != null) {
    final resolvedTrace = _resolveTracePath(traceArg);
    traceConversion = await tui.ReplayTraceConverter.convertFile(
      resolvedTrace,
      options: tui.ReplayTraceConversionOptions(
        name: traceName,
        description: traceDescription ?? 'Generated from trace',
        screenWidth: traceScreenWidth,
        screenHeight: traceScreenHeight,
        fixedRightWidth: traceFixedRightWidth,
        fromUs: traceFromUs,
        toUs: traceToUs,
        minSleepUs: traceMinSleepUs,
        includeHoverMoves: traceIncludeHoverMoves,
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
    scenario = await tui.ReplayScenario.load(scenarioPath);
    resolvedPath = scenarioPath;
  }

  final replay = scenario.toProgramReplay(
    loop: loop,
    keepOpen: keepOpen,
    speed: speed,
  );
  final interceptor = tui.ReplayCoordinateInterceptor(
    sourceWidth: scenario.screen.width,
    sourceHeight: scenario.screen.height,
    sourceRightFixedWidth: scenario.screen.fixedRightWidth,
  );

  return OpenCodeReplayPlan(
    path: resolvedPath,
    name: scenario.name,
    actionCount: scenario.actions.length,
    loop: loop,
    keepOpen: keepOpen,
    blockInput: blockInput,
    speed: speed,
    replay: replay,
    interceptor: interceptor,
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

int _parseRequiredInt(String rawValue, String optionName) {
  final parsed = int.tryParse(rawValue.trim());
  if (parsed == null) {
    throw FormatException('Invalid $optionName value: $rawValue');
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
  addCandidate('pkgs/artisanal_widgets/example/opencode/scenarios/$trimmed');
  addCandidate('pkgs/artisanal_widgets/example/opencode/scenarios/$withJson');
  addCandidate('example/opencode/scenarios/$trimmed');
  addCandidate('example/opencode/scenarios/$withJson');

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
