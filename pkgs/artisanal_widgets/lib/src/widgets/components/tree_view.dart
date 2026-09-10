import 'package:artisanal/bubbles.dart' as bubbles;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/style.dart' show Style;

import '_component_foundation.dart';
import 'scroll_area.dart';

/// Builds a widget for one projected [bubbles.TreeRow].
typedef TreeViewItemBuilder<T> =
    Widget Function(BuildContext context, bubbles.TreeRow<T> row);

/// Handles selection or activation of a tree item.
typedef TreeViewItemCallback<T> =
    runtime.Cmd? Function(bubbles.TreeItem<T> item);

/// Handles a change to a branch's expansion state.
typedef TreeViewToggleCallback<T> =
    runtime.Cmd? Function(bubbles.TreeItem<T> item, bool expanded);

/// A node in the compatibility [TreeView] constructor.
///
/// Use [TreeView.model] with [bubbles.TreeItem] when expansion, selection, and
/// viewport state must be shared with another host. This class remains useful
/// for concise, display-oriented trees and preserves the original `TreeView`
/// API.
///
/// Named `TreeViewNode` to avoid collision with the bubbles `TreeNode`
/// interface from `package:artisanal`.
class TreeViewNode<T> {
  const TreeViewNode({
    required this.label,
    this.children = const [],
    this.style,
    this.icon,
    this.expanded = true,
    this.id,
    this.value,
    this.selectable = true,
  });

  /// The text label for this node.
  final String label;

  /// Child nodes.
  final List<TreeViewNode<T>> children;

  /// Optional style override for this node's label.
  final Style? style;

  /// Optional icon/prefix for this node (for example, `"📁"` or `"📄"`).
  final String? icon;

  /// Whether this node's children are initially shown.
  final bool expanded;

  /// Optional stable identity.
  ///
  /// Positional path IDs are generated when this is omitted.
  final String? id;

  /// Optional consumer value used by selection and activation callbacks.
  final T? value;

  /// Whether this node may receive selection.
  final bool selectable;

  /// Creates a [TreeViewNode] from a map structure.
  ///
  /// Expected format:
  /// ```json
  /// {"label": "Root", "children": [...], "icon": "📁"}
  /// ```
  factory TreeViewNode.fromMap(Map<String, dynamic> map) {
    final childrenRaw = map['children'] as List?;
    final children =
        childrenRaw?.map((child) {
          return TreeViewNode<T>.fromMap(child as Map<String, dynamic>);
        }).toList() ??
        const [];
    return TreeViewNode<T>(
      label: (map['label'] ?? map['name'] ?? '') as String,
      children: children,
      icon: map['icon'] as String?,
      expanded: (map['expanded'] as bool?) ?? true,
      id: map['id'] as String?,
      value: map['value'] as T?,
      selectable: (map['selectable'] as bool?) ?? true,
    );
  }
}

/// An interactive hierarchical tree backed by [bubbles.TreeModel].
///
/// The default constructor preserves the concise [TreeViewNode] API. Use
/// [TreeView.model] when a Bubble Tea application and widget tree need to
/// share expansion, selection, keyboard navigation, and scroll position.
///
/// Mouse taps select rows, toggle branches, and activate leaves. A focused
/// tree supports arrow keys, Vim-style `hjkl`, home/end, page navigation,
/// `H`/`L` horizontal panning, space to toggle, and enter to activate.
///
/// ```dart
/// final model = TreeModel<String>(
///   items: [TreeItem(id: 'src', label: 'src', value: 'src')],
/// );
///
/// TreeView<String>.model(
///   model: model,
///   height: 12,
///   onActivated: (item) => open(item.value),
/// )
/// ```
class TreeView<T> extends StatefulWidget {
  TreeView({
    required this.nodes,
    this.labelStyle,
    this.connectorStyle,
    this.indentSize = 2,
    this.height,
    this.width,
    this.showScrollbar = true,
    this.showExpandIndicators = false,
    this.showSelection = false,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    this.onSelected,
    this.onActivated,
    this.onToggle,
    super.key,
  }) : model = null,
       itemBuilder = null;

  /// Creates a widget that renders and controls an existing tree model.
  TreeView.model({
    required this.model,
    this.itemBuilder,
    this.labelStyle,
    this.connectorStyle,
    this.height,
    this.width,
    this.showScrollbar = true,
    this.showExpandIndicators = true,
    this.showSelection = true,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    this.onSelected,
    this.onActivated,
    this.onToggle,
    super.key,
  }) : nodes = null,
       indentSize = model!.indentSize;

  /// Compatibility nodes used by the default constructor.
  final List<TreeViewNode<T>>? nodes;

  /// Externally owned model used by [TreeView.model].
  final bubbles.TreeModel<T>? model;

  /// Optional renderer for projected rows.
  final TreeViewItemBuilder<T>? itemBuilder;

  /// Default style for node labels.
  final Style? labelStyle;

  /// Style for connector lines.
  final Style? connectorStyle;

  /// Number of characters per indent level (minimum 2).
  final int indentSize;

  /// Optional viewport height.
  final int? height;

  /// Optional horizontal viewport width used to bound panning.
  final int? width;

  /// Whether a scrollbar is shown when [height] constrains the tree.
  final bool showScrollbar;

  /// Whether the default renderer shows branch expansion indicators.
  final bool showExpandIndicators;

  /// Whether the default renderer visually distinguishes the selected row.
  final bool showSelection;

  /// Whether this tree requests keyboard focus on first build.
  final bool autofocus;

  /// Optional identifier used by the focus controller.
  final String? focusId;

  /// Optional controller shared with other focusable widgets.
  final FocusController? focusController;

  /// Called after selection changes.
  final TreeViewItemCallback<T>? onSelected;

  /// Called when a leaf is tapped or the selected item is activated.
  final TreeViewItemCallback<T>? onActivated;

  /// Called after a branch changes expansion state.
  final TreeViewToggleCallback<T>? onToggle;

  @override
  State<TreeView<T>> createState() => _TreeViewState<T>();
}

class _TreeViewState<T> extends State<TreeView<T>> {
  late bubbles.TreeModel<T> _model;
  late _TreeModelScrollController<T> _scrollController;
  Map<String, TreeViewNode<T>> _compatibilityNodes = const {};

  @override
  void initState() {
    super.initState();
    _model = _resolveModel();
    _scrollController = _TreeModelScrollController(_model);
  }

  @override
  runtime.Cmd? didUpdateWidget(covariant TreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != null && !identical(widget.model, _model)) {
      _scrollController.dispose();
      _model = widget.model!;
      _scrollController = _TreeModelScrollController(_model);
    } else if (widget.model == null) {
      final items = _compatibilityItems(widget.nodes ?? const []);
      _model
        ..indentSize = widget.indentSize.clamp(2, 1 << 20)
        ..replaceItems(items);
      _scrollController.notify();
    }
    return null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bubbles.TreeModel<T> _resolveModel() {
    final external = widget.model;
    if (external != null) return external;
    return bubbles.TreeModel<T>(
      items: _compatibilityItems(widget.nodes ?? const []),
      indentSize: widget.indentSize.clamp(2, 1 << 20),
    );
  }

  List<bubbles.TreeItem<T>> _compatibilityItems(List<TreeViewNode<T>> nodes) {
    final byId = <String, TreeViewNode<T>>{};

    List<bubbles.TreeItem<T>> convert(
      List<TreeViewNode<T>> source,
      String parentPath,
    ) {
      return [
        for (var index = 0; index < source.length; index++)
          (() {
            final node = source[index];
            final path = parentPath.isEmpty ? '$index' : '$parentPath/$index';
            final id = node.id ?? path;
            byId[id] = node;
            return bubbles.TreeItem<T>(
              id: id,
              label: node.label,
              value: (node.value ?? node) as T,
              children: convert(node.children, path),
              icon: node.icon,
              initiallyExpanded: node.expanded,
              selectable: node.selectable,
            );
          })(),
      ];
    }

    final items = convert(nodes, '');
    _compatibilityNodes = byId;
    return items;
  }

  runtime.Cmd? _handleKey(runtime.KeyMsg message) {
    final selectedBefore = _model.selectedItem?.id;
    final expandedBefore = <String, bool>{
      for (final row in _model.rows)
        if (row.item.hasChildren) row.item.id: row.isExpanded,
    };
    final isActivation = runtime.keyMatches(message.key, [
      _model.keyMap.activate,
    ]);
    final (_, command) = _model.update(message);
    final selectedAfter = _model.selectedItem;
    final callbackCommands = <runtime.Cmd?>[];
    if (selectedAfter != null && selectedAfter.id != selectedBefore) {
      callbackCommands.add(widget.onSelected?.call(selectedAfter));
    }
    for (final row in _model.rows) {
      final before = expandedBefore[row.item.id];
      if (before != null && before != row.isExpanded) {
        callbackCommands.add(widget.onToggle?.call(row.item, row.isExpanded));
      }
    }
    if (isActivation && selectedAfter != null && widget.onActivated != null) {
      callbackCommands.add(widget.onActivated!(selectedAfter));
    } else {
      callbackCommands.add(command);
    }
    setState(() {});
    _scrollController.notify();
    return _batch(callbackCommands);
  }

  runtime.Cmd? _handleTap(bubbles.TreeRow<T> row) {
    final changedSelection = _model.select(row.item.id);
    runtime.Cmd? action;
    if (row.item.hasChildren) {
      final changed = _model.toggle(row.item.id);
      if (changed) {
        action = widget.onToggle?.call(
          row.item,
          _model.isExpanded(row.item.id),
        );
      }
    } else {
      action = widget.onActivated?.call(row.item);
    }
    setState(() {});
    _scrollController.notify();
    return _batch([
      if (changedSelection) widget.onSelected?.call(row.item),
      action,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.height case final height?) {
      _model.height = height.clamp(0, 1 << 20);
    } else {
      _model.height = 0;
    }
    _model.width = widget.width?.clamp(0, 1 << 20) ?? 0;
    _model.setOffset(_model.offset);
    _model.setHorizontalOffset(_model.horizontalOffset);

    final rows = _model.rows;
    Widget result = Column(
      gap: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          GestureDetector(
            key: ValueKey('tree-row:${row.item.id}'),
            onTap: () => _handleTap(row),
            child:
                widget.itemBuilder?.call(context, row) ??
                _buildDefaultRow(context, row),
          ),
      ],
    );

    if (widget.height case final height?) {
      result = ScrollArea(
        controller: _scrollController,
        height: height,
        showScrollbar: widget.showScrollbar,
        child: result,
      );
    }

    return Focusable(
      controller: widget.focusController ?? FocusScope.of(context),
      focusId: widget.focusId,
      autofocus: widget.autofocus,
      onKey: _handleKey,
      child: result,
    );
  }

  Widget _buildDefaultRow(BuildContext context, bubbles.TreeRow<T> row) {
    final theme = ThemeScope.of(context);
    final compatibilityNode = _compatibilityNodes[row.item.id];
    final labelStyle = copyStyle(
      compatibilityNode?.style ?? widget.labelStyle ?? theme.bodyMedium,
    )..foreground(theme.onSurface);
    if (widget.showSelection && row.isSelected) labelStyle.bold();
    final connectorStyle = copyStyle(widget.connectorStyle ?? theme.bodySmall)
      ..foreground(theme.border);
    final indicator = widget.showExpandIndicators
        ? row.item.hasChildren
              ? row.isExpanded
                    ? '▾ '
                    : '▸ '
              : '  '
        : '';
    final icon = row.item.icon == null ? '' : '${row.item.icon} ';
    var remainingOffset = _model.horizontalOffset;

    String renderSegment(String value, Style style) {
      if (value.isEmpty) return '';
      if (remainingOffset >= value.length) {
        remainingOffset -= value.length;
        return '';
      }
      final visible = value.substring(remainingOffset);
      remainingOffset = 0;
      return style.render(visible);
    }

    return Text(
      '${renderSegment(row.prefix + row.connector, connectorStyle)}'
      '${renderSegment(indicator + icon, labelStyle)}'
      '${renderSegment(row.item.label, labelStyle)}',
      softWrap: false,
      overflow: TextOverflow.clip,
    );
  }
}

final class _TreeModelScrollController<T> implements ScrollController {
  _TreeModelScrollController(this.model);

  final bubbles.TreeModel<T> model;
  final Set<void Function()> _listeners = {};

  @override
  int get offset => model.offset;

  @override
  int get viewportExtent => model.height;

  @override
  int get contentExtent => model.rows.length;

  @override
  int get maxOffset => model.maxOffset;

  @override
  double get scrollPercent => maxOffset == 0 ? 0 : offset / maxOffset;

  @override
  bool jumpTo(int offset) {
    final changed = model.setOffset(offset);
    if (changed) notify();
    return changed;
  }

  @override
  bool scrollBy(int delta) {
    final changed = model.scrollBy(delta);
    if (changed) notify();
    return changed;
  }

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void notify() {
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
  }

  void dispose() {
    _listeners.clear();
  }
}

runtime.Cmd? _batch(Iterable<runtime.Cmd?> commands) {
  final nonNull = commands.whereType<runtime.Cmd>().toList(growable: false);
  if (nonNull.isEmpty) return null;
  if (nonNull.length == 1) return nonNull.single;
  return runtime.Cmd.batch(nonNull);
}
