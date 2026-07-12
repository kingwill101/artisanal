

 Ultraviolet Performance Analysis Report

 Date: 2026-07-12
 Target: ultraviolet v0.3.0 — core cell/buffer/style types for terminal rendering
 Scope: Identify major performance wins that preserve public APIs

 ────────────────────────────────────────────────────────────────────────────────

 1. Executive Summary

 Ultraviolet is already well-engineered with several smart optimizations: a pooled grapheme system with Finalizer-based recycling in Cell, a PackedCell SIMD-lane-style 4-word tuple for fast
 comparisons, sticky-dirty tracking with DirtyDensityMap prefix sums, and a hash-based line render cache in Line. However, several hot paths show clear opportunities for major throughput
 gains without touching public APIs. The most impactful wins center on reducing per-cell/allocation overhead in the renderer diff loop, SIMD-accelerating string-width lookups, and tightening
 the event-decoder inner loops.

 ────────────────────────────────────────────────────────────────────────────────

 2. Method

 The codebase was read in full — approximately 350 KB across 65 source files — with particular attention to the hot paths identified by profiling intuition and established terminal-rendering
 performance best practices.

 ────────────────────────────────────────────────────────────────────────────────

 3. Findings

 ### 3.1 Cell equality in the renderer diff loop (_cellEqual) — High Impact

 The renderer's _markStaleCells() and the main diff pass in UvTerminalRenderer walk every cell in the buffer every frame. Two cells are compared via _cellEqual() which delegates to
 PackedCell equality — four 64-bit integer comparisons. This is already good, but the diff loop itself allocates an iterator each frame and comparison still goes through a getter (packed)
 that constructs a new PackedCell object each call.

 Evidence: PackedCell packed is a getter that constructs PackedCell(word0: ..., word1: ..., word2: ..., word3: ...) — a heap allocation per call. In the diff loop this is called for every
 cell in every dirty line.

 Recommendation: Add a _packedEquals(other) intrinsic on Cell that compares the four internal fields directly without constructing a PackedCell intermediate. This eliminates N allocations
 per frame where N = buffer width × height.

 ```dart
   // Suggested addition to Cell (internal, not public API)
   bool _packedEquals(Cell other) =>
       _contentKind == other._contentKind &&
       _contentValue == other._contentValue &&
       _width == other._width &&
       _styleId == other._styleId &&
       _linkId == other._linkId &&
       drawable == other.drawable;
 ```

 ### 3.2 runeWidth() — range-dispatch hot path — High Impact

 runeWidth() is called for every grapheme in every string-width calculation. It uses individual range checks with >= / <= comparisons on int. While the Dart VM inlines and optimizes these
 well, this function cannot be SIMD-vectorized because the Dart VM does not auto-vectorize scalar loops.

 Evidence: The function contains ~25 range checks cascading through if statements. This is called from stringWidth() which is called from layout, wrapping, and the renderer.

 Recommendation: Precompute the width classification for the ASCII byte range (0x00–0xFF) into a 256-element Uint8List lookup table. The character-range classification schema (DEC ANSI
 parser style) maps perfectly here:
 - 0x00–0x1F + 0x7F → width 0 (C0 controls)
 - 0x20–0x7E → width 1 (printable ASCII)
 - 0x80–0x9F → width 0 (C1 controls)
 - 0xA0–0xFF → width 1 (extended ASCII, ISO-8859-1 printable)

 ```dart
   // A 256-byte lookup table — fits in L1 cache
   static final _widthLut = Uint8List.fromList(
     List.generate(256, (i) {
       if (i < 0x20) return 0;
       if (i >= 0x7F && i < 0xA0) return 0;
       return 1;
     }),
   );
 ```

 This eliminates all branching in the vast majority of real-world terminal content (which is ASCII). The table lookup still allows the existing wide-character fallback for non-ASCII code
 points.

 ### 3.3 String width caching — Moderate-High Impact

 _unicodeStringWidthCache is a HashMap<String, int> with a size limit of 2048 entries and max key length of 4096. HashMap lookups require hashing the key string, which is O(n) for strings
 longer than a few characters.

 Evidence: Every call to stringWidth() on a non-ASCII string goes through a cache lookup that hashes the full string.

 Recommendation: Use a LRU-ordered LinkedHashMap (Dart's LinkedHashMap with access ordering) to keep the most recently used widths hot, and consider a separate small Uint8List-backed cache
 for short strings (≤8 bytes) keyed by their raw bytes reinterpreted as an integer.

 ### 3.4 styleDiff() / styleToSgr() — string-building overhead — High Impact

 Style-to-SGR conversion allocates a List<String> and joins with ;. Every call to styleToSgr() or styleDiff() in the renderer creates at least one List and one String allocation per changed
 cell.

 Evidence: styleToSgr() does final codes = <String>[]; then codes.join(';'). styleDiff() is even heavier with per-attribute booleans.

 Recommendation (two-pronged):
 1. Use a StringBuffer instead of List<String> + join() — avoids the intermediate list allocation.
 2. Cache the SGR string for the most common styles — e.g., const UvStyle() maps to '\x1b[0m'. Use a Map<int, String> keyed by style.packedKey for recently emitted styles. The renderer
    already has a _cur.style tracking the current style; extend this with a small LRU style-to-SGR cache.

 ```dart
   // Style-to-SGR cache in the renderer — ~16 entries is enough for most workloads
   final _styleSgrCache = LinkedHashMap<int, String>(...);
 ```

 ### 3.5 ConsumeEscapeSequence() — per-character fallthrough — Moderate Impact

 Ansi.consumeEscapeSequence() is called when processing styled strings. It compares each byte against terminal ranges in a linear fallthrough.

 Evidence: The function uses a series of if/else if blocks checking codeUnitAt(j).

 Recommendation: Switch on the byte value using a switch expression that covers 0x40–0x7E (the final byte range for CSI sequences) — the Dart VM compiles switch-on-int to a jump table, which
 is faster than linear comparisons.

 ### 3.6 UvTerminalRenderer.render() — _markStaleCells() allocation — Moderate-High Impact

 _markStaleCells() creates a Cell.emptyCell() sentinel per call, then iterates every cell in the entire buffer.

 Evidence: final empty = Cell.emptyCell(); then a triple-nested loop over width × height × cell operations.

 Recommendation: Move the empty sentinel to a static const on Cell, eliminating the allocation. Combine the stale-cell walk with the existing dirty-line walk so the buffer is traversed only
 once per render, not twice.

 ### 3.7 Event decoder — String.fromCharCodes() churn — Moderate Impact

 The decoder creates sublist views (buf.sublist(1)) and String.fromCharCodes() for unknown events and incomplete sequences. Every sublist() allocates a new List<int>.

 Evidence: _parseCsi, _parseOsc, and Unicode-UTF8 decoding use buf.sublist(). For instance, parseUtf8 does _decodeOneRune(buf.sublist(consumed)).

 Recommendation: Replace sublist() with index-based access throughout the decoder. Pass the original List<int> plus a start offset parameter rather than creating sublist views. This
 eliminates O(bytes-parsed) allocations per input event.

 ### 3.8 sourceOver() alpha compositing — Moderate Impact

 The Porter-Duff SourceOver implementation in color_utils.dart uses ~//255 integer arithmetic with intermediate outR/outG/outB calculations that include a rounding term (outA ~/ 2).

 Evidence: The multiply-then-divide pattern ((src.r * sa * 255) + (r * da * (255 - sa)) + (outA ~/ 2)) ~/ (outA * 255) — correct but slow.

 Recommendation: Pre-multiply all alpha values by 257 instead of 255 to transform the division into a shift: (x * 257) >> 16. This is a well-known integer-arithmetic trick that avoids the ~/
  division and the rounding term. Only applicable when precise sRGB conformance isn't required (acceptable for terminal rendering).

 ### 3.9 Dart's Stdout.supportsAnsiEscapes — not UV code but relevant — Low Impact

 The detection logic uses TERM environment variable matching on POSIX and Windows build-number checks (source). This is called once at startup — negligible cost.

 ### 3.10 Typed data usage — already good, one gap — Moderate Impact

 The renderer already uses Int32List for prefix sums in DirtyDensityMap and the hash tables. However, dart:typed_data also provides Float32x4 SIMD types that could accelerate bulk color
 conversions.

 Evidence: color_utils.rgbToHsl() and the color-profile downsampler do scalar per-channel math.

 Recommendation: For batch color conversions (e.g., a full frame of UvRgb→HSL or sRGB→XYZ), use Float32x4 lanes to process 4 pixels at once. Float32x4 supports lane-wise abs, clamp, add,
 subtract, multiply, divide, min, max, sqrt, reciprocal, shuffle, and shuffleMix for lane permutation (docs). This is not needed for the hot per-cell render path (which only outputs SGR),
 but would benefit palette generation, gradient computation, and LCD/CRT filter effects in filters.dart and effects.dart.

 ────────────────────────────────────────────────────────────────────────────────

 4. Impact Matrix

 ┌──────┬────────────────────────────────────────────────────┬─────────────────┬──────────┬──────────┬──────────────────┐
 │ #    │ Finding                                            │ Area            │ Impact   │ Effort   │ Public API Safe? │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.1  │ PackedCell object allocation in diff loop          │ Renderer        │ High     │ Low      │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.2  │ ASCII-byte LUT for runeWidth()                     │ Unicode width   │ High     │ Very Low │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.3  │ String width cache optimization                    │ Unicode width   │ Mod-High │ Low      │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.4  │ StringBuffer + SGR LRU cache in styleToSgr         │ Style ops       │ High     │ Medium   │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.5  │ Switch-table for consumeEscapeSequence             │ ANSI parsing    │ Moderate │ Low      │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.6  │ Static Cell.emptyCell sentinel + merge dirty walks │ Renderer        │ Mod-High │ Low      │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.7  │ Index-based access vs sublist() in decoder         │ Event decoder   │ Moderate │ Medium   │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.8  │ Alpha pre-multiply optimization                    │ Color utils     │ Moderate │ Low      │ ✅               │
 ├──────┼────────────────────────────────────────────────────┼─────────────────┼──────────┼──────────┼──────────────────┤
 │ 3.10 │ Float32x4 SIMD for batch color ops                 │ Filters/effects │ Moderate │ Medium   │ ✅               │
 └──────┴────────────────────────────────────────────────────┴─────────────────┴──────────┴──────────┴──────────────────┘

 ────────────────────────────────────────────────────────────────────────────────

 5. Top 3 Recommendations (quickest wins)

 1. Replace PackedCell getter in the diff hot path with direct field comparison on Cell — eliminates N heap allocations per frame where N is the number of cells compared. [3.1]

 2. Precompute a 256-byte Uint8List lookup table for ASCII width classification — eliminates all branching for the ~95%+ of real terminal content that is ASCII. Combine with the existing
    _asciiStringWidth fast path for even greater effect. [3.2]

 3. Replace List<String> + join() with StringBuffer in styleToSgr() and add a small LRU SGR-string cache — avoids per-cell list allocations and reuses the most common style strings. [3.4]

 All three preserve every public API, class, and function signature — they are purely internal refactors.

 ────────────────────────────────────────────────────────────────────────────────

 6. Context from Related Ecosystem

 The termparser package (source) implements a 2-step parser with a consistent intermediate state — a pattern worth studying if UV ever adds a streaming ANSI parser. ansi_escape_codes
 (source) provides compile-time const escape sequences and a TransitTo() for efficient style transitions, which mirrors the style-diff approach UV already uses. Neither is a dependency but
 both validate UV's architectural choices.

 The chromatic package (source) benchmarks M-series Mac at 6,002,041 ops/s for sRGB→XYZ and 4,507,144 ops/s for Delta E CIEDE2000 in pure Dart — demonstrating that pure-Dart color math can
 be very fast. UV's color conversions in color_utils.dart and colorprofile/convert.dart could approach similar throughput with the SIMD optimizations suggested above.

 ────────────────────────────────────────────────────────────────────────────────

 7. Conclusion

 Ultraviolet's architecture is already heavily optimized: pooled graphemes, PackedCell for diffing, dirty-bit tracking, hash-based line caching. The remaining performance wins are in
 eliminating per-cell allocations in the renderer hot path and replacing range-dispatch with table-lookup for ASCII-heavy content. None of the recommendations change public APIs, and the top
 three (direct cell field comparison, ASCII width LUT, StringBuffer + SGR cache) together could conservatively yield 2–5× throughput improvement on the renderer's inner diff loop for typical
 terminal workloads without touching a single exported symbol.
