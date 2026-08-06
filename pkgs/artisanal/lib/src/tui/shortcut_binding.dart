/// Unified single-key and multi-key shortcut bindings for [KeymapHub].
///
library;

import 'key_binding.dart' show Help, KeyBinding, KeyMap, keyMatchesSingle;
import 'key.dart' show Key;
import 'key_chord.dart' show KeyChordBinding;

/// Default action id for “show shortcuts for this view” (OpenCode `help_show`).
const String shortcutHelpActionId = 'help_show';

/// A named action bound to a key sequence of length ≥ 1.
///
/// ```dart
/// ShortcutBinding.single(
///   id: 'command_list',
///   key: 'ctrl+p',
///   description: 'commands',
/// );
/// ShortcutBinding.chord(
///   id: 'sidebar_toggle',
///   leader: 'ctrl+x',
///   key: 'b',
///   description: 'toggle sidebar',
///   group: 'session',
/// );
/// ShortcutBinding.help(); // ? → help_show
/// ```
final class ShortcutBinding {
  const ShortcutBinding({
    required this.id,
    required this.keys,
    this.description = '',
    this.group = 'Commands',
    this.displayKeys,
  }) : assert(keys.length >= 1, 'ShortcutBinding requires at least one key');

  /// Single-key shortcut.
  factory ShortcutBinding.single({
    required String id,
    required String key,
    String description = '',
    String group = 'Commands',
    String? displayKey,
  }) {
    return ShortcutBinding(
      id: id,
      keys: [key],
      description: description,
      group: group,
      displayKeys: displayKey != null ? [displayKey] : null,
    );
  }

  /// Binding that opens the shortcuts sheet (`?` by default).
  factory ShortcutBinding.help({
    String key = '?',
    String id = shortcutHelpActionId,
    String description = 'show shortcuts',
    String group = 'Help',
  }) {
    return ShortcutBinding.single(
      id: id,
      key: key,
      description: description,
      group: group,
    );
  }

  /// Two-key leader chord (OpenCode-style `ctrl+x` then letter).
  factory ShortcutBinding.chord({
    required String id,
    required String leader,
    required String key,
    String description = '',
    String group = 'Commands',
  }) {
    return ShortcutBinding(
      id: id,
      keys: [leader, key],
      description: description,
      group: group,
    );
  }

  /// Bridge from a [KeyChordBinding].
  factory ShortcutBinding.fromChord(KeyChordBinding chord) {
    final prefixHelp = chord.prefix.help;
    final keyHelp = chord.key.help;
    final leader = prefixHelp.key.isNotEmpty
        ? prefixHelp.key
        : (chord.prefix.keys.isNotEmpty ? chord.prefix.keys.first : 'ctrl+x');
    final cont = keyHelp.key.isNotEmpty
        ? keyHelp.key
        : (chord.key.keys.isNotEmpty ? chord.key.keys.first : chord.id);
    final desc = keyHelp.desc.isNotEmpty ? keyHelp.desc : chord.id;
    final group = prefixHelp.desc.isNotEmpty ? prefixHelp.desc : 'Commands';
    return ShortcutBinding(
      id: chord.id,
      keys: [leader, cont],
      description: desc,
      group: group,
    );
  }

  /// Stable action id (e.g. `sidebar_toggle`, OpenCode keybind names).
  final String id;

  /// Ordered key specs (`ctrl+x`, `b`, …). Length 1 = single; 2+ = sequence.
  final List<String> keys;

  /// Human-readable action description.
  final String description;

  /// Help / which-key group label.
  final String group;

  /// Optional display labels per step (defaults to [keys]).
  final List<String>? displayKeys;

  /// Whether this is a multi-key sequence.
  bool get isSequence => keys.length > 1;

  /// Labels for UI (which-key, sheets).
  List<String> get labels =>
      displayKeys ?? List<String>.unmodifiable(keys);

  /// First-step key label (leader or single).
  String get prefixLabel => labels.first;

  /// Last-step key label.
  String get continuationLabel => labels.last;

  /// Display string for the full path (`ctrl+x b` or `ctrl+p`).
  String get formattedKeys => formatShortcutKeys(labels);

  /// Whether [key] matches sequence step [index].
  bool matchesStep(Key key, int index) {
    if (index < 0 || index >= keys.length) return false;
    final spec = keys[index];
    return keyMatchesSingle(
      key,
      KeyBinding.withHelp([spec], spec, ''),
    );
  }

  /// Convert to a help [KeyBinding] for single-key entries / HelpView adapters.
  KeyBinding toKeyBinding() {
    final label = labels.join(' ');
    return KeyBinding(
      keys: List<String>.of(keys),
      help: Help(key: label, desc: description),
    );
  }

  /// Bridge to [KeyChordBinding] when [keys] has length 2.
  KeyChordBinding? toChordBinding() {
    if (keys.length != 2) return null;
    return KeyChordBinding(
      id: id,
      prefix: KeyBinding.withHelp([keys[0]], labels[0], group),
      key: KeyBinding.withHelp([keys[1]], labels[1], description),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShortcutBinding &&
        other.id == id &&
        other.description == description &&
        other.group == group &&
        _listEq(other.keys, keys) &&
        _listEq(other.displayKeys, displayKeys);
  }

  @override
  int get hashCode => Object.hash(
    id,
    description,
    group,
    Object.hashAll(keys),
    displayKeys == null ? 0 : Object.hashAll(displayKeys!),
  );
}

bool _listEq(List<String>? a, List<String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Live multi-key sequence state (which-key input).
final class KeymapPendingSequence {
  const KeymapPendingSequence({
    required this.surfaceId,
    required this.matchedKeys,
    required this.matchedLabels,
    required this.candidates,
  });

  /// Surface that owns this pending sequence.
  final String surfaceId;

  /// Key specs matched so far (e.g. `['ctrl+x']`).
  final List<String> matchedKeys;

  /// Display labels for matched steps.
  final List<String> matchedLabels;

  /// Bindings still possible given [matchedKeys].
  final List<ShortcutBinding> candidates;

  /// Compact prefix label (first matched step).
  String get prefixLabel =>
      matchedLabels.isEmpty ? '' : matchedLabels.first;

  /// Full matched path as a single string.
  String get matchedPath => matchedLabels.join(' ');

  /// Continuation steps for which-key (next key only).
  List<ShortcutContinuation> get continuations {
    final depth = matchedKeys.length;
    final out = <ShortcutContinuation>[];
    final seen = <String>{};
    for (final b in candidates) {
      if (b.keys.length <= depth) continue;
      final next = b.labels[depth];
      if (!seen.add('${b.id}:$next')) continue;
      out.add(
        ShortcutContinuation(
          keyLabel: next,
          description: b.description,
          group: b.group,
          actionId: b.id,
          binding: b,
        ),
      );
    }
    return out;
  }
}

/// One which-key row for the next key in a pending sequence.
final class ShortcutContinuation {
  const ShortcutContinuation({
    required this.keyLabel,
    required this.description,
    required this.group,
    required this.actionId,
    required this.binding,
  });

  final String keyLabel;
  final String description;
  final String group;
  final String actionId;
  final ShortcutBinding binding;
}

/// Map chord bindings into [ShortcutBinding]s.
List<ShortcutBinding> shortcutBindingsFromChords(
  Iterable<KeyChordBinding> chords,
) {
  return [for (final c in chords) ShortcutBinding.fromChord(c)];
}

/// Join key labels for display (`ctrl+x` + `b` → `ctrl+x b`).
String formatShortcutKeys(List<String> labels, {String separator = ' '}) {
  return labels.where((l) => l.isNotEmpty).join(separator);
}

/// Build a [KeyMap] for [HelpView] from shortcut bindings.
///
/// Groups by [ShortcutBinding.group]; each group becomes a full-help column.
KeyMap keyMapFromShortcutBindings(Iterable<ShortcutBinding> bindings) {
  final byGroup = <String, List<KeyBinding>>{};
  for (final b in bindings) {
    byGroup.putIfAbsent(b.group, () => []).add(
      KeyBinding.withHelp([b.formattedKeys], b.formattedKeys, b.description),
    );
  }
  final short = <KeyBinding>[
    for (final list in byGroup.values) ...list,
  ];
  final full = [
    for (final list in byGroup.values)
      if (list.isNotEmpty) list,
  ];
  return KeyMap(shortHelp: short, fullHelp: full.isEmpty ? [short] : full);
}
