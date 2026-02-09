/// Animation system for nocterm.
///
/// This library provides a complete animation system similar to Flutter's,
/// including:
///
/// * [AnimationController] - The core controller for driving animations
/// * [Animation] - Base class for all animations
/// * [Tween] - Interpolation between values
/// * [Curve] - Timing curves for animations
/// * [Ticker] - Frame callbacks for animations
/// * [AnimatedBuilder] - Widget that rebuilds when an animation changes
///
/// ## Getting Started
///
/// To use animations in your component, first add the
/// [SingleTickerProviderStateMixin] to your State class:
///
/// ```dart
/// class _MyComponentState extends State<MyComponent>
///     with SingleTickerProviderStateMixin {
///   late AnimationController _controller;
///   late Animation<double> _animation;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = AnimationController(
///       duration: const Duration(seconds: 1),
///       vsync: this,
///     );
///     _animation = CurveTween(curve: Curves.easeInOut).animate(_controller);
///     _controller.forward();
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Component build(BuildContext context) {
///     return AnimatedBuilder(
///       animation: _animation,
///       builder: (context, child) {
///         // Use _animation.value to drive your UI
///         return SomeComponent(opacity: _animation.value);
///       },
///     );
///   }
/// }
/// ```
library;

export 'animation.dart';
export 'animated_builder.dart';
export 'curves.dart';
export 'ticker.dart' hide objectRuntimeType;
export 'ticker_provider.dart';
export 'tween.dart' hide objectRuntimeType;
