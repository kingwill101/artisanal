# Inline TUI Examples

These examples run on the primary terminal screen instead of the alternate
screen. They are intended for CLI workflows where normal terminal scrollback
must remain useful while a small live UI stays pinned.

See `docs/INLINE_TUI.md` for the authoring guide and `docs/TUI.md` for the
runtime options reference.

Run from `pkgs/artisanal`:

```bash
dart run example/tui/examples/inline/bottom_status.dart
dart run example/tui/examples/inline/pinned_build_dashboard.dart
dart run example/tui/examples/inline/top_panel.dart
```

## Examples

- `bottom_status.dart` renders a bottom status bar and continuously prints log
  lines above it with `Cmd.println`.
- `pinned_build_dashboard.dart` simulates a build/run dashboard with progress,
  phase, device status, and streaming logs above the pinned panel.
- `top_panel.dart` demonstrates a top-anchored inline panel with normal output
  below it.

For bottom-pinned examples, native terminal scrollback should continue to work:
logs flow above the UI and the dashboard stays fixed in the bottom rows.
