// InheritedWidget Example
//
// Run with: dart run example/tui/examples/widgets/inherited-widget/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ThemeHost(), scanZones: false);
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      useUltravioletRenderer: false,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ThemeHost extends w.StatefulWidget {
  ThemeHost({super.key});

  @override
  w.State createState() => _ThemeHostState();
}

class _ThemeHostState extends w.State<ThemeHost> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  final List<(String, Color)> themes = [
    ('Sunrise', Colors.warning),
    ('Ocean', Colors.info),
    ('Forest', Colors.success),
  ];
  int index = 0;

  (String, Color) get current => themes[index % themes.length];

  @override
  w.Widget build(w.BuildContext context) {
    final (label, accent) = current;
    return ThemeAccent(
      label: label,
      accent: accent,
      child: w.Container(
        padding: const w.EdgeInsets.all(1),
        color: widget.theme.background,
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
                  w.Text(
                    'InheritedWidget Demo',
                    style: widget.theme.titleLarge,
                  ),
                  ThemeBadge(),
                  ThemeStatus(),
                  w.Text(
                    'Press t to toggle theme, q to quit',
                    style: widget.theme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') {
        return tui.Cmd.quit();
      }
      if (key.char == 't') {
        setState(() => index = (index + 1) % themes.length);
      }
    }
    return null;
  }
}

class ThemeAccent extends w.InheritedWidget {
  ThemeAccent({
    required this.label,
    required this.accent,
    required super.child,
  });

  final String label;
  final Color accent;

  static ThemeAccent? of(w.BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeAccent>();
  }

  @override
  bool updateShouldNotify(covariant ThemeAccent oldWidget) {
    return oldWidget.label != label || oldWidget.accent != accent;
  }
}

class ThemeBadge extends w.StatelessWidget {
  ThemeBadge({super.key});

  @override
  w.Widget build(w.BuildContext context) {
    final inherited = ThemeAccent.of(context);
    final label = inherited?.label ?? 'Unknown';
    final accent = inherited?.accent ?? Colors.muted;

    return w.Container(
      padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      color: accent,
      child: w.Text(label, style: Style().foreground(Colors.white)),
    );
  }
}

class ThemeStatus extends w.StatelessWidget {
  ThemeStatus({super.key});

  @override
  w.Widget build(w.BuildContext context) {
    final host = context.findAncestorStateOfType<_ThemeHostState>();
    final index = host?.index ?? 0;
    return w.Text('Theme index: $index');
  }
}
