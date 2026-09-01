# artisanal `args` Examples

This directory demonstrates all the improvements artisanal adds on top of
`package:args` for building CLI applications.

## Features Demonstrated

| # | Feature | Run Command |
|---|---------|-------------|
| 1 | **Basic command** — `Command<T>` with name, description, `run()` | `dart run example/args/main.dart demo` |
| 2 | **Arguments** — flags, options, positional, multi-value, validation | `dart run example/args/main.dart greet --name Alice --times 3 --formal` |
| 3 | **Subcommands** — nested command hierarchies | `dart run example/args/main.dart project:create MyApp` |
| 4 | **Namespace grouping** — commands like `db:migrate`, `db:seed` grouped together | `dart run example/args/main.dart` (see help) |
| 5 | **Namespace discovery** — typing a namespace shows subcommands | `dart run example/args/main.dart db` |
| 6 | **Styled help** — sectioned, colored help output | `dart run example/args/main.dart --ansi` |
| 7 | **Custom help colors** — `HelpColorScheme` presets | `dart run example/args/main.dart --ansi --help-color dark` |
| 8 | **Styled error blocks** — Symfony-style `<error>` blocks on stderr | `dart run example/args/main.dart unknown-command` |
| 9 | **Shell completion** — `--completion-script` flag | `./build/args-example --completion-script` (compile first) |
| 10 | **Verbosity** — `--quiet`, `--verbose` / `-v`, `-vv`, `-vvv` | `dart run example/args/main.dart demo -v` |
| 11 | **Non-interactive mode** — `--no-interaction` / `-n` | `dart run example/args/main.dart demo -n` |
| 12 | **UnknownCommandFallback** — shim-style delegation | `dart run example/args/main.dart shim:some-tool` |
| 13 | **Console integration** — `io` helpers (info, warn, table, etc.) | `dart run example/args/main.dart demo` |
| 14 | **Injectable I/O** — custom `out`, `err`, `renderer` for testing | See `lib/src/runner/command_runner.dart` |

## How artisanal Improves `package:args`

artisanal's `CommandRunner` and `Command` extend `package:args` with:

- **Global flags** auto-registered: `--ansi`, `--no-ansi`, `--quiet`, `--silent`,
  `--no-interaction`, `--verbose`, `--completion-script`
- **Namespace-aware command grouping** in help output (commands like `db:migrate`
  and `db:seed` appear under a `db` heading)
- **Namespace error recovery** — typing a namespace prefix lists its subcommands
  instead of showing "command not found"
- **`getNamespaces()` / `allCommandsInNamespace()`** — Symfony Console-style
  namespace APIs
- **Styled help output** with `HelpColorScheme` (dark, light, minimal presets)
- **Symfony-style error blocks** — white-on-red `ERROR` block written to stderr
- **Built-in shell tab-completion** via `ShellCompleter`
- **Console/IO integration** — every command gets `io` for info, success, warn,
  error, tables, progress bars, prompts, and more
- **Custom exit codes** (`usageExitCode` defaults to 64)
- **Injectable output streams** for testing
- **`UnknownCommandFallback`** for shim-style wrappers

## Shell Completion Setup

Completion scripts register an executable name, so compile the example before
generating one:

```bash
dart compile exe example/args/main.dart -o build/args-example
eval "$(./build/args-example --completion-script)"
```
