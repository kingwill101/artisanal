/// Unified terminal module for artisanal.
///
/// This module provides a single source of truth for terminal operations
/// used throughout the package, including both static components and the
/// TUI runtime.
library;

// ANSI escape sequences
export 'ansi.dart' show Ansi;

// Kitty Graphics Protocol
export 'kitty.dart' show KittyImage;
export 'iterm2.dart' show ITerm2Image;
export 'sixel.dart' show SixelImage;

// Key types and constants
export 'keys.dart' show Key, KeyType, Keys;

// Terminal interface and implementations (always available — io-free)
export 'terminal_base.dart'
    show
        Terminal,
        SplitTerminal,
        StringTerminal,
        RawModeGuard;

// Io-dependent terminal implementations (native only)
export 'terminal_io_stub.dart'
    if (dart.library.io) 'terminal_io_impl.dart';

// Report probe (probe function is io-dependent, snapshot type is io-free)
export 'report_probe_stub.dart'
    if (dart.library.io) 'report_probe.dart';

// Backend interface and io-free implementations
export 'backend.dart'
    show
        TerminalDimensions,
        TerminalBackend,
        BackendTerminal,
        EmbeddedTerminalBackend,
        TerminalBridge;

// Io-dependent backends (native only)
export 'backend_io_stub.dart'
    if (dart.library.io) 'backend_io_impl.dart';

// Io-dependent bridge protocol, hosts, and stdin stream (native only)
export 'bridge_protocol_stub.dart'
    if (dart.library.io) 'bridge_protocol.dart';
export 'browser_host_stub.dart'
    if (dart.library.io) 'browser_host.dart';
export 'socket_host_stub.dart'
    if (dart.library.io) 'socket_host.dart';
export 'stdin_stream_stub.dart'
    if (dart.library.io) 'stdin_stream.dart';
