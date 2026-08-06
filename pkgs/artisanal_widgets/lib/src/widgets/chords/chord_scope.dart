/// Provides a [ChordController] to descendants.
library;

import '../core/framework.dart' show BuildContext, InheritedWidget;
import 'chord_controller.dart';

/// Inherited access to the app [ChordController].
///
/// Prefer constructing this via [ChordHost]. Descendants use
/// [ChordController.of] / [ChordController.maybeOf].
///
/// Snapshots [isActive] / [prefixLabel] so [updateShouldNotify] works even
/// though [controller] is a mutable listenable.
class ChordScope extends InheritedWidget {
  ChordScope({
    required this.controller,
    required super.child,
    super.key,
  })  : isActive = controller.isActive,
        prefixLabel = controller.prefixLabel,
        generation = controller.generation;

  /// Live chord definitions + pending state.
  final ChordController controller;

  /// Snapshot of [ChordController.isActive] at build time.
  final bool isActive;

  /// Snapshot of [ChordController.prefixLabel] at build time.
  final String prefixLabel;

  /// Monotonic generation from [ChordController] (forces notify on change).
  final int generation;

  static ChordScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChordScope>();
  }

  static ChordScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'ChordScope.of() called with no ChordScope ancestor');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant ChordScope oldWidget) {
    return controller != oldWidget.controller ||
        generation != oldWidget.generation ||
        isActive != oldWidget.isActive ||
        prefixLabel != oldWidget.prefixLabel;
  }
}
