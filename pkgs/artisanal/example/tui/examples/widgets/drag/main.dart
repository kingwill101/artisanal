//
// Run with: dart run example/tui/examples/widgets/drag/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(DragDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.cellMotion,
      useUltravioletRenderer: true,
    ),
  );
}

class DragDemo extends w.StatefulWidget {
  DragDemo({super.key});

  @override
  w.State createState() => _DragDemoState();
}

class _DragDemoState extends w.State<DragDemo> {
  static const int _sliderWidth = 36;
  static const int _splitMin = 14;
  static const int _splitMax = 44;

  double _sliderValue = 0.35;
  int _splitWidth = 26;

  bool _draggingSlider = false;
  bool _draggingSplit = false;

  int _dragStartX = 0;
  double _dragStartValue = 0;
  int _dragStartSplit = 0;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        gap: 1,
        children: [
          w.Text('Drag Capture Demo', style: theme.titleLarge),
          w.Text(
            'Drag the slider or the splitter handle. Press q to quit.',
            style: theme.labelSmall,
          ),
          w.Container(
            color: theme.surface,
            padding: const w.EdgeInsets.all(1),
            child: w.Column(
              gap: 1,
              children: [_buildSlider(theme), _buildSplitter(theme)],
            ),
          ),
        ],
      ),
    );
  }

  w.Widget _buildSlider(w.Theme theme) {
    final track = _renderSlider(theme);
    return w.Row(
      gap: 2,
      children: [
        w.Text('Gain', style: theme.labelMedium),
        w.GestureDetector(
          onDragStart: _startSliderDrag,
          onDragUpdate: _updateSliderDrag,
          onDragEnd: _endSliderDrag,
          child: w.Text(track),
        ),
        w.Text('${(_sliderValue * 100).round()}%', style: theme.labelSmall),
      ],
    );
  }

  w.Widget _buildSplitter(w.Theme theme) {
    final left = w.Container(
      width: _splitWidth,
      height: 8,
      color: theme.surface,
      padding: const w.EdgeInsets.all(1),
      child: w.Text('Left pane', style: theme.bodySmall),
    );
    final handle = w.GestureDetector(
      onDragStart: _startSplitDrag,
      onDragUpdate: _updateSplitDrag,
      onDragEnd: _endSplitDrag,
      child: w.Container(
        width: 1,
        height: 8,
        color: _draggingSplit ? theme.primary : theme.border,
        child: w.Text(' ', style: theme.bodySmall),
      ),
    );
    final right = w.Container(
      width: 30,
      height: 8,
      color: theme.surface,
      padding: const w.EdgeInsets.all(1),
      child: w.Text('Right pane', style: theme.bodySmall),
    );
    return w.Row(gap: 1, children: [left, handle, right]);
  }

  String _renderSlider(w.Theme theme) {
    final clamped = _sliderValue.clamp(0.0, 1.0);
    final pos = (clamped * (_sliderWidth - 1)).round();
    final trackStyle = _draggingSlider
        ? Style().foreground(theme.onSurface)
        : Style().foreground(theme.muted);
    final thumbStyle = _draggingSlider
        ? Style().foreground(theme.secondary).bold()
        : Style().foreground(theme.primary).bold();
    final before = trackStyle.render('─' * pos);
    final thumb = thumbStyle.render('●');
    final after = trackStyle.render('─' * (_sliderWidth - pos - 1));
    return '$before$thumb$after';
  }

  tui.Cmd? _startSliderDrag(w.DragStartDetails details) {
    _dragStartX = details.globalPosition.dx.toInt();
    _dragStartValue = _sliderValue;
    setState(() {
      _draggingSlider = true;
    });
    return null;
  }

  tui.Cmd? _updateSliderDrag(w.DragUpdateDetails details) {
    final delta = details.globalPosition.dx.toInt() - _dragStartX;
    final next = _dragStartValue + delta / (_sliderWidth - 1);
    setState(() {
      _sliderValue = next.clamp(0.0, 1.0);
    });
    return null;
  }

  tui.Cmd? _startSplitDrag(w.DragStartDetails details) {
    _dragStartX = details.globalPosition.dx.toInt();
    _dragStartSplit = _splitWidth;
    setState(() {
      _draggingSplit = true;
    });
    return null;
  }

  tui.Cmd? _updateSplitDrag(w.DragUpdateDetails details) {
    final delta = details.globalPosition.dx.toInt() - _dragStartX;
    final next = (_dragStartSplit + delta).clamp(_splitMin, _splitMax);
    setState(() {
      _splitWidth = next.toInt();
    });
    return null;
  }

  tui.Cmd? _endSliderDrag(w.DragEndDetails details) {
    if (_draggingSlider) {
      setState(() {
        _draggingSlider = false;
      });
    }
    return null;
  }

  tui.Cmd? _endSplitDrag(w.DragEndDetails details) {
    if (_draggingSplit) {
      setState(() {
        _draggingSplit = false;
      });
    }
    return null;
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key)) {
      if (key.char == 'q') return tui.Cmd.quit();
    }
    return null;
  }
}
