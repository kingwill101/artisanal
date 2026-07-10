import 'package:artisanal_widgets/src/widgets/core/element.dart';
import 'package:artisanal_widgets/src/widgets/rendering/render_object.dart';
import 'dart:math' as math;

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color, Border, Style, Colors;

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
  _PopupMenuFloatingMenuState<T>? _floatingMenuState;
  int _menuLeft = 0;
  int _menuTop = 0;
  T? _currentValue;
  final Map<Object, String> _renderedTextLineCache = <Object, String>{};
  final Map<Object, Widget> _menuRowWidgetCache = <Object, Widget>{};
  int? _cachedMenuRowWidth;

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
    final root = firstRenderObject(host);
    if (root == null) return null;
    final anchor = bestPopupAnchorRenderObject(host, root);
    final global = globalOffset(anchor);
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
          child: _PopupMenuFloatingMenu<T>(owner: this),
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

  ({int left, int top, int width, int height})? _floatingMenuRect() {
    if (!_usingFloatingOverlay) return null;
    final media = MediaQuery.of(context);
    final width = _menuRowWidth() + 2;
    final height = _menuContentHeight() + 2;
    final left = _menuLeft
        .clamp(0, math.max(0, media.size.width.toInt() - width))
        .toInt();
    final top = _menuTop
        .clamp(0, math.max(0, media.size.height.toInt() - height))
        .toInt();
    return (left: left, top: top, width: width, height: height);
  }

  int? _menuIndexAtLocal({
    required int localX,
    required int localY,
    required int menuWidth,
    required int menuHeight,
  }) {
    if (localX < 0 || localX >= menuWidth) return null;
    if (localY < 1 || localY >= menuHeight - 1) return null;

    var rowOffset = localY - 1;
    for (var i = 0; i < widget.items.length; i++) {
      final entry = widget.items[i];
      final height = entry is PopupMenuDivider<T> ? entry.height : 1;
      if (rowOffset < height) {
        return entry is PopupMenuItem<T> && entry.enabled ? i : null;
      }
      rowOffset -= height;
    }
    return null;
  }

  Cmd? _setHighlightedIndex(int nextIndex) {
    if (_highlightedIndex == nextIndex) return null;
    if (_usingFloatingOverlay) {
      _highlightedIndex = nextIndex;
      final menuState = _floatingMenuState;
      if (menuState != null) {
        menuState.rebuild();
      } else {
        _markFloatingEntryNeedsBuild();
      }
      return null;
    }
    setState(() {
      _highlightedIndex = nextIndex;
    });
    return Cmd.none();
  }

  @override
  Cmd? didUpdateWidget(covariant PopupMenuButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _renderedTextLineCache.clear();
    _menuRowWidgetCache.clear();
    _cachedMenuRowWidth = null;

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
    return _setHighlightedIndex(selectable[cursor]) ?? Cmd.none();
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
    final itemPadding =
        widget.itemPadding ??
        const EdgeInsets.symmetric(horizontal: 1, vertical: 0);
    final bodyMedium = theme.bodyMedium;
    final bodySmall = theme.bodySmall;
    final labelSmall = theme.labelSmall;

    for (var i = 0; i < widget.items.length; i++) {
      final entry = widget.items[i];
      if (entry is PopupMenuDivider<T>) {
        final dividerKey = (
          'divider',
          entry,
          width,
          theme.border,
          bodySmall,
          hasDarkBackground,
        );
        final cachedDivider = _menuRowWidgetCache[dividerKey];
        if (cachedDivider != null) {
          rows.add(cachedDivider);
        } else {
          final divider = Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              '-' * width,
              style: copyStyle(bodySmall)..foreground(theme.border),
            ),
          );
          _menuRowWidgetCache[dividerKey] = divider;
          rows.add(divider);
        }
        for (var h = 1; h < entry.height; h++) {
          rows.add(SizedBox(height: 1));
        }
        continue;
      }

      if (entry is! PopupMenuItem<T>) continue;
      final selected = i == _highlightedIndex;
      final selectedBg =
          widget.menuSelectedBackground ?? theme.listRowSelectedBackground;
      final selectedFg =
          widget.menuSelectedForeground ?? theme.listRowSelectedForeground;
      final normalFg = widget.menuForeground ?? theme.listRowForeground;
      final foreground = selected ? selectedFg : normalFg;
      final textStyle = copyStyle(bodyMedium)..foreground(foreground);
      if (!entry.enabled) {
        textStyle.dim();
      }

      final markerStyle = copyStyle(labelSmall)..foreground(foreground);
      if (selected) markerStyle.bold();
      if (!entry.enabled) markerStyle.dim();

      final checkmark = entry is CheckedPopupMenuItem<T> && entry.checked
          ? 'x'
          : ' ';
      final lineLabel = _menuItemLabel(entry);
      final rowKey = (
        'row',
        entry,
        i,
        width,
        selected,
        _usingFloatingOverlay,
        itemPadding,
        selectedBg,
        selectedFg,
        normalFg,
        bodyMedium,
        labelSmall,
        hasDarkBackground,
      );
      final cachedRow = _menuRowWidgetCache[rowKey];
      if (cachedRow != null) {
        rows.add(cachedRow);
        continue;
      }

      final row = lineLabel != null
          ? Text(
              _renderedTextMenuLine(
                entry: entry,
                label: lineLabel,
                marker: selected ? '>' : ' ',
                checkmark: checkmark,
                styleKey: (
                  bodyMedium,
                  labelSmall,
                  foreground,
                  selected,
                  entry.enabled,
                  hasDarkBackground,
                ),
                textStyle: textStyle,
                markerStyle: markerStyle,
              ),
              softWrap: false,
            )
          : Row(
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
        padding: itemPadding,
        child: row,
      );

      if (entry.enabled && !_usingFloatingOverlay) {
        tile = GestureDetector(
          onTap: () => _selectAt(i),
          onEnter: (_) => _setHighlightedIndex(i),
          child: tile,
        );
      }

      _menuRowWidgetCache[rowKey] = tile;
      rows.add(tile);
    }

    return rows;
  }

  Widget _menuItemChild(PopupMenuItem<T> item, Style style) {
    if (item.child is! Text) return item.child;
    final label = _menuItemLabel(item);
    if (label == null) return item.child;
    return Text(label, style: style, softWrap: false);
  }

  String? _menuItemLabel(PopupMenuItem<T> item) {
    if (item.child is! Text) return null;
    final text = item.child as Text;
    return text.data;
  }

  String _renderedTextMenuLine({
    required PopupMenuItem<T> entry,
    required String label,
    required String marker,
    required String checkmark,
    required Object styleKey,
    required Style textStyle,
    required Style markerStyle,
  }) {
    final cacheKey = (entry, label, marker, checkmark, styleKey);
    final cached = _renderedTextLineCache[cacheKey];
    if (cached != null) return cached;

    final rendered =
        '${markerStyle.render('$marker $checkmark')} ${textStyle.render(label)}';
    _renderedTextLineCache[cacheKey] = rendered;
    return rendered;
  }

  int _menuRowWidth() {
    final cachedWidth = _cachedMenuRowWidth;
    if (cachedWidth != null) return cachedWidth;
    var width = 8;
    for (final entry in widget.items) {
      if (entry is! PopupMenuItem<T>) continue;
      final labelLength = _menuItemLabelLength(entry);
      width = math.max(width, labelLength + 7);
    }
    _cachedMenuRowWidth = width;
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

class _PopupMenuFloatingMenu<T> extends StatefulWidget {
  _PopupMenuFloatingMenu({required this.owner});

  final _PopupMenuButtonState<T> owner;

  @override
  State<_PopupMenuFloatingMenu<T>> createState() =>
      _PopupMenuFloatingMenuState<T>();
}

class _PopupMenuFloatingMenuState<T> extends State<_PopupMenuFloatingMenu<T>> {
  void rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  void _attach(_PopupMenuButtonState<T> owner) {
    owner._floatingMenuState = this;
  }

  void _detach(_PopupMenuButtonState<T> owner) {
    if (identical(owner._floatingMenuState, this)) {
      owner._floatingMenuState = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _attach(widget.owner);
  }

  @override
  Cmd? didUpdateWidget(covariant _PopupMenuFloatingMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.owner, widget.owner)) {
      _detach(oldWidget.owner);
      _attach(widget.owner);
    }
    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    final owner = widget.owner;
    if (!owner._open) return null;

    if (msg is HitTestMouseMsg) {
      final menuRect = owner._floatingMenuRect();
      if (menuRect == null) return null;
      final hoveredIndex = owner._menuIndexAtLocal(
        localX: msg.event.x - menuRect.left,
        localY: msg.event.y - menuRect.top,
        menuWidth: menuRect.width,
        menuHeight: menuRect.height,
      );
      final event = msg.event;
      if (event.action == MouseAction.motion) {
        if (hoveredIndex == null) return null;
        return owner._setHighlightedIndex(hoveredIndex);
      }
      if (event.action == MouseAction.release &&
          event.button == MouseButton.left) {
        if (hoveredIndex == null) return null;
        return owner._selectAt(hoveredIndex);
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.owner._buildMenuFrame(context);
  }

  @override
  void dispose() {
    _detach(widget.owner);
    super.dispose();
  }
}

/// Returns the render object to use as the anchor for a popup menu.
RenderObject bestPopupAnchorRenderObject(Element host, RenderObject root) {
  final rootWidth = root.size.width;
  final rootHeight = root.size.height;
  if (rootWidth <= 0 || rootHeight <= 0) return root;

  RenderObject? best;
  for (final candidate in renderObjectsInSubtree(host)) {
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
