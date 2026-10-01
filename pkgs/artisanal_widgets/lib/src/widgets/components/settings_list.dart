import 'dart:async';

import '_component_foundation.dart';
import 'frame.dart' as widget_frame;
import 'fuzzy_search.dart';

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/runtime.dart';
import 'package:artisanal/style.dart' show Color;

/// The action performed when a settings row is activated with Enter or a tap.
enum SettingsListActivation {
  /// Increase or advance the selected setting.
  adjust,

  /// Invoke the list's action callback for the selected row.
  action,

  /// Keep the row informational and ignore activation.
  none,
}

/// A typed row displayed by [SettingsList].
///
/// The host owns the accepted value and persistence. Build a new item list
/// after an accepted callback to show the new value; this widget never
/// optimistically changes a setting.
class SettingsListItem<T> {
  /// Creates a settings row with a stable [id] used to preserve selection.
  const SettingsListItem({
    required this.id,
    required this.label,
    this.value,
    this.category,
    this.description,
    this.searchTerms = const [],
    this.disabledReason,
    this.enabled = true,
    this.canDecrease = true,
    this.canIncrease = true,
    this.isBusy = false,
    this.activation = SettingsListActivation.adjust,
    this.background,
  });

  /// Stable identity for retaining the selected row across updates.
  final T id;

  /// Primary setting name or action label.
  final String label;

  /// Current accepted value shown at the trailing edge.
  final String? value;

  /// Optional section label shared with adjacent rows.
  final String? category;

  /// Optional explanatory text shown below the row label.
  final String? description;

  /// Additional terms included in case-insensitive, all-terms search.
  final List<String> searchTerms;

  /// Explanation shown when the row is unavailable.
  final String? disabledReason;

  /// Whether this row can receive focus and interaction.
  final bool enabled;

  /// Whether a decrement request is currently allowed.
  final bool canDecrease;

  /// Whether an increment request is currently allowed.
  final bool canIncrease;

  /// Whether the host is already processing this row.
  final bool isBusy;

  /// How Enter and pointer activation operate on this row.
  final SettingsListActivation activation;

  /// Optional per-row background color override.
  final Color? background;

  /// Whether this row can be interacted with under its current state.
  bool get isInteractive => enabled && disabledReason == null && !isBusy;

  /// Returns whether every term in [query] occurs in searchable row text.
  bool matchesQuery(String query) {
    final searchable = [
      label,
      category ?? '',
      description ?? '',
      disabledReason ?? '',
      ...searchTerms,
    ].join(' ').toLowerCase();
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .every(searchable.contains);
  }

  /// Returns a fuzzy relevance score for [query] across this row's text.
  double searchScore(String query) => FuzzySearch.score(
    query,
    [
      label,
      category ?? '',
      description ?? '',
      disabledReason ?? '',
      ...searchTerms,
    ].join(' '),
  );
}

/// Result of a host-owned setting change or action.
class SettingsListResult {
  /// Reports that the host accepted the request.
  const SettingsListResult.accepted() : message = null;

  /// Reports that the host rejected the request without changing its value.
  const SettingsListResult.rejected(this.message);

  /// Optional rejection message displayed in the list footer.
  final String? message;
}

/// Host callback that requests a relative setting change.
typedef SettingsListAdjustCallback<T> = FutureOr<SettingsListResult> Function(
  T id,
  int direction,
);

/// Host callback that activates a non-setting row.
typedef SettingsListActionCallback<T> = FutureOr<SettingsListResult> Function(
  T id,
);

/// Searchable, grouped, host-controlled settings list for terminal UIs.
///
/// Up/down navigates rows. Left/right adjusts a setting; Enter and pointer
/// activation use each row's [SettingsListActivation]. A callback may be
/// asynchronous. While it is pending, edits are serialized and the accepted
/// value remains entirely host-owned. Return a rejected [SettingsListResult]
/// or throw to show an error without changing the row optimistically.
/// Tab switches focus between the search field and setting rows. Left/right
/// edits only while the rows own focus, so the search caret remains usable.
///
/// Search matches every whitespace-separated term across row labels,
/// categories, descriptions, disabled reasons and [SettingsListItem.searchTerms].
/// Selection is retained by stable row ID when filtering or replacing items.
///
/// ```dart
/// SettingsList<String>(
///   title: 'Settings',
///   items: [
///     SettingsListItem(
///       id: 'scroll-speed',
///       label: 'Scroll speed',
///       category: 'Input',
///       value: '3.00',
///       canDecrease: true,
///     ),
///   ],
///   onAdjust: (id, direction) async {
///     await saveSetting(id, direction);
///     return const SettingsListResult.accepted();
///   },
///   onDismiss: () => closeSettings(),
/// )
/// ```
class SettingsList<T> extends StatefulWidget {
  /// Creates a settings list whose values and persistence remain host-owned.
  SettingsList({
    required this.items,
    this.title = 'Settings',
    this.searchHint = 'Search settings',
    this.initialSelection,
    this.adjustWhileSearching = false,
    double? filterThreshold,
    this.onAdjust,
    this.onActivate,
    this.onDismiss,
    this.status,
    this.width,
    this.height,
    this.focusId = 'settings-list',
    super.key,
  }) : filterThreshold = filterThreshold {
    assert(
      filterThreshold == null || (filterThreshold >= 0 && filterThreshold <= 1),
    );
  }

  /// Rows to display. Supply stable IDs and rebuild after accepted changes.
  final List<SettingsListItem<T>> items;

  /// Dialog title.
  final String title;

  /// Search field placeholder.
  final String searchHint;

  /// ID selected on first build when it exists in [items].
  final T? initialSelection;

  /// Whether left/right adjusts the selected row while search owns focus.
  ///
  /// Disable this to preserve normal search-caret navigation. Enable it when
  /// the host routes setting changes independently from text-field focus.
  final bool adjustWhileSearching;

  /// Minimum fuzzy relevance score for an item to match a non-empty query.
  ///
  /// When omitted, matching uses [SettingsListItem.matchesQuery] and preserves
  /// exact all-term substring behavior. Values must be between `0` and `1`.
  final double? filterThreshold;

  /// Requests a relative adjustment for an adjustable row.
  final SettingsListAdjustCallback<T>? onAdjust;

  /// Runs when an action row is activated.
  final SettingsListActionCallback<T>? onActivate;

  /// Called when Escape or the title close affordance is activated.
  final CmdCallback? onDismiss;

  /// Optional host-owned status text shown when no request is pending.
  final String? status;

  /// Dialog width in terminal columns.
  final int? width;

  /// Dialog height in terminal rows.
  final int? height;

  /// Stable prefix for search and row focus IDs when lists are nested.
  final String focusId;

  @override
  State createState() => _SettingsListState<T>();
}

class _SettingsListState<T> extends State<SettingsList<T>> {
  late final TextEditingController _searchController;
  final _focusController = FocusController();
  late final WidgetScrollController _scroll;
  var _searchQuery = '';
  var _selectedIndex = 0;
  var _busy = false;
  T? _pendingId;
  String? _error;
  late List<SettingsListItem<T>> _filteredItems;

  String get _searchFocusId => '${widget.focusId}.search';
  String get _rowsFocusId => '${widget.focusId}.rows';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = const [];
    _recomputeItems(preserveSelection: false);
    _scroll = WidgetScrollController(
      initialOffset: _rowOffsetForIndex(_selectedIndex),
    );
  }

  @override
  Cmd? didUpdateWidget(covariant SettingsList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.filterThreshold != widget.filterThreshold) {
      _recomputeItems(preserveSelection: true);
      _scrollSelectionIntoView();
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recomputeItems({
    required bool preserveSelection,
    bool selectFirstMatch = false,
  }) {
    final previousSelection =
        preserveSelection &&
            _selectedIndex >= 0 &&
            _selectedIndex < _filteredItems.length
        ? _filteredItems[_selectedIndex]
        : null;
    final threshold = widget.filterThreshold;
    final nextItems = threshold == null || _searchQuery.trim().isEmpty
        ? widget.items
              .where((item) => item.matchesQuery(_searchQuery))
              .toList(growable: false)
        : _filterFuzzyItems(threshold);

    var nextIndex = -1;
    if (previousSelection != null) {
      nextIndex = nextItems.indexWhere(
        (item) => item.id == previousSelection.id,
      );
    } else if (!preserveSelection &&
        !selectFirstMatch &&
        widget.initialSelection != null) {
      nextIndex = nextItems.indexWhere(
        (item) => item.id == widget.initialSelection,
      );
    }
    if (nextIndex < 0 && nextItems.isNotEmpty) {
      nextIndex = selectFirstMatch
          ? 0
          : _selectedIndex.clamp(0, nextItems.length - 1);
    }
    _filteredItems = nextItems;
    _selectedIndex = nextIndex < 0 ? 0 : nextIndex;
  }

  List<SettingsListItem<T>> _filterFuzzyItems(double threshold) {
    final rankedItems =
        <({int index, double score, SettingsListItem<T> item})>[];
    for (final (index, item) in widget.items.indexed) {
      final score = item.searchScore(_searchQuery);
      if (score >= threshold) {
        rankedItems.add((index: index, score: score, item: item));
      }
    }
    rankedItems.sort((left, right) {
      final scoreOrder = right.score.compareTo(left.score);
      return scoreOrder == 0 ? left.index.compareTo(right.index) : scoreOrder;
    });
    return rankedItems.map((entry) => entry.item).toList(growable: false);
  }

  void _moveSelection(int delta) {
    if (_filteredItems.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(
        0,
        _filteredItems.length - 1,
      );
      _error = null;
    });
    _scrollSelectionIntoView();
  }

  void _scrollSelectionIntoView() {
    if (_filteredItems.isEmpty || _scroll.viewportExtent <= 0) return;
    final selected = _rowOffsetForIndex(_selectedIndex);
    if (selected < _scroll.offset) {
      _scroll.jumpTo(selected);
    } else if (selected >= _scroll.offset + _scroll.viewportExtent) {
      _scroll.jumpTo(selected - _scroll.viewportExtent + 1);
    }
  }

  int _rowOffsetForIndex(int itemIndex) {
    if (itemIndex < 0 || itemIndex >= _filteredItems.length) return 0;
    var offset = 0;
    String? lastCategory;
    for (var index = 0; index <= itemIndex; index++) {
      final item = _filteredItems[index];
      if (item.category != null && item.category != lastCategory) {
        offset += 2;
        lastCategory = item.category;
      }
      if (index == itemIndex) break;
      offset += 1;
      if (item.disabledReason != null || item.description != null) offset += 1;
    }
    return offset;
  }

  SettingsListItem<T>? get _selectedItem =>
      _selectedIndex >= 0 && _selectedIndex < _filteredItems.length
      ? _filteredItems[_selectedIndex]
      : null;

  void _activateCurrent() {
    final item = _selectedItem;
    if (item == null || _busy || !item.isInteractive) return;
    switch (item.activation) {
      case SettingsListActivation.adjust:
        _adjust(1);
      case SettingsListActivation.action:
        final callback = widget.onActivate;
        if (callback != null) {
          unawaited(_run(item.id, () => callback(item.id)));
        }
      case SettingsListActivation.none:
        return;
    }
  }

  void _adjust(int direction) {
    final item = _selectedItem;
    final callback = widget.onAdjust;
    if (item == null ||
        callback == null ||
        _busy ||
        !item.isInteractive ||
        item.activation != SettingsListActivation.adjust ||
        (direction < 0 && !item.canDecrease) ||
        (direction > 0 && !item.canIncrease)) {
      return;
    }
    unawaited(_run(item.id, () => callback(item.id, direction)));
  }

  Future<void> _run(
    T itemId,
    FutureOr<SettingsListResult> Function() request,
  ) async {
    setState(() {
      _busy = true;
      _pendingId = itemId;
      _error = null;
    });
    try {
      final result = await request();
      if (mounted) setState(() => _error = result.message);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _pendingId = null;
        });
      }
    }
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is! KeyMsg) return null;
    final searchFocused = _focusController.isFocused(_searchFocusId);
    switch (msg.key.type) {
      case terminal_keys.KeyType.escape:
        return widget.onDismiss?.call();
      case terminal_keys.KeyType.enter:
        _activateCurrent();
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
      case terminal_keys.KeyType.left:
        if (searchFocused && !widget.adjustWhileSearching) return null;
        _adjust(-1);
        return Cmd.none();
      case terminal_keys.KeyType.right:
        if (searchFocused && !widget.adjustWhileSearching) return null;
        _adjust(1);
        return Cmd.none();
      case terminal_keys.KeyType.tab:
        _focusController.requestFocus(
          searchFocused ? _rowsFocusId : _searchFocusId,
        );
        return Cmd.none();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final dialogTheme = theme.dialogTheme;
    final paletteTheme = theme.commandPaletteTheme;
    final background =
        dialogTheme?.background ?? paletteTheme?.background ?? theme.surface;
    final foreground =
        dialogTheme?.foreground ?? paletteTheme?.foreground ?? theme.onSurface;
    final selectedBackground =
        dialogTheme?.buttonSelectedBackground ??
        paletteTheme?.selectedBackground ??
        theme.listRowSelectedBackground;
    final selectedForeground =
        dialogTheme?.buttonSelectedForeground ??
        paletteTheme?.selectedForeground ??
        theme.listRowSelectedForeground;
    final headerForeground = paletteTheme?.headerForeground ?? theme.muted;
    final searchBackground = paletteTheme?.searchBackground ?? theme.background;
    final hintForeground = dialogTheme?.hintForeground ?? theme.muted;
    final width =
        widget.width ?? dialogTheme?.width ?? paletteTheme?.width ?? 64;
    final height =
        widget.height ??
        dialogTheme?.maxHeight ??
        paletteTheme?.maxHeight ??
        22;

    return SizedBox(
      width: width,
      height: height,
      child: widget_frame.Frame(
        background: background,
        foreground: foreground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitle(theme, hintForeground),
            SizedBox(height: 1),
            _buildSearch(theme, searchBackground),
            SizedBox(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Focusable(
                    controller: _focusController,
                    focusId: _rowsFocusId,
                    child: _buildRows(
                      theme,
                      selectedBackground,
                      selectedForeground,
                      headerForeground,
                      foreground,
                    ),
                  ),
                ),
              ),
            ),
            _buildFooter(theme, hintForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(Theme theme, Color hintForeground) {
    final titleStyle = copyStyle(theme.titleMedium)
      ..foreground(theme.onSurface);
    final hintStyle = copyStyle(theme.bodySmall)..foreground(hintForeground);
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title, style: titleStyle),
          GestureDetector(
            onTap: widget.onDismiss,
            child: Text('esc', style: hintStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(Theme theme, Color searchBackground) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: widget_frame.Frame(
        background: searchBackground,
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
                focusController: _focusController,
                focusId: _searchFocusId,
                prompt: '',
                placeholder: widget.searchHint,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _recomputeItems(
                      preserveSelection: widget.filterThreshold == null,
                      selectFirstMatch: widget.filterThreshold != null,
                    );
                    _error = null;
                  });
                  _scroll.jumpTo(0);
                  _scrollSelectionIntoView();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRows(
    Theme theme,
    Color selectedBackground,
    Color selectedForeground,
    Color headerForeground,
    Color defaultForeground,
  ) {
    if (_filteredItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Text(
          _searchQuery.isEmpty
              ? 'No settings'
              : 'No matches for "$_searchQuery"',
          style: copyStyle(theme.bodySmall)..foreground(theme.muted),
        ),
      );
    }

    final rows = <Widget>[];
    String? lastCategory;
    for (final (index, item) in _filteredItems.indexed) {
      if (item.category != null && item.category != lastCategory) {
        lastCategory = item.category;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              item.category!,
              style: copyStyle(theme.titleSmall)
                ..foreground(headerForeground)
                ..bold(),
            ),
          ),
        );
      }
      final selected = index == _selectedIndex;
      final interactive = item.isInteractive && !_busy;
      final rowForeground = !interactive
          ? theme.muted
          : selected
          ? selectedForeground
          : defaultForeground;
      final description = item.disabledReason ?? item.description;
      final row = widget_frame.Frame(
        background: selected ? selectedBackground : item.background,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  selected ? '›' : ' ',
                  style: copyStyle(theme.bodySmall)
                    ..foreground(
                      selected
                          ? theme.listRowSelectedMarkerForeground
                          : theme.listRowMarkerForeground,
                    ),
                ),
                SizedBox(width: 1),
                Expanded(
                  child: Text(
                    item.label,
                    style: copyStyle(theme.bodyMedium)
                      ..foreground(rowForeground),
                  ),
                ),
                if ((_busy && item.id == _pendingId) || item.isBusy)
                  Text(
                    'Saving…',
                    style: copyStyle(theme.bodySmall)..foreground(theme.muted),
                  )
                else if (item.value != null)
                  Text(
                    item.value!,
                    style: copyStyle(theme.bodySmall)
                      ..foreground(
                        selected
                            ? theme.listRowSelectedMutedForeground
                            : theme.listRowMutedForeground,
                      ),
                  ),
              ],
            ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  description,
                  style: copyStyle(theme.bodySmall)
                    ..foreground(
                      selected
                          ? theme.listRowSelectedMutedForeground
                          : theme.listRowMutedForeground,
                    ),
                ),
              ),
          ],
        ),
      );
      rows.add(
        GestureDetector(
          onTap: item.isInteractive && !_busy
              ? () {
                  setState(() {
                    _selectedIndex = index;
                    _error = null;
                  });
                  _focusController.requestFocus(_rowsFocusId);
                  _activateCurrent();
                  return null;
                }
              : null,
          child: MouseRegion(
            onEnter: (_) {
              if (_selectedIndex != index) {
                setState(() => _selectedIndex = index);
                _scrollSelectionIntoView();
              }
              return null;
            },
            child: row,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildFooter(Theme theme, Color hintForeground) {
    final item = _selectedItem;
    final message = _busy
        ? 'Saving…'
        : _error ??
              item?.disabledReason ??
              widget.status ??
              switch (item?.activation) {
                SettingsListActivation.adjust =>
                  '←/→ change · Enter change · Esc close',
                SettingsListActivation.action => 'Enter open · Esc close',
                SettingsListActivation.none => 'Esc close',
                null => 'Esc close',
              };
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 1, top: 1),
      child: Text(
        message,
        style: copyStyle(theme.bodySmall)
          ..foreground(_error == null ? hintForeground : theme.error),
      ),
    );
  }
}
