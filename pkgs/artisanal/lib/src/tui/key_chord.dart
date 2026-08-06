import 'dart:async';

import 'bubbles/key_binding.dart' show KeyBinding, KeyMap, keyMatchesSingle;
import 'key.dart';
import 'msg.dart';
import 'program.dart' show ProgramInterceptor, ResettableInterceptor;

/// A declarative chord binding made of a prefix key and a continuation key.
final class KeyChordBinding {
  const KeyChordBinding({
    required this.id,
    required this.prefix,
    required this.key,
  });

  /// Convenience constructor using help-key strings (e.g. `ctrl+x`, `b`).
  ///
  /// ```dart
  /// KeyChordBinding.simple(
  ///   id: 'toggle-sidebar',
  ///   leader: 'ctrl+x',
  ///   key: 'b',
  ///   description: 'toggle sidebar',
  ///   group: 'session',
  /// )
  /// ```
  factory KeyChordBinding.simple({
    required String id,
    required String leader,
    required String key,
    required String description,
    String group = 'Commands',
  }) {
    return KeyChordBinding(
      id: id,
      prefix: KeyBinding.withHelp([leader], leader, group),
      key: KeyBinding.withHelp([key], key, description),
    );
  }

  /// Stable identifier for the chord.
  final String id;

  /// The prefix key that starts the chord.
  final KeyBinding prefix;

  /// The continuation key that resolves the chord.
  final KeyBinding key;
}

final class _KeyChordTimeoutMsg extends Msg {
  const _KeyChordTimeoutMsg(this.sessionId);

  final int sessionId;
}

final class _ActiveChord {
  const _ActiveChord({
    required this.sessionId,
    required this.prefix,
    required this.bindings,
  });

  final int sessionId;
  final Key prefix;
  final List<KeyChordBinding> bindings;
}

/// Interceptor that turns prefix key sequences into chord messages.
final class KeyChordInterceptor extends ProgramInterceptor
    implements ResettableInterceptor {
  KeyChordInterceptor({
    required List<KeyChordBinding> bindings,
    this.timeout,
    this.inner,
  }) : _bindings = List.unmodifiable(bindings);

  /// Optional interceptor to compose underneath the chord layer.
  final ProgramInterceptor? inner;

  /// Chord definitions to recognize.
  final List<KeyChordBinding> _bindings;

  /// Read-only view of configured chord bindings.
  List<KeyChordBinding> get bindings => _bindings;

  /// Whether a chord prefix is currently pending.
  bool get isPending => _active != null;

  /// Active prefix key while a chord is pending, otherwise `null`.
  Key? get activePrefix => _active?.prefix;

  /// Bindings that match the currently pending prefix (empty when idle).
  List<KeyChordBinding> get activeBindings =>
      _active == null ? const [] : List.unmodifiable(_active!.bindings);

  /// How long to wait for the continuation key before cancelling.
  ///
  /// When `null` (the default) the interceptor waits indefinitely for the
  /// continuation key, matching opencode-style behavior. Set a duration to
  /// enable automatic cancellation after a period of inactivity.
  final Duration? timeout;

  void Function(Msg msg)? _send;
  Timer? _timer;
  int _nextSessionId = 0;
  _ActiveChord? _active;

  @override
  void onStart(void Function(Msg msg) send) {
    _send = send;
    inner?.onStart(send);
  }

  @override
  Msg? onSend(Msg msg) {
    final innerResult = inner?.onSend(msg);
    if (inner != null && innerResult == null) return null;

    final forwarded = innerResult ?? msg;
    if (forwarded is _KeyChordTimeoutMsg) {
      if (_active?.sessionId == forwarded.sessionId) {
        final active = _active!;
        _clearActive();
        return KeyChordCancelledMsg(prefix: active.prefix, timedOut: true);
      }
      return null;
    }

    if (forwarded is! KeyMsg) return forwarded;

    final key = forwarded.key;
    final active = _active;

    if (active != null) {
      final resolved = _matchContinuation(active, key);
      if (resolved != null) {
        _clearActive();
        return KeyChordResolvedMsg(
          id: resolved.id,
          prefix: active.prefix,
          key: key,
        );
      }

      if (_matchesAnyPrefix(key)) {
        final previousPrefix = active.prefix;
        _clearActive();
        _startChord(key);
        return BatchMsg([
          KeyChordCancelledMsg(prefix: previousPrefix, key: key),
          KeyChordPrefixMsg(key),
        ]);
      }

      final cancelled = KeyChordCancelledMsg(prefix: active.prefix, key: key);
      _clearActive();
      return BatchMsg([cancelled, forwarded]);
    }

    if (_matchesAnyPrefix(key)) {
      _startChord(key);
      return KeyChordPrefixMsg(key);
    }

    return forwarded;
  }

  @override
  void onStop() {
    _clearActive();
    inner?.onStop();
  }

  /// Clear pending chord state (e.g. when [KeymapHub] pops this surface).
  @override
  void reset() => _clearActive();

  bool _matchesAnyPrefix(Key key) {
    for (final binding in _bindings) {
      if (keyMatchesSingle(key, binding.prefix)) return true;
    }
    return false;
  }

  KeyChordBinding? _matchContinuation(_ActiveChord active, Key key) {
    for (final binding in active.bindings) {
      if (keyMatchesSingle(key, binding.key)) return binding;
    }
    return null;
  }

  void _startChord(Key prefix) {
    final matching = <KeyChordBinding>[];
    for (final binding in _bindings) {
      if (keyMatchesSingle(prefix, binding.prefix)) {
        matching.add(binding);
      }
    }
    if (matching.isEmpty) return;

    _clearActive();
    final sessionId = ++_nextSessionId;
    _active = _ActiveChord(
      sessionId: sessionId,
      prefix: prefix,
      bindings: matching,
    );
    final t = timeout;
    if (t != null) {
      _timer = Timer(t, () {
        _send?.call(_KeyChordTimeoutMsg(sessionId));
      });
    }
  }

  void _clearActive() {
    _timer?.cancel();
    _timer = null;
    _active = null;
  }
}

/// Extracts chord bindings from [keyMap] for use with [KeyChordInterceptor].
///
/// ```dart
/// final interceptor = KeyChordInterceptor(
///   bindings: chordBindings(myKeyMap),
/// );
/// ```
List<KeyChordBinding> chordBindings(KeyMap keyMap) {
  final chords = keyMap.chords;
  if (chords == null || chords.isEmpty) return [];
  return [
    for (final c in chords)
      KeyChordBinding(id: c.id, prefix: c.prefix, key: c.key),
  ];
}
