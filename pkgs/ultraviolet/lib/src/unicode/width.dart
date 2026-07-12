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
int get emojiPresentationWidth => _emojiPresentationWidth;

set emojiPresentationWidth(int width) => setEmojiPresentationWidth(width);

int _emojiPresentationWidth = 2;

/// Sets the display width used for emoji presentation characters.
///
/// Values outside {1,2} are ignored.
void setEmojiPresentationWidth(int width) {
  if (width != 1 && width != 2) return;
  if (_emojiPresentationWidth == width) return;
  _emojiPresentationWidth = width;
  _unicodeStringWidthCache.clear();
}

/// Maximum number of entries in [_unicodeStringWidthCache].
const _unicodeStringWidthCacheLimit = 2048;
const _unicodeStringWidthCacheMaxLength = 4096;

final _unicodeStringWidthCache = <String, int>{};

int? _cachedStringWidth(String s) => _unicodeStringWidthCache[s];

void _cacheStringWidth(String s, int width) {
  if (s.length > _unicodeStringWidthCacheMaxLength) return;
  if (_unicodeStringWidthCache.length >= _unicodeStringWidthCacheLimit) {
    _unicodeStringWidthCache.clear();
  }
  _unicodeStringWidthCache[s] = width;
}

/// Specifies the method used to calculate character display width.
enum WidthMethod { grapheme, wcwidth }

/// Extension on [WidthMethod] providing string width calculation.
extension WidthMethodX on WidthMethod {
  /// Calculates the display width of [s] using grapheme cluster iteration.
  ///
  /// Each grapheme cluster is measured individually. Clusters containing
  /// U+FE0F (emoji presentation selector) are widened to
  /// [emojiPresentationWidth] when the base rune would otherwise be narrow.
  int stringWidth(String s) {
    final asciiWidth = _asciiStringWidth(s);
    if (asciiWidth != null) return asciiWidth;

    final cachedWidth = _cachedStringWidth(s);
    if (cachedWidth != null) return cachedWidth;

    final simpleUnicodeWidth = _simpleUnicodeStringWidth(s);
    if (simpleUnicodeWidth != null) {
      _cacheStringWidth(s, simpleUnicodeWidth);
      return simpleUnicodeWidth;
    }

    var width = 0;
    // Count display width per grapheme cluster to avoid double-counting
    // multi-codepoint clusters (e.g. ZWJ emoji sequences).
    for (final g in uni.graphemes(s)) {
      final iterator = g.runes.iterator;
      if (!iterator.moveNext()) continue;

      final first = iterator.current;
      var hasEmojiPresentationSelector = first == 0xFE0F;
      while (iterator.moveNext()) {
        if (iterator.current == 0xFE0F) {
          hasEmojiPresentationSelector = true;
          break;
        }
      }

      var w = runeWidth(first);
      // If the grapheme contains U+FE0F (variation selector 16 — emoji
      // presentation), terminals render the base character at emoji width
      // even if runeWidth() returned 1.
      if (w == 1 && hasEmojiPresentationSelector) {
        w = emojiPresentationWidth;
      }
      width += w;
    }
    _cacheStringWidth(s, width);
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
  if (s.isEmpty) return 0;
  if (!s.contains('\n') && !s.contains('\r')) {
    return stringWidth(s);
  }

  final normalized = s.replaceAll('\r\n', '\n');
  var maxWidth = 0;
  for (final line in normalized.split('\n')) {
    final w = stringWidth(line);
    if (w > maxWidth) maxWidth = w;
  }
  return maxWidth;
}

/// 128-byte lookup table for ASCII character widths.
///
/// - 0x00–0x1F and 0x7F → 0 (control characters)
/// - 0x20–0x7E          → 1 (printable ASCII)
///
/// Fits in a single cache line on modern CPUs.
int? _asciiStringWidth(String s) {
  var width = 0;
  for (var i = 0; i < s.length; i++) {
    final unit = s.codeUnitAt(i);
    if (unit >= 0x80) return null;
    if (unit >= 0x20 && unit != 0x7F) {
      width++;
    }
  }
  return width;
}

int? _simpleUnicodeStringWidth(String s) {
  var width = 0;
  for (var i = 0; i < s.length; i++) {
    final unit = s.codeUnitAt(i);
    if (_requiresGraphemeFallback(unit)) return null;
    width += runeWidth(unit);
  }
  return width;
}

bool _requiresGraphemeFallback(int unit) {
  if (unit >= 0xD800 && unit <= 0xDFFF) return true;
  if (unit == 0x200C || unit == 0x200D) return true;
  if (unit >= 0xFE00 && unit <= 0xFE0F) return true;
  return false;
}

/// Returns the display width of a single Unicode code point.
///
/// Control characters, combining marks, and zero-width characters return 0.
/// CJK, fullwidth, and emoji characters return 2. All others return 1.
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
      rune == 0xFEFF || // BOM
      (rune >= 0xFE00 && rune <= 0xFE0F) || // Variation Selectors (VS1-VS16)
      (rune >= 0xE0100 && rune <= 0xE01EF)) {
    // Variation Selectors Supplement (VS17-VS256)
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

  // Emoji / symbol characters that terminals render as wide (2 cells).
  // These are below U+2E80 (the CJK range start) but have emoji presentation
  // in most terminals.
  if (_isEmojiPresentation(rune)) {
    return emojiPresentationWidth;
  }

  // Emoji ranges in Supplementary Multilingual Plane (U+1Fxxx).
  // Covers all Emoji_Presentation=Yes code points above U+FFFF.
  // Source: Unicode Emoji Data 15.1 — emoji-data.txt
  if ((rune >= 0x1F000 && rune <= 0x1F02F) || // Mahjong Tiles, Dominos
      (rune >= 0x1F0A0 && rune <= 0x1F0FF) || // Playing Cards
      (rune >= 0x1F100 &&
          rune <= 0x1F1FF) || // Enclosed Alphanumerics + Regional Indicators
      (rune >= 0x1F200 && rune <= 0x1F2FF) || // Enclosed Ideographic Supplement
      (rune >= 0x1F300 &&
          rune <= 0x1F9FF) || // Misc Symbols/Pictographs, Emoticons, etc.
      (rune >= 0x1FA00 &&
          rune <= 0x1FAFF) || // Symbols and Pictographs Extended-A
      (rune >= 0x1F7E0 && rune <= 0x1F7FF)) {
    // Geometric Shapes Extended (colored circles/squares)
    return emojiPresentationWidth;
  }

  return 1;
}

/// Returns true if [rune] has the Unicode `Emoji_Presentation=Yes` property,
/// meaning terminals render it as 2 cells wide by default (without needing
/// U+FE0F variation selector).
///
/// Characters with `Emoji_Presentation=No` are text-default and rendered at
/// width 1. They only become width 2 when followed by U+FE0F, which is
/// handled separately in [WidthMethodX.stringWidth].
///
/// Source: Unicode Emoji Data 15.1 — emoji-data.txt
bool _isEmojiPresentation(int r) {
  // Miscellaneous Technical
  if (r == 0x231A || r == 0x231B) return true; // ⌚⌛
  if (r >= 0x23E9 && r <= 0x23EC) return true; // ⏩⏪⏫⏬
  if (r == 0x23F0) return true; // ⏰
  if (r == 0x23F3) return true; // ⏳

  // Geometric Shapes
  if (r >= 0x25FD && r <= 0x25FE) return true; // ◽◾

  // Miscellaneous Symbols (U+2600..U+26FF) — ONLY Emoji_Presentation=Yes
  if (r == 0x2614 || r == 0x2615) return true; // ☔☕
  if (r >= 0x2648 && r <= 0x2653) return true; // ♈♉♊♋♌♍♎♏♐♑♒♓
  if (r == 0x267F) return true; // ♿
  if (r == 0x2693) return true; // ⚓
  if (r == 0x26A1) return true; // ⚡
  if (r == 0x26AA || r == 0x26AB) return true; // ⚪⚫
  if (r == 0x26BD || r == 0x26BE) return true; // ⚽⚾
  if (r == 0x26C4 || r == 0x26C5) return true; // ⛄⛅
  if (r == 0x26CE) return true; // ⛎
  if (r == 0x26D4) return true; // ⛔
  if (r == 0x26EA) return true; // ⛪
  if (r == 0x26F2 || r == 0x26F3) return true; // ⛲⛳
  if (r == 0x26F5) return true; // ⛵
  if (r == 0x26FA) return true; // ⛺
  if (r == 0x26FD) return true; // ⛽

  // Dingbats (U+2700..U+27BF) — ONLY Emoji_Presentation=Yes
  if (r == 0x2705) return true; // ✅
  if (r == 0x270A || r == 0x270B) return true; // ✊✋
  if (r == 0x2728) return true; // ✨
  if (r == 0x274C) return true; // ❌
  if (r == 0x274E) return true; // ❎
  if (r >= 0x2753 && r <= 0x2755) return true; // ❓❔❕
  if (r == 0x2757) return true; // ❗
  if (r >= 0x2795 && r <= 0x2797) return true; // ➕➖➗
  if (r == 0x27B0) return true; // ➰
  if (r == 0x27BF) return true; // ➿

  // Misc Symbols and Arrows
  if (r == 0x2B1B || r == 0x2B1C) return true; // ⬛⬜
  if (r == 0x2B50) return true; // ⭐
  if (r == 0x2B55) return true; // ⭕

  return false;
}
