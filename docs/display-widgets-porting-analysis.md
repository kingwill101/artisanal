# Display Widgets: Frankentui → Artisanal Porting Analysis

Compares Frankentui widget implementations with current Artisanal state, identifies gaps, and recommends what to port.

---

## 1. Badge

### Frankentui (`ftui-widgets/src/badge.rs` — 210 lines)
- Simple `&str` label + `Style` + left/right padding (u16 cells)
- Builder: `Badge::new("OK").with_style(s).with_padding(1, 2)`
- `width()` method returns display width in terminal cells
- Zero-allocation render: draws padding cells + text span directly to Frame
- Tiny-area safe (0 width/height is no-op)
- `is_essential()` returns false (decorative)
- Hash/Eq derived for caching

### Artisanal (`pkgs/artisanal_widgets/lib/src/widgets/components/badge.dart` — 32 lines)
- `Badge(this.label, {background, foreground, padding, textStyle})`
- Uses `Frame` widget + `Text` child (compositional, not direct render)
- Themed via `ThemeScope`
- Configurable colors and padding via `EdgeInsets`

### Gap Analysis
| Feature | Frankentui | Artisanal |
|---------|-----------|-----------|
| Width calculation | `badge.width()` method | Missing |
| Configurable padding per-side | `with_padding(left, right)` | Symmetric `EdgeInsets` only |
| Zero-area safety | Explicit guard | Delegated to Frame |
| Hash/Eq for caching | Derived | Missing |
| `is_essential` flag | Explicit | Missing |

### Recommendation
**Minor enhancement.** Artisanal's Badge is functional but could benefit from:
- Adding a `width()` getter for layout planning
- Per-side padding support (left/right asymmetric)
- The Frankentui approach of zero-allocation rendering is not directly applicable in Flutter's compositional model, so the current Frame+Text approach is correct for Dart

---

## 2. Sparkline

### Frankentui (`ftui-widgets/src/sparkline.rs` — 594 lines)
- 9-level Unicode block chars: `[' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']`
- Builder: `Sparkline::new(&data).min(0).max(100).style(s).gradient(low, high).baseline(0.0)`
- Auto-scaling: computes min/max from data if not explicit
- Color gradient: linear interpolation between two colors based on value
- Baseline support: values ≤ baseline render as empty
- NaN/infinity handling: clamped gracefully
- `MeasurableWidget` trait impl: returns intrinsic size constraints
- Degradation-aware: skips at Skeleton level, no-style at NoStyling
- `render_to_string()` for testing/debugging
- Extensive tests (28 tests)

### Artisanal — Two Layers

**Widget layer** (`pkgs/artisanal_widgets/lib/src/widgets/charting/sparkline_chart.dart` — 276 lines):
- `SparklineChart({values, width, height, style, showGrid, gridStyle, legendEntries, legendPosition, crosshairX/Y, crosshairStyle})`
- LeafRenderObjectWidget with internal `_RenderSparklineChart`
- Legend overlay, crosshair overlay, grid support
- Delegates to `drawSparkline()` renderer

**Renderer layer** (`pkgs/artisanal/lib/src/charting/sparkline.dart` — 102 lines):
- `drawSparkline(screen, area, values, {style, showGrid, gridStyle})`
- Same 8-level block chars (uses 8, Frankentui uses 9 with empty)
- Single-row and multi-row modes
- Data sampling via `sampleSeries()` (up/down-sampling)
- Grid overlay support

### Gap Analysis
| Feature | Frankentui | Artisanal |
|---------|-----------|-----------|
| 9 levels (empty + 8 bars) | Yes (9 chars) | 8 chars only (no empty level) |
| Auto-scaling min/max | Yes | Yes (in renderer) |
| Explicit bounds | `bounds(min, max)` | Not exposed at widget level |
| Color gradient | `gradient(low, high)` | Missing (flat style only) |
| Baseline value | `baseline(f64)` | Hardcoded to 0 |
| NaN/infinity handling | Explicit | Implicit (sampling handles it) |
| Intrinsic size (`measure`) | `MeasurableWidget` trait | `width`/`height` params |
| Legend overlay | No | Yes |
| Crosshair | No | Yes |
| Grid overlay | No | Yes |
| Data sampling | No (raw truncation) | Yes (smart up/down) |
| `render_to_string()` | Yes | Missing |
| Degradation awareness | 4 levels | N/A (no degradation in Dart) |

### Recommendation
**Moderate enhancement.** Artisanal's Sparkline is already more feature-rich (legend, crosshair, grid, sampling). Inspiration from Frankentui:
- Add color gradient support (`gradient(lowColor, highColor)`) — this is a clear gap
- Add configurable baseline (currently hardcoded to 0)
- Add explicit min/max bounds at the widget API level
- Add the 9th "empty" level for values at/below baseline
- The `MeasurableWidget` pattern doesn't translate directly to Flutter's layout, but the concept of intrinsic sizing is already handled via `width`/`height` params

---

## 3. StatusLine / StatusItem

### Frankentui (`ftui-widgets/src/status_line.rs` — 640 lines)
- `StatusItem` enum: `Text(&str)`, `Spinner(usize)`, `Progress {current, total}`, `KeyHint {key, action}`, `Spacer`
- `StatusLine` builder with left/center/right regions
- Custom separator between items (default " ")
- Spacer expands to fill available space (evenly distributed)
- Background fill across entire area
- `is_essential()` returns true (always renders)
- Center region auto-centers in available space between left and right
- Graceful truncation when area is too narrow
- Braille spinner frames (10 frames: ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏)
- Progress shows as "N%" format
- Extensive tests (30 tests)

### Artisanal (`pkgs/artisanal_widgets/lib/src/widgets/components/status_bar.dart` — 91 lines)
- `StatusBar({items, leading, trailing, background, foreground, padding, separator, gap})`
- Takes `List<Widget>` items (typically `KeyHint` widgets)
- Simple Row-based layout with leading/trailing slots
- Gap or separator between items
- Themed via `StatusBarThemeData`

### Gap Analysis
| Feature | Frankentui | Artisanal |
|---------|-----------|-----------|
| Left/center/right regions | Yes (3 regions) | leading/trailing only (no center) |
| Item types (enum) | Text, Spinner, Progress, KeyHint, Spacer | Generic `List<Widget>` |
| Spacer/flexible space | Yes (distributes evenly) | Missing |
| Center auto-positioning | Yes (centers between left/right) | Missing |
| Background fill | Explicit fill loop | Via Container |
| Essential flag | `is_essential() -> true` | Missing |
| Spinner integration | Built-in braille frames | Separate widget |
| Progress display | Built-in "N%" format | Separate widget |
| Graceful truncation | Priority-based | Delegated to Row |

### Recommendation
**Significant new functionality.** Artisanal's StatusBar is a basic Row wrapper. Frankentui's StatusLine is substantially more capable:
- **Port the 3-region layout** (left/center/right) — this is the most valuable feature
- **Port the Spacer concept** — flexible space distribution between items
- **Port the StatusItem enum** pattern — even as a convenience layer, having typed items (Text, KeyHint, Progress, Spinner) provides a cleaner API than raw Widget list
- The center region auto-positioning is particularly useful for editor-style status bars (e.g., mode on left, filename center, position right)

---

## 4. DecisionCard

### Frankentui (`ftui-widgets/src/decision_card.rs` — 536 lines)
- 4 progressive-disclosure levels:
  - **Level 0** (Traffic Light): Green/Yellow/Red badge + action label
  - **Level 1** (Plain English): + one-sentence explanation
  - **Level 2** (Evidence Terms): + Bayes factor terms with direction (+/-/~)
  - **Level 3** (Full Bayesian): + log-posterior, CI, expected loss
- Traffic-light color palette (green/yellow/red with fg+bg pairs)
- Bordered card with configurable border type (Square, Rounded, Double, Heavy, ASCII)
- Evidence rendering: supporting/opposing/neutral with color coding
- Bayesian details: horizontal rule separator + stats line
- `min_height()` computes minimum height for current disclosure level
- Degradation-aware (skips decorative borders at reduced budget)
- Depends on `ftui_runtime::transparency::{Disclosure, DisclosureLevel, EvidenceDirection, TrafficLight}` types

### Artisanal
**Does not exist.** Building blocks available:
- `Card` (42 lines) — basic bordered frame with padding
- `PanelBox` (74 lines) — titled panel with actions and divider
- `Badge` (32 lines) — compact label widget

### Recommendation
**New widget — high value.** This is a unique, well-designed widget that doesn't exist in Artisanal. However, it's tightly coupled to Frankentui's Bayesian decision engine (`Disclosure`, `TrafficLight`, etc.).

**Porting approach:**
- Extract the progressive-disclosure rendering pattern (4 levels, each adding more detail)
- Decouple from Frankentui's specific `Disclosure` type — use a generic data class:
  ```dart
  class DecisionData {
    final DecisionSignal signal; // green/yellow/red
    final String actionLabel;
    final String? explanation;
    final List<EvidenceTerm>? evidence;
    final BayesianDetails? bayesianDetails;
  }
  ```
- Reuse Artisanal's `Card` for the bordered container
- Reuse Artisanal's `Badge` for the traffic-light badge
- The evidence direction coloring (+ green, - red, ~ gray) is a clean pattern worth porting

---

## 5. HistoryPanel / HistoryEntry

### Frankentui (`ftui-widgets/src/history_panel.rs` — 829 lines)
- `HistoryEntry {description, is_redo}` — single entry in history
- `HistoryPanelMode` enum: `Compact` (default) / `Full`
- Builder: `HistoryPanel::new().with_undo_items(&[...]).with_redo_items(&[...]).with_title("History")`
- Dual-stack display: undo items (above marker) + redo items (below marker)
- Current position marker: centered separator line ("─── current ───")
- Compact mode: limits items with "..." overflow indicators
- Configurable icons: undo icon ("↶ "), redo icon ("↷ ")
- Styles: title, undo, redo, marker, background (5 separate Style slots)
- Background fill across entire area
- `is_empty()`, `len()`, accessors for undo/redo items
- Extensive tests (40+ tests)

### Artisanal
**Does not exist.** Building blocks available:
- `PanelBox` (74 lines) — titled panel container
- `Card` (42 lines) — bordered card
- `DataTable` — tabular data display
- `ListTile` — list entry widget

### Recommendation
**New widget — medium value.** The dual-stack undo/redo visualization is a clean, reusable pattern.

**Porting approach:**
- Create `HistoryEntry` data class with `description` and `isRedo` fields
- Create `HistoryPanel` widget with:
  - `undoItems` and `redoItems` lists
  - Configurable `title` (default "History")
  - `mode` enum: compact/full
  - `compactLimit` (default 5)
  - Configurable marker text and styles
- Build on `PanelBox` for the titled container
- The compact mode ellipsis ("... (N more)") is a nice UX touch
- The centered marker separator is the key visual feature

---

## Summary: Porting Priority

| Widget | Status | Priority | Effort | Action |
|--------|--------|----------|--------|--------|
| **Badge** | Exists | Low | Small | Add `width()` getter, per-side padding |
| **Sparkline** | Exists | Medium | Medium | Add gradient, baseline, explicit bounds |
| **StatusLine** | Partial (StatusBar) | **High** | Medium | Port 3-region layout, Spacer, typed items |
| **DecisionCard** | Missing | **High** | Large | New widget, decouple from Frankentui types |
| **HistoryPanel** | Missing | Medium | Medium | New widget, build on PanelBox |

### Recommended Order
1. **StatusLine** — Most immediately useful, clear API improvement over StatusBar
2. **DecisionCard** — Unique capability, high value for agent/AI UIs
3. **Sparkline enhancements** — Incremental improvements to existing widget
4. **HistoryPanel** — Nice to have, lower urgency
5. **Badge** — Minor polish
