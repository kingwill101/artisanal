/// Single source of truth for key chords: bindings, interceptor, live state.
///
/// Define chords once on a [ChordController], pass [interceptor] to the
/// program, host with [ChordHost], and read pending state anywhere via
/// [ChordController.of] / [WhichKeySlot] — no parallel which-key map.
library;

import 'package:artisanal/runtime.dart' as tui;

import '../animation/listenable.dart';
import '../components/which_key.dart';
import '../core/framework.dart' show BuildContext;
import 'chord_scope.dart';

/// Owns chord definitions and the live pending-chord snapshot.
///
/// ```dart
/// final chords = ChordController(bindings: [
///   tui.KeyChordBinding.simple(
///     id: 'toggle-sidebar',
///     leader: 'ctrl+x',
///     key: 'b',
///     description: 'toggle sidebar',
///   ),
/// ]);
///
/// // main.dart
/// interceptor: chords.interceptor
///
/// // app
/// ChordHost(controller: chords, onResolved: handleId, child: ...)
///
/// // anywhere in the tree
/// final c = ChordController.of(context);
/// if (c.isActive) WhichKeySlot()
/// ```
class ChordController extends ChangeNotifier {
  ChordController({
    required List<tui.KeyChordBinding> bindings,
    this.timeout,
    tui.ProgramInterceptor? innerInterceptor,
  }) : _bindings = List.unmodifiable(bindings) {
    _interceptor = tui.KeyChordInterceptor(
      bindings: _bindings,
      timeout: timeout,
      inner: innerInterceptor,
    );
  }

  final List<tui.KeyChordBinding> _bindings;
  late final tui.KeyChordInterceptor _interceptor;

  /// How long the interceptor waits for a continuation key (`null` = forever).
  final Duration? timeout;

  bool _active = false;
  tui.Key? _prefix;
  String _prefixLabel = '';
  int _generation = 0;

  /// Bumps whenever pending state changes (for [ChordScope] notify).
  int get generation => _generation;

  /// All configured bindings (definition source of truth).
  List<tui.KeyChordBinding> get bindings => _bindings;

  /// Program interceptor derived from the same [bindings].
  ///
  /// Use this in [tui.ProgramOptions.interceptor] so interception and UI
  /// never diverge.
  tui.ProgramInterceptor get interceptor => _interceptor;

  /// Underlying interceptor (same instance as [interceptor]).
  tui.KeyChordInterceptor get keyChordInterceptor => _interceptor;

  /// Whether a leader/prefix chord is pending.
  bool get isActive => _active;

  /// Active prefix key, if any.
  tui.Key? get prefix => _prefix;

  /// Human-readable prefix (from binding help, e.g. `ctrl+x`).
  String get prefixLabel => _prefixLabel;

  /// Continuation entries for the active prefix (empty when idle).
  ///
  /// Derived from [bindings] — not a second hand-maintained list.
  List<WhichKeyEntry> get entries {
    if (!_active) return const [];
    return whichKeyEntriesFromChords(
      _bindings,
      prefixKeyLabel: _prefixLabel.isEmpty ? null : _prefixLabel,
    );
  }

  /// Compact status-row hint while pending (e.g. `ctrl+x …`).
  String get statusHint =>
      _active && _prefixLabel.isNotEmpty ? '$_prefixLabel …' : '';

  /// Space-separated continuation key labels (`b l m t …`).
  String get continuationKeysLabel =>
      entries.map((e) => e.keyLabel).join(' ');

  /// Banner-friendly line for which-key chrome.
  String whichKeyBanner({String title = 'which-key'}) {
    if (!_active) return '';
    final keys = continuationKeysLabel;
    if (keys.isEmpty) return ' $title  $_prefixLabel ';
    return ' $title  $_prefixLabel then:  $keys ';
  }

  /// Nearest [ChordController] from the tree, or `null`.
  static ChordController? maybeOf(BuildContext context) {
    return ChordScope.maybeOf(context)?.controller;
  }

  /// Nearest [ChordController]; asserts if missing.
  static ChordController of(BuildContext context) {
    final c = maybeOf(context);
    assert(c != null, 'ChordController.of() called with no ChordScope ancestor');
    return c!;
  }

  /// Apply a chord / keymap lifecycle message from the program loop.
  ///
  /// Returns the resolved action id when appropriate, otherwise `null`.
  /// Prefer [ChordHost] or [KeymapHubScope], which call this automatically.
  String? applyMessage(tui.Msg msg) {
    if (msg is tui.BatchMsg) {
      String? resolved;
      for (final m in msg.messages) {
        resolved = applyMessage(m) ?? resolved;
      }
      return resolved;
    }

    // KeymapHub sequence messages (Phase 1+).
    if (msg is tui.KeymapSequencePrefixMsg) {
      _setActiveLabel(
        msg.matchedLabels.isNotEmpty
            ? msg.matchedLabels.first
            : (msg.matchedKeys.isNotEmpty ? msg.matchedKeys.first : ''),
      );
      return null;
    }
    if (msg is tui.KeymapActionMsg) {
      _clearActive();
      return msg.id;
    }
    if (msg is tui.KeymapSequenceCancelledMsg) {
      _clearActive();
      return null;
    }

    // Legacy KeyChordInterceptor messages.
    if (msg is tui.KeyChordPrefixMsg) {
      _setActive(msg.prefix);
      return null;
    }
    if (msg is tui.KeyChordResolvedMsg) {
      _clearActive();
      return msg.id;
    }
    if (msg is tui.KeyChordCancelledMsg) {
      _clearActive();
      return null;
    }
    return null;
  }

  /// Whether [msg] is a chord/keymap lifecycle message this controller understands.
  static bool isChordMessage(tui.Msg msg) {
    return msg is tui.KeyChordPrefixMsg ||
        msg is tui.KeyChordResolvedMsg ||
        msg is tui.KeyChordCancelledMsg ||
        msg is tui.KeymapSequencePrefixMsg ||
        msg is tui.KeymapActionMsg ||
        msg is tui.KeymapSequenceCancelledMsg ||
        msg is tui.BatchMsg;
  }

  void _setActive(tui.Key prefix) {
    final label = _labelForPrefix(prefix);
    if (_active && _prefix == prefix && _prefixLabel == label) return;
    _active = true;
    _prefix = prefix;
    _prefixLabel = label;
    _generation++;
    notifyListeners();
  }

  void _setActiveLabel(String label) {
    if (_active && _prefixLabel == label) return;
    _active = true;
    _prefix = null;
    _prefixLabel = label;
    _generation++;
    notifyListeners();
  }

  void _clearActive() {
    if (!_active && _prefix == null) return;
    _active = false;
    _prefix = null;
    _prefixLabel = '';
    _generation++;
    notifyListeners();
  }

  String _labelForPrefix(tui.Key prefix) {
    for (final b in _bindings) {
      if (tui.keyMatchesSingle(prefix, b.prefix)) {
        final help = b.prefix.help;
        if (help.key.isNotEmpty) return help.key;
        if (b.prefix.keys.isNotEmpty) return b.prefix.keys.first;
      }
    }
    // Fallback: best-effort from Key (Key(Ctrl+x) → ctrl+x).
    final raw = prefix.toString();
    final match = RegExp(r'Key\((.+)\)$').firstMatch(raw);
    if (match != null) {
      return match.group(1)!.toLowerCase().replaceAll('ctrl', 'ctrl');
    }
    return raw;
  }
}
