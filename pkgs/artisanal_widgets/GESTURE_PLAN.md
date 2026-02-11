# Gesture System Implementation Plan for artisanal_widgets

## Overview

This plan describes how to bring proper gesture recognition infrastructure to
`artisanal_widgets`, modelled after the nocterm `gestures/` module. The goal is
to move from the current monolithic inline gesture handling inside
`GestureDetector` to a structured recognizer-based system that supports tap,
double-tap, long-press, and drag gestures with proper arena-based conflict
resolution.

The old `GestureCallback = Cmd? Function(MouseMsg msg)` typedef is **removed
entirely** — this is a breaking change. All call sites (components, examples,
tests) are migrated in the same pass.

---

## Current State

### What exists in artisanal_widgets today

| File | What it provides |
|------|-----------------|
| `layout/gesture_detector.dart` | `GestureDetector` StatefulWidget with inline gesture logic. Callbacks: `onTapDown`, `onTapUp`, `onTap`, `onEnter`, `onExit`, `onDragStart`, `onDragUpdate`, `onDragEnd`, `onWheel`. All callbacks are `GestureCallback = Cmd? Function(MouseMsg msg)`. |
| `layout/mouse_region.dart` | Thin `StatelessWidget` wrapper around `GestureDetector` exposing only `onEnter`/`onExit`. Also typed as `GestureCallback`. |
| `layout/geometry.dart` | `Offset`, `Size`, `Rect`, `BoxConstraints`, `HitTestEntry`, `HitTestResult`. |
| `rendering/render_object.dart` | `RenderObject` base with `hitTest(result, localX, localY)`. Always adds itself — no behaviour control. |
| `core/element.dart` | `ElementTree.hitTestAt()` maps render-object hits back to elements. `HitTestElementEntry`. |
| `app/widget_app.dart` | Dispatches `HitTestMouseMsg` via `dispatchBubbleUp`. Supports mouse capture for drags. |

### Key architectural facts

- artisanal_widgets uses a **TEA (The Elm Architecture)** pattern: `State.handleUpdate(Msg) → Cmd?`.
- Mouse events arrive as `MouseMsg` (from `package:artisanal/tui.dart`) with `MouseAction` (press/release/motion/wheel) and `MouseButton`.
- Hit-test dispatch wraps `MouseMsg` in `HitTestMouseMsg` with local coordinates.
- Callbacks return `Cmd?` — this is different from nocterm/Flutter where callbacks are `void`.
- Mouse capture is done at the element level (`element.captureMouse()`/`releaseMouse()`).

### What's missing

1. No gesture recognizer abstraction (all logic inline in `_GestureDetectorState._handleInBounds`).
2. No gesture arena for conflict resolution.
3. No `HitTestBehavior` (deferToChild / opaque / translucent).
4. No double-tap support.
5. No long-press support.
6. No `onTapCancel` callback.
7. No structured detail objects (`TapDownDetails`, etc.) — callbacks receive raw `MouseMsg`.
8. No dedicated mouse tracker infrastructure for enter/exit/hover lifecycle.

---

## Reference: nocterm gestures module

```
nocterm/lib/src/gestures/
├── events.dart       # TapDownDetails, TapUpDetails, LongPressStartDetails,
│                     # LongPressEndDetails, typed callback signatures
├── hit_test.dart     # HitTestBehavior enum
├── recognizer.dart   # GestureRecognizer base, GestureRecognizerState,
│                     # GestureDisposition, GestureArenaManager
├── tap.dart          # TapGestureRecognizer, DoubleTapGestureRecognizer
└── long_press.dart   # LongPressGestureRecognizer
```

nocterm's `components/gesture_detector.dart`:
- Creates recognizer instances in `_syncRecognizers()`.
- Has a `_RenderGestureDetector` that extends `RenderMouseRegion` and tracks
  button-state transitions, feeding events to recognizers.
- Exposes `HitTestBehavior` on the widget.

nocterm's mouse tracking:
- `MouseTrackerAnnotation` binds callbacks to render objects with validity tracking.
- `MouseTracker` dispatches enter/exit/hover events based on hit-test results.
- `MouseTrackerAnnotationProvider` mixin for render objects.

---

## Implementation Plan

### Phase 1: Gesture Detail Classes & Callback Types

**New file:** `lib/src/widgets/gestures/events.dart`

Create structured detail objects that carry both global and local position
information, plus modifier key state from the original `MouseMsg`.

```
TapDownDetails
  - globalPosition: Offset
  - localPosition: Offset
  - button: MouseButton
  - modifiers (ctrl, alt, shift)

TapUpDetails
  - globalPosition: Offset
  - localPosition: Offset

LongPressStartDetails
  - globalPosition: Offset
  - localPosition: Offset

LongPressEndDetails
  - globalPosition: Offset
  - localPosition: Offset

DragStartDetails
  - globalPosition: Offset
  - localPosition: Offset
  - button: MouseButton

DragUpdateDetails
  - globalPosition: Offset
  - localPosition: Offset
  - delta: Offset (change since last update)

DragEndDetails
  - globalPosition: Offset
  - localPosition: Offset
```

Typed callback signatures (TEA-compatible, returning `Cmd?`):

```
typedef GestureTapDownCallback    = Cmd? Function(TapDownDetails details);
typedef GestureTapUpCallback      = Cmd? Function(TapUpDetails details);
typedef GestureTapCallback        = Cmd? Function();
typedef GestureTapCancelCallback  = Cmd? Function();
typedef GestureDoubleTapCallback  = Cmd? Function();
typedef GestureLongPressCallback  = Cmd? Function();
typedef GestureLongPressStartCallback = Cmd? Function(LongPressStartDetails);
typedef GestureLongPressEndCallback   = Cmd? Function(LongPressEndDetails);
typedef GestureDragStartCallback  = Cmd? Function(DragStartDetails details);
typedef GestureDragUpdateCallback = Cmd? Function(DragUpdateDetails details);
typedef GestureDragEndCallback    = Cmd? Function(DragEndDetails details);
typedef GestureWheelCallback      = Cmd? Function(MouseMsg msg);
typedef MouseEnterCallback        = Cmd? Function(MouseMsg msg);
typedef MouseExitCallback         = Cmd? Function(MouseMsg msg);
```

> **Design note:** These callbacks return `Cmd?` to fit the TEA architecture.
> nocterm's equivalents are `void Function(...)`. The recognizers themselves
> will not return commands — instead, the `_GestureDetectorState` will collect
> pending commands from callbacks and return them from `handleUpdate`.

**Barrel file:** `lib/src/widgets/gestures/gestures.dart`

Exports all gesture-related files for clean imports.

---

### Phase 2: HitTestBehavior

**New file:** `lib/src/widgets/gestures/hit_test.dart`

```
enum HitTestBehavior {
  /// Only receives events if a child is hit.
  deferToChild,

  /// Receives events within bounds; blocks targets behind.
  opaque,

  /// Receives events within bounds; allows targets behind to also receive.
  translucent,
}
```

This will later be used by:
- `GestureDetector` widget (as a constructor parameter).
- `RenderObject.hitTest` (to decide whether to add self to result).

---

### Phase 3: Gesture Recognizer Framework

**New file:** `lib/src/widgets/gestures/recognizer.dart`

```
enum GestureRecognizerState { ready, possible, defunct }
enum GestureDisposition { accepted, rejected }

abstract class GestureRecognizer {
  GestureRecognizerState state;
  Offset? initialPosition;

  void addPointer(MouseMsg event, Offset localPosition);
  void handlePointerDown(MouseMsg event, Offset localPosition);
  void handlePointerUp(MouseMsg event, Offset localPosition);
  void handlePointerMove(MouseMsg event, Offset localPosition);
  void acceptGesture();
  void rejectGesture();
  void resolve(GestureDisposition disposition);
  void reset();
  void dispose();
}
```

> **Adaptation for TEA:** Recognizers invoke their typed callbacks directly.
> The `_GestureDetectorState` holds a `List<Cmd>` accumulator. When a
> recognizer fires a callback (e.g. `onTap?.call()`) the callback returns
> a `Cmd?` which gets added to the accumulator. After all recognizers have
> processed the pointer event, the state returns `Cmd.batch(accumulated)`.

```
class GestureArenaManager {
  Map<int, List<GestureRecognizer>> arenas;

  int createArena();
  void add(int arenaId, GestureRecognizer recognizer);
  void close(int arenaId);   // resolve: first-possible wins
  void sweep(int arenaId);   // alias for close
}
```

> **Simplification:** For the initial implementation the arena can use
> nocterm's "first recognizer in `possible` state wins" strategy. A more
> sophisticated approach (scoring, hold-off timers) can be added later.

---

### Phase 4: Tap Recognizers

**New file:** `lib/src/widgets/gestures/tap.dart`

#### TapGestureRecognizer

```
class TapGestureRecognizer extends GestureRecognizer {
  GestureTapDownCallback? onTapDown;
  GestureTapUpCallback? onTapUp;
  GestureTapCallback? onTap;
  GestureTapCancelCallback? onTapCancel;

  static const double _kTouchSlop = 2.0; // cells
}
```

Lifecycle:
1. `handlePointerDown` → record position, call `onTapDown`.
2. `handlePointerMove` → if delta > slop → reject (call `onTapCancel`).
3. `handlePointerUp` → if within slop → call `onTapUp`, then `onTap`.
4. Arena acceptance auto-fires `onTap` if not yet fired.

#### DoubleTapGestureRecognizer

```
class DoubleTapGestureRecognizer extends GestureRecognizer {
  GestureDoubleTapCallback? onDoubleTap;

  static const Duration _doubleTapTimeout = Duration(milliseconds: 300);
  static const double _kDoubleTapSlop = 2.0;
}
```

Lifecycle:
1. First pointer-down starts a 300 ms timer and records position.
2. Second pointer-down within timeout and slop → fire `onDoubleTap`, reset.
3. Timeout expires → reset (was a single tap only).

---

### Phase 5: Long-Press Recognizer

**New file:** `lib/src/widgets/gestures/long_press.dart`

```
class LongPressGestureRecognizer extends GestureRecognizer {
  GestureLongPressCallback? onLongPress;
  GestureLongPressStartCallback? onLongPressStart;
  GestureLongPressEndCallback? onLongPressEnd;

  Duration duration; // default 500ms
  static const double _kTouchSlop = 2.0;
}
```

Lifecycle:
1. `handlePointerDown` → start timer for `duration`.
2. Timer fires → call `onLongPressStart`, then `onLongPress`.
3. `handlePointerMove` → if delta > slop before timer → cancel timer, reject.
4. `handlePointerUp` → if long press was accepted → call `onLongPressEnd`.

---

### Phase 6: Drag Recognizer

**New file:** `lib/src/widgets/gestures/drag.dart`

This extracts the existing inline drag logic from `GestureDetector` into a
proper recognizer.

```
class DragGestureRecognizer extends GestureRecognizer {
  GestureDragStartCallback? onDragStart;
  GestureDragUpdateCallback? onDragUpdate;
  GestureDragEndCallback? onDragEnd;

  static const double _kDragSlop = 1.0; // cells — start drag after 1 cell move
}
```

Lifecycle:
1. `handlePointerDown` → record initial position, enter `possible` state.
2. `handlePointerMove` → if delta > drag slop → accept gesture, call
   `onDragStart`, then `onDragUpdate` with delta. Subsequent moves call
   `onDragUpdate`.
3. `handlePointerUp` → call `onDragEnd`, reset.

> **Note:** Drag and tap compete in the arena. If the pointer moves beyond
> slop, the drag recognizer wins and the tap recognizer is rejected (fires
> `onTapCancel`). If the pointer is released without moving, the tap wins
> and the drag is rejected.

---

### Phase 7: Refactor GestureDetector Widget — BREAKING CHANGE

**Modify:** `lib/src/widgets/layout/gesture_detector.dart`

The old `GestureCallback = Cmd? Function(MouseMsg msg)` typedef is **removed**.
All callbacks use the new typed signatures from `events.dart`. This is a
breaking change that requires updating every call site in the same pass.

#### New API surface

```dart
class GestureDetector extends StatefulWidget {
  GestureDetector({
    required this.child,
    // --- Tap ---
    this.onTapDown,        // GestureTapDownCallback?
    this.onTapUp,          // GestureTapUpCallback?
    this.onTap,            // GestureTapCallback?
    this.onTapCancel,      // GestureTapCancelCallback?
    // --- Double tap ---
    this.onDoubleTap,      // GestureDoubleTapCallback?
    // --- Long press ---
    this.onLongPress,      // GestureLongPressCallback?
    this.onLongPressStart, // GestureLongPressStartCallback?
    this.onLongPressEnd,   // GestureLongPressEndCallback?
    // --- Drag ---
    this.onDragStart,      // GestureDragStartCallback?
    this.onDragUpdate,     // GestureDragUpdateCallback?
    this.onDragEnd,        // GestureDragEndCallback?
    // --- Hover ---
    this.onEnter,          // MouseEnterCallback?
    this.onExit,           // MouseExitCallback?
    // --- Wheel ---
    this.onWheel,          // GestureWheelCallback?
    // --- Behavior ---
    this.behavior = HitTestBehavior.deferToChild,
    this.enabled = true,
    this.captureMouse = true,
    super.key,
  });
}
```

**Removed:**
- `typedef GestureCallback = Cmd? Function(MouseMsg msg)` — deleted.
- `zoneId` parameter — legacy zone-based dispatch is dropped.

#### Internal changes

The `_GestureDetectorState` will:

1. **Create recognizer instances** in `initState()` via `_syncRecognizers()`.
2. **Update recognizer callbacks** in `didUpdateWidget()`.
3. **Dispose recognizers** in `dispose()`.
4. **Route pointer events** to recognizers from `handleUpdate()`:
   - On `HitTestMouseMsg` → determine pointer event type from `MouseAction`,
     build `Offset localPosition`, dispatch to recognizers.
   - On captured `MouseMsg` → dispatch to active drag recognizer.
5. **Collect `Cmd?` results** via a `_pendingCmds` accumulator that recognizer
   callbacks append to. Return `Cmd.batch(_pendingCmds)` from `handleUpdate`.

#### MouseRegion changes

**Modify:** `lib/src/widgets/layout/mouse_region.dart`

```dart
class MouseRegion extends StatelessWidget {
  MouseRegion({
    required this.child,
    this.onEnter,   // MouseEnterCallback?
    this.onExit,    // MouseExitCallback?
    this.enabled = true,
    super.key,
  });
  // ...
}
```

`zoneId` parameter is removed (matches GestureDetector removal).

---

### Phase 8: HitTestBehavior in the Render Layer

**Modify:** `lib/src/widgets/rendering/render_object.dart`

Update `RenderObject.hitTest` to support `HitTestBehavior`:

```dart
bool hitTest(
  HitTestResult result, {
  required double localX,
  required double localY,
  HitTestBehavior behavior = HitTestBehavior.deferToChild,
}) {
  // bounds check...

  bool childHit = false;
  for (var i = children.length - 1; i >= 0; i--) {
    // test children...
    if (child.hitTest(...)) { childHit = true; break; }
  }

  switch (behavior) {
    case HitTestBehavior.deferToChild:
      if (childHit) result.add(HitTestEntry(this, ...));
      return childHit;
    case HitTestBehavior.opaque:
      result.add(HitTestEntry(this, ...));
      return true;
    case HitTestBehavior.translucent:
      result.add(HitTestEntry(this, ...));
      return childHit; // allows siblings behind to also be hit
  }
}
```

> **Note:** The current `hitTest` always adds itself, which is equivalent to
> `opaque` behavior. Changing the default to `deferToChild` could break
> existing hit-testing. We'll keep the current behavior as default and only
> apply the `behavior` parameter when explicitly passed from `GestureDetector`.

---

### Phase 9: Mouse Tracker Infrastructure (Optional / Future)

**New file:** `lib/src/widgets/gestures/mouse_tracker.dart`

This is lower priority but provides a cleaner foundation for enter/exit/hover:

```
class MouseTrackerAnnotation {
  MouseEventCallback? onEnter;
  MouseEventCallback? onExit;
  MouseEventCallback? onHover;
  Object renderObject;
  bool validForMouseTracker = true;
}

class MouseTracker {
  Set<MouseTrackerAnnotation> _hoveredAnnotations;

  void updateAnnotations(HitTestResult result, MouseMsg event);
  void clear(MouseMsg event);
}

mixin MouseTrackerAnnotationProvider {
  MouseTrackerAnnotation? get annotation;
}
```

This would move hover tracking from the current inline approach in
`_GestureDetectorState._handleInBounds` to a centralized tracker that's
updated each frame in `WidgetApp`.

---

## File Structure (Final)

```
lib/src/widgets/gestures/
├── gestures.dart          # barrel file (exports everything below)
├── events.dart            # detail classes + typed callback signatures
├── hit_test.dart          # HitTestBehavior enum
├── recognizer.dart        # GestureRecognizer base, GestureArenaManager
├── tap.dart               # TapGestureRecognizer, DoubleTapGestureRecognizer
├── long_press.dart        # LongPressGestureRecognizer
├── drag.dart              # DragGestureRecognizer
└── mouse_tracker.dart     # MouseTrackerAnnotation, MouseTracker (Phase 9)
```

Update `widgets.dart` to add:
```dart
export 'gestures/gestures.dart';
```

---

## Implementation Order & Dependencies

```
Phase 1: events.dart
  └─ no dependencies (just data classes)

Phase 2: hit_test.dart
  └─ no dependencies (just an enum)

Phase 3: recognizer.dart
  └─ depends on: events.dart (Offset from geometry.dart), MouseMsg from artisanal/tui

Phase 4: tap.dart
  └─ depends on: recognizer.dart, events.dart

Phase 5: long_press.dart
  └─ depends on: recognizer.dart, events.dart

Phase 6: drag.dart
  └─ depends on: recognizer.dart, events.dart

Phase 7: Refactor GestureDetector + migrate all call sites (BREAKING)
  └─ depends on: all of the above
  └─ also modify: mouse_region.dart, all call sites listed below

Phase 8: HitTestBehavior in render layer
  └─ depends on: hit_test.dart
  └─ modify: render_object.dart

Phase 9: Mouse tracker (optional, future)
  └─ depends on: hit_test.dart, geometry.dart
  └─ modify: widget_app.dart
```

Phases 1–2 can be done in parallel.
Phases 4–6 can be done in parallel (all depend on Phase 3).
Phase 7 depends on all recognizer phases.
Phase 8 can be done any time after Phase 2.
Phase 9 is independent and can be deferred.

---

## Breaking Change: Complete Call Site Migration

The old `GestureCallback = Cmd? Function(MouseMsg msg)` is **deleted**. Every
call site that uses `GestureDetector` or `MouseRegion` must be updated in the
same commit as Phase 7. Below is the exhaustive list.

### GestureDetector call sites

#### `lib/src/widgets/components/accordion.dart`

```dart
// BEFORE:
GestureDetector(
  onTap: (_) => onChanged?.call(!expanded),
  child: header,
)

// AFTER:
GestureDetector(
  onTap: () => onChanged?.call(!expanded),
  child: header,
)
```

#### `lib/src/widgets/components/button.dart`

```dart
// BEFORE:
GestureDetector(
  onTapDown: (_) { _setPressed(true); return null; },
  onTapUp: (_) { _setPressed(false); return null; },
  onTap: (_) => _activate(),
  child: result,
)

// AFTER:
GestureDetector(
  onTapDown: (_) { _setPressed(true); return null; },
  onTapUp: (_) { _setPressed(false); return null; },
  onTap: () => _activate(),
  child: result,
)
```

Note: `onTapDown`/`onTapUp` now receive `TapDownDetails`/`TapUpDetails`
instead of `MouseMsg`. The `_` discard pattern still works.

#### `lib/src/widgets/components/checkbox.dart`

```dart
// BEFORE:
GestureDetector(onTap: (_) => _toggle(), child: result)

// AFTER:
GestureDetector(onTap: () => _toggle(), child: result)
```

#### `lib/src/widgets/components/drawer.dart`

```dart
// BEFORE:
GestureDetector(
  onTap: dismissible ? (_) => onDismiss?.call() : null,
  child: ...,
)

// AFTER:
GestureDetector(
  onTap: dismissible ? () => onDismiss?.call() : null,
  child: ...,
)
```

#### `lib/src/widgets/components/modal.dart`

```dart
// BEFORE:
GestureDetector(
  onTap: dismissible ? (_) => onDismiss?.call() : null,
  child: ...,
)

// AFTER:
GestureDetector(
  onTap: dismissible ? () => onDismiss?.call() : null,
  child: ...,
)
```

#### `lib/src/widgets/components/radio.dart`

```dart
// BEFORE:
GestureDetector(onTap: (_) => _select(), child: result)

// AFTER:
GestureDetector(onTap: () => _select(), child: result)
```

#### `lib/src/widgets/components/switch.dart`

```dart
// BEFORE:
GestureDetector(onTap: (_) => _toggle(), child: result)

// AFTER:
GestureDetector(onTap: () => _toggle(), child: result)
```

#### `lib/src/widgets/focus/focus.dart`

```dart
// BEFORE:
GestureDetector(
  onTapDown: (_) { _requestFocus(); return null; },
  child: ...,
)

// AFTER:
GestureDetector(
  onTapDown: (_) { _requestFocus(); return null; },
  child: ...,
)
```

(`_` discard still works — type changes from `MouseMsg` to `TapDownDetails`)

### MouseRegion call sites

All these use `onEnter: (_) { ... }` / `onExit: (_) { ... }` with `_` discard.
The type changes from `GestureCallback` (`Cmd? Function(MouseMsg)`) to
`MouseEnterCallback` / `MouseExitCallback` (same signature `Cmd? Function(MouseMsg)`).
**No code changes needed** for these — only the typedef name changes internally.

Affected files (no edits required at call site):
- `lib/src/widgets/components/button.dart`
- `lib/src/widgets/components/checkbox.dart`
- `lib/src/widgets/components/radio.dart`
- `lib/src/widgets/components/switch.dart`
- `lib/src/widgets/components/tooltip.dart`

### Example call sites

#### `example/main.dart`

```dart
// BEFORE:
GestureDetector(
  key: w.ValueKey<int>(index),
  onTap: (_) { ... },
  child: ...,
)

// AFTER:
GestureDetector(
  key: w.ValueKey<int>(index),
  onTap: () { ... },
  child: ...,
)
```

(Two occurrences in this file.)

#### `example/drag/main.dart`

```dart
// BEFORE:
GestureDetector(
  zoneId: 'slider-track',
  onDragStart: _startSliderDrag,   // Cmd? Function(MouseMsg)
  onDragUpdate: _updateSliderDrag, // Cmd? Function(MouseMsg)
  onDragEnd: _endSliderDrag,       // Cmd? Function(MouseMsg)
  child: ...,
)

// AFTER:
GestureDetector(
  onDragStart: _startSliderDrag,   // Cmd? Function(DragStartDetails)
  onDragUpdate: _updateSliderDrag, // Cmd? Function(DragUpdateDetails)
  onDragEnd: _endSliderDrag,       // Cmd? Function(DragEndDetails)
  child: ...,
)
```

The `_startSliderDrag` / `_updateSliderDrag` / etc. method signatures change:
- `Cmd? _startSliderDrag(MouseMsg msg)` → `Cmd? _startSliderDrag(DragStartDetails d)`
- `Cmd? _updateSliderDrag(MouseMsg msg)` → `Cmd? _updateSliderDrag(DragUpdateDetails d)`
- `Cmd? _endSliderDrag(MouseMsg msg)` → `Cmd? _endSliderDrag(DragEndDetails d)`

These methods currently use `msg.x` for delta calculations. They need to use
`d.globalPosition.dx` or `d.localPosition.dx` (and `d.delta.dx` for updates).

The `zoneId` parameter is removed everywhere.

Two `GestureDetector` usages in this file (slider + splitter).

### Test call sites

#### `test/app_widget_debug_test.dart`

Three `GestureDetector` usages in tab widget state classes:

```dart
// BEFORE:
GestureDetector(
  key: w.ValueKey<int>(i),
  onTap: (_) { setState(() => _selectedTab = i); return null; },
  child: ...,
)

// AFTER:
GestureDetector(
  key: w.ValueKey<int>(i),
  onTap: () { setState(() => _selectedTab = i); return null; },
  child: ...,
)
```

(`_PaddedTabWidgetState`, `_NoPaddingTabWidgetState`, `_ColoredTabWidgetState`)

#### `test/element_tree_test.dart`

```dart
// BEFORE (multiple occurrences):
GestureDetector(onTap: (_) { setState(() => ...); return null; }, child: ...)

// AFTER:
GestureDetector(onTap: () { setState(() => ...); return null; }, child: ...)
```

Affected classes: `_ClickableCounterState`, `_MultiButtonWidgetState`, and
the closure capture tab widget test.

### Complete file list requiring changes

| File | Change type |
|------|------------|
| `lib/src/widgets/layout/gesture_detector.dart` | Rewrite (Phase 7) |
| `lib/src/widgets/layout/mouse_region.dart` | Remove `zoneId`, update callback types |
| `lib/src/widgets/components/accordion.dart` | `onTap: (_) →` → `onTap: () →` |
| `lib/src/widgets/components/button.dart` | `onTap: (_) →` → `onTap: () →` |
| `lib/src/widgets/components/checkbox.dart` | `onTap: (_) →` → `onTap: () →` |
| `lib/src/widgets/components/drawer.dart` | `onTap: (_) →` → `onTap: () →` |
| `lib/src/widgets/components/modal.dart` | `onTap: (_) →` → `onTap: () →` |
| `lib/src/widgets/components/radio.dart` | `onTap: (_) →` → `onTap: () →` |
| `lib/src/widgets/components/switch.dart` | `onTap: (_) →` → `onTap: () →` |
| `lib/src/widgets/focus/focus.dart` | Type change only (discard still works) |
| `example/main.dart` | `onTap: (_) →` → `onTap: () →` (2 sites) |
| `example/drag/main.dart` | Full rewrite of drag callbacks + remove `zoneId` |
| `test/app_widget_debug_test.dart` | `onTap: (_) →` → `onTap: () →` (3 sites) |
| `test/element_tree_test.dart` | `onTap: (_) →` → `onTap: () →` (3+ sites) |

---

## Testing Strategy

### Unit tests for recognizers

Each recognizer should have standalone unit tests that feed synthetic
`MouseMsg` sequences and assert callback invocations:

- **TapGestureRecognizer:** press → release (within slop) → `onTap` fires.
  Press → move beyond slop → `onTapCancel` fires.
- **DoubleTapGestureRecognizer:** two taps within 300ms and 2-cell slop →
  `onDoubleTap` fires. Single tap + timeout → no callback.
- **LongPressGestureRecognizer:** press → hold 500ms → `onLongPress` fires.
  Press → move before timeout → no callback.
- **DragGestureRecognizer:** press → move beyond slop → `onDragStart` +
  `onDragUpdate`. Release → `onDragEnd`.
- **GestureArenaManager:** two recognizers compete; first in `possible` state
  wins, other is rejected.

### Widget integration tests

Use `WidgetTester` to send mouse events and verify:

- `GestureDetector` with `onTap` responds to click.
- `GestureDetector` with `onDoubleTap` responds to double-click.
- `GestureDetector` with `onLongPress` responds to press-and-hold.
- `GestureDetector` with `onDragStart`/`onDragUpdate`/`onDragEnd` works with
  mouse capture.
- `HitTestBehavior.deferToChild` vs `opaque` vs `translucent` correctly
  affects which widgets receive events.

### Test file locations

```
test/gestures/
├── tap_recognizer_test.dart
├── double_tap_recognizer_test.dart
├── long_press_recognizer_test.dart
├── drag_recognizer_test.dart
├── gesture_arena_test.dart
└── gesture_detector_widget_test.dart
```

---

## Open Questions

1. **Timer support:** `DoubleTapGestureRecognizer` and
   `LongPressGestureRecognizer` need `dart:async` `Timer`. Since
   artisanal_widgets runs in a TEA event loop, confirm that timers fire
   correctly within the program's run loop and that `setState` from timer
   callbacks triggers rebuilds. (The existing scroll widgets already use
   timers, so this should be fine.)

2. **Arena scope:** Should each `GestureDetector` widget get its own arena,
   or should overlapping detectors share one? The initial implementation
   gives each widget its own internal arena (matching nocterm). Cross-widget
   arena resolution can be added later if needed.

3. **Modifier keys in details:** Should `TapDownDetails` etc. carry
   `ctrl`/`alt`/`shift` from the original `MouseMsg`? Useful for
   ctrl-click patterns. Included in Phase 1 for `TapDownDetails` at minimum.

4. **Right-click / middle-click:** The current `GestureDetector` only tracks
   left-button drags. Should we add `onSecondaryTap` / `onSecondaryTapDown`
   (like Flutter) for right-click context menus? Deferred to a future phase
   but the recognizer framework should not hardcode `MouseButton.left`.