import 'package:artisanal/tui.dart' show Msg;

/// Message delivered on each animation frame tick.
///
/// Carries the controller's identity and the wall-clock time of the tick,
/// allowing the controller to compute elapsed duration.
///
/// This message flows through the TEA loop: the animation controller schedules
/// a [Cmd.tick] that produces an [AnimationTickMsg], which is then dispatched
/// via [State.handleUpdate] (or [AnimationMixin]) back to the controller's
/// [AnimationController.processTick] method.
class AnimationTickMsg extends Msg {
  const AnimationTickMsg(this.controllerId, this.time);

  /// Identifies which [AnimationController] this tick belongs to.
  ///
  /// Each controller has a unique [id], and when an [AnimationTickMsg] arrives
  /// in [handleUpdate], we match [controllerId] against the controller's [id]
  /// to dispatch the tick to the correct controller.
  final Object controllerId;

  /// The wall-clock time when this tick was generated.
  ///
  /// Used by [AnimationController.processTick] to compute the elapsed duration
  /// since the animation started, which in turn determines the current
  /// animation value.
  final DateTime time;

  @override
  String toString() => 'AnimationTickMsg($controllerId, $time)';
}
