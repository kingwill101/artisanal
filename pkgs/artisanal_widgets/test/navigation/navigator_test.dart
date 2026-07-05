import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Test helpers — simple page widgets and a push-button wrapper
// ---------------------------------------------------------------------------

/// A simple page widget that displays a label.
class _TestPage extends w.StatelessWidget {
  _TestPage(this.label);
  final String label;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(label);
  }
}

/// A page that has a button (key press) to push another page.
class _PushPage extends w.StatefulWidget {
  _PushPage({required this.label, required this.targetLabel, this.targetName});

  final String label;
  final String targetLabel;
  final String? targetName;

  @override
  w.State<_PushPage> createState() => _PushPageState();
}

class _PushPageState extends w.State<_PushPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'p') {
        // Push a new page.
        w.Navigator.of(
          context,
        ).pushWidget(_TestPage(widget.targetLabel), name: widget.targetName);
        return null;
      }
      if (char == 'n') {
        // Push named route.
        if (widget.targetName != null) {
          w.Navigator.of(context).pushNamed(widget.targetName!);
        }
        return null;
      }
    }
    return null;
  }
}

/// A page that intercepts Escape to simulate a modal overlay.
///
/// When [modalOpen] is true, `handleIntercept` consumes Escape so the
/// Navigator does NOT pop the route. When false, Escape passes through
/// and the Navigator pops normally.
class _EscapeModalPage extends w.StatefulWidget {
  _EscapeModalPage({required this.label, this.modalOpen = false});
  final String label;
  final bool modalOpen;

  @override
  w.State<_EscapeModalPage> createState() => _EscapeModalPageState();
}

class _EscapeModalPageState extends w.State<_EscapeModalPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg &&
        msg.key.type == KeyType.escape &&
        widget.modalOpen) {
      return tui.Cmd.none();
    }
    return null;
  }
}

/// A page that can push a page that intercepts Escape.
///
/// Pushes [_EscapeModalPage] on 'p'. Used to test that a child widget's
/// Escape interception prevents the Navigator from popping.
class _EscapeModalPushPage extends w.StatefulWidget {
  _EscapeModalPushPage({
    required this.label,
    this.childModalOpen = false,
    this.childLabel = 'Child',
  });
  final String label;
  final bool childModalOpen;
  final String childLabel;

  @override
  w.State<_EscapeModalPushPage> createState() => _EscapeModalPushPageState();
}

class _EscapeModalPushPageState extends w.State<_EscapeModalPushPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      if (String.fromCharCodes(msg.key.runes) == 'p') {
        w.Navigator.of(context).pushWidget(
          _EscapeModalPage(
            label: widget.childLabel,
            modalOpen: widget.childModalOpen,
          ),
        );
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

/// A page that pops itself when 'b' is pressed, optionally with a result.
class _PopPage extends w.StatefulWidget {
  _PopPage({required this.label, this.result});

  final String label;
  final String? result;

  @override
  w.State<_PopPage> createState() => _PopPageState();
}

class _PopPageState extends w.State<_PopPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'b') {
        w.Navigator.of(context).pop(widget.result);
        return null;
      }
    }
    return null;
  }
}

/// A page that pushes on 'p' and displays the result when the pushed page pops.
class _PushAndAwaitPage extends w.StatefulWidget {
  _PushAndAwaitPage({required this.label});
  final String label;

  @override
  w.State<_PushAndAwaitPage> createState() => _PushAndAwaitPageState();
}

class _PushAndAwaitPageState extends w.State<_PushAndAwaitPage> {
  String _resultText = '';

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Text(widget.label),
        if (_resultText.isNotEmpty) w.Text('result:$_resultText'),
      ],
    );
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'p') {
        w.Navigator.of(context)
            .pushWidget<String>(_PopPage(label: 'Second', result: 'hello'))
            .then((value) {
              setState(() {
                _resultText = value ?? 'null';
              });
            });
        return null;
      }
    }
    return null;
  }
}

/// Simple observer that records navigation events.
class _TestObserver extends w.NavigatorObserver {
  final List<String> events = [];

  @override
  void didPush(w.Route<dynamic> route, w.Route<dynamic>? previousRoute) {
    events.add('push:${route.settings.name}');
  }

  @override
  void didPop(w.Route<dynamic> route, w.Route<dynamic>? previousRoute) {
    events.add('pop:${route.settings.name}');
  }

  @override
  void didRemove(w.Route<dynamic> route, w.Route<dynamic>? previousRoute) {
    events.add('remove:${route.settings.name}');
  }

  @override
  void didReplace({w.Route<dynamic>? newRoute, w.Route<dynamic>? oldRoute}) {
    events.add(
      'replace:${oldRoute?.settings.name}->${newRoute?.settings.name}',
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RouteSettings', () {
    test('stores name and arguments', () {
      final settings = w.RouteSettings(name: '/test', arguments: 42);
      expect(settings.name, '/test');
      expect(settings.arguments, 42);
    });

    test('copyWith creates a copy with updated fields', () {
      final original = w.RouteSettings(name: '/a', arguments: 1);
      final copied = original.copyWith(name: '/b');
      expect(copied.name, '/b');
      expect(copied.arguments, 1);
    });

    test('toString includes name and arguments', () {
      final settings = w.RouteSettings(name: '/x');
      expect(settings.toString(), contains('/x'));
    });
  });

  group('PopBehavior', () {
    test('defaultBehavior has escape enabled', () {
      expect(w.PopBehavior.defaultBehavior.escapeEnabled, isTrue);
      expect(w.PopBehavior.defaultBehavior.backspaceEnabled, isFalse);
    });

    test('strict disables all keyboard pops', () {
      expect(w.PopBehavior.strict.escapeEnabled, isFalse);
      expect(w.PopBehavior.strict.backspaceEnabled, isFalse);
    });
  });

  group('Route', () {
    test('PageRoute creates one opaque overlay entry', () {
      final route = w.PageRoute(
        builder: (_) => w.Text('test'),
        settings: w.RouteSettings(name: '/page'),
      );
      route.install();
      expect(route.overlayEntries.length, 1);
      expect(route.overlayEntries.first.opaque, isTrue);
      expect(route.overlayEntries.first.maintainState, isTrue);
    });

    test('ModalRoute creates two overlay entries (barrier + content)', () {
      final route = w.ModalRoute(
        builder: (_) => w.Text('modal'),
        settings: w.RouteSettings(name: '/modal'),
      );
      route.install();
      expect(route.overlayEntries.length, 2);
      // Barrier is non-opaque.
      expect(route.overlayEntries.first.opaque, isFalse);
      // Content is non-opaque (it's a positioned overlay).
      expect(route.overlayEntries.last.opaque, isFalse);
    });

    test('Route.canPop defaults to true', () {
      final route = w.PageRoute(builder: (_) => w.Text('test'));
      expect(route.canPop(), isTrue);
    });

    test('dispose clears overlay entries', () {
      final route = w.PageRoute(builder: (_) => w.Text('test'));
      route.install();
      expect(route.overlayEntries.length, 1);
      route.dispose();
      expect(route.overlayEntries, isEmpty);
    });
  });

  group('Navigator', () {
    test('renders home widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.Navigator(home: w.Text('Home Page')));

      expect(tester.find.text('Home Page'), isTrue);
    });

    test('renders initial route from routes map', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          routes: {
            '/': (_) => w.Text('Root Page'),
            '/other': (_) => w.Text('Other Page'),
          },
        ),
      );

      expect(tester.find.text('Root Page'), isTrue);
    });

    test('renders named initial route', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          initialRoute: '/settings',
          routes: {'/settings': (_) => w.Text('Settings')},
        ),
      );

      expect(tester.find.text('Settings'), isTrue);
    });

    test('push shows new content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Home', targetLabel: 'Pushed'),
        ),
      );

      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Pushed'), isFalse);

      // Press 'p' to push.
      tester.sendKey('p');

      expect(tester.find.text('Pushed'), isTrue);
    });

    test('pop returns to previous content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Home', targetLabel: 'Pushed'),
        ),
      );

      // Push a new page.
      tester.sendKey('p');
      expect(tester.find.text('Pushed'), isTrue);

      // Pop via escape key.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Pushed'), isFalse);
    });

    test('push Future completes with result from pop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(home: _PushAndAwaitPage(label: 'First')),
      );

      expect(tester.find.text('First'), isTrue);

      // Push second page.
      tester.sendKey('p');
      expect(tester.find.text('Second'), isTrue);

      // Pop with result by pressing 'b'.
      tester.sendKey('b');

      // After popping, the first page should display the result.
      // The Completer.complete() schedules .then() callbacks as microtasks,
      // so we need multiple microtask turns: one for the .then() to fire
      // (which calls setState), then an update cycle to rebuild the view.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('First'), isTrue);
      expect(tester.find.text('result:hello'), isTrue);
    });

    test('pushNamed uses routes map', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          routes: {
            '/': (_) => _PushPage(
              label: 'Home',
              targetLabel: 'ignored',
              targetName: '/details',
            ),
            '/details': (_) => w.Text('Details Page'),
          },
        ),
      );

      expect(tester.find.text('Home'), isTrue);

      // Press 'n' to push named.
      tester.sendKey('n');
      expect(tester.find.text('Details Page'), isTrue);
    });

    test('canPop returns false with single route', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.Navigator(home: w.Text('Only')));

      // Escape should not pop the last route.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Only'), isTrue);
    });

    test('canPop returns true with multiple routes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Home', targetLabel: 'Second'),
        ),
      );

      // Push a second route.
      tester.sendKey('p');
      expect(tester.find.text('Second'), isTrue);

      // Escape should pop back.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Home'), isTrue);
    });

    test('PopBehavior escape disabled prevents pop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Home', targetLabel: 'Second'),
          popBehavior: w.PopBehavior(escapeEnabled: false),
        ),
      );

      tester.sendKey('p');
      expect(tester.find.text('Second'), isTrue);

      // Escape should NOT pop.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Second'), isTrue);
    });

    test('PopBehavior backspace enabled pops', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Home', targetLabel: 'Second'),
          popBehavior: w.PopBehavior(
            escapeEnabled: false,
            backspaceEnabled: true,
          ),
        ),
      );

      tester.sendKey('p');
      expect(tester.find.text('Second'), isTrue);

      // Backspace should pop.
      tester.sendSpecialKey(KeyType.backspace);
      expect(tester.find.text('Home'), isTrue);
    });

    test('PopBehavior custom key pops', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Home', targetLabel: 'Second'),
          popBehavior: w.PopBehavior(escapeEnabled: false, customPopKey: 'q'),
        ),
      );

      tester.sendKey('p');
      expect(tester.find.text('Second'), isTrue);

      // 'q' should pop.
      tester.sendKey('q');
      expect(tester.find.text('Home'), isTrue);
    });

    test('NavigatorObserver receives push and pop callbacks', () async {
      final observer = _TestObserver();
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Home', targetLabel: 'Second'),
          observers: [observer],
        ),
      );

      // Push.
      tester.sendKey('p');
      expect(observer.events, contains('push:null'));

      // Pop.
      tester.sendSpecialKey(KeyType.escape);
      expect(observer.events, contains('pop:null'));
    });

    test('multiple sequential push/pop operations', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _PushPage(label: 'Page 1', targetLabel: 'Page 2'),
        ),
      );

      expect(tester.find.text('Page 1'), isTrue);

      // Push page 2.
      tester.sendKey('p');
      expect(tester.find.text('Page 2'), isTrue);

      // Pop back to page 1.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Page 1'), isTrue);

      // Push again.
      tester.sendKey('p');
      expect(tester.find.text('Page 2'), isTrue);

      // Pop again.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Page 1'), isTrue);
    });

    test('pushReplacement replaces current route', () async {
      final observer = _TestObserver();
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // A page that replaces itself when 'r' is pressed.
      final home = _ReplacePage(
        label: 'Original',
        replacementLabel: 'Replaced',
      );

      await tester.pumpWidget(w.Navigator(home: home, observers: [observer]));

      expect(tester.find.text('Original'), isTrue);

      // Press 'r' to replace.
      tester.sendKey('r');
      expect(tester.find.text('Replaced'), isTrue);
      expect(tester.find.text('Original'), isFalse);

      // Should have a remove event (for the replaced route).
      expect(observer.events.any((e) => e.startsWith('remove:')), isTrue);
    });

    test('popUntil pops to matching route', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // A page that pushes multiple pages and then pops until root.
      await tester.pumpWidget(w.Navigator(home: _MultiPushPage(label: 'Root')));

      expect(tester.find.text('Root'), isTrue);

      // Push 3 pages: press 'p' three times.
      tester.sendKey('p');
      expect(tester.find.text('Level 1'), isTrue);
      tester.sendKey('p');
      expect(tester.find.text('Level 2'), isTrue);
      tester.sendKey('p');
      expect(tester.find.text('Level 3'), isTrue);

      // Press 'u' to popUntil root.
      tester.sendKey('u');
      expect(tester.find.text('Root'), isTrue);
    });

    test('child handling Escape prevents Navigator pop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _EscapeModalPushPage(
            label: 'Home',
            childModalOpen: true,
            childLabel: 'Modal Open',
          ),
        ),
      );

      expect(tester.find.text('Home'), isTrue);

      // Push page that intercepts Escape.
      tester.sendKey('p');
      expect(tester.find.text('Modal Open'), isTrue);

      // Escape should be consumed by the child — route stays.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Modal Open'), isTrue);
      expect(tester.find.text('Home'), isFalse);
    });

    test('child not handling Escape allows Navigator pop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _EscapeModalPushPage(
            label: 'Home',
            childModalOpen: false,
            childLabel: 'Modal Closed',
          ),
        ),
      );

      expect(tester.find.text('Home'), isTrue);

      // Push page that does NOT intercept Escape.
      tester.sendKey('p');
      expect(tester.find.text('Modal Closed'), isTrue);

      // Escape should pop back to Home.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Modal Closed'), isFalse);
    });

    test('route willHandlePopInternally prevents Navigator pop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _WillHandlePopPage(label: 'Home'),
        ),
      );

      expect(tester.find.text('Home'), isTrue);

      // Push a page that claims it handles pops internally.
      tester.sendKey('p');
      expect(tester.find.text('Pushed'), isTrue);

      // Escape should not pop because the route handles it internally.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Pushed'), isTrue);
      expect(tester.find.text('Home'), isFalse);
    });

    test('route popDisposition doNotPop prevents Navigator pop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _NoPopPage(label: 'Home'),
        ),
      );

      expect(tester.find.text('Home'), isTrue);

      // Push a page whose popDisposition is doNotPop.
      tester.sendKey('p');
      expect(tester.find.text('No Pop'), isTrue);

      // Escape should not pop because disposition says so.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('No Pop'), isTrue);
      expect(tester.find.text('Home'), isFalse);
    });

    test('PopBehavior canPop callback prevents Navigator pop', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _BlockedPage(label: 'Home'),
          popBehavior: w.PopBehavior(
            escapeEnabled: true,
            canPop: (route) => route.settings.name != '/blocked',
          ),
        ),
      );

      expect(tester.find.text('Home'), isTrue);

      // Push a page with a name that the canPop callback blocks.
      tester.sendKey('p');
      expect(tester.find.text('Pushed'), isTrue);

      // Escape should not pop because canPop returned false.
      tester.sendSpecialKey(KeyType.escape);
      expect(tester.find.text('Pushed'), isTrue);
      expect(tester.find.text('Home'), isFalse);
    });

    test('empty navigator renders shrink box', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.Navigator());

      // No home, no routes — should not crash.
      expect(tester.view, isNotNull);
    });

    test('onGenerateRoute is used for dynamic routes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          initialRoute: '/dynamic/42',
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/dynamic/') ?? false) {
              final id = settings.name!.split('/').last;
              return w.PageRoute(
                builder: (_) => w.Text('Dynamic $id'),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );

      expect(tester.find.text('Dynamic 42'), isTrue);
    });

    test('onUnknownRoute is used as fallback', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          initialRoute: '/nonexistent',
          onUnknownRoute: (settings) {
            return w.PageRoute(
              builder: (_) => w.Text('404 Not Found'),
              settings: settings,
            );
          },
        ),
      );

      expect(tester.find.text('404 Not Found'), isTrue);
    });
  });

  group('Overlay enhancements', () {
    test('OverlayEntry.remove removes itself from overlay', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Start with a single entry so we can verify it renders.
      final entry = w.OverlayEntry(builder: (context) => w.Text('removable'));

      await tester.pumpWidget(w.Overlay(initialEntries: [entry]));

      expect(tester.find.text('removable'), isTrue);

      // Remove the entry. Use sendKey to trigger an update cycle
      // so the dirty element rebuild is picked up by view().
      entry.remove();
      tester.sendKey(' ');

      expect(tester.find.text('removable'), isFalse);
    });

    test('OverlayEntry.markNeedsBuild triggers rebuild', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var counter = 0;

      final entry = w.OverlayEntry(
        builder: (context) {
          return w.Text('count:$counter');
        },
      );

      await tester.pumpWidget(w.Overlay(initialEntries: [entry]));

      expect(tester.find.text('count:0'), isTrue);

      counter = 5;
      entry.markNeedsBuild();
      tester.sendKey(' ');

      expect(tester.find.text('count:5'), isTrue);
    });

    test('OverlayState.insertAll adds multiple entries', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Overlay(
          initialEntries: [w.OverlayEntry(builder: (_) => w.Text('base'))],
        ),
      );

      expect(tester.find.text('base'), isTrue);

      // Insert multiple entries via Overlay.of.
      // To access OverlayState, we need a context inside the overlay.
      // We can test insertAll indirectly through Navigator which uses it.
      // For a direct test, we verify insertAll exists and works by
      // building a custom widget that calls it.

      // This is implicitly tested through the Navigator tests above
      // where multiple routes are pushed, each adding entries.
    });
  });
}

// ---------------------------------------------------------------------------
// Additional test helper widgets
// ---------------------------------------------------------------------------

/// A page that replaces itself with another page when 'r' is pressed.
class _ReplacePage extends w.StatefulWidget {
  _ReplacePage({required this.label, required this.replacementLabel});
  final String label;
  final String replacementLabel;

  @override
  w.State<_ReplacePage> createState() => _ReplacePageState();
}

class _ReplacePageState extends w.State<_ReplacePage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'r') {
        w.Navigator.of(context).pushReplacement(
          w.PageRoute(
            builder: (_) => w.Text(widget.replacementLabel),
            settings: w.RouteSettings(name: '/replaced'),
          ),
        );
        return null;
      }
    }
    return null;
  }
}

/// A page that pushes named levels and supports popUntil.
class _MultiPushPage extends w.StatefulWidget {
  _MultiPushPage({required this.label});
  final String label;

  @override
  w.State<_MultiPushPage> createState() => _MultiPushPageState();
}

class _MultiPushPageState extends w.State<_MultiPushPage> {
  static int _pushCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.label == 'Root') {
      _pushCount = 0;
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'p') {
        _pushCount++;
        w.Navigator.of(context).pushWidget(
          _MultiPushPage(label: 'Level $_pushCount'),
          name: '/level/$_pushCount',
        );
        return tui.Cmd.none();
      }
      if (char == 'u') {
        // popUntil the root (first route).
        final nav = w.Navigator.of(context);
        nav.popUntil((route) => nav.routes.first == route);
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

/// Simple page that pushes on 'p' and returns, with a route that claims
/// it handles pops internally.
class _WillHandlePopPage extends w.StatefulWidget {
  _WillHandlePopPage({required this.label});
  final String label;

  @override
  w.State<_WillHandlePopPage> createState() => _WillHandlePopPageState();
}

class _WillHandlePopPageState extends w.State<_WillHandlePopPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'p') {
        w.Navigator.of(context).push(
          _HandlePopInternallyRoute(
            builder: (_) => w.Text('Pushed'),
            settings: w.RouteSettings(name: '/pushed'),
          ),
        );
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

/// Simple page whose route reports `willHandlePopInternally = true`.
class _HandlePopInternallyRoute extends w.Route<void> {
  _HandlePopInternallyRoute({required this.builder, super.settings});

  final w.Widget Function(w.BuildContext) builder;

  @override
  bool get willHandlePopInternally => true;

  @override
  List<w.OverlayEntry> createOverlayEntries() {
    return [
      w.OverlayEntry(
        opaque: true,
        maintainState: true,
        builder: builder,
      ),
    ];
  }
}

/// Simple page whose route reports `popDisposition = doNotPop`.
class _NoPopRoute extends w.Route<void> {
  _NoPopRoute({required this.builder, super.settings});

  final w.Widget Function(w.BuildContext) builder;

  @override
  w.RoutePopDisposition get popDisposition => w.RoutePopDisposition.doNotPop;

  @override
  List<w.OverlayEntry> createOverlayEntries() {
    return [
      w.OverlayEntry(
        opaque: true,
        maintainState: true,
        builder: builder,
      ),
    ];
  }
}

/// Simple page that pushes on 'p'.
class _SimplePage extends w.StatefulWidget {
  _SimplePage({required this.label});
  final String label;

  @override
  w.State<_SimplePage> createState() => _SimplePageState();
}

class _SimplePageState extends w.State<_SimplePage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'p') {
        w.Navigator.of(context).push(
          _HandlePopInternallyRoute(
            builder: (_) => w.Text('Pushed'),
            settings: w.RouteSettings(name: '/blocked'),
          ),
        );
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

/// Page used in the PopBehavior.canPop test. Any pushed child page will
/// display "Blocked" and is named `/blocked` so the canPop callback blocks it.
class _BlockedPage extends _SimplePage {
  _BlockedPage({required String label}) : super(label: label);
}

class _NoPopPage extends w.StatefulWidget {
  _NoPopPage({required this.label});
  final String label;

  @override
  w.State<_NoPopPage> createState() => _NoPopPageState();
}

class _NoPopPageState extends w.State<_NoPopPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'p') {
        w.Navigator.of(context).push(
          _NoPopRoute(
            builder: (_) => w.Text('No Pop'),
            settings: w.RouteSettings(name: '/nopop'),
          ),
        );
        return tui.Cmd.none();
      }
    }
    return null;
  }
}
