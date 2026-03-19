// HelpView Showcase
//
// Demonstrates compact and full HelpView layouts, custom styling, and an
// interactive preview that toggles between the two modes.
//
// Run with: dart run example/help_view/main.dart

import 'package:artisanal/app.dart' as app;
import 'package:artisanal/style.dart'
    show AdaptiveColor, BasicColor, Color, CompleteAdaptiveColor;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/widgets.dart' as w;

app.WidgetApp createHelpViewApp() => app.WidgetApp(
  HelpViewShowcase(),
  backgroundColorBuilder: _resolvedHelpViewTerminalBackground,
);

Color _resolvedHelpViewTerminalBackground() {
  final background = w.currentTheme.background;
  final resolved = switch (background) {
    AdaptiveColor(:final light, :final dark) => w.hasDarkBackground
        ? dark
        : light,
    CompleteAdaptiveColor(:final light, :final dark) => w.hasDarkBackground
        ? dark
        : light,
    _ => background,
  };
  final hex = resolved.toHex();
  return hex.isEmpty ? resolved : BasicColor(hex);
}

void main() async {
  final shell = createHelpViewApp();
  await runtime.runProgram(
    shell,
    options: const runtime.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: runtime.MouseMode.allMotion,
    ),
  );
}

class HelpViewShowcase extends w.StatefulWidget {
  HelpViewShowcase({super.key});

  @override
  w.State createState() => _HelpViewShowcaseState();
}

class _HelpViewShowcaseState extends w.State<HelpViewShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  final _keyMap = _HelpExampleKeyMap();

  bool _showAll = false;

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final accentKeyStyle = theme.titleSmall.copy()..foreground(theme.primary);
    final accentDescriptionStyle = theme.labelSmall.copy()
      ..foreground(theme.onSurface);
    // Leave one spare column beyond the scrollbar so terminals with
    // right-edge autowrap quirks do not have to redraw into the absolute
    // last cell of the viewport.
    final contentWidth = (media.size.width.round() - 5).clamp(32, 2000);
    final dividerWidth = (contentWidth - 2).clamp(24, 2000);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            width: contentWidth,
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text('HelpView Showcase', style: theme.titleLarge),
              w.Text(
                'Press ? to toggle the preview mode. Press q to quit.',
                style: label,
              ),
              w.Divider(width: dividerWidth),

              w.Text('Interactive Preview', style: theme.titleMedium),
              // Keep this preview unframed so partial scroll does not expose
              // clipped border/padding rows at the top of the viewport.
              w.Container(
                padding: const w.EdgeInsets.symmetric(horizontal: 2),
                child: w.Column(
                  gap: 1,
                  children: [
                    w.Text(
                      _showAll ? 'Full grouped mode' : 'Compact mode',
                      style: theme.labelSmall,
                    ),
                    w.HelpView(
                      keyMap: _keyMap,
                      showAll: _showAll,
                      columnGap: 6,
                    ),
                  ],
                ),
              ),
              w.Divider(width: dividerWidth),

              w.Text('Compact Footer Style', style: theme.titleMedium),
              w.HelpView(keyMap: _keyMap),
              w.Divider(width: dividerWidth),

              w.Text('Full Grouped Help', style: theme.titleMedium),
              w.HelpView(keyMap: _keyMap, showAll: true, columnGap: 6),
              w.Divider(width: dividerWidth),

              w.Text('Custom Styling', style: theme.titleMedium),
              w.HelpView(
                keyMap: _keyMap,
                itemSpacing: 2,
                keyStyle: accentKeyStyle,
                descriptionStyle: accentDescriptionStyle,
              ),
              w.Divider(width: dividerWidth),

              w.Text('Status Bar Pairing', style: theme.titleMedium),
              w.StatusBar(
                items: [
                  w.KeyHint(keyLabel: '?', description: 'toggle preview'),
                  w.KeyHint(keyLabel: 'j/k', description: 'navigate'),
                  w.KeyHint(keyLabel: 'q', description: 'quit'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is runtime.KeyMsg) {
      if (msg.key.char == 'q') return runtime.Cmd.quit();
      if (msg.key.char == '?') {
        setState(() => _showAll = !_showAll);
      }
    }
    return null;
  }
}

class _HelpExampleKeyMap implements w.KeyMap {
  final next = w.KeyBinding.withHelp(['down', 'j'], '↓/j', 'next item');
  final previous = w.KeyBinding.withHelp(['up', 'k'], '↑/k', 'previous item');
  final open = w.KeyBinding.withHelp(['enter'], '↵', 'open item');
  final palette = w.KeyBinding.withHelp(['ctrl+p'], 'ctrl+p', 'commands');
  final search = w.KeyBinding.withHelp(['/'], '/', 'search');
  final filter = w.KeyBinding.withHelp(['f'], 'f', 'filter');
  final help = w.KeyBinding.withHelp(['?'], '?', 'toggle help');
  final quit = w.KeyBinding.withHelp(['q'], 'q', 'quit');

  @override
  List<w.KeyBinding> shortHelp() => [palette, search, help, quit];

  @override
  List<List<w.KeyBinding>> fullHelp() => [
    [previous, next, open],
    [palette, search, filter],
    [help, quit],
  ];
}
