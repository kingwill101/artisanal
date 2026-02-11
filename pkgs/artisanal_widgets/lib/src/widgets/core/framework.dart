/// Flutter-style widget framework primitives.
@experimental
library;

import 'package:meta/meta.dart' show experimental, internal, mustCallSuper;

import 'package:artisanal/tui.dart' show Cmd, Msg;
import 'widget.dart';

/// An opaque handle to location in the widget tree.
abstract class BuildContext {
  Widget get widget;

  T? findAncestorWidgetOfExactType<T extends Widget>();

  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>();

  T? findAncestorStateOfType<T extends State>();
}

@internal
abstract class StateSetter {
  void markNeedsBuild();
}

/// A widget with a build method and no mutable state.
abstract class StatelessWidget extends Widget {
  StatelessWidget({super.key});

  Widget build(BuildContext context);

  @override
  Object view() {
    final built = build(_FallbackBuildContext(this));
    return built.view();
  }
}

/// A widget with mutable state managed by a [State] object.
abstract class StatefulWidget extends Widget {
  StatefulWidget({super.key});

  State createState();

  @override
  Object view() {
    throw StateError('StatefulWidget requires WidgetApp rendering.');
  }
}

/// Mutable state for a [StatefulWidget].
abstract class State<T extends StatefulWidget> {
  late T widget;
  late BuildContext context;
  StateSetter? _element;

  bool get mounted => _element != null;

  @mustCallSuper
  void initState() {}

  @mustCallSuper
  Cmd? didUpdateWidget(covariant T oldWidget) => null;

  @mustCallSuper
  void dispose() {}

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

  Widget build(BuildContext context);

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
  InheritedWidget({required this.child, super.key});

  final Widget child;

  @override
  List<Widget> get children => [child];

  @override
  Object view() => child.view();

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
