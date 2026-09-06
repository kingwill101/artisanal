import 'dart:math' as math;
import '_component_foundation.dart';
import 'frame.dart';

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' as core;

import 'package:artisanal/runtime.dart';
import 'package:artisanal/style.dart' show Color, Border;

/// Compatibility alias for the shared Artisanal palette item.
typedef CommandPaletteItem = core.CommandPaletteItem;

/// Compatibility alias for the shared Artisanal scored match.
typedef CommandPaletteMatch = core.CommandPaletteMatch;

/// A searchable, grouped list displayed in a modal overlay.
///
/// Modeled after VS Code's command palette / Ctrl+P picker. Supports:
/// - Bayesian scoring with match types (exact > prefix > word-start > substring > fuzzy)
/// - Incremental scoring for query-as-you-type performance
/// - Conformal rank confidence (stable/marginal/unstable)
/// - Searchable tags that boost match scores
/// - Grouped items with section headers
/// - Keyboard navigation (up/down arrows, enter to select, esc to dismiss)
/// - Mouse click selection
/// - Fully themeable via [CommandPaletteThemeData]
///
/// ```dart
/// CommandPalette(
///   open: _showPalette,
///   title: 'Commands',
///   items: [
///     CommandPaletteItem(label: 'Open File', shortcut: 'ctrl+o', group: 'File', tags: ['open', 'load']),
///     CommandPaletteItem(label: 'Save', shortcut: 'ctrl+s', group: 'File', tags: ['write', 'persist']),
///     CommandPaletteItem(label: 'Find', shortcut: 'ctrl+f', group: 'Edit', tags: ['search']),
///   ],
///   onDismiss: () { setState(() => _showPalette = false); return null; },
///   child: myAppContent,
/// )
/// ```
class CommandPalette extends StatefulWidget {
  CommandPalette({
    required this.child,
    required this.items,
    this.open = false,
    this.title,
    this.hint,
    this.onDismiss,
    this.onSelect,
    this.background,
    this.selectedBackground,
    this.selectedForeground,
    this.border,
    this.borderColor,
    this.width,
    this.maxHeight,
    this.backdropOpacity = 0.6,
    super.key,
  });

  /// Background content shown behind the palette.
  final Widget child;

  /// Available items to display and filter.
  final List<CommandPaletteItem> items;

  /// Whether the palette is visible.
  final bool open;

  /// Optional title shown at the top of the palette.
  final String? title;

  /// Placeholder hint text for the search input.
  final String? hint;

  /// Called when the palette should be dismissed (esc key or backdrop tap).
  final CmdCallback? onDismiss;

  /// Called when an item is selected. Receives the selected item.
  final ValueCmdCallback<CommandPaletteItem>? onSelect;

  /// Background color override.
  final Color? background;

  /// Background color for the selected item.
  final Color? selectedBackground;

  /// Foreground color for the selected item.
  final Color? selectedForeground;

  /// Border style override.
  final Border? border;

  /// Border color override.
  final Color? borderColor;

  /// Width of the palette in columns.
  final int? width;

  /// Maximum height of the palette in rows.
  final int? maxHeight;

  /// Opacity used to dim the background while open.
  final double backdropOpacity;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();

  /// Returns ranked matches for [query] with deterministic scoring and
  /// explainable evidence.
  ///
  /// Public for testing and parity-validation workflows.
  static List<CommandPaletteMatch> matchItems(
    List<CommandPaletteItem> items,
    String query,
  ) => core.matchCommandPaletteItems(items, query);
}

class _CommandPaletteState extends State<CommandPalette> {
  late final core.CommandPaletteController _paletteController;
  final _listController = WidgetScrollController();

  int get _selectedIndex => _paletteController.selectedIndex;
  set _selectedIndex(int value) => _paletteController.selectedIndex = value;

  List<CommandPaletteItem> get _filteredItems {
    _paletteController.updateItems(widget.items);
    return _paletteController.filteredItems;
  }

  @override
  void initState() {
    super.initState();
    _paletteController = core.CommandPaletteController(items: widget.items);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _paletteController.updateQuery(value);
      _listController.jumpTo(0);
    });
  }

  void _setSelectedIndex(
    int nextIndex, {
    required List<CommandPaletteItem> items,
  }) {
    if (items.isEmpty) {
      _selectedIndex = 0;
      return;
    }

    _paletteController.selectIndex(nextIndex);
    _scrollSelectedItemIntoView(items);
  }

  void _scrollSelectedItemIntoView(List<CommandPaletteItem> items) {
    if (items.isEmpty) return;
    if (_selectedIndex < 0 || _selectedIndex >= items.length) return;

    final viewportExtent = _listController.viewportExtent;
    if (viewportExtent <= 0) return;

    final row = _itemRowOffset(items, _selectedIndex);
    final offset = _listController.offset;
    final viewportEnd = offset + viewportExtent;
    if (row < offset) {
      _listController.jumpTo(row);
      return;
    }
    if (row >= viewportEnd) {
      _listController.jumpTo(row - viewportExtent + 1);
    }
  }

  int _itemRowOffset(List<CommandPaletteItem> items, int itemIndex) {
    var row = 0;
    String? lastGroup;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.group != null && item.group != lastGroup) {
        lastGroup = item.group;
        if (row > 0) row += 1;
        row += 1;
      }
      if (i == itemIndex) return row;
      row += 1;
    }
    return row;
  }

  Cmd? _highlightHoveredIndex(int index) {
    final items = _filteredItems;
    if (index < 0 || index >= items.length) return null;
    if (_selectedIndex == index) return null;
    setState(() {
      _selectedIndex = index;
      _scrollSelectedItemIntoView(items);
    });
    return Cmd.none();
  }

  Cmd? _selectCurrent() {
    final items = _filteredItems;
    if (_selectedIndex >= 0 && _selectedIndex < items.length) {
      final item = items[_selectedIndex];
      if (widget.onSelect != null) return widget.onSelect!(item) ?? Cmd.none();
      if (item.onSelect != null) return item.onSelect!() ?? Cmd.none();
      return Cmd.none();
    }
    return Cmd.none();
  }

  Cmd? _handleKey(KeyMsg msg) {
    final key = msg.key;

    // Escape dismisses
    if (key.type == terminal_keys.KeyType.escape) {
      return widget.onDismiss?.call() ?? Cmd.none();
    }

    // Enter selects
    if (key.type == terminal_keys.KeyType.enter) {
      return _selectCurrent();
    }

    // Arrow navigation
    if (key.type == terminal_keys.KeyType.up) {
      setState(() {
        final items = _filteredItems;
        if (items.isNotEmpty) {
          _setSelectedIndex(_selectedIndex - 1, items: items);
        }
      });
      return Cmd.none();
    }
    if (key.type == terminal_keys.KeyType.down) {
      setState(() {
        final items = _filteredItems;
        if (items.isNotEmpty) {
          _setSelectedIndex(_selectedIndex + 1, items: items);
        }
      });
      return Cmd.none();
    }

    // Keep focus trapped while open: consume modified and focus-nav keys.
    if (key.ctrl || key.alt || key.type == terminal_keys.KeyType.tab) {
      return Cmd.none();
    }

    return null;
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (!widget.open) return null;
    if (msg is KeyMsg) return _handleKey(msg);
    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (!widget.open) return null;
    if (msg is MouseMsg) return Cmd.none();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Always keep a stable Stack so [child] (often a Navigator) is never
    // remounted when the palette opens/closes.
    final theme = ThemeScope.of(context);
    final cpTheme = theme.commandPaletteTheme;
    final media = MediaQuery.of(context);

    final bg = widget.background ?? cpTheme?.background ?? theme.surface;
    final fg = cpTheme?.foreground ?? theme.onSurface;
    final selBg =
        widget.selectedBackground ??
        cpTheme?.selectedBackground ??
        theme.listRowSelectedBackground;
    final selFg =
        widget.selectedForeground ??
        cpTheme?.selectedForeground ??
        theme.listRowSelectedForeground;
    final headerFg = cpTheme?.headerForeground ?? theme.muted;
    final shortcutFg = cpTheme?.shortcutForeground ?? theme.muted;
    final searchBg = cpTheme?.searchBackground ?? theme.background;
    final bdr = widget.border ?? cpTheme?.border;
    final bdrColor = widget.borderColor ?? cpTheme?.borderColor ?? theme.border;
    final paletteWidth =
        widget.width ??
        cpTheme?.width ??
        math.min(60, media.size.width.toInt() - 4);
    final maxH =
        widget.maxHeight ?? cpTheme?.maxHeight ?? media.size.height.toInt() - 6;

    final items = _filteredItems;
    final headerStyle = copyStyle(theme.labelSmall)
      ..foreground(headerFg)
      ..bold();
    final normalStyle = copyStyle(theme.bodyMedium)..foreground(fg);
    final selectedStyle = copyStyle(theme.bodyMedium)
      ..foreground(selFg)
      ..bold();
    final shortcutStyle = copyStyle(theme.labelSmall)..foreground(shortcutFg);
    final selectedShortcutStyle = copyStyle(theme.labelSmall)
      ..foreground(theme.listRowSelectedMutedForeground);

    // Build grouped item list
    final rows = <Widget>[];
    String? lastGroup;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      // Section header
      if (item.group != null && item.group != lastGroup) {
        lastGroup = item.group;
        if (rows.isNotEmpty) {
          rows.add(SizedBox(height: 1));
        }
        rows.add(
          Padding(
            padding: const EdgeInsets.only(left: 3, right: 3),
            child: Text(item.group!, style: headerStyle),
          ),
        );
      }

      // Item row
      final isSelected = i == _selectedIndex;
      final itemStyle = isSelected ? selectedStyle : normalStyle;
      final itemShortcutStyle = isSelected
          ? selectedShortcutStyle
          : shortcutStyle;

      Widget row = Row(
        children: [
          Expanded(child: Text(item.label, style: itemStyle, softWrap: false)),
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(
                item.description!,
                style: itemShortcutStyle,
                softWrap: false,
              ),
            ),
          if (item.shortcut != null)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                item.shortcut!,
                style: itemShortcutStyle,
                softWrap: false,
              ),
            ),
        ],
      );

      row = GestureDetector(
        onEnter: (_) => _highlightHoveredIndex(i),
        onTap: () {
          setState(() {
            _selectedIndex = i;
            _scrollSelectedItemIntoView(items);
          });
          return _selectCurrent();
        },
        child: Container(
          color: isSelected ? selBg : null,
          padding: const EdgeInsets.only(left: 3, right: 3),
          child: row,
        ),
      );

      rows.add(row);
    }

    // Build the palette dialog
    final titleRow = widget.title != null
        ? Row(
            children: [
              Expanded(
                child: Text(
                  widget.title!,
                  style: copyStyle(theme.titleSmall)
                    ..foreground(fg)
                    ..bold(),
                ),
              ),
              Text(
                'esc',
                style: copyStyle(theme.labelSmall)..foreground(theme.muted),
              ),
            ],
          )
        : null;

    final reservedRows = (titleRow != null ? 5 : 3);
    final availableListRows = math.max(3, maxH - reservedRows);
    final listHeight = math.max(
      3,
      math.min(rows.length + 1, availableListRows),
    );

    final listBody = rows.isEmpty
        ? Padding(
            padding: const EdgeInsets.only(left: 3, right: 3),
            child: Text(
              'No results found',
              style: copyStyle(theme.bodySmall)..foreground(theme.muted),
            ),
          )
        : SingleChildScrollView(
            controller: _listController,
            handleKeys: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          );

    // FocusScope trap (via Modal) + autofocus so search steals from prompt.
    final dialog = ClipRect(
      child: SizedBox(
        width: paletteWidth,
        child: Container(
          color: bg,
          child: Frame(
            border: bdr,
            borderColor: bdrColor,
            padding: const EdgeInsets.only(top: 1, bottom: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (titleRow != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: titleRow,
                  ),
                SizedBox(height: 1),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: Container(
                    color: searchBg,
                    padding: const EdgeInsets.only(left: 1, right: 1),
                    child: TextField(
                      focusId: 'command-palette-search',
                      prompt: '',
                      placeholder: widget.hint ?? 'Search',
                      onChanged: _onSearchChanged,
                      autofocus: true,
                    ),
                  ),
                ),
                SizedBox(height: 1),
                SizedBox(
                  height: listHeight,
                  child: Container(
                    color: bg,
                    padding: const EdgeInsets.only(left: 1, right: 1),
                    child: listBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: widget.open
              ? (1.0 - widget.backdropOpacity).clamp(0.2, 1.0)
              : 1.0,
          child: IgnorePointer(ignoring: widget.open, child: widget.child),
        ),
        if (widget.open) ...[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => widget.onDismiss?.call(),
              child: Container(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: FocusScope(isTrapped: true, child: dialog)),
          ),
        ],
      ],
    );
  }
}
