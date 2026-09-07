# artisanal_widgets demo captures

Each tape records one of the more consequential `example/` demos with
[VHS](https://github.com/charmbracelet/vhs) and produces a GIF in
`pkgs/artisanal_widgets/assets/`. The tapes run precompiled kernel snapshots
from `build/vhs/widgets/*.dill` so the recording shows the app instead of the
compiler.

## Regenerate

```sh
task widgets-demos          # compile dills, then record every .tape here
task widgets-demos-build    # only compile the kernel snapshots
```

Run from the workspace root. Requires VHS, ffmpeg, and the DejaVu Sans Mono
font (the CI workflow installs it before rendering).

Add a new demo by dropping `<name>.tape` here — the `widgets-demos`
task picks up every `*.tape` automatically, and `widgets-demos-build`
compiles every `example/*/main.dart` (no per-example listing needed).

Omitted: `browser_host` (needs a real browser). `github_cli` /
`flutter_cli_port` are separate app packages with their own entrypoints,
not single-file demos.
