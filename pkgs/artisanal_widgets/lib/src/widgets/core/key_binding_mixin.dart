import 'package:artisanal/tui.dart' show Cmd, KeyMap, KeyMsg, Msg;

import 'framework.dart' show State, StatefulWidget;

/// Mixes [KeyMap] dispatch into [State.handleIntercept].
///
/// Callers must provide a [keyMap] getter. The mixin automatically routes
/// [KeyMsg] through [KeyMap.intercept] (for `action` callbacks) and
/// [KeyMap.handle] (for `handler` commands), consuming the event on match.
///
/// ## Example
///
/// ```dart
/// class _MyState extends State<MyWidget> with KeyBindingMixin {
///   @override
///   KeyMap get keyMap => _MyKeyMap(
///     onDismiss: () => Navigator.of(context).pop(),
///   );
/// }
/// ```
mixin KeyBindingMixin<T extends StatefulWidget> on State<T> {
  KeyMap get keyMap;

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is KeyMsg) {
      if (keyMap.intercept(msg)) return Cmd.none();
      final cmd = keyMap.handle(msg);
      if (cmd != null) return cmd;
    }
    return super.handleIntercept(msg);
  }
}
