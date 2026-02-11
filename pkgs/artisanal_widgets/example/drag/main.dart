// Drag Interaction Demo
//
// Demonstrates drag gestures with the recognizer-based gesture system:
//   - Draggable slider with live value feedback
//   - Resizable split-pane with drag handle
//   - Moveable box that can be repositioned via drag
//   - Status panel showing DragStartDetails, DragUpdateDetails, DragEndDetails
//
// Run with: dart run example/drag/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(DragDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
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
  // -- Slider state --
  static const int _sliderWidth = 36;
  double _sliderValue = 0.35;
  bool _draggingSlider = false;
  int _sliderDragStartX = 0;
  double _sliderDragStartValue = 0;

  // -- Split-pane state --
  static const int _splitMin = 10;
  static const int _splitMax = 44;
  int _splitWidth = 24;
  bool _draggingSplit = false;
  int _splitDragStartX = 0;
  int _splitDragStartWidth = 0;

  // -- Moveable box state --
  static const int _arenaW = 50;
  static const int _arenaH = 5;
  static const int _boxW = 12;
  static const int _boxH = 3;
  int _boxX = 4;
  int _boxY = 0;
  bool _draggingBox = false;
  int _boxDragStartX = 0;
  int _boxDragStartY = 0;
  int _boxDragStartBoxX = 0;
  int _boxDragStartBoxY = 0;

  // -- Detail display --
  String _phase = 'idle';
  String _globalPos = '--';
  String _localPos = '--';
  String _delta = '--';
  String _button = '--';
  int _dragCount = 0;
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Container(
        child: w.Scrollbar(
          controller: _scrollController,
          thickness: 1,
          gap: 1,
          enableHover: true,
          trackChar: ' ',
          thumbChar: ' ',
          trackUsesBackground: true,
          thumbUsesBackground: true,
          trackGradient: w.ScrollbarGradient.background(
            start: w.hasDarkBackground
                ? const BasicColor('#2f363d')
                : const BasicColor('#e3e7eb'),
            end: w.hasDarkBackground
                ? const BasicColor('#1f252a')
                : const BasicColor('#d3d9e0'),
          ),
          thumbGradient: w.ScrollbarGradient.background(
            start: w.hasDarkBackground
                ? const BasicColor('#3fb2ff')
                : const BasicColor('#2f7df6'),
            end: w.hasDarkBackground
                ? const BasicColor('#7c5cff')
                : const BasicColor('#6e55f5'),
          ),
          hoverThumbGradient: w.ScrollbarGradient.background(
            start: w.hasDarkBackground
                ? const BasicColor('#79ddff')
                : const BasicColor('#4f93ff'),
            end: w.hasDarkBackground
                ? const BasicColor('#b18bff')
                : const BasicColor('#836bff'),
          ),
          hoverThumbChar: ' ',
          child: w.ScrollView(
            controller: _scrollController,
            handleKeys: true,
            child: w.Column(
              gap: 1,
              children: [
                w.Text('Drag Gesture Demo', style: theme.titleLarge),
                w.Text(
                  'Drag the slider, splitter handle, or the moveable box. '
                  'Press q to quit.',
                  style: theme.labelSmall,
                ),
                w.Divider(width: 64),
                _buildSlider(theme),
                w.Divider(width: 64),
                _buildSplitter(theme),
                w.Divider(width: 64),
                _buildMoveableBox(theme),
                w.Divider(width: 64),
                _buildDetails(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1) Horizontal slider — uses globalPosition for absolute tracking
  // ---------------------------------------------------------------------------

  w.Widget _buildSlider(w.Theme theme) {
    final pct = (_sliderValue * 100).round();
    final clamped = _sliderValue.clamp(0.0, 1.0);
    final thumbPos = (clamped * (_sliderWidth - 1)).round();

    // Build the track as a Row of widgets so hit-testing works correctly.
    // A single Container acts as the drag target with the track drawn inside.
    return w.Column(
      gap: 0,
      children: [
        w.Text('Slider (drag horizontal)', style: theme.titleMedium),
        w.Row(
          gap: 2,
          children: [
            w.Text('Gain', style: theme.labelMedium),
            w.GestureDetector(
              onDragStart: _onSliderDragStart,
              onDragUpdate: _onSliderDragUpdate,
              onDragEnd: _onSliderDragEnd,
              child: w.Container(
                width: _sliderWidth,
                height: 1,
                color: theme.surface,
                child: w.Row(
                  gap: 0,
                  children: [
                    w.Text(
                      '─' * thumbPos,
                      style: _draggingSlider
                          ? Style().foreground(theme.onSurface)
                          : Style().foreground(theme.muted),
                    ),
                    w.Text(
                      '●',
                      style: _draggingSlider
                          ? Style().foreground(theme.secondary).bold()
                          : Style().foreground(theme.primary).bold(),
                    ),
                    w.Text(
                      '─' * (_sliderWidth - thumbPos - 1),
                      style: _draggingSlider
                          ? Style().foreground(theme.onSurface)
                          : Style().foreground(theme.muted),
                    ),
                  ],
                ),
              ),
            ),
            w.Text('$pct%', style: theme.labelSmall),
          ],
        ),
      ],
    );
  }

  tui.Cmd? _onSliderDragStart(w.DragStartDetails d) {
    _sliderDragStartX = d.globalPosition.dx.round();
    _sliderDragStartValue = _sliderValue;
    setState(() {
      _draggingSlider = true;
      _updateDetails(
        'dragStart',
        d.globalPosition,
        d.localPosition,
        button: d.button,
      );
    });
    return null;
  }

  tui.Cmd? _onSliderDragUpdate(w.DragUpdateDetails d) {
    final dx = d.globalPosition.dx.round() - _sliderDragStartX;
    final next = _sliderDragStartValue + dx / (_sliderWidth - 1);
    setState(() {
      _sliderValue = next.clamp(0.0, 1.0);
      _updateDetails(
        'dragUpdate',
        d.globalPosition,
        d.localPosition,
        delta: d.delta,
      );
    });
    return null;
  }

  tui.Cmd? _onSliderDragEnd(w.DragEndDetails d) {
    setState(() {
      _draggingSlider = false;
      _updateDetailsEnd('dragEnd', d.globalPosition, d.localPosition);
    });
    return null;
  }

  // ---------------------------------------------------------------------------
  // 2) Resizable split-pane — uses globalPosition for absolute tracking
  // ---------------------------------------------------------------------------

  w.Widget _buildSplitter(w.Theme theme) {
    return w.Column(
      gap: 0,
      children: [
        w.Text('Split Pane (drag the divider)', style: theme.titleMedium),
        w.Row(
          gap: 0,
          children: [
            w.Container(
              width: _splitWidth,
              height: 6,
              color: theme.surface,
              padding: const w.EdgeInsets.all(1),
              child: w.Column(
                gap: 0,
                children: [
                  w.Text('Left pane', style: theme.bodySmall),
                  w.Text('width: $_splitWidth', style: theme.labelSmall),
                ],
              ),
            ),
            w.GestureDetector(
              onDragStart: _onSplitDragStart,
              onDragUpdate: _onSplitDragUpdate,
              onDragEnd: _onSplitDragEnd,
              child: w.Container(
                width: 3,
                height: 6,
                color: _draggingSplit ? theme.primary : theme.border,
                alignment: w.Alignment.center,
                child: w.Text(
                  _draggingSplit ? '┃' : '│',
                  style: Style().foreground(
                    _draggingSplit ? theme.onPrimary : theme.onSurface,
                  ),
                ),
              ),
            ),
            w.Container(
              width: 28,
              height: 6,
              color: theme.surface,
              padding: const w.EdgeInsets.all(1),
              child: w.Text('Right pane', style: theme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }

  tui.Cmd? _onSplitDragStart(w.DragStartDetails d) {
    _splitDragStartX = d.globalPosition.dx.round();
    _splitDragStartWidth = _splitWidth;
    setState(() {
      _draggingSplit = true;
      _updateDetails(
        'dragStart',
        d.globalPosition,
        d.localPosition,
        button: d.button,
      );
    });
    return null;
  }

  tui.Cmd? _onSplitDragUpdate(w.DragUpdateDetails d) {
    final dx = d.globalPosition.dx.round() - _splitDragStartX;
    final next = (_splitDragStartWidth + dx).clamp(_splitMin, _splitMax);
    setState(() {
      _splitWidth = next.toInt();
      _updateDetails(
        'dragUpdate',
        d.globalPosition,
        d.localPosition,
        delta: d.delta,
      );
    });
    return null;
  }

  tui.Cmd? _onSplitDragEnd(w.DragEndDetails d) {
    setState(() {
      _draggingSplit = false;
      _updateDetailsEnd('dragEnd', d.globalPosition, d.localPosition);
    });
    return null;
  }

  // ---------------------------------------------------------------------------
  // 3) Moveable box — uses globalPosition for absolute tracking
  //
  // We track the global mouse position at drag start and compute the box
  // offset from that, rather than using delta. This avoids the box drifting
  // if it gets clamped to bounds while the mouse keeps moving.
  // ---------------------------------------------------------------------------

  w.Widget _buildMoveableBox(w.Theme theme) {
    final boxColor = _draggingBox ? theme.primary : theme.secondary;
    final textStyle = Style().foreground(
      _draggingBox ? theme.onPrimary : theme.onSecondary,
    );

    return w.Column(
      gap: 0,
      children: [
        w.Text('Moveable Box (drag in 2D)', style: theme.titleMedium),
        w.Stack(
          width: _arenaW,
          height: _arenaH,
          children: [
            // Background
            w.Container(
              width: _arenaW,
              height: _arenaH,
              color: theme.background,
            ),
            // Draggable box
            w.Positioned(
              left: _boxX,
              top: _boxY,
              child: w.GestureDetector(
                onDragStart: _onBoxDragStart,
                onDragUpdate: _onBoxDragUpdate,
                onDragEnd: _onBoxDragEnd,
                child: w.Container(
                  width: _boxW,
                  height: _boxH,
                  color: boxColor,
                  alignment: w.Alignment.center,
                  child: w.Text('Drag me', style: textStyle),
                ),
              ),
            ),
          ],
        ),
        w.Text('Position: ($_boxX, $_boxY)', style: theme.labelSmall),
      ],
    );
  }

  tui.Cmd? _onBoxDragStart(w.DragStartDetails d) {
    _boxDragStartX = d.globalPosition.dx.round();
    _boxDragStartY = d.globalPosition.dy.round();
    _boxDragStartBoxX = _boxX;
    _boxDragStartBoxY = _boxY;
    setState(() {
      _draggingBox = true;
      _updateDetails(
        'dragStart',
        d.globalPosition,
        d.localPosition,
        button: d.button,
      );
    });
    return null;
  }

  tui.Cmd? _onBoxDragUpdate(w.DragUpdateDetails d) {
    final dx = d.globalPosition.dx.round() - _boxDragStartX;
    final dy = d.globalPosition.dy.round() - _boxDragStartY;
    setState(() {
      _boxX = (_boxDragStartBoxX + dx).clamp(0, _arenaW - _boxW);
      _boxY = (_boxDragStartBoxY + dy).clamp(0, _arenaH - _boxH);
      _updateDetails(
        'dragUpdate',
        d.globalPosition,
        d.localPosition,
        delta: d.delta,
      );
    });
    return null;
  }

  tui.Cmd? _onBoxDragEnd(w.DragEndDetails d) {
    setState(() {
      _draggingBox = false;
      _updateDetailsEnd('dragEnd', d.globalPosition, d.localPosition);
    });
    return null;
  }

  // ---------------------------------------------------------------------------
  // Status panel — shows detail object contents
  // ---------------------------------------------------------------------------

  w.Widget _buildDetails(w.Theme theme) {
    return w.Container(
      width: 52,
      color: theme.surface,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 0,
        children: [
          w.Text('Drag Details (last event)', style: theme.titleSmall),
          w.Row(
            gap: 1,
            children: [
              w.Text('Phase:', style: theme.labelSmall),
              w.Text(_phase, style: _phaseStyle(theme)),
            ],
          ),
          w.Row(
            gap: 1,
            children: [
              w.Text('Global:', style: theme.labelSmall),
              w.Text(_globalPos, style: theme.bodySmall),
              w.Text('Local:', style: theme.labelSmall),
              w.Text(_localPos, style: theme.bodySmall),
            ],
          ),
          w.Row(
            gap: 1,
            children: [
              w.Text('Delta:', style: theme.labelSmall),
              w.Text(_delta, style: theme.bodySmall),
              w.Text('Button:', style: theme.labelSmall),
              w.Text(_button, style: theme.bodySmall),
            ],
          ),
          w.Text('Total drags: $_dragCount', style: theme.labelSmall),
        ],
      ),
    );
  }

  Style _phaseStyle(w.Theme theme) {
    final color = switch (_phase) {
      'dragStart' => theme.success,
      'dragUpdate' => theme.warning,
      'dragEnd' => theme.error,
      _ => theme.muted,
    };
    return Style().foreground(color).bold();
  }

  void _updateDetails(
    String phase,
    w.Offset global,
    w.Offset local, {
    w.Offset? delta,
    tui.MouseButton? button,
  }) {
    _phase = phase;
    _globalPos = '(${global.dx.round()}, ${global.dy.round()})';
    _localPos = '(${local.dx.round()}, ${local.dy.round()})';
    if (delta != null) {
      _delta = '(${delta.dx.round()}, ${delta.dy.round()})';
    }
    if (button != null) {
      _button = button.name;
    }
    if (phase == 'dragStart') _dragCount++;
  }

  void _updateDetailsEnd(String phase, w.Offset global, w.Offset local) {
    _phase = phase;
    _globalPos = '(${global.dx.round()}, ${global.dy.round()})';
    _localPos = '(${local.dx.round()}, ${local.dy.round()})';
    _delta = '--';
  }

  // ---------------------------------------------------------------------------
  // Keyboard
  // ---------------------------------------------------------------------------

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key)) {
      if (key.char == 'q') return tui.Cmd.quit();
      // h/j/k/l to nudge the moveable box via keyboard.
      if (key.char == 'h' || key.char == 'H') {
        setState(() => _boxX = (_boxX - 1).clamp(0, _arenaW - _boxW));
      }
      if (key.char == 'l' || key.char == 'L') {
        setState(() => _boxX = (_boxX + 1).clamp(0, _arenaW - _boxW));
      }
      if (key.char == 'k' || key.char == 'K') {
        setState(() => _boxY = (_boxY - 1).clamp(0, _arenaH - _boxH));
      }
      if (key.char == 'j' || key.char == 'J') {
        setState(() => _boxY = (_boxY + 1).clamp(0, _arenaH - _boxH));
      }
    }
    return null;
  }
}
