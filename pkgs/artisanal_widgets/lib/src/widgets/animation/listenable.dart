/// Observer pattern primitives for the animation system.
///
/// Provides [Listenable], [ValueListenable], [ChangeNotifier], and
/// [ValueNotifier] — the foundation that [Animation], [AnimationController],
/// and [AnimatedBuilder] are built on.
///
/// These classes are pure Dart with no framework dependencies.
library;

// ---------------------------------------------------------------------------
// Listenable
// ---------------------------------------------------------------------------

/// An object that maintains a list of listeners.
///
/// Listeners are notified when the object changes. This is the base type for
/// [Animation] and is consumed by [AnimatedBuilder] / [ListenableBuilder].
abstract class Listenable {
  const Listenable();

  /// Creates a [Listenable] that triggers when *any* of [listenables] fires.
  factory Listenable.merge(Iterable<Listenable?> listenables) =
      _MergingListenable;

  /// Register [listener] to be called when the object notifies.
  void addListener(void Function() listener);

  /// Remove a previously registered [listener].
  void removeListener(void Function() listener);
}

// ---------------------------------------------------------------------------
// ValueListenable
// ---------------------------------------------------------------------------

/// A [Listenable] that exposes a current [value].
abstract class ValueListenable<T> extends Listenable {
  const ValueListenable();

  /// The current value held by this object.
  T get value;
}

// ---------------------------------------------------------------------------
// ChangeNotifier
// ---------------------------------------------------------------------------

/// A [Listenable] implementation that stores listeners and can notify them.
///
/// Subclasses (or mixins) call [notifyListeners] whenever their state changes.
mixin class ChangeNotifier implements Listenable {
  final List<void Function()?> _listeners = <void Function()?>[];
  int _listenerCount = 0;
  int _notificationDepth = 0;
  bool _needsCompaction = false;
  bool _isDisposed = false;

  @override
  void addListener(void Function() listener) {
    throwIfDisposed();
    _listeners.add(listener);
    _listenerCount += 1;
  }

  @override
  void removeListener(void Function() listener) {
    if (_isDisposed) {
      return;
    }
    for (var i = 0; i < _listeners.length; i++) {
      if (_listeners[i] != listener) {
        continue;
      }
      if (_notificationDepth > 0) {
        _listeners[i] = null;
        _listenerCount -= 1;
        _needsCompaction = true;
      } else {
        _listeners.removeAt(i);
        _listenerCount -= 1;
      }
      return;
    }
  }

  /// Throws [StateError] if this notifier has already been disposed.
  void throwIfDisposed() {
    if (_isDisposed) {
      throw StateError(
        'A $runtimeType was used after being disposed. '
        'Once dispose() is called, it can no longer be used.',
      );
    }
  }

  /// Notify all registered listeners.
  ///
  void notifyListeners() {
    throwIfDisposed();
    if (_listenerCount == 0) {
      return;
    }
    _notificationDepth += 1;
    final end = _listeners.length;
    try {
      for (var i = 0; i < end; i++) {
        _listeners[i]?.call();
      }
    } finally {
      _notificationDepth -= 1;
      if (_notificationDepth == 0 && _needsCompaction) {
        _listeners.removeWhere((listener) => listener == null);
        _needsCompaction = false;
      }
    }
  }

  /// Whether any listeners are currently registered.
  bool get hasListeners => _listenerCount > 0;

  /// Releases all listeners. After this call the notifier should not be used.
  void dispose() {
    throwIfDisposed();
    if (_notificationDepth > 0) {
      throw StateError(
        'dispose() cannot be called while notifyListeners() is running.',
      );
    }
    _isDisposed = true;
    _listeners.clear();
    _listenerCount = 0;
    _needsCompaction = false;
  }
}

// ---------------------------------------------------------------------------
// ValueNotifier
// ---------------------------------------------------------------------------

/// A [ChangeNotifier] that holds a single value and notifies when it changes.
class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  /// Creates a [ValueNotifier] with the given initial [value].
  ValueNotifier(this._value);

  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    throwIfDisposed();
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// _MergingListenable (internal)
// ---------------------------------------------------------------------------

/// Combines multiple [Listenable]s into one. Fires when *any* child fires.
class _MergingListenable extends Listenable {
  _MergingListenable(this._listenables);

  final Iterable<Listenable?> _listenables;

  @override
  void addListener(void Function() listener) {
    for (final listenable in _listenables) {
      listenable?.addListener(listener);
    }
  }

  @override
  void removeListener(void Function() listener) {
    for (final listenable in _listenables) {
      listenable?.removeListener(listener);
    }
  }
}
