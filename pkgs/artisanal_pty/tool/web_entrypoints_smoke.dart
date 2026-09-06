import 'package:artisanal_pty/artisanal_pty.dart' as core;
import 'package:artisanal_pty/widgets.dart' as widgets;

void main() {
  final terminal = core.VirtualTerminal(width: 1, height: 1);
  widgets.TerminalView(terminal: terminal);
  widgets.PseudoTerminalView(pty: Object());
}
