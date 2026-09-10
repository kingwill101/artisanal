import 'package:artisanal/style.dart';

import '../cmd.dart';
import '../component.dart';
import '../key_binding.dart';
import '../msg.dart';
import 'runeutil.dart' show stringWidth;

/// An immutable item in an interactive [TreeModel].
///
/// IDs must be unique across the complete tree. They are used to preserve
/// selection and expansion state when [TreeModel.replaceItems] is called.
final class TreeItem<T> {
  /// Creates a tree item.
  TreeItem({
    required this.id,
    required this.label,
    required this.value,
    List<TreeItem<T>> children = const [],
    this.icon,
    this.initiallyExpanded = true,
    this.selectable = true,
  }) : children = List.unmodifiable(children);

  /// Stable identity for this item.
  final String id;

  /// Text shown for this item.
  final String label;

  /// Consumer-owned value associated with this item.
  final T value;

  /// Nested child items.
  final List<TreeItem<T>> children;

  /// Optional icon rendered before [label].
  final String? icon;

  /// Initial expansion state when this item first enters a model.
  final bool initiallyExpanded;

  /// Whether keyboard and pointer selection may target this item.
  final bool selectable;

  /// Whether this item contains children.
  bool get hasChildren => children.isNotEmpty;
}

/// One projected row in an interactive tree.
final class TreeRow<T> {
  const TreeRow({
    required this.item,
    required this.depth,
    required this.prefix,
    required this.connector,
    required this.parentId,
    required this.isExpanded,
    required this.isSelected,
  });

  /// Source item represented by this row.
  final TreeItem<T> item;

  /// Zero-based nesting depth.
  final int depth;

  /// Continuation indentation before [connector].
  final String prefix;

  /// Branch connector for this row, or an empty string for root rows.
  final String connector;

  /// Parent item ID, or `null` for root rows.
  final String? parentId;

  /// Whether this row currently exposes its children.
  final bool isExpanded;

  /// Whether this is the model's selected row.
  final bool isSelected;
}

/// Message emitted when the selected tree item is activated.
final class TreeItemActivatedMsg<T> extends Msg {
  const TreeItemActivatedMsg(this.item);

  /// Activated item.
  final TreeItem<T> item;
}

/// Keyboard bindings for [TreeModel].
final class TreeKeyMap extends KeyMap {
  TreeKeyMap({
    KeyBinding? up,
    KeyBinding? down,
    KeyBinding? left,
    KeyBinding? right,
    KeyBinding? toggle,
    KeyBinding? activate,
    KeyBinding? home,
    KeyBinding? end,
    KeyBinding? pageUp,
    KeyBinding? pageDown,
    KeyBinding? panLeft,
    KeyBinding? panRight,
  }) : up =
           up ??
           KeyBinding(
             keys: const ['up', 'k'],
             help: const Help(key: '↑/k', desc: 'up'),
           ),
       down =
           down ??
           KeyBinding(
             keys: const ['down', 'j'],
             help: const Help(key: '↓/j', desc: 'down'),
           ),
       left =
           left ??
           KeyBinding(
             keys: const ['left', 'h'],
             help: const Help(key: '←/h', desc: 'collapse'),
           ),
       right =
           right ??
           KeyBinding(
             keys: const ['right', 'l'],
             help: const Help(key: '→/l', desc: 'expand'),
           ),
       toggle =
           toggle ??
           KeyBinding(
             keys: const ['space'],
             help: const Help(key: 'space', desc: 'toggle'),
           ),
       activate =
           activate ??
           KeyBinding(
             keys: const ['enter'],
             help: const Help(key: 'enter', desc: 'open'),
           ),
       home =
           home ??
           KeyBinding(
             keys: const ['home', 'g'],
             help: const Help(key: 'home', desc: 'first'),
           ),
       end =
           end ??
           KeyBinding(
             keys: const ['end', 'G'],
             help: const Help(key: 'end', desc: 'last'),
           ),
       pageUp =
           pageUp ??
           KeyBinding(
             keys: const ['pgup', 'ctrl+u'],
             help: const Help(key: 'pgup', desc: 'page up'),
           ),
       pageDown =
           pageDown ??
           KeyBinding(
             keys: const ['pgdown', 'ctrl+d'],
             help: const Help(key: 'pgdn', desc: 'page down'),
           ),
       panLeft =
           panLeft ??
           KeyBinding(
             keys: const ['shift+left', 'H'],
             help: const Help(key: 'H', desc: 'pan left'),
           ),
       panRight =
           panRight ??
           KeyBinding(
             keys: const ['shift+right', 'L'],
             help: const Help(key: 'L', desc: 'pan right'),
           ) {
    shortHelp = [this.up, this.down, this.toggle, this.activate];
    fullHelp = [
      [this.up, this.down, this.left, this.right],
      [this.home, this.end, this.pageUp, this.pageDown],
      [this.panLeft, this.panRight, this.toggle, this.activate],
    ];
  }

  final KeyBinding up;
  final KeyBinding down;
  final KeyBinding left;
  final KeyBinding right;
  final KeyBinding toggle;
  final KeyBinding activate;
  final KeyBinding home;
  final KeyBinding end;
  final KeyBinding pageUp;
  final KeyBinding pageDown;
  final KeyBinding panLeft;
  final KeyBinding panRight;
}

/// Styles used by [TreeModel.view].
final class TreeStyles {
  TreeStyles({
    Style? item,
    Style? selectedItem,
    Style? connector,
    Style? icon,
    this.cursor = '› ',
    this.expandedIndicator = '▾ ',
    this.collapsedIndicator = '▸ ',
    this.leafIndicator = '  ',
  }) : item = item ?? Style(),
       selectedItem = selectedItem ?? Style().bold(),
       connector = connector ?? Style().faint(),
       icon = icon ?? Style();

  final Style item;
  final Style selectedItem;
  final Style connector;
  final Style icon;
  final String cursor;
  final String expandedIndicator;
  final String collapsedIndicator;
  final String leafIndicator;
}

/// Shared state and interaction policy for hierarchical tree views.
///
/// The model owns stable expansion, selection, visible-row projection, and
/// viewport offset. String-based TEA applications can render [view] directly;
/// widget applications can render [rows] and control the same model.
///
/// {@category TUI}
final class TreeModel<T> extends ViewComponent {
  TreeModel({
    required Iterable<TreeItem<T>> items,
    this.height = 0,
    this.width = 0,
    this.indentSize = 2,
    this.mouseWheelDelta = 3,
    String? initialSelectedId,
    TreeKeyMap? keyMap,
    TreeStyles? styles,
  }) : assert(height >= 0),
       assert(width >= 0),
       assert(indentSize >= 2),
       assert(mouseWheelDelta > 0),
       keyMap = keyMap ?? TreeKeyMap(),
       styles = styles ?? TreeStyles(),
       _items = List.unmodifiable(items) {
    _validateUniqueIds(_items);
    _seedExpansion(_items);
    final projected = _projectRows();
    final requestedIndex = initialSelectedId == null
        ? -1
        : projected.indexWhere((row) => row.item.id == initialSelectedId);
    _cursor = requestedIndex >= 0
        ? requestedIndex
        : _firstSelectableIndex(projected);
    _clampState();
  }

  List<TreeItem<T>> _items;
  final Set<String> _expandedIds = {};
  int _cursor = -1;
  int _offset = 0;
  int _horizontalOffset = 0;

  /// Number of rows in the viewport. Zero shows all rows.
  int height;

  /// Number of cells in the horizontal viewport. Zero leaves panning unbound.
  int width;

  /// Number of cells in each branch indentation.
  int indentSize;

  /// Rows scrolled per mouse-wheel event.
  int mouseWheelDelta;

  /// Keyboard bindings.
  final TreeKeyMap keyMap;

  /// String renderer styles.
  final TreeStyles styles;

  /// Root tree items.
  List<TreeItem<T>> get items => List.unmodifiable(_items);

  /// Complete flattened projection after applying expansion state.
  List<TreeRow<T>> get rows => List.unmodifiable(_projectRows());

  /// Rows currently inside the model viewport.
  List<TreeRow<T>> get visibleRows {
    final projected = _projectRows();
    if (height <= 0 || projected.length <= height) {
      return List.unmodifiable(projected);
    }
    final start = _offset.clamp(0, _maxOffset(projected.length));
    return List.unmodifiable(
      projected.sublist(start, (start + height).clamp(0, projected.length)),
    );
  }

  /// Selected projected row index.
  int get cursor => _cursor;

  /// Current viewport offset.
  int get offset => _offset;

  /// Maximum viewport offset.
  int get maxOffset => _maxOffset(_projectRows().length);

  /// Number of cells hidden from the left edge by horizontal panning.
  int get horizontalOffset => _horizontalOffset;

  /// Maximum horizontal offset for the current rows and [width].
  int get maxHorizontalOffset {
    if (width <= 0) return 1 << 20;
    var contentWidth = 0;
    for (final row in _projectRows()) {
      final rowWidth = _rowTextWidth(row);
      if (rowWidth > contentWidth) contentWidth = rowWidth;
    }
    return (contentWidth - width).clamp(0, contentWidth);
  }

  /// Currently selected item.
  TreeItem<T>? get selectedItem {
    final projected = _projectRows();
    if (_cursor < 0 || _cursor >= projected.length) return null;
    return projected[_cursor].item;
  }

  /// Whether [id] is currently expanded.
  bool isExpanded(String id) => _expandedIds.contains(id);

  /// Replaces tree content while preserving state for IDs that remain.
  void replaceItems(Iterable<TreeItem<T>> items) {
    final replacement = List<TreeItem<T>>.unmodifiable(items);
    _validateUniqueIds(replacement);
    final previousSelection = selectedItem?.id;
    final previousIds = _allIds(_items);
    _items = replacement;
    for (final item in _walkItems(replacement)) {
      if (!previousIds.contains(item.id) && item.initiallyExpanded) {
        _expandedIds.add(item.id);
      }
    }
    _expandedIds.removeWhere((id) => !_containsId(replacement, id));
    final projected = _projectRows();
    final selectedIndex = previousSelection == null
        ? -1
        : projected.indexWhere((row) => row.item.id == previousSelection);
    _cursor = selectedIndex >= 0
        ? selectedIndex
        : _cursor.clamp(-1, projected.length - 1);
    if (_cursor < 0) _cursor = _firstSelectableIndex(projected);
    _clampState();
  }

  /// Selects the visible item with [id].
  bool select(String id) {
    final projected = _projectRows();
    final index = projected.indexWhere(
      (row) => row.item.id == id && row.item.selectable,
    );
    if (index < 0 || index == _cursor) return false;
    _cursor = index;
    _ensureCursorVisible(projected.length);
    return true;
  }

  /// Toggles a branch. Returns whether expansion state changed.
  bool toggle(String id) {
    final item = _findItem(id);
    if (item == null || !item.hasChildren) return false;
    final selectedId = selectedItem?.id;
    if (_expandedIds.contains(id)) {
      _expandedIds.remove(id);
    } else {
      _expandedIds.add(id);
    }
    _restoreSelection(id, selectedId: selectedId);
    return true;
  }

  /// Expands one branch.
  bool expand(String id) {
    final item = _findItem(id);
    if (item == null || !item.hasChildren || _expandedIds.contains(id)) {
      return false;
    }
    final selectedId = selectedItem?.id;
    _expandedIds.add(id);
    _restoreSelection(id, selectedId: selectedId);
    return true;
  }

  /// Collapses one branch.
  bool collapse(String id) {
    final selectedId = selectedItem?.id;
    if (!_expandedIds.remove(id)) return false;
    _restoreSelection(id, selectedId: selectedId);
    return true;
  }

  /// Expands every branch.
  void expandAll() {
    final selectedId = selectedItem?.id;
    for (final item in _walkItems(_items)) {
      if (item.hasChildren) _expandedIds.add(item.id);
    }
    _restoreSelection(selectedId ?? '', selectedId: selectedId);
  }

  /// Collapses every branch.
  void collapseAll() {
    final selectedPath = _itemPath(selectedItem?.id);
    _expandedIds.clear();
    _restoreSelectionFromPath(selectedPath);
  }

  /// Moves selection by [delta] visible selectable rows.
  bool moveBy(int delta) {
    if (delta == 0) return false;
    final projected = _projectRows();
    if (projected.isEmpty) return false;
    final direction = delta.sign;
    var remaining = delta.abs();
    var next = _cursor < 0 ? (direction > 0 ? -1 : projected.length) : _cursor;
    var lastSelectable = _cursor;
    while (remaining > 0) {
      next += direction;
      while (next >= 0 &&
          next < projected.length &&
          !projected[next].item.selectable) {
        next += direction;
      }
      if (next < 0 || next >= projected.length) break;
      lastSelectable = next;
      remaining--;
    }
    if (lastSelectable < 0 ||
        lastSelectable >= projected.length ||
        lastSelectable == _cursor) {
      return false;
    }
    _cursor = lastSelectable;
    _ensureCursorVisible(projected.length);
    return true;
  }

  /// Sets an absolute viewport offset.
  bool setOffset(int offset) {
    final next = offset.clamp(0, maxOffset);
    if (next == _offset) return false;
    _offset = next;
    return true;
  }

  /// Scrolls the viewport by [delta] rows without changing selection.
  bool scrollBy(int delta) => setOffset(_offset + delta);

  /// Sets the horizontal viewport offset.
  ///
  /// The model clamps only the left boundary because the renderer owns the
  /// available width and therefore decides how much content can be revealed.
  bool setHorizontalOffset(int offset) {
    final next = offset.clamp(0, maxHorizontalOffset);
    if (next == _horizontalOffset) return false;
    _horizontalOffset = next;
    return true;
  }

  /// Pans the viewport horizontally by [delta] cells.
  bool panBy(int delta) => setHorizontalOffset(_horizontalOffset + delta);

  @override
  Cmd? init() => null;

  @override
  (TreeModel<T>, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(:final key):
        if (keyMatches(key, [keyMap.up])) {
          moveBy(-1);
        } else if (keyMatches(key, [keyMap.down])) {
          moveBy(1);
        } else if (keyMatches(key, [keyMap.home])) {
          _moveToBoundary(first: true);
        } else if (keyMatches(key, [keyMap.end])) {
          _moveToBoundary(first: false);
        } else if (keyMatches(key, [keyMap.pageUp])) {
          moveBy(-(height > 0 ? height : 1));
        } else if (keyMatches(key, [keyMap.pageDown])) {
          moveBy(height > 0 ? height : 1);
        } else if (keyMatches(key, [keyMap.panLeft])) {
          panBy(-2);
        } else if (keyMatches(key, [keyMap.panRight])) {
          panBy(2);
        } else if (keyMatches(key, [keyMap.left])) {
          _collapseOrSelectParent();
        } else if (keyMatches(key, [keyMap.right])) {
          _expandOrSelectChild();
        } else if (keyMatches(key, [keyMap.toggle])) {
          final selected = selectedItem;
          if (selected != null) toggle(selected.id);
        } else if (keyMatches(key, [keyMap.activate])) {
          final selected = selectedItem;
          if (selected != null) {
            return (this, Cmd.message(TreeItemActivatedMsg<T>(selected)));
          }
        }
      case MouseMsg(:final action, :final button)
          when action == MouseAction.wheel ||
              button == MouseButton.wheelUp ||
              button == MouseButton.wheelDown:
        if (button == MouseButton.wheelUp) {
          scrollBy(-mouseWheelDelta);
        } else {
          scrollBy(mouseWheelDelta);
        }
      default:
        break;
    }
    return (this, null);
  }

  @override
  String view() {
    return visibleRows.map(_renderRow).join('\n');
  }

  String _renderRow(TreeRow<T> row) {
    final indicator = row.item.hasChildren
        ? row.isExpanded
              ? styles.expandedIndicator
              : styles.collapsedIndicator
        : styles.leafIndicator;
    final cursorPrefix = row.isSelected ? styles.cursor : '  ';
    final icon = row.item.icon ?? '';
    final itemStyle = row.isSelected ? styles.selectedItem : styles.item;
    var remainingOffset = _horizontalOffset;

    String renderSegment(String value, [Style? style]) {
      if (value.isEmpty) return '';
      final width = stringWidth(value);
      if (remainingOffset >= width) {
        remainingOffset -= width;
        return '';
      }
      final visible = truncateLeftAnsiByCells(value, remainingOffset);
      remainingOffset = 0;
      return style?.render(visible) ?? visible;
    }

    return '${renderSegment(cursorPrefix)}'
        '${renderSegment(row.prefix + row.connector, styles.connector)}'
        '${renderSegment(indicator)}'
        '${renderSegment(icon, styles.icon)}'
        '${renderSegment(icon.isEmpty ? "" : " ")}'
        '${renderSegment(row.item.label, itemStyle)}';
  }

  void _collapseOrSelectParent() {
    final projected = _projectRows();
    if (_cursor < 0 || _cursor >= projected.length) return;
    final row = projected[_cursor];
    if (row.item.hasChildren && row.isExpanded) {
      collapse(row.item.id);
      return;
    }
    final parentId = row.parentId;
    if (parentId != null) select(parentId);
  }

  void _expandOrSelectChild() {
    final projected = _projectRows();
    if (_cursor < 0 || _cursor >= projected.length) return;
    final row = projected[_cursor];
    if (!row.item.hasChildren) return;
    if (!row.isExpanded) {
      expand(row.item.id);
      return;
    }
    final child = row.item.children
        .where((item) => item.selectable)
        .firstOrNull;
    if (child != null) select(child.id);
  }

  void _moveToBoundary({required bool first}) {
    final projected = _projectRows();
    final indexes = Iterable<int>.generate(projected.length);
    final candidates = first ? indexes : indexes.toList().reversed;
    for (final index in candidates) {
      if (projected[index].item.selectable) {
        _cursor = index;
        _ensureCursorVisible(projected.length);
        return;
      }
    }
  }

  void _restoreSelection(String preferredId, {required String? selectedId}) {
    final projected = _projectRows();
    var index = selectedId == null
        ? -1
        : projected.indexWhere((row) => row.item.id == selectedId);
    index = index >= 0
        ? index
        : projected.indexWhere((row) => row.item.id == preferredId);
    _cursor = index >= 0 ? index : _firstSelectableIndex(projected);
    _clampState();
  }

  void _restoreSelectionFromPath(List<String> path) {
    final projected = _projectRows();
    final visibleIds = {for (final row in projected) row.item.id};
    final nearestVisibleId = path.reversed
        .where(visibleIds.contains)
        .firstOrNull;
    _cursor = nearestVisibleId == null
        ? _firstSelectableIndex(projected)
        : projected.indexWhere((row) => row.item.id == nearestVisibleId);
    _clampState();
  }

  void _ensureCursorVisible(int rowCount) {
    if (height <= 0 || _cursor < 0) return;
    if (_cursor < _offset) {
      _offset = _cursor;
    } else if (_cursor >= _offset + height) {
      _offset = _cursor - height + 1;
    }
    _offset = _offset.clamp(0, _maxOffset(rowCount));
  }

  void _clampState() {
    final projected = _projectRows();
    if (projected.isEmpty) {
      _cursor = -1;
      _offset = 0;
      return;
    }
    _cursor = _cursor.clamp(0, projected.length - 1);
    if (!projected[_cursor].item.selectable) {
      _cursor = _firstSelectableIndex(projected);
    }
    _offset = _offset.clamp(0, _maxOffset(projected.length));
    _horizontalOffset = _horizontalOffset.clamp(0, maxHorizontalOffset);
    _ensureCursorVisible(projected.length);
  }

  int _maxOffset(int rowCount) =>
      height <= 0 ? 0 : (rowCount - height).clamp(0, rowCount);

  int _rowTextWidth(TreeRow<T> row) {
    final indicator = row.item.hasChildren
        ? row.isExpanded
              ? styles.expandedIndicator
              : styles.collapsedIndicator
        : styles.leafIndicator;
    final icon = row.item.icon == null ? '' : '${row.item.icon} ';
    return stringWidth(
      '${styles.cursor}${row.prefix}${row.connector}'
      '$indicator$icon${row.item.label}',
    );
  }

  int _firstSelectableIndex(List<TreeRow<T>> projected) =>
      projected.indexWhere((row) => row.item.selectable);

  TreeItem<T>? _findItem(String id) {
    for (final item in _walkItems(_items)) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<String> _itemPath(String? id) {
    if (id == null) return const [];

    List<String>? find(List<TreeItem<T>> items, List<String> ancestors) {
      for (final item in items) {
        final path = [...ancestors, item.id];
        if (item.id == id) return path;
        final nested = find(item.children, path);
        if (nested != null) return nested;
      }
      return null;
    }

    return find(_items, const []) ?? const [];
  }

  void _seedExpansion(Iterable<TreeItem<T>> items) {
    for (final item in _walkItems(items)) {
      if (item.hasChildren && item.initiallyExpanded) {
        _expandedIds.add(item.id);
      }
    }
  }

  List<TreeRow<T>> _projectRows() {
    final rows = <TreeRow<T>>[];
    final effectiveIndent = indentSize < 2 ? 2 : indentSize;

    void append(
      List<TreeItem<T>> items,
      int depth,
      String prefix,
      String? parentId,
    ) {
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final isLast = index == items.length - 1;
        final connector = depth == 0
            ? ''
            : '${isLast ? '└' : '├'}${'─' * (effectiveIndent - 1)} ';
        final isExpanded = _expandedIds.contains(item.id);
        rows.add(
          TreeRow<T>(
            item: item,
            depth: depth,
            prefix: prefix,
            connector: connector,
            parentId: parentId,
            isExpanded: isExpanded,
            isSelected: rows.length == _cursor,
          ),
        );
        if (item.hasChildren && isExpanded) {
          final childPrefix = depth == 0
              ? ''
              : '$prefix${isLast ? ' ' : '│'}${' ' * effectiveIndent}';
          append(item.children, depth + 1, childPrefix, item.id);
        }
      }
    }

    append(_items, 0, '', null);
    return rows;
  }
}

Iterable<TreeItem<T>> _walkItems<T>(Iterable<TreeItem<T>> items) sync* {
  for (final item in items) {
    yield item;
    yield* _walkItems(item.children);
  }
}

Set<String> _allIds<T>(Iterable<TreeItem<T>> items) =>
    _walkItems(items).map((item) => item.id).toSet();

bool _containsId<T>(Iterable<TreeItem<T>> items, String id) {
  for (final item in _walkItems(items)) {
    if (item.id == id) return true;
  }
  return false;
}

void _validateUniqueIds<T>(Iterable<TreeItem<T>> items) {
  assert(() {
    final ids = <String>{};
    for (final item in _walkItems(items)) {
      if (!ids.add(item.id)) {
        throw ArgumentError.value(item.id, 'items', 'Tree IDs must be unique');
      }
    }
    return true;
  }());
}
