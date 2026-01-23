/// Dart port of lipgloss list examples.
///
/// Demonstrates the List component with various styles.
///
/// Run with: dart run example/lipgloss_list.dart
library;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  print('=== Simple List ===\n');
  _simpleList();

  print('\n=== Nested List ===\n');
  _nestedList();

  print('\n=== Grocery List ===\n');
  _groceryList();

  print('\n=== Custom Enumerator List ===\n');
  _customEnumeratorList();
}

/// Simple bullet list.
void _simpleList() {
  final list = BulletList(
    items: ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'],
  );
  print(list.render());
}

/// Nested list with different enumerators.
void _nestedList() {
  final tree = Tree()
      .root('Fruits')
      .enumerator(TreeEnumerator.rounded)
      .child(Tree().root('Citrus').child('Orange').child('Lemon').child('Lime'))
      .child(
        Tree()
            .root('Berries')
            .child('Strawberry')
            .child('Blueberry')
            .child('Raspberry'),
      )
      .child(
        Tree()
            .root('Tropical')
            .child('Mango')
            .child('Papaya')
            .child('Pineapple'),
      );

  print(tree.render());
}

/// Grocery list with checkmarks for purchased items.
void _groceryList() {
  final purchased = {
    'Bananas',
    'Barley',
    'Cashews',
    'Coconut Milk',
    'Dill',
    'Eggs',
    'Fish Cake',
    'Leeks',
    'Papaya',
  };

  final items = [
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
  ];

  final buffer = StringBuffer();

  for (final item in items) {
    final isPurchased = purchased.contains(item);
    final marker = isPurchased ? '✓' : '•';

    final markerStyle = isPurchased
        ? Style().foreground(AnsiColor(10)).margin(0, 1, 0, 0)
        : Style().foreground(AnsiColor(240)).margin(0, 1, 0, 0);

    final itemStyle = isPurchased
        ? Style().foreground(AnsiColor(255)).strikethrough()
        : Style().foreground(AnsiColor(255));

    buffer.writeln('${markerStyle.render(marker)} ${itemStyle.render(item)}');
  }

  print(buffer.toString());
}

/// Custom enumerator list with roman numerals.
void _customEnumeratorList() {
  final items = [
    'Introduction',
    'Getting Started',
    'Basic Concepts',
    'Advanced Topics',
    'Best Practices',
    'Conclusion',
  ];

  final romanNumerals = ['I', 'II', 'III', 'IV', 'V', 'VI'];

  final buffer = StringBuffer();
  final numStyle = Style().foreground(BasicColor('#7D56F4')).bold();
  final textStyle = Style().foreground(BasicColor('#FAFAFA'));

  for (var i = 0; i < items.length; i++) {
    final num = romanNumerals[i].padLeft(4);
    buffer.writeln('${numStyle.render(num)}. ${textStyle.render(items[i])}');
  }

  print(buffer.toString());
}
