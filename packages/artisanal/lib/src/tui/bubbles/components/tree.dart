import '../../../style/color.dart';
import '../../../style/properties.dart';
import '../../../style/style.dart';
import '../../../layout/layout.dart';
import 'base.dart';

/// Callback for per-item styling in trees.
///
/// [item] is the item being rendered (the label/name).
/// [depth] is the nesting depth (0 for root level).
/// [isDirectory] indicates if the item has children.
///
/// Return a [Style] to apply to the item, or `null` for no styling.
typedef TreeStyleFunc =
    Style? Function(String item, int depth, bool isDirectory);

/// Callback for per-item enumerator (branch character) styling in trees.
///
/// [children] is the list of sibling items at the current level.
/// [index] is the index of the current item being rendered.
///
/// Return a [Style] to apply to the enumerator, or `null` for no styling.
///
/// Example:
/// ```dart
/// tree.enumeratorStyleFunc((children, index) {
///   if (index == selectedIndex) {
///     return Style().foreground(Colors.green);
///   }
///   return Style().foreground(Colors.dim);
/// });
/// ```
typedef TreeEnumeratorStyleFunc =
    Style? Function(List<dynamic> children, int index);

/// Defines the characters used to draw tree branches.
///
/// ```dart
/// // Use a preset
/// Tree().enumerator(TreeEnumerator.rounded)
///
/// // Or create custom
/// Tree().enumerator(TreeEnumerator(
///   pipe: '│',
///   tee: '├',
///   elbow: '╰',
///   dash: '──',
/// ))
/// ```
class TreeEnumerator {
  /// Creates a tree enumerator with the specified characters.
  const TreeEnumerator({
    required this.pipe,
    required this.tee,
    required this.elbow,
    required this.dash,
    this.indent = '   ',
  });

  /// Vertical pipe character for continuing branches.
  final String pipe;

  /// T-junction character for non-last items.
  final String tee;

  /// Elbow/corner character for last items.
  final String elbow;

  /// Horizontal dash connecting to items.
  final String dash;

  /// Indentation string when no pipe is needed.
  final String indent;

  // ─────────────────────────────────────────────────────────────────────────
  // Preset Enumerators
  // ─────────────────────────────────────────────────────────────────────────

  /// Normal/standard tree characters (├── └──).
  static const normal = TreeEnumerator(
    pipe: '│',
    tee: '├',
    elbow: '└',
    dash: '──',
    indent: '    ',
  );

  /// Rounded tree characters with curved elbow (├── ╰──).
  static const rounded = TreeEnumerator(
    pipe: '│',
    tee: '├',
    elbow: '╰',
    dash: '──',
    indent: '    ',
  );

  /// ASCII-only characters for maximum compatibility (+-- `--).
  static const ascii = TreeEnumerator(
    pipe: '|',
    tee: '+',
    elbow: '`',
    dash: '--',
    indent: '    ',
  );

  /// Bullet-style list (• for all items).
  static const bullet = TreeEnumerator(
    pipe: ' ',
    tee: '•',
    elbow: '•',
    dash: ' ',
    indent: '  ',
  );

  /// Arrow-style list (→ for all items).
  static const arrow = TreeEnumerator(
    pipe: ' ',
    tee: '→',
    elbow: '→',
    dash: ' ',
    indent: '  ',
  );

  /// Dash-style list (- for all items).
  static const dash_ = TreeEnumerator(
    pipe: ' ',
    tee: '-',
    elbow: '-',
    dash: ' ',
    indent: '  ',
  );

  /// Heavy/thick tree characters.
  static const heavy = TreeEnumerator(
    pipe: '┃',
    tee: '┣',
    elbow: '┗',
    dash: '━━',
    indent: '    ',
  );

  /// Double-line tree characters.
  static const doubleLine = TreeEnumerator(
    pipe: '║',
    tee: '╠',
    elbow: '╚',
    dash: '══',
    indent: '    ',
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreeEnumerator &&
        other.pipe == pipe &&
        other.tee == tee &&
        other.elbow == elbow &&
        other.dash == dash &&
        other.indent == indent;
  }

  @override
  int get hashCode => Object.hash(pipe, tee, elbow, dash, indent);

  @override
  String toString() => 'TreeEnumerator(pipe: $pipe, tee: $tee, elbow: $elbow)';
}

/// A tree structure component.
///
/// ```dart
/// TreeComponent(
///   data: {
///     'src': {
///       'lib': ['main.dart', 'utils.dart'],
///       'test': ['main_test.dart'],
///     },
///     'pubspec.yaml': null,
///   },
/// ).renderln(context);
/// ```
class TreeComponent extends DisplayComponent {
  final Map<String, dynamic> data;
  final bool showRoot;
  final String rootLabel;

  /// The tree enumerator (branch characters) to use.
  final TreeEnumerator enumerator;

  /// Optional callback for per-item styling.
  final TreeStyleFunc? itemStyleFunc;

  /// Creates a TreeComponent with optional enumerator.
  const TreeComponent({
    required this.data,
    this.showRoot = false,
    this.rootLabel = '.',
    this.enumerator = TreeEnumerator.normal,
    this.itemStyleFunc,
    this.renderConfig = const RenderConfig(),
  });

  @override
  String render() {
    final buffer = StringBuffer();
    final nodeStyle = renderConfig.configureStyle(
      Style().foreground(Colors.info),
    );
    String nodeFn(String s) => nodeStyle.render(s);
    String leafFn(String s) => s;
    final e = enumerator;

    if (showRoot) {
      String label = rootLabel;
      if (itemStyleFunc != null) {
        final style = itemStyleFunc!(rootLabel, 0, true);
        if (style != null) {
          renderConfig.configureStyle(style);
          label = style.render(rootLabel);
        } else {
          label = nodeFn(rootLabel);
        }
      } else {
        label = nodeFn(rootLabel);
      }
      buffer.writeln(label);
    }

    _renderNode(buffer, data, '', true, nodeFn, leafFn, e, 0);

    return buffer.toString().trimRight();
  }

  final RenderConfig renderConfig;

  void _renderNode(
    StringBuffer buffer,
    dynamic node,
    String prefix,
    bool isLast,
    String Function(String) nodeFn,
    String Function(String) leafFn,
    TreeEnumerator e,
    int depth,
  ) {
    if (node is Map<String, dynamic>) {
      final entries = node.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLastEntry = i == entries.length - 1;
        final connector = isLastEntry ? e.elbow : e.tee;

        final isDirectory = entry.value is Map || entry.value is List;
        String label = entry.key;

        if (itemStyleFunc != null) {
          final style = itemStyleFunc!(label, depth + 1, isDirectory);
          if (style != null) {
            renderConfig.configureStyle(style);
            label = style.render(label);
          } else if (isDirectory) {
            label = nodeFn(label);
          } else {
            label = leafFn(label);
          }
        } else {
          if (isDirectory) {
            label = nodeFn(label);
          } else {
            label = leafFn(label);
          }
        }

        if (isDirectory) {
          buffer.writeln('$prefix$connector${e.dash} $label');
          final newPrefix = prefix + (isLastEntry ? e.indent : '${e.pipe}   ');
          _renderNode(
            buffer,
            entry.value,
            newPrefix,
            isLastEntry,
            nodeFn,
            leafFn,
            e,
            depth + 1,
          );
        } else {
          buffer.writeln('$prefix$connector${e.dash} $label');
        }
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final item = node[i];
        final isLastItem = i == node.length - 1;
        final connector = isLastItem ? e.elbow : e.tee;

        final isDirectory = item is Map || item is List;

        if (isDirectory) {
          _renderNode(
            buffer,
            item,
            prefix,
            isLastItem,
            nodeFn,
            leafFn,
            e,
            depth,
          );
        } else {
          String label = item.toString();
          if (itemStyleFunc != null) {
            final style = itemStyleFunc!(label, depth + 1, false);
            if (style != null) {
              renderConfig.configureStyle(style);
              label = style.render(label);
            } else {
              label = leafFn(label);
            }
          } else {
            label = leafFn(label);
          }

          buffer.writeln('$prefix$connector${e.dash} $label');
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Tree Builder
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class TreeNode {
  String get value;
  Iterable<TreeNode> get childrenNodes;
  bool get hidden;
}

abstract interface class TreeChildren {
  TreeNode? at(int index);
  int get length;
}

final class TreeNodeChildren implements TreeChildren {
  TreeNodeChildren(this._nodes);
  final List<TreeNode> _nodes;

  @override
  TreeNode? at(int index) =>
      (index >= 0 && index < _nodes.length) ? _nodes[index] : null;

  @override
  int get length => _nodes.length;
}

final class TreeStringData implements TreeChildren {
  TreeStringData(this._values);
  final List<String> _values;

  @override
  TreeNode? at(int index) =>
      (index >= 0 && index < _values.length) ? _TreeLeaf(_values[index]) : null;

  @override
  int get length => _values.length;
}

final class TreeFilter implements TreeChildren {
  TreeFilter(this._data);

  final TreeChildren _data;
  bool Function(int index)? _filter;

  TreeFilter filter(bool Function(int index) fn) {
    _filter = fn;
    return this;
  }

  @override
  TreeNode? at(int index) {
    final f = _filter;
    if (f == null) return null;

    var j = 0;
    for (var i = 0; i < _data.length; i++) {
      if (f(i)) {
        if (j == index) return _data.at(i);
        j++;
      }
    }
    return null;
  }

  @override
  int get length {
    final f = _filter;
    if (f == null) return 0;
    var j = 0;
    for (var i = 0; i < _data.length; i++) {
      if (f(i)) j++;
    }
    return j;
  }
}

final class _TreeLeaf implements TreeNode {
  _TreeLeaf(this._value, {bool hidden = false}) : _hidden = hidden;

  final String _value;
  final bool _hidden;

  @override
  String get value => _value;

  @override
  Iterable<TreeNode> get childrenNodes => const [];

  @override
  bool get hidden => _hidden;
}

typedef TreeEnumeratorFunc =
    String Function(List<TreeNode> children, int index);
typedef TreeIndenterFunc = String Function(List<TreeNode> children, int index);
typedef TreeNodeStyleFunc = Style Function(List<TreeNode> children, int index);

String _defaultEnumerator(List<TreeNode> children, int index) {
  if (children.length - 1 == index) return '└──';
  return '├──';
}

String _defaultIndenter(List<TreeNode> children, int index) {
  if (children.length - 1 == index) return '   ';
  return '│  ';
}

final class _TreeRendererStyle {
  _TreeRendererStyle({
    required this.enumeratorStyle,
    required this.indenterStyle,
    required this.itemStyle,
    required this.rootStyle,
  });

  TreeNodeStyleFunc enumeratorStyle;
  TreeNodeStyleFunc indenterStyle;
  TreeNodeStyleFunc itemStyle;
  Style rootStyle;
}

final class _TreeRenderer {
  _TreeRenderer()
    : style = _TreeRendererStyle(
        enumeratorStyle: (_, _) => Style().paddingRight(1),
        indenterStyle: (_, _) => Style().paddingRight(1),
        itemStyle: (_, _) => Style(),
        rootStyle: Style(),
      ),
      enumerator = _defaultEnumerator,
      indenter = _defaultIndenter,
      width = 0;

  final _TreeRendererStyle style;
  TreeEnumeratorFunc enumerator;
  TreeIndenterFunc indenter;
  int width;
}

/// A fluent builder for creating styled trees (lipgloss v2 parity).
///
/// This mirrors `charm.land/lipgloss/v2/tree` behavior:
/// - Per-node hide + child filtering
/// - Auto-parenting unnamed subtrees to previous siblings
/// - Separate enumerator/indenter functions + styles
/// - Multiline items and mixed prefix widths are aligned
/// A component for rendering hierarchical tree structures.
///
/// The [Tree] component supports:
/// - Nested children with arbitrary depth.
/// - Custom enumerators (branch characters) like bullets, numbers, or custom strings.
/// - Per-item and per-enumerator styling.
/// - Automatic indentation and branch line rendering.
///
/// Example:
/// ```dart
/// final tree = Tree(['Root'])
///   .children([
///     Tree(['Child 1']),
///     Tree(['Child 2']).children([
///       Tree(['Grandchild']),
///     ]),
///   ]);
///
/// print(tree.render());
/// ```
class Tree extends DisplayComponent implements TreeNode {
  Tree({RenderConfig renderConfig = const RenderConfig(), bool showRoot = true})
    : _renderConfig = renderConfig,
      _showRoot = showRoot;

  final RenderConfig _renderConfig;

  String _value = '';
  bool _hidden = false;
  int _offsetStart = 0;
  int _offsetEnd = 0;
  final List<TreeNode> _children = <TreeNode>[];
  bool _showRoot;

  _TreeRenderer? _renderer; // null => inherit parent renderer

  _TreeRenderer _ensureRenderer() => _renderer ??= _TreeRenderer();

  @override
  String get value => _value;

  Tree root(Object? label) {
    _value = label?.toString() ?? '';
    return this;
  }

  Tree showRoot(bool value) {
    _showRoot = value;
    return this;
  }

  @override
  bool get hidden => _hidden;

  Tree hide(bool value) {
    _hidden = value;
    return this;
  }

  Tree offset(int start, [int end = 0]) {
    var s = start;
    var e = end;
    if (s > e) {
      final tmp = s;
      s = e;
      e = tmp;
    }
    if (s < 0) s = 0;
    if (e < 0 || e > _children.length) e = _children.length;
    _offsetStart = s;
    _offsetEnd = e;
    return this;
  }

  @override
  Iterable<TreeNode> get childrenNodes {
    final len = _children.length;
    final end = (len - _offsetEnd).clamp(0, len);
    final start = _offsetStart.clamp(0, end);
    return _children.sublist(start, end);
  }

  List<TreeNode> _visibleChildren() =>
      childrenNodes.where((c) => !c.hidden).toList(growable: false);

  Tree child(Object? item) {
    switch (item) {
      case null:
        return this;

      case TreeChildren data:
        for (var i = 0; i < data.length; i++) {
          child(data.at(i));
        }
        return this;

      case List<dynamic> items:
        for (final it in items) {
          child(it);
        }
        return this;

      case Iterable<dynamic> items:
        for (final it in items) {
          child(it);
        }
        return this;

      case Tree t:
        return _appendTree(t);

      case TreeNode n:
        _children.add(n);
        return this;

      default:
        _children.add(_TreeLeaf(item.toString()));
        return this;
    }
  }

  Tree childrenAll(List<dynamic> items) => children(items);

  Tree children(List<dynamic> items) {
    for (final it in items) {
      child(it);
    }
    return this;
  }

  Tree _appendTree(Tree t) {
    // Auto-parent unnamed trees to the previous sibling.
    if (t.value.isEmpty && _children.isNotEmpty) {
      final parent = _children.last;
      switch (parent) {
        case Tree parentTree:
          for (final c in t.childrenNodes) {
            parentTree._children.add(c);
          }
          return this;
        case _TreeLeaf leaf:
          _children.removeLast();
          t._value = leaf.value;
          _children.add(t);
          return this;
        default:
          break;
      }
    }

    _children.add(t);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // v2 parity configuration surface
  // ─────────────────────────────────────────────────────────────────────────

  Tree enumerator(Object enumerator) {
    // Back-compat: map our preset enumerators onto v2 enumerator/indenter funcs.
    if (enumerator is TreeEnumerator) {
      final e = enumerator;

      String indenter(List<TreeNode> children, int index) {
        final isLast = children.length - 1 == index;
        final dashWidth = Style.visibleLength(e.dash);
        final pipeWidth = Style.visibleLength(e.pipe);
        final w = pipeWidth + dashWidth;
        if (isLast) return ' ' * w;
        return '${e.pipe}${' ' * dashWidth}';
      }

      String enumr(List<TreeNode> children, int index) {
        final isLast = children.length - 1 == index;
        return '${isLast ? e.elbow : e.tee}${e.dash}';
      }

      return enumeratorFunc(enumr).indenterFunc(indenter);
    }

    // Unknown enumerator object: fall back to the default.
    return enumeratorFunc(_defaultEnumerator).indenterFunc(_defaultIndenter);
  }

  Tree enumeratorFunc(TreeEnumeratorFunc fn) {
    _ensureRenderer().enumerator = fn;
    return this;
  }

  Tree indenterFunc(TreeIndenterFunc fn) {
    _ensureRenderer().indenter = fn;
    return this;
  }

  Tree width(int width) {
    _ensureRenderer().width = width;
    return this;
  }

  Tree rootStyle(Style style) {
    _ensureRenderer().style.rootStyle = style;
    return this;
  }

  Tree enumeratorStyle(Style style) {
    _ensureRenderer().style.enumeratorStyle = (_, _) => style;
    return this;
  }

  /// Sets the enumeration style function. Use this for conditional styling.
  ///
  /// This mirrors `lipgloss` v2 `EnumeratorStyleFunc`.
  Tree enumeratorStyleFunc(TreeNodeStyleFunc fn) {
    _ensureRenderer().style.enumeratorStyle = fn;
    return this;
  }

  Tree indenterStyle(Style style) {
    _ensureRenderer().style.indenterStyle = (_, _) => style;
    return this;
  }

  /// Sets the indentation style function. Use this for conditional styling.
  ///
  /// This mirrors `lipgloss` v2 `IndenterStyleFunc`.
  Tree indenterStyleFunc(TreeNodeStyleFunc fn) {
    _ensureRenderer().style.indenterStyle = fn;
    return this;
  }

  Tree itemStyle(Style style) {
    _ensureRenderer().style.itemStyle = (_, _) => style;
    return this;
  }

  /// Sets the item style function. Use this for conditional styling.
  ///
  /// This mirrors `lipgloss` v2 `ItemStyleFunc`.
  Tree itemStyleFunc(TreeNodeStyleFunc fn) {
    _ensureRenderer().style.itemStyle = fn;
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rendering
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String render() {
    if (_hidden) return '';
    final renderer = _ensureRenderer();
    return _renderWith(renderer, prefix: '', isRoot: true);
  }

  String _renderWith(
    _TreeRenderer renderer, {
    required String prefix,
    required bool isRoot,
  }) {
    if (_hidden) return '';

    final children = _visibleChildren();
    final enumerator = renderer.enumerator;
    final indenter = renderer.indenter;

    final out = <String>[];

    // Print root (if any).
    if (isRoot && _showRoot && _value.isNotEmpty) {
      final line = _renderConfig
          .configureStyle(renderer.style.rootStyle)
          .render(_value);
      out.add(line);
    }

    // Compute max prefix width (after styling).
    var maxLen = 0;
    for (var i = 0; i < children.length; i++) {
      final enumStyle = _renderConfig.configureStyle(
        renderer.style.enumeratorStyle(children, i),
      );
      final p = enumStyle.render(enumerator(children, i));
      maxLen = maxLen < Layout.visibleLength(p)
          ? Layout.visibleLength(p)
          : maxLen;
    }

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (child.hidden) continue;

      final enumStyle = _renderConfig.configureStyle(
        renderer.style.enumeratorStyle(children, i),
      );
      final indentStyle = _renderConfig.configureStyle(
        renderer.style.indenterStyle(children, i),
      );
      final itemStyle = _renderConfig.configureStyle(
        renderer.style.itemStyle(children, i),
      );

      final indent = indentStyle.render(indenter(children, i));
      var nodePrefix = enumStyle.render(enumerator(children, i));

      final bg = enumStyle.getBackground;
      final enumBgStyle = bg == null ? Style() : Style().background(bg);
      final padLeft = maxLen - Layout.visibleLength(nodePrefix);
      if (padLeft > 0) {
        nodePrefix = enumBgStyle.render(' ' * padLeft) + nodePrefix;
      }

      final item = itemStyle.render(child.value);
      var multiPrefix = enumBgStyle.render(prefix);

      while (item.split('\n').length > nodePrefix.split('\n').length) {
        nodePrefix = Layout.joinVertical(HorizontalAlign.left, [
          nodePrefix,
          indent,
        ]);
      }

      while (nodePrefix.split('\n').length > multiPrefix.split('\n').length) {
        multiPrefix = Layout.joinVertical(HorizontalAlign.left, [
          multiPrefix,
          prefix,
        ]);
      }

      var line = Layout.joinHorizontal(VerticalAlign.top, [
        multiPrefix,
        nodePrefix,
        item,
      ]);

      final w = renderer.width;
      if (w > 0) {
        final pad = w - Layout.visibleLength(line);
        if (pad > 0) {
          line = line + itemStyle.render(' ' * pad);
        }
      }

      out.add(line);

      final childChildren = child.childrenNodes
          .where((c) => !c.hidden)
          .toList();
      if (childChildren.isEmpty) continue;

      // Use a child renderer if the child has one, otherwise inherit.
      var nextRenderer = renderer;
      var nextPrefix = prefix + indent;
      if (child is Tree && child._renderer != null) {
        nextRenderer = child._renderer!;
        nextPrefix = prefix + indent;
      }

      final subtree = switch (child) {
        Tree t => t._renderWith(
          nextRenderer,
          prefix: nextPrefix,
          isRoot: false,
        ),
        _ => '',
      };

      if (subtree.isNotEmpty) out.add(subtree);
    }

    return out.join('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common tree styles.
extension TreeFactory on Tree {
  /// Creates a tree from a nested map structure.
  static Tree fromMap(Map<String, dynamic> data, {String? root}) {
    final tree = Tree();
    if (root != null) tree.root(root);

    void addItems(Tree t, Map<String, dynamic> map) {
      for (final entry in map.entries) {
        if (entry.value is Map<String, dynamic>) {
          final subtree = Tree()..root(entry.key);
          addItems(subtree, entry.value as Map<String, dynamic>);
          t.child(subtree);
        } else if (entry.value is List) {
          final subtree = Tree()..root(entry.key);
          for (final item in entry.value as List) {
            if (item is Map<String, dynamic>) {
              final nested = Tree();
              addItems(nested, item);
              subtree.child(nested);
            } else {
              subtree.child(item.toString());
            }
          }
          t.child(subtree);
        } else {
          t.child(entry.key);
        }
      }
    }

    addItems(tree, data);
    return tree;
  }

  /// Creates a file tree with directory styling.
  static Tree fileTree(Map<String, dynamic> structure, {String? root}) {
    return fromMap(structure, root: root)
      ..enumerator(TreeEnumerator.normal)
      ..itemStyleFunc((children, index) {
        final node = children[index];
        if (node.childrenNodes.isNotEmpty) {
          return Style().bold().foreground(Colors.info);
        }
        return Style().foreground(Colors.white);
      });
  }

  /// Creates a rounded tree.
  static Tree rounded(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.rounded);
  }

  /// Creates an ASCII-compatible tree.
  static Tree ascii(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.ascii);
  }

  /// Creates a bullet-style list tree.
  static Tree bulletList(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.bullet);
  }

  /// Creates an arrow-style list tree.
  static Tree arrowList(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.arrow);
  }

  /// Creates a tree with colored depth levels.
  static Tree coloredDepth(String rootLabel, {List<Color>? depthColors}) {
    final colors =
        depthColors ??
        [Colors.info, Colors.cyan, Colors.green, Colors.yellow, Colors.magenta];

    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.rounded)
      ..itemStyleFunc((children, index) {
        final node = children[index];
        final isDir = node.childrenNodes.isNotEmpty;
        final colorIndex = index % colors.length;
        final style = Style().foreground(colors[colorIndex]);
        if (isDir) return style.bold();
        return style;
      });
  }

  /// Creates a tree that highlights directories.
  static Tree highlightDirectories(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.normal)
      ..itemStyleFunc((children, index) {
        final node = children[index];
        if (node.childrenNodes.isNotEmpty) {
          return Style().bold().foreground(Colors.info);
        }
        return Style();
      })
      ..enumeratorStyle(Style().dim())
      ..indenterStyle(Style().dim());
  }

  /// Creates a tree with muted styling.
  static Tree muted(String rootLabel) {
    return Tree()
      ..root(rootLabel)
      ..enumerator(TreeEnumerator.normal)
      ..rootStyle(Style().dim())
      ..itemStyle(Style().dim())
      ..enumeratorStyle(Style().dim())
      ..indenterStyle(Style().dim());
  }
}
