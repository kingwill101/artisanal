/// Stable chart widget entrypoint for terminal UIs.
///
/// Import this library when you want the supported chart widget surface
/// without reaching for the broader experimental compatibility entrypoint.
///
/// ```dart
/// import 'package:artisanal_widgets/charting.dart' as w;
/// ```
///
/// The legacy `package:artisanal_widgets/artisanal_widgets.dart` entrypoint
/// remains available for backward compatibility and still exposes additional
/// experimental internals and modules.
library;

export 'widgets.dart';
export 'src/widgets/charting/chart_widgets.dart';
export 'package:artisanal/charting.dart'
    show ChartLegendEntry, ChartRamp, ChartPainter, BrailleCanvas;
