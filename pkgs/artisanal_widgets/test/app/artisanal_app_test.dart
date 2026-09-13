import 'dart:async';

import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal/tui.dart' as runtime;
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

  test('WidgetApp catches exceptions raised while painting the tree', () {
    final app = w.WidgetApp(_PaintFailureWidget());
    app.update(const WindowSizeMsg(40, 12));

    final view = app.view();

    expect(Layout.stripAnsi(view.toString()), contains('Unhandled exception'));
    expect(Layout.stripAnsi(view.toString()), contains('paint failure'));
    expect(Layout.stripAnsi(view.toString()), contains('Copy'));
    expect(Layout.stripAnsi(view.toString()), contains('Dismiss'));
    // A successfully rendered error screen is a normal cached view. In
    // particular, this must not turn a later update into a stale fallback.
    expect(identical(view, app.view()), isTrue);

    // Dismiss is a real retry: this failing root is restored, and its new
    // exception must replace the old details rather than being discarded.
    app.update(KeyMsg(const Key(KeyType.escape)));
    final retried = Layout.stripAnsi(app.view().toString());
    expect(retried, contains('paint failure'));
    expect(retried, contains('Dismiss'));
  });

  test('WidgetApp dispose unmounts the root tree exactly once', () {
    _DisposeProbeState.disposeCount = 0;
    final app = w.WidgetApp(_DisposeProbe());

    app.view();
    app.dispose();
    app.dispose();

    expect(_DisposeProbeState.disposeCount, 1);
    expect(app.view(), '');
  });

  test('WidgetApp renders the error boundary through Program', () async {
    final terminal = runtime.StringTerminal();
    final program = runtime.Program(
      w.WidgetApp(_PaintFailureWidget()),
      terminal: terminal,
      options: const runtime.ProgramOptions(
        signalHandlers: false,
        startupProbes: false,
        frameTick: false,
      ),
    );
    final run = program.run();
    addTearDown(() async {
      program.send(const runtime.QuitMsg());
      await run;
    });

    await _waitUntil(
      () => Layout.stripAnsi(
        program.currentModel?.view().toString() ?? '',
      ).contains('Dismiss'),
    );
    final output = Layout.stripAnsi(program.currentModel!.view().toString());
    expect(output, contains('paint failure'));
    expect(output, contains('Copy'));
  });
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(predicate(), isTrue, reason: 'condition was not met');
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

final class _PaintFailureWidget extends w.LeafRenderObjectWidget {
  @override
  w.RenderObject createRenderObject() {
    return w.RenderDelegateBox(() => throw StateError('paint failure'));
  }

  @override
  Object view() => 'unused';
}

final class _DisposeProbe extends w.StatefulWidget {
  @override
  w.State<_DisposeProbe> createState() => _DisposeProbeState();
}

final class _DisposeProbeState extends w.State<_DisposeProbe> {
  static int disposeCount = 0;

  @override
  w.Widget build(w.BuildContext context) => w.Text('dispose probe');

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
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
