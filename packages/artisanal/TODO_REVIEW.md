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

- [x] **KeyType missing extended keys** (Documented 2025-01-19)
  - **File:** `lib/src/terminal/keys.dart:29-166`
  - **Issue:** F21-F63, media keys, lock keys not in KeyType enum
  - **Impact:** Extended keys become `KeyType.unknown` in TUI mode
  - **Fix:** Documented the behavior in KeyType enum docs and unknown value docs.
    Extended keys should use raw UV events via UvEventMsg.
  - **Test:** `test/tui/uv/tui_adapter_test.dart` - tests for F21+ mapping to unknown

- [ ] **key_table C0 entries potentially dead code**
  - **File:** `lib/src/uv/key_table.dart:62-94`
  - **Issue:** C0 entries never consulted since decoder handles them first
  - **Impact:** Maintenance burden, confusion
  - **Fix:** Remove dead entries or document fallback purpose
  - **Test:** Verify code path that uses key_table C0 entries

---

## Low - Nice to Have

### Commands

- [ ] **EveryCmd.isActive wrong during delay**
  - **File:** `lib/src/tui/cmd.dart:859-860`
  - **Issue:** Returns false during initial delay when actually active
  - **Impact:** Incorrect state reporting
  - **Fix:** Check `_starter?.isActive` as well
  - **Test:** EveryCmd with delay reports isActive correctly

### Performance

- [ ] **Unnecessary Cell cloning**
  - **File:** `lib/src/uv/buffer.dart:118`
  - **Issue:** Every `set()` clones cell even when not needed
  - **Impact:** Performance overhead in hot path
  - **Fix:** Only clone when necessary
  - **Test:** Benchmark buffer operations

### Code Quality

- [ ] **Magic numbers in Win32/SS3**
  - **File:** `lib/src/uv/decoder.dart:2138, 431`
  - **Issue:** Hardcoded VK codes and key ranges
  - **Impact:** Code readability
  - **Fix:** Extract to named constants
  - **Test:** N/A (refactoring)

- [ ] **enterByte docs unclear**
  - **File:** `lib/src/terminal/keys.dart:918-919`
  - **Issue:** `enterByte = LF` vs `enterCR = CR` convention not documented
  - **Impact:** Developer confusion
  - **Fix:** Add documentation explaining Unix (LF) vs Windows (CR) convention
  - **Test:** N/A (documentation)

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
