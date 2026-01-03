/// Tree styles example - ported from lipgloss/examples/tree/styles
///
/// Demonstrates different enumerator styles per subtree.
library;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  final purple = Style().foreground(AnsiColor(99)).marginRight(1);
  final pink = Style().foreground(AnsiColor(212)).marginRight(1);

  final t = Tree()
      .children([
        'Glossier',
        "Claire's Boutique",
        Tree()
            .root('Nyx')
            .children(['Lip Gloss', 'Foundation'])
            .enumeratorStyle(pink)
            .indenterStyle(pink),
        'Mac',
        'Milk',
      ])
      .enumeratorStyle(purple)
      .indenterStyle(purple);

  print(t);
}
