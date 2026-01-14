/// Unified terminal module for artisanal.
///
/// This module provides a single source of truth for terminal operations
/// used throughout the package, including both static components and the
/// TUI runtime.
///
/// {@category Terminal}
///
/// {@macro artisanal_terminal_overview}
/// {@macro artisanal_terminal_raw_mode}
/// {@macro artisanal_terminal_ansi_sequences}
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
/// ```
library;

// ANSI escape sequences
export 'ansi.dart' show Ansi;

// Kitty Graphics Protocol
export 'kitty.dart' show KittyImage;
export 'iterm2.dart' show ITerm2Image;
export 'sixel.dart' show SixelImage;

// Key types and constants
export 'keys.dart' show Key, KeyType, Keys;

// Terminal interface and implementations
export 'terminal_base.dart'
    show
        Terminal,
        SplitTerminal,
        StdioTerminal,
        TtyTerminal,
        StringTerminal,
        RawModeGuard;

export 'stdin_stream.dart'
    show
        sharedStdinStream,
        isSharedStdinStreamStarted,
        shutdownSharedStdinStream;
