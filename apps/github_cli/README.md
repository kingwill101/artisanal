# GitHub CLI

A standalone GitHub terminal dashboard built with Artisanal. This application
lives in the Artisanal Dart workspace and uses its local toolkit packages.

## Run

Install the Flutter SDK (required to resolve the whole workspace) and the
[GitHub CLI](https://cli.github.com/), then authenticate with `gh auth login`.

From the repository root:

```sh
flutter pub get
dart run apps/github_cli/bin/github_cli.dart --help
dart run apps/github_cli/bin/github_cli.dart owner/repo
```

Or run from this app directory:

```sh
dart run bin/github_cli.dart owner/repo
```

The dashboard requires an interactive terminal. It also accepts an owner or
organization instead of a repository; use `--help` for available options.

## Development

From the repository root:

```sh
dart analyze apps/github_cli
dart test apps/github_cli
```

The offline SIMD issue bench uses the attributed issue-body fixture in
`artisanal_capture`. It tests the actual `GithubMarkdownBody` widget, including
comment visibility, scrolling, and F12 over linked tables:

```sh
dart test apps/github_cli/test/markdown_issue_bench_test.dart
```

`lib/` contains app logic, `test/` the app tests, `web/` the browser entrypoint
and reproduction pages, and `tool/` debugging utilities. Replay scenarios live
in `scenarios/` and can be resolved by name from the app or repository root.
