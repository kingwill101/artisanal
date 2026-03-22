/// Accessibility tree structures and diff utilities.
library;

import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import 'widget.dart';

@immutable
final class A11yNode {
  const A11yNode({
    required this.id,
    required this.widget,
    required this.parentId,
    required this.children,
    required this.role,
    this.label,
  });

  /// Deterministic, stable identifier for this node.
  final int id;

  /// Widget represented by this node.
  final Widget widget;

  /// Parent node id, or `null` for the root.
  final int? parentId;

  /// Child node ids in tree order.
  final List<int> children;

  /// Accessibility role for this node.
  final String role;

  /// Optional accessibility label for this node.
  final String? label;

  bool hasSameSemanticShape(A11yNode other) {
    if (id != other.id ||
        role != other.role ||
        label != other.label ||
        parentId != other.parentId) {
      return false;
    }

    if (children.length != other.children.length) return false;
    for (var i = 0; i < children.length; i++) {
      if (children[i] != other.children[i]) return false;
    }
    return true;
  }
}

@immutable
final class A11yTreeDiff {
  const A11yTreeDiff({
    required this.added,
    required this.removed,
    required this.changed,
  });

  /// Nodes that did not exist in the previous tree.
  final List<A11yNode> added;

  /// Nodes that no longer exist in the new tree.
  final List<A11yNode> removed;

  /// Nodes that exist in both trees but changed semantics or structure.
  final List<A11yNode> changed;

  bool get isEmpty => added.isEmpty && removed.isEmpty && changed.isEmpty;
}

@immutable
final class A11yTree {
  const A11yTree({
    required this.rootId,
    required this.nodes,
    required Map<Widget, int> widgetToNodeId,
  }) : _widgetToNodeId = widgetToNodeId;

  /// Node id for the tree root.
  final int rootId;

  /// Nodes in DFS order keyed by node id.
  final Map<int, A11yNode> nodes;

  final Map<Widget, int> _widgetToNodeId;

  A11yNode? get root => nodes[rootId];

  Iterable<A11yNode> get nodesInOrder =>
      List<A11yNode>.unmodifiable(nodes.values.toList());

  A11yNode? nodeForWidget(Widget widget) {
    final id = _widgetToNodeId[widget];
    if (id == null) return null;
    return nodes[id];
  }

  A11yTreeDiff diff(A11yTree previous) {
    final added = <A11yNode>[];
    final removed = <A11yNode>[];
    final changed = <A11yNode>[];

    for (final id in nodes.keys) {
      final previousNode = previous.nodes[id];
      final currentNode = nodes[id];
      if (previousNode == null) {
        added.add(currentNode!);
      } else if (currentNode == null) {
        continue;
      } else if (!currentNode.hasSameSemanticShape(previousNode)) {
        changed.add(currentNode);
      }
    }

    for (final id in previous.nodes.keys) {
      if (!nodes.containsKey(id)) {
        removed.add(previous.nodes[id]!);
      }
    }

    int compareById(A11yNode a, A11yNode b) => a.id.compareTo(b.id);
    added.sort(compareById);
    removed.sort(compareById);
    changed.sort(compareById);
    return A11yTreeDiff(
      added: List<A11yNode>.unmodifiable(added),
      removed: List<A11yNode>.unmodifiable(removed),
      changed: List<A11yNode>.unmodifiable(changed),
    );
  }
}

/// Computes a 32-bit FNV-1a hash for stable accessibility node ids.
int fnv1a32(String data) {
  const int offsetBasis = 0x811C9DC5;
  const int prime = 0x01000193;
  var hash = offsetBasis;
  final bytes = utf8.encode(data);
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * prime) & 0xFFFFFFFF;
  }
  return hash;
}
