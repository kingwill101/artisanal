# Terminal Graphics

Artisanal provides robust support for high-resolution graphics in the terminal, including images, icons, and custom drawings. It abstracts the complexities of different terminal graphics protocols into a unified API.

## Supported Protocols

Artisanal automatically detects and uses the best available protocol for your terminal:

1.  **Kitty Graphics Protocol**: The most advanced protocol, supporting high-performance image transmission, retained mode (caching), and superior alpha transparency.
2.  **iTerm2 Image Protocol**: Widely supported on macOS terminals (iTerm2, WezTerm, Ghostty).
3.  **Sixel Graphics**: A legacy but broadly supported bitmap format (xterm, foot, mlterm).
4.  **Half-Block Fallback**: If no high-resolution protocol is available, Artisanal falls back to using Unicode half-blocks (`▀`, `▄`) with foreground/background colors to render a lower-resolution version of the image.

## Usage

### Image Drawables

The easiest way to display an image is using the `Drawable` system in the `ultraviolet` package.

#### KittyImageDrawable

Used for the Kitty graphics protocol. It encodes images as PNG for efficient transmission.

```dart
final image = img.decodeImage(File('photo.png').readAsBytesSync())!;
final drawable = KittyImageDrawable(
  image,
  columns: 20, // Display width in terminal cells
  rows: 10,    // Display height in terminal cells
  id: 123,     // Optional: unique ID for caching/deletion
  clearBeforeDraw: true, // Delete existing placements for this ID before drawing
);
```

#### SixelImageDrawable

Used for the Sixel protocol. It handles color quantization (max 256 colors) and RLE compression automatically.

```dart
final drawable = SixelImageDrawable(
  image,
  columns: 20,
  rows: 10,
  maxColors: 256, // Optional: customize palette size
);
```

### Protocol Helpers

The `uv_graphics` module in `ultraviolet` provides low-level helpers for working
with these protocols directly. The primary source file is
`pkgs/ultraviolet/lib/src/uv/terminal_graphics.dart`.

- **`TerminalGraphicsProtocol`**: Enum for `kitty` or `sixel`.
- **`TerminalGraphicsControl`**: Represents a parsed graphics control sequence.
- **`parseTerminalGraphicsControls(String)`**: Scans a string for embedded graphics sequences.
- **`terminalGraphicsCellWidth(String)`**: Calculates how many columns a graphics-laden string will occupy on screen.

## Advanced Features

### Retained Graphics & Deferred Rendering

Artisanal uses a **deferred rendering** model for graphics to prevent cursor-state conflicts between text and images in the same frame:

- **Retained-mode images** (e.g., Kitty images with `C=1`) are queued during the main render pass.
- They are "flushed" after the normal text output, ensuring they are placed accurately at their target coordinates using absolute positioning or relative movement.
- Stale retained graphics from previous frames are automatically tracked and deleted via `TerminalGraphicsFrame.deletionSequencesSince`.

### Sixel Erase-before-render

Sixel graphics behave differently from modern protocols—they are "painted" onto the terminal's text grid. To prevent artifacts when images move or are removed, Artisanal's renderer detects Sixel content and forces a full screen erase (`\x1b[2J`) at the start of the frame if necessary.

### Tmux Passthrough

When running inside `tmux`, graphics sequences are often swallowed or corrupted. Artisanal automatically detects tmux sessions (via `TMUX` or `TERM` environment variables) and wraps Kitty/Sixel sequences in a **DCS passthrough** wrapper (`ESC P tmux; ... ESC \`).

### Embedded Sequence Parsing in StyledString

Graphics protocols work by embedding special escape sequences inside the
normal character stream. The `StyledString` type understands two such
control-sequence classes and treats them as opaque, zero-width spans rather
than renderable characters:

- **DCS (Device Control String)** — `ESC P ... ESC \` — used by Sixel and by
  the tmux DCS passthrough wrapper for Kitty sequences.
- **APC (Application Program Command)** — `ESC _ ... ESC \` — used by the
  Kitty graphics protocol for image transmission and management commands.

`StyledString.fromRaw` detects and preserves these spans during parsing so
that width calculations (`visibleLength`, `stringWidth`) exclude the
non-printing escape payload, while rendering passes the bytes through
unmodified.

The `parseTerminalGraphicsControls(String)` helper (from
`terminal_graphics.dart`) walks a raw string and extracts
`TerminalGraphicsControl` objects representing each DCS / APC segment:

```dart
import 'package:ultraviolet/ultraviolet.dart';

final raw = fetchRenderedLine(); // may contain Kitty or Sixel sequences
final controls = parseTerminalGraphicsControls(raw);
for (final ctrl in controls) {
  print('protocol: ${ctrl.protocol}, offset: ${ctrl.byteOffset}');
}
```

This is the mechanism that allows the TUI renderer to measure cursor positions
correctly even when graphics sequences are embedded mid-line.

### Cursor Movement Suppression

The Kitty protocol allows displaying an image without advancing the terminal's "real" cursor (`C=1`). Artisanal leverages this for precise layout, manually advancing the cursor in its internal state while keeping the terminal's hardware cursor stationary during the image display sequence.

## Performance Optimizations

- **PNG Encoding**: Images are transmitted as PNG rather than raw RGBA, reducing bandwidth by up to 90% for typical photos.
- **Sixel RLE**: Sixel data is RLE-compressed to minimize escape sequence length.
- **Dirty Tracking**: `OwnedCellScreen` and buffers support optional dirty tracking to skip re-rendering images that haven't changed.
- **Sixel Aspect Ratio**: Sixel headers include explicit raster dimensions and a 1:1 aspect ratio hint to ensure correct scaling in modern terminals like `foot`.
