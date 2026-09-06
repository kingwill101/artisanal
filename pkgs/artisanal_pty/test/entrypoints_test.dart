import 'package:artisanal_pty/artisanal_pty.dart' as core;
import 'package:artisanal_pty/widgets.dart' as widgets;
import 'package:test/test.dart';

void main() {
  test('core entrypoint supports plain Artisanal applications', () {
    final terminal = core.VirtualTerminal(width: 3, height: 1);
    terminal.writeText('pty');
    expect(terminal.render(), 'pty');
  });

  test('widget entrypoint exposes terminal widgets', () {
    final terminal = widgets.VirtualTerminal(width: 3, height: 1);
    expect(widgets.TerminalView(terminal: terminal), isNotNull);
  });
}
