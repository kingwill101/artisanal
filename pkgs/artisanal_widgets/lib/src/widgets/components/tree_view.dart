
import 'package:artisanal/widgets.dart';

import 'package:artisanal/style.dart' show Color, Border, Style, Colors;


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

  /// Number of characters per indent level (minimum 2).
  ///
  /// Controls the width of tree connectors and continuation lines.
  /// The default value of 2 produces compact output like:
  /// ```
  /// ├─ item
  /// │ ├─ child
  /// ```
  /// A value of 4 produces wider output:
  /// ```
  /// ├─── item
  /// │   ├─── child
  /// ```
  final int indentSize;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final lStyle = copyStyle(labelStyle ?? theme.bodyMedium)
      ..foreground(theme.onSurface);
    final cStyle = copyStyle(connectorStyle ?? theme.bodySmall)
      ..foreground(theme.border);

    final effectiveIndent = indentSize < 2 ? 2 : indentSize;
    final lines = <Widget>[];
    _buildLines(nodes, '', true, lines, lStyle, cStyle, theme, effectiveIndent);
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
    int indent,
  ) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isLast = i == nodes.length - 1;
      // Build connector: branch char + (indent - 1) dashes + space
      // e.g. indent=2 → '└─ ', indent=4 → '└─── '
      final dashes = '─' * (indent - 1);
      final connector = isRoot ? '' : (isLast ? '└$dashes ' : '├$dashes ');
      // Build child prefix: pipe/space + (indent - 1) spaces + space
      final padding = ' ' * (indent - 1);
      final childPrefix = isRoot ? '' : (isLast ? ' $padding ' : '│$padding ');

      final resolvedLabelStyle = node.style != null
          ? copyStyle(node.style!)
          : copyStyle(labelStyle);

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
          indent,
        );
      }
    }
  }
}
