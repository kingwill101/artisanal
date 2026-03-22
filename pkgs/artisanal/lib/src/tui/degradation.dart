/// Budget-aware render degradation support for the TUI runtime.
///
/// {@category TUI}
library;

import 'evidence.dart';

/// Ordered render degradation levels used by the runtime.
///
/// The runtime starts at [full] and moves down the list when frames stay over
/// budget, then recovers toward [full] after sustained within-budget renders.
enum DegradationLevel {
  /// Full-fidelity rendering.
  full,

  /// Reduced border/detail fidelity while keeping styling.
  simpleBorders,

  /// Minimal styling while preserving layout and content.
  noStyling,

  /// Essential content only.
  essentialOnly,

  /// Skeleton or placeholder content only.
  skeleton,
}

/// Configuration for budget-aware render degradation.
class RenderBudgetOptions {
  /// Creates render budget options.
  const RenderBudgetOptions({
    this.enabled = false,
    this.frameBudget,
    this.overBudgetFrames = 3,
    this.recoveryFrames = 8,
    this.maxLevel = DegradationLevel.skeleton,
  }) : assert(overBudgetFrames >= 1),
       assert(recoveryFrames >= 1);

  /// Whether render degradation is enabled.
  final bool enabled;

  /// Optional frame budget override.
  ///
  /// When omitted, the runtime derives the budget from the configured FPS.
  final Duration? frameBudget;

  /// Consecutive over-budget frames required to increase degradation.
  final int overBudgetFrames;

  /// Consecutive within-budget frames required to reduce degradation.
  final int recoveryFrames;

  /// The maximum degradation level the runtime may apply.
  final DegradationLevel maxLevel;
}

/// The current state of a [RenderBudgetController].
class RenderBudgetState {
  /// Creates render budget state.
  const RenderBudgetState({
    required this.level,
    required this.frameBudget,
    required this.lastRenderDuration,
    required this.overBudgetStreak,
    required this.recoveryStreak,
  });

  /// The active degradation level.
  final DegradationLevel level;

  /// The frame budget being enforced.
  final Duration frameBudget;

  /// The last measured render duration.
  final Duration lastRenderDuration;

  /// The current consecutive over-budget streak.
  final int overBudgetStreak;

  /// The current consecutive recovery streak.
  final int recoveryStreak;
}

/// Tracks render budget pressure and adjusts degradation levels.
class RenderBudgetController {
  /// Creates a render budget controller.
  RenderBudgetController({required this.options, required Duration frameBudget})
    : _frameBudget = options.frameBudget ?? frameBudget;

  /// Controller configuration.
  final RenderBudgetOptions options;

  Duration _frameBudget;
  Duration _lastRenderDuration = Duration.zero;
  int _overBudgetStreak = 0;
  int _recoveryStreak = 0;
  DegradationLevel _level = DegradationLevel.full;

  /// Whether degradation is enabled.
  bool get enabled => options.enabled;

  /// The active degradation level.
  DegradationLevel get level => _level;

  /// The current controller state.
  RenderBudgetState get state => RenderBudgetState(
    level: _level,
    frameBudget: _frameBudget,
    lastRenderDuration: _lastRenderDuration,
    overBudgetStreak: _overBudgetStreak,
    recoveryStreak: _recoveryStreak,
  );

  /// Updates the frame budget used by this controller.
  void updateFrameBudget(Duration frameBudget) {
    if (options.frameBudget != null) return;
    _frameBudget = frameBudget;
  }

  /// Records one completed render and returns whether the level changed.
  bool recordFrame(Duration renderDuration) {
    _lastRenderDuration = renderDuration;

    final frameBudgetUs = _frameBudget.inMicroseconds;
    final renderDurationUs = renderDuration.inMicroseconds;
    final current = _level;

    if (!enabled) {
      _recordBudgetDecision(
        current: current,
        next: current,
        decisionResult: 'disabled',
        renderDurationUs: renderDurationUs,
        frameBudgetUs: frameBudgetUs,
      );
      return false;
    }

    if (renderDuration > _frameBudget) {
      _overBudgetStreak++;
      _recoveryStreak = 0;
      if (_overBudgetStreak < options.overBudgetFrames) {
        _recordBudgetDecision(
          current: current,
          next: current,
          decisionResult: 'hold',
          renderDurationUs: renderDurationUs,
          frameBudgetUs: frameBudgetUs,
          overBudget: true,
        );
        return false;
      }
      _overBudgetStreak = 0;
      final next = _nextLevel(_level, options.maxLevel);
      if (next == _level) {
        _recordBudgetDecision(
          current: current,
          next: current,
          decisionResult: 'hold',
          renderDurationUs: renderDurationUs,
          frameBudgetUs: frameBudgetUs,
          overBudget: true,
        );
        return false;
      }
      _level = next;
      _recordBudgetDecision(
        current: current,
        next: next,
        decisionResult: 'degrade',
        renderDurationUs: renderDurationUs,
        frameBudgetUs: frameBudgetUs,
        overBudget: true,
      );
      return true;
    }

    _recoveryStreak++;
    _overBudgetStreak = 0;
    if (_recoveryStreak < options.recoveryFrames) {
      _recordBudgetDecision(
        current: current,
        next: current,
        decisionResult: 'hold',
        renderDurationUs: renderDurationUs,
        frameBudgetUs: frameBudgetUs,
      );
      return false;
    }
    _recoveryStreak = 0;
    final next = _previousLevel(_level);
    if (next == _level) {
      _recordBudgetDecision(
        current: current,
        next: current,
        decisionResult: 'hold',
        renderDurationUs: renderDurationUs,
        frameBudgetUs: frameBudgetUs,
      );
      return false;
    }
    _level = next;
    _recordBudgetDecision(
      current: current,
      next: next,
      decisionResult: 'recover',
      renderDurationUs: renderDurationUs,
      frameBudgetUs: frameBudgetUs,
    );
    return true;
  }

  /// Resets controller state back to full-fidelity rendering.
  void reset() {
    _level = DegradationLevel.full;
    _lastRenderDuration = Duration.zero;
    _overBudgetStreak = 0;
    _recoveryStreak = 0;

    _recordBudgetDecision(
      current: DegradationLevel.full,
      next: DegradationLevel.full,
      decisionResult: 'reset',
      renderDurationUs: _lastRenderDuration.inMicroseconds,
      frameBudgetUs: _frameBudget.inMicroseconds,
    );
  }

  void _recordBudgetDecision({
    required DegradationLevel current,
    required DegradationLevel next,
    required String decisionResult,
    required int renderDurationUs,
    required int frameBudgetUs,
    bool overBudget = false,
  }) {
    TuiEvidence.logDecision(
      decisionType: 'render_budget',
      result: decisionResult,
      factors: <String, Object?>{
        'frameBudgetUs': frameBudgetUs,
        'renderDurationUs': renderDurationUs,
        'overBudgetStreak': _overBudgetStreak,
        'recoveryStreak': _recoveryStreak,
        'beforeLevel': current.name,
        'afterLevel': next.name,
        'enabled': options.enabled,
        'maxLevel': options.maxLevel.name,
        'overBudget': overBudget,
      },
    );
  }
}

/// Opt-in degraded content stages for a [View].
class ViewDegradation {
  /// Creates degraded view content stages.
  const ViewDegradation({
    this.simpleBordersContent,
    this.noStylingContent,
    this.essentialContent,
    this.skeletonContent,
  });

  /// The content to use at [DegradationLevel.simpleBorders].
  final String? simpleBordersContent;

  /// The content to use at [DegradationLevel.noStyling].
  final String? noStylingContent;

  /// The content to use at [DegradationLevel.essentialOnly].
  final String? essentialContent;

  /// The content to use at [DegradationLevel.skeleton].
  final String? skeletonContent;

  /// Resolves content for [level], falling back toward fuller stages when a
  /// more degraded stage is not provided.
  String resolve(String fullContent, DegradationLevel level) {
    return switch (level) {
      DegradationLevel.full => fullContent,
      DegradationLevel.simpleBorders => simpleBordersContent ?? fullContent,
      DegradationLevel.noStyling =>
        noStylingContent ?? simpleBordersContent ?? fullContent,
      DegradationLevel.essentialOnly =>
        essentialContent ??
            noStylingContent ??
            simpleBordersContent ??
            fullContent,
      DegradationLevel.skeleton =>
        skeletonContent ??
            essentialContent ??
            noStylingContent ??
            simpleBordersContent ??
            fullContent,
    };
  }
}

DegradationLevel _nextLevel(DegradationLevel current, DegradationLevel max) {
  final nextIndex = current.index + 1;
  if (nextIndex > max.index || nextIndex >= DegradationLevel.values.length) {
    return current;
  }
  return DegradationLevel.values[nextIndex];
}

DegradationLevel _previousLevel(DegradationLevel current) {
  if (current == DegradationLevel.full) return current;
  return DegradationLevel.values[current.index - 1];
}
