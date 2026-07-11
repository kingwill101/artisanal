/// Tests for the F12 debug overlay toggle in [WidgetApp].
///
/// Covers:
/// - F12 toggles the built-in debug overlay on and off
/// - F12 is consumed (not forwarded to child widgets)
/// - [WidgetApp.debugOverlayEnabled] getter tracks toggle state
/// - `debugOverlay: true` starts with overlay visible
/// - `debugOverlay: false` starts without overlay, F12 enables it
/// - User content is preserved through F12 toggles
/// - [DebugOverlayPosition] variants are honoured
/// - Overlay survives [WindowSizeMsg]
/// - User-provided [DebugOverlay] is not interfered with by F12
/// - Full pipeline test via [WidgetTester.sendSpecialKey]
library;

import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart' hide Key;
import 'package:test/test.dart';

void main() {
  group('WidgetApp F12 debug overlay toggle', () {
    group('debugOverlay: true (starts enabled)', () {
      test('overlay is visible in initial render', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        final output = app.view();

        expect(output, contains('FPS:'), reason: 'overlay should show FPS');
        expect(output, contains('hello'), reason: 'user content should show');
      });

      test('debugOverlayEnabled getter is true initially', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        expect(app.debugOverlayEnabled, isTrue);
      });

      test('F12 disables the overlay', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Toggle off
        app.update(KeyMsg(const Key(KeyType.f12)));
        final output = app.view();

        expect(app.debugOverlayEnabled, isFalse);
        expect(
          output,
          isNot(contains('FPS:')),
          reason: 'overlay should be hidden after F12',
        );
        expect(
          output,
          contains('hello'),
          reason: 'user content should still be visible',
        );
      });

      test('F12 twice re-enables the overlay', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Toggle off
        app.update(KeyMsg(const Key(KeyType.f12)));
        expect(app.debugOverlayEnabled, isFalse);

        // Toggle back on
        app.update(KeyMsg(const Key(KeyType.f12)));
        final output = app.view();

        expect(app.debugOverlayEnabled, isTrue);
        expect(
          output,
          contains('FPS:'),
          reason: 'overlay should reappear after second F12',
        );
      });
    });

    group('debugOverlay: false (starts disabled)', () {
      test('overlay is not visible in initial render', () {
        final app = WidgetApp(Text('hello'), debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        final output = app.view();

        expect(
          output,
          isNot(contains('FPS:')),
          reason: 'overlay should not show when disabled',
        );
        expect(output, contains('hello'));
      });

      test('debugOverlayEnabled getter is false initially', () {
        final app = WidgetApp(Text('hello'), debugOverlay: false);
        expect(app.debugOverlayEnabled, isFalse);
      });

      test('F12 enables the overlay on the fly', () {
        final app = WidgetApp(Text('hello'), debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Toggle on
        app.update(KeyMsg(const Key(KeyType.f12)));
        final output = app.view();

        expect(app.debugOverlayEnabled, isTrue);
        expect(
          output,
          contains('FPS:'),
          reason: 'overlay should appear after F12',
        );
        expect(output, contains('hello'));
      });

      test('default (no debugOverlay param) starts disabled', () {
        final app = WidgetApp(Text('hello'));
        expect(app.debugOverlayEnabled, isFalse);

        app.update(WindowSizeMsg(80, 24));
        final output = app.view();
        expect(output, isNot(contains('FPS:')));
      });
    });

    group('F12 event consumption', () {
      test('F12 is consumed and not forwarded to child widgets', () {
        // Use a StatefulWidget that tracks whether it received F12
        final app = WidgetApp(_F12Tracker(), debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Send F12
        app.update(KeyMsg(const Key(KeyType.f12)));
        final output = app.view();

        // The _F12Tracker widget should NOT have received the F12 event
        expect(
          output,
          isNot(contains('F12_RECEIVED')),
          reason: 'F12 should be consumed by WidgetApp, not forwarded',
        );
      });

      test('non-F12 keys are forwarded to child widgets', () {
        final app = WidgetApp(_F12Tracker(), debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Send a regular key — should be forwarded
        app.update(
          KeyMsg(
            const Key(KeyType.runes, runes: [0x61]), // 'a'
          ),
        );
        final output = app.view();

        expect(
          output,
          contains('KEY_RECEIVED'),
          reason: 'non-F12 keys should be forwarded to child',
        );
      });
    });

    group('DebugOverlayPosition', () {
      test('debugOverlayPosition: topRight (default) is accepted', () {
        final app = WidgetApp(
          Text('hello'),
          debugOverlay: true,
          debugOverlayPosition: DebugOverlayPosition.topRight,
        );
        app.update(WindowSizeMsg(80, 24));
        final output = app.view();

        expect(output, contains('FPS:'));
        expect(output, contains('hello'));
      });

      test('debugOverlayPosition: topLeft is accepted', () {
        final app = WidgetApp(
          Text('hello'),
          debugOverlay: true,
          debugOverlayPosition: DebugOverlayPosition.topLeft,
        );
        app.update(WindowSizeMsg(80, 24));
        final output = app.view();

        expect(output, contains('FPS:'));
      });

      test('debugOverlayPosition: bottomLeft is accepted', () {
        final app = WidgetApp(
          Text('hello'),
          debugOverlay: true,
          debugOverlayPosition: DebugOverlayPosition.bottomLeft,
        );
        app.update(WindowSizeMsg(80, 24));
        final output = app.view();

        expect(output, contains('FPS:'));
      });

      test('debugOverlayPosition: bottomRight is accepted', () {
        final app = WidgetApp(
          Text('hello'),
          debugOverlay: true,
          debugOverlayPosition: DebugOverlayPosition.bottomRight,
        );
        app.update(WindowSizeMsg(80, 24));
        final output = app.view();

        expect(output, contains('FPS:'));
      });

      test('position is preserved across F12 toggle cycles', () {
        final app = WidgetApp(
          Text('hello'),
          debugOverlay: true,
          debugOverlayPosition: DebugOverlayPosition.bottomLeft,
        );
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Toggle off then on
        app.update(KeyMsg(const Key(KeyType.f12)));
        app.update(KeyMsg(const Key(KeyType.f12)));
        final output = app.view();

        // Overlay should still be showing (position is stored in WidgetApp)
        expect(output, contains('FPS:'));
      });
    });

    group('overlay survives window resize', () {
      test('enabled overlay persists after WindowSizeMsg', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Resize
        app.update(WindowSizeMsg(120, 40));
        final output = app.view();

        expect(app.debugOverlayEnabled, isTrue);
        expect(output, contains('FPS:'));
        expect(output, contains('hello'));
      });

      test('F12-toggled overlay persists after WindowSizeMsg', () {
        final app = WidgetApp(Text('hello'), debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Enable via F12
        app.update(KeyMsg(const Key(KeyType.f12)));
        app.view();
        expect(app.debugOverlayEnabled, isTrue);

        // Resize — overlay should survive
        app.update(WindowSizeMsg(120, 40));
        final output = app.view();

        expect(app.debugOverlayEnabled, isTrue);
        expect(output, contains('FPS:'));
      });

      test('disabled overlay stays disabled after WindowSizeMsg', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Disable via F12
        app.update(KeyMsg(const Key(KeyType.f12)));
        expect(app.debugOverlayEnabled, isFalse);

        // Resize — overlay should stay disabled
        app.update(WindowSizeMsg(120, 40));
        final output = app.view();

        expect(app.debugOverlayEnabled, isFalse);
        expect(output, isNot(contains('FPS:')));
      });
    });

    group('user-provided DebugOverlay is not affected by F12', () {
      test('user DebugOverlay passes through _currentRoot() untouched', () {
        // User wraps their root in their own DebugOverlay (no _debugOverlayKey)
        final userOverlay = DebugOverlay(
          enabled: true,
          child: Text('user content'),
        );
        final app = WidgetApp(userOverlay, debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        final output = app.view();

        expect(
          output,
          contains('FPS:'),
          reason: 'user-provided overlay should show',
        );
        expect(output, contains('user content'));
      });

      test('F12 adds WidgetApp overlay on top of user overlay', () {
        final userOverlay = DebugOverlay(
          enabled: true,
          child: Text('user content'),
        );
        final app = WidgetApp(userOverlay, debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // F12 enables the WidgetApp-managed overlay
        app.update(KeyMsg(const Key(KeyType.f12)));
        final output = app.view();

        // Both the user overlay and the WidgetApp overlay should be present
        expect(output, contains('user content'));
        expect(app.debugOverlayEnabled, isTrue);
      });

      test('F12 toggle does not strip user DebugOverlay', () {
        final userOverlay = DebugOverlay(
          enabled: true,
          child: Text('user content'),
        );
        final app = WidgetApp(userOverlay, debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));

        // Toggle on then off
        app.update(KeyMsg(const Key(KeyType.f12)));
        app.update(KeyMsg(const Key(KeyType.f12)));
        final output = app.view();

        // User overlay should still be there
        expect(output, contains('user content'));
        expect(
          output,
          contains('FPS:'),
          reason: 'user-provided overlay should survive F12 cycles',
        );
      });
    });

    group('overlay shows FPS data with RenderMetricsMsg', () {
      test('built-in overlay updates when receiving RenderMetricsMsg', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        final metrics = RenderMetrics();
        metrics.beginFrame();
        metrics.endFrame();

        app.update(RenderMetricsMsg(metrics));
        final output = app.view();

        expect(output, contains('FPS:'));
        expect(output, contains('Frames:'));
        // Should have real metrics, not fallback ~estimated
        expect(output, isNot(contains('FPS: ~')));
      });

      test('overlay shows frame and render timing labels', () {
        final app = WidgetApp(Text('hello'), debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        final metrics = RenderMetrics();
        metrics.beginFrame();
        metrics.endFrame();

        app.update(RenderMetricsMsg(metrics));
        final output = app.view();

        expect(output, contains('Frame Time:'));
        expect(output, contains('Render Time:'));
      });

      test('built-in overlay updates without rebuilding child subtree', () {
        final counter = _BuildCounter();
        final app = WidgetApp(counter, debugOverlay: true);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        final buildsBefore = counter.buildCount;
        expect(buildsBefore, greaterThan(0));

        final metrics = RenderMetrics();
        metrics.beginFrame();
        metrics.endFrame();

        app.update(RenderMetricsMsg(metrics));
        final output = app.view();

        expect(output, contains('FPS:'));
        expect(counter.buildCount, equals(buildsBefore));
      });

      test(
        'built-in overlay continues updating when the same metrics object mutates during mouse motion',
        () {
          final app = WidgetApp(Text('hello'), debugOverlay: true);
          app.update(WindowSizeMsg(80, 24));
          app.view();

          final metrics = RenderMetrics();
          metrics.beginFrame();
          metrics.endFrame();

          app.update(RenderMetricsMsg(metrics));
          final firstOutput = _stripAnsi(app.view());
          expect(firstOutput, contains('Frames: 1'));

          app.update(
            const MouseMsg(
              action: MouseAction.motion,
              button: MouseButton.none,
              x: 10,
              y: 4,
            ),
          );
          app.view();

          metrics.beginFrame();
          metrics.endFrame();

          app.update(RenderMetricsMsg(metrics));
          final secondOutput = _stripAnsi(app.view());

          expect(secondOutput, contains('Frames: 2'));
          expect(secondOutput, isNot(equals(firstOutput)));
        },
      );
    });

    group('rapid F12 toggling', () {
      test('multiple rapid toggles do not corrupt state', () {
        final app = WidgetApp(Text('hello'), debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Toggle 10 times
        for (var i = 0; i < 10; i++) {
          app.update(KeyMsg(const Key(KeyType.f12)));
        }

        // Even number of toggles → back to original (false)
        expect(app.debugOverlayEnabled, isFalse);
        final output = app.view();
        expect(output, isNot(contains('FPS:')));
        expect(output, contains('hello'));
      });

      test('odd number of toggles enables overlay', () {
        final app = WidgetApp(Text('hello'), debugOverlay: false);
        app.update(WindowSizeMsg(80, 24));
        app.view();

        // Toggle 7 times
        for (var i = 0; i < 7; i++) {
          app.update(KeyMsg(const Key(KeyType.f12)));
        }

        // Odd number of toggles → enabled
        expect(app.debugOverlayEnabled, isTrue);
        final output = app.view();
        expect(output, contains('FPS:'));
      });
    });
  });

  group('WidgetTester F12 integration', () {
    test('sendSpecialKey(f12) toggles debug overlay via full pipeline', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text('tester content'),
        debugOverlay: true,
        width: 80,
        height: 24,
      );

      // Overlay should be visible
      expect(
        tester.find.text('FPS:'),
        isTrue,
        reason:
            'overlay should be visible after pumpWidget with debugOverlay: true',
      );
      expect(tester.find.text('tester content'), isTrue);

      // Toggle off via F12
      tester.sendSpecialKey(KeyType.f12);

      expect(
        tester.find.text('FPS:'),
        isFalse,
        reason: 'overlay should be hidden after F12',
      );
      expect(
        tester.find.text('tester content'),
        isTrue,
        reason: 'user content should remain',
      );

      // Toggle back on via F12
      tester.sendSpecialKey(KeyType.f12);

      expect(
        tester.find.text('FPS:'),
        isTrue,
        reason: 'overlay should reappear after second F12',
      );
    });

    test(
      'pumpWidget with debugOverlay: false starts without overlay',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Text('no overlay'),
          debugOverlay: false,
          width: 80,
          height: 24,
        );

        expect(tester.find.text('FPS:'), isFalse);
        expect(tester.find.text('no overlay'), isTrue);
      },
    );

    test('F12 enables overlay from disabled state via tester', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text('content'),
        debugOverlay: false,
        width: 80,
        height: 24,
      );

      expect(tester.find.text('FPS:'), isFalse);

      tester.sendSpecialKey(KeyType.f12);

      expect(
        tester.find.text('FPS:'),
        isTrue,
        reason: 'F12 should enable overlay even when started disabled',
      );
    });

    test('overlay survives tester.resize()', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text('resizable'),
        debugOverlay: true,
        width: 80,
        height: 24,
      );

      expect(tester.find.text('FPS:'), isTrue);

      tester.resize(120, 40);

      expect(
        tester.find.text('FPS:'),
        isTrue,
        reason: 'overlay should survive resize',
      );
      expect(tester.find.text('resizable'), isTrue);
    });

    test('debugOverlayPosition parameter is passed to WidgetApp', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Text('positioned'),
        debugOverlay: true,
        debugOverlayPosition: DebugOverlayPosition.bottomLeft,
        width: 80,
        height: 24,
      );

      // Overlay should be visible regardless of position
      expect(tester.find.text('FPS:'), isTrue);
      expect(tester.find.text('positioned'), isTrue);
    });
  });
}

String _stripAnsi(Object value) {
  return value.toString().replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
}

// ---------------------------------------------------------------------------
// Test helper widgets
// ---------------------------------------------------------------------------

/// A widget that tracks whether it received an F12 key event or any other key.
class _F12Tracker extends StatefulWidget {
  _F12Tracker();

  @override
  State<_F12Tracker> createState() => _F12TrackerState();
}

class _F12TrackerState extends State<_F12Tracker> {
  String _status = 'NO_KEY';

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg) {
      if (msg.key.type == KeyType.f12) {
        setState(() => _status = 'F12_RECEIVED');
      } else {
        setState(() => _status = 'KEY_RECEIVED');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Text(_status);
  }
}

class _BuildCounter extends StatefulWidget {
  _BuildCounter();

  int buildCount = 0;

  @override
  State<_BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<_BuildCounter> {
  @override
  Widget build(BuildContext context) {
    widget.buildCount += 1;
    return Text('BUILD_COUNT:${widget.buildCount}');
  }
}
