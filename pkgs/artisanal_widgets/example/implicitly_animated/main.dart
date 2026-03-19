// ImplicitlyAnimatedWidget Example
//
// Demonstrates the ImplicitlyAnimatedWidget pattern by creating a concrete
// AnimatedBox that animates width changes. Press +/- to change width,
// 'c' to cycle colors (animated).
//
// Run with: dart run example/implicitly_animated/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ImplicitlyAnimatedDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ImplicitlyAnimatedDemo extends w.StatefulWidget {
  ImplicitlyAnimatedDemo({super.key});

  @override
  w.State createState() => _ImplicitlyAnimatedDemoState();
}

class _ImplicitlyAnimatedDemoState extends w.State<ImplicitlyAnimatedDemo> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _width = 20;
  int _height = 3;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == '+') {
        setState(() => _width = (_width + 5).clamp(10, 60));
      }
      if (msg.key.char == '-') {
        setState(() => _width = (_width - 5).clamp(10, 60));
      }
      if (msg.key.type == tui.KeyType.up) {
        setState(() => _height = (_height + 1).clamp(1, 10));
      }
      if (msg.key.type == tui.KeyType.down) {
        setState(() => _height = (_height - 1).clamp(1, 10));
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final onSurface = Style()..foreground(theme.onSurface);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
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
            crossAxisAlignment: w.CrossAxisAlignment.start,
            children: [
              w.Text('ImplicitlyAnimatedWidget Demo', style: theme.titleLarge),
              w.Text('+/- = width | up/down = height | q = quit', style: label),
              w.Text(
                'Target Width: $_width | Target Height: $_height',
                style: label,
              ),
              w.Divider(width: 65),

              // AnimatedBox demo
              w.Text(
                'AnimatedBox (animates width & height):',
                style: theme.titleMedium,
              ),
              AnimatedBox(
                targetWidth: _width,
                targetHeight: _height,
                duration: const Duration(milliseconds: 800),
                child: w.Container(
                  color: theme.surface,
                  alignment: w.Alignment.center,
                  child: w.Text('Animated', style: onSurface),
                ),
              ),
              w.Divider(width: 65),

              // Explanation
              w.Text(
                'How ImplicitlyAnimatedWidget works:',
                style: theme.titleMedium,
              ),
              w.Text(
                'Subclass ImplicitlyAnimatedWidget and provide a duration.\n'
                'In the State, extend AnimatedWidgetBaseState and override\n'
                'forEachTween() to declare which properties animate.\n'
                'When properties change, the framework automatically\n'
                'animates from old to new values using the controller.',
                style: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Custom ImplicitlyAnimatedWidget ----------

/// An example ImplicitlyAnimatedWidget that animates width and height.
class AnimatedBox extends w.ImplicitlyAnimatedWidget {
  AnimatedBox({
    required this.targetWidth,
    required this.targetHeight,
    this.child,
    required super.duration,
    super.curve,
    super.key,
  });

  final int targetWidth;
  final int targetHeight;
  final w.Widget? child;

  @override
  w.AnimatedWidgetBaseState<AnimatedBox> createState() => _AnimatedBoxState();
}

class _AnimatedBoxState extends w.AnimatedWidgetBaseState<AnimatedBox> {
  w.Tween<double>? _widthTween;
  w.Tween<double>? _heightTween;

  @override
  void forEachTween(w.TweenVisitor visitor) {
    _widthTween =
        visitor(
              _widthTween,
              widget.targetWidth.toDouble(),
              (value) => w.Tween<double>(begin: value as double, end: value),
            )
            as w.Tween<double>?;

    _heightTween =
        visitor(
              _heightTween,
              widget.targetHeight.toDouble(),
              (value) => w.Tween<double>(begin: value as double, end: value),
            )
            as w.Tween<double>?;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final animatedWidth =
        _widthTween?.evaluate(controller) ?? widget.targetWidth.toDouble();
    final animatedHeight =
        _heightTween?.evaluate(controller) ?? widget.targetHeight.toDouble();

    return w.SizedBox(
      width: animatedWidth.round(),
      height: animatedHeight.round(),
      child: widget.child,
    );
  }
}
