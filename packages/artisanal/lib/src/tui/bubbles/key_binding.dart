import '../key.dart';
import '../msg.dart';

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
  KeyBinding({List<String>? keys, Help? help, bool disabled = false})
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

  for (final binding in bindings) {
    if (!binding.enabled) continue;
    for (final k in binding.keys) {
      // For character keys (runes), match case-sensitively
      // For other keys, match case-insensitively
      final matches = key.type == KeyType.runes
          ? (keyName == k || keyStr == k)
          : (keyName.toLowerCase() == k.toLowerCase() || keyStr == k);
      if (matches) return true;
    }
  }
  return false;
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
/// Implement this interface to provide key bindings for help views.
///
/// ## Example
///
/// ```dart
/// class MyKeyMap implements KeyMap {
///   final up = KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up');
///   final down = KeyBinding.withHelp(['down', 'j'], '↓/j', 'move down');
///   final quit = KeyBinding.withHelp(['q', 'ctrl+c'], 'q', 'quit');
///
///   @override
///   List<KeyBinding> shortHelp() => [up, down, quit];
///
///   @override
///   List<List<KeyBinding>> fullHelp() => [
///     [up, down],
///     [quit],
///   ];
/// }
/// ```
abstract class KeyMap {
  /// Returns bindings for the short help view.
  ///
  /// These are displayed in a single line at the bottom of the screen.
  List<KeyBinding> shortHelp();

  /// Returns bindings for the full help view, grouped by columns.
  ///
  /// Each inner list represents a column of help items.
  List<List<KeyBinding>> fullHelp();
}

/// Commonly used key bindings for navigation.
class CommonKeyBindings {
  CommonKeyBindings._();

  /// Up navigation (↑ or k).
  static final up = KeyBinding.withHelp(['up', 'k'], '↑/k', 'up');

  /// Down navigation (↓ or j).
  static final down = KeyBinding.withHelp(['down', 'j'], '↓/j', 'down');

  /// Left navigation (← or h).
  static final left = KeyBinding.withHelp(['left', 'h'], '←/h', 'left');

  /// Right navigation (→ or l).
  static final right = KeyBinding.withHelp(['right', 'l'], '→/l', 'right');

  /// Enter/confirm.
  static final enter = KeyBinding.withHelp(['enter'], '↵', 'confirm');

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
