# Changelog

## 0.1.1

### Fixed

- Quit the widget application when its child PTY exits, with an opt-out through
  `PseudoTerminalView.quitOnExit`.
- Ignore queued output from a previous PTY after `PseudoTerminalView` switches
  to a replacement process.

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
