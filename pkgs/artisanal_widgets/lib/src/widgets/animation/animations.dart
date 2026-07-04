/// Animation system for artisanal_widgets.
///
/// This library provides curves, tweens, animation controllers, and animated
/// builder widgets that integrate naturally with the TEA (The Elm Architecture)
/// message loop used by artisanal.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal_widgets/widgets.dart';
///
/// class _FadeInState extends State<FadeIn> with AnimationMixin {
///   late AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = createAnimationController(
///       duration: const Duration(milliseconds: 300),
///     );
///     _controller.addListener(() => setState(() {}));
///   }
///
///   @override
///   Cmd? handleInit() => _controller.forward();
///
///   @override
///   Widget build(BuildContext context) {
///     if (_controller.value < 0.01) return SizedBox.shrink();
///     return widget.child;
///   }
/// }
/// ```
///
/// ## Key Concepts
///
/// - **AnimationController**: TEA-native animation driver. Returns [Cmd]s
///   instead of relying on `SchedulerBinding`.
/// - **AnimationMixin**: Convenience mixin for [State] that auto-dispatches
///   [AnimationTickMsg] to registered controllers.
/// - **Curves**: Standard easing curves (ease, easeIn, easeOut, bounceIn, etc.)
/// - **Tween**: Interpolation between begin/end values of any type.
/// - **AnimatedBuilder** / **ListenableBuilder**: Widgets that rebuild when a
///   [Listenable] (typically an animation) notifies.
library;

export 'animation.dart';
export 'animation_controller.dart';
export 'animation_mixin.dart';
export 'animation_tick.dart';
export 'animated_builder.dart';
export 'curves.dart';
export 'listenable.dart';
export 'tween.dart';
export 'implicitly_animated.dart';
export 'timeline.dart';
export 'spinner_controller.dart';
