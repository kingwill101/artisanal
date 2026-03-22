/// Route classes for the navigation system.
///
/// Provides the route hierarchy: [Route] (abstract base), [PageRoute] (full-screen),
/// and [ModalRoute] (dialog/modal overlay with barrier).
library;

import 'dart:async' show Completer;

import 'package:artisanal/style.dart' hide Padding, Align;

import '../components/components_widgets.dart'
    show CmdCallback, FadeModalBarrier;
import '../components/overlay.dart';
import '../core/framework.dart' show BuildContext;
import '../core/widget.dart';
import '../layout/layout_widgets.dart';
import 'route_settings.dart';

/// A builder that creates a widget for a route.
typedef RouteWidgetBuilder = Widget Function(BuildContext context);

/// A factory function that creates a route from settings.
///
/// Returns `null` if the factory cannot create a route for the given settings.
typedef RouteFactory = Route<dynamic>? Function(RouteSettings settings);

/// Abstract base class for routes managed by a [Navigator].
///
/// A route represents a single screen or modal in the navigation stack.
/// Each route produces one or more [OverlayEntry] objects that are inserted
/// into the navigator's [Overlay].
///
/// Subclasses must implement [createOverlayEntries] to define what overlay
/// entries the route contributes.
abstract class Route<T> {
  /// Creates a route with the given [settings].
  Route({RouteSettings? settings})
    : settings = settings ?? const RouteSettings();

  /// Metadata for this route (name, arguments).
  final RouteSettings settings;

  /// The overlay entries this route contributes to the navigator's overlay.
  final List<OverlayEntry> _overlayEntries = [];

  /// The overlay entries this route has created.
  List<OverlayEntry> get overlayEntries => List.unmodifiable(_overlayEntries);

  /// Back-reference to the [NavigatorState] managing this route.
  ///
  /// Set by the navigator when the route is installed.
  dynamic navigator;

  /// The [Completer] that completes when this route is popped.
  ///
  /// Set by the navigator during route push.
  Completer<T?>? completer;

  /// Installs this route, creating its overlay entries.
  ///
  /// Called by the navigator when the route is pushed.
  void install() {
    _overlayEntries.addAll(createOverlayEntries());
  }

  /// Creates the overlay entries for this route.
  ///
  /// Subclasses must implement this to define what layers the route
  /// contributes to the overlay stack.
  Iterable<OverlayEntry> createOverlayEntries();

  /// Disposes this route, removing all its overlay entries.
  ///
  /// Called by the navigator when the route is removed from the stack.
  void dispose() {
    for (final entry in _overlayEntries) {
      entry.remove();
    }
    _overlayEntries.clear();
  }

  /// Whether this route can be popped.
  ///
  /// Override to prevent popping (e.g., for routes with unsaved changes).
  bool canPop() => true;
}

/// A full-screen page route.
///
/// Creates a single opaque [OverlayEntry] that renders the page content.
/// This is the standard route type for pushing a new screen.
///
/// ```dart
/// navigator.push(PageRoute(
///   builder: (context) => SettingsScreen(),
///   settings: RouteSettings(name: '/settings'),
/// ));
/// ```
class PageRoute<T> extends Route<T> {
  /// Creates a page route with the given [builder].
  PageRoute({required this.builder, super.settings});

  /// Builds the page content.
  final RouteWidgetBuilder builder;

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return [OverlayEntry(opaque: true, maintainState: true, builder: builder)];
  }
}

/// A modal overlay route with an optional barrier.
///
/// Creates two [OverlayEntry] objects: a barrier entry (which can be
/// dismissible and/or animated) and a content entry positioned according
/// to the specified [alignment].
///
/// ```dart
/// navigator.push(ModalRoute(
///   builder: (context) => DialogContent(),
///   barrierDismissible: true,
///   barrierColor: Color.fromHex('#000000'),
///   alignment: Alignment.center,
/// ));
/// ```
class ModalRoute<T> extends Route<T> {
  /// Creates a modal route with the given [builder] and barrier options.
  ModalRoute({
    required this.builder,
    this.barrierDismissible = true,
    this.barrierColor,
    this.animateBarrier = true,
    this.barrierAnimationDuration = const Duration(milliseconds: 200),
    this.alignment = Alignment.center,
    this.width,
    this.height,
    super.settings,
  });

  /// Builds the modal content.
  final RouteWidgetBuilder builder;

  /// Whether tapping the barrier dismisses the modal.
  final bool barrierDismissible;

  /// The color of the barrier behind the modal.
  ///
  /// If `null`, no visible barrier color is rendered (but the barrier
  /// still intercepts taps when [barrierDismissible] is true).
  final Color? barrierColor;

  /// Whether to animate the barrier fade-in.
  final bool animateBarrier;

  /// Duration of the barrier fade animation.
  final Duration barrierAnimationDuration;

  /// Alignment of the modal content within the overlay.
  final Alignment alignment;

  /// Optional width constraint for the modal content.
  final num? width;

  /// Optional height constraint for the modal content.
  final num? height;

  /// Pops this modal route, completing it with the given [result].
  void _pop([T? result]) {
    final nav = navigator;
    if (nav != null) {
      nav.pop(result);
    }
  }

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return [
      // Barrier entry
      _createBarrierEntry(),
      // Content entry
      OverlayEntry(
        opaque: false,
        maintainState: true,
        builder: (context) {
          Widget content = builder(context);

          // Apply size constraints if specified.
          if (width != null || height != null) {
            content = SizedBox(width: width, height: height, child: content);
          }

          return Align(alignment: alignment, child: content);
        },
      ),
    ];
  }

  OverlayEntry _createBarrierEntry() {
    return OverlayEntry(
      opaque: false,
      maintainState: false,
      builder: (context) {
        final CmdCallback? dismissCallback = barrierDismissible
            ? () {
                _pop();
                return null;
              }
            : null;

        if (barrierColor != null && animateBarrier) {
          // Animated colored barrier.
          return FadeModalBarrier(
            visible: true,
            color: barrierColor,
            duration: barrierAnimationDuration,
            dismissible: barrierDismissible,
            onDismiss: dismissCallback,
            child: SizedBox.shrink(),
          );
        } else if (barrierColor != null) {
          // Static colored barrier.
          Widget barrier = Container(
            color: barrierColor,
            width: double.infinity,
            height: double.infinity,
          );
          if (barrierDismissible) {
            barrier = GestureDetector(
              onTap: () {
                _pop();
                return null;
              },
              child: barrier,
            );
          }
          return barrier;
        } else if (barrierDismissible) {
          // Transparent dismissible barrier.
          return GestureDetector(
            onTap: () {
              _pop();
              return null;
            },
            child: SizedBox(width: double.infinity, height: double.infinity),
          );
        } else {
          // Transparent non-dismissible barrier.
          return SizedBox(width: double.infinity, height: double.infinity);
        }
      },
    );
  }
}
