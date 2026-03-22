import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('ResponsiveBreakpoints', () {
    test('reports transitions at expected widths', () {
      final breakpoints = ResponsiveBreakpoints.defaults;

      expect(breakpoints.resolve(0), equals(LayoutBreakpoint.xs));
      expect(breakpoints.resolve(20), equals(LayoutBreakpoint.xs));
      expect(breakpoints.resolve(39), equals(LayoutBreakpoint.xs));

      expect(breakpoints.resolve(40), equals(LayoutBreakpoint.sm));
      expect(breakpoints.resolve(79), equals(LayoutBreakpoint.sm));

      expect(breakpoints.resolve(80), equals(LayoutBreakpoint.md));
      expect(breakpoints.resolve(119), equals(LayoutBreakpoint.md));

      expect(breakpoints.resolve(120), equals(LayoutBreakpoint.lg));
      expect(breakpoints.resolve(159), equals(LayoutBreakpoint.lg));

      expect(breakpoints.resolve(160), equals(LayoutBreakpoint.xl));
      expect(breakpoints.resolve(200), equals(LayoutBreakpoint.xl));
    });

    test('respects custom threshold configuration', () {
      final breakpoints = ResponsiveBreakpoints(
        xs: 5,
        sm: 12,
        md: 20,
        lg: 30,
        xl: 40,
      );

      expect(breakpoints.resolve(4), equals(LayoutBreakpoint.xs));
      expect(breakpoints.resolve(5), equals(LayoutBreakpoint.xs));
      expect(breakpoints.resolve(11), equals(LayoutBreakpoint.xs));
      expect(breakpoints.resolve(12), equals(LayoutBreakpoint.sm));
      expect(breakpoints.resolve(19), equals(LayoutBreakpoint.sm));
      expect(breakpoints.resolve(20), equals(LayoutBreakpoint.md));
      expect(breakpoints.resolve(29), equals(LayoutBreakpoint.md));
      expect(breakpoints.resolve(30), equals(LayoutBreakpoint.lg));
      expect(breakpoints.resolve(39), equals(LayoutBreakpoint.lg));
      expect(breakpoints.resolve(40), equals(LayoutBreakpoint.xl));
    });

    test('supports isAtLeast/isBelow-based layout branching', () {
      final breakpoints = ResponsiveBreakpoints.defaults;
      String layoutState(int width) {
        return breakpoints.isAtLeast(width, LayoutBreakpoint.md)
            ? 'split'
            : 'stacked';
      }

      expect(layoutState(79), equals('stacked'));
      expect(layoutState(80), equals('split'));

      expect(breakpoints.isAtLeast(79, LayoutBreakpoint.md), isFalse);
      expect(breakpoints.isBelow(79, LayoutBreakpoint.md), isTrue);
      expect(breakpoints.isAtLeast(80, LayoutBreakpoint.md), isTrue);
      expect(breakpoints.isBelow(80, LayoutBreakpoint.md), isFalse);
    });
  });
}
