import 'package:artisanal/tui.dart' show Cmd, Msg;

import '../core/framework.dart' show State, StatefulWidget;
import 'animation_controller.dart';
import 'animation_tick.dart';

/// Mixin for [State] classes that host one or more [AnimationController]s.
///
/// Automatically dispatches [AnimationTickMsg] to the correct controller
/// and chains the next frame tick if the animation is still running.
///
/// Controllers created via [createAnimationController] are automatically
/// disposed when the State is disposed. Externally created controllers can
/// be registered with [registerAnimationController] for tick dispatch and
/// automatic disposal.
///
/// ## Usage
///
/// ```dart
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
///     return Opacity(opacity: _controller.value, child: widget.child);
///   }
/// }
/// ```
///
/// ## Multiple controllers
///
/// You can create as many controllers as you need. Each one gets a unique
/// [AnimationController.id] so that tick messages are dispatched correctly:
///
/// ```dart
/// late AnimationController _fadeController;
/// late AnimationController _slideController;
///
/// @override
/// void initState() {
///   super.initState();
///   _fadeController = createAnimationController(
///     duration: const Duration(milliseconds: 300),
///   );
///   _slideController = createAnimationController(
///     duration: const Duration(milliseconds: 500),
///   );
///   _fadeController.addListener(() => setState(() {}));
///   _slideController.addListener(() => setState(() {}));
/// }
///
/// @override
/// Cmd? handleInit() {
///   return Cmd.batch([
///     _fadeController.forward(),
///     _slideController.forward(curve: Curves.easeOut),
///   ]);
/// }
/// ```
mixin AnimationMixin<T extends StatefulWidget> on State<T> {
  final List<AnimationController> _controllers = [];

  /// Creates and registers an [AnimationController].
  ///
  /// The controller is automatically disposed when this State is disposed.
  /// Its tick messages are automatically dispatched by [handleUpdate].
  ///
  /// All parameters are forwarded to [AnimationController.new].
  AnimationController createAnimationController({
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    int fps = 30,
    Object? id,
  }) {
    final controller = AnimationController(
      value: value,
      duration: duration,
      reverseDuration: reverseDuration,
      lowerBound: lowerBound,
      upperBound: upperBound,
      fps: fps,
      id: id,
    );
    _controllers.add(controller);
    return controller;
  }

  /// Registers an externally-created [controller] for tick dispatch and
  /// automatic disposal.
  ///
  /// If the controller is already registered this is a no-op.
  void registerAnimationController(AnimationController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  /// Unregisters a [controller] so it no longer receives tick dispatch
  /// and is no longer automatically disposed.
  ///
  /// Returns `true` if the controller was found and removed.
  bool unregisterAnimationController(AnimationController controller) {
    return _controllers.remove(controller);
  }

  /// Intercepts [AnimationTickMsg] and dispatches it to the matching
  /// controller via [AnimationController.processTick].
  ///
  /// If the message is an [AnimationTickMsg] whose `controllerId` matches
  /// one of the registered controllers, the tick is processed and the
  /// resulting [Cmd] (which schedules the next tick, or `null` if done)
  /// is returned.
  ///
  /// For all other messages, delegates to `super.handleUpdate`.
  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is AnimationTickMsg) {
      for (final controller in _controllers) {
        if (controller.id == msg.controllerId) {
          // processTick calls notifyListeners internally, which triggers
          // any setState callbacks the user registered — so the widget
          // is already marked dirty by the time we return.
          return controller.processTick(msg.time);
        }
      }
    }
    return super.handleUpdate(msg);
  }

  /// Disposes all registered controllers and clears the list.
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}
