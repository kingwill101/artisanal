import '../keyboard/mouse_event.dart';
import '../framework/framework.dart';

/// The possible states of a [GestureRecognizer].
enum GestureRecognizerState {
  /// The recognizer is ready to start recognizing a gesture.
  ready,

  /// The recognizer is actively tracking a potential gesture.
  possible,

  /// The recognizer has determined that the gesture it is tracking cannot occur.
  defunct,
}

/// Base class for gesture recognizers.
///
/// A gesture recognizer tracks pointer events and determines when they
/// constitute a gesture. It can compete with other gesture recognizers
/// through the gesture arena.
abstract class GestureRecognizer {
  GestureRecognizer();

  GestureRecognizerState _state = GestureRecognizerState.ready;
  GestureRecognizerState get state => _state;

  /// The position where the pointer was pressed down.
  Offset? _initialPosition;
  Offset? get initialPosition => _initialPosition;

  /// Start tracking a new pointer.
  void addPointer(MouseEvent event, Offset localPosition) {
    _initialPosition = localPosition;
    _state = GestureRecognizerState.possible;
    handlePointerDown(event, localPosition);
  }

  /// Handle a pointer down event.
  void handlePointerDown(MouseEvent event, Offset localPosition);

  /// Handle a pointer up event.
  void handlePointerUp(MouseEvent event, Offset localPosition);

  /// Handle a pointer move event.
  void handlePointerMove(MouseEvent event, Offset localPosition);

  /// Called when this recognizer wins the gesture arena.
  void acceptGesture() {
    if (_state == GestureRecognizerState.possible) {
      resolve(GestureDisposition.accepted);
    }
  }

  /// Called when this recognizer loses the gesture arena.
  void rejectGesture() {
    if (_state == GestureRecognizerState.possible) {
      resolve(GestureDisposition.rejected);
    }
  }

  /// Resolve the gesture with the given disposition.
  void resolve(GestureDisposition disposition);

  /// Reset the recognizer to its initial state.
  void reset() {
    _state = GestureRecognizerState.ready;
    _initialPosition = null;
  }

  /// Dispose of any resources used by this recognizer.
  void dispose() {
    reset();
  }
}

/// The result of a gesture recognition.
enum GestureDisposition {
  /// The gesture was accepted.
  accepted,

  /// The gesture was rejected.
  rejected,
}

/// Simple gesture arena for resolving conflicts between gesture recognizers.
///
/// In this simplified version, all recognizers compete and the first one
/// to claim the gesture wins. In Flutter, this is more sophisticated.
class GestureArenaManager {
  final Map<int, List<GestureRecognizer>> _arenas = {};
  int _nextArenaId = 0;

  /// Create a new arena and return its ID.
  int createArena() {
    final id = _nextArenaId++;
    _arenas[id] = [];
    return id;
  }

  /// Add a recognizer to an arena.
  void add(int arenaId, GestureRecognizer recognizer) {
    _arenas[arenaId]?.add(recognizer);
  }

  /// Close an arena and resolve it.
  void close(int arenaId) {
    final recognizers = _arenas[arenaId];
    if (recognizers == null || recognizers.isEmpty) {
      _arenas.remove(arenaId);
      return;
    }

    // Simple resolution: accept the first recognizer that's still possible
    bool resolved = false;
    for (final recognizer in recognizers) {
      if (recognizer.state == GestureRecognizerState.possible) {
        if (!resolved) {
          recognizer.acceptGesture();
          resolved = true;
        } else {
          recognizer.rejectGesture();
        }
      }
    }

    _arenas.remove(arenaId);
  }

  /// Sweep all arenas and resolve them.
  void sweep(int arenaId) {
    close(arenaId);
  }
}
