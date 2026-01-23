/// Makeup tree example - ported from lipgloss/examples/tree/makeup
///
/// Demonstrates a tree with nested items and rounded enumerators.
library;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  final enumeratorStyle = Style().foreground(AnsiColor(63)).marginRight(1);
  final rootStyle = Style().foreground(AnsiColor(35));
  final itemStyle = Style().foreground(AnsiColor(212));

  final t = Tree()
      .root('⁜ Makeup')
      .child('Glossier')
      .child('Fenty Beauty')
      .child(
        Tree()
            .child('Gloss Bomb Universal Lip Luminizer')
            .child('Hot Cheeks Velour Blushlighter'),
      )
      .child('Nyx')
      .child('Mac')
      .child('Milk')
      .enumerator(TreeEnumerator.rounded)
      .enumeratorStyle(enumeratorStyle)
      .indenterStyle(enumeratorStyle)
      .rootStyle(rootStyle)
      .itemStyle(itemStyle);

  print(t.render());
}
