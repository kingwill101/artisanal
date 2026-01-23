/// Random item generator for the fancy list example.
library;

import 'dart:math';

class RandomItem {
  const RandomItem({required this.title, required this.description});

  final String title;
  final String description;
}

class RandomItemGenerator {
  RandomItemGenerator() {
    _reset();
  }

  late final List<String> _titles;
  late final List<String> _descs;
  var _titleIndex = 0;
  var _descIndex = 0;
  final _rand = Random();

  void _reset() {
    _titles = [
      'Artichoke',
      'Baking Flour',
      'Bananas',
      'Barley',
      'Bean Sprouts',
      'Bitter Melon',
      'Black Cod',
      'Blood Orange',
      'Brown Sugar',
      'Cashew Apple',
      'Cashews',
      'Cat Food',
      'Coconut Milk',
      'Cucumber',
      'Curry Paste',
      'Currywurst',
      'Dill',
      'Dragonfruit',
      'Dried Shrimp',
      'Eggs',
      'Fish Cake',
      'Furikake',
      'Garlic',
      'Gherkin',
      'Ginger',
      'Granulated Sugar',
      'Grapefruit',
      'Green Onion',
      'Hazelnuts',
      'Heavy whipping cream',
      'Honey Dew',
      'Horseradish',
      'Jicama',
      'Kohlrabi',
      'Leeks',
      'Lentils',
      'Licorice Root',
      'Meyer Lemons',
      'Milk',
      'Molasses',
      'Muesli',
      'Nectarine',
      'Niagamo Root',
      'Nopal',
      'Nutella',
      'Oat Milk',
      'Oatmeal',
      'Olives',
      'Papaya',
      'Party Gherkin',
      'Peppers',
      'Persian Lemons',
      'Pickle',
      'Pineapple',
      'Plantains',
      'Pocky',
      'Powdered Sugar',
      'Quince',
      'Radish',
      'Ramps',
      'Star Anise',
      'Sweet Potato',
      'Tamarind',
      'Unsalted Butter',
      'Watermelon',
      'Weißwurst',
      'Yams',
      'Yeast',
      'Yuzu',
      'Snow Peas',
    ];

    _descs = [
      'A little weird',
      'Bold flavor',
      'Can’t get enough',
      'Delectable',
      'Expensive',
      'Expired',
      'Exquisite',
      'Fresh',
      'Gimme',
      'In season',
      'Kind of spicy',
      'Looks fresh',
      'Looks good to me',
      'Maybe not',
      'My favorite',
      'Oh my',
      'On sale',
      'Organic',
      'Questionable',
      'Really fresh',
      'Refreshing',
      'Salty',
      'Scrumptious',
      'Delectable',
      'Slightly sweet',
      'Smells great',
      'Tasty',
      'Too ripe',
      'At last',
      'What?',
      'Wow',
      'Yum',
      'Maybe',
      'Sure, why not?',
    ];

    _titles.shuffle(_rand);
    _descs.shuffle(_rand);
  }

  RandomItem next() {
    final item = RandomItem(
      title: _titles[_titleIndex],
      description: _descs[_descIndex],
    );

    _titleIndex = (_titleIndex + 1) % _titles.length;
    _descIndex = (_descIndex + 1) % _descs.length;
    return item;
  }
}
