/// Simple list example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/tui.dart' as tui;

const _listHeight = 14;
const _defaultWidth = 20;

// #region list_usage
class ListSimpleModel implements tui.Model {
  const ListSimpleModel({
    required this.list,
    this.choice = '',
    this.quitting = false,
  });

  final tui.ListModel list;
  final String choice;
  final bool quitting;

  ListSimpleModel copyWith({
    tui.ListModel? list,
    String? choice,
    bool? quitting,
  }) {
    return ListSimpleModel(
      list: list ?? this.list,
      choice: choice ?? this.choice,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.WindowSizeMsg(:final width):
        final updated = list..setSize(width, _listHeight);
        return (copyWith(list: updated), null);

      case tui.KeyMsg(key: tui.Key(type: tui.KeyType.runes, runes: [0x71])) ||
          // q
          tui.KeyMsg(key: tui.Key(ctrl: true, runes: [0x63])): // Ctrl+C
        return (copyWith(quitting: true), tui.Cmd.quit());

      case tui.KeyMsg(key: tui.Key(type: tui.KeyType.enter)):
        final selected = list.selectedItem;
        if (selected != null) {
          return (copyWith(choice: selected.toString()), tui.Cmd.quit());
        }
        return (this, null);

      default:
        final (newList, cmd) = list.update(msg);
        return (copyWith(list: newList), cmd);
    }
  }

  @override
  String view() {
    final quitStyle = Style().margin(1, 0, 2, 4);
    if (choice.isNotEmpty) {
      return quitStyle.render('$choice? Sounds good to me.');
    }
    if (quitting) {
      return quitStyle.render("Not hungry? That's cool.");
    }
    return '\n${list.view()}';
  }
}
// #endregion

tui.ListModel _buildList() {
  final items = <tui.ListItem>[
    tui.StringItem('Ramen'),
    tui.StringItem('Tomato Soup'),
    tui.StringItem('Hamburgers'),
    tui.StringItem('Cheeseburgers'),
    tui.StringItem('Currywurst'),
    tui.StringItem('Okonomiyaki'),
    tui.StringItem('Pasta'),
    tui.StringItem('Fillet Mignon'),
    tui.StringItem('Caviar'),
    tui.StringItem('Just Wine'),
  ];

  final delegate = tui.DefaultItemDelegate(
    normalStyle: Style().paddingLeft(4),
    selectedStyle: Style()
        .paddingLeft(2)
        .foreground(const AnsiColor(170))
        .bold(),
  );

  final baseStyles = tui.ListStyles.defaults();
  final styles = tui.ListStyles(
    title: baseStyles.title.paddingLeft(2),
    titleBar: baseStyles.titleBar,
    filterPrompt: baseStyles.filterPrompt,
    filterCursor: baseStyles.filterCursor,
    statusBar: baseStyles.statusBar,
    statusEmpty: baseStyles.statusEmpty,
    statusBarActiveFilter: baseStyles.statusBarActiveFilter,
    noItems: baseStyles.noItems,
    paginationStyle: baseStyles.paginationStyle.paddingLeft(4),
    helpStyle: baseStyles.helpStyle.paddingLeft(4).paddingBottom(1),
    activePaginationDot: baseStyles.activePaginationDot,
    inactivePaginationDot: baseStyles.inactivePaginationDot,
    spinner: baseStyles.spinner,
  );

  return tui.ListModel(
    items: items,
    delegate: delegate,
    width: _defaultWidth,
    height: _listHeight,
    title: 'What do you want for dinner?',
    showStatusBar: false,
    filteringEnabled: false,
    showFilter: false,
    styles: styles,
  );
}

Future<void> main() async {
  await tui.runProgram(
    ListSimpleModel(list: _buildList()),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
