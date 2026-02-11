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
  final List<void Function()> _listeners = [];

  @override
  void addListener(void Function() listener) => _listeners.add(listener);

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Notify all registered listeners.
  ///
  /// Iterates over a *copy* of the listener list so that listeners may safely
  /// add or remove other listeners during the notification.
  void notifyListeners() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  /// Whether any listeners are currently registered.
  bool get hasListeners => _listeners.isNotEmpty;

  /// Releases all listeners. After this call the notifier should not be used.
  void dispose() => _listeners.clear();
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
