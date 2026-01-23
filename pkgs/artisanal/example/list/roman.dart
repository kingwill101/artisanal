/// Roman numerals list example - demonstrates styled Roman numeral enumeration.
///
/// This is a port of the Go lipgloss example: examples/list/roman/main.go
library;

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
