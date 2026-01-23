/// Fancy list example ported from Bubble Tea.
library;

import 'dart:math' as math;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

import 'delegate.dart';
import 'random_items.dart';

final _appStyle = Style().padding(1, 2);
final _titleStyle = Style()
    .foreground(const AnsiColor(15)) // bright white
    .background(const AnsiColor(35)) // green-ish
    .padding(0, 1);

String _statusMessageStyle(String text) =>
    Style().foreground(const AnsiColor(35)).render(text);

class GroceryItem implements tui.ListItem {
  GroceryItem({required this.title, required this.description});

  final String title;
  final String description;

  @override
  String filterValue() => title;
}

class FancyKeys {
  FancyKeys()
    : toggleSpinner = tui.KeyBinding.withHelp(['s'], 's', 'toggle spinner'),
      toggleTitleBar = tui.KeyBinding.withHelp(['T'], 'T', 'toggle title'),
      toggleStatusBar = tui.KeyBinding.withHelp(['S'], 'S', 'toggle status'),
      togglePagination = tui.KeyBinding.withHelp(
        ['P'],
        'P',
        'toggle pagination',
      ),
      toggleHelpMenu = tui.KeyBinding.withHelp(['H'], 'H', 'toggle help'),
      insertItem = tui.KeyBinding.withHelp(['a'], 'a', 'add item'),
      choose = tui.KeyBinding.withHelp(['enter'], 'enter', 'choose'),
      remove = tui.KeyBinding.withHelp(['x', 'backspace'], 'x', 'delete');

  final tui.KeyBinding toggleSpinner;
  final tui.KeyBinding toggleTitleBar;
  final tui.KeyBinding toggleStatusBar;
  final tui.KeyBinding togglePagination;
  final tui.KeyBinding toggleHelpMenu;
  final tui.KeyBinding insertItem;

  final tui.KeyBinding choose;
  final tui.KeyBinding remove;
}

class FancyModel implements tui.Model {
  FancyModel({required this.list, required this.generator, required this.keys});

  final tui.ListModel list;
  final RandomItemGenerator generator;
  final FancyKeys keys;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        final h =
            _appStyle.getHorizontalMargins + _appStyle.getHorizontalPadding;
        final v = _appStyle.getVerticalMargins + _appStyle.getVerticalPadding;
        list.setSize(math.max(0, width - h), math.max(0, height - v));

      case tui.KeyMsg(key: final key):
        // Skip our hotkeys when filtering
        if (list.filterState == tui.FilterState.filtering) break;

        if (key.matchesSingle(keys.toggleSpinner)) {
          final cmd = list.startSpinner();
          return (this, cmd);
        }
        if (key.matchesSingle(keys.toggleTitleBar)) {
          final show = !list.showTitle;
          list.showTitle = show;
          list.showFilter = show;
          list.filteringEnabled = show;
          return (this, null);
        }
        if (key.matchesSingle(keys.toggleStatusBar)) {
          list.showStatusBar = !list.showStatusBar;
          return (this, null);
        }
        if (key.matchesSingle(keys.togglePagination)) {
          list.showPagination = !list.showPagination;
          return (this, null);
        }
        if (key.matchesSingle(keys.toggleHelpMenu)) {
          list.showHelp = !list.showHelp;
          return (this, null);
        }
        if (key.matchesSingle(keys.insertItem)) {
          keys.remove.enabled = true;
          final newItem = generator.next();
          final newItems = [
            GroceryItem(title: newItem.title, description: newItem.description),
            ...list.items,
          ];
          list.items = newItems;
          list.resetSelected();
          final status = list.newStatusMessage(
            _statusMessageStyle('Added ${newItem.title}'),
          );
          return (this, status);
        }
    }

    final (newList, cmd) = list.update(msg);
    return (FancyModel(list: newList, generator: generator, keys: keys), cmd);
  }

  @override
  String view() => _appStyle.render(list.view());
}

tui.ListModel _buildList(FancyKeys keys, RandomItemGenerator generator) {
  const numItems = 24;
  final items = List<tui.ListItem>.generate(numItems, (_) {
    final item = generator.next();
    return GroceryItem(title: item.title, description: item.description);
  });

  final delegate = FancyDelegate(keys);

  final list = tui.ListModel(
    items: items,
    delegate: delegate,
    title: 'Groceries',
    showPagination: true,
    showFilter: true,
    filteringEnabled: true,
  );

  list.styles = tui.ListStyles(
    title: _titleStyle,
    titleBar: list.styles.titleBar,
    filterPrompt: list.styles.filterPrompt,
    filterCursor: list.styles.filterCursor,
    statusBar: list.styles.statusBar,
    statusEmpty: list.styles.statusEmpty,
    statusBarActiveFilter: list.styles.statusBarActiveFilter,
    noItems: list.styles.noItems,
    paginationStyle: list.styles.paginationStyle,
    helpStyle: list.styles.helpStyle,
    activePaginationDot: list.styles.activePaginationDot,
    inactivePaginationDot: list.styles.inactivePaginationDot,
    spinner: list.styles.spinner,
  );

  return list;
}

Future<void> main() async {
  final generator = RandomItemGenerator();
  final keys = FancyKeys();
  final list = _buildList(keys, generator);

  await tui.runProgram(
    FancyModel(list: list, generator: generator, keys: keys),
    options: const tui.ProgramOptions(),
  );
}
