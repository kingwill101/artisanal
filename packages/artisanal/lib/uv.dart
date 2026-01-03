/// Ultraviolet (UV): High-performance terminal rendering and input.
///
/// The UV subsystem provides core rendering primitives, a diffing terminal
/// renderer, structured cell buffers, and fast input decoders to build
/// responsive, visually rich terminal UIs.
///
/// {@category Ultraviolet}
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
/// import 'package:artisanal/uv.dart';
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
///
/// ## Concepts
///
/// {@macro artisanal_uv_concept_overview}
///
/// ## Rendering
///
/// {@macro artisanal_uv_renderer_overview}
///
/// ## Input and Events
///
/// {@macro artisanal_uv_events_overview}
///
/// ## Performance Tips
///
/// {@macro artisanal_uv_performance_tips}
///
/// ## Compatibility
///
/// {@macro artisanal_uv_compatibility}
///
/// {@template artisanal_uv_concept_overview}
/// UV models the terminal as layers of drawable cells. A [Buffer] holds the
/// current state, a [UvTerminalRenderer] diffs and flushes changes, and
/// [Terminal] manages lifecycle and device capabilities. Use [Canvas] for
/// immediate-mode drawing, or [Screen] for a higher-level facade.
///
/// - A [Cell] contains a glyph and [UvStyle] (foreground/background, effects).
/// - [StyledString] enables styled runs with state readers like [readStyle].
/// - [Layer] and [Compositor] support stacking and hit-testing ([LayerHit]).
/// - [Rectangle] and [Position] describe geometry; see [rect] helper.
/// {@endtemplate}
///
/// {@template artisanal_uv_renderer_overview}
/// The [UvTerminalRenderer] computes minimal diffs between the previous and
/// next [Buffer] frames and emits optimized ANSI/OSC sequences to the terminal.
/// Combine it with [TerminalCapabilities] to adapt to device features (kitty,
/// sixel, hyperlinks, etc.). For text drawing, prefer [StyledString] and the
/// style ops to avoid per-cell overhead.
///
/// Example (pseudo-flow):
///
/// ```dart
/// final screen = Screen(size: Rectangle(0, 0, 80, 24));
/// final renderer = UvTerminalRenderer();
/// // mutate screen/buffers
/// renderer.render(screen.buffer);
/// ```
/// {@endtemplate}
///
/// {@template artisanal_uv_events_overview}
/// Input is decoded by [EventDecoder] into typed events:
///
/// - [KeyEvent], [KeyPressEvent] for keyboard input.
/// - [MouseEvent], [MouseClickEvent], [MouseMotionEvent] for mouse input.
/// - [WindowSizeEvent], [FocusEvent], [PasteEvent] for terminal state.
/// - [KittyGraphicsEvent], [PrimaryDeviceAttributesEvent] for device features.
///
/// Access mouse modes via [MouseMode] and buttons via [MouseButton].
/// {@endtemplate}
///
/// {@template artisanal_uv_performance_tips}
/// - Batch mutations on buffers to reduce diff churn.
/// - Prefer region updates; avoid full-screen rewrites.
/// - Use [StyledString] runs instead of per-cell style objects when possible.
/// - Cache geometry and avoid repeated allocations in hot paths.
/// - Detect capabilities once; gate feature use via [TerminalCapabilities].
/// {@endtemplate}
///
/// {@template artisanal_uv_compatibility}
/// UV targets modern terminals with ANSI + extended capabilities (kitty/sixel).
/// Behavior can vary across emulators; query [TerminalCapabilities] and
/// gracefully degrade. Hyperlinks ([Link], [LinkState]) and RGB ([UvRgb]) may
/// be unavailable on legacy terminals; fall back to [UvBasic16] or
/// [UvIndexed256] palettes.
/// {@endtemplate}
library;

export 'src/uv/terminal.dart' show Terminal;
export 'src/uv/buffer.dart' show Buffer, Line, LineData;
export 'src/uv/cell.dart'
    show Cell, Link, UvStyle, UvColor, UvBasic16, UvIndexed256, UvRgb;
export 'src/uv/event.dart'
    show
        Event,
        KeyEvent,
        WindowSizeEvent,
        MouseEvent,
        MouseClickEvent,
        MouseMotionEvent,
        KeyPressEvent,
        KittyGraphicsEvent,
        PrimaryDeviceAttributesEvent,
        FocusEvent,
        PasteEvent;
export 'src/uv/mouse.dart' show MouseMode, MouseButton;
export 'src/uv/border.dart' show UvBorder;
export 'src/uv/decoder.dart' show EventDecoder, LegacyKeyEncoding;
export 'src/uv/terminal_renderer.dart' show UvTerminalRenderer, RenderMetrics;
export 'src/uv/geometry.dart' show Position, Rectangle, rect;
export 'src/uv/capabilities.dart' show TerminalCapabilities;
export 'src/uv/styled_string.dart'
    show
        StyledString,
        newStyledString,
        LinkState,
        StyleState,
        readLink,
        readStyle;
export 'src/uv/layer.dart' show Layer, Compositor, newLayer, LayerHit;
export 'src/uv/canvas.dart' show Canvas;
export 'src/uv/layout.dart' show splitHorizontal, splitVertical, Fixed, Percent;
export 'src/uv/screen.dart' show Screen;
