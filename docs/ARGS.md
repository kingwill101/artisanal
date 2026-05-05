# Args Wrapper (Command Runner)

The Artisanal Args library provides a polished command-line interface framework built on top of `package:args`. It extends the base functionality with Lip Gloss styling, automatic help generation, verbosity management, and seamless Console integration.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [CommandRunner](#commandrunner)
  - [Creating a Runner](#creating-a-runner)
  - [Constructor and I/O Hooks](#constructor-and-io-hooks)
  - [Global Flags](#global-flags)
  - [Command Namespaces](#command-namespaces)
  - [Help Output](#help-output)
- [Command](#command)
  - [Creating Commands](#creating-commands)
  - [Accessing Console](#accessing-console)
  - [Command Help](#command-help)
- [Command Structure](#command-structure)
- [Argument Parsing](#argument-parsing)
- [Error Handling](#error-handling)
- [Integration with Console](#integration-with-console)
- [Advanced Usage](#advanced-usage)
- [Related Documentation](#related-documentation)

---

## Overview

Artisanal's Args library provides:

- **Beautiful Help Output**: Automatically styled with Lip Gloss colors
- **Command Namespacing**: Group commands with `:` separators (e.g., `db:migrate`, `ui:build`)
- **Verbosity Management**: `-v`, `-vv`, and `-vvv` flags plus quiet/silent modes
- **Interactive Control**: `--no-interaction` flag for non-interactive mode
- **ANSI Control**: `--ansi`/`--no-ansi` flags to force color output
- **Seamless Console Integration**: Each command gets automatic access to the [Console](CONSOLE.md)
- **Deterministic Testing Hooks**: Injectable output, input, and exit-code callbacks

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
  final runner = CommandRunner('myapp', 'My Application');
  runner.addCommand(ServeCommand());
  await runner.run(args);
}
```

---

## Quick Start

### Simple Command

```dart
import 'package:artisanal/args.dart';

class HelloCommand extends Command<void> {
  @override
  String get name => 'hello';
  
  @override
  String get description => 'Say hello to someone';
  
  HelloCommand() {
    argParser.addOption('name', abbr: 'n', help: 'Name to greet');
  }
  
  @override
  void run() {
    final name = argResults!['name'] as String? ?? 'World';
    io.success('Hello, $name!');
  }
}

void main(List<String> args) async {
  final runner = CommandRunner('greet', 'A friendly CLI');
  runner.addCommand(HelloCommand());
  await runner.run(args);
}
```

Run with:
```bash
dart run bin/greet.dart hello --name John
```

Output:
```
Hello, John!
```

---

## CommandRunner

### Creating a Runner

```dart
void main(List<String> args) async {
  final runner = CommandRunner('mycli', 'My CLI application')
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

### Command Namespaces

Commands can be grouped using the `:` separator:

```dart
class DbCommand extends Command<void> {
  @override
  String get name => 'db';
  
  @override
  String get description => 'Database operations';
  
  DbCommand() {
    addSubcommand(DbMigrateCommand());
    addSubcommand(DbSeedCommand());
  }
  
  @override
  void run() {
    printUsage();
  }
}

class DbMigrateCommand extends Command<void> {
  @override
  String get name => 'migrate';
  
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
```

Run with:
```bash
dart run bin/myapp.dart db:migrate
```

### Help Output

The runner generates beautiful, styled help output:

```
My CLI application

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
  db        Database operations
  serve     Start the development server

Run "myapp <command> --help" for more information about a command.
```

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
    final watch = argResults!['watch'] as bool;
    final output = argResults!['output'] as String;
    
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
    final dryRun = argResults!['dry-run'] as bool;
    final environment = argResults!['environment'] as String;
    final tags = argResults!['tag'] as List<String>;
    
    io.info('Deploying to $environment${dryRun ? ' (dry run)' : ''}');
    if (tags.isNotEmpty) {
      io.text('Tags: ${tags.join(', ')}');
    }
  }
}
```

### Positional Arguments

`package:args` stores trailing positional values in `argResults.rest`. You can
support both a named `--name` option and a fallback positional value:

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
    final name = argResults!['name'] as String? ??
        (argResults!.rest.isNotEmpty ? argResults!.rest.first : 'World');
    io.success('Hello, $name!');
  }
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

### Usage Errors

The runner automatically catches and formats `UsageException`:

```bash
dart run bin/myapp.dart serve --invalid-option

Error: Could not find an option named "invalid-option".

Usage: myapp serve [arguments]

Options:
      --port            The port to listen on (default: 8080)
  -h, --help           Print this usage information.
```

---

## Integration with Console

Commands automatically get access to the [Console](CONSOLE.md) through the `io` property:

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

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [CONSOLE.md](CONSOLE.md) - Console I/O operations and styling
- [STYLE.md](STYLE.md) - Text styling and formatting
- [TUI.md](TUI.md) - Interactive terminal applications
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
