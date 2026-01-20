/// Base Widget class for composable TUI components.
///
/// Widget extends the Model pattern with:
/// - Automatic message forwarding to children
/// - Built-in theme access
/// - Unique ID for identification
///
/// ```dart
/// class MyWidget extends Widget {
///   @override
///   String get id => 'my-widget';
///
///   final input = TextInputWidget(id: 'input');
///
///   @override
///   List<Widget> get children => [input];
///
///   @override
///   Object view() {
///     return Column(children: [
///       Text('Enter name:', style: theme.labelStyle),
///       input,
///     ]);
///   }
/// }
/// ```
library;

import '../model.dart';
import '../msg.dart';
import '../cmd.dart';
import 'theme.dart';

/// Base class for composable TUI widgets.
///
/// Widgets are Models with automatic child message forwarding and theme access.
abstract class Widget implements Model {
  /// Unique identifier for this widget.
  ///
  /// Used for message routing and debugging.
  String get id;

  /// Child widgets that receive forwarded messages.
  ///
  /// Override this to declare child widgets. The framework automatically
  /// forwards messages to all children before calling [handleUpdate].
  List<Widget> get children => const [];

  /// Whether this widget can receive keyboard focus.
  bool get focusable => false;

  /// Access the current theme.
  ///
  /// Returns the global theme instance.
  Theme get theme => currentTheme;

  /// Called once when the widget is first mounted.
  ///
  /// Override to perform initialization like starting timers or fetching data.
  /// Default implementation collects init commands from children.
  @override
  Cmd? init() {
    final cmds = <Cmd>[];
    for (final child in children) {
      final cmd = child.init();
      if (cmd != null) cmds.add(cmd);
    }
    final selfCmd = handleInit();
    if (selfCmd != null) cmds.add(selfCmd);
    return cmds.isEmpty ? null : Cmd.batch(cmds);
  }

  /// Override this instead of [init] for widget-specific initialization.
  Cmd? handleInit() => null;

  /// Handles messages by forwarding to children then calling [handleUpdate].
  ///
  /// Do not override this method. Override [handleUpdate] instead.
  @override
  (Model, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];

    // Forward to all children
    for (final child in children) {
      final (_, cmd) = child.update(msg);
      if (cmd != null) cmds.add(cmd);
    }

    // Handle own messages
    final (newWidget, cmd) = handleUpdate(msg);
    if (cmd != null) cmds.add(cmd);

    return (newWidget, cmds.isEmpty ? null : Cmd.batch(cmds));
  }

  /// Override this to handle messages specific to this widget.
  ///
  /// Children have already received the message before this is called.
  ///
  /// ```dart
  /// @override
  /// (Widget, Cmd?) handleUpdate(Msg msg) {
  ///   return switch (msg) {
  ///     KeyMsg(key: Key(type: KeyType.enter)) => _submit(),
  ///     _ => (this, null),
  ///   };
  /// }
  /// ```
  (Widget, Cmd?) handleUpdate(Msg msg) => (this, null);

  /// Renders the widget to a string or View.
  ///
  /// Use layout widgets like [Row] and [Column] to compose child views.
  @override
  Object view();

  @override
  String toString() => 'Widget($id)';
}

/// A simple widget that wraps a static string or View.
///
/// Useful for leaf content that doesn't need state or message handling.
class StaticWidget extends Widget {
  StaticWidget(this._content, {String? id})
    : _id = id ?? 'static-${_counter++}';

  static int _counter = 0;

  final Object _content;
  final String _id;

  @override
  String get id => _id;

  @override
  Object view() => _content;
}

/// Mixin for widgets that need to track focus state.
mixin FocusableWidget on Widget {
  bool _focused = false;

  /// Whether this widget currently has focus.
  bool get focused => _focused;

  @override
  bool get focusable => true;

  /// Called when the widget receives focus.
  void onFocus() {
    _focused = true;
  }

  /// Called when the widget loses focus.
  void onBlur() {
    _focused = false;
  }
}
