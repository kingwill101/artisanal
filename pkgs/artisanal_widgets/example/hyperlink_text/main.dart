// HyperlinkText Showcase
//
// Demonstrates HyperlinkText with labeled links, bare URLs, custom colors,
// and links embedded in other layouts. Requires a terminal that supports
// OSC 8 hyperlinks (e.g., iTerm2, WezTerm, Windows Terminal, foot, kitty).
//
// Run with: dart run example/hyperlink_text/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(HyperlinkTextShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class HyperlinkTextShowcase extends w.StatefulWidget {
  HyperlinkTextShowcase({super.key});

  @override
  w.State createState() => _HyperlinkTextShowcaseState();
}

class _HyperlinkTextShowcaseState extends w.State<HyperlinkTextShowcase> {
  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        gap: 1,
        children: [
          w.Text('HyperlinkText Showcase', style: theme.titleLarge),
          w.Text(
            'Hover/click links if your terminal supports OSC 8.  q: quit',
            style: label,
          ),
          w.Divider(width: 60),

          // -- Labeled links --
          w.Text('Labeled Links', style: theme.titleMedium),
          w.HyperlinkText(
            url: 'https://dart.dev',
            label: 'Dart Programming Language',
          ),
          w.HyperlinkText(url: 'https://github.com', label: 'GitHub'),
          w.HyperlinkText(
            url: 'https://pub.dev',
            label: 'Dart Package Registry (pub.dev)',
          ),
          w.Divider(width: 60),

          // -- Bare URL (no label) --
          w.Text('Bare URL (no label)', style: theme.titleMedium),
          w.HyperlinkText(
            url: 'https://example.com/some/long/path?query=value',
          ),
          w.Divider(width: 60),

          // -- Custom colors --
          w.Text('Custom Link Colors', style: theme.titleMedium),
          w.HyperlinkText(
            url: 'https://dart.dev',
            label: 'Primary colored link',
            linkColor: theme.primary,
          ),
          w.HyperlinkText(
            url: 'https://dart.dev',
            label: 'Success colored link',
            linkColor: theme.success,
          ),
          w.HyperlinkText(
            url: 'https://dart.dev',
            label: 'Warning colored link',
            linkColor: theme.warning,
          ),
          w.HyperlinkText(
            url: 'https://dart.dev',
            label: 'Error colored link',
            linkColor: theme.error,
          ),
          w.Divider(width: 60),

          // -- Links in a layout --
          w.Text('Links in Context', style: theme.titleMedium),
          w.Frame(
            border: Border.rounded,
            borderColor: theme.border,
            padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: w.Column(
              gap: 0,
              children: [
                w.Row(
                  gap: 1,
                  children: [
                    w.Text('Docs:', style: label),
                    w.HyperlinkText(
                      url: 'https://api.dart.dev',
                      label: 'API Reference',
                    ),
                  ],
                ),
                w.Row(
                  gap: 1,
                  children: [
                    w.Text('Repo:', style: label),
                    w.HyperlinkText(
                      url: 'https://github.com/dart-lang/sdk',
                      label: 'dart-lang/sdk',
                    ),
                  ],
                ),
                w.Row(
                  gap: 1,
                  children: [
                    w.Text('Chat:', style: label),
                    w.HyperlinkText(
                      url: 'https://discord.gg/dart',
                      label: 'Discord',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
