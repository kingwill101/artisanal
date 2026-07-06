// AnimatedTint & FadeTint Example
//
// Demonstrates AnimatedTint (animates between two colors) and FadeTint
// (fades a single color in/out). Press 'a' to restart AnimatedTint,
// 'f' to toggle FadeTint fade direction.
//
// Run with: dart run example/animated_tint/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/widgets.dart';

void main() async {
  final app = WidgetApp(AnimatedTintDemo());
  await runProgram(
    app,
    options: const ProgramOptions(
      altScreen: true,
      mouseMode: MouseMode.allMotion,
    ),
  );
}

class AnimatedTintDemo extends StatefulWidget {
  AnimatedTintDemo({super.key});

  @override
  State createState() => _AnimatedTintDemoState();
}

class _AnimatedTintDemoState extends State<AnimatedTintDemo> {
  final WidgetScrollController _scrollController = WidgetScrollController();
  late final List<AnimationController> _timelineControllers;
  late final AnimationTimeline _timeline;
  late final AnimationController _pulseController;
  late final AnimationTimeline _pulseTimeline;
  int _animColorIndex = 0;
  bool _fadeIn = true;
  int _fadeKey = 0;
  int _animKey = 0;
  String _timelineStatus = 'idle';
  String _pulseStatus = 'idle';

  static final _colorPairs = [
    (Colors.red, Colors.blue, 'Red -> Blue'),
    (Colors.green, Colors.yellow, 'Green -> Yellow'),
    (Colors.cyan, Colors.magenta, 'Cyan -> Magenta'),
    (Colors.blue, Colors.green, 'Blue -> Green'),
  ];

  @override
  void initState() {
    super.initState();
    _timelineControllers = List<AnimationController>.generate(
      3,
      (index) => AnimationController(
        value: 0.0,
        duration: Duration(milliseconds: 420 + (index * 120)),
      ),
      growable: false,
    );
    for (final controller in _timelineControllers) {
      controller.addListener(() => setState(() {}));
    }
    _pulseController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 280),
    )..addListener(() => setState(() {}));
    _timeline = AnimationTimeline.cascade(
      controllers: _timelineControllers,
      hold: const Duration(milliseconds: 90),
      gap: const Duration(milliseconds: 120),
      rest: const Duration(milliseconds: 180),
      repeat: true,
      alternate: true,
      labelBuilder: (index, phase) => 'cascade-$phase-$index',
      onStepStart: (index, step, direction) {
        setState(() {
          _timelineStatus = 'start ${step.label ?? index} ${direction.name}';
        });
      },
      onStepComplete: (index, step, direction) {
        setState(() {
          _timelineStatus = 'done ${step.label ?? index} ${direction.name}';
        });
      },
    );
    _pulseTimeline = AnimationTimeline.pulse(
      controller: _pulseController,
      hold: const Duration(milliseconds: 120),
      rest: const Duration(milliseconds: 180),
      repeat: true,
      onStepStart: (index, step, direction) {
        setState(() {
          _pulseStatus = 'start ${step.label ?? index} ${direction.name}';
        });
      },
      onStepComplete: (index, step, direction) {
        setState(() {
          _pulseStatus = 'done ${step.label ?? index} ${direction.name}';
        });
      },
    );
  }

  @override
  Cmd? handleInit() =>
      _mergeCmds([_timeline.start(), _pulseTimeline.start()]);

  @override
  Cmd? handleUpdate(Msg msg) {
    final timelineCmd = _timeline.handleMessage(msg);
    final pulseCmd = _pulseTimeline.handleMessage(msg);
    if (msg is KeyMsg) {
      if (msg.key.char == 'q') {
        return _mergeCmds([timelineCmd, pulseCmd, Cmd.quit()]);
      }
      if (msg.key.char == 'a') {
        setState(() {
          _animColorIndex = (_animColorIndex + 1) % _colorPairs.length;
          _animKey++;
        });
      }
      if (msg.key.char == 'f') {
        setState(() {
          _fadeIn = !_fadeIn;
          _fadeKey++;
        });
      }
      if (msg.key.char == 't') {
        _timeline.reset();
        _pulseTimeline.reset();
        return _mergeCmds([
          timelineCmd,
          pulseCmd,
          _timeline.start(direction: TimelineDirection.forward),
          _pulseTimeline.start(direction: TimelineDirection.forward),
        ]);
      }
    }
    return _mergeCmds([timelineCmd, pulseCmd]);
  }

  @override
  void dispose() {
    for (final controller in _timelineControllers) {
      controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = Style()..foreground(theme.onSurface);

    final pair = _colorPairs[_animColorIndex];

    return Container(
      child: Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: ScrollbarGradient.background(
          start: hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: ScrollbarGradient.background(
          start: hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: ScrollbarGradient.background(
          start: hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: Container(
            padding: const EdgeInsets.all(1),
            color: theme.background,
            child: Column(
              gap: 1,
              children: [
                Text('AnimatedTint & FadeTint Demo', style: theme.titleLarge),
                Text(
                  'a = cycle AnimatedTint colors | f = toggle FadeTint | t = restart timeline | q = quit',
                  style: label,
                ),
                Divider(width: 65),

                // AnimatedTint section
                Text('AnimatedTint (${pair.$3}):', style: theme.titleMedium),
                AnimatedTint(
                  key: ValueKey('anim-$_animKey'),
                  begin: pair.$1,
                  end: pair.$2,
                  duration: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 50,
                    height: 3,
                    color: theme.surface,
                    alignment: Alignment.center,
                    child: Text(
                      'Animated color transition',
                      style: onSurface,
                    ),
                  ),
                ),
                Divider(width: 65),

                // FadeTint section
                Text(
                  'FadeTint (${_fadeIn ? "Fade In" : "Fade Out"}):',
                  style: theme.titleMedium,
                ),
                FadeTint(
                  key: ValueKey('fade-$_fadeKey'),
                  color: Colors.blue,
                  duration: const Duration(milliseconds: 1000),
                  fadeIn: _fadeIn,
                  child: Container(
                    width: 50,
                    height: 3,
                    color: theme.surface,
                    alignment: Alignment.center,
                    child: Text('Blue fade tint overlay', style: onSurface),
                  ),
                ),
                Divider(width: 65),

                Text(
                  'AnimationTimeline choreography:',
                  style: theme.titleMedium,
                ),
                Text('Timeline: $_timelineStatus', style: label),
                for (
                  var index = 0;
                  index < _timelineControllers.length;
                  index++
                )
                  Text(
                    'lane ${index + 1} ${_timelineBar(_timelineControllers[index].value)}',
                    style: label,
                  ),
                Text('Pulse preset: $_pulseStatus', style: label),
                Text(
                  'pulse ${_timelineBar(_pulseController.value)}',
                  style: label,
                ),
                Text(
                  'These lanes are driven by AnimationTimeline.staggered(...) plus AnimationTimeline.pulse(...) for the repeating emphasis lane.',
                  style: label,
                ),
                Divider(width: 65),

                // Info
                Text(
                  'AnimatedTint interpolates between two colors over time.\n'
                  'FadeTint fades a single color opacity from 0 to 1 (or reverse).\n'
                  'The timeline section below is controller choreography rather than implicit animation.',
                  style: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Cmd? _mergeCmds(List<Cmd?> cmds) {
    final concrete = cmds.whereType<Cmd>().toList(growable: false);
    if (concrete.isEmpty) return null;
    if (concrete.length == 1) return concrete.first;
    return Cmd.batch(concrete);
  }

  static String _timelineBar(double value) {
    const width = 18;
    final filled = (value.clamp(0.0, 1.0) * width).round();
    return '[${'#' * filled}${'-' * (width - filled)}] ${value.toStringAsFixed(2)}';
  }
}
