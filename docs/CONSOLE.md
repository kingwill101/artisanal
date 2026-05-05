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
  - [Diff Comments](#diff-comments)
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

### Diff Comments

The Console provides diff rendering with anchor links and selection exposure for interactive diff browsing. These features are useful for code review tools, CLI git clients, and any application that needs to display or interact with unified diffs.

#### Diff Comment Anchors

Diff comment anchors are hyperlinks embedded within diff output that point to specific lines or hunks. They enable direct navigation to exact changes, making them ideal for code review systems where users need to reference or comment on specific modifications.

The `console.diff()` method renders a unified diff with line number anchors. In terminals that support hyperlinks (e.g., iTerm2, Kitty, GNOME Terminal), the line numbers become clickable links that can be used to reference specific locations.

**Example: Rendering a unified diff with line number anchors**

```dart
final console = Console();

final unifiedDiff = '''
diff --git a/lib/example.dart b/lib/example.dart
--- a/lib/example.dart
+++ b/lib/example.dart
@@ -10,6 +10,7 @@ void main() {
   print('Hello');
   print('World');
   print('Foo');
+  print('Bar');
   print('Baz');
 }
''';

console.diff(unifiedDiff);
```

The output includes anchored line numbers for changed lines. The anchors encode file path, side (left/right), and line number, enabling other tools to parse and link back to those exact locations.

**Programmatic anchor access**

If you need to retrieve or work with the anchors programmatically (e.g., to build custom UI or generate external links), you can access them via the underlying model:

```dart
final model = console.diffModel; // Access the GitDiffModel
final anchors = model.commentAnchors;

for (final anchor in anchors) {
  print('${anchor.path}:${anchor.side.name} line ${anchor.line}');
  // anchor.key provides a stable DiffCommentLineKey for identification
}
```

#### Diff Comment Selection

The Console exposes selected diff hunks or lines for further processing. This allows building interactive diff viewers where users can select a region and perform actions like adding a review comment, copying the selected text, or applying a patch.

Use `console.diffSelection()` to retrieve the currently selected diff hunk or line content. This returns a `DiffSelection?` object containing the selected file path, line range, and text.

**Example: Selecting a diff hunk and getting its content**

```dart
final console = Console(interactive: true);

// Render an interactive diff (user can navigate with arrow keys)
console.diff(unifiedDiff, interactive: true);

// Later, retrieve the user's selection
final selected = console.diffSelection();
if (selected != null) {
  console.info('Selected hunk in ${selected.path}:');
  console.text(selected.content);
  
  // Use selection to add a comment, copy to clipboard, etc.
  await addReviewComment(selected.path, selected.line, selected.side);
}
```

The selection updates as the user moves the cursor in interactive mode. You can also set the selection programmatically for custom navigation controls:

```dart
// Jump to a specific line
console.setDiffSelection(
  file: 'lib/example.dart',
  line: 12,
  side: DiffCommentSide.right,
);
```

**Selection state access**

For more control, the Console exposes the selection state through properties:

```dart
// Check if a selection exists
if (console.hasDiffSelection) {
  final anchor = console.selectedDiffAnchor;
  final range = console.selectedDiffRange;
  // Process selection...
}

// Clear current selection
console.clearDiffSelection();
```

#### Interactive Diff Navigation

When `interactive: true`, the diff viewer supports full keyboard navigation:

| Key | Action |
|-----|--------|
| `↑` / `↓` | Move between commentable lines |
| `←` / `→` | Jump between hunk boundaries |
| `Enter` | Select the current line/hunk |
| `Space` | Toggle multi-line range selection |
| `Esc` | Cancel selection / exit |
| `?` | Show key binding help |
| `v` | Cycle view mode (unified / side-by-side / pretty) |

Navigation state is maintained in the `GitDiffModel`'s viewport and can be queried or controlled via the model's properties and methods.

#### Diff Display Modes

The diff viewer supports multiple display modes, configurable via `console.diffViewMode` or per-call:

- **Unified** — Traditional `git diff` format with `+`/`-` markers in a single column.
- **Side-by-side** — Old version on left, new version on right, separated by `│`.
- **Pretty** — Clean layout with single line-number column and minimal noise.

```dart
// Set globally
console.diffViewMode = DiffViewMode.sideBySide;

// Or per call
console.diff(diffText, viewMode: DiffViewMode.pretty);
```

#### Customizing Diff Appearance

Diff styling can be customized via `DiffStyles`. The Console provides theme-aware defaults, but you can override specific elements:

```dart
console.diffStyles = DiffStyles(
  addedLine: Style().foreground(Colors.green).bold(),
  removedLine: Style().foreground(Colors.red),
  selectedCommentLine: Style().background(Colors.blue).foreground(Colors.white),
);
```

The `DiffStyles.fromColors()` factory maps semantic colors from your theme:

```dart
console.diffStyles = DiffStyles.fromColors(
  success: Colors.green,      // added (+) lines
  error: Colors.red,          // removed (-) lines
  muted: Colors.gray,         // line numbers, gutters
  surface: Colors.gray850,    // panel background
  onSurface: Colors.white,    // file headers
  onBackground: Colors.gray200, // context lines
  border: Colors.gray600,     // separators
);
```

#### Diff Model API

When working with diffs programmatically, you can access the underlying `GitDiffModel` directly:

```dart
final model = console.diffModel;

// Parse diff without rendering
final files = model.files;
for (final file in files) {
  print('File: ${file.oldPath} → ${file.newPath}');
  print('  +${file.additions} -${file.deletions}');
}

// Get rendered output (useful for testing or custom rendering)
final output = model.view();

// Programmatic navigation
model.viewport.scrollTo(10);
final anchor = model.nearestCommentAnchor(renderLine: 5);
```

#### Non-Interactive Mode

In non-interactive environments (CI/CD, logging), diffs are rendered without anchors or interactive prompts:

```dart
final console = Console(interactive: false);
console.diff(diffText); // Plain text diff, no hyperlinks or key handling
```

The rendering remains fully styled with ANSI colors but omits terminal-specific features like hyperlink OSC sequences.

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
