/// Default list example ported from Bubble Tea.
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart' show AnsiColor, Style;
import 'package:artisanal/tui.dart' as tui;

final _docStyle = Style().margin(1, 2);

class ThingItem implements tui.ListItem {
  ThingItem(this.title, this.desc);

  final String title;
  final String desc;

  @override
  String filterValue() => title;
}

class ThingDelegate implements tui.ItemDelegate {
  ThingDelegate({
    Style? titleStyle,
    Style? descStyle,
    Style? selectedTitleStyle,
  }) : titleStyle = titleStyle ?? Style(),
       descStyle = descStyle ?? Style().foreground(const AnsiColor(241)),
       selectedTitleStyle =
           selectedTitleStyle ??
           Style().foreground(const AnsiColor(170)).bold().paddingLeft(0);

  final Style titleStyle;
  final Style descStyle;
  final Style selectedTitleStyle;

  @override
  int get height => 2;

  @override
  int get spacing => 0;

  @override
  tui.Cmd? update(tui.Msg msg, tui.ListModel model) => null;

  @override
  String render(tui.ListModel model, int index, tui.ListItem item) {
    final thing = item as ThingItem;
    final selected = model.index == index;
    final title = selected
        ? selectedTitleStyle.render(thing.title)
        : titleStyle.render(thing.title);
    final desc = descStyle.render(thing.desc);
    return '$title\n$desc';
  }
}

class ListDefaultModel implements tui.Model {
  const ListDefaultModel({required this.list});

  final tui.ListModel list;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: tui.Key(ctrl: true, runes: [0x63])): // Ctrl+C
        return (this, tui.Cmd.quit());

      case tui.WindowSizeMsg(:final width, :final height):
        final hFrame =
            _docStyle.getHorizontalMargins + _docStyle.getHorizontalPadding;
        final vFrame =
            _docStyle.getVerticalMargins + _docStyle.getVerticalPadding;
        list.setSize(math.max(0, width - hFrame), math.max(0, height - vFrame));
    }

    final (newList, cmd) = list.update(msg);
    return (ListDefaultModel(list: newList), cmd);
  }

  @override
  String view() => _docStyle.render(list.view());
}

tui.ListModel _buildList() {
  final items = <tui.ListItem>[
    ThingItem('Raspberry Pi’s', 'I have ’em all over my house'),
    ThingItem('Nutella', 'It\'s good on toast'),
    ThingItem('Bitter melon', 'It cools you down'),
    ThingItem('Nice socks', 'And by that I mean socks without holes'),
    ThingItem('Eight hours of sleep', 'I had this once'),
    ThingItem('Cats', 'Usually'),
    ThingItem('Plantasia, the album', 'My plants love it too'),
    ThingItem('Pour over coffee', 'It takes forever to make though'),
    ThingItem('VR', 'Virtual reality...what is there to say?'),
    ThingItem('Noguchi Lamps', 'Such pleasing organic forms'),
    ThingItem('Linux', 'Pretty much the best OS'),
    ThingItem('Business school', 'Just kidding'),
    ThingItem('Pottery', 'Wet clay is a great feeling'),
    ThingItem('Shampoo', 'Nothing like clean hair'),
    ThingItem('Table tennis', 'It’s surprisingly exhausting'),
    ThingItem('Milk crates', 'Great for packing in your extra stuff'),
    ThingItem('Afternoon tea', 'Especially the tea sandwich part'),
    ThingItem('Stickers', 'The thicker the vinyl the better'),
    ThingItem('20° Weather', 'Celsius, not Fahrenheit'),
    ThingItem('Warm light', 'Like around 2700 Kelvin'),
    ThingItem('The vernal equinox', 'The autumnal equinox is pretty good too'),
    ThingItem('Gaffer’s tape', 'Basically sticky fabric'),
    ThingItem('Terrycloth', 'In other words, towel fabric'),
  ];

  final delegate = ThingDelegate(
    titleStyle: Style(),
    descStyle: Style().foreground(const AnsiColor(241)),
    selectedTitleStyle: Style()
        .foreground(const AnsiColor(170))
        .bold()
        .paddingLeft(0),
  );

  final list = tui.ListModel(
    items: items,
    delegate: delegate,
    showPagination: true,
    showFilter: true,
    filteringEnabled: true,
    title: 'My Fave Things',
  );

  return list;
}

Future<void> main() async {
  await tui.runProgram(
    ListDefaultModel(list: _buildList()),
    options: const tui.ProgramOptions(),
  );
}
