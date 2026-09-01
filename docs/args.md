# Build commands and subcommands

Use Artisanal's command runner when your program has subcommands, options,
generated help, or shell completion. It builds on `package:args` and connects
each command to `Console`, so parsing and user-facing output follow the same
conventions.

## Quick start

```dart
import 'package:artisanal/args.dart';

class ServeCommand extends Command<void> {
  @override
  String get name => 'serve';
  
  @override
  String get description => 'Start the development server.';
  
  @override
  Future<void> run() async {
    io.title('Starting server...');
    io.info('Listening on port 8080');
  }
}

void main(List<String> args) async {
  final runner = CommandRunner(
    CommandRunner.detectExecutableName(),
    'My Application',
  );
  runner.addCommand(ServeCommand());
  await runner.run(args);
}
```

## Shell Completion

Artisanal can automatically generate shell completion scripts for your CLI. This
is enabled by default on every `CommandRunner` — no extra setup required.
You do not need to add a `completion` command, read `COMP_LINE`, or call the
completion parser from your app.

### How It Works

When the shell invokes your executable with `completion -- <args>`, Artisanal
detects the call, computes matching command names, option flags, and allowed
values, prints them to stdout, and exits. Normal runs are completely unaffected.

### Installing

Print the completion script from your compiled or installed binary and source
it in your shell rc file:

```bash
# One-shot evaluation (bash / zsh)
eval "$(github_cli --completion-script)"

# Persistent: append to your rc file
github_cli --completion-script >> ~/.bashrc   # bash
github_cli --completion-script >> ~/.zshrc    # zsh
```

Generate the script from the final executable name. A `dart run ...`
invocation contains spaces and is not a shell command name that the completion
script can register:

```bash
dart compile exe bin/myapp.dart -o build/myapp
export PATH="$PWD/build:$PATH"
eval "$(myapp --completion-script)"
```

Keep the executable in a directory on `PATH` in future shell sessions (or
install it into one), because the generated wrapper invokes `myapp` by name.
For Zsh, initialize its completion system with
`autoload -Uz compinit && compinit` before sourcing the generated script if
your shell configuration does not already do so.

After adding to your rc file, restart your shell or `source ~/.bashrc` /
`source ~/.zshrc`.

Most apps never call completion APIs directly. For installers or release
tooling, `ShellCompleter.generate('myapp')` can produce the same script without
constructing a runner.

### Opting Out

Disable completion per runner if you need to:

```dart
final runner = CommandRunner('myapp', 'My Application', enableShellCompletion: false);
```

### Unknown Command Fallbacks

Shim-style CLIs sometimes need to delegate unknown commands to another
executable. Use `unknownCommandFallback` for that case instead of pre-parsing
the argument list before `CommandRunner.run`.

```dart
final runner = CommandRunner<void>(
  'flutter-cli',
  'Flutter CLI shim',
  unknownCommandFallback: (args) async {
    await runExternalFlutter(args);
  },
);
```

The fallback runs only after the runner has handled built-in completion
requests, so `completion -- ...` and `--completion-script` remain automatic.

### What Gets Completed

The completer walks your full command tree:

- **Top-level commands** — names and aliases
- **Subcommands** — recursively through nested `addSubcommand` chains
- **Option names** — `--flag` and `--no-flag` for negatable options
- **Allowed values** — completion lists from `argParser.addOption(..., allowed: [...])`

All of the above respect the same `namespaceSeparator` grouping your help already uses.

### Advanced Programmatic Access

```dart
import 'package:artisanal/args.dart';

final runner = CommandRunner(
  CommandRunner.detectExecutableName(),
  'My Application',
);
runner.addCommand(ServeCommand());

// Lazy-initialized completer bound to this runner's arg tree.
// Most applications do not need to call this directly.
final completer = runner.shellCompleter;

// Generate a standalone completion script
final script = runner.shellCompletionScript;
```

`ShellCompleter` is also re-exported directly so you can call
`ShellCompleter.generate('myapp')` or `ShellCompleter.generateAll(['myapp', 'myapp-dev'])`
without a runner instance.

---

## CommandRunner

### Creating a Runner

```dart
void main(List<String> args) async {
  final runner = CommandRunner(
    CommandRunner.detectExecutableName(),
    'My CLI application',
  )
    ..addCommand(ServeCommand())
    ..addCommand(DbCommand())
    ..addCommand(DbMigrateCommand());

  await runner.run(args);
}
```

### Global Flags

The runner automatically adds these global flags:

| Flag | Description |
|------|-------------|
| `--help`, `-h` | Display help information |
| `--ansi` / `--no-ansi` | Force enable/disable ANSI colors |
| `--quiet`, `-q` / `--silent` | Suppress all output |
| `--no-interaction`, `-n` | Disable interactive prompts |
| `--verbose`, `-v`, `-vv`, `-vvv` | Increase verbosity (verbose, very verbose, debug) |
| `--completion-script` | Print a shell completion script to stdout |

### Auto-detecting the Executable Name

Pass `CommandRunner.detectExecutableName()` as the executable name to have the
runner automatically pick up the correct name from the running script:

```dart
final runner = CommandRunner(
  CommandRunner.detectExecutableName(),
  'My CLI application',
);
```

When run as a compiled binary, the usage shows the binary's file name:

```bash
$ ./artisan --help
Usage: artisan <command> [arguments]
...
```

When run via `dart run`, the usage includes the script path:

```bash
$ dart run bin/myapp.dart --help
Usage: dart run bin/myapp.dart <command> [arguments]
...
```

You can always pass an explicit name if you prefer a fixed value:

```dart
// Always shows "myapp" regardless of how it's executed
final runner = CommandRunner('myapp', 'My CLI');
```

### Constructor and I/O Hooks

`CommandRunner` supports dependency injection for tests and hosts:

```dart
final runner = CommandRunner(
  'mycli',
  'My CLI',
  ansi: false,
  namespaceSeparator: ':',
  usageExitCode: 64,
  out: (line) => output.add(line),
  err: (line) => errors.add(line),
  outRaw: (text) => rawOut.add(text),
  errRaw: (text) => rawErr.add(text),
  readLine: () => 'input',
  setExitCode: (code) => exitCode = code,
  usageLineLength: 80,
);
```

Important constructor options:

- `namespaceSeparator`: custom command namespace separator (default `:`).
- `usageExitCode`: exit code used for argument/usage errors (default `64`).
- `ansi`: force or disable ANSI behavior globally (`null` = auto-detect).
- `renderer`: optional renderer override (`StringRenderer`, `TerminalRenderer`, etc.).
- `out`, `err`, `outRaw`, `errRaw`: output redirection hooks.
- `readLine`: custom stdin reader for prompts.
- `setExitCode`: custom exit-code sink.

#### Argument / Option Accessors

Artisanal's `Command` provides Laravel-style convenience helpers so you don't
need to reach for raw `argResults!` every time:

```dart
class GreetCommand extends Command<void> {
  GreetCommand() {
    argParser.addOption('name', abbr: 'n', help: 'Who to greet.');
    argParser.addFlag('shout', help: 'SHOUT the greeting.');
  }

  @override String get name => 'greet';
  @override String get description => 'Greet someone.';

  @override
  void run() {
    // --name value (or default)
    final name = option('name') as String? ?? 'World';

    // --shout flag (bool)
    final shout = option('shout') as bool;

    // First positional argument
    final message = argument(0);

    // All positional arguments
    for (final arg in arguments) { ... }

    // Check if --name was explicitly provided
    if (hasOption('name')) { ... }

    io.success('Hello, $name!');
  }
}
```

#### Available Helpers

| Method | Returns | Description |
|--------|---------|-------------|
| `option(name)` | `Object?` | Value of a named option/flag (e.g., `--name`, `--force`) |
| `hasOption(name)` | `bool` | Whether the option was explicitly provided on the command line |
| `argument(index)` | `String?` | Positional argument at `index` (0-based), or `null` if not provided |
| `arguments` | `List<String>` | All positional arguments |
| `argumentCount` | `int` | Number of positional arguments |

---

## Command Namespaces

Commands can be grouped using the `:` separator:

```dart
class DbMigrateCommand extends Command<void> {
  @override
  String get name => 'db:migrate';
  
  @override
  String get description => 'Run database migrations';
  
  @override
  void run() {
    io.task('Running migrations', run: () async {
      // ...
      return TaskResult.success;
    });
  }
}

class DbSeedCommand extends Command<void> {
  @override
  String get name => 'db:seed';
  
  @override
  String get description => 'Seed the database';
  
  @override
  void run() { ... }
}

final runner = CommandRunner('myapp', 'My Application')
  ..addCommand(DbMigrateCommand())
  ..addCommand(DbSeedCommand());
```

Run with:
```bash
dart run bin/myapp.dart db:migrate
```

### Namespace Discovery (Symfony-style)

When a user types a namespace prefix (e.g., `db` where commands like `db:migrate`,
`db:seed` exist), the runner displays the subcommands in that namespace instead of
a "command not found" error:

```bash
$ dart run bin/myapp.dart db
Available commands for the "db" namespace:
db
  db:migrate   Run database migrations
  db:seed      Seed the database

Run "myapp db:<subcommand> --help" for more information about a command.
```

This works for nested namespaces too (e.g., `cache:user` lists `cache:user:list`,
`cache:user:evict`).

Like Symfony Console, namespace-only invocations exit with code **1** (no command
was actually executed).

### Namespace APIs

The runner exposes Symfony Console-style APIs for programmatic namespace
inspection:

```dart
// Get all unique namespace prefixes
final namespaces = runner.getNamespaces();
// -> ['cache', 'cache:user', 'db', 'help', 'project']

// Get all commands within a namespace
final dbCommands = runner.allCommandsInNamespace('db');
// -> {'db:migrate': ..., 'db:seed': ...}
```

- `getNamespaces()` -- equivalent to Symfony's `Application::getNamespaces()`
- `allCommandsInNamespace(name)` -- equivalent to Symfony's `Application::all($namespace)`

### Help Output Grouping

Commands sharing a namespace prefix are automatically grouped under a heading
in the help output:

### Help Output

The runner generates beautiful, styled help output with namespaces grouped:

```
My Application

Usage: myapp <command> [arguments]

Options:
  -h, --help              Print this usage information.
      --[no-]ansi         Force (or disable with --no-ansi) ANSI output.
  -q, --quiet             Do not output any message.
      --silent            Alias for --quiet.
  -n, --no-interaction    Do not ask any interactive question.
  -v, --verbose           Increase verbosity of messages:
                          1 for verbose, 2 for very verbose, 3 for debug.

Available commands:
  serve     Start the development server

db
  db:migrate   Run database migrations
  db:seed      Seed the database

cache
  cache:clear      Clear the cache
  cache:user:list  List cached users

Run "myapp <command> --help" for more information about a command.
```

Commands without a namespace prefix appear first (e.g., `serve`), followed by
grouped commands under their namespace headings (`db`, `cache`).

### HelpColorScheme

`HelpColorScheme` controls the colors applied to different elements of help
output. Pass it as the `helpColorScheme` argument to `CommandRunner`:

```dart
final runner = CommandRunner(
  'myapp',
  'My Application',
  helpColorScheme: HelpColorScheme.dark(),
);
```

#### Built-in Presets

| Preset | Description |
|--------|-------------|
| `HelpColorScheme.default_` | Default scheme (same amber/green palette, auto-adaptive) |
| `HelpColorScheme.dark()` | Optimized for dark terminals (amber headings, green commands) |
| `HelpColorScheme.light()` | Optimized for light terminals (darker shades) |
| `HelpColorScheme.minimal(color)` | Single foreground color for all elements |

#### Customizing Colors

Each field accepts any Artisanal `Color` (`AdaptiveColor`, `BasicColor`,
`AnsiColor`, etc.). Use `AdaptiveColor` to supply different values for light
and dark backgrounds:

```dart
final runner = CommandRunner(
  'myapp',
  'My Application',
  helpColorScheme: HelpColorScheme(
    heading: AdaptiveColor(
      light: BasicColor('#7c3aed'),
      dark: BasicColor('#a78bfa'),
    ),
    command: AdaptiveColor(
      light: BasicColor('#0369a1'),
      dark: BasicColor('#38bdf8'),
    ),
    option: AdaptiveColor(
      light: BasicColor('#047857'),
      dark: BasicColor('#34d399'),
    ),
    error: AdaptiveColor(
      light: BasicColor('#b91c1c'),
      dark: BasicColor('#f87171'),
    ),
  ),
);
```

Use `copyWith` to extend an existing scheme without respecifying every field:

```dart
final myScheme = HelpColorScheme.dark().copyWith(
  heading: const BasicColor('#ff9900'),
  namespace: const BasicColor('#cc77ff'),
);
```

#### Color Fields

| Field | Applies to |
|-------|-----------|
| `heading` | Section labels: `Description:`, `Usage:`, `Options:`, `Available commands:` |
| `command` | Command names in the listing |
| `option` | Option flags: `--port`, `-p` |
| `description` | Option description text (defaults to no extra color) |
| `error` | Error prefix in usage exceptions |
| `emphasis` | Quoted items like `"myapp <command> --help"` |
| `namespace` | Namespace prefixes in grouped command listings (e.g., `db:`) |

### Command Listing Utilities

```dart
import 'package:artisanal/args.dart';

void main() {
  final entries = [
    CommandListingEntry(name: 'serve', description: 'Start the server'),
    CommandListingEntry(name: 'db:migrate', description: 'Run migrations'),
  ];

  final output = formatCommandListing(
    entries,
    namespaceSeparator: ':',
  );

  print(indentBlock(output, 2));
}
```

---

## Command

### Creating Commands

```dart
class BuildCommand extends Command<void> {
  @override
  String get name => 'build';
  
  @override
  String get description => 'Build the application';
  
  @override
  String get summary => 'Compiles the application to executable code';
  
  BuildCommand() {
    argParser.addFlag(
      'watch', 
      abbr: 'w', 
      help: 'Watch for changes and rebuild',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory',
      defaultsTo: 'build',
    );
  }
  
  @override
  Future<void> run() async {
    final watch = option('watch') as bool;
    final output = option('output') as String? ?? 'build';
    
    io.title('Building application');
    io.text('Output directory: $output');
    
    if (watch) {
      io.info('Watching for changes...');
    } else {
      io.task('Compiling', run: () async {
        // ...
        return TaskResult.success;
      });
    }
  }
}
```

### Accessing Console

Every command has access to the `io` property for console output:

```dart
@override
void run() {
  io.title('My Command');
  io.info('This is an info message');
  io.success('Operation completed');
  io.warn('This is a warning');
  io.error('An error occurred');
  
  // Advanced features
  io.table([
    ['Name', 'Value'],
    ['Version', '1.0.0'],
    ['Status', 'Active'],
  ]);
  
  final confirmed = io.confirm('Are you sure?');
  if (confirmed) {
    io.task('Processing', run: () async {
      // ...
      return TaskResult.success;
    });
  }
}
```

`Command` also exposes convenience forwarding methods (`line`, `info`, `comment`, `question`,
`warn`, `error`, `alert`) when you only need lightweight formatting without touching
the full `io` API.

### Command Help

Commands can override `formatUsage()` to customize their help output:

```dart
@override
String formatUsage({bool includeDescription = true}) {
  final buffer = StringBuffer();
  
  buffer.writeln('Custom help header');
  buffer.writeln();
  
  buffer.writeln(super.formatUsage(includeDescription: includeDescription));
  
  return buffer.toString();
}
```

---

## Command Structure

### Command Lifecycle

```dart
class MyCommand extends Command<void> {
  @override
  String get name => 'my-command';
  
  @override
  String get description => 'My command description';
  
  @override
  void run() {
    // Main command logic here
  }
}
```

### Command Aliases

```dart
class ServeCommand extends Command<void> {
  ServeCommand() : super(aliases: ['server', 's']);
  
  @override
  String get name => 'serve';
  
  @override
  String get description => 'Start the server';
  
  @override
  void run() {
    io.title('Starting server...');
  }
}
```

Now you can run:
```bash
dart run bin/myapp.dart serve
dart run bin/myapp.dart server
dart run bin/myapp.dart s
```

---

## Argument Parsing

### Basic Arguments

```dart
class DeployCommand extends Command<void> {
  DeployCommand() {
    argParser.addFlag('dry-run', help: 'Simulate deployment');
    argParser.addOption('environment', 
      abbr: 'e',
      help: 'Target environment',
      allowed: ['dev', 'staging', 'prod'],
      defaultsTo: 'dev',
    );
    argParser.addMultiOption('tag', 
      help: 'Tags to apply',
    );
  }
  
  @override
  void run() {
    final dryRun = option('dry-run') as bool;
    final environment = option('environment') as String;
    final tags = option('tag') as List<String>? ?? [];
    
    io.info('Deploying to $environment${dryRun ? ' (dry run)' : ''}');
    if (tags.isNotEmpty) {
      io.text('Tags: ${tags.join(', ')}');
    }
  }
}
```

### Positional Arguments

`package:args` stores trailing positional values in `argResults.rest`. Use the
convenience `argument(index)` and `arguments` helpers:

```dart
class HelloCommand extends Command<void> {
  HelloCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Name to greet',
    );
  }
  
  @override
  void run() {
    // Named option value
    final name = option('name') as String? ?? 'World';
    // First positional argument (or null if not provided)
    final greeting = argument(0);
    io.success('Hello, $name!');
  }
}
```

### Checking if an Option Was Explicitly Provided

Use `hasOption()` to distinguish between "not provided" and "provided with
default value":

```dart
if (hasOption('environment')) {
  io.info('Environment explicitly set to ${option('environment')}');
} else {
  io.info('Using default environment');
}
```

## Re-exported Args Types

```dart
import 'package:artisanal/args.dart';

void main() {
  final parser = ArgParser()..addFlag('verbose', abbr: 'v');
  final results = parser.parse(['-v']);
  final isVerbose = results['verbose'] as bool;

  if (!isVerbose) {
    throw UsageException('Missing -v', parser.usage);
  }
}
```

---

## Error Handling

Artisanal provides friendly error handling without stack traces:

```dart
try {
  await runner.run(args);
} catch (e) {
  io.error('Unhandled error: $e');
  exit(1);
}
```

### Symfony-style Error Blocks

The runner catches `UsageException` and formats errors as styled blocks
(written to stderr), matching Symfony Console / Laravel Artisan conventions:

```bash
$ dart run bin/myapp.dart unknown-command

  Could not find a command named "unknown-command".  

$ echo $?
64
```

- Errors go to **stderr** (matching Symfony's `$output->getErrorOutput()`)
- In ANSI mode, the message is rendered with white foreground on red background
- In ASCII mode (`--no-ansi`), the message is padded with spaces
- The block is surrounded by blank lines, matching Symfony's `formatBlock(..., large: true)`
- Exit code is `usageExitCode` (default **64**)

### Usage Errors

For argument-level errors (e.g., missing required options, invalid values),
the runner prints the error block to stderr without a stack trace:

```bash
$ dart run bin/myapp.dart serve --invalid-option

  Could not find an option named "invalid-option".  
```

### Throwing Usage Errors from Commands

Commands can throw structured errors with the `usageException()` helper:

```dart
@override
void run() {
  final port = option('port') as String?;
  if (port != null && int.tryParse(port) == null) {
    usageException('The --port option must be a number.');
  }
  // ...
}
```

This produces the same styled error block output.

---

## Integration with Console

Commands automatically get access to the [Console](console.md) through the `io` property:

```dart
@override
void run() {
  // Text output
  io.title('My Command');
  io.text('This is some text');
  
  // Status messages
  io.info('Processing files...');
  io.success('Operation completed');
  io.warn('This is a warning');
  io.error('An error occurred');
  
  // Interactive prompts
  final name = io.ask('What is your name?');
  final confirmed = io.confirm('Are you sure?');
  
  // Tasks
  final result = await io.task('Processing', run: () async {
    await Future.delayed(Duration(seconds: 2));
    return TaskResult.success;
  });
  
  // Tables
  io.table([
    ['Name', 'Email'],
    ['John Doe', 'john@example.com'],
    ['Jane Smith', 'jane@example.com'],
  ]);
}
```

---

## Advanced Usage

### Custom Renderer

```dart
final runner = CommandRunner(
  'myapp',
  'My Application',
  renderer: StringRenderer(colorProfile: ColorProfile.ansi256),
);
```

### Custom I/O Callbacks

```dart
final runner = CommandRunner(
  'myapp',
  'My Application',
  out: (line) => print('[OUT] $line'),
  err: (line) => print('[ERR] $line'),
  readLine: () => 'user input',
);
```

### Testing

For testing, you can inject custom I/O callbacks:

```dart
void main() async {
  final output = <String>[];
  final runner = CommandRunner(
    'myapp',
    'My Application',
    out: (line) => output.add(line),
    err: (line) => output.add(line),
    readLine: () => 'yes',
  );
  
  runner.addCommand(MyCommand());
  await runner.run(['my-command']);
  
  print(output.join('\n'));
}
```

---

## Related Documentation

- [docs_index.md](docs_index.md) - Full documentation index
- [console.md](console.md) - Console I/O operations and styling
- [style.md](style.md) - Text styling and formatting
- [tui.md](tui.md) - Interactive terminal applications
- [architecture.md](architecture.md) - System architecture
