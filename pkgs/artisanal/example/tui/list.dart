/// TUI List Selection Example
///
/// This example demonstrates an interactive list selection component
/// using the Elm Architecture pattern.
///
/// Run with: dart run example/tui_list.dart
library;

import 'package:artisanal/tui.dart';

/// The list selection model.
class ListModel implements Model {
  /// Creates a list model with the given items.
  const ListModel({required this.items, this.cursor = 0, this.selected});

  /// The list items to choose from.
  final List<String> items;

  /// The current cursor position.
  final int cursor;

  /// The selected item (null if nothing selected yet).
  final String? selected;

  /// Creates a copy with the given fields replaced.
  ListModel copyWith({List<String>? items, int? cursor, String? selected}) {
    return ListModel(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      selected: selected ?? this.selected,
    );
  }

  @override
  Cmd? init() => null; // No initialization needed

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: final key)
          when key.isChar('q') || key.isEscape || key.isCtrlC =>
        (this, Cmd.quit()),

      // Accept/select should win over navigation in case a terminal reports
      // Enter as Ctrl+J / Ctrl+M (or other enter-like variants).
      KeyMsg(key: final key) when key.isEnterLike || key.isSpaceLike => (
        copyWith(selected: items[cursor]),
        Cmd.quit(),
      ),

      KeyMsg(key: final key) when key.type == KeyType.up || key.isChar('k') => (
        copyWith(cursor: (cursor - 1).clamp(0, items.length - 1)),
        null,
      ),

      KeyMsg(key: final key) when key.type == KeyType.down || key.isChar('j') =>
        (copyWith(cursor: (cursor + 1).clamp(0, items.length - 1)), null),

      KeyMsg(key: final key) when key.type == KeyType.home || key.char == 'g' =>
        (copyWith(cursor: 0), null),

      KeyMsg(key: final key) when key.type == KeyType.end || key.char == 'G' =>
        (copyWith(cursor: items.length - 1), null),

      _ => (this, null),
    };
  }

  @override
  String view() {
    final buffer = StringBuffer();

    buffer.writeln();
    buffer.writeln('  What would you like to have for lunch?');
    buffer.writeln();

    for (var i = 0; i < items.length; i++) {
      final isSelected = i == cursor;
      final prefix = isSelected ? '▸ ' : '  ';
      final item = items[i];

      if (isSelected) {
        // Highlight selected item
        buffer.writeln('  \x1b[36m$prefix$item\x1b[0m');
      } else {
        buffer.writeln('  $prefix$item');
      }
    }

    buffer.writeln();
    buffer.writeln(
      '  \x1b[2m↑/k: up • ↓/j: down • Enter: select • q: quit\x1b[0m',
    );
    buffer.writeln();

    return buffer.toString();
  }
}

void main() async {
  final model = ListModel(
    items: [
      '🍕 Pizza',
      '🍔 Burger',
      '🌮 Tacos',
      '🍜 Ramen',
      '🥗 Salad',
      '🍣 Sushi',
      '🥪 Sandwich',
      '🍝 Pasta',
    ],
  );

  final result = await runProgramWithResult(
    model,
    options: const ProgramOptions(
      altScreen: true,
      useUltravioletRenderer: true,
      useUltravioletInputDecoder: true,
    ),
  );

  Cmd.println(
    // tui:allow-stdout
    result.selected == null
        ? 'No selection made. Maybe next time!'
        : 'You selected: ${result.selected}',
  );
}
