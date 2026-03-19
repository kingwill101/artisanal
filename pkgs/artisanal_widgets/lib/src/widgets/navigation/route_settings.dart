/// Route settings for the navigation system.
///
/// Provides metadata associated with a route, including its name and arguments.
library;

/// Immutable route metadata.
///
/// Describes a route configuration with an optional [name] for named routing
/// and optional [arguments] for passing data between routes.
///
/// ```dart
/// final settings = RouteSettings(name: '/details', arguments: {'id': 42});
/// ```
class RouteSettings {
  /// Creates route settings with the given [name] and [arguments].
  const RouteSettings({this.name, this.arguments});

  /// The name of the route (e.g., `'/settings'`).
  final String? name;

  /// Arbitrary arguments passed to the route.
  final Object? arguments;

  /// Creates a copy of these settings with the given fields replaced.
  RouteSettings copyWith({String? name, Object? arguments}) {
    return RouteSettings(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
    );
  }

  @override
  String toString() => 'RouteSettings(name: $name, arguments: $arguments)';
}
