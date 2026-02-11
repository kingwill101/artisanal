/// Tests for the MouseRegion widget.
///
/// MouseRegion is a StatelessWidget wrapper around GestureDetector that only
/// hooks onEnter/onExit callbacks with captureMouse: false. Tests verify hover
/// behavior, enabled/disabled, and child rendering.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Constructor / defaults
  // ---------------------------------------------------------------------------

  group('constructor', () {
    test('creates with required child', () {
      final region = w.MouseRegion(child: w.Text('content'));
      expect(region.child, isA<w.Text>());
      expect(region.enabled, isTrue);
      expect(region.onEnter, isNull);
      expect(region.onExit, isNull);
    });

    test('accepts all optional parameters', () {
      final region = w.MouseRegion(
        child: w.Text('content'),
        onEnter: (_) => null,
        onExit: (_) => null,
        enabled: false,
      );
      expect(region.enabled, isFalse);
      expect(region.onEnter, isNotNull);
      expect(region.onExit, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  group('rendering', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(w.MouseRegion(child: w.Text('hover-me')));

      expect(tester.find.text('hover-me'), isTrue);
    });

    test('renders complex child tree', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.MouseRegion(
          child: w.Column(children: [w.Text('row-a'), w.Text('row-b')]),
        ),
      );

      expect(tester.find.text('row-a'), isTrue);
      expect(tester.find.text('row-b'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // onEnter / onExit
  // ---------------------------------------------------------------------------

  group('onEnter / onExit', () {
    test('onEnter fires on mouse motion within bounds', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.MouseRegion(
          onEnter: (_) {
            enterCount++;
            return null;
          },
          child: w.Text('region'),
        ),
      );

      tester.mouseMove(0, 0);
      expect(enterCount, equals(1));
    });

    test('onEnter fires once for repeated motions', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.MouseRegion(
          onEnter: (_) {
            enterCount++;
            return null;
          },
          child: w.Text('region'),
        ),
      );

      tester.mouseMove(0, 0);
      tester.mouseMove(1, 0);
      tester.mouseMove(2, 0);
      expect(enterCount, equals(1));
    });

    test('onEnter and onExit both provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final events = <String>[];
      await tester.pumpWidget(
        w.MouseRegion(
          onEnter: (_) {
            events.add('enter');
            return null;
          },
          onExit: (_) {
            events.add('exit');
            return null;
          },
          child: w.Text('region'),
        ),
      );

      tester.mouseMove(0, 0);
      expect(events, contains('enter'));
    });
  });

  // ---------------------------------------------------------------------------
  // enabled / disabled
  // ---------------------------------------------------------------------------

  group('enabled / disabled', () {
    test('enabled=false suppresses hover callbacks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.MouseRegion(
          enabled: false,
          onEnter: (_) {
            enterCount++;
            return null;
          },
          child: w.Text('disabled-region'),
        ),
      );

      tester.mouseMove(0, 0);
      expect(enterCount, equals(0));
    });

    test('enabled=false still renders child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.MouseRegion(enabled: false, child: w.Text('still-visible')),
      );

      expect(tester.find.text('still-visible'), isTrue);
    });

    test('enabled=true allows hover callbacks', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.MouseRegion(
          enabled: true,
          onEnter: (_) {
            enterCount++;
            return null;
          },
          child: w.Text('enabled-region'),
        ),
      );

      tester.mouseMove(0, 0);
      expect(enterCount, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // captureMouse behavior
  // ---------------------------------------------------------------------------

  group('captureMouse', () {
    test(
      'MouseRegion does not capture mouse (no tap/drag callbacks)',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        // MouseRegion wraps GestureDetector with captureMouse: false.
        // It should not interfere with taps — only hover is wired.
        var enterCount = 0;
        await tester.pumpWidget(
          w.MouseRegion(
            onEnter: (_) {
              enterCount++;
              return null;
            },
            child: w.Text('no-capture'),
          ),
        );

        // Tap should work normally (no capture interference).
        tester.tapAt(0, 0);
        // Move after tap to trigger enter.
        tester.mouseMove(0, 0);
        expect(enterCount, greaterThanOrEqualTo(1));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Inside layout containers
  // ---------------------------------------------------------------------------

  group('layout integration', () {
    test('works inside Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var enterCount = 0;
      await tester.pumpWidget(
        w.Container(
          width: 30,
          height: 5,
          child: w.MouseRegion(
            onEnter: (_) {
              enterCount++;
              return null;
            },
            child: w.Text('in-container'),
          ),
        ),
      );

      expect(tester.find.text('in-container'), isTrue);
      tester.mouseMove(0, 0);
      expect(enterCount, equals(1));
    });

    test('works inside Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Row(
          children: [
            w.MouseRegion(child: w.Text('item-a')),
            w.MouseRegion(child: w.Text('item-b')),
          ],
        ),
      );

      expect(tester.find.text('item-a'), isTrue);
      expect(tester.find.text('item-b'), isTrue);
    });
  });
}
