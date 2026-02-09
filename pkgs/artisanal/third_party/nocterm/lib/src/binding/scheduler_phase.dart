/// Phases of the frame rendering pipeline.
///
/// The scheduler progresses through these phases in order during each frame.
/// Each phase has specific responsibilities and timing guarantees.
///
/// This mirrors Flutter's SchedulerPhase enum for consistency with Flutter patterns.
enum SchedulerPhase {
  /// No frame is being processed.
  ///
  /// This is the default state when the app is idle and waiting for events.
  idle,

  /// Transient frame callbacks are running.
  ///
  /// This phase is for animation tickers and other time-based updates.
  /// Callbacks registered with [scheduleFrameCallback] execute during this phase.
  ///
  /// This corresponds to Flutter's handleBeginFrame().
  transientCallbacks,

  /// Microtasks scheduled during [transientCallbacks] are running.
  ///
  /// After all transient callbacks complete, the event loop processes any
  /// microtasks they scheduled before proceeding to the next phase.
  midFrameMicrotasks,

  /// Persistent frame callbacks are running.
  ///
  /// This is the main rendering pipeline: build, layout, and paint.
  /// Callbacks registered with [addPersistentFrameCallback] execute here.
  ///
  /// The build, layout, and paint phases all happen during this scheduler phase.
  persistentCallbacks,

  /// Post-frame callbacks are running.
  ///
  /// These run after the frame completes and are used for cleanup tasks.
  /// Callbacks registered with [addPostFrameCallback] execute here.
  postFrameCallbacks,
}
