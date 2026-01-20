# Widget Composition System

Artisanal's Widget system provides a composable, hierarchical approach to building terminal user interfaces. Built on top of the Model pattern (Elm Architecture), Widgets extend it with automatic message forwarding, theme access, and layout primitives.

## Table of Contents

1. [Overview](#overview)
2. [Widget Base Class](#widget-base-class)
3. [Widget Lifecycle](#widget-lifecycle)
4. [Theme System](#theme-system)
5. [Layout Widgets](#layout-widgets)
6. [Creating Custom Widgets](#creating-custom-widgets)
7. [Widget Composition](#widget-composition)
8. [Message Propagation](#message-propagation)
9. [Focus Management](#focus-management)
10. [Integration with TUI Program](#integration-with-tui-program)
11. [Integration with UV Canvas](#integration-with-uv-canvas)

---

## Overview

The Widget system provides:

- **Hierarchical composition** - Build complex UIs from smaller, reusable widgets
- **Automatic message forwarding** - Parent widgets forward messages to children
- **Built-in theming** - Access semantic colors and text styles via `theme`
- **Layout primitives** - `HBox`, `VBox`, `Container`, `Label`, `Spacer`, `Divider`
- **Adaptive styling** - Colors that auto-switch between light and dark terminals

```dart
import 'package:artisanal/tui.dart';

class MyApp extends Widget {
  @override
  String get id => 'app';

  final header = Label('My Application', style: Style().bold());
  final content = VBox(children: [
    Label('Line 1'),
    Label('Line 2'),
  ]);

  @override
  List<Widget> get children => [header, content];

  @override
  Object view() {
    return VBox(
      gap: 1,
      children: [
        Label('Title', style: theme.titleLarge),
        HBox(
          gap: 2,
          children: [Label('Left'), Label('Right')],
        ),
      ],
    );
  }
}
```

---

## Widget Base Class

The `Widget` class is the foundation for all composable TUI components. It implements the `Model` interface with additional features for composition.

### Core Properties

```dart
abstract class Widget implements Model {
  /// Unique identifier for this widget (required).
  String get id;

  /// Child widgets that receive forwarded messages.
  List<Widget> get children => const [];

  /// Whether this widget can receive keyboard focus.
  bool get focusable => false;

  /// Access the current theme.
  Theme get theme => currentTheme;
}
```

### Key Differences from Model

| Feature | Model | Widget |
|---------|-------|--------|
| Message handling | Manual | Auto-forwards to children first |
| Theme access | Manual | Built-in `theme` getter |
| Identification | None | Required `id` property |
| Composition | Manual | Declarative `children` list |
| Background detection | Manual | Automatic via `BackgroundColorMsg` |

---

## Widget Lifecycle

### Initialization (`init` / `handleInit`)

When a widget is first mounted, `init()` is called. The default implementation:

1. Requests the terminal background color (for adaptive theming)
2. Calls `init()` on all children
3. Calls `handleInit()` for widget-specific initialization
4. Batches all commands together

```dart
class MyWidget extends Widget {
  @override
  String get id => 'my-widget';

  @override
  Cmd? handleInit() {
    // Widget-specific initialization
    return Cmd.perform(
      () => loadData(),
      onSuccess: (data) => DataLoadedMsg(data),
    );
  }
}
```

> **Important:** Override `handleInit()`, not `init()`. The base `init()` handles child initialization and background color detection.

### Update (`update` / `handleUpdate`)

When a message arrives, `update()` is called. The default implementation:

1. Handles `BackgroundColorMsg` to update theme state
2. Forwards the message to all children
3. Calls `handleUpdate()` for widget-specific handling
4. Batches all commands together

```dart
class MyWidget extends Widget {
  @override
  String get id => 'my-widget';
  
  int count = 0;

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) => _increment(),
      KeyMsg(key: Key(type: KeyType.down)) => _decrement(),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  (Widget, Cmd?) _increment() {
    count++;
    return (this, null);
  }

  (Widget, Cmd?) _decrement() {
    count--;
    return (this, null);
  }
}
```

> **Important:** Override `handleUpdate()`, not `update()`. The base `update()` handles message forwarding to children.

### View (`view`)

The `view()` method renders the widget to a string or layout object:

```dart
@override
Object view() {
  return VBox(
    children: [
      Label('Count: $count', style: theme.bodyLarge),
      Label('Press ↑/↓ to change', style: theme.labelSmall),
    ],
  );
}
```

The return type is `Object`, allowing you to return:
- A `String` - rendered directly
- A layout widget (`VBox`, `HBox`, `Container`, etc.) - composed and rendered
- Any object with a `toString()` method

---

## Theme System

The theme system provides semantic colors and text styles for consistent UI appearance.

### Theme Class

```dart
class Theme {
  // Semantic Colors
  final Color primary;      // Primary accent (interactive elements)
  final Color secondary;    // Secondary accent
  final Color surface;      // Cards, panels
  final Color background;   // Main background
  final Color error;        // Error/danger
  final Color success;      // Success states
  final Color warning;      // Warning states
  final Color onPrimary;    // Text on primary
  final Color onSecondary;  // Text on secondary
  final Color onSurface;    // Text on surface
  final Color onBackground; // Text on background
  final Color onError;      // Text on error
  final Color muted;        // Dimmed text
  final Color border;       // Border color

  // Text Styles
  final Style titleLarge;   // Large titles
  final Style titleMedium;  // Medium titles
  final Style titleSmall;   // Small titles
  final Style bodyLarge;    // Large body text
  final Style bodyMedium;   // Medium body text
  final Style bodySmall;    // Small body text
  final Style labelLarge;   // Large labels
  final Style labelMedium;  // Medium labels
  final Style labelSmall;   // Small/dimmed labels
}
```

### Built-in Themes

#### Dark Theme

```dart
final theme = Theme.dark();
```

Cyan accents on dark gray backgrounds:
- Primary: Cyan (ANSI 39)
- Surface: Dark gray (ANSI 236)
- Background: Very dark gray (ANSI 233)
- Text: Light gray (ANSI 250-252)

#### Light Theme

```dart
final theme = Theme.light();
```

Blue accents on light backgrounds:
- Primary: Blue (ANSI 33)
- Surface: Light gray (ANSI 254)
- Background: White (ANSI 255)
- Text: Dark gray to black (ANSI 232-235)

#### Adaptive Theme (Recommended)

```dart
final theme = Theme.adaptive();
```

Automatically switches between light and dark based on terminal background detection. Uses `AdaptiveColor` for all color slots.

### Global Theme State

```dart
// Get the current theme
Theme get currentTheme;

// Check if terminal has dark background
bool get hasDarkBackground;

// Set a custom theme
void setTheme(Theme theme);

// Update dark background state manually
void setHasDarkBackground(bool value);

// Update from hex color (automatic luminance detection)
void updateThemeFromBackground(String? hex);
```

### Accessing Theme in Widgets

```dart
class MyWidget extends Widget {
  @override
  String get id => 'my-widget';

  @override
  Object view() {
    return VBox(children: [
      Label('Title', style: theme.titleLarge),
      Label('Subtitle', style: theme.titleSmall),
      Divider(),
      Label('Body text', style: theme.bodyMedium),
      Label('Muted hint', style: theme.labelSmall),
    ]);
  }
}
```

### Terminal Background Detection

Widgets automatically handle `BackgroundColorMsg` to update the theme state:

```dart
// In Widget.update() (automatic):
if (msg is BackgroundColorMsg) {
  updateThemeFromBackground(msg.hex);
}
```

The luminance calculation uses the standard formula:
```dart
final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
_hasDarkBackground = lum < 0.5;
```

### AdaptiveColor

Colors that automatically resolve based on terminal background:

```dart
const textColor = AdaptiveColor(
  light: AnsiColor(232), // Black on light backgrounds
  dark: AnsiColor(250),  // Light gray on dark backgrounds
);

// Usage in styles
Style().foreground(textColor);
```

### Custom Themes

```dart
final customTheme = Theme.dark().copyWith(
  primary: BasicColor('#ff5500'),
  secondary: BasicColor('#00ff55'),
  titleLarge: Style().bold().foreground(BasicColor('#ff5500')),
);

setTheme(customTheme);
```

---

## Layout Widgets

### Container

A widget that wraps a child with padding, sizing, and styling:

```dart
Container(
  child: myWidget,
  padding: EdgeInsets.all(2),
  width: 40,
  height: 10,
  background: theme.surface,
  foreground: theme.onSurface,
  align: HorizontalAlign.center,
  verticalAlign: VerticalAlign.center,
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `child` | `Widget?` | Child widget to wrap |
| `padding` | `EdgeInsets?` | Padding around the child |
| `width` | `int?` | Fixed width in characters |
| `height` | `int?` | Fixed height in lines |
| `background` | `Color?` | Background color |
| `foreground` | `Color?` | Text (foreground) color |
| `align` | `HorizontalAlign` | Horizontal alignment (default: left) |
| `verticalAlign` | `VerticalAlign` | Vertical alignment (default: top) |

**EdgeInsets:**

```dart
EdgeInsets.all(2)                           // All sides
EdgeInsets.symmetric(horizontal: 2, vertical: 1)
EdgeInsets.only(left: 1, right: 1, top: 0, bottom: 2)
EdgeInsets.zero                             // No padding
```

### Label

A widget for styled text:

```dart
Label('Hello, World!')
Label('Error!', style: Style().foreground(theme.error))
Label.styled('Success', style: theme.bodyLarge)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String` | Text content |
| `style` | `Style?` | Optional style to apply |

### HBox (Horizontal Box)

Arranges children horizontally:

```dart
HBox(
  gap: 2,
  align: VerticalAlign.center,
  children: [
    Label('Left'),
    Spacer(size: 4),
    Label('Right'),
  ],
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `children` | `List<Widget>` | Child widgets |
| `gap` | `int` | Gap between children (default: 1) |
| `align` | `VerticalAlign` | Vertical alignment (default: top) |

### VBox (Vertical Box)

Arranges children vertically:

```dart
VBox(
  gap: 1,
  align: HorizontalAlign.center,
  children: [
    Label('Header'),
    Divider(),
    Label('Content'),
    Label('Footer'),
  ],
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `children` | `List<Widget>` | Child widgets |
| `gap` | `int` | Gap between children (default: 0) |
| `align` | `HorizontalAlign` | Horizontal alignment (default: left) |

### Spacer

Fills space with a character:

```dart
Spacer()                    // 1 space (default)
Spacer(size: 10)            // 10 spaces
Spacer(size: 5, fill: '─')  // 5 horizontal lines
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `size` | `int` | Number of fill characters (default: 1) |
| `fill` | `String` | Fill character (default: ' ') |

### Divider

A horizontal line:

```dart
Divider()                   // ────────────
Divider(char: '═')          // ════════════
Divider(width: 20)          // 20 characters wide
Divider(style: Style().foreground(theme.primary))
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `width` | `int` | Width in characters (default: 40) |
| `char` | `String` | Line character (default: '─') |
| `style` | `Style?` | Optional style (default: theme.border) |

### Expanded

Wraps a child with a flex factor (for future flex layout support):

```dart
Expanded(
  flex: 2,
  child: myWidget,
)
```

---

## Creating Custom Widgets

### Basic Custom Widget

```dart
class Counter extends Widget {
  Counter({String? id}) : _id = id ?? 'counter';

  final String _id;
  int count = 0;

  @override
  String get id => _id;

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) => (this..count++, null),
      KeyMsg(key: Key(type: KeyType.down)) => (this..count--, null),
      _ => (this, null),
    };
  }

  @override
  Object view() {
    return Container(
      padding: EdgeInsets.all(1),
      background: theme.surface,
      child: VBox(children: [
        Label('Counter: $count', style: theme.titleMedium),
        Label('↑/↓ to change', style: theme.labelSmall),
      ]),
    );
  }
}
```

### Widget with Children

```dart
class Panel extends Widget {
  Panel({
    required this.title,
    required this.body,
    String? id,
  }) : _id = id ?? 'panel-${_counter++}';

  static int _counter = 0;

  final String _id;
  final String title;
  final Widget body;

  @override
  String get id => _id;

  @override
  List<Widget> get children => [body];

  @override
  Object view() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      background: theme.surface,
      child: VBox(children: [
        Label(title, style: theme.titleMedium),
        Divider(),
        StaticWidget(body.view()),
      ]),
    );
  }
}
```

### StaticWidget

For wrapping static content that doesn't need state:

```dart
class MyWidget extends Widget {
  @override
  String get id => 'my-widget';

  @override
  Object view() {
    return VBox(children: [
      StaticWidget('Static text'),
      StaticWidget(someView, id: 'custom-id'),
    ]);
  }
}
```

---

## Widget Composition

### Hierarchical Structure

```dart
class App extends Widget {
  @override
  String get id => 'app';

  final header = Header();
  final sidebar = Sidebar();
  final content = Content();
  final footer = Footer();

  @override
  List<Widget> get children => [header, sidebar, content, footer];

  @override
  Object view() {
    return VBox(children: [
      StaticWidget(header.view()),
      HBox(children: [
        StaticWidget(sidebar.view()),
        Container(width: 60, child: StaticWidget(content.view())),
      ]),
      StaticWidget(footer.view()),
    ]);
  }
}
```

### Nested Layouts

```dart
@override
Object view() {
  return Container(
    padding: EdgeInsets.all(1),
    background: theme.background,
    child: VBox(
      gap: 1,
      children: [
        // Header row
        Container(
          background: theme.surface,
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: HBox(children: [
            Label('App Title', style: theme.titleLarge),
            Spacer(size: 20),
            Label('v1.0.0', style: theme.labelSmall),
          ]),
        ),
        // Content
        Container(
          height: 20,
          child: contentWidget,
        ),
        // Footer
        Label('Press q to quit', style: theme.labelSmall),
      ],
    ),
  );
}
```

---

## Message Propagation

Messages flow through the widget tree in a specific order:

### Propagation Order

1. **Parent receives message**
2. **Parent forwards to all children** (in order)
3. **Parent handles the message itself** (via `handleUpdate`)
4. **Commands from all handlers are batched**

```dart
// In Widget.update() (simplified):
(Model, Cmd?) update(Msg msg) {
  final cmds = <Cmd>[];

  // 1. Handle background color detection
  if (msg is BackgroundColorMsg) {
    updateThemeFromBackground(msg.hex);
  }

  // 2. Forward to all children
  for (final child in children) {
    final (_, cmd) = child.update(msg);
    if (cmd != null) cmds.add(cmd);
  }

  // 3. Handle own messages
  final (newWidget, cmd) = handleUpdate(msg);
  if (cmd != null) cmds.add(cmd);

  return (newWidget, cmds.isEmpty ? null : Cmd.batch(cmds));
}
```

### Example: Message Flow

```dart
class Parent extends Widget {
  @override
  String get id => 'parent';

  final child1 = Child1();
  final child2 = Child2();

  @override
  List<Widget> get children => [child1, child2];

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) {
    // This runs AFTER child1 and child2 have handled the message
    print('Parent handling: $msg');
    return (this, null);
  }
}
```

When a `KeyMsg` arrives:
1. `child1.update(KeyMsg)` is called
2. `child2.update(KeyMsg)` is called
3. `Parent.handleUpdate(KeyMsg)` is called
4. All commands are batched and returned

---

## Focus Management

### FocusableWidget Mixin

```dart
class TextInput extends Widget with FocusableWidget {
  @override
  String get id => 'text-input';

  String value = '';

  @override
  void onFocus() {
    super.onFocus();
    // Input received focus
  }

  @override
  void onBlur() {
    super.onBlur();
    // Input lost focus
  }

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) {
    if (!focused) return (this, null);

    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.runes, :final runes)) => (
        this..value += String.fromCharCodes(runes),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.backspace)) when value.isNotEmpty => (
        this..value = value.substring(0, value.length - 1),
        null,
      ),
      _ => (this, null),
    };
  }

  @override
  Object view() {
    final style = focused 
        ? Style().foreground(theme.primary) 
        : Style().foreground(theme.muted);
    return Label('> $value${focused ? '█' : ''}', style: style);
  }
}
```

### FocusableWidget Properties

| Property | Type | Description |
|----------|------|-------------|
| `focused` | `bool` | Whether widget has focus |
| `focusable` | `bool` | Always `true` when using mixin |

### FocusableWidget Methods

| Method | Description |
|--------|-------------|
| `onFocus()` | Called when widget receives focus |
| `onBlur()` | Called when widget loses focus |

---

## Integration with TUI Program

Widgets implement the `Model` interface and can be run directly with `Program`:

```dart
void main() async {
  final app = MyApp();
  final program = Program(app);
  await program.run();
}
```

### With Program Options

```dart
void main() async {
  final app = MyApp();
  final program = Program(
    app,
    options: ProgramOptions(
      altScreen: true,
      mouse: true,
      fps: 60,
    ),
  );
  await program.run();
}
```

### Convenience Helper

```dart
void main() async {
  await runProgram(MyApp());
}
```

### Key Messages

Widgets commonly handle these message types:

```dart
@override
(Widget, Cmd?) handleUpdate(Msg msg) {
  return switch (msg) {
    // Keyboard
    KeyMsg(key: Key(type: KeyType.enter)) => _submit(),
    KeyMsg(key: Key(type: KeyType.escape)) => _cancel(),
    KeyMsg(key: Key(type: KeyType.up)) => _moveUp(),
    KeyMsg(key: Key(type: KeyType.down)) => _moveDown(),
    KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()), // Ctrl+C
    
    // Window resize
    WindowSizeMsg(:final width, :final height) => _resize(width, height),
    
    // Mouse (when enabled)
    MouseMsg(action: MouseAction.press, :final x, :final y) => _click(x, y),
    
    // Animation frames
    FrameTickMsg(:final delta) => _animate(delta),
    
    // Background color detected
    BackgroundColorMsg(:final hex) => _updateTheme(hex),
    
    _ => (this, null),
  };
}
```

---

## Integration with UV Canvas

The Container widget uses the UV Canvas system for rendering:

### How Container Renders

```dart
// Simplified Container.view() implementation:
@override
Object view() {
  final contentStr = child != null ? _viewToString(child!.view()) : '';
  
  // Calculate dimensions
  final contentWidth = Layout.getWidth(contentStr);
  final contentHeight = Layout.getHeight(contentStr);
  
  // Create Canvas
  final canvas = Canvas(targetWidth, targetHeight);
  
  // Fill with background
  final bgColor = _colorToUvColor(background);
  final bgStyle = UvStyle(bg: bgColor, fg: fgColor);
  final bgCell = Cell(content: ' ', width: 1, style: bgStyle);
  
  for (var y = 0; y < targetHeight; y++) {
    for (var x = 0; x < targetWidth; x++) {
      canvas.setCell(x, y, bgCell.clone());
    }
  }
  
  // Draw child content
  _drawStyledContent(canvas, contentStr, offsetX, offsetY, bgStyle);
  
  return canvas.render();
}
```

### Color Conversion

Colors are converted from the Style system to UV colors:

```dart
UvColor? _colorToUvColor(Color? color) {
  if (color == null || color is NoColor) return null;

  // Resolve AdaptiveColor based on hasDarkBackground
  Color resolved = color;
  if (color is AdaptiveColor) {
    resolved = hasDarkBackground ? color.dark : color.light;
  }

  // Convert hex to RGB
  final hex = resolved.toHex();
  final r = int.tryParse(hex.substring(1, 3), radix: 16) ?? 0;
  final g = int.tryParse(hex.substring(3, 5), radix: 16) ?? 0;
  final b = int.tryParse(hex.substring(5, 7), radix: 16) ?? 0;

  return UvColor.rgb(r, g, b);
}
```

### Canvas Basics

```dart
// Create a canvas
final canvas = Canvas(80, 24);

// Set individual cells
canvas.setCell(x, y, Cell(
  content: 'A',
  width: 1,
  style: UvStyle(fg: UvColor.rgb(255, 0, 0)),
));

// Get cell at position
final cell = canvas.cellAt(x, y);

// Render to string
final output = canvas.render();
```

### Layout Utilities

The Layout class provides string manipulation utilities:

```dart
// Join horizontally
Layout.joinHorizontal(VerticalAlign.top, [left, right], gap: 2);

// Join vertically
Layout.joinVertical(HorizontalAlign.center, [top, middle, bottom], gap: 1);

// Get dimensions
final width = Layout.getWidth(content);
final height = Layout.getHeight(content);
final size = Layout.getSize(content); // (width: int, height: int)

// Visible length (ignoring ANSI codes)
final visible = Layout.visibleLength(styledText);

// Place content in container
Layout.place(
  width: 80,
  height: 24,
  horizontal: HorizontalAlign.center,
  vertical: VerticalAlign.center,
  content: 'Centered!',
);
```

---

## Quick Reference

### Widget Template

```dart
class MyWidget extends Widget {
  MyWidget({String? id}) : _id = id ?? 'my-widget';

  final String _id;

  @override
  String get id => _id;

  @override
  List<Widget> get children => const [];

  @override
  Cmd? handleInit() => null;

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) => (this, null);

  @override
  Object view() => '';
}
```

### Common Patterns

```dart
// Styled text
Label('Error!', style: Style().foreground(theme.error).bold())

// Centered container
Container(
  width: 40,
  align: HorizontalAlign.center,
  child: Label('Centered'),
)

// Padded panel
Container(
  padding: EdgeInsets.all(2),
  background: theme.surface,
  child: content,
)

// Horizontal layout with gap
HBox(gap: 2, children: [left, middle, right])

// Vertical layout with gap  
VBox(gap: 1, children: [header, content, footer])

// Divider line
Divider(width: 60, char: '═')

// Flexible spacer
Spacer(size: 10)
```

### Alignment Constants

```dart
// Horizontal
HorizontalAlign.left
HorizontalAlign.center
HorizontalAlign.right

// Vertical
VerticalAlign.top
VerticalAlign.center
VerticalAlign.bottom
```
