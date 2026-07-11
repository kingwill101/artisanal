/// Flutter-style widget framework primitives.
library;

import 'package:meta/meta.dart' show internal, mustCallSuper;

import 'package:artisanal/tui.dart' show Cmd, Msg;
import 'widget.dart';

/// An opaque handle to location in the widget tree.
abstract class BuildContext {
  /// The widget currently associated with this context.
  Widget get widget;

  /// Returns the nearest ancestor widget of type [T], or `null`.
  T? findAncestorWidgetOfExactType<T extends Widget>();

  /// Returns the nearest inherited widget of type [T] and registers this
  /// context as a dependent.
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>();

  /// Returns the nearest ancestor [State] of type [T], or `null`.
  T? findAncestorStateOfType<T extends State>();
}

@internal
abstract class StateSetter {
  /// Marks the owning element as needing rebuild.
  void markNeedsBuild();
}

/// A widget with a build method and no mutable state.
abstract class StatelessWidget extends Widget {
  /// Creates a stateless widget.
  StatelessWidget({super.key});

  /// Describes the part of the UI represented by this widget.
  Widget build(BuildContext context);

  @override
  Object view() {
    final built = build(_FallbackBuildContext(this));
    return built.view();
  }
}

/// A widget with mutable state managed by a [State] object.
abstract class StatefulWidget extends Widget {
  /// Creates a stateful widget.
  StatefulWidget({super.key});

  /// Creates the mutable [State] associated with this widget.
  State createState();

  @override
  Object view() {
    throw StateError('StatefulWidget requires WidgetApp rendering.');
  }
}

/// Mutable state for a [StatefulWidget].
abstract class State<T extends StatefulWidget> {
  /// The current configuration for this state.
  late T widget;

  /// The build context for this state.
  late BuildContext context;
  StateSetter? _element;

  /// Whether this state is currently mounted in the element tree.
  bool get mounted => _element != null;

  /// Called when the state is inserted into the tree.
  @mustCallSuper
  void initState() {}

  /// Called when the widget configuration changes.
  ///
  /// Return a [Cmd] to schedule side effects caused by the configuration
  /// update.
  @mustCallSuper
  Cmd? didUpdateWidget(covariant T oldWidget) => null;

  /// Called when this state is permanently removed from the tree.
  @mustCallSuper
  void dispose() {}

  /// Called when an inherited widget this state depends on changes.
  @mustCallSuper
  void didChangeDependencies() {}

  /// Called once when the widget tree is first mounted.
  ///
  /// Return a [Cmd] to schedule initialization work such as starting
  /// animations.  This is the State-level equivalent of
  /// [Widget.handleInit].
  Cmd? handleInit() => null;

  /// Called before children during message dispatch.
  ///
  /// Return a [Cmd] to intercept the message and prevent it from reaching
  /// children.
  Cmd? handleIntercept(Msg msg) => null;

  /// Called after children during message dispatch.
  Cmd? handleUpdate(Msg msg) => null;

  /// Builds the widget subtree for this state.
  Widget build(BuildContext context);

  /// Notifies the framework that this state's internal data has changed.
  ///
  /// The callback [fn] runs synchronously, then the owning element is marked
  /// dirty so it can rebuild in the next build scope.
  void setState(void Function() fn) {
    fn();
    _element?.markNeedsBuild();
  }

  @internal
  void attach(StateSetter element, BuildContext context, T widget) {
    _element = element;
    this.context = context;
    this.widget = widget;
  }

  @internal
  void detach() {
    _element = null;
  }
}

/// A widget that exposes data to descendants.
abstract class InheritedWidget extends Widget {
  /// Creates an inherited widget that wraps [child].
  InheritedWidget({required this.child, super.key});

  /// The descendant subtree that can depend on this widget's data.
  final Widget child;

  @override
  List<Widget> get children => [child];

  @override
  Object view() => child.view();

  /// Whether dependents should rebuild when this widget updates.
  bool updateShouldNotify(covariant InheritedWidget oldWidget);
}

class _FallbackBuildContext implements BuildContext {
  _FallbackBuildContext(this._widget);

  final Widget _widget;

  @override
  Widget get widget => _widget;

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() => null;

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  T? findAncestorStateOfType<T extends State>() => null;
}
