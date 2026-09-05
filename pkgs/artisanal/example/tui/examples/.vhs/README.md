# tui/examples demo captures

Each tape records one of the Bubble Tea-port examples in
[`../`](../README.md) with [VHS](https://github.com/charmbracelet/vhs) and
produces a GIF next to its example (`../<name>/<name>.gif`, embedded by the
per-example README). The tapes run precompiled kernel snapshots from
`build/vhs/tui/*.dill` so the recording shows the app instead of the
compiler.

## Regenerate

```sh
task tui-demos          # compile dills, then record every .tape here
task tui-demos-build    # only compile the kernel snapshots
```

Run from the workspace root. Requires VHS, ffmpeg, and the DejaVu Sans Mono
font.

Add a new demo by dropping `<name>.tape` here — the `tui-demos` task picks
up every `*.tape` automatically, and `tui-demos-build` compiles every
`../*/main.dart` (no per-example listing needed).
