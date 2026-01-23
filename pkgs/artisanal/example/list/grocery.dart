/// Grocery list example - demonstrates custom enumerators and conditional styling.
///
/// This is a port of the Go lipgloss example: examples/list/grocery/main.go
library;

import 'package:artisanal/style.dart';

final purchased = [
  'Bananas',
  'Barley',
  'Cashews',
  'Coconut Milk',
  'Dill',
  'Eggs',
  'Fish Cake',
  'Leeks',
  'Papaya',
];

String groceryEnumerator(ListItems items, int i) {
  for (final p in purchased) {
    if (items.at(i).value == p) {
      return '✓';
    }
  }
  return '•';
}

final dimEnumStyle = Style().foreground(AnsiColor(240)).marginRight(1);

final highlightedEnumStyle = Style().foreground(AnsiColor(10)).marginRight(1);

Style enumStyleFunc(ListItems items, int i) {
  for (final p in purchased) {
    if (items.at(i).value == p) {
      return highlightedEnumStyle;
    }
  }
  return dimEnumStyle;
}

Style itemStyleFunc(ListItems items, int i) {
  final itemStyle = Style().foreground(AnsiColor(255));
  for (final p in purchased) {
    if (items.at(i).value == p) {
      return itemStyle.strikethrough();
    }
  }
  return itemStyle;
}

void main() {
  final l =
      LipList.create([
            'Artichoke',
            'Baking Flour',
            'Bananas',
            'Barley',
            'Bean Sprouts',
            'Cashew Apple',
            'Cashews',
            'Coconut Milk',
            'Curry Paste',
            'Currywurst',
            'Dill',
            'Dragonfruit',
            'Dried Shrimp',
            'Eggs',
            'Fish Cake',
            'Furikake',
            'Jicama',
            'Kohlrabi',
            'Leeks',
            'Lentils',
            'Licorice Root',
          ])
          .enumerator(groceryEnumerator)
          .enumeratorStyleFunc(enumStyleFunc)
          .itemStyleFunc(itemStyleFunc);

  print(l);
}
