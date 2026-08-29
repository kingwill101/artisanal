# Build a TUI with widgets

The widget framework is a good fit for apps with several screens, forms,
scrolling content, navigation, or reusable UI pieces. If you know Flutter, the
shape will feel familiar: widgets describe the UI, stateful widgets own mutable
state, and `build()` returns a tree.

You do not need to understand the lower-level TEA runtime before using widgets.
If you prefer a smaller `Model` → `update` → `view` loop, start with the
[TEA guide](tui.md) instead.

## Quick start

```dart
import 'package:artisanal/artisanal.dart' show runWidgetApp;
import 'package:artisanal_widgets/app.dart';
import 'package:artisanal_widgets/widgets.dart';

class HelloApp extends StatelessWidget {
  HelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello widgets', style: theme.titleLarge),
        Text('Press q to quit', style: theme.bodyMedium),
      ],
    );
  }
}

void main() async {
  await runWidgetApp(
    ArtisanalApp(
      title: 'Hello widgets',
      home: HelloApp(),
    ),
  );
}
```

## Where to import from

Most widget apps use `package:artisanal_widgets/app.dart` for the app shell,
`package:artisanal_widgets/widgets.dart` for widgets, and `runWidgetApp` from
`package:artisanal/artisanal.dart` to start the app. Focused libraries are also
available for [charting](#chart-widgets), [editors](#input-widgets),
[selection](#selection-widgets), and [testing](#widget-testing).

The umbrella package re-exports the main widget and testing APIs as
`package:artisanal/widgets.dart` and `package:artisanal/testing.dart`.

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
import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/app.dart';

final app = WidgetApp(MyRoot(), scanZones: true);
runProgram(
  app,
  options: const ProgramOptions(mouseMode: MouseMode.allMotion),
);
```

For the common fullscreen widget case, use the higher-level runner:

```dart
import 'package:artisanal/artisanal.dart' show runWidgetApp;

await runWidgetApp(WidgetApp(MyRoot()));

await runWidgetApp(
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
await runWidgetApp(
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
import 'package:artisanal/artisanal.dart' show Transport, serveWidgetApp;

final browserHost = await serveWidgetApp(
  transport: Transport.browser,
  browserTitle: 'Browser Demo',
  appBuilder: () => ArtisanalApp(
    title: 'Browser Demo',
    home: MyRoot(),
  ),
);

final socketHost = await serveWidgetApp(
  transport: Transport.socket,
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

await runWidgetApp(
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

await runWidgetApp(
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

await runWidgetApp(
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

### Widget Runtime Metrics

`WidgetApp` integrates a three-layer performance model that makes runtime
metrics available to the widget tree without triggering extra rebuilds.

**Three layers:**

1. **`RenderMetrics`** — TUI runtime FPS, frame times, render durations
   (from `UvTerminalRenderer`). Enabled when `enableRenderMetrics: true`
   (the default).
2. **`WidgetFrameTiming`** — widget-layer breakdown per frame: build,
   layout, and paint durations. Always collected when the widget tree runs.
3. **`PerformanceMetricsSnapshot`** — combined view of both layers.

#### Accessing Metrics from Code

```dart
// From the WidgetApp instance (outside the widget tree)
final snapshot = widgetApp.performanceSnapshot;
print(snapshot.averageBuildDuration);   // widget build phase
print(snapshot.averageLayoutDuration);  // layout phase
print(snapshot.averagePaintDuration);   // paint phase
print(snapshot.slowFrameCount);         // frames > 16.67ms
print(snapshot.renderMetrics?.averageFps); // runtime FPS

// Register a per-frame callback
widgetApp.addFrameTimingCallback((timing) {
  if (timing.isSlowFrame) {
    debugPrint('Slow frame #${timing.frameNumber}: ${timing.totalDuration}');
  }
});
```

#### Injecting Custom Metrics into Debug Overlays

`RenderMetricsInjector` is a global bus for pushing custom key-value lines
into `DebugOverlay` without modifying the widget tree:

```dart
import 'package:artisanal_widgets/app.dart';

// Inject a custom metric line
RenderMetricsInjector.instance.setMetric('cache_size', '1,024 items');

// Inject many at once
RenderMetricsInjector.instance.setMetrics({
  'requests': 42,
  'latency_ms': 12,
});

// Remove a key
RenderMetricsInjector.instance.removeMetric('cache_size');

// Clear all custom entries
RenderMetricsInjector.instance.clearMetrics();
```

#### Forwarding Runtime Monitor Stats

`RenderMetricsProgramMonitor` is a `ProgramInterceptor` that automatically
forwards `UvTerminalRenderer` stats into overlays:

```dart
final monitor = RenderMetricsProgramMonitor(prefix: 'Render');

await runWidgetApp(
  ArtisanalApp(home: MyApp()),
  options: ProgramOptions(interceptors: [monitor]),
);
```

#### Debug Overlay

Set `debugOverlay: true` on `ArtisanalApp` (or `WidgetApp`) to show an
always-on HUD that displays FPS, frame timing, and any custom metrics
injected via `RenderMetricsInjector`. Press **F12** at runtime to toggle.

```dart
ArtisanalApp(
  debugOverlay: true,
  debugOverlayPosition: DebugOverlayPosition.topRight,
  home: MyApp(),
)
```

#### WidgetApp Constructor Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enableRenderMetrics` | `true` | Subscribe to `RenderMetricsMsg` from TUI runtime |
| `enableRenderMetricsInjection` | `true` | Listen to `RenderMetricsInjector` stream |
| `debugOverlay` | `false` | Show runtime debug overlay on startup |
| `debugOverlayPosition` | `topRight` | Where the overlay appears |

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

> **Use `runWidgetApp` for widget trees.** Although widgets implement `Model`
> for framework integration, passing a bare `StatelessWidget` or
> `StatefulWidget` to `runProgram` bypasses the element tree that manages
> `BuildContext` and state lifecycles. Wrap the root in `WidgetApp` or
> `ArtisanalApp`, then start it with `runWidgetApp`.

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

### Key Differences from TEA Model

| Feature | TEA `Model` | `Widget` / `StatefulWidget` |
|---------|-------------|-----------------------------|
| Message handling | Override `update(Msg)` directly | Override `handleUpdate(Msg)`; base `update()` fans out to children automatically |
| State update | Return a new model instance | Return `(this, null)` from `handleUpdate`; for `StatefulWidget`, call `setState(() { ... })` |
| Runner | `runProgram(model)` | `runWidgetApp(WidgetApp(root))` or `runWidgetApp(ArtisanalApp(...))` |
| `view()` return type | `String` or `View` (ANSI output) | `Widget` subtree (further traversed by element tree); `StatelessWidget.build()` returns a `Widget` |
| Theme access | Manual | Built-in `theme` getter; `BuildContext` for `InheritedWidget` ancestors |
| Identification | None | Key-based identity |
| Composition | Manual string/View building | Declarative `children` list, layout widgets |
| Background detection | Manual | Automatic via `BackgroundColorMsg` |
| `StatelessWidget` / `StatefulWidget` | N/A | **Only valid inside `WidgetApp`** — bare `Program(widget)` does not manage the element tree |

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
Text(
  'Ready',
  style: Style().padding(0, 1),
  textStyle: const TextStyle(
    color: Colors.green,
    fontWeight: FontWeight.bold,
  ),
)
Text.rich(
  TextSpan(
    text: 'Status: ',
    textStyle: const TextStyle(fontWeight: FontWeight.dim),
    children: [
      TextSpan(
        text: 'Success',
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  ),
)
```

`Style` remains the complete Artisanal style, including layout and block
properties. The optional immutable `textStyle` is applied afterward, so it
can override only text properties while preserving padding, borders, sizing,
and alignment from `style`. Nested `TextSpan` values inherit both layers;
nullable `TextStyle` properties inherit, while `normal` and `none` explicitly
disable inherited presentation.

When `softWrap` is enabled, `Text` measures the `Style` box model against its
layout constraint, wraps the content inside the available border and padding,
then rebuilds the block around the resulting lines. Borders therefore remain
rectangular and resize with wrapped text instead of being wrapped themselves.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `data` | `String` | Text content |
| `style` | `Style?` | Optional complete Artisanal style |
| `textStyle` | `TextStyle?` | Optional immutable text-only overlay |

`SelectableText` and `SelectableRichText` accept the same `textStyle`
overlay, including nested `TextSpan` inheritance.

Run the complete showcase to see immutable updates, `Style` composition,
nested inheritance and resets, selectable spans, decorations, and ASCII-art
fonts together:

```sh
dart run pkgs/artisanal_widgets/example/text_style/main.dart
```

### ASCII text and selectable fonts

`AsciiText` renders each input character as a multi-line terminal glyph. Pick
one of the built-in ASCII-art fonts or implement `AsciiFont` for custom glyphs:

```dart
AsciiText(
  data: 'ARTISANAL',
  font: AsciiFont.banner,
)

StyledAsciiText(
  data: 'READY',
  font: AsciiFont.slim,
  style: Style().foreground(Colors.green),
)
```

The built-in choices are `standard`, `banner`, `block`, and `slim`. These
fonts expand text across terminal cells; the terminal host still controls the
actual monospace typeface and cell size.

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
| `onKeyboardDrag` | `bool` | Enable keyboard-driven drag via focus + arrows (default: `false`) |
| `onEnter` | `Cmd? Function(MouseMsg)?` | Pointer enters zone |
| `onExit` | `Cmd? Function(MouseMsg)?` | Pointer exits zone |
| `onWheel` | `Cmd? Function(MouseMsg)?` | Scroll wheel event |
| `behavior` | `HitTestBehavior` | Hit test strategy (default: `deferToChild`) |
| `enabled` | `bool` | Enable/disable all gestures (default: `true`) |
| `captureMouse` | `bool` | Capture mouse during drags (default: `false`) |

---

### Keyboard Drag Support

`GestureDetector` supports keyboard-driven drag-and-drop when `onKeyboardDrag: true`
is set and the widget has keyboard focus.

1. **Activation**: Press `Enter` (or the configured accept key) while focused to
   begin a drag.
2. **Movement**: Use arrow keys to move the "drag pointer" by 1 cell increments.
3. **Completion**: Press `Enter` again to drop at the current position, or `Esc`
   to cancel.

The `onDragUpdate` callback receives `DragUpdateDetails` with deltas for each
arrow key step, matching the mouse drag API.

---

### Accessibility Tree (A11yTree)

The widget system builds a semantic accessibility hierarchy that can be used by
screen readers or audit tools.

```dart
Text(
  'Submit',
  accessibilityRole: 'button',
  accessibilityLabel: 'Submit form data',
)
```

- **Stable IDs**: Each node has a deterministic FNV-1a ID based on its widget
  key and tree path.
- **Tree Diffs**: `WidgetApp` can produce semantic diffs between frames to
  notify assistive technology of relevant updates.
- **Roles & Labels**: Use the `accessibilityRole` and `accessibilityLabel`
  properties on any `Widget` to expose semantic metadata.

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
- `SelectableTextFieldView` and `SelectableTextAreaView` for controller-backed
  read-only text that should participate in shared selection
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

Mouse selection behavior matches the shared text editor model:

- single click moves the cursor
- double click selects the current word
- triple click selects the current logical line

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

Mouse selection behavior also follows the shared editor model:

- single click moves the cursor
- double click selects the current word
- triple click selects the current logical line

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
- `F8` and `Shift+F8` move to the next or previous diagnostic when diagnostics
  are present.
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
- The editor body stays visually focused while inline utility UI such as the
  find bar or go-to-line input has focus.
- `TextEditor`, `CodeEditor`, and `MarkdownEditor` use the widget theme's
  editor-specific shell/body/utility tokens instead of generic panel colors.

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
- Inherits the same `F8` / `Shift+F8` diagnostic navigation as `TextEditor`.
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
- Uses the same shared text decoration layer model as the plain editor, so
  syntax spans, search matches, diagnostics, and active-line treatment can
  stack instead of overwriting one another.
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

### Editor Diagnostics And Decorations

The editor widgets expose a shared diagnostics and decoration system on top of
`TextAreaController`.

For diagnostics, the stable widget surface includes:

- `TextDiagnosticRange` and `TextPositionDiagnosticRange`
- `TextDiagnosticsBinding`
- `TextPositionDiagnosticsSource`
- `TextDecorationLayerBinding`
- `TextLineDecorationLayerBinding`

Use `TextPositionDiagnosticsSource` when an external producer should own the
diagnostics and `TextDiagnosticsBinding.fromPositionListenable(...)` when you
want to route those diagnostics onto a controller:

```dart
final controller = TextAreaController(text: 'TODO: wire diagnostics');
final source = TextPositionDiagnosticsSource.patternRules(
  text: controller,
  rules: const [
    TextPatternDiagnosticRule(
      pattern: 'TODO',
      severity: TextDiagnosticSeverity.warning,
      code: 'TODO001',
      wholeWord: true,
    ),
  ],
);
final binding = TextDiagnosticsBinding.fromPositionListenable(
  controller: controller,
  diagnostics: source,
);
```

At the controller level you can also set overlays directly:

- `setDiagnostics(...)`
- `setDiagnosticsFromPositions(...)`
- `clearDiagnostics()`
- `setDecorations(...)`
- `clearDecorations(...)`
- `setLineDecorations(...)`
- `clearLineDecorations(...)`

`TextEditor` and `CodeEditor` use the same system for search highlighting and
diagnostic navigation, while `CodeEditor` also feeds editable syntax
highlighting through a dedicated decoration layer.

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
with variable-height rows using Fenwick trees for O(log n) offset lookup.

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

**Performance & Logic**:

- **O(log n) Lookup**: Uses a binary indexed tree (Fenwick tree) to track
  item offsets when `variableHeight: true` is set.
- **Adaptive Convergence**: The list predicts unknown item heights and
  converges on exact offsets as rows are scrolled into view.
- **Large List Support**: Efficiently handles 100K+ items without full-list
  measurements or layout passes.

---

### Budget-Aware Widgets

Widgets can opt-out of rendering during high-pressure frames using the
`Budgeted<W>` wrapper or the `shouldRenderAt` gate.

```dart
Budgeted(
  priority: WidgetDegradationPriority.high,
  child: MyComplexDashboard(),
)
```

- **Degradation Levels**: Widgets are skipped or simplified as the runtime
  steps through `DegradationLevel` (Normal, Simple, NoStyling, Skeleton,
  EssentialOnly).
- **Essential Widgets**: Widgets with `essential: true` or high priority
  continue to render even at max degradation.
- **Focus Preservation**: Focused widgets and their ancestors are never
  skipped by the budget controller.

---

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

### List and Scroll Keyboard Navigation

All scroll widgets (`ScrollView`, `SingleChildScrollView`, `ListView`,
`VirtualListView`) respond to the same keyboard shortcuts when focused:

| Key | Action |
|-----|--------|
| ↑ | Scroll up 1 row |
| ↓ | Scroll down 1 row |
| Page Up | Scroll up one full viewport height |
| Page Down | Scroll down one full viewport height |
| Home | Jump to the top (offset 0) |
| End | Jump to the bottom (max offset) |
| Mouse wheel ↑ | Scroll up `mouseWheelDelta` rows (default: 3) |
| Mouse wheel ↓ | Scroll down `mouseWheelDelta` rows (default: 3) |

**Customizing scroll speed:**

```dart
ScrollView(
  controller: controller,
  mouseWheelDelta: 5,  // scroll 5 rows per wheel tick instead of 3
  child: content,
)
```

**Making a scroll widget focusable:**

Wrap the scroll widget with `Focusable` so it can receive keyboard events:

```dart
final focus = FocusController();

Focusable(
  controller: focus,
  child: ScrollView(
    controller: scrollController,
    child: content,
  ),
)
```

`VirtualListView` also accepts `autofocus: true` for cases where the list
should automatically take focus on mount.

**List row theming:**

List rows can be styled using the theme's dedicated row tokens
(`listRow`, `listRowOdd`, `listRowHover`, `listRowEven`, `listRowSelected`)
so hover, selection, and alternating stripe states all react consistently to
theme switches. See [style.md → List Row Theme Tokens](style.md#list-row-theme-tokens)
for the full token reference and usage examples with `LipList`.

---

## Keyboard Shortcuts and Chords

`artisanal_widgets` provides a surface-first keyboard shortcut system built
around `KeymapHub`, `ShortcutSurface`, and `ShortcutBinding`. Surfaces
push/pop at runtime so dialogs, sidebars, and views each declare their own
bindings without collisions.

### KeymapHubScope

Wrap your app (or a subtree) with `KeymapHubScope` to provide a
`KeymapHub` to all descendant surfaces:

```dart
KeymapHubScope(
  child: MaterialApp.router(
    routerConfig: router,
  ),
);
```

### ShortcutSurfaceScope

Each screen or route wraps its content with `ShortcutSurfaceScope` to
declare the active surface's bindings:

```dart
ShortcutSurfaceScope(
  surface: ShortcutSurface(
    id: 'session',
    bindings: [
      ShortcutBinding.chord(
        id: 'toggle_sidebar',
        leader: 'ctrl+x',
        key: 'b',
        description: 'toggle sidebar',
        group: 'session',
      ),
      ShortcutBinding.single(
        id: 'command_list',
        key: 'ctrl+p',
        description: 'commands',
        group: 'app',
      ),
      ShortcutBinding.help(), // ? → help_show
    ],
  ),
  child: SessionScreen(),
);
```

### WhichKeySlot

`WhichKeySlot` is a dock widget that renders pending leader-chord
continuations so the user can see available chords without memorising
them. Place it in your app's footer or sidebar:

```dart
Scaffold(
  footer: WhichKeySlot(),
  body: SessionScreen(),
);
```

While a leader chord is pending the slot shows the available continuations
grouped by binding group. The hub's `pending` property exposes the current
state for custom which-key panels.

### ShortcutsSheet

`ShortcutsSheet` is a bottom sheet that lists all bindings for the active
surface. Trigger it with the `?` key (default) or programmatically:

```dart
// The ? key is bound by default via ShortcutBinding.help().
// Open the sheet programmatically:
ShortcutsSheet.of(context).open();
```

### WhichKeyPanel

For a custom overlay panel instead of the dock, use `WhichKeyPanel`:

```dart
WhichKeyPanel(
  entries: entries,
  position: WhichKeyPosition.top,
  child: MyScreen(),
);
```

### Leader chords

Leader chords use a prefix key (default: `ctrl+x`) followed by a
continuation key. The hub tracks pending sequences and exposes them via
`KeymapHub.pending`:

| Property | Description |
|----------|-------------|
| `pending.isPending` | `true` while the leader key is held |
| `pending.bindings` | Available continuation bindings |
| `pending.statusHint` | Status bar hint text (e.g. `ctrl+x …`) |

### Messages

| Message | When |
|---------|------|
| `KeymapActionMsg` | A binding matched. `actionId` holds the binding id. |
| `KeymapHelpMsg` | The help key (`?`) was pressed for the active surface. |

---

## Components Widgets

Higher-level widgets built from layout primitives. These are exported from
the stable `package:artisanal_widgets/widgets.dart` entrypoint. The older
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

Passive hover requires `MouseMode.allMotion` when you launch widgets through
`Program` or `runProgram()` directly. The higher-level `runWidgetApp()` helper
already enables that mode by default.

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

## Widget Slot Registry

The widget slot registry provides a typed, ordered plugin system for in-process
widget contributions. Applications define named slots; independent modules
register widget builders for those slots; a `SlotBuilder` widget resolves and
renders all registered contributions at the right point in the UI.

This enables plugin-style extensibility without hard-coding every contributor
into the host widget tree.

### SlotRegistry

`SlotRegistry<TSlot, TData>` holds a mutable list of typed contributions.
Create one per plugin extension point and share it through `SlotScope`:

```dart
// Define a typed slot key
enum DashboardSlot { sidebar, toolbar, statusBar }

// Create a registry (typically app-level singleton)
final registry = SlotRegistry<DashboardSlot, DashboardData>();

// Register a contribution (returns a disposer)
final dispose = registry.register(
  pluginId: 'my_plugin',
  slot: DashboardSlot.sidebar,
  builder: (context, data) => MyPluginSidebarWidget(data: data),
  order: 10, // lower = rendered first
);

// Later, unregister
dispose();
```

### SlotScope and SlotBuilder

Expose the registry to the widget tree with `SlotScope`, then render a slot
with `SlotBuilder`:

```dart
SlotScope<DashboardSlot, DashboardData>(
  registry: registry,
  child: Column(children: [
    // Render all sidebar contributions stacked
    SlotBuilder<DashboardSlot, DashboardData>(
      slot: DashboardSlot.sidebar,
      data: currentDashboardData,
      mode: SlotBuildMode.column,  // or SlotBuildMode.first for highest priority only
      fallback: Text('No sidebar plugins registered'),
    ),
  ]),
)
```

### Declarative Plugin Registration

Use `SlotPlugin` and `SlotPluginMount` to register contributions
declaratively from anywhere in the widget tree:

```dart
final myPlugin = SlotPlugin<DashboardSlot, DashboardData>(
  pluginId: 'analytics_plugin',
  slots: {
    DashboardSlot.toolbar: SlotPluginContribution(
      builder: (context, data) => AnalyticsToolbarButton(data: data),
      order: 5,
    ),
  },
);

// Mount it from a subtree (auto-unregisters on unmount)
SlotPluginMount<DashboardSlot, DashboardData>(
  plugin: myPlugin,
  child: MySubtree(),
)
```

### Mixed Local and Remote Slots

`SlotRegion` combines local `SlotRegistry` contributions with remote plugin
surfaces from the out-of-process plugin system. Local content renders first;
remote surfaces are positioned using their declared coordinates:

```dart
SlotRegion<DashboardSlot, DashboardData>(
  slot: DashboardSlot.sidebar,
  data: currentDashboardData,
  remoteEntries: resolveRemotePluginSlotEntries(workspace.surfaces, 'sidebar'),
)
```

For remote plugin surfaces, see [plugins.md](plugins.md).

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
- `SelectableRichText`, `SelectableMarkdownText`, and `SelectableView` for
  richer read-only content
- `SelectionArea` for cross-widget shared selection
- `SelectionController` for programmatic access
- `.selectable()` adapters on `Text`, `RichText`, `MarkdownText`, and `View`
  for opt-in shared selection without changing the original widget's layout role

```dart
SelectionArea(
  child: Column(
    children: [
      SelectableText('First paragraph'),
      RichText(
        text: TextSpan(
          text: 'Second ',
          children: [TextSpan(text: 'paragraph')],
        ),
      ).selectable(),
    ],
  ),
)
```

Shared selection behavior:

- one `SelectionArea` can span multiple selectable children and copy them as
  one combined buffer
- drag selection works top-to-bottom and bottom-to-top across mixed selectable
  content
- `SelectionArea(scrollController: ...)` supports edge auto-scroll while
  dragging and keeps selection active while using the mouse wheel
- drag selection can begin from surrounding whitespace on the same row, not
  just directly on top of visible glyphs
- double click selects the current word
- triple click selects the current logical line

Selection styling:

- `SelectableText`, `SelectableRichText`, `SelectableMarkdownText`, and
  `SelectableView` all accept `selectionHighlightStyle`
- the `.selectable()` adapters also forward `selectionHighlightStyle`
- `TextSpan.selectionHighlightStyle` lets one `SelectableRichText` mix
  different selection palettes within the same selected region

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

- `legendEntries`: `List<ChartLegendEntry>` from `package:artisanal/artisanal.dart`
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

### NetworkImage

`NetworkImage` is an `ImageProvider` that fetches images over HTTP(S) with
built-in caching, content-type filtering, and size constraints:

```dart
Image(
  image: NetworkImage(
    'https://example.com/photo.png',
    headers: {'Authorization': 'Bearer $token'},
    maximumBytes: 5 * 1024 * 1024,  // reject responses > 5 MB
    decodeFrame: 0,                  // static preview of animated GIF/WebP
    allowedContentTypes: {'image/png', 'image/jpeg'},
    blockedContentTypes: {'image/gif'},
  ),
)
```

**Constructor parameters:**

| Parameter | Type | Description |
|---|---|---|
| `url` | `String` | HTTPS or HTTP URL to fetch |
| `headers` | `Map<String, String>` | Optional request headers |
| `maximumBytes` | `int?` | Max response size; rejects oversized responses |
| `decodeFrame` | `int?` | Frame index to decode (0 = first frame / static preview) |
| `allowedContentTypes` | `Set<String>` | MIME allow-list; empty = allow all |
| `blockedContentTypes` | `Set<String>` | MIME deny-list |

Responses are deduplicated and cached in an in-process `LruCache` keyed by
`(url, headers, maximumBytes, decodeFrame, allowedContentTypes, blockedContentTypes)`.

---

## Animation Widgets

Animation support in `artisanal_widgets` includes both controller primitives and
rebuild helpers. For the full animation timeline, curve, tween, and implicit
animation API see **[animation.md](animation.md)**.

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

## Widget Testing

Artisanal ships a dedicated testing infrastructure for widget apps. Import
`package:artisanal/testing.dart` or `package:artisanal_widgets/testing.dart`
to access the harness.

```dart
import 'package:artisanal/testing.dart';
import 'package:test/test.dart';

void main() {
  test('counter increments', () async {
    final tester = WidgetTester(CounterWidget());
    await tester.pump();
    tester.expect(find.text('0'), findsOneWidget);

    await tester.sendKey(Key(type: KeyType.up));
    tester.expect(find.text('1'), findsOneWidget);
  });
}
```

Key testing types:

| Type | File | Purpose |
|------|------|---------|
| `WidgetTester` | `widget_testing.dart` | Drive widget builds, dispatch msgs, assert on output |
| `WidgetGauntlet` | `widget_gauntlet.dart` | Stress-test a widget under varied sizes and inputs |
| `WidgetStorm` | `widget_storm.dart` | Fuzz builds with random message sequences |
| `FlickerAnalyzer` | `flicker_analyzer.dart` | Detect render-frame visual instability |
| `HarnessArtifactManifest` | `harness_artifacts.dart` | Record / replay widget render artifacts in CI |
| `ManualClock` | `harness_artifacts.dart` | Override `DateTime.now()` for deterministic timing |

For full harness configuration, `HarnessArtifactManifest` CI integration, and
all `WidgetGauntlet`/`WidgetStorm` options see **[testing.md](testing.md)**.

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

## Running a Widget App

There are two app shells for the public `runWidgetApp` runner. For lower-level
control, you can also pass `WidgetApp` directly to `runProgram`.

### `ArtisanalApp` + `runWidgetApp` (recommended)

Full app shell with title, theme, routing, and sensible defaults:

```dart
void main() async {
  await runWidgetApp(
    ArtisanalApp(
      title: 'My App',
      themeMode: ThemeMode.system,
      home: MyRootWidget(),
    ),
  );
}
```

### `WidgetApp` + `runWidgetApp`

Lightweight shell — no built-in routing or theming, but enables the element tree:

```dart
void main() async {
  await runWidgetApp(WidgetApp(MyRootWidget()));
}
```

### `WidgetApp` + `runProgram` (advanced / low-level)

Use when you need direct control over `ProgramOptions` or are composing with a
custom `Program` host. `WidgetApp` **is** a `Model`, so it can be passed to the
TEA runner. This is appropriate for non-`StatefulWidget` trees or specialised
embedded scenarios:

```dart
void main() async {
  final app = WidgetApp(MyRoot(), scanZones: true);
  await runProgram(
    app,
    options: const ProgramOptions(mouseMode: MouseMode.allMotion),
  );
}
```

> **Note:** `runWidgetApp` calls `runProgram` internally with widget-appropriate
> defaults (`altScreen: true`, `mouseMode: allMotion`). Prefer it over calling
> `runProgram(WidgetApp(...))` directly unless you have a
> specific reason to override those defaults.

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
  final bgColor = colorToUvColor(background);
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
UvColor? colorToUvColor(Color? color) {
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

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [tui.md](tui.md) - TEA programming model (the alternative to the Widget system)
- [uv.md](uv.md) - UV renderer
- [animation.md](animation.md) - Animation timeline and tween system
- [testing.md](testing.md) - Widget testing infrastructure
- [plugins.md](plugins.md) - Remote plugin surfaces and slot registry
