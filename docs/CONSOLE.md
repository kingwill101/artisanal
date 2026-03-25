# Console I/O System

The Console class provides a high-level API for building polished CLI applications with beautiful, semantic output. It combines terminal styling, interactive prompts, and utility methods for common console operations.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Creating a Console](#creating-a-console)
- [Text Output](#text-output)
  - [Basic Output](#basic-output)
  - [Formatted Output](#formatted-output)
  - [Message Blocks](#message-blocks)
  - [Alert Boxes](#alert-boxes)
- [Text Styling](#text-styling)
  - [Console Tags](#console-tags)
  - [Custom Styles](#custom-styles)
  - [Direct Styling](#direct-styling)
- [Interactive Prompts](#interactive-prompts)
  - [Text Input](#text-input)
  - [Confirm Dialogs](#confirm-dialogs)
  - [Selection Prompts](#selection-prompts)
  - [Password Input](#password-input)
  - [Prompt Validators](#prompt-validators)
- [Tasks and Progress](#tasks-and-progress)
  - [Simple Tasks](#simple-tasks)
  - [Complex Tasks](#complex-tasks)
- [Components](#components)
  - [Tables](#tables)
  - [Trees](#trees)
  - [Progress Bars](#progress-bars)
  - [Listings](#listings)
  - [Components Helper](#components-helper)
- [Advanced Features](#advanced-features)
  - [Verbosity Control](#verbosity-control)
  - [Interactive Mode](#interactive-mode)
  - [Terminal Detection](#terminal-detection)
  - [Inline Animations](#inline-animations)
- [Configuration](#configuration)
- [Integration with Args](#integration-with-args)
- [Related Documentation](#related-documentation)

---

## Overview

The Console class provides:

- **Beautiful Output**: Styled text with colors and formatting
- **Semantic Messages**: info, success, comment, question, warn, error, note, caution, verbose, debug
- **Interactive Prompts**: ask, confirm, choice, secret
- **Tasks**: Progress indicators with success/failure states
- **Components**: Tables, trees, progress bars, listings
- **Console Tags**: Symfony/Laravel-style inline styling
- **Custom Styles**: Register reusable styled components
- **Verbosity Control**: Output based on verbosity levels
- **Terminal Detection**: Automatic ANSI support and color profile

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final console = Console();
  
  console.title('My Application');
  console.section('Welcome');
  
  console.info('This is an information message');
  console.success('Operation completed successfully');
  console.warn('This is a warning');
  console.error('An error occurred');
  
  final name = console.ask('What is your name?');
  console.text('Hello, $name!');
  
  if (console.confirm('Do you want to continue?')) {
    console.task('Processing', run: () async {
      // Do some work
      await Future.delayed(Duration(seconds: 2));
      return TaskResult.success;
    });
  }
}
```

---

## Quick Start

### Basic Usage

```dart
import 'package:artisanal/artisanal.dart';

void main() {
  final console = Console();
  
  console.title('My CLI Tool');
  console.section('Introduction');
  
  console.text('This is a simple CLI tool built with Artisanal.');
  
  console.listing([
    'Feature 1: Beautiful output',
    'Feature 2: Interactive prompts',
    'Feature 3: Semantic messages',
  ]);
  
  console.success('Setup complete!');
}
```

---

## Creating a Console

### Default Console

```dart
final console = Console();
```

### Custom Configuration

```dart
final console = Console(
  verbosity: Verbosity.verbose,
  interactive: false,
  terminalWidth: 120,
);
```

### Testing Configuration

```dart
final output = <String>[];
final console = Console(
  out: (line) => output.add(line),
  err: (line) => output.add(line),
  readLine: () => 'test input',
  renderer: StringRenderer(colorProfile: ColorProfile.ascii),
);
```

---

## Text Output

### Basic Output

```dart
console.writeln('Hello, World!');
console.write('Loading...');
console.newLine(2);

console.writelnErr('Error message');
console.writeErr('Error details');
```

### Formatted Output

```dart
console.title('Main Title');
console.section('Section Header');
console.text('This is some indented text');

console.listing([
  'First item',
  'Second item',
  'Third item',
]);
```

### Message Blocks

```dart
console.line('This is a plain line');
console.info('This is an information message');
console.success('Operation completed successfully');
console.comment('This is a comment');
console.question('This is a question');
console.warn('This is a warning');
console.error('An error occurred');
console.note('This is a note');
console.caution('This is a caution');
console.verbose('Verbose message (only in verbose mode)');
console.debug('Debug message (only in debug mode)');
```

These methods print directly in color without label prefixes, matching Laravel Artisan.

### Alert Boxes

```dart
console.alert('This is an important alert!');

console.alert('''
This is a multi-line alert
with multiple paragraphs.

- Point 1
- Point 2
- Point 3
''');
```

---

## Text Styling

### Console Tags

Use Symfony/Laravel-style tags for inline styling:

```dart
console.writeln('<info>Information message</info>');
console.writeln('<comment>Comment</comment>');
console.writeln('<question>Question?</question>');
console.writeln('<error>Error message</error>');
console.writeln('<success>Success!</success>');
console.writeln('<warning>Warning</warning>');
console.writeln('<alert>Alert!</alert>');
console.writeln('<muted>Muted text</muted>');
```

Tags automatically map to the active `OutputTheme` semantic colors.

### Custom Styles

```dart
console.registerStyle('brand', Style().foreground(BasicColor('#ff5500')).bold());
console.registerStyle('highlight', Style().foreground(Colors.yellow).background(Colors.black));

console.writeln('<brand>My Brand</brand>');
console.writeln('<highlight>Important content</highlight>');
```

### Direct Styling

```dart
final style = Style()
    .bold()
    .foreground(Colors.blue)
    .background(Colors.white);

console.writeln(style.render('Styled text'));
```

---

## Interactive Prompts

### Text Input

```dart
final name = console.ask('What is your name?');
final email = console.ask('What is your email?', defaultValue: 'user@example.com');
```

### Confirm Dialogs

```dart
final confirmed = console.confirm('Are you sure?');
final proceed = console.confirm('Do you want to continue?', defaultValue: true);
```

### Selection Prompts

```dart
final choice = console.choice(
  'Choose an option:',
  ['Option 1', 'Option 2', 'Option 3'],
);

final selected = console.choice(
  'Pick a color:',
  ['Red', 'Green', 'Blue'],
  defaultValue: 'Green',
);
```

### Password Input

```dart
final password = console.secret('Enter your password:');
```

### Prompt Validators

```dart
import 'package:artisanal/artisanal.dart';
import 'package:acanthis/acanthis.dart';

void main() {
  final console = Console();
  final email = console.ask('Email', validator: Validators.email());
  final port = console.ask('Port', validator: Validators.integer(min: 1, max: 65535));

  final schema = string().min(3).max(20);
  final name = console.ask('Name', validator: schema.toValidator());

  console.info('Email: $email');
  console.info('Port: $port');
  console.info('Name: $name');
}
```

---

## Tasks and Progress

### Simple Tasks

```dart
console.task('Processing files', run: () async {
  await Future.delayed(Duration(seconds: 1));
  return TaskResult.success;
});
```

### Complex Tasks

```dart
final result = await console.task('Deploying application', run: () async {
  console.text('Step 1: Preparing');
  await Future.delayed(Duration(milliseconds: 500));
  
  console.text('Step 2: Deploying');
  await Future.delayed(Duration(milliseconds: 1000));
  
  console.text('Step 3: Verifying');
  await Future.delayed(Duration(milliseconds: 500));
  
  return TaskResult.success;
});
```

### Task Group

```dart
final tasks = await console.taskGroup('Setup', [
  ('Install dependencies', () async {
    await Future.delayed(Duration(seconds: 1));
    return TaskResult.success;
  }),
  ('Configure environment', () async {
    await Future.delayed(Duration(seconds: 0.5));
    return TaskResult.success;
  }),
  ('Start server', () async {
    await Future.delayed(Duration(seconds: 1));
    return TaskResult.success;
  }),
]);

if (tasks.success) {
  console.success('All tasks completed successfully');
} else {
  console.error('${tasks.failed.length} tasks failed');
}
```

---

## Components

### Tables

```dart
console.table([
  ['Name', 'Email', 'Role'],
  ['John Doe', 'john@example.com', 'Admin'],
  ['Jane Smith', 'jane@example.com', 'User'],
  ['Bob Johnson', 'bob@example.com', 'Guest'],
]);
```

### Trees

```dart
console.tree({
  'Folder 1': {
    'File 1.txt': null,
    'File 2.txt': null,
    'Subfolder': {
      'File 3.txt': null,
    },
  },
  'Folder 2': {
    'Image.png': null,
  },
});
```

### Progress Bars

```dart
final progress = console.progressBar(total: 100);
for (var i = 0; i < 100; i++) {
  await Future.delayed(Duration(milliseconds: 50));
  progress.update(i + 1);
}
progress.complete();
```

### Listings

```dart
console.listing([
  'Item 1',
  'Item 2',
  'Item 3',
]);

console.listing([
  'First level',
  {
    'Second level': [
      'Third level 1',
      'Third level 2',
    ],
  },
]);
```

### Components Helper

```dart
final console = Console();

console.components.alert('Heads up!');
console.components.twoColumnDetail('Version', '1.2.3');
console.components.definitionList({
  'Host': 'localhost',
  'Port': 5432,
});
console.components.horizontalTable({'Env': 'prod', 'Region': 'us-east'});
```

---

## Advanced Features

### Verbosity Control

```dart
console.verbose('This is only shown in verbose mode');
console.debug('This is only shown in debug mode');

// Output only when the current verbosity is very verbose or higher
console.info('Detailed info', verbosity: Verbosity.veryVerbose);

// Check verbosity level
if (console.verbosity >= Verbosity.verbose) {
  console.writeln('Verbose output');
}

// Create console with specific verbosity
final verboseConsole = Console(verbosity: Verbosity.veryVerbose);
```

### Interactive Mode

```dart
final console = Console(interactive: false);

// Check if interactive
if (console.interactive) {
  final response = console.ask('Enter input:');
} else {
  console.info('Using default settings');
}
```

### Terminal Detection

```dart
final console = Console();

// Check terminal capabilities
print(console.renderer.colorProfile); // ColorProfile.trueColor
print(console.renderer.hasDarkBackground); // true/false
print(console.terminalWidth); // 80/120/etc.
```

### Inline Animations

```dart
import 'package:artisanal/artisanal.dart';

Future<void> main() async {
  final console = Console();
  final animation = InlineAnimation(terminal: console.promptTerminal);

  await animation.spin(
    message: 'Connecting',
    task: () async => Future.delayed(const Duration(milliseconds: 200)),
    clearOnDone: true,
  );

  await animation.progress(
    message: 'Downloading',
    task: (setProgress) async {
      for (var i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 10));
        setProgress(i / 100);
      }
    },
  );
}
```

---

## Configuration

### Renderer Options

```dart
final console = Console(
  renderer: StringRenderer(colorProfile: ColorProfile.ansi256),
);

// or

final console = Console(
  renderer: TerminalRenderer(forceProfile: ColorProfile.ascii),
);
```

### Custom I/O Callbacks

```dart
final output = <String>[];
final console = Console(
  out: (line) => output.add(line),
  err: (line) => output.add(line),
  readLine: () => 'user input',
);
```

---

## Integration with Args

Commands automatically get a Console instance:

```dart
import 'package:artisanal/args.dart';

class MyCommand extends Command<void> {
  @override
  String get name => 'my-command';
  
  @override
  String get description => 'My command description';
  
  @override
  void run() {
    io.title('My Command');
    io.text('This command uses the console');
    
    final name = io.ask('What is your name?');
    io.success('Hello, $name!');
  }
}
```

---

## Related Documentation

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [ARGS.md](ARGS.md) - Command runner and argument parsing
- [STYLE.md](STYLE.md) - Text styling and formatting
- [TUI.md](TUI.md) - Interactive terminal applications
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [IO_COMPONENTS.md](IO_COMPONENTS.md) - Console components helper
