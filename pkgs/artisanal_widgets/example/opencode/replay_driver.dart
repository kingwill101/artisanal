import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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
}

Future<OpenCodeReplayPlan?> loadOpenCodeReplayPlanFromArgs(
  List<String> args,
) async {
  String? scenarioArg;
  var loop = false;
  var keepOpen = false;
  var blockInput = false;
  var speed = 1.0;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];

    if (arg.startsWith('--replay-scenario=')) {
      final value = arg.substring('--replay-scenario='.length).trim();
      if (value.isEmpty) {
        throw const FormatException('Missing value for --replay-scenario.');
      }
      scenarioArg = value;
      continue;
    }

    if (arg == '--replay-scenario') {
      if (i + 1 >= args.length) {
        throw const FormatException('Missing value for --replay-scenario.');
      }
      scenarioArg = args[++i].trim();
      if (scenarioArg.isEmpty) {
        throw const FormatException('Missing value for --replay-scenario.');
      }
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
      final value = arg.substring('--replay-speed='.length).trim();
      speed = _parseReplaySpeed(value);
      continue;
    }

    if (arg == '--replay-speed') {
      if (i + 1 >= args.length) {
        throw const FormatException('Missing value for --replay-speed.');
      }
      speed = _parseReplaySpeed(args[++i].trim());
      continue;
    }
  }

  if (scenarioArg == null) return null;

  final scenarioPath = _resolveScenarioPath(scenarioArg);
  final scenario = await _ReplayScenario.load(scenarioPath);
  final interceptor = _ReplayCoordinateInterceptor(
    sourceWidth: scenario.screenWidth,
    sourceHeight: scenario.screenHeight,
    sourceRightFixedWidth: scenario.screenFixedRightWidth,
  );
  final replay = tui.ProgramReplay.stream(
    _scenarioStream(
      scenario.actions,
      loop: loop,
      keepOpen: keepOpen,
      speed: speed,
    ),
  );

  return OpenCodeReplayPlan(
    path: scenarioPath,
    name: scenario.name,
    actionCount: scenario.actions.length,
    loop: loop,
    keepOpen: keepOpen,
    blockInput: blockInput,
    speed: speed,
    replay: replay,
    interceptor: interceptor,
  );
}

double _parseReplaySpeed(String value) {
  final parsed = double.tryParse(value);
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    throw FormatException('Invalid --replay-speed value: $value');
  }
  return parsed;
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

Stream<tui.Msg> _scenarioStream(
  List<_ReplayAction> actions, {
  required bool loop,
  required bool keepOpen,
  required double speed,
}) async* {
  if (actions.isEmpty) {
    if (!keepOpen && !loop) yield const tui.QuitMsg();
    return;
  }

  Duration pendingDelay = Duration.zero;

  Duration scaled(Duration input) {
    final micros = (input.inMicroseconds / speed).round();
    return Duration(microseconds: math.max(0, micros));
  }

  do {
    for (final action in actions) {
      if (action.type == 'sleep') {
        pendingDelay += scaled(Duration(milliseconds: action.ms));
        continue;
      }

      final events = action.toMessages();
      for (final msg in events) {
        if (pendingDelay > Duration.zero) {
          await Future<void>.delayed(pendingDelay);
          pendingDelay = Duration.zero;
        }
        yield msg;
      }
    }

    if (pendingDelay > Duration.zero) {
      await Future<void>.delayed(pendingDelay);
      pendingDelay = Duration.zero;
    }
  } while (loop);

  if (!keepOpen) {
    yield const tui.QuitMsg();
  }
}

class _ReplayScenario {
  _ReplayScenario({
    required this.name,
    required this.actions,
    required this.screenWidth,
    required this.screenHeight,
    required this.screenFixedRightWidth,
  });

  final String name;
  final List<_ReplayAction> actions;
  final int screenWidth;
  final int screenHeight;
  final int screenFixedRightWidth;

  static Future<_ReplayScenario> load(String path) async {
    final raw =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    final screenRaw = raw['screen'];
    final screen = screenRaw is Map<String, dynamic>
        ? screenRaw
        : screenRaw is Map
        ? Map<String, dynamic>.from(screenRaw.cast<String, dynamic>())
        : const <String, dynamic>{};
    final actionsRaw = (raw['actions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()),
        )
        .toList(growable: false);
    final actions = actionsRaw
        .map(_ReplayAction.fromJson)
        .toList(growable: false);
    return _ReplayScenario(
      name: (raw['name'] as String?) ?? path,
      actions: actions,
      screenWidth: (screen['width'] as int?) ?? 0,
      screenHeight: (screen['height'] as int?) ?? 0,
      screenFixedRightWidth:
          (screen['fixedRightWidth'] as int?) ??
          (screen['rightFixedWidth'] as int?) ??
          0,
    );
  }
}

class _ReplayAction {
  _ReplayAction({
    required this.type,
    this.repeat = 1,
    this.ms = 0,
    this.value = '',
    this.key = '',
    this.direction = 'down',
    this.x = 0,
    this.y = 0,
    this.x2 = 0,
    this.y2 = 0,
    this.steps = 8,
  });

  final String type;
  final int repeat;
  final int ms;
  final String value;
  final String key;
  final String direction;
  final int x;
  final int y;
  final int x2;
  final int y2;
  final int steps;

  factory _ReplayAction.fromJson(Map<String, dynamic> json) {
    return _ReplayAction(
      type: (json['type'] as String? ?? '').trim(),
      repeat: (json['repeat'] as int?) ?? 1,
      ms: (json['ms'] as int?) ?? 0,
      value: (json['value'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      direction: (json['direction'] as String?) ?? 'down',
      x: (json['x'] as int?) ?? 0,
      y: (json['y'] as int?) ?? 0,
      x2: (json['x2'] as int?) ?? (json['x'] as int?) ?? 0,
      y2: (json['y2'] as int?) ?? (json['y'] as int?) ?? 0,
      steps: (json['steps'] as int?) ?? 8,
    );
  }

  List<tui.Msg> toMessages() {
    final times = math.max(1, repeat);
    final output = <tui.Msg>[];
    switch (type) {
      case 'text':
        for (var r = 0; r < times; r++) {
          for (final rune in value.runes) {
            output.add(tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [rune])));
          }
        }
        return output;
      case 'special':
        final parsed = _parseKeyType(key);
        for (var i = 0; i < times; i++) {
          output.add(tui.KeyMsg(tui.Key(parsed)));
        }
        return output;
      case 'wheel':
        final button = _parseWheelButton(direction);
        for (var i = 0; i < times; i++) {
          output.add(
            _ReplayMouseMsg(
              action: tui.MouseAction.wheel,
              button: button,
              x: x,
              y: y,
            ),
          );
        }
        return output;
      case 'tap':
        for (var i = 0; i < times; i++) {
          output.add(
            _ReplayMouseMsg(
              action: tui.MouseAction.press,
              button: tui.MouseButton.left,
              x: x,
              y: y,
            ),
          );
          output.add(
            _ReplayMouseMsg(
              action: tui.MouseAction.release,
              button: tui.MouseButton.left,
              x: x,
              y: y,
            ),
          );
        }
        return output;
      case 'move':
        for (var i = 0; i < times; i++) {
          output.add(
            _ReplayMouseMsg(
              action: tui.MouseAction.motion,
              button: tui.MouseButton.none,
              x: x,
              y: y,
            ),
          );
        }
        return output;
      case 'drag':
        final dragSteps = math.max(1, steps);
        for (var r = 0; r < times; r++) {
          output.add(
            _ReplayMouseMsg(
              action: tui.MouseAction.press,
              button: tui.MouseButton.left,
              x: x,
              y: y,
            ),
          );
          for (var i = 1; i <= dragSteps; i++) {
            final t = i / dragSteps;
            output.add(
              _ReplayMouseMsg(
                action: tui.MouseAction.motion,
                button: tui.MouseButton.left,
                x: x + ((x2 - x) * t).round(),
                y: y + ((y2 - y) * t).round(),
              ),
            );
          }
          output.add(
            _ReplayMouseMsg(
              action: tui.MouseAction.release,
              button: tui.MouseButton.left,
              x: x2,
              y: y2,
            ),
          );
        }
        return output;
      default:
        return const <tui.Msg>[];
    }
  }
}

final class _ReplayMouseMsg extends tui.Msg {
  const _ReplayMouseMsg({
    required this.action,
    required this.button,
    required this.x,
    required this.y,
  });

  final tui.MouseAction action;
  final tui.MouseButton button;
  final int x;
  final int y;
}

final class _ReplayCoordinateInterceptor extends tui.ProgramInterceptor {
  _ReplayCoordinateInterceptor({
    required this.sourceWidth,
    required this.sourceHeight,
    this.sourceRightFixedWidth = 0,
  });

  final int sourceWidth;
  final int sourceHeight;
  final int sourceRightFixedWidth;

  int? _targetWidth;
  int? _targetHeight;

  @override
  tui.Msg? onSend(tui.Msg msg) {
    if (msg is! _ReplayMouseMsg) return msg;

    final targetWidth = _targetWidth;
    final targetHeight = _targetHeight;
    final scaledX = sourceWidth > 0 && targetWidth != null && targetWidth > 0
        ? _scaleXCoordinate(msg.x, sourceWidth, targetWidth)
        : msg.x;
    final scaledY = sourceHeight > 0 && targetHeight != null && targetHeight > 0
        ? _scaleCoordinate(msg.y, sourceHeight, targetHeight)
        : msg.y;

    return tui.MouseMsg(
      action: msg.action,
      button: msg.button,
      x: scaledX,
      y: scaledY,
    );
  }

  int _scaleXCoordinate(int value, int sourceExtent, int targetExtent) {
    final fixedRight = sourceRightFixedWidth;
    if (fixedRight <= 0 ||
        fixedRight >= sourceExtent ||
        fixedRight >= targetExtent) {
      return _scaleCoordinate(value, sourceExtent, targetExtent);
    }

    final sourceFlexibleExtent = sourceExtent - fixedRight;
    final targetFlexibleExtent = targetExtent - fixedRight;
    if (sourceFlexibleExtent <= 0 || targetFlexibleExtent <= 0) {
      return _scaleCoordinate(value, sourceExtent, targetExtent);
    }

    if (value < sourceFlexibleExtent) {
      return _scaleCoordinate(
        value,
        sourceFlexibleExtent,
        targetFlexibleExtent,
      );
    }

    final rightOffset = value - sourceFlexibleExtent;
    final anchored = targetFlexibleExtent + rightOffset;
    return anchored.clamp(0, targetExtent - 1);
  }

  @override
  void onProcessed(tui.Msg msg, Duration elapsed) {
    if (msg is tui.WindowSizeMsg) {
      _targetWidth = msg.width;
      _targetHeight = msg.height;
    }
  }

  int _scaleCoordinate(int value, int sourceExtent, int targetExtent) {
    if (targetExtent <= 0 || sourceExtent <= 0) return value;
    if (sourceExtent == targetExtent) return value.clamp(0, targetExtent - 1);
    if (sourceExtent == 1) return 0;

    final scaled = (value * (targetExtent - 1) / (sourceExtent - 1)).round();
    return scaled.clamp(0, targetExtent - 1);
  }
}

tui.KeyType _parseKeyType(String key) {
  final normalized = key.trim();
  return switch (normalized) {
    'enter' => tui.KeyType.enter,
    'tab' => tui.KeyType.tab,
    'backspace' => tui.KeyType.backspace,
    'delete' => tui.KeyType.delete,
    'escape' => tui.KeyType.escape,
    'space' => tui.KeyType.space,
    'up' => tui.KeyType.up,
    'down' => tui.KeyType.down,
    'left' => tui.KeyType.left,
    'right' => tui.KeyType.right,
    'home' => tui.KeyType.home,
    'end' => tui.KeyType.end,
    'pageUp' => tui.KeyType.pageUp,
    'pageDown' => tui.KeyType.pageDown,
    _ => throw FormatException('Unsupported special key: $key'),
  };
}

tui.MouseButton _parseWheelButton(String direction) {
  final normalized = direction.trim();
  return switch (normalized) {
    'up' => tui.MouseButton.wheelUp,
    'down' => tui.MouseButton.wheelDown,
    'left' => tui.MouseButton.wheelLeft,
    'right' => tui.MouseButton.wheelRight,
    _ => throw FormatException('Unsupported wheel direction: $direction'),
  };
}
