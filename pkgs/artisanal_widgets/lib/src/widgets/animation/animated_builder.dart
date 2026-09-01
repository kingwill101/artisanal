import 'package:artisanal/runtime.dart' show Cmd;

import '../core/framework.dart';
import '../core/widget.dart';
import 'listenable.dart';

/// A general-purpose widget that rebuilds whenever a [Listenable] notifies.
///
/// [AnimatedBuilder] is the primary way to build widgets that depend on an
/// [Animation] (or any [Listenable]). It takes an [animation] and a [builder]
/// callback, and rebuilds whenever the animation notifies its listeners.
///
/// The optional [child] parameter allows you to cache a subtree that does not
/// depend on the animation, avoiding unnecessary rebuilds.
///
/// ```dart
/// AnimatedBuilder(
///   animation: controller,
///   builder: (context, child) {
///     return Container(
///       width: controller.value * 100,
///       child: child,
///     );
///   },
///   child: Text('Hello'),
/// )
/// ```
class AnimatedBuilder extends StatefulWidget {
  /// Creates a widget that rebuilds when [animation] notifies.
  AnimatedBuilder({
    required this.animation,
    required this.builder,
    this.child,
    super.key,
  });

  /// The [Listenable] to which this widget is listening.
  ///
  /// Typically an [Animation] or [AnimationController], but any [Listenable]
  /// works.
  final Listenable animation;

  /// Called every time the [animation] notifies.
  ///
  /// The [child] argument is the same widget passed to this
  /// [AnimatedBuilder]'s constructor, allowing you to cache subtrees that
  /// do not depend on the animation value.
  final Widget Function(BuildContext context, Widget? child) builder;

  /// An optional child widget that does not depend on the animation.
  ///
  /// This is passed through to the [builder] callback. If a subtree does not
  /// change based on the animation value, it's more efficient to build it
  /// once and pass it here rather than rebuilding it on every animation frame.
  final Widget? child;

  @override
  State<AnimatedBuilder> createState() => _AnimatedBuilderState();
}

class _AnimatedBuilderState extends State<AnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_handleChange);
  }

  @override
  Cmd? didUpdateWidget(covariant AnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation.removeListener(_handleChange);
      widget.animation.addListener(_handleChange);
    }
    return null;
  }

  @override
  void dispose() {
    widget.animation.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}

/// A widget that rebuilds when a [Listenable] changes.
///
/// This is functionally identical to [AnimatedBuilder] but uses different
/// naming to clarify intent: use [ListenableBuilder] when the listenable is
/// not necessarily an animation (e.g., a [ChangeNotifier], [ValueNotifier],
/// or a merged listenable).
///
/// ```dart
/// ListenableBuilder(
///   listenable: myNotifier,
///   builder: (context, child) {
///     return Text('Value: ${myNotifier.value}');
///   },
/// )
/// ```
class ListenableBuilder extends StatefulWidget {
  /// Creates a widget that rebuilds when [listenable] notifies.
  ListenableBuilder({
    required this.listenable,
    required this.builder,
    this.child,
    super.key,
  });

  /// The [Listenable] to which this widget is listening.
  final Listenable listenable;

  /// Called every time the [listenable] notifies.
  ///
  /// The [child] argument is the same widget passed to this
  /// [ListenableBuilder]'s constructor.
  final Widget Function(BuildContext context, Widget? child) builder;

  /// An optional child widget that does not depend on the listenable.
  final Widget? child;

  @override
  State<ListenableBuilder> createState() => _ListenableBuilderState();
}

class _ListenableBuilderState extends State<ListenableBuilder> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
  }

  @override
  Cmd? didUpdateWidget(covariant ListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
    return null;
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}

/// A widget that rebuilds when a [ValueListenable] changes its value.
///
/// [ValueListenableBuilder] takes a [valueListenable] and a [builder] callback.
/// The builder is called whenever the value changes, providing the current value.
///
/// ```dart
/// ValueListenableBuilder<int>(
///   valueListenable: myCounter,
///   builder: (context, value, child) {
///     return Text('Count: $value');
///   },
/// )
/// ```
class ValueListenableBuilder<T> extends StatefulWidget {
  /// Creates a widget that rebuilds when [valueListenable] notifies.
  ValueListenableBuilder({
    required this.valueListenable,
    required this.builder,
    this.child,
    super.key,
  });

  /// The [ValueListenable] to which this widget is listening.
  final ValueListenable<T> valueListenable;

  /// Called every time the [valueListenable] notifies.
  ///
  /// The [value] is the current value of the [valueListenable].
  /// The [child] argument is the same widget passed to this
  /// [ValueListenableBuilder]'s constructor.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// An optional child widget that does not depend on the value.
  final Widget? child;

  @override
  State<ValueListenableBuilder<T>> createState() =>
      _ValueListenableBuilderState<T>();
}

class _ValueListenableBuilderState<T> extends State<ValueListenableBuilder<T>> {
  @override
  void initState() {
    super.initState();
    widget.valueListenable.addListener(_handleChange);
  }

  @override
  Cmd? didUpdateWidget(covariant ValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valueListenable != oldWidget.valueListenable) {
      oldWidget.valueListenable.removeListener(_handleChange);
      widget.valueListenable.addListener(_handleChange);
    }
    return null;
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() => setState(() {});

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.valueListenable.value, widget.child);
}
