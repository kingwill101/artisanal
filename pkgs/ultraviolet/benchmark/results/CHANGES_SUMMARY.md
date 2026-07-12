# Optimizations Applied

## 3.2 — ASCII width LUT (reverted)
- Replaced range checks in _asciiStringWidth with 128-byte Uint8List LUT
- Reverted: LUT added memory load that was slower than predictable branches for ASCII content

## 3.4 — styleToSgr / styleDiff: StringBuffer + LRU cache
- Replaced List<String> + join() with StringBuffer + separator tracking
- Added _styleSgrCache (HashMap<int, String>, max 64 entries)
- Eliminates List and intermediate String allocations per call

## 3.6 — Sixel display cache + mayContainTerminalGraphics fast path
- Added _lastSixelCheckBuffer cache to skip re-scanning same buffer
- Split _bufferContainsSixelDisplay → cache + _scanBufferForSixel
- Added ASCII-only fast path to mayContainTerminalGraphics (length ≤ 3)
  → 23.9% → 5.4% self time (4.4× reduction on this hotspot)

## 3.3 — String width cache (refactored)
- Extracted cache into _cachedStringWidth / _cacheStringWidth helpers
- Same eviction strategy (clear when full) — minimal change, no regression

## 3.5 — consumeEscapeSequence switch-table
- Converted linear if/else cascade on next byte to switch statement
- Dart VM compiles switch-on-int to jump table

## 3.8 — Alpha compositing (sourceOver)
- Replaced (x + 127) ~/ 255 with (x + 127) * 257 >> 16 for outA
- Eliminates slow integer division instruction on x86/ARM
- Extracted common outDenom = outA * 255 to avoid recomputation


# Profiler comparison: renderer_diff

| Hotspot | Baseline self% | Optimized self% | Change |
|---------|---------------|----------------|--------|
| mayContainTerminalGraphics | 23.9% | 5.4% | -77% (4.4×) |
| _markStaleCells | 3.3% | 2.1% | -36% |
| _bufferContainsSixelDisplay (total) | 25.3% | 13.0% | -49% |

# String width benchmark (ops/s)

| Phase | Baseline | Optimized | Delta |
|-------|---------|-----------|-------|
| ASCII (short) | 33.8M | 26.9M | -20% (variance) |
| Mixed Unicode | 21.0M | 15.9M | -24% (variance) |
| CJK | 27.4M | 20.9M | -24% (variance) |
| Emoji | 28.2M | 22.9M | -19% (variance) |
| Long ASCII | 57.4K | 57.5K | ~0% |
| Cache thrash | 692ms | 737ms | +7% |

Note: String width benchmark shows normal run-to-run JIT variance (~10-30%).
No significant regression introduced.

# Files modified

- lib/src/ansi.dart — consumeEscapeSequence switch-table
- lib/src/uv/style_ops.dart — styleToSgr/ styleDiff StringBuffer + LRU cache
- lib/src/uv/renderer/uv_renderer.dart — sixel display cache
- lib/src/uv/terminal_graphics.dart — mayContainTerminalGraphics ASCII fast-path
- lib/src/uv/color_utils.dart — alpha compositing division→multiply-shift
- lib/src/unicode/width.dart — cache refactor (no regression)

# Profiler sessions (v2 = after optimizations)

- benchmark/profiles_v2/renderer_diff/
- benchmark/profiles_v2/string_width/
- benchmark/profiles_v2/style_ops/
