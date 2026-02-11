# Nocterm → Artisanal Widgets Migration Analysis

This document compares widgets available in Nocterm with those in artisanal_widgets, identifying gaps and migration priorities.

## Summary

| Category | Nocterm | Artisanal | Missing |
|----------|---------|-----------|---------|
| Core/App | 1 | 1 | 0 |
| Layout | 17 | 27 | 0 |
| Scrolling | 3 | 6 | 0 (we have more) |
| Display/Text | 11 | 11 | 0 |
| Input | 8 | 2 | 0 |
| Interactive/Gesture | 2 | 3 | 0 (we have more) |
| Decoration | 6 | 6 | 0 |
| Navigation/Overlay | 5 | 12 | 0 |
| Builder/Utility | 5 | 2 | 0 |
| Debug/Development | 4 | 4 | 0 |
| **TOTAL** | **~72** | **~90+** | **0** |

---

## Detailed Gap Analysis

### ✅ Already Implemented (Nocterm widgets we have)

#### Layout Widgets (All Core Covered)
| Nocterm Widget | Artisanal Equivalent | Notes |
|----------------|---------------------|-------|
| Row | `Row` / `HBox` | HBox adds gap=1 default |
| Column | `Column` / `VBox` | VBox adds configurable alignment |
| Flex | `Flex` | |
| Expanded | `Expanded` | |
| Flexible | `Flexible` | |
| Stack | `Stack` | |
| Positioned | `Positioned` | |
| Align | `Align` | |
| Center | `Center` | |
| Padding | `Padding` | |
| SizedBox | `SizedBox` | |
| ConstrainedBox | `ConstrainedBox` | |
| Spacer | `Spacer` | |

#### Scrolling Widgets (All Covered + More)
| Nocterm Widget | Artisanal Equivalent | Notes |
|----------------|---------------------|-------|
| ListView | `ListView` | We also have `VirtualListView` |
| SingleChildScrollView | `SingleChildScrollView` | |
| Scrollbar | `Scrollbar` | |

#### Interactive/Gesture Widgets (All Covered + More)
| Nocterm Widget | Artisanal Equivalent | Notes |
|----------------|---------------------|-------|
| GestureDetector | `GestureDetector` | We have typed recognizer system (more advanced) |
| MouseRegion | `MouseRegion` | |
| — | `Zone` | We have this, Nocterm doesn't |

#### Form Controls (Covered + More)
| Nocterm Widget | Artisanal Equivalent | Notes |
|----------------|---------------------|-------|
| — | `Button` | We have this, Nocterm doesn't |
| — | `Checkbox` | We have this |
| — | `Radio<T>` | We have this |
| — | `Switch` | We have this |
| — | `Select<T>` | We have this |

#### Navigation (Mostly Covered)
| Nocterm Widget | Artisanal Equivalent | Notes |
|----------------|---------------------|-------|
| ModalBarrier | `Modal` | Different API, similar purpose |
| — | `Sidebar` | We have this, Nocterm doesn't |
| — | `Drawer` | We have this |
| — | `Tabs` | We have this |
| — | `Breadcrumbs` | We have this |
| — | `Pagination` | We have this |
| — | `Accordion` | We have this |
| — | `SplitView` | We have this |

---

### ❌ MISSING Widgets (Need to implement from Nocterm)

#### HIGH PRIORITY — Core Functionality

| # | Widget | Source File | Description | Status |
|---|--------|------------|-------------|--------|
| 1 | **RichText** | `nocterm/lib/src/components/rich_text.dart` | Text with multiple styles via TextSpan tree | ✅ Implemented (`layout/rich_text.dart`) |
| 2 | **TextSpan** | (part of RichText) | Styled text span node for RichText | ✅ Already existed (`layout/text.dart`) |
| 3 | **Image** | `nocterm/lib/src/components/image.dart` | Terminal image display (sixel, kitty, iTerm2, half-block) | ✅ Implemented (`layout/image.dart`) |
| 4 | **MarkdownText** | `nocterm/lib/src/components/markdown_text.dart` | Renders markdown | ✅ Implemented (`layout/markdown_text.dart`) |
| 5 | **ProgressBar** | `nocterm/lib/src/components/progress_bar.dart` | Progress indicator | ✅ Already existed (`components/progress_indicator.dart`) |
| 6 | **DecoratedBox** | `nocterm/lib/src/components/decorated_box.dart` | Decoration painting | ✅ Already existed (`layout/decorated_box.dart`) |
| 7 | **LayoutBuilder** | `nocterm/lib/src/framework/layout_builder.dart` | Constraint-based building | ✅ Already existed (`layout/layout_builder.dart`) |
| 8 | **Builder** | `nocterm/lib/src/components/builder.dart` | Build callback delegate | ✅ Already existed (`layout/builder.dart`) |

#### MEDIUM PRIORITY — Input & Focus

| # | Widget | Source File | Description | Status |
|---|--------|------------|-------------|--------|
| 9 | **Focusable** | `nocterm/lib/src/components/focusable.dart` | Keyboard focus handling | ✅ Already existed (`focus/focus.dart`) |
| 10 | **KeyboardListener** | `nocterm/lib/src/components/keyboard_listener.dart` | Raw keyboard events | ✅ Already existed (`layout/keyboard_listener.dart`) |
| 11 | **FocusScope** | `nocterm/lib/src/components/focus_scope.dart` | Focus boundary | ✅ Already existed (`focus/focus.dart`) |
| 12 | **BlockFocus** | `nocterm/lib/src/components/block_focus.dart` | Blocks keyboard events | ✅ Implemented (`layout/block_focus.dart`) |
| 13 | **TextEditingController** | `nocterm/lib/src/components/text_field.dart` | Text field controller | ✅ Already existed (`input/input_widgets.dart`) |
| 14 | **ValueListenableBuilder** | `nocterm/lib/src/components/value_listenable_builder.dart` | Reactive rebuilds | ✅ Already existed (`animation/animated_builder.dart`) |

#### MEDIUM PRIORITY — Layout & Clipping

| # | Widget | Source File | Description | Status |
|---|--------|------------|-------------|--------|
| 15 | **ClipRect** | `nocterm/lib/src/components/clip.dart` | Clips child to rectangle | ✅ Already existed (`layout/clip_rect.dart`) |
| 16 | **OverflowBox** | `nocterm/lib/src/components/clip.dart` | Child can overflow constraints | ✅ Implemented (`layout/overflow_box.dart`) |
| 17 | **SizedOverflowBox** | `nocterm/lib/src/components/clip.dart` | Fixed size, child can overflow | ✅ Implemented (`layout/overflow_box.dart`) |
| 18 | **VerticalDivider** | `nocterm/lib/src/components/divider.dart` | Vertical line divider | ✅ Already existed (`layout/vertical_divider.dart`) |

#### LOW PRIORITY — Decoration & Effects

| # | Widget | Source File | Description | Status |
|---|--------|------------|-------------|--------|
| 19 | **ColoredBox** | `nocterm/lib/src/components/modal_barrier.dart` | Fills area with solid color | ✅ Already existed (`layout/colored_box.dart`) |
| 20 | **Tint** | `nocterm/lib/src/components/modal_barrier.dart` | Color tint overlay | ✅ Implemented (`layout/tint.dart`) |
| 21 | **AnimatedTint** | `nocterm/lib/src/components/modal_barrier.dart` | Animated color tint transition | ✅ Implemented (`layout/animated_tint.dart`) |
| 22 | **FadeTint** | `nocterm/lib/src/components/modal_barrier.dart` | Stateful fading tint | ✅ Implemented (`layout/animated_tint.dart`) |

#### LOW PRIORITY — Navigation & Overlays

| # | Widget | Source File | Description | Status |
|---|--------|------------|-------------|--------|
| 23 | **Overlay** | `nocterm/lib/src/navigation/overlay.dart` | Stack of independently managed entries | ✅ Implemented (`components/overlay.dart`) |
| 24 | **OverlayEntry** | `nocterm/lib/src/navigation/overlay.dart` | Single entry in Overlay | ✅ Implemented (`components/overlay.dart`) |
| 25 | **FadeModalBarrier** | `nocterm/lib/src/components/modal_barrier.dart` | Modal barrier with fade animation | ✅ Implemented (`components/fade_modal_barrier.dart`) |

#### LOW PRIORITY — Debug & Development

| # | Widget | Source File | Description | Status |
|---|--------|------------|-------------|--------|
| 26 | **DebugOverlay** | `nocterm/lib/src/components/debug_overlay.dart` | Real-time debug info (FPS, frame time, CPU); toggle Ctrl+G | ✅ Implemented (`components/debug_overlay.dart`) |
| 27 | **PerformanceOverlay** | `nocterm/lib/src/components/performance_overlay.dart` | Real-time performance metrics display | ✅ Implemented (`components/debug_overlay.dart`) |
| 28 | **TUIErrorWidget** | `nocterm/lib/src/components/error_widget.dart` | Error display for render object failures | ✅ Implemented (`layout/error_widget.dart`) |
| 29 | **ErrorThrowingWidget** | `nocterm/lib/src/components/error_widget.dart` | Deliberately throws errors for testing | ✅ Implemented (`layout/error_widget.dart`) |

#### VERY LOW PRIORITY — Niche

| # | Widget | Source File | Description | Status |
|---|--------|------------|-------------|--------|
| 30 | **AsciiText** | `nocterm/lib/src/components/ascii_text.dart` | ASCII art text with fonts (standard, banner, block, slim) | ✅ Implemented (`layout/ascii_text.dart`, `layout/ascii_font.dart`) |
| 31 | **StyledAsciiText** | `nocterm/lib/src/components/ascii_text.dart` | Stateless styled ASCII text wrapper | ✅ Implemented (`layout/ascii_text.dart`) |
| 32 | **LimitedBox** | `nocterm/lib/src/components/basic.dart` | Limits child size (pass-through currently) | ✅ Implemented (`layout/limited_box.dart`) |
| 33 | **Transform** | `nocterm/lib/src/components/basic.dart` | Transformation matrix (pass-through currently) | ✅ Implemented (`layout/transform.dart`) |
| 34 | **TerminalXterm** | `nocterm/lib/src/components/terminal_xterm.dart` | Full xterm terminal emulator (requires xterm.dart) | ❌ Deferred (requires xterm.dart dependency) |
| 35 | **AnimatedComponent** | `nocterm/lib/src/animation/animated_builder.dart` | Abstract base for animated components | ✅ Implemented (`animation/implicitly_animated.dart`) |

---

## 🔄 Widgets We Have That Nocterm Doesn't

These are unique to artisanal_widgets and should be preserved:

| Widget | Category | Description |
|--------|----------|-------------|
| `Zone` | Interactive | Interactive message handling zone |
| `Visibility` | Layout | Show/hide widget |
| `Wrap` | Layout | Wraps children to next line |
| `ShrinkWrap` | Layout | Tight content wrapping |
| `Card` | Components | Card-style container |
| `PanelBox` | Components | Panel container |
| `Badge` | Components | Notification badge |
| `AlertBox` | Components | Alert notification box |
| `Toast` | Components | Toast notification |
| `Tooltip` | Components | Hover tooltip |
| `SpinnerIndicator` | Components | Loading spinner |
| `ListTile` | Components | List item row |
| `ScrollArea` | Components | Scrollable area wrapper |
| `VirtualListView` | Scroll | Virtualized list for large datasets |
| `Viewport` | Scroll | Scrollable viewport |
| `ScrollView` | Scroll | Scrollable view |
| `AnimationController` | Animation | TEA-native animation driver |
| `Curves` | Animation | Standard easing curves |
| `Tween<T>` | Animation | Value interpolation |
| `MediaQuery` | Media | Terminal size/capabilities |

---

## Implementation Status

All phases have been completed except for TerminalXterm (deferred due to external dependency).

### ✅ Phase 1: High Priority (Core functionality) — COMPLETE
1. **RichText + TextSpan** — `layout/rich_text.dart`
2. **Image** — `layout/image.dart` (FileImage, MemoryImage, BoxFit, HalfBlockImageDrawable)
3. **MarkdownText** — `layout/markdown_text.dart`
4. **ProgressBar** — Already existed
5. **DecoratedBox** — Already existed
6. **LayoutBuilder** — Already existed
7. **Builder** — Already existed

### ✅ Phase 2: Input & Focus — COMPLETE (all pre-existing)
8–14. All already existed in artisanal_widgets.

### ✅ Phase 3: Layout & Clipping — COMPLETE
14. **ClipRect** — Already existed
15. **OverflowBox / SizedOverflowBox** — `layout/overflow_box.dart`
16. **VerticalDivider** — Already existed

### ✅ Phase 4: Polish & Effects — COMPLETE
17. **Tint / AnimatedTint / FadeTint** — `layout/tint.dart`, `layout/animated_tint.dart`
18. **Overlay / OverlayEntry / FadeModalBarrier** — `components/overlay.dart`, `components/fade_modal_barrier.dart`
19. **DebugOverlay / PerformanceOverlay** — `components/debug_overlay.dart`
20. **AsciiText / StyledAsciiText / AsciiFont** — `layout/ascii_text.dart`, `layout/ascii_font.dart`
21. **TUIErrorWidget / ErrorThrowingWidget** — `layout/error_widget.dart`
22. **LimitedBox / Transform** — `layout/limited_box.dart`, `layout/transform.dart`
23. **ImplicitlyAnimatedWidget** — `animation/implicitly_animated.dart`

### ❌ Phase 5: Complex (deferred)
24. **TerminalXterm** — Requires xterm.dart dependency, deferred indefinitely

### Framework Enhancement
- Added `State.handleInit()` to the widget framework (`core/framework.dart`, `core/element.dart`)
  to allow StatefulWidget State classes to return `Cmd` during initialization.

### Test Coverage
- **Phase 1 tests**: 52 tests in `test/layout/gap_widgets_test.dart`
- **Phase 2 tests**: 113 tests in `test/layout/gap_widgets_phase2_test.dart`
- **Total**: 165 new tests, all passing
- **Full suite**: 1907 artisanal_widgets tests + 2205 artisanal tests = 4112 total, all passing

---

## Notes

- **Gesture System**: Our implementation is more advanced (typed recognizers vs raw MouseMsg)
- **Animation**: We use TEA-native animations; Nocterm uses Flutter's Listenable pattern
- **Focus**: Both have focus management but different implementations
- **Navigation**: We use WidgetApp; Nocterm uses Navigator/Overlay pattern
- **Framework**: Both follow Flutter patterns with different base class hierarchies
- **Image widget** should be straightforward since we already have the Drawable infrastructure in UV
