part of 'components_widgets.dart';

/// A single item in a [CommandPalette].
class CommandPaletteItem {
  const CommandPaletteItem({
    required this.label,
    this.description,
    this.shortcut,
    this.group,
    this.onSelect,
    this.enabled = true,
  });

  /// Display text for the item.
  final String label;

  /// Optional secondary description text.
  final String? description;

  /// Optional keyboard shortcut hint (displayed right-aligned).
  final String? shortcut;

  /// Group name for section headers. Items with the same group are
  /// displayed under a shared header.
  final String? group;

  /// Callback when this item is selected. Returns a [Cmd] or null.
  final CmdCallback? onSelect;

  /// Whether the item is selectable.
  final bool enabled;
}

/// A searchable, grouped list displayed in a modal overlay.
///
/// Modeled after VS Code's command palette / Ctrl+P picker. Supports:
/// - Fuzzy text filtering via a search input
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
///     CommandPaletteItem(label: 'Open File', shortcut: 'ctrl+o', group: 'File'),
///     CommandPaletteItem(label: 'Save', shortcut: 'ctrl+s', group: 'File'),
///     CommandPaletteItem(label: 'Find', shortcut: 'ctrl+f', group: 'Edit'),
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
}

class _CommandPaletteState extends State<CommandPalette> {
  String _query = '';
  int _selectedIndex = 0;

  List<CommandPaletteItem> get _filteredItems {
    if (_query.isEmpty) {
      return widget.items.where((item) => item.enabled).toList();
    }
    final lower = _query.toLowerCase();
    return widget.items
        .where(
          (item) => item.enabled && item.label.toLowerCase().contains(lower),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _selectedIndex = 0;
    });
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
          _selectedIndex = (_selectedIndex - 1) % items.length;
          if (_selectedIndex < 0) _selectedIndex = items.length - 1;
        }
      });
      return Cmd.none();
    }
    if (key.type == terminal_keys.KeyType.down) {
      setState(() {
        final items = _filteredItems;
        if (items.isNotEmpty) {
          _selectedIndex = (_selectedIndex + 1) % items.length;
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
    if (!widget.open) return widget.child;

    final theme = ThemeScope.of(context);
    final cpTheme = theme.commandPaletteTheme;
    final media = MediaQuery.of(context);

    final bg = widget.background ?? cpTheme?.background ?? theme.surface;
    final selBg =
        widget.selectedBackground ??
        cpTheme?.selectedBackground ??
        theme.resolvedHighlight;
    final selFg =
        widget.selectedForeground ??
        cpTheme?.selectedForeground ??
        theme.resolvedOnHighlight;
    final headerFg = cpTheme?.headerForeground ?? theme.muted;
    final shortcutFg = cpTheme?.shortcutForeground ?? theme.muted;
    final bdr = widget.border ?? cpTheme?.border ?? Border.rounded;
    final bdrColor = widget.borderColor ?? cpTheme?.borderColor ?? theme.border;
    final paletteWidth =
        widget.width ??
        cpTheme?.width ??
        math.min(60, media.size.width.toInt() - 4);
    final maxH =
        widget.maxHeight ?? cpTheme?.maxHeight ?? media.size.height.toInt() - 6;

    final items = _filteredItems;
    final headerStyle = _copyStyle(theme.labelSmall)
      ..foreground(headerFg)
      ..bold();
    final normalStyle = _copyStyle(theme.bodyMedium)
      ..foreground(theme.onSurface);
    final selectedStyle = _copyStyle(theme.bodyMedium)..foreground(selFg);
    final shortcutStyle = _copyStyle(theme.labelSmall)..foreground(shortcutFg);

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
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(item.group!, style: headerStyle),
          ),
        );
      }

      // Item row
      final isSelected = i == _selectedIndex;
      final itemStyle = isSelected ? selectedStyle : normalStyle;

      Widget row = Row(
        children: [
          Expanded(child: Text(item.label, style: itemStyle, softWrap: false)),
          if (item.shortcut != null)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                item.shortcut!,
                style: shortcutStyle,
                softWrap: false,
              ),
            ),
        ],
      );

      row = GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = i);
          return _selectCurrent();
        },
        child: Frame(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
          background: isSelected ? selBg : bg,
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
                  style: _copyStyle(theme.titleSmall)
                    ..foreground(theme.onSurface)
                    ..bold(),
                ),
              ),
              Text(
                'esc',
                style: _copyStyle(theme.labelSmall)..foreground(theme.muted),
              ),
            ],
          )
        : null;

    final listHeight = math.min(rows.length + 1, maxH - 4);

    final dialog = ClipRect(
      child: SizedBox(
        width: paletteWidth,
        child: Frame(
          background: bg,
          border: bdr,
          borderColor: bdrColor,
          padding: const EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (titleRow != null) titleRow,
              if (titleRow != null)
                Divider(style: Style()..foreground(theme.border)),
              TextField(
                focusId: 'command-palette-search',
                placeholder: widget.hint ?? 'Type to search...',
                onChanged: _onSearchChanged,
                autofocus: true,
              ),
              Divider(style: Style()..foreground(theme.border)),
              SizedBox(
                height: listHeight,
                child: Container(
                  color: bg,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: rows,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Modal(
      open: true,
      onDismiss: widget.onDismiss,
      backdropOpacity: widget.backdropOpacity,
      child: widget.child,
      dialog: dialog,
    );
  }
}
