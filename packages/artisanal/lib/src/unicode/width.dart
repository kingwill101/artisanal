/// Upstream: `third_party/ultraviolet/styled.go` uses `ansi.GraphemeWidth` and
/// `ansi.WcWidth`. For now, this is a minimal wcwidth-like approximation.
///
/// Note: This is intentionally minimal-first. The Ultraviolet parity tests we
/// port initially mostly cover ASCII + common wide (CJK/emoji) characters.
library;
import 'grapheme.dart' as uni;

/// Runtime configuration for width calculations that depend on terminal
/// behavior.
///
/// Some terminals render emoji as 1 cell wide, others as 2. Our cell-buffer
/// renderer needs to match the terminal’s behavior to avoid overwriting
/// graphemes during incremental updates.
///
/// Default is 2 (Unicode wide emoji behavior).
int emojiPresentationWidth = 2;

/// Sets the display width used for emoji presentation characters.
///
/// Values outside {1,2} are ignored.
void setEmojiPresentationWidth(int width) {
  if (width != 1 && width != 2) return;
  emojiPresentationWidth = width;
}

enum WidthMethod { grapheme, wcwidth }

extension WidthMethodX on WidthMethod {
  int stringWidth(String s) {
    var width = 0;
    // Count display width per grapheme cluster to avoid double-counting
    // multi-codepoint clusters (e.g. ZWJ emoji sequences).
    for (final g in uni.graphemes(s)) {
      width += runeWidth(uni.firstCodePoint(g));
    }
    return width;
  }
}

/// Returns the terminal display width of [s], counting per grapheme cluster.
///
/// This is a convenience wrapper around [WidthMethodX.stringWidth] using the
/// default grapheme-based method.
int stringWidth(String s) => WidthMethod.grapheme.stringWidth(s);

/// Returns the maximum display width across all lines in [s].
///
/// The input is treated as newline-separated rows; width resets after each
/// newline. This matches how layout code interprets terminal cell widths.
int maxLineWidth(String s) {
  final normalized = s.replaceAll('\r\n', '\n');
  var maxWidth = 0;
  for (final line in normalized.split('\n')) {
    final w = stringWidth(line);
    if (w > maxWidth) maxWidth = w;
  }
  return maxWidth;
}

int runeWidth(int rune) {
  // Control characters and null
  if (rune < 32 || (rune >= 0x7F && rune < 0xA0)) {
    return 0;
  }

  // Combining characters (zero width)
  if ((rune >= 0x0300 && rune <= 0x036F) || // Combining Diacritical Marks
      (rune >= 0x1AB0 &&
          rune <= 0x1AFF) || // Combining Diacritical Marks Extended
      (rune >= 0x1DC0 &&
          rune <= 0x1DFF) || // Combining Diacritical Marks Supplement
      (rune >= 0x20D0 &&
          rune <= 0x20FF) || // Combining Diacritical Marks for Symbols
      (rune >= 0xFE20 && rune <= 0xFE2F)) {
    // Combining Half Marks
    return 0;
  }

  // Zero-width (very small subset).
  if (rune == 0x200B || // ZWSP
      rune == 0x200C || // ZWNJ
      rune == 0x200D || // ZWJ
      rune == 0xFEFF) {
    // BOM
    return 0;
  }

  // Wide characters (CJK + emoji range subset).
  if ((rune >= 0x1100 && rune <= 0x115F) || // Hangul Jamo
      (rune >= 0x2E80 && rune <= 0x9FFF) || // CJK
      (rune >= 0xAC00 && rune <= 0xD7A3) || // Hangul Syllables
      (rune >= 0xF900 && rune <= 0xFAFF) || // CJK Compatibility
      (rune >= 0xFE10 && rune <= 0xFE1F) || // Vertical Forms
      (rune >= 0xFE30 && rune <= 0xFE6F) || // CJK Compatibility Forms
      (rune >= 0xFF00 && rune <= 0xFF60) || // Fullwidth ASCII
      (rune >= 0xFFE0 && rune <= 0xFFE6) || // Fullwidth symbols
      (rune >= 0x20000 && rune <= 0x3FFFF)) {
    return 2;
  }

  // Emoji range subset. Terminal behavior varies (1 or 2).
  if (rune >= 0x1F300 && rune <= 0x1F9FF) {
    return emojiPresentationWidth;
  }

  return 1;
}
