part of 'components_widgets.dart';

/// A single item in a [DialogSelect] list.
///
/// Generic over [T] so callers can attach a typed value to each item.
class DialogSelectItem<T> {
  const DialogSelectItem({
    required this.label,
    this.value,
    this.description,
    this.footer,
    this.category,
    this.isCurrent = false,
    this.isDisabled = false,
    this.background,
  });

  /// Primary display text for the item.
  final String label;

  /// The underlying value associated with this item.
  final T? value;

  /// Optional secondary description shown below the label.
  final String? description;

  /// Optional trailing text shown on the right.
  final String? footer;

  /// Group/category name. Items with the same category are grouped under
  /// a shared section header.
  final String? category;

  /// Whether this item represents the current/active selection.
  /// Shown with a `●` marker.
  final bool isCurrent;

  /// Whether the item is non-selectable.
  final bool isDisabled;

  /// Optional per-item background color override.
  final Color? background;
}

/// A generic searchable, grouped selection list dialog.
///
/// This is the lower-level primitive that [CommandPalette] and domain-specific
/// list dialogs (model picker, agent picker, etc.) build upon.
///
/// Features:
/// - Title bar with `esc` dismiss hint
/// - Search input with fuzzy text filtering
/// - Grouped items with section headers
/// - Keyboard nav: up/down, pgup/pgdn, home/end, enter, esc
/// - Mouse hover + click
/// - Current item marker (`●`)
/// - Fully themeable via [DialogThemeData] + [CommandPaletteThemeData]
///
/// ```dart
/// DialogSelect<String>(
///   title: 'Select Model',
///   items: models.map((m) => DialogSelectItem(
///     label: m.name,
///     value: m.id,
///     description: m.provider,
///     category: m.providerGroup,
///     isCurrent: m.id == currentModelId,
///   )).toList(),
///   onSelect: (item) => _setModel(item.value!),
///   onDismiss: () => _close(),
/// )
/// ```
class DialogSelect<T> extends StatefulWidget {
  DialogSelect({
    required this.items,
    this.title,
    this.searchHint,
    this.onSelect,
    this.onDismiss,
    this.width,
    this.height,
    this.keybinds = const [],
    this.trailing,
    this.onHighlightChanged,
    this.emptyBuilder,
    super.key,
  });

  /// Items to display and filter.
  final List<DialogSelectItem<T>> items;

  /// Title shown at the top of the dialog.
  final String? title;

  /// Placeholder text for the search input.
  final String? searchHint;

  /// Called when an item is selected (enter or click).
  final void Function(DialogSelectItem<T> item)? onSelect;

  /// Called when the dialog should be dismissed.
  final CmdCallback? onDismiss;

  /// Width of the dialog in columns. Defaults to theme or 64.
  final int? width;

  /// Height of the dialog in rows. Defaults to theme or 22.
  final int? height;

  /// Additional keybind hints shown in the footer.
  final List<({String key, String description})> keybinds;

  /// Optional trailing widget shown at the bottom (e.g., item count).
  final Widget Function(int filteredCount, int totalCount)? trailing;

  /// Called when the highlighted (selected) item changes due to keyboard
  /// navigation or mouse hover. Useful for live-preview scenarios like
  /// theme switching.
  final void Function(DialogSelectItem<T> item)? onHighlightChanged;

  /// Custom builder for the empty state (when no items match the search).
  /// Receives the current search query. If null, a default "No matches" text
  /// is shown.
  final Widget Function(String searchQuery)? emptyBuilder;

  @override
  State createState() => _DialogSelectState<T>();
}

class _DialogSelectState<T> extends State<DialogSelect<T>> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  late TextEditingController _searchController;
  late List<DialogSelectItem<T>> _filteredItems;
  WidgetScrollController? _scrollController;

  WidgetScrollController get _scroll =>
      _scrollController ??= WidgetScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = <DialogSelectItem<T>>[];
    _recomputeFilteredItems(preserveSelection: false);
  }

  @override
  Cmd? didUpdateWidget(covariant DialogSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      _recomputeFilteredItems(preserveSelection: true);
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  void _recomputeFilteredItems({required bool preserveSelection}) {
    final previousItems = _filteredItems;
    final previousSelection =
        preserveSelection &&
            _selectedIndex >= 0 &&
            _selectedIndex < previousItems.length
        ? previousItems[_selectedIndex]
        : null;

    final nextItems = () {
      if (_searchQuery.isEmpty) return widget.items;
      final q = _searchQuery.toLowerCase();
      return widget.items
          .where((item) {
            return item.label.toLowerCase().contains(q) ||
                (item.description?.toLowerCase().contains(q) ?? false) ||
                (item.category?.toLowerCase().contains(q) ?? false);
          })
          .toList(growable: false);
    }();

    var nextIndex = 0;
    if (nextItems.isNotEmpty) {
      if (previousSelection != null) {
        nextIndex = nextItems.indexWhere(
          (item) => identical(item, previousSelection),
        );
        if (nextIndex < 0) {
          final previousValue = previousSelection.value;
          if (previousValue != null) {
            nextIndex = nextItems.indexWhere(
              (item) => item.value == previousValue,
            );
          }
        }
      } else {
        nextIndex = _indexOfCurrent(nextItems);
      }
      if (nextIndex < 0) {
        nextIndex = _selectedIndex.clamp(0, nextItems.length - 1);
      }
    }

    _filteredItems = nextItems;
    _selectedIndex = nextIndex;
  }

  int _indexOfCurrent(List<DialogSelectItem<T>> items) {
    final index = items.indexWhere((item) => item.isCurrent);
    return index < 0 ? 0 : index;
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void _moveSelection(int delta) {
    final items = _filteredItems;
    if (items.isEmpty) return;
    var next = (_selectedIndex + delta).clamp(0, items.length - 1);
    // Skip disabled items
    while (next >= 0 && next < items.length && items[next].isDisabled) {
      next += delta.sign;
    }
    next = next.clamp(0, items.length - 1);
    if (items[next].isDisabled) return;
    setState(() {
      _selectedIndex = next;
    });
    _scrollSelectionIntoView(items.length);
    widget.onHighlightChanged?.call(items[next]);
  }

  void _selectCurrent() {
    final items = _filteredItems;
    if (_selectedIndex < 0 || _selectedIndex >= items.length) return;
    final item = items[_selectedIndex];
    if (item.isDisabled) return;
    widget.onSelect?.call(item);
  }

  void _scrollSelectionIntoView(int itemCount) {
    if (itemCount <= 0) return;
    final controller = _scroll;
    final viewportExtent = controller.viewportExtent;
    if (viewportExtent <= 0) return;
    final selected = _selectedIndex.clamp(0, itemCount - 1);
    final offset = controller.offset;
    if (selected < offset) {
      controller.jumpTo(selected);
    } else if (selected >= offset + viewportExtent) {
      controller.jumpTo(selected - viewportExtent + 1);
    }
  }

  // ── Keyboard ───────────────────────────────────────────────────────────────

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is! KeyMsg) return null;
    final key = msg.key;

    switch (key.type) {
      case terminal_keys.KeyType.escape:
        return widget.onDismiss?.call();
      case terminal_keys.KeyType.enter:
        _selectCurrent();
        return Cmd.none();
      case terminal_keys.KeyType.up:
        _moveSelection(-1);
        return Cmd.none();
      case terminal_keys.KeyType.down:
        _moveSelection(1);
        return Cmd.none();
      case terminal_keys.KeyType.pageUp:
        _moveSelection(-10);
        return Cmd.none();
      case terminal_keys.KeyType.pageDown:
        _moveSelection(10);
        return Cmd.none();
      case terminal_keys.KeyType.home:
        _moveSelection(-_filteredItems.length);
        return Cmd.none();
      case terminal_keys.KeyType.end:
        _moveSelection(_filteredItems.length);
        return Cmd.none();
      default:
        return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final dTheme = theme.dialogTheme;
    final cpTheme = theme.commandPaletteTheme;

    final dialogBg = dTheme?.background ?? cpTheme?.background ?? theme.surface;
    final dialogFg =
        dTheme?.foreground ?? cpTheme?.foreground ?? theme.onSurface;
    final selectedBg =
        dTheme?.buttonSelectedBackground ??
        cpTheme?.selectedBackground ??
        theme.listRowSelectedBackground;
    final selectedFg =
        dTheme?.buttonSelectedForeground ??
        cpTheme?.selectedForeground ??
        theme.listRowSelectedForeground;
    final headerFg = cpTheme?.headerForeground ?? theme.muted;
    final searchBg = cpTheme?.searchBackground ?? theme.background;
    final hintFg = dTheme?.hintForeground ?? theme.muted;

    final w = widget.width ?? dTheme?.width ?? cpTheme?.width ?? 64;
    final h = widget.height ?? dTheme?.maxHeight ?? cpTheme?.maxHeight ?? 22;

    final items = _filteredItems;

    return SizedBox(
      width: w,
      height: h,
      child: Frame(
        background: dialogBg,
        foreground: dialogFg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title bar
            _buildTitleBar(theme, hintFg),
            SizedBox(height: 1),
            // Search input
            _buildSearchInput(theme, searchBg),
            SizedBox(height: 1),
            // List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items.isEmpty
                        ? [
                            if (widget.emptyBuilder != null)
                              widget.emptyBuilder!(_searchQuery)
                            else
                              Padding(
                                padding: const EdgeInsets.only(left: 1),
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No items'
                                      : 'No matches for "$_searchQuery"',
                                  style: copyStyle(theme.bodySmall)
                                    ..foreground(hintFg),
                                ),
                              ),
                          ]
                        : _buildItemRows(
                            items,
                            theme,
                            selectedBg,
                            selectedFg,
                            headerFg,
                            dialogFg,
                          ),
                  ),
                ),
              ),
            ),
            // Footer
            _buildFooter(theme, items, hintFg),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(Theme theme, Color hintFg) {
    final titleStyle = copyStyle(theme.titleMedium)
      ..foreground(theme.onSurface);
    final escStyle = copyStyle(theme.bodySmall)..foreground(hintFg);

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title ?? '', style: titleStyle),
          GestureDetector(
            onTap: widget.onDismiss,
            child: Text('esc', style: escStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(Theme theme, Color searchBg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Frame(
        background: searchBg,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Row(
          children: [
            Text(
              '/',
              style: copyStyle(theme.bodySmall)..foreground(theme.muted),
            ),
            SizedBox(width: 1),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusId: 'dialog-select-search',
                prompt: '',
                placeholder: widget.searchHint ?? 'Search',
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _recomputeFilteredItems(preserveSelection: false);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemRows(
    List<DialogSelectItem<T>> items,
    Theme theme,
    Color selectedBg,
    Color selectedFg,
    Color headerFg,
    Color defaultFg,
  ) {
    final rows = <Widget>[];
    String? lastCategory;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      // Category header
      if (item.category != null && item.category != lastCategory) {
        lastCategory = item.category;
        final headerStyle = copyStyle(theme.titleSmall)
          ..foreground(headerFg)
          ..bold();
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 0),
            child: Text(item.category!.toUpperCase(), style: headerStyle),
          ),
        );
      }

      final isSelected = i == _selectedIndex;
      final fg = item.isDisabled
          ? theme.muted
          : isSelected
          ? selectedFg
          : defaultFg;
      final bg = isSelected ? selectedBg : item.background;

      final labelStyle = copyStyle(theme.bodyMedium)..foreground(fg);
      final descStyle = copyStyle(theme.bodySmall)
        ..foreground(
          isSelected
              ? theme.listRowSelectedMutedForeground
              : theme.listRowMutedForeground,
        );

      // Marker for current item
      final marker = item.isCurrent ? '●' : ' ';
      final markerStyle = copyStyle(theme.bodySmall)
        ..foreground(
          isSelected
              ? theme.listRowSelectedMarkerForeground
              : theme.listRowMarkerForeground,
        );

      final index = i;
      Widget row = Frame(
        background: bg,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(marker, style: markerStyle),
                SizedBox(width: 1),
                Expanded(child: Text(item.label, style: labelStyle)),
                if (item.footer != null) Text(item.footer!, style: descStyle),
              ],
            ),
            if (item.description != null)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(item.description!, style: descStyle),
              ),
          ],
        ),
      );

      row = GestureDetector(
        onTap: item.isDisabled
            ? null
            : () {
                if (_selectedIndex != index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
                widget.onSelect?.call(item);
                return null;
              },
        child: MouseRegion(
          onEnter: (_) {
            if (!item.isDisabled && _selectedIndex != index) {
              setState(() {
                _selectedIndex = index;
              });
              widget.onHighlightChanged?.call(item);
            }
            return null;
          },
          child: row,
        ),
      );

      rows.add(row);
    }

    return rows;
  }

  Widget _buildFooter(
    Theme theme,
    List<DialogSelectItem<T>> filteredItems,
    Color hintFg,
  ) {
    final hintStyle = copyStyle(theme.bodySmall)..foreground(hintFg);

    final defaultHints = [
      (key: '↑↓', description: 'navigate'),
      (key: 'enter', description: 'select'),
      ...widget.keybinds,
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 1, top: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            gap: 2,
            children: [
              for (final hint in defaultHints)
                Row(
                  gap: 1,
                  children: [
                    Text(hint.key, style: hintStyle),
                    Text(hint.description, style: hintStyle),
                  ],
                ),
            ],
          ),
          if (widget.trailing != null)
            widget.trailing!(filteredItems.length, widget.items.length)
          else
            Text(
              '${filteredItems.length}/${widget.items.length}',
              style: hintStyle,
            ),
        ],
      ),
    );
  }
}
