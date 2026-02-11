library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ScrollArea — constructor / properties
  // ---------------------------------------------------------------------------
  group('ScrollArea properties', () {
    test('constructor stores all parameters', () {
      final ctrl = WidgetScrollController();
      final sa = ScrollArea(
        child: Text('content'),
        width: 20,
        height: 10,
        showScrollbar: false,
        controller: ctrl,
        padding: EdgeInsets.all(1),
      );
      expect(sa.width, equals(20));
      expect(sa.height, equals(10));
      expect(sa.showScrollbar, isFalse);
      expect(sa.controller, same(ctrl));
      expect(sa.padding, isNotNull);
    });

    test('defaults are correct', () {
      final sa = ScrollArea(child: Text('x'));
      expect(sa.width, isNull);
      expect(sa.height, isNull);
      expect(sa.showScrollbar, isTrue);
      expect(sa.controller, isNull);
      expect(sa.padding, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ScrollArea — rendering
  // ---------------------------------------------------------------------------
  group('ScrollArea rendering', () {
    test('renders child content', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          ScrollArea(width: 20, height: 5, child: Text('Scrollable content')),
        );
        expect(tester.find.text('Scrollable content'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with explicit dimensions', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        final longContent = List.generate(20, (i) => 'Item $i').join('\n');
        await tester.pumpWidget(
          ScrollArea(width: 20, height: 5, child: Text(longContent)),
        );
        // Should show first items
        expect(tester.find.text('Item 0'), isTrue);
        // Items beyond viewport should not be visible
        expect(tester.find.text('Item 15'), isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with WidgetScrollController', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        final ctrl = WidgetScrollController();
        await tester.pumpWidget(
          ScrollArea(
            width: 20,
            height: 5,
            controller: ctrl,
            child: Text('With controller'),
          ),
        );
        expect(tester.find.text('With controller'), isTrue);
        expect(ctrl.offset, equals(0));
      } finally {
        await tester.dispose();
      }
    });

    test('renders with showScrollbar false', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          ScrollArea(
            width: 20,
            height: 5,
            showScrollbar: false,
            child: Text('No bar'),
          ),
        );
        expect(tester.find.text('No bar'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders with padding', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          ScrollArea(
            width: 20,
            height: 5,
            padding: EdgeInsets.all(1),
            child: Text('Padded'),
          ),
        );
        final pos = tester.locateText('Padded');
        expect(pos, isNotNull);
        // Padding should push content inward
        expect(pos!.x, greaterThanOrEqualTo(1));
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ScrollArea — layout integration
  // ---------------------------------------------------------------------------
  group('ScrollArea layout integration', () {
    test('inside Container', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 25,
            height: 8,
            child: ScrollArea(width: 20, height: 5, child: Text('Nested')),
          ),
        );
        expect(tester.find.text('Nested'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('inside Column with siblings', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 15);
      try {
        await tester.pumpWidget(
          Column(
            children: [
              Text('Header'),
              ScrollArea(width: 20, height: 3, child: Text('Scroll content')),
              Text('Footer'),
            ],
          ),
        );
        expect(tester.find.text('Header'), isTrue);
        expect(tester.find.text('Scroll content'), isTrue);
        expect(tester.find.text('Footer'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });
}
