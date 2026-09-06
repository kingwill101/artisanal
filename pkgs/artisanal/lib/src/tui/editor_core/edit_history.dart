library;

typedef EditHistoryStateEquals<State> = bool Function(State a, State b);

typedef EditHistoryCoalescePredicate<Action, State, Marker> =
    bool Function(
      Action action, {
      required Action? lastAction,
      required Marker? lastMarker,
      required State currentState,
    });

typedef EditHistoryMarkerBuilder<Action, State, Marker> =
    Marker Function(Action action, State state);

final class EditHistoryCheckpoint<Action, State, Marker> {
  const EditHistoryCheckpoint._({
    required this.undo,
    required this.redo,
    required this.currentAction,
    required this.lastAction,
    required this.lastMarker,
    required this.didRecordUndoSnapshot,
  });

  final List<State> undo;
  final List<State> redo;
  final Action? currentAction;
  final Action? lastAction;
  final Marker? lastMarker;
  final bool didRecordUndoSnapshot;
}

final class EditHistoryController<Action, State, Marker> {
  EditHistoryController({
    required this.maxEntries,
    required this.sameState,
    required this.canCoalesce,
    required this.markerForState,
  });

  final int maxEntries;
  final EditHistoryStateEquals<State> sameState;
  final EditHistoryCoalescePredicate<Action, State, Marker> canCoalesce;
  final EditHistoryMarkerBuilder<Action, State, Marker> markerForState;

  final List<State> _undoStack = <State>[];
  final List<State> _redoStack = <State>[];
  bool _frameActive = false;
  bool _didRecordUndoSnapshot = false;
  Action? _currentAction;
  Action? _lastAction;
  Marker? _lastMarker;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  EditHistoryCheckpoint<Action, State, Marker> checkpoint() {
    return EditHistoryCheckpoint._(
      undo: List<State>.of(_undoStack),
      redo: List<State>.of(_redoStack),
      currentAction: _currentAction,
      lastAction: _lastAction,
      lastMarker: _lastMarker,
      didRecordUndoSnapshot: _didRecordUndoSnapshot,
    );
  }

  void restoreCheckpoint(EditHistoryCheckpoint<Action, State, Marker> value) {
    _undoStack
      ..clear()
      ..addAll(value.undo);
    _redoStack
      ..clear()
      ..addAll(value.redo);
    _currentAction = value.currentAction;
    _lastAction = value.lastAction;
    _lastMarker = value.lastMarker;
    _didRecordUndoSnapshot = value.didRecordUndoSnapshot;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    breakCoalescing();
  }

  void beginAction(Action action, {bool breakChain = false}) {
    if (breakChain) {
      breakCoalescing();
    }
    _currentAction = action;
  }

  void breakCoalescing() {
    _currentAction = null;
    _lastAction = null;
    _lastMarker = null;
  }

  void recordUndoSnapshot(State Function() captureState) {
    if (_frameActive && _didRecordUndoSnapshot) {
      return;
    }

    final action = _currentAction;
    final currentState = captureState();
    if (action != null &&
        canCoalesce(
          action,
          lastAction: _lastAction,
          lastMarker: _lastMarker,
          currentState: currentState,
        )) {
      _didRecordUndoSnapshot = true;
      return;
    }

    if (_undoStack.isNotEmpty && sameState(_undoStack.last, currentState)) {
      _didRecordUndoSnapshot = true;
      return;
    }

    _undoStack.add(currentState);
    if (_undoStack.length > maxEntries) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _didRecordUndoSnapshot = true;
  }

  T runFrame<T>({
    required State Function() captureState,
    required T Function() body,
    void Function()? onCommittedChange,
  }) {
    final wasActive = _frameActive;
    State? beforeState;
    if (!wasActive) {
      _frameActive = true;
      _didRecordUndoSnapshot = false;
      beforeState = captureState();
    }

    try {
      return body();
    } finally {
      if (!wasActive) {
        _finalizeFrame(
          beforeState as State,
          captureState: captureState,
          onCommittedChange: onCommittedChange,
        );
        _frameActive = false;
        _didRecordUndoSnapshot = false;
        _currentAction = null;
      }
    }
  }

  bool undo({
    required State Function() captureState,
    required void Function(State state) restoreState,
  }) {
    if (_undoStack.isEmpty) {
      return false;
    }

    breakCoalescing();
    final current = captureState();
    final previous = _undoStack.removeLast();
    _redoStack.add(current);
    restoreState(previous);
    return true;
  }

  bool redo({
    required State Function() captureState,
    required void Function(State state) restoreState,
  }) {
    if (_redoStack.isEmpty) {
      return false;
    }

    breakCoalescing();
    final current = captureState();
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    restoreState(next);
    return true;
  }

  void _finalizeFrame(
    State beforeState, {
    required State Function() captureState,
    void Function()? onCommittedChange,
  }) {
    final action = _currentAction;
    final afterState = captureState();
    if (sameState(beforeState, afterState)) {
      if (action == null) {
        breakCoalescing();
      }
      return;
    }

    if (action == null) {
      breakCoalescing();
      return;
    }

    _lastAction = action;
    _lastMarker = markerForState(action, afterState);
    onCommittedChange?.call();
  }
}
