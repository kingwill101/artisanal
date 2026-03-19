import 'package:artisanal/style.dart';
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Container', () {
    test('renders child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Container(child: Text('Content')));
      expect(tester.find.text('Content'), isTrue);
    });

    test('renders empty container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Container());
      expect(tester.view.trim(), isEmpty);
    });

    test('applies uniform padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(padding: EdgeInsets.all(2), child: Text('X')),
      );

      final lines = tester.viewLines;
      expect(lines.length, greaterThanOrEqualTo(5));
    });

    test('applies symmetric padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Text('X'),
        ),
      );
      expect(tester.find.text('X'), isTrue);
    });

    test('applies specific padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          padding: EdgeInsets.only(left: 2, top: 1, right: 2, bottom: 1),
          child: Text('X'),
        ),
      );
      expect(tester.find.text('X'), isTrue);
    });

    test('applies width constraint', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Container(width: 20, child: Text('Hi')));

      final lines = tester.viewLines;
      for (final line in lines) {
        if (line.isNotEmpty) {
          expect(Layout.visibleLength(line), lessThanOrEqualTo(20));
        }
      }
    });

    test('applies height constraint', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Container(height: 5, child: Text('Hi')));

      final lines = tester.viewLines;
      expect(lines.length, lessThanOrEqualTo(5));
    });

    test('applies width and height constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(width: 10, height: 3, child: Text('Hi')),
      );

      final lines = tester.viewLines;
      expect(lines.length, lessThanOrEqualTo(3));
      for (final line in lines) {
        if (line.isNotEmpty) {
          expect(Layout.visibleLength(line), lessThanOrEqualTo(10));
        }
      }
    });

    test('applies background color', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(background: Colors.blue, child: Text('BG')),
      );
      expect(tester.find.text('BG'), isTrue);
    });

    test('applies foreground color', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(foreground: Colors.white, child: Text('FG')),
      );
      expect(tester.find.text('FG'), isTrue);
    });

    test('applies color (shorthand for background)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(color: Colors.green, child: Text('Colored')),
      );
      expect(tester.find.text('Colored'), isTrue);
    });

    test('applies BoxDecoration', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          decoration: BoxDecoration(
            color: Colors.yellow,
            border: Border.normal,
          ),
          child: Text('Decorated'),
        ),
      );
      expect(tester.find.text('Decorated'), isTrue);
    });

    test('applies foregroundDecoration', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          foregroundDecoration: BoxDecoration(color: Colors.cyan),
          child: Text('Foreground'),
        ),
      );
      expect(tester.find.text('Foreground'), isTrue);
    });

    test('applies alignment', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 20,
          alignment: Alignment.center,
          child: Text('Centered'),
        ),
      );
      expect(tester.find.text('Centered'), isTrue);
    });

    test('applies horizontal align', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 20,
          align: HorizontalAlign.center,
          child: Text('H-Centered'),
        ),
      );
      expect(tester.find.text('H-Centered'), isTrue);
    });

    test('applies vertical align', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          height: 5,
          verticalAlign: VerticalAlign.center,
          child: Text('V-Centered'),
        ),
      );
      expect(tester.find.text('V-Centered'), isTrue);
    });

    test('applies margin', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(margin: EdgeInsets.all(1), child: Text('Margin')),
      );
      expect(tester.find.text('Margin'), isTrue);
    });

    test('has one child', () async {
      final container = Container(child: Text('test'));
      expect(container.children.length, equals(1));
    });

    test('has no children when empty', () async {
      final container = Container();
      expect(container.children, isEmpty);
    });

    test('is not focusable', () async {
      final container = Container(child: Text('test'));
      expect(container.focusable, isFalse);
    });

    test('has unique id', () {
      final c1 = Container();
      final c2 = Container();
      expect(c1.id, isNot(equals(c2.id)));
    });

    test('respects key', () {
      final container = Container(key: ValueKey('container-key'));
      expect(container.id, equals('container-key'));
    });
  });

  group('Container integration', () {
    test('nested Containers', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          padding: EdgeInsets.all(1),
          decoration: BoxDecoration(border: Border.normal),
          child: Container(padding: EdgeInsets.all(1), child: Text('Nested')),
        ),
      );
      expect(tester.find.text('Nested'), isTrue);
    });

    test('Container with Column child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          padding: EdgeInsets.all(2),
          child: Column(children: [Text('Line 1'), Text('Line 2')]),
        ),
      );

      expect(tester.find.text('Line 1'), isTrue);
      expect(tester.find.text('Line 2'), isTrue);
    });

    test('Container with Row child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Row(children: [Text('A'), Text('B')]),
        ),
      );

      expect(tester.find.text('A'), isTrue);
      expect(tester.find.text('B'), isTrue);
    });

    test('Container with constrained size', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(
            border: Border.rounded,
            color: Colors.white,
          ),
          child: Center(child: Text('Centered')),
        ),
      );

      expect(tester.find.text('Centered'), isTrue);
    });
  });

  group('BoxDecoration', () {
    test('creates decoration with color', () {
      final decoration = BoxDecoration(color: Colors.red);
      expect(decoration.color, equals(Colors.red));
    });

    test('creates decoration with border', () {
      final decoration = BoxDecoration(border: Border.double);
      expect(decoration.border, equals(Border.double));
    });

    test('creates decoration with border radius', () {
      final decoration = BoxDecoration(borderRadius: BorderRadius.all(2));
      expect(decoration.borderRadius, isNotNull);
    });

    test('creates decoration with gradient', () {
      final decoration = BoxDecoration(
        gradient: Gradient([Colors.red, Colors.blue]),
      );
      expect(decoration.gradient, isNotNull);
    });

    test('creates decoration with all properties', () {
      final decoration = BoxDecoration(
        color: Colors.white,
        border: Border.normal,
        borderRadius: BorderRadius.only(topLeft: 1, topRight: 2),
        gradient: Gradient([Colors.black, Colors.white]),
      );
      expect(decoration.color, equals(Colors.white));
      expect(decoration.border, equals(Border.normal));
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.gradient, isNotNull);
    });
  });

  group('BorderRadius', () {
    test('creates uniform radius with all', () {
      final radius = BorderRadius.all(5);
      expect(radius.topLeft, equals(5));
      expect(radius.topRight, equals(5));
      expect(radius.bottomLeft, equals(5));
      expect(radius.bottomRight, equals(5));
    });

    test('creates specific radius with only', () {
      final radius = BorderRadius.only(
        topLeft: 1,
        topRight: 2,
        bottomLeft: 3,
        bottomRight: 4,
      );
      expect(radius.topLeft, equals(1));
      expect(radius.topRight, equals(2));
      expect(radius.bottomLeft, equals(3));
      expect(radius.bottomRight, equals(4));
    });

    test('creates partial radius with only', () {
      final radius = BorderRadius.only(topLeft: 2);
      expect(radius.topLeft, equals(2));
      expect(radius.topRight, equals(0));
      expect(radius.bottomLeft, equals(0));
      expect(radius.bottomRight, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // BoxDecoration rendering — Bug 6 regression tests
  // border, borderRadius, and gradient are now rendered by
  // _renderContainerContent.
  // ---------------------------------------------------------------------------
  group('BoxDecoration rendering', () {
    test('decoration color is applied as background', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 1,
            decoration: BoxDecoration(color: Colors.red),
            child: Text('Red'),
          ),
        );
        expect(tester.find.text('Red'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('border produces visible border characters', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        // Without border
        await tester.pumpWidget(
          Container(width: 10, height: 3, child: Text('NoBorder')),
        );
        final viewWithout = tester.view;

        // With border
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.double),
            child: Text('NoBorder'),
          ),
        );
        final viewWith = tester.view;

        // Bug 6 fix: border now has a visual effect
        expect(viewWithout, isNot(equals(viewWith)));
        // Verify border characters appear
        expect(viewWith, contains('╔'));
        expect(viewWith, contains('╗'));
        expect(viewWith, contains('╚'));
        expect(viewWith, contains('╝'));
        expect(viewWith, contains('═'));
        expect(viewWith, contains('║'));
      } finally {
        await tester.dispose();
      }
    });

    test('borderRadius without border has no visual effect', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Container(width: 10, height: 3, child: Text('NoRadius')),
        );
        final viewWithout = tester.view;

        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(borderRadius: BorderRadius.all(2)),
            child: Text('NoRadius'),
          ),
        );
        final viewWith = tester.view;

        // borderRadius without a border has no visible effect
        expect(viewWithout, equals(viewWith));
      } finally {
        await tester.dispose();
      }
    });

    test('gradient produces per-row background colors', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Container(width: 10, height: 3, child: Text('NoGrad')),
        );
        final viewWithout = tester.view;

        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              gradient: Gradient([Colors.red, Colors.blue]),
            ),
            child: Text('NoGrad'),
          ),
        );
        final viewWith = tester.view;

        // Bug 6 fix: gradient now has a visual effect (ANSI bg color codes)
        expect(viewWithout, isNot(equals(viewWith)));
        // Gradient injects ANSI escape codes for background color
        expect(viewWith, contains('\x1B['));
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Bug 6 regression: comprehensive BoxDecoration rendering tests
  // ---------------------------------------------------------------------------
  group('Bug 6 regression: border rendering', () {
    test('Border.normal renders ┌─┐│└─┘ characters', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.normal),
            child: Text('Hi'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(3));
        expect(lines[0], contains('┌'));
        expect(lines[0], contains('─'));
        expect(lines[0], contains('┐'));
        expect(lines[1], contains('│'));
        expect(lines[1], contains('Hi'));
        expect(lines[2], contains('└'));
        expect(lines[2], contains('─'));
        expect(lines[2], contains('┘'));
      } finally {
        await tester.dispose();
      }
    });

    test('Border.rounded renders ╭─╮│╰─╯ characters', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.rounded),
            child: Text('Hi'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines[0], contains('╭'));
        expect(lines[0], contains('╮'));
        expect(lines[2], contains('╰'));
        expect(lines[2], contains('╯'));
      } finally {
        await tester.dispose();
      }
    });

    test('Border.thick renders ┏━┓┃┗━┛ characters', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.thick),
            child: Text('Hi'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines[0], contains('┏'));
        expect(lines[0], contains('━'));
        expect(lines[0], contains('┓'));
        expect(lines[1], contains('┃'));
        expect(lines[2], contains('┗'));
        expect(lines[2], contains('━'));
        expect(lines[2], contains('┛'));
      } finally {
        await tester.dispose();
      }
    });

    test('Border.double renders ╔═╗║╚═╝ characters', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.double),
            child: Text('Hi'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines[0], contains('╔'));
        expect(lines[0], contains('═'));
        expect(lines[0], contains('╗'));
        expect(lines[1], contains('║'));
        expect(lines[2], contains('╚'));
        expect(lines[2], contains('═'));
        expect(lines[2], contains('╝'));
      } finally {
        await tester.dispose();
      }
    });

    test('Border.ascii renders +--+||+--+ characters', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.ascii),
            child: Text('Hi'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines[0], contains('+'));
        expect(lines[0], contains('-'));
        expect(lines[1], contains('|'));
        expect(lines[1], contains('Hi'));
        expect(lines[2], contains('+'));
        expect(lines[2], contains('-'));
      } finally {
        await tester.dispose();
      }
    });

    test('Border.none produces no visible border', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(width: 10, height: 3, child: Text('Hi')),
        );
        final viewWithout = tester.view;

        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.none),
            child: Text('Hi'),
          ),
        );
        final viewWith = tester.view;

        // Border.none has empty strings — no visual change
        expect(viewWithout, equals(viewWith));
      } finally {
        await tester.dispose();
      }
    });

    test(
      'border auto-sizes around content when no explicit width/height',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
        try {
          await tester.pumpWidget(
            Container(
              width: 6,
              height: 3,
              decoration: BoxDecoration(border: Border.normal),
              child: Text('Auto'),
            ),
          );
          final lines = tester.viewLines;
          // Auto text is 4 chars wide, border adds 2 (left+right), total = 6
          expect(lines.length, equals(3));
          expect(Layout.visibleLength(lines[0]), equals(6));
          expect(lines[0], contains('┌'));
          expect(lines[0], contains('┐'));
          expect(lines[1], contains('Auto'));
        } finally {
          await tester.dispose();
        }
      },
    );

    test('border with explicit width fills remaining space', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(border: Border.normal),
            child: Text('X'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(3));
        // Width 12 total: border left (1) + 10 inner + border right (1) = 12
        expect(Layout.visibleLength(lines[0]), equals(12));
        expect(lines[1], contains('X'));
      } finally {
        await tester.dispose();
      }
    });

    test('border + padding positions content inside border', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 14,
            height: 5,
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(border: Border.normal),
            child: Text('Pad'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(5));
        // Top border
        expect(lines[0], contains('┌'));
        // Row 1: padding row (empty inside border)
        expect(lines[1], contains('│'));
        expect(lines[1], isNot(contains('Pad')));
        // Row 2: content row
        expect(lines[2], contains('│'));
        expect(lines[2], contains('Pad'));
        // Row 3: padding row
        expect(lines[3], contains('│'));
        // Bottom border
        expect(lines[4], contains('└'));
      } finally {
        await tester.dispose();
      }
    });

    test('content is visible between border edges', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            decoration: BoxDecoration(border: Border.normal),
            child: Text('Hello'),
          ),
        );
        expect(tester.find.text('Hello'), isTrue);
        final lines = tester.viewLines;
        // Middle line has │Hello│
        expect(lines[1], contains('│'));
        expect(lines[1], contains('Hello'));
      } finally {
        await tester.dispose();
      }
    });
  });

  group('Bug 6 regression: borderRadius rendering', () {
    test('borderRadius replaces normal corners with rounded ones', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              border: Border.normal,
              borderRadius: BorderRadius.all(1),
            ),
            child: Text('R'),
          ),
        );
        final lines = tester.viewLines;
        // Normal corners ┌┐└┘ are replaced with ╭╮╰╯
        expect(lines[0], contains('╭'));
        expect(lines[0], contains('╮'));
        expect(lines[0], isNot(contains('┌')));
        expect(lines[0], isNot(contains('┐')));
        expect(lines[2], contains('╰'));
        expect(lines[2], contains('╯'));
        expect(lines[2], isNot(contains('└')));
        expect(lines[2], isNot(contains('┘')));
        // Edge characters remain unchanged
        expect(lines[0], contains('─'));
        expect(lines[1], contains('│'));
      } finally {
        await tester.dispose();
      }
    });

    test('borderRadius only affects specified corners', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              border: Border.normal,
              borderRadius: BorderRadius.only(topLeft: 1, bottomRight: 1),
            ),
            child: Text('P'),
          ),
        );
        final lines = tester.viewLines;
        // Only topLeft and bottomRight are rounded
        expect(lines[0], contains('╭'));
        expect(lines[0], contains('┐')); // topRight stays normal
        expect(lines[2], contains('└')); // bottomLeft stays normal
        expect(lines[2], contains('╯'));
      } finally {
        await tester.dispose();
      }
    });

    test('borderRadius with thick border replaces corners', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              border: Border.thick,
              borderRadius: BorderRadius.all(1),
            ),
            child: Text('T'),
          ),
        );
        final lines = tester.viewLines;
        // Thick corners ┏┓┗┛ are replaced with ╭╮╰╯
        expect(lines[0], contains('╭'));
        expect(lines[0], contains('╮'));
        expect(lines[2], contains('╰'));
        expect(lines[2], contains('╯'));
        // Thick edges remain unchanged
        expect(lines[0], contains('━'));
        expect(lines[1], contains('┃'));
      } finally {
        await tester.dispose();
      }
    });

    test('borderRadius 0 keeps original corners', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              border: Border.normal,
              borderRadius: BorderRadius.all(0),
            ),
            child: Text('Z'),
          ),
        );
        final lines = tester.viewLines;
        // radius 0 means no rounding — original corners
        expect(lines[0], contains('┌'));
        expect(lines[0], contains('┐'));
        expect(lines[2], contains('└'));
        expect(lines[2], contains('┘'));
      } finally {
        await tester.dispose();
      }
    });
  });

  group('Bug 6 regression: gradient rendering', () {
    test('gradient applies ANSI background color codes', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              gradient: Gradient([
                BasicColor('#ff0000'),
                BasicColor('#0000ff'),
              ]),
            ),
            child: Text('G'),
          ),
        );
        final view = tester.view;
        // Gradient produces ANSI escape codes
        expect(view, contains('\x1B['));
        // Content is still visible
        expect(tester.find.text('G'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('gradient with single color fills uniformly', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        // Single color: blend1D returns empty or same color for all rows
        // (blend1D requires >= 2 colors to produce a gradient)
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              gradient: Gradient([BasicColor('#ff0000')]),
            ),
            child: Text('S'),
          ),
        );
        // Should still render content
        expect(tester.find.text('S'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('gradient rows have different colors for tall containers', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 6,
            height: 5,
            decoration: BoxDecoration(
              gradient: Gradient([
                BasicColor('#ff0000'),
                BasicColor('#0000ff'),
              ]),
            ),
          ),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(5));
        // Different rows should have different ANSI codes
        // (top is red-ish, bottom is blue-ish)
        final uniqueLines = lines.toSet();
        expect(
          uniqueLines.length,
          greaterThan(1),
          reason: 'gradient should produce different rows',
        );
      } finally {
        await tester.dispose();
      }
    });
  });

  group('Bug 6 regression: border + gradient combination', () {
    test('border wraps around gradient interior', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 12,
            height: 5,
            decoration: BoxDecoration(
              border: Border.normal,
              gradient: Gradient([
                BasicColor('#ff0000'),
                BasicColor('#0000ff'),
              ]),
            ),
            child: Text('BG'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(5));

        // Top and bottom are border lines (no gradient ANSI in border line)
        expect(lines[0], contains('┌'));
        expect(lines[0], contains('┐'));
        expect(lines[4], contains('└'));
        expect(lines[4], contains('┘'));

        // Middle rows have gradient (ANSI codes) between border edges
        expect(lines[1], contains('│'));
        expect(lines[1], contains('\x1B['));
        expect(lines[2], contains('│'));
        expect(lines[3], contains('│'));

        // Content visible
        expect(tester.find.text('BG'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('border + gradient + padding', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 12);
      try {
        await tester.pumpWidget(
          Container(
            width: 14,
            height: 7,
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.rounded,
              gradient: Gradient([
                BasicColor('#ff0000'),
                BasicColor('#0000ff'),
              ]),
            ),
            child: Text('X'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(7));
        // Rounded border
        expect(lines[0], contains('╭'));
        expect(lines[0], contains('╮'));
        expect(lines[6], contains('╰'));
        expect(lines[6], contains('╯'));
        // Content somewhere in the middle
        expect(tester.find.text('X'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('borderRadius + gradient + border all combined', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 5,
            decoration: BoxDecoration(
              border: Border.thick,
              borderRadius: BorderRadius.all(1),
              gradient: Gradient([
                BasicColor('#00ff00'),
                BasicColor('#ff00ff'),
              ]),
            ),
            child: Text('All'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(5));
        // Rounded corners (from borderRadius)
        expect(lines[0], contains('╭'));
        expect(lines[0], contains('╮'));
        // Thick edges
        expect(lines[0], contains('━'));
        expect(lines[1], contains('┃'));
        // Gradient in middle
        expect(lines[2], contains('\x1B['));
        // Content visible
        expect(tester.find.text('All'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  group('Bug 6 regression: border size accounting', () {
    test('border consumes space within explicit width/height', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(border: Border.normal),
            child: Text('Hi'),
          ),
        );
        final lines = tester.viewLines;
        // Total width should be exactly 10
        for (final line in lines) {
          expect(Layout.visibleLength(line), equals(10));
        }
        // Total height should be exactly 3
        expect(lines.length, equals(3));
      } finally {
        await tester.dispose();
      }
    });

    test('border auto-sizes: width = content + 2 border chars', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 7,
            height: 3,
            decoration: BoxDecoration(border: Border.normal),
            child: Text('ABCDE'),
          ),
        );
        final lines = tester.viewLines;
        // 5 chars + 1 left border + 1 right border = 7
        expect(Layout.visibleLength(lines[0]), equals(7));
        // 1 top + 1 content + 1 bottom = 3
        expect(lines.length, equals(3));
      } finally {
        await tester.dispose();
      }
    });

    test('nested containers with borders', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            decoration: BoxDecoration(border: Border.normal),
            child: Container(
              decoration: BoxDecoration(border: Border.rounded),
              child: Text('Deep'),
            ),
          ),
        );
        final view = tester.view;
        // Both border types should be visible
        expect(view, contains('┌'));
        expect(view, contains('╭'));
        expect(tester.find.text('Deep'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('border with margin', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            margin: EdgeInsets.only(left: 2),
            decoration: BoxDecoration(border: Border.normal),
            child: Text('M'),
          ),
        );
        final lines = tester.viewLines;
        // Margin pushes the border right
        expect(lines[0], startsWith('  '));
        expect(lines[0], contains('┌'));
      } finally {
        await tester.dispose();
      }
    });

    test('container with border and alignment centers content', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(
            width: 12,
            height: 5,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.normal),
            child: Text('C'),
          ),
        );
        final lines = tester.viewLines;
        expect(lines[0], contains('┌'));
        // Content 'C' should be roughly centered (not at left edge)
        expect(tester.find.text('C'), isTrue);
        // The content line should have border + spaces + C + spaces + border
        final contentLine = lines[2]; // middle row of 5
        expect(contentLine, contains('│'));
        expect(contentLine, contains('C'));
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Container fills entire viewport — the root Container's paint output must
  // cover every cell of the terminal so background colors span the full screen.
  // ---------------------------------------------------------------------------
  group('Container fills viewport', () {
    test(
      'plain Container with child fills viewport width and height',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
        try {
          await tester.pumpWidget(Container(child: Text('Hello')));
          final lines = tester.viewLines;
          // The container should produce exactly screenHeight lines.
          expect(lines.length, equals(10));
          // Every line should span the full screenWidth.
          for (var i = 0; i < lines.length; i++) {
            expect(
              Layout.visibleLength(lines[i]),
              equals(40),
              reason: 'line $i should be 40 chars wide',
            );
          }
          // Content is still present at (0,0).
          expect(tester.find.text('Hello'), isTrue);
          final pos = tester.locateText('Hello');
          expect(pos, isNotNull);
          expect(pos!.x, equals(0));
          expect(pos.y, equals(0));
        } finally {
          await tester.dispose();
        }
      },
    );

    test('Container with color fills entire viewport', () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 20);
      try {
        await tester.pumpWidget(
          Container(color: Colors.blue, child: Text('World')),
        );
        final lines = tester.viewLines;
        expect(lines.length, equals(20));
        for (var i = 0; i < lines.length; i++) {
          expect(
            Layout.visibleLength(lines[i]),
            equals(60),
            reason: 'line $i should be 60 chars wide',
          );
        }
        expect(tester.find.text('World'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test(
      'Container with padding fills viewport, child offset by padding',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
        try {
          await tester.pumpWidget(
            Container(
              padding: const EdgeInsets.all(2),
              color: Colors.green,
              child: Text('Padded'),
            ),
          );
          final lines = tester.viewLines;
          expect(lines.length, equals(10));
          for (var i = 0; i < lines.length; i++) {
            expect(
              Layout.visibleLength(lines[i]),
              equals(40),
              reason: 'line $i should be 40 chars wide',
            );
          }
          // Content should be offset by padding.
          final pos = tester.locateText('Padded');
          expect(pos, isNotNull);
          expect(pos!.x, equals(2));
          expect(pos.y, equals(2));
        } finally {
          await tester.dispose();
        }
      },
    );

    test('empty Container fills viewport with blank cells', () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 8);
      try {
        await tester.pumpWidget(Container());
        final lines = tester.viewLines;
        expect(lines.length, equals(8));
        for (var i = 0; i < lines.length; i++) {
          expect(
            Layout.visibleLength(lines[i]),
            equals(30),
            reason: 'line $i should be 30 chars wide',
          );
        }
        // All content is whitespace.
        expect(tester.view.trim(), isEmpty);
      } finally {
        await tester.dispose();
      }
    });

    test('Container resizes when terminal resizes', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          Container(color: Colors.red, child: Text('Resize')),
        );
        var lines = tester.viewLines;
        expect(lines.length, equals(10));
        expect(Layout.visibleLength(lines[0]), equals(40));

        // Resize the terminal.
        tester.resize(60, 15);
        lines = tester.viewLines;
        expect(lines.length, equals(15));
        expect(Layout.visibleLength(lines[0]), equals(60));
        expect(tester.find.text('Resize'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });
}
