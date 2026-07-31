// Artisanal widget and rendering features.
//
// Demonstrates a fixed terminal viewport, cell shadows, UV buffer filters,
// structured table cells, and the monthly calendar.
//
// Run with: dart run example/widget_features/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' show ScanlineFilter;
import 'package:artisanal/artisanal.dart' as chart;
import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/charting.dart' as w;

Future<void> main() async {
  await tui.runProgram(
    w.WidgetApp(FeatureShowcase()),
    options: const tui.ProgramOptions(
      screenMode: tui.ScreenMode.fixed,
      fixedViewport: tui.FixedViewport(x: 2, y: 1, width: 58, height: 24),
      mouse: true,
      frameTick: false,
    ),
  );
}

class FeatureShowcase extends w.StatefulWidget {
  FeatureShowcase({super.key});

  @override
  w.State createState() => _FeatureShowcaseState();
}

class _FeatureShowcaseState extends w.State<FeatureShowcase> {
  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    return w.Container(
      color: theme.background,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        children: [
          w.Shadow(
            color: theme.shadow,
            shadowStyle: w.TerminalShadowStyle.dark,
            child: w.Frame(
              border: style.Border.rounded,
              borderColor: theme.primary,
              padding: const w.EdgeInsets.symmetric(horizontal: 1),
              child: w.Text('Artisanal rendering primitives'),
            ),
          ),
          w.Row(
            gap: 3,
            children: [
              w.MonthlyCalendar(
                month: DateTime(2026, 7),
                selectedDate: DateTime(2026, 7, 31),
                markers: {
                  DateTime(2026, 7, 4): '*',
                  DateTime(2026, 7, 18): '•',
                },
              ),
              w.DataTable.cells(
                columns: const [
                  w.DataTableCell('Task'),
                  w.DataTableCell('State'),
                ],
                rows: const [
                  [w.DataTableCell('Renderer', columnSpan: 2)],
                  [w.DataTableCell('diff'), w.DataTableCell('ready')],
                  [w.DataTableCell('viewport'), w.DataTableCell('fixed')],
                ],
                borderStyle: w.DataTableBorderStyle.rounded,
              ),
            ],
          ),
          w.CellFilter(
            filters: [ScanlineFilter(lineStrength: 0.25)],
            child: w.Text('UV filters can wrap any widget subtree.'),
          ),
          w.CustomChart(
            width: 54,
            height: 4,
            painter: (screen, area) =>
                chart.drawCanvasShapes(screen, area, const [
                  chart.CanvasRectangle(x: 2, y: 8, width: 25, height: 75),
                  chart.CanvasLine(x1: 0, y1: 0, x2: 100, y2: 100),
                  chart.CanvasCircle(x: 72, y: 50, radius: 24),
                ]),
          ),
          w.Text('Press q to quit', style: theme.labelSmall),
        ],
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
