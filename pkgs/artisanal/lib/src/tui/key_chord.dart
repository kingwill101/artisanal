import 'dart:async';

import 'bubbles/key_binding.dart' show KeyBinding, keyMatchesSingle;
import 'key.dart';
import 'msg.dart';
import 'program.dart' show ProgramInterceptor;

/// A declarative chord binding made of a prefix key and a continuation key.
final class KeyChordBinding {
  const KeyChordBinding({
    required this.id,
    required this.prefix,
    required this.key,
  });

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
final class KeyChordInterceptor extends ProgramInterceptor {
  KeyChordInterceptor({
    required List<KeyChordBinding> bindings,
    this.timeout,
    this.inner,
  }) : _bindings = List.unmodifiable(bindings);

  /// Optional interceptor to compose underneath the chord layer.
  final ProgramInterceptor? inner;

  /// Chord definitions to recognize.
  final List<KeyChordBinding> _bindings;

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
