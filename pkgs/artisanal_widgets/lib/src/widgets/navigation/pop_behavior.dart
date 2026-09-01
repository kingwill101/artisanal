/// Pop behavior configuration for the navigation system.
///
/// Configures which keyboard keys trigger a pop action in the navigator.
library;

import 'package:artisanal/runtime.dart' show KeyMsg;
import 'package:artisanal/terminal.dart' show KeyType;

import 'route.dart';

/// Configuration for how a [Navigator] handles pop requests via keyboard.
///
/// By default, pressing Escape will pop the current route (if the stack
/// has more than one route). Backspace popping is disabled by default.
///
/// ```dart
/// Navigator(
///   popBehavior: PopBehavior(
///     escapeEnabled: true,
///     backspaceEnabled: false,
///     customPopKey: 'q',
///   ),
///   home: HomeScreen(),
/// )
/// ```
class PopBehavior {
  /// Creates a pop behavior configuration.
  const PopBehavior({
    this.escapeEnabled = true,
    this.backspaceEnabled = false,
    this.customPopKey,
    this.canPop,
    this.onPopInvoked,
  });

  /// Whether pressing Escape triggers a pop.
  final bool escapeEnabled;

  /// Whether pressing Backspace triggers a pop.
  final bool backspaceEnabled;

  /// An optional custom character key that triggers a pop (e.g., `'q'`).
  final String? customPopKey;

  /// Optional callback to determine if popping is allowed for the
  /// current route. If `null`, the navigator's default [canPop] logic is used.
  final bool Function(Route<dynamic>)? canPop;

  /// Optional async callback invoked before popping, allowing confirmation
  /// dialogs (e.g., "Discard unsaved changes?"). Return `true` to allow
  /// the pop, `false` to prevent it.
  final Future<bool> Function(Route<dynamic>)? onPopInvoked;

  /// Default behavior: only Escape pops.
  static const defaultBehavior = PopBehavior();

  /// Strict behavior: no keyboard-triggered pops.
  static const strict = PopBehavior(
    escapeEnabled: false,
    backspaceEnabled: false,
  );

  /// Returns `true` if the given [msg] should trigger a pop action
  /// based on this configuration.
  bool shouldPop(KeyMsg msg) {
    final key = msg.key;

    if (escapeEnabled && key.type == KeyType.escape) return true;
    if (backspaceEnabled && key.type == KeyType.backspace) return true;
    if (customPopKey != null &&
        key.type == KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCodes(key.runes) == customPopKey) {
      return true;
    }

    return false;
  }
}
