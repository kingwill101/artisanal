/// Artisanal: A polished CLI framework for Dart.
///
/// This library provides the core CLI experience, including:
/// - [Console] for rich terminal output and interactive prompts.
/// - [Verbosity] levels for controlling output detail.
/// - Unified [Terminal] abstraction for raw mode and ANSI handling.
///
/// {@category Core}
///
/// ## Functional Areas
///
/// - **I/O**: [Console] provides a high-level API for writing to stdout/stderr,
///   handling verbosity, and running tasks with status indicators.
/// - **Terminal**: [Terminal] and [StdioTerminal] handle raw mode, cursor
///   positioning, and input event decoding.
/// - **Styling**: [Style] and [Color] provide a fluent API for terminal text
///   formatting (Lip Gloss-inspired).
///
/// ## High-Level I/O
///
/// {@macro artisanal_io_overview}
///
/// ## Verbosity and Logging
///
/// {@macro artisanal_io_verbosity}
///
/// ## Modular Exports
///
/// For specific functionality, you may want to import the modular libraries:
/// - `package:artisanal/args.dart`: Command-line argument parsing and runners.
/// - `package:artisanal/style.dart`: Full Lip Gloss-style styling system.
/// - `package:artisanal/tui.dart`: Interactive TUI framework (Elm Architecture),
///   including the core runtime, key/mouse messages, and replay/trace utilities.
/// - `package:artisanal/bubbles.dart`: Reusable interactive TUI components.
/// - `package:artisanal/terminal.dart`: Unified terminal abstraction and ANSI handling.
/// - `package:artisanal/uv.dart`: Compatibility re-export for UV cell-buffer types.
/// - `package:artisanal/compat.dart`: Backward-compatible shims for prior APIs.
/// - `package:artisanal/widgets.dart`: Stable re-export of the widget framework.
/// - `package:artisanal/editor_core.dart`: Stable low-level text document,
///   state, and viewport primitives for editor integrations.
/// - `package:artisanal/glamour.dart`: Glamour-style Markdown rendering.
/// - `package:ultraviolet/ultraviolet.dart`: Low-level cell-buffer rendering engine.
///
/// Charting, Liquify adapters, Markdown, physics, scoring, web helpers,
/// widget testing, and the remote plugin protocol are exported directly from
/// this library (`package:artisanal/artisanal.dart`).
///
/// {@template artisanal_io_overview}
/// The [Console] class is the primary entry point for high-level CLI output.
/// It supports:
/// - Writing styled text with verbosity awareness.
/// - Rendering [DisplayComponent]s (tables, lists, panels).
/// - Interactive prompts (confirm, select, input).
/// - Task tracking with spinners and progress bars.
/// {@endtemplate}
///
/// {@template artisanal_io_verbosity}
/// [Verbosity] levels allow users to control the amount of output produced
/// by your CLI.
/// - `quiet`: Only essential output.
/// - `normal`: Standard output (default).
/// - `verbose`: Detailed information for debugging.
/// - `debug`: Maximum detail, including internal state.
/// {@endtemplate}
library;

import 'src/io/console.dart' show Console;

// I/O
export 'src/io/console.dart';

export 'src/io/components.dart' show Components;
export 'src/io/inline_animation.dart'
    show InlineAnimation, InlineAnimationResult;
export 'src/io/output_theme.dart' show OutputTheme;
export 'src/io/uv_console.dart' show UVConsole;
export 'src/io/validators.dart' show Validators;

// Terminal utilities
export 'src/terminal/terminal.dart'
    show
        Terminal,
        StdioTerminal,
        StringTerminal,
        RawModeGuard,
        Ansi,
        KittyImage,
        TerminalReportProbe,
        TerminalReportSnapshot,
        Key,
        KeyType,
        Keys;

// Hosts (terminal backends, bridges, and host servers)
export 'src/tui/tui.dart'
    show ProgramHostResolver, ProgramHostBinding, ProgramHost, ProgramOptions;
export 'src/terminal/terminal.dart'
    show
        TerminalDimensions,
        TerminalBackend,
        BackendTerminal,
        EmbeddedTerminalBackend,
        TerminalBridge;
export 'src/terminal/backend_io_impl.dart'
    if (dart.library.html) 'src/terminal/backend_io_stub.dart'
    show StdioTerminalBackend, SocketTerminalBackend;
export 'src/terminal/bridge_protocol.dart'
    if (dart.library.html) 'src/terminal/bridge_protocol_stub.dart'
    show
        TerminalBridgeMessageType,
        TerminalBridgeMessage,
        TerminalBridgeJsonChannel,
        JsonTerminalBackend,
        WebSocketTerminalBackend;
export 'src/terminal/browser_host.dart'
    if (dart.library.html) 'src/terminal/browser_host_stub.dart'
    show BrowserTerminalSessionHandler, BrowserTerminalHostServer;
export 'src/terminal/socket_host.dart'
    if (dart.library.html) 'src/terminal/socket_host_stub.dart'
    show SocketTerminalSessionHandler, SocketTerminalHostServer;

// Style - Verbosity
export 'src/style/verbosity.dart' show Verbosity;
export 'src/style/style.dart';
export 'src/style/color.dart'
    show
        Color,
        AnsiColor,
        BasicColor,
        AdaptiveColor,
        CompleteAdaptiveColor,
        Colors,
        ColorProfile;

// Renderer
export 'src/renderer/renderer.dart'
    show
        Renderer,
        TerminalRenderer,
        StringRenderer,
        NullRenderer,
        defaultRenderer,
        resetDefaultRenderer;

// Layout
export 'src/layout/layout.dart'
    show Layout, WhitespaceOptions, LayoutBreakpoint, ResponsiveBreakpoints;

// Args Aliases
export 'args.dart' show Command, CommandRunner;

// Charting
export 'src/charting/charting.dart';

// Liquify adapters
export 'src/liquid/liquid.dart';

// Stable low-level editor primitives
export 'src/tui/editor_core/editor_core.dart';

// Markdown rendering
export 'src/tui/markdown/ansi_renderer.dart';
export 'src/tui/markdown/fence_language_resolver.dart';
export 'src/tui/markdown/syntax_highlighter.dart';

// Glamour (GitHub-style markdown rendering)
export 'src/glamour/theme.dart';
export 'src/glamour/renderer.dart';

// Physics
export 'src/physics/physics.dart';
export 'package:forge2d/forge2d.dart' show Joint, RevoluteJoint, DistanceJoint;

// Scoring
export 'src/scoring/scoring.dart';

// Web helpers (web/Flutter only — pulls in dart:js_interop)
export 'src/web/web_stub.dart' if (dart.library.html) 'src/web/web.dart';

// Widget testing
export 'package:artisanal_widgets/testing.dart';

// Remote plugin protocol
export 'src/plugins/plugins_impl.dart'
    if (dart.library.html) 'src/plugins/plugins_stub.dart';

// Hosts / terminal backends (formerly `hosts.dart`)
export 'src/tui/tui.dart' show ProgramHostResolver, ProgramHostBinding, ProgramHost, ProgramOptions;
export 'src/terminal/terminal.dart'
    show
        TerminalDimensions,
        TerminalBackend,
        BackendTerminal,
        EmbeddedTerminalBackend,
        TerminalBridge;
export 'src/terminal/backend_io_impl.dart'
    if (dart.library.html) 'src/terminal/backend_io_stub.dart'
    show StdioTerminalBackend, SocketTerminalBackend;
export 'src/terminal/bridge_protocol.dart'
    if (dart.library.html) 'src/terminal/bridge_protocol_stub.dart'
    show
        TerminalBridgeMessageType,
        TerminalBridgeMessage,
        TerminalBridgeJsonChannel,
        JsonTerminalBackend,
        WebSocketTerminalBackend;
export 'src/terminal/browser_host.dart'
    if (dart.library.html) 'src/terminal/browser_host_stub.dart'
    show BrowserTerminalSessionHandler, BrowserTerminalHostServer;
export 'src/terminal/socket_host.dart'
    if (dart.library.html) 'src/terminal/socket_host_stub.dart'
    show SocketTerminalSessionHandler, SocketTerminalHostServer;
