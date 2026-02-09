# PDR: Scroll Acceleration for nocterm

## Overview

Add macOS-style scroll acceleration to nocterm's scrollable components (ListView, SingleChildScrollView). When enabled, scroll speed increases with rapid scrolling gestures and stays precise for slower movements.

## Motivation

Modern terminal UIs like OpenCode/Crush provide smooth, natural scrolling that mimics native OS behavior. Currently, nocterm scrolls by a fixed 3 lines per wheel event (`list_view.dart:463`), which feels mechanical and doesn't adapt to user intent.

## Current Implementation

**ScrollController** (`lib/src/components/scroll_controller.dart`):
- Manages scroll offset, min/max extent, viewport dimension
- `scrollBy(delta)` - moves by fixed delta
- `scrollUp(lines)` / `scrollDown(lines)` - scroll by N lines (default 1.0)

**RenderListViewport** (`lib/src/components/list_view.dart:456-498`):
- `handleMouseWheel()` scrolls by fixed 3.0 lines on wheel events
- No velocity tracking or acceleration

## Proposed Design

### 1. AcceleratedScrollController

Create a new `AcceleratedScrollController` that extends `ScrollController`:

```dart
class AcceleratedScrollController extends ScrollController {
  AcceleratedScrollController({
    super.initialScrollOffset,
    this.accelerationEnabled = true,
    this.minSpeed = 1.0,
    this.maxSpeed = 20.0,
    this.accelerationFactor = 1.5,
    this.decayRate = 0.85,
  });

  final bool accelerationEnabled;
  final double minSpeed;      // Minimum scroll speed (lines)
  final double maxSpeed;      // Maximum scroll speed (lines)
  final double accelerationFactor;  // How quickly speed builds up
  final double decayRate;     // How quickly speed decays (0-1)

  double _currentVelocity = 0.0;
  DateTime? _lastScrollTime;

  /// Scroll with acceleration based on timing of wheel events
  void scrollWithAcceleration(double direction) {
    final now = DateTime.now();

    if (!accelerationEnabled) {
      scrollBy(direction * minSpeed);
      return;
    }

    // Calculate time since last scroll
    final timeDelta = _lastScrollTime != null
        ? now.difference(_lastScrollTime!).inMilliseconds
        : 1000;
    _lastScrollTime = now;

    // Rapid scrolling (< 100ms between events) builds velocity
    // Slow scrolling (> 300ms) resets to base speed
    if (timeDelta < 100) {
      // Accelerate
      _currentVelocity = (_currentVelocity * accelerationFactor)
          .clamp(minSpeed, maxSpeed);
    } else if (timeDelta > 300) {
      // Reset to minimum
      _currentVelocity = minSpeed;
    } else {
      // Decay velocity
      _currentVelocity = (_currentVelocity * decayRate)
          .clamp(minSpeed, maxSpeed);
    }

    scrollBy(direction * _currentVelocity);
  }
}
```

### 2. Update handleMouseWheel in Scrollable Components

Modify `RenderListViewport.handleMouseWheel()` to use acceleration:

```dart
@override
bool handleMouseWheel(MouseEvent event) {
  if (_scrollDirection == Axis.vertical) {
    final direction = event.button == MouseButton.wheelUp ? -1.0 : 1.0;
    final effectiveDirection = _reverse ? -direction : direction;

    if (_controller is AcceleratedScrollController) {
      (_controller as AcceleratedScrollController)
          .scrollWithAcceleration(effectiveDirection);
    } else {
      _controller.scrollBy(effectiveDirection * 3.0);
    }
    return true;
  }
  // ... horizontal handling
}
```

### 3. Configuration

Add a global configuration option:

```dart
/// Global scroll configuration
class ScrollConfiguration {
  static bool accelerationEnabled = true;
  static double minSpeed = 1.0;
  static double maxSpeed = 15.0;
  static double accelerationFactor = 1.4;
  static double decayRate = 0.8;
}
```

### 4. Alternative: Smooth Animation Approach

For even smoother scrolling, consider using nocterm's animation system:

```dart
class AnimatedScrollController extends ScrollController {
  AnimationController? _animationController;
  double _targetOffset = 0;

  void animateScrollBy(double delta, {Duration duration = const Duration(milliseconds: 150)}) {
    _targetOffset = (offset + delta).clamp(minScrollExtent, maxScrollExtent);

    // Animate from current to target
    _animationController?.stop();
    _animationController = AnimationController(duration: duration)
      ..addListener(() {
        final t = _animationController!.value;
        jumpTo(lerpDouble(offset, _targetOffset, t)!);
      })
      ..forward();
  }
}
```

## Algorithm Details

The acceleration algorithm uses a simple velocity model:

1. **Time-based acceleration**: Track time between scroll events
2. **Velocity buildup**: Rapid events (< 100ms apart) multiply velocity by `accelerationFactor`
3. **Velocity decay**: Slower events decay velocity by `decayRate`
4. **Bounds clamping**: Velocity stays between `minSpeed` and `maxSpeed`

**Why this works:**
- Fast trackpad swipes generate events ~20-50ms apart → builds to max speed
- Slow deliberate scrolling generates events ~200-400ms apart → stays at min speed
- Deceleration at end feels natural due to decay

**Tunable parameters:**
- `minSpeed`: 1-3 lines (precise control)
- `maxSpeed`: 10-20 lines (rapid navigation)
- `accelerationFactor`: 1.3-1.6 (how quickly it speeds up)
- `decayRate`: 0.7-0.9 (how quickly it slows down)

## Files to Modify

1. **`lib/src/components/scroll_controller.dart`**
   - Add `AcceleratedScrollController` class
   - Add velocity tracking state

2. **`lib/src/components/list_view.dart`**
   - Update `handleMouseWheel()` to use acceleration
   - Pass through acceleration config

3. **`lib/src/components/single_child_scroll_view.dart`**
   - Same updates as ListView

4. **`lib/nocterm.dart`**
   - Export new `AcceleratedScrollController`

5. **New file: `lib/src/components/scroll_configuration.dart`**
   - Global scroll settings

## Testing

1. **Unit tests**: Verify velocity calculations
2. **Manual testing**: Test feel with trackpad and mouse wheel
3. **Edge cases**:
   - Very rapid scrolling doesn't overshoot
   - Slow scrolling stays precise
   - Works in reverse mode
   - Works with lazy and non-lazy ListView

## Backward Compatibility

- Default `ScrollController` behavior unchanged
- Acceleration is opt-in via `AcceleratedScrollController`
- Global `ScrollConfiguration` defaults match current behavior if disabled

## Open Questions

1. Should acceleration be enabled by default?
2. Should we support pixel-level scrolling for terminals that support it (Kitty, Ghostty)?
3. Should there be per-component acceleration settings?

## References

- [OpenCode scroll_acceleration config](https://opencode.ai/docs/tui/)
- [Textual smooth scrolling blog post](https://textual.textualize.io/blog/2025/02/16/smoother-scrolling-in-the-terminal-mdash-a-feature-decades-in-the-making/)
- [Kitty pixel scrolling issue](https://github.com/kovidgoyal/kitty/issues/1123)
