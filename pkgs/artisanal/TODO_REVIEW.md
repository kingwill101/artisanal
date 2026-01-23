# Artisanal Package Review - Issues & Fixes

This document tracks issues identified during the comprehensive code review.
Check off items as they are fixed and tested.

---

## Critical - Fix Now

### Input/Key Handling

- [x] **key_table.dart LF inconsistency** (Fixed 2025-01-19)
  - **File:** `lib/src/uv/key_table.dart:73`
  - **Issue:** LF (0x0A) mapped to Ctrl+J in key table but Enter in decoder
  - **Impact:** Same class of bug as the Enter-read-as-j issue
  - **Fix:** Added `lfKey` variable that respects `_flagCtrlJ` (bit 0x100), similar to `enterKey`
  - **Test:** `test/tui/uv/key_table_test.dart` - comprehensive tests for C0 codes and decoder/table consistency

### Rendering

- [x] **cloneArea wide-cell corruption** (Verified 2025-01-19 - NOT A BUG)
  - **File:** `lib/src/uv/buffer.dart:317`
  - **Issue:** Originally thought skipping `isZero` cells corrupts wide characters
  - **Investigation:** The implementation is actually correct:
    - Placeholders are skipped intentionally (they're auto-created when origin cell is copied via `setCell`)
    - Wide chars at boundaries that overflow are converted to spaces (correct behavior)
    - Placeholders without their origin become spaces (correct behavior)
  - **Test:** `test/tui/uv/buffer_parity_test.dart` - comprehensive tests added for wide char cloning

### Program Lifecycle

- [x] **Race condition in send()** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/program.dart`
  - **Issue:** `_running` check and `_processMessage` not atomic, reentrant calls possible
  - **Impact:** Messages can be processed after shutdown begins, state corruption
  - **Fix:** Added `_messageQueue` and `_processingMessage` flag for sequential processing
  - **Test:** Reentrant send() doesn't corrupt state

- [x] **Type cast without validation** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/program.dart`
  - **Issue:** `_model = newModel as M` crashes with unclear error if wrong type
  - **Impact:** Confusing runtime error if model.update returns wrong type
  - **Fix:** Added type check with descriptive error message
  - **Test:** Model that returns wrong type should give clear error

---

## High - Should Fix Soon

### Input/Key Handling

- [x] **Meta/Hyper/Super modifiers dropped** (Fixed 2025-01-19)
  - **File:** `lib/src/uv/tui_adapter.dart:154-157`, `lib/src/terminal/keys.dart`
  - **Issue:** UV keys with Meta/Hyper/Super modifiers silently lose those modifiers
  - **Impact:** Applications cannot detect Meta/Hyper/Super key combinations
  - **Fix:** Added `meta`, `hyper`, `superKey` fields to TUI Key class and updated adapter to preserve them
  - **Test:** `test/tui/uv/tui_adapter_test.dart` - tests for extended modifier preservation

- [x] **0x08 (Backspace/Ctrl+H) inconsistency** (Fixed 2025-01-19)
  - **File:** `lib/src/uv/tui_adapter.dart`
  - **Issue:** TUI parser returns `KeyType.backspace` for 0x08, UV decoder returns Ctrl+H (0x68 with ctrl mod)
  - **Impact:** Inconsistent behavior between parsers - apps using UV input would see Ctrl+H instead of Backspace
  - **Fix:** Added detection for Ctrl+H (code=0x68, ctrl=true) in adapter and map to `KeyType.backspace`
  - **Test:** `test/tui/uv/tui_adapter_test.dart` - test for 0x08 mapping to Backspace

### Program Lifecycle

- [x] **StreamCmd/EveryCmd continue after quit** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/program.dart`
  - **Issue:** Commands can still send messages after `_quit()` but before `_cleanup()`
  - **Impact:** Orphaned tasks, potential crashes
  - **Fix:** Set `_running = false` in `_quit()` and `kill()` immediately to stop accepting new messages
  - **Test:** Existing tests pass; messages sent after quit are now ignored

- [x] **Reentrant _processMessage** (Fixed 2025-01-19 with Race condition fix)
  - **File:** `lib/src/tui/program.dart`
  - **Issue:** No protection against message handlers calling `send()` synchronously
  - **Impact:** Model state corruption, out-of-order updates
  - **Fix:** Added message queue, process sequentially via `_drainMessageQueue()`
  - **Test:** Message handler that synchronously sends another message

- [x] **init() called after first render** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/program.dart:858-889`
  - **Issue:** Model's init() command ran after initial render
  - **Impact:** Visual flash showing pre-init state
  - **Fix:** Added `_initializing` flag to suppress renders during initialization,
    moved init() execution before first render, render once after init completes
  - **Test:** All existing program tests pass

### Rendering

- [x] **wrapAnsiPreserving truecolor bug** (Fixed 2025-01-19)
  - **File:** `lib/src/uv/wrap.dart`
  - **Issue:** Didn't preserve `38;2;r;g;b` (truecolor) and `38;5;n` (256-color) sequences
  - **Impact:** Colors lost when wrapping styled text
  - **Fix:** Rewrote `_applySgr` to properly consume extended color parameters (38/48;5;n and 38/48;2;r;g;b).
    Added `_parseExtendedColor` helper function.
  - **Test:** `test/tui/uv/wrap_behavior_test.dart` - comprehensive tests for 256-color and truecolor preservation

---

## Medium - Plan to Fix

### Rendering

- [x] **Frame timing drift** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/renderer.dart`
  - **Issue:** Uses `DateTime.now()` instead of `Stopwatch`
  - **Impact:** Frame timing can drift with NTP sync, DST changes
  - **Fix:** Changed all renderers to use `Stopwatch` for elapsed time measurement
  - **Test:** All existing tests pass

- [x] **Missing Unicode width ranges** (Fixed 2025-01-19)
  - **File:** `lib/src/unicode/width.dart:91-101`
  - **Issue:** CJK Extension B+, Regional Indicators, Variation Selectors incomplete
  - **Impact:** Some wide characters measured as single-width
  - **Fix:** Added Variation Selectors (VS1-VS256) as zero-width, added Regional Indicators and expanded emoji ranges
  - **Test:** `test/unicode/width_edge_cases_test.dart` - comprehensive tests for emoji, ZWJ sequences, regional indicators

### Program Lifecycle

- [x] **BatchMsg can stack overflow** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/program.dart`
  - **Issue:** Nested BatchMsg causes deep recursion
  - **Impact:** Stack overflow on deeply nested batches
  - **Fix:** Changed `_processMessage` to use iterative queue-based processing for BatchMsg
  - **Test:** `test/tui/program_test.dart` - "deeply nested BatchMsg does not cause stack overflow"

- [x] **Double cleanup possible** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/program.dart`
  - **Issue:** No guard against `_cleanup()` being called multiple times
  - **Impact:** Potential errors on double cleanup
  - **Fix:** Added `_cleanedUp` guard flag, reset in `run()`
  - **Test:** `test/tui/program_test.dart` - "double cleanup does not cause errors"

- [x] **Silent cleanup failures** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/program.dart`
  - **Issue:** All cleanup exceptions swallowed silently
  - **Impact:** Hard to debug cleanup issues
  - **Fix:** Collect errors in `cleanupErrors` list, accessible via `program.cleanupErrors`
  - **Test:** `test/tui/program_test.dart` - "cleanup errors are collected"

### Input/Key Handling

- [x] **KeyType missing extended keys** (Fixed 2025-01-19)
  - **File:** `lib/src/terminal/keys.dart:29-380`
  - **Issue:** F21-F63, media keys, lock keys not in KeyType enum
  - **Impact:** Extended keys became `KeyType.unknown` in TUI mode
  - **Fix:** Added all extended keys to KeyType enum:
    - F21-F63 (43 function keys)
    - Lock keys: capsLock, scrollLock, numLock, printScreen, pause, menu
    - Media keys: mediaPlay, mediaPause, mediaPlayPause, mediaReverse, mediaStop,
      mediaFastForward, mediaRewind, mediaNext, mediaPrev, mediaRecord
    - Volume keys: volumeDown, volumeUp, mute
    - Modifier keys: leftShift, leftAlt, leftCtrl, leftSuper, leftHyper, leftMeta,
      rightShift, rightAlt, rightCtrl, rightSuper, rightHyper, rightMeta,
      isoLevel3Shift, isoLevel5Shift
  - Updated `tui_adapter.dart` to map all extended keys from UV to TUI
  - **Test:** `test/tui/uv/tui_adapter_test.dart` - comprehensive tests for all key types

- [x] **key_table C0 entries potentially dead code** (Documented 2025-01-19)
  - **File:** `lib/src/uv/key_table.dart:66-99`
  - **Issue:** C0 entries never consulted since decoder handles them first
  - **Impact:** Maintenance burden, confusion
  - **Fix:** Added documentation comment explaining entries are for consistency/documentation.
    The decoder handles all C0 bytes directly in `parseControl()` and always returns
    KeyPressEvent. The table is only consulted for UnknownEvents, so these entries
    serve as documentation and fallback consistency.
  - **Test:** N/A (documentation only)

---

## Low - Nice to Have

### Commands

- [x] **EveryCmd.isActive wrong during delay** (Fixed 2025-01-19)
  - **File:** `lib/src/tui/cmd.dart:859-860`
  - **Issue:** Returns false during initial delay when actually active
  - **Impact:** Incorrect state reporting
  - **Fix:** Check `_starter?.isActive` as well: `(_starter?.isActive ?? false) || (_timer?.isActive ?? false)`
  - **Test:** `test/tui/cmd_test.dart` - "isActive is true during initial delay period"

### Performance

- [x] **Unnecessary Cell cloning** (Analyzed 2025-01-19 - NOT A BUG)
  - **File:** `lib/src/uv/buffer.dart:118`
  - **Issue:** Every `set()` clones cell even when not needed
  - **Analysis:** The clone is necessary because `Cell` is mutable (fields are not `final`).
    Without cloning, external code could mutate a Cell after passing it to `set()`,
    corrupting the buffer state. This is correct defensive programming.
  - **Future optimization:** Make `Cell` immutable with `copyWith` patterns,
    but this would be a breaking API change requiring careful migration.

### Code Quality

- [x] **Magic numbers in Win32/SS3** (Analyzed 2025-01-19 - WON'T FIX)
  - **File:** `lib/src/uv/decoder.dart` (219 hex literals throughout)
  - **Issue:** Hardcoded VK codes, ASCII values, and key ranges
  - **Analysis:** The decoder has inline comments explaining each magic number
    (e.g., `0x08: // VK_BACK`, `0x41: // A`). Extracting 200+ constants would:
    - Significantly increase code size
    - Diverge from upstream Go implementation (harder to port fixes)
    - Provide marginal readability improvement over existing comments
  - **Recommendation:** Accept as technical debt; inline comments are sufficient.

- [x] **enterByte docs unclear** (Fixed 2025-01-19)
  - **File:** `lib/src/terminal/keys.dart:991-1005`
  - **Issue:** `enterByte = LF` vs `enterCR = CR` convention not documented
  - **Impact:** Developer confusion
  - **Fix:** Added comprehensive documentation explaining Unix (LF) vs Windows (CR) conventions
    and cross-references between the two constants.

---

## Testing Checklist

### Key/Input Handling Tests

- [x] Test: LF (0x0A) decoded as Enter by default (decoder)
- [x] Test: LF (0x0A) decoded as Ctrl+J with legacy flag (decoder)
- [x] Test: CR (0x0D) decoded as Enter by default (decoder)
- [x] Test: CR (0x0D) decoded as Ctrl+M with legacy flag (decoder) - exists in decoder_parity_test.dart:219-223
- [x] Test: key_table lookup for 0x0A returns Enter
- [x] Test: key_table lookup for 0x0D returns Enter
- [x] Test: Plain 'j' key distinct from Enter/Ctrl+J
- [x] Test: TUI parser and UV decoder consistent for all C0 codes (LF, CR, Tab)
- [x] Test: Modifier preservation through UV -> TUI adapter
- [x] Test: Extended keys (F21+, media) handled gracefully - added in tui_adapter_test.dart

### Program Lifecycle Tests

- [x] Test: Quit during message processing doesn't crash
- [x] Test: StreamCmd stops sending after quit
- [x] Test: EveryCmd stops sending after quit
- [x] Test: Reentrant send() doesn't corrupt state (covered by queue implementation)
- [x] Test: Model returning wrong type gives clear error
- [x] Test: Double cleanup doesn't crash
- [x] Test: Panic recovery restores terminal
- [x] Test: Cleanup errors are collected
- [x] Test: Deeply nested BatchMsg doesn't crash

### Rendering Tests

- [x] Test: Wide characters (CJK) render correctly
- [x] Test: Wide characters survive cloneArea
- [x] Test: Emoji with ZWJ sequences measure correctly - added in width_edge_cases_test.dart
- [x] Test: Truecolor preserved through wrap
- [x] Test: 256-color preserved through wrap
- [x] Test: Frame timing uses Stopwatch (immune to clock adjustments)

---

## Completed

- [x] **LF (0x0A) not handled in UV decoder** (Fixed 2025-01-19)
  - **File:** `lib/src/uv/decoder.dart:302-340`
  - **Issue:** LF fell through to generic C0 handler, became Ctrl+J
  - **Fix:** Added explicit `case 0x0a` with `_flagCtrlJ` legacy option
  - **Test:** `test/tui/uv/decoder_parity_test.dart`, `test/tui/uv/tui_adapter_test.dart`
