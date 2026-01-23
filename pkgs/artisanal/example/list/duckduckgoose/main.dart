import 'package:artisanal/style.dart';

String duckDuckGooseEnumerator(ListItems items, int i) {
  if (items.at(i).value == 'Goose') {
    return 'Honk →';
  }
  return ' ';
}

void main() {
  final enumStyle = Style().foreground(BasicColor('#00d787')).marginRight(1);
  final itemStyle = Style().foreground(AnsiColor(255));

  final l = LipList.create(['Duck', 'Duck', 'Duck', 'Goose', 'Duck'])
      .itemStyle(itemStyle)
      .enumeratorStyle(enumStyle)
      .enumerator(duckDuckGooseEnumerator);

  print(l);
}
