library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // MediaQueryData — construction
  // ---------------------------------------------------------------------------
  group('MediaQueryData construction', () {
    test('constructor requires size', () {
      final data = MediaQueryData(size: Size(80, 24));
      expect(data.size.width, equals(80));
      expect(data.size.height, equals(24));
    });

    test('width and height getters delegate to size', () {
      final data = MediaQueryData(size: Size(120, 40));
      expect(data.width, equals(120));
      expect(data.height, equals(40));
    });

    test('zero returns all zeros', () {
      final data = MediaQueryData.zero;
      expect(data.width, equals(0));
      expect(data.height, equals(0));
      expect(data.size, equals(Size.zero));
    });
  });

  // ---------------------------------------------------------------------------
  // MediaQueryData — copyWith
  // ---------------------------------------------------------------------------
  group('MediaQueryData copyWith', () {
    test('copyWith without args returns equivalent data', () {
      final original = MediaQueryData(size: Size(80, 24));
      final copy = original.copyWith();
      expect(copy.width, equals(80));
      expect(copy.height, equals(24));
      expect(copy, equals(original));
    });

    test('copyWith with size overrides size', () {
      final original = MediaQueryData(size: Size(80, 24));
      final modified = original.copyWith(size: Size(120, 40));
      expect(modified.width, equals(120));
      expect(modified.height, equals(40));
    });

    test('copyWith returns new instance', () {
      final original = MediaQueryData(size: Size(80, 24));
      final copy = original.copyWith();
      expect(identical(original, copy), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // MediaQueryData — equality
  // ---------------------------------------------------------------------------
  group('MediaQueryData equality', () {
    test('equal data objects are equal', () {
      final a = MediaQueryData(size: Size(80, 24));
      final b = MediaQueryData(size: Size(80, 24));
      expect(a, equals(b));
    });

    test('different width makes them unequal', () {
      final a = MediaQueryData(size: Size(80, 24));
      final b = MediaQueryData(size: Size(100, 24));
      expect(a, isNot(equals(b)));
    });

    test('different height makes them unequal', () {
      final a = MediaQueryData(size: Size(80, 24));
      final b = MediaQueryData(size: Size(80, 30));
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      final a = MediaQueryData(size: Size(80, 24));
      final b = MediaQueryData(size: Size(80, 24));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal objects have different hashCodes (usually)', () {
      final a = MediaQueryData(size: Size(80, 24));
      final b = MediaQueryData(size: Size(100, 40));
      // hashCodes could theoretically collide, but this is extremely unlikely
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('not equal to non-MediaQueryData objects', () {
      final data = MediaQueryData(size: Size(80, 24));
      // ignore: unrelated_type_equality_checks
      expect(data == 'not a MediaQueryData', isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // MediaQueryData — toString
  // ---------------------------------------------------------------------------
  group('MediaQueryData toString', () {
    test('toString shows size', () {
      final data = MediaQueryData(size: Size(80, 24));
      expect(data.toString(), contains('80'));
      expect(data.toString(), contains('24'));
    });

    test('zero toString', () {
      expect(MediaQueryData.zero.toString(), contains('0'));
    });
  });

  // ---------------------------------------------------------------------------
  // MediaQuery — InheritedWidget behavior
  // ---------------------------------------------------------------------------
  group('MediaQuery InheritedWidget', () {
    test('MediaQuery.of returns data from ancestor', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(80, 24)),
            child: _MediaQueryReaderWidget(label: 'mq-ok'),
          ),
        );
        expect(tester.find.text('mq-ok'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('MediaQuery.maybeOf returns data when ancestor exists', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        // WidgetTester always wraps with a MediaQuery, so maybeOf returns data
        await tester.pumpWidget(_MaybeMediaQueryWidget());
        expect(tester.find.text('has-mq'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('updateShouldNotify returns true for different data', () {
      final mq1 = MediaQuery(
        data: MediaQueryData(size: Size(80, 24)),
        child: Text('a'),
      );
      final mq2 = MediaQuery(
        data: MediaQueryData(size: Size(100, 40)),
        child: Text('b'),
      );
      expect(mq1.updateShouldNotify(mq2), isTrue);
    });

    test('updateShouldNotify returns false for same data', () {
      final data = MediaQueryData(size: Size(80, 24));
      final mq1 = MediaQuery(data: data, child: Text('a'));
      final mq2 = MediaQuery(data: data, child: Text('b'));
      expect(mq1.updateShouldNotify(mq2), isFalse);
    });

    test('updateShouldNotify returns false for equal data', () {
      final mq1 = MediaQuery(
        data: MediaQueryData(size: Size(80, 24)),
        child: Text('a'),
      );
      final mq2 = MediaQuery(
        data: MediaQueryData(size: Size(80, 24)),
        child: Text('b'),
      );
      // Equal data means updateShouldNotify returns false
      expect(mq1.updateShouldNotify(mq2), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // MediaQuery — with WidgetTester (auto-provided)
  // ---------------------------------------------------------------------------
  group('MediaQuery via WidgetTester', () {
    test('WidgetTester provides MediaQuery to widgets', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(_MediaQuerySizeWidget());
        // WidgetTester wraps widgets with MediaQuery automatically
        // The widget should be able to read screen dimensions
        expect(tester.find.text('80x24'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('resize updates MediaQuery data', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(_MediaQuerySizeWidget());
        expect(tester.find.text('80x24'), isTrue);

        tester.resize(120, 40);
        expect(tester.find.text('120x40'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('custom initial dimensions are reflected', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 50);
      try {
        await tester.pumpWidget(_MediaQuerySizeWidget());
        expect(tester.find.text('100x50'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // MediaQuery — nested
  // ---------------------------------------------------------------------------
  group('MediaQuery nesting', () {
    test('inner MediaQuery overrides outer', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(80, 24)),
            child: MediaQuery(
              data: MediaQueryData(size: Size(40, 12)),
              child: _MediaQuerySizeWidget(),
            ),
          ),
        );
        // Inner MediaQuery should take precedence
        expect(tester.find.text('40x12'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });
}

/// Reads MediaQuery.of(context) and renders the label to prove it didn't throw.
class _MediaQueryReaderWidget extends StatelessWidget {
  _MediaQueryReaderWidget({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // Access MediaQuery to verify it works
    MediaQuery.of(context);
    return Text(label);
  }
}

/// Uses MediaQuery.maybeOf and renders different text based on result.
class _MaybeMediaQueryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.maybeOf(context);
    return Text(data != null ? 'has-mq' : 'no-mq');
  }
}

/// Reads the MediaQuery size and renders "WxH" text.
class _MediaQuerySizeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return Text('${data.width.toInt()}x${data.height.toInt()}');
  }
}
