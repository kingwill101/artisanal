/// OpenTUI-style terminal charts for Artisanal / Ultraviolet.
///
/// Provides nine chart types with sub-pixel rendering (quadrant blocks and
/// braille), axis scaling, legends, and time-series buffers for live
/// dashboards.
///
/// ```dart
/// import 'package:artisanal_charts/artisanal_charts.dart';
///
/// final chart = createLineChart(LineChartProps(
///   width: 60,
///   height: 20,
///   title: 'Revenue',
///   series: [
///     DataSeries(name: '2025', data: [10, 25, 35, 42], color: '#4FC3F7'),
///   ],
///   showDots: true,
///   grid: GridOptions(show: true),
/// ));
/// print(chart.render());
/// ```
library;

export 'src/types.dart';
export 'src/frame_buffer.dart';
export 'src/surface.dart';
export 'src/utils.dart'
    show
        color,
        dimColor,
        lerpColor,
        computeNiceScale,
        formatNumber,
        resolveMargins,
        NiceScale,
        BrailleCanvas,
        QuadrantCanvas,
        drawAxes,
        drawLegend,
        drawLine,
        drawHLine,
        drawVLine,
        parseHexColor;
export 'src/time_series.dart';
export 'src/charts/line.dart';
export 'src/charts/bar.dart';
export 'src/charts/pie.dart';
export 'src/charts/scatter.dart';
export 'src/charts/area.dart';
export 'src/charts/stacked_bar.dart';
export 'src/charts/heatmap.dart';
export 'src/charts/gauge.dart';
export 'src/charts/sparkline.dart';
export 'src/widgets/chart_view.dart';
