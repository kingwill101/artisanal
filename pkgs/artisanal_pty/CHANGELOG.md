# Changelog

## 0.1.1

- Normalize bare line feeds from raw PTY output so shell output starts at
  column zero instead of drifting across the terminal.
- Acknowledge processed PTY chunks to support low-latency, backpressured output
  streaming when `PseudoTerminal.start(ackProcessed: true)` is used.
- Consume encoded keys in `TerminalView` so control input is delivered only to
  the focused terminal.
- Start the interactive shell example in cooked mode so terminal-generated
  signals such as `Ctrl+C` and `Ctrl+Z` reach foreground processes.
- Track DEC application-cursor mode for shell history navigation and answer
  terminal status/cursor-position reports used by interactive shell tooling.
- Support alternate-screen buffers, Kitty keyboard enhancement flags, and
  negotiated SGR/urxvt mouse reporting for embedded interactive TUI programs.
- Add bounded primary-screen scrollback with wheel navigation and an overlay
  scrollbar, while forwarding wheel events to alternate-screen applications
  that negotiate mouse tracking.
- Add explicit `PseudoTerminalView.width` and `height` overrides for nested
  layouts whose inherited constraints differ from their visible pane.
- Preserve terminal focus when switching between local scrollback and
  child-controlled mouse modes.

## 0.1.0

### Added

- Added a transport-independent `VirtualTerminal` screen model with
  incremental ANSI/CSI parsing, cursor movement, erasure, scrolling, resizing,
  SGR styling, UTF-8 decoding, and grapheme-aware output.
- Added `TerminalInputEncoder` for translating Artisanal key events into
  conventional xterm input sequences.
- Added the core `package:artisanal_pty/artisanal_pty.dart` entrypoint for
  plain Artisanal and TEA applications.
- Added the `package:artisanal_pty/widgets.dart` entrypoint with `TerminalView`
  and the `pty2`-backed `PseudoTerminalView` for `artisanal_widgets`
  applications.
- Added conditional platform support so non-IO targets receive an informative
  placeholder instead of importing `pty2`.
- Added Linux, macOS, Windows, and web package platform declarations.
- Added an interactive example that embeds the user's default shell.

### Fixed

- Quit the widget application when its child PTY exits, with an opt-out through
  `PseudoTerminalView.quitOnExit`.
- Ignore queued output from a previous PTY after `PseudoTerminalView` switches
  to a replacement process.
