# artisanal_capture

Reusable terminal capture APIs and an Artisanal-based CLI. This package is a
consumer of the terminal toolkit, not a second renderer or widget framework.

- Keep cell-to-pixel rendering in `ultraviolet`; this package owns capture,
  serialization, export workflows, and CLI integration.
- No Chromium, browser automation, Flutter, or native-library dependency is
  required for PNG generation. Use the Ultraviolet raster backend and
  `package:image`.
- Preserve raw cell data and report unsupported content. Do not infer missing
  backgrounds, discard styles, or replace missing glyphs silently.
- `lib/*.dart` files only export; implementations live in `lib/src/`.
- Keep the capture library free of `dart:io`; filesystem/CLI code belongs in
  its own entrypoint.
- Validate untrusted capture files before allocating buffers. Keep dimensions
  and format versions explicit.
- Test pixel values, cell round trips, and real CLI invocations—not just PNG
  file existence.

Run from the workspace root:

```sh
dart analyze pkgs/artisanal_capture
dart test pkgs/artisanal_capture
dart run pkgs/artisanal_capture/bin/artisanal_capture.dart --help
```
