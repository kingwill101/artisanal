# Adapt colors to the terminal

Not every terminal can display the same colors. Color-profile detection lets
you choose an appropriate palette and downsample ANSI output instead of showing
broken or unreadable styling.

## Quick Start

```dart
import 'dart:io';
import 'package:ultraviolet/colorprofile.dart' as cp;

void main() {
  final profile = cp.detect(
    isTty: stdout.hasTerminal,
    env: Platform.environment,
    isWindows: Platform.isWindows,
  );
  print('profile: $profile');

  final red = cp.sgrColor(
    profile: profile,
    rgb: const cp.Rgb(255, 0, 0),
  );
  final text = '${red}Hello\x1B[0m';
  print('styled: ${cp.downsampleSgr(text, profile)}');

  final ascii = cp.downsampleSgr(text, cp.Profile.ascii);
  print('ascii: $ascii');
}
```

## Environment Variables

Detection respects common env vars:

- `NO_COLOR`
- `CLICOLOR` / `CLICOLOR_FORCE`
- `COLORTERM`
- `TERM`

## Things to keep in mind

- `downsampleSgr` only processes SGR sequences; other escapes are untouched.
- `Profile.ascii` strips color parameters but preserves bold/underline.
- `NO_COLOR` only reduces output when stdout is a TTY.

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [style.md](style.md)
- [renderer.md](renderer.md)
