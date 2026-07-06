import 'package:artisanal/style.dart';

import 'cmd.dart';
import 'key.dart';
import 'msg.dart';

/// Help information for a key binding.
///
/// Contains the key representation and description for display in help views.
class Help {
  const Help({this.key = '', this.desc = ''});

  /// The key representation (e.g., "↑/k", "ctrl+c").
  final String key;

  /// Description of what the key does (e.g., "move up", "quit").
  final String desc;

  /// Returns true if this help has content.
  bool get hasContent => key.isNotEmpty || desc.isNotEmpty;
}

/// A key binding that maps keys to actions with optional help text.
///
/// Key bindings are the foundation of TUI keyboard navigation. They allow
/// you to define which keys trigger which actions, and provide help text
/// for user documentation.
///
/// ## Example
///
/// ```dart
/// final upBinding = KeyBinding(
///   keys: ['up', 'k'],
///   help: Help(key: '↑/k', desc: 'move up'),
/// );
///
/// final quitBinding = KeyBinding(
///   keys: ['q', 'ctrl+c'],
///   help: Help(key: 'q', desc: 'quit'),
/// );
/// ```
class KeyBinding {
  /// Creates a new key binding.
  KeyBinding({List<String>? keys, Help? help, bool disabled = false, this.handler, this.action})
    : keys = keys ?? [],
      help = help ?? const Help(),
      _disabled = disabled;

  /// Creates a key binding with the given keys.
  factory KeyBinding.withKeys(List<String> keys) {
    return KeyBinding(keys: keys);
  }

  /// Creates a key binding with keys and help text.
  factory KeyBinding.withHelp(List<String> keys, String keyText, String desc) {
    return KeyBinding(
      keys: keys,
      help: Help(key: keyText, desc: desc),
    );
  }

  /// Optional handler invoked when this binding is activated.
  ///
  /// Used by [activate] to produce a [Cmd] when the binding matches a key.
  /// When `null`, [activate] returns `null` even if the key matches.
  final Cmd? Function()? handler;

  /// Widget-level callback invoked when this binding is intercepted.
  ///
  /// Used by [KeyMap.intercept] for direct side effects in StatefulWidget
  /// states. When `null`, [intercept] skips this binding.
  final void Function()? action;

  /// Returns `true` if this binding is enabled and [msg] matches its keys.
  bool matches(KeyMsg msg) => enabled && keyMatches(msg.key, [this]);

  /// Attempts to activate this binding for [msg].
  ///
  /// Returns the result of [handler] when the binding is enabled and the
  /// key matches [msg], or `null` otherwise.
  Cmd? activate(KeyMsg msg) {
    if (!enabled || handler == null) return null;
    if (!matches(msg)) return null;
    return handler!();
  }

  /// The keys that trigger this binding.
  List<String> keys;

  /// The help information for this binding.
  Help help;

  bool _disabled;

  /// Sets the help text for this binding.
  void setHelp(String key, String desc) {
    help = Help(key: key, desc: desc);
  }

  /// Whether this binding is enabled.
  ///
  /// Disabled bindings won't be activated and won't show up in help.
  bool get enabled => !_disabled && keys.isNotEmpty;

  /// Enables or disables this binding.
  set enabled(bool value) => _disabled = !value;

  /// Disables this binding.
  void disable() => _disabled = true;

  /// Enables this binding.
  void enable() => _disabled = false;

  /// Removes the keys and help from this binding, effectively nullifying it.
  void unbind() {
    keys = [];
    help = const Help();
  }
}

/// Checks if a key message matches any of the given bindings.
///
/// This is the primary way to check if user input matches a key binding.
///
/// ## Example
///
/// ```dart
/// final keyMap = MyKeyMap();
///
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     KeyMsg(:final key) when keyMatches(key, keyMap.up) =>
///       (moveUp(), null),
///     KeyMsg(:final key) when keyMatches(key, keyMap.down) =>
///       (moveDown(), null),
///     KeyMsg(:final key) when keyMatches(key, keyMap.quit) =>
///       (this, Cmd.quit()),
///     _ => (this, null),
///   };
/// }
/// ```
bool keyMatches(Key key, List<KeyBinding> bindings) {
  final keyStr = key.toString();
  // Extract the key name from Key(...) format
  final keyName = keyStr.startsWith('Key(') && keyStr.endsWith(')')
      ? keyStr.substring(4, keyStr.length - 1)
      : keyStr;
  final caseSensitiveRunes =
      key.type == KeyType.runes &&
      !key.ctrl &&
      !key.alt &&
      !key.meta &&
      !key.hyper &&
      !key.superKey;
  final keyNameCmp = caseSensitiveRunes ? keyName : keyName.toLowerCase();
  final keyStrCmp = caseSensitiveRunes ? keyStr : keyStr.toLowerCase();

  for (final binding in bindings) {
    if (!binding.enabled) continue;
    for (final k in binding.keys) {
      // For character keys (runes), match case-sensitively
      // For other keys, match case-insensitively
      final kCmp = caseSensitiveRunes ? k : k.toLowerCase();
      final matches = caseSensitiveRunes
          ? (keyNameCmp == kCmp || keyStrCmp == kCmp)
          : (keyNameCmp == kCmp || keyStrCmp == kCmp);
      if (matches) return true;

      // Handle special key type aliases (e.g., ' ' for space, '\t' for tab)
      if (_keyTypeMatchesAlias(key.type, k)) return true;
    }
  }
  return false;
}

/// Maps binding string aliases to their corresponding KeyType.
bool _keyTypeMatchesAlias(KeyType type, String alias) {
  final aliasLower = alias.toLowerCase();
  return switch (type) {
    KeyType.space => alias == ' ',
    KeyType.tab => alias == '\t',
    KeyType.enter => alias == '\n' || alias == '\r',
    KeyType.escape =>
      alias == '\x1b' || aliasLower == 'esc' || aliasLower == 'escape',
    _ => false,
  };
}

/// Checks if a key matches a single binding.
bool keyMatchesSingle(Key key, KeyBinding binding) {
  return keyMatches(key, [binding]);
}

/// Extension to check key matches more fluently.
extension KeyMatchExtension on Key {
  /// Returns true if this key matches any of the given bindings.
  bool matches(List<KeyBinding> bindings) => keyMatches(this, bindings);

  /// Returns true if this key matches the given binding.
  bool matchesSingle(KeyBinding binding) => keyMatchesSingle(this, binding);
}

/// Extension to check KeyMsg matches.
extension KeyMsgMatchExtension on KeyMsg {
  /// Returns true if this key message matches any of the given bindings.
  bool matches(List<KeyBinding> bindings) => keyMatches(key, bindings);

  /// Returns true if this key message matches the given binding.
  bool matchesSingle(KeyBinding binding) => keyMatchesSingle(key, binding);
}

/// A collection of key bindings forming a key map.
///
/// Use this to group related bindings for help views and dispatch. Handlers
/// are placed directly on each [KeyBinding] via the `handler` parameter.
///
/// ## Basic usage (subclass)
///
/// ```dart
/// class MyKeyMap extends KeyMap {
///   MyKeyMap() {
///     shortHelp = [up, down, quit];
///     fullHelp = [
///       [up, down],
///       [quit],
///     ];
///   }
///
///   final up = KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up');
///   final down = KeyBinding.withHelp(['down', 'j'], '↓/j', 'move down');
///   final quit = KeyBinding.withHelp(['q', 'ctrl+c'], 'q', 'quit');
/// }
/// ```
///
/// ## With handlers
///
/// ```dart
/// class AppKeyMap extends KeyMap {
///   AppKeyMap() {
///     shortHelp = [quit, help];
///     fullHelp = [[quit], [help]];
///   }
///
///   final quit = KeyBinding(
///     keys: ['q'],
///     help: Help(key: 'q', desc: 'quit'),
///     handler: () => Cmd.quit(),
///   );
///   final help = KeyBinding(
///     keys: ['?'],
///     help: Help(key: '?', desc: 'toggle help'),
///     handler: () => Cmd.message(ToggleHelpMsg()),
///   );
/// }
/// ```
///
/// In your model:
/// ```dart
/// (Model, Cmd?) update(Msg msg) {
///   if (msg case KeyMsg()) {
///     final cmd = keyMap.handle(msg);
///     if (cmd != null) return (this, cmd);
///   }
///   return (this, null);
/// }
/// ```
class KeyMap {
  /// Creates a new key map.
  KeyMap({List<KeyBinding>? shortHelp, List<List<KeyBinding>>? fullHelp, this.chords})
    : shortHelp = shortHelp ?? [],
      fullHelp = fullHelp ?? [];

  /// Creates a key map with [bindings] set as both short and full help.
  ///
  /// Shorthand for:
  /// ```dart
  /// KeyMap(shortHelp: bindings, fullHelp: [bindings])
  /// ```
  factory KeyMap.simple(List<KeyBinding> bindings) {
    return KeyMap(shortHelp: bindings, fullHelp: [bindings]);
  }

  /// Bindings for the short help view.
  ///
  /// These are displayed in a single line at the bottom of the screen.
  List<KeyBinding> shortHelp;

  /// Bindings for the full help view, grouped by columns.
  ///
  /// Each inner list represents a column of help items.
  List<List<KeyBinding>> fullHelp;

  /// Optional multi-key chord bindings.
  ///
  /// Each entry defines a chord: a prefix keybinding followed by a
  /// continuation keybinding. Use [toChordBindings] to convert these
  /// into [KeyChordBinding] objects for [KeyChordInterceptor].
  ///
  /// ```dart
  /// chords = [
  ///   (prefix: ctrlX, key: sBinding, id: 'save'),
  ///   (prefix: ctrlX, key: qBinding, id: 'quit'),
  /// ];
  /// ```
  List<({KeyBinding prefix, KeyBinding key, String id})>? chords;

  /// Returns the first enabled [KeyBinding] that matches [msg], or `null`.
  ///
  /// Useful when you need to dispatch stateful actions in `update()` based
  /// on which binding matched:
  ///
  /// ```dart
  /// final binding = keyMap.firstMatch(msg);
  /// if (binding == keyMap.up) { _cursorUp(); }
  /// else if (binding == keyMap.down) { _cursorDown(); }
  /// ```
  KeyBinding? firstMatch(KeyMsg msg) {
    for (final binding in shortHelp) {
      if (binding.matches(msg)) return binding;
    }
    return null;
  }

  /// Returns `true` if a matching binding's [KeyBinding.action] was called.
  ///
  /// Iterates [shortHelp], invokes [KeyBinding.action] on the first enabled
  /// binding that matches [msg]. Returns `true` if consumed. Designed for
  /// use in widget `handleIntercept`:
  ///
  /// ```dart
  /// @override
  /// bool handleIntercept(Msg msg) {
  ///   if (msg is KeyMsg && keyMap.intercept(msg)) return true;
  ///   return super.handleIntercept(msg);
  /// }
  /// ```
  bool intercept(KeyMsg msg) {
    for (final binding in shortHelp) {
      if (!binding.matches(msg)) continue;
      if (binding.action != null) {
        binding.action!();
        return true;
      }
    }
    return false;
  }

  /// Returns the command from the first matching handler, or `null`.
  ///
  /// Iterates [shortHelp] calling [KeyBinding.activate] on each. Returns
  /// the first non-null result. If no binding matches, or none have a
  /// handler registered, returns `null`.
  ///
  /// This is the primary entry point for dispatch:
  ///
  /// ```dart
  /// final cmd = keyMap.handle(msg);
  /// if (cmd != null) return (this, cmd);
  /// ```
  Cmd? handle(KeyMsg msg) {
    for (final binding in shortHelp) {
      final cmd = binding.activate(msg);
      if (cmd != null) return cmd;
    }
    return null;
  }
}

/// Commonly used key bindings for navigation.
class CommonKeyBindings {
  CommonKeyBindings._();

  /// Up navigation (↑ or k).
  static final up = KeyBinding.withHelp(['up', 'k'], '${Arrows.up}/k', 'up');

  /// Down navigation (↓ or j).
  static final down = KeyBinding.withHelp(
    ['down', 'j'],
    '${Arrows.down}/j',
    'down',
  );

  /// Left navigation (← or h).
  static final left = KeyBinding.withHelp(
    ['left', 'h'],
    '${Arrows.left}/h',
    'left',
  );

  /// Right navigation (→ or l).
  static final right = KeyBinding.withHelp(
    ['right', 'l'],
    '${Arrows.right}/l',
    'right',
  );

  /// Enter/confirm.
  static final enter = KeyBinding.withHelp(
    ['enter'],
    KeyboardChars.enter,
    'confirm',
  );

  /// Escape/cancel.
  static final escape = KeyBinding.withHelp(['esc'], 'esc', 'cancel');

  /// Quit (q or Ctrl+C).
  static final quit = KeyBinding.withHelp(['q', 'ctrl+c'], 'q', 'quit');

  /// Page up.
  static final pageUp = KeyBinding.withHelp(['pgup', 'b'], 'pgup', 'page up');

  /// Page down.
  static final pageDown = KeyBinding.withHelp(
    ['pgdown', 'f', ' '],
    'pgdn',
    'page down',
  );

  /// Go to top (home or g).
  static final gotoTop = KeyBinding.withHelp(['home', 'g'], 'g', 'go to top');

  /// Go to bottom (end or G).
  static final gotoBottom = KeyBinding.withHelp(
    ['end', 'G'],
    'G',
    'go to bottom',
  );

  /// Tab to next.
  static final tab = KeyBinding.withHelp(['tab'], 'tab', 'next');

  /// Shift+Tab to previous.
  static final shiftTab = KeyBinding.withHelp(
    ['shift+tab'],
    'shift+tab',
    'previous',
  );

  /// Help toggle (?).
  static final help = KeyBinding.withHelp(['?'], '?', 'help');

  /// Filter (/).
  static final filter = KeyBinding.withHelp(['/'], '/', 'filter');
}
