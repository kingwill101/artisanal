/// Comprehensive tests using WidgetTester to reproduce the example app behavior.
///
/// These tests verify:
/// - WidgetTester lifecycle (pumpWidget, pump, dispose)
/// - Key input dispatching and state updates
/// - Hit-test-based tap dispatching (textLocation and tapAt)
/// - Tab switching via taps and key presses
/// - Counter increment via keys and clicks
/// - Combined key + mouse interactions
/// - State preservation across resizes
/// - Finder API for text queries
/// - Exact reproduction of the example app's widget structure
///
/// All mouse/tap tests use render-tree hit-testing (the Flutter-centric
/// approach) rather than zone-based dispatch.
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:test/test.dart';

// Import the actual example app widget — test the real code, not a re-impl.
import '../example/main.dart' show AppWidget;

void main() {
  // -------------------------------------------------------------------------
  // WidgetTester lifecycle
  // -------------------------------------------------------------------------

  group('WidgetTester lifecycle', () {
    test('pumpWidget mounts widget and produces initial view', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.Text('hello world'));
      expect(tester.view, contains('hello world'));
      expect(tester.pumpCount, equals(1));
    });

    test('pump without pumpWidget throws', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      expect(() => tester.pump(), throwsStateError);
    });

    test('dispose cleans up and allows fresh tester', () async {
      final tester = WidgetTester();
      await tester.pumpWidget(w.Text('test'));
      await tester.dispose();
      // Should not throw when creating a new tester after dispose.
      final tester2 = WidgetTester();
      await tester2.pumpWidget(w.Text('test2'));
      expect(tester2.view, contains('test2'));
      await tester2.dispose();
    });

    test('pumpWidget with custom screen size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_MediaQueryReader(), width: 120, height: 40);
      expect(tester.view, contains('120x40'));
    });

    test('resize updates MediaQuery and re-renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_MediaQueryReader());
      expect(tester.view, contains('80x24')); // default size

      tester.resize(100, 30);
      expect(tester.view, contains('100x30'));
    });
  });

  // -------------------------------------------------------------------------
  // Finder API
  // -------------------------------------------------------------------------

  group('Finder', () {
    test('find.text checks rendered output', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.Text('visible content'));
      expect(tester.find.text('visible'), isTrue);
      expect(tester.find.text('invisible'), isFalse);
    });

    test('find.textMatching uses regex', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.Text('count: 42'));
      expect(tester.find.textMatching(RegExp(r'count: \d+')), isTrue);
      expect(tester.find.textMatching(RegExp(r'total: \d+')), isFalse);
    });

    test('find.textLocation returns coordinates of visible text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Column(children: [w.Text('first line'), w.Text('second line')]),
      );

      final loc1 = tester.locateText('first');
      expect(loc1, isNotNull);
      expect(loc1!.y, equals(0));

      final loc2 = tester.locateText('second');
      expect(loc2, isNotNull);
      expect(loc2!.y, equals(1));

      expect(tester.locateText('nonexistent'), isNull);
    });

    test('find.byType returns mounted elements by widget type', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Column(
          children: [
            w.Text('one'),
            w.Container(child: w.Text('two')),
            w.Text('three'),
          ],
        ),
      );

      final textElements = tester.find.byType<w.Text>();
      expect(textElements.length, equals(3));
      expect(textElements.first.widget.runtimeType, equals(w.Text));
    });

    test('find.byKey returns mounted elements by key', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      const targetKey = w.ValueKey<String>('target-button');

      await tester.pumpWidget(
        w.Column(
          children: [
            w.Text('before'),
            w.GestureDetector(
              key: targetKey,
              onTap: () => null,
              child: w.Text('tap me'),
            ),
            w.Text('after'),
          ],
        ),
      );

      final keyed = tester.find.byKey(targetKey);
      expect(keyed.length, equals(1));
      expect(keyed.single.widget.key, equals(targetKey));
    });

    test('find.byKeyLocation can tap by widget key', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      const tapKey = w.ValueKey<String>('keyed-tap-target');

      await tester.pumpWidget(_KeyedTapCounter(key: tapKey));
      expect(tester.find.text('keyed clicks: 0'), isTrue);

      tester.tap(tester.find.byKeyLocation(tapKey));
      expect(tester.find.text('keyed clicks: 1'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Key input
  // -------------------------------------------------------------------------

  group('sendKey', () {
    test('dispatches KeyMsg and triggers setState', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_KeyCounterWidget());
      expect(tester.find.text('counter: 0'), isTrue);

      tester.sendKey('+');
      expect(tester.find.text('counter: 1'), isTrue);

      tester.sendKey('+');
      tester.sendKey('+');
      expect(tester.find.text('counter: 3'), isTrue);
    });

    test('sendKey with minus decrements', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_KeyCounterWidget());
      tester.sendKey('+');
      tester.sendKey('+');
      tester.sendKey('+');
      expect(tester.find.text('counter: 3'), isTrue);

      tester.sendKey('-');
      expect(tester.find.text('counter: 2'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Hit-test-based tap dispatching
  // -------------------------------------------------------------------------

  group('tap via hit-testing', () {
    test('tap on GestureDetector invokes onTap callback', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ClickableCounter());
      expect(tester.find.text('clicks: 0'), isTrue);

      tester.tap(tester.find.textLocation('clicks: 0'));
      expect(tester.find.text('clicks: 1'), isTrue);

      tester.tap(tester.find.textLocation('clicks: 1'));
      tester.tap(tester.find.textLocation('clicks: 2'));
      expect(tester.find.text('clicks: 3'), isTrue);
    });

    test('tap on correct target among multiple GestureDetectors', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_MultiButtonWidget());
      expect(tester.find.text('tapped: none'), isTrue);

      tester.tap(tester.find.textLocation('Button A'));
      expect(tester.find.text('tapped: A'), isTrue);

      tester.tap(tester.find.textLocation('Button B'));
      expect(tester.find.text('tapped: B'), isTrue);

      // Back to A.
      tester.tap(tester.find.textLocation('Button A'));
      expect(tester.find.text('tapped: A'), isTrue);
    });

    test('tapAt with raw coordinates triggers GestureDetector', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ClickableCounter());
      expect(tester.find.text('clicks: 0'), isTrue);

      // Tap at the beginning of the text — should be within the
      // GestureDetector's child render object.
      tester.tapAt(0, 0);
      expect(tester.find.text('clicks: 1'), isTrue);
    });

    test('tapAt outside render bounds does nothing', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Wrap in Container so the _ClickableCounter receives loose constraints
      // and does not fill the entire terminal.
      await tester.pumpWidget(w.Container(child: _ClickableCounter()));
      expect(tester.find.text('clicks: 0'), isTrue);

      // Tap way outside the content area.
      tester.tapAt(79, 23);
      expect(
        tester.find.text('clicks: 0'),
        isTrue,
        reason: 'Click outside render bounds should not increment',
      );
    });

    test('hit-test returns elements deepest first', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.Text('hello'));
      final hits = tester.hitTestAt(0, 0);
      expect(hits, isNotEmpty);
      // The deepest element should be the Text's render element.
      expect(hits.first.element.widget.runtimeType.toString(), equals('Text'));
    });
  });

  // -------------------------------------------------------------------------
  // Tab switching via taps (hit-test based)
  // -------------------------------------------------------------------------

  group('tab switching (hit-test)', () {
    test('clicking tab text changes displayed content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_TabWidget());
      expect(tester.find.text('Content: Tab 0'), isTrue);

      tester.tap(tester.find.textLocation('Tab 1'));
      expect(tester.find.text('Content: Tab 1'), isTrue);

      tester.tap(tester.find.textLocation('Tab 2'));
      expect(tester.find.text('Content: Tab 2'), isTrue);

      tester.tap(tester.find.textLocation('Tab 0'));
      expect(tester.find.text('Content: Tab 0'), isTrue);
    });

    test('rapid tab switching works correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_TabWidget());

      for (var i = 0; i < 5; i++) {
        tester.tap(tester.find.textLocation('Tab ${i % 3}'));
        expect(tester.find.text('Content: Tab ${i % 3}'), isTrue);
      }
    });

    test('tab state survives resize', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_TabWidget());

      tester.tap(tester.find.textLocation('Tab 2'));
      expect(tester.find.text('Content: Tab 2'), isTrue);

      tester.resize(100, 30);
      expect(
        tester.find.text('Content: Tab 2'),
        isTrue,
        reason: 'Tab selection should survive resize',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Key-driven tab switching
  // -------------------------------------------------------------------------

  group('key-driven tab switching', () {
    test('pressing 1-4 switches tabs', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_KeyTabWidget());
      expect(tester.find.text('Tab: 0'), isTrue);

      tester.sendKey('2');
      expect(tester.find.text('Tab: 1'), isTrue);

      tester.sendKey('3');
      expect(tester.find.text('Tab: 2'), isTrue);

      tester.sendKey('4');
      expect(tester.find.text('Tab: 3'), isTrue);

      tester.sendKey('1');
      expect(tester.find.text('Tab: 0'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Combined key + mouse interactions
  // -------------------------------------------------------------------------

  group('combined key + mouse', () {
    test('key and tap coexist without state loss', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_KeyAndClickWidget());
      expect(tester.find.text('counter: 0'), isTrue);
      expect(tester.find.text('clicks: 0'), isTrue);

      // Key increments counter.
      tester.sendKey('+');
      expect(tester.find.text('counter: 1'), isTrue);
      expect(tester.find.text('clicks: 0'), isTrue);

      // Tap increments clicks (using hit-test via text location).
      tester.tap(tester.find.textLocation('clicks: 0'));
      expect(tester.find.text('counter: 1'), isTrue);
      expect(tester.find.text('clicks: 1'), isTrue);

      // Both still work.
      tester.sendKey('+');
      tester.tap(tester.find.textLocation('clicks: 1'));
      expect(tester.find.text('counter: 2'), isTrue);
      expect(tester.find.text('clicks: 2'), isTrue);
    });

    test('key dispatch after resize preserves state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_KeyCounterWidget());
      tester.sendKey('+');
      tester.sendKey('+');
      expect(tester.find.text('counter: 2'), isTrue);

      tester.resize(100, 30);
      expect(
        tester.find.text('counter: 2'),
        isTrue,
        reason: 'Counter should survive resize',
      );

      tester.sendKey('+');
      expect(
        tester.find.text('counter: 3'),
        isTrue,
        reason: 'Key input should work after resize',
      );
    });

    test('mouse tap after resize still works via hit-testing', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ClickableCounter());
      tester.tap(tester.find.textLocation('clicks: 0'));
      expect(tester.find.text('clicks: 1'), isTrue);

      tester.resize(120, 40);
      expect(tester.find.text('clicks: 1'), isTrue);

      // Hit-testing should still work after resize.
      tester.tap(tester.find.textLocation('clicks: 1'));
      expect(
        tester.find.text('clicks: 2'),
        isTrue,
        reason: 'Tap via hit-test should work after resize',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Mouse press/release and drag semantics
  // -------------------------------------------------------------------------

  group('mouse press/release', () {
    test('mouseDown + mouseUp at same position is a tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ClickableCounter());
      expect(tester.find.text('clicks: 0'), isTrue);

      // Manual press + release (equivalent to tapAt).
      tester.mouseDown(0, 0);
      tester.mouseUp(0, 0);
      expect(tester.find.text('clicks: 1'), isTrue);
    });

    test('mouse capture: drag events go to capture owner', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var dragStarted = false;
      var dragUpdated = false;
      var dragEnded = false;

      await tester.pumpWidget(
        w.GestureDetector(
          onDragStart: (_) {
            dragStarted = true;
            return null;
          },
          onDragUpdate: (_) {
            dragUpdated = true;
            return null;
          },
          onDragEnd: (_) {
            dragEnded = true;
            return null;
          },
          child: w.Text('drag me'),
        ),
        useHitTesting: true,
      );

      // Press to initiate — drag hasn't started until movement exceeds slop.
      tester.mouseDown(0, 0);
      expect(dragStarted, isFalse);

      // Motion beyond the drag slop triggers dragStart + first dragUpdate.
      tester.mouseMove(5, 0);
      expect(dragStarted, isTrue);
      expect(dragUpdated, isTrue);

      // Release ends drag.
      tester.mouseUp(5, 0);
      expect(dragEnded, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Full example-app reproduction
  // -------------------------------------------------------------------------

  group('example app reproduction', () {
    test('header counter increments with + key', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ExampleApp());
      expect(tester.find.text('Counter: 0'), isTrue);

      tester.sendKey('+');
      expect(tester.find.text('Counter: 1'), isTrue);

      tester.sendKey('+');
      tester.sendKey('+');
      expect(tester.find.text('Counter: 3'), isTrue);
    });

    test('header counter decrements with - key', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ExampleApp());
      tester.sendKey('+');
      tester.sendKey('+');
      tester.sendKey('+');

      tester.sendKey('-');
      expect(tester.find.text('Counter: 2'), isTrue);
    });

    test('tab switching with number keys', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ExampleApp());
      expect(tester.find.text('Layout Content'), isTrue);

      tester.sendKey('2');
      expect(tester.find.text('Theme Content'), isTrue);
      expect(tester.find.text('Layout Content'), isFalse);

      tester.sendKey('3');
      expect(tester.find.text('Stack Content'), isTrue);

      tester.sendKey('4');
      expect(tester.find.text('Components Content'), isTrue);

      tester.sendKey('1');
      expect(tester.find.text('Layout Content'), isTrue);
    });

    test('tab switching via tap on tab text (hit-test)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ExampleApp());
      expect(tester.find.text('Layout Content'), isTrue);

      tester.tap(tester.find.textLocation('Theme'));
      expect(tester.find.text('Theme Content'), isTrue);
      expect(tester.find.text('Layout Content'), isFalse);

      tester.tap(tester.find.textLocation('Stack'));
      expect(tester.find.text('Stack Content'), isTrue);

      tester.tap(tester.find.textLocation('Layout'));
      expect(tester.find.text('Layout Content'), isTrue);
    });

    test('counter and tab switching are independent', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ExampleApp());

      // Increment counter.
      tester.sendKey('+');
      tester.sendKey('+');
      expect(tester.find.text('Counter: 2'), isTrue);
      expect(tester.find.text('Layout Content'), isTrue);

      // Switch tab — counter should be preserved.
      tester.tap(tester.find.textLocation('Stack'));
      expect(tester.find.text('Counter: 2'), isTrue);
      expect(tester.find.text('Stack Content'), isTrue);

      // Increment counter on different tab.
      tester.sendKey('+');
      expect(tester.find.text('Counter: 3'), isTrue);
      expect(tester.find.text('Stack Content'), isTrue);

      // Switch back — counter still correct.
      tester.tap(tester.find.textLocation('Layout'));
      expect(tester.find.text('Counter: 3'), isTrue);
      expect(tester.find.text('Layout Content'), isTrue);
    });

    test('everything survives resize', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ExampleApp());
      tester.sendKey('+');
      tester.sendKey('+');
      tester.tap(tester.find.textLocation('Theme'));
      expect(tester.find.text('Counter: 2'), isTrue);
      expect(tester.find.text('Theme Content'), isTrue);

      tester.resize(120, 40);
      expect(
        tester.find.text('Counter: 2'),
        isTrue,
        reason: 'Counter should survive resize',
      );
      expect(
        tester.find.text('Theme Content'),
        isTrue,
        reason: 'Tab selection should survive resize',
      );

      // Interactions should still work after resize.
      tester.sendKey('+');
      expect(tester.find.text('Counter: 3'), isTrue);

      tester.tap(tester.find.textLocation('Stack'));
      expect(tester.find.text('Stack Content'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Nested stateful widgets
  // -------------------------------------------------------------------------

  group('nested stateful widgets', () {
    test('parent and child have independent state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_NestedCounters());
      expect(tester.find.text('outer: 0'), isTrue);
      expect(tester.find.text('inner: 0'), isTrue);

      // Increment outer via key.
      tester.sendKey('o');
      expect(tester.find.text('outer: 1'), isTrue);
      expect(tester.find.text('inner: 0'), isTrue);

      // Increment inner via key.
      tester.sendKey('i');
      expect(tester.find.text('outer: 1'), isTrue);
      expect(tester.find.text('inner: 1'), isTrue);

      // Multiple increments.
      tester.sendKey('o');
      tester.sendKey('o');
      tester.sendKey('i');
      expect(tester.find.text('outer: 3'), isTrue);
      expect(tester.find.text('inner: 2'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // setState triggers rebuild
  // -------------------------------------------------------------------------

  group('setState and rebuild', () {
    test('setState during handleUpdate triggers rebuild', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_KeyCounterWidget());
      expect(tester.find.text('counter: 0'), isTrue);

      // Each sendKey calls handleUpdate → setState → rebuild → re-render.
      for (var i = 1; i <= 10; i++) {
        tester.sendKey('+');
        expect(tester.find.text('counter: $i'), isTrue);
      }
    });

    test('setState during onTap triggers rebuild', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ClickableCounter());
      for (var i = 0; i < 5; i++) {
        expect(tester.find.text('clicks: $i'), isTrue);
        tester.tap(tester.find.textLocation('clicks: $i'));
      }
      expect(tester.find.text('clicks: 5'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // GestureDetector callbacks
  // -------------------------------------------------------------------------

  group('GestureDetector callbacks', () {
    test('onTapDown fires on press', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapDownCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTapDown: (_) {
            tapDownCount++;
            return null;
          },
          child: w.Text('press me'),
        ),
        useHitTesting: true,
      );

      tester.mouseDown(0, 0);
      expect(tapDownCount, equals(1));
    });

    test('onTapUp fires on release', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapUpCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onTapUp: (_) {
            tapUpCount++;
            return null;
          },
          child: w.Text('release me'),
        ),
        useHitTesting: true,
      );

      // Must press first (to establish capture), then release.
      tester.mouseDown(0, 0);
      tester.mouseUp(0, 0);
      expect(tapUpCount, equals(1));
    });

    test('onWheel fires on scroll', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var wheelCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          onWheel: (_) {
            wheelCount++;
            return null;
          },
          child: w.Text('scroll me'),
        ),
        useHitTesting: true,
      );

      tester.sendMsg(
        tui.MouseMsg(
          action: tui.MouseAction.wheel,
          button: tui.MouseButton.wheelUp,
          x: 0,
          y: 0,
        ),
      );
      expect(wheelCount, equals(1));
    });

    test('enabled=false suppresses all callbacks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var tapCount = 0;
      await tester.pumpWidget(
        w.GestureDetector(
          enabled: false,
          onTap: () {
            tapCount++;
            return null;
          },
          child: w.Text('disabled'),
        ),
        useHitTesting: true,
      );

      tester.tapAt(0, 0);
      expect(
        tapCount,
        equals(0),
        reason: 'Disabled GestureDetector should not fire',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Keyed reconciliation
  // -------------------------------------------------------------------------

  group('keyed reconciliation', () {
    test('ValueKey preserves state across reorder', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_KeyedReorderWidget(reversed: false));
      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);

      // Increment A's counter.
      tester.sendKey('a');
      expect(tester.find.text('A:1'), isTrue);
      expect(tester.find.text('B:0'), isTrue);

      // Swap order — state should follow the key.
      tester.sendKey('r'); // trigger reorder
      tester.pump();
      expect(tester.find.text('A:1'), isTrue, reason: 'A counter preserved');
      expect(tester.find.text('B:0'), isTrue, reason: 'B counter preserved');
    });
  });

  // -------------------------------------------------------------------------
  // sendSpecialKey
  // -------------------------------------------------------------------------

  group('sendSpecialKey', () {
    test('escape key dispatches correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var escaped = false;
      await tester.pumpWidget(
        _SpecialKeyWidget(onEscape: () => escaped = true),
      );

      tester.sendSpecialKey(terminal_keys.KeyType.escape);
      expect(escaped, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Real example app (imported directly — no reimplementation)
  // -------------------------------------------------------------------------

  group('real example AppWidget', () {
    test('tab click changes content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      // Initial state: tab 0 (Layout) is selected.
      expect(
        tester.find.text('Row + Column'),
        isTrue,
        reason: 'Layout demo should be visible initially',
      );

      // Click the "Theme" tab label to switch tabs.
      // The real AppWidget uses GestureDetector onTap (not key events)
      // for tab switching.
      tester.tap(tester.find.textLocation('Theme'));

      // _themeDemo() produces "Theme Colors" as its title text.
      expect(
        tester.find.text('Theme Colors'),
        isTrue,
        reason: 'Theme demo should appear after clicking Theme tab',
      );
      expect(
        tester.find.text('Row + Column'),
        isFalse,
        reason: 'Layout demo should no longer be visible',
      );
    });

    test('tab state survives resize', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      tester.tap(tester.find.textLocation('Theme'));
      expect(tester.find.text('Theme Colors'), isTrue);

      tester.resize(100, 30);
      expect(
        tester.find.text('Theme Colors'),
        isTrue,
        reason: 'Tab selection should survive resize',
      );
    });
  });
}

// =============================================================================
// Helper: content text per tab index
// =============================================================================

String _tabContentText(int index) {
  const labels = [
    'Layout Content',
    'Theme Content',
    'Stack Content',
    'Components Content',
  ];
  return labels[index];
}

// =============================================================================
// Test widgets
// =============================================================================

// -- MediaQuery reader --------------------------------------------------------

class _MediaQueryReader extends w.StatelessWidget {
  _MediaQueryReader();

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();
    final height = media.size.height.round();
    return w.Text('${width}x$height');
  }
}

// -- Key counter --------------------------------------------------------------

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
      if (msg.key.char == '+' || msg.key.char == '=') {
        setState(() => _counter++);
      }
      if (msg.key.char == '-') {
        setState(() => _counter--);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('counter: $_counter');
  }
}

// -- Clickable counter (hit-test based) ---------------------------------------

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

class _KeyedTapCounter extends w.StatefulWidget {
  _KeyedTapCounter({super.key});

  @override
  w.State createState() => _KeyedTapCounterState();
}

class _KeyedTapCounterState extends w.State<_KeyedTapCounter> {
  int _clicks = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.GestureDetector(
      key: widget.key,
      onTap: () {
        setState(() => _clicks++);
        return null;
      },
      child: w.Text('keyed clicks: $_clicks'),
    );
  }
}

// -- Multi-button widget (hit-test based) -------------------------------------

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

// -- Tab widget (hit-test based) ----------------------------------------------

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

// -- Key-driven tab switching -------------------------------------------------

class _KeyTabWidget extends w.StatefulWidget {
  _KeyTabWidget();

  @override
  w.State createState() => _KeyTabWidgetState();
}

class _KeyTabWidgetState extends w.State<_KeyTabWidget> {
  int _tab = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final c = msg.key.char;
      if (c == '1') setState(() => _tab = 0);
      if (c == '2') setState(() => _tab = 1);
      if (c == '3') setState(() => _tab = 2);
      if (c == '4') setState(() => _tab = 3);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('Tab: $_tab');
  }
}

// -- Key + click combined widget ----------------------------------------------

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
    if (msg is tui.KeyMsg && msg.key.char == '+') {
      setState(() => _counter++);
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

// -- Nested counters (parent + child independent state) -----------------------

class _NestedCounters extends w.StatefulWidget {
  _NestedCounters();

  @override
  w.State createState() => _NestedCountersState();
}

class _NestedCountersState extends w.State<_NestedCounters> {
  int _outerCount = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'o') {
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
    if (msg is tui.KeyMsg && msg.key.char == 'i') {
      setState(() => _count++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('inner: $_count');
  }
}

// -- Keyed reorder widget (tests reconciliation) ------------------------------

class _KeyedReorderWidget extends w.StatefulWidget {
  _KeyedReorderWidget({required this.reversed});

  final bool reversed;

  @override
  w.State createState() => _KeyedReorderWidgetState();
}

class _KeyedReorderWidgetState extends w.State<_KeyedReorderWidget> {
  bool _reversed = false;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'r') {
      setState(() => _reversed = !_reversed);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final items = [
      _KeyedCounter(key: const w.ValueKey('a'), label: 'A'),
      _KeyedCounter(key: const w.ValueKey('b'), label: 'B'),
    ];
    return w.Column(children: _reversed ? items.reversed.toList() : items);
  }
}

class _KeyedCounter extends w.StatefulWidget {
  _KeyedCounter({required this.label, super.key});

  final String label;

  @override
  w.State createState() => _KeyedCounterState();
}

class _KeyedCounterState extends w.State<_KeyedCounter> {
  int _count = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == widget.label.toLowerCase()) {
      setState(() => _count++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('${widget.label}:$_count');
  }
}

// -- Special key widget -------------------------------------------------------

class _SpecialKeyWidget extends w.StatefulWidget {
  _SpecialKeyWidget({required this.onEscape});

  final void Function() onEscape;

  @override
  w.State createState() => _SpecialKeyWidgetState();
}

class _SpecialKeyWidgetState extends w.State<_SpecialKeyWidget> {
  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == terminal_keys.KeyType.escape) {
      widget.onEscape();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('press escape');
  }
}

// =============================================================================
// Example app reproduction widget (hit-test based, no zones)
// =============================================================================

class _ExampleApp extends w.StatefulWidget {
  _ExampleApp();

  @override
  w.State createState() => _ExampleAppState();
}

class _ExampleAppState extends w.State<_ExampleApp> {
  int _counter = 0;
  int _selectedTab = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final c = msg.key.char;
      if (c == '+' || c == '=') setState(() => _counter++);
      if (c == '-') setState(() => _counter--);
      if (c == '1') setState(() => _selectedTab = 0);
      if (c == '2') setState(() => _selectedTab = 1);
      if (c == '3') setState(() => _selectedTab = 2);
      if (c == '4') setState(() => _selectedTab = 3);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Text('Counter: $_counter'),
        w.Row(
          children: [
            for (var i = 0; i < 4; i++)
              w.GestureDetector(
                key: w.ValueKey<int>(i),
                onTap: () {
                  setState(() => _selectedTab = i);
                  return null;
                },
                child: w.Container(
                  padding: const w.EdgeInsets.symmetric(horizontal: 2),
                  child: w.Text(_tabLabel(i)),
                ),
              ),
          ],
        ),
        w.Text(_tabContentText(_selectedTab)),
      ],
    );
  }

  static String _tabLabel(int i) {
    const labels = ['Layout', 'Theme', 'Stack', 'Components'];
    return labels[i];
  }
}
