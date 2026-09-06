# artisanal_pty

Embeddable terminal emulation for Artisanal applications, backed by
[`pty2`](https://pub.dev/packages/pty2) for local processes.

## Widget applications

```dart
import 'dart:io';

import 'package:artisanal_pty/widgets.dart';
import 'package:artisanal_widgets/app.dart';
import 'package:pty2/pty2.dart';

final pty = PseudoTerminal.start(
  Platform.isWindows ? 'pwsh.exe' : 'bash',
  [],
  environment: {'TERM': 'xterm-256color'},
);

try {
  await runWidgetApp(PseudoTerminalView(pty: pty));
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
