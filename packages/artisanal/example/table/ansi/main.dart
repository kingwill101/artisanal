/// ANSI table example - ported from lipgloss/examples/table/ansi
///
/// Demonstrates a simple table with styled cell values.
library;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  final s = Style().foreground(AnsiColor(240));

  final t = Table()
      .row(['Bubble Tea', s.render('Milky')])
      .row(['Milk Tea', s.render('Also milky')])
      .row(['Actual milk', s.render('Milky as well')]);

  print(t.render());
}
