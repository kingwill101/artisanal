/// Custom list delegate for fancy list example.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

import 'main.dart' show GroceryItem;
import 'main.dart' show FancyKeys;

class FancyDelegate implements tui.ItemDelegate {
  FancyDelegate(this.keys);

  final FancyKeys keys;

  @override
  int get height => 2;

  @override
  int get spacing => 0;

  @override
  tui.Cmd? update(tui.Msg msg, tui.ListModel model) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final selected = model.selectedItem;
        if (selected is! GroceryItem) return null;

        if (key.matchesSingle(keys.choose)) {
          return model.newStatusMessage(
            _statusStyle('You chose ${selected.title}'),
          );
        }
        if (key.matchesSingle(keys.remove)) {
          final idx = model.index;
          if (idx >= 0 && idx < model.items.length) {
            final items = [...model.items]..removeAt(idx);
            model.items = items;
            if (items.isEmpty) {
              keys.remove.enabled = false;
            } else {
              model.resetSelected();
            }
            return model.newStatusMessage(
              _statusStyle('Deleted ${selected.title}'),
            );
          }
        }
    }
    return null;
  }

  @override
  String render(tui.ListModel model, int index, tui.ListItem item) {
    final grocery = item as GroceryItem;
    final selected = model.index == index;
    final titleStyle = selected
        ? Style().foreground(const AnsiColor(170)).bold().paddingLeft(0)
        : Style();
    final descStyle = Style().foreground(const AnsiColor(241));
    final title = titleStyle.render(grocery.title);
    final desc = descStyle.render(grocery.description);
    return '$title\n$desc';
  }

  String _statusStyle(String text) {
    return Style()
        .foreground(const AnsiColor(35))
        .render(text); // approximate adaptive green
  }
}
