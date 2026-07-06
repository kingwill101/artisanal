library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ConstrainedBox — constructor
  // ---------------------------------------------------------------------------
  group('ConstrainedBox constructor', () {
    test('stores constraints', () {
      final c = BoxConstraints(maxWidth: 10, maxHeight: 5);
      final cb = ConstrainedBox(constraints: c, child: Text('x'));
      expect(cb.constraints, same(c));
    });

    test('child is optional', () {
      final cb = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 10, maxHeight: 5),
      );
      expect(cb.child, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ConstrainedBox — width constraint
  // ---------------------------------------------------------------------------
  group('ConstrainedBox width constraint', () {
    test('truncates content wider than maxWidth', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 5),
            child: Text('ABCDEFGHIJ'),
          ),
        );
        // The 10-char text should be truncated by constrainContent
        // using Layout.truncateLines with ellipsis='...'
        // Full 10-char text should NOT appear
        expect(tester.find.text('ABCDEFGHIJ'), isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('content shorter than maxWidth renders normally', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 20),
            child: Text('Short'),
          ),
        );
        expect(tester.find.text('Short'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('unbounded width does not truncate', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(),
            child: Text('NoTruncation'),
          ),
        );
        expect(tester.find.text('NoTruncation'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ConstrainedBox — height constraint
  // ---------------------------------------------------------------------------
  group('ConstrainedBox height constraint', () {
    test('truncates content taller than maxHeight', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        final longContent = List.generate(10, (i) => 'Line$i').join('\n');
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 3),
            child: Text(longContent),
          ),
        );
        expect(tester.find.text('Line0'), isTrue);
        expect(tester.find.text('Line1'), isTrue);
        expect(tester.find.text('Line2'), isTrue);
        // Lines beyond maxHeight should be truncated
        expect(tester.find.text('Line5'), isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('content shorter than maxHeight renders normally', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 10),
            child: Text('Line1\nLine2'),
          ),
        );
        expect(tester.find.text('Line1'), isTrue);
        expect(tester.find.text('Line2'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ConstrainedBox — combined constraints
  // ---------------------------------------------------------------------------
  group('ConstrainedBox combined constraints', () {
    test('constrains both width and height', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        final longContent = List.generate(10, (i) => 'ABCDEFGHIJ').join('\n');
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 5, maxHeight: 3),
            child: Text(longContent),
          ),
        );
        final view = tester.view;
        final lines = view
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        expect(lines.length, lessThanOrEqualTo(3));
      } finally {
        await tester.dispose();
      }
    });

    test('zero width returns empty', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 0),
            child: Text('Hidden'),
          ),
        );
        expect(tester.find.text('Hidden'), isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('zero height returns empty', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 0),
            child: Text('Hidden'),
          ),
        );
        expect(tester.find.text('Hidden'), isFalse);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ConstrainedBox — no child
  // ---------------------------------------------------------------------------
  group('ConstrainedBox without child', () {
    test('renders empty when no child', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 10, maxHeight: 5),
          ),
        );
        // Should render without error
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ConstrainedBox — layout integration
  // ---------------------------------------------------------------------------
  group('ConstrainedBox layout integration', () {
    test('inside Container', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 30,
            height: 5,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 10),
              child: Text('Constrained'),
            ),
          ),
        );
        // Content should be visible but constrained
        final view = tester.view;
        expect(view, isNotEmpty);
      } finally {
        await tester.dispose();
      }
    });

    test('inside Row with siblings', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 5),
                child: Text('ABC'),
              ),
              Text('After'),
            ],
          ),
        );
        expect(tester.find.text('ABC'), isTrue);
        expect(tester.find.text('After'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('inside Column', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 1),
                child: Text('Line1\nLine2\nLine3'),
              ),
              Text('Below'),
            ],
          ),
        );
        expect(tester.find.text('Line1'), isTrue);
        // Line2 and Line3 should be truncated
        expect(tester.find.text('Below'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });
}
