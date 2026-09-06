import 'package:artisanal/src/terminal/stty_flow_control.dart';
import 'package:test/test.dart';

void main() {
  // All cases target a missing tty device, so they are deterministic
  // with or without a controlling terminal and never touch real state.
  test('disable is a no-op for a missing tty device', () {
    expect(
      disableTerminalFlowControl(ttyPath: '/nonexistent-tty'),
      isNull,
    );
  });

  test('restore is safe for null, empty, and bogus modes', () {
    expect(() => restoreTerminalFlowControl(null), returnsNormally);
    expect(
      () => restoreTerminalFlowControl('', ttyPath: '/nonexistent-tty'),
      returnsNormally,
    );
    expect(
      () => restoreTerminalFlowControl(
        'bogus-mode',
        ttyPath: '/nonexistent-tty',
      ),
      returnsNormally,
    );
  });
}
