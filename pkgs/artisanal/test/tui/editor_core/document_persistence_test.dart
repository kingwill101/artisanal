import 'dart:async';

import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  test('save records revision and clears recovery state', () async {
    final store = _MemoryDocumentStore();
    final session = EditorPersistenceSession(
      documentId: 'file:///demo.dart',
      store: store,
      now: () => DateTime.utc(2026),
    );

    expect(session.isDirty(1), isTrue);
    expect(
      await session.checkpoint(TextDocument(text: 'draft'), revision: 1),
      isTrue,
    );
    expect(session.savedRevision, isNull);
    expect(
      await session.save(TextDocument(text: 'saved'), revision: 1),
      isTrue,
    );

    expect(session.savedRevision, 1);
    expect(session.isDirty(1), isFalse);
    expect(store.durable?.document.text, 'saved');
    expect(store.durable?.savedAt, DateTime.utc(2026));
    expect(store.recovery, isNull);
  });

  test('newer operations invalidate stale load results', () async {
    final store = _MemoryDocumentStore()..pauseReads = true;
    final session = EditorPersistenceSession(
      documentId: 'memory:demo',
      store: store,
    );

    final load = session.load();
    final checkpoint = session.checkpoint(
      TextDocument(text: 'newer'),
      revision: 2,
    );
    store.pendingRead!.complete(
      EditorDocumentSnapshot(
        documentId: 'memory:demo',
        document: TextDocument(text: 'old'),
        revision: 1,
        savedAt: DateTime.utc(2025),
      ),
    );

    expect(await load, isNull);
    expect(await checkpoint, isTrue);
    expect(session.savedRevision, isNull);
  });

  test('serializes saves so stale content cannot finish last', () async {
    final store = _MemoryDocumentStore()..pauseWrites = true;
    final session = EditorPersistenceSession(
      documentId: 'memory:demo',
      store: store,
    );

    final older = session.save(TextDocument(text: 'old'), revision: 1);
    await _waitFor(() => store.pendingWrites.length == 1);
    final newer = session.save(TextDocument(text: 'new'), revision: 2);

    store.pendingWrites[0].complete();
    await _waitFor(() => store.pendingWrites.length == 2);
    store.pendingWrites[1].complete();

    expect(await older, isFalse);
    expect(await newer, isTrue);
    expect(store.durable?.document.text, 'new');
    expect(session.savedRevision, 2);
  });

  test('memory store separates durable and recovery snapshots', () async {
    final store = MemoryEditorDocumentStore();
    final session = EditorPersistenceSession(
      documentId: 'memory:demo',
      store: store,
      now: () => DateTime.utc(2026),
    );

    await session.checkpoint(TextDocument(text: 'draft'), revision: 1);
    expect(store.recoveryFor('memory:demo')?.document.text, 'draft');
    expect(store.durableFor('memory:demo'), isNull);

    await session.save(TextDocument(text: 'saved'), revision: 2);
    expect(store.durableFor('memory:demo')?.document.text, 'saved');
    expect(store.recoveryFor('memory:demo'), isNull);

    store.failNextWrite = true;
    expect(
      session.save(TextDocument(text: 'failed'), revision: 3),
      throwsStateError,
    );
    expect(store.durableFor('memory:demo')?.revision, 2);
  });
}

final class _MemoryDocumentStore implements EditorDocumentStore {
  EditorDocumentSnapshot? durable;
  EditorDocumentSnapshot? recovery;
  bool pauseReads = false;
  bool pauseWrites = false;
  Completer<EditorDocumentSnapshot?>? pendingRead;
  final List<Completer<void>> pendingWrites = [];

  @override
  Future<void> deleteRecovery(String documentId) async {
    recovery = null;
  }

  @override
  Future<EditorDocumentSnapshot?> read(String documentId) {
    if (!pauseReads) return Future.value(durable);
    pendingRead = Completer<EditorDocumentSnapshot?>();
    return pendingRead!.future;
  }

  @override
  Future<EditorDocumentSnapshot?> readRecovery(String documentId) async =>
      recovery;

  @override
  Future<void> write(EditorDocumentSnapshot snapshot) async {
    durable = snapshot;
    if (pauseWrites) {
      final pending = Completer<void>();
      pendingWrites.add(pending);
      await pending.future;
    }
  }

  @override
  Future<void> writeRecovery(EditorDocumentSnapshot snapshot) async {
    recovery = snapshot;
  }
}

Future<void> _waitFor(bool Function() condition) async {
  while (!condition()) {
    await Future<void>.delayed(Duration.zero);
  }
}
