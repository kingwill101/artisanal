/// Gesture recognizer base class and gesture arena for conflict resolution.
///
/// Provides the abstract [GestureRecognizer] base that concrete recognizers
/// (tap, double-tap, long-press, drag) extend, plus [GestureArenaManager]
/// for resolving conflicts when multiple recognizers compete for the same
/// pointer sequence.
library;

import 'package:artisanal/runtime.dart' show Cmd, MouseMsg;

import '../layout/geometry.dart' show Offset;

// ---------------------------------------------------------------------------
// State enums
// ---------------------------------------------------------------------------

/// The lifecycle state of a gesture recognizer.
enum GestureRecognizerState {
  /// Ready to accept a new pointer sequence.
  ready,

  /// A pointer sequence is in progress; the recognizer hasn't decided yet.
  possible,

  /// The recognizer has been accepted and is actively tracking.
  accepted,

  /// The recognizer has finished (accepted or rejected) and needs reset.
  defunct,
}

/// The final disposition of a recognizer in the arena.
enum GestureDisposition {
  /// The recognizer won the arena and should handle the gesture.
  accepted,

  /// The recognizer lost the arena and should clean up.
  rejected,
}

// ---------------------------------------------------------------------------
// GestureRecognizer base
// ---------------------------------------------------------------------------

/// Abstract base class for all gesture recognizers.
///
/// A recognizer receives pointer events and decides whether the sequence
/// matches its gesture. It participates in a [GestureArenaManager] to
/// resolve conflicts with other recognizers.
///
/// Recognizer callbacks return `Cmd?` to fit the TEA architecture.
/// The [pendingCmds] list collects all commands produced during a pointer
/// event so the owning widget can batch them.
abstract class GestureRecognizer {
  /// Current lifecycle state.
  GestureRecognizerState state = GestureRecognizerState.ready;

  /// Position where the pointer first went down.
  Offset? initialPosition;

  /// Commands accumulated from callbacks during the current event.
  final List<Cmd> pendingCmds = [];

  /// The arena this recognizer belongs to, if any.
  GestureArenaManager? _arena;

  /// The arena key for this recognizer (assigned by the arena).
  int? _arenaKey;

  /// Adds a command to [pendingCmds] if non-null.
  void addCmd(Cmd? cmd) {
    if (cmd != null) pendingCmds.add(cmd);
  }

  /// Called when a pointer-down event occurs.
  void handlePointerDown(MouseMsg event, Offset localPosition) {
    initialPosition = localPosition;
    state = GestureRecognizerState.possible;
  }

  /// Called when a pointer-up event occurs.
  void handlePointerUp(MouseMsg event, Offset localPosition);

  /// Called when a pointer-move event occurs.
  void handlePointerMove(MouseMsg event, Offset localPosition);

  /// Called when this recognizer wins the arena.
  void acceptGesture();

  /// Called when this recognizer loses the arena.
  void rejectGesture();

  /// Requests acceptance or rejection from the arena.
  void resolve(GestureDisposition disposition) {
    if (_arena != null && _arenaKey != null) {
      _arena!.resolve(_arenaKey!, this, disposition);
    } else {
      // No arena — auto-accept.
      if (disposition == GestureDisposition.accepted) {
        acceptGesture();
      } else {
        rejectGesture();
      }
    }
  }

  /// Resets the recognizer to [GestureRecognizerState.ready].
  void reset() {
    state = GestureRecognizerState.ready;
    initialPosition = null;
    pendingCmds.clear();
  }

  /// Cleans up resources. Called when the recognizer is no longer needed.
  void dispose() {
    reset();
  }
}

// ---------------------------------------------------------------------------
// GestureArenaManager
// ---------------------------------------------------------------------------

/// Manages gesture arenas for conflict resolution.
///
/// When multiple recognizers compete for the same pointer sequence,
/// the arena resolves which one wins. The first recognizer to claim
/// acceptance wins; all others are rejected.
///
/// Each arena is identified by an integer key (typically derived from
/// a pointer ID or a monotonic counter).
class GestureArenaManager {
  final Map<int, _GestureArena> _arenas = {};
  int _nextKey = 0;

  /// Creates a new arena and returns its key.
  int createArena() {
    final key = _nextKey++;
    _arenas[key] = _GestureArena();
    return key;
  }

  /// Adds a [recognizer] to the arena identified by [arenaKey].
  void add(int arenaKey, GestureRecognizer recognizer) {
    final arena = _arenas[arenaKey];
    if (arena == null) return;
    arena.members.add(recognizer);
    recognizer._arena = this;
    recognizer._arenaKey = arenaKey;
  }

  /// A member resolves with a given [disposition].
  ///
  /// If [disposition] is [GestureDisposition.accepted], the member wins
  /// and all other members are rejected. If all members reject, the arena
  /// is closed.
  void resolve(
    int arenaKey,
    GestureRecognizer member,
    GestureDisposition disposition,
  ) {
    final arena = _arenas[arenaKey];
    if (arena == null) return;

    if (disposition == GestureDisposition.accepted) {
      // This member wins — accept it, reject everyone else.
      for (final other in arena.members) {
        if (other != member) {
          other.rejectGesture();
        }
      }
      member.acceptGesture();
      _arenas.remove(arenaKey);
    } else {
      // Member rejects itself — remove it from the arena.
      arena.members.remove(member);
      member.rejectGesture();

      // If only one member remains, it wins by default.
      if (arena.members.length == 1) {
        arena.members.first.acceptGesture();
        _arenas.remove(arenaKey);
      } else if (arena.members.isEmpty) {
        _arenas.remove(arenaKey);
      }
    }
  }

  /// Closes an arena. The first member in [GestureRecognizerState.possible]
  /// or [GestureRecognizerState.accepted] wins; all others are rejected.
  void close(int arenaKey) {
    final arena = _arenas[arenaKey];
    if (arena == null) return;

    GestureRecognizer? winner;
    for (final member in arena.members) {
      if (member.state == GestureRecognizerState.possible ||
          member.state == GestureRecognizerState.accepted) {
        winner = member;
        break;
      }
    }

    if (winner != null) {
      for (final other in arena.members) {
        if (other != winner) {
          other.rejectGesture();
        }
      }
      winner.acceptGesture();
    } else {
      // No possible winners — reject everyone.
      for (final member in arena.members) {
        member.rejectGesture();
      }
    }

    _arenas.remove(arenaKey);
  }

  /// Alias for [close].
  void sweep(int arenaKey) => close(arenaKey);

  /// Whether the manager has any active arenas.
  bool get hasActiveArenas => _arenas.isNotEmpty;

  /// Disposes all arenas and their members.
  void dispose() {
    for (final arena in _arenas.values) {
      for (final member in arena.members) {
        member.rejectGesture();
      }
    }
    _arenas.clear();
  }
}

/// Internal arena tracking structure.
class _GestureArena {
  final List<GestureRecognizer> members = [];
}
