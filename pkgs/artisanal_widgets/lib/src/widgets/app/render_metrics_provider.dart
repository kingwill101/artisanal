/// Provides [RenderMetrics] to the widget tree without triggering rebuilds.
///
/// [WidgetApp] writes to the [RenderMetricsHolder] in-place when a
/// [RenderMetricsMsg] arrives. Widgets like [DebugOverlay] read from
/// the holder lazily via [RenderMetricsProvider.maybeOf] when they
/// rebuild for other reasons.
@experimental
library;

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart' show experimental;

import 'package:artisanal/tui.dart' show RenderMetrics;
import '../core/framework.dart' show BuildContext, InheritedWidget;

/// A portable render-metrics update payload.
///
/// Use this to inject runtime [metrics] and/or custom key-value lines that
/// should appear in debug overlays.
class RenderMetricsInjection {
  const RenderMetricsInjection({
    this.metrics,
    this.upsertEntries = const <String, String>{},
    this.removeKeys = const <String>{},
    this.clearEntries = false,
  });

  /// Optional runtime metrics snapshot to publish.
  final RenderMetrics? metrics;

  /// Custom entries to add/update in overlays.
  final Map<String, String> upsertEntries;

  /// Custom entry keys to remove.
  final Set<String> removeKeys;

  /// Whether to clear all custom entries before applying updates.
  final bool clearEntries;

  /// Returns `true` when this update carries no changes.
  bool get isEmpty =>
      metrics == null &&
      upsertEntries.isEmpty &&
      removeKeys.isEmpty &&
      !clearEntries;
}

/// Global bus for injecting render metrics from anywhere.
///
/// Any running [WidgetApp] listens to this stream and applies updates.
class RenderMetricsInjector {
  RenderMetricsInjector._();

  static final RenderMetricsInjector instance = RenderMetricsInjector._();

  final StreamController<RenderMetricsInjection> _controller =
      StreamController<RenderMetricsInjection>.broadcast(sync: true);

  /// Stream consumed by [WidgetApp].
  Stream<RenderMetricsInjection> get stream => _controller.stream;

  /// Injects a full [RenderMetricsInjection] payload.
  void inject(RenderMetricsInjection injection) {
    if (injection.isEmpty) return;
    _controller.add(injection);
  }

  /// Injects runtime renderer metrics.
  void injectRuntime(RenderMetrics metrics) {
    inject(RenderMetricsInjection(metrics: metrics));
  }

  /// Adds or updates one custom overlay metric line.
  void setMetric(String key, Object? value) {
    inject(
      RenderMetricsInjection(
        upsertEntries: <String, String>{key: value?.toString() ?? 'null'},
      ),
    );
  }

  /// Adds or updates many custom overlay metric lines.
  ///
  /// When [replace] is `true`, existing custom entries are cleared first.
  void setMetrics(Map<String, Object?> entries, {bool replace = false}) {
    if (entries.isEmpty && !replace) return;
    final normalized = <String, String>{};
    for (final entry in entries.entries) {
      normalized[entry.key] = entry.value?.toString() ?? 'null';
    }
    inject(
      RenderMetricsInjection(clearEntries: replace, upsertEntries: normalized),
    );
  }

  /// Removes one custom overlay metric line.
  void removeMetric(String key) {
    inject(RenderMetricsInjection(removeKeys: <String>{key}));
  }

  /// Clears all custom overlay metric lines.
  void clearMetrics() {
    inject(const RenderMetricsInjection(clearEntries: true));
  }
}

/// Mutable holder for [RenderMetrics] that [WidgetApp] updates in-place.
///
/// This is intentionally mutable so that metrics can be updated without
/// triggering InheritedWidget notifications. Widgets that read from this
/// holder (e.g. DebugOverlay) pick up the latest value whenever they
/// rebuild for any other reason.
class RenderMetricsHolder {
  /// The latest [RenderMetrics] snapshot, or `null` if none received yet.
  RenderMetrics? metrics;

  final LinkedHashMap<String, String> _customMetrics =
      LinkedHashMap<String, String>();

  /// Custom overlay metric entries.
  Map<String, String> get customMetrics =>
      UnmodifiableMapView<String, String>(_customMetrics);

  /// Applies an external [RenderMetricsInjection].
  ///
  /// Returns `true` when any stored value changed.
  bool applyInjection(RenderMetricsInjection injection) {
    var changed = false;

    final nextMetrics = injection.metrics;
    if (nextMetrics != null && !identical(nextMetrics, metrics)) {
      metrics = nextMetrics;
      changed = true;
    }

    if (injection.clearEntries && _customMetrics.isNotEmpty) {
      _customMetrics.clear();
      changed = true;
    }

    if (injection.removeKeys.isNotEmpty) {
      for (final key in injection.removeKeys) {
        final removed = _customMetrics.remove(key);
        if (removed != null) changed = true;
      }
    }

    if (injection.upsertEntries.isNotEmpty) {
      for (final entry in injection.upsertEntries.entries) {
        final prev = _customMetrics[entry.key];
        if (prev == entry.value) continue;
        _customMetrics[entry.key] = entry.value;
        changed = true;
      }
    }

    return changed;
  }
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
