import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import '../../style/style.dart';
import '../../style/color.dart';
import 'key_binding.dart';
import 'paginator.dart';

/// Message sent when an item is selected.
class SelectionMadeMsg<T> extends Msg {
  const SelectionMadeMsg(this.item, this.index);

  /// The selected item.
  final T item;

  /// The index of the selected item.
  final int index;

  @override
  String toString() => 'SelectionMadeMsg($item, index: $index)';
}

/// Message sent when selection is cancelled.
class SelectionCancelledMsg extends Msg {
  const SelectionCancelledMsg();

  @override
  String toString() => 'SelectionCancelledMsg()';
}

/// Key bindings for the select component.
class SelectKeyMap implements KeyMap {
  SelectKeyMap({
    KeyBinding? up,
    KeyBinding? down,
    KeyBinding? home,
    KeyBinding? end,
    KeyBinding? pageUp,
    KeyBinding? pageDown,
    KeyBinding? select,
    KeyBinding? cancel,
  }) : up =
           up ??
           KeyBinding(
             keys: ['up', 'k'],
             help: Help(key: '↑/k', desc: 'up'),
           ),
       down =
           down ??
           KeyBinding(
             keys: ['down', 'j'],
             help: Help(key: '↓/j', desc: 'down'),
           ),
       home =
           home ??
           KeyBinding(
             keys: ['home', 'g'],
             help: Help(key: 'home', desc: 'first'),
           ),
       end =
           end ??
           KeyBinding(
             keys: ['end', 'G'],
             help: Help(key: 'end', desc: 'last'),
           ),
       pageUp =
           pageUp ??
           KeyBinding(
             keys: ['pgup', 'ctrl+u'],
             help: Help(key: 'pgup', desc: 'page up'),
           ),
       pageDown =
           pageDown ??
           KeyBinding(
             keys: ['pgdown', 'ctrl+d'],
             help: Help(key: 'pgdn', desc: 'page down'),
           ),
       select =
           select ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: '↵', desc: 'select'),
           ),
       cancel =
           cancel ??
           KeyBinding(
             keys: ['esc', 'q'],
             help: Help(key: 'esc', desc: 'cancel'),
           );

  /// Move cursor up.
  final KeyBinding up;

  /// Move cursor down.
  final KeyBinding down;

  /// Jump to first item.
  final KeyBinding home;

  /// Jump to last item.
  final KeyBinding end;

  /// Page up.
  final KeyBinding pageUp;

  /// Page down.
  final KeyBinding pageDown;

  /// Confirm selection.
  final KeyBinding select;

  /// Cancel selection.
  final KeyBinding cancel;

  @override
  List<KeyBinding> shortHelp() {
    return [up, down, select, cancel];
  }

  @override
  List<List<KeyBinding>> fullHelp() {
    return [
      [up, down, home, end],
      [pageUp, pageDown, select, cancel],
    ];
  }
}

/// Styles for the select component.
class SelectStyles {
  SelectStyles({
    Style? title,
    Style? item,
    Style? selectedItem,
    Style? cursor,
    Style? dimmed,
    String? cursorPrefix,
    String? itemPrefix,
  }) : title = title ?? Style().bold(),
       item = item ?? Style(),
       selectedItem = selectedItem ?? Style().foreground(AnsiColor(14)),
       cursor = cursor ?? Style().foreground(AnsiColor(14)),
       dimmed = dimmed ?? Style().foreground(AnsiColor(8)),
       cursorPrefix = cursorPrefix ?? '❯ ',
       itemPrefix = itemPrefix ?? '  ';

  /// Style for the title/prompt.
  final Style title;

  /// Style for unselected items.
  final Style item;

  /// Style for the currently highlighted item.
  final Style selectedItem;

  /// Style for the cursor indicator.
  final Style cursor;

  /// Style for dimmed elements.
  final Style dimmed;

  /// Prefix shown before the selected item.
  final String cursorPrefix;

  /// Prefix shown before non-selected items.
  final String itemPrefix;

  /// Creates default styles.
  factory SelectStyles.defaults() => SelectStyles();
}

/// A single-select component following the Model architecture.
///
/// Displays a list of items and allows the user to select one.
///
/// ## Example
///
/// ```dart
/// final select = SelectModel<String>(
///   title: 'Choose a color:',
///   items: ['Red', 'Green', 'Blue'],
/// );
///
/// // In your update function:
/// switch (msg) {
///   case SelectionMadeMsg<String>(:final item):
///     print('Selected: $item');
///     return (this, Cmd.quit());
///   case SelectionCancelledMsg():
///     return (this, Cmd.quit());
/// }
/// ```
class SelectModel<T> extends ViewComponent {
  /// Creates a new select model.
  SelectModel({
    required List<T> items,
    this.title = 'Select an option:',
    this.showTitle = true,
    this.showHelp = true,
    this.showPagination = true,
    int height = 10,
    int initialIndex = 0,
    this.display,
    SelectKeyMap? keyMap,
    SelectStyles? styles,
  }) : _items = items,
       keyMap = keyMap ?? SelectKeyMap(),
       styles = styles ?? SelectStyles.defaults(),
       _cursor = initialIndex.clamp(0, items.isEmpty ? 0 : items.length - 1),
       _height = height {
    _paginator = PaginatorModel(
      type: PaginationType.dots,
      activeDot: '●',
      inactiveDot: '○',
    );
    _updatePagination();
  }

  /// The title/prompt displayed above the list.
  final String title;

  /// Whether to show the title.
  final bool showTitle;

  /// Whether to show help text.
  final bool showHelp;

  /// Whether to show pagination.
  final bool showPagination;

  /// Key bindings.
  final SelectKeyMap keyMap;

  /// Styles.
  final SelectStyles styles;

  /// Custom display function for items.
  final String Function(T)? display;

  // Internal state
  final List<T> _items;
  late PaginatorModel _paginator;
  int _cursor;
  final int _height;

  /// Gets the items.
  List<T> get items => List.unmodifiable(_items);

  /// Gets the current cursor position.
  int get cursor => _cursor;

  /// Gets the currently highlighted item.
  T? get selectedItem {
    if (_items.isEmpty || _cursor >= _items.length) return null;
    return _items[_cursor];
  }

  /// Gets the visible height for items.
  int get _visibleHeight {
    var h = _height;
    if (showTitle) h -= 1;
    if (showHelp) h -= 1;
    if (showPagination && _paginator.totalPages > 1) h -= 1;
    return h.clamp(1, _items.length);
  }

  /// Gets display text for an item.
  String _displayItem(T item) {
    return display?.call(item) ?? item.toString();
  }

  /// Move cursor up.
  void _cursorUp() {
    if (_cursor > 0) {
      _cursor--;
      _updatePagination();
    }
  }

  /// Move cursor down.
  void _cursorDown() {
    if (_cursor < _items.length - 1) {
      _cursor++;
      _updatePagination();
    }
  }

  /// Jump to first item.
  void _goToStart() {
    _cursor = 0;
    _updatePagination();
  }

  /// Jump to last item.
  void _goToEnd() {
    _cursor = _items.isEmpty ? 0 : _items.length - 1;
    _updatePagination();
  }

  /// Page up.
  void _pageUp() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor - pageSize).clamp(0, _items.length - 1);
    _updatePagination();
  }

  /// Page down.
  void _pageDown() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor + pageSize).clamp(0, _items.length - 1);
    _updatePagination();
  }

  void _updatePagination() {
    if (_items.isEmpty) return;
    final pageSize = _visibleHeight;
    final page = _cursor ~/ pageSize;
    final totalPages = (_items.length / pageSize).ceil();
    _paginator = PaginatorModel(
      page: page,
      perPage: pageSize,
      totalPages: totalPages,
      type: PaginationType.dots,
      activeDot: '●',
      inactiveDot: '○',
    );
  }

  @override
  Cmd? init() => null;

  @override
  (SelectModel<T>, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      final key = msg.key;

      // Check for Ctrl+C
      if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63) {
        return (this, Cmd.message(const SelectionCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.cancel])) {
        return (this, Cmd.message(const SelectionCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.select])) {
        if (_items.isNotEmpty) {
          return (
            this,
            Cmd.message(SelectionMadeMsg<T>(_items[_cursor], _cursor)),
          );
        }
        return (this, null);
      }

      if (keyMatches(key, [keyMap.up])) {
        _cursorUp();
      } else if (keyMatches(key, [keyMap.down])) {
        _cursorDown();
      } else if (keyMatches(key, [keyMap.home])) {
        _goToStart();
      } else if (keyMatches(key, [keyMap.end])) {
        _goToEnd();
      } else if (keyMatches(key, [keyMap.pageUp])) {
        _pageUp();
      } else if (keyMatches(key, [keyMap.pageDown])) {
        _pageDown();
      }
    }

    return (this, null);
  }

  @override
  String view() {
    if (_items.isEmpty) {
      final buffer = StringBuffer();
      if (showTitle) {
        buffer.writeln(styles.title.render(title));
      }
      buffer.writeln(styles.dimmed.render('  No items'));
      return buffer.toString();
    }

    final buffer = StringBuffer();

    // Title
    if (showTitle) {
      buffer.writeln(styles.title.render(title));
    }

    // Calculate visible range
    final pageSize = _visibleHeight;
    final startIndex = (_cursor ~/ pageSize) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _items.length);

    // Render items
    for (var i = startIndex; i < endIndex; i++) {
      final item = _items[i];
      final isSelected = i == _cursor;
      final displayText = _displayItem(item);

      if (isSelected) {
        buffer.writeln(
          '${styles.cursor.render(styles.cursorPrefix)}${styles.selectedItem.render(displayText)}',
        );
      } else {
        buffer.writeln(
          '${styles.itemPrefix}${styles.item.render(displayText)}',
        );
      }
    }

    // Pagination
    if (showPagination && _paginator.totalPages > 1) {
      buffer.writeln(styles.dimmed.render(_paginator.view()));
    }

    // Help
    if (showHelp) {
      final helpItems = keyMap.shortHelp();
      final helpText = helpItems
          .where((b) => b.help.hasContent)
          .map((b) => '${b.help.key} ${b.help.desc}')
          .join('  ');
      buffer.writeln(styles.dimmed.render(helpText));
    }

    return buffer.toString();
  }
}

/// Message sent when multiple items are selected.
class MultiSelectionMadeMsg<T> extends Msg {
  const MultiSelectionMadeMsg(this.items, this.indices);

  /// The selected items.
  final List<T> items;

  /// The indices of the selected items.
  final List<int> indices;

  @override
  String toString() => 'MultiSelectionMadeMsg($items, indices: $indices)';
}

/// Key bindings for the multi-select component.
class MultiSelectKeyMap implements KeyMap {
  MultiSelectKeyMap({
    KeyBinding? up,
    KeyBinding? down,
    KeyBinding? home,
    KeyBinding? end,
    KeyBinding? pageUp,
    KeyBinding? pageDown,
    KeyBinding? toggle,
    KeyBinding? toggleAll,
    KeyBinding? confirm,
    KeyBinding? cancel,
  }) : up =
           up ??
           KeyBinding(
             keys: ['up', 'k'],
             help: Help(key: '↑/k', desc: 'up'),
           ),
       down =
           down ??
           KeyBinding(
             keys: ['down', 'j'],
             help: Help(key: '↓/j', desc: 'down'),
           ),
       home =
           home ??
           KeyBinding(
             keys: ['home', 'g'],
             help: Help(key: 'home', desc: 'first'),
           ),
       end =
           end ??
           KeyBinding(
             keys: ['end', 'G'],
             help: Help(key: 'end', desc: 'last'),
           ),
       pageUp =
           pageUp ??
           KeyBinding(
             keys: ['pgup', 'ctrl+u'],
             help: Help(key: 'pgup', desc: 'page up'),
           ),
       pageDown =
           pageDown ??
           KeyBinding(
             keys: ['pgdown', 'ctrl+d'],
             help: Help(key: 'pgdn', desc: 'page down'),
           ),
       toggle =
           toggle ??
           KeyBinding(
             keys: [' ', 'x'],
             help: Help(key: 'space', desc: 'toggle'),
           ),
       toggleAll =
           toggleAll ??
           KeyBinding(
             keys: ['a'],
             help: Help(key: 'a', desc: 'toggle all'),
           ),
       confirm =
           confirm ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: '↵', desc: 'confirm'),
           ),
       cancel =
           cancel ??
           KeyBinding(
             keys: ['esc', 'q'],
             help: Help(key: 'esc', desc: 'cancel'),
           );

  /// Move cursor up.
  final KeyBinding up;

  /// Move cursor down.
  final KeyBinding down;

  /// Jump to first item.
  final KeyBinding home;

  /// Jump to last item.
  final KeyBinding end;

  /// Page up.
  final KeyBinding pageUp;

  /// Page down.
  final KeyBinding pageDown;

  /// Toggle current item selection.
  final KeyBinding toggle;

  /// Toggle all items.
  final KeyBinding toggleAll;

  /// Confirm selection.
  final KeyBinding confirm;

  /// Cancel selection.
  final KeyBinding cancel;

  @override
  List<KeyBinding> shortHelp() {
    return [up, down, toggle, confirm, cancel];
  }

  @override
  List<List<KeyBinding>> fullHelp() {
    return [
      [up, down, home, end],
      [toggle, toggleAll, confirm, cancel],
    ];
  }
}

/// Styles for the multi-select component.
class MultiSelectStyles {
  MultiSelectStyles({
    Style? title,
    Style? item,
    Style? highlightedItem,
    Style? selectedIcon,
    Style? unselectedIcon,
    Style? dimmed,
    String? cursorPrefix,
    String? selectedIconChar,
    String? unselectedIconChar,
  }) : title = title ?? Style().bold(),
       item = item ?? Style(),
       highlightedItem = highlightedItem ?? Style().foreground(AnsiColor(14)),
       selectedIcon = selectedIcon ?? Style().foreground(AnsiColor(10)),
       unselectedIcon = unselectedIcon ?? Style().foreground(AnsiColor(8)),
       dimmed = dimmed ?? Style().foreground(AnsiColor(8)),
       cursorPrefix = cursorPrefix ?? '❯',
       selectedIconChar = selectedIconChar ?? '●',
       unselectedIconChar = unselectedIconChar ?? '○';

  /// Style for the title/prompt.
  final Style title;

  /// Style for unselected items.
  final Style item;

  /// Style for the currently highlighted item.
  final Style highlightedItem;

  /// Style for selected item icon.
  final Style selectedIcon;

  /// Style for unselected item icon.
  final Style unselectedIcon;

  /// Style for dimmed elements.
  final Style dimmed;

  /// Prefix shown before the highlighted item.
  final String cursorPrefix;

  /// Character for selected items.
  final String selectedIconChar;

  /// Character for unselected items.
  final String unselectedIconChar;

  /// Creates default styles.
  factory MultiSelectStyles.defaults() => MultiSelectStyles();
}

/// A multi-select component following the Model architecture.
///
/// Displays a list of items and allows the user to select multiple.
///
/// ## Example
///
/// ```dart
/// final multiSelect = MultiSelectModel<String>(
///   title: 'Choose colors:',
///   items: ['Red', 'Green', 'Blue'],
/// );
///
/// // In your update function:
/// switch (msg) {
///   case MultiSelectionMadeMsg<String>(:final items):
///     print('Selected: $items');
///     return (this, Cmd.quit());
/// }
/// ```
class MultiSelectModel<T> extends ViewComponent {
  /// Creates a new multi-select model.
  MultiSelectModel({
    required List<T> items,
    this.title = 'Select options:',
    this.hint = '(Space to toggle, Enter to confirm)',
    this.showTitle = true,
    this.showHint = true,
    this.showHelp = true,
    this.showPagination = true,
    int height = 10,
    int initialIndex = 0,
    Set<int>? initialSelected,
    this.display,
    MultiSelectKeyMap? keyMap,
    MultiSelectStyles? styles,
  }) : _items = items,
       _selected = initialSelected ?? {},
       keyMap = keyMap ?? MultiSelectKeyMap(),
       styles = styles ?? MultiSelectStyles.defaults(),
       _cursor = initialIndex.clamp(0, items.isEmpty ? 0 : items.length - 1),
       _height = height {
    _paginator = PaginatorModel(
      type: PaginationType.dots,
      activeDot: '●',
      inactiveDot: '○',
    );
    _updatePagination();
  }

  /// The title/prompt displayed above the list.
  final String title;

  /// Hint text displayed below title.
  final String hint;

  /// Whether to show the title.
  final bool showTitle;

  /// Whether to show the hint.
  final bool showHint;

  /// Whether to show help text.
  final bool showHelp;

  /// Whether to show pagination.
  final bool showPagination;

  /// Key bindings.
  final MultiSelectKeyMap keyMap;

  /// Styles.
  final MultiSelectStyles styles;

  /// Custom display function for items.
  final String Function(T)? display;

  // Internal state
  final List<T> _items;
  late PaginatorModel _paginator;
  int _cursor;
  final int _height;
  final Set<int> _selected;

  /// Gets the items.
  List<T> get items => List.unmodifiable(_items);

  /// Gets the current cursor position.
  int get cursor => _cursor;

  /// Gets the selected indices.
  Set<int> get selectedIndices => Set.unmodifiable(_selected);

  /// Gets the selected items.
  List<T> get selectedItems {
    final indices = _selected.toList()..sort();
    return indices.map((i) => _items[i]).toList();
  }

  /// Gets the visible height for items.
  int get _visibleHeight {
    var h = _height;
    if (showTitle) h -= 1;
    if (showHint) h -= 1;
    if (showHelp) h -= 1;
    if (showPagination && _paginator.totalPages > 1) h -= 1;
    return h.clamp(1, _items.length);
  }

  /// Gets display text for an item.
  String _displayItem(T item) {
    return display?.call(item) ?? item.toString();
  }

  /// Move cursor up.
  void _cursorUp() {
    if (_cursor > 0) {
      _cursor--;
      _updatePagination();
    }
  }

  /// Move cursor down.
  void _cursorDown() {
    if (_cursor < _items.length - 1) {
      _cursor++;
      _updatePagination();
    }
  }

  /// Jump to first item.
  void _goToStart() {
    _cursor = 0;
    _updatePagination();
  }

  /// Jump to last item.
  void _goToEnd() {
    _cursor = _items.isEmpty ? 0 : _items.length - 1;
    _updatePagination();
  }

  /// Page up.
  void _pageUp() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor - pageSize).clamp(0, _items.length - 1);
    _updatePagination();
  }

  /// Page down.
  void _pageDown() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor + pageSize).clamp(0, _items.length - 1);
    _updatePagination();
  }

  /// Toggle selection of current item.
  void _toggleSelection() {
    if (_items.isEmpty) return;
    if (_selected.contains(_cursor)) {
      _selected.remove(_cursor);
    } else {
      _selected.add(_cursor);
    }
  }

  /// Toggle all items.
  void _toggleAll() {
    if (_selected.length == _items.length) {
      _selected.clear();
    } else {
      _selected.addAll(List.generate(_items.length, (i) => i));
    }
  }

  void _updatePagination() {
    if (_items.isEmpty) return;
    final pageSize = _visibleHeight;
    final page = _cursor ~/ pageSize;
    final totalPages = (_items.length / pageSize).ceil();
    _paginator = PaginatorModel(
      page: page,
      perPage: pageSize,
      totalPages: totalPages,
      type: PaginationType.dots,
      activeDot: '●',
      inactiveDot: '○',
    );
  }

  @override
  Cmd? init() => null;

  @override
  (MultiSelectModel<T>, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      final key = msg.key;

      // Check for Ctrl+C
      if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63) {
        return (this, Cmd.message(const SelectionCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.cancel])) {
        return (this, Cmd.message(const SelectionCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.confirm])) {
        final selectedItems = _selected.toList()..sort();
        final result = selectedItems.map((i) => _items[i]).toList();
        return (
          this,
          Cmd.message(MultiSelectionMadeMsg<T>(result, selectedItems)),
        );
      }

      if (keyMatches(key, [keyMap.toggle])) {
        _toggleSelection();
      } else if (keyMatches(key, [keyMap.toggleAll])) {
        _toggleAll();
      } else if (keyMatches(key, [keyMap.up])) {
        _cursorUp();
      } else if (keyMatches(key, [keyMap.down])) {
        _cursorDown();
      } else if (keyMatches(key, [keyMap.home])) {
        _goToStart();
      } else if (keyMatches(key, [keyMap.end])) {
        _goToEnd();
      } else if (keyMatches(key, [keyMap.pageUp])) {
        _pageUp();
      } else if (keyMatches(key, [keyMap.pageDown])) {
        _pageDown();
      }
    }

    return (this, null);
  }

  @override
  String view() {
    if (_items.isEmpty) {
      final buffer = StringBuffer();
      if (showTitle) {
        buffer.writeln(styles.title.render(title));
      }
      buffer.writeln(styles.dimmed.render('  No items'));
      return buffer.toString();
    }

    final buffer = StringBuffer();

    // Title
    if (showTitle) {
      buffer.writeln(styles.title.render(title));
    }

    // Hint
    if (showHint && hint.isNotEmpty) {
      buffer.writeln(styles.dimmed.render('  $hint'));
    }

    // Calculate visible range
    final pageSize = _visibleHeight;
    final startIndex = (_cursor ~/ pageSize) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _items.length);

    // Render items
    for (var i = startIndex; i < endIndex; i++) {
      final item = _items[i];
      final isHighlighted = i == _cursor;
      final isSelected = _selected.contains(i);
      final displayText = _displayItem(item);

      final icon = isSelected
          ? styles.selectedIcon.render(styles.selectedIconChar)
          : styles.unselectedIcon.render(styles.unselectedIconChar);

      final prefix = isHighlighted ? styles.cursorPrefix : ' ';
      final itemStyle = isHighlighted ? styles.highlightedItem : styles.item;

      buffer.writeln('  $prefix $icon ${itemStyle.render(displayText)}');
    }

    // Pagination
    if (showPagination && _paginator.totalPages > 1) {
      buffer.writeln(styles.dimmed.render(_paginator.view()));
    }

    // Help
    if (showHelp) {
      final helpItems = keyMap.shortHelp();
      final helpText = helpItems
          .where((b) => b.help.hasContent)
          .map((b) => '${b.help.key} ${b.help.desc}')
          .join('  ');
      buffer.writeln(styles.dimmed.render(helpText));
    }

    return buffer.toString();
  }
}
