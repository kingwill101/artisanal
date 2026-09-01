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
/// - `package:artisanal/editor_core.dart`: Stable low-level text document,
///   state, and viewport primitives for editor integrations.
/// - `package:artisanal/glamour.dart`: Glamour-style Markdown rendering.
/// - `package:ultraviolet/ultraviolet.dart`: Low-level cell-buffer rendering engine.
///
/// Charting, Liquify adapters, Markdown, scoring, and web helpers are exported
/// directly from this library (`package:artisanal/artisanal.dart`).
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

// Args Aliases
export 'args.dart' show Command, CommandRunner;
// Charting
export 'src/charting/charting.dart';
// Public component/widget registry
export 'catalog.dart';
export 'src/glamour/renderer.dart';
// Glamour (GitHub-style markdown rendering)
export 'src/glamour/theme.dart';
export 'src/io/components.dart' show Components;
// I/O
export 'src/io/component_theme.dart'
    show ComponentTheme, componentThemeForName, componentThemePresetNames;
export 'src/io/console.dart';
export 'src/io/inline_animation.dart'
    show InlineAnimation, InlineAnimationResult;
export 'src/io/output_theme.dart' show OutputTheme;
export 'src/io/uv_console.dart' show UVConsole;
export 'src/io/validators.dart' show Validators;
// Layout
export 'src/layout/layout.dart'
    show Layout, WhitespaceOptions, LayoutBreakpoint, ResponsiveBreakpoints;
// Liquify adapters
export 'src/liquid/liquid.dart';
// Renderer
export 'src/renderer/renderer.dart'
    show
        Renderer,
        TerminalRenderer,
        StringRenderer,
        NullRenderer,
        defaultRenderer,
        resetDefaultRenderer;
// Scoring
export 'src/scoring/scoring.dart';
export 'src/style/color.dart'
    show
        Color,
        AnsiColor,
        BasicColor,
        AdaptiveColor,
        CompleteAdaptiveColor,
        Colors,
        ColorProfile;
export 'src/style/style.dart';
export 'src/style/text_style.dart';
export 'src/style/theme.dart';
// Style - Verbosity
export 'src/style/verbosity.dart' show Verbosity;
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
export 'src/terminal/terminal.dart'
    show
        TerminalDimensions,
        TerminalBackend,
        BackendTerminal,
        EmbeddedTerminalBackend,
        TerminalBridge;
export 'src/terminal/host_server.dart' show TerminalHostServer;
// Stable low-level editor primitives
export 'src/tui/editor_core/editor_core.dart';
// Markdown rendering
export 'src/tui/markdown/ansi_renderer.dart';
export 'src/tui/markdown/github_comment.dart';
export 'src/tui/markdown/glamour_bridge.dart';
export 'src/tui/markdown/renderer.dart' show MarkdownRenderer;
export 'src/tui/markdown/fence_language_resolver.dart';
export 'src/tui/markdown/syntax_highlighter.dart';
// Hosts (terminal backends, bridges, and host servers)
export 'src/tui/tui.dart'
    show ProgramHostResolver, ProgramHostBinding, ProgramHost, ProgramOptions;
