import 'package:artisanal/style.dart';

void main() {
  final enumeratorStyle = Style().foreground(AnsiColor(99)).marginRight(1);
  final itemStyle = Style().foreground(AnsiColor(255)).marginRight(1);

  final l =
      LipList.create(['Glossier', "Claire's Boutique", 'Nyx', 'Mac', 'Milk'])
          .enumerator(ListEnumerators.roman)
          .enumeratorStyle(enumeratorStyle)
          .itemStyle(itemStyle);

  print(l);
}
