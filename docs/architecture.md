# How Artisanal fits together

You do not have to adopt the whole stack to use Artisanal. A command-line tool
might only use `Console` and `Style`; an interactive app can add either the TEA
runtime or the widget framework; a custom renderer can work directly with
Ultraviolet.

This page explains where those pieces meet and helps you choose the smallest
useful starting point.

## Choose how to structure an interactive app

Both approaches run on the same `Program` runtime and Ultraviolet renderer.
Choose based on how you prefer to organize application code:

| | TEA model | Widget system |
|---|---|---|
| **A good fit for** | Small apps, custom event flows, and direct runtime control | Screens, forms, navigation, and reusable UI |
| **Code shape** | `Model`, `update`, and `view` | `Widget`, `State`, and `build` |
| **Start with** | [The TEA runtime](tui.md) | [The widget framework](widgets.md) |

The two are not isolated worlds. `WidgetApp` is itself a `Model`, so advanced
apps can mix widget screens with lower-level runtime features when needed.

## How output reaches the terminal

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Application Layer                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                │
│  │    Console    │  │    Program    │  │ CommandRunner │                │
│  │  (High-level  │  │   (TUI Elm    │  │   (CLI with   │                │
│  │     I/O)      │  │ Architecture) │  │  subcommands) │                │
│  └───────┬───────┘  └───────┬───────┘  └───────────────┘                │
│          │                  │                                           │
├──────────┼──────────────────┼───────────────────────────────────────────┤
│          │    Presentation Layer                                        │
│  ┌───────▼───────┐  ┌───────▼───────┐  ┌───────────────┐                │
│  │     Style     │  │    Widgets    │  │    Bubbles    │                │
│  │  (Lip Gloss   │  │ (Declarative  │  │  (Reusable    │                │
│  │   styling)    │  │   layouts)    │  │  components)  │                │
│  └───────┬───────┘  └───────┬───────┘  └───────────────┘                │
│          │                  │                                           │
├──────────┼──────────────────┼───────────────────────────────────────────┤
│          │  Rendering Layer │                                           │
│          ▼                  ▼                                           │
│  ┌─────────────────────────────────────┐                                │
│  │           UV (Ultraviolet)          │                                │
│  │      Cell-based terminal renderer   │                                │
│  │  ┌─────────┐ ┌─────────┐ ┌───────┐  │                                │
│  │  │ Canvas  │ │ Buffer  │ │ Layer │  │                                │
│  │  └─────────┘ └─────────┘ └───────┘  │                                │
│  └───────────────────┬─────────────────┘                                │
│                      │                                                  │
├──────────────────────┼──────────────────────────────────────────────────┤
│                      │    Terminal Layer                                │
│  ┌───────────────────▼─────────────────┐  ┌───────────────┐             │
│  │        Terminal Abstraction         │  │  Color Profile│             │
│  │   (Raw mode, ANSI, Input parsing)   │  │   Detection   │             │
│  └─────────────────────────────────────┘  └───────────────┘             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Core Systems

### 1. Style System (Lip Gloss-inspired)

**Location:** `pkgs/artisanal/lib/src/style/`
**Documentation:** [style.md](style.md)

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

**Location:** `pkgs/artisanal/lib/src/tui/`
**Documentation:** [tui.md](tui.md)

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

**Location:** `pkgs/artisanal_widgets/lib/src/widgets/`  
**Documentation:** [widgets.md](widgets.md)

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
- `GestureDetector` - Typed gesture recognition (tap, double-tap, long-press, drag)
- `Theme` - Color theming with adaptive support
- Flutter-style ports - `Chip`, `DropdownButton`, `PopupMenuButton`, `Slider`, `RangeSlider`, `LinearProgressIndicator`, `CircularProgressIndicator`

### 4. UV System (Ultraviolet)

**Location:** `pkgs/ultraviolet/lib/src/uv/`
**Documentation:** [uv.md](uv.md)

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
| **Style Colors** | `pkgs/artisanal/lib/src/style/color.dart` | High-level API producing ANSI strings |
| **UV Colors** | `pkgs/ultraviolet/lib/src/uv/cell.dart` | Low-level cell storage for deferred rendering |

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
UvColor? colorToUvColor(Color? color) {
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

// Low-level cell renderer (prefer dedicated package in new code)
import 'package:ultraviolet/ultraviolet.dart';
// Compatibility: `package:artisanal/uv.dart` continues to re-export these UV types.

// CLI command runner
import 'package:artisanal/args.dart';

// Terminal abstraction
import 'package:artisanal/terminal.dart';

// Umbrella API: Console, Markdown, charting, plugins, Liquid, and physics
import 'package:artisanal/artisanal.dart';

// Focused high-fidelity Markdown renderer
import 'package:artisanal/glamour.dart';
```

## Satellite Libraries

- **Charting**: Terminal-native charts rendered into UV buffers.
- **Markdown**: Lightweight ANSI renderer for inline docs.
- **Glamour**: High-fidelity Markdown renderer with themes.
- **Liquid**: Templating adapters for UI blocks (experimental).
- **Physics**: Forge2D helpers for demos (experimental).

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

There are two separate rendering paths depending on which programming model is in use:

**TEA model path** (bare `Model`, no widget tree):
```
Model.view() → String/View → UvTerminalRenderer → diff → stdout
```

**Widget system path** (`WidgetApp` wraps a widget tree):
```
WidgetApp.view()
  └── ElementTree.render()
        └── RenderObject tree → Canvas → Buffer
                                              ↓
                                        UvTerminalRenderer → diff → stdout
```

In both cases the `Program` runtime calls `model.view()` — the difference is that `WidgetApp.view()` triggers a full element-tree traversal before producing a string.

## Terminal Capabilities

Artisanal automatically detects terminal capabilities:

- **Color Profile**: ASCII, ANSI (16), ANSI256, TrueColor
- **Background**: Light/Dark detection via OSC 11
- **Graphics**: Sixel, Kitty, iTerm2 image protocols (auto-selected by priority: Kitty > iTerm2 > Sixel > HalfBlock fallback)
- **Features**: Mouse tracking, bracketed paste, focus events
- **Gesture System**: Recognizer-based gesture processing with typed detail objects for tap, double-tap, long-press, and drag

```dart
// Automatic degradation
final style = Style().foreground(BasicColor('#ff5500'));
// TrueColor terminal: \x1b[38;2;255;85;0m
// ANSI256 terminal: \x1b[38;5;208m
// ANSI16 terminal: \x1b[91m
```

## Performance Considerations

1. **Diff-based Rendering**: UV only redraws changed cells
2. **Synchronized Output**: Uses DEC synchronized-output mode where supported
3. **Frame Rate Control**: Configurable FPS with automatic throttling
4. **Lazy Evaluation**: Style rendering is deferred until needed

## File Organization

```
pkgs/artisanal/lib/
├── artisanal.dart      # Main entry point
├── style.dart          # Style system exports
├── tui.dart            # TUI framework exports
├── bubbles.dart        # Bubble components exports
├── compat.dart         # Compatibility helpers
├── editor_core.dart    # Low-level editor primitives
├── glamour.dart        # Focused high-fidelity Markdown renderer
├── args.dart           # CLI argument parser exports
├── terminal.dart       # Terminal abstraction exports
├── testing.dart        # Widget testing re-export
├── uv.dart             # UV compatibility re-export
├── widgets.dart        # Widget framework re-export
└── src/
    ├── charting/       # Charting renderers
    ├── plugins/        # Remote plugin protocol and surfaces
    ├── run/            # App and hosted runner support
    ├── style/          # Lip Gloss-inspired styling
    ├── tui/            # Bubble Tea-inspired TUI
    │   └── bubbles/    # Pre-built TEA components
    │
    │   # Widget system lives in a separate package:
    │   # pkgs/artisanal_widgets/lib/src/widgets/
    ├── uv/             # Ultraviolet cell renderer
    ├── io/             # Console I/O utilities
    ├── terminal/       # Terminal abstraction
    ├── colorprofile/   # Color capability detection
    ├── unicode/        # Unicode width/grapheme handling
    ├── layout/         # Layout utilities
    ├── renderer/       # Renderer abstraction
    ├── runner/         # Command runner
    ├── tui/markdown/   # Markdown to ANSI
    ├── glamour/        # Glamour renderer
    ├── liquid/         # Liquid adapters
    └── physics/        # Forge2D helpers
```

Standalone UV users should import `package:ultraviolet/ultraviolet.dart` directly;
`package:artisanal/uv.dart` is retained as a compatibility shim.

## Related Documentation

- [docs_index.md](docs_index.md) - Full documentation index
- [args.md](args.md) - Command runner and argument parsing
- [console.md](console.md) - Console I/O operations and styling
- [style.md](style.md) - Detailed Style system documentation
- [tui.md](tui.md) - TUI framework and components
- [widgets.md](widgets.md) - Widget composition system
- [uv.md](uv.md) - Low-level rendering engine
- [terminal.md](terminal.md) - Terminal abstraction and ANSI utilities
- [renderer.md](renderer.md) - Renderer abstraction
- [markdown.md](markdown.md) - Markdown rendering (ANSI + Glamour)
- [charting.md](charting.md) - Charting primitives
