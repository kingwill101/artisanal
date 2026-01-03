/// ANSI escape sequence constants and utilities for terminal control.
///
/// This library provides a comprehensive set of ANSI escape sequences used by
/// the Ultraviolet renderer to control cursor position, screen clearing,
/// mouse tracking, and more.
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_renderer_overview}
library;

/// A collection of ANSI escape sequence constants and utilities.
///
/// This class provides static constants for common terminal control sequences
/// such as cursor movement, screen clearing, and mode switching.
///
/// Upstream: `github.com/charmbracelet/x/ansi` (used by `third_party/ultraviolet/*`).
abstract final class UvAnsi {
  // Upstream: `github.com/charmbracelet/x/ansi` (`ResetStyle`).
  static const resetStyle = '\x1b[m';

  static const cursorHomePosition = '\x1b[H';
  static const eraseEntireScreen = '\x1b[2J';
  static const eraseScreenBelow = '\x1b[J';

  static const eraseLineRight = '\x1b[K';
  static const eraseLineLeft = '\x1b[1K';
  static const eraseEntireLine = '\x1b[2K';

  static const reverseIndex = '\x1bM';

  // Auto wrap mode (DECAWM).
  static const resetModeAutoWrap = '\x1b[?7l';
  static const setModeAutoWrap = '\x1b[?7h';

  // Alternate screen buffer (DECSET/DECRST 1049).
  static const setModeAltScreenSaveCursor = '\x1b[?1049h';
  static const resetModeAltScreenSaveCursor = '\x1b[?1049l';

  // Cursor visibility (DECTCEM).
  static const hideCursor = '\x1b[?25l';
  static const showCursor = '\x1b[?25h';

  // Mouse tracking.
  static const enableMouseAllEvents = '\x1b[?1003h';
  static const disableMouseAllEvents = '\x1b[?1003l';
  static const enableMouseSgr = '\x1b[?1006h';
  static const disableMouseSgr = '\x1b[?1006l';

  // Bracketed paste.
  static const enableBracketedPaste = '\x1b[?2004h';
  static const disableBracketedPaste = '\x1b[?2004l';

  // Focus reporting.
  static const enableFocusReporting = '\x1b[?1004h';
  static const disableFocusReporting = '\x1b[?1004l';

  /// Returns an ANSI sequence that moves the cursor up by [n] rows.
  static String cursorUp(int n) => n == 1 ? '\x1b[A' : '\x1b[${n}A';

  /// Returns an ANSI sequence that moves the cursor down by [n] rows.
  static String cursorDown(int n) => n == 1 ? '\x1b[B' : '\x1b[${n}B';

  /// Returns an ANSI sequence that moves the cursor forward by [n] columns.
  static String cursorForward(int n) => n == 1 ? '\x1b[C' : '\x1b[${n}C';

  /// Returns an ANSI sequence that moves the cursor backward by [n] columns.
  static String cursorBackward(int n) => n == 1 ? '\x1b[D' : '\x1b[${n}D';

  /// Returns an ANSI sequence that moves the cursor to 1-based [col1]/[row1].
  static String cursorPosition(int col1, int row1) {
    // Upstream (`x/ansi`): `CursorPosition(1,1)` compacts to `ESC [ H`.
    if (col1 == 1 && row1 == 1) return cursorHomePosition;
    return '\x1b[$row1;${col1}H';
  }

  /// Returns an ANSI sequence that moves to absolute 1-based [row1].
  static String verticalPositionAbsolute(int row1) => '\x1b[${row1}d';

  /// Returns an ANSI sequence that moves to absolute 1-based [col1].
  static String horizontalPositionAbsolute(int col1) => '\x1b[${col1}G';

  /// Returns an ANSI sequence for forward-tab by [n] stops.
  static String cursorHorizontalForwardTab(int n) =>
      n == 1 ? '\x1b[I' : '\x1b[${n}I';

  /// Returns an ANSI sequence for backward-tab by [n] stops.
  static String cursorBackwardTab(int n) => n == 1 ? '\x1b[Z' : '\x1b[${n}Z';

  /// Returns an ANSI sequence to insert [n] lines.
  static String insertLine(int n) => n == 1 ? '\x1b[L' : '\x1b[${n}L';

  /// Returns an ANSI sequence to delete [n] lines.
  static String deleteLine(int n) => n == 1 ? '\x1b[M' : '\x1b[${n}M';

  /// Returns an ANSI sequence to delete [n] characters.
  static String deleteCharacter(int n) => n == 1 ? '\x1b[P' : '\x1b[${n}P';

  /// Returns an ANSI sequence to insert [n] characters.
  static String insertCharacter(int n) => n == 1 ? '\x1b[@' : '\x1b[$n@';

  /// Returns an ANSI sequence to erase [n] characters.
  static String eraseCharacter(int n) => n == 1 ? '\x1b[X' : '\x1b[${n}X';

  /// Returns an ANSI sequence to repeat the previous character [n] times.
  static String repeatPreviousCharacter(int n) =>
      n == 1 ? '\x1b[b' : '\x1b[${n}b';

  /// Returns an ANSI sequence to scroll up by [n] lines.
  static String scrollUp(int n) => n == 1 ? '\x1b[S' : '\x1b[${n}S';

  /// Returns an ANSI sequence to scroll down by [n] lines.
  static String scrollDown(int n) => n == 1 ? '\x1b[T' : '\x1b[${n}T';

  /// Returns an ANSI sequence to set scrolling margins to [top1]/[bottom1].
  static String setTopBottomMargins(int top1, int bottom1) =>
      '\x1b[$top1;${bottom1}r';

  /// Returns an OSC 8 hyperlink sequence for [url] and [params].
  static String setHyperlink(String url, String params) {
    // OSC 8: ESC ] 8 ; params ; url BEL
    //
    // Upstream uses BEL terminator (also supported by most terminals).
    return '\x1b]8;$params;$url\x07';
  }

  /// Returns the OSC 8 sequence that clears the current hyperlink.
  static String resetHyperlink() => setHyperlink('', '');
}
