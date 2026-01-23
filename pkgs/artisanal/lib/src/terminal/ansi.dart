library;

import 'package:characters/characters.dart';
import '../unicode/width.dart';

/// Unified ANSI escape sequence constants and utilities.
///
/// This module provides a single source of truth for all ANSI escape sequences
/// used throughout the artisanal package, including both static components
/// and the TUI runtime.
///
/// {@category Terminal}
///
/// {@macro artisanal_terminal_ansi_sequences}
///
/// ```dart
/// import 'package:artisanal/terminal.dart';
///
/// // Use constants
/// stdout.write(Ansi.cursorHide);
/// stdout.write(Ansi.clearScreen);
/// ```
abstract final class Ansi {
  /// Non-breaking space (NBSP, U+00A0).
  ///
  /// Upstream parity: `x/ansi.NBSP`.
  static const nbsp = '\u00A0';

  /// Default tab width used by our string renderers when expanding `\t`.
  ///
  /// Upstream parity: lipgloss v2 default tab width is 4.
  static const defaultTabWidth = 4;

  /// Expands tab characters (`\t`) to spaces.
  ///
  /// Semantics:
  /// - `tabWidth == -1`: do not expand tabs
  /// - `tabWidth == 0`: remove tabs
  /// - otherwise: replace each tab with `tabWidth` spaces
  static String expandTabs(String text, {int tabWidth = defaultTabWidth}) {
    if (tabWidth == -1) return text;
    if (tabWidth == 0) return text.replaceAll('\t', '');
    return text.replaceAll('\t', ' ' * tabWidth);
  }

  /// If [text] contains an ANSI escape sequence starting at [index], returns
  /// the index immediately after the sequence; otherwise returns [index].
  ///
  /// This is intentionally *byte-ish* (ASCII) parsing for terminal control
  /// sequences and is independent of Unicode/grapheme helpers.
  ///
  /// Supported:
  /// - CSI: `ESC [ ... <final>`
  /// - OSC: `ESC ] ... (BEL|ST)`
  /// - DCS/APC/PM/SOS: `ESC P|_|^|X ... ST`
  /// - 2-byte ESC sequences (fallback)
  static int consumeEscapeSequence(String text, int index) {
    if (index < 0 || index >= text.length) return index;
    if (text.codeUnitAt(index) != 0x1b) return index;
    if (index + 1 >= text.length) return index + 1;

    final next = text.codeUnitAt(index + 1);

    // CSI: ESC [
    if (next == 0x5b) {
      var j = index + 2;
      while (j < text.length) {
        final cu = text.codeUnitAt(j);
        if (cu >= 0x40 && cu <= 0x7e) return j + 1;
        j++;
      }
      return text.length;
    }

    // OSC: ESC ] ... (BEL or ST terminator)
    if (next == 0x5d) {
      var j = index + 2;
      while (j < text.length) {
        final cu = text.codeUnitAt(j);
        if (cu == 0x07) return j + 1; // BEL
        if (cu == 0x1b &&
            j + 1 < text.length &&
            text.codeUnitAt(j + 1) == 0x5c) {
          return j + 2; // ST (ESC \)
        }
        j++;
      }
      return text.length;
    }

    // DCS/APC/PM/SOS: ESC P / ESC _ / ESC ^ / ESC X ... ST
    if (next == 0x50 || next == 0x5f || next == 0x5e || next == 0x58) {
      var j = index + 2;
      while (j < text.length) {
        final cu = text.codeUnitAt(j);
        if (cu == 0x1b &&
            j + 1 < text.length &&
            text.codeUnitAt(j + 1) == 0x5c) {
          return j + 2; // ST
        }
        j++;
      }
      return text.length;
    }

    // Simple 2-byte ESC sequences.
    return (index + 2).clamp(0, text.length);
  }

  /// Request primary device attributes (DA1).
  ///
  /// Terminal responds with `ESC [ ? <attrs> c`.
  ///
  /// Upstream parity: `x/ansi.RequestPrimaryDeviceAttributes`.
  static const requestPrimaryDeviceAttributes = '\x1b[?c';

  /// Requests the terminal foreground color (OSC 10).
  ///
  /// Terminal responds with `ESC ] 10 ; <color> (BEL|ST)`.
  static const requestForegroundColor = '\x1b]10;?\x07';

  /// Requests the terminal background color (OSC 11).
  ///
  /// Terminal responds with `ESC ] 11 ; <color> (BEL|ST)`.
  static const requestBackgroundColor = '\x1b]11;?\x07';

  /// Requests the terminal cursor color (OSC 12).
  ///
  /// Terminal responds with `ESC ] 12 ; <color> (BEL|ST)`.
  static const requestCursorColor = '\x1b]12;?\x07';

  // ─────────────────────────────────────────────────────────────────────────────
  // Escape Sequences
  // ─────────────────────────────────────────────────────────────────────────────

  /// The escape character (ESC, 0x1B).
  static const escape = '\x1b';

  /// The Control Sequence Introducer (ESC [).
  static const csi = '\x1b[';

  /// The Operating System Command introducer (ESC ]).
  static const osc = '\x1b]';

  /// The Application Program Command introducer (ESC _).
  static const apc = '\x1b_';

  /// The String Terminator (ESC \).
  static const st = '\x1b\\';

  /// The Bell character (BEL, 0x07).
  static const bel = '\x07';

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  /// Hides the cursor.
  static const cursorHide = '\x1b[?25l';

  /// Shows the cursor.
  static const cursorShow = '\x1b[?25h';

  /// Saves the current cursor position (ANSI.SYS).
  static const cursorSave = '\x1b[s';

  /// Restores the previously saved cursor position (ANSI.SYS).
  static const cursorRestore = '\x1b[u';

  /// Saves cursor position (DEC private mode).
  static const cursorSaveDec = '\x1b7';

  /// Restores cursor position (DEC private mode).
  static const cursorRestoreDec = '\x1b8';

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement - Constants
  // ─────────────────────────────────────────────────────────────────────────────

  /// Moves cursor up one line.
  static const cursorUp = '\x1b[A';

  /// Moves cursor down one line.
  static const cursorDown = '\x1b[B';

  /// Moves cursor right one column.
  static const cursorRight = '\x1b[C';

  /// Moves cursor left one column.
  static const cursorLeft = '\x1b[D';

  /// Moves cursor to home position (1, 1).
  static const cursorHome = '\x1b[H';

  /// Moves cursor to beginning of next line.
  static const cursorNextLine = '\x1b[E';

  /// Moves cursor to beginning of previous line.
  static const cursorPrevLine = '\x1b[F';

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement - Functions
  // ─────────────────────────────────────────────────────────────────────────────

  /// Moves cursor up by [n] lines.
  static String cursorUpBy(int n) => '\x1b[${n}A';

  /// Moves cursor down by [n] lines.
  static String cursorDownBy(int n) => '\x1b[${n}B';

  /// Moves cursor right by [n] columns.
  static String cursorRightBy(int n) => '\x1b[${n}C';

  /// Moves cursor left by [n] columns.
  static String cursorLeftBy(int n) => '\x1b[${n}D';

  /// Moves cursor to beginning of line [n] lines down.
  static String cursorNextLineBy(int n) => '\x1b[${n}E';

  /// Moves cursor to beginning of line [n] lines up.
  static String cursorPrevLineBy(int n) => '\x1b[${n}F';

  /// Moves cursor to column [n] (1-based).
  static String cursorToColumn(int n) => '\x1b[${n}G';

  /// Moves cursor to [row] and [col] (1-based).
  static String cursorTo(int row, int col) => '\x1b[$row;${col}H';

  /// Alias for [cursorTo] using 'f' terminator.
  static String cursorPosition(int row, int col) => '\x1b[$row;${col}f';

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Clearing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Clears the entire screen.
  static const clearScreen = '\x1b[2J';

  /// Clears from cursor to end of screen.
  static const clearScreenToEnd = '\x1b[J';

  /// Clears from cursor to end of screen (explicit mode).
  static const clearScreenToEndExplicit = '\x1b[0J';

  /// Clears from cursor to beginning of screen.
  static const clearScreenToStart = '\x1b[1J';

  /// Clears entire screen and scrollback buffer.
  static const clearScreenAndScrollback = '\x1b[3J';

  // ─────────────────────────────────────────────────────────────────────────────
  // Line Clearing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Clears the entire current line.
  static const clearLine = '\x1b[2K';

  /// Clears from cursor to end of line.
  static const clearLineToEnd = '\x1b[K';

  /// Clears from cursor to end of line (explicit mode).
  static const clearLineToEndExplicit = '\x1b[0K';

  /// Clears from cursor to beginning of line.
  static const clearLineToStart = '\x1b[1K';

  // ─────────────────────────────────────────────────────────────────────────────
  // Scrolling
  // ─────────────────────────────────────────────────────────────────────────────

  /// Scrolls screen up by one line.
  static const scrollUp = '\x1b[S';

  /// Scrolls screen down by one line.
  static const scrollDown = '\x1b[T';

  /// Scrolls screen up by [n] lines.
  static String scrollUpBy(int n) => '\x1b[${n}S';

  /// Scrolls screen down by [n] lines.
  static String scrollDownBy(int n) => '\x1b[${n}T';

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enters the alternate screen buffer (fullscreen mode).
  static const altScreenEnter = '\x1b[?1049h';

  /// Exits the alternate screen buffer.
  static const altScreenExit = '\x1b[?1049l';

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables X10 mouse reporting (button press only).
  static const mouseEnableX10 = '\x1b[?9h';

  /// Disables X10 mouse reporting.
  static const mouseDisableX10 = '\x1b[?9l';

  /// Enables normal mouse tracking (button press and release).
  static const mouseEnableNormal = '\x1b[?1000h';

  /// Disables normal mouse tracking.
  static const mouseDisableNormal = '\x1b[?1000l';

  /// Enables button event tracking (press, release, motion with button).
  static const mouseEnableButton = '\x1b[?1002h';

  /// Disables button event tracking.
  static const mouseDisableButton = '\x1b[?1002l';

  /// Enables any-event tracking (all motion events).
  static const mouseEnableAny = '\x1b[?1003h';

  /// Disables any-event tracking.
  static const mouseDisableAny = '\x1b[?1003l';

  /// Enables SGR extended mouse mode (supports coordinates > 223).
  static const mouseEnableSgr = '\x1b[?1006h';

  /// Disables SGR extended mouse mode.
  static const mouseDisableSgr = '\x1b[?1006l';

  /// Enables UTF-8 mouse mode.
  static const mouseEnableUtf8 = '\x1b[?1005h';

  /// Disables UTF-8 mouse mode.
  static const mouseDisableUtf8 = '\x1b[?1005l';

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables bracketed paste mode.
  static const bracketedPasteEnable = '\x1b[?2004h';

  /// Disables bracketed paste mode.
  static const bracketedPasteDisable = '\x1b[?2004l';

  /// Start of bracketed paste content.
  static const bracketedPasteStart = '\x1b[200~';

  /// End of bracketed paste content.
  static const bracketedPasteEnd = '\x1b[201~';

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables focus reporting.
  static const focusEnable = '\x1b[?1004h';

  /// Disables focus reporting.
  static const focusDisable = '\x1b[?1004l';

  /// Focus gained sequence.
  static const focusIn = '\x1b[I';

  /// Focus lost sequence.
  static const focusOut = '\x1b[O';

  // ─────────────────────────────────────────────────────────────────────────────
  // Style/SGR (Select Graphic Rendition)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Resets all attributes to default.
  static const reset = '\x1b[0m';

  /// Enables bold/bright mode.
  static const bold = '\x1b[1m';

  /// Enables dim/faint mode.
  static const dim = '\x1b[2m';

  /// Enables italic mode.
  static const italic = '\x1b[3m';

  /// Enables underline mode.
  static const underline = '\x1b[4m';

  /// Enables slow blink mode.
  static const blink = '\x1b[5m';

  /// Enables rapid blink mode.
  static const rapidBlink = '\x1b[6m';

  /// Enables reverse/inverse mode.
  static const reverse = '\x1b[7m';

  /// Enables hidden/invisible mode.
  static const hidden = '\x1b[8m';

  /// Enables strikethrough mode.
  static const strikethrough = '\x1b[9m';

  /// Disables bold mode.
  static const boldOff = '\x1b[21m';

  /// Disables bold and dim modes.
  static const normalIntensity = '\x1b[22m';

  /// Disables italic mode.
  static const italicOff = '\x1b[23m';

  /// Disables underline mode.
  static const underlineOff = '\x1b[24m';

  /// Disables blink mode.
  static const blinkOff = '\x1b[25m';

  /// Disables reverse mode.
  static const reverseOff = '\x1b[27m';

  /// Disables hidden mode.
  static const hiddenOff = '\x1b[28m';

  /// Disables strikethrough mode.
  static const strikethroughOff = '\x1b[29m';

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the window title. Use with [bel] to terminate.
  ///
  /// Example: `Ansi.setTitle('My App')` produces `\x1b]0;My App\x07`
  static String setTitle(String title) => '\x1b]0;$title\x07';

  /// Sets the terminal progress bar (OSC 9;4).
  ///
  /// [state]: 0=none, 1=default, 2=error, 3=indeterminate, 4=warning
  /// [value]: 0-100
  static String setProgressBar(int state, int value) =>
      '\x1b]9;4;$state;$value\x07';

  /// Resets the terminal progress bar (OSC 9;4).
  static const resetProgressBar = '\x1b]9;4;0;0\x07';

  // ─────────────────────────────────────────────────────────────────────────────
  // Kitty Keyboard Protocol
  // ─────────────────────────────────────────────────────────────────────────────

  /// Requests the current Kitty keyboard protocol flags.
  ///
  /// Terminal responds with `ESC [ ? <flags> u`.
  static const requestKittyKeyboard = '\x1b[?u';

  /// Sets the Kitty keyboard protocol flags.
  ///
  /// [flags] is a bitmask of features to enable.
  /// [mode] is the operation mode: 0 (set), 1 (push), 2 (pop).
  static String kittyKeyboard(int flags, {int mode = 0}) {
    if (mode == 0) {
      return '\x1b[>$flags u';
    }
    return '\x1b[>$flags;$mode u';
  }

  /// Resets the Kitty keyboard protocol flags to 0.
  static const resetKittyKeyboard = '\x1b[>0u';

  /// Kitty keyboard protocol flags.
  static const kittyDisambiguateEscapeCodes = 1;
  static const kittyReportEventTypes = 2;
  static const kittyReportAlternateKeys = 4;
  static const kittyReportAllKeysAsEscapeCodes = 8;
  static const kittyReportAssociatedText = 16;

  /// Rings the terminal bell.
  static const bell = '\x07';

  /// Requests cursor position report. Terminal responds with `\x1b[{row};{col}R`.
  static const requestCursorPosition = '\x1b[6n';

  /// Requests extended cursor position report (DECXCPR).
  ///
  /// Terminals respond with `\x1b[?{row};{col}R`, which is unambiguous vs
  /// `CSI 1 ; <mod> R` (modified F3) when the cursor is on row 1.
  static const requestExtendedCursorPosition = '\x1b[?6n';

  /// Requests device attributes.
  static const requestDeviceAttributes = '\x1b[c';

  // ─────────────────────────────────────────────────────────────────────────────
  // Line Drawing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables line drawing character set.
  static const lineDrawingEnable = '\x1b(0';

  /// Disables line drawing character set (return to ASCII).
  static const lineDrawingDisable = '\x1b(B';

  // ─────────────────────────────────────────────────────────────────────────────
  // Color Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets foreground color using ANSI 16-color palette (0-15).
  static String fg16(int color) {
    if (color < 8) {
      return '\x1b[${30 + color}m';
    } else {
      return '\x1b[${90 + color - 8}m';
    }
  }

  /// Sets background color using ANSI 16-color palette (0-15).
  static String bg16(int color) {
    if (color < 8) {
      return '\x1b[${40 + color}m';
    } else {
      return '\x1b[${100 + color - 8}m';
    }
  }

  /// Sets foreground color using 256-color palette.
  static String fg256(int color) => '\x1b[38;5;${color}m';

  /// Sets background color using 256-color palette.
  static String bg256(int color) => '\x1b[48;5;${color}m';

  /// Sets foreground color using RGB true color.
  static String fgRgb(int r, int g, int b) => '\x1b[38;2;$r;$g;${b}m';

  /// Sets background color using RGB true color.
  static String bgRgb(int r, int g, int b) => '\x1b[48;2;$r;$g;${b}m';

  /// Resets foreground color to default.
  static const fgDefault = '\x1b[39m';

  /// Resets background color to default.
  static const bgDefault = '\x1b[49m';

  // ─────────────────────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────────────────────

  /// Pattern matching all ANSI escape sequences.
  ///
  /// Supports CSI, OSC, DCS, and common control sequences.
  static final ansiPattern = RegExp(
    r'(?:'
    // 7-bit CSI: ESC [ ... <final>
    r'\x1b\[[0-9;:]*[ -/]*[@-~]'
    r'|'
    // 8-bit CSI: CSI ... <final> (0x9B)
    r'\x9b[0-9;:]*[ -/]*[@-~]'
    r'|'
    // 7-bit OSC: ESC ] ... (BEL | ST)
    r'\x1b\].*?(?:\x07|\x1b\\)'
    r'|'
    // 8-bit OSC: OSC ... (BEL | ST) (0x9D ... 0x9C)
    r'\x9d.*?(?:\x07|\x9c)'
    r'|'
    // 7-bit DCS/SOS/PM/APC: ESC (P|X|^|_) ... ST
    r'\x1b(?:P|X|\^|_).*?\x1b\\'
    r'|'
    // 8-bit DCS/SOS/PM/APC: (0x90|0x98|0x9E|0x9F) ... ST (0x9C)
    r'[\x90\x98\x9e\x9f].*?\x9c'
    r'|'
    // Character set selection (ESC ( or ESC ) ...)
    r'\x1b[()][AB012]'
    r'|'
    // DEC cursor save/restore (ESC 7 / ESC 8)
    r'\x1b[78]'
    r')',
    dotAll: true,
  );

  /// Strips all ANSI escape sequences from a string.
  static String stripAnsi(String text) {
    return text.replaceAll(ansiPattern, '');
  }

  /// Calculates the visible width of a string (excluding ANSI sequences).
  static int visibleLength(String text) {
    final stripped = stripAnsi(text);
    return maxLineWidth(stripped);
  }

  /// Wraps text in ANSI sequences that will be stripped by [stripAnsi].
  ///
  /// Useful for applying styles that can be conditionally removed.
  static String wrap(String text, String startSeq, String endSeq) {
    return '$startSeq$text$endSeq';
  }

  /// Cuts a string at given character indices, preserving ANSI state.
  ///
  /// [start] and [end] are indices into the *stripped* version of the string.
  ///
  /// Upstream parity: `x/ansi.Cut`.
  static String cut(String text, int start, int end) {
    if (start < 0) start = 0;
    final stripped = stripAnsi(text);
    final strippedChars = stripped.characters;
    if (start >= strippedChars.length) return '';
    if (end > strippedChars.length) end = strippedChars.length;
    if (start >= end) return '';

    final result = StringBuffer();
    final matches = ansiPattern.allMatches(text).toList();

    var currentVisibleIdx = 0;
    var lastTextIdx = 0;

    // Track active ANSI sequences to prepend them if we start in the middle.
    final activeAnsi = <String>[];

    for (final match in matches) {
      final textBefore = text.substring(lastTextIdx, match.start);
      final charsBefore = textBefore.characters;

      for (final char in charsBefore) {
        if (currentVisibleIdx >= start && currentVisibleIdx < end) {
          if (currentVisibleIdx == start) {
            for (final seq in activeAnsi) {
              result.write(seq);
            }
          }
          result.write(char);
        }
        currentVisibleIdx++;
      }

      final ansiSeq = match.group(0)!;
      if (currentVisibleIdx >= start && currentVisibleIdx < end) {
        result.write(ansiSeq);
      } else if (currentVisibleIdx < start) {
        // Track stateful sequences (SGR, OSC 8, etc.)
        if (ansiSeq.startsWith('\x1b[') || ansiSeq.startsWith('\x1b]')) {
          activeAnsi.add(ansiSeq);
        }
      }

      lastTextIdx = match.end;
    }

    final remainingText = text.substring(lastTextIdx);
    final remainingChars = remainingText.characters;
    for (final char in remainingChars) {
      if (currentVisibleIdx >= start && currentVisibleIdx < end) {
        if (currentVisibleIdx == start) {
          for (final seq in activeAnsi) {
            result.write(seq);
          }
        }
        result.write(char);
      }
      currentVisibleIdx++;
    }

    return result.toString();
  }

  /// Truncates a string from the left by [n] characters, preserving ANSI state.
  ///
  /// Upstream parity: `x/ansi.TruncateLeft`.
  static String truncateLeft(String text, int n, [String replacement = '']) {
    final stripped = stripAnsi(text);
    final strippedChars = stripped.characters;
    if (n <= 0) return text;
    if (n >= strippedChars.length) return replacement;

    return replacement + cut(text, n, strippedChars.length);
  }
}
