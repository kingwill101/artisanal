# FrankenTUI Parity Tracker

Features ported from [FrankenTUI](../artisanal-dash/third_party/frankentui) into Artisanal.

Each item must include passing tests before being checked off.
Tests should live alongside the feature and cover the happy path,
edge cases, and regression guards.

---

## Inline Mode (Top Priority)

- [ ] Inline scrollback-preserving terminal mode
  - **Where:** artisanal (tui runtime)
  - **Gap:** TUI runtime only supports alt-screen mode. FrankenTUI has
    kernel-level inline mode that preserves terminal scrollback while
    keeping UI chrome stable.
  - **Why:** CLI tools that embed TUI components (spinners, progress
    bars) inline in a build log or pipeline output.
  - **Tests:** Verify scrollback is preserved, cursor positioning in
    inline region, resize behavior, cleanup on exit.

---

## High Impact — Rendering Engine (ultraviolet)

- [ ] Packed cell layout (16-byte, SIMD-comparable)
  - **Where:** ultraviolet
  - **Gap:** Cell is ~56+ bytes with heap-allocated strings. FrankenTUI
    uses 16-byte repr(C) cells (4 per cache line, single 128-bit
    comparison).
  - **Why:** 3-4x memory reduction, enables SIMD cell equality,
    reduces cache misses.
  - **Tests:** Cell size assertion, equality correctness for all
    content types (char, grapheme, continuation), packed equality
    vs field-by-field comparison.

- [ ] Multi-level dirty tracking (rows + spans + per-cell bits)
  - **Where:** ultraviolet
  - **Gap:** Only per-line `touched` with first/last cell range.
    FrankenTUI tracks dirty_rows, dirty_spans (SmallVec<4>), and
    per-cell dirty_bits.
  - **Why:** Narrower redraw regions per line, skip unchanged lines
    faster, foundation for tile-based diff.
  - **Tests:** Dirty region correctness after set/fill/insert/delete,
    span merging logic, fallback to full-row at overflow, bitmap
    consistency.

- [ ] Block-based diff with summed-area table tile-skip
  - **Where:** ultraviolet
  - **Gap:** Per-line left+right scan diff. FrankenTUI compares
    4-cell quads via bitwise AND and uses SAT for O(1) tile density
    queries on large buffers.
  - **Why:** Fewer branches per diff pass, skip clean tile regions
    entirely on large terminals.
  - **Tests:** Diff correctness matches naive diff, tile boundaries
    handled correctly, SAT query accuracy, dense buffer fallback
    triggers correctly.

- [ ] Grapheme pool (interned IDs, deduped, ref-counted)
  - **Where:** ultraviolet
  - **Gap:** Complex graphemes stored as raw strings per cell.
    FrankenTUI deduplicates via AHashMap, ref-counts, uses 16-bit
    pool slots with ABA generation protection.
  - **Why:** Avoids emoji duplication, faster cell equality (integer
    compare vs string compare), enables gc of unreferenced graphemes.
  - **Tests:** Intern dedup, release/gc correctness, generation
    wrapping, slot reuse, width embedding in ID.

- [ ] Arena allocator (bump allocation, O(1) reset per frame)
  - **Where:** ultraviolet
  - **Gap:** No arena, individual heap allocs per cell/line.
    FrankenTUI uses bumpalo with 256KB default, O(1) reset.
  - **Why:** Eliminates per-frame GC pressure, faster allocation
    for frame-scoped temporaries.
  - **Tests:** Allocation correctness, reset reclaims memory,
    capacity retention across frames, no use-after-reset.

- [ ] Alpha compositing (Porter-Duff SourceOver)
  - **Where:** ultraviolet
  - **Gap:** UvColor has alpha but no compositing. FrankenTUI
    applies SourceOver in cell bg with integer-only arithmetic.
  - **Why:** Enables transparency/layering effects, overlay
    rendering, style blending.
  - **Tests:** Full opacity passthrough, full transparency passthrough,
    semi-transparent compositing correctness, integer overflow safety.

---

## High Impact — TUI Runtime (artisanal)

- [ ] Budget-aware degradation cascade
  - **Where:** artisanal (tui runtime)
  - **Gap:** Only fps control, no graceful degradation. FrankenTUI
    has PID controller + E-process with 6 degradation levels.
  - **Why:** Graceful perf under load, widgets self-identify as
    essential vs decorative, skips decorative elements first.
  - **Tests:** Degradation triggers on sustained over-budget frames,
    recovery after sustained within-budget frames, essential widgets
    never skipped, E-process false positive bounds.

- [ ] DP cursor cost model
  - **Where:** ultraviolet
  - **Gap:** Multi-strategy cursor movement, picks shortest sequence.
    FrankenTUI uses backward DP per row comparing sparse vs merged
    write-through.
  - **Why:** Better decisions on when to merge vs skip, fewer bytes
    emitted per frame.
  - **Tests:** Output byte count <= current strategy, correct cursor
    positioning after all moves, gap threshold boundary behavior.

- [ ] SGR delta emission
  - **Where:** ultraviolet
  - **Gap:** Per-attribute set/reset codes. FrankenTUI compares
    delta_len vs baseline_len (reset+reapply) and picks cheaper.
  - **Why:** Fewer bytes per style change, handles collateral damage
    from BOLD/DIM toggling.
  - **Tests:** Delta produces correct final style, delta_len <=
    baseline_len always, collateral damage cases (bold+dim) handled.

---

## Medium Impact — TUI Runtime (artisanal)

- [ ] BOCPD resize coalescing
  - **Where:** artisanal (tui runtime)
  - **Gap:** Fixed resize delay. FrankenTUI detects steady vs burst
    regimes with Bayesian change-point detection.
  - **Why:** Faster response during steady resize, coalesces rapid
    bursts to avoid wasted renders.
  - **Tests:** Steady regime uses short delay, burst regime uses
    coalesced delay, regime transitions detected correctly.

- [ ] Macro recorder/player
  - **Where:** artisanal (tui runtime)
  - **Gap:** ProgramReplay exists but no user-facing recording.
    FrankenTUI can record and replay input sequences.
  - **Why:** Power-user automation, testing, reproducible demos.
  - **Tests:** Record captures all inputs, replay produces identical
    output, nested recording rejected, playback timing preserved.

- [ ] Evidence logging (JSONL structured diagnostics)
  - **Where:** artisanal (tui runtime)
  - **Gap:** TuiTrace is timing-focused. FrankenTUI logs every
    probabilistic decision as JSONL with factor ledgers.
  - **Why:** Debug complex TUI apps, understand why degradation
    decisions were made, audit rendering behavior.
  - **Tests:** Log entries emitted for each decision type, JSONL
    format valid, factor ledger completeness, opt-in/opt-out control.

- [ ] Undo system (command pattern)
  - **Where:** artisanal (tui runtime)
  - **Gap:** TextField has basic Ctrl+Z. FrankenTUI has full
    command-pattern undo with journal, transactions, merge.
  - **Why:** Benefit editors and form-heavy apps, transactional
    undo for multi-step operations.
  - **Tests:** Undo/redo correctness, transaction commit/rollback,
    merge semantics, journal persistence.

---

## Medium Impact — Layout (artisanal)

- [ ] Stable layout rounding (Largest Remainder Method)
  - **Where:** artisanal (layout)
  - **Gap:** Potential layout jitter on fractional pixel allocations.
    FrankenTUI uses LRM with temporal tie-breaking.
  - **Why:** Minimize layout jitter across frames, stable visual
    output during resize.
  - **Tests:** Allocations sum to total always, previous frame's
    rounding preferred when tie, no visual jitter on fixed-size
    terminal.

- [ ] Tiling pane manager
  - **Where:** artisanal (tui runtime)
  - **Gap:** SplitView is static. FrankenTUI has full tiling WM
    with split/drag/resize/dock/snap/magnetic fields.
  - **Why:** IDE-like TUI apps, draggable pane layouts, keyboard
    and mouse pane management.
  - **Tests:** Split creates correct sub-panes, drag-to-resize
    respects min sizes, snap zones trigger correctly, keyboard
    navigation between panes, invariant checking.

- [ ] Responsive breakpoints
  - **Where:** artisanal (layout)
  - **Gap:** No responsive layout system. FrankenTUI has
    xs/sm/md/lg/xl with configurable thresholds.
  - **Why:** TUIs that adapt to terminal width, collapsing
    sidebars or switching layouts at breakpoints.
  - **Tests:** Breakpoint transitions at correct widths, custom
    thresholds respected, widget visibility changes on breakpoint.

---

## Medium Impact — Widgets (artisanal_widgets)

- [ ] Keyboard drag
  - **Where:** artisanal_widgets
  - **Gap:** Drag is mouse-only. FrankenTUI supports keyboard-
    driven drag-and-drop.
  - **Why:** Accessibility, keyboard-only workflows.
  - **Tests:** Keyboard activation/deactivation, move by step,
    drop at target, focus management during drag.

- [ ] Bayesian fuzzy scoring for CommandPalette
  - **Where:** artisanal_widgets
  - **Gap:** CommandPalette exists but likely simpler matching.
    FrankenTUI uses Bayes factors with explainable evidence
    ledgers.
  - **Why:** Better ranked results, explainable scoring, handles
    edge cases (typos, partial matches) more gracefully.
  - **Tests:** Exact matches rank highest, prefix matches rank
    below exact, scoring is deterministic, evidence ledger
    populated.

- [ ] Virtualized list with Fenwick trees + height prediction
  - **Where:** artisanal_widgets
  - **Gap:** VirtualListView exists without advanced data
    structures. FrankenTUI uses Fenwick trees for O(log n)
    scroll and Bayesian height prediction.
  - **Why:** Faster scroll positioning for large lists, reduced
    scroll jumps from height estimation errors.
  - **Tests:** Scroll position accuracy, O(log n) bounds on
    prefix sum queries, height prediction convergence, large
    list (100K+ items) performance.

- [ ] Degradation-aware widget priority
  - **Where:** artisanal_widgets
  - **Gap:** No widget degradation system. FrankenTUI has
    Budgeted\<W\> wrapper and widget signals (priority, staleness,
    focus boost).
  - **Why:** Essential widgets (input, status) render first,
    decorative widgets (animations, sparklines) degrade.
  - **Tests:** Essential widgets never skipped at any degradation
    level, priority ordering respected, widget signals computed
    correctly.

---

## Lower Impact — Style & Accessibility (artisanal)

- [ ] WCAG contrast checking
  - **Where:** artisanal (style)
  - **Gap:** No contrast checking. FrankenTUI has contrast_ratio,
    meets_wcag_aa/aaa, best_text_color, relative_luminance.
  - **Why:** Accessible color combinations, automatic text color
    selection on colored backgrounds.
  - **Tests:** Contrast ratios match reference values, AA/AAA
    thresholds correct, best_text_color returns highest contrast,
    luminance calculation matches spec.

- [ ] InteractiveStyle (hover/focus/active/disabled states)
  - **Where:** artisanal (style)
  - **Gap:** No state-based styling. FrankenTUI has CSS pseudo-
    class equivalent with resolve() merging.
  - **Why:** Hover highlights, focus rings, active press states,
    disabled dimming — all from a single style definition.
  - **Tests:** State resolution priority (hover after focus),
    absent state falls back to normal, all state combinations.

- [ ] TableTheme with gradients, blend modes, effect presets
  - **Where:** artisanal (style)
  - **Gap:** Basic table styling. FrankenTUI has effect rules
    (Pulse, BreathingGlow, GradientSweep), blend modes, 9
    presets.
  - **Why:** Rich table visualization, animated rows, themed
    presets for quick styling.
  - **Tests:** Effect application by section/row/cell targeting,
    blend mode math correctness, preset round-trip, color
    profile fallback.

- [ ] Accessibility tree (A11yTree)
  - **Where:** artisanal_widgets
  - **Gap:** No a11y features. FrankenTUI has A11yTree nodes
    with deterministic FNV-1a node IDs.
  - **Why:** Screen reader support, semantic widget identity,
    diff-based tree updates.
  - **Tests:** Tree construction from widget hierarchy, node ID
    stability, diff correctness, widget-to-node mapping.

---

## Lower Impact — Extras

- [ ] Scissor + opacity stacks in Buffer
  - **Where:** ultraviolet
  - **Gap:** No clipping or opacity stacks. FrankenTUI has GPU-
    style scissor (monotonically decreasing intersection) and
    opacity (product of pushed values).
  - **Why:** Enables composited overlays, partial-region rendering,
    transparent layers.
  - **Tests:** Scissor intersection correctness, pop restores
    previous, opacity product applied to fg/bg, base case (empty
    stack) is full coverage + full opacity.

- [ ] Link registry (deduped, 24-bit IDs, free list)
  - **Where:** ultraviolet
  - **Gap:** Link stored as string per cell. FrankenTUI deduplicates
    URLs, uses 24-bit integer IDs with free list reuse.
  - **Why:** Faster cell equality (int compare vs string), lower
    memory for repeated links, supports 16M unique links.
  - **Tests:** Dedup returns same ID for same URL, release returns
    slot to free list, 24-bit overflow handled, URL validation
    rejects control characters.
