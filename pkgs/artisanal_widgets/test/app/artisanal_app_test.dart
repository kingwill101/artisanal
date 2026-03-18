import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal/tui.dart'
    show BackgroundColorMsg, View, WindowSizeMsg;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  test('ArtisanalApp publishes title and background color metadata', () {
    final theme = w.Theme.light();
    final app = w.ArtisanalApp(
      title: 'Docs',
      theme: theme,
      home: w.Text('Home screen'),
    );

    app.update(const WindowSizeMsg(40, 12));
    final view = app.view();

    expect(view, isA<View>());
    expect((view as View).windowTitle, 'Docs');
    expect(view.backgroundColor, equals(theme.background));
    expect(Layout.stripAnsi(view.content), contains('Home screen'));
  });

  test('ArtisanalApp scopes the provided theme for child trees', () {
    final theme = w.Theme.dark();
    final app = w.ArtisanalApp(
      theme: theme,
      child: _ThemeProbe(expectedBackground: theme.background),
    );

    app.update(const WindowSizeMsg(30, 8));
    final view = app.view() as View;

    expect(Layout.stripAnsi(view.content), contains('theme ok'));
  });

  test('ArtisanalApp rebuilds immediately when terminal background changes', () {
    final initialDarkBackground = w.hasDarkBackground;
    addTearDown(() => w.setHasDarkBackground(initialDarkBackground));

    w.setHasDarkBackground(true);
    final app = w.ArtisanalApp(
      theme: w.Theme.adaptive(),
      home: _BackgroundModeProbe(),
    );

    app.update(const WindowSizeMsg(40, 12));
    final initialView = app.view() as View;
    expect(Layout.stripAnsi(initialView.content), contains('dark background'));

    app.update(const BackgroundColorMsg(hex: '#ffffff'));
    final updatedView = app.view() as View;
    expect(Layout.stripAnsi(updatedView.content), contains('light background'));
  });
}

final class _ThemeProbe extends w.StatelessWidget {
  _ThemeProbe({required this.expectedBackground});

  final Object expectedBackground;

  @override
  w.Widget build(w.BuildContext context) {
    final scoped = w.ThemeScope.of(context);
    final result = scoped.background == expectedBackground ? 'theme ok' : 'theme mismatch';
    return w.Text(result);
  }
}

final class _BackgroundModeProbe extends w.StatelessWidget {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(
      w.hasDarkBackground ? 'dark background' : 'light background',
    );
  }
}
