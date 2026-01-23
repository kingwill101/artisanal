import 'msg.dart';
import 'cmd.dart';
import 'model.dart';

/// A lightweight, composable TUI component.
///
/// Unlike a full [Model], a [ViewComponent] is designed to be hosted
/// inside a parent model. It follows the same Elm Architecture pattern
/// (init/update/view) but is optimized for composition.
///
/// ## Example
///
/// ```dart
/// class MyComponent extends ViewComponent {
///   int count = 0;
///
///   @override
///   (ViewComponent, Cmd?) update(Msg msg) {
///     if (msg is IncrementMsg) {
///       count++;
///       return (this, null);
///     }
///     return (this, null);
///   }
///
///   @override
///   String view() => 'Count: $count';
/// }
/// ```
abstract class ViewComponent extends Model {
  const ViewComponent();

  /// Updates the component state in response to a message.
  ///
  /// Returns the updated component (often `this`) and an optional command.
  @override
  (ViewComponent, Cmd?) update(Msg msg);
}

/// A mixin for [Model]s that host one or more [ViewComponent]s.
///
/// This provides helpers for delegating messages and commands to child
/// components.
mixin ComponentHost {
  /// Helper to update a child component and return the parent model.
  ///
  /// ```dart
  /// @override
  /// (Model, Cmd?) update(Msg msg) {
  ///   return updateComponent(myChild, msg, (newChild) => myChild = newChild);
  /// }
  /// ```
  (P, Cmd?) updateComponent<T extends Model, P extends Model>(
    T component,
    Msg msg,
    void Function(T) setter,
  ) {
    final (newComponent, cmd) = component.update(msg);
    setter(newComponent as T);
    return (this as P, cmd);
  }
}

/// A [ViewComponent] that only has a view and no state/updates.
abstract class StaticComponent extends ViewComponent {
  const StaticComponent();

  @override
  (ViewComponent, Cmd?) update(Msg msg) => (this, null);
}
