// Buttons & Badge Showcase
//
// Demonstrates Button with all variants (primary, secondary, outline,
// ghost, danger), Flutter-style wrappers (ElevatedButton, FilledButton,
// TextButton, OutlinedButton, IconButton), all sizes (small, medium,
// large), disabled state, and Badge with custom colors.
//
// Run with: dart run example/buttons/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  // Keep primary text high-contrast regardless of terminal background report.
  w.setTheme(
    w.Theme.adaptive().copyWith(
      onPrimary: const AdaptiveColor(
        light: AnsiColor(255),
        dark: AnsiColor(255),
      ),
    ),
  );

  final app = tui.WidgetApp(ButtonShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ButtonShowcase extends w.StatefulWidget {
  ButtonShowcase({super.key});

  @override
  w.State createState() => _ButtonShowcaseState();
}

class _ButtonShowcaseState extends w.State<ButtonShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  String _lastClicked = 'None';
  int _clickCount = 0;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

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
            children: [
              w.Text('Buttons & Badge Showcase', style: theme.titleLarge),
              w.Text('Click buttons to see feedback. q to quit.', style: label),
              w.Divider(width: 60),

              // -- Button variants --
              w.Text('Button Variants', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.Button(
                    label: 'Primary',
                    variant: w.ButtonVariant.primary,
                    onPressed: () => _press('Primary'),
                  ),
                  w.Button(
                    label: 'Secondary',
                    variant: w.ButtonVariant.secondary,
                    onPressed: () => _press('Secondary'),
                  ),
                  w.Button(
                    label: 'Outline',
                    variant: w.ButtonVariant.outline,
                    onPressed: () => _press('Outline'),
                  ),
                  w.Button(
                    label: 'Ghost',
                    variant: w.ButtonVariant.ghost,
                    onPressed: () => _press('Ghost'),
                  ),
                  w.Button(
                    label: 'Danger',
                    variant: w.ButtonVariant.danger,
                    onPressed: () => _press('Danger'),
                  ),
                ],
              ),
              w.Divider(width: 60),

              // -- Flutter-style wrappers --
              w.Text('Flutter-style Buttons', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.ElevatedButton(
                    child: w.Text('Elevated'),
                    onPressed: () => _press('ElevatedButton'),
                  ),
                  w.FilledButton(
                    child: w.Text('Filled'),
                    onPressed: () => _press('FilledButton'),
                  ),
                  w.FilledButton.tonal(
                    child: w.Text('Tonal'),
                    onPressed: () => _press('FilledButton.tonal'),
                  ),
                ],
              ),
              w.Row(
                gap: 1,
                children: [
                  w.TextButton(
                    child: w.Text('Text'),
                    onPressed: () => _press('TextButton'),
                  ),
                  w.OutlinedButton(
                    child: w.Text('Outlined'),
                    onPressed: () => _press('OutlinedButton'),
                  ),
                  w.IconButton(
                    icon: w.Text('*'),
                    onPressed: () => _press('IconButton'),
                  ),
                ],
              ),
              w.Text(
                'Wrappers use child widgets (Flutter-style API).',
                style: label,
              ),
              w.Divider(width: 60),

              // -- Button sizes --
              w.Text('Button Sizes', style: theme.titleMedium),
              w.Row(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.end,
                children: [
                  w.Button(
                    label: 'Small',
                    size: w.ButtonSize.small,
                    onPressed: () => _press('Small'),
                  ),
                  w.Button(
                    label: 'Medium',
                    size: w.ButtonSize.medium,
                    onPressed: () => _press('Medium'),
                  ),
                  w.Button(
                    label: 'Large',
                    size: w.ButtonSize.large,
                    onPressed: () => _press('Large'),
                  ),
                ],
              ),
              w.Divider(width: 60),

              // -- Disabled button --
              w.Text('Disabled', style: theme.titleMedium),
              w.Row(
                gap: 1,
                children: [
                  w.Button(
                    label: 'Disabled',
                    enabled: false,
                    onPressed: () => _press('Disabled'),
                  ),
                  w.FilledButton(
                    child: w.Text('Filled off'),
                    enabled: false,
                    onPressed: () => _press('Filled off'),
                  ),
                  w.IconButton(
                    icon: w.Text('*'),
                    enabled: false,
                    onPressed: () => _press('Icon off'),
                  ),
                ],
              ),
              w.Divider(width: 60),

              // -- Badge --
              w.Text('Badge', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Badge('Default'),
                  w.Badge(
                    'Warning',
                    background: theme.warning,
                    foreground: theme.onSurface,
                  ),
                  w.Badge(
                    'Error',
                    background: theme.error,
                    foreground: theme.onError,
                  ),
                  w.Badge(
                    'Success',
                    background: theme.success,
                    foreground: theme.onSurface,
                  ),
                  w.Badge(
                    'Muted',
                    background: theme.surface,
                    foreground: theme.onSurface,
                  ),
                ],
              ),
              w.Divider(width: 60),

              // -- Status --
              w.Text(
                'Last clicked: $_lastClicked ($_clickCount)',
                style: label,
              ),
            ],
          ),
        ),
      ),
    );
  }

  tui.Cmd? _press(String name) {
    setState(() {
      _lastClicked = name;
      _clickCount++;
    });
    return null;
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
