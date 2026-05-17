part of 'components_widgets.dart';

/// Trend direction for a [MetricDisplay].
enum MetricTrend {
  /// Value is increasing (shown with ▲).
  up,

  /// Value is decreasing (shown with ▼).
  down,

  /// Value is stable (shown with ─).
  flat,
}

/// A single-value metric display widget.
///
/// Shows a label, value, optional unit, and optional trend indicator.
///
/// ```dart
/// MetricDisplay(
///   label: 'CPU Usage',
///   value: '42',
///   unit: '%',
///   trend: MetricTrend.up,
/// )
/// ```
class MetricDisplay extends StatelessWidget {
  MetricDisplay({
    required this.label,
    required this.value,
    this.unit,
    this.trend,
    this.labelStyle,
    this.valueStyle,
    this.trendColor,
    super.key,
  });

  /// The metric label (e.g., "CPU Usage").
  final String label;

  /// The metric value (e.g., "42").
  final String value;

  /// Optional unit suffix (e.g., "%", "ms", "MB").
  final String? unit;

  /// Optional trend direction.
  final MetricTrend? trend;

  /// Style for the label text. Defaults to muted theme text.
  final Style? labelStyle;

  /// Style for the value text. Defaults to bold theme text.
  final Style? valueStyle;

  /// Color for the trend indicator. Defaults to theme colors based on trend.
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final lStyle = copyStyle(labelStyle ?? theme.labelMedium)
      ..foreground(theme.muted);
    final vStyle = copyStyle(valueStyle ?? theme.titleMedium)
      ..foreground(theme.onSurface)
      ..bold();

    final valueText = unit != null ? '$value$unit' : value;

    final children = <Widget>[
      Text(label, style: lStyle),
      Text(valueText, style: vStyle),
    ];

    if (trend != null) {
      final (trendChar, defaultColor) = switch (trend!) {
        MetricTrend.up => ('▲', theme.success),
        MetricTrend.down => ('▼', theme.error),
        MetricTrend.flat => ('─', theme.muted),
      };
      final tStyle = copyStyle(Style())
        ..foreground(trendColor ?? defaultColor);
      children.add(Text(trendChar, style: tStyle));
    }

    return Row(gap: 1, children: children);
  }
}
