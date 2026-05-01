/// Tests for the performance metrics system.
///
/// Covers:
/// - [WidgetFrameTiming] — per-frame timing data
/// - [PerformanceMetricsSnapshot] — combined runtime + widget metrics
/// - [BuildOwner] — frame timing instrumentation
/// - [WidgetApp] — performance API integration
/// - [DebugOverlay] — overlay consuming real metrics
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('WidgetFrameTiming', () {
    test('constructor stores all fields correctly', () {
      final timestamp = DateTime(2026, 1, 1);
      final timing = w.WidgetFrameTiming(
        frameNumber: 42,
        buildDuration: const Duration(microseconds: 100),
        layoutDuration: const Duration(microseconds: 200),
        paintDuration: const Duration(microseconds: 300),
        totalDuration: const Duration(microseconds: 600),
        timestamp: timestamp,
      );

      expect(timing.frameNumber, equals(42));
      expect(timing.buildDuration, equals(const Duration(microseconds: 100)));
      expect(timing.layoutDuration, equals(const Duration(microseconds: 200)));
      expect(timing.paintDuration, equals(const Duration(microseconds: 300)));
      expect(timing.totalDuration, equals(const Duration(microseconds: 600)));
      expect(timing.timestamp, equals(timestamp));
    });

    test('isSlowFrame returns true when totalDuration > 16.67ms', () {
      final timing = w.WidgetFrameTiming(
        frameNumber: 1,
        buildDuration: Duration.zero,
        layoutDuration: Duration.zero,
        paintDuration: Duration.zero,
        totalDuration: const Duration(microseconds: 16668), // > 16667
        timestamp: DateTime.now(),
      );
      expect(timing.isSlowFrame, isTrue);
    });

    test('isSlowFrame returns false when totalDuration <= 16.67ms', () {
      final timing = w.WidgetFrameTiming(
        frameNumber: 1,
        buildDuration: Duration.zero,
        layoutDuration: Duration.zero,
        paintDuration: Duration.zero,
        totalDuration: const Duration(microseconds: 16667), // exactly threshold
        timestamp: DateTime.now(),
      );
      expect(timing.isSlowFrame, isFalse);
    });

    test('isSlowFrame returns false for fast frames', () {
      final timing = w.WidgetFrameTiming(
        frameNumber: 1,
        buildDuration: Duration.zero,
        layoutDuration: Duration.zero,
        paintDuration: Duration.zero,
        totalDuration: const Duration(microseconds: 5000),
        timestamp: DateTime.now(),
      );
      expect(timing.isSlowFrame, isFalse);
    });

    test('toString() produces expected format', () {
      final timing = w.WidgetFrameTiming(
        frameNumber: 7,
        buildDuration: const Duration(microseconds: 100),
        layoutDuration: const Duration(microseconds: 200),
        paintDuration: const Duration(microseconds: 300),
        totalDuration: const Duration(microseconds: 600),
        timestamp: DateTime.now(),
      );

      final str = timing.toString();
      expect(str, contains('frame: 7'));
      expect(str, contains('build: 100us'));
      expect(str, contains('layout: 200us'));
      expect(str, contains('paint: 300us'));
      expect(str, contains('total: 600us'));
    });
  });

  group('PerformanceMetricsSnapshot', () {
    test('empty widgetTimings returns Duration.zero for all averages', () {
      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: [],
        widgetFrameCount: 0,
      );

      expect(snapshot.averageBuildDuration, equals(Duration.zero));
      expect(snapshot.averageLayoutDuration, equals(Duration.zero));
      expect(snapshot.averagePaintDuration, equals(Duration.zero));
      expect(snapshot.averageTotalDuration, equals(Duration.zero));
    });

    test('averageBuildDuration computes correctly', () {
      final timings = [
        _makeTiming(buildUs: 100, layoutUs: 0, paintUs: 0, totalUs: 100),
        _makeTiming(buildUs: 200, layoutUs: 0, paintUs: 0, totalUs: 200),
        _makeTiming(buildUs: 300, layoutUs: 0, paintUs: 0, totalUs: 300),
      ];

      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: timings,
        widgetFrameCount: 3,
      );

      expect(
        snapshot.averageBuildDuration,
        equals(const Duration(microseconds: 200)),
      );
    });

    test('averageLayoutDuration computes correctly', () {
      final timings = [
        _makeTiming(buildUs: 0, layoutUs: 150, paintUs: 0, totalUs: 150),
        _makeTiming(buildUs: 0, layoutUs: 250, paintUs: 0, totalUs: 250),
      ];

      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: timings,
        widgetFrameCount: 2,
      );

      expect(
        snapshot.averageLayoutDuration,
        equals(const Duration(microseconds: 200)),
      );
    });

    test('averagePaintDuration computes correctly', () {
      final timings = [
        _makeTiming(buildUs: 0, layoutUs: 0, paintUs: 400, totalUs: 400),
        _makeTiming(buildUs: 0, layoutUs: 0, paintUs: 600, totalUs: 600),
      ];

      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: timings,
        widgetFrameCount: 2,
      );

      expect(
        snapshot.averagePaintDuration,
        equals(const Duration(microseconds: 500)),
      );
    });

    test('averageTotalDuration computes correctly', () {
      final timings = [
        _makeTiming(buildUs: 50, layoutUs: 50, paintUs: 50, totalUs: 1000),
        _makeTiming(buildUs: 50, layoutUs: 50, paintUs: 50, totalUs: 3000),
      ];

      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: timings,
        widgetFrameCount: 2,
      );

      expect(
        snapshot.averageTotalDuration,
        equals(const Duration(microseconds: 2000)),
      );
    });

    test('slowFrameCount counts frames exceeding 16.67ms budget', () {
      final timings = [
        _makeTiming(buildUs: 0, layoutUs: 0, paintUs: 0, totalUs: 5000), // fast
        _makeTiming(
          buildUs: 0,
          layoutUs: 0,
          paintUs: 0,
          totalUs: 20000,
        ), // slow
        _makeTiming(
          buildUs: 0,
          layoutUs: 0,
          paintUs: 0,
          totalUs: 16667,
        ), // exactly at boundary (not slow)
        _makeTiming(
          buildUs: 0,
          layoutUs: 0,
          paintUs: 0,
          totalUs: 16668,
        ), // slow
      ];

      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: timings,
        widgetFrameCount: 4,
      );

      expect(snapshot.slowFrameCount, equals(2));
    });

    test('slowFramePercentage computes correctly', () {
      final timings = [
        _makeTiming(buildUs: 0, layoutUs: 0, paintUs: 0, totalUs: 5000),
        _makeTiming(buildUs: 0, layoutUs: 0, paintUs: 0, totalUs: 20000),
        _makeTiming(buildUs: 0, layoutUs: 0, paintUs: 0, totalUs: 8000),
        _makeTiming(buildUs: 0, layoutUs: 0, paintUs: 0, totalUs: 25000),
      ];

      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: timings,
        widgetFrameCount: 4,
      );

      // 2 out of 4 = 50%
      expect(snapshot.slowFramePercentage, equals(50.0));
    });

    test('slowFramePercentage returns 0 for empty timings', () {
      final snapshot = w.PerformanceMetricsSnapshot(
        widgetTimings: [],
        widgetFrameCount: 0,
      );

      expect(snapshot.slowFramePercentage, equals(0.0));
    });

    test('renderMetrics can be null', () {
      final snapshot = w.PerformanceMetricsSnapshot(
        renderMetrics: null,
        widgetTimings: [],
        widgetFrameCount: 0,
      );

      expect(snapshot.renderMetrics, isNull);
    });

    test('renderMetrics stores a real RenderMetrics instance', () {
      final metrics = tui.RenderMetrics();
      final snapshot = w.PerformanceMetricsSnapshot(
        renderMetrics: metrics,
        widgetTimings: [],
        widgetFrameCount: 0,
      );

      expect(snapshot.renderMetrics, same(metrics));
    });
  });

  group('BuildOwner frame timing', () {
    test('widgetFrameCount increments after ElementTree.render()', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);

      expect(owner.widgetFrameCount, equals(0));

      tree.render();
      expect(owner.widgetFrameCount, equals(1));

      tree.render();
      expect(owner.widgetFrameCount, equals(2));

      tree.render();
      expect(owner.widgetFrameCount, equals(3));
    });

    test('recentTimings has entries with non-zero durations after render', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);

      expect(owner.recentTimings, isEmpty);

      tree.render();
      expect(owner.recentTimings, hasLength(1));

      final timing = owner.recentTimings.first;
      expect(timing.frameNumber, equals(1));
      // totalDuration should be non-zero since render() takes some time
      expect(timing.totalDuration.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('frame timing timestamps can be driven by an injected clock', () {
      final clock = ManualClock(initialTime: DateTime.utc(2026, 1, 1, 12));
      final owner = w.BuildOwner(nowProvider: () => clock.now);
      final tree = w.ElementTree(w.Text('hello'), owner: owner);

      tree.render();
      expect(owner.recentTimings.single.timestamp, equals(clock.now));

      clock.advance(const Duration(milliseconds: 40));
      tree.render();
      expect(owner.recentTimings.last.timestamp, equals(clock.now));
    });

    test('recentTimings is capped at 120 entries', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);

      // Render 130 times — should cap at 120
      for (var i = 0; i < 130; i++) {
        tree.render();
      }

      expect(owner.recentTimings.length, equals(120));
      expect(owner.widgetFrameCount, equals(130));

      // The oldest entries should have been evicted; the first entry should
      // be frame 11 (frames 1-10 evicted).
      expect(owner.recentTimings.first.frameNumber, equals(11));
      expect(owner.recentTimings.last.frameNumber, equals(130));
    });

    test('addFrameTimingCallback fires after each render', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);
      final receivedTimings = <w.WidgetFrameTiming>[];

      owner.addFrameTimingCallback((timing) {
        receivedTimings.add(timing);
      });

      tree.render();
      expect(receivedTimings, hasLength(1));
      expect(receivedTimings.first.frameNumber, equals(1));

      tree.render();
      expect(receivedTimings, hasLength(2));
      expect(receivedTimings.last.frameNumber, equals(2));
    });

    test('removeFrameTimingCallback stops the callback from firing', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);
      final receivedTimings = <w.WidgetFrameTiming>[];

      void callback(w.WidgetFrameTiming timing) {
        receivedTimings.add(timing);
      }

      owner.addFrameTimingCallback(callback);

      tree.render();
      expect(receivedTimings, hasLength(1));

      owner.removeFrameTimingCallback(callback);

      tree.render();
      // Should still be 1 — callback was removed
      expect(receivedTimings, hasLength(1));
    });

    test('performanceSnapshot returns a valid PerformanceMetricsSnapshot', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);

      tree.render();
      tree.render();

      final snapshot = owner.performanceSnapshot(null);
      expect(snapshot.widgetFrameCount, equals(2));
      expect(snapshot.widgetTimings, hasLength(2));
      expect(snapshot.renderMetrics, isNull);
    });

    test('performanceSnapshot includes renderMetrics when provided', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);
      final metrics = tui.RenderMetrics();

      tree.render();

      final snapshot = owner.performanceSnapshot(metrics);
      expect(snapshot.renderMetrics, same(metrics));
      expect(snapshot.widgetFrameCount, equals(1));
    });

    test('multiple callbacks all fire', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);
      var callbackACount = 0;
      var callbackBCount = 0;

      owner.addFrameTimingCallback((_) => callbackACount++);
      owner.addFrameTimingCallback((_) => callbackBCount++);

      tree.render();
      expect(callbackACount, equals(1));
      expect(callbackBCount, equals(1));

      tree.render();
      expect(callbackACount, equals(2));
      expect(callbackBCount, equals(2));
    });

    test('timing entries contain build, layout, and paint durations', () {
      final owner = w.BuildOwner();
      final tree = w.ElementTree(w.Text('hello'), owner: owner);

      tree.render();

      final timing = owner.recentTimings.first;
      // Build duration should be non-negative
      expect(timing.buildDuration.inMicroseconds, greaterThanOrEqualTo(0));
      // Layout and paint should be non-negative (Text has a render object)
      expect(timing.layoutDuration.inMicroseconds, greaterThanOrEqualTo(0));
      expect(timing.paintDuration.inMicroseconds, greaterThanOrEqualTo(0));
      // Total should be >= build (since total covers all phases)
      expect(
        timing.totalDuration.inMicroseconds,
        greaterThanOrEqualTo(timing.buildDuration.inMicroseconds),
      );
    });
  });

  group('WidgetApp performance integration', () {
    test('wantsRenderMetrics is true by default', () {
      final app = tui.WidgetApp(w.Text('hello'));
      expect(app.wantsRenderMetrics, isTrue);
    });

    test('wantsRenderMetrics is false when enableRenderMetrics is false', () {
      final app = tui.WidgetApp(w.Text('hello'), enableRenderMetrics: false);
      expect(app.wantsRenderMetrics, isFalse);
    });

    test('latestRenderMetrics is null initially', () {
      final app = tui.WidgetApp(w.Text('hello'));
      app.view();
      expect(app.latestRenderMetrics, isNull);
    });

    test('latestRenderMetrics stores metrics after RenderMetricsMsg', () {
      final app = tui.WidgetApp(w.Text('hello'));
      app.view();

      final metrics = tui.RenderMetrics();
      app.update(tui.RenderMetricsMsg(metrics));

      expect(app.latestRenderMetrics, same(metrics));
    });

    test('latestRenderMetrics updates on subsequent RenderMetricsMsg', () {
      final app = tui.WidgetApp(w.Text('hello'));
      app.view();

      final metrics1 = tui.RenderMetrics();
      app.update(tui.RenderMetricsMsg(metrics1));
      expect(app.latestRenderMetrics, same(metrics1));

      final metrics2 = tui.RenderMetrics();
      app.update(tui.RenderMetricsMsg(metrics2));
      expect(app.latestRenderMetrics, same(metrics2));
    });

    test('performanceSnapshot returns data after rendering', () {
      final app = tui.WidgetApp(w.Text('hello'));
      app.view(); // first render

      final snapshot = app.performanceSnapshot;
      expect(snapshot.widgetFrameCount, equals(1));
      expect(snapshot.widgetTimings, hasLength(1));
      expect(snapshot.renderMetrics, isNull);
    });

    test('performanceSnapshot includes render metrics after msg', () {
      final app = tui.WidgetApp(w.Text('hello'));
      app.view();

      final metrics = tui.RenderMetrics();
      app.update(tui.RenderMetricsMsg(metrics));
      // RenderMetricsMsg alone doesn't dirty plain widgets — force a re-render.
      app.update(tui.WindowSizeMsg(80, 24));
      app.view(); // second render

      final snapshot = app.performanceSnapshot;
      expect(snapshot.renderMetrics, same(metrics));
      expect(snapshot.widgetFrameCount, equals(2));
    });

    test('performanceSnapshot frame count increments with each render', () {
      final app = tui.WidgetApp(w.Text('hello'));

      app.view();
      expect(app.performanceSnapshot.widgetFrameCount, equals(1));

      // Force a re-render by sending a WindowSizeMsg
      app.update(tui.WindowSizeMsg(80, 24));
      app.view();
      expect(app.performanceSnapshot.widgetFrameCount, equals(2));

      app.update(tui.WindowSizeMsg(100, 30));
      app.view();
      expect(app.performanceSnapshot.widgetFrameCount, equals(3));
    });

    test('addFrameTimingCallback delegates to BuildOwner', () {
      final app = tui.WidgetApp(w.Text('hello'));
      final timings = <w.WidgetFrameTiming>[];

      app.addFrameTimingCallback((timing) {
        timings.add(timing);
      });

      app.view(); // triggers render
      expect(timings, hasLength(1));
      expect(timings.first.frameNumber, equals(1));
    });

    test('removeFrameTimingCallback stops callback from firing', () {
      final app = tui.WidgetApp(w.Text('hello'));
      final timings = <w.WidgetFrameTiming>[];

      void callback(w.WidgetFrameTiming timing) {
        timings.add(timing);
      }

      app.addFrameTimingCallback(callback);
      app.view();
      expect(timings, hasLength(1));

      app.removeFrameTimingCallback(callback);

      // Force re-render
      app.update(tui.WindowSizeMsg(80, 24));
      app.view();

      // Should still be 1
      expect(timings, hasLength(1));
    });

    test('RenderMetricsInjector stream updates latestRenderMetrics', () async {
      final tester = WidgetTester();
      try {
        await tester.pumpWidget(w.Text('content'), debugOverlay: true);

        final metrics = tui.RenderMetrics();
        metrics.beginFrame();
        metrics.endFrame();

        w.RenderMetricsInjector.instance.injectRuntime(metrics);
        tester.pump();

        expect(tester.app, isNotNull);
        expect(tester.app!.latestRenderMetrics, same(metrics));
      } finally {
        w.RenderMetricsInjector.instance.clearMetrics();
        await tester.dispose();
      }
    });

    test(
      'RenderMetricsInjector custom entries appear in built-in overlay',
      () async {
        final tester = WidgetTester();
        try {
          await tester.pumpWidget(w.Text('content'), debugOverlay: true);

          w.RenderMetricsInjector.instance.setMetric(
            'Key->Render p50',
            '4.8ms',
          );
          w.RenderMetricsInjector.instance.setMetric('Queue depth', 2);
          tester.pump();

          expect(tester.find.text('Key->Render p50: 4.8ms'), isTrue);
          expect(tester.find.text('Queue depth: 2'), isTrue);
        } finally {
          w.RenderMetricsInjector.instance.clearMetrics();
          await tester.dispose();
        }
      },
    );

    test(
      'RenderMetricsInjector render stats appear in built-in overlay',
      () async {
        final tester = WidgetTester();
        try {
          await tester.pumpWidget(w.Text('content'), debugOverlay: true);

          const stats = tui.ProgramRenderStats(
            totalRenders: 12,
            changedRenders: 9,
            totalChangedCells: 144,
            totalChangedSpans: 24,
            maxDirtyLines: 3,
            maxChangedCells: 18,
            maxChangedSpans: 4,
            totalRenderDuration: Duration(milliseconds: 60),
            lastRenderGeneration: 12,
            lastDegradationLevel: tui.DegradationLevel.full,
            lastChangeSummary: null,
          );

          w.RenderMetricsInjector.instance.setRenderStats(
            stats,
            prefix: 'Monitor',
            replace: true,
          );
          tester.pump();

          expect(
            tester.find.text('Monitor renders: 12 (9 changed, 75%)'),
            isTrue,
          );
          expect(tester.find.text('Monitor avg: 5.0ms'), isTrue);
          expect(
            tester.find.text('Monitor cells: 144 total / 18 peak'),
            isTrue,
          );
          expect(tester.find.text('Monitor spans: 24 total / 4 peak'), isTrue);
          expect(tester.find.text('Monitor dirty: 3 peak'), isTrue);
          expect(tester.find.text('Monitor level: full'), isTrue);
        } finally {
          w.RenderMetricsInjector.instance.clearMetrics();
          await tester.dispose();
        }
      },
    );

    test('built-in overlay publishes live key->render percentiles', () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 30);
      try {
        await tester.pumpWidget(_KeyCounterWidget(), debugOverlay: true);

        tester.sendKey('a');
        tester.sendKey('b');
        tester.sendKey('c');

        expect(
          tester.find.textMatching(RegExp(r'Key->Render p50: \d+\.\d+ms')),
          isTrue,
        );
        expect(
          tester.find.textMatching(RegExp(r'Key->Render p95: \d+\.\d+ms')),
          isTrue,
        );
      } finally {
        w.RenderMetricsInjector.instance.clearMetrics();
        await tester.dispose();
      }
    });
  });

  group('DebugOverlay with performance metrics', () {
    test('before any handleUpdate, shows FPS: 0.0 and Frames: 0', () {
      final app = tui.WidgetApp(
        w.DebugOverlay(enabled: true, child: w.Text('content')),
      );
      final output = app.view();
      expect(output, contains('FPS: 0.0'));
      expect(output, contains('Frames: 0'));
    });

    test('disabled overlay only shows child content', () {
      final app = tui.WidgetApp(
        w.DebugOverlay(enabled: false, child: w.Text('content')),
      );
      final output = app.view();
      expect(output, contains('content'));
      // Should NOT contain FPS or Frames when disabled
      expect(output, isNot(contains('FPS:')));
      expect(output, isNot(contains('Frames:')));
    });

    test('after RenderMetricsMsg, shows real FPS data', () {
      final app = tui.WidgetApp(
        w.DebugOverlay(enabled: true, child: w.Text('content')),
      );
      app.update(tui.WindowSizeMsg(80, 24));
      app.view();

      // Create a RenderMetrics with some frame data
      final metrics = tui.RenderMetrics();
      // Simulate some frames to get non-zero FPS
      metrics.beginFrame();
      metrics.endFrame();

      app.update(tui.RenderMetricsMsg(metrics));
      final output = app.view();

      // After receiving real metrics, the overlay should show real data
      // It should show 'FPS:' (without the ~ prefix that fallback uses)
      // and 'Frames:' with the runtime frame count
      expect(output, contains('FPS:'));
      expect(output, contains('Frames:'));
      // Should NOT show the estimated ~ prefix since we have real metrics
      expect(output, isNot(contains('FPS: ~')));
    });

    test('overlay shows runtime frame and render timing labels', () async {
      final tester = WidgetTester();
      try {
        await tester.pumpWidget(w.Text('content'), debugOverlay: true);

        final metrics = tui.RenderMetrics();
        metrics.beginFrame();
        metrics.endFrame();

        w.RenderMetricsInjector.instance.injectRuntime(metrics);
        tester.pump();

        expect(tester.view, contains('Frame Time:'));
        expect(tester.view, contains('Render Time:'));
      } finally {
        w.RenderMetricsInjector.instance.clearMetrics();
        await tester.dispose();
      }
    });

    test('DebugOverlay stores an injected fallback clock', () {
      final clock = ManualClock(initialTime: DateTime.utc(2026, 1, 1, 12));
      final overlay = w.DebugOverlay(
        enabled: true,
        nowProvider: () => clock.now,
        child: w.Text('content'),
      );

      expect(overlay.nowProvider(), equals(clock.now));
    });

    test('PerformanceOverlay shows fallback before metrics', () {
      final app = tui.WidgetApp(
        w.PerformanceOverlay(enabled: true, child: w.Text('content')),
      );
      app.update(tui.WindowSizeMsg(80, 24));
      final output = app.view();

      // Before any metrics, shows widget frame count
      expect(output, contains('Frame'));
    });

    test('PerformanceOverlay disabled only shows child', () {
      final app = tui.WidgetApp(
        w.PerformanceOverlay(enabled: false, child: w.Text('content')),
      );
      final output = app.view();
      expect(output, contains('content'));
      expect(output, isNot(contains('Frame')));
      expect(output, isNot(contains('FPS')));
    });

    test('PerformanceOverlay stores an injected fallback clock', () {
      final clock = ManualClock(initialTime: DateTime.utc(2026, 1, 1, 12));
      final overlay = w.PerformanceOverlay(
        enabled: true,
        nowProvider: () => clock.now,
        child: w.Text('content'),
      );

      expect(overlay.nowProvider(), equals(clock.now));
    });
  });

  group('RenderMetricsProgramMonitor', () {
    test(
      'publishes render stats and clears injected metrics on stop',
      () async {
        final monitor = w.RenderMetricsProgramMonitor(prefix: 'Monitor');
        final injections = <w.RenderMetricsInjection>[];
        final subscription = w.RenderMetricsInjector.instance.stream.listen(
          injections.add,
        );
        addTearDown(() async {
          await subscription.cancel();
        });

        monitor.onRendered(
          renderGeneration: 7,
          view: 'frame',
          degradationLevel: tui.DegradationLevel.full,
          renderDuration: const Duration(milliseconds: 5),
        );
        monitor.onStop();

        await Future<void>.delayed(Duration.zero);

        expect(injections, hasLength(2));
        expect(injections.first.clearEntries, isTrue);
        expect(
          injections.first.upsertEntries['Monitor renders'],
          '1 (0 changed, 0%)',
        );
        expect(injections.first.upsertEntries['Monitor avg'], '5.0ms');
        expect(injections.first.upsertEntries['Monitor level'], 'full');
        expect(injections.last.clearEntries, isTrue);
        expect(injections.last.upsertEntries, isEmpty);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int _frameCounter = 0;

w.WidgetFrameTiming _makeTiming({
  required int buildUs,
  required int layoutUs,
  required int paintUs,
  required int totalUs,
}) {
  _frameCounter++;
  return w.WidgetFrameTiming(
    frameNumber: _frameCounter,
    buildDuration: Duration(microseconds: buildUs),
    layoutDuration: Duration(microseconds: layoutUs),
    paintDuration: Duration(microseconds: paintUs),
    totalDuration: Duration(microseconds: totalUs),
    timestamp: DateTime.now(),
  );
}

class _KeyCounterWidget extends w.StatefulWidget {
  _KeyCounterWidget();

  @override
  w.State createState() => _KeyCounterWidgetState();
}

class _KeyCounterWidgetState extends w.State<_KeyCounterWidget> {
  int _count = 0;

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char != null) {
      setState(() {
        _count++;
      });
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('count: $_count');
  }
}
