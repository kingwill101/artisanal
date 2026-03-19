/// Observer pattern for navigation events.
///
/// Provides an abstract [NavigatorObserver] that can be subclassed to
/// listen for route push, pop, remove, and replace events.
library;

import 'route.dart';

/// An interface for observing the behavior of a [Navigator].
///
/// Subclass this and pass instances to [Navigator.observers] to receive
/// callbacks when routes are pushed, popped, removed, or replaced.
///
/// ```dart
/// class MyObserver extends NavigatorObserver {
///   @override
///   void didPush(Route route, Route? previousRoute) {
///     print('Pushed: ${route.settings.name}');
///   }
/// }
/// ```
abstract class NavigatorObserver {
  /// The navigator this observer is attached to.
  dynamic navigator;

  /// Called when a route is pushed onto the navigator.
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  /// Called when a route is popped from the navigator.
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  /// Called when a route is removed from the navigator.
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  /// Called when a route is replaced in the navigator.
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {}
}

/// A [NavigatorObserver] that logs navigation events to the console.
///
/// Useful for debugging route transitions during development.
///
/// ```dart
/// Navigator(
///   observers: [LoggingNavigatorObserver()],
///   home: HomeScreen(),
/// )
/// ```
class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // ignore: avoid_print
    print(
      'Navigator push: ${route.settings.name ?? route.runtimeType} '
      '(previous: ${previousRoute?.settings.name ?? previousRoute?.runtimeType})',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // ignore: avoid_print
    print(
      'Navigator pop: ${route.settings.name ?? route.runtimeType} '
      '(previous: ${previousRoute?.settings.name ?? previousRoute?.runtimeType})',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // ignore: avoid_print
    print(
      'Navigator remove: ${route.settings.name ?? route.runtimeType} '
      '(previous: ${previousRoute?.settings.name ?? previousRoute?.runtimeType})',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // ignore: avoid_print
    print(
      'Navigator replace: ${oldRoute?.settings.name ?? oldRoute?.runtimeType} '
      '-> ${newRoute?.settings.name ?? newRoute?.runtimeType}',
    );
  }
}
