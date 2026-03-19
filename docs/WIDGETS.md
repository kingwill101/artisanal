# Widget Composition System

Artisanal's Widget system provides a composable, hierarchical approach to building terminal user interfaces. Built on top of the Model pattern (Elm Architecture), Widgets extend it with automatic message forwarding, theme access, and layout primitives.

## Table of Contents

- [Overview](#overview)
- [Widget Base Class](#widget-base-class)
- [Keys and Debugging](#keys-and-debugging)
- [Widget Lifecycle](#widget-lifecycle)
- [Theme System](#theme-system)
- [Layout Widgets](#layout-widgets)
- [Focus Widgets](#focus-widgets)
- [Input Widgets](#input-widgets)
- [Scroll Widgets](#scroll-widgets)
- [Components Widgets](#components-widgets)
  - [Flutter-style ports](#flutter-style-ports)
- [Navigation Widgets](#navigation-widgets)
- [Selection Widgets](#selection-widgets)
- [Chart Widgets](#chart-widgets)
- [Media Widgets](#media-widgets)
- [Animation Widgets](#animation-widgets)
- [Creating Custom Widgets](#creating-custom-widgets)
  - [RenderObject widgets](#renderobject-widgets)
- [Widget Composition](#widget-composition)
- [Message Propagation](#message-propagation)
- [Focus Management](#focus-management)
- [Integration with TUI Program](#integration-with-tui-program)
- [Integration with UV Canvas](#integration-with-uv-canvas)
- [Quick Reference](#quick-reference)
- [Related Docs](#related-docs)

---

## Overview

The Widget system provides:

- **Hierarchical composition** - Build complex UIs from smaller, reusable widgets
- **Automatic message forwarding** - Parent widgets forward messages to children
- **Built-in theming** - Access semantic colors and text styles via `theme`
- **Layout primitives** - `Row`, `Column`, `Wrap`, `Stack`, `Container`, `Text`, `Icon`, `Spacer`, `Divider` (aliases: `HBox`, `VBox`, `Label`)
- **Adaptive styling** - Colors that auto-switch between light and dark terminals

Stable top-level entrypoints:

- `package:artisanal/app.dart` and `package:artisanal_widgets/app.dart` for app shells, runners, reload helpers, and hosted wrappers
- `package:artisanal/widgets.dart` and `package:artisanal_widgets/widgets.dart` for the main widget/app/layout/input/navigation surface, including `KeyMap`/`KeyBinding` for shortcut-oriented components like `HelpView` and zone-hit messages like `ZoneInBoundsMsg` for interactive demos
- `package:artisanal_widgets/charting.dart` for chart widgets
- `package:artisanal/editors.dart` and `package:artisanal_widgets/editors.dart` for text inputs, higher-level editors, and stable `TextInputKeyMap` / `TextAreaKeyMap` customization
- `package:artisanal/selection.dart` and `package:artisanal_widgets/selection.dart` for text selection widgets
- `package:artisanal/testing.dart` and `package:artisanal_widgets/testing.dart` for `WidgetTester`

The older `package:artisanal_widgets/artisanal_widgets.dart` import remains
available as the broader experimental compatibility surface.

The local runner helpers (`runWidgetApp`, `runArtisanalApp`, watched/reloadable
variants) and the hosted browser/socket helpers all accept an `imageAutoMode`
override. Local runners keep the default environment-driven behavior. Hosted
browser/socket runners now default to `ImageAutoMode.sessionCapabilities`, so
`Image(renderMode: ImageRenderMode.auto)` can follow terminal version and
device-attribute reports from the active remote session instead of only the
server process environment. Override `imageAutoMode` when you want to force
portable half-block rendering or another explicit mode.

```dart
import 'package:artisanal_widgets/app.dart';
import 'package:artisanal_widgets/widgets.dart';

class MyApp extends Widget {
  final header = Text('My Application', style: Style().bold());
  final content = Column(children: [
    Text('Line 1'),
    Text('Line 2'),
  ]);

  @override
  List<Widget> get children => [header, content];

  @override
  Object view() {
    return Column(
      gap: 1,
      children: [
        Text('Title', style: theme.titleLarge),
        Row(
          gap: 2,
          children: [Text('Left'), Text('Right')],
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
  /// Key for preserving identity.
  Key get key;

  /// Unique identifier for this widget.
  String get id =>
      key is ValueKey<String> ? (key as ValueKey<String>).value : key.toString();

  /// Child widgets that receive forwarded messages.
  List<Widget> get children => const [];

  /// Whether this widget can receive keyboard focus.
  bool get focusable => false;

  /// Access the current theme.
  Theme get theme => currentTheme;
}
```

### Keys

Use widget keys to preserve identity (and to derive zone IDs automatically):

```dart
import 'package:artisanal_widgets/widgets.dart' as w;

w.Text('Title', key: const w.Key('title'))
```

When no key is provided, widgets are matched by `runtimeType` and tree position.
Pass a stable key only when you need identity preserved across reordering.

### WidgetApp

Use `WidgetApp` to render widgets through the element tree (required for
`StatefulWidget`):

```dart
import 'package:artisanal/runtime.dart';
import 'package:artisanal_widgets/app.dart';

final app = WidgetApp(MyRoot(), scanZones: true);
runProgram(
  app,
  options: const ProgramOptions(mouseMode: MouseMode.allMotion),
);
```

For the common fullscreen widget case, use the higher-level runners:

```dart
await runWidgetApp(WidgetApp(MyRoot()));

await runArtisanalApp(
  ArtisanalApp(
    title: 'Demo',
    themeMode: ThemeMode.system,
    home: MyRoot(),
  ),
);
```

Use `theme` / `darkTheme` with `themeMode` when you want an explicit light and
dark pair instead of the default adaptive palette:

```dart
await runArtisanalApp(
  ArtisanalApp(
    title: 'Docs',
    theme: Theme.light(),
    darkTheme: Theme.dark(),
    themeMode: ThemeMode.dark,
    home: DocsScreen(),
  ),
);
```

The same runner layer can also target browser and raw-socket hosts:

```dart
final browserHost = await serveArtisanalAppInBrowser(
  browserTitle: 'Browser Demo',
  appBuilder: () => ArtisanalApp(
    title: 'Browser Demo',
    home: MyRoot(),
  ),
);

final socketHost = await serveArtisanalAppOnSocket(
  appBuilder: () => ArtisanalApp(
    title: 'Socket Demo',
    home: MyRoot(),
  ),
);
```

Use the browser host when you want an xterm.js-backed remote session, and the
socket host when you want a raw TCP terminal stream managed by your own client.

Hosted browser and socket runners default `Image(renderMode: ImageRenderMode.auto)`
to `ImageAutoMode.sessionCapabilities`, so remote terminals can upgrade from
portable half-block rendering when they answer device/version queries. Override
`imageAutoMode` when the hosted surface should stay portable-only or when you
need another explicit mode.

`WidgetTester` uses the same portable fallback by default so widget tests stay
deterministic regardless of the terminal they were launched from.

When using `ArtisanalApp` with a `DebugConsoleController`, you can also opt
into automatic `print()` and uncaught zone error capture:

```dart
final console = DebugConsoleController(initiallyVisible: true);

await runArtisanalApp(
  ArtisanalApp(
    title: 'Diagnostics',
    debugConsoleController: console,
    debugConsoleCapturePrint: true,
    debugConsoleCaptureErrors: true,
    home: DiagnosticsScreen(),
  ),
);
```

Set `scanZones: true` when you want automatic zone scanning at the root.
Use `debugRebuilds: true` to log dirty element rebuilds.

`WidgetApp` runs collected widget/state `handleInit()` commands via
`ParallelCmd`, which ensures runtime-managed commands (for example
`EveryCmd`/`StreamCmd`) are started correctly.

### Development Reloads

Use `ReloadHost` with a `ReloadController` when you want a subtree that can be
rebuilt or fully restarted from an editor hook, file watcher, or in-app
shortcut:

```dart
final controller = ReloadController();

await runArtisanalApp(
  ArtisanalApp(
    title: 'Reload Demo',
    home: ReloadHost(
      controller: controller,
      builder: (context, revision) => MyRoot(revision: revision),
    ),
  ),
);

controller.reload();  // rebuild, preserve compatible state
controller.restart(); // remount from scratch
```

For a lightweight local development loop, pair the controller with
`ReloadFileWatcher`:

```dart
final controller = ReloadController();
final watcher = await ReloadFileWatcher.watch(
  controller: controller,
  roots: const ['lib', 'test'],
  extensions: const ['.dart'],
);

await runArtisanalApp(
  ArtisanalApp(
    title: 'Reload Demo',
    home: ReloadHost(
      controller: controller,
      builder: (context, revision) => MyRoot(revision: revision),
    ),
  ),
);

await watcher.dispose();
await controller.dispose();
```

Use `mode: ReloadMode.restart` when changed files should force a full remount
instead of a state-preserving rebuild.

For the common case, the runner helpers can own the watcher lifecycle:

```dart
await runWatchedArtisanalApp(
  title: 'Reload Demo',
  watchRoots: const ['lib', 'test'],
  homeBuilder: (context, revision) => MyRoot(revision: revision),
);
```

To expose the same reload flow through the browser host, use
`serveWatchedArtisanalAppInBrowser(...)`. See
[`pkgs/artisanal_widgets/example/browser_host/main.dart`](../pkgs/artisanal_widgets/example/browser_host/main.dart)
for a complete example.

The watched browser/socket host wrappers also expose `close(force: true)` when
you need to tear down active remote sessions immediately during test cleanup or
development restarts. Forced close still waits for the wrapped host session
cleanup to finish before the wrapper returns.

If you want manual control over when reloads happen, use the app-shell helper
without a watcher:

```dart
final controller = ReloadController();

await runReloadableArtisanalApp(
  title: 'Reload Demo',
  controller: controller,
  homeBuilder: (context, revision) => MyRoot(revision: revision),
);
```

### Build Owner and Dirty Elements

`BuildOwner` tracks dirty elements that need rebuilding. When an element
rebuilds or unmounts, it must remove itself from the dirty set. If elements
remain in the dirty set after rebuild/unmount, the dirty queue grows over time
and render latency increases on every frame.

### BuildContext helpers

```dart
final inherited = context.dependOnInheritedWidgetOfExactType<MyTheme>();
final state = context.findAncestorStateOfType<MyState>();
```

### InheritedWidget Example

```dart
class Accent extends InheritedWidget {
  Accent({required this.color, required super.child});

  final Color color;

  static Accent? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Accent>();
  }

  @override
  bool updateShouldNotify(covariant Accent oldWidget) {
    return oldWidget.color != color;
  }
}

class AccentLabel extends StatelessWidget {
  AccentLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Accent.of(context)?.color ?? Colors.muted;
    return Text('Accent', style: Style().foreground(accent));
  }
}
```

### StatelessWidget and StatefulWidget

```dart
class Title extends StatelessWidget {
  Title({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: theme.titleLarge);
  }
}

class Counter extends StatefulWidget {
  Counter({super.key});

  @override
  State createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Text('Count: $count');
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg && msg.key.char == '+') {
      setState(() => count++);
    }
    return null;
  }
}
```

### Key Differences from Model

| Feature | Model | Widget |
|---------|-------|--------|
| Message handling | Manual | Auto-forwards to children first |
| Theme access | Manual | Built-in `theme` getter |
| Identification | None | Key-based identity |
| Composition | Manual | Declarative `children` list |
| Background detection | Manual | Automatic via `BackgroundColorMsg` |

---

## Keys and Debugging

```dart
class Header extends Widget {
  Header({super.key});

  @override
  Object view() => Text('Title');
}

void main() {
  print(Header(key: const Key('header'))); // Widget([<'header'>])
}
```

## Widget Lifecycle

### Initialization (`init` / `handleInit`)

When a widget is first mounted, `init()` is called. The default implementation:

1. Requests the terminal background color (for adaptive theming)
2. Calls `init()` on all children
3. Calls `handleInit()` for widget-specific initialization
4. Returns a combined command

When mounted through `WidgetApp`, collected `handleInit()` commands are executed
via `ParallelCmd` so runtime-managed commands (for example timers/streams) are
started by `Program`.

```dart
class MyWidget extends Widget {
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
    return Column(
      children: [
        Text('Count: $count', style: theme.bodyLarge),
        Text('Press ↑/↓ to change', style: theme.labelSmall),
      ],
    );
}
```

The return type is `Object`, allowing you to return:
- A `String` - rendered directly
- A layout widget (`Column`, `Row`, `Container`, etc.) - composed and rendered
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
  Object view() {
    return Column(children: [
      Text('Title', style: theme.titleLarge),
      Text('Subtitle', style: theme.titleSmall),
      Divider(),
      Text('Body text', style: theme.bodyMedium),
      Text('Muted hint', style: theme.labelSmall),
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

Implemented layout widgets are grouped as follows:

- **Core text/display:** `Text`, `Text.rich`, `RichText`, `Label`, `Icon`,
  `MarkdownText`, `AsciiText`, `StyledAsciiText`, `Image`
- **Flex/layout primitives:** `Flex`, `Row`, `Column`, `HBox`, `VBox`, `Wrap`,
  `Spacer`, `Flexible`, `Expanded`, `Divider`, `VerticalDivider`
- **Sizing/alignment:** `Container`, `Padding`, `Align`, `Center`, `SizedBox`,
  `ConstrainedBox`, `LimitedBox`, `OverflowBox`, `SizedOverflowBox`,
  `ShrinkWrap`, `Positioned`, `Stack`
- **Decorators/effects:** `Opacity`, `Tint`, `AnimatedTint`, `FadeTint`,
  `ColoredBox`, `DecoratedBox`, `ClipRect`, `Transform`, `Visibility`
- **Event wrappers/utilities:** `GestureDetector`, `MouseRegion`, `Zone`,
  `KeyboardListener`, `BlockFocus`, `IgnorePointer`, `Builder`,
  `LayoutBuilder`, `TUIErrorWidget`, `ErrorThrowingWidget`

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
| `margin` | `EdgeInsets?` | Margin outside the container |
| `width` | `num?` | Fixed width in characters |
| `height` | `num?` | Fixed height in lines |
| `color` | `Color?` | Background color (preferred) |
| `decoration` | `BoxDecoration?` | Background decoration (Decoration alias) |
| `foregroundDecoration` | `BoxDecoration?` | Foreground decoration (Decoration alias) |
| `background` | `Color?` | Background color (legacy) |
| `foreground` | `Color?` | Text (foreground) color (legacy) |
| `alignment` | `Alignment?` | Flutter-like alignment (overrides align/verticalAlign) |
| `align` | `HorizontalAlign` | Horizontal alignment (default: left) |
| `verticalAlign` | `VerticalAlign` | Vertical alignment (default: top) |

**EdgeInsets:**

```dart
EdgeInsets.all(2)                           // All sides
EdgeInsets.symmetric(horizontal: 2, vertical: 1)
EdgeInsets.only(left: 1, right: 1, top: 0, bottom: 2)
EdgeInsets.zero                             // No padding
```

**BoxDecoration:**

```dart
Container(
  decoration: const BoxDecoration(color: Colors.gray800),
  child: Text('Decorated'),
)
```

### Text

A widget for styled text:

```dart
Text('Hello, World!')
Text('Error!', style: Style().foreground(theme.error))
Text.rich(
  TextSpan(text: 'Success', style: theme.bodyLarge),
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `data` | `String` | Text content |
| `style` | `Style?` | Optional style to apply |

### Icon

Displays a single glyph icon:

```dart
Icon(Icons.star, color: theme.warning)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `icon` | `IconData` | Glyph to render |
| `color` | `Color?` | Foreground color |
| `style` | `Style?` | Optional style |
| `size` | `num?` | Square size (cells) |

### Row

Arranges children horizontally:

```dart
Row(
  gap: 2,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('Left'),
    Spacer(size: 4),
    Text('Right'),
  ],
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `children` | `List<Widget>` | Child widgets |
| `gap` | `num` | Gap between children (default: 0) |
| `crossAxisAlignment` | `CrossAxisAlignment` | Cross axis alignment (default: start) |

### Wrap

Wraps children into multiple lines:

```dart
Wrap(
  spacing: 1,
  runSpacing: 1,
  children: [
    Text('One'),
    Text('Two'),
    Text('Three'),
  ],
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `direction` | `Axis` | Wrap axis (default: horizontal) |
| `spacing` | `num` | Gap between items |
| `runSpacing` | `num` | Gap between runs |
| `alignment` | `WrapAlignment` | Item alignment within runs |
| `runAlignment` | `WrapAlignment` | Run alignment within container |
| `crossAxisAlignment` | `WrapCrossAlignment` | Cross axis alignment |

### Column

Arranges children vertically:

```dart
Column(
  gap: 1,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('Header'),
    Divider(),
    Text('Content'),
    Text('Footer'),
  ],
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `children` | `List<Widget>` | Child widgets |
| `gap` | `num` | Gap between children (default: 0) |
| `crossAxisAlignment` | `CrossAxisAlignment` | Cross axis alignment (default: start) |

### Spacer

Fills space with a character:

```dart
Spacer()                    // 1 space (default)
Spacer(size: 10)            // 10 spaces
Spacer(size: 5, fill: '─')  // 5 horizontal lines
Spacer.flex(flex: 2)         // Flexible spacing
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `size` | `int` | Number of fill characters (default: 1) |
| `fill` | `String` | Fill character (default: ' ') |
| `flex` | `int?` | Optional flex factor |

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

### Stack

Overlay children on top of each other:

```dart
Stack(
  alignment: Alignment.center,
  children: [
    Container(width: 20, height: 5, color: theme.surface),
    Text('Overlay', style: theme.titleSmall),
    Positioned(
      right: 1,
      bottom: 0,
      child: Text('Badge', style: theme.labelSmall),
    ),
  ],
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `alignment` | `Alignment` | Align non-positioned children (default: topLeft) |
| `fit` | `StackFit` | How non-positioned children should fit (default: loose) |
| `overflow` | `Overflow` | Clip or allow overflow (default: clip) |
| `width` | `num?` | Fixed width in characters |
| `height` | `num?` | Fixed height in lines |

### Positioned

Positions a child inside a [Stack]:

```dart
Positioned(
  left: 2,
  top: 1,
  child: Text('Pinned'),
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `left`/`right` | `num?` | Horizontal offsets |
| `top`/`bottom` | `num?` | Vertical offsets |
| `width` | `num?` | Force child width |
| `height` | `num?` | Force child height |

### GestureDetector

Handles mouse gestures using a typed recognizer-based system. Each gesture type
(tap, double-tap, long-press, drag) is processed by a dedicated `GestureRecognizer`
that interprets raw mouse events and emits typed detail objects.

```dart
GestureDetector(
  onTap: () => Cmd.message(MyClickMsg()),
  onTapDown: (details) => Cmd.message(TapMsg(details.globalPosition)),
  onDoubleTap: () => Cmd.message(const DoubleTapMsg()),
  onLongPress: () => Cmd.message(const LongPressMsg()),
  onDragUpdate: (details) => Cmd.message(DragMsg(details.delta)),
  onEnter: (_) => Cmd.message(const HoverMsg(true)),
  onExit: (_) => Cmd.message(const HoverMsg(false)),
  behavior: HitTestBehavior.opaque,
  child: Text('Clickable'),
)
```

Drag callbacks capture the mouse so movement continues outside the zone.
Use `MouseMode.cellMotion` or `MouseMode.allMotion` in `ProgramOptions`.

> **Breaking Change:** Callbacks no longer take raw `MouseMsg` parameters.
> Tap/double-tap/long-press/drag callbacks use typed detail objects (or no
> parameter). Only `onEnter`, `onExit`, and `onWheel` still receive `MouseMsg`.
> See [Migration Guide](#gesture-migration-guide) below.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `child` | `Widget?` | Child widget |
| `onTap` | `Cmd? Function()?` | Tap completed (no parameter) |
| `onTapDown` | `Cmd? Function(TapDownDetails)?` | Pointer pressed down |
| `onTapUp` | `Cmd? Function(TapUpDetails)?` | Pointer released |
| `onTapCancel` | `Cmd? Function()?` | Tap cancelled (moved too far) |
| `onDoubleTap` | `Cmd? Function()?` | Two taps within 300ms |
| `onLongPress` | `Cmd? Function()?` | Press held for 500ms |
| `onLongPressStart` | `Cmd? Function(LongPressStartDetails)?` | Long press recognized |
| `onLongPressEnd` | `Cmd? Function(LongPressEndDetails)?` | Long press released |
| `onDragStart` | `Cmd? Function(DragStartDetails)?` | Drag begins (after slop) |
| `onDragUpdate` | `Cmd? Function(DragUpdateDetails)?` | Drag movement |
| `onDragEnd` | `Cmd? Function(DragEndDetails)?` | Drag released |
| `onEnter` | `Cmd? Function(MouseMsg)?` | Pointer enters zone |
| `onExit` | `Cmd? Function(MouseMsg)?` | Pointer exits zone |
| `onWheel` | `Cmd? Function(MouseMsg)?` | Scroll wheel event |
| `behavior` | `HitTestBehavior` | Hit test strategy (default: `deferToChild`) |
| `enabled` | `bool` | Enable/disable all gestures (default: `true`) |
| `captureMouse` | `bool` | Capture mouse during drags (default: `false`) |

---

### Gesture System

The gesture system uses a recognizer-based architecture inspired by Flutter's
gesture arena, adapted for terminal mouse events and the TEA (The Elm
Architecture) command pattern.

#### How It Works

1. **Raw mouse events** (`MouseMsg`) arrive from the terminal
2. **Hit testing** determines which widgets are under the pointer (using `HitTestBehavior`)
3. **GestureDetector** routes events to its **GestureRecognizers**
4. Each recognizer **interprets the event stream** and fires typed callbacks
5. Callbacks return `Cmd?` values that flow back through the TEA update cycle

#### HitTestBehavior

Controls how a `GestureDetector` participates in hit testing:

| Value | Description |
|-------|-------------|
| `deferToChild` | (Default) Only receives events if a child was hit |
| `opaque` | Receives events even if no child was hit; blocks widgets behind it |
| `translucent` | Receives events even if no child was hit; allows widgets behind it to also receive events |

```dart
// Invisible tap zone that covers the full area
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => Cmd.message(const BackgroundTapMsg()),
  child: Container(width: 40, height: 10),
)
```

#### Gesture Recognizers

Each gesture type is handled by a dedicated recognizer class. These are created
automatically by `GestureDetector` based on which callbacks are provided.

| Recognizer | Callbacks | Constants |
|------------|-----------|-----------|
| `TapGestureRecognizer` | `onTap`, `onTapDown`, `onTapUp`, `onTapCancel` | `kTouchSlop = 2.0` cells |
| `DoubleTapGestureRecognizer` | `onDoubleTap` | `doubleTapTimeout = 300ms`, `kDoubleTapSlop = 2.0` cells |
| `LongPressGestureRecognizer` | `onLongPress`, `onLongPressStart`, `onLongPressEnd` | `duration = 500ms`, `kTouchSlop = 2.0` cells |
| `DragGestureRecognizer` | `onDragStart`, `onDragUpdate`, `onDragEnd` | `kDragSlop = 1.0` cell |

**Slop thresholds** prevent accidental gesture triggers. A tap is cancelled if
the pointer moves more than `kTouchSlop` cells from the down position. A drag
only starts after the pointer moves more than `kDragSlop` cells.

#### Gesture Detail Classes

Typed detail objects replace raw `MouseMsg` in gesture callbacks:

**TapDownDetails** — Fired when the pointer is pressed down.

| Field | Type | Description |
|-------|------|-------------|
| `globalPosition` | `Offset` | Position in terminal coordinates |
| `localPosition` | `Offset` | Position relative to the widget |
| `button` | `int` | Mouse button (0 = left, 1 = middle, 2 = right) |
| `ctrl` | `bool` | Ctrl modifier held |
| `alt` | `bool` | Alt modifier held |
| `shift` | `bool` | Shift modifier held |
| `hasModifier` | `bool` | Any modifier held |

**TapUpDetails** — Fired when the pointer is released (tap completed).

| Field | Type | Description |
|-------|------|-------------|
| `globalPosition` | `Offset` | Position in terminal coordinates |
| `localPosition` | `Offset` | Position relative to the widget |

**DragStartDetails** — Fired when a drag gesture begins.

| Field | Type | Description |
|-------|------|-------------|
| `globalPosition` | `Offset` | Position in terminal coordinates |
| `localPosition` | `Offset` | Position relative to the widget |
| `button` | `int` | Mouse button initiating the drag |

**DragUpdateDetails** — Fired on each drag movement.

| Field | Type | Description |
|-------|------|-------------|
| `globalPosition` | `Offset` | Current position in terminal coordinates |
| `localPosition` | `Offset` | Current position relative to the widget |
| `delta` | `Offset` | Movement since last update (`dx`, `dy`) |

**DragEndDetails** — Fired when the drag is released.

| Field | Type | Description |
|-------|------|-------------|
| `globalPosition` | `Offset` | Final position in terminal coordinates |
| `localPosition` | `Offset` | Final position relative to the widget |

**LongPressStartDetails** — Fired when a long press is recognized.

| Field | Type | Description |
|-------|------|-------------|
| `globalPosition` | `Offset` | Position in terminal coordinates |
| `localPosition` | `Offset` | Position relative to the widget |

**LongPressEndDetails** — Fired when a long press is released.

| Field | Type | Description |
|-------|------|-------------|
| `globalPosition` | `Offset` | Position in terminal coordinates |
| `localPosition` | `Offset` | Position relative to the widget |

#### Callback Type Reference

| Typedef | Signature |
|---------|-----------|
| `GestureTapCallback` | `Cmd? Function()` |
| `GestureTapDownCallback` | `Cmd? Function(TapDownDetails)` |
| `GestureTapUpCallback` | `Cmd? Function(TapUpDetails)` |
| `GestureTapCancelCallback` | `Cmd? Function()` |
| `GestureDoubleTapCallback` | `Cmd? Function()` |
| `GestureLongPressCallback` | `Cmd? Function()` |
| `GestureLongPressStartCallback` | `Cmd? Function(LongPressStartDetails)` |
| `GestureLongPressEndCallback` | `Cmd? Function(LongPressEndDetails)` |
| `GestureDragStartCallback` | `Cmd? Function(DragStartDetails)` |
| `GestureDragUpdateCallback` | `Cmd? Function(DragUpdateDetails)` |
| `GestureDragEndCallback` | `Cmd? Function(DragEndDetails)` |
| `GestureWheelCallback` | `Cmd? Function(MouseMsg)` |
| `MouseEnterCallback` | `Cmd? Function(MouseMsg)` |
| `MouseExitCallback` | `Cmd? Function(MouseMsg)` |

#### Gesture Migration Guide

If upgrading from the old `MouseMsg`-based callback API:

**Tap callbacks** — Remove the parameter:

```dart
// Before:
onTap: (_) => Cmd.message(MyClickMsg()),
// After:
onTap: () => Cmd.message(MyClickMsg()),
```

**Tap down/up** — Use typed details instead of `MouseMsg`:

```dart
// Before:
onTapDown: (msg) => Cmd.message(DownMsg(msg.x, msg.y)),
// After:
onTapDown: (details) => Cmd.message(DownMsg(
  details.globalPosition.dx.toInt(),
  details.globalPosition.dy.toInt(),
)),
```

**Drag callbacks** — Use `DragUpdateDetails.delta` for movement:

```dart
// Before:
onDragUpdate: (msg) => Cmd.message(DragMsg(msg.x, msg.y)),
// After:
onDragUpdate: (details) => Cmd.message(DragMsg(
  details.delta.dx.toInt(),
  details.delta.dy.toInt(),
)),
```

**New capabilities** — These gestures had no equivalent in the old API:

```dart
onDoubleTap: () => Cmd.message(const DoubleTapMsg()),
onLongPress: () => Cmd.message(const LongPressMsg()),
onLongPressStart: (details) => ...,
onLongPressEnd: (details) => ...,
onTapCancel: () => ...,
```

**Unchanged callbacks** — `onEnter`, `onExit`, and `onWheel` still take `MouseMsg`:

```dart
onEnter: (msg) => Cmd.message(HoverMsg(msg.x, msg.y)),
onExit: (msg) => Cmd.message(const ExitMsg()),
onWheel: (msg) => Cmd.message(ScrollMsg(msg.wheelDelta)),
```

### MouseRegion

Tracks pointer movement without click semantics:

```dart
MouseRegion(
  onEnter: (_) => Cmd.message(const HoverMsg(true)),
  onExit: (_) => Cmd.message(const HoverMsg(false)),
  onHover: (_) => Cmd.message(const HoverMsg(true)),
  child: Text('Hover me'),
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `onEnter` | `Cmd? Function(MouseMsg)?` | Pointer enter |
| `onExit` | `Cmd? Function(MouseMsg)?` | Pointer exit |
| `onHover` | `Cmd? Function(MouseMsg)?` | Motion callback |
| `onMouse` | `Cmd? Function(MouseMsg)?` | Raw mouse callback |

### Opacity

Opacity is a no-op in terminal rendering, but useful for API parity:

```dart
Opacity(opacity: 0.5, child: Text('Muted'))
```

### Expanded

Wraps a child with a flex factor and a tight fit so it fills its allocated
share of the available space inside `Row` and `Column` layouts:

```dart
Expanded(
  flex: 2,
  child: myWidget,
)
```

---

## Focus Widgets

### FocusController

Tracks the focused widget ID for a scope:

```dart
final controller = FocusController();
controller.requestFocus('field-1');
```

### FocusScope

Provides a [FocusController] to descendants:

```dart
FocusScope(
  controller: controller,
  child: Column(children: [...]),
)
```

### Focusable

Handles key input when focused:

```dart
Focusable(
  controller: controller,
  focusId: 'field-1',
  onKey: (msg) => Cmd.message(TextChanged(msg.key.char ?? '')),
  child: Text('Type here'),
)
```

Focusable widgets request focus on click by default. Use `MouseMode.cellMotion`
or `MouseMode.allMotion` for interactive focus with the mouse.

---

## Input Widgets

The input module includes:

- `TextField` for interactive editing
- `TextArea` for multi-line editing with line numbers
- `TextEditingController` for external model/control access
- `TextAreaController` for textarea state/control access
- `TextEditingValue` and `TextSelection` for value + selection state

### TextField

Single-line text input powered by the bubbles textinput model:

```dart
final focus = FocusController();

TextField(
  focusController: focus,
  focusId: 'name',
  prompt: 'Name: ',
  placeholder: 'Ada Lovelace',
  width: 24,
  onChanged: (value) => Cmd.message(NameChanged(value)),
)
```

TextField uses a static cursor by default. Pass a custom `cursor` if you need
blinking behavior.

Editing history is built into the shared text model:

- `Ctrl+Z` undoes the current contiguous edit burst
- `Ctrl+Y` and `Ctrl+Shift+Z` redo
- `TextEditingController` exposes `canUndo`, `canRedo`, `undo()`, `redo()`, and `clearHistory()`
- `TextEditingController` also exposes programmatic edit helpers: `insertText()`, `replaceSelection()`, `deleteSelection()`, `deleteBackward()`, `deleteForward()`, and `pushHistoryBoundary()`

Typing and repeated deletes are coalesced into a single undo step until
navigation, selection changes, or another non-edit action breaks the history
chain.

### TextArea

Multi-line text editing powered by the bubbles textarea model:

```dart
final focus = FocusController();
final controller = TextAreaController(text: 'Line one\nLine two');

TextArea(
  controller: controller,
  focusController: focus,
  focusId: 'notes',
  height: 8,
  placeholder: 'Write notes here...',
)
```

`TextArea` is the better fit when you want:

- fixed-height multi-line editing
- built-in line numbers
- prompt-per-line rendering
- textarea-style mouse selection and navigation

Use `TextField(multiline: true)` when you want a field-oriented widget that
still behaves like the single-line input API, and `TextArea` when you want an
editor-style surface.

`TextAreaController` exposes the same basic history controls as the text field
controller:

- `Ctrl+A` selects the entire textarea contents
- `Ctrl+L` selects the current line, or expands the current selection to whole lines
- `Ctrl+Z` undoes the current contiguous typing or delete burst
- `Ctrl+Y` and `Ctrl+Shift+Z` redo
- `canUndo`, `canRedo`, `undo()`, `redo()`, `clearHistory()`, and `pushHistoryBoundary()`

### TextEditor

`TextEditor` is a higher-level component built on top of `TextArea`. It adds
editor chrome like a title row, dirty/save status, cursor/length status, and a
compact shortcuts bar:

```dart
final controller = TextAreaController(text: 'Ship editor component');

TextEditor(
  title: 'Roadmap.md',
  controller: controller,
  height: 8,
  onSave: (value) {
    saveDraft(value);
    return null;
  },
)
```

Use `TextEditor` when you want a ready-made editing surface, and `TextArea`
when you want to embed the raw multiline editor behavior inside your own
layout/chrome.

- `Ctrl+S` calls `onSave` and resets the dirty indicator.
- `Ctrl+A` selects the entire editor contents.
- `Ctrl+L` selects the current line, or expands the current selection to whole lines.
- `Ctrl+F` opens an inline find bar shared by `TextEditor` and `CodeEditor`.
- `Ctrl+G` opens an inline go-to-line bar.
- While find is open, `Enter` jumps to the next match, `Shift+Enter` moves
  backward, and `Esc` closes the find bar.
- While go-to-line is open, typing a line number updates the cursor target,
  `Enter` applies it, and `Esc` closes the bar.
- `Tab` inserts editor indentation (`indentWidth`, default `2` spaces), or
  indents the selected lines as a block.
- `Shift+Tab` outdents the current line or selected block.
- `Alt+J` joins the current line with the next line, or joins the selected
  block into one line.
- `Ctrl+Shift+K` deletes the current line or selected block.
- `Ctrl+Shift+D` duplicates the current line or selected block below.
- `Alt+Shift+Up` duplicates the current line or selected block above.
- `Alt+Shift+Down` duplicates the current line or selected block below.
- `Alt+Up` and `Alt+Down` move the current line or selected block.
- `Alt+Shift+J` splits the current line at the cursor, or replaces the
  selected range with a newline.
- `Alt+Shift+U`, `Alt+Shift+L`, and `Alt+Shift+C` uppercase, lowercase, or
  capitalize the selected block, or the current line when there is no
  selection.
- `Alt+Shift+S` sorts the selected lines, or the whole buffer when nothing is
  selected.
- `Alt+Shift+Q` toggles quote prefixes (`> `) on the current line or selected
  block.
- `Alt+Shift+B` toggles bullet list prefixes (`- `) on the current line or
  selected block.
- `Alt+Shift+X` toggles checklist prefixes (`- [ ] `) on the current line or
  selected block.
- `Alt+Shift+N` toggles numbered list prefixes on the current line or
  selected block.
- `Alt+Shift+M` toggles checklist completion state on the current line or
  selected checklist block.
- `Alt+Shift+R` renumbers existing numbered list items in the current line or
  selected block.
- `Alt+Shift+H` toggles Markdown heading prefixes on the current line or
  selected block, normalizing existing headings to level 1 before toggling
  them back off.
- `Alt+Shift+F` trims trailing whitespace in the selected block, or in the
  whole buffer when there is no selection. On the whole buffer it also removes
  extra blank lines from the end of the file.
- Typing opening delimiters like `(`, `[`, `{`, quotes, or backticks wraps the
  current selection instead of replacing it.
- `Alt+Shift+W` removes matching surrounding delimiters or quotes from around
  the current selection.
- `Ctrl+Z`, `Ctrl+Y`, and `Ctrl+Shift+Z` come from the shared textarea history.

### CodeEditor

`CodeEditor` builds on `TextEditor` and adds a live syntax-highlighted preview
using artisanal's existing code highlighter:

```dart
final controller = TextAreaController(
  text: 'void main() {\n  print("hello");\n}',
);

CodeEditor(
  title: 'main.dart',
  language: 'dart',
  controller: controller,
  height: 8,
  previewHeight: 8,
)
```

- Reuses all `TextEditor` editing, save, and history behavior.
- Inherits the same `Ctrl+A` select-all behavior as `TextEditor`.
- Inherits the same `Ctrl+L` line selection behavior as `TextEditor`.
- Inherits the same inline find workflow (`Ctrl+F`, `Enter`, `Shift+Enter`,
  `Esc`) as `TextEditor`.
- Inherits the same go-to-line workflow (`Ctrl+G`) as `TextEditor`.
- `Enter` keeps the current line indentation and adds one more indent level
  after opening delimiters like `{`, `[`, and `(`.
- Pressing `Enter` directly before a matching closing `}`, `]`, or `)` opens
  an indented blank line and keeps the closing delimiter on its own line.
- Typing opening delimiters like `(`, `[`, `{`, quotes, and backticks inserts
  matching closing delimiters, wraps selections, and skips over existing
  closing delimiters when appropriate.
- Pressing `Backspace` between an empty auto-paired delimiter collapses the
  whole pair as one edit.
- Typing a closing `}`, `]`, or `)` on an otherwise blank indented line snaps
  that delimiter outward by one indent level instead of leaving it at the
  inner block indentation.
- `Alt+J` joins the current line with the next line, or joins the selected
  block into one line.
- `Alt+Shift+J` splits the current line at the cursor, or replaces the
  selected range with a newline.
- `Ctrl+Shift+K` deletes the current line or selected block.
- `Ctrl+Shift+D` duplicates the current line or selected block below.
- `Alt+Shift+Up` duplicates the current line or selected block above.
- `Alt+Shift+Down` duplicates the current line or selected block below.
- `Alt+Shift+F` trims trailing whitespace in the selected block, or in the
  whole buffer when there is no selection. On the whole buffer it also removes
  extra blank lines from the end of the file.
- Inherits the same `Alt+Shift+U`, `Alt+Shift+L`, and `Alt+Shift+C`
  block-level text transforms as `TextEditor`.
- Inherits the same `Alt+Shift+S` line sorting behavior as `TextEditor`.
- Inherits the same `Alt+Shift+Q` quote-prefix toggle as `TextEditor`.
- Inherits the same `Alt+Shift+B` and `Alt+Shift+X` list-prefix toggles as
  `TextEditor`.
- Inherits the same `Alt+Shift+N` numbered-list toggle as `TextEditor`.
- Inherits the same `Alt+Shift+M` checklist-state toggle as `TextEditor`.
- Inherits the same `Alt+Shift+R` numbered-list renumber action as
  `TextEditor`.
- Inherits the same `Alt+Shift+H` Markdown heading toggle as `TextEditor`.
- Inherits the same `Alt+Shift+W` selection unwrap behavior as `TextEditor`.
- `Alt+Up` and `Alt+Down` move the current line or selected lines.
- `Tab` indents selected lines, while `Shift+Tab` outdents the current line or
  selected lines.
- `Ctrl+/` toggles line comments for the current line or selected lines.
- `Alt+Shift+A` toggles block comments around the current line or selected
  block when the active language supports block delimiters.
- Adds a preview panel rendered with `highlightCodeString`.
- Supports explicit `syntaxTheme` or adaptive `adaptiveSyntaxTheme`.
- Uses shared scroll semantics for the preview through `ScrollArea`.

### MarkdownEditor

`MarkdownEditor` builds on `TextEditor` and adds a live rendered markdown
preview using `MarkdownText`:

```dart
final controller = TextAreaController(
  text: '# Notes\n\n- Ship MarkdownEditor',
);

MarkdownEditor(
  title: 'README.md',
  controller: controller,
  height: 8,
  previewHeight: 10,
)
```

- Reuses all `TextEditor` editing, save, selection, list, heading, and
  history behavior.
- Adds a live markdown preview panel titled `Preview · markdown`.
- Uses the shared `MarkdownText` renderer, so headings, lists, blockquotes,
  fenced code blocks, and inline formatting render the same way they do
  elsewhere in the widget layer.
- Supports preview wrapping, preview height, preview scrollbar control, and
  custom markdown renderer options through `markdownOptions`.

---

## Scroll Widgets

Scroll controllers:

- `WidgetScrollController` for widget-native scrolling (recommended)
- `ListViewController` for list-style offset/extent tracking
- `ViewportController` for viewport-model backed content

### ScrollView

Renders a single child into a scrollable viewport:

```dart
final controller = WidgetScrollController();

Container(
  height: 20,
  child: ScrollView(
    controller: controller,
    child: content,
  ),
)
```

### SingleChildScrollView

Adds optional padding around the child before scrolling:

```dart
Container(
  height: 20,
  child: SingleChildScrollView(
    padding: EdgeInsets.all(1),
    child: content,
  ),
)
```

### ListView

Renders a list of children into a scrollable viewport:

```dart
Container(
  height: 12,
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => Text(items[index]),
  ),
)
```

### VirtualListView

Render-object based list that only paints visible rows. Best for long lists
with fixed-height rows:

```dart
VirtualListView(
  itemExtent: 1,
  variableHeight: true,
  estimatedItemExtent: 3,
  children: items,
  // width/height can be set directly when desired.
  width: 80,
  height: 12,
)
```

### Scrollbar

Overlays a scrollbar on top of a scrollable child. Provide the same controller
used by the scrollable:

```dart
final controller = WidgetScrollController();

Container(
  height: 12,
  child: Scrollbar(
    controller: controller,
    child: ScrollView(
      controller: controller,
      child: content,
    ),
  ),
)
```

Use `trackUsesBackground` / `thumbUsesBackground` with space characters to get
solid gutters and smoother scrollbars. Gradients apply per row.

By default the scrollbar reserves space to the right of the child. Set
`overlay: true` to draw on top of the child instead.

Hover styling requires `MouseMode.allMotion` (see `ProgramOptions`).

Use `gutterWidth` to reserve a wider track than the thumb, and `roundedCaps`
to add a rounded top/bottom glyph when using non-space thumb characters.

Fancy styling example:

```dart
final controller = WidgetScrollController();

Container(
  height: 12,
  child: Scrollbar(
    controller: controller,
    thickness: 1,
    gutterWidth: 3,
    roundedCaps: true,
    enableHover: true,
    trackChar: ' ',
    thumbChar: ' ',
    trackUsesBackground: true,
    thumbUsesBackground: true,
    trackGradient: ScrollbarGradient.background(
      start: theme.surface,
      end: theme.background,
    ),
    thumbGradient: ScrollbarGradient.background(
      start: theme.primary,
      end: theme.secondary,
    ),
    hoverTrackGradient: ScrollbarGradient.background(
      start: theme.surface,
      end: theme.onBackground,
    ),
    hoverThumbGradient: ScrollbarGradient.background(
      start: theme.primary,
      end: theme.secondary,
    ),
    child: ScrollView(
      controller: controller,
      child: content,
    ),
  ),
)
```

---

## Components Widgets

Higher-level widgets built from layout primitives. These are exported from
the stable `package:artisanal_widgets/widgets.dart` entrypoint (and re-exported
by `package:artisanal/tui.dart`). The older
`package:artisanal_widgets/artisanal_widgets.dart` import remains available as
the broader experimental compatibility surface.

**Naming note:** `AlertBox`, `PanelBox`, and `ListTile` are used to avoid
collisions with bubbles components that expose `Alert`, `Panel`, and `ListItem`.

### Flutter-style ports

`artisanal_widgets` also includes Flutter-style component ports:

- Chips: `Chip`, `ActionChip`, `ChoiceChip`, `FilterChip`, `InputChip`
- Menus: `DropdownButton`, `DropdownMenuItem`, `PopupMenuButton`,
  `PopupMenuItem`, `CheckedPopupMenuItem`, `PopupMenuDivider`
- Sliders: `Slider`, `RangeSlider`, `RangeValues`
- Indicators: `LinearProgressIndicator`, `CircularProgressIndicator`

Each port has a focused example under `pkgs/artisanal_widgets/example/` and a
dedicated component test file under `pkgs/artisanal_widgets/test/components/`.

### Component catalog

Implemented component widgets and companion types include:

- **Buttons/actions:** `Button`, `ElevatedButton`, `FilledButton`,
  `TextButton`, `OutlinedButton`, `IconButton`, `KeyHint`, `HelpView`,
  `DebugConsole`, `Wizard`, `WizardFormStep`, `FilePicker`, `CommandPalette`,
  `CommandPaletteItem`
- **Surfaces/feedback:** `Frame`, `Card`, `PanelBox`, `AccentPanel`,
  `StatusBar`, `AlertBox`, `Toast`, `Badge`
- **Navigation/layout components:** `Tabs`, `TabItem`, `Tooltip`, `Modal`,
  `Drawer`, `Sidebar`, `SplitView`, `ScrollArea`
- **Selection/form rows:** `ListTile`, `CheckboxListTile`, `SwitchListTile`,
  `RadioListTile`, `ExpansionTile`, `Accordion`, `Select`, `SelectOption`,
  `DropdownButton`, `DropdownMenuItem`, `Pagination`, `Breadcrumbs`,
  `BreadcrumbItem`
- **Menus/chips/sliders/progress:** `PopupMenuButton`, `PopupMenuItem`,
  `CheckedPopupMenuItem`, `PopupMenuDivider`, `Chip`, `ActionChip`,
  `ChoiceChip`, `FilterChip`, `InputChip`, `Slider`, `RangeSlider`,
  `RangeValues`, `ProgressIndicator`, `LinearProgressIndicator`,
  `SpinnerIndicator`, `CircularProgressIndicator`, `Checkbox`, `Radio`,
  `Switch`
- **Overlay/debug helpers:** `Overlay`, `OverlayEntry`, `FadeModalBarrier`,
  `DebugOverlay`, `PerformanceOverlay`, `GitDiffViewer`, `GitDiffController`

### Button

```dart
Button(
  label: 'Primary',
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  onPressed: () => Cmd.message(DoThingMsg()),
)
```

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `label` | `String?` | Optional label text |
| `child` | `Widget?` | Custom content instead of label |
| `variant` | `ButtonVariant` | primary/secondary/outline/ghost/danger |
| `size` | `ButtonSize` | small/medium/large |
| `enabled` | `bool` | Whether button accepts input |
| `onPressed` | `Cmd? Function()?` | Called on activation |

### Badge

```dart
Badge('New', background: theme.secondary, foreground: theme.onSecondary)
```

### Card and PanelBox

```dart
Card(
  child: Column(children: [Text('Title'), Text('Body')]),
)

PanelBox(
  title: 'Settings',
  actions: [Button(label: 'Save', size: ButtonSize.small)],
  child: Text('Panel content'),
)
```

### AlertBox and Toast

```dart
AlertBox(
  title: 'Warning',
  message: 'Disk space is low.',
  variant: AlertVariant.warning,
)

Toast(message: 'Saved', variant: AlertVariant.success)
```

### Tabs

```dart
Tabs(
  tabs: const [TabItem('Overview'), TabItem('Metrics')],
  index: 0,
  onChanged: (i) => Cmd.message(TabSelectedMsg(i)),
)
```

### Tooltip

```dart
Tooltip(
  message: 'Hover for details',
  child: Button(label: 'Hover me'),
)
```

### Modal and Drawer

```dart
Modal(
  open: isOpen,
  onDismiss: () => Cmd.message(CloseModalMsg()),
  child: content,
  dialog: Card(child: Text('Dialog')),
)

Drawer(
  open: isOpen,
  onDismiss: () => Cmd.message(CloseDrawerMsg()),
  drawer: PanelBox(title: 'Menu', child: Text('Links')),
  child: content,
)
```

### ProgressIndicator and SpinnerIndicator

```dart
ProgressIndicator(value: 0.4, showLabel: true)
SpinnerIndicator()
```

### Checkbox, Radio, Switch, Select

```dart
Checkbox(value: true, label: Text('Alerts'))
Radio<int>(value: 1, groupValue: 1, label: Text('Option'))
Switch(value: false, label: Text('Auto sync'))
Select<String>(
  options: const [SelectOption(label: 'Alpha', value: 'Alpha')],
  value: 'Alpha',
)
```

### ListTile, Breadcrumbs, Pagination, Accordion

```dart
ListTile(title: 'Release Notes', subtitle: 'Today')
Breadcrumbs(items: [BreadcrumbItem('Home'), BreadcrumbItem('Docs')])
Pagination(page: 1, pageCount: 10, onChanged: (p) => Cmd.message(PageMsg(p)))
Accordion(title: 'Details', expanded: true, child: Text('More info'))
```

### SplitView, Sidebar, ScrollArea

```dart
SplitView(first: leftPane, second: rightPane)
Sidebar(sidebar: nav, child: content)
ScrollArea(height: 6, showScrollbar: true, child: longContent)
```

---

## Navigation Widgets

Navigation is provided by a Flutter-like route stack API:

- `Navigator` and `NavigatorState`
- `Route`, `PageRoute`, `ModalRoute`, `RouteSettings`
- `NavigatorObserver`, `LoggingNavigatorObserver`
- `PopBehavior` for keyboard-driven pop behavior

```dart
Navigator(
  home: HomeScreen(),
  routes: {
    '/settings': (_) => SettingsScreen(),
  },
)

// Later in a child widget:
Navigator.of(context).push(PageRoute(builder: (_) => DetailsScreen()));
```

---

## Selection Widgets

Text selection widgets for copyable terminal content:

Import `package:artisanal_widgets/selection.dart` when you want the stable
selection surface.

- `SelectableText` for per-widget selection
- `SelectionArea` for cross-widget shared selection
- `SelectionController` for programmatic access

```dart
SelectionArea(
  child: Column(
    children: [
      SelectableText('First paragraph'),
      SelectableText('Second paragraph'),
    ],
  ),
)
```

---

## Chart Widgets

Charting widgets use UV canvas-backed render objects:

Import `package:artisanal_widgets/charting.dart` when you want the stable
chart widget surface.

- `SparklineChart`, `LineChart`, `BarChart`, `HeatmapChart`, `PieChart`,
  `RibbonChart`
- `ChartModel`, `ChartSeries`, and `ChartBuilder` for reactive data-driven
  chart updates
- Optional in-chart legends via `legendEntries`, `legendColumns`,
  `legendPosition`, and `legendPadding`

Legend API details:

- `legendEntries`: `List<ChartLegendEntry>` from `package:artisanal/charting.dart`
- `legendColumns`: number of legend columns (default `1`)
- `legendRowGap`: extra blank rows between legend rows (default `0`)
- `legendPosition`: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`
- `legendPadding`: inset from chart edges (default `1`)
- Legends render in an opaque framed panel so chart colors do not bleed through
  labels

Crosshair note:

- Pie and donut charts tint only chart pixels by default for hover crosshair,
  instead of drawing full-width/full-height guide lines through empty space.

```dart
LineChart(
  values: [10, 20, 15, 30, 25],
  width: 60,
  height: 12,
  showGrid: true,
  legendEntries: [
    ChartLegendEntry(label: 'Requests', style: UvStyle(fg: UvColor.rgb(80, 180, 255))),
  ],
  legendColumns: 1,
  legendPadding: 1,
  legendPosition: ChartLegendPosition.topRight,
)
```

---

## Media Widgets

The media module currently includes:

- `MediaQuery` and `MediaQueryData`

```dart
final mq = MediaQuery.of(context);
Text('Terminal size: ${mq.width}x${mq.height}');
```

---

## Animation Widgets

Animation support in `artisanal_widgets` includes both controller primitives and
rebuild helpers:

- `AnimationController`, `AnimationMixin`, `AnimationTickMsg`
- `AnimatedBuilder`, `ListenableBuilder`, `ValueListenableBuilder`
- `ImplicitlyAnimatedWidget`, `AnimatedWidgetBaseState`
- `Tween`, `CurveTween`, `TweenSequence`, and standard `Curves`

```dart
class PulseLabel extends StatefulWidget {
  PulseLabel({super.key});

  @override
  State createState() => _PulseLabelState();
}

class _PulseLabelState extends State<PulseLabel> with AnimationMixin {
  late final AnimationController _controller = createAnimationController(
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = 0.3 + (_controller.value * 0.7);
        return Opacity(opacity: value, child: child ?? SizedBox.shrink());
      },
      child: Text('Working...'),
    );
  }
}
```

---

## Creating Custom Widgets

### Basic Custom Widget

```dart
class Counter extends Widget {
  Counter({super.key});
  int count = 0;

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
    child: Column(children: [
      Text('Counter: $count', style: theme.titleMedium),
      Text('↑/↓ to change', style: theme.labelSmall),
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
    super.key,
  });
  final String title;
  final Widget body;

  @override
  List<Widget> get children => [body];

  @override
  Object view() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      background: theme.surface,
      child: Column(children: [
        Text(title, style: theme.titleMedium),
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
  Object view() {
    return Column(children: [
      StaticWidget('Static text'),
      StaticWidget(someView, key: const Key('custom-id')),
    ]);
  }
}
```

### RenderObject widgets

Use a render-object widget when you need tight control over layout, hit testing,
or paint performance.

- `LeafRenderObjectWidget` for single-node drawing
- `SingleChildRenderObjectWidget` for one child with custom layout/paint
- `MultiChildRenderObjectWidget` for custom multi-child layout engines

```dart
class HorizontalRule extends LeafRenderObjectWidget {
  HorizontalRule({this.char = '─', this.height = 1, super.key});

  final String char;
  final int height;

  @override
  RenderObject createRenderObject() {
    return _RenderHorizontalRule(char: char, height: height);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderHorizontalRule;
    ro
      ..char = char
      ..height = height;
  }
}

class _RenderHorizontalRule extends RenderBox {
  _RenderHorizontalRule({required this.char, required this.height});

  String char;
  int height;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final w = constraints.hasBoundedWidth ? constraints.maxWidth.toInt() : 0;
    final h = height.clamp(1, 3);
    size = constraints.constrain(Size(w.toDouble(), h.toDouble()));
  }

  @override
  String paint() {
    final w = size.width.round();
    final h = size.height.round();
    final line = List<String>.filled(w, char).join();
    return List<String>.filled(h, line).join('\n');
  }
}
```

Most widgets should stay at `StatelessWidget`/`StatefulWidget` level; only
drop to render objects when profiling shows a measurable need.

---

## Widget Composition

### Hierarchical Structure

```dart
class App extends Widget {
  final header = Header();
  final sidebar = Sidebar();
  final content = Content();
  final footer = Footer();

  @override
  List<Widget> get children => [header, sidebar, content, footer];

  @override
  Object view() {
    return Column(children: [
      StaticWidget(header.view()),
      Row(children: [
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
      child: Column(
        gap: 1,
        children: [
          // Header row
          Container(
            background: theme.surface,
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Row(children: [
              Text('App Title', style: theme.titleLarge),
              Spacer(size: 20),
              Text('v1.0.0', style: theme.labelSmall),
            ]),
          ),
          // Content
          Container(
            height: 20,
            child: contentWidget,
          ),
          // Footer
          Text('Press q to quit', style: theme.labelSmall),
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
    return Text('> $value${focused ? '█' : ''}', style: style);
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
    
    // Runtime interrupt
    InterruptMsg() => (this, Cmd.quit()),
    
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

When widgets run through `WidgetApp` or `runProgram()`, real Ctrl+C usually
arrives as `InterruptMsg` because `ProgramOptions.sendInterrupt` defaults to
`true`. Handle `KeyMsg(key: Key(ctrl: true, ...))` only if you opt into the
legacy behavior with `ProgramOptions(sendInterrupt: false)` or
`ProgramOptions().withoutInterruptMsg()`.

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
  MyWidget({super.key});

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
Text('Error!', style: Style().foreground(theme.error).bold())

// Centered container
Container(
  width: 40,
  align: HorizontalAlign.center,
  child: Text('Centered'),
)

// Padded panel
Container(
  padding: EdgeInsets.all(2),
  background: theme.surface,
  child: content,
)

// Horizontal layout with gap
Row(gap: 2, children: [left, middle, right])

// Vertical layout with gap  
Column(gap: 1, children: [header, content, footer])

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

// Flutter-like alignment
Alignment.topLeft
Alignment.center
Alignment.bottomRight
```

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [TUI.md](TUI.md) - TUI runtime
- [UV.md](UV.md) - UV renderer
