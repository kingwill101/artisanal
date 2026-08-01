# Animation System

Artisanal features a TEA-native animation system designed specifically for the terminal's message-based update loop. Unlike traditional UI frameworks that rely on a tight render loop and global ticker, Artisanal animations are driven by the The Elm Architecture (TEA) lifecycle.

## Core Concepts

### TEA-Native Lifecycle

Animations in Artisanal work by scheduling future messages:

1.  An `AnimationController` is started, returning a `Cmd` that schedules a tick.
2.  The TEA loop delivers an `AnimationTickMsg` to the component's `handleUpdate` method.
3.  The controller processes the tick, updates its value, and returns a new `Cmd` to schedule the *next* frame.
4.  This cycle continues until the animation completes, self-terminating by not returning a new `Cmd`.

### AnimationController

The `AnimationController` manages the state of a single value (usually 0.0 to 1.0) over time.

```dart
final controller = AnimationController(
  duration: const Duration(milliseconds: 300),
  fps: 30, // Target frames per second
);

// Start the animation (returns a Cmd)
final cmd = controller.forward();
```

Key features of `AnimationController`:
- **Directional Playback**: `forward()`, `reverse()`, `animateTo()`, `animateBack()`.
- **Indefinite Loops**: `repeat()` with optional `reverse` (ping-pong) mode.
- **Custom Ranges**: Define `lowerBound` and `upperBound`.
- **Status Tracking**: Listen for status changes (dismissed, forward, reverse, completed).

### AnimationMixin

Integrating animations into a `StatefulWidget` is simplified using `AnimationMixin`. It automatically handles:
- Correctly dispatching `AnimationTickMsg` to the right controller.
- Chaining the next frame's `Cmd`.
- Automatic disposal of controllers when the widget is removed.

```dart
class _MyState extends State<MyWidget> with AnimationMixin {
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = createAnimationController(duration: const Duration(seconds: 1));
    _fade.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() => _fade.forward();

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: _fade.value, child: Text('Hello'));
  }
}
```

### AnimatedBuilder

`AnimatedBuilder` rebuilds a subtree whenever an `Animation` changes value,
keeping the rebuild scope small. Pass an `animation` and a `builder`; the
optional `child` subtree is built once and handed to the builder so the static
parts are not recreated on every tick.

```dart
class FadeLabel extends StatefulWidget {
  final String text;
  const FadeLabel(this.text, {super.key});

  @override
  State createState() => _FadeLabelState();
}

class _FadeLabelState extends State<FadeLabel> with AnimationMixin {
  late final AnimationController _ctrl = createAnimationController(
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    // `child` is the static subtree — built once, not per-tick.
    return AnimatedBuilder(
      animation: _ctrl,
      child: Text(widget.text),
      builder: (context, child) =>
          Opacity(opacity: _ctrl.value, child: child),
    );
  }
}
```

`ListenableBuilder` and `ValueListenableBuilder` are structurally identical
but accept a `Listenable` / `ValueListenable` instead of an `Animation`,
making them useful for any change-notifier source beyond `AnimationController`.

### ImplicitlyAnimated Widgets

`ImplicitlyAnimatedWidget` (and its companion `AnimatedWidgetBaseState`)
provide a higher-level pattern for widgets that animate to a **new target
value** whenever a property changes, without the caller having to create or
manage a controller.

```dart
class AnimatedOpacity extends ImplicitlyAnimatedWidget {
  final double opacity;
  final Widget child;

  const AnimatedOpacity({
    required this.opacity,
    required this.child,
    super.duration = const Duration(milliseconds: 300),
    super.curve = Curves.easeInOut,
    super.key,
  });

  @override
  AnimatedWidgetBaseState<AnimatedOpacity> createState() =>
      _AnimatedOpacityState();
}

class _AnimatedOpacityState
    extends AnimatedWidgetBaseState<AnimatedOpacity> {
  Tween<double>? _opacity;

  @override
  void forEachTween(TweenVisitor visitor) {
    _opacity = visitor(
      _opacity,
      widget.opacity,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) =>
      Opacity(opacity: _opacity!.evaluate(animation), child: widget.child);
}
```

**How it works:**

1. Whenever a property changes, `AnimatedWidgetBaseState` calls `forEachTween`
   to update the tween's `begin` value and reset the controller.
2. The controller runs forward from `begin` to `end` over `duration`.
3. The `build` method reads the current interpolated value via
   `tween.evaluate(animation)`.

This pattern is used by Flutter's built-in `AnimatedOpacity`, `AnimatedAlign`,
and `AnimatedContainer`. Custom implicitly-animated widgets follow the same
shape.

## Animation Timeline

For complex, multi-step animations, the `AnimationTimeline` provides a declarative choreography system.

### Steps

A timeline consists of a series of steps:
- **`forward` / `reverse`**: Run a controller in the specified direction.
- **`animateTo` / `animateBack`**: Move a controller to a specific value.
- **`delay`**: Wait for a duration.
- **`parallel`**: Start multiple steps simultaneously and wait for all to complete.
- **`callback`**: Run arbitrary logic as a step.

### Orchestration Presets

The timeline includes many high-level presets for common patterns:
- **`staggered`**: Run multiple controllers with a fixed gap between starts.
- **`pulse`**: Animate forward, hold, then reverse.
- **`cascade`**: Run a pulse on a list of controllers in sequence.
- **`wave`**: A traveling wave effect (forward sweep, then reverse sweep).
- **`fan`**: Staggered entrance, synchronized exit.
- **`breath`**: All controllers animate forward and reverse together.
- **`ripple`**: Center-origin ripple effect.

```dart
_timeline = AnimationTimeline(
  steps: [
    AnimationTimelineStep.forward(_fade),
    AnimationTimelineStep.delay(const Duration(milliseconds: 80)),
    AnimationTimelineStep.parallel([
      AnimationTimelineStep.forward(_slide),
      AnimationTimelineStep.forward(_scale),
    ]),
  ],
  repeat: true,
  alternate: true,
);
```

## Curves and Tweens

### Curves

Curves control the rate of change over time. Artisanal includes a comprehensive set of standard curves:
- `linear`, `decelerate`, `easeIn`, `easeOut`, `easeInOut`.
- `elasticIn`, `elasticOut`, `bounceIn`, `bounceOut`, etc.
- Custom `Cubic` Bezier curves.
- `Interval` for applying a curve to a sub-range of an animation.

### Tweens

Tweens interpolate between two values.
- `IntTween`, `DoubleTween`, `ColorTween`, `RectTween`.
- Chain tweens using `.chain(CurveTween(...))`.

## Visual Effects (UV)

The `ultraviolet` package provides post-processing effects that can be applied to rendered buffers. These are often driven by animations.

### ColorMatrix

A 4x5 RGBA color matrix for transforming cell styles.
- **Grayscale**: `ColorMatrix.grayscale()`.
- **Invert**: `ColorMatrix.invert()`.
- **Tint**: `ColorMatrix.tint(color, amount: 0.5)`.
- **Gain/Attenuation**: Scale RGB brightness.

### CRT & Terminal Filters

Composite filters that simulate vintage hardware:
- **`PhosphorFilter`**: Classic green phosphor monitor.
- **`AmberTerminalFilter`**: Warm monochrome display.
- **`CrtFilter`**: Scanlines, vignette, and slight wave distortion.
- **`GhostingFilter`**: Temporal persistence (afterimage trails).

```dart
// Apply a CRT effect with persistence
final filter = CrtTrailFilter(
  scanline: 0.1,
  persistence: 0.32,
);
```
