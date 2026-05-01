import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

final class _CounterState {
  _CounterState(this.value);

  int value;
}

final class _CounterCommand implements UndoableCommand<_CounterState> {
  _CounterCommand(this.delta, {this.mergeable = true});

  final int delta;
  final bool mergeable;

  @override
  String get type => 'counter_delta';

  @override
  void apply(_CounterState state) {
    state.value += delta;
  }

  @override
  void undo(_CounterState state) {
    state.value -= delta;
  }

  @override
  UndoableCommand<_CounterState>? mergeWith(
    UndoableCommand<_CounterState> next,
  ) {
    if (!mergeable) return null;
    if (next is! _CounterCommand || !next.mergeable) return null;
    if (next.delta.sign != delta.sign) return null;
    return _CounterCommand(delta + next.delta);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'delta': delta, 'mergeable': mergeable};
  }
}

UndoableCommand<_CounterState> _decodeCounterCommand(
  String type,
  Map<String, Object?> payload,
) {
  if (type != 'counter_delta') {
    throw StateError('Unknown command type: $type');
  }
  return _CounterCommand(
    (payload['delta'] as int?) ?? 0,
    mergeable: (payload['mergeable'] as bool?) ?? true,
  );
}

void main() {
  group('UndoManager', () {
    test('supports undo and redo', () {
      final state = _CounterState(0);
      final manager = UndoManager<_CounterState>(
        decodeCommand: _decodeCounterCommand,
      );

      manager.execute(command: _CounterCommand(5), state: state);
      manager.execute(command: _CounterCommand(-2), state: state);

      expect(state.value, 3);
      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);

      expect(manager.undo(state: state), isTrue);
      expect(state.value, 5);
      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isTrue);

      expect(manager.undo(state: state), isTrue);
      expect(state.value, 0);
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isTrue);

      expect(manager.redo(state: state), isTrue);
      expect(state.value, 5);
      expect(manager.undo(state: state), isTrue);
      expect(state.value, 0);
    });

    test('supports committed and rolled-back transactions', () {
      final state = _CounterState(0);
      final manager = UndoManager<_CounterState>(
        decodeCommand: _decodeCounterCommand,
      );

      manager.beginTransaction();
      manager.execute(command: _CounterCommand(3), state: state);
      manager.execute(command: _CounterCommand(4), state: state);
      manager.commitTransaction();
      expect(state.value, 7);
      expect(manager.canUndo, isTrue);

      expect(manager.undo(state: state), isTrue);
      expect(state.value, 0);

      expect(manager.redo(state: state), isTrue);
      expect(state.value, 7);

      manager.beginTransaction();
      manager.execute(command: _CounterCommand(2), state: state);
      manager.rollbackTransaction(state);
      expect(state.value, 7);
      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
    });

    test('merges adjacent compatible commands', () {
      final state = _CounterState(0);
      final manager = UndoManager<_CounterState>(
        decodeCommand: _decodeCounterCommand,
      );

      manager.execute(command: _CounterCommand(1), state: state);
      manager.execute(command: _CounterCommand(1), state: state);
      manager.execute(
        command: _CounterCommand(-4, mergeable: false),
        state: state,
      );

      expect(state.value, -2);
      expect(manager.undo(state: state), isTrue);
      expect(state.value, 2);
      expect(manager.undo(state: state), isTrue);
      expect(state.value, 0);
    });

    test('persists and restores undo/redo command stacks', () {
      final state = _CounterState(0);
      final manager = UndoManager<_CounterState>(
        decodeCommand: _decodeCounterCommand,
      );

      manager.execute(command: _CounterCommand(3), state: state);
      manager.execute(
        command: _CounterCommand(-4, mergeable: false),
        state: state,
      );
      manager.beginTransaction();
      manager.execute(command: _CounterCommand(1), state: state);
      manager.execute(command: _CounterCommand(-1), state: state);
      manager.commitTransaction();
      expect(manager.undo(state: state), isTrue);
      expect(state.value, -1);

      final journal = manager.toJournal();
      final restoredState = _CounterState(-1);
      final restored = UndoManager<_CounterState>.fromJournal(
        journal: journal,
        decodeCommand: _decodeCounterCommand,
      );

      expect(restored.canUndo, isTrue);
      expect(restored.canRedo, isTrue);
      expect(restored.undo(state: restoredState), isTrue);
      expect(restoredState.value, 3);
      expect(restored.undo(state: restoredState), isTrue);
      expect(restoredState.value, 0);
      expect(restored.redo(state: restoredState), isTrue);
      expect(restoredState.value, 3);
    });
  });
}
