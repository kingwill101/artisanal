// InheritedWidget Example
import 'package:artisanal/widgets.dart' as w;
import 'package:artisanal/widgets.dart' as tui hide Key, TextSelection;
//
// Run with: dart run example/tui/examples/widgets/inherited-widget/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

void main() async {
  final app = tui.WidgetApp(ThemeHost(), scanZones: false);
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      useUltravioletRenderer: false,
    ),
  );
}

class ThemeHost extends w.StatefulWidget {
  ThemeHost({super.key});

  @override
  w.State createState() => _ThemeHostState();
}

class _ThemeHostState extends w.State<ThemeHost> {
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
        child: w.Column(
          gap: 1,
          children: [
            w.Text('InheritedWidget Demo', style: widget.theme.titleLarge),
            ThemeBadge(),
            ThemeStatus(),
            w.Text(
              'Press t to toggle theme, q to quit',
              style: widget.theme.labelSmall,
            ),
          ],
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
