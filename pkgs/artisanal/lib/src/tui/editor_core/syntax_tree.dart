library;

import 'text_change.dart';
import 'text_document.dart';

/// Pure-Dart syntax-tree DTOs for Tree-sitter-style backends.
///
/// The core never imports `dart:ffi` and never links a native parser. An
/// external package (for example `artisanal_treesitter`) implements
/// [SyntaxTreeProvider] with whatever native bindings it needs and maps its
/// nodes into these plain DTOs. The core then renders captures as
/// decorations, drives motions/text-objects, and supports incremental
/// re-parses via [SyntaxTreeEdit].

/// A single syntax node in a parsed tree snapshot.
final class EditorSyntaxNode {
  const EditorSyntaxNode({
    required this.id,
    required this.type,
    required this.startOffset,
    required this.endOffset,
    this.named = true,
    this.field,
    this.parentId,
    this.childIds = const <int>[],
  });

  final int id;
  final String type;
  final int startOffset;
  final int endOffset;
  final bool named;
  final String? field;
  final int? parentId;
  final List<int> childIds;

  int get length => endOffset - startOffset;
  bool get isEmpty => startOffset >= endOffset;

  bool containsOffset(int offset) =>
      offset >= startOffset && offset < endOffset;
}

/// An incremental edit applied to a previous tree snapshot.
///
/// Mirrors the Tree-sitter `TSInputEdit` shape (start/end + new end) using
/// plain offsets so any backend can translate directly.
final class SyntaxTreeEdit {
  const SyntaxTreeEdit({
    required this.startOffset,
    required this.oldEndOffset,
    required this.newEndOffset,
  });

  final int startOffset;
  final int oldEndOffset;
  final int newEndOffset;

  int get oldLength => oldEndOffset - startOffset;
  int get newLength => newEndOffset - startOffset;
  int get delta => newLength - oldLength;
}

/// A query capture mapped to a decoration style.
final class EditorSyntaxCapture {
  const EditorSyntaxCapture({
    required this.nodeId,
    required this.capture,
    required this.startOffset,
    required this.endOffset,
    this.styleKey,
    this.priority = 0,
  });

  final int nodeId;
  final String capture;
  final int startOffset;
  final int endOffset;
  final String? styleKey;
  final int priority;
}

/// Immutable snapshot of a parsed syntax tree.
final class EditorSyntaxTree {
  EditorSyntaxTree({
    required this.languageId,
    required this.revision,
    required List<EditorSyntaxNode> nodes,
    this.rootId,
  }) : nodes = List<EditorSyntaxNode>.unmodifiable(nodes);

  final String languageId;
  final int revision;
  final List<EditorSyntaxNode> nodes;
  final int? rootId;

  Map<int, EditorSyntaxNode> get byId => <int, EditorSyntaxNode>{
    for (final n in nodes) n.id: n,
  };

  EditorSyntaxNode? nodeAtOffset(int offset) {
    EditorSyntaxNode? best;
    for (final node in nodes) {
      if (!node.containsOffset(offset)) continue;
      if (best == null || node.length < best.length) best = node;
    }
    return best;
  }

  EditorSyntaxNode? namedAncestorOf(int nodeId, Set<String> types) {
    final index = byId;
    var current = index[nodeId]?.parentId;
    while (current != null) {
      final node = index[current];
      if (node == null) return null;
      if (types.contains(node.type)) return node;
      current = node.parentId;
    }
    return null;
  }
}

/// Backend interface for incremental syntax trees.
///
/// Implementations live outside the core package. They may hold native parser
/// handles, WASM runtimes, or LSP connections; the core only sees snapshots.
abstract class SyntaxTreeProvider {
  const SyntaxTreeProvider();

  String get languageId;
  bool get supportsIncremental => false;

  EditorSyntaxTree parse({
    required String text,
    String? languageId,
    EditorSyntaxTree? previous,
    List<SyntaxTreeEdit>? edits,
    int? revision,
  });

  List<EditorSyntaxCapture> capturesFor(
    EditorSyntaxTree tree, {
    Set<String>? captureNames,
  }) => const <EditorSyntaxCapture>[];
}

/// Asynchronous backend interface for incremental syntax trees.
///
/// Implementations may call native workers, isolates, or remote parsers. The
/// current and previous documents use grapheme coordinates; adapters translate
/// them to their backend's coordinate system.
abstract class AsyncSyntaxTreeProvider {
  const AsyncSyntaxTreeProvider();

  String get languageId;
  bool get supportsIncremental => false;

  Future<EditorSyntaxTree> parse({
    required TextDocument document,
    String? languageId,
    TextDocument? previousDocument,
    EditorSyntaxTree? previous,
    List<SyntaxTreeEdit>? edits,
    int? revision,
  });

  Future<List<EditorSyntaxCapture>> capturesFor(
    EditorSyntaxTree tree, {
    Set<String>? captureNames,
  }) async => const <EditorSyntaxCapture>[];
}

/// Coordinates asynchronous tree builds and rejects stale responses.
final class AsyncSyntaxTreeSession {
  AsyncSyntaxTreeSession({required this.provider, this.languageId});

  final AsyncSyntaxTreeProvider provider;
  String? languageId;

  int _generation = 0;
  EditorSyntaxTree? _snapshot;
  TextDocument? _document;

  /// Most recently accepted syntax tree.
  EditorSyntaxTree? get snapshot => _snapshot;

  /// Document snapshot corresponding to [snapshot].
  TextDocument? get document => _document;

  /// Parses [document], returning `null` if a newer request supersedes it.
  Future<EditorSyntaxTree?> request(
    TextDocument document, {
    String? languageId,
    TextDocumentChange? change,
    bool force = false,
  }) async {
    final generation = ++_generation;
    final requestedDocument = document.copy();
    final resolvedLanguage =
        languageId ?? this.languageId ?? provider.languageId;
    final previousTree = _snapshot;
    final previousDocument = _document;
    final unchanged =
        !force &&
        previousTree != null &&
        previousDocument != null &&
        previousTree.languageId == resolvedLanguage &&
        previousDocument.storageIdentity == requestedDocument.storageIdentity &&
        previousDocument.revision == requestedDocument.revision &&
        (change == null || change.isNoop);
    if (unchanged) return previousTree;

    final incremental =
        !force &&
        provider.supportsIncremental &&
        previousTree != null &&
        previousDocument != null &&
        previousTree.languageId == resolvedLanguage;
    final resolvedChange = incremental
        ? change ??
              computeTextDocumentChangeForDocuments(
                previousDocument: previousDocument,
                nextDocument: requestedDocument,
              )
        : null;
    final edits = resolvedChange == null || resolvedChange.isNoop
        ? incremental
              ? const <SyntaxTreeEdit>[]
              : null
        : syntaxTreeEditsForDocumentChange(resolvedChange);
    final tree = await provider.parse(
      document: requestedDocument.copy(),
      languageId: resolvedLanguage,
      previousDocument: incremental ? previousDocument.copy() : null,
      previous: incremental ? previousTree : null,
      edits: edits,
      revision: requestedDocument.revision,
    );
    if (generation != _generation) return null;
    _snapshot = tree;
    _document = requestedDocument;
    return tree;
  }

  /// Invalidates every outstanding request without clearing accepted state.
  void cancel() {
    _generation++;
  }

  /// Clears accepted state and invalidates every outstanding request.
  void reset() {
    cancel();
    _snapshot = null;
    _document = null;
  }
}

/// Maps [EditorSyntaxCapture]s to core decoration ranges.
///
/// Keeps the tree DTO layer independent of the decoration layer's exact
/// range type while giving Tree-sitter adapters a one-call path to
/// highlighting.
List<({int startOffset, int endOffset, String? styleKey, int priority})>
syntaxCapturesToRanges(Iterable<EditorSyntaxCapture> captures) {
  return List<
    ({int startOffset, int endOffset, String? styleKey, int priority})
  >.unmodifiable(
    captures.map(
      (capture) => (
        startOffset: capture.startOffset,
        endOffset: capture.endOffset,
        styleKey: capture.styleKey,
        priority: capture.priority,
      ),
    ),
  );
}

/// Computes the [SyntaxTreeEdit] list for a single replacement.
List<SyntaxTreeEdit> syntaxTreeEditsForReplacement({
  required int startOffset,
  required int oldEndOffset,
  required int newEndOffset,
}) {
  if (startOffset == oldEndOffset && startOffset == newEndOffset) {
    return const <SyntaxTreeEdit>[];
  }
  return <SyntaxTreeEdit>[
    SyntaxTreeEdit(
      startOffset: startOffset,
      oldEndOffset: oldEndOffset,
      newEndOffset: newEndOffset,
    ),
  ];
}

/// Converts a document change into the backend-neutral syntax-tree edit shape.
List<SyntaxTreeEdit> syntaxTreeEditsForDocumentChange(
  TextDocumentChange change,
) => syntaxTreeEditsForReplacement(
  startOffset: change.startOffset,
  oldEndOffset: change.oldEndOffset,
  newEndOffset: change.newEndOffset,
);
