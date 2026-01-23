/// Paginator example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

class PaginatorExampleModel implements tui.Model {
  PaginatorExampleModel({required this.items, tui.PaginatorModel? paginator})
    : paginator =
          paginator ??
          tui.PaginatorModel(
            type: tui.PaginationType.dots,
            perPage: 10,
            activeDot: Style().foreground(const AnsiColor(235)).render('•'),
            inactiveDot: Style().foreground(const AnsiColor(250)).render('•'),
          ).setTotalPages(items.length);

  final List<String> items;
  final tui.PaginatorModel paginator;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        if (key.matchesSingle(tui.CommonKeyBindings.quit)) {
          return (this, tui.Cmd.quit());
        }
    }

    final (newPaginator, cmd) = paginator.update(msg);
    return (PaginatorExampleModel(items: items, paginator: newPaginator), cmd);
  }

  @override
  String view() {
    final buffer = StringBuffer();
    buffer.write('\n  Paginator Example\n\n');
    final (start, end) = paginator.getSliceBounds(items.length);
    for (final item in items.sublist(start, end)) {
      buffer.write('  • $item\n\n');
    }
    buffer.write('  ${paginator.view()}');
    buffer.write('\n\n  h/l ←/→ page • q: quit\n');
    return buffer.toString();
  }
}

List<String> _items() => List.generate(100, (i) => 'Item ${i + 1}');

Future<void> main() async {
  await tui.runProgram(
    PaginatorExampleModel(items: _items()),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
