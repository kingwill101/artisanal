import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal/widgets.dart' as w;
import 'package:artisanal/tui.dart'
    show BackgroundColorMsg, KeyMsg, View, WindowSizeMsg;
import 'package:artisanal/terminal.dart' show Key, KeyType;
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

  test('ArtisanalApp themeMode.light forces the light theme', () {
    final initialDarkBackground = w.hasDarkBackground;
    addTearDown(() => w.setHasDarkBackground(initialDarkBackground));

    w.setHasDarkBackground(true);
    final lightTheme = w.Theme.light();
    final darkTheme = w.Theme.dark();
    final app = w.ArtisanalApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: w.ThemeMode.light,
      child: _ThemeProbe(expectedBackground: lightTheme.background),
    );

    app.update(const WindowSizeMsg(30, 8));
    final view = app.view() as View;

    expect(view.backgroundColor, equals(lightTheme.background));
    expect(Layout.stripAnsi(view.content), contains('theme ok'));
  });

  test('ArtisanalApp themeMode.dark forces the dark theme', () {
    final initialDarkBackground = w.hasDarkBackground;
    addTearDown(() => w.setHasDarkBackground(initialDarkBackground));

    w.setHasDarkBackground(false);
    final lightTheme = w.Theme.light();
    final darkTheme = w.Theme.dark();
    final app = w.ArtisanalApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: w.ThemeMode.dark,
      child: _ThemeProbe(expectedBackground: darkTheme.background),
    );

    app.update(const WindowSizeMsg(30, 8));
    final view = app.view() as View;

    expect(view.backgroundColor, equals(darkTheme.background));
    expect(Layout.stripAnsi(view.content), contains('theme ok'));
  });

  test(
    'ArtisanalApp themeMode.system switches between light and dark themes',
    () {
      final initialDarkBackground = w.hasDarkBackground;
      addTearDown(() => w.setHasDarkBackground(initialDarkBackground));

      w.setHasDarkBackground(true);
      final lightTheme = w.Theme.light();
      final darkTheme = w.Theme.dark();
      final app = w.ArtisanalApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: w.ThemeMode.system,
        child: _ThemeModeProbe(
          lightBackground: lightTheme.background,
          darkBackground: darkTheme.background,
        ),
      );

      app.update(const WindowSizeMsg(30, 8));
      final initialView = app.view() as View;
      expect(initialView.backgroundColor, equals(darkTheme.background));
      expect(Layout.stripAnsi(initialView.content), contains('dark theme'));

      app.update(const BackgroundColorMsg(hex: '#ffffff'));
      final updatedView = app.view() as View;
      expect(updatedView.backgroundColor, equals(lightTheme.background));
      expect(Layout.stripAnsi(updatedView.content), contains('light theme'));
    },
  );

  test(
    'ArtisanalApp rebuilds immediately when terminal background changes',
    () {
      final initialDarkBackground = w.hasDarkBackground;
      addTearDown(() => w.setHasDarkBackground(initialDarkBackground));

      w.setHasDarkBackground(true);
      final app = w.ArtisanalApp(
        theme: w.Theme.adaptive(),
        home: _BackgroundModeProbe(),
      );

      app.update(const WindowSizeMsg(40, 12));
      final initialView = app.view() as View;
      expect(
        Layout.stripAnsi(initialView.content),
        contains('dark background'),
      );

      app.update(const BackgroundColorMsg(hex: '#ffffff'));
      final updatedView = app.view() as View;
      expect(
        Layout.stripAnsi(updatedView.content),
        contains('light background'),
      );
    },
  );

  test('ArtisanalApp hosts a toggleable debug console pane', () {
    final controller = w.DebugConsoleController(initiallyVisible: false);
    controller.info('boot ok');

    final app = w.ArtisanalApp(
      debugConsoleController: controller,
      home: w.Text('Home screen'),
    );

    app.update(const WindowSizeMsg(60, 16));
    final initial = app.view() as View;
    expect(Layout.stripAnsi(initial.content), isNot(contains('Debug Console')));

    app.update(KeyMsg(const Key(KeyType.f10)));
    final shown = app.view() as View;
    expect(Layout.stripAnsi(shown.content), contains('Debug Console'));
    expect(Layout.stripAnsi(shown.content), contains('boot ok'));

    app.update(KeyMsg(const Key(KeyType.runes, runes: <int>[0x0c])));
    final cleared = app.view() as View;
    expect(
      Layout.stripAnsi(cleared.content),
      contains('No console entries yet.'),
    );

    app.update(KeyMsg(const Key(KeyType.f10)));
    final hidden = app.view() as View;
    expect(Layout.stripAnsi(hidden.content), isNot(contains('Debug Console')));
  });
}

final class _ThemeProbe extends w.StatelessWidget {
  _ThemeProbe({required this.expectedBackground});

  final Object expectedBackground;

  @override
  w.Widget build(w.BuildContext context) {
    final scoped = w.ThemeScope.of(context);
    final result = scoped.background == expectedBackground
        ? 'theme ok'
        : 'theme mismatch';
    return w.Text(result);
  }
}

final class _BackgroundModeProbe extends w.StatelessWidget {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(w.hasDarkBackground ? 'dark background' : 'light background');
  }
}

final class _ThemeModeProbe extends w.StatelessWidget {
  _ThemeModeProbe({
    required this.lightBackground,
    required this.darkBackground,
  });

  final Object lightBackground;
  final Object darkBackground;

  @override
  w.Widget build(w.BuildContext context) {
    final background = w.ThemeScope.of(context).background;
    final label = switch (background) {
      final value when value == lightBackground => 'light theme',
      final value when value == darkBackground => 'dark theme',
      _ => 'unknown theme',
    };
    return w.Text(label);
  }
}
