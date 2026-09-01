# AGENTS.md — Artisanal Workspace

Guidance for AI agents and contributors working anywhere in this repository.

## What this is

A Dart **workspace** (`resolution: workspace` in the root `pubspec.yaml`)
implementing a full-stack terminal toolkit: CLI I/O, terminal styling, a
Bubble Tea-style TEA runtime, a Flutter-inspired widget framework, and a
high-performance cell-buffer renderer. It is a faithful Dart port of Charm's
Go libraries (Lip Gloss, Bubble Tea, Bubbles), plus renderer, markdown, and
charting layers of its own.

SDK: `>=3.10.0 <4.0.0`.

## Packages and boundaries

| Path | Package | Role |
|---|---|---|
| `pkgs/ultraviolet` | `ultraviolet` 0.5.x | Low-level renderer: cells, buffers, diff-based `UvTerminalRenderer`, typed input decoding, terminal capabilities, image protocols (Kitty/iTerm2/Sixel/half-block). |
| `pkgs/artisanal` | `artisanal` 0.6.x | Core toolkit: `Console` I/O, `Style` system, TEA runtime (`Program`/`Model`/`Msg`/`Cmd`), Bubbles widgets, `CommandRunner`, markdown/glamour, charting, and editor core. |
| `pkgs/artisanal_widgets` | `artisanal_widgets` 0.4.x | Flutter-inspired widget framework (`Widget`/`Element`/`State`, layout, gestures, scroll, navigation, components). Primary package for widget-first apps. |
| `pkgs/flutter_artisanal` | `flutter_artisanal` 0.2.x | Flutter rendering, input bridge, and app shell for UV terminal buffers (Flutter package, `publish_to: none`). |
| `pkgs/artisanal_widgets/example/...` | example packages | `github_cli`, `flutter_cli_port` — app-level consumers. |

**Boundary rules** (see `docs/workspace_architecture.md`):
- Keep renderer concerns (diff, sync output, frame behavior) in `ultraviolet`.
- Keep widget APIs and internals in `artisanal_widgets`; `artisanal` must not
  depend on or re-export the widget package.
- Keep `artisanal` focused on stable primitives and integration, not
  app-specific logic.
- Treat examples and app shells as consumers, not framework core.

Every package has its own `AGENTS.md` with details:
- [`pkgs/ultraviolet/AGENTS.md`](pkgs/ultraviolet/AGENTS.md)
- [`pkgs/artisanal/AGENTS.md`](pkgs/artisanal/AGENTS.md)
- [`pkgs/artisanal_widgets/AGENTS.md`](pkgs/artisanal_widgets/AGENTS.md)

## Commands

Run from the repo root unless noted. Workspace resolution means
`dart pub get` at the root resolves all packages.

```sh
dart pub get             # resolve the whole workspace
dart analyze             # analyze the workspace (lints: package:lints/recommended.yaml)
dart test pkgs/ultraviolet -r compact    # test one package (also flutter test for widgets)
dart run pkgs/artisanal/example/main.dart          # run an example
dart run tool/startup_benchmark.dart --json=build/benchmarks/demo-startup.json
```

`Taskfile.yml` shortcuts (`task <name>`):

| Task | Purpose |
|---|---|
| `analyze` | `dart analyze` on the workspace |
| `test-core` / `test-widgets` / `test-uv` | `dart test` inside the respective package |
| `run-opencode` / `run-uv-layout` | run a specific example |
| `demos-build` | compile example kernels (`.dill`) into `build/demos/` |
| `demos` / `demo NAME=...` | record terminal demos with VHS (`tool/demos/*.tape`) |
| `benchmark-demos` | measure demo startup time |
| `benchmark-uv` | run all ultraviolet microbenchmarks |

Requires the Flutter SDK for `flutter pub get` / `flutter analyze` / widget
tests (CI sets up Flutter stable).

## CI

`.github/workflows/ci.yaml` runs on branches `artisanal`, `main`, `master`:

1. **analyze** job (ubuntu): `flutter pub get` + `flutter analyze` on the whole
   workspace.
2. **test** job, matrix over OS (ubuntu, windows) × package
   (`pkgs/ultraviolet`, `pkgs/artisanal`, `pkgs/artisanal_widgets`):
   - Dart packages on Ubuntu: `dart test pkgs/<pkg> -r compact`.
   - `artisanal_widgets`: `flutter test pkgs/artisanal_widgets -r compact`
     on Ubuntu and with `--concurrency=1` on Windows.
   - Dart packages on Windows: `dart test pkgs/<pkg> --concurrency=1 -r compact`.

Changes must pass on both Ubuntu and Windows where the platform matrix
applies; Windows differs in ANSI/wrap behavior and needs `--concurrency=1`.

## Documentation

`docs/` holds the user documentation — start at `docs/docs_index.md`, and use
`docs/architecture.md` for how the packages fit together and
`docs/workspace_architecture.md` for the boundary rules. Update the relevant
doc when public behavior changes.

## Conventions

- **Entrypoints**: each package exposes `lib/*.dart` barrels that only export;
  implementation lives in `lib/src/...`. The README occasionally documents
  entrypoints that do not exist as separate files (e.g. `runtime.dart`,
  `hosts.dart` in `artisanal`) — trust the actual `lib/*.dart` files.
- **Platform splitting**: io/web/stub splits via conditional imports
  (`if (dart.library.io)` / `if (dart.library.html)`); web and stub variants
  must keep compiling.
- **Doc comments**: public APIs get `///` docs; major types carry
  `{@category ...}` tags and `{@template}` / `{@macro}` blocks.
- **Parity**: this is a port of Charm's Go libraries — where behavior mirrors
  upstream, match it; parity tests pin exact output (see per-package guides).
- **Lints**: `package:lints/recommended.yaml` everywhere.
- **Versioning**: each package is versioned independently with its own
  `CHANGELOG.md`; keep them updated for user-visible changes.

## Gotchas

- Most examples are interactive full-screen TUI apps that need a TTY and quit
  on `q` / `ctrl+c` — don't run them expecting immediate exit.
- `print()` from application code corrupts full-screen TUIs; use
  `ProgramOptions.withCaptureOutput()` or `Cmd.println`.
- Widget framework code belongs in `artisanal_widgets`, renderer internals in
  `ultraviolet` — keep `artisanal` as the integration layer.
- `pkgs/ultraviolet/benchmark/profiles/` contains generated profiling session
  artifacts; don't treat them as source of truth.
- The workspace includes Flutter packages; plain `dart` tooling can analyze
  most packages, but Flutter-dependent work needs the Flutter SDK.
