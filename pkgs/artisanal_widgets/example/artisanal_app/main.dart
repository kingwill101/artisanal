// ArtisanalApp Example
//
// Demonstrates the high-level app shell with title publishing, adaptive
// theming, and built-in navigator wiring.

import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = w.ArtisanalApp(
    title: 'ArtisanalApp Demo',
    theme: w.Theme.adaptive(),
    home: _HomeScreen(),
  );

  await w.runArtisanalApp(app);
}

final class _HomeScreen extends w.StatefulWidget {
  @override
  w.State<_HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends w.State<_HomeScreen> {
  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    if (msg.key.char == 'q') return tui.Cmd.quit();
    if (msg.key.type == KeyType.enter) {
      w.Navigator.of(context).pushWidget(_DetailsScreen());
      return tui.Cmd.none();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('ArtisanalApp Shell', style: theme.titleLarge),
          w.Text(
            'Enter = push route | Escape = pop | q = quit',
            style: label,
          ),
          w.Divider(width: 60),
          w.Text(
            'Theme mode: ${w.hasDarkBackground ? "dark background" : "light background"}',
            style: theme.bodyMedium,
          ),
          w.Text(
            'The window title and terminal background are managed by the shell.',
            style: label,
          ),
        ],
      ),
    );
  }
}

final class _DetailsScreen extends w.StatelessWidget {
  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('Details', style: theme.titleLarge),
          w.Text('Press Escape to go back.', style: label),
        ],
      ),
    );
  }
}
