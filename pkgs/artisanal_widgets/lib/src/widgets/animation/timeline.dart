import 'package:artisanal/runtime.dart' show Cmd, Msg;

import 'animation_controller.dart';
import 'animation_tick.dart';
import 'curves.dart';

/// Playback direction for an [AnimationTimeline].
enum TimelineDirection { forward, reverse }

/// Builds one timeline step for a staged controller choreography.
typedef TimelineStepBuilder =
    AnimationTimelineStep Function(int index, AnimationController controller);

/// Invoked by [AnimationTimelineStep.callback].
typedef TimelineStepCallback = Cmd? Function(TimelineDirection direction);

/// Message emitted by [AnimationTimeline] delay steps.
class TimelineDelayMsg extends Msg {
  const TimelineDelayMsg(this.timelineId, this.token, this.time);

  /// Identifies which timeline scheduled this delay tick.
  final Object timelineId;

  /// Identifies the specific pending delay within the timeline.
  final Object token;

  /// The wall-clock time when the delay completed.
  final DateTime time;

  @override
  String toString() => 'TimelineDelayMsg($timelineId, $token, $time)';
}

/// Declarative step used by [AnimationTimeline].
abstract class AnimationTimelineStep {
  const AnimationTimelineStep();

  /// Optional human-readable label for diagnostics and hooks.
  String? get label;

  /// Runs an [AnimationController] toward its upper bound.
  ///
  /// When the timeline is playing in reverse, this step automatically runs
  /// the same controller back toward its lower bound.
  factory AnimationTimelineStep.forward(
    AnimationController controller, {
    String? label,
    double? from,
    double? reverseFrom,
    Curve curve,
    Curve? reverseCurve,
  }) = _ControllerForwardStep;

  /// Runs an [AnimationController] toward its lower bound.
  ///
  /// When the timeline is playing in reverse, this step automatically runs
  /// the same controller forward toward its upper bound.
  factory AnimationTimelineStep.reverse(
    AnimationController controller, {
    String? label,
    double? from,
    double? reverseFrom,
    Curve curve,
    Curve? reverseCurve,
  }) = _ControllerReverseStep;

  /// Animates [controller] to [target].
  ///
  /// If the timeline later alternates into reverse playback, [reverseTarget]
  /// is used with [AnimationController.animateBack]. When omitted, the
  /// controller's lower bound is used.
  factory AnimationTimelineStep.animateTo(
    AnimationController controller,
    double target, {
    String? label,
    double? reverseTarget,
    Duration? duration,
    Duration? reverseDuration,
    Curve curve,
    Curve? reverseCurve,
  }) = _AnimateToStep;

  /// Animates [controller] backward to [target].
  ///
  /// If the timeline later alternates into reverse playback, [forwardTarget]
  /// is used with [AnimationController.animateTo]. When omitted, the
  /// controller's upper bound is used.
  factory AnimationTimelineStep.animateBack(
    AnimationController controller,
    double target, {
    String? label,
    double? forwardTarget,
    Duration? duration,
    Duration? reverseDuration,
    Curve curve,
    Curve? reverseCurve,
  }) = _AnimateBackStep;

  /// Waits for [duration] before the next step can start.
  factory AnimationTimelineStep.delay(Duration duration, {String? label}) =
      _DelayStep;

  /// Starts multiple child steps together and waits for all of them.
  factory AnimationTimelineStep.parallel(
    List<AnimationTimelineStep> steps, {
    String? label,
  }) = _ParallelStep;

  /// Runs synchronous orchestration logic as one timeline step.
  ///
  /// The [callback] may return a [Cmd] that will be merged with the command
  /// used to start the following step when this callback completes immediately.
  factory AnimationTimelineStep.callback(
    TimelineStepCallback callback, {
    String? label,
  }) = _CallbackStep;
}

/// Small TEA-native animation sequencer built on top of [AnimationController].
///
/// Hosts typically call [start] from `handleInit`, then forward messages from
/// `handleUpdate` into [handleMessage]:
///
/// ```dart
/// late final AnimationTimeline _timeline;
///
/// @override
/// void initState() {
///   super.initState();
///   _timeline = AnimationTimeline(
///     steps: [
///       AnimationTimelineStep.forward(_fade),
///       AnimationTimelineStep.delay(const Duration(milliseconds: 80)),
///       AnimationTimelineStep.parallel([
///         AnimationTimelineStep.forward(_slide),
///         AnimationTimelineStep.forward(_scale),
///       ]),
///     ],
///     alternate: true,
///     repeat: true,
///   );
/// }
///
/// @override
/// Cmd? handleInit() => _timeline.start();
///
/// @override
/// Cmd? handleUpdate(Msg msg) => _timeline.handleMessage(msg);
/// ```
final class AnimationTimeline {
  AnimationTimeline({
    required List<AnimationTimelineStep> steps,
    this.repeat = false,
    this.alternate = false,
    this.onStepStart,
    this.onStepComplete,
    Object? id,
  }) : _steps = List<AnimationTimelineStep>.unmodifiable(steps),
       _id = id ?? Object() {
    if (_steps.isEmpty) {
      throw ArgumentError.value(steps, 'steps', 'must not be empty');
    }
  }

  factory AnimationTimeline.staggeredForward({
    required List<AnimationController> controllers,
    required Duration gap,
    bool repeat = false,
    bool alternate = false,
    Object? id,
    String Function(int index)? labelForController,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    return AnimationTimeline.staggered(
      controllers: controllers,
      gap: gap,
      repeat: repeat,
      alternate: alternate,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
      buildStep: (index, controller) => AnimationTimelineStep.forward(
        controller,
        label: labelForController?.call(index),
      ),
    );
  }

  factory AnimationTimeline.staggered({
    required List<AnimationController> controllers,
    required TimelineStepBuilder buildStep,
    Duration gap = Duration.zero,
    bool repeat = false,
    bool alternate = false,
    Object? id,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final steps = <AnimationTimelineStep>[];
    for (var index = 0; index < controllers.length; index++) {
      if (index > 0 && gap > Duration.zero) {
        steps.add(AnimationTimelineStep.delay(gap, label: 'gap-$index'));
      }
      steps.add(buildStep(index, controllers[index]));
    }

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      alternate: alternate,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds a common pulse cycle for one controller.
  ///
  /// The generated sequence is:
  /// 1. animate forward
  /// 2. optional [hold]
  /// 3. animate reverse
  /// 4. optional [rest]
  ///
  /// This is useful for breathing indicators, spotlight pulses, and repeated
  /// emphasis without hand-writing the same four-step sequence each time.
  factory AnimationTimeline.pulse({
    required AnimationController controller,
    Duration hold = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    Object? id,
    String? forwardLabel,
    String? holdLabel,
    String? reverseLabel,
    String? restLabel,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    final steps = <AnimationTimelineStep>[
      AnimationTimelineStep.forward(
        controller,
        label: forwardLabel ?? 'pulse-in',
      ),
      if (hold > Duration.zero)
        AnimationTimelineStep.delay(hold, label: holdLabel ?? 'hold'),
      AnimationTimelineStep.reverse(
        controller,
        label: reverseLabel ?? 'pulse-out',
      ),
      if (rest > Duration.zero)
        AnimationTimelineStep.delay(rest, label: restLabel ?? 'rest'),
    ];

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds a serial pulse choreography across multiple controllers.
  ///
  /// Each controller runs through:
  /// 1. animate forward
  /// 2. optional [hold]
  /// 3. animate reverse
  ///
  /// A [gap] is inserted between controllers, and an optional [rest] is
  /// inserted after the final controller before the next repeated cycle.
  factory AnimationTimeline.cascade({
    required List<AnimationController> controllers,
    Duration hold = Duration.zero,
    Duration gap = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    bool alternate = false,
    Object? id,
    String Function(int index, String phase)? labelBuilder,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final steps = <AnimationTimelineStep>[];
    for (var index = 0; index < controllers.length; index++) {
      final controller = controllers[index];
      steps.add(
        AnimationTimelineStep.forward(
          controller,
          label: labelBuilder?.call(index, 'in') ?? 'cascade-in-$index',
        ),
      );
      if (hold > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            hold,
            label: labelBuilder?.call(index, 'hold') ?? 'cascade-hold-$index',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.reverse(
          controller,
          label: labelBuilder?.call(index, 'out') ?? 'cascade-out-$index',
        ),
      );
      if (index < controllers.length - 1 && gap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            gap,
            label: labelBuilder?.call(index, 'gap') ?? 'cascade-gap-$index',
          ),
        );
      }
    }
    if (rest > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          rest,
          label:
              labelBuilder?.call(controllers.length - 1, 'rest') ??
              'cascade-rest',
        ),
      );
    }

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      alternate: alternate,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds a traveling wave across multiple controllers.
  ///
  /// The generated sequence is:
  /// 1. animate each controller forward in index order with optional [gap]
  /// 2. optional [crestHold]
  /// 3. animate each controller reverse in reverse index order with optional
  ///    [returnGap]
  /// 4. optional [rest]
  ///
  /// This is useful for marquee highlights, stepped focus sweeps, and
  /// left-to-right then right-to-left motion without manually spelling out
  /// the mirrored controller choreography.
  factory AnimationTimeline.wave({
    required List<AnimationController> controllers,
    Duration gap = Duration.zero,
    Duration crestHold = Duration.zero,
    Duration returnGap = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    Object? id,
    String Function(int index, String phase)? labelBuilder,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final steps = <AnimationTimelineStep>[];
    for (var index = 0; index < controllers.length; index++) {
      if (index > 0 && gap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            gap,
            label: labelBuilder?.call(index, 'gap') ?? 'wave-gap-$index',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.forward(
          controllers[index],
          label: labelBuilder?.call(index, 'crest-in') ?? 'wave-in-$index',
        ),
      );
    }
    if (crestHold > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          crestHold,
          label:
              labelBuilder?.call(controllers.length - 1, 'crest-hold') ??
              'wave-crest-hold',
        ),
      );
    }
    for (var offset = 0; offset < controllers.length; offset++) {
      final index = controllers.length - 1 - offset;
      if (offset > 0 && returnGap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            returnGap,
            label:
                labelBuilder?.call(index, 'return-gap') ??
                'wave-return-gap-$index',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.reverse(
          controllers[index],
          label: labelBuilder?.call(index, 'crest-out') ?? 'wave-out-$index',
        ),
      );
    }
    if (rest > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          rest,
          label: labelBuilder?.call(0, 'rest') ?? 'wave-rest',
        ),
      );
    }

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds a fan choreography with staggered entrance and synchronized exit.
  ///
  /// The generated sequence is:
  /// 1. animate each controller forward in index order with optional [gap]
  /// 2. optional [hold]
  /// 3. animate all controllers reverse together
  /// 4. optional [rest]
  ///
  /// This is useful for menu reveals, panel blooms, and stepped entrances that
  /// should collapse back out in one coordinated beat.
  factory AnimationTimeline.fan({
    required List<AnimationController> controllers,
    Duration gap = Duration.zero,
    Duration hold = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    Object? id,
    String Function(int index, String phase)? labelBuilder,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final steps = <AnimationTimelineStep>[];
    for (var index = 0; index < controllers.length; index++) {
      if (index > 0 && gap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            gap,
            label: labelBuilder?.call(index, 'gap') ?? 'fan-gap-$index',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.forward(
          controllers[index],
          label: labelBuilder?.call(index, 'in') ?? 'fan-in-$index',
        ),
      );
    }
    if (hold > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          hold,
          label:
              labelBuilder?.call(controllers.length - 1, 'hold') ?? 'fan-hold',
        ),
      );
    }
    steps.add(
      AnimationTimelineStep.parallel(
        [
          for (var index = 0; index < controllers.length; index++)
            AnimationTimelineStep.reverse(
              controllers[index],
              label: labelBuilder?.call(index, 'out') ?? 'fan-out-$index',
            ),
        ],
        label:
            labelBuilder?.call(controllers.length - 1, 'collapse') ??
            'fan-collapse',
      ),
    );
    if (rest > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          rest,
          label:
              labelBuilder?.call(controllers.length - 1, 'rest') ?? 'fan-rest',
        ),
      );
    }

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds a synchronized multi-controller pulse.
  ///
  /// The generated sequence is:
  /// 1. animate all controllers forward together
  /// 2. optional [hold]
  /// 3. animate all controllers reverse together
  /// 4. optional [rest]
  ///
  /// This is useful for breathing cards, modal emphasis, and coordinated
  /// spotlight effects that should move as one unit instead of staging a sweep.
  factory AnimationTimeline.breath({
    required List<AnimationController> controllers,
    Duration hold = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    Object? id,
    String Function(int index, String phase)? labelBuilder,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final steps = <AnimationTimelineStep>[
      AnimationTimelineStep.parallel(
        [
          for (var index = 0; index < controllers.length; index++)
            AnimationTimelineStep.forward(
              controllers[index],
              label: labelBuilder?.call(index, 'in') ?? 'breath-in-$index',
            ),
        ],
        label:
            labelBuilder?.call(controllers.length - 1, 'expand') ??
            'breath-expand',
      ),
      if (hold > Duration.zero)
        AnimationTimelineStep.delay(
          hold,
          label:
              labelBuilder?.call(controllers.length - 1, 'hold') ??
              'breath-hold',
        ),
      AnimationTimelineStep.parallel(
        [
          for (var index = 0; index < controllers.length; index++)
            AnimationTimelineStep.reverse(
              controllers[index],
              label: labelBuilder?.call(index, 'out') ?? 'breath-out-$index',
            ),
        ],
        label:
            labelBuilder?.call(controllers.length - 1, 'contract') ??
            'breath-contract',
      ),
      if (rest > Duration.zero)
        AnimationTimelineStep.delay(
          rest,
          label:
              labelBuilder?.call(controllers.length - 1, 'rest') ??
              'breath-rest',
        ),
    ];

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds a center-origin ripple across multiple controllers.
  ///
  /// Controllers are animated outward from [originIndex], alternating toward
  /// lower and higher indices as distance increases. The return sweep reverses
  /// that resolved ripple order.
  ///
  /// This is useful for spotlight ripples, centered selection emphasis, and
  /// radial-feeling text/UI motion in a linear controller list.
  factory AnimationTimeline.ripple({
    required List<AnimationController> controllers,
    int? originIndex,
    Duration gap = Duration.zero,
    Duration crestHold = Duration.zero,
    Duration returnGap = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    Object? id,
    String Function(int index, String phase)? labelBuilder,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final resolvedOrigin = originIndex ?? ((controllers.length - 1) ~/ 2);
    if (resolvedOrigin < 0 || resolvedOrigin >= controllers.length) {
      throw RangeError.range(
        resolvedOrigin,
        0,
        controllers.length - 1,
        'originIndex',
      );
    }

    final order = <int>[resolvedOrigin];
    for (var distance = 1; order.length < controllers.length; distance++) {
      final lower = resolvedOrigin - distance;
      final upper = resolvedOrigin + distance;
      if (lower >= 0) {
        order.add(lower);
      }
      if (upper < controllers.length) {
        order.add(upper);
      }
    }

    final steps = <AnimationTimelineStep>[];
    for (var position = 0; position < order.length; position++) {
      final index = order[position];
      if (position > 0 && gap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            gap,
            label: labelBuilder?.call(index, 'gap') ?? 'ripple-gap-$position',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.forward(
          controllers[index],
          label: labelBuilder?.call(index, 'in') ?? 'ripple-in-$index',
        ),
      );
    }
    if (crestHold > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          crestHold,
          label:
              labelBuilder?.call(resolvedOrigin, 'crest-hold') ??
              'ripple-crest-hold',
        ),
      );
    }
    for (var position = order.length - 1; position >= 0; position--) {
      final index = order[position];
      if (position < order.length - 1 && returnGap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            returnGap,
            label:
                labelBuilder?.call(index, 'return-gap') ??
                'ripple-return-gap-$position',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.reverse(
          controllers[index],
          label: labelBuilder?.call(index, 'out') ?? 'ripple-out-$index',
        ),
      );
    }
    if (rest > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          rest,
          label: labelBuilder?.call(resolvedOrigin, 'rest') ?? 'ripple-rest',
        ),
      );
    }

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds an edge-origin convergence across multiple controllers.
  ///
  /// Controllers are animated inward from the outer edges toward the center.
  /// The return sweep reverses that resolved order back toward the edges.
  ///
  /// This is useful for bracket-like emphasis, collapsing rails, and
  /// edge-first convergence patterns that are the spatial counterpart to
  /// [ripple]'s center-out motion.
  factory AnimationTimeline.converge({
    required List<AnimationController> controllers,
    Duration gap = Duration.zero,
    Duration crestHold = Duration.zero,
    Duration returnGap = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    Object? id,
    String Function(int index, String phase)? labelBuilder,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final order = <int>[];
    var left = 0;
    var right = controllers.length - 1;
    while (left <= right) {
      if (left == right) {
        order.add(left);
      } else {
        order.add(left);
        order.add(right);
      }
      left++;
      right--;
    }

    final steps = <AnimationTimelineStep>[];
    for (var position = 0; position < order.length; position++) {
      final index = order[position];
      if (position > 0 && gap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            gap,
            label: labelBuilder?.call(index, 'gap') ?? 'converge-gap-$position',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.forward(
          controllers[index],
          label: labelBuilder?.call(index, 'in') ?? 'converge-in-$index',
        ),
      );
    }
    if (crestHold > Duration.zero) {
      final centerIndex = order.last;
      steps.add(
        AnimationTimelineStep.delay(
          crestHold,
          label:
              labelBuilder?.call(centerIndex, 'crest-hold') ??
              'converge-crest-hold',
        ),
      );
    }
    for (var position = order.length - 1; position >= 0; position--) {
      final index = order[position];
      if (position < order.length - 1 && returnGap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            returnGap,
            label:
                labelBuilder?.call(index, 'return-gap') ??
                'converge-return-gap-$position',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.reverse(
          controllers[index],
          label: labelBuilder?.call(index, 'out') ?? 'converge-out-$index',
        ),
      );
    }
    if (rest > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(
          rest,
          label: labelBuilder?.call(order.first, 'rest') ?? 'converge-rest',
        ),
      );
    }

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  /// Builds a pairwise accordion choreography expanding from the center.
  ///
  /// Controllers are grouped into symmetric pairs around the center and each
  /// pair animates together on the outward sweep. The return sweep reverses the
  /// pair order back toward the center.
  ///
  /// This is useful for centered panel reveals, mirrored lane emphasis, and
  /// accordion-style motion where left/right counterparts should move as one.
  factory AnimationTimeline.accordion({
    required List<AnimationController> controllers,
    Duration gap = Duration.zero,
    Duration crestHold = Duration.zero,
    Duration returnGap = Duration.zero,
    Duration rest = Duration.zero,
    bool repeat = false,
    Object? id,
    String Function(int index, String phase)? labelBuilder,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepStart,
    void Function(
      int index,
      AnimationTimelineStep step,
      TimelineDirection direction,
    )?
    onStepComplete,
  }) {
    if (controllers.isEmpty) {
      throw ArgumentError.value(
        controllers,
        'controllers',
        'must not be empty',
      );
    }

    final groups = <List<int>>[];
    final centerLeft = (controllers.length - 1) ~/ 2;
    final centerRight = controllers.length ~/ 2;
    if (centerLeft == centerRight) {
      groups.add([centerLeft]);
    } else {
      groups.add([centerLeft, centerRight]);
    }
    for (
      var distance = 1;
      groups.expand((group) => group).length < controllers.length;
      distance++
    ) {
      final left = centerLeft - distance;
      final right = centerRight + distance;
      final group = <int>[];
      if (left >= 0) {
        group.add(left);
      }
      if (right < controllers.length) {
        group.add(right);
      }
      if (group.isNotEmpty) {
        groups.add(group);
      }
    }

    final steps = <AnimationTimelineStep>[];
    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      if (groupIndex > 0 && gap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(gap, label: 'accordion-gap-$groupIndex'),
        );
      }
      steps.add(
        AnimationTimelineStep.parallel([
          for (final index in group)
            AnimationTimelineStep.forward(
              controllers[index],
              label: labelBuilder?.call(index, 'in') ?? 'accordion-in-$index',
            ),
        ], label: 'accordion-expand-$groupIndex'),
      );
    }
    if (crestHold > Duration.zero) {
      steps.add(
        AnimationTimelineStep.delay(crestHold, label: 'accordion-crest-hold'),
      );
    }
    for (var groupIndex = groups.length - 1; groupIndex >= 0; groupIndex--) {
      final group = groups[groupIndex];
      if (groupIndex < groups.length - 1 && returnGap > Duration.zero) {
        steps.add(
          AnimationTimelineStep.delay(
            returnGap,
            label: 'accordion-return-gap-$groupIndex',
          ),
        );
      }
      steps.add(
        AnimationTimelineStep.parallel([
          for (final index in group)
            AnimationTimelineStep.reverse(
              controllers[index],
              label: labelBuilder?.call(index, 'out') ?? 'accordion-out-$index',
            ),
        ], label: 'accordion-collapse-$groupIndex'),
      );
    }
    if (rest > Duration.zero) {
      steps.add(AnimationTimelineStep.delay(rest, label: 'accordion-rest'));
    }

    return AnimationTimeline(
      steps: steps,
      repeat: repeat,
      id: id,
      onStepStart: onStepStart,
      onStepComplete: onStepComplete,
    );
  }

  final List<AnimationTimelineStep> _steps;
  final bool repeat;
  final bool alternate;
  final void Function(
    int index,
    AnimationTimelineStep step,
    TimelineDirection direction,
  )?
  onStepStart;
  final void Function(
    int index,
    AnimationTimelineStep step,
    TimelineDirection direction,
  )?
  onStepComplete;
  final Object _id;

  int _currentStepIndex = -1;
  int _completedCycles = 0;
  bool _isRunning = false;
  TimelineDirection _direction = TimelineDirection.forward;
  _TimelineStepRuntime? _activeStep;

  /// Stable identity used by internal [TimelineDelayMsg] instances.
  Object get id => _id;

  /// Whether the timeline currently has an active step.
  bool get isRunning => _isRunning;

  /// Zero-based index of the currently active step, or `-1` when idle.
  int get currentStepIndex => _currentStepIndex;

  /// Active step metadata, or `null` when idle.
  AnimationTimelineStep? get currentStep =>
      _currentStepIndex >= 0 && _currentStepIndex < _steps.length
      ? _steps[_currentStepIndex]
      : null;

  /// Optional label for the currently active step.
  String? get currentStepLabel => currentStep?.label;

  /// Number of completed full passes through the configured step list.
  int get completedCycles => _completedCycles;

  /// Current playback direction.
  TimelineDirection get direction => _direction;

  /// Starts playback from the first configured step.
  Cmd? start({TimelineDirection direction = TimelineDirection.forward}) {
    _direction = direction;
    _completedCycles = 0;
    _isRunning = true;
    _currentStepIndex = 0;
    _activeStep = null;
    return _startCurrentStep();
  }

  /// Stops playback without mutating the underlying controllers.
  void stop() {
    _isRunning = false;
    _currentStepIndex = -1;
    _activeStep = null;
  }

  /// Resets the timeline back to its idle state.
  void reset() {
    stop();
    _direction = TimelineDirection.forward;
    _completedCycles = 0;
  }

  /// Processes a [Msg] produced by the active timeline step.
  ///
  /// Returns a [Cmd] when the active step schedules more work or when the
  /// timeline advances into the next step.
  Cmd? handleMessage(Msg msg) {
    if (!_isRunning || _activeStep == null) {
      return null;
    }

    final next = _activeStep!.handleMessage(msg);
    if (!_activeStep!.isComplete) {
      return next;
    }

    onStepComplete?.call(
      _currentStepIndex,
      _steps[_currentStepIndex],
      _direction,
    );

    _currentStepIndex += 1;
    final advance = _startCurrentStep();
    return _mergeSequential(next, advance);
  }

  Cmd? _startCurrentStep() {
    while (_isRunning) {
      if (_currentStepIndex >= _steps.length) {
        _completedCycles += 1;
        if (!repeat) {
          stop();
          return null;
        }
        if (alternate) {
          _direction = _direction == TimelineDirection.forward
              ? TimelineDirection.reverse
              : TimelineDirection.forward;
        }
        _currentStepIndex = 0;
      }

      final runtime = _createRuntime(
        _steps[_currentStepIndex],
        _id,
        _direction,
      );
      _activeStep = runtime;
      onStepStart?.call(
        _currentStepIndex,
        _steps[_currentStepIndex],
        _direction,
      );
      final cmd = runtime.start();
      if (!runtime.isComplete) {
        return cmd;
      }

      _currentStepIndex += 1;
      if (cmd != null) {
        final after = _startCurrentStep();
        return _mergeSequential(cmd, after);
      }
    }
    return null;
  }

  static Cmd? _mergeSequential(Cmd? first, Cmd? second) {
    if (first == null) return second;
    if (second == null) return first;
    return Cmd.sequence([first, second]);
  }
}

_TimelineStepRuntime _createRuntime(
  AnimationTimelineStep step,
  Object timelineId,
  TimelineDirection direction,
) {
  return switch (step) {
    _ControllerForwardStep() => step.createRuntime(timelineId, direction),
    _ControllerReverseStep() => step.createRuntime(timelineId, direction),
    _AnimateToStep() => step.createRuntime(timelineId, direction),
    _AnimateBackStep() => step.createRuntime(timelineId, direction),
    _DelayStep() => step.createRuntime(timelineId, direction),
    _ParallelStep() => step.createRuntime(timelineId, direction),
    _CallbackStep() => step.createRuntime(timelineId, direction),
    _ => throw StateError('Unsupported timeline step: ${step.runtimeType}'),
  };
}

abstract class _TimelineStepRuntime {
  bool get isComplete;

  Cmd? start();

  Cmd? handleMessage(Msg msg);
}

final class _ControllerForwardStep extends AnimationTimelineStep {
  const _ControllerForwardStep(
    this.controller, {
    this.label,
    this.from,
    this.reverseFrom,
    this.curve = Curves.linear,
    this.reverseCurve,
  });

  final AnimationController controller;
  @override
  final String? label;
  final double? from;
  final double? reverseFrom;
  final Curve curve;
  final Curve? reverseCurve;

  _TimelineStepRuntime createRuntime(
    Object timelineId,
    TimelineDirection direction,
  ) {
    return _ControllerRuntime(
      controller,
      start: () => direction == TimelineDirection.forward
          ? controller.forward(from: from, curve: curve)
          : controller.reverse(
              from: reverseFrom ?? from,
              curve: reverseCurve ?? curve,
            ),
    );
  }
}

final class _ControllerReverseStep extends AnimationTimelineStep {
  const _ControllerReverseStep(
    this.controller, {
    this.label,
    this.from,
    this.reverseFrom,
    this.curve = Curves.linear,
    this.reverseCurve,
  });

  final AnimationController controller;
  @override
  final String? label;
  final double? from;
  final double? reverseFrom;
  final Curve curve;
  final Curve? reverseCurve;

  _TimelineStepRuntime createRuntime(
    Object timelineId,
    TimelineDirection direction,
  ) {
    return _ControllerRuntime(
      controller,
      start: () => direction == TimelineDirection.forward
          ? controller.reverse(from: from, curve: curve)
          : controller.forward(
              from: reverseFrom ?? from,
              curve: reverseCurve ?? curve,
            ),
    );
  }
}

final class _AnimateToStep extends AnimationTimelineStep {
  const _AnimateToStep(
    this.controller,
    this.target, {
    this.label,
    this.reverseTarget,
    this.duration,
    this.reverseDuration,
    this.curve = Curves.linear,
    this.reverseCurve,
  });

  final AnimationController controller;
  final double target;
  @override
  final String? label;
  final double? reverseTarget;
  final Duration? duration;
  final Duration? reverseDuration;
  final Curve curve;
  final Curve? reverseCurve;

  _TimelineStepRuntime createRuntime(
    Object timelineId,
    TimelineDirection direction,
  ) {
    return _ControllerRuntime(
      controller,
      start: () => direction == TimelineDirection.forward
          ? controller.animateTo(target, duration: duration, curve: curve)
          : controller.animateBack(
              reverseTarget ?? controller.lowerBound,
              duration: reverseDuration ?? duration,
              curve: reverseCurve ?? curve,
            ),
    );
  }
}

final class _AnimateBackStep extends AnimationTimelineStep {
  const _AnimateBackStep(
    this.controller,
    this.target, {
    this.label,
    this.forwardTarget,
    this.duration,
    this.reverseDuration,
    this.curve = Curves.linear,
    this.reverseCurve,
  });

  final AnimationController controller;
  final double target;
  @override
  final String? label;
  final double? forwardTarget;
  final Duration? duration;
  final Duration? reverseDuration;
  final Curve curve;
  final Curve? reverseCurve;

  _TimelineStepRuntime createRuntime(
    Object timelineId,
    TimelineDirection direction,
  ) {
    return _ControllerRuntime(
      controller,
      start: () => direction == TimelineDirection.forward
          ? controller.animateBack(target, duration: duration, curve: curve)
          : controller.animateTo(
              forwardTarget ?? controller.upperBound,
              duration: reverseDuration ?? duration,
              curve: reverseCurve ?? curve,
            ),
    );
  }
}

final class _DelayStep extends AnimationTimelineStep {
  const _DelayStep(this.duration, {this.label});

  final Duration duration;
  @override
  final String? label;

  _TimelineStepRuntime createRuntime(
    Object timelineId,
    TimelineDirection direction,
  ) {
    return _DelayRuntime(timelineId, duration);
  }
}

final class _ParallelStep extends AnimationTimelineStep {
  const _ParallelStep(this.steps, {this.label});

  final List<AnimationTimelineStep> steps;
  @override
  final String? label;

  _TimelineStepRuntime createRuntime(
    Object timelineId,
    TimelineDirection direction,
  ) {
    return _ParallelRuntime(
      steps
          .map((step) => _createRuntime(step, timelineId, direction))
          .toList(growable: false),
    );
  }
}

final class _CallbackStep extends AnimationTimelineStep {
  const _CallbackStep(this.callback, {this.label});

  final TimelineStepCallback callback;
  @override
  final String? label;

  _TimelineStepRuntime createRuntime(
    Object timelineId,
    TimelineDirection direction,
  ) {
    return _CallbackRuntime(() => callback(direction));
  }
}

final class _ControllerRuntime implements _TimelineStepRuntime {
  _ControllerRuntime(this.controller, {required Cmd Function() start})
    : _start = start;

  final AnimationController controller;
  final Cmd Function() _start;
  bool _isComplete = false;

  @override
  bool get isComplete => _isComplete;

  @override
  Cmd? start() => _start();

  @override
  Cmd? handleMessage(Msg msg) {
    if (_isComplete) {
      return null;
    }
    if (msg case AnimationTickMsg(
      controllerId: final id,
      time: final time,
    ) when id == controller.id) {
      final next = controller.processTick(time);
      if (!controller.isAnimating) {
        _isComplete = true;
      }
      return next;
    }
    return null;
  }
}

final class _DelayRuntime implements _TimelineStepRuntime {
  _DelayRuntime(this.timelineId, this.duration);

  final Object timelineId;
  final Duration duration;
  final Object _token = Object();
  bool _isComplete = false;

  @override
  bool get isComplete => _isComplete;

  @override
  Cmd? start() {
    if (duration <= Duration.zero) {
      _isComplete = true;
      return null;
    }
    return Cmd.tick(
      duration,
      (time) => TimelineDelayMsg(timelineId, _token, time),
    );
  }

  @override
  Cmd? handleMessage(Msg msg) {
    if (_isComplete) {
      return null;
    }
    if (msg case TimelineDelayMsg(
      timelineId: final msgTimelineId,
      token: final token,
    ) when msgTimelineId == timelineId && token == _token) {
      _isComplete = true;
    }
    return null;
  }
}

final class _ParallelRuntime implements _TimelineStepRuntime {
  _ParallelRuntime(this.children);

  final List<_TimelineStepRuntime> children;
  bool _isComplete = false;

  @override
  bool get isComplete => _isComplete;

  @override
  Cmd? start() {
    final commands = <Cmd>[];
    for (final child in children) {
      final cmd = child.start();
      if (cmd != null) {
        commands.add(cmd);
      }
    }
    _refreshCompletion();
    if (commands.isEmpty) {
      return null;
    }
    return Cmd.batch(commands);
  }

  @override
  Cmd? handleMessage(Msg msg) {
    if (_isComplete) {
      return null;
    }
    final commands = <Cmd>[];
    for (final child in children) {
      final cmd = child.handleMessage(msg);
      if (cmd != null) {
        commands.add(cmd);
      }
    }
    _refreshCompletion();
    if (commands.isEmpty) {
      return null;
    }
    return Cmd.batch(commands);
  }

  void _refreshCompletion() {
    _isComplete = children.every((child) => child.isComplete);
  }
}

final class _CallbackRuntime implements _TimelineStepRuntime {
  _CallbackRuntime(this._callback);

  final Cmd? Function() _callback;
  bool _isComplete = false;

  @override
  bool get isComplete => _isComplete;

  @override
  Cmd? start() {
    _isComplete = true;
    return _callback();
  }

  @override
  Cmd? handleMessage(Msg msg) => null;
}
