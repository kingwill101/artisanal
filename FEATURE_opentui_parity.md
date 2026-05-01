# Feature: Opentui Parity Gaps for Artisanal / Ultraviolet

## Summary

Bring the clearly missing `opentui` capabilities into the `artisanal`
workspace, focusing on the areas that do not already have a local equivalent.

This is not a full parity effort. Focus, blur, overlay composition, and remote
plugin routing already exist in `artisanal`/`ultraviolet` and should not be
re-implemented under new names just to mirror `opentui`.

## Status

Implemented locally:

- public UV post-effects API via `ColorMatrix` and `ColorMatrixFilter`
- built-in UV effect filters for identity, grayscale, invert, tint, multiply,
  gain, and attenuation
- UV effects example in `pkgs/ultraviolet/example/effects.dart`
- centralized markdown fence language and filename resolver
- broader fenced-code alias coverage and filename/file-extension hints
- markdown resolver tests and example coverage
- in-process slot registry and declarative plugin mounting in
  `artisanal_widgets`
- remote-surface-to-slot bridge, slot-region composition, and interactive
  remote input routing across `artisanal` and `artisanal_widgets`
- concrete slot-system example coverage in
  `pkgs/artisanal_widgets/example/slots/main.dart`
- deterministic widget-test frame recording plus a testing-side `ManualClock`
  with animation-tick helpers
- terminal palette service and theme-host integration for foreground,
  background, cursor, and indexed palette reports
- public render-frame inspection with ANSI-aware line parsing and carried style
  prefixes

The original scope from this document is complete. Follow-up work should now be
treated as a new candidate list from a broader `opentui` scan, not as unfinished
closure work from the original parity gap.

## Reclassified After Broader `opentui` Scan

A wider pass over `third_party/opentui/packages/core`, `packages/react`, and
the testing utilities changes the picture a bit.

Several things that looked like parity gaps at a glance are already covered in
this workspace under different package boundaries or APIs:

- `package:artisanal/testing.dart` already re-exports a real widget-testing
  surface from `artisanal_widgets`, including `pumpWidget`, `pump`, `resize`,
  `sendKey`, `sendSpecialKey`, `tap`, `tapAt`, `mouseDown`, `mouseUp`, and
  `mouseMove`
- `artisanal_widgets` already has equivalents for many `opentui` renderables:
  `TextField`, `TextArea`, `TextEditor`, `CodeEditor`, `MarkdownEditor`,
  `GitDiffViewer`, `ScrollArea`, `Scrollbar`, `Slider`, `RangeSlider`, and
  `AsciiFont`
- the widget stack already has real animation primitives via
  `AnimationController`, `AnimationMixin`, and implicit animation helpers
- low-level terminal color report plumbing already exists through
  `Cmd.requestForegroundColor()`, `Cmd.requestBackgroundColor()`,
  `Cmd.requestCursorColor()`, `Cmd.requestColorPalette(...)`,
  `ForegroundColorMsg`, `BackgroundColorMsg`, `CursorColorMsg`,
  `ColorPaletteMsg`, UV `TerminalCapabilities`, and browser-host palette sync

That means the best remaining candidates are now narrower and more
infrastructure-oriented.

## Best Remaining Candidates From Additional `opentui` Scan

These are not strict parity requirements. They are the most credible remaining
ports after removing surfaces that already exist locally.

### 1. In-process plugin slot registry in `artisanal` / `artisanal_widgets`

`opentui` has a real in-process slot contribution model in
`packages/core/src/plugins/core-slot.ts` and
`packages/core/src/plugins/registry.ts`.

Good follow-up target for this workspace:

- named slots exposed by host apps or host widgets
- plugin contributions registered against those slots
- typed slot renderables / slot renderers
- explicit plugin ordering and deterministic conflict resolution
- lifecycle hooks and error reporting for slot contributions

Why it matters here:

- this workspace already has strong out-of-process remote plugin transport
- what it still lacks is a first-class in-process slot composition API
- this would complement the existing remote plugin model rather than replace it

Current local status:

- `SlotRegistry`, `SlotScope`, `SlotPlugin`, `SlotPluginMount`,
  `SlotBuilder`, `SlotRegion`, and `InteractiveSlotRegion` now provide a typed
  in-process slot composition surface with deterministic ordering
- remote plugin surfaces can already be resolved and rendered into the same
  slot-oriented host model through the `RemotePluginSlotEntry` bridge
- `pkgs/artisanal_widgets/example/slots/main.dart` now gives that API a
  concrete in-process example with live plugin mount/unmount toggles and
  visible contribution ordering

### 2. Deterministic clock + frame recorder additions to the existing testing stack

`opentui`'s testing surface is broader than just input helpers. The most
interesting pieces are in `packages/core/src/testing/test-recorder.ts`,
`packages/core/src/testing/test-renderer.ts`, and
`packages/core/src/testing/manual-clock.ts`.

Good follow-up target for this workspace:

- a shared clock abstraction for runtime pieces that currently schedule timers
  directly
- a `ManualClock` for deterministic animation, console, and replay tests
- broader recorder / snapshot coverage for `Program`, widget tests, or UV
  renderers
- optional scripted convenience wrappers for common key/mouse/paste sequences

Why it matters here:

- the workspace already has a substantial tester, so the remaining value is in
  determinism and richer recorder coverage rather than a second generic
  harness
- this would make animation and interactive tests less timing-sensitive
- it would also pair well with replay/evidence tooling already in the repo

Current local status:

- `WidgetTester` now supports deterministic frame recording with stable trigger
  labels, frame sequences, width/height metadata, manual frame capture, and
  scoped recording helpers
- `artisanal_widgets/testing.dart` now exports a deterministic `ManualClock`
  and `WidgetTester` helpers for driving animation ticks from explicit test
  time
- `WidgetTester` also has higher-level scripted helpers for common interactive
  sequences like `typeText(...)`, `pasteText(...)`, and `drag(...)`, so widget
  tests no longer need to open-code repeated low-level input dispatch
- `artisanal_widgets/testing.dart` now also exports a deterministic
  `WidgetFuzzer` / `WidgetTester.fuzz(...)` harness for seeded key, special
  key, paste, mouse, drag, resize, and pump input streams, with structured
  failure reporting and optional frame capture for replaying a failed run
- `ProgramRenderRecorder` now provides deterministic runtime-side render
  snapshots for direct `Program` tests, including parsed frame metadata and
  optional native-frame / delta payload capture through the interceptor path
- `ProgramRenderCapture` now bundles `ProgramRenderRecorder` and
  `ProgramRenderMonitor` into one reusable interceptor, so tests and tooling
  can collect both detailed snapshots and aggregate render stats without
  wiring two parallel interceptors
- `ProgramRenderCapture` now also formats combined metric/report lines, and
  `pkgs/artisanal/example/render_recorder_demo.dart` uses that bundled surface
  directly instead of manually coordinating separate recorder/monitor objects
- `ProgramRenderCaptureReport` now exposes that same bundled state as a
  structured value object for tooling that wants typed report fields instead
  of only preformatted diagnostic lines
- `ProgramRenderCaptureReport` can now also serialize to a simple map via
  `toJson()`, which makes it easier to hand bundled render-capture summaries
  to evidence, debug, or external tooling layers without reformatting
- that structured report now also carries the latest native-change summary,
  so tooling can inspect the final dirty/line/cell/span counts as typed data
  instead of only recovering them from formatted metric strings
- `ProgramRenderCapturePayload` now exposes that bundled export state as a
  typed value object, so tooling can pass around one stable payload instead of
  rebuilding ad hoc maps from recorder and monitor pieces
- `ProgramRenderCapture` now also emits that payload directly via
  `payload(...)` and `toJson()`, and the export includes typed aggregate stats,
  the structured report, the latest snapshot, and a compact last-snapshot
  summary with typed change-summary data
- `TuiEvidence` can now persist that same render-capture surface directly via
  `logRenderCapture(...)` / `logRenderCapturePayload(...)`, so evidence tooling
  no longer has to rebuild capture-state payloads by hand before writing JSONL
- `ProgramRenderSnapshotSummary` now provides a stable compact view of the
  latest captured frame, so tooling can consume “last render” metadata without
  depending on the full snapshot record shape
- `ProgramOptions.nowProvider` now lets runtime tests inject deterministic
  logical timestamps for frame ticks, queue timing, macro timing, and resize
  coalescing instead of always reading wall time directly
- `Cmd.tick(...)`, `EveryCmd`, and the `every(...)` helper now also accept
  injected logical time sources for deterministic command/timer callback
  timestamps
- bubble-level timer surfaces now follow that same pattern:
  `TimerModel`, `StopwatchModel`, and `SpinnerModel` can stamp generated tick
  and timeout messages from injected logical clocks instead of always reading
  wall time directly
- smaller convenience bubbles now follow it too:
  `CountdownModel` can emit deterministic start/tick timestamps, and
  `ProgressModel` can compute ETA from an injected logical clock
- input-heavy bubbles now participate too: `ViewportModel`,
  `TextInputModel`, and `TextAreaModel` use injected logical clocks for
  double/triple-click timing instead of always reading wall time directly
- scroll-selection widgets now follow the same pattern:
  `SingleChildScrollView`, `ScrollView`, and `VirtualListView` accept injected
  logical clocks for click sequencing, and the virtual list also uses that
  seam for wheel-pulse dedupe timing
- debug/runtime helpers now expose the same seam where it matters:
  `DebugConsoleController`, `DebugOverlay`, and `PerformanceOverlay` can all
  take injected logical clocks instead of hard-wiring wall time for fallback
  timestamps
- widget-frame timing itself is now covered too:
  `BuildOwner` accepts an injected logical clock for `WidgetFrameTiming`
  timestamps, so performance snapshots and frame callbacks no longer have to
  depend on wall time
- internal scan bookkeeping has also been tightened:
  `ZoneManager` now uses a monotonic iteration counter for zone scans instead
  of wall-clock microseconds, removing another unnecessary time dependency
- remote plugin workspace waits are now elapsed-time based:
  surface readiness polling in `RemotePluginWorkspace` no longer depends on
  wall-clock deadlines to enforce timeouts
- evidence logging now has a deterministic path seam:
  `TuiEvidence.configureForTest(...)` can inject the date/time source used for
  generated evidence file paths, so path naming no longer has to depend on the
  real wall clock in tests
- trace logging now has the same test seam:
  `TuiTrace.configureForTest(...)` can inject the wall-clock source used for
  generated trace file paths and `# trace start:` headers, so runtime trace
  artifacts are no longer pinned to the real clock in tests
- the remaining value in this area is primarily smaller utility cleanup and
  recorder integration polish rather than missing core determinism seams

### 3. Higher-level terminal palette detector/service in `artisanal`

`opentui` ships a dedicated `TerminalPalette` abstraction in
`packages/core/src/lib/terminal-palette.ts`.

Good follow-up target for this workspace:

- a higher-level terminal palette detector/service
- bundled orchestration of foreground/background/cursor/palette queries
- cached palette capability results for apps and themes
- tmux-aware query wrapping and cleanup hidden behind one API

Why it matters here:

- the low-level message plumbing already exists here
- what is missing is the ergonomic service that batches detection and caching
- this would be useful for adaptive themes and host/browser parity

Current local status:

- `TerminalPaletteService` now batches core color and indexed palette probes,
  caches replies from terminal color report messages, and exposes immutable
  snapshots
- `TerminalThemeHost` now integrates that cache into `TerminalThemeState` and
  provides one-call startup probing helpers for host models
- example hosts now use the shared probing path instead of manually assembling
  color report commands
- the `uv-input` example now also surfaces the cached palette state directly,
  including foreground/background/cursor values and ANSI slot previews, and it
  exposes explicit palette probe shortcuts for interactive verification

### 4. Native span feed / streaming render bridge

`opentui` exports `NativeSpanFeed` and also exposes span capture from its test
renderer.

Good follow-up target for this workspace:

- a streaming span/native render feed abstraction
- lower-overhead render snapshots than full string materialization
- future browser/socket/remote-surface bridge hooks based on spans instead of
  only char-frame dumps

Why it matters here:

- there is no direct local equivalent
- it could improve render inspection, debugging, and performance work
- it is a better fit for renderer infrastructure than normal widget parity

Current local status:

- `TerminalRenderFrame` and `TerminalRenderLine` now expose public,
  ANSI-aware inspection of rendered strings and `View` content, including
  carried line state prefixes, plain-text extraction, and visible-width
  helpers
- `TerminalNativeFrame` now exposes a public UV cell-buffer snapshot model with
  per-cell style/link metadata, dirty spans, and wide-cell placeholder
  preservation from native buffers or temporary rendered screens
- `ProgramRenderFeed` now provides a live subscription surface for render
  events, and UV-backed programs can receive native frame snapshots on each
  render through the existing interceptor pipeline
- those live events and recorded snapshots now also expose a compact
  `ProgramRenderChangeSummary`, so consumers can answer “what changed?” from
  dirty-line, changed-cell, and grouped-span counts without re-walking the raw
  native delta payloads every time
- `ProgramRenderMonitor` now provides a reusable higher-level consumer on top
  of that feed, aggregating total renders, changed renders, duration averages,
  and native-change peak/cumulative counts across one run
- `ProgramRenderStats` can now also format those aggregates into compact
  key-value metric entries, so apps can surface monitor data in debug overlays
  or custom metrics panes without hand-formatting the counters each time
- `pkgs/artisanal/example/render_recorder_demo.dart` now demonstrates direct
  non-widget consumption of `ProgramRenderRecorder` and `ProgramRenderMonitor`,
  including parsed lines and formatted metric entries, so the render-feed
  surface is not only exercised through widget overlays
- `artisanal_widgets` now exposes that bridge through
  `RenderMetricsInjector.setRenderStats(...)`, so the runtime-side monitor can
  feed the built-in debug overlay/custom metrics path directly instead of
  requiring app code to repackage the entries by hand
- `RenderMetricsProgramMonitor` now provides that bridge as a reusable
  interceptor, so widget apps can publish `ProgramRenderMonitor` aggregates
  into debug overlays without open-coding monitor/injector wiring in each app
- the `artisanal_widgets` `debug_overlay` example now demonstrates that path
  concretely by pushing `ProgramRenderMonitor` stats into the built-in overlay
  during a real app run
- those live render events now also carry dirty-line native deltas captured
  before UV clears dirty tracking, which is enough for incremental observers
  that do not need a full span stream
- live render events now also carry changed-cell deltas computed against the
  previously committed native frame, which further narrows the gap to
  higher-level span semantics rather than raw change detection
- those changed-cell deltas are now grouped into semantic spans per line, so
  live observers can consume styled run-level changes without rebuilding span
  grouping themselves
- the fullscreen renderer now uses the same shared parser for diffing and
  inspection, which removes duplicate parsing logic
- `TuiEvidence` can now emit opt-in parsed `render_frame` records for runtime
  renders, so replay/debug tooling can consume structured line snapshots
  without re-parsing raw ANSI output later, and those records can now also
  include semantic native span deltas when available
- `ReplayTraceConverter` now preserves those evidence-backed `render_frame`
  records as replay custom events, including inferred screen dimensions and
  per-line metadata, and it carries span-delta payloads through unchanged for
  downstream replay/debug consumers
- that replay/evidence bridge now also understands typed `render_capture`
  payloads, so nested capture reports and last-snapshot summaries survive
  conversion and can seed inferred replay dimensions without being flattened
  back into ad hoc top-level fields
- replay-side consumers can now also decode those `runtime.render_capture`
  custom events back into typed `ProgramRenderCapturePayload` values directly,
  and the shared `ReplayEventPresentation` / `ReplayRenderCaptureEvent`
  surfaces now provide centralized ready-to-display summary lines and status
  hints on top of that decoded payload, with both
  `pkgs/artisanal_widgets/example/tooltip_trace` and
  `pkgs/artisanal_widgets/example/opencode` now using that path for replay
  summaries instead of dumping raw nested field maps, and
  `ReplayEventPanel` now exposes that same replay-summary surface as a
  reusable widget for debug/replay UIs; `ReplayEventHistoryPanel` now extends
  that into a recent-event browser with built-in filtering, flat/grouped
  modes, type-count overview chips, and optional interactive filter/mode
  controls, with both `tooltip_trace` and `opencode` using it to display
  replay-event history in the UI, `opencode` filtering that view down to
  render-capture traffic while now also exposing the shared flat/grouped mode
  controls plus an expand/collapse toggle for compact versus fuller history
  browsing, with collapsed views now also surfacing a compact hidden-event
  summary that becomes grouped-row-aware in grouped mode and now also uses a
  grouped-mode-aware expand label; the type-chip overview is now grouped-row-
  aware too, with `opencode` now explicitly covered by an example test for
  those grouped summaries; a shared `ReplayEventHistoryState` now also keeps
  filter/mode/expanded state from being open-coded separately in each example,
  and `ReplayEventHistoryBrowser` now also exposes reusable `interactive` and
  `renderCaptures` presets so consumers like `tooltip_trace` and `opencode`
  stop open-coding their browser configuration too; `tooltip_trace` now uses
  the same shared expand/collapse path alongside its live filter/mode chip
  toggles instead of manually spelunking nested `eventFields` maps
- the remaining value in this area is now mostly app-specific consumers and
  deeper native/span protocol integration rather than missing reusable feed
  infrastructure

## Worth Considering

### 1. Low-level text buffer / edit buffer / editor view primitives

`opentui` exposes `TextBuffer`, `EditBuffer`, and `EditorView` in
`packages/core/src/text-buffer.ts`, `packages/core/src/edit-buffer.ts`, and
`packages/core/src/editor-view.ts`.

Potential follow-up target:

- a reusable non-widget text buffer with styled ranges/highlights
- an editor viewport/selection primitive independent of widgets
- a lower-level editing core for future editor features

Why it is lower priority:

- this workspace already has strong high-level editor widgets and controllers
- the value here is engine reuse, not surface parity for end-user editing

Current local status:

- the underlying editing engine already existed locally in
  `src/tui/editor_core`, including `TextDocument`, `EditorState`, `TextView`,
  edit operations, command helpers, decorations, diagnostics, syntax ranges,
  paste helpers, and undo/history plumbing
- that core is now promoted through a stable public entrypoint at
  `package:artisanal/editor_core.dart` instead of requiring `src/` imports
- the public entrypoint also exposes compatibility-facing aliases
  `TextBuffer`, `EditorView`, and `EditBufferState` so lower-level consumers
  can discover the existing primitives more easily
- `package:artisanal/editor_core.dart` now also exposes a thin `EditBuffer`
  facade that owns `TextDocument`, `EditorState`, `TextView`, range helpers,
  core editing commands, cursor movement, and snapshot-based undo/redo on top
  of the shared primitives
- that `EditBuffer` facade now also supports committed and rolled-back edit
  transactions plus journal round-tripping for undo/redo state
- `pkgs/artisanal/example/editor_core_demo.dart` now demonstrates the public
  low-level `EditBuffer` surface directly, including cursor movement,
  transactions, rollback/commit, and journal restore without routing through
  widget-level editor components
- the remaining value in this area is deeper API expansion, command-level
  journaling interoperability, or native-buffer optimization rather than the
  absence of a reusable low-level editing surface

### 2. Timeline / animation sequencing API

`opentui` exposes a richer imperative `Timeline` in
`packages/core/src/animation/Timeline.ts`.

Potential follow-up target:

- animation sequencing across multiple targets/controllers
- loop, alternate, and easing orchestration in one timeline surface
- a small bridge layer on top of existing widget animation primitives

Why it is lower priority:

- base animation capability already exists locally
- the gap is sequencing ergonomics, not missing animation support

Current local status:

- `artisanal_widgets` now exposes a TEA-native `AnimationTimeline` on top of
  `AnimationController`
- timeline steps can sequence `forward`, `reverse`, `animateTo`,
  `animateBack`, `delay`, and `parallel(...)` groups through one message-driven
  API
- timeline playback now supports repeating and alternating cycles for common
  entrance/exit choreography without hand-written controller orchestration
- timeline steps now support optional labels, the runtime exposes active-step
  metadata, and hosts can subscribe to step start/complete hooks for debug or
  orchestration glue
- timeline steps can now also run synchronous callback/orchestration hooks
  inline, which makes it possible to interleave animation progress with
  imperative TEA-side coordination without building a second control surface
- `AnimationTimeline.staggeredForward(...)` now provides a higher-level
  stagger helper for the common “controller ladder with gaps” case
- `AnimationTimeline.staggered(...)` now generalizes that pattern for custom
  per-controller step builders, so staggered reverse/custom controller ladders
  do not need to hand-build step lists
- `AnimationTimeline.pulse(...)` now provides a reusable preset for the common
  forward/hold/reverse/rest emphasis cycle instead of forcing hosts to hand-roll
  that sequence from primitive steps each time
- `AnimationTimeline.cascade(...)` now provides a higher-level multi-controller
  choreography preset for serial in/hold/out sequences with inter-controller
  gaps and end-of-cycle rest timing, so stepped lane animations no longer need
  to hand-build repeated forward/delay/reverse groups
- `AnimationTimeline.wave(...)` now provides the mirrored traveling-wave
  counterpart to that, sequencing a forward crest sweep across controllers and
  then a reverse return sweep without forcing hosts to hand-build the mirrored
  order themselves
- `AnimationTimeline.fan(...)` now provides a staggered-entrance /
  synchronized-exit preset for stepped reveals that should collapse back out
  in one coordinated beat, covering another common choreography shape without
  forcing hosts to assemble parallel reverse groups manually
- `AnimationTimeline.breath(...)` now provides the synchronized multi-
  controller counterpart to `pulse`, giving hosts a ready-made expand/hold/
  contract/rest cycle for grouped emphasis without hand-building paired
  parallel steps
- `AnimationTimeline.ripple(...)` now provides a center-origin choreography
  preset for outward emphasis and mirrored return motion, covering a non-linear
  multi-controller sequence that would otherwise require hand-building a custom
  order list
- `AnimationTimeline.converge(...)` now provides the edge-origin inward
  counterpart to that, giving the API a reusable edge-to-center / center-to-
  edge choreography shape instead of only center-out non-linear motion
- `AnimationTimeline.accordion(...)` now provides a symmetric pairwise
  center-out preset for mirrored lanes that should move in grouped left/right
  pairs instead of one controller at a time
- the `artisanal_widgets` `animated_tint` example now also includes a concrete
  timeline-driven choreography section, so the newer cascade and pulse helpers
  are exercised in a real demo instead of existing only as library surface
- the remaining value in this area is now mostly more opinionated choreography
  presets rather than the absence of reusable sequencing/orchestration sugar

### 3. Animated post-effects in `ultraviolet`

The current UV work covers color-matrix effects. `opentui` goes further with
public higher-level effects in `packages/core/src/post/effects.ts`.

Potential follow-up target:

- vignette-style effects
- distortion-style effects
- CRT or rolling-bar style effects
- simple procedural atmosphere effects
- text-oriented animated effects built on top of the existing filter pipeline

Why it is still optional:

- it builds directly on the new `ColorMatrix` / `ColorMatrixFilter` work
- it could support modal backdrops, debug overlays, and richer demos
- but it is iteration on an existing UV surface, not a missing parity block

Current local status:

- `ultraviolet` now exposes public higher-level spatial/temporal post filters in
  addition to the matrix pipeline
- `VignetteFilter` provides a reusable edge-darkening pass for framing and
  backdrop emphasis
- `ScanlineFilter` provides a CRT-style scanline pass with an animated rolling
  brightness band
- `WaveDistortionFilter` now provides a deterministic distortion-style pass for
  shimmer/heat-haze style motion without relying on the noisier liquify field
- `GhostingFilter` now provides a temporal glyph-afterimage pass for
  phosphor/echo-style text trails without dragging full background fills along
  with the trail
- `CompositeFilter`, `CrtFilter`, and `AtmosphereFilter` now provide reusable
  preset stacks on top of those primitives so hosts can opt into higher-level
  looks without assembling filter chains manually
- `AmberTerminalFilter` and `PhosphorFilter` now provide display-style color
  grading presets on top of the matrix and composite-filter layers
- `PhosphorTrailFilter` now provides a higher-level persistence preset on top
  of phosphor grading and glyph ghosting, so the temporal trail surface is
  available as a ready-made display variant rather than only as a primitive
- `AmberTrailFilter` now provides the warm-monochrome counterpart to that
  persistence preset, so both phosphor-style and amber-style trail looks are
  available as ready-made display variants
- `CrtTrailFilter` now provides the display-emulation counterpart to those
  persistence presets, combining CRT structure with a dimmed afterimage trail
  for scenes that want both scanline/vignette character and temporal echo
- the remaining value here is broader effect variety such as more specialized
  CRT/distortion/afterimage variants, not the absence of public non-matrix
  filters

### 4. 3D package or experimental module

`opentui` exposes a full `3d` surface with WebGPU, sprites, and physics
adapters.

Potential follow-up target:

- a separate experimental package
- sprite/canvas helpers for terminal-adjacent rendering
- isolated demos rather than core-package coupling

This is a real gap, but it is large enough to be its own project. It should
not be mixed into normal parity cleanup.

## Historical Gaps Now Closed

### 1. UV post-effects and color-matrix pipeline

Before the completed work tracked by this document, `opentui` exposed public
post effects and matrices backed by a native color-matrix implementation while
this workspace exported only:

- `BufferFilter`
- `BufferRenderSink`
- `LiquifyFilter`

At that point there was no equivalent public API for:

- reusable color matrices
- gain/attenuation-style effects
- a first-class post-processing/effects namespace
- native or optimized matrix-based color transforms

### 2. Expanded markdown fence language/filetype resolution

Before the completed markdown work tracked here, `artisanal` already supported
fenced code blocks and syntax highlighting, but its language normalization was
smaller and more alias-based than the newer mapping layer in `opentui`.

The missing or likely incomplete pieces at that time were:

- broader language alias coverage
- filename-to-language mapping for fenced blocks
- a more systematic resolver for code-fence language labels
- docs/tests for expanded mapping behavior

## Already Covered Locally

These should be treated as existing capabilities, not gaps:

- focus and blur events in `ultraviolet`
- focus reporting and `FocusMsg` handling in `artisanal`
- widget-level focus management in `artisanal_widgets`
- widget testing via `package:artisanal/testing.dart` /
  `package:artisanal_widgets/testing.dart`
- editor widgets and controllers such as `TextField`, `TextArea`, `TextEditor`,
  `CodeEditor`, and `MarkdownEditor`
- `GitDiffViewer`, `ScrollArea`, `Scrollbar`, `Slider`, `RangeSlider`, and
  `AsciiFont`
- widget animation primitives via `AnimationController`, `AnimationMixin`, and
  implicit animation helpers
- remote plugin surface routing and host/guest plumbing
- low-level terminal foreground/background/cursor/palette query plumbing
- tint, backdrop, overlay, and blend helpers
- markdown code block rendering and syntax highlighting in general

## Historical Scope That Was Completed

### A. Add a public UV effects surface

Create a first-class post-processing API in `pkgs/ultraviolet` that can grow
beyond `LiquifyFilter`.

Initial target:

- export a public effects module from `package:ultraviolet`
- introduce reusable color-matrix primitives
- add at least a small starter set of built-in effects
- keep `BufferFilter` compatibility where practical

Candidate built-ins:

- gain
- attenuation
- grayscale
- invert
- tint / multiply-style transforms

### B. Expand markdown language resolution in `artisanal`

Improve fenced code block language resolution in the markdown renderer.

Initial target:

- centralize language normalization
- add common alias coverage beyond the current short list
- support filename/file-extension style hints where reasonable
- add focused tests for alias and mapping behavior

## Acceptance Criteria That Are Now Met

- `ultraviolet` exposes a public post-effects API beyond `LiquifyFilter`.
- At least one matrix-driven effect is implemented and tested.
- `artisanal` markdown rendering recognizes a broader set of fence language
  labels than it does today.
- Markdown language resolution behavior is covered by explicit tests.
- The feature lands with at least one example or doc update for each area.

## Non-Goals

- Rebuilding `opentui`'s Solid bindings API in `artisanal_widgets`
- Replacing the current remote plugin architecture with `opentui`'s plugin
  model
- Full one-to-one `opentui` API naming parity

## Historical Implementation Order

1. Add UV color-matrix primitives and one simple effect.
2. Export the new API from `ultraviolet` and `artisanal`.
3. Add markdown language resolver improvements and tests.
4. Add examples/docs for both features.
