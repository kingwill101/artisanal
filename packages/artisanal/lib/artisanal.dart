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
/// - `package:artisanal/tui.dart`: Interactive TUI framework (Elm Architecture).
/// - `package:artisanal/bubbles.dart`: Reusable interactive TUI components.
/// - `package:artisanal/uv.dart`: Low-level cell-buffer rendering engine.
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
        Key,
        KeyType,
        Keys;

// Style - Verbosity
export 'src/style/verbosity.dart' show Verbosity;
export 'src/style/style.dart';
export 'src/style/color.dart'
    show Color, AnsiColor, BasicColor, Colors, ColorProfile;

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
export 'src/layout/layout.dart' show Layout;

// Args Aliases
export 'args.dart' show Command, CommandRunner;
