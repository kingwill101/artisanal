part of 'framework.dart';

/// A key that is only equal to itself.
@immutable
abstract class Key {
  const factory Key(String value) = ValueKey<String>;

  const Key.empty();
}

/// A key that uses a value of a particular type to identify itself.
@immutable
class ValueKey<T> extends Key {
  const ValueKey(this.value) : super.empty();

  final T value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ValueKey<T> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    final String valueString = T == String ? "<'$value'>" : '<$value>';
    if (runtimeType == ValueKey<T>) {
      return '[$valueString]';
    }
    return '[$T $valueString]';
  }
}

/// A key that is unique across the entire app.
@immutable
class GlobalKey<T extends State> extends Key {
  factory GlobalKey({String? debugLabel}) => GlobalKey._(debugLabel);

  const GlobalKey._(this.debugLabel) : super.empty();

  final String? debugLabel;

  static final Map<GlobalKey, Element> _registry = <GlobalKey, Element>{};

  Element? get _currentElement => _registry[this];

  BuildContext? get currentContext => _currentElement;

  T? get currentState {
    final Element? element = _currentElement;
    if (element is StatefulElement) {
      final State state = element.state;
      if (state is T) {
        return state;
      }
    }
    return null;
  }

  void _register(Element element) {
    _registry[this] = element;
  }

  void _unregister(Element element) {
    if (_registry[this] == element) {
      _registry.remove(this);
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is GlobalKey && identical(other, this);
  }

  @override
  int get hashCode => Object.hash(runtimeType, identityHashCode(this));
}
