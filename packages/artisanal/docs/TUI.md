# TUI System (Bubble Tea-inspired)

The TUI system provides an Elm Architecture-based framework for building interactive terminal user interfaces. It's inspired by [Charm's Bubble Tea](https://github.com/charmbracelet/bubbletea) for Go.

## Overview

The Elm Architecture (TEA) is a pattern for building interactive applications with three core concepts:

```
┌─────────────────────────────────────────────────────────────┐
│                       Program Runtime                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    ┌──────────┐     ┌──────────┐     ┌──────────┐         │
│    │  Model   │────▶│  View    │────▶│ Terminal │         │
│    │  (State) │     │ (Render) │     │ (Output) │         │
│    └────▲─────┘     └──────────┘     └──────────┘         │
│         │                                                   │
│    ┌────┴─────┐     ┌──────────┐     ┌──────────┐         │
│    │  Update  │◀────│   Msg    │◀────│  Input   │         │
│    │ (Logic)  │     │ (Events) │     │ (Stdin)  │         │
│    └──────────┘     └──────────┘     └──────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

1. **Model** - Immutable state of your application
2. **Update** - Pure function that handles messages and returns new state
3. **View** - Pure function that renders state to the terminal

## Quick Start

```dart
import 'package:artisanal/tui.dart';

class CounterModel implements Model {
  final int count;
  const CounterModel([this.count = 0]);

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) => (CounterModel(count + 1), null),
      KeyMsg(key: Key(type: KeyType.down)) => (CounterModel(count - 1), null),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => '''
Counter: $count

Press ↑/↓ to change, q to quit
''';
}

void main() async {
  await runProgram(CounterModel());
}
```

## Model Interface

The `Model` interface defines the core contract for TUI applications:

```dart
abstract class Model {
  /// Called once at startup, returns an optional initial command
  Cmd? init() => null;

  /// Handles messages and returns (newState, optionalCommand)
  (Model, Cmd?) update(Msg msg);

  /// Renders current state to a string or View object
  Object view();
}
```

### Immutability

Models should be immutable - create new instances rather than mutating:

```dart
class TodoModel implements Model {
  final List<String> items;
  final int cursor;
  
  const TodoModel({this.items = const [], this.cursor = 0});
  
  // Good: copyWith pattern for updates
  TodoModel copyWith({List<String>? items, int? cursor}) {
    return TodoModel(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
    );
  }
  
  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.down)) =>
        (copyWith(cursor: (cursor + 1).clamp(0, items.length - 1)), null),
      _ => (this, null),
    };
  }
}
```

## Program Class

The `Program` class manages the runtime lifecycle:

```dart
final program = Program(
  MyModel(),
  options: ProgramOptions(
    altScreen: true,        // Use alternate screen buffer
    mouse: true,            // Enable mouse tracking
    fps: 60,                // Maximum frames per second
    frameTick: true,        // Auto-send FrameTickMsg
    hideCursor: true,       // Hide cursor during execution
    bracketedPaste: false,  // Enable bracketed paste mode
    catchPanics: true,      // Catch exceptions and restore terminal
  ),
);

await program.run();
```

### ProgramOptions

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `altScreen` | `bool` | `true` | Use alternate screen buffer (fullscreen mode) |
| `mouse` | `bool` | `false` | Enable mouse tracking |
| `mouseMode` | `MouseMode` | `none` | Mouse tracking mode (none, click, drag, motion) |
| `fps` | `int` | `60` | Maximum frames per second (1-120) |
| `frameTick` | `bool` | `true` | Auto-send FrameTickMsg at configured fps |
| `hideCursor` | `bool` | `true` | Hide cursor during execution |
| `bracketedPaste` | `bool` | `false` | Enable bracketed paste mode |
| `inputTimeout` | `Duration` | `50ms` | Timeout for incomplete escape sequences |
| `catchPanics` | `bool` | `true` | Catch exceptions and restore terminal |
| `filter` | `MessageFilter?` | `null` | Filter messages before reaching model |
| `signalHandlers` | `bool` | `true` | Install signal handlers (SIGINT, SIGTERM) |
| `startupTitle` | `String?` | `null` | Set window title on startup |
| `useUltravioletRenderer` | `bool` | `true` | Use UV cell-based renderer |

### Convenience Functions

```dart
// Simple way to run a program
await runProgram(MyModel());

// With options
await runProgram(
  MyModel(),
  altScreen: true,
  mouse: true,
);
```

## Command System (Cmd)

Commands represent side effects - async operations that may produce messages.

### Built-in Commands

```dart
// No-op command
Cmd.none()

// Exit the program
Cmd.quit()

// Send a message after delay
Cmd.tick(Duration(seconds: 1), () => TimerMsg())

// Repeating timer
Cmd.every(Duration(milliseconds: 100), () => AnimateMsg())

// Run multiple commands concurrently
Cmd.batch([cmd1, cmd2, cmd3])

// Run commands in sequence
Cmd.sequence([cmd1, cmd2, cmd3])

// Immediately send a message
Cmd.message(MyMsg())

// Force repaint
Cmd.repaint()

// Set window title
Cmd.setWindowTitle('My App')

// Execute external process
Cmd.exec(
  executable: 'ls',
  arguments: ['-la'],
  onComplete: (result) => ProcessCompleteMsg(result),
)
```

### Custom Commands with Cmd.perform

```dart
Cmd? init() {
  return Cmd.perform(
    () => fetchDataFromApi(),
    onSuccess: (data) => DataLoadedMsg(data),
    onError: (error, stack) => ErrorMsg(error.toString()),
  );
}
```

### StreamCmd for Continuous Events

```dart
// Subscribe to a stream
StreamCmd(
  myStream,
  onData: (data) => DataReceivedMsg(data),
  onError: (error) => StreamErrorMsg(error),
  onDone: () => StreamDoneMsg(),
)
```

### EveryCmd for Repeating Timers

```dart
// Animation tick every 100ms
EveryCmd(
  Duration(milliseconds: 100),
  () => AnimationTickMsg(),
)
```

## Message Types (Msg)

Messages are events that trigger state updates:

### Input Messages

```dart
// Keyboard input
KeyMsg(key: Key(type: KeyType.enter))
KeyMsg(key: Key(type: KeyType.runes, runes: [0x61])) // 'a'
KeyMsg(key: Key(ctrl: true, runes: [0x63])) // Ctrl+C

// Mouse input
MouseMsg(mouse: Mouse(
  type: MouseEventType.press,
  button: MouseButton.left,
  x: 10, y: 5,
))

// Window resize
WindowSizeMsg(width: 80, height: 24)

// Focus change
FocusMsg(focused: true)

// Pasted text (bracketed paste mode)
PasteMsg(text: 'pasted content')
```

### Timer Messages

```dart
// From Cmd.tick
TickMsg(time: DateTime.now(), tag: 'myTimer')

// From frameTick option
FrameTickMsg(time: DateTime.now(), frame: 42)
```

### Control Messages

```dart
// Quit signal
QuitMsg()

// Interrupt (Ctrl+C)
InterruptMsg()

// Batch multiple messages
BatchMsg([msg1, msg2, msg3])
```

### Custom Messages

```dart
class DataLoadedMsg extends Msg {
  final List<String> items;
  const DataLoadedMsg(this.items);
}

class ErrorMsg extends Msg {
  final String message;
  const ErrorMsg(this.message);
}
```

## View Rendering

The `view()` method can return a `String` or a `View` object:

### Simple String View

```dart
@override
String view() {
  return '''
╔════════════════════════╗
║     My Application     ║
╚════════════════════════╝

Items: ${items.length}
Selected: ${items[cursor]}

↑/↓: Navigate  q: Quit
''';
}
```

### View Object with Metadata

```dart
@override
View view() {
  return View(
    content: renderContent(),
    cursor: CursorPosition(x: cursorX, y: cursorY), // Show cursor at position
    title: 'My App - Page $page',                    // Window title
    progressBar: progress / 100.0,                   // Terminal progress bar
    mouseMode: MouseMode.motion,                     // Dynamic mouse mode
  );
}
```

## Built-in Bubbles (Components)

Artisanal includes pre-built interactive components called "bubbles":

### TextInputModel

```dart
final input = TextInputModel(
  placeholder: 'Enter your name...',
  prompt: '> ',
  charLimit: 50,
  width: 40,
  echoMode: EchoMode.normal, // normal, password, none
);

// In update:
final (newInput, cmd) = input.update(msg);

// In view:
return input.view();

// Get value:
final text = input.value;
```

### ListModel

```dart
final list = ListModel<String>(
  items: ['Apple', 'Banana', 'Cherry'],
  itemDelegate: (item, index, isSelected) {
    final prefix = isSelected ? '▸ ' : '  ';
    return '$prefix$item';
  },
  height: 5,
  showFilter: true,
);

// In update:
final (newList, cmd) = list.update(msg);

// Get selected item:
final selected = list.selectedItem;
```

### ConfirmModel

```dart
final confirm = ConfirmModel(
  prompt: 'Delete all files?',
  affirmative: 'Yes',
  negative: 'No',
);

// Check result:
if (confirm.confirmed) {
  // User confirmed
}
```

### SpinnerModel

```dart
final spinner = SpinnerModel(
  spinner: Spinners.dots,  // or: line, pulse, globe, moon, etc.
  title: 'Loading...',
);

// Update on each frame tick
final (newSpinner, _) = spinner.update(FrameTickMsg(...));
```

Available spinner presets in `Spinners`:
- `line`, `dot`, `miniDot`, `jump`
- `pulse`, `points`, `globe`, `moon`
- `monkey`, `meter`, `hamburger`, `ellipsis`

### FilePickerModel

```dart
final picker = FilePickerModel(
  initialPath: Directory.current.path,
  allowFiles: true,
  allowDirectories: false,
  extensions: ['.dart', '.yaml'],
);

// Get selected path:
final path = picker.selectedPath;
```

### WizardModel

```dart
final wizard = WizardModel(
  steps: [
    WizardStep.text(
      title: 'Name',
      prompt: 'Enter your name:',
      validate: (v) => v.isNotEmpty ? null : 'Name required',
    ),
    WizardStep.select(
      title: 'Language',
      prompt: 'Choose language:',
      options: ['Dart', 'Go', 'Rust'],
    ),
    WizardStep.confirm(
      title: 'Confirm',
      prompt: 'Proceed?',
    ),
  ],
);

// Get all answers:
final answers = wizard.answers; // Map<String, dynamic>
```

### PaginatorModel

```dart
final paginator = PaginatorModel(
  totalPages: 10,
  currentPage: 0,
  style: PaginatorStyle.dots, // or: arabic
);
```

## Creating Custom Components

### ViewComponent Interface

```dart
class MyComponent implements ViewComponent {
  final String label;
  const MyComponent(this.label);

  @override
  (ViewComponent, Cmd?) init() => (this, null);

  @override
  (ViewComponent, Cmd?) update(Msg msg) {
    // Handle messages
    return (this, null);
  }

  @override
  String view() => '[$label]';
}
```

### StaticComponent (No State Updates)

```dart
class HeaderComponent extends StaticComponent {
  final String title;
  const HeaderComponent(this.title);

  @override
  String view() => '''
╔════════════════════════════════╗
║  $title  ║
╚════════════════════════════════╝
''';
}
```

## Composing Components

Use the `ComponentHost` mixin to manage child components:

```dart
class AppModel with ComponentHost implements Model {
  final TextInputModel searchInput;
  final ListModel<String> itemList;
  
  AppModel({
    required this.searchInput,
    required this.itemList,
  });

  @override
  List<ViewComponent> get components => [searchInput, itemList];

  @override
  Cmd? init() {
    // Initialize all components
    return initComponents();
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    // Update all components
    final (newComponents, cmd) = updateComponents(msg);
    
    return (
      AppModel(
        searchInput: newComponents[0] as TextInputModel,
        itemList: newComponents[1] as ListModel<String>,
      ),
      cmd,
    );
  }

  @override
  String view() {
    return '''
Search: ${searchInput.view()}

${itemList.view()}
''';
  }
}
```

## Message Filtering

Filter or transform messages before they reach the model:

```dart
Msg? preventUnsavedQuit(Model model, Msg msg) {
  if (msg is KeyMsg && msg.key.ctrl && msg.key.runes.firstOrNull == 0x63) {
    // Ctrl+C pressed
    if (model is EditorModel && model.hasUnsavedChanges) {
      // Show warning instead of quitting
      return const ShowUnsavedWarningMsg();
    }
  }
  return msg; // Allow message through
}

final program = Program(
  EditorModel(),
  options: ProgramOptions(filter: preventUnsavedQuit),
);
```

## UV Renderer Integration

The TUI system can use the Ultraviolet cell-based renderer for optimized rendering:

```dart
final program = Program(
  MyModel(),
  options: ProgramOptions(
    useUltravioletRenderer: true, // Default
  ),
);
```

The UV renderer provides:
- Diff-based rendering (only update changed cells)
- Proper wide character handling
- Graphics protocol support (Sixel, Kitty, iTerm2)
- Synchronized output for flicker-free updates

## Helper Functions

```dart
// Create update result with no command
UpdateResult noCmd(Model model) => (model, null);

// Create update result that quits
UpdateResult quit(Model model) => (model, Cmd.quit());
```

## Best Practices

1. **Keep Models Immutable** - Use `copyWith` pattern
2. **Pure View Functions** - No side effects in `view()`
3. **Use Pattern Matching** - Dart's `switch` expressions are perfect for `update()`
4. **Batch Related Commands** - Use `Cmd.batch()` for concurrent operations
5. **Handle All Key Types** - Include a default case in your update function
6. **Clean Up Resources** - Return cleanup commands when needed

## Import

```dart
// Core TUI framework
import 'package:artisanal/tui.dart';

// Pre-built bubble components
import 'package:artisanal/bubbles.dart';
```
