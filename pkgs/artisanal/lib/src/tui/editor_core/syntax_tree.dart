library;

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

  Map<int, EditorSyntaxNode> get byId =>
      <int, EditorSyntaxNode>{for (final n in nodes) n.id: n};

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
  }) =>
      const <EditorSyntaxCapture>[];
}

/// Maps [EditorSyntaxCapture]s to core decoration ranges.
///
/// Keeps the tree DTO layer independent of the decoration layer's exact
/// range type while giving Tree-sitter adapters a one-call path to
/// highlighting.
List<({int startOffset, int endOffset, String? styleKey, int priority})>
    syntaxCapturesToRanges(Iterable<EditorSyntaxCapture> captures) {
  return List<({int startOffset, int endOffset, String? styleKey, int priority})>.unmodifiable(
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
