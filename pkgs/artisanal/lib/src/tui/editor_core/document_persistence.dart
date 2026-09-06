library;

import 'text_document.dart';

/// Serializable editor document state supplied to persistence adapters.
final class EditorDocumentSnapshot {
  EditorDocumentSnapshot({
    required this.documentId,
    required this.document,
    required this.revision,
    required this.savedAt,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) : metadata = Map<String, Object?>.unmodifiable(metadata);

  /// Stable host-defined identifier, usually a URI or workspace-relative path.
  final String documentId;

  /// Document content captured for this revision.
  final TextDocument document;

  /// Monotonically increasing host revision.
  final int revision;

  /// Time at which the snapshot was created.
  final DateTime savedAt;

  /// Adapter-specific serializable metadata.
  final Map<String, Object?> metadata;
}

/// Persistence boundary for files, databases, browser storage, or remote APIs.
abstract interface class EditorDocumentStore {
  /// Reads the latest durable document snapshot.
  Future<EditorDocumentSnapshot?> read(String documentId);

  /// Writes [snapshot] durably.
  Future<void> write(EditorDocumentSnapshot snapshot);

  /// Reads a crash-recovery snapshot, when one exists.
  Future<EditorDocumentSnapshot?> readRecovery(String documentId);

  /// Writes a crash-recovery snapshot without replacing durable content.
  Future<void> writeRecovery(EditorDocumentSnapshot snapshot);

  /// Removes recovery state after a successful durable save or dismissal.
  Future<void> deleteRecovery(String documentId);
}

/// Coordinates durable saves and recovery while rejecting stale completions.
final class EditorPersistenceSession {
  EditorPersistenceSession({
    required this.documentId,
    required this.store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String documentId;
  final EditorDocumentStore store;
  final DateTime Function() _now;

  int _generation = 0;
  int? _savedRevision;

  /// Most recent revision whose durable write completed successfully.
  int? get savedRevision => _savedRevision;

  /// Whether [revision] differs from the most recently saved revision.
  bool isDirty(int revision) => revision != _savedRevision;

  /// Loads durable state unless superseded by a newer session operation.
  Future<EditorDocumentSnapshot?> load() async {
    final generation = ++_generation;
    final snapshot = await store.read(documentId);
    if (generation != _generation) return null;
    _savedRevision = snapshot?.revision;
    return snapshot;
  }

  /// Loads recovery state without marking it as durably saved.
  Future<EditorDocumentSnapshot?> loadRecovery() async {
    final generation = ++_generation;
    final snapshot = await store.readRecovery(documentId);
    return generation == _generation ? snapshot : null;
  }

  /// Saves [document] and clears obsolete recovery state.
  Future<bool> save(
    TextDocument document, {
    required int revision,
    Map<String, Object?> metadata = const {},
  }) async {
    final generation = ++_generation;
    final snapshot = _snapshot(document, revision, metadata);
    await store.write(snapshot);
    if (generation != _generation) return false;
    _savedRevision = revision;
    await store.deleteRecovery(documentId);
    return generation == _generation;
  }

  /// Writes recovery state without changing the durable saved revision.
  Future<bool> checkpoint(
    TextDocument document, {
    required int revision,
    Map<String, Object?> metadata = const {},
  }) async {
    final generation = ++_generation;
    await store.writeRecovery(_snapshot(document, revision, metadata));
    return generation == _generation;
  }

  /// Invalidates outstanding operations.
  void cancel() {
    _generation++;
  }

  EditorDocumentSnapshot _snapshot(
    TextDocument document,
    int revision,
    Map<String, Object?> metadata,
  ) {
    return EditorDocumentSnapshot(
      documentId: documentId,
      document: document.copy(),
      revision: revision,
      savedAt: _now(),
      metadata: metadata,
    );
  }
}

/// In-memory [EditorDocumentStore] for tests, examples, and recovery drills.
final class MemoryEditorDocumentStore implements EditorDocumentStore {
  final Map<String, EditorDocumentSnapshot> _durable =
      <String, EditorDocumentSnapshot>{};
  final Map<String, EditorDocumentSnapshot> _recovery =
      <String, EditorDocumentSnapshot>{};

  /// When true, the next [write] throws and is then cleared.
  bool failNextWrite = false;

  EditorDocumentSnapshot? durableFor(String documentId) => _durable[documentId];

  EditorDocumentSnapshot? recoveryFor(String documentId) =>
      _recovery[documentId];

  @override
  Future<EditorDocumentSnapshot?> read(String documentId) async =>
      _durable[documentId];

  @override
  Future<void> write(EditorDocumentSnapshot snapshot) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Save failed');
    }
    _durable[snapshot.documentId] = snapshot;
  }

  @override
  Future<EditorDocumentSnapshot?> readRecovery(String documentId) async =>
      _recovery[documentId];

  @override
  Future<void> writeRecovery(EditorDocumentSnapshot snapshot) async {
    _recovery[snapshot.documentId] = snapshot;
  }

  @override
  Future<void> deleteRecovery(String documentId) async {
    _recovery.remove(documentId);
  }
}
