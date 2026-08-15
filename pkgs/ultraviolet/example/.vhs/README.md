# Ultraviolet example recordings (VHS tapes)

Every `pkgs/ultraviolet/example/*.dart` example has a matching VHS tape here
that records it into a GIF under `pkgs/ultraviolet/assets/`, so the README
demo captures are reproducible instead of hand-generated.

Requires [VHS](https://github.com/charmbracelet/vhs) and `ffmpeg` on your
`PATH`. The tapes run from the **repo root** (all paths inside the tapes are
repo-root relative), like the existing `tool/demos/*.tape` recordings.

## Record everything

```sh
task uv-demos
```

This compiles every example once into `build/vhs/uv/*.dill` (so recordings
start fast instead of waiting on the Dart compiler each time), then runs VHS
on every tape. GIFs land in `pkgs/ultraviolet/assets/<example>.gif`.

## Record one example

```sh
task uv-demos-build
vhs pkgs/ultraviolet/example/.vhs/raycast_maze.tape
```

## Manually

```sh
mkdir -p build/vhs/uv pkgs/ultraviolet/assets
for example in pkgs/ultraviolet/example/*.dart; do
  name="$(basename "$example" .dart)"
  dart compile kernel "$example" -o "build/vhs/uv/$name.dill"
done
for tape in pkgs/ultraviolet/example/.vhs/*.tape; do
  vhs "$tape"
done
```

## Notes

- The recordings use DejaVu Sans Mono with zero letter spacing (the same
  settings as `tool/demos/`), and the `Catppuccin Mocha` theme.
- `web_canvas/` is a browser-only example and has no tape.
- Examples with no on-screen text (`space`, `splits`, `tv`) use a timed wait
  instead of `Wait+Screen`.
- `panic` exits on its own (it intentionally throws after a countdown); the
  other tapes send `q` (or the example's own quit key) to exit.
