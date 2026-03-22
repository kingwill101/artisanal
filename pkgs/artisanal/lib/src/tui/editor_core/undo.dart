library;

typedef UndoCommandDecoder<State> =
    UndoableCommand<State> Function(String type, Map<String, Object?> payload);

Map<String, Object?> _serializeCommandForJournal<State>(
  UndoableCommand<State> command,
) {
  final data = command.toJson();
  return <String, Object?>{
    'type': command.type,
    if (data.isNotEmpty) 'payload': data,
  };
}

/// A command that knows how to apply and undo its own effect on a mutable state.
abstract interface class UndoableCommand<State> {
  /// Command category for journal persistence.
  String get type;

  /// Applies this command to [state].
  void apply(State state);

  /// Restores [state] to the value before this command ran.
  void undo(State state);

  /// Attempts to merge [next] into this command, returning a replacement.
  ///
  /// Return `null` when no merge is possible.
  UndoableCommand<State>? mergeWith(UndoableCommand<State> next) => null;

  /// Serializes the command payload for the journal.
  Map<String, Object?> toJson();
}

/// Journal envelope for one command or transaction.
final class UndoCommandJournalEntry {
  /// Creates a serializable journal entry.
  const UndoCommandJournalEntry({
    required this.type,
    this.payload = const <String, Object?>{},
  });

  /// Command kind.
  final String type;

  /// Serialized command payload.
  final Map<String, Object?> payload;

  /// Creates a journal entry from JSON.
  factory UndoCommandJournalEntry.fromJson(Map<String, Object?> json) {
    return UndoCommandJournalEntry(
      type: (json['type'] as String?) ?? '',
      payload: _asObjectMap(json['payload']),
    );
  }

  /// Serializes this entry.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type,
      if (payload.isNotEmpty) 'payload': payload,
    };
  }

  static Map<String, Object?> _asObjectMap(Object? raw) {
    if (raw is Map) {
      final casted = <String, Object?>{};
      for (final entry in raw.entries) {
        final key = entry.key;
        if (key is String) {
          casted[key] = entry.value;
        }
      }
      return casted;
    }
    return const <String, Object?>{};
  }
}

/// Private composite command used to represent committed transactions.
final class _UndoTransactionCommand<State> implements UndoableCommand<State> {
  _UndoTransactionCommand(this.commands)
    : assert(commands.isNotEmpty),
      assert(commands.length > 1);

  final List<UndoableCommand<State>> commands;

  @override
  String get type => _undoTransactionType;

  @override
  void apply(State state) {
    for (final command in commands) {
      command.apply(state);
    }
  }

  @override
  void undo(State state) {
    for (var i = commands.length - 1; i >= 0; i--) {
      commands[i].undo(state);
    }
  }

  @override
  UndoableCommand<State>? mergeWith(UndoableCommand<State> next) {
    if (next.type == _undoTransactionType &&
        next is _UndoTransactionCommand<State>) {
      return _UndoTransactionCommand<State>([...commands, ...next.commands]);
    }
    return null;
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'commands': commands
          .map((command) {
            return _serializeCommandForJournal(command);
          })
          .toList(growable: false),
    };
  }

  static const String _undoTransactionType = '_composite_command';
}

/// Undo/redo command journal with optional transactional grouping.
final class UndoManager<State> {
  UndoManager({
    required UndoCommandDecoder<State> decodeCommand,
    this.maxEntries = 100,
  }) : _decodeCommand = decodeCommand;

  /// Builds a manager from a persisted journal payload.
  factory UndoManager.fromJournal({
    required Map<String, Object?> journal,
    required UndoCommandDecoder<State> decodeCommand,
    int maxEntries = 100,
  }) {
    final manager = UndoManager<State>(
      decodeCommand: decodeCommand,
      maxEntries: maxEntries,
    );
    manager.loadJournal(journal);
    return manager;
  }

  static const int schemaVersion = 1;
  static const String _versionKey = 'version';
  static const String _undoKey = 'undo';
  static const String _redoKey = 'redo';

  final UndoCommandDecoder<State> _decodeCommand;
  final int maxEntries;

  final List<UndoableCommand<State>> _undoStack = <UndoableCommand<State>>[];
  final List<UndoableCommand<State>> _redoStack = <UndoableCommand<State>>[];
  final List<List<UndoableCommand<State>>> _transactions =
      <List<UndoableCommand<State>>>[];

  /// Whether undo can be performed.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo can be performed.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of active nested transactions.
  int get transactionDepth => _transactions.length;

  /// Clears undo/redo stacks and abandons active transactions.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _transactions.clear();
  }

  /// Begins a nested command transaction.
  void beginTransaction() {
    _transactions.add(<UndoableCommand<State>>[]);
  }

  /// Commits the current transaction into one undoable journal entry.
  void commitTransaction() {
    final commands = _recordedTransaction();
    if (commands == null) {
      throw StateError('No active transaction to commit');
    }
    if (commands.isEmpty) {
      return;
    }

    final command = commands.length == 1
        ? commands.single
        : _UndoTransactionCommand<State>(commands);
    _appendCommand(command);
  }

  /// Reverts all state changes from the active transaction.
  void rollbackTransaction(State state) {
    final commands = _recordedTransaction();
    if (commands == null) {
      throw StateError('No active transaction to rollback');
    }

    for (var i = commands.length - 1; i >= 0; i--) {
      commands[i].undo(state);
    }
  }

  /// Executes [command], records it for undo/redo, and applies it to [state].
  void execute({
    required UndoableCommand<State> command,
    required State state,
  }) {
    command.apply(state);
    _appendCommand(command);
  }

  /// Undo one command group if possible.
  bool undo({required State state}) {
    if (_undoStack.isEmpty) return false;
    final command = _undoStack.removeLast();
    command.undo(state);
    _redoStack.add(command);
    return true;
  }

  /// Redo one command group if possible.
  bool redo({required State state}) {
    if (_redoStack.isEmpty) return false;
    final command = _redoStack.removeLast();
    command.apply(state);
    if (_undoStack.isEmpty) {
      _undoStack.add(command);
    } else {
      final last = _undoStack.last;
      final merged = last.mergeWith(command);
      if (merged != null) {
        _undoStack[_undoStack.length - 1] = merged;
      } else {
        _undoStack.add(command);
      }
    }
    return true;
  }

  /// Serializes undo and redo stacks as a journal payload.
  Map<String, Object?> toJournal() {
    return <String, Object?>{
      _versionKey: schemaVersion,
      _undoKey: _undoStack
          .map(_serializeCommandForJournal)
          .toList(growable: false),
      _redoKey: _redoStack
          .map(_serializeCommandForJournal)
          .toList(growable: false),
    };
  }

  /// Restores undo/redo stacks from a journal payload.
  void loadJournal(Map<String, Object?> journal) {
    final undo = journal[_undoKey];
    final redo = journal[_redoKey];

    _undoStack
      ..clear()
      ..addAll(_decodeCommandStack(undo));
    _redoStack
      ..clear()
      ..addAll(_decodeCommandStack(redo));
    if (maxEntries > 0) {
      _trimToMax();
    }
    _trimTransactions();
  }

  void _appendCommand(UndoableCommand<State> command) {
    if (_transactions.isNotEmpty) {
      _transactions.last.add(command);
      return;
    }

    if (_undoStack.isEmpty) {
      _undoStack.add(command);
      _redoStack.clear();
      _trimToMax();
      return;
    }

    final last = _undoStack.last;
    final merged = last.mergeWith(command);
    if (merged != null) {
      _undoStack[_undoStack.length - 1] = merged;
    } else {
      _undoStack.add(command);
    }
    _redoStack.clear();
    _trimToMax();
  }

  List<UndoableCommand<State>>? _recordedTransaction() {
    if (_transactions.isEmpty) return null;
    return _transactions.removeLast();
  }

  void _trimTransactions() {
    _transactions.clear();
  }

  void _trimToMax() {
    if (_undoStack.length <= maxEntries) return;
    _undoStack.removeRange(0, _undoStack.length - maxEntries);
  }

  List<UndoableCommand<State>> _decodeCommandStack(Object? raw) {
    if (raw is! List) {
      return <UndoableCommand<State>>[];
    }

    final commands = <UndoableCommand<State>>[];
    for (final value in raw) {
      if (value is! Map) continue;
      final entry = UndoCommandJournalEntry.fromJson(
        Map<String, Object?>.from(value),
      );
      final command = _decodeCommandEntry(entry);
      if (command == null) {
        continue;
      }
      commands.add(command);
    }
    return commands;
  }

  UndoableCommand<State>? _decodeCommandEntry(UndoCommandJournalEntry entry) {
    if (entry.type == _UndoTransactionCommand._undoTransactionType) {
      final nested = entry.payload['commands'];
      final nestedCommands = _decodeCommandStack(nested);
      if (nestedCommands.isEmpty) return null;
      if (nestedCommands.length == 1) {
        return nestedCommands.single;
      }
      return _UndoTransactionCommand<State>(nestedCommands);
    }

    return _decodeCommand(entry.type, entry.payload);
  }
}
