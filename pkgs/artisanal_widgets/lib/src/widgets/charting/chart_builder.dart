part of 'chart_widgets.dart';

/// A convenience widget that rebuilds whenever a [ChartModel] changes.
///
/// [ChartBuilder] subscribes to the given [model] and calls [builder]
/// each time the model notifies its listeners. The returned widget is
/// typically one of the chart widgets ([SparklineChart], [LineChart], etc.)
/// but can be any widget tree.
///
/// ```dart
/// final model = ChartModel(
///   type: ChartType.line,
///   values: [10, 20, 15, 30],
///   showGrid: true,
/// );
///
/// ChartBuilder(
///   model: model,
///   builder: (context, model) => LineChart(
///     values: model.values,
///     showGrid: model.showGrid,
///     width: 60,
///     height: 12,
///   ),
/// )
/// ```
///
/// Under the hood this is a thin wrapper around [ListenableBuilder] that
/// provides typed access to the [ChartModel] in the builder callback.
class ChartBuilder extends StatefulWidget {
  /// Creates a [ChartBuilder] that rebuilds when [model] changes.
  ChartBuilder({required this.model, required this.builder, super.key});

  /// The observable chart model to subscribe to.
  final ChartModel model;

  /// Called on each rebuild to produce the widget subtree.
  ///
  /// Receives the current [BuildContext] and the [ChartModel] so the builder
  /// can read the latest data without capturing stale closures.
  final Widget Function(BuildContext context, ChartModel model) builder;

  @override
  State<ChartBuilder> createState() => _ChartBuilderState();

  @override
  Object view() => builder(_NullBuildContext(), model);
}

class _ChartBuilderState extends State<ChartBuilder> {
  void _handleChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_handleChange);
  }

  @override
  didUpdateWidget(ChartBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_handleChange);
      widget.model.addListener(_handleChange);
    }
    return null;
  }

  @override
  void dispose() {
    widget.model.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.model);
  }
}

/// Minimal [BuildContext] stub used only in the [ChartBuilder.view] fallback.
class _NullBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
