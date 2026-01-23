/// TUI terminal abstraction layer.
///
/// This module re-exports the unified terminal primitives from the shared
/// terminal module, providing backward compatibility for existing TUI code.
///
/// ## Migration
///
/// The TUI terminal types are now aliases to the unified terminal module:
/// - `TuiTerminal` → `Terminal`
/// - `StdioTerminal` (TUI) → `StdioTerminal` (unified)
/// - `AnsiCodes` → `Ansi`
/// - `TerminalState` → Use `Terminal` state properties directly
///
/// New code should import from the unified terminal module:
/// ```dart
/// import 'package:artisanal/src/terminal/terminal.dart';
/// ```
library;

import '../terminal/terminal.dart' as unified;

// Re-export unified terminal types with TUI-compatible names
export '../terminal/terminal.dart'
    show
        Terminal,
        StdioTerminal,
        TtyTerminal,
        StringTerminal,
        RawModeGuard,
        Ansi,
        sharedStdinStream,
        isSharedStdinStreamStarted,
        shutdownSharedStdinStream;

/// Alias for backward compatibility.
///
/// The TUI terminal interface is now unified with the package-wide
/// [Terminal] interface. This typedef maintains compatibility with
/// existing code that uses `TuiTerminal`.
///
/// **Migration**: Replace `TuiTerminal` with `Terminal`.
typedef TuiTerminal = unified.Terminal;

/// Terminal state snapshot for saving/restoring.
///
/// This class captures the current state of terminal modes for
/// saving and restoring during operations like external process
/// execution.
class TerminalState {
  const TerminalState({
    required this.rawModeEnabled,
    required this.altScreenEnabled,
    required this.cursorHidden,
    required this.mouseEnabled,
    required this.bracketedPasteEnabled,
  });

  /// Creates a state snapshot from a terminal.
  factory TerminalState.capture(unified.Terminal terminal) {
    return TerminalState(
      rawModeEnabled: terminal.isRawMode,
      altScreenEnabled: terminal.isAltScreen,
      cursorHidden: false, // Terminal doesn't track cursor visibility
      mouseEnabled: terminal.isMouseEnabled,
      bracketedPasteEnabled: terminal.isBracketedPasteEnabled,
    );
  }

  final bool rawModeEnabled;
  final bool altScreenEnabled;
  final bool cursorHidden;
  final bool mouseEnabled;
  final bool bracketedPasteEnabled;

  /// Restores this state to the given terminal.
  void restore(unified.Terminal terminal) {
    // Restore in reverse order of typical setup
    if (bracketedPasteEnabled) {
      terminal.enableBracketedPaste();
    }
    if (mouseEnabled) {
      terminal.enableMouse();
    }
    if (altScreenEnabled) {
      terminal.enterAltScreen();
    }
    if (rawModeEnabled) {
      terminal.enableRawMode();
    }
    // Note: cursor visibility is handled by the renderer
  }
}
