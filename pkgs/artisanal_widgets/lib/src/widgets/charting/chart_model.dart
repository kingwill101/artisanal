part of 'chart_widgets.dart';

// ---------------------------------------------------------------------------
// ChartType
// ---------------------------------------------------------------------------

/// Enumerates the supported chart types.
///
/// Used by [ChartModel] to indicate which renderer should paint the data.
enum ChartType {
  /// A compact sparkline rendered with Unicode block characters.
  sparkline,

  /// A multi-point line chart with optional markers and grid.
  line,

  /// A vertical bar chart (histogram).
  bar,

  /// A 2D heatmap that maps grid values to colours via a [ChartRamp].
  heatmap,

  /// A pie or donut chart.
  pie,

  /// A stacked area (ribbon) chart for multiple series.
  ribbon,
}

// ---------------------------------------------------------------------------
// ChartSeries
// ---------------------------------------------------------------------------

/// A named data series for use in charts that support multiple series.
///
/// ```dart
/// final series = ChartSeries('Revenue', [10, 20, 30, 25],
///     style: UvStyle(fg: UvColor.rgb(0, 200, 100)));
/// ```
class ChartSeries {
  /// Creates a [ChartSeries] with the given [label], [values], and optional
  /// [style].
  const ChartSeries(this.label, this.values, {this.style});

  /// A human-readable label for the series (used in legends).
  final String label;

  /// The data values for this series.
  final List<double> values;

  /// Optional rendering style override for this series.
  final UvStyle? style;
}

// ---------------------------------------------------------------------------
// ChartModel
// ---------------------------------------------------------------------------

/// An observable data model for driving chart widget rebuilds.
///
/// [ChartModel] extends [ChangeNotifier] so it can be used with
/// [ListenableBuilder], [ChartBuilder], or any listener-based subscription
/// pattern.
///
/// ```dart
/// final model = ChartModel(
///   type: ChartType.line,
///   values: [10, 20, 15, 30, 25],
///   showGrid: true,
/// );
///
/// // Later, update the data:
/// model.values = [12, 22, 18, 35, 28]; // notifies listeners
/// ```
class ChartModel extends ChangeNotifier {
  /// Creates a [ChartModel] with the given configuration.
  ChartModel({
    ChartType type = ChartType.line,
    List<double> values = const [],
    List<ChartSeries> series = const [],
    List<List<double>> grid = const [],
    bool showGrid = false,
    bool showMarkers = true,
    bool showAxis = true,
    bool donut = false,
    double innerRadiusRatio = 0.45,
    bool normalizeTotals = true,
    ChartRamp? ramp,
    UvStyle? lineStyle,
    UvStyle? barStyle,
    UvStyle? gridStyle,
    UvStyle? labelStyle,
    List<UvStyle>? sliceStyles,
    List<String>? xLabels,
    List<String>? yLabels,
    String? title,
  }) : _type = type,
       _values = values,
       _series = series,
       _grid = grid,
       _showGrid = showGrid,
       _showMarkers = showMarkers,
       _showAxis = showAxis,
       _donut = donut,
       _innerRadiusRatio = innerRadiusRatio,
       _normalizeTotals = normalizeTotals,
       _ramp = ramp,
       _lineStyle = lineStyle,
       _barStyle = barStyle,
       _gridStyle = gridStyle,
       _labelStyle = labelStyle,
       _sliceStyles = sliceStyles,
       _xLabels = xLabels,
       _yLabels = yLabels,
       _title = title;

  // -- type --

  ChartType _type;

  /// The type of chart to render.
  ChartType get type => _type;
  set type(ChartType value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }

  // -- values (single series) --

  List<double> _values;

  /// The primary data values for single-series charts.
  List<double> get values => _values;
  set values(List<double> value) {
    _values = value;
    notifyListeners();
  }

  // -- series (multi-series) --

  List<ChartSeries> _series;

  /// Named data series for multi-series charts like [ChartType.ribbon].
  List<ChartSeries> get series => _series;
  set series(List<ChartSeries> value) {
    _series = value;
    notifyListeners();
  }

  // -- grid (2D data for heatmap) --

  List<List<double>> _grid;

  /// 2D grid data for [ChartType.heatmap].
  List<List<double>> get grid => _grid;
  set grid(List<List<double>> value) {
    _grid = value;
    notifyListeners();
  }

  // -- display options --

  bool _showGrid;

  /// Whether to draw background grid lines.
  bool get showGrid => _showGrid;
  set showGrid(bool value) {
    if (_showGrid == value) return;
    _showGrid = value;
    notifyListeners();
  }

  bool _showMarkers;

  /// Whether to draw markers at data points (line charts).
  bool get showMarkers => _showMarkers;
  set showMarkers(bool value) {
    if (_showMarkers == value) return;
    _showMarkers = value;
    notifyListeners();
  }

  bool _showAxis;

  /// Whether to draw the axis line (bar charts).
  bool get showAxis => _showAxis;
  set showAxis(bool value) {
    if (_showAxis == value) return;
    _showAxis = value;
    notifyListeners();
  }

  bool _donut;

  /// Whether to render a donut hole (pie charts).
  bool get donut => _donut;
  set donut(bool value) {
    if (_donut == value) return;
    _donut = value;
    notifyListeners();
  }

  double _innerRadiusRatio;

  /// Inner radius ratio for donut charts.
  double get innerRadiusRatio => _innerRadiusRatio;
  set innerRadiusRatio(double value) {
    if (_innerRadiusRatio == value) return;
    _innerRadiusRatio = value;
    notifyListeners();
  }

  bool _normalizeTotals;

  /// Whether ribbon charts normalize each column to 100%.
  bool get normalizeTotals => _normalizeTotals;
  set normalizeTotals(bool value) {
    if (_normalizeTotals == value) return;
    _normalizeTotals = value;
    notifyListeners();
  }

  // -- styling --

  ChartRamp? _ramp;

  /// Colour ramp for heatmap rendering.
  ChartRamp? get ramp => _ramp;
  set ramp(ChartRamp? value) {
    _ramp = value;
    notifyListeners();
  }

  UvStyle? _lineStyle;

  /// Style for line/sparkline chart elements.
  UvStyle? get lineStyle => _lineStyle;
  set lineStyle(UvStyle? value) {
    _lineStyle = value;
    notifyListeners();
  }

  UvStyle? _barStyle;

  /// Style for bar chart elements.
  UvStyle? get barStyle => _barStyle;
  set barStyle(UvStyle? value) {
    _barStyle = value;
    notifyListeners();
  }

  UvStyle? _gridStyle;

  /// Style for grid lines.
  UvStyle? get gridStyle => _gridStyle;
  set gridStyle(UvStyle? value) {
    _gridStyle = value;
    notifyListeners();
  }

  UvStyle? _labelStyle;

  /// Style for axis labels.
  UvStyle? get labelStyle => _labelStyle;
  set labelStyle(UvStyle? value) {
    _labelStyle = value;
    notifyListeners();
  }

  List<UvStyle>? _sliceStyles;

  /// Per-slice/per-series styles for pie and ribbon charts.
  List<UvStyle>? get sliceStyles => _sliceStyles;
  set sliceStyles(List<UvStyle>? value) {
    _sliceStyles = value;
    notifyListeners();
  }

  // -- labels --

  List<String>? _xLabels;

  /// Labels for the X axis.
  List<String>? get xLabels => _xLabels;
  set xLabels(List<String>? value) {
    _xLabels = value;
    notifyListeners();
  }

  List<String>? _yLabels;

  /// Labels for the Y axis.
  List<String>? get yLabels => _yLabels;
  set yLabels(List<String>? value) {
    _yLabels = value;
    notifyListeners();
  }

  // -- title --

  String? _title;

  /// An optional title displayed above the chart.
  String? get title => _title;
  set title(String? value) {
    if (_title == value) return;
    _title = value;
    notifyListeners();
  }
}
