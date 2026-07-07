/// Deterministic storm profiles for widget harnesses.
library;

import 'dart:math' as math;

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show MouseButton;

import 'widget_tester.dart';

const _defaultStormAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

const _defaultStormSpecialKeys = <terminal_keys.KeyType>[
  terminal_keys.KeyType.enter,
  terminal_keys.KeyType.tab,
  terminal_keys.KeyType.backspace,
  terminal_keys.KeyType.delete,
  terminal_keys.KeyType.escape,
  terminal_keys.KeyType.up,
  terminal_keys.KeyType.down,
  terminal_keys.KeyType.left,
  terminal_keys.KeyType.right,
  terminal_keys.KeyType.home,
  terminal_keys.KeyType.end,
  terminal_keys.KeyType.pageUp,
  terminal_keys.KeyType.pageDown,
];

const _defaultPasteSamples = <String>[
  'alpha',
  'beta gamma',
  'line one\nline two',
  '[]{}()<>"',
];

/// Named deterministic storm families.
enum WidgetStormPattern {
  keyboardStorm,
  mouseFlood,
  mixedBurst,
  longPaste,
  rapidResize,
  resizeSweep,
  resizeOscillation,
  pathologicalResize,
  custom,
}

/// Action emitted by a [WidgetStormProfile].
enum WidgetStormAction {
  key,
  specialKey,
  paste,
  mouseMove,
  tap,
  drag,
  resize,
  pump,
}

/// One generated storm action.
final class WidgetStormStep {
  /// Creates a generated storm action.
  const WidgetStormStep({
    required this.index,
    required this.action,
    this.text,
    this.keyType,
    this.x,
    this.y,
    this.endX,
    this.endY,
    this.width,
    this.height,
    this.dragSteps,
  });

  /// Zero-based index in the generated storm.
  final int index;

  /// Action family.
  final WidgetStormAction action;

  /// Text payload for key and paste actions.
  final String? text;

  /// Special key payload.
  final terminal_keys.KeyType? keyType;

  /// Primary x coordinate for pointer actions.
  final int? x;

  /// Primary y coordinate for pointer actions.
  final int? y;

  /// Drag destination x coordinate.
  final int? endX;

  /// Drag destination y coordinate.
  final int? endY;

  /// Resize target width.
  final int? width;

  /// Resize target height.
  final int? height;

  /// Drag motion steps.
  final int? dragSteps;

  /// Converts this step into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'index': index,
      'action': action.name,
      if (text != null) 'text': text,
      if (keyType != null) 'keyType': keyType!.name,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (endX != null) 'endX': endX,
      if (endY != null) 'endY': endY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (dragSteps != null) 'dragSteps': dragSteps,
    };
  }

  @override
  String toString() {
    return switch (action) {
      WidgetStormAction.key => '#$index key "$text"',
      WidgetStormAction.specialKey => '#$index specialKey ${keyType?.name}',
      WidgetStormAction.paste => '#$index paste ${text?.length ?? 0} chars',
      WidgetStormAction.mouseMove => '#$index mouseMove $x,$y',
      WidgetStormAction.tap => '#$index tap $x,$y',
      WidgetStormAction.drag =>
        '#$index drag $x,$y -> $endX,$endY steps=$dragSteps',
      WidgetStormAction.resize => '#$index resize ${width}x$height',
      WidgetStormAction.pump => '#$index pump',
    };
  }
}

/// A deterministic, named stress profile for [WidgetTester].
final class WidgetStormProfile {
  const WidgetStormProfile._({
    required this.name,
    required this.pattern,
    this.seed = 1,
    this.count = 0,
    this.width = 80,
    this.height = 24,
    this.minWidth = 20,
    this.maxWidth = 120,
    this.minHeight = 8,
    this.maxHeight = 40,
    this.startWidth = 80,
    this.startHeight = 24,
    this.endWidth = 120,
    this.endHeight = 40,
    this.cycles = 0,
    this.sizeBytes = 0,
    this.maxDragSteps = 4,
    this.keyAlphabet = _defaultStormAlphabet,
    this.specialKeys = _defaultStormSpecialKeys,
    this.pasteSamples = _defaultPasteSamples,
    this.captureFrames = false,
    List<WidgetStormStep>? customSteps,
  }) : _customSteps = customSteps;

  /// Rapid keyboard input at an impossible typing rate.
  factory WidgetStormProfile.keyboardStorm({
    int count = 1000,
    int seed = 1,
    String keyAlphabet = _defaultStormAlphabet,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'keyboard_storm',
      pattern: WidgetStormPattern.keyboardStorm,
      seed: seed,
      count: count,
      keyAlphabet: keyAlphabet,
      captureFrames: captureFrames,
    );
  }

  /// High-frequency mouse motion over a bounded viewport.
  factory WidgetStormProfile.mouseFlood({
    int count = 1000,
    int seed = 1,
    int width = 80,
    int height = 24,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'mouse_flood',
      pattern: WidgetStormPattern.mouseFlood,
      seed: seed,
      count: count,
      width: width,
      height: height,
      captureFrames: captureFrames,
    );
  }

  /// Interleaved key, special-key, paste, mouse, drag, resize, and pump steps.
  factory WidgetStormProfile.mixedBurst({
    int count = 250,
    int seed = 1,
    int width = 80,
    int height = 24,
    int minWidth = 20,
    int maxWidth = 120,
    int minHeight = 8,
    int maxHeight = 40,
    int maxDragSteps = 4,
    String keyAlphabet = _defaultStormAlphabet,
    List<terminal_keys.KeyType> specialKeys = _defaultStormSpecialKeys,
    List<String> pasteSamples = _defaultPasteSamples,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'mixed_burst',
      pattern: WidgetStormPattern.mixedBurst,
      seed: seed,
      count: count,
      width: width,
      height: height,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      maxDragSteps: maxDragSteps,
      keyAlphabet: keyAlphabet,
      specialKeys: specialKeys,
      pasteSamples: pasteSamples,
      captureFrames: captureFrames,
    );
  }

  /// One large paste payload.
  factory WidgetStormProfile.longPaste({
    int sizeBytes = 100 * 1024,
    int seed = 1,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'long_paste',
      pattern: WidgetStormPattern.longPaste,
      seed: seed,
      sizeBytes: sizeBytes,
      captureFrames: captureFrames,
    );
  }

  /// Random resize burst within explicit bounds.
  factory WidgetStormProfile.rapidResize({
    int count = 100,
    int seed = 1,
    int minWidth = 20,
    int maxWidth = 120,
    int minHeight = 8,
    int maxHeight = 40,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'rapid_resize',
      pattern: WidgetStormPattern.rapidResize,
      seed: seed,
      count: count,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      captureFrames: captureFrames,
    );
  }

  /// Gradual viewport sweep from one size to another.
  factory WidgetStormProfile.resizeSweep({
    int startWidth = 40,
    int startHeight = 10,
    int endWidth = 120,
    int endHeight = 40,
    int steps = 12,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'resize_sweep',
      pattern: WidgetStormPattern.resizeSweep,
      count: steps,
      startWidth: startWidth,
      startHeight: startHeight,
      endWidth: endWidth,
      endHeight: endHeight,
      captureFrames: captureFrames,
    );
  }

  /// Oscillates between two viewport sizes.
  factory WidgetStormProfile.resizeOscillation({
    int widthA = 40,
    int heightA = 10,
    int widthB = 120,
    int heightB = 40,
    int cycles = 10,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'resize_oscillation',
      pattern: WidgetStormPattern.resizeOscillation,
      startWidth: widthA,
      startHeight: heightA,
      endWidth: widthB,
      endHeight: heightB,
      cycles: cycles,
      captureFrames: captureFrames,
    );
  }

  /// Repeats cramped, wide, tall, and maximum viewport edge cases.
  factory WidgetStormProfile.pathologicalResize({
    int count = 24,
    int minWidth = 1,
    int maxWidth = 200,
    int minHeight = 1,
    int maxHeight = 80,
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: 'pathological_resize',
      pattern: WidgetStormPattern.pathologicalResize,
      count: count,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      captureFrames: captureFrames,
    );
  }

  /// A caller-provided deterministic storm.
  factory WidgetStormProfile.custom(
    String name,
    List<WidgetStormStep> steps, {
    bool captureFrames = false,
  }) {
    return WidgetStormProfile._(
      name: name,
      pattern: WidgetStormPattern.custom,
      captureFrames: captureFrames,
      customSteps: List<WidgetStormStep>.unmodifiable(steps),
    );
  }

  /// Stable profile name for reports and artifacts.
  final String name;

  /// Storm family.
  final WidgetStormPattern pattern;

  /// Deterministic seed.
  final int seed;

  /// Event count for count-based profiles.
  final int count;

  /// Coordinate width used by pointer profiles.
  final int width;

  /// Coordinate height used by pointer profiles.
  final int height;

  /// Minimum generated resize width.
  final int minWidth;

  /// Maximum generated resize width.
  final int maxWidth;

  /// Minimum generated resize height.
  final int minHeight;

  /// Maximum generated resize height.
  final int maxHeight;

  /// Sweep or oscillation starting width.
  final int startWidth;

  /// Sweep or oscillation starting height.
  final int startHeight;

  /// Sweep or oscillation ending width.
  final int endWidth;

  /// Sweep or oscillation ending height.
  final int endHeight;

  /// Number of resize oscillation cycles.
  final int cycles;

  /// Paste size for [WidgetStormPattern.longPaste].
  final int sizeBytes;

  /// Maximum drag motion steps in mixed bursts.
  final int maxDragSteps;

  /// Alphabet used by key-generating profiles.
  final String keyAlphabet;

  /// Special-key corpus for mixed bursts.
  final List<terminal_keys.KeyType> specialKeys;

  /// Paste corpus for mixed bursts.
  final List<String> pasteSamples;

  /// Whether the runner should record frames during this profile.
  final bool captureFrames;

  final List<WidgetStormStep>? _customSteps;

  /// Generates the deterministic action sequence for this profile.
  List<WidgetStormStep> generate() {
    _validate();
    final rng = _StormRandom(seed);
    return switch (pattern) {
      WidgetStormPattern.keyboardStorm => _keyboardStorm(rng),
      WidgetStormPattern.mouseFlood => _mouseFlood(rng),
      WidgetStormPattern.mixedBurst => _mixedBurst(rng),
      WidgetStormPattern.longPaste => _longPaste(rng),
      WidgetStormPattern.rapidResize => _rapidResize(rng),
      WidgetStormPattern.resizeSweep => _resizeSweep(),
      WidgetStormPattern.resizeOscillation => _resizeOscillation(),
      WidgetStormPattern.pathologicalResize => _pathologicalResize(),
      WidgetStormPattern.custom => List<WidgetStormStep>.unmodifiable(
        _customSteps ?? const <WidgetStormStep>[],
      ),
    };
  }

  /// Converts this profile into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'pattern': pattern.name,
      'seed': seed,
      'count': count,
      'width': width,
      'height': height,
      'minWidth': minWidth,
      'maxWidth': maxWidth,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'startWidth': startWidth,
      'startHeight': startHeight,
      'endWidth': endWidth,
      'endHeight': endHeight,
      'cycles': cycles,
      'sizeBytes': sizeBytes,
      'captureFrames': captureFrames,
    };
  }

  List<WidgetStormStep> _keyboardStorm(_StormRandom rng) {
    return List<WidgetStormStep>.generate(count, (index) {
      return WidgetStormStep(
        index: index,
        action: WidgetStormAction.key,
        text: _nextChar(rng),
      );
    }, growable: false);
  }

  List<WidgetStormStep> _mouseFlood(_StormRandom rng) {
    return List<WidgetStormStep>.generate(count, (index) {
      return WidgetStormStep(
        index: index,
        action: WidgetStormAction.mouseMove,
        x: rng.nextInt(math.max(1, width)),
        y: rng.nextInt(math.max(1, height)),
      );
    }, growable: false);
  }

  List<WidgetStormStep> _mixedBurst(_StormRandom rng) {
    return List<WidgetStormStep>.generate(count, (index) {
      final action = rng.nextInt(8);
      return switch (action) {
        0 => WidgetStormStep(
          index: index,
          action: WidgetStormAction.key,
          text: _nextChar(rng),
        ),
        1 => WidgetStormStep(
          index: index,
          action: WidgetStormAction.specialKey,
          keyType: specialKeys[rng.nextInt(specialKeys.length)],
        ),
        2 => WidgetStormStep(
          index: index,
          action: WidgetStormAction.paste,
          text: pasteSamples[rng.nextInt(pasteSamples.length)],
        ),
        3 => WidgetStormStep(
          index: index,
          action: WidgetStormAction.mouseMove,
          x: rng.nextInt(math.max(1, width)),
          y: rng.nextInt(math.max(1, height)),
        ),
        4 => WidgetStormStep(
          index: index,
          action: WidgetStormAction.tap,
          x: rng.nextInt(math.max(1, width)),
          y: rng.nextInt(math.max(1, height)),
        ),
        5 => WidgetStormStep(
          index: index,
          action: WidgetStormAction.drag,
          x: rng.nextInt(math.max(1, width)),
          y: rng.nextInt(math.max(1, height)),
          endX: rng.nextInt(math.max(1, width)),
          endY: rng.nextInt(math.max(1, height)),
          dragSteps: 1 + rng.nextInt(math.max(1, maxDragSteps)),
        ),
        6 => WidgetStormStep(
          index: index,
          action: WidgetStormAction.resize,
          width: _nextInRange(rng, minWidth, maxWidth),
          height: _nextInRange(rng, minHeight, maxHeight),
        ),
        _ => WidgetStormStep(index: index, action: WidgetStormAction.pump),
      };
    }, growable: false);
  }

  List<WidgetStormStep> _longPaste(_StormRandom rng) {
    final buffer = StringBuffer();
    while (buffer.length < sizeBytes) {
      buffer.write(_nextChar(rng));
    }
    return <WidgetStormStep>[
      WidgetStormStep(
        index: 0,
        action: WidgetStormAction.paste,
        text: buffer.toString(),
      ),
    ];
  }

  List<WidgetStormStep> _rapidResize(_StormRandom rng) {
    return List<WidgetStormStep>.generate(count, (index) {
      return WidgetStormStep(
        index: index,
        action: WidgetStormAction.resize,
        width: _nextInRange(rng, minWidth, maxWidth),
        height: _nextInRange(rng, minHeight, maxHeight),
      );
    }, growable: false);
  }

  List<WidgetStormStep> _resizeSweep() {
    if (count <= 1) {
      return <WidgetStormStep>[
        WidgetStormStep(
          index: 0,
          action: WidgetStormAction.resize,
          width: endWidth,
          height: endHeight,
        ),
      ];
    }
    return List<WidgetStormStep>.generate(count, (index) {
      final t = index / (count - 1);
      return WidgetStormStep(
        index: index,
        action: WidgetStormAction.resize,
        width: startWidth + ((endWidth - startWidth) * t).round(),
        height: startHeight + ((endHeight - startHeight) * t).round(),
      );
    }, growable: false);
  }

  List<WidgetStormStep> _resizeOscillation() {
    return List<WidgetStormStep>.generate(cycles * 2, (index) {
      final useA = index.isEven;
      return WidgetStormStep(
        index: index,
        action: WidgetStormAction.resize,
        width: useA ? startWidth : endWidth,
        height: useA ? startHeight : endHeight,
      );
    }, growable: false);
  }

  List<WidgetStormStep> _pathologicalResize() {
    final sizes = <({int width, int height})>[
      (width: minWidth, height: minHeight),
      (width: maxWidth, height: maxHeight),
      (width: maxWidth, height: minHeight),
      (width: minWidth, height: maxHeight),
      (width: 1, height: math.max(1, maxHeight)),
      (width: math.max(1, maxWidth), height: 1),
    ];
    return List<WidgetStormStep>.generate(count, (index) {
      final size = sizes[index % sizes.length];
      return WidgetStormStep(
        index: index,
        action: WidgetStormAction.resize,
        width: size.width,
        height: size.height,
      );
    }, growable: false);
  }

  String _nextChar(_StormRandom rng) {
    final runes = keyAlphabet.runes.toList(growable: false);
    return String.fromCharCode(runes[rng.nextInt(runes.length)]);
  }

  int _nextInRange(_StormRandom rng, int min, int max) {
    return min + rng.nextInt(max - min + 1);
  }

  void _validate() {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }
    if (seed < 0) {
      throw ArgumentError.value(seed, 'seed', 'must not be negative');
    }
    if (keyAlphabet.isEmpty) {
      throw ArgumentError.value(
        keyAlphabet,
        'keyAlphabet',
        'must not be empty',
      );
    }
    if (specialKeys.isEmpty) {
      throw ArgumentError.value(
        specialKeys,
        'specialKeys',
        'must not be empty',
      );
    }
    if (pasteSamples.isEmpty) {
      throw ArgumentError.value(
        pasteSamples,
        'pasteSamples',
        'must not be empty',
      );
    }
    if (minWidth < 1 || minHeight < 1) {
      throw ArgumentError('minimum resize dimensions must be positive');
    }
    if (maxWidth < minWidth || maxHeight < minHeight) {
      throw ArgumentError('maximum resize dimensions must be >= minimums');
    }
    if (maxDragSteps < 1) {
      throw ArgumentError.value(maxDragSteps, 'maxDragSteps');
    }
    if (sizeBytes < 0) {
      throw ArgumentError.value(sizeBytes, 'sizeBytes', 'must not be negative');
    }
  }
}

/// Result from running a [WidgetStormProfile].
final class WidgetStormResult {
  const WidgetStormResult({
    required this.profile,
    required this.history,
    required this.frames,
    this.failedStep,
    this.error,
    this.stackTrace,
  });

  /// Profile that produced the storm.
  final WidgetStormProfile profile;

  /// Generated steps, including a failed step if the run failed.
  final List<WidgetStormStep> history;

  /// Frames captured when [WidgetStormProfile.captureFrames] was enabled.
  final List<WidgetTestFrame> frames;

  /// Failed step, if any.
  final WidgetStormStep? failedStep;

  /// Error thrown while applying [failedStep], if any.
  final Object? error;

  /// Stack trace captured with [error].
  final StackTrace? stackTrace;

  /// Whether the storm completed without an exception.
  bool get passed => error == null;

  /// Number of steps that completed.
  int get completedSteps => passed ? history.length : history.length - 1;

  /// Throws [WidgetStormFailure] when the run failed.
  void throwIfFailed() {
    if (passed) return;
    throw WidgetStormFailure(this);
  }

  /// Converts this result into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'profile': profile.toJson(),
      'passed': passed,
      'requestedSteps': history.length,
      'completedSteps': completedSteps,
      'failedStep': failedStep?.toJson(),
      'error': error?.toString(),
      'history': history.map((step) => step.toJson()).toList(growable: false),
      'frames': frames
          .map(
            (frame) => <String, Object?>{
              'sequence': frame.sequence,
              'pumpCount': frame.pumpCount,
              'width': frame.width,
              'height': frame.height,
              'trigger': frame.trigger,
              'lines': frame.lines,
            },
          )
          .toList(growable: false),
    };
  }
}

/// Exception wrapper for failed storm results.
final class WidgetStormFailure implements Exception {
  const WidgetStormFailure(this.result);

  /// Failed result.
  final WidgetStormResult result;

  @override
  String toString() {
    final tail = result.history.length <= 8
        ? result.history
        : result.history.sublist(result.history.length - 8);
    final recent = tail.map((step) => '  $step').join('\n');
    return 'Widget storm ${result.profile.name} failed at '
        '${result.failedStep} (completed=${result.completedSteps}/'
        '${result.history.length}): ${result.error}\n'
        'Recent steps:\n$recent';
  }
}

/// Runner that applies [WidgetStormProfile] instances to one tester.
final class WidgetStormRunner {
  /// Creates a storm runner bound to [tester].
  WidgetStormRunner(this.tester);

  /// Tester receiving generated events.
  final WidgetTester tester;

  /// Runs [profile] and returns a structured result.
  WidgetStormResult run(WidgetStormProfile profile) {
    final generated = profile.generate();
    final history = <WidgetStormStep>[];
    var frames = const <WidgetTestFrame>[];
    WidgetStormStep? failedStep;
    Object? error;
    StackTrace? stackTrace;

    if (profile.captureFrames) {
      tester.startFrameRecording(
        clearExisting: true,
        captureCurrentFrame: true,
      );
    }

    try {
      for (final step in generated) {
        history.add(step);
        _apply(step);
      }
    } catch (caughtError, caughtStackTrace) {
      failedStep = history.isEmpty ? null : history.last;
      error = caughtError;
      stackTrace = caughtStackTrace;
    } finally {
      if (profile.captureFrames) {
        frames = tester.stopFrameRecording();
      }
    }

    return WidgetStormResult(
      profile: profile,
      history: List<WidgetStormStep>.unmodifiable(history),
      frames: frames,
      failedStep: failedStep,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _apply(WidgetStormStep step) {
    switch (step.action) {
      case WidgetStormAction.key:
        tester.sendKey(step.text!);
      case WidgetStormAction.specialKey:
        tester.sendSpecialKey(step.keyType!);
      case WidgetStormAction.paste:
        tester.pasteText(step.text!);
      case WidgetStormAction.mouseMove:
        tester.mouseMove(step.x!, step.y!);
      case WidgetStormAction.tap:
        tester.tapAt(step.x!, step.y!);
      case WidgetStormAction.drag:
        tester.drag(
          step.x!,
          step.y!,
          step.endX!,
          step.endY!,
          steps: step.dragSteps!,
          button: MouseButton.left,
        );
      case WidgetStormAction.resize:
        tester.resize(step.width!, step.height!);
      case WidgetStormAction.pump:
        tester.pump();
    }
  }
}

/// Convenience extension for running deterministic storm profiles.
extension WidgetTesterStorming on WidgetTester {
  /// Runs one deterministic storm profile against this tester.
  WidgetStormResult runStorm(WidgetStormProfile profile) {
    return WidgetStormRunner(this).run(profile);
  }
}

final class _StormRandom {
  _StormRandom(int seed) : _state = seed == 0 ? 1 : seed;

  static const int _maskAll = -1;

  int _state;

  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    return _next() % max;
  }

  int _next() {
    var value = _state;
    value = (value ^ (value << 13)) & _maskAll;
    value = (value ^ (value >> 7)) & _maskAll;
    value = (value ^ (value << 17)) & _maskAll;
    _state = value == 0 ? 1 : value;
    return _state;
  }
}
