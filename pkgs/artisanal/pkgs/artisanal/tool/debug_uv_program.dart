import 'package:artisanal/src/tui/renderer.dart';
import 'package:artisanal/src/terminal/terminal_base.dart';

void main() {
  final terminal = StringTerminal();
  final renderer = UltravioletTuiRenderer(
    terminal: terminal,
    options: const TuiRendererOptions(altScreen: false),
  );
  renderer.render('Hello UV');
  print(terminal.output.replaceAll('\x1b', '<ESC>'));
}
