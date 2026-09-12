import 'dart:convert';
import 'dart:io';

import 'package:artisanal/tui.dart' as tui;

import 'generated/builtin_assets.dart';

/// The command-line options understood by the OpenCode app.
///
/// Keeping this model next to replay parsing makes the executable and replay
/// loader agree on which arguments are valid.
class OpenCodeCliOptions {
  const OpenCodeCliOptions({this.theme, this.help = false});

  final String? theme;
  final bool help;
}

/// Parses and validates OpenCode command-line arguments.
///
/// Values may be supplied either as `--option value` or `--option=value`.
/// Unknown options, positional arguments, missing values, and malformed
/// numeric values are rejected with a [FormatException].
OpenCodeCliOptions parseOpenCodeCliOptions(List<String> args) {
  String? theme;
  var help = false;

  const valueOptions = <String>{
    '--theme',
    '--replay-scenario',
    '--replay-trace',
    '--replay-trace-out',
    '--replay-trace-name',
    '--replay-trace-description',
    '--replay-trace-from-us',
    '--replay-trace-to-us',
    '--replay-trace-min-sleep-us',
    '--replay-trace-screen-width',
    '--replay-trace-screen-height',
    '--replay-trace-fixed-right-width',
    '--replay-speed',
  };
  const flags = <String>{
    '--help',
    '--replay-trace-include-hover',
    '--replay-convert-only',
    '--replay-loop',
    '--replay-keep-open',
    '--replay-block-input',
  };

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (flags.contains(arg)) {
      help = help || arg == '--help';
      continue;
    }

    final equals = arg.indexOf('=');
    final name = equals == -1 ? arg : arg.substring(0, equals);
    if (!valueOptions.contains(name)) {
      throw FormatException('Unknown or malformed option: $arg');
    }

    final value = equals == -1
        ? (i + 1 < args.length ? args[++i] : null)
        : arg.substring(equals + 1);
    if (value == null || value.trim().isEmpty || value.startsWith('--')) {
      throw FormatException('Missing value for $name.');
    }
    if (name == '--theme') {
      theme = value.trim();
    } else if (name == '--replay-speed') {
      final parsed = double.tryParse(value.trim());
      if (parsed == null || !parsed.isFinite || parsed <= 0) {
        throw FormatException('Invalid --replay-speed value: $value');
      }
    } else if (name != '--replay-scenario' &&
        name != '--replay-trace' &&
        name != '--replay-trace-out' &&
        name != '--replay-trace-name' &&
        name != '--replay-trace-description') {
      if (int.tryParse(value.trim()) == null) {
        throw FormatException('Invalid $name value: $value');
      }
    }
  }

  return OpenCodeCliOptions(theme: theme, help: help);
}

/// Usage text describing the accepted options.
String get openCodeUsage => '''
OpenCode usage:
  --theme <name>
  --replay-scenario <name|path>
  --replay-trace <path>
  --replay-trace-out <path>
  --replay-trace-name <name>
  --replay-trace-description <text>
  --replay-trace-from-us <microseconds>
  --replay-trace-to-us <microseconds>
  --replay-trace-min-sleep-us <microseconds> (default: 30000)
  --replay-trace-screen-width <columns>
  --replay-trace-screen-height <rows>
  --replay-trace-fixed-right-width <columns>
  --replay-trace-include-hover
  --replay-convert-only
  --replay-speed <factor> (default: 1.0)
  --replay-loop
  --replay-keep-open
  --replay-block-input
  --help
''';

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
  parseOpenCodeCliOptions(args);
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
    final resolved = await _resolveScenario(scenarioArg!);
    if (resolved.path != null) {
      scenario = await tui.ReplayScenario.load(resolved.path!);
      resolvedPath = resolved.path!;
    } else {
      scenario = tui.ReplayScenario.fromJson(
        jsonDecode(resolved.source!) as Map<String, dynamic>,
        fallbackName: scenarioArg,
      );
      resolvedPath = 'builtin:${_scenarioName(scenarioArg)}';
    }
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

Future<({String? path, String? source})> _resolveScenario(
  String scenarioArg,
) async {
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
  addCandidate('apps/opencode/scenarios/$trimmed');
  addCandidate('apps/opencode/scenarios/$withJson');
  addCandidate('scenarios/$trimmed');
  addCandidate('scenarios/$withJson');

  for (final candidate in candidates) {
    if (await File(candidate).exists()) return (path: candidate, source: null);
  }

  final source = openCodeBuiltinAssets['scenarios/${_scenarioName(trimmed)}'];
  if (source != null) return (path: null, source: source);
  throw FileSystemException('Replay scenario file not found', scenarioArg);
}

String _scenarioName(String value) {
  final trimmed = value.trim();
  return trimmed.endsWith('.json')
      ? trimmed.substring(0, trimmed.length - '.json'.length)
      : trimmed;
}

String _resolveTracePath(String traceArg) {
  final trimmed = traceArg.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Missing value for --replay-trace.');
  }
  if (File(trimmed).existsSync()) return trimmed;
  throw FileSystemException('Replay trace file not found', traceArg);
}
