part of 'components_widgets.dart';

/// Base class for entries used in [PopupMenuButton].
abstract class PopupMenuEntry<T> extends StatelessWidget {
  PopupMenuEntry({super.key});

  /// Whether this entry can be selected.
  bool get enabled;

  /// Whether this entry represents [value].
  bool represents(T? value);
}

/// A selectable menu entry for [PopupMenuButton].
class PopupMenuItem<T> extends PopupMenuEntry<T> {
  PopupMenuItem({
    required this.value,
    required this.child,
    this.enabled = true,
    this.onTap,
    super.key,
  });

  final T value;
  final Widget child;
  @override
  final bool enabled;

  /// Optional callback executed before [PopupMenuButton.onSelected].
  final CmdCallback? onTap;

  @override
  bool represents(T? value) => this.value == value;

  @override
  Widget build(BuildContext context) => child;
}

/// A selectable menu entry with a check indicator.
class CheckedPopupMenuItem<T> extends PopupMenuItem<T> {
  CheckedPopupMenuItem({
    required super.value,
    required super.child,
    this.checked = false,
    super.enabled = true,
    super.onTap,
    super.key,
  });

  final bool checked;
}

/// A non-selectable divider entry for [PopupMenuButton].
class PopupMenuDivider<T> extends PopupMenuEntry<T> {
  PopupMenuDivider({this.height = 1, super.key}) : assert(height > 0);

  final int height;

  @override
  bool get enabled => false;

  @override
  bool represents(T? value) => false;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

/// Flutter-style popup menu button.
///
/// Pressing the trigger opens a dropdown menu under the button.
class PopupMenuButton<T> extends StatefulWidget {
  PopupMenuButton({
    required this.items,
    this.onSelected,
    this.onCanceled,
    this.initialValue,
    this.child,
    this.icon,
    this.enabled = true,
    this.size = ButtonSize.small,
    this.variant = ButtonVariant.outline,
    this.menuBorder = Border.rounded,
    this.menuBorderColor,
    this.menuBackground,
    this.menuSelectedBackground,
    this.menuSelectedForeground,
    this.menuForeground,
    this.itemPadding,
    super.key,
  });

  final List<PopupMenuEntry<T>> items;
  final ValueCmdCallback<T>? onSelected;
  final CmdCallback? onCanceled;
  final T? initialValue;
  final Widget? child;
  final Widget? icon;
  final bool enabled;
  final ButtonSize size;
  final ButtonVariant variant;
  final Border? menuBorder;
  final Color? menuBorderColor;
  final Color? menuBackground;
  final Color? menuSelectedBackground;
  final Color? menuSelectedForeground;
  final Color? menuForeground;
  final EdgeInsets? itemPadding;

  @override
  State createState() => _PopupMenuButtonState<T>();
}

class _PopupMenuButtonState<T> extends State<PopupMenuButton<T>> {
  bool _open = false;
  int _highlightedIndex = -1;
  OverlayEntry? _floatingEntry;
  int _menuLeft = 0;
  int _menuTop = 0;
  T? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  List<int> get _selectableIndexes {
    final indexes = <int>[];
    for (var i = 0; i < widget.items.length; i++) {
      final entry = widget.items[i];
      if (entry is PopupMenuItem<T> && entry.enabled) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  bool get _hasSelectableItems => _selectableIndexes.isNotEmpty;

  int _defaultHighlightedIndex() {
    final selectable = _selectableIndexes;
    if (selectable.isEmpty) return -1;

    final selectedValue = _currentValue;
    if (selectedValue != null) {
      for (final index in selectable) {
        if (widget.items[index].represents(selectedValue)) {
          return index;
        }
      }
    }
    return selectable.first;
  }

  bool get _usingFloatingOverlay => _floatingEntry != null;

  ({int x, int y, int width, int height})? _triggerGeometry() {
    final host = elementOf(widget);
    if (host == null) return null;
    final root = _firstRenderObject(host);
    if (root == null) return null;
    final anchor = _bestPopupAnchorRenderObject(host, root);
    final global = _globalOffset(anchor);
    return (
      x: global.x.floor(),
      y: global.y.floor(),
      width: anchor.size.width.toInt(),
      height: anchor.size.height.toInt(),
    );
  }

  void _insertFloatingEntry(OverlayState overlayState) {
    final trigger = _triggerGeometry();
    if (trigger == null) return;

    _menuLeft = trigger.x;
    _menuTop = trigger.y + trigger.height;
    _floatingEntry = OverlayEntry(
      builder: (context) {
        final media = MediaQuery.of(context);
        final menuWidth = _menuRowWidth() + 2;
        final menuHeight = _menuContentHeight() + 2;
        final left = _menuLeft.clamp(
          0,
          math.max(0, media.size.width.toInt() - menuWidth),
        );
        final top = _menuTop.clamp(
          0,
          math.max(0, media.size.height.toInt() - menuHeight),
        );

        return Positioned(
          left: left,
          top: top,
          child: _buildMenuFrame(context),
        );
      },
    );

    overlayState.insert(_floatingEntry!);
  }

  void _removeFloatingEntry() {
    final entry = _floatingEntry;
    if (entry == null) return;
    _floatingEntry = null;
    entry.remove();
  }

  void _markFloatingEntryNeedsBuild() {
    _floatingEntry?.markNeedsBuild();
  }

  @override
  Cmd? didUpdateWidget(covariant PopupMenuButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue) {
      _currentValue = widget.initialValue;
    }

    if (!_open) return null;

    if (!widget.enabled || !_hasSelectableItems) {
      return _closeMenu(canceled: true);
    }

    if (_usingFloatingOverlay) {
      final trigger = _triggerGeometry();
      if (trigger != null) {
        _menuLeft = trigger.x;
        _menuTop = trigger.y + trigger.height;
      }
      _markFloatingEntryNeedsBuild();
    }

    return null;
  }

  Cmd? _openMenu() {
    if (_open || !widget.enabled || !_hasSelectableItems) return null;
    final overlayState = Overlay.maybeOf(context);
    setState(() {
      _open = true;
      _highlightedIndex = _defaultHighlightedIndex();
    });
    if (overlayState != null) {
      _insertFloatingEntry(overlayState);
    }
    return null;
  }

  Cmd? _closeMenu({bool canceled = false}) {
    if (!_open) return null;
    _removeFloatingEntry();
    setState(() {
      _open = false;
      _highlightedIndex = -1;
    });
    if (canceled) {
      return widget.onCanceled?.call();
    }
    return null;
  }

  Cmd? _toggleMenu() {
    if (_open) return _closeMenu(canceled: true);
    return _openMenu();
  }

  Cmd? _selectAt(int index) {
    if (index < 0 || index >= widget.items.length) return null;
    final entry = widget.items[index];
    if (entry is! PopupMenuItem<T> || !entry.enabled) return null;

    final cmds = <Cmd>[];
    final itemCmd = entry.onTap?.call();
    if (itemCmd != null) cmds.add(itemCmd);
    final selectedCmd = widget.onSelected?.call(entry.value);
    if (selectedCmd != null) cmds.add(selectedCmd);
    _currentValue = entry.value;
    _closeMenu();

    if (cmds.isEmpty) return null;
    if (cmds.length == 1) return cmds.first;
    return Cmd.batch(cmds);
  }

  Cmd? _moveHighlight(int delta) {
    final selectable = _selectableIndexes;
    if (selectable.isEmpty) return Cmd.none();

    var cursor = selectable.indexOf(_highlightedIndex);
    if (cursor < 0) cursor = 0;
    cursor = (cursor + delta) % selectable.length;
    if (cursor < 0) cursor += selectable.length;

    setState(() {
      _highlightedIndex = selectable[cursor];
    });
    _markFloatingEntryNeedsBuild();
    return Cmd.none();
  }

  Cmd? _handleOpenKey(KeyMsg msg) {
    final key = msg.key;

    if (key.type == terminal_keys.KeyType.escape) {
      return _closeMenu(canceled: true) ?? Cmd.none();
    }
    if (key.type == terminal_keys.KeyType.up || key.char == 'k') {
      return _moveHighlight(-1);
    }
    if (key.type == terminal_keys.KeyType.down || key.char == 'j') {
      return _moveHighlight(1);
    }
    if (key.type == terminal_keys.KeyType.enter ||
        key.type == terminal_keys.KeyType.space ||
        key.char == ' ') {
      return _selectAt(_highlightedIndex) ?? Cmd.none();
    }

    // Trap key presses while the popup is open.
    return Cmd.none();
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (!_open) return null;
    if (msg is KeyMsg) return _handleOpenKey(msg);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final triggerChild =
        widget.child ?? widget.icon ?? Text(_defaultTriggerLabel());
    final trigger = Button(
      child: Row(gap: 1, children: [triggerChild, Text('v')]),
      onPressed: _toggleMenu,
      variant: widget.variant,
      size: widget.size,
      enabled: widget.enabled && _hasSelectableItems,
    );

    if (!_open) return trigger;

    // Floating overlay mode: menu is rendered via an OverlayEntry and should
    // not consume layout space where the trigger lives.
    if (_usingFloatingOverlay) return trigger;

    final menu = _buildMenuFrame(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      gap: 0,
      children: [trigger, menu],
    );
  }

  String _defaultTriggerLabel() {
    final selected = _selectedItemFor(_currentValue);
    if (selected == null) return 'Menu';
    if (selected.child is Text) {
      final data = (selected.child as Text).data;
      if (data != null && data.trim().isNotEmpty) {
        return data.trim();
      }
    }
    return selected.value.toString();
  }

  PopupMenuItem<T>? _selectedItemFor(T? value) {
    if (value == null) return null;
    for (final entry in widget.items) {
      if (entry is! PopupMenuItem<T>) continue;
      if (entry.represents(value)) return entry;
    }
    return null;
  }

  Widget _buildMenuFrame(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Frame(
      border: widget.menuBorder,
      borderColor: widget.menuBorderColor ?? theme.border,
      background: widget.menuBackground ?? theme.surface,
      child: Column(gap: 0, children: _buildMenuRows(theme)),
    );
  }

  List<Widget> _buildMenuRows(Theme theme) {
    final rows = <Widget>[];
    final width = _menuRowWidth();

    for (var i = 0; i < widget.items.length; i++) {
      final entry = widget.items[i];
      if (entry is PopupMenuDivider<T>) {
        final line = Text(
          '-' * width,
          style: _copyStyle(theme.bodySmall)..foreground(theme.border),
        );
        rows.add(
          Padding(padding: EdgeInsets.symmetric(horizontal: 1), child: line),
        );
        for (var h = 1; h < entry.height; h++) {
          rows.add(SizedBox(height: 1));
        }
        continue;
      }

      if (entry is! PopupMenuItem<T>) continue;
      final selected = i == _highlightedIndex;
      final selectedBg = widget.menuSelectedBackground ?? theme.primary;
      final selectedFg = widget.menuSelectedForeground ?? theme.onPrimary;
      final normalFg = widget.menuForeground ?? theme.onSurface;
      final foreground = selected ? selectedFg : normalFg;
      final textStyle = _copyStyle(theme.bodyMedium)..foreground(foreground);
      if (!entry.enabled) {
        textStyle.dim();
      }

      final markerStyle = _copyStyle(theme.labelSmall)..foreground(foreground);
      if (selected) markerStyle.bold();
      if (!entry.enabled) markerStyle.dim();

      final checkmark = entry is CheckedPopupMenuItem<T> && entry.checked
          ? 'x'
          : ' ';
      final row = Row(
        gap: 1,
        children: [
          Text(selected ? '>' : ' ', style: markerStyle),
          Text(checkmark, style: markerStyle),
          Expanded(child: _menuItemChild(entry, textStyle)),
        ],
      );

      Widget tile = Container(
        width: width,
        color: selected ? selectedBg : null,
        padding:
            widget.itemPadding ??
            const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
        child: row,
      );

      if (entry.enabled) {
        tile = GestureDetector(
          onTap: () => _selectAt(i),
          onEnter: (_) {
            if (_highlightedIndex != i) {
              setState(() => _highlightedIndex = i);
              _markFloatingEntryNeedsBuild();
            }
            return null;
          },
          child: tile,
        );
      }

      rows.add(tile);
    }

    return rows;
  }

  Widget _menuItemChild(PopupMenuItem<T> item, Style style) {
    if (item.child is! Text) return item.child;
    final text = item.child as Text;
    final data = text.data;
    if (data == null) return item.child;
    return Text(data, style: style, softWrap: false);
  }

  int _menuRowWidth() {
    var width = 8;
    for (final entry in widget.items) {
      if (entry is! PopupMenuItem<T>) continue;
      final labelLength = _menuItemLabelLength(entry);
      width = math.max(width, labelLength + 7);
    }
    return width;
  }

  int _menuContentHeight() {
    var height = 0;
    for (final entry in widget.items) {
      if (entry is PopupMenuDivider<T>) {
        height += entry.height;
      } else if (entry is PopupMenuItem<T>) {
        height += 1;
      }
    }
    return math.max(1, height);
  }

  int _menuItemLabelLength(PopupMenuItem<T> item) {
    if (item.child is Text) {
      final data = (item.child as Text).data;
      if (data != null) {
        return math.max(1, Style.visibleLength(data));
      }
    }
    return math.max(1, Style.visibleLength(item.value.toString()));
  }

  @override
  void dispose() {
    _removeFloatingEntry();
    super.dispose();
  }
}

RenderObject? _firstRenderObject(Element element) {
  final direct = element.renderObject;
  if (direct != null) return direct;
  for (final child in element.children) {
    final nested = _firstRenderObject(child);
    if (nested != null) return nested;
  }
  return null;
}

RenderObject _bestPopupAnchorRenderObject(Element host, RenderObject root) {
  final rootWidth = root.size.width;
  final rootHeight = root.size.height;
  if (rootWidth <= 0 || rootHeight <= 0) return root;

  RenderObject? best;
  for (final candidate in _renderObjectsInSubtree(host)) {
    if (identical(candidate, root)) continue;

    final width = candidate.size.width;
    final height = candidate.size.height;
    if (width <= 0 || height <= 0) continue;
    if (height > rootHeight + 0.001) continue;
    if (width >= rootWidth - 0.001) continue;

    if (best == null || width > best.size.width) {
      best = candidate;
    }
  }

  if (best == null) return root;

  // Only switch anchors when the descendant is materially narrower.
  if (rootWidth - best.size.width < 2) return root;
  return best;
}

Iterable<RenderObject> _renderObjectsInSubtree(Element element) sync* {
  final ro = element.renderObject;
  if (ro != null) yield ro;
  for (final child in element.children) {
    yield* _renderObjectsInSubtree(child);
  }
}

({double x, double y}) _globalOffset(RenderObject renderObject) {
  var x = 0.0;
  var y = 0.0;
  RenderObject? current = renderObject;
  while (current != null) {
    x += current.offset.dx;
    y += current.offset.dy;
    current = current.parent;
  }
  return (x: x, y: y);
}
