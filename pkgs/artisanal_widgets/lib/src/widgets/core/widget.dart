/// Base Widget class for composable TUI components.
///
/// Widget extends the Model pattern with:
/// - Automatic message forwarding to children
/// - Built-in theme access
/// - Unique ID for identification
///
/// ```dart
/// class MyWidget extends Widget {
///   final input = TextInputWidget(key: const Key('input'));
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
@experimental
library;

import 'package:meta/meta.dart' show experimental, protected;

import 'package:artisanal/tui.dart'
    show Model, Msg, Cmd, MouseMsg, BackgroundColorMsg, globalZone;
import 'key.dart';
import '../theme/theme.dart';

/// Base class for composable TUI widgets.
///
/// Widgets are Models with automatic child message forwarding and theme access.
abstract class Widget implements Model {
  Widget({this.key});

  Object? _cachedView;
  Object? _cachedViewKey;

  /// Unique identifier for this widget.
  ///
  /// Derived from the widget [key]. Returns a hash-based fallback when no key
  /// is provided.
  String get id => key != null ? _keyToId(key!) : '[#${shortHash(this)}]';

  /// Key for preserving widget identity.
  ///
  /// When null, the framework matches widgets by position and [runtimeType]
  /// during reconciliation (like Flutter). Provide an explicit key only when
  /// you need to move a widget to a different position while preserving its
  /// state.
  final Key? key;

  /// Whether the framework can update [oldWidget]'s element to display
  /// [newWidget].
  ///
  /// Two widgets can be updated when they have the same [runtimeType] and
  /// [key] (both null counts as matching).
  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType &&
        oldWidget.key == newWidget.key;
  }

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
  /// Default implementation queries terminal background color and collects
  /// init commands from children. Override [handleInit] for widget-specific
  /// initialization.
  @override
  Cmd? init() {
    final cmds = <Cmd>[
      // Query terminal background color for adaptive theming
      Cmd.requestBackgroundColorReport(),
    ];
    for (final child in children) {
      final cmd = child.init();
      if (cmd != null) cmds.add(cmd);
    }
    final selfCmd = handleInit();
    if (selfCmd != null) cmds.add(selfCmd);
    return Cmd.batch(cmds);
  }

  /// Override this instead of [init] for widget-specific initialization.
  Cmd? handleInit() => null;

  /// Handles messages by forwarding to children then calling [handleUpdate].
  ///
  /// Automatically updates theme state when terminal background is detected.
  /// Do not override this method. Override [handleUpdate] instead.
  @override
  (Model, Cmd?) update(Msg msg) {
    final cmds = <Cmd>[];
    var current = this;

    if (msg is MouseMsg) {
      final zoneManager = globalZone;
      if (zoneManager != null) {
        final (updated, cmd) = zoneManager.anyInBoundsAndUpdate(current, msg);
        current = updated as Widget;
        if (cmd != null) cmds.add(cmd);
      }
    }

    // Auto-detect terminal background and update theme state
    if (msg is BackgroundColorMsg) {
      updateThemeFromBackground(msg.hex);
    }

    // Forward to all children
    for (final child in current.children) {
      final (_, cmd) = child.update(msg);
      if (cmd != null) cmds.add(cmd);
    }

    // Handle own messages
    final (newWidget, cmd) = current.handleUpdate(msg);
    if (cmd != null) cmds.add(cmd);

    return (newWidget, cmds.isEmpty ? null : Cmd.batch(cmds));
  }

  /// Override this to handle messages before they reach children.
  ///
  /// Return a [Cmd] to intercept the message.
  (Widget, Cmd?) handleIntercept(Msg msg) => (this, null);

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

  /// Returns a cached view if the cache key matches.
  @protected
  T buildCachedView<T>(T Function() builder, Object? cacheKey) {
    if (_cachedView != null && _cachedViewKey == cacheKey) {
      return _cachedView as T;
    }
    final result = builder();
    _cachedView = result;
    _cachedViewKey = cacheKey;
    return result;
  }

  /// Clears any cached view for this widget.
  @protected
  void invalidateCachedView() {
    _cachedView = null;
    _cachedViewKey = null;
  }

  @override
  String toString() => 'Widget($id)';
}

String _keyToId(Key key) {
  if (key is ValueKey<Object?>) {
    final value = key.value;
    if (value is String) return value;
    return value?.toString() ?? 'null';
  }
  return key.toString();
}

/// Returns a stable string ID for a possibly-null key.
///
/// When [key] is null, returns a hash-based fallback using [fallback].
String keyToIdOrFallback(Key? key, Object fallback) {
  if (key != null) return _keyToId(key);
  return '[#${shortHash(fallback)}]';
}

/// A simple widget that wraps a static string or View.
///
/// Useful for leaf content that doesn't need state or message handling.
class StaticWidget extends Widget {
  StaticWidget(this._content, {super.key});

  final Object _content;

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
