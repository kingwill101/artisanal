# Inline Renderer Blank Space Bug — Root Cause Analysis

## Summary

The blank space in the log area after a viewport resize is caused by **the UV renderer's `erase()` call emitting an `ED2` (`ESC[2J`) sequence that is captured into `_inlineCapture` and then written to the terminal _after_ the log history has already been replayed** — erasing everything it just wrote.

> [!IMPORTANT]
> The trace file `pinned-build-dashboard-2026-06-30T13-44-29.564077.log` (13:44:29) was captured **before** the fix was applied (renderer.dart modified at 13:47:43). Both Option A and Option B are now applied. A new trace must be generated to confirm the fix works.

---

## Trace Evidence

Trace file: `pinned-build-dashboard-2026-06-30T13-44-29.564077.log` (**pre-fix**)

- **First real resize** at event #3649: `window.size` 110→113 wide (height stays 49)
- `inline.terminal_size_changed` follows at event #3653
- First post-resize flush at event #3654:
  - `uiHeight=6`, `uiStartRow=44`, `logBottom=43`
  - `clearInlineRegion=True`, `replayLogBand=True`
- ANSI bytes at event #3655 (decoded):

```
Phase 1 — _appendInlineLogReplay(out, 43):
  CUP(1,1)+EL2 … CUP(43,1)+EL2      ← clears rows 1-43
  CUP(1,1)+TEXT[0090]… CUP(43,1)+TEXT[0132]  ← writes 43 log lines ✓

Phase 2 — clearInlineRegion:
  CUP(44,1)+EL2 … CUP(49,1)+EL2    ← clears UI rows 44-49 ✓

Phase 3 — shifted UV output (from r.flush()):
  CUP(44,1)
  ESC[2J   ← ED2: ERASE ENTIRE SCREEN (rows 1-49 all wiped!) 💥
  [box drawing characters for the dashboard UI at rows 44-49]
```

The ED2 at `CUP(44)` **erases the entire terminal screen**, not just the UI region. Since the terminal emulator interprets `ESC[2J` as "erase all", the log history written in Phase 1 is immediately destroyed, leaving rows 1-43 blank.

---

## Code Path

```
render()
  → _flushInternal()
      → _ensureSize()            # detects resize
          → scr.resize(w, h)
          → _renderer?.resize(w, h)
          → _renderer?.erase()   # <-- UV renderer resets its diff state
                                 #     emits ESC[H ESC[2J into _inlineCapture
          → _inlineNeedsFullClear = true
          → _inlineNeedsLogReplay = true
      → r.render(scr.buffer)
      → _flushInline()
          → _appendInlineLogReplay(out, logBottom)   # writes log to rows 1-43
          → clearInlineRegion loop                    # clears rows 44-49
          → out.write(shifted)                        # <- ED2 is IN HERE
```

The `_renderer?.erase()` call in `_ensureSize()` writes into `_inlineCapture` because the UV renderer's sink is `_CapturingSink`. The erase output is accumulated in the capture buffer. When `r.flush()` is subsequently called inside `_flushInline()`, it calls `r.flush()` again — but the **erase output from `erase()` is already queued inside the UV renderer's internal writer** and gets emitted on the next `flush()`. This includes an `ESC[2J`.

> [!IMPORTANT]
> The `erase()` output goes through `_inlineCapture`. After `_offsetInlineRows()` shifts all `CUP` coordinates, the `ED2` sequence is **not a CUP**, so it passes through unmodified and lands in the final terminal write still as `ESC[2J`.

---

## Why Only on Resize?

On a normal (non-resize) frame:
- `_ensureSize()` returns early (no size change) — no `erase()` call
- `_inlineNeedsLogReplay = false` — no log replay step
- The UV diff output is incremental and never contains `ESC[2J`

On resize:
- `_ensureSize()` calls `_renderer?.erase()` to reset the UV diff engine
- `_inlineNeedsLogReplay = true` is set
- `_flushInline()` correctly replays log history first — but then the queued `erase()` output containing `ESC[2J` destroys it all

---

## Fix Options

### Option A — Drain `_inlineCapture` before `_flushInline()` (simplest, surgical)

After `_renderer?.erase()` in `_ensureSize()`, immediately clear `_inlineCapture` so the erase output doesn't accumulate for the next `flush()`:

```dart
// In _ensureSize(), inline branch:
_renderer?.erase();
_inlineCapture.clear();   // ← add this line
_inlineNeedsFullClear = true;
_inlineNeedsLogReplay = _options.uiAnchor == UiAnchor.bottom;
```

> [!NOTE]
> `_renderer?.erase()` is needed to reset the UV renderer's internal cell-diff state (so it forces a full redraw of all cells next frame). But for inline mode we don't _want_ the erase sequence in the terminal output — we handle clearing the UI region ourselves via `clearInlineRegion` and the log replay. Clearing `_inlineCapture` discards the unwanted `ESC[2J` while leaving the diff state reset intact.

### Option B — Strip `ED` sequences from shifted output in `_flushInline()`

In `_flushInline()`, after computing `shifted`, strip any `ESC[\d*J` sequences that could erase outside the UI region:

```dart
// Strip erase-display sequences (ED0/ED1/ED2/ED3) from UV output
// because they can erase the log band which we manage separately.
final safeShifted = shifted.replaceAll(RegExp(r'\x1b\[\d*J'), '');
out.write(safeShifted);
```

This is safer but broader — it removes all ED sequences, which the UV renderer shouldn't be emitting in normal incremental diffs anyway.

### Option C — Use a two-sink approach (cleanest)

Split `_ensureSize()` so the erase() call uses a throwaway sink, not `_inlineCapture`. This is architecturally cleanest but requires more refactoring.

---

## Applied Fix: Both Option A + Option B

### Option B — Strip ED in `_flushInline()` (applied at 13:47)

In `_flushInline()`, after `r.flush()` writes UV output into `_inlineCapture`, strip any `ESC[\d*J` (ED) sequence before shifting and writing to the terminal:

```dart
// In _flushInline():
if (raw.contains('\x1b[')) {
  raw = raw.replaceAll(RegExp(r'\x1b\[\d*J'), '');
}
```

This is a **last-resort safety net** — if any ED leaks through from the UV renderer, it is stripped before it can reach the terminal.

### Option A — Drain `_inlineCapture` after `erase()` (applied 13:55)

Added `_inlineCapture.clear()` immediately after every `_renderer?.erase()` in inline mode at all three call sites:

| Method | Line | Status |
|---|---|---|
| `_ensureSize()` | 976-982 | ✅ Fixed |
| `clear()` | 1040-1041 | ✅ Fixed |
| `invalidate()` | 1052-1053 | ✅ Fixed |

```dart
// _ensureSize() — on resize:
_renderer?.erase();
_inlineCapture.clear(); // ← discard ESC[H ESC[2J
_inlineNeedsFullClear = true;
_inlineNeedsLogReplay = _options.uiAnchor == UiAnchor.bottom;
```

This prevents the erase output from **accumulating** in the capture buffer between the `erase()` call and the next `_flushInline()` → `r.flush()` invocation.

---

## Why Option A Alone May Not Be Sufficient

The UV renderer has two separate things:
1. **The capture buffer** (`_inlineCapture`) — cleared by `_inlineCapture.clear()`
2. **The UV renderer's internal writer queue** — flushed by `r.flush()`

When `_renderer?.erase()` is called, it writes the erase sequences **into the UV renderer's internal writer** (which is backed by `_inlineCapture`). So clearing `_inlineCapture` immediately after `erase()` should drain both, since the UV renderer writes synchronously. Option B is kept as a defense-in-depth measure.

---

## Verification

1. Run: `dart run pinned_build_dashboard.dart --trace --trace-capture --tick-ms 100 --seed 1`
2. Resize the terminal window
3. In the post-resize `inline.ansi.flush` event:
   - `rawLength` should be ~0 if no UV diff was needed, or contain only diff content
   - **No `ESC[2J]` (`\\x1b\\[\\d*J`) anywhere in the base64 payload**
   - Log history visible at rows 1–43 ✓
   - UI box at rows 44–49 ✓
