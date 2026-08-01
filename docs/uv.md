# Draw directly with Ultraviolet

Ultraviolet is the low-level rendering layer beneath Artisanal's TUI runtime and
widget framework. Most applications do not need to begin here. Use it directly
when you want to draw cells, compose layers, decode terminal input, build a
renderer, or work with terminal image protocols.

New code should import `package:ultraviolet/ultraviolet.dart`.
`package:artisanal/uv.dart` remains as a compatibility export.

## The basic idea

UV models the terminal as layers of drawable cells. The architecture consists of:

- **Cell**: A single character with style, link, and display width
- **Buffer**: A 2D grid of cells representing screen state
- **Screen**: Abstract drawing surface interface
- **Canvas**: Immediate-mode drawing with composition
- **UvTerminalRenderer**: Efficient diff-based ANSI output
- **Terminal**: Lifecycle management and I/O orchestration

```dart
import 'dart:io';

import 'package:ultraviolet/ultraviolet.dart';

void main() async {
  final terminal = Terminal();
  await terminal.start();

  // Draw a red "H" at (0, 0)
  terminal.setCell(0, 0, Cell(
    content: 'H',
    style: UvStyle(fg: UvColor.rgb(255, 0, 0)),
  ));

  terminal.draw();
  await terminal.stop();
}
```

---

## Cell and UvStyle

### Cell

A `Cell` represents a single terminal cell containing:

- **content**: The grapheme (character or emoji)
- **style**: Visual attributes via `UvStyle`
- **link**: Optional hyperlink via `Link` (OSC 8)
- **width**: Display width in columns (1 for normal, 2 for wide characters)
- **drawable**: Optional embedded drawable for images/graphics

```dart
// Basic cell creation
final cell = Cell(
  content: 'A',
  style: const UvStyle(fg: UvColor.rgb(255, 0, 0)),
  link: const Link(url: 'https://example.com'),
);

// Create from grapheme with automatic width calculation
final wideCell = Cell.newCell(WidthMethod.wcwidth, '');  // width = 2

// Empty cell (space)
final empty = Cell.emptyCell();

// Check cell state
print(cell.isZero);  // No content, style, or link
print(cell.isEmpty); // Plain space with no attributes
```

### UvStyle

`UvStyle` holds visual attributes for a cell:

```dart
final style = UvStyle(
  fg: UvColor.rgb(255, 255, 255),           // Foreground color
  bg: UvColor.basic16(4),                   // Background color (blue)
  underlineColor: UvColor.indexed256(196),  // Underline color (red)
  underline: UnderlineStyle.curly,          // Underline variant
  attrs: Attr.bold | Attr.italic,           // Text attributes
);

// Available attributes (bitmask)
Attr.bold          // Bold text
Attr.faint         // Dim/faint text
Attr.italic        // Italic text
Attr.blink         // Slow blink
Attr.rapidBlink    // Fast blink
Attr.reverse       // Reverse video
Attr.conceal       // Hidden text
Attr.strikethrough // Strikethrough

// Underline styles
UnderlineStyle.none
UnderlineStyle.single
UnderlineStyle.double
UnderlineStyle.curly
UnderlineStyle.dotted
UnderlineStyle.dashed

// Copy with modifications
final newStyle = style.copyWith(
  fg: UvColor.basic16(2),
  clearBg: true,  // Remove background color
);
```

### Link

`Link` enables OSC 8 hyperlinks:

```dart
final link = Link(
  url: 'https://example.com',
  params: 'id=my-link',  // Optional parameters
);

// Check if link is empty
print(link.isZero);  // true if no URL or params
```

---

## UvColor Types

UV provides three color representations matching terminal capabilities:

### UvBasic16

The standard 16-color ANSI palette (8 normal + 8 bright):

```dart
// Normal colors (0-7): black, red, green, yellow, blue, magenta, cyan, white
final red = UvColor.basic16(1);
final blue = UvColor.basic16(4);

// Bright variants
final brightRed = UvColor.basic16(1, bright: true);
final brightWhite = UvColor.basic16(7, bright: true);
```

### UvIndexed256

The 256-color xterm palette:

```dart
// Indices 0-15: standard colors
// Indices 16-231: 6x6x6 color cube
// Indices 232-255: grayscale ramp

final orange = UvColor.indexed256(208);
final gray = UvColor.indexed256(240);
```

### UvRgb

True 24-bit color with optional alpha:

```dart
final coral = UvColor.rgb(255, 127, 80);
final semiTransparent = UvColor.rgb(255, 0, 0, a: 128);
```

---

## Buffer

`Buffer` is a 2D grid of `Line`s containing `Cell`s. It tracks modifications ("touched" lines) for efficient incremental rendering.

### Creating and Resizing

```dart
// Create an 80x24 buffer
final buf = Buffer.create(80, 24);

// Resize (preserves content where possible)
buf.resize(120, 40);

// Get dimensions
print(buf.width());   // 120
print(buf.height());  // 40
print(buf.bounds());  // Rectangle(0, 0, 120, 40)
```

### Cell Access

```dart
// Get a cell
final cell = buf.cellAt(10, 5);

// Set a cell (automatically marks line as touched)
buf.setCell(10, 5, Cell(content: 'X'));

// Access a line directly
final line = buf.line(5);
line?.set(10, Cell(content: 'Y'));

// Mark cells as dirty for re-rendering
buf.touch(10, 5);
buf.touchLine(0, 5, 80);  // Touch 80 cells starting at x=0
```

### Fill and Clear Operations

```dart
// Fill entire buffer
buf.fill(Cell(content: '.', style: UvStyle(fg: UvColor.basic16(8))));

// Fill a rectangular area
buf.fillArea(
  Cell(content: '#'),
  rect(5, 5, 20, 10),
);

// Clear (fill with spaces)
buf.clear();
buf.clearArea(rect(0, 0, 40, 12));
```

### Line Operations (ANSI IL/DL semantics)

```dart
// Insert 3 blank lines at row 10
buf.insertLine(10, 3, Cell.emptyCell());

// Delete 2 lines at row 5
buf.deleteLine(5, 2, Cell.emptyCell());

// Insert/delete within a region
buf.insertLineArea(10, 2, null, rect(0, 5, 80, 20));
buf.deleteLineArea(8, 1, null, rect(0, 5, 80, 20));

// Cell insert/delete (ICH/DCH)
buf.insertCell(10, 5, 3, null);  // Insert 3 cells at (10, 5)
buf.deleteCell(10, 5, 2, null);  // Delete 2 cells at (10, 5)
```

### Dirty Tracking

`Buffer` supports optional per-cell dirty tracking to allow renderers to skip
unchanged regions. Enable it at creation time:

```dart
// Create a buffer with dirty-bit tracking enabled
final buf = Buffer.create(80, 24, tracksDirty: true);

// Mark a single cell as dirty explicitly
buf.markDirty(x, y);

// Check whether any row is dirty
if (buf.dirtyRows[y]) { ... }

// Check the dirty-bit for a specific cell column
// dirtyBits is a List<Uint32List>; each word covers 32 columns.
final word = buf.dirtyBits[y][x >> 5];
final bit = (word >> (x & 31)) & 1;
```

When `tracksDirty` is `false` (the default), `dirtyRows` and `dirtyBits` are
empty lists and dirty marking is a no-op. The UV terminal renderer uses dirty
tracking internally when it operates on an `OwnedCellScreen` to limit the
number of ANSI sequences emitted per frame.

### Cloning

```dart
// Clone entire buffer
final copy = buf.clone();

// Clone a region
final region = buf.cloneArea(rect(10, 10, 30, 15));
```

### Rendering to String

```dart
// Render with ANSI sequences
final ansiOutput = buf.render();

// Plain text (no escapes)
final plainText = buf.toString();
```

---

## Screen

`Screen` is the abstract interface for a 2D drawing surface:

```dart
abstract class Screen {
  Rectangle bounds();
  Cell? cellAt(int x, int y);
  void setCell(int x, int y, Cell? cell);
  WidthMethod widthMethod();
}
```

### Optional Fast-Path Interfaces

Implementations can provide optimized operations:

```dart
// ClearableScreen - fast full clear
abstract class ClearableScreen implements Screen {
  void clear();
}

// ClearAreaScreen - fast region clear
abstract class ClearAreaScreen implements Screen {
  void clearArea(Rectangle area);
}

// FillableScreen - fast full fill
abstract class FillableScreen implements Screen {
  void fill(Cell? cell);
}

// FillAreaScreen - fast region fill
abstract class FillAreaScreen implements Screen {
  void fillArea(Cell? cell, Rectangle area);
}

// CloneableScreen - clone backing buffer
abstract class CloneableScreen implements Screen {
  Object clone();
}

// CloneAreaScreen - clone region
abstract class CloneAreaScreen implements Screen {
  Object? cloneArea(Rectangle area);
}

// OwnedCellScreen - take ownership of a cell (zero-copy fast path)
abstract class OwnedCellScreen implements Screen {
  void setCellOwned(int x, int y, Cell? cell);
}
```

`OwnedCellScreen` lets implementations take ownership of an already-allocated `Cell` instead of cloning it, reducing allocations in high-frequency paint loops. Only pass cells that are not shared with another buffer or line.

### ScreenBuffer

`ScreenBuffer` is a concrete implementation combining `Screen` with a `Buffer`:

```dart
final screen = ScreenBuffer(80, 24);

// Use as Screen
screen.setCell(0, 0, Cell(content: 'H'));

// Access underlying buffer
screen.buffer.fill(Cell.emptyCell());
```

---

## Canvas

`Canvas` provides immediate-mode drawing with composition support:

```dart
final canvas = Canvas(80, 24);

// Basic operations
canvas.setCell(5, 5, Cell(content: '*'));
canvas.clear();
canvas.resize(100, 30);

// Compose drawables
canvas.compose(StyledString('Hello, World!'));
canvas.compose(roundedBorder());

// Render to string
final output = canvas.render();
```

### Composition Pattern

```dart
final canvas = Canvas(40, 10);

// Build up layers
canvas
  ..compose(normalBorder())
  ..compose(StyledString('\x1b[1mTitle\x1b[0m'));

// Or chain with method return
canvas.compose(drawer1).compose(drawer2);
```

---

## Drawable Interface

Any object that can draw itself onto a `Screen`:

```dart
abstract interface class Drawable {
  void draw(Screen screen, Rectangle area);
  Rectangle bounds();
}
```

### Built-in Drawables

#### StyledString

Renders ANSI-styled text with automatic SGR/OSC parsing:

```dart
final styled = StyledString('\x1b[1;31mBold Red\x1b[0m Normal');

// Get required bounds
final bounds = styled.bounds();  // Rectangle for text dimensions

// Draw into a screen region
styled.draw(screen, rect(0, 0, 40, 5));

// With word wrapping
final wrapped = StyledString('Long text...', wrap: true);

// With truncation indicator
final truncated = StyledString('Very long...', tail: '...');
```

#### UvBorder

Draws configurable borders around regions:

```dart
// Built-in border styles
final border = normalBorder();    // ┌─┐│└─┘
final rounded = roundedBorder();  // ╭─╮│╰─╯
final thick = thickBorder();      // ┏━┓┃┗━┛
final double = doubleBorder();    // ╔═╗║╚═╝
final block = blockBorder();      // ████
final ascii = asciiBorder();      // +-+|+-+
final hidden = hiddenBorder();    // Spaces

// Apply style to all sides
final styledBorder = roundedBorder().style(
  UvStyle(fg: UvColor.basic16(6)),  // Cyan
);

// Apply hyperlink
final linkedBorder = normalBorder().link(
  Link(url: 'https://example.com'),
);

// Draw into region
styledBorder.draw(screen, rect(0, 0, 20, 10));
```

#### EmptyDrawable

A no-op drawable for fallback scenarios:

```dart
final placeholder = EmptyDrawable(width: 10, height: 5);
placeholder.draw(screen, area);  // Does nothing
```

---

## Layer System

Layers enable z-ordered composition with hit-testing:

### Layer

```dart
// Create from string or Drawable
final layer = newLayer('Hello')
  ..setId('greeting')
  ..setX(10)
  ..setY(5)
  ..setZ(1);  // Higher z = on top

// Add child layers
layer.addLayers([
  newLayer('Child 1')..setX(2)..setY(1),
  newLayer('Child 2')..setX(2)..setY(2),
]);

// Find nested layer by ID
final found = layer.getLayer('child-id');

// Get max z in subtree
final maxZ = layer.maxZ();
```

### Compositor

Manages layer composition, drawing, and hit-testing:

```dart
// Create with initial layers
final comp = Compositor([
  newLayer('Background')..setZ(0),
  newLayer('Foreground')..setZ(1)..setId('fg'),
]);

// Add more layers
comp.addLayers([newLayer('Overlay')..setZ(2)]);

// Refresh after modifications
comp.refresh();

// Get computed bounds
final bounds = comp.bounds();

// Draw to screen
comp.draw(screen, bounds);

// Render to string
final output = comp.render();

// Hit testing - find top layer at position
final hit = comp.hit(15, 10);
if (!hit.isEmpty) {
  print('Hit layer: ${hit.id}');
  print('Layer bounds: ${hit.bounds}');
}

// Lookup by ID
final layer = comp.getLayer('fg');
```

### LayerHit

Result of hit-testing:

```dart
final hit = comp.hit(x, y);
hit.id       // Layer ID (empty if no hit)
hit.layer    // Layer instance (null if no hit)
hit.bounds   // Layer bounds (null if no hit)
hit.isEmpty  // true if no layer was hit
```

---

## Geometry

### Position

A 2D integer coordinate:

```dart
final pos = Position(10, 5);
print(pos.x);  // 10
print(pos.y);  // 5
```

### Rectangle

Inclusive-exclusive bounds `[min, max)`:

```dart
// Create from origin and size
final r = rect(10, 5, 30, 20);  // x=10, y=5, width=30, height=20

// Or with explicit bounds
final r2 = Rectangle(minX: 10, minY: 5, maxX: 40, maxY: 25);

// Properties
print(r.width);   // 30
print(r.height);  // 20
print(r.isEmpty); // false

// Point containment
print(r.contains(Position(15, 10)));  // true

// Rectangle containment
print(r.containsRect(rect(12, 8, 10, 5)));  // true

// Overlap detection
print(r.overlaps(rect(35, 20, 20, 10)));  // true

// Union (bounding box of both)
final union = r.union(rect(50, 30, 10, 10));

// Intersection
final inter = r.intersect(rect(20, 10, 30, 20));
```

---

## Layout Helpers

Utilities for splitting screen regions:

### Constraints

```dart
// Fixed size (absolute cells)
final fixed = Fixed(20);
print(fixed.apply(80));  // 20 (clamped to available)

// Percentage
final percent = Percent(30);
print(percent.apply(100));  // 30

// Ratio helper
final half = ratio(1, 2);  // 50%
```

### Splitting

```dart
final area = rect(0, 0, 80, 24);

// Horizontal split (left/right)
final (:left, :right) = splitHorizontal(area, Fixed(20));
// left: rect(0, 0, 20, 24)
// right: rect(20, 0, 60, 24)

// Vertical split (top/bottom)
final (:top, :bottom) = splitVertical(area, Percent(30));
// top: rect(0, 0, 80, 7)
// bottom: rect(0, 7, 80, 17)
```

### Positioning Helpers

```dart
final area = rect(0, 0, 80, 24);

// Centered rectangle
centerRect(area, 40, 10);      // Centered 40x10

// Corner/edge positions
topLeftRect(area, 20, 5);      // Top-left 20x5
topCenterRect(area, 20, 5);    // Top-center 20x5
topRightRect(area, 20, 5);     // Top-right 20x5
leftCenterRect(area, 20, 5);   // Left-center 20x5
rightCenterRect(area, 20, 5);  // Right-center 20x5
bottomLeftRect(area, 20, 5);   // Bottom-left 20x5
bottomCenterRect(area, 20, 5); // Bottom-center 20x5
bottomRightRect(area, 20, 5);  // Bottom-right 20x5
```

---

## Terminal Events and Input

### Event Types

All events extend the sealed `Event` class:

#### Key Events

```dart
// KeyPressEvent - key was pressed
// KeyReleaseEvent - key was released (with Kitty keyboard protocol)

terminal.events.listen((event) {
  if (event is KeyPressEvent) {
    final key = event.key();
    
    // Match by string (supports multiple alternatives)
    if (event.matchString('q', 'Q', 'ctrl+c')) {
      // Quit
    }
    
    // Get human-readable keystroke
    print(event.keystroke());  // "ctrl+shift+A"
  }
});
```

#### Mouse Events

```dart
// MouseClickEvent - button pressed
// MouseReleaseEvent - button released
// MouseWheelEvent - scroll wheel
// MouseMotionEvent - mouse moved/dragged

if (event is MouseClickEvent) {
  final mouse = event.mouse();
  print('Click at (${mouse.x}, ${mouse.y})');
  print('Button: ${MouseButton.toName(mouse.button)}');
  print('Modifiers: ${mouse.mod}');  // KeyMod bitmask
}
```

#### Window Events

```dart
// WindowSizeEvent - terminal resized
if (event is WindowSizeEvent) {
  print('New size: ${event.width}x${event.height}');
  print('Pixels: ${event.widthPx}x${event.heightPx}');
  terminal.resize(event.width, event.height);
}

// FocusEvent - terminal gained focus
// BlurEvent - terminal lost focus
```

#### Paste Events

```dart
// PasteEvent - bracketed paste content
if (event is PasteEvent) {
  print('Pasted: ${event.content}');
}
```

#### Device Reports

```dart
// PrimaryDeviceAttributesEvent - DA1 response
if (event is PrimaryDeviceAttributesEvent) {
  print('Attributes: ${event.attrs}');
  // attr 4 = Sixel support
}

// KeyboardEnhancementsEvent - Kitty keyboard protocol
if (event is KeyboardEnhancementsEvent) {
  if (event.supportsKeyReleases) {
    // Enable key release reporting
  }
}

// KittyGraphicsEvent - Kitty graphics protocol response
// BackgroundColorEvent - terminal background color
// ColorPaletteEvent - palette color response
```

### EventDecoder

Decodes raw terminal bytes into events:

```dart
final decoder = EventDecoder(
  legacy: LegacyKeyEncoding()
    .ctrlM(true)    // Ctrl+M as Enter
    .backspace(true), // Legacy backspace handling
);

// Decode bytes
final (consumed, event) = decoder.decode(bytes);
if (event != null) {
  // Handle event
}
```

---

## Mouse Handling

### MouseMode

Controls mouse reporting:

```dart
MouseMode.none    // No mouse reporting
MouseMode.cellMotion  // Button events + motion while a button is pressed
MouseMode.allMotion   // All motion events
```

### MouseButton

Button identifiers:

```dart
MouseButton.none
MouseButton.left
MouseButton.middle
MouseButton.right
MouseButton.wheelUp
MouseButton.wheelDown
MouseButton.wheelLeft
MouseButton.wheelRight
MouseButton.button4
MouseButton.button5

// Get name
MouseButton.toName(MouseButton.left);  // "left"
```

### Mouse Payload

```dart
final mouse = Mouse(
  x: 10,
  y: 5,
  button: MouseButton.left,
  mod: KeyMod.ctrl | KeyMod.shift,
);

print(mouse);  // "ctrl+shift+left (10,5)"
```

---

## Terminal Capabilities

`TerminalCapabilities` tracks discovered terminal features:

```dart
final caps = TerminalCapabilities(env: Platform.environment.entries
    .map((e) => '${e.key}=${e.value}').toList());

// Graphics support
caps.hasKittyGraphics  // Kitty graphics protocol
caps.hasSixel          // Sixel graphics
caps.hasITerm2         // iTerm2 image protocol

// Keyboard
caps.hasKeyboardEnhancements  // Kitty keyboard protocol

// Colors
caps.hasBackgroundColor  // Background color reported
caps.backgroundColor     // UvRgb? of background
caps.hasColorPalette     // Palette entries reported
caps.palette             // Map<int, UvRgb> of palette

// Primary device attributes
caps.primaryAttributes   // List<int> from DA1

// Update from events
caps.updateFromEvent(event);  // Returns true if changed
```

### Capability Detection Flow

```dart
final terminal = Terminal();
await terminal.start();

// Queries are sent automatically
// Listen for capability events
terminal.events.listen((event) {
  if (terminal.capabilities.updateFromEvent(event)) {
    // Capabilities changed - adapt rendering
    if (terminal.capabilities.hasKittyGraphics) {
      // Use Kitty graphics
    }
  }
});
```

---

## Rendering Pipeline

### UvTerminalRenderer

The core renderer computes minimal ANSI diffs:

```dart
final sink = StringBuffer();
final renderer = UvTerminalRenderer(sink, env: env, isTty: true);

// Resize
renderer.resize(80, 24);

// Render buffer (computes diff from previous frame)
renderer.render(buffer);

// Flush to sink
renderer.flush();

// Force full redraw
renderer.redraw(buffer);

// Mark for clear on next render
renderer.erase();
```

### Terminal Mode Control

```dart
// Alternate screen
renderer.enterAltScreen();
renderer.exitAltScreen();

// Cursor
renderer.hideCursor();
renderer.showCursor();
renderer.moveTo(10, 5);

// Mouse
renderer.enableMouseAllEvents();
renderer.disableMouseAllEvents();

// Paste
renderer.enableBracketedPaste();
renderer.disableBracketedPaste();

// Focus
renderer.enableFocusReporting();
renderer.disableFocusReporting();

// Kitty keyboard
renderer.pushKeyboardEnhancements(flags);
renderer.popKeyboardEnhancements();
```

### Render Metrics

Track rendering performance:

```dart
final metrics = renderer.metrics;

// Frame timing
metrics.frameCount         // Total frames
metrics.skippedFrames      // Frames with no changes
metrics.lastFrameTime      // Duration since last frame
metrics.averageFrameTime   // Rolling average

// Render timing  
metrics.lastRenderDuration    // Time spent in render()
metrics.averageRenderDuration // Rolling average

// FPS
metrics.currentFps    // Based on last frame
metrics.averageFps    // Rolling average
metrics.minFps        // Slowest in window
metrics.maxFps        // Fastest in window

// Utilization
metrics.renderTimePercentage  // % of frame time in render()

// Display
print(metrics.summary());
// "FPS: 60.0 (58.5-61.2) | Frame: 16ms | Render: 450µs (2.8%) | Frames: 1000 (skipped: 50)"
```

### Optimization Flags

```dart
// Enable scroll optimization (uses IL/DL instead of redraw)
renderer.setScrollOptim(true);

// Fullscreen mode (enables more optimizations)
renderer.setFullscreen(true);

// Relative cursor movement
renderer.setRelativeCursor(true);

// Tab stops for cursor movement
renderer.setTabStops(8);

// Backspace as movement
renderer.setBackspace(true);
```

### Performance Internals

The UV system applies several optimizations that are transparent to callers but
relevant when diagnosing performance or porting the library:

**Cell style/link packing** — `UvStyle` and `Link` are stored as compact
integer bitfields rather than heap-allocated objects. Cell display width is
stored in the same word with widened bit capacity so wide characters (width 2)
and image cells are represented without extra allocations. This keeps
per-cell memory low and improves cache locality for large buffers.

**Unicode string width caching** — `visibleLength` and `stringWidth` calls
for multi-character grapheme strings are memoized in a bounded `LruCache`.
This avoids re-scanning long styled strings (e.g. repeated `StyledString`
draws). Emoji presentation sequences (`\uFE0F`) are guarded with a separate
fast-path to prevent double-counting their display width.

**`expandTabs` fast-path** — Tab-expansion uses a protocol-aware path that
correctly handles Kitty and Sixel display widths. A fast-path skips tab
expansion entirely for strings that contain no `\t` characters, which is the
common case in programmatically generated output.

**Truecolor SGR clamping** — RGB components in `UvRgb` are clamped and
normalized to the `[0, 255]` byte range when generating ANSI SGR sequences.
This prevents invalid escape sequences from truncating or wrapping terminals
that do not clamp out-of-range values themselves.

**Render primitive microbenchmarks** — The UV renderer suite is covered by a
suite of focused microbenchmarks (`pkg:ultraviolet/benchmark/`) that track
per-frame buffer diff time, cell write throughput, and ANSI serialization
speed. Run with `dart run benchmark/` from the `ultraviolet` package.

---

## Buffer Filters and Render Sinks

```dart
import 'dart:io';

import 'package:ultraviolet/ultraviolet.dart';

Future<void> main() async {
  const width = 40;
  const height = 10;
  final sink = BufferRenderSink(width: width, height: height);
  final filter = LiquifyFilter(strength: 2.5);

  for (var frame = 0; frame < 20; frame++) {
    final buffer = Buffer.create(width, height);
    _drawBox(buffer, 0, 0, width, height);
    _drawText(buffer, 2, 2, 'LIQUIFY FILTER');
    _drawText(buffer, 2, 4, 'frame ${frame.toString().padLeft(2)}');

    final filtered = sink.render(buffer, [filter], dt: 1 / 30);

    stdout.write('\x1B[2J\x1B[H');
    stdout.write(filtered.render());
    stdout.write('\n');
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }
}

void _drawText(Buffer buffer, int x, int y, String text) {
  for (var i = 0; i < text.length; i++) {
    _setCell(buffer, x + i, y, text[i]);
  }
}

void _drawBox(Buffer buffer, int x, int y, int width, int height) {
  if (width < 2 || height < 2) return;
  _setCell(buffer, x, y, '+');
  _setCell(buffer, x + width - 1, y, '+');
  _setCell(buffer, x, y + height - 1, '+');
  _setCell(buffer, x + width - 1, y + height - 1, '+');

  for (var i = 1; i < width - 1; i++) {
    _setCell(buffer, x + i, y, '-');
    _setCell(buffer, x + i, y + height - 1, '-');
  }

  for (var j = 1; j < height - 1; j++) {
    _setCell(buffer, x, y + j, '|');
    _setCell(buffer, x + width - 1, y + j, '|');
  }
}

void _setCell(Buffer buffer, int x, int y, String ch) {
  final line = buffer.line(y);
  if (line == null) return;
  line.set(x, Cell(content: ch));
}
```

---

## Color Matrix Effects

`effects.dart` provides a `ColorMatrix` primitive (a 4×5 RGBA coefficient
matrix) and a `ColorMatrixFilter` that plugs into the `BufferFilter` pipeline.
Effects operate on cell style colors (fg, bg, underline color) while leaving
glyph content, display width, links, and drawables untouched.

### ColorMatrix

A `ColorMatrix` is a row-major 4×5 matrix of `double` coefficients. Each of
the four rows transforms one channel (R, G, B, A). The fifth column in each
row is an additive bias.

```dart
import 'package:ultraviolet/ultraviolet.dart';

// Built-in presets
final grayscale = ColorMatrix.grayscale();   // sRGB luminance
final inverted  = ColorMatrix.invert();      // flip RGB
final brightened = ColorMatrix.gain(1.25);   // scale all channels
final dimmed    = ColorMatrix.attenuation(0.6);

// Tint toward a color
final warmed = ColorMatrix.tint(const UvRgb(255, 180, 80), amount: 0.4);

// Chain two matrices
final combined = grayscale.followedBy(warmed);

// Collapse a list of matrices in order
final stacked = ColorMatrix.compose([grayscale, inverted, dimmed]);

// Apply directly to a UvStyle
final styled = UvStyle(fg: const UvRgb(0, 200, 255));
final transformed = grayscale.transformStyle(styled);
```

### ColorMatrixFilter

`ColorMatrixFilter` wraps a `ColorMatrix` as a `BufferFilter` so it can be
used directly in a `BufferRenderSink`:

```dart
import 'package:ultraviolet/ultraviolet.dart';

final sink = BufferRenderSink(width: 80, height: 24);

// Grayscale all foreground colors (preserve background)
final grayFg = ColorMatrixFilter.grayscale(background: false);

// Tint everything toward amber
final amber = ColorMatrixFilter.tint(
  const UvRgb(255, 191, 96),
  amount: 0.6,
);

final filtered = sink.render(sourceBuffer, [grayFg, amber], dt: 1 / 60);
renderer.render(filtered);
```

Named factory constructors on `ColorMatrixFilter`:

| Constructor | Effect |
|---|---|
| `ColorMatrixFilter.identity()` | No-op pass-through |
| `ColorMatrixFilter.grayscale()` | sRGB luminance desaturation |
| `ColorMatrixFilter.invert()` | Flip RGB channels |
| `ColorMatrixFilter.gain(amount)` | Scale all channels |
| `ColorMatrixFilter.attenuation(amount)` | Scale channels ≤ 1 |
| `ColorMatrixFilter.tint(color, amount)` | Blend toward a color |
| `ColorMatrixFilter.multiply(color)` | Per-channel multiply |

Each factory accepts `foreground`, `background`, and `underlineColor` boolean
flags to restrict which style components are transformed.

---

## Post-Processing Filters

`filters.dart` provides spatial and temporal post-processing filters that
extend the `BufferFilter` base class. They are designed to compose with
`ColorMatrixFilter` inside a `BufferRenderSink` pipeline.

```dart
import 'package:ultraviolet/ultraviolet.dart';

final sink = BufferRenderSink(width: 80, height: 24);

// Combine several filters in one pass
final crt = CrtFilter(
  distortion: 0.22,
  vignette: 0.16,
  scanline: 0.10,
  rollingBar: 0.08,
);

final filtered = sink.render(sourceBuffer, [crt], dt: elapsedSeconds);
renderer.render(filtered);
```

### Available Filters

| Filter | Effect |
|---|---|
| `LiquifyFilter` | Damped noise-field displacement |
| `VignetteFilter` | Radial edge darkening |
| `ScanlineFilter` | CRT horizontal scan-line dimming |
| `WaveDistortionFilter` | Sinusoidal cell displacement |
| `GhostingFilter` | Temporal afterimage persistence trail |
| `CrtFilter` | Composite CRT preset (wave + vignette + scanlines) |
| `AtmosphereFilter` | Gentle background bloom and vignette |

### Composite Presets

High-level presets compose multiple primitives into a single `CompositeFilter`:

```dart
// Warm amber monochrome monitor
final amber = AmberTerminalFilter(tint: 0.62, attenuation: 0.96);

// Green phosphor CRT
final phosphor = PhosphorFilter(tint: 0.58, distortion: 0.08);

// Phosphor with persistence trail
final trail = PhosphorTrailFilter(persistence: 0.42);

// Amber with trail
final amberTrail = AmberTrailFilter(persistence: 0.38);

// CRT with trail
final crtTrail = CrtTrailFilter(persistence: 0.32);
```

### BufferRenderSink

`BufferRenderSink` is the entry point for all filter pipelines:

```dart
final sink = BufferRenderSink(width: 80, height: 24);

// Resize when the terminal changes
sink.resize(newWidth, newHeight);

// Apply a filter list each frame
final result = sink.render(myBuffer, [filter1, filter2], dt: 1 / 60);
```

Internally the sink double-buffers render targets so filters never
read and write the same buffer simultaneously.

For detailed source API, see `package:ultraviolet/ultraviolet.dart`.

---

## Image Drawables

The UV system supports rendering images in the terminal via multiple graphics
protocols. All image rendering is abstracted behind the `Drawable` interface,
allowing portable code that adapts to terminal capabilities automatically.

### Drawable Interface

```dart
abstract interface class Drawable {
  /// Render to the given screen within the specified rectangle.
  void draw(Screen screen, Rectangle rect);

  /// The bounds (width, height) this drawable wants.
  Rectangle bounds();
}
```

`EmptyDrawable` is a no-op implementation used as a fallback when no image
protocol is available.

### Auto-Detection

Use `bestImageDrawableForTerminal()` to automatically select the best protocol
based on detected terminal capabilities:

```dart
import 'package:ultraviolet/ultraviolet.dart';
import 'package:image/image.dart' as img;

final image = img.Image(width: 100, height: 60);
final drawable = terminal.bestImageDrawableForTerminal(
  image,
  columns: 20,
  rows: 10,
);

drawable.draw(screen, rect(0, 0, 20, 10));
```

The selection priority is: **Kitty > iTerm2 > Sixel > HalfBlock**. The
`HalfBlock` fallback always works (requires only true color support).

### Protocol Implementations

#### KittyImageDrawable

Uses the [Kitty Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
to transmit images as base64-encoded PNG data. Supported in Kitty, WezTerm, and
other compatible terminals.

```dart
final drawable = KittyImageDrawable(
  image,
  id: 1,           // Optional image ID (auto-assigned if omitted)
  columns: 20,
  rows: 10,
  quiet: 2,        // Suppress terminal responses (0/1/2)
);
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `image` | `img.Image` | Source image |
| `id` | `int?` | Image ID (auto-assigned via `KittyImage.getNextImageId()`) |
| `columns` | `int` | Width in terminal cells |
| `rows` | `int` | Height in terminal cells |
| `quiet` | `int` | Quiet mode: 0 = normal, 1 = suppress OK, 2 = suppress all |

**How it works:** The image is PNG-encoded, base64-encoded, then sent as a single
escape sequence placed in the top-left cell. Remaining cells are marked as
occupied (width=0, empty content). Use `deleteSequence()` to clean up the image
when no longer needed.

#### ITerm2ImageDrawable

Uses the [iTerm2 Inline Images Protocol](https://iterm2.com/documentation-images.html).
Supported in iTerm2, WezTerm, and other compatible terminals.

```dart
final drawable = ITerm2ImageDrawable(
  image,
  name: 'photo.png',  // Optional display name
  columns: 20,
  rows: 10,
);
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `image` | `img.Image` | Source image |
| `name` | `String?` | Optional file name for the image |
| `columns` | `int` | Width in terminal cells |
| `rows` | `int` | Height in terminal cells |

**How it works:** The image is PNG-encoded, base64-encoded, and transmitted via
an OSC 1337 escape sequence. Like Kitty, it uses a single escape sequence in the
top-left cell with remaining cells marked as occupied.

#### SixelImageDrawable

Uses the [Sixel graphics format](https://en.wikipedia.org/wiki/Sixel), a legacy
protocol with broad support across terminals (xterm, mlterm, foot, WezTerm, etc.).

```dart
final drawable = SixelImageDrawable(
  image,
  columns: 20,
  rows: 10,
  maxColors: 256,         // Color palette size (default: 256)
  cellPixelWidth: 8,      // Pixels per cell horizontally
  cellPixelHeight: 16,    // Pixels per cell vertically
);
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `image` | `img.Image` | Source image |
| `columns` | `int` | Width in terminal cells |
| `rows` | `int` | Height in terminal cells |
| `maxColors` | `int` | Max palette colors (default: 256) |
| `cellPixelWidth` | `int?` | Pixel width per cell (for resize calculation) |
| `cellPixelHeight` | `int?` | Pixel height per cell (for resize calculation) |

**How it works:** The image is resized to the target pixel dimensions
(`columns * cellPixelWidth` x `rows * cellPixelHeight`), height is rounded up
to a multiple of 6 (Sixel band height), colors are quantized to `maxColors`,
then encoded as Sixel data. Single escape sequence in top-left cell.

#### HalfBlockImageDrawable

Unicode half-block fallback that works in any terminal with true color support.
Uses the `▀` (upper half block) character with foreground=top pixel and
background=bottom pixel to achieve 2 vertical pixels per cell.

```dart
final drawable = HalfBlockImageDrawable(
  image,
  columns: 20,
  rows: 10,
);
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `image` | `img.Image` | Source image |
| `columns` | `int` | Width in terminal cells |
| `rows` | `int` | Height in terminal cells |

**How it works:** Unlike the other protocols, HalfBlock renders **per-cell** —
each cell gets the `▀` character with the top pixel as foreground color and the
bottom pixel as background color. The image is resized to `columns` x `rows * 2`
pixels to fill the grid. No special terminal protocol support is required.

### Custom Drawables

Implement the `Drawable` interface to create custom drawables:

```dart
class AsciiArtDrawable implements Drawable {
  final String art;
  final int width;
  final int height;

  AsciiArtDrawable(this.art, {required this.width, required this.height});

  @override
  Rectangle bounds() => rect(0, 0, width, height);

  @override
  void draw(Screen screen, Rectangle rect) {
    final lines = art.split('\n');
    for (var y = 0; y < lines.length && y < rect.height; y++) {
      for (var x = 0; x < lines[y].length && x < rect.width; x++) {
        final line = screen.line(rect.y + y);
        if (line != null) {
          line.set(rect.x + x, Cell(content: lines[y][x]));
        }
      }
    }
  }
}
```

### Best Practices

- **Use auto-detection** (`bestImageDrawableForTerminal()`) for cross-terminal
  portability instead of hardcoding a specific protocol.
- **Clean up Kitty images** by calling `deleteSequence()` when removing images
  from the screen, to free terminal-side resources.
- **Reuse drawables** when redrawing the same image — avoid re-encoding on every
  frame. Cache the `Drawable` instance and call `draw()` repeatedly.
- **Consider HalfBlock for testing** — it requires no special terminal support
  and is useful for development on terminals without image protocol support.

---

## Style Bridge

`style_ops.dart` bridges UV styles with color profiles:

### Profile Conversion

```dart
import 'package:ultraviolet/ultraviolet.dart' as uv;

// Convert style to respect terminal capabilities
final converted = uv.convertStyle(style, uv.Profile.ansi256);

// True color -> unchanged
// ANSI 256 -> RGB downsampled to 256
// ANSI -> RGB/256 downsampled to 16
// ASCII/NoTTY -> colors stripped
```

### SGR Generation

```dart
// Full SGR sequence for a style
final sgr = uv.styleToSgr(style);
// "\x1b[1;3;38;2;255;0;0m" for bold italic red

// Diff sequence between styles (minimal change)
final diff = uv.styleDiff(oldStyle, newStyle);
```

---

## Quick Start

### Basic Terminal Application

```dart
import 'package:ultraviolet/ultraviolet.dart';

Future<void> main() async {
  final terminal = Terminal();
  
  try {
    await terminal.start();
    terminal.enterAltScreen();
    terminal.hideCursor();
    terminal.enableMouse();
    
    // Main loop
    await for (final event in terminal.events) {
      if (event is KeyPressEvent && event.matchString('q', 'ctrl+c')) {
        break;
      }
      
      if (event is WindowSizeEvent) {
        terminal.resize(event.width, event.height);
      }
      
      // Clear and draw
      terminal.clear();
      terminal.setCell(0, 0, Cell(
        content: 'Press Q to quit',
        style: UvStyle(fg: UvColor.basic16(2)),
      ));
      terminal.draw();
    }
  } finally {
    terminal.disableMouse();
    terminal.showCursor();
    terminal.exitAltScreen();
    await terminal.stop();
  }
}
```

### Using Canvas and Layers

```dart
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  // Create a canvas
  final canvas = Canvas(60, 20);
  
  // Build layers
  final compositor = Compositor([
    newLayer(roundedBorder())
      ..setId('border')
      ..setZ(0),
    newLayer(StyledString('\x1b[1mWelcome!\x1b[0m'))
      ..setId('title')
      ..setX(2)
      ..setY(0)
      ..setZ(1),
    newLayer(StyledString('Content goes here...'))
      ..setId('content')
      ..setX(2)
      ..setY(2)
      ..setZ(1),
  ]);
  
  // Render
  compositor.draw(canvas, canvas.bounds());
  print(canvas.render());
}
```

### Image Rendering

```dart
import 'package:ultraviolet/ultraviolet.dart';
import 'package:image/image.dart' as img;

Future<void> renderImage(Terminal terminal, img.Image image) async {
  // Get best drawable for terminal capabilities
  final drawable = terminal.bestImageDrawableForTerminal(
    image,
    columns: 40,
    rows: 20,
  );
  
  // Draw to terminal
  drawable.draw(terminal, rect(0, 0, 40, 20));
  terminal.draw();
}
```

---

## Reference

### Exports from `package:ultraviolet/ultraviolet.dart`

```dart
// `package:artisanal/uv.dart` (compatibility) re-exports the same API set.

// Core types
Terminal, Buffer, Line, LineData, Cell, Link, UvStyle
UvColor, UvBasic16, UvIndexed256, UvRgb

// Geometry
Position, Rectangle, rect

// Drawing
Screen, Canvas, Drawable, EmptyDrawable
StyledString, newStyledString, StyleState, LinkState, readStyle, readLink
UvBorder

// Layers
Layer, Compositor, LayerHit, newLayer

// Layout
splitHorizontal, splitVertical, Fixed, Percent

// Rendering
UvTerminalRenderer, RenderMetrics

// Events
Event, KeyEvent, KeyPressEvent, KeyReleaseEvent
MouseEvent, MouseClickEvent, MouseReleaseEvent, MouseWheelEvent, MouseMotionEvent
WindowSizeEvent, FocusEvent, BlurEvent, PasteEvent
KittyGraphicsEvent, PrimaryDeviceAttributesEvent, KeyboardEnhancementsEvent

// Input
EventDecoder, LegacyKeyEncoding
MouseMode, MouseButton

// Capabilities
TerminalCapabilities
```

## Where to go next

- [docs_index.md](docs_index.md) - Full documentation index
- [terminal.md](terminal.md) - Terminal abstraction
- [terminal_graphics.md](terminal_graphics.md) - Sixel / Kitty / iTerm2 image protocols
- [charting.md](charting.md) - Charting primitives
