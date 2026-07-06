// Navigator Example
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates the Navigator widget for stack-based page navigation.
// Features push, pop, named routes, push result handling, and popUntil.
//
// Controls:
//   Enter  = push the selected page
//   Escape = pop (go back)
//   q      = quit
//
// Run with: dart run example/navigator/main.dart

import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(NavigatorDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

// ---------------------------------------------------------------------------
// Root widget — wraps everything in a Navigator
// ---------------------------------------------------------------------------

class NavigatorDemo extends w.StatelessWidget {
  NavigatorDemo({super.key});

  @override
  w.Widget build(w.BuildContext context) {
    return w.Navigator(
      home: _HomePage(),
      popBehavior: w.PopBehavior.defaultBehavior,
    );
  }
}

// ---------------------------------------------------------------------------
// Home Page — menu of navigation demos
// ---------------------------------------------------------------------------

class _HomePage extends w.StatefulWidget {
  @override
  w.State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends w.State<_HomePage> {
  int _selected = 0;
  String _lastResult = '';

  static const _items = [
    'Push a detail page',
    'Push and await result',
    'Push 3 levels, then popUntil home',
    'Named routes demo',
  ];

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();

      if (msg.key.type == KeyType.down) {
        setState(() => _selected = (_selected + 1) % _items.length);
        return tui.Cmd.none();
      }
      if (msg.key.type == KeyType.up) {
        setState(
          () => _selected = (_selected - 1 + _items.length) % _items.length,
        );
        return tui.Cmd.none();
      }
      if (msg.key.type == KeyType.enter) {
        _activate();
        return tui.Cmd.none();
      }
    }
    return null;
  }

  void _activate() {
    final nav = w.Navigator.of(context);
    switch (_selected) {
      case 0:
        nav.pushWidget(_DetailPage(title: 'Detail Page'));
        break;
      case 1:
        nav.pushWidget<String>(_ResultPage()).then((value) {
          setState(() {
            _lastResult = value ?? '(null)';
          });
        });
        break;
      case 2:
        nav.pushWidget(_LevelPage(level: 1));
        break;
      case 3:
        nav.push(
          w.PageRoute(
            builder: (_) => _NamedRoutesHome(),
            settings: const w.RouteSettings(name: '/named'),
          ),
        );
        break;
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    final menuItems = <w.Widget>[];
    for (var i = 0; i < _items.length; i++) {
      final prefix = i == _selected ? '> ' : '  ';
      final style = i == _selected
          ? (theme.titleSmall.copy()..foreground(theme.primary))
          : label;
      menuItems.add(w.Text('$prefix${_items[i]}', style: style));
    }

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('Navigator Demo', style: theme.titleLarge),
          w.Text(
            'Up/Down = select | Enter = go | Escape = back | q = quit',
            style: label,
          ),
          w.Divider(width: 55),
          ...menuItems,
          if (_lastResult.isNotEmpty) ...[
            w.Divider(width: 55),
            w.Text('Last result: $_lastResult', style: label),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Page — simple page that shows a title
// ---------------------------------------------------------------------------

class _DetailPage extends w.StatelessWidget {
  _DetailPage({required this.title});
  final String title;

  @override
  w.Widget build(w.BuildContext context) {
    final t = theme;
    final label = t.labelSmall.copy()..foreground(t.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: t.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text(title, style: t.titleLarge),
          w.Text('Press Escape to go back.', style: label),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result Page — pops with a result string
// ---------------------------------------------------------------------------

class _ResultPage extends w.StatefulWidget {
  @override
  w.State<_ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends w.State<_ResultPage> {
  int _counter = 0;

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == '+') {
        setState(() => _counter++);
        return tui.Cmd.none();
      }
      if (msg.key.char == '-') {
        setState(() => _counter--);
        return tui.Cmd.none();
      }
      if (msg.key.type == KeyType.enter) {
        w.Navigator.of(context).pop('counter=$_counter');
        return tui.Cmd.none();
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('Result Page', style: theme.titleLarge),
          w.Text('Counter: $_counter', style: theme.titleMedium),
          w.Text(
            '+/- to change | Enter to pop with result | Escape to cancel',
            style: label,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level Page — pushes deeper levels; 'u' pops back to home
// ---------------------------------------------------------------------------

class _LevelPage extends w.StatefulWidget {
  _LevelPage({required this.level});
  final int level;

  @override
  w.State<_LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends w.State<_LevelPage> {
  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'p' && widget.level < 3) {
        w.Navigator.of(context).pushWidget(_LevelPage(level: widget.level + 1));
        return tui.Cmd.none();
      }
      if (msg.key.char == 'u') {
        final nav = w.Navigator.of(context);
        nav.popUntil((route) => nav.routes.first == route);
        return tui.Cmd.none();
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final depth = '>' * widget.level;

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('$depth Level ${widget.level}', style: theme.titleLarge),
          if (widget.level < 3) w.Text('p = push next level', style: label),
          w.Text('u = popUntil home | Escape = back one level', style: label),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Named Routes Demo
// ---------------------------------------------------------------------------

class _NamedRoutesHome extends w.StatefulWidget {
  @override
  w.State<_NamedRoutesHome> createState() => _NamedRoutesHomeState();
}

class _NamedRoutesHomeState extends w.State<_NamedRoutesHome> {
  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == '1') {
        w.Navigator.of(
          context,
        ).pushWidget(_DetailPage(title: 'Settings'), name: '/settings');
        return tui.Cmd.none();
      }
      if (msg.key.char == '2') {
        w.Navigator.of(
          context,
        ).pushWidget(_DetailPage(title: 'Profile'), name: '/profile');
        return tui.Cmd.none();
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('Named Routes', style: theme.titleLarge),
          w.Text('1 = /settings | 2 = /profile | Escape = back', style: label),
        ],
      ),
    );
  }
}
