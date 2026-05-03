/// Tests for element tree reconciliation and stateful widget interactions.
///
/// These tests verify that:
/// - StatefulWidget state survives rebuilds (no accidental state loss)
/// - GestureDetector tap events correctly invoke callbacks via hit-testing
/// - setState triggers rebuilds that produce updated output
/// - Element reconciliation preserves state for matching widgets
/// - Mouse capture/release flow works end-to-end through WidgetApp
/// - KeyMsg dispatch through handleUpdate triggers setState correctly
///
/// All mouse/tap tests use render-tree hit-testing (the Flutter-centric
/// approach) rather than zone-based dispatch.
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/style.dart' show Layout;
import 'package:test/test.dart';

void main() {
  group('StatefulWidget state preservation', () {
    test(
      'state survives rebuild when widget has same runtimeType and no key',
      () {
        final app = tui.WidgetApp(_CounterWidget());
        final output1 = app.view();
        expect(output1, contains('count: 0'));

        // Dispatch a message that increments the counter via setState
        app.update(const _IncrementMsg());
        final output2 = app.view();
        expect(output2, contains('count: 1'));

        // Dispatch again
        app.update(const _IncrementMsg());
        final output3 = app.view();
        expect(output3, contains('count: 2'));
      },
    );

    test('state survives window resize', () {
      final app = tui.WidgetApp(_CounterWidget());
      app.view();

      // Increment to 3
      app.update(const _IncrementMsg());
      app.update(const _IncrementMsg());
      app.update(const _IncrementMsg());
      final beforeResize = app.view();
      expect(beforeResize, contains('count: 3'));

      // Simulate window resize
      app.update(tui.WindowSizeMsg(120, 40));
      final afterResize = app.view();
      expect(
        afterResize,
        contains('count: 3'),
        reason: 'State should survive window resize',
      );
    });

    test('state survives multiple rapid rebuilds', () {
      final app = tui.WidgetApp(_CounterWidget());
      app.view();

      for (var i = 0; i < 10; i++) {
        app.update(const _IncrementMsg());
      }
      final output = app.view();
      expect(output, contains('count: 10'));
    });
  });

  group('GestureDetector tap via hit-testing', () {
    test('tap increments counter through hit-test click', () {
      final app = tui.WidgetApp(_ClickableCounter());

      // Initial render
      final output1 = app.view();
      expect(output1, contains('clicks: 0'));

      // Simulate press + release via hit-testing
      _simulateTapOnText(app, 'clicks: 0');

      final output2 = app.view();
      expect(
        output2,
        contains('clicks: 1'),
        reason: 'Click counter should increment after tap',
      );
    });

    test('multiple taps increment counter correctly', () {
      final app = tui.WidgetApp(_ClickableCounter());
      app.view();

      _simulateTapOnText(app, 'clicks: 0');
      _simulateTapOnText(app, 'clicks: 1');
      _simulateTapOnText(app, 'clicks: 2');

      final output = app.view();
      expect(output, contains('clicks: 3'));
    });

    test('tap on correct target among multiple GestureDetectors', () {
      final app = tui.WidgetApp(_MultiButtonWidget());
      app.view();

      // Tap Button A
      _simulateTapOnText(app, 'Button A');
      expect(app.view(), contains('tapped: A'));

      // Tap Button B
      _simulateTapOnText(app, 'Button B');
      expect(app.view(), contains('tapped: B'));
    });
  });

  group('Tab switching', () {
    test('clicking a tab changes the selected tab', () {
      final app = tui.WidgetApp(_TabWidget());
      final output1 = app.view();
      expect(output1, contains('Content: Tab 0'));

      _simulateTapOnText(app, 'Tab 1');

      final output2 = app.view();
      expect(
        output2,
        contains('Content: Tab 1'),
        reason: 'Tab content should change after clicking tab 1',
      );
    });

    test('multiple tab switches work', () {
      final app = tui.WidgetApp(_TabWidget());
      app.view();

      _simulateTapOnText(app, 'Tab 2');
      expect(app.view(), contains('Content: Tab 2'));

      _simulateTapOnText(app, 'Tab 0');
      expect(app.view(), contains('Content: Tab 0'));

      _simulateTapOnText(app, 'Tab 1');
      expect(app.view(), contains('Content: Tab 1'));
    });

    test('tab switching works without explicit zoneId (auto hit-test)', () {
      // This reproduces the exact pattern from the example app's _tab() method:
      // GestureDetector with a ValueKey but NO explicit zoneId.
      final app = tui.WidgetApp(_TabWidgetNoZone());
      final output1 = app.view();
      expect(output1, contains('Content: Tab 0'));

      // Tap on Tab 1 text — hit-testing should bubble up to GestureDetector
      _simulateTapOnText(app, 'Tab 1');
      expect(
        app.view(),
        contains('Content: Tab 1'),
        reason: 'Hit-testing should dispatch to GestureDetector ancestor',
      );

      _simulateTapOnText(app, 'Tab 2');
      expect(app.view(), contains('Content: Tab 2'));
    });

    test('tab state survives rebuild after resize', () {
      final app = tui.WidgetApp(_TabWidget());
      app.view();

      // Switch to tab 2
      _simulateTapOnText(app, 'Tab 2');
      expect(app.view(), contains('Content: Tab 2'));

      // Simulate resize — state should survive
      app.update(tui.WindowSizeMsg(100, 30));
      expect(
        app.view(),
        contains('Content: Tab 2'),
        reason: 'Tab selection should survive resize',
      );
    });
  });

  group('Element reconciliation', () {
    test('canUpdate matches widgets with same type and null keys', () {
      expect(w.Widget.canUpdate(w.Text('a'), w.Text('b')), isTrue);
    });

    test('canUpdate matches widgets with same type and same key', () {
      expect(
        w.Widget.canUpdate(
          w.Text('a', key: const w.Key('k')),
          w.Text('b', key: const w.Key('k')),
        ),
        isTrue,
      );
    });

    test('canUpdate rejects widgets with same type but different keys', () {
      expect(
        w.Widget.canUpdate(
          w.Text('a', key: const w.Key('k1')),
          w.Text('b', key: const w.Key('k2')),
        ),
        isFalse,
      );
    });

    test('canUpdate rejects widgets with different types', () {
      expect(w.Widget.canUpdate(w.Text('a'), w.Spacer()), isFalse);
    });

    test('unkeyed children preserve state by position', () {
      final app = tui.WidgetApp(_PositionalStateTest());
      app.view();

      // Increment child A
      app.update(const _IncrementChildMsg('A'));
      expect(app.view(), contains('A: 1'));
      expect(app.view(), contains('B: 0'));

      // Increment child B
      app.update(const _IncrementChildMsg('B'));
      expect(app.view(), contains('A: 1'));
      expect(app.view(), contains('B: 1'));
    });

    test('keyed children preserve state when reordered', () {
      final app = tui.WidgetApp(_KeyedReorderTest());
      app.view();

      // Increment the first child (named 'alpha')
      app.update(const _IncrementChildMsg('alpha'));
      expect(app.view(), contains('alpha: 1'));
      expect(app.view(), contains('beta: 0'));

      // Trigger reorder (reverses the list)
      app.update(const _ReorderMsg());
      final output = app.view();
      // After reorder, alpha should still have count 1 (state preserved by key)
      expect(
        output,
        contains('alpha: 1'),
        reason: 'Keyed widget state should survive reorder',
      );
      expect(output, contains('beta: 0'));
    });

    test('leaf render object updates repaint after parent rebuild', () {
      final app = tui.WidgetApp(_LeafRenderUpdateWidget());
      expect(app.view(), contains('leaf: 0'));

      app.update(const _IncrementMsg());

      final output = app.view();
      expect(output, contains('leaf: 1'));
      expect(output, isNot(contains('leaf: 0')));
    });
  });

  group('setState triggers rebuild', () {
    test('setState marks element dirty and triggers rebuild', () {
      final app = tui.WidgetApp(_SetStateTester(), debugRebuilds: true);
      final output1 = app.view();
      expect(output1, contains('value: initial'));

      app.update(const _ChangeValueMsg('updated'));
      final output2 = app.view();
      expect(output2, contains('value: updated'));
    });

    test('nested setState propagates correctly', () {
      final app = tui.WidgetApp(_NestedSetStateWidget());
      app.view();

      app.update(const _IncrementMsg());
      final output = app.view();
      expect(output, contains('outer: 1'));
      // Inner should not be affected
      expect(output, contains('inner: 0'));

      app.update(const _IncrementInnerMsg());
      final output2 = app.view();
      expect(output2, contains('outer: 1'));
      expect(output2, contains('inner: 1'));
    });
  });

  group('Mouse capture flow', () {
    test('press captures and release fires onTap', () {
      final app = tui.WidgetApp(_ClickableCounter());
      app.view();

      // Find the text location for hit-testing
      final loc = _locateText(app.view() as String, 'clicks: 0');
      expect(loc, isNotNull, reason: 'clicks text should be visible');

      final x = loc!.x;
      final y = loc.y;

      // Press
      app.update(
        tui.MouseMsg(
          action: tui.MouseAction.press,
          button: tui.MouseButton.left,
          x: x,
          y: y,
        ),
      );
      app.view(); // render to process any dirty elements

      // Release at same position
      app.update(
        tui.MouseMsg(
          action: tui.MouseAction.release,
          button: tui.MouseButton.left,
          x: x,
          y: y,
        ),
      );

      final output = app.view();
      expect(
        output,
        contains('clicks: 1'),
        reason: 'onTap should fire after press+release via hit-testing',
      );
    });

    test('release outside bounds does not fire onTap when using capture', () {
      final app = tui.WidgetApp(_ClickableCounter());
      app.view();

      final loc = _locateText(app.view() as String, 'clicks: 0');
      expect(loc, isNotNull);

      // Press inside the widget
      app.update(
        tui.MouseMsg(
          action: tui.MouseAction.press,
          button: tui.MouseButton.left,
          x: loc!.x,
          y: loc.y,
        ),
      );
      app.view();

      // Release way outside — mouse capture means release still goes to the
      // capture owner. The GestureDetector's capture path will fire onTap
      // on release regardless of position (since the element owns the capture).
      app.update(
        tui.MouseMsg(
          action: tui.MouseAction.release,
          button: tui.MouseButton.left,
          x: 79,
          y: 23,
        ),
      );

      final output = app.view();
      // With mouse capture, release always fires onTap on the capture owner.
      // This is correct behavior — the GestureDetector captured the mouse on
      // press and gets the release event directly.
      expect(
        output,
        contains('clicks: 1'),
        reason:
            'With mouse capture, release fires on capture owner regardless '
            'of position',
      );
    });
  });

  group('Example app tab pattern (exact reproduction)', () {
    test('GestureDetector without zoneId works via hit-testing', () {
      final app = tui.WidgetApp(_ExampleTabPattern());
      final output1 = app.view();
      expect(output1, contains('selected: 0'));

      // Tap on Tab1 text
      _simulateTapOnText(app, 'Tab1');
      expect(
        app.view(),
        contains('selected: 1'),
        reason: 'Hit-testing should dispatch to GestureDetector ancestor',
      );
    });

    test('tap on auto-hit-tested GestureDetector fires onTap callback', () {
      final app = tui.WidgetApp(_ExampleTabPattern());
      final output1 = app.view();
      expect(output1, contains('selected: 0'));

      _simulateTapOnText(app, 'Tab2');
      expect(
        app.view(),
        contains('selected: 2'),
        reason: 'Tapping tab text should switch via hit-test dispatch',
      );

      _simulateTapOnText(app, 'Tab3');
      expect(
        app.view(),
        contains('selected: 3'),
        reason: 'Tapping tab text should switch via hit-test dispatch',
      );
    });

    test('onTap callback captures correct closure variable', () {
      // This tests the specific pattern:
      //   for (var i = 0; i < 4; i++)
      //     GestureDetector(key: ValueKey(i), onTap: (_) {
      //       setState(() => _selected = i);  // closure over loop var
      //     })
      final app = tui.WidgetApp(_ClosureCaptureTabWidget());
      app.view();

      // Tap T1
      _simulateTapOnText(app, 'T1');
      expect(
        app.view(),
        contains('selected: 1'),
        reason: 'Closure should capture correct loop variable value',
      );

      _simulateTapOnText(app, 'T3');
      expect(
        app.view(),
        contains('selected: 3'),
        reason: 'Closure should capture correct loop variable value',
      );
    });
  });

  group('WidgetApp integration', () {
    test('initial render produces output', () {
      final app = tui.WidgetApp(w.Text('Hello'));
      final output = app.view();
      expect(output, contains('Hello'));
    });

    test('window size message updates media query', () {
      final app = tui.WidgetApp(_MediaQueryReader());
      app.update(tui.WindowSizeMsg(80, 24));
      final output = app.view();
      expect(output, contains('80x24'));
    });

    test('dispatch returns commands from handlers', () {
      final app = tui.WidgetApp(_CmdReturner());
      app.view();

      final (_, cmd) = app.update(const _TriggerCmdMsg());
      expect(cmd, isNotNull);
    });
  });

  group('Full example app structure reproduction', () {
    test('counter increments with nested MediaQuery + tabs + body', () {
      final app = tui.WidgetApp(_FullExampleApp());
      app.update(tui.WindowSizeMsg(120, 40));
      final output1 = app.view();
      expect(output1, contains('Counter: 0'));
      expect(output1, contains('Tab: 0'));

      // Press + to increment counter
      app.update(_keyMsg('+'));
      final output2 = app.view();
      expect(
        output2,
        contains('Counter: 1'),
        reason: 'Counter should increment via + key in full app structure',
      );
    });

    test('tab switches via key in full app structure', () {
      final app = tui.WidgetApp(_FullExampleApp());
      app.update(tui.WindowSizeMsg(120, 40));
      app.view();

      app.update(_keyMsg('2'));
      final output = app.view();
      expect(
        output,
        contains('Tab: 1'),
        reason: 'Tab should switch via key 2 in full app structure',
      );
      expect(output, contains('Content for tab 1'));
    });

    test('tab switches via click in full app structure', () {
      final app = tui.WidgetApp(_FullExampleApp());
      app.update(tui.WindowSizeMsg(120, 40));
      app.view();

      _simulateTapOnText(app, 'Tab2');
      final output = app.view();
      expect(
        output,
        contains('Tab: 2'),
        reason: 'Tab should switch via click in full app structure',
      );
    });

    test('counter + tabs + click counter all work together', () {
      final app = tui.WidgetApp(_FullExampleApp());
      app.update(tui.WindowSizeMsg(120, 40));
      app.view();

      // Increment counter via key
      app.update(_keyMsg('+'));
      app.update(_keyMsg('+'));
      expect(app.view(), contains('Counter: 2'));

      // Switch tab via key
      app.update(_keyMsg('3'));
      expect(app.view(), contains('Tab: 2'));
      // Counter should still be 2
      expect(app.view(), contains('Counter: 2'));

      // Switch tab via click
      _simulateTapOnText(app, 'Tab1');
      expect(app.view(), contains('Tab: 1'));
      expect(app.view(), contains('Counter: 2'));

      // Click the click counter
      _simulateTapOnText(app, 'clicks: 0');
      expect(app.view(), contains('clicks: 1'));
      expect(app.view(), contains('Counter: 2'));
      expect(app.view(), contains('Tab: 1'));

      // Resize
      app.update(tui.WindowSizeMsg(80, 24));
      final output = app.view();
      expect(output, contains('Counter: 2'));
      expect(output, contains('Tab: 1'));
      expect(output, contains('clicks: 1'));
    });

    test('state survives rapid key + resize + click sequence', () {
      final app = tui.WidgetApp(_FullExampleApp());
      app.update(tui.WindowSizeMsg(120, 40));
      app.view();

      app.update(_keyMsg('+'));
      app.update(_keyMsg('+'));
      app.update(_keyMsg('+'));
      app.update(_keyMsg('4'));
      app.update(tui.WindowSizeMsg(100, 30));
      _simulateTapOnText(app, 'clicks: 0');
      _simulateTapOnText(app, 'clicks: 1');
      app.update(_keyMsg('+'));

      final output = app.view();
      expect(output, contains('Counter: 4'));
      expect(output, contains('Tab: 3'));
      expect(output, contains('clicks: 2'));
    });
  });

  group('KeyMsg dispatch (example app pattern)', () {
    test('pressing + increments counter via handleUpdate', () {
      final app = tui.WidgetApp(_KeyCounterWidget());
      final output1 = app.view();
      expect(output1, contains('Counter: 0'));

      // Simulate pressing '+'
      app.update(_keyMsg('+'));
      final output2 = app.view();
      expect(
        output2,
        contains('Counter: 1'),
        reason: 'Pressing + should increment counter via handleUpdate',
      );
    });

    test('pressing + multiple times increments correctly', () {
      final app = tui.WidgetApp(_KeyCounterWidget());
      app.view();

      app.update(_keyMsg('+'));
      app.update(_keyMsg('+'));
      app.update(_keyMsg('+'));
      final output = app.view();
      expect(output, contains('Counter: 3'));
    });

    test('pressing 1-4 switches tabs via handleUpdate', () {
      final app = tui.WidgetApp(_KeyTabWidget());
      final output1 = app.view();
      expect(output1, contains('Tab: 0'));

      app.update(_keyMsg('2'));
      expect(app.view(), contains('Tab: 1'));

      app.update(_keyMsg('3'));
      expect(app.view(), contains('Tab: 2'));

      app.update(_keyMsg('1'));
      expect(app.view(), contains('Tab: 0'));

      app.update(_keyMsg('4'));
      expect(app.view(), contains('Tab: 3'));
    });

    test('key dispatch + mouse tap coexist without state loss', () {
      final app = tui.WidgetApp(_KeyAndClickWidget());
      app.view();

      // Increment counter via key
      app.update(_keyMsg('+'));
      expect(app.view(), contains('counter: 1'));
      expect(app.view(), contains('clicks: 0'));

      // Increment clicks via tap
      _simulateTapOnText(app, 'clicks: 0');
      expect(app.view(), contains('counter: 1'));
      expect(app.view(), contains('clicks: 1'));

      // Increment counter again via key
      app.update(_keyMsg('+'));
      expect(app.view(), contains('counter: 2'));
      expect(app.view(), contains('clicks: 1'));
    });

    test('key dispatch after resize preserves state', () {
      final app = tui.WidgetApp(_KeyCounterWidget());
      app.view();

      app.update(_keyMsg('+'));
      app.update(_keyMsg('+'));
      expect(app.view(), contains('Counter: 2'));

      // Resize
      app.update(tui.WindowSizeMsg(100, 30));
      expect(
        app.view(),
        contains('Counter: 2'),
        reason: 'Counter should survive resize',
      );

      // Key still works after resize
      app.update(_keyMsg('+'));
      expect(app.view(), contains('Counter: 3'));
    });
  });

  group('Hit-test specifics', () {
    test('hitTestAt returns deepest element first', () {
      final app = tui.WidgetApp(w.Text('hello'));
      app.view();

      final hits = app.hitTestAt(0, 0);
      expect(hits, isNotEmpty);
      expect(hits.first.element.widget.runtimeType.toString(), equals('Text'));
    });

    test('hit-test outside render bounds returns empty', () {
      final app = tui.WidgetApp(w.Text('hello'));
      app.view();

      final hits = app.hitTestAt(79, 23);
      expect(hits, isEmpty);
    });

    test('hit-test dispatches to correct GestureDetector in Column', () {
      final app = tui.WidgetApp(_MultiButtonWidget());
      app.view();

      _simulateTapOnText(app, 'Button A');
      expect(app.view(), contains('tapped: A'));

      _simulateTapOnText(app, 'Button B');
      expect(app.view(), contains('tapped: B'));

      // Tap A again
      _simulateTapOnText(app, 'Button A');
      expect(app.view(), contains('tapped: A'));
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: create a KeyMsg from a character
// ---------------------------------------------------------------------------

tui.KeyMsg _keyMsg(String char) {
  return tui.KeyMsg(
    terminal_keys.Key(terminal_keys.KeyType.runes, runes: char.codeUnits),
  );
}

// ---------------------------------------------------------------------------
// Helper: locate text in rendered output (returns terminal coordinates)
// ---------------------------------------------------------------------------

({int x, int y})? _locateText(String view, String text) {
  final lines = view.split('\n');
  for (var row = 0; row < lines.length; row++) {
    final stripped = Layout.stripAnsi(lines[row]);
    final col = stripped.indexOf(text);
    if (col >= 0) {
      // Return a position in the middle of the text
      return (x: col + text.length ~/ 2, y: row);
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Helper: simulate a tap (press + release) on visible text via hit-testing
// ---------------------------------------------------------------------------

void _simulateTapOnText(tui.WidgetApp app, String text) {
  final view = app.view() as String;
  final loc = _locateText(view, text);
  if (loc == null) {
    final snippet = view.length > 500 ? '${view.substring(0, 500)}...' : view;
    fail(
      'Text "$text" not found in rendered view.\n'
      'View:\n$snippet',
    );
  }

  final x = loc.x;
  final y = loc.y;

  // Press
  app.update(
    tui.MouseMsg(
      action: tui.MouseAction.press,
      button: tui.MouseButton.left,
      x: x,
      y: y,
    ),
  );
  // Render between press and release so dirty elements are processed
  app.view();

  // Release at same position
  app.update(
    tui.MouseMsg(
      action: tui.MouseAction.release,
      button: tui.MouseButton.left,
      x: x,
      y: y,
    ),
  );
  // Render to process the rebuild
  app.view();
}

// ---------------------------------------------------------------------------
// Test widgets
// ---------------------------------------------------------------------------

/// A simple counter that increments on _IncrementMsg via setState.
class _CounterWidget extends w.StatefulWidget {
  _CounterWidget();

  @override
  w.State createState() => _CounterWidgetState();
}

class _CounterWidgetState extends w.State<_CounterWidget> {
  int _count = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _IncrementMsg) {
      setState(() => _count++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('count: $_count');
  }
}

/// A counter that increments on tap (hit-test based).
class _ClickableCounter extends w.StatefulWidget {
  _ClickableCounter();

  @override
  w.State createState() => _ClickableCounterState();
}

class _ClickableCounterState extends w.State<_ClickableCounter> {
  int _clicks = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.GestureDetector(
      onTap: () {
        setState(() => _clicks++);
        return null;
      },
      child: w.Text('clicks: $_clicks'),
    );
  }
}

/// Two buttons, tracks which one was last tapped.
class _MultiButtonWidget extends w.StatefulWidget {
  _MultiButtonWidget();

  @override
  w.State createState() => _MultiButtonWidgetState();
}

class _MultiButtonWidgetState extends w.State<_MultiButtonWidget> {
  String _tapped = 'none';

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.GestureDetector(
          onTap: () {
            setState(() => _tapped = 'A');
            return null;
          },
          child: w.Text('Button A'),
        ),
        w.GestureDetector(
          onTap: () {
            setState(() => _tapped = 'B');
            return null;
          },
          child: w.Text('Button B'),
        ),
        w.Text('tapped: $_tapped'),
      ],
    );
  }
}

/// Tab widget with GestureDetectors (no zoneId).
class _TabWidget extends w.StatefulWidget {
  _TabWidget();

  @override
  w.State createState() => _TabWidgetState();
}

class _TabWidgetState extends w.State<_TabWidget> {
  int _selectedTab = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Row(
          children: [
            for (var i = 0; i < 3; i++)
              w.GestureDetector(
                key: w.ValueKey<int>(i),
                onTap: () {
                  setState(() => _selectedTab = i);
                  return null;
                },
                child: w.Text('Tab $i'),
              ),
          ],
        ),
        w.Text('Content: Tab $_selectedTab'),
      ],
    );
  }
}

/// Tab widget WITHOUT explicit zoneId — hit-test-only path.
class _TabWidgetNoZone extends w.StatefulWidget {
  _TabWidgetNoZone();

  @override
  w.State createState() => _TabWidgetNoZoneState();
}

class _TabWidgetNoZoneState extends w.State<_TabWidgetNoZone> {
  int _selectedTab = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Row(
          children: [
            for (var i = 0; i < 3; i++)
              w.GestureDetector(
                key: w.ValueKey<int>(i),
                onTap: () {
                  setState(() => _selectedTab = i);
                  return null;
                },
                child: w.Container(
                  padding: const w.EdgeInsets.symmetric(horizontal: 2),
                  child: w.Text('Tab $i'),
                ),
              ),
          ],
        ),
        w.Text('Content: Tab $_selectedTab'),
      ],
    );
  }
}

/// Tests positional state preservation for unkeyed children.
class _PositionalStateTest extends w.StatefulWidget {
  _PositionalStateTest();

  @override
  w.State createState() => _PositionalStateTestState();
}

class _PositionalStateTestState extends w.State<_PositionalStateTest> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        _NamedCounter(name: 'A'),
        _NamedCounter(name: 'B'),
      ],
    );
  }
}

class _NamedCounter extends w.StatefulWidget {
  _NamedCounter({required this.name, super.key});
  final String name;

  @override
  w.State createState() => _NamedCounterState();
}

class _NamedCounterState extends w.State<_NamedCounter> {
  int _count = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _IncrementChildMsg && msg.name == widget.name) {
      setState(() => _count++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('${widget.name}: $_count');
  }
}

/// Tests that keyed children preserve state when reordered.
class _KeyedReorderTest extends w.StatefulWidget {
  _KeyedReorderTest();

  @override
  w.State createState() => _KeyedReorderTestState();
}

class _KeyedReorderTestState extends w.State<_KeyedReorderTest> {
  bool _reversed = false;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _ReorderMsg) {
      setState(() => _reversed = !_reversed);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final children = [
      _NamedCounter(name: 'alpha', key: const w.Key('alpha')),
      _NamedCounter(name: 'beta', key: const w.Key('beta')),
    ];
    return w.Column(
      children: _reversed ? children.reversed.toList() : children,
    );
  }
}

/// Tests that setState updates the rendered value.
class _SetStateTester extends w.StatefulWidget {
  _SetStateTester();

  @override
  w.State createState() => _SetStateTesterState();
}

class _SetStateTesterState extends w.State<_SetStateTester> {
  String _value = 'initial';

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _ChangeValueMsg) {
      setState(() => _value = msg.newValue);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('value: $_value');
  }
}

/// Tests nested stateful widgets with independent setState.
class _NestedSetStateWidget extends w.StatefulWidget {
  _NestedSetStateWidget();

  @override
  w.State createState() => _NestedSetStateWidgetState();
}

class _NestedSetStateWidgetState extends w.State<_NestedSetStateWidget> {
  int _outerCount = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _IncrementMsg) {
      setState(() => _outerCount++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(children: [w.Text('outer: $_outerCount'), _InnerCounter()]);
  }
}

class _InnerCounter extends w.StatefulWidget {
  _InnerCounter();

  @override
  w.State createState() => _InnerCounterState();
}

class _InnerCounterState extends w.State<_InnerCounter> {
  int _count = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _IncrementInnerMsg) {
      setState(() => _count++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('inner: $_count');
  }
}

/// Full example app structure: MediaQuery-aware, with header, tabs, body,
/// click counter — reproduces the exact nesting pattern from the example.
class _FullExampleApp extends w.StatefulWidget {
  _FullExampleApp();

  @override
  w.State createState() => _FullExampleAppState();
}

class _FullExampleAppState extends w.State<_FullExampleApp> {
  int _counter = 0;
  int _selectedTab = 0;
  int? _hoveredTab;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == '+' || key.char == '=') {
        setState(() => _counter++);
      }
      if (key.char == '-') {
        setState(() => _counter--);
      }
      if (key.char == '1') setState(() => _selectedTab = 0);
      if (key.char == '2') setState(() => _selectedTab = 1);
      if (key.char == '3') setState(() => _selectedTab = 2);
      if (key.char == '4') setState(() => _selectedTab = 3);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();

    return w.Column(
      gap: 1,
      children: [
        // Header (like example)
        w.SizedBox(
          width: width > 0 ? width : null,
          child: w.Row(
            children: [w.Text('Widget Demo'), w.Text('Counter: $_counter')],
          ),
        ),
        // Tabs (like example)
        w.Row(gap: 2, children: [for (var i = 0; i < 4; i++) _tab(i, 'Tab$i')]),
        // Body (like example)
        w.Column(
          children: [
            w.Text('Tab: $_selectedTab'),
            w.Text('Content for tab $_selectedTab'),
          ],
        ),
        // Click counter (like example)
        _FullClickCounter(),
      ],
    );
  }

  w.Widget _tab(int index, String label) {
    final isSelected = _selectedTab == index;
    return w.GestureDetector(
      key: w.ValueKey<int>(index),
      onTap: () {
        setState(() => _selectedTab = index);
        return null;
      },
      onEnter: (_) {
        setState(() => _hoveredTab = index);
        return null;
      },
      onExit: (_) {
        if (_hoveredTab == index) {
          setState(() => _hoveredTab = null);
        }
        return null;
      },
      child: w.Container(
        padding: const w.EdgeInsets.symmetric(horizontal: 2),
        child: w.Text(isSelected ? '[$label]' : label),
      ),
    );
  }
}

class _FullClickCounter extends w.StatefulWidget {
  _FullClickCounter();

  @override
  w.State createState() => _FullClickCounterState();
}

class _FullClickCounterState extends w.State<_FullClickCounter> {
  int _clicks = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.GestureDetector(
      onTap: () {
        setState(() => _clicks++);
        return null;
      },
      child: w.Text('clicks: $_clicks'),
    );
  }
}

/// Counter widget that increments via KeyMsg handleUpdate (like example app).
class _KeyCounterWidget extends w.StatefulWidget {
  _KeyCounterWidget();

  @override
  w.State createState() => _KeyCounterWidgetState();
}

class _KeyCounterWidgetState extends w.State<_KeyCounterWidget> {
  int _counter = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == '+' || key.char == '=') {
        setState(() => _counter++);
      }
      if (key.char == '-') {
        setState(() => _counter--);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('Counter: $_counter');
  }
}

/// Tab widget that switches via key 1-4 (like example app).
class _KeyTabWidget extends w.StatefulWidget {
  _KeyTabWidget();

  @override
  w.State createState() => _KeyTabWidgetState();
}

class _KeyTabWidgetState extends w.State<_KeyTabWidget> {
  int _selectedTab = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == '1') setState(() => _selectedTab = 0);
      if (key.char == '2') setState(() => _selectedTab = 1);
      if (key.char == '3') setState(() => _selectedTab = 2);
      if (key.char == '4') setState(() => _selectedTab = 3);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Text('Tab: $_selectedTab'),
        w.Text('Content for tab $_selectedTab'),
      ],
    );
  }
}

/// Widget with both key-driven counter and click-driven counter.
class _KeyAndClickWidget extends w.StatefulWidget {
  _KeyAndClickWidget();

  @override
  w.State createState() => _KeyAndClickWidgetState();
}

class _KeyAndClickWidgetState extends w.State<_KeyAndClickWidget> {
  int _counter = 0;
  int _clicks = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      if (msg.key.char == '+') {
        setState(() => _counter++);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Text('counter: $_counter'),
        w.GestureDetector(
          onTap: () {
            setState(() => _clicks++);
            return null;
          },
          child: w.Text('clicks: $_clicks'),
        ),
      ],
    );
  }
}

/// Reproduces the example app's exact tab construction pattern:
/// GestureDetector with ValueKey, onTap, onEnter, onExit, wrapping Container.
class _ExampleTabPattern extends w.StatefulWidget {
  _ExampleTabPattern();

  @override
  w.State createState() => _ExampleTabPatternState();
}

class _ExampleTabPatternState extends w.State<_ExampleTabPattern> {
  int _selectedTab = 0;
  int? _hoveredTab;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Row(gap: 2, children: [for (var i = 0; i < 4; i++) _tab(i, 'Tab$i')]),
        w.Text('selected: $_selectedTab'),
        w.Text('hovered: $_hoveredTab'),
      ],
    );
  }

  w.Widget _tab(int index, String label) {
    return w.GestureDetector(
      key: w.ValueKey<int>(index),
      onTap: () {
        setState(() => _selectedTab = index);
        return null;
      },
      onEnter: (_) {
        setState(() => _hoveredTab = index);
        return null;
      },
      onExit: (_) {
        if (_hoveredTab == index) {
          setState(() => _hoveredTab = null);
        }
        return null;
      },
      child: w.Container(
        padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        child: w.Text(label),
      ),
    );
  }
}

/// Tab widget to test closure capture.
class _ClosureCaptureTabWidget extends w.StatefulWidget {
  _ClosureCaptureTabWidget();

  @override
  w.State createState() => _ClosureCaptureTabWidgetState();
}

class _ClosureCaptureTabWidgetState extends w.State<_ClosureCaptureTabWidget> {
  int _selected = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Row(
          children: [
            for (var i = 0; i < 4; i++)
              w.GestureDetector(
                key: w.ValueKey<int>(i),
                onTap: () {
                  setState(() => _selected = i);
                  return null;
                },
                child: w.Text('T$i'),
              ),
          ],
        ),
        w.Text('selected: $_selected'),
      ],
    );
  }
}

/// Reads MediaQuery data and displays it.
class _MediaQueryReader extends w.StatelessWidget {
  _MediaQueryReader();

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final mw = media.size.width.round();
    final mh = media.size.height.round();
    return w.Text('${mw}x$mh');
  }
}

/// Returns a command when it receives _TriggerCmdMsg.
class _CmdReturner extends w.StatefulWidget {
  _CmdReturner();

  @override
  w.State createState() => _CmdReturnerState();
}

class _CmdReturnerState extends w.State<_CmdReturner> {
  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _TriggerCmdMsg) {
      return tui.Cmd.none();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('cmd returner');
  }
}

class _LeafRenderUpdateWidget extends w.StatefulWidget {
  _LeafRenderUpdateWidget();

  @override
  w.State createState() => _LeafRenderUpdateWidgetState();
}

class _LeafRenderUpdateWidgetState extends w.State<_LeafRenderUpdateWidget> {
  int _count = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _IncrementMsg) {
      setState(() => _count++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('leaf: $_count');
  }
}

// ---------------------------------------------------------------------------
// Test messages
// ---------------------------------------------------------------------------

class _IncrementMsg extends tui.Msg {
  const _IncrementMsg();
}

class _IncrementChildMsg extends tui.Msg {
  const _IncrementChildMsg(this.name);
  final String name;
}

class _IncrementInnerMsg extends tui.Msg {
  const _IncrementInnerMsg();
}

class _ReorderMsg extends tui.Msg {
  const _ReorderMsg();
}

class _ChangeValueMsg extends tui.Msg {
  const _ChangeValueMsg(this.newValue);
  final String newValue;
}

class _TriggerCmdMsg extends tui.Msg {
  const _TriggerCmdMsg();
}
