# Color Profile Detection

Artisanal detects terminal color capabilities and can downsample ANSI output to match the detected profile.

## Quick Start

```dart
import 'dart:io';
import 'package:artisanal/src/colorprofile/detect.dart' as cp_detect;
import 'package:artisanal/src/colorprofile/convert.dart' as cp_conv;
import 'package:artisanal/src/colorprofile/downsample.dart' as cp_down;
import 'package:artisanal/src/colorprofile/profile.dart' as cp;

void main() {
  final profile = cp_detect.detect(
    isTty: stdout.hasTerminal,
    env: Platform.environment,
    isWindows: Platform.isWindows,
  );
  print('profile: $profile');

  final red = cp_conv.sgrColor(
    profile: profile,
    rgb: const cp_conv.Rgb(255, 0, 0),
  );
  final text = '${red}Hello\x1B[0m';
  print('styled: ${cp_down.downsampleSgr(text, profile)}');

  final ascii = cp_down.downsampleSgr(text, cp.Profile.ascii);
  print('ascii: $ascii');
}
```

## Environment Variables

Detection respects common env vars:

- `NO_COLOR`
- `CLICOLOR` / `CLICOLOR_FORCE`
- `COLORTERM`
- `TERM`

## Gotchas

- `downsampleSgr` only processes SGR sequences; other escapes are untouched.
- `Profile.ascii` strips color parameters but preserves bold/underline.
- `NO_COLOR` only reduces output when stdout is a TTY.

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [STYLE.md](STYLE.md)
- [RENDERER.md](RENDERER.md)
