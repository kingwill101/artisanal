import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import '../view.dart';
import '../../style/style.dart';
import '../../style/color.dart';
import 'key_binding.dart';
import 'textinput.dart';
import 'paginator.dart';

/// Message sent when a search result is selected.
class SearchSelectionMadeMsg<T> extends Msg {
  const SearchSelectionMadeMsg(this.item, this.index);

  /// The selected item.
  final T item;

  /// The index of the selected item in the original list.
  final int index;

  @override
  String toString() => 'SearchSelectionMadeMsg($item, index: $index)';
}

/// Message sent when search is cancelled.
class SearchCancelledMsg extends Msg {
  const SearchCancelledMsg();

  @override
  String toString() => 'SearchCancelledMsg()';
}

/// A filtered item with its original index and match positions.
class FilteredSearchItem<T> {
  const FilteredSearchItem({
    required this.item,
    required this.index,
    this.matches = const [],
  });

  /// The item.
  final T item;

  /// Original index in the unfiltered list.
  final int index;

  /// Indices of matched characters (for highlighting).
  final List<int> matches;
}

/// Filter function type for search.
typedef SearchFilterFunc<T> =
    List<FilteredSearchItem<T>> Function(
      String query,
      List<T> items,
      String Function(T) toString,
    );

/// Default fuzzy filter implementation.
List<FilteredSearchItem<T>> defaultSearchFilter<T>(
  String query,
  List<T> items,
  String Function(T) toString,
) {
  if (query.isEmpty) {
    return items
        .asMap()
        .entries
        .map((e) => FilteredSearchItem(item: e.value, index: e.key))
        .toList();
  }

  final results = <FilteredSearchItem<T>>[];
  final queryLower = query.toLowerCase();

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final text = toString(item).toLowerCase();

    // Simple substring match with character positions
    final matches = <int>[];
    var queryIndex = 0;

    for (var j = 0; j < text.length && queryIndex < queryLower.length; j++) {
      if (text[j] == queryLower[queryIndex]) {
        matches.add(j);
        queryIndex++;
      }
    }

    if (queryIndex == queryLower.length) {
      results.add(FilteredSearchItem(item: item, index: i, matches: matches));
    }
  }

  return results;
}

/// Key bindings for the search component.
class SearchKeyMap implements KeyMap {
  SearchKeyMap({
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
             keys: ['up', 'ctrl+p'],
             help: Help(key: '↑', desc: 'up'),
           ),
       down =
           down ??
           KeyBinding(
             keys: ['down', 'ctrl+n'],
             help: Help(key: '↓', desc: 'down'),
           ),
       home =
           home ??
           KeyBinding(
             keys: ['ctrl+home'],
             help: Help(key: '^home', desc: 'first'),
           ),
       end =
           end ??
           KeyBinding(
             keys: ['ctrl+end'],
             help: Help(key: '^end', desc: 'last'),
           ),
       pageUp =
           pageUp ??
           KeyBinding(
             keys: ['pgup'],
             help: Help(key: 'pgup', desc: 'page up'),
           ),
       pageDown =
           pageDown ??
           KeyBinding(
             keys: ['pgdown'],
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
             keys: ['esc'],
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

  /// Cancel search.
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

/// Styles for the search component.
class SearchStyles {
  SearchStyles._({
    required this.title,
    required this.prompt,
    required this.item,
    required this.selectedItem,
    required this.matchHighlight,
    required this.cursor,
    required this.dimmed,
    required this.noResults,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.selectedIconChar,
    required this.unselectedIconChar,
    required this.cursorPrefix,
    required this.itemPrefix,
  });

  /// Creates default styles.
  factory SearchStyles({
    Style? title,
    Style? prompt,
    Style? item,
    Style? selectedItem,
    Style? matchHighlight,
    Style? cursor,
    Style? dimmed,
    Style? noResults,
    Style? selectedIcon,
    Style? unselectedIcon,
    String? selectedIconChar,
    String? unselectedIconChar,
    String? cursorPrefix,
    String? itemPrefix,
  }) => SearchStyles._(
    title: title ?? Style().bold(),
    prompt: prompt ?? Style().foreground(AnsiColor(11)),
    item: item ?? Style(),
    selectedItem: selectedItem ?? Style().foreground(AnsiColor(14)),
    matchHighlight: matchHighlight ?? Style().foreground(AnsiColor(11)).bold(),
    cursor: cursor ?? Style().foreground(AnsiColor(14)),
    dimmed: dimmed ?? Style().foreground(AnsiColor(8)),
    noResults: noResults ?? Style().foreground(AnsiColor(8)).italic(),
    selectedIcon: selectedIcon ?? Style().foreground(AnsiColor(10)),
    unselectedIcon: unselectedIcon ?? Style().foreground(AnsiColor(8)),
    selectedIconChar: selectedIconChar ?? '●',
    unselectedIconChar: unselectedIconChar ?? '○',
    cursorPrefix: cursorPrefix ?? '❯ ',
    itemPrefix: itemPrefix ?? '  ',
  );

  /// Style for the title.
  final Style title;

  /// Style for the search prompt.
  final Style prompt;

  /// Style for unselected items.
  final Style item;

  /// Style for the currently highlighted item.
  final Style selectedItem;

  /// Style for matched characters.
  final Style matchHighlight;

  /// Style for the cursor indicator.
  final Style cursor;

  /// Style for dimmed elements.
  final Style dimmed;

  /// Style for "no results" message.
  final Style noResults;

  /// Style for selected item icon.
  final Style selectedIcon;

  /// Style for unselected item icon.
  final Style unselectedIcon;

  /// Character for selected items.
  final String selectedIconChar;

  /// Character for unselected items.
  final String unselectedIconChar;

  /// Prefix shown before the selected item.
  final String cursorPrefix;

  /// Prefix shown before non-selected items.
  final String itemPrefix;

  /// Creates default styles.
  factory SearchStyles.defaults() => SearchStyles();
}

/// Message sent when multiple search results are selected.
class MultiSearchSelectionMadeMsg<T> extends Msg {
  const MultiSearchSelectionMadeMsg(this.items, this.indices);

  /// The selected items.
  final List<T> items;

  /// The indices of the selected items in the original list.
  final List<int> indices;

  @override
  String toString() => 'MultiSearchSelectionMadeMsg($items, indices: $indices)';
}

/// Key bindings for the multi-search component.
class MultiSearchKeyMap extends SearchKeyMap {
  MultiSearchKeyMap({
    super.up,
    super.down,
    super.home,
    super.end,
    super.pageUp,
    super.pageDown,
    super.cancel,
    KeyBinding? toggle,
    KeyBinding? toggleAll,
    KeyBinding? confirm,
  }) : toggle =
           toggle ??
           KeyBinding(
             keys: [' ', 'ctrl+space'],
             help: Help(key: 'space', desc: 'toggle'),
           ),
       toggleAll =
           toggleAll ??
           KeyBinding(
             keys: ['ctrl+a'],
             help: Help(key: '^a', desc: 'toggle all'),
           ),
       confirm =
           confirm ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: '↵', desc: 'confirm'),
           );

  /// Toggle current item selection.
  final KeyBinding toggle;

  /// Toggle all currently filtered items.
  final KeyBinding toggleAll;

  /// Confirm multi-selection.
  final KeyBinding confirm;

  @override
  List<KeyBinding> shortHelp() {
    return [up, down, toggle, confirm, cancel];
  }

  @override
  List<List<KeyBinding>> fullHelp() {
    return [
      [up, down, home, end],
      [pageUp, pageDown, toggle, toggleAll, confirm, cancel],
    ];
  }
}

/// A search/filter component following the Model architecture.
///
/// Combines a text input with a filterable list of items.
///
/// ## Example
///
/// ```dart
/// final search = SearchModel<String>(
///   title: 'Search files:',
///   items: ['main.dart', 'pubspec.yaml', 'README.md'],
/// );
///
/// // In your update function:
/// switch (msg) {
///   case SearchSelectionMadeMsg<String>(:final item):
///     print('Selected: $item');
///     return (this, Cmd.quit());
///   case SearchCancelledMsg():
///     return (this, Cmd.quit());
/// }
/// ```
class SearchModel<T> extends ViewComponent {
  /// Creates a new search model.
  SearchModel({
    required List<T> items,
    this.title = '',
    this.placeholder = 'Type to search...',
    this.noResultsText = 'No matches found',
    this.showTitle = true,
    this.showHelp = true,
    this.showPagination = true,
    this.highlightMatches = true,
    int height = 10,
    int initialIndex = 0,
    this.display,
    SearchFilterFunc<T>? filter,
    SearchKeyMap? keyMap,
    SearchStyles? styles,
  }) : _items = items,
       _filter = filter ?? defaultSearchFilter,
       keyMap = keyMap ?? SearchKeyMap(),
       styles = styles ?? SearchStyles.defaults(),
       _height = height {
    _input = TextInputModel(prompt: '🔍 ', placeholder: placeholder);
    _paginator = PaginatorModel(
      type: PaginationType.dots,
      activeDot: '●',
      inactiveDot: '○',
    );
    _runFilter();
    _cursor = initialIndex.clamp(
      0,
      _filteredItems.isEmpty ? 0 : _filteredItems.length - 1,
    );
    _updatePagination();
  }

  /// The title displayed above the search.
  final String title;

  /// Placeholder text for the search input.
  final String placeholder;

  /// Text shown when no results match.
  final String noResultsText;

  /// Whether to show the title.
  final bool showTitle;

  /// Whether to show help text.
  final bool showHelp;

  /// Whether to show pagination.
  final bool showPagination;

  /// Whether to highlight matched characters.
  final bool highlightMatches;

  /// Key bindings.
  final SearchKeyMap keyMap;

  /// Styles.
  final SearchStyles styles;

  /// Custom display function for items.
  final String Function(T)? display;

  // Internal state
  final List<T> _items;
  final SearchFilterFunc<T> _filter;
  late TextInputModel _input;
  late PaginatorModel _paginator;
  List<FilteredSearchItem<T>> _filteredItems = [];
  int _cursor = 0;
  final int _height;

  /// Gets the items.
  List<T> get items => List.unmodifiable(_items);

  /// Gets the current search query.
  String get query => _input.value;

  /// Gets the filtered items.
  List<FilteredSearchItem<T>> get filteredItems =>
      List.unmodifiable(_filteredItems);

  /// Gets the current cursor position.
  int get cursor => _cursor;

  /// Gets the currently highlighted item.
  FilteredSearchItem<T>? get selectedItem {
    if (_filteredItems.isEmpty || _cursor >= _filteredItems.length) return null;
    return _filteredItems[_cursor];
  }

  /// Gets the visible height for items.
  int get _visibleHeight {
    var h = _height;
    if (showTitle && title.isNotEmpty) h -= 1;
    h -= 1; // Search input
    if (showHelp) h -= 1;
    if (showPagination && _paginator.totalPages > 1) h -= 1;
    return h.clamp(1, _filteredItems.isEmpty ? 1 : _filteredItems.length);
  }

  /// Gets display text for an item.
  String _displayItem(T item) {
    return display?.call(item) ?? item.toString();
  }

  /// Renders item text with match highlighting.
  String _renderItemWithHighlights(FilteredSearchItem<T> filteredItem) {
    if (!highlightMatches || filteredItem.matches.isEmpty) {
      return _displayItem(filteredItem.item);
    }

    final text = _displayItem(filteredItem.item);
    final buffer = StringBuffer();
    final matchSet = filteredItem.matches.toSet();

    for (var i = 0; i < text.length; i++) {
      if (matchSet.contains(i)) {
        buffer.write(styles.matchHighlight.render(text[i]));
      } else {
        buffer.write(text[i]);
      }
    }

    return buffer.toString();
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
    if (_cursor < _filteredItems.length - 1) {
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
    _cursor = _filteredItems.isEmpty ? 0 : _filteredItems.length - 1;
    _updatePagination();
  }

  /// Page up.
  void _pageUp() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor - pageSize).clamp(0, _filteredItems.length - 1);
    _updatePagination();
  }

  /// Page down.
  void _pageDown() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor + pageSize).clamp(0, _filteredItems.length - 1);
    _updatePagination();
  }

  void _runFilter() {
    _filteredItems = _filter(_input.value, _items, _displayItem);
    // Reset cursor if it's out of bounds
    if (_cursor >= _filteredItems.length) {
      _cursor = _filteredItems.isEmpty ? 0 : _filteredItems.length - 1;
    }
  }

  void _updatePagination() {
    if (_filteredItems.isEmpty) {
      _paginator = PaginatorModel(
        page: 0,
        perPage: _visibleHeight,
        totalPages: 1,
        type: PaginationType.dots,
      );
      return;
    }
    final pageSize = _visibleHeight;
    final page = _cursor ~/ pageSize;
    final totalPages = (_filteredItems.length / pageSize).ceil();
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
  Cmd? init() => _input.focus();

  @override
  (SearchModel<T>, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      final key = msg.key;

      // Check for Ctrl+C
      if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63) {
        return (this, Cmd.message(const SearchCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.cancel])) {
        return (this, Cmd.message(const SearchCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.select])) {
        if (_filteredItems.isNotEmpty) {
          final selected = _filteredItems[_cursor];
          return (
            this,
            Cmd.message(
              SearchSelectionMadeMsg<T>(selected.item, selected.index),
            ),
          );
        }
        return (this, null);
      }

      if (keyMatches(key, [keyMap.up])) {
        _cursorUp();
        return (this, null);
      } else if (keyMatches(key, [keyMap.down])) {
        _cursorDown();
        return (this, null);
      } else if (keyMatches(key, [keyMap.home])) {
        _goToStart();
        return (this, null);
      } else if (keyMatches(key, [keyMap.end])) {
        _goToEnd();
        return (this, null);
      } else if (keyMatches(key, [keyMap.pageUp])) {
        _pageUp();
        return (this, null);
      } else if (keyMatches(key, [keyMap.pageDown])) {
        _pageDown();
        return (this, null);
      }
    }

    // Forward other messages to input
    final oldValue = _input.value;
    final (newInput, inputCmd) = _input.update(msg);
    _input = newInput;
    if (inputCmd != null) cmds.add(inputCmd);

    // Re-run filter if query changed
    if (_input.value != oldValue) {
      _runFilter();
      _cursor = 0;
      _updatePagination();
    }

    return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
  }

  @override
  String view() {
    final buffer = StringBuffer();

    // Title
    if (showTitle && title.isNotEmpty) {
      buffer.writeln(styles.title.render(title));
    }

    // Search input
    final inputView = _input.view();
    final inputContent = inputView is View
        ? inputView.content
        : inputView.toString();
    buffer.writeln(inputContent.trimRight());

    // Results
    if (_filteredItems.isEmpty) {
      buffer.writeln(styles.noResults.render('  $noResultsText'));
    } else {
      // Calculate visible range
      final pageSize = _visibleHeight;
      final startIndex = (_cursor ~/ pageSize) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, _filteredItems.length);

      // Render items
      for (var i = startIndex; i < endIndex; i++) {
        final filteredItem = _filteredItems[i];
        final isSelected = i == _cursor;
        final displayText = _renderItemWithHighlights(filteredItem);

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

/// A multi-select search/filter component.
class MultiSearchModel<T> extends ViewComponent {
  MultiSearchModel({
    required List<T> items,
    this.title = '',
    this.hint = '(Space to toggle, ^a to toggle all, Enter to confirm)',
    this.placeholder = 'Type to search...',
    this.noResultsText = 'No matches found',
    this.showTitle = true,
    this.showHint = true,
    this.showHelp = true,
    this.showPagination = true,
    this.highlightMatches = true,
    int height = 10,
    int initialIndex = 0,
    Set<int>? initialSelected,
    this.display,
    SearchFilterFunc<T>? filter,
    MultiSearchKeyMap? keyMap,
    SearchStyles? styles,
  }) : _items = items,
       _selected = initialSelected ?? {},
       _filter = filter ?? defaultSearchFilter,
       keyMap = keyMap ?? MultiSearchKeyMap(),
       styles = styles ?? SearchStyles.defaults(),
       _height = height {
    _input = TextInputModel(prompt: '🔍 ', placeholder: placeholder);
    _paginator = PaginatorModel(
      type: PaginationType.dots,
      activeDot: '●',
      inactiveDot: '○',
    );
    _runFilter();
    _cursor = initialIndex.clamp(
      0,
      _filteredItems.isEmpty ? 0 : _filteredItems.length - 1,
    );
    _updatePagination();
  }

  final String title;
  final String hint;
  final String placeholder;
  final String noResultsText;
  final bool showTitle;
  final bool showHint;
  final bool showHelp;
  final bool showPagination;
  final bool highlightMatches;
  final MultiSearchKeyMap keyMap;
  final SearchStyles styles;
  final String Function(T)? display;

  final List<T> _items;
  final SearchFilterFunc<T> _filter;
  late TextInputModel _input;
  late PaginatorModel _paginator;
  List<FilteredSearchItem<T>> _filteredItems = [];
  final Set<int> _selected;
  int _cursor = 0;
  final int _height;

  List<T> get items => List.unmodifiable(_items);
  String get query => _input.value;
  List<FilteredSearchItem<T>> get filteredItems =>
      List.unmodifiable(_filteredItems);
  int get cursor => _cursor;

  List<T> get selectedItems {
    final indices = _selected.toList()..sort();
    return indices.map((i) => _items[i]).toList();
  }

  int get _visibleHeight {
    var h = _height;
    if (showTitle && title.isNotEmpty) h -= 1;
    if (showHint && hint.isNotEmpty) h -= 1;
    h -= 1; // Search input
    if (showHelp) h -= 1;
    if (showPagination && _paginator.totalPages > 1) h -= 1;
    return h.clamp(1, _filteredItems.isEmpty ? 1 : _filteredItems.length);
  }

  String _displayItem(T item) {
    return display?.call(item) ?? item.toString();
  }

  String _renderItemWithHighlights(FilteredSearchItem<T> filteredItem) {
    if (!highlightMatches || filteredItem.matches.isEmpty) {
      return _displayItem(filteredItem.item);
    }

    final text = _displayItem(filteredItem.item);
    final buffer = StringBuffer();
    final matchSet = filteredItem.matches.toSet();

    for (var i = 0; i < text.length; i++) {
      if (matchSet.contains(i)) {
        buffer.write(styles.matchHighlight.render(text[i]));
      } else {
        buffer.write(text[i]);
      }
    }

    return buffer.toString();
  }

  void _cursorUp() {
    if (_cursor > 0) {
      _cursor--;
      _updatePagination();
    }
  }

  void _cursorDown() {
    if (_cursor < _filteredItems.length - 1) {
      _cursor++;
      _updatePagination();
    }
  }

  void _goToStart() {
    _cursor = 0;
    _updatePagination();
  }

  void _goToEnd() {
    _cursor = _filteredItems.isEmpty ? 0 : _filteredItems.length - 1;
    _updatePagination();
  }

  void _pageUp() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor - pageSize).clamp(0, _filteredItems.length - 1);
    _updatePagination();
  }

  void _pageDown() {
    final pageSize = _visibleHeight;
    _cursor = (_cursor + pageSize).clamp(0, _filteredItems.length - 1);
    _updatePagination();
  }

  void _toggleSelection() {
    if (_filteredItems.isEmpty) return;
    final item = _filteredItems[_cursor];
    if (_selected.contains(item.index)) {
      _selected.remove(item.index);
    } else {
      _selected.add(item.index);
    }
  }

  void _toggleAll() {
    if (_filteredItems.isEmpty) return;
    final allVisibleSelected = _filteredItems.every(
      (item) => _selected.contains(item.index),
    );

    if (allVisibleSelected) {
      for (final item in _filteredItems) {
        _selected.remove(item.index);
      }
    } else {
      for (final item in _filteredItems) {
        _selected.add(item.index);
      }
    }
  }

  void _runFilter() {
    _filteredItems = _filter(_input.value, _items, _displayItem);
    if (_cursor >= _filteredItems.length) {
      _cursor = _filteredItems.isEmpty ? 0 : _filteredItems.length - 1;
    }
  }

  void _updatePagination() {
    if (_filteredItems.isEmpty) {
      _paginator = PaginatorModel(
        page: 0,
        perPage: _visibleHeight,
        totalPages: 1,
        type: PaginationType.dots,
      );
      return;
    }
    final pageSize = _visibleHeight;
    final page = _cursor ~/ pageSize;
    final totalPages = (_filteredItems.length / pageSize).ceil();
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
  Cmd? init() => _input.focus();

  @override
  (MultiSearchModel<T>, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      final key = msg.key;

      if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63) {
        return (this, Cmd.message(const SearchCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.cancel])) {
        return (this, Cmd.message(const SearchCancelledMsg()));
      }

      if (keyMatches(key, [keyMap.confirm])) {
        final sortedIndices = _selected.toList()..sort();
        final selectedItems = sortedIndices.map((i) => _items[i]).toList();
        return (
          this,
          Cmd.message(
            MultiSearchSelectionMadeMsg<T>(selectedItems, sortedIndices),
          ),
        );
      }

      if (keyMatches(key, [keyMap.toggle])) {
        _toggleSelection();
        return (this, null);
      } else if (keyMatches(key, [keyMap.toggleAll])) {
        _toggleAll();
        return (this, null);
      } else if (keyMatches(key, [keyMap.up])) {
        _cursorUp();
        return (this, null);
      } else if (keyMatches(key, [keyMap.down])) {
        _cursorDown();
        return (this, null);
      } else if (keyMatches(key, [keyMap.home])) {
        _goToStart();
        return (this, null);
      } else if (keyMatches(key, [keyMap.end])) {
        _goToEnd();
        return (this, null);
      } else if (keyMatches(key, [keyMap.pageUp])) {
        _pageUp();
        return (this, null);
      } else if (keyMatches(key, [keyMap.pageDown])) {
        _pageDown();
        return (this, null);
      }
    }

    final oldValue = _input.value;
    final (newInput, inputCmd) = _input.update(msg);
    _input = newInput;
    if (inputCmd != null) cmds.add(inputCmd);

    if (_input.value != oldValue) {
      _runFilter();
      _cursor = 0;
      _updatePagination();
    }

    return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
  }

  @override
  String view() {
    final buffer = StringBuffer();

    if (showTitle && title.isNotEmpty) {
      buffer.writeln(styles.title.render(title));
    }

    if (showHint && hint.isNotEmpty) {
      buffer.writeln(styles.dimmed.render('  $hint'));
    }

    final inputView = _input.view();
    final inputContent = inputView is View
        ? inputView.content
        : inputView.toString();
    buffer.writeln(inputContent.trimRight());

    if (_filteredItems.isEmpty) {
      buffer.writeln(styles.noResults.render('  $noResultsText'));
    } else {
      final pageSize = _visibleHeight;
      final startIndex = (_cursor ~/ pageSize) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, _filteredItems.length);

      for (var i = startIndex; i < endIndex; i++) {
        final filteredItem = _filteredItems[i];
        final isHighlighted = i == _cursor;
        final isSelected = _selected.contains(filteredItem.index);
        final displayText = _renderItemWithHighlights(filteredItem);

        final icon = isSelected
            ? styles.selectedIcon.render(styles.selectedIconChar)
            : styles.unselectedIcon.render(styles.unselectedIconChar);

        final prefix = isHighlighted ? styles.cursorPrefix.trimRight() : ' ';
        final itemStyle = isHighlighted ? styles.selectedItem : styles.item;

        buffer.writeln('  $prefix $icon ${itemStyle.render(displayText)}');
      }
    }

    if (showPagination && _paginator.totalPages > 1) {
      buffer.writeln(styles.dimmed.render(_paginator.view()));
    }

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
