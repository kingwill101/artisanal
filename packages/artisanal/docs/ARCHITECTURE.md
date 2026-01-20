# Artisanal Architecture

Artisanal is a full-stack terminal toolkit for Dart, providing everything needed to build polished CLI applications and interactive TUIs. It's inspired by Charm's ecosystem (Lip Gloss, Bubble Tea, Ultraviolet).

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Application Layer                              │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               │
│  │    Console    │  │    Program    │  │ CommandRunner │               │
│  │  (High-level  │  │   (TUI Elm    │  │   (CLI with   │               │
│  │     I/O)      │  │ Architecture) │  │  subcommands) │               │
│  └───────┬───────┘  └───────┬───────┘  └───────────────┘               │
│          │                  │                                           │
├──────────┼──────────────────┼───────────────────────────────────────────┤
│          │    Presentation Layer                                        │
│  ┌───────▼───────┐  ┌───────▼───────┐  ┌───────────────┐               │
│  │     Style     │  │    Widgets    │  │    Bubbles    │               │
│  │  (Lip Gloss   │  │ (Declarative  │  │  (Reusable    │               │
│  │   styling)    │  │   layouts)    │  │  components)  │               │
│  └───────┬───────┘  └───────┬───────┘  └───────────────┘               │
│          │                  │                                           │
├──────────┼──────────────────┼───────────────────────────────────────────┤
│          │    Rendering Layer                                           │
│          ▼                  ▼                                           │
│  ┌─────────────────────────────────────┐                               │
│  │           UV (Ultraviolet)          │                               │
│  │      Cell-based terminal renderer   │                               │
│  │  ┌─────────┐ ┌─────────┐ ┌───────┐ │                               │
│  │  │ Canvas  │ │ Buffer  │ │ Layer │ │                               │
│  │  └─────────┘ └─────────┘ └───────┘ │                               │
│  └───────────────────┬─────────────────┘                               │
│                      │                                                  │
├──────────────────────┼──────────────────────────────────────────────────┤
│                      │    Terminal Layer                                │
│  ┌───────────────────▼─────────────────┐  ┌───────────────┐           │
│  │        Terminal Abstraction         │  │  Color Profile │           │
│  │   (Raw mode, ANSI, Input parsing)   │  │   Detection    │           │
│  └─────────────────────────────────────┘  └───────────────┘           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Core Systems

### 1. Style System (Lip Gloss-inspired)

**Location:** `lib/src/style/`  
**Documentation:** [STYLE.md](STYLE.md)

The Style system provides a fluent API for terminal text styling:

```dart
final style = Style()
    .bold()
    .foreground(Colors.cyan)
    .padding(Padding.symmetric(horizontal: 2))
    .border(Border.rounded);

print(style.render('Hello, World!'));
```

**Key components:**
- `Style` - Fluent builder for text formatting
- `Color`, `AnsiColor`, `BasicColor`, `AdaptiveColor` - Color types
- `Border`, `BorderSides` - Box borders
- `Padding`, `Margin`, `Align` - Layout properties
- `LipList` - Styled list rendering

### 2. TUI System (Bubble Tea-inspired)

**Location:** `lib/src/tui/`  
**Documentation:** [TUI.md](TUI.md)

The TUI system implements the Elm Architecture for interactive terminal applications:

```dart
class MyModel implements Model {
  @override
  Cmd? init() => null;
  
  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }
  
  @override
  String view() => 'Press q to quit';
}
```

**Key components:**
- `Program` - Runtime that manages event loop and rendering
- `Model` - Application state with init/update/view
- `Cmd` - Async side effects (quit, tick, perform, batch)
- `Msg` - Events (KeyMsg, MouseMsg, WindowSizeMsg, etc.)
- Bubbles - Pre-built components (TextInput, List, Confirm, etc.)

### 3. Widget System

**Location:** `lib/src/tui/widgets/`  
**Documentation:** [WIDGETS.md](WIDGETS.md)

Declarative widget composition for building complex layouts:

```dart
Container(
  padding: EdgeInsets.all(1),
  border: Border.rounded,
  child: VBox([
    Label('Header', style: theme.primary),
    Spacer(),
    HBox([Label('Left'), Spacer(), Label('Right')]),
  ]),
)
```

**Key components:**
- `Widget` - Base class with lifecycle (init, update, view)
- `Container` - Box with padding, borders, backgrounds
- `Label` - Styled text
- `HBox`, `VBox` - Horizontal/vertical layouts
- `Theme` - Color theming with adaptive support

### 4. UV System (Ultraviolet)

**Location:** `lib/src/uv/`  
**Documentation:** [UV.md](UV.md)

Low-level cell-based terminal rendering:

```dart
final canvas = Canvas(80, 24);
canvas.setString(10, 5, 'Hello');
canvas.drawBorder(roundedBorder(), rect(5, 3, 20, 5));
final output = canvas.render();
```

**Key components:**
- `Cell`, `UvStyle`, `UvColor` - Cell representation
- `Buffer` - 2D grid of cells
- `Screen` - Abstract drawing surface
- `Canvas` - Compositing with drawables
- `Layer` - Z-ordered composition
- `UvTerminalRenderer` - Diff-based terminal output

## Two Color Systems

Artisanal has two color systems serving different purposes:

| System | Location | Purpose |
|--------|----------|---------|
| **Style Colors** | `lib/src/style/color.dart` | High-level API producing ANSI strings |
| **UV Colors** | `lib/src/uv/cell.dart` | Low-level cell storage for deferred rendering |

### Style Colors

```dart
// Used with Style fluent API
Style().foreground(Colors.red)              // BasicColor
Style().foreground(AnsiColor(196))          // Explicit ANSI code
Style().foreground(AdaptiveColor(           // Auto light/dark
  light: Colors.black,
  dark: Colors.white,
))
```

### UV Colors

```dart
// Used with Cell/Canvas API
final cell = Cell(
  content: 'A',
  style: UvStyle(fg: UvColor.rgb(255, 0, 0)),
);
```

### Bridge Code

The widget system bridges these two systems:

```dart
// In layout_widgets.dart
UvColor? _colorToUvColor(Color? color) {
  if (color is AdaptiveColor) {
    resolved = hasDarkBackground ? color.dark : color.light;
  }
  // Convert Style Color → UV Color
}
```

## Import Structure

```dart
// Core CLI utilities (Console, Verbosity, Terminal)
import 'package:artisanal/artisanal.dart';

// Just the styling system
import 'package:artisanal/style.dart';

// TUI framework (Model, Program, Cmd, Msg)
import 'package:artisanal/tui.dart';

// Pre-built TUI components
import 'package:artisanal/bubbles.dart';

// Low-level cell renderer
import 'package:artisanal/uv.dart';

// CLI command runner
import 'package:artisanal/args.dart';

// Markdown rendering
import 'package:artisanal/markdown.dart';
```

## Data Flow

### Console (High-level I/O)

```
User Code → Console → Style.render() → Terminal → stdout
```

### TUI (Interactive)

```
stdin → KeyParser → Msg → Model.update() → Model → Model.view() → Renderer → stdout
                            ↓
                           Cmd
                            ↓
                     Async Operation
                            ↓
                           Msg (loops back)
```

### UV Rendering

```
Model.view() → Widget.view() → Canvas → Buffer → UvTerminalRenderer → stdout
                                          ↓
                                    Diff with previous
                                          ↓
                                    Minimal ANSI output
```

## Terminal Capabilities

Artisanal automatically detects terminal capabilities:

- **Color Profile**: ASCII, ANSI (16), ANSI256, TrueColor
- **Background**: Light/Dark detection via OSC 11
- **Graphics**: Sixel, Kitty, iTerm2 image protocols
- **Features**: Mouse tracking, bracketed paste, focus events

```dart
// Automatic degradation
final style = Style().foreground(BasicColor('#ff5500'));
// TrueColor terminal: \x1b[38;2;255;85;0m
// ANSI256 terminal: \x1b[38;5;208m
// ANSI16 terminal: \x1b[91m
```

## Performance Considerations

1. **Diff-based Rendering**: UV only redraws changed cells
2. **Synchronized Output**: Uses DCS/ST sequences for atomic updates
3. **Frame Rate Control**: Configurable FPS with automatic throttling
4. **Lazy Evaluation**: Style rendering is deferred until needed

## File Organization

```
lib/
├── artisanal.dart      # Main entry point
├── style.dart          # Style system exports
├── tui.dart            # TUI framework exports
├── bubbles.dart        # Bubble components exports
├── uv.dart             # UV renderer exports
├── args.dart           # CLI argument parser exports
├── markdown.dart       # Markdown renderer exports
└── src/
    ├── style/          # Lip Gloss-inspired styling
    ├── tui/            # Bubble Tea-inspired TUI
    │   ├── bubbles/    # Pre-built components
    │   └── widgets/    # Declarative widgets
    ├── uv/             # Ultraviolet cell renderer
    ├── io/             # Console I/O utilities
    ├── terminal/       # Terminal abstraction
    ├── colorprofile/   # Color capability detection
    ├── unicode/        # Unicode width/grapheme handling
    ├── layout/         # Layout utilities
    ├── renderer/       # Renderer abstraction
    ├── runner/         # Command runner
    └── markdown/       # Markdown to ANSI
```

## Related Documentation

- [STYLE.md](STYLE.md) - Detailed Style system documentation
- [TUI.md](TUI.md) - TUI framework and components
- [WIDGETS.md](WIDGETS.md) - Widget composition system
- [UV.md](UV.md) - Low-level rendering engine
