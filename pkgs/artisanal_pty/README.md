# artisanal_pty

Embeddable terminal emulation for Artisanal applications, backed by
[`pty2`](https://pub.dev/packages/pty2) for local processes.

## Widget applications

```dart
import 'dart:io';

import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_pty/widgets.dart';
import 'package:artisanal_widgets/app.dart';
import 'package:pty2/pty2.dart';

final pty = PseudoTerminal.start(
  Platform.isWindows ? 'pwsh.exe' : 'bash',
  [],
  environment: {'TERM': 'xterm-256color'},
  ackProcessed: true,
  raw: false,
);

try {
  await runWidgetApp(
    ArtisanalApp(
      title: 'Artisanal PTY',
      home: PseudoTerminalView(pty: pty),
    ),
    options: runtime.ProgramOptions().withoutInterruptMsg(),
  );
} finally {
  pty.kill();
}
```

For SSH and other transports, feed output to `VirtualTerminal` and use
`TerminalView(onInput: transport.write)`.

## Plain Artisanal applications

Plain TEA applications can import the terminal model without importing the
widget API:

```dart
import 'package:artisanal_pty/artisanal_pty.dart';

final terminal = VirtualTerminal(width: 80, height: 24);
terminal.write(serverOutput);

// Return this from a Model's view method.
final view = terminal.render();
```

The caller always owns the process or remote transport. Terminate a local PTY
after the application exits.

`PseudoTerminalView` quits the widget application when the child process exits
by default. Set `quitOnExit: false` when the surrounding application should
remain open after the terminal session ends.

Use cooked PTY mode for interactive shells so control characters generate
signals for foreground processes. `PseudoTerminalView` supports alternate
screens, DEC and Kitty keyboard modes, cursor-position reports, and negotiated
SGR/urxvt mouse tracking. Primary-screen output has bounded scrollback with
wheel navigation and an overlay scrollbar; when a child enables mouse tracking,
wheel and pointer events are forwarded to it instead. When `ackProcessed: true`
is enabled, the view acknowledges each rendered output chunk to keep streaming
bounded and responsive.

When embedding the view in a nested split whose inherited constraints are not
the final visible pane, pass explicit `width` and `height` values to
`PseudoTerminalView`. These values control both the emulated screen and the
child PTY's reported geometry.
