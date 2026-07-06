// HyperlinkText Showcase

import 'package:artisanal/style.dart' show Border;
import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';

void main() async {
  final app = WidgetApp(HyperlinkTextShowcase());
  await runProgram(
    app,
    options: const ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: MouseMode.allMotion,
    ),
  );
}

class HyperlinkTextShowcase extends StatefulWidget {
  HyperlinkTextShowcase({super.key});

  @override
  State createState() => _HyperlinkTextShowcaseState();
}

class _HyperlinkTextShowcaseState extends State<HyperlinkTextShowcase> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return Container(
      padding: const EdgeInsets.all(1),
      color: theme.background,
      child: Column(
        gap: 1,
        children: [
          Text('HyperlinkText Showcase', style: theme.titleLarge),
          Text(
            'Hover/click links if your terminal supports OSC 8.  q: quit',
            style: label,
          ),
          Divider(width: 60),

          // -- Labeled links --
          Text('Labeled Links', style: theme.titleMedium),
          HyperlinkText(
            url: 'https://dart.dev',
            label: 'Dart Programming Language',
          ),
          HyperlinkText(url: 'https://github.com', label: 'GitHub'),
          HyperlinkText(
            url: 'https://pub.dev',
            label: 'Dart Package Registry (pub.dev)',
          ),
          Divider(width: 60),

          // -- Bare URL (no label) --
          Text('Bare URL (no label)', style: theme.titleMedium),
          HyperlinkText(
            url: 'https://example.com/some/long/path?query=value',
          ),
          Divider(width: 60),

          // -- Custom colors --
          Text('Custom Link Colors', style: theme.titleMedium),
          HyperlinkText(
            url: 'https://dart.dev',
            label: 'Primary colored link',
            linkColor: theme.primary,
          ),
          HyperlinkText(
            url: 'https://dart.dev',
            label: 'Success colored link',
            linkColor: theme.success,
          ),
          HyperlinkText(
            url: 'https://dart.dev',
            label: 'Warning colored link',
            linkColor: theme.warning,
          ),
          HyperlinkText(
            url: 'https://dart.dev',
            label: 'Error colored link',
            linkColor: theme.error,
          ),
          Divider(width: 60),

          // -- Links in a layout --
          Text('Links in Context', style: theme.titleMedium),
          Frame(
            border: Border.rounded,
            borderColor: theme.border,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Column(
              gap: 0,
              children: [
                Row(
                  gap: 1,
                  children: [
                    Text('Docs:', style: label),
                    HyperlinkText(
                      url: 'https://api.dart.dev',
                      label: 'API Reference',
                    ),
                  ],
                ),
                Row(
                  gap: 1,
                  children: [
                    Text('Repo:', style: label),
                    HyperlinkText(
                      url: 'https://github.com/dart-lang/sdk',
                      label: 'dart-lang/sdk',
                    ),
                  ],
                ),
                Row(
                  gap: 1,
                  children: [
                    Text('Chat:', style: label),
                    HyperlinkText(
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
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg && msg.key.char == 'q') {
      return Cmd.quit();
    }
    return null;
  }
}
