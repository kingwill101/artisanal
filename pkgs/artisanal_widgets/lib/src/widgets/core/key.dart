/// Keys for widget identity.
///
/// Borrowed from Flutter's `foundation/key.dart`, trimmed for TUI use.
@experimental
library;

import 'package:meta/meta.dart' show immutable, experimental, protected;

/// A [Key] is an identifier for [Widget]s.
///
/// Keys must be unique amongst widgets with the same parent.
@immutable
abstract class Key {
  /// Construct a [ValueKey<String>] with the given [String].
  const factory Key(String value) = ValueKey<String>;

  /// Default constructor, used by subclasses.
  @protected
  const Key.empty();
}

/// A key that is not a [GlobalKey].
abstract class LocalKey extends Key {
  /// Abstract const constructor for subclasses.
  const LocalKey() : super.empty();
}

/// A key that is only equal to itself.
class UniqueKey extends LocalKey {
  /// Creates a key that is equal only to itself.
  // ignore: prefer_const_constructors_in_immutables
  UniqueKey();

  @override
  String toString() => '[#${shortHash(this)}]';
}

/// A key that uses a value of a particular type to identify itself.
class ValueKey<T> extends LocalKey {
  /// Creates a key that delegates its [operator==] to the given value.
  const ValueKey(this.value);

  /// The value to which this key delegates its [operator==].
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
    if (runtimeType == _TypeLiteral<ValueKey<T>>().type) {
      return '[$valueString]';
    }
    return '[$T $valueString]';
  }
}

class _TypeLiteral<T> {
  Type get type => T;
}

/// Short 5-hex hash for diagnostics.
String shortHash(Object? object) {
  if (object == null) return '00000';
  final int value = object.hashCode & 0xFFFFF;
  return value.toRadixString(16).padLeft(5, '0');
}
