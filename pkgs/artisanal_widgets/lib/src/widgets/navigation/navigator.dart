/// Navigator widget for managing a stack of routes.
///
/// Provides a Flutter-like navigation system adapted for the TEA
/// (The Elm Architecture) message-passing model used by artisanal_widgets.
library;

import 'dart:async' show Completer;

import 'package:artisanal/runtime.dart' show Cmd, Msg, KeyMsg;
import 'package:artisanal/style.dart' hide Padding, Align;

import '../components/overlay.dart';
import '../core/framework.dart' show BuildContext, State, StatefulWidget;
import '../core/key.dart' show Key, UniqueKey;
import '../core/widget.dart';
import '../focus/focus.dart' show FocusScope;
import '../layout/_layout_core.dart';
import 'navigator_observer.dart';
import 'pop_behavior.dart';
import 'route.dart';
import 'route_settings.dart';
import 'dialog_route.dart' show DialogRoute;
import 'animation_style.dart' show AnimationStyle;

/// A widget that manages a stack of [Route] objects.
///
/// The navigator maintains a route stack and provides methods to push
/// and pop routes, similar to Flutter's [Navigator]. Each route produces
/// overlay entries that are rendered in a layered [Overlay].
///
/// ## Basic usage
///
/// ```dart
/// Navigator(
///   home: HomeScreen(),
/// )
/// ```
///
/// ## Named routing
///
/// ```dart
/// Navigator(
///   initialRoute: '/',
///   routes: {
///     '/': (context) => HomeScreen(),
///     '/settings': (context) => SettingsScreen(),
///     '/profile': (context) => ProfileScreen(),
///   },
/// )
/// ```
///
/// ## Accessing the navigator
///
/// ```dart
/// Navigator.of(context).push(PageRoute(
///   builder: (context) => DetailScreen(),
/// ));
/// ```
class Navigator extends StatefulWidget {
  /// Creates a navigator.
  ///
  /// At least one of [home], [routes], or [onGenerateRoute] must be provided
  /// so the navigator can create an initial route.
  Navigator({
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.popBehavior = const PopBehavior(),
    this.observers = const [],
    super.key,
  });

  /// The widget for the default route of the navigator.
  ///
  /// If provided, this is wrapped in a [PageRoute] with name `'/'`.
  final Widget? home;

  /// A map of named routes.
  ///
  /// Each key is a route name (e.g., `'/settings'`) and each value
  /// is a builder function that creates the route's widget.
  final Map<String, Widget Function(BuildContext)>? routes;

  /// The name of the first route to display.
  ///
  /// Defaults to `'/'`. If [routes] or [onGenerateRoute] can handle
  /// this route, it will be pushed on initialization.
  final String? initialRoute;

  /// Called to generate a route for a given [RouteSettings].
  ///
  /// Used when the named route is not found in [routes].
  final RouteFactory? onGenerateRoute;

  /// Called when [onGenerateRoute] fails to generate a route.
  ///
  /// Typically used to show a "404" or "not found" screen.
  final RouteFactory? onUnknownRoute;

  /// Configuration for keyboard-triggered pop behavior.
  final PopBehavior popBehavior;

  /// Observers that receive notifications of route changes.
  final List<NavigatorObserver> observers;

  /// Returns the [NavigatorState] from the closest [Navigator] ancestor.
  ///
  /// Throws a [StateError] if no [Navigator] ancestor is found.
  static NavigatorState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'Navigator.of() called with a context that does not contain '
        'a Navigator.',
      );
    }
    return state;
  }

  /// Returns the [NavigatorState] from the closest [Navigator] ancestor,
  /// or `null` if no [Navigator] ancestor exists.
  static NavigatorState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<NavigatorState>();
  }

  @override
  State<Navigator> createState() => NavigatorState();
}

/// State for [Navigator], providing route stack management.
///
/// Access this via [Navigator.of(context)] to push, pop, and manage routes.
class NavigatorState extends State<Navigator> {
  final List<Route<dynamic>> _routes = [];
  final Map<Route<dynamic>, Completer<dynamic>> _routeCompleters = {};
  final Map<OverlayEntry, Key> _entryKeys = {};

  @override
  void initState() {
    super.initState();
    // Attach observers.
    for (final observer in widget.observers) {
      observer.navigator = this;
    }
    _initializeRoutes();
  }

  @override
  void dispose() {
    // Dispose all routes.
    for (final route in _routes.reversed.toList()) {
      route.dispose();
    }
    _routes.clear();
    _entryKeys.clear();
    // Complete any pending futures with null.
    for (final completer in _routeCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _routeCompleters.clear();
    // Detach observers.
    for (final observer in widget.observers) {
      observer.navigator = null;
    }
    super.dispose();
  }

  void _initializeRoutes() {
    if (widget.home != null) {
      // Push the home widget as the initial route.
      final route = PageRoute<void>(
        builder: (_) => widget.home!,
        settings: const RouteSettings(name: '/'),
      );
      _installRoute(route);
    } else if (widget.initialRoute != null) {
      _buildInitialRouteStack(widget.initialRoute!);
    } else if (widget.routes != null && widget.routes!.containsKey('/')) {
      // Use the '/' route from the routes map.
      final route = PageRoute<void>(
        builder: widget.routes!['/']!,
        settings: const RouteSettings(name: '/'),
      );
      _installRoute(route);
    }
  }

  void _buildInitialRouteStack(String routeName) {
    // Split path segments and push routes incrementally.
    // e.g., '/a/b/c' → push '/', '/a', '/a/b', '/a/b/c'
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      // Just push '/'
      final route = _createRoute(const RouteSettings(name: '/'));
      if (route != null) _installRoute(route);
      return;
    }

    var currentPath = '';
    for (final segment in segments) {
      currentPath = '$currentPath/$segment';
      final route = _createRoute(RouteSettings(name: currentPath));
      if (route != null) _installRoute(route);
    }

    // If no routes were pushed, try the full path as a single route.
    if (_routes.isEmpty) {
      final route = _createRoute(RouteSettings(name: routeName));
      if (route != null) _installRoute(route);
    }
  }

  Route<dynamic>? _createRoute(RouteSettings settings) {
    // Try named routes map first.
    if (widget.routes != null && settings.name != null) {
      final builder = widget.routes![settings.name!];
      if (builder != null) {
        return PageRoute<dynamic>(builder: builder, settings: settings);
      }
    }

    // Try onGenerateRoute.
    if (widget.onGenerateRoute != null) {
      final route = widget.onGenerateRoute!(settings);
      if (route != null) return route;
    }

    // Try onUnknownRoute.
    if (widget.onUnknownRoute != null) {
      return widget.onUnknownRoute!(settings);
    }

    return null;
  }

  void _installRoute(Route<dynamic> route) {
    route.navigator = this;
    route.install();
    _routes.add(route);
    // Assign a stable key to each overlay entry so that element
    // reconciliation can match entries across position changes.
    for (final entry in route.overlayEntries) {
      _entryKeys[entry] = UniqueKey();
    }
  }

  // ---------------------------------------------------------------------------
  // Public navigation API
  // ---------------------------------------------------------------------------

  /// Pushes a [route] onto the navigation stack.
  ///
  /// Returns a [Future] that completes with the result value when the
  /// route is popped.
  Future<T?> push<T>(Route<T> route) {
    final completer = Completer<T?>();
    route.completer = completer;
    _routeCompleters[route] = completer;

    final previousRoute = _routes.isNotEmpty ? _routes.last : null;
    _installRoute(route);

    setState(() {});

    for (final observer in widget.observers) {
      observer.didPush(route, previousRoute);
    }

    return completer.future;
  }

  /// Pushes a named route onto the navigation stack.
  ///
  /// The route is created from the [Navigator.routes] map or
  /// [Navigator.onGenerateRoute] factory.
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    final settings = RouteSettings(name: routeName, arguments: arguments);
    final route = _createRoute(settings);
    if (route == null && widget.onUnknownRoute != null) {
      return push<T>(widget.onUnknownRoute!(settings) as Route<T>);
    }
    if (route == null) {
      throw StateError(
        'Navigator.pushNamed called with a route name that could not be '
        'resolved: "$routeName".',
      );
    }
    return push<T>(route as Route<T>);
  }

  /// Pushes a widget directly as a [PageRoute].
  ///
  /// Convenience method that wraps [widget] in a [PageRoute].
  Future<T?> pushWidget<T>(Widget child, {String? name}) {
    return push<T>(
      PageRoute<T>(
        builder: (_) => child,
        settings: RouteSettings(name: name),
      ),
    );
  }

  /// Pushes a [route] and removes the current top route.
  ///
  /// The [result] is used to complete the previous route's future.
  Future<T?> pushReplacement<T, TO>(Route<T> route, {TO? result}) {
    // Pop the current route first (without triggering rebuild yet).
    if (_routes.isNotEmpty) {
      _removeTopRoute(result: result);
    }
    return push<T>(route);
  }

  /// Pushes a named route and removes the current top route.
  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    final settings = RouteSettings(name: routeName, arguments: arguments);
    final route = _createRoute(settings);
    if (route == null) {
      throw StateError(
        'Navigator.pushReplacementNamed called with a route name that could '
        'not be resolved: "$routeName".',
      );
    }
    return pushReplacement<T, TO>(route as Route<T>, result: result);
  }

  /// Pops the current route, optionally returning a [result].
  ///
  /// The result is used to complete the [Future] returned by [push].
  void pop<T>([T? result]) {
    if (_routes.isEmpty) return;

    final route = _routes.last;
    final previousRoute = _routes.length > 1
        ? _routes[_routes.length - 2]
        : null;

    // Clean up entry keys before disposing (dispose clears overlayEntries).
    for (final entry in route.overlayEntries) {
      _entryKeys.remove(entry);
    }

    _routes.removeLast();
    route.dispose();

    // Complete the route's future.
    final completer = _routeCompleters.remove(route);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }

    setState(() {});

    for (final observer in widget.observers) {
      observer.didPop(route, previousRoute);
    }
  }

  /// Whether the navigator can pop the current route.
  ///
  /// Returns `true` if there are at least two routes on the stack and
  /// the current route's [Route.canPop] returns `true`.
  bool canPop() {
    if (_routes.length <= 1) return false;
    final currentRoute = _routes.last;
    if (!currentRoute.canPop()) return false;

    // Check PopBehavior.canPop if provided.
    final popCanPop = widget.popBehavior.canPop;
    if (popCanPop != null && !popCanPop(currentRoute)) return false;

    return true;
  }

  /// Pops routes until [predicate] returns `true` for a route.
  ///
  /// The route for which [predicate] returns `true` is NOT popped.
  void popUntil(bool Function(Route<dynamic>) predicate) {
    while (_routes.isNotEmpty && !predicate(_routes.last)) {
      pop();
    }
  }

  /// Shows a modal dialog by pushing a [DialogRoute].
  ///
  /// Returns a [Future] that completes with the dialog's result when
  /// the dialog is dismissed.
  ///
  /// ```dart
  /// final result = await Navigator.of(context).showDialog<bool>(
  ///   builder: (context) => ConfirmDialog(),
  /// );
  /// ```
  Future<T?> showDialog<T>({
    required RouteWidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    Alignment alignment = Alignment.center,
    num? width,
    num? height,
    RouteSettings? routeSettings,
    AnimationStyle? animationStyle,
  }) {
    final route = DialogRoute<T>(
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      alignment: alignment,
      width: width,
      height: height,
      animationStyle: animationStyle,
      settings: routeSettings ?? RouteSettings(name: DialogRoute.routeName),
    );
    return push<T>(route);
  }

  /// The current route stack (read-only).
  List<Route<dynamic>> get routes => List.unmodifiable(_routes);

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _removeTopRoute<TO>({TO? result}) {
    if (_routes.isEmpty) return;

    final route = _routes.removeLast();
    final previousRoute = _routes.isNotEmpty ? _routes.last : null;

    // Clean up entry keys before disposing (dispose clears overlayEntries).
    for (final entry in route.overlayEntries) {
      _entryKeys.remove(entry);
    }

    route.dispose();

    // Complete the route's future.
    final completer = _routeCompleters.remove(route);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }

    for (final observer in widget.observers) {
      observer.didRemove(route, previousRoute);
    }
  }

  Cmd? _popFor(KeyMsg msg) {
    if (!canPop()) {
      return null;
    }

    if (widget.popBehavior.shouldPop(msg)) {
      final currentRoute = _routes.last;

      if (currentRoute.willHandlePopInternally) {
        return null;
      }

      final popCanPop = widget.popBehavior.canPop;
      if (popCanPop != null && !popCanPop(currentRoute)) {
        return null;
      }

      if (currentRoute.popDisposition == RoutePopDisposition.doNotPop) {
        return null;
      }

      final onPopInvoked = widget.popBehavior.onPopInvoked;
      if (onPopInvoked != null) {
        onPopInvoked(currentRoute).then((shouldPop) {
          if (shouldPop && _routes.contains(currentRoute)) {
            pop();
          }
        });
        return null;
      }

      pop();
      return null;
    }

    return null;
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg) {
      return _popFor(msg);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Collect all overlay entries from all routes.
    final entries = <OverlayEntry>[];
    for (final route in _routes) {
      entries.addAll(route.overlayEntries);
    }

    if (entries.isEmpty) {
      return SizedBox.shrink();
    }

    // Find the lowest opaque entry — everything from there upward is visible.
    var opaqueIndex = 0;
    for (var i = entries.length - 1; i >= 0; i--) {
      if (entries[i].opaque) {
        opaqueIndex = i;
        break;
      }
    }

    // Build children list using _RouteEntry wrappers with stable keys.
    // Offstage entries come first and active entries come last.
    // Element.dispatch walks children in reverse order for KeyMsg (one-winner
    // policy), so placing active entries last ensures they receive keyboard
    // input before offstage entries.
    // Offstage entries render as zero-size (SizedBox 0x0) and their
    // handleIntercept returns Cmd.none() to suppress message delivery to
    // their children.
    //
    // Using a single _RouteEntry type with a stable Key for each entry
    // ensures Widget.canUpdate returns true when an entry transitions
    // between active↔offstage (same runtimeType + same Key). The
    // _RouteEntry.build() always returns SizedBox(child: widget.child)
    // keeping the subtree structure identical and preserving child
    // State objects and pending Futures.
    final children = <Widget>[];

    // Offstage entries first (below opaqueIndex, maintainState only).
    for (var i = 0; i < opaqueIndex; i++) {
      if (entries[i].maintainState) {
        final key = _entryKeys[entries[i]];
        children.add(
          _RouteEntry(
            key: key,
            offstage: true,
            child: Builder(builder: (ctx) => entries[i].builder(ctx)),
          ),
        );
      }
    }

    // Active entries last (from opaqueIndex onward).
    for (var i = opaqueIndex; i < entries.length; i++) {
      final key = _entryKeys[entries[i]];
      children.add(
        _RouteEntry(
          key: key,
          child: Builder(builder: (ctx) => entries[i].builder(ctx)),
        ),
      );
    }

    // Always use a Stack — even for a single child — so the element tree
    // structure remains stable across push/pop cycles and State objects
    // are preserved rather than disposed and re-created.
    final result = Stack(fit: StackFit.expand, children: children);

    // Wrap in FocusScope to trap focus in the navigator.
    return FocusScope(isTrapped: true, child: result);
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// A keyed wrapper for route overlay entries in the [Navigator] stack.
///
/// Using a single widget type for both active and offstage entries ensures
/// that [Widget.canUpdate] returns `true` when an entry transitions between
/// active and offstage states (same `runtimeType` + same [Key]). This
/// preserves the element tree (and thus [State] objects and pending Futures)
/// across push/pop operations.
///
/// When [offstage] is `true`:
/// - [handleIntercept] returns [Cmd.none()] to suppress all messages.
/// - The child is wrapped in [SizedBox.shrink] to avoid rendering.
class _RouteEntry extends StatefulWidget {
  _RouteEntry({required this.child, this.offstage = false, super.key});

  final Widget child;
  final bool offstage;

  @override
  State<_RouteEntry> createState() => _RouteEntryState();
}

class _RouteEntryState extends State<_RouteEntry> {
  @override
  Widget build(BuildContext context) {
    // Always wrap in SizedBox to keep the subtree structure identical
    // when transitioning between active and offstage. This ensures
    // Widget.canUpdate succeeds for the SizedBox (same runtimeType, no key)
    // and the child element tree is preserved.
    // When offstage, width/height=0 renders as zero-size.
    // When active, width/height=null passes through constraints.
    return SizedBox(
      width: widget.offstage ? 0 : null,
      height: widget.offstage ? 0 : null,
      child: widget.child,
    );
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    return null;
  }
}
