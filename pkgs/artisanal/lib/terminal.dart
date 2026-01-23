/// Unified terminal module for artisanal.
///
/// This library provides a single source of truth for terminal operations
/// used throughout the package, including both static components and the
/// TUI runtime.
///
/// {@category Terminal}
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal/terminal.dart';
///
/// // Create a terminal
/// final terminal = StdioTerminal();
///
/// // Use terminal operations
/// terminal.hideCursor();
/// terminal.write('Hello, ');
/// terminal.writeln('World!');
/// terminal.showCursor();
///
/// // Use ANSI codes directly
/// import 'dart:io';
/// stdout.write(Ansi.bold);
/// stdout.write('Bold text');
/// stdout.write(Ansi.reset);
///
/// // Check key input
/// if (Keys.isPrintable(byte)) { ... }
/// ```
///
/// ## Terminal Abstraction
///
/// {@macro artisanal_terminal_overview}
///
/// ## Raw Mode and Input
///
/// {@macro artisanal_terminal_raw_mode}
///
/// ## ANSI and Escape Sequences
///
/// {@macro artisanal_terminal_ansi_sequences}
///
/// {@template artisanal_terminal_overview}
/// Artisanal provides a unified [Terminal] interface that abstracts away the
/// differences between standard I/O, string buffers (for testing), and
/// specialized terminal emulators.
///
/// - [StdioTerminal]: The default implementation for real terminal apps.
/// - [StringTerminal]: Useful for unit testing terminal output.
/// - [TuiTerminal]: Extended interface for interactive TUI applications.
/// {@endtemplate}
///
/// {@template artisanal_terminal_raw_mode}
/// Interactive applications often require "raw mode" to receive input
/// character-by-character without waiting for a newline, and to disable
/// local echo.
///
/// Use [RawModeGuard] or [Terminal.enableRawMode] to manage this state
/// safely. Always ensure raw mode is disabled before the program exits to
/// avoid leaving the user's terminal in a broken state.
/// {@endtemplate}
///
/// {@template artisanal_terminal_ansi_sequences}
/// Artisanal includes a comprehensive [Ansi] utility class for generating
/// standard ANSI escape sequences for colors, styles, cursor movement, and
/// screen control.
///
/// For more advanced rendering, see the [Ultraviolet](package:artisanal/uv.dart)
/// subsystem.
/// {@endtemplate}
library;

export 'src/terminal/terminal.dart';
export 'src/terminal/ansi.dart';
export 'src/terminal/keys.dart';
export 'src/terminal/stdin_stream.dart';
