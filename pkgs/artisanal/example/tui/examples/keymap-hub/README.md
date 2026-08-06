# KeymapHub

Surface-first shortcut layers inspired by OpenTUI `@opentui/keymap`.

```bash
# from pkgs/artisanal
dart run example/tui/examples/keymap-hub/main.dart
```

## What it shows

| Key | Behavior |
|-----|----------|
| `ctrl+x` then `b` / `m` / `t` | Leader sequence → `KeymapActionMsg` |
| `ctrl+p` | Single-key action (command palette demo) |
| `?` | Shortcuts list for the **active** surface |
| `d` | Push an **exclusive** dialog surface |
| `y` / `n` | Dialog confirm/cancel (session chords blocked) |
| `esc` | Close help, then dialog |
| `q` | Quit |

Surfaces are pushed on a [KeymapHub] installed as the program interceptor.
Unclaimed keys under an exclusive dialog do not fall through to the session map.

See also: [docs/KEYMAP_SURFACE_PLAN.md](../../../../../docs/KEYMAP_SURFACE_PLAN.md).
