part of 'components_widgets.dart';

/// A node in a [TreeView] widget.
///
/// Each node has a [label] and optional [children]. Nodes can be styled
/// individually via [style], or use the tree's default styling.
///
/// Named `TreeViewNode` to avoid collision with the bubbles `TreeNode`
/// interface from `package:artisanal`.
class TreeViewNode {
  const TreeViewNode({
    required this.label,
    this.children = const [],
    this.style,
    this.icon,
    this.expanded = true,
  });

  /// The text label for this node.
  final String label;

  /// Child nodes.
  final List<TreeViewNode> children;

  /// Optional style override for this node's label.
  final Style? style;

  /// Optional icon/prefix for this node (e.g., "📁", "📄").
  final String? icon;

  /// Whether this node's children are shown. Only meaningful if [children]
  /// is non-empty.
  final bool expanded;

  /// Creates a [TreeViewNode] from a map structure.
  ///
  /// Expected format:
  /// ```json
  /// {"label": "Root", "children": [...], "icon": "📁"}
  /// ```
  factory TreeViewNode.fromMap(Map<String, dynamic> map) {
    final childrenRaw = map['children'] as List?;
    final children =
        childrenRaw
            ?.map((c) => TreeViewNode.fromMap(c as Map<String, dynamic>))
            .toList() ??
        const [];
    return TreeViewNode(
      label: (map['label'] ?? map['name'] ?? '') as String,
      children: children,
      icon: map['icon'] as String?,
      expanded: (map['expanded'] as bool?) ?? true,
    );
  }
}

/// A hierarchical tree view widget.
///
/// Renders a tree structure using Unicode box-drawing characters for
/// connectors.
///
/// ```dart
/// TreeView(
///   nodes: [
///     TreeViewNode(label: 'src', icon: '📁', children: [
///       TreeViewNode(label: 'main.dart', icon: '📄'),
///       TreeViewNode(label: 'utils.dart', icon: '📄'),
///     ]),
///   ],
/// )
/// ```
class TreeView extends StatelessWidget {
  TreeView({
    required this.nodes,
    this.labelStyle,
    this.connectorStyle,
    this.indentSize = 2,
    super.key,
  });

  /// Root-level nodes to display.
  final List<TreeViewNode> nodes;

  /// Default style for node labels.
  final Style? labelStyle;

  /// Style for connector lines (├, │, └, ─).
  final Style? connectorStyle;

  /// Number of spaces per indent level (minimum 1).
  final int indentSize;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final lStyle = _copyStyle(labelStyle ?? theme.bodyMedium)
      ..foreground(theme.onSurface);
    final cStyle = _copyStyle(connectorStyle ?? theme.bodySmall)
      ..foreground(theme.border);

    final lines = <Widget>[];
    _buildLines(nodes, '', true, lines, lStyle, cStyle, theme);
    return Column(gap: 0, children: lines);
  }

  void _buildLines(
    List<TreeViewNode> nodes,
    String prefix,
    bool isRoot,
    List<Widget> lines,
    Style labelStyle,
    Style connectorStyle,
    Theme theme,
  ) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isLast = i == nodes.length - 1;
      final connector = isRoot ? '' : (isLast ? '└─ ' : '├─ ');
      final childPrefix = isRoot ? '' : (isLast ? '   ' : '│  ');

      final resolvedLabelStyle = node.style != null
          ? _copyStyle(node.style!)
          : _copyStyle(labelStyle);

      final iconPart = node.icon != null ? '${node.icon} ' : '';
      final connectorWidget = connector.isEmpty
          ? ''
          : connectorStyle.render(connector);
      final prefixWidget = prefix.isEmpty ? '' : connectorStyle.render(prefix);

      lines.add(
        Text(
          '$prefixWidget$connectorWidget$iconPart${resolvedLabelStyle.render(node.label)}',
        ),
      );

      if (node.children.isNotEmpty && node.expanded) {
        _buildLines(
          node.children,
          '$prefix$childPrefix',
          false,
          lines,
          labelStyle,
          connectorStyle,
          theme,
        );
      }
    }
  }
}
