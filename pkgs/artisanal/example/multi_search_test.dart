import 'package:artisanal/artisanal.dart';

void main() async {
  final io = Console();

  final fruits = [
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Honeydew',
    'Kiwi',
    'Lemon',
    'Mango',
    'Nectarine',
    'Orange',
    'Papaya',
    'Quince',
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Ugli fruit',
    'Vanilla bean',
    'Watermelon',
  ];

  final selected = await io.multiSearch(
    'Select your favorite fruits:',
    items: fruits,
  );

  if (selected.isEmpty) {
    io.warn('No fruits selected.');
  } else {
    io.success('You selected: ${selected.join(', ')}');
  }
}
