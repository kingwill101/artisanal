# artisanal demo captures

Each tape records one of the more consequential `example/` demos with
[VHS](https://github.com/charmbracelet/vhs) and produces a GIF in
`pkgs/artisanal/assets/`. The tapes run precompiled kernel snapshots from
`build/vhs/artisanal/*.dill` so the recording shows the app instead of the
compiler.

## Regenerate

```sh
task artisanal-demos          # compile dills, then record every .tape here
task artisanal-demos-build    # only compile the kernel snapshots
```

Run from the workspace root. Requires VHS, ffmpeg, and the DejaVu Sans Mono
font (the CI workflow installs it before rendering).

Add a new demo by dropping `<name>.tape` here and listing `<name>` in the
`artisanal-demos-build` task in the root `Taskfile.yml` — the `artisanal-demos`
task picks up every `*.tape` automatically.
