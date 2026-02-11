// Theme & MediaQuery Showcase
//
// Demonstrates Theme (dark/light/adaptive), ThemeScope for propagating
// themes down the widget tree, theme color palette, typography styles,
// and MediaQuery for responsive layout.
//
// Run with: dart run example/theme/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ThemeShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ThemeShowcase extends w.StatefulWidget {
  ThemeShowcase({super.key});

  @override
  w.State createState() => _ThemeShowcaseState();
}

class _ThemeShowcaseState extends w.State<ThemeShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _useDark = w.hasDarkBackground;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = _useDark ? w.Theme.dark() : w.Theme.light();
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    // MediaQuery
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();
    final height = media.size.height.round();

    return w.ThemeScope(
      theme: theme,
      child: w.Container(
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
                  w.Text(
                    'Theme & MediaQuery Showcase',
                    style: theme.titleLarge,
                  ),
                  w.Text('t: toggle dark/light, q: quit', style: label),
                  w.Divider(width: 60),

                  // -- MediaQuery info --
                  w.Text('MediaQuery', style: theme.titleMedium),
                  w.Text(
                    'Terminal size: ${width}x$height',
                    style: theme.bodyMedium,
                  ),
                  w.Divider(width: 60),

                  // -- Color palette --
                  w.Text(
                    'Theme: ${_useDark ? "Dark" : "Light"}',
                    style: theme.titleMedium,
                  ),
                  w.Row(
                    gap: 1,
                    children: [
                      _swatch('Primary', theme.primary, theme),
                      _swatch('Secondary', theme.secondary, theme),
                      _swatch('Surface', theme.surface, theme),
                      _swatch('Background', theme.background, theme),
                    ],
                  ),
                  w.Row(
                    gap: 1,
                    children: [
                      _swatch('Success', theme.success, theme),
                      _swatch('Error', theme.error, theme),
                      _swatch('Warning', theme.warning, theme),
                      _swatch('Muted', theme.muted, theme),
                    ],
                  ),
                  w.Divider(width: 60),

                  // -- Typography --
                  w.Text('Typography', style: theme.titleMedium),
                  w.Text('titleLarge', style: theme.titleLarge),
                  w.Text('titleMedium', style: theme.titleMedium),
                  w.Text('bodyMedium', style: theme.bodyMedium),
                  w.Text('labelSmall', style: theme.labelSmall),
                  w.Divider(width: 60),

                  // -- ThemeScope nesting --
                  w.Text(
                    'ThemeScope: nested override',
                    style: theme.titleMedium,
                  ),
                  w.Row(
                    gap: 2,
                    children: [
                      w.Container(
                        width: 20,
                        height: 3,
                        color: theme.surface,
                        alignment: w.Alignment.center,
                        child: w.Text(
                          'Outer theme',
                          style: Style().foreground(theme.onSurface),
                        ),
                      ),
                      w.ThemeScope(
                        theme: _useDark ? w.Theme.light() : w.Theme.dark(),
                        child: _InnerThemeBox(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  w.Widget _swatch(String name, Color color, w.Theme theme) {
    return w.Container(
      width: 14,
      height: 2,
      color: color,
      alignment: w.Alignment.center,
      child: w.Text(name, style: Style().foreground(theme.onPrimary)),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q') return tui.Cmd.quit();
      if (key.char == 't') {
        setState(() => _useDark = !_useDark);
      }
    }
    return null;
  }
}

/// Inner widget that reads theme from ThemeScope.
class _InnerThemeBox extends w.StatelessWidget {
  _InnerThemeBox();

  @override
  w.Widget build(w.BuildContext context) {
    final inner = w.ThemeScope.of(context);
    return w.Container(
      width: 20,
      height: 3,
      color: inner.surface,
      alignment: w.Alignment.center,
      child: w.Text('Inner theme', style: Style().foreground(inner.onSurface)),
    );
  }
}
