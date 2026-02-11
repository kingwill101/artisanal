/// Provides [RenderMetrics] to the widget tree without triggering rebuilds.
///
/// [WidgetApp] writes to the [RenderMetricsHolder] in-place when a
/// [RenderMetricsMsg] arrives. Widgets like [DebugOverlay] read from
/// the holder lazily via [RenderMetricsProvider.maybeOf] when they
/// rebuild for other reasons.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'package:artisanal/tui.dart' show RenderMetrics;
import '../core/framework.dart' show BuildContext, InheritedWidget;

/// Mutable holder for [RenderMetrics] that [WidgetApp] updates in-place.
///
/// This is intentionally mutable so that metrics can be updated without
/// triggering InheritedWidget notifications. Widgets that read from this
/// holder (e.g. DebugOverlay) pick up the latest value whenever they
/// rebuild for any other reason.
class RenderMetricsHolder {
  /// The latest [RenderMetrics] snapshot, or `null` if none received yet.
  RenderMetrics? metrics;
}

/// Provides [RenderMetricsHolder] to the widget tree via [InheritedWidget].
///
/// Unlike a typical InheritedWidget, this never notifies dependents —
/// [updateShouldNotify] always returns `false`. The holder's data is
/// mutated in-place by [WidgetApp], and widgets read from it lazily
/// when they rebuild for other reasons (e.g. when `_dirty` is set for
/// a real state change or the periodic debug overlay repaint).
class RenderMetricsProvider extends InheritedWidget {
  RenderMetricsProvider({
    required this.holder,
    required super.child,
    super.key,
  });

  final RenderMetricsHolder holder;

  /// Returns the [RenderMetricsHolder] from the nearest ancestor, or `null`.
  static RenderMetricsHolder? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RenderMetricsProvider>()
        ?.holder;
  }

  @override
  bool updateShouldNotify(covariant RenderMetricsProvider oldWidget) {
    // Never notify — the holder is the same mutable object; its data
    // is written in-place by WidgetApp.
    return false;
  }
}
