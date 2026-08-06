/// Surface-first layered key/message interception (OpenTUI keymap-inspired).
///
/// [KeymapHub] is the single [ProgramInterceptor] installed on a [Program].
/// Shortcut surfaces push/pop at runtime (routes, dialogs); base interceptors
/// (replay, devtools) always run **after** the surface stack.
///
/// Surfaces may declare [ShortcutBinding]s for single keys and multi-key
/// sequences (leader chords). Pending sequences expose which-key data via
/// [KeymapHub.pending].
///
library;

import 'dart:async';

import 'degradation.dart' show DegradationLevel;
import 'key.dart' show Key;
import 'msg.dart';
import 'program.dart' show ProgramInterceptor, ResettableInterceptor;
import 'shortcut_binding.dart';
import 'terminal_native_frame.dart'
    show
        TerminalNativeCellDeltaFrame,
        TerminalNativeDeltaFrame,
        TerminalNativeFrame,
        TerminalNativeSpanDelta;

// ---------------------------------------------------------------------------
// Layer result
// ---------------------------------------------------------------------------

/// Outcome of a [ShortcutSurface] handling one message.
sealed class KeymapLayerResult {
  const KeymapLayerResult();
}

/// Surface did not handle the message — try the next layer (or drop if
/// [ShortcutSurface.exclusive]).
final class KeymapLayerPass extends KeymapLayerResult {
  const KeymapLayerPass();
}

/// Surface claims the message (optionally transformed). Stops the stack.
final class KeymapLayerClaim extends KeymapLayerResult {
  const KeymapLayerClaim(this.msg);

  /// Message to enqueue (may be a transform of the input).
  final Msg msg;
}

/// Surface swallows the message. Stops the stack; nothing is enqueued.
final class KeymapLayerDrop extends KeymapLayerResult {
  const KeymapLayerDrop();
}

// ---------------------------------------------------------------------------
// Internal timeout
// ---------------------------------------------------------------------------

final class _SequenceTimeoutMsg extends Msg {
  const _SequenceTimeoutMsg({
    required this.surfaceId,
    required this.sessionId,
  });

  final String surfaceId;
  final int sessionId;
}

// ---------------------------------------------------------------------------
// Surface
// ---------------------------------------------------------------------------

/// A named, stackable input layer (route, dialog, editor chrome, …).
///
/// Dispatch order inside a surface:
/// 1. [bindings] sequence/single engine (if non-empty)
/// 2. [onMessage] custom handler
/// 3. nested [interceptor]
final class ShortcutSurface {
  /// Creates a surface.
  ShortcutSurface({
    required this.id,
    this.exclusive = false,
    List<ShortcutBinding> bindings = const [],
    this.sequenceTimeout,
    this.interceptor,
    this.onMessage,
    this.meta = const {},
  }) : bindings = List.unmodifiable(bindings);

  /// Stable id for push/pop/replace (e.g. `session`, `confirm-dialog`).
  final String id;

  /// When `true`, an unhandled message is **dropped** (no fallthrough).
  final bool exclusive;

  /// Shortcut catalog for this surface (singles + sequences).
  final List<ShortcutBinding> bindings;

  /// Auto-cancel pending sequences after this duration (`null` = wait forever).
  final Duration? sequenceTimeout;

  /// Optional nested interceptor (e.g. legacy [KeyChordInterceptor]).
  final ProgramInterceptor? interceptor;

  /// Explicit layer handler after bindings.
  final KeymapLayerResult Function(Msg msg)? onMessage;

  /// Optional metadata (title, group, …) for discovery UIs.
  final Map<String, Object?> meta;

  // Sequence runtime (owned by surface; cleared on [reset]).
  int _nextSessionId = 0;
  int? _pendingSessionId;
  List<String> _matchedKeys = const [];
  List<String> _matchedLabels = const [];
  List<ShortcutBinding> _candidates = const [];
  Timer? _timer;
  void Function(Msg msg)? _send;

  /// Whether a multi-key sequence is pending on this surface.
  bool get isSequencePending => _pendingSessionId != null;

  /// Pending sequence snapshot, or `null`.
  KeymapPendingSequence? get pending {
    if (_pendingSessionId == null) return null;
    return KeymapPendingSequence(
      surfaceId: id,
      matchedKeys: List.unmodifiable(_matchedKeys),
      matchedLabels: List.unmodifiable(_matchedLabels),
      candidates: List.unmodifiable(_candidates),
    );
  }

  /// Bind [send] for sequence timeouts (called from hub [onStart] / push).
  void attachSend(void Function(Msg msg)? send) {
    _send = send;
  }

  /// Dispatch [msg] through this surface.
  KeymapLayerResult handle(Msg msg) {
    // Sequence timeouts are surface-scoped.
    if (msg is _SequenceTimeoutMsg) {
      if (msg.surfaceId != id) return const KeymapLayerPass();
      if (_pendingSessionId != msg.sessionId) {
        return const KeymapLayerDrop(); // stale
      }
      _clearPending();
      return KeymapLayerClaim(
        KeymapSequenceCancelledMsg(surfaceId: id, timedOut: true),
      );
    }

    if (bindings.isNotEmpty && msg is KeyMsg) {
      final seq = _handleKey(msg.key);
      if (seq != null) return seq;
    }

    final custom = onMessage;
    if (custom != null) {
      final result = custom(msg);
      if (result is! KeymapLayerPass) return result;
    }

    final nested = interceptor;
    if (nested != null) {
      final out = nested.onSend(msg);
      if (out == null) return const KeymapLayerDrop();
      // Nested interceptor always claims non-null results (Phase 0 contract).
      // Use bindings for fallthrough-aware catalogs; nested is opaque.
      return KeymapLayerClaim(out);
    }

    return const KeymapLayerPass();
  }

  /// Clear pending multi-key state and nested resettables.
  void reset() {
    _clearPending();
    switch (interceptor) {
      case final ResettableInterceptor r:
        r.reset();
      default:
        break;
    }
  }

  KeymapLayerResult? _handleKey(Key key) {
    // Continue pending sequence.
    if (_pendingSessionId != null) {
      final next = <ShortcutBinding>[];
      final depth = _matchedKeys.length;
      for (final b in _candidates) {
        if (b.matchesStep(key, depth)) next.add(b);
      }

      if (next.isEmpty) {
        // Unmatched continuation: cancel and do not consume the key so
        // fallthrough can handle it — but exclusive hub may still drop.
        // OpenCode-style: cancel + forward key. We claim a cancel batch.
        final cancel = KeymapSequenceCancelledMsg(surfaceId: id, key: key);
        _clearPending();
        // Forward original key after cancel (batch).
        return KeymapLayerClaim(
          BatchMsg([cancel, KeyMsg(key)]),
        );
      }

      // Exact complete match (prefer shortest complete at this depth).
      final complete = next.where((b) => b.keys.length == depth + 1).toList();
      if (complete.isNotEmpty) {
        final hit = complete.first;
        _clearPending();
        return KeymapLayerClaim(
          KeymapActionMsg(
            id: hit.id,
            surfaceId: id,
            sequence: hit.keys,
            key: key,
          ),
        );
      }

      // Still a prefix of longer sequences.
      _matchedKeys = [..._matchedKeys, next.first.keys[depth]];
      _matchedLabels = [..._matchedLabels, next.first.labels[depth]];
      _candidates = next;
      _armTimeout();
      return KeymapLayerClaim(
        KeymapSequencePrefixMsg(
          surfaceId: id,
          matchedKeys: List.unmodifiable(_matchedKeys),
          matchedLabels: List.unmodifiable(_matchedLabels),
        ),
      );
    }

    // Start sequence or fire single-key.
    final singles = <ShortcutBinding>[];
    final sequenceStarts = <ShortcutBinding>[];
    for (final b in bindings) {
      if (!b.matchesStep(key, 0)) continue;
      if (b.keys.length == 1) {
        singles.add(b);
      } else {
        sequenceStarts.add(b);
      }
    }

    // Prefer starting a multi-key sequence when any longer binding matches
    // the first key (leader). Singles with the same key fire only if no
    // sequence starts on that key — matches OpenCode leader behavior.
    if (sequenceStarts.isNotEmpty) {
      _pendingSessionId = ++_nextSessionId;
      _matchedKeys = [sequenceStarts.first.keys[0]];
      _matchedLabels = [sequenceStarts.first.labels[0]];
      _candidates = sequenceStarts;
      _armTimeout();
      return KeymapLayerClaim(
        KeymapSequencePrefixMsg(
          surfaceId: id,
          matchedKeys: List.unmodifiable(_matchedKeys),
          matchedLabels: List.unmodifiable(_matchedLabels),
        ),
      );
    }

    if (singles.isNotEmpty) {
      final hit = singles.first;
      return KeymapLayerClaim(
        KeymapActionMsg(
          id: hit.id,
          surfaceId: id,
          sequence: hit.keys,
          key: key,
        ),
      );
    }

    return null; // not handled by bindings
  }

  void _armTimeout() {
    _timer?.cancel();
    _timer = null;
    final t = sequenceTimeout;
    final session = _pendingSessionId;
    final send = _send;
    if (t == null || session == null || send == null) return;
    _timer = Timer(t, () {
      send(
        _SequenceTimeoutMsg(surfaceId: id, sessionId: session),
      );
    });
  }

  void _clearPending() {
    _timer?.cancel();
    _timer = null;
    _pendingSessionId = null;
    _matchedKeys = const [];
    _matchedLabels = const [];
    _candidates = const [];
  }

  ShortcutSurface copyWith({
    String? id,
    bool? exclusive,
    List<ShortcutBinding>? bindings,
    Duration? sequenceTimeout,
    ProgramInterceptor? interceptor,
    KeymapLayerResult Function(Msg msg)? onMessage,
    Map<String, Object?>? meta,
  }) {
    return ShortcutSurface(
      id: id ?? this.id,
      exclusive: exclusive ?? this.exclusive,
      bindings: bindings ?? this.bindings,
      sequenceTimeout: sequenceTimeout ?? this.sequenceTimeout,
      interceptor: interceptor ?? this.interceptor,
      onMessage: onMessage ?? this.onMessage,
      meta: meta ?? this.meta,
    );
  }
}

// ---------------------------------------------------------------------------
// Hub
// ---------------------------------------------------------------------------

/// Program interceptor that owns a dynamic **surface-first** stack plus
/// optional base layers.
///
/// ```dart
/// final hub = KeymapHub();
/// hub.push(ShortcutSurface(
///   id: 'session',
///   bindings: [
///     ShortcutBinding.chord(
///       id: 'sidebar_toggle',
///       leader: 'ctrl+x',
///       key: 'b',
///       description: 'toggle sidebar',
///     ),
///   ],
/// ));
/// ```
///
/// **Order on [onSend]:** top surface → … → bottom surface → [base].
/// Exclusive surfaces that pass drop the message.
final class KeymapHub extends ProgramInterceptor {
  /// Creates a hub.
  KeymapHub({
    List<ProgramInterceptor> base = const [],
    this.onStackChanged,
    this.onPendingChanged,
  }) : _base = List<ProgramInterceptor>.of(base);

  final List<ProgramInterceptor> _base;
  final List<ShortcutSurface> _stack = [];
  final List<void Function()> _listeners = [];

  void Function(Msg msg)? _send;

  /// Invoked after push/pop/replace/clear (for widget rebuilds).
  void Function()? onStackChanged;

  /// Invoked when any surface's pending sequence starts/clears.
  void Function()? onPendingChanged;

  /// Register a listener for stack or pending-sequence changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Remove a previously registered [listener].
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Base interceptors (never popped by surface APIs).
  List<ProgramInterceptor> get base => List.unmodifiable(_base);

  /// Surface stack, bottom → top (top is last).
  List<ShortcutSurface> get stack => List.unmodifiable(_stack);

  /// Top surface, if any.
  ShortcutSurface? get top => _stack.isEmpty ? null : _stack.last;

  /// Ids of surfaces currently on the stack (bottom → top).
  List<String> get surfaceIds => [for (final s in _stack) s.id];

  /// Whether [id] is on the stack.
  bool contains(String id) => _stack.any((s) => s.id == id);

  /// Pending multi-key sequence on the top surface (or any surface).
  ///
  /// Prefers the topmost surface that has pending state.
  KeymapPendingSequence? get pending {
    for (var i = _stack.length - 1; i >= 0; i--) {
      final p = _stack[i].pending;
      if (p != null) return p;
    }
    return null;
  }

  /// Whether any surface has a pending multi-key sequence.
  bool get isSequencePending => pending != null;

  /// Prefix label for which-key / footer (`ctrl+x`), or empty.
  String get pendingPrefixLabel => pending?.prefixLabel ?? '';

  /// Continuation rows for the active pending sequence.
  List<ShortcutContinuation> get activeContinuations =>
      pending?.continuations ?? const [];

  /// Compact status hint while a sequence is pending (`ctrl+x …`).
  String get pendingStatusHint {
    final label = pendingPrefixLabel;
    if (label.isEmpty) return '';
    return '$label …';
  }

  /// All bindings from the top surface (for shortcuts sheets).
  List<ShortcutBinding> get topBindings =>
      top == null ? const [] : top!.bindings;

  /// Bindings for discovery UIs.
  ///
  /// By default only the **top** surface. When [includeReachable] is true and
  /// the top surface is not exclusive, also includes lower surfaces until an
  /// exclusive layer is hit (bottom-up accumulate, top first).
  List<ShortcutBinding> activeShortcuts({bool includeReachable = false}) {
    if (_stack.isEmpty) return const [];
    if (!includeReachable) {
      return List.unmodifiable(top!.bindings);
    }

    final out = <ShortcutBinding>[];
    final seen = <String>{};
    for (var i = _stack.length - 1; i >= 0; i--) {
      final surface = _stack[i];
      for (final b in surface.bindings) {
        if (seen.add(b.id)) out.add(b);
      }
      if (surface.exclusive) break;
    }
    return List.unmodifiable(out);
  }

  /// Cancel pending sequences on every surface.
  void resetPending() {
    var any = false;
    for (final s in _stack) {
      if (s.isSequencePending) any = true;
      s.reset();
    }
    if (any) onPendingChanged?.call();
  }

  /// Push [surface] as the new top.
  ///
  /// If a surface with the same [ShortcutSurface.id] already exists it is
  /// **moved to the top** (bring-to-front). Prefer [replace] to update config
  /// without reordering, or [activate] to only reorder.
  ///
  /// Resets pending state on the previous top (surface switch cancels chords).
  void push(ShortcutSurface surface) {
    final prevTop = top;
    if (prevTop != null && prevTop.id != surface.id) {
      prevTop.reset();
    }
    final existing = _indexOf(surface.id);
    if (existing >= 0) {
      _stack[existing].reset();
      _stack[existing].interceptor?.onStop();
      _stack[existing].attachSend(null);
      _stack.removeAt(existing);
    }
    _stack.add(surface);
    surface.attachSend(_send);
    final send = _send;
    if (send != null) {
      surface.interceptor?.onStart(send);
    }
    _notifyStack();
    onPendingChanged?.call();
  }

  /// Move an existing surface to the top without changing others' relative order.
  ///
  /// No-op if [id] is missing or already top. Resets pending on the previous top.
  bool activate(String id) {
    final i = _indexOf(id);
    if (i < 0) return false;
    if (i == _stack.length - 1) return true;
    final prevTop = top;
    prevTop?.reset();
    final surface = _stack.removeAt(i);
    _stack.add(surface);
    _notifyStack();
    onPendingChanged?.call();
    return true;
  }

  /// Remove the top surface, or the surface named [id] if given.
  ShortcutSurface? pop([String? id]) {
    if (_stack.isEmpty) return null;

    if (id == null) {
      final removed = _stack.removeLast();
      removed.reset();
      removed.attachSend(null);
      _notifyStack();
      onPendingChanged?.call();
      return removed;
    }

    final i = _indexOf(id);
    if (i < 0) return null;
    final removed = _stack.removeAt(i);
    removed.reset();
    removed.attachSend(null);
    _notifyStack();
    onPendingChanged?.call();
    return removed;
  }

  /// Replace the surface with [surface.id], or push if missing.
  void replace(ShortcutSurface surface) {
    final i = _indexOf(surface.id);
    if (i < 0) {
      push(surface);
      return;
    }
    _stack[i].reset();
    _stack[i].interceptor?.onStop();
    _stack[i].attachSend(null);
    _stack[i] = surface;
    surface.attachSend(_send);
    final send = _send;
    if (send != null) {
      surface.interceptor?.onStart(send);
    }
    _notifyStack();
    onPendingChanged?.call();
  }

  /// Pop until [id] is top (removes layers above it).
  void popUntil(String id) {
    final i = _indexOf(id);
    if (i < 0) return;
    while (_stack.length > i + 1) {
      final removed = _stack.removeLast();
      removed.reset();
      removed.attachSend(null);
    }
    _notifyStack();
    onPendingChanged?.call();
  }

  /// Clear all surfaces (base remains).
  void clearSurfaces() {
    if (_stack.isEmpty) return;
    for (final s in _stack) {
      s.reset();
      s.attachSend(null);
    }
    _stack.clear();
    _notifyStack();
    onPendingChanged?.call();
  }

  /// Append a base interceptor (e.g. late-bound devtools).
  void addBase(ProgramInterceptor interceptor) {
    _base.add(interceptor);
    if (_send != null) {
      interceptor.onStart(_send!);
    }
  }

  // ---------------------------------------------------------------------------
  // ProgramInterceptor
  // ---------------------------------------------------------------------------

  @override
  bool get wantsNativeFrames {
    for (final s in _stack) {
      if (s.interceptor?.wantsNativeFrames ?? false) return true;
    }
    for (final b in _base) {
      if (b.wantsNativeFrames) return true;
    }
    return false;
  }

  @override
  void onStart(void Function(Msg msg) send) {
    _send = send;
    for (final s in _stack) {
      s.attachSend(send);
      s.interceptor?.onStart(send);
    }
    for (final b in _base) {
      b.onStart(send);
    }
  }

  @override
  Msg? onSend(Msg msg) {
    // Timeouts always go to the owning surface first.
    if (msg is _SequenceTimeoutMsg) {
      for (final s in _stack) {
        if (s.id == msg.surfaceId) {
          final result = s.handle(msg);
          switch (result) {
            case KeymapLayerClaim(:final msg):
              onPendingChanged?.call();
              return msg;
            case KeymapLayerDrop():
              return null;
            case KeymapLayerPass():
              return null;
          }
        }
      }
      return null;
    }

    final hadPending = isSequencePending;

    // Surface-first: top of stack → bottom.
    for (var i = _stack.length - 1; i >= 0; i--) {
      final surface = _stack[i];
      final result = surface.handle(msg);
      switch (result) {
        case KeymapLayerPass():
          if (surface.exclusive) {
            if (hadPending != isSequencePending) onPendingChanged?.call();
            return null;
          }
          continue;
        case KeymapLayerClaim(:final msg):
          if (hadPending != isSequencePending ||
              msg is KeymapSequencePrefixMsg ||
              msg is KeymapSequenceCancelledMsg ||
              msg is KeymapActionMsg) {
            onPendingChanged?.call();
          }
          return msg;
        case KeymapLayerDrop():
          if (hadPending != isSequencePending) onPendingChanged?.call();
          return null;
      }
    }

    // Base layers last.
    var current = msg;
    for (final b in _base) {
      final out = b.onSend(current);
      if (out == null) return null;
      current = out;
    }
    return current;
  }

  @override
  void onProcessed(Msg msg, Duration elapsed) {
    for (var i = _stack.length - 1; i >= 0; i--) {
      _stack[i].interceptor?.onProcessed(msg, elapsed);
    }
    for (final b in _base) {
      b.onProcessed(msg, elapsed);
    }
  }

  @override
  void onRendered({
    required int renderGeneration,
    required Object view,
    required DegradationLevel degradationLevel,
    required Duration renderDuration,
    int? width,
    int? height,
    TerminalNativeFrame? nativeFrame,
    TerminalNativeDeltaFrame? nativeDelta,
    TerminalNativeCellDeltaFrame? nativeCellDelta,
    List<TerminalNativeSpanDelta>? nativeSpanDelta,
  }) {
    for (var i = _stack.length - 1; i >= 0; i--) {
      _stack[i].interceptor?.onRendered(
        renderGeneration: renderGeneration,
        view: view,
        degradationLevel: degradationLevel,
        renderDuration: renderDuration,
        width: width,
        height: height,
        nativeFrame: nativeFrame,
        nativeDelta: nativeDelta,
        nativeCellDelta: nativeCellDelta,
        nativeSpanDelta: nativeSpanDelta,
      );
    }
    for (final b in _base) {
      b.onRendered(
        renderGeneration: renderGeneration,
        view: view,
        degradationLevel: degradationLevel,
        renderDuration: renderDuration,
        width: width,
        height: height,
        nativeFrame: nativeFrame,
        nativeDelta: nativeDelta,
        nativeCellDelta: nativeCellDelta,
        nativeSpanDelta: nativeSpanDelta,
      );
    }
  }

  @override
  void onStop() {
    for (final s in _stack) {
      s.reset();
      s.attachSend(null);
      s.interceptor?.onStop();
    }
    _stack.clear();
    for (final b in _base) {
      b.onStop();
    }
    _send = null;
    _emitListeners();
  }

  int _indexOf(String id) {
    for (var i = 0; i < _stack.length; i++) {
      if (_stack[i].id == id) return i;
    }
    return -1;
  }

  void _notifyStack() {
    onStackChanged?.call();
    _emitListeners();
  }

  void _emitListeners() {
    for (final l in List<void Function()>.of(_listeners)) {
      l();
    }
  }
}
