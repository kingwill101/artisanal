/// Adaptive resize coalescing helpers for the TUI runtime.
///
/// {@category TUI}
library;

/// Decides how aggressively resize events should be coalesced.
///
/// This uses a lightweight adaptive heuristic instead of a fixed debounce so
/// isolated resizes stay responsive while rapid bursts get collapsed.
class ResizeCoalescer {
  /// Creates a resize coalescer.
  const ResizeCoalescer();

  /// Computes the delay to use for a resize event observed at [now].
  ResizeCoalescerState next(ResizeCoalescerState state, DateTime now) {
    final last = state.lastEventAt;
    if (last == null) {
      return ResizeCoalescerState(
        lastEventAt: now,
        burstCount: 0,
        delay: Duration.zero,
      );
    }

    final delta = now.difference(last);
    if (delta <= const Duration(milliseconds: 20)) {
      return ResizeCoalescerState(
        lastEventAt: now,
        burstCount: state.burstCount + 1,
        delay: const Duration(milliseconds: 30),
      );
    }
    if (delta <= const Duration(milliseconds: 80)) {
      return ResizeCoalescerState(
        lastEventAt: now,
        burstCount: 1,
        delay: const Duration(milliseconds: 8),
      );
    }
    return ResizeCoalescerState(
      lastEventAt: now,
      burstCount: 0,
      delay: Duration.zero,
    );
  }
}

/// One decision produced by [ResizeCoalescer.next].
class ResizeCoalescerState {
  /// Creates coalescer state.
  const ResizeCoalescerState({
    this.lastEventAt,
    this.burstCount = 0,
    this.delay = Duration.zero,
  });

  /// The timestamp of the last resize event.
  final DateTime? lastEventAt;

  /// The current burst count.
  final int burstCount;

  /// The coalescing delay to apply for the current event.
  final Duration delay;
}
