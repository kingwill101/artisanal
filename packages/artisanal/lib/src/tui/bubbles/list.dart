/// List component for TUI applications.
///
/// This provides an interactive list with selection, filtering,
/// pagination, and keyboard navigation.
///
/// Based on the Bubble Tea list component.
library;

import 'dart:math' as math;

import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';

import '../tui.dart';
import 'key_binding.dart';
import 'paginator.dart';
import 'spinner.dart';
import 'textinput.dart';
import 'help.dart';

/// Item interface for list items.
abstract class ListItem {
  /// Value used for filtering.
  String filterValue();
}

/// Simple string item implementation.
class StringItem implements ListItem {
  /// Creates a string item.
  StringItem(this.value);

  /// The string value.
  final String value;

  @override
  String filterValue() => value;

  @override
  String toString() => value;
}

/// Item delegate for rendering list items.
abstract class ItemDelegate {
  /// Render the item at the given index.
  String render(ListModel model, int index, ListItem item);

  /// Height of each list item in lines.
  int get height;

  /// Spacing between items in lines.
  int get spacing;

  /// Handle update messages for items.
  Cmd? update(Msg msg, ListModel model);
}

/// Default item delegate with simple rendering.
class DefaultItemDelegate implements ItemDelegate {
  /// Creates a default item delegate.
  DefaultItemDelegate({
    Style? normalStyle,
    Style? selectedStyle,
    Style? matchedStyle,
  }) : normalStyle = normalStyle ?? Style(),
       selectedStyle =
           selectedStyle ?? Style().bold().foreground(AnsiColor(212)),
       matchedStyle = matchedStyle ?? Style().underline();

  /// Style for normal items.
  final Style normalStyle;

  /// Style for selected item.
  final Style selectedStyle;

  /// Style for matched characters in filtered items.
  final Style matchedStyle;

  @override
  int get height => 1;

  @override
  int get spacing => 0;

  @override
  String render(ListModel model, int index, ListItem item) {
    final selected = model.index == index;
    final value = item.filterValue();
    final matches = model.matchesForItem(index);

    String styledValue;
    if (matches != null && matches.isNotEmpty) {
      // Highlight matched characters
      final buffer = StringBuffer();
      for (var i = 0; i < value.length; i++) {
        if (matches.contains(i)) {
          buffer.write(matchedStyle.render(value[i]));
        } else {
          buffer.write(value[i]);
        }
      }
      styledValue = buffer.toString();
    } else {
      styledValue = value;
    }

    if (selected) {
      return selectedStyle.render('> $styledValue');
    }
    return normalStyle.render('  $styledValue');
  }

  @override
  Cmd? update(Msg msg, ListModel model) => null;
}

/// Filter state for the list.
enum FilterState {
  /// No filter applied.
  unfiltered,

  /// User is actively typing a filter.
  filtering,

  /// A filter has been applied.
  filterApplied,
}

/// Filtered item with match information.
class FilteredItem {
  /// Creates a filtered item.
  FilteredItem({
    required this.index,
    required this.item,
    this.matches = const [],
  });

  /// Index in the original unfiltered list.
  final int index;

  /// The matched item.
  final ListItem item;

  /// Rune indices of matched characters.
  final List<int> matches;
}

/// Rank from filtering.
class Rank {
  /// Creates a rank.
  Rank({required this.index, this.matchedIndexes = const []});

  /// Index in the original list.
  final int index;

  /// Indices of matched characters.
  final List<int> matchedIndexes;
}

/// Filter function type.
typedef FilterFunc = List<Rank> Function(String term, List<String> targets);

/// Default fuzzy filter implementation.
List<Rank> defaultFilter(String term, List<String> targets) {
  if (term.isEmpty) {
    return List.generate(targets.length, (i) => Rank(index: i));
  }

  final results = <Rank>[];
  final termLower = term.toLowerCase();

  for (var i = 0; i < targets.length; i++) {
    final target = targets[i].toLowerCase();
    final matches = <int>[];
    var termIdx = 0;

    for (var j = 0; j < target.length && termIdx < termLower.length; j++) {
      if (target[j] == termLower[termIdx]) {
        matches.add(j);
        termIdx++;
      }
    }

    if (termIdx == termLower.length) {
      results.add(Rank(index: i, matchedIndexes: matches));
    }
  }

  // Sort by number of matches and position
  results.sort((a, b) {
    final aScore = _scoreRank(a, targets[a.index]);
    final bScore = _scoreRank(b, targets[b.index]);
    return aScore.compareTo(bScore);
  });

  return results;
}

int _scoreRank(Rank rank, String target) {
  if (rank.matchedIndexes.isEmpty) return target.length;
  // Lower score is better - prefer matches at the start
  var score = 0;
  for (final idx in rank.matchedIndexes) {
    score += idx;
  }
  return score;
}

/// Key map for list navigation.
class ListKeyMap implements KeyMap {
  /// Creates a list key map with default bindings.
  ListKeyMap({
    KeyBinding? cursorUp,
    KeyBinding? cursorDown,
    KeyBinding? nextPage,
    KeyBinding? prevPage,
    KeyBinding? goToStart,
    KeyBinding? goToEnd,
    KeyBinding? filter,
    KeyBinding? clearFilter,
    KeyBinding? acceptWhileFiltering,
    KeyBinding? cancelWhileFiltering,
    KeyBinding? quit,
    KeyBinding? forceQuit,
    KeyBinding? showFullHelp,
    KeyBinding? closeFullHelp,
  }) : cursorUp =
           cursorUp ??
           KeyBinding(
             keys: ['up', 'k'],
             help: Help(key: '↑/k', desc: 'up'),
           ),
       cursorDown =
           cursorDown ??
           KeyBinding(
             keys: ['down', 'j'],
             help: Help(key: '↓/j', desc: 'down'),
           ),
       nextPage =
           nextPage ??
           KeyBinding(
             keys: ['right', 'l', 'pgdown'],
             help: Help(key: '→/l', desc: 'next page'),
           ),
       prevPage =
           prevPage ??
           KeyBinding(
             keys: ['left', 'h', 'pgup'],
             help: Help(key: '←/h', desc: 'prev page'),
           ),
       goToStart =
           goToStart ??
           KeyBinding(
             keys: ['home', 'g'],
             help: Help(key: 'g', desc: 'go to start'),
           ),
       goToEnd =
           goToEnd ??
           KeyBinding(
             keys: ['end', 'G'],
             help: Help(key: 'G', desc: 'go to end'),
           ),
       filter =
           filter ??
           KeyBinding(
             keys: ['/'],
             help: Help(key: '/', desc: 'filter'),
           ),
       clearFilter =
           clearFilter ??
           KeyBinding(
             keys: ['esc'],
             help: Help(key: 'esc', desc: 'clear filter'),
           ),
       acceptWhileFiltering =
           acceptWhileFiltering ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: 'enter', desc: 'apply filter'),
           ),
       cancelWhileFiltering =
           cancelWhileFiltering ??
           KeyBinding(
             keys: ['esc'],
             help: Help(key: 'esc', desc: 'cancel'),
           ),
       quit =
           quit ??
           KeyBinding(
             keys: ['q'],
             help: Help(key: 'q', desc: 'quit'),
           ),
       forceQuit = forceQuit ?? KeyBinding(keys: ['ctrl+c']),
       showFullHelp =
           showFullHelp ??
           KeyBinding(
             keys: ['?'],
             help: Help(key: '?', desc: 'more'),
           ),
       closeFullHelp =
           closeFullHelp ??
           KeyBinding(
             keys: ['?'],
             help: Help(key: '?', desc: 'less'),
           );

  /// Move cursor up.
  final KeyBinding cursorUp;

  /// Move cursor down.
  final KeyBinding cursorDown;

  /// Go to next page.
  final KeyBinding nextPage;

  /// Go to previous page.
  final KeyBinding prevPage;

  /// Go to start.
  final KeyBinding goToStart;

  /// Go to end.
  final KeyBinding goToEnd;

  /// Start filtering.
  final KeyBinding filter;

  /// Clear current filter.
  final KeyBinding clearFilter;

  /// Accept filter while filtering.
  final KeyBinding acceptWhileFiltering;

  /// Cancel filtering.
  final KeyBinding cancelWhileFiltering;

  /// Quit the list.
  final KeyBinding quit;

  /// Force quit the list.
  final KeyBinding forceQuit;

  /// Show full help.
  final KeyBinding showFullHelp;

  /// Close full help.
  final KeyBinding closeFullHelp;

  @override
  List<KeyBinding> shortHelp() => [cursorUp, cursorDown, filter, quit];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [cursorUp, cursorDown],
    [nextPage, prevPage],
    [goToStart, goToEnd],
    [filter, clearFilter],
    [quit, forceQuit],
  ];
}

/// Styles for list rendering.
class ListStyles {
  /// Creates list styles.
  ListStyles({
    Style? title,
    Style? titleBar,
    Style? filterPrompt,
    Style? filterCursor,
    Style? statusBar,
    Style? statusEmpty,
    Style? statusBarActiveFilter,
    Style? statusBarFilterCount,
    Style? noItems,
    Style? paginationStyle,
    Style? helpStyle,
    this.activePaginationDot,
    this.inactivePaginationDot,
    Style? arabicPagination,
    Style? spinner,
    Style? dividerDot,
  }) : title = title ?? Style(),
       titleBar = titleBar ?? Style(),
       filterPrompt = filterPrompt ?? Style(),
       filterCursor = filterCursor ?? Style(),
       statusBar = statusBar ?? Style(),
       statusEmpty = statusEmpty ?? Style(),
       statusBarActiveFilter = statusBarActiveFilter ?? Style(),
       statusBarFilterCount = statusBarFilterCount ?? Style(),
       noItems = noItems ?? Style(),
       paginationStyle = paginationStyle ?? Style(),
       helpStyle = helpStyle ?? Style(),
       arabicPagination = arabicPagination ?? Style(),
       spinner = spinner ?? Style(),
       dividerDot = dividerDot ?? Style();

  /// Title style.
  final Style title;

  /// Title bar style.
  final Style titleBar;

  /// Filter prompt style.
  final Style filterPrompt;

  /// Filter cursor style.
  final Style filterCursor;

  /// Status bar style.
  final Style statusBar;

  /// Empty status style.
  final Style statusEmpty;

  /// Active filter status style.
  final Style statusBarActiveFilter;

  /// Filter count status style.
  final Style statusBarFilterCount;

  /// No items message style.
  final Style noItems;

  /// Pagination style.
  final Style paginationStyle;

  /// Help style.
  final Style helpStyle;

  /// Active pagination dot.
  final String? activePaginationDot;

  /// Inactive pagination dot.
  final String? inactivePaginationDot;

  /// Arabic pagination style.
  final Style arabicPagination;

  /// Spinner style.
  final Style spinner;

  /// Divider dot style.
  final Style dividerDot;

  /// Creates default styles.
  factory ListStyles.defaults() => ListStyles(
    title: Style().bold(),
    titleBar: Style().background(AnsiColor(62)), // Purple background
    filterPrompt: Style().foreground(AnsiColor(241)), // Gray
    filterCursor: Style().foreground(AnsiColor(62)), // Purple
    statusBar: Style().foreground(AnsiColor(241)), // Gray
    statusEmpty: Style().foreground(AnsiColor(240)), // Dark gray
    statusBarActiveFilter: Style().foreground(AnsiColor(62)), // Purple
    statusBarFilterCount: Style().foreground(AnsiColor(240)), // Dark gray
    noItems: Style().foreground(AnsiColor(240)), // Dark gray
    paginationStyle: Style().foreground(AnsiColor(241)),
    helpStyle: Style().foreground(AnsiColor(241)),
    activePaginationDot: Style().foreground(AnsiColor(62)).render('●'),
    inactivePaginationDot: Style().foreground(AnsiColor(241)).render('○'),
    dividerDot: Style().foreground(AnsiColor(240)).padding(0, 1),
  );
}

/// Filter matches message.
class FilterMatchesMsg implements Msg {
  /// Creates a filter matches message.
  FilterMatchesMsg(this.matches);

  /// The filtered items.
  final List<FilteredItem> matches;
}

/// Status message timeout message.
class StatusMessageTimeoutMsg implements Msg {}

/// List model for interactive lists.
///
/// Features:
/// - Item selection with keyboard navigation
/// - Optional fuzzy filtering
/// - Pagination
/// - Loading spinner
/// - Status messages
/// - Help view
///
/// Example:
/// ```dart
/// final list = ListModel(
///   items: ['Apple', 'Banana', 'Cherry'].map(StringItem.new).toList(),
///   title: 'Fruits',
/// );
/// ```
class ListModel extends ViewComponent {
  /// Creates a new list model.
  ListModel({
    List<ListItem>? items,
    ItemDelegate? delegate,
    int width = 80,
    int height = 20,
    this.title = 'List',
    this.showTitle = true,
    this.showFilter = true,
    this.showStatusBar = true,
    this.showPagination = true,
    this.showHelp = true,
    this.filteringEnabled = true,
    this.infiniteScrolling = false,
    this.itemNameSingular = 'item',
    this.itemNamePlural = 'items',
    ListKeyMap? keyMap,
    ListStyles? styles,
    FilterFunc? filter,
    Duration? statusMessageLifetime,
  }) : _items = items ?? [],
       _delegate = delegate ?? DefaultItemDelegate(),
       keyMap = keyMap ?? ListKeyMap(),
       styles = styles ?? ListStyles.defaults(),
       _filter = filter ?? defaultFilter,
       statusMessageLifetime =
           statusMessageLifetime ?? const Duration(seconds: 1),
       _width = width,
       _height = height {
    paginator = PaginatorModel(
      type: PaginationType.dots,
      activeDot: this.styles.activePaginationDot ?? '●',
      inactiveDot: this.styles.inactivePaginationDot ?? '○',
    );
    filterInput = TextInputModel(prompt: 'Filter: ', charLimit: 64);
    spinner = SpinnerModel(spinner: Spinners.line);
    help = HelpModel();
    _updatePagination();
  }

  /// List title.
  String title;

  /// Whether to show the title.
  bool showTitle;

  /// Whether to show the filter input.
  bool showFilter;

  /// Whether to show the status bar.
  bool showStatusBar;

  /// Whether to show pagination.
  bool showPagination;

  /// Whether to show help.
  bool showHelp;

  /// Whether filtering is enabled.
  bool filteringEnabled;

  /// Whether to enable infinite scrolling.
  bool infiniteScrolling;

  /// Singular item name for status.
  String itemNameSingular;

  /// Plural item name for status.
  String itemNamePlural;

  /// Key bindings.
  ListKeyMap keyMap;

  /// List styles.
  ListStyles styles;

  /// Status message lifetime.
  Duration statusMessageLifetime;

  // Internal state
  List<ListItem> _items;
  final ItemDelegate _delegate;
  final FilterFunc _filter;
  late PaginatorModel paginator;
  late TextInputModel filterInput;
  late SpinnerModel spinner;
  late HelpModel help;
  int _cursor = 0;
  int _width;
  int _height;
  FilterState _filterState = FilterState.unfiltered;
  List<FilteredItem> _filteredItems = [];
  String _statusMessage = '';
  bool _showSpinner = false;
  bool _disableQuitKeybindings = false;

  /// Gets the items.
  List<ListItem> get items => _items;

  /// Sets the items.
  set items(List<ListItem> value) {
    _items = value;
    if (_filterState != FilterState.unfiltered) {
      _filteredItems = [];
      _runFilter();
    }
    _updatePagination();
    updateKeybindings();
  }

  /// Sets the items (parity with bubbles).
  void setItems(List<ListItem> items) {
    this.items = items;
  }

  /// Inserts an item at the given index.
  void insertItem(int index, ListItem item) {
    _items.insert(index, item);
    _updatePagination();
    updateKeybindings();
  }

  /// Removes an item at the given index.
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      if (_filterState != FilterState.unfiltered) {
        _filteredItems.removeWhere((f) => f.index == index);
        // Update indices of remaining filtered items
        for (var i = 0; i < _filteredItems.length; i++) {
          if (_filteredItems[i].index > index) {
            _filteredItems[i] = FilteredItem(
              index: _filteredItems[i].index - 1,
              item: _filteredItems[i].item,
              matches: _filteredItems[i].matches,
            );
          }
        }
        if (_filteredItems.isEmpty) {
          _resetFiltering();
        }
      }
      _updatePagination();
      updateKeybindings();
    }
  }

  /// Sets an item at the given index.
  void setItem(int index, ListItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      if (_filterState != FilterState.unfiltered) {
        _runFilter();
      }
      _updatePagination();
    }
  }

  /// Sets whether filtering is enabled.
  void setFilteringEnabled(bool enabled) {
    filteringEnabled = enabled;
    updateKeybindings();
  }

  /// Sets whether to show the title.
  void setShowTitle(bool show) {
    showTitle = show;
  }

  /// Sets whether to show the status bar.
  void setShowStatusBar(bool show) {
    showStatusBar = show;
  }

  /// Sets whether to show pagination.
  void setShowPagination(bool show) {
    showPagination = show;
  }

  /// Sets whether to show help.
  void setShowHelp(bool show) {
    showHelp = show;
  }

  /// Sets whether to show the filter.
  void setShowFilter(bool show) {
    showFilter = show;
  }

  /// Gets the width.
  int get width => _width;

  /// Gets the height.
  int get height => _height;

  /// Sets the width.
  void setWidth(int width) {
    setSize(width, _height);
  }

  /// Sets the height.
  void setHeight(int height) {
    setSize(_width, height);
  }

  /// Sets the size.
  void setSize(int width, int height) {
    _width = width;
    _height = height;
    help = help.copyWith(width: width);
    // Update filter input width
    final promptWidth = styles.title.render(filterInput.prompt).length;
    filterInput.width = width - promptWidth;
    _updatePagination();
    updateKeybindings();
  }

  /// Whether the spinner is currently showing.
  bool get isShowingSpinner => _showSpinner;

  /// Gets the current status message.
  String get statusMessage => _statusMessage;

  /// Sets the spinner animation.
  void setSpinner(Spinner s) {
    spinner = spinner.copyWith(spinner: s);
  }

  /// Starts the spinner.
  Cmd? startSpinner() {
    _showSpinner = true;
    return spinner.tick();
  }

  /// Stops the spinner.
  void stopSpinner() {
    _showSpinner = false;
  }

  /// Toggles the spinner.
  Cmd? toggleSpinner() {
    if (_showSpinner) {
      stopSpinner();
      return null;
    }
    return startSpinner();
  }

  /// Gets visible items (filtered or all).
  List<ListItem> get visibleItems {
    if (_filterState != FilterState.unfiltered) {
      return _filteredItems.map((f) => f.item).toList();
    }
    return _items;
  }

  /// Gets the current index in the visible items.
  int get index => paginator.page * paginator.perPage + _cursor;

  /// Gets the global index in the unfiltered items.
  int get globalIndex {
    final idx = index;
    if (_filteredItems.isEmpty || idx >= _filteredItems.length) {
      return idx;
    }
    return _filteredItems[idx].index;
  }

  /// Gets the cursor position on the current page.
  int get cursor => _cursor;

  /// Gets the selected item, or null if none.
  ListItem? get selectedItem {
    final items = visibleItems;
    final idx = index;
    if (idx < 0 || items.isEmpty || idx >= items.length) {
      return null;
    }
    return items[idx];
  }

  /// Gets match indices for an item (for highlighting).
  List<int>? matchesForItem(int index) {
    if (_filteredItems.isEmpty || index >= _filteredItems.length) {
      return null;
    }
    return _filteredItems[index].matches;
  }

  /// Gets the current filter state.
  FilterState get filterState => _filterState;

  /// Gets the current filter value.
  String get filterValue => filterInput.value;

  /// Whether currently setting a filter.
  bool get settingFilter => _filterState == FilterState.filtering;

  /// Whether a filter is applied.
  bool get isFiltered => _filterState == FilterState.filterApplied;

  /// Move cursor up.
  void cursorUp() {
    _cursor--;
    if (_cursor < 0 && paginator.onFirstPage) {
      if (infiniteScrolling) {
        goToEnd();
        return;
      }
      _cursor = 0;
      return;
    }
    if (_cursor >= 0) return;
    paginator.prevPage();
    _cursor = _maxCursorIndex();
  }

  /// Move cursor down.
  void cursorDown() {
    final maxIdx = _maxCursorIndex();
    _cursor++;
    if (_cursor <= maxIdx) return;
    if (!paginator.onLastPage) {
      paginator.nextPage();
      _cursor = 0;
      return;
    }
    _cursor = math.max(0, maxIdx);
    if (infiniteScrolling) {
      goToStart();
    }
  }

  /// Go to start.
  void goToStart() {
    paginator = paginator.copyWith(page: 0);
    _cursor = 0;
  }

  /// Go to end.
  void goToEnd() {
    paginator = paginator.copyWith(page: math.max(0, paginator.totalPages - 1));
    _cursor = _maxCursorIndex();
  }

  /// Go to previous page.
  void prevPage() {
    paginator = paginator.prevPage();
    _cursor = _cursor.clamp(0, _maxCursorIndex());
  }

  /// Go to next page.
  void nextPage() {
    paginator = paginator.nextPage();
    _cursor = _cursor.clamp(0, _maxCursorIndex());
  }

  /// Select item at index.
  void select(int index) {
    paginator = paginator.copyWith(page: index ~/ paginator.perPage);
    _cursor = index % paginator.perPage;
  }

  /// Reset selection to start.
  void resetSelected() {
    select(0);
  }

  /// Reset the filter.
  void resetFilter() {
    _resetFiltering();
  }

  /// Disable quit keybindings.
  void disableQuitKeybindings() {
    _disableQuitKeybindings = true;
    keyMap.quit.disable();
    keyMap.forceQuit.disable();
  }

  /// Enables quit keybindings.
  void enableQuitKeybindings() {
    _disableQuitKeybindings = false;
    keyMap.quit.enable();
    keyMap.forceQuit.enable();
  }

  /// Set a status message.
  Cmd? newStatusMessage(String message) {
    _statusMessage = message;
    return Cmd.delayed(statusMessageLifetime, () => StatusMessageTimeoutMsg());
  }

  /// Hide the status message.
  void hideStatusMessage() {
    _statusMessage = '';
  }

  /// Update keybindings based on state.
  void updateKeybindings() {
    switch (_filterState) {
      case FilterState.filtering:
        keyMap.cursorUp.disable();
        keyMap.cursorDown.disable();
        keyMap.nextPage.disable();
        keyMap.prevPage.disable();
        keyMap.goToStart.disable();
        keyMap.goToEnd.disable();
        keyMap.filter.disable();
        keyMap.clearFilter.disable();
        keyMap.cancelWhileFiltering.enable();
        keyMap.acceptWhileFiltering.enabled = filterInput.value.isNotEmpty;
        keyMap.quit.disable();
        keyMap.showFullHelp.disable();
        keyMap.closeFullHelp.disable();
        break;

      default:
        final hasItems = _items.isNotEmpty;
        keyMap.cursorUp.enabled = hasItems;
        keyMap.cursorDown.enabled = hasItems;

        final hasPages = paginator.totalPages > 1;
        keyMap.nextPage.enabled = hasPages;
        keyMap.prevPage.enabled = hasPages;

        keyMap.goToStart.enabled = hasItems;
        keyMap.goToEnd.enabled = hasItems;

        keyMap.filter.enabled = filteringEnabled && hasItems;
        keyMap.clearFilter.enabled = _filterState == FilterState.filterApplied;
        keyMap.cancelWhileFiltering.disable();
        keyMap.acceptWhileFiltering.disable();
        keyMap.quit.enabled = !_disableQuitKeybindings;
        keyMap.showFullHelp.enable();
        keyMap.closeFullHelp.enable();
        break;
    }
  }

  int _maxCursorIndex() {
    return math.max(0, paginator.itemsOnPage(visibleItems.length) - 1);
  }

  void _resetFiltering() {
    if (_filterState == FilterState.unfiltered) return;
    _filterState = FilterState.unfiltered;
    filterInput.reset();
    _filteredItems = [];
    _updatePagination();
    updateKeybindings();
  }

  void _runFilter() {
    final targets = _items.map((i) => i.filterValue()).toList();
    final ranks = _filter(filterInput.value, targets);
    _filteredItems = ranks
        .map(
          (r) => FilteredItem(
            index: r.index,
            item: _items[r.index],
            matches: r.matchedIndexes,
          ),
        )
        .toList();
  }

  void _updatePagination() {
    final idx = index;
    var availHeight = _height;

    if (showTitle || (showFilter && filteringEnabled)) {
      availHeight -= 1; // Title line
    }
    if (showStatusBar) {
      availHeight -= 1; // Status line
    }
    if (showPagination) {
      availHeight -= 1; // Pagination line
    }
    if (showHelp) {
      availHeight -= 1; // Help line
    }

    paginator = paginator.copyWith(
      perPage: math.max(
        1,
        availHeight ~/ (_delegate.height + _delegate.spacing),
      ),
    );

    final pages = visibleItems.length;
    if (pages < 1) {
      paginator = paginator.setTotalPages(1);
    } else {
      paginator = paginator.setTotalPages(pages);
    }

    // Restore index
    paginator = paginator.copyWith(page: idx ~/ paginator.perPage);
    _cursor = idx % paginator.perPage;

    // Keep page in bounds
    if (paginator.page >= paginator.totalPages - 1) {
      paginator = paginator.copyWith(
        page: math.max(0, paginator.totalPages - 1),
      );
    }
  }

  @override
  Cmd? init() => null;

  @override
  (ListModel, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      if (keyMatches(msg.key, [keyMap.forceQuit])) {
        return (this, Cmd.quit());
      }
    }

    if (msg is FilterMatchesMsg) {
      _filteredItems = msg.matches;
      return (this, null);
    }

    if (msg is SpinnerTickMsg) {
      final (newSpinner, cmd) = spinner.update(msg);
      spinner = newSpinner;
      if (_showSpinner && cmd != null) cmds.add(cmd);
    }

    if (msg is StatusMessageTimeoutMsg) {
      hideStatusMessage();
    }

    if (_filterState == FilterState.filtering) {
      final cmd = _handleFiltering(msg);
      if (cmd != null) cmds.add(cmd);
    } else {
      final cmd = _handleBrowsing(msg);
      if (cmd != null) cmds.add(cmd);
    }

    return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
  }

  Cmd? _handleBrowsing(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      if (keyMatches(msg.key, [keyMap.clearFilter])) {
        _resetFiltering();
      } else if (keyMatches(msg.key, [keyMap.quit])) {
        return Cmd.quit();
      } else if (keyMatches(msg.key, [keyMap.cursorUp])) {
        cursorUp();
      } else if (keyMatches(msg.key, [keyMap.cursorDown])) {
        cursorDown();
      } else if (keyMatches(msg.key, [keyMap.prevPage])) {
        prevPage();
      } else if (keyMatches(msg.key, [keyMap.nextPage])) {
        nextPage();
      } else if (keyMatches(msg.key, [keyMap.goToStart])) {
        goToStart();
      } else if (keyMatches(msg.key, [keyMap.goToEnd])) {
        goToEnd();
      } else if (keyMatches(msg.key, [keyMap.showFullHelp]) ||
          keyMatches(msg.key, [keyMap.closeFullHelp])) {
        help = help.copyWith(showAll: !help.showAll);
        _updatePagination();
      } else if (keyMatches(msg.key, [keyMap.filter]) && filteringEnabled) {
        hideStatusMessage();
        if (filterInput.value.isEmpty) {
          _filteredItems = _items
              .asMap()
              .entries
              .map((e) => FilteredItem(index: e.key, item: e.value))
              .toList();
        }
        goToStart();
        _filterState = FilterState.filtering;
        filterInput.cursorEnd();
        final focusCmd = filterInput.focus();
        if (focusCmd != null) cmds.add(focusCmd);
        updateKeybindings();
      }
    }

    final delegateCmd = _delegate.update(msg, this);
    if (delegateCmd != null) cmds.add(delegateCmd);

    _cursor = _cursor.clamp(0, _maxCursorIndex());

    return cmds.isNotEmpty ? Cmd.batch(cmds) : null;
  }

  Cmd? _handleFiltering(Msg msg) {
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      if (keyMatches(msg.key, [keyMap.cancelWhileFiltering])) {
        _resetFiltering();
      } else if (keyMatches(msg.key, [keyMap.acceptWhileFiltering])) {
        hideStatusMessage();
        if (_items.isEmpty) {
          return Cmd.batch(cmds);
        }
        if (visibleItems.isEmpty) {
          _resetFiltering();
          return Cmd.batch(cmds);
        }
        filterInput.blur();
        _filterState = FilterState.filterApplied;
        updateKeybindings();
        if (filterInput.value.isEmpty) {
          _resetFiltering();
        }
      } else {
        // Forward to filter input
        final oldValue = filterInput.value;
        final (_, inputCmd) = filterInput.update(msg);
        if (inputCmd != null) cmds.add(inputCmd);

        // If changed, re-run filter
        if (filterInput.value != oldValue) {
          _runFilter();
          updateKeybindings();
        }
      }
    }

    _updatePagination();
    return Cmd.batch(cmds);
  }

  @override
  String view() {
    final sections = <String>[];
    var availHeight = _height;

    if (showTitle || (showFilter && filteringEnabled)) {
      final titleView = _titleView();
      sections.add(titleView);
      availHeight -= titleView.split('\n').length;
    }

    if (showStatusBar) {
      final statusView = _statusView();
      sections.add(statusView);
      availHeight -= 1;
    }

    String? pagination;
    if (showPagination) {
      pagination = _paginationView();
      availHeight -= 1;
    }

    String? help;
    if (showHelp) {
      help = _helpView();
      availHeight -= 1;
    }

    final content = _populatedView(availHeight);
    sections.add(content);

    if (pagination != null) {
      sections.add(pagination);
    }

    if (help != null) {
      sections.add(help);
    }

    return sections.join('\n');
  }

  String _titleView() {
    var view = '';
    var titleBarStyle = styles.titleBar;

    final spinnerView = spinner.view();
    final spinnerWidth = spinnerView.length;
    const spinnerLeftGap = ' ';
    final spinnerOnLeft =
        titleBarStyle.getPaddingLeft >= spinnerWidth + spinnerLeftGap.length &&
        _showSpinner;

    if (showFilter && _filterState == FilterState.filtering) {
      view += filterInput.view() as String;
    } else if (showTitle) {
      if (_showSpinner && spinnerOnLeft) {
        view += spinnerView + spinnerLeftGap;
        final titleBarGap = titleBarStyle.getPaddingLeft;
        titleBarStyle = titleBarStyle.paddingLeft(
          titleBarGap - spinnerWidth - spinnerLeftGap.length,
        );
      }

      view += styles.title.render(title);

      // Status message
      if (_filterState != FilterState.filtering && _statusMessage.isNotEmpty) {
        view += '  $_statusMessage';
        // Truncate if needed (simplified)
        if (view.length > _width - spinnerWidth) {
          view =
              '${view.substring(0, math.max(0, _width - spinnerWidth - 1))}…';
        }
      }
    }

    // Spinner on right
    if (_showSpinner && !spinnerOnLeft) {
      final renderedView = titleBarStyle.render(view);
      final availSpace = _width - renderedView.length;
      if (availSpace > spinnerWidth) {
        view += ' ' * (availSpace - spinnerWidth);
        view += spinnerView;
      }
    }

    if (view.isNotEmpty) {
      return titleBarStyle.render(view);
    }
    return view;
  }

  String _statusView() {
    var status = '';

    final totalItems = _items.length;
    final visibleItemsCount = visibleItems.length;

    final itemName = visibleItemsCount != 1 ? itemNamePlural : itemNameSingular;
    final itemsDisplay = '$visibleItemsCount $itemName';

    if (_filterState == FilterState.filtering) {
      if (visibleItemsCount == 0) {
        status = styles.statusEmpty.render('Nothing matched');
      } else {
        status = itemsDisplay;
      }
    } else if (_items.isEmpty) {
      status = styles.statusEmpty.render('No $itemNamePlural');
    } else {
      final filtered = _filterState == FilterState.filterApplied;
      if (filtered) {
        var f = filterInput.value.trim();
        if (f.length > 10) f = '${f.substring(0, 9)}…';
        status += '“$f” ';
      }
      status += itemsDisplay;
    }

    final numFiltered = totalItems - visibleItemsCount;
    if (numFiltered > 0) {
      status += styles.dividerDot.render('•');
      status += styles.statusBarFilterCount.render('$numFiltered filtered');
    }

    return styles.statusBar.render(status);
  }

  String _paginationView() {
    if (paginator.totalPages < 2) {
      return '';
    }

    var s = paginator.view();

    // If the dot pagination is wider than the width of the window
    // use the arabic paginator.
    if (s.length > _width) {
      final oldType = paginator.type;
      paginator = paginator.copyWith(type: PaginationType.arabic);
      s = styles.arabicPagination.render(paginator.view());
      paginator = paginator.copyWith(type: oldType);
    }

    var style = styles.paginationStyle;
    if (_delegate.spacing == 0 && style.getMarginTop == 0) {
      style = style.marginTop(1);
    }

    return style.render(s);
  }

  String _helpView() {
    return styles.helpStyle.render(help.view(keyMap));
  }

  String _populatedView(int height) {
    final items = visibleItems;

    if (items.isEmpty) {
      if (_filterState == FilterState.filtering) {
        return '';
      }
      return styles.noItems.render('No $itemNamePlural.');
    }

    final buffer = StringBuffer();
    final start = paginator.page * paginator.perPage;
    final end = math.min(start + paginator.perPage, items.length);
    final docs = items.sublist(start, end);

    for (var i = 0; i < docs.length; i++) {
      buffer.write(_delegate.render(this, i + start, docs[i]));
      if (i != docs.length - 1) {
        buffer.write('\n' * (_delegate.spacing + 1));
      }
    }

    // Pad to fill available height
    final itemsOnPage = paginator.itemsOnPage(items.length);
    if (itemsOnPage < paginator.perPage) {
      var n =
          (paginator.perPage - itemsOnPage) *
          (_delegate.height + _delegate.spacing);
      if (items.isEmpty) {
        n -= _delegate.height - 1;
      }
      buffer.write('\n' * math.max(0, n));
    }

    return buffer.toString();
  }
}
