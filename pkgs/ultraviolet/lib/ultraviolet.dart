/// Ultraviolet (UV): High-performance terminal rendering and input.
///
/// The UV subsystem provides core rendering primitives, a diffing terminal
/// renderer, structured cell buffers, and fast input decoders to build
/// responsive, visually rich terminal UIs.
///
/// ## Key Components
///
/// - **[Terminal]**: Lifecycle, I/O, and orchestration for UV apps.
/// - **[Buffer]**: A 2D grid of [Cell]s representing screen state.
/// - **[Cell]**: A single glyph with [UvStyle] and optional [Link].
/// - **[UvTerminalRenderer]**: Efficient diff-based rendering to the terminal.
/// - **[EventDecoder]**: Fast ANSI/kitty input decoder for keys and mouse.
/// - **[Screen]**: High-level convenient API over buffers and rendering.
/// - **[Canvas]**: Immediate-mode drawing utilities on top of buffers.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:ultraviolet/ultraviolet.dart';
///
/// void main() async {
///   final terminal = Terminal();
///   await terminal.start();
///
///   // Draw a red "H" at (0, 0).
///   terminal.setCell(0, 0, Cell(
///     content: 'H',
///     style: UvStyle(fg: UvColor.rgb(255, 0, 0)),
///   ));
///
///   terminal.draw();
///   await terminal.stop();
/// }
/// ```
library;

export 'src/uv/terminal.dart';
export 'src/uv/buffer.dart' show Buffer, Line, LineData;
export 'src/uv/cell.dart'
    show
        Cell,
        Link,
        UvStyle,
        UvColor,
        UvBasic16,
        UvIndexed256,
        UvRgb,
        Attr,
        UnderlineStyle;
export 'src/uv/event.dart';
export 'src/uv/mouse.dart' show MouseMode, MouseButton, Mouse;
export 'src/uv/border.dart';
export 'src/uv/cursor.dart';
export 'src/uv/decoder.dart' show EventDecoder, LegacyKeyEncoding;
export 'src/uv/terminal_renderer.dart';
export 'src/uv/geometry.dart' show Position, Rectangle, rect;
export 'src/uv/capabilities.dart';
export 'src/uv/styled_string.dart'
    show
        StyledString,
        newStyledString,
        LinkState,
        StyleState,
        readLink,
        readStyle,
        SgrParam;
export 'src/uv/layer.dart' show Layer, Compositor, newLayer, LayerHit;
export 'src/uv/canvas.dart' show Canvas;
export 'src/uv/layout.dart';
export 'src/uv/screen.dart';
export 'src/uv/filters.dart'
    show
        BufferFilter,
        BufferRenderSink,
        LiquifyFilter,
        CompositeFilter,
        VignetteFilter,
        ScanlineFilter,
        WaveDistortionFilter,
        GhostingFilter,
        CrtFilter,
        AtmosphereFilter;
export 'src/uv/effects.dart'
    show
        AmberTrailFilter,
        ColorMatrix,
        ColorMatrixFilter,
        AmberTerminalFilter,
        CrtTrailFilter,
        PhosphorFilter,
        PhosphorTrailFilter;
export 'src/uv/drawable.dart' show Drawable, EmptyDrawable;
export 'src/unicode/width.dart'
    show
        runeWidth,
        stringWidth,
        maxLineWidth,
        WidthMethod,
        WidthMethodX,
        emojiPresentationWidth,
        setEmojiPresentationWidth;
export 'src/uv/halfblock_drawable.dart' show HalfBlockImageDrawable;
export 'src/uv/iterm2_drawable.dart' show ITerm2ImageDrawable;
export 'src/uv/kitty_drawable.dart' show KittyImageDrawable;
export 'src/uv/sixel_drawable.dart' show SixelImageDrawable;
export 'src/uv/terminal_graphics.dart';
export 'src/uv/ansi_slice.dart' show cutAnsiByCells;
export 'src/uv/key.dart';
export 'src/uv/key_table.dart';
export 'src/uv/ansi.dart' show UvAnsi;
// Windows-only CONIN$ native reader; lets the TUI bypass Dart's stdin so
// Ctrl+Z (0x1A) does not latch the stream into EOF when
// ENABLE_VIRTUAL_TERMINAL_INPUT is active. Imported by artisanal's stdin
// stream source on Windows.
export 'src/uv/terminal_windows_native.dart' show NativeWindowsInputStream, sharedWindowsInputStream;
export 'src/ansi.dart' show Ansi;
export 'src/uv/style_ops.dart';
export 'src/uv/progress_bar.dart';
export 'src/uv/wrap.dart';
export 'src/uv/screen_ops.dart';
export 'src/uv/color_utils.dart';
export 'src/colorprofile/profile.dart';
export 'src/colorprofile/detect.dart' show detect;
export 'src/colorprofile/convert.dart';
export 'src/colorprofile/downsample.dart';
export 'src/colorprofile/environ.dart';
export 'src/unicode/grapheme.dart';
