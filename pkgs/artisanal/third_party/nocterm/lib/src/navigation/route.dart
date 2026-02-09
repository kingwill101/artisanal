import '../framework/framework.dart';
import '../components/basic.dart';
import '../components/gesture_detector.dart';
import '../components/modal_barrier.dart';
import '../components/stack.dart' show Alignment, Positioned;
import '../gestures/hit_test.dart' show HitTestBehavior;
import '../style.dart' show Color;
import 'route_settings.dart';
import 'overlay.dart';

/// Base class for routes in the navigation system
abstract class Route<T> {
  /// The settings for this route (name, arguments)
  final RouteSettings settings;

  Route({
    required this.settings,
  });

  /// The overlay entries for this route.
  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  /// Navigator that this route is in.
  dynamic get navigator => _navigator;
  dynamic _navigator;

  set navigatorState(dynamic navigator) {
    _navigator = navigator;
  }

  /// Called when the route is inserted into the navigator.
  void install() {
    assert(_overlayEntries.isEmpty);
    _overlayEntries.addAll(createOverlayEntries());
  }

  /// Create the overlay entries for this route.
  Iterable<OverlayEntry> createOverlayEntries();

  /// Called when the route is removed from the navigator.
  void dispose() {
    for (final OverlayEntry entry in _overlayEntries) {
      entry.remove();
    }
    _overlayEntries.clear();
  }

  /// Check if this route can be popped.
  /// Override to prevent popping in certain conditions.
  bool canPop() => true;
}

/// A standard page route
class PageRoute<T> extends Route<T> {
  final ComponentBuilder builder;

  PageRoute({
    required this.builder,
    required super.settings,
  });

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      OverlayEntry(
        builder: builder,
        maintainState: true,
        opaque: true,
      ),
    ];
  }
}

/// A modal overlay route (like a dialog)
class ModalRoute<T> extends Route<T> {
  /// Builder for the modal content
  final ComponentBuilder builder;

  /// Whether tapping outside the modal dismisses it
  final bool barrierDismissible;

  /// The color of the barrier behind the dialog.
  ///
  /// If null, no barrier color is shown.
  /// Defaults to semi-transparent black when using [NavigatorState.showDialog].
  final Color? barrierColor;

  /// Whether to animate the barrier color.
  ///
  /// When true, the barrier fades in smoothly.
  /// Defaults to true.
  final bool animateBarrier;

  /// Duration of the barrier animation.
  ///
  /// Defaults to 200ms.
  final Duration barrierAnimationDuration;

  /// Alignment of the modal on screen
  final Alignment alignment;

  /// Width constraint for the modal
  final double? width;

  /// Height constraint for the modal
  final double? height;

  ModalRoute({
    required this.builder,
    required super.settings,
    this.barrierDismissible = true,
    this.barrierColor,
    this.animateBarrier = true,
    this.barrierAnimationDuration = const Duration(milliseconds: 200),
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      // Barrier entry
      OverlayEntry(
        builder: (context) {
          if (barrierColor == null) {
            // No barrier color - just an invisible hit target if dismissible
            if (barrierDismissible) {
              return GestureDetector(
                onTap: () => navigator?.pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              );
            }
            return const SizedBox.expand();
          }

          // With barrier color
          if (animateBarrier) {
            return FadeModalBarrier(
              color: barrierColor,
              duration: barrierAnimationDuration,
              dismissible: barrierDismissible,
              onDismiss: barrierDismissible ? () => navigator?.pop() : null,
              obscure: false,
            );
          } else {
            return ModalBarrier(
              color: barrierColor,
              dismissible: barrierDismissible,
              onDismiss: barrierDismissible ? () => navigator?.pop() : null,
              obscure: false,
            );
          }
        },
        opaque: false,
      ),
      // Modal content entry
      OverlayEntry(
        builder: (context) {
          Component modalContent = builder(context);

          // Apply size constraints if provided
          if (width != null || height != null) {
            modalContent = SizedBox(
              width: width,
              height: height,
              child: modalContent,
            );
          }

          // Apply alignment
          return Positioned.fill(
            child: Align(
              alignment: alignment,
              child: modalContent,
            ),
          );
        },
        maintainState: true,
      ),
    ];
  }
}

/// Factory for creating routes from settings
typedef RouteFactory = Route<dynamic>? Function(RouteSettings settings);
