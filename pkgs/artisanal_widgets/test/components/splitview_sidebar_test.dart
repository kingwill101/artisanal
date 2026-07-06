import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SplitView
  // ---------------------------------------------------------------------------
  group('SplitView', () {
    group('horizontal split', () {
      test('renders both children', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          SplitView(first: Text('Left'), second: Text('Right')),
        );

        expect(tester.view, isNotEmpty);
        expect(tester.locateText('Left'), isNotNull);
        expect(tester.locateText('Right'), isNotNull);
      });

      test('default axis is horizontal', () {
        final sv = SplitView(first: Text('A'), second: Text('B'));
        expect(sv.axis, Axis.horizontal);
      });

      test('both children appear on same row in horizontal mode', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(SplitView(first: Text('L'), second: Text('R')));

        final leftLoc = tester.locateText('L');
        final rightLoc = tester.locateText('R');
        expect(leftLoc, isNotNull);
        expect(rightLoc, isNotNull);
        // Both on same row, right after left
        expect(leftLoc!.y, equals(rightLoc!.y));
        expect(rightLoc.x, greaterThan(leftLoc.x));
      });
    });

    group('vertical split', () {
      test('renders both children vertically', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          SplitView(
            axis: Axis.vertical,
            first: Text('Top'),
            second: Text('Bottom'),
          ),
        );

        expect(tester.locateText('Top'), isNotNull);
        expect(tester.locateText('Bottom'), isNotNull);
      });

      test('first child is above second in vertical mode', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          SplitView(
            axis: Axis.vertical,
            first: Text('Top'),
            second: Text('Bottom'),
          ),
        );

        final topLoc = tester.locateText('Top');
        final bottomLoc = tester.locateText('Bottom');
        expect(topLoc, isNotNull);
        expect(bottomLoc, isNotNull);
        expect(bottomLoc!.y, greaterThan(topLoc!.y));
      });
    });

    group('custom flex ratios', () {
      test('stores firstFlex and secondFlex', () {
        final sv = SplitView(
          first: Text('A'),
          second: Text('B'),
          firstFlex: 2,
          secondFlex: 3,
        );
        expect(sv.firstFlex, 2);
        expect(sv.secondFlex, 3);
      });
    });

    group('gap and separator', () {
      test('gap=0 hides default separator', () {
        // With gap=0 and no custom separator, the separator is not included
        final sv = SplitView(first: Text('A'), second: Text('B'), gap: 0);
        expect(sv.gap, 0);
        expect(sv.separator, isNull);
      });

      test('default gap is 1', () {
        final sv = SplitView(first: Text('A'), second: Text('B'));
        expect(sv.gap, 1);
      });

      test('custom separator widget is stored', () {
        final sep = Text('|');
        final sv = SplitView(
          first: Text('A'),
          second: Text('B'),
          separator: sep,
        );
        expect(sv.separator, same(sep));
      });

      test('custom separator renders between children', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          SplitView(first: Text('A'), second: Text('B'), separator: Text('|')),
        );

        expect(tester.locateText('A'), isNotNull);
        expect(tester.locateText('|'), isNotNull);
        expect(tester.locateText('B'), isNotNull);
      });

      test('gap=0 with custom separator still shows separator', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          SplitView(
            first: Text('X'),
            second: Text('Y'),
            gap: 0,
            separator: Text('||'),
          ),
        );

        // separator != null, so it should still be rendered
        expect(tester.locateText('||'), isNotNull);
      });
    });

    group('properties', () {
      test('default properties', () {
        final sv = SplitView(first: Text('A'), second: Text('B'));
        expect(sv.axis, Axis.horizontal);
        expect(sv.firstFlex, 1);
        expect(sv.secondFlex, 1);
        expect(sv.gap, 1);
        expect(sv.separator, isNull);
      });

      test('custom properties are stored', () {
        final sep = Text('---');
        final sv = SplitView(
          first: Text('A'),
          second: Text('B'),
          axis: Axis.vertical,
          firstFlex: 3,
          secondFlex: 7,
          gap: 2,
          separator: sep,
        );
        expect(sv.axis, Axis.vertical);
        expect(sv.firstFlex, 3);
        expect(sv.secondFlex, 7);
        expect(sv.gap, 2);
        expect(sv.separator, same(sep));
      });

      test('respects key', () {
        final k = ValueKey('sv');
        final sv = SplitView(first: Text('A'), second: Text('B'), key: k);
        expect(sv.key, same(k));
      });

      test('has unique id without key', () {
        final sv = SplitView(first: Text('A'), second: Text('B'));
        expect(sv.id, isNotNull);
        expect(sv.id, isNotEmpty);
      });
    });

    group('integration', () {
      test('SplitView inside Container', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 40,
            child: SplitView(first: Text('Panel1'), second: Text('Panel2')),
          ),
        );

        expect(tester.locateText('Panel1'), isNotNull);
        expect(tester.locateText('Panel2'), isNotNull);
      });

      test('nested SplitViews', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          SplitView(
            first: Text('LeftPane'),
            second: SplitView(
              axis: Axis.vertical,
              first: Text('TopRight'),
              second: Text('BottomRight'),
            ),
          ),
        );

        expect(tester.locateText('LeftPane'), isNotNull);
        expect(tester.locateText('TopRight'), isNotNull);
        expect(tester.locateText('BottomRight'), isNotNull);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // SidebarSide enum
  // ---------------------------------------------------------------------------
  group('SidebarSide', () {
    test('has left and right values', () {
      expect(SidebarSide.values, hasLength(2));
      expect(SidebarSide.values, contains(SidebarSide.left));
      expect(SidebarSide.values, contains(SidebarSide.right));
    });
  });

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------
  group('Sidebar', () {
    group('left sidebar', () {
      test('renders sidebar and child', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Sidebar(sidebar: Text('Nav'), child: Text('Main')),
        );

        expect(tester.view, isNotEmpty);
        expect(tester.locateText('Nav'), isNotNull);
        expect(tester.locateText('Main'), isNotNull);
      });

      test('sidebar appears to the left of content', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Sidebar(sidebar: Text('Nav'), child: Text('Main')),
        );

        final navLoc = tester.locateText('Nav');
        final mainLoc = tester.locateText('Main');
        expect(navLoc, isNotNull);
        expect(mainLoc, isNotNull);
        // Nav should be at a smaller x position than Main
        expect(navLoc!.x, lessThan(mainLoc!.x));
      });
    });

    group('right sidebar', () {
      test('stores right side property', () {
        final s = Sidebar(
          sidebar: Text('Nav'),
          child: Text('Main'),
          side: SidebarSide.right,
        );
        expect(s.side, SidebarSide.right);
      });

      test('renders sidebar and child with right side', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Sidebar(
            sidebar: Text('Nav'),
            child: Text('Content'),
            side: SidebarSide.right,
          ),
        );

        expect(tester.locateText('Nav'), isNotNull);
        expect(tester.locateText('Content'), isNotNull);
      });
    });

    group('custom width', () {
      test('stores custom width', () {
        final s = Sidebar(sidebar: Text('Nav'), child: Text('Main'), width: 30);
        expect(s.width, 30);
      });
    });

    group('gap', () {
      test('default gap is 1', () {
        final s = Sidebar(sidebar: Text('N'), child: Text('M'));
        expect(s.gap, 1);
      });

      test('gap=0 stored', () {
        final s = Sidebar(sidebar: Text('N'), child: Text('M'), gap: 0);
        expect(s.gap, 0);
      });
    });

    group('properties', () {
      test('default properties', () {
        final s = Sidebar(sidebar: Text('N'), child: Text('M'));
        expect(s.width, 24);
        expect(s.gap, 1);
        expect(s.side, SidebarSide.left);
      });

      test('custom properties are stored', () {
        final bar = Text('Nav');
        final content = Text('Main');
        final s = Sidebar(
          sidebar: bar,
          child: content,
          width: 32,
          gap: 2,
          side: SidebarSide.right,
        );
        expect(s.sidebar, same(bar));
        expect(s.child, same(content));
        expect(s.width, 32);
        expect(s.gap, 2);
        expect(s.side, SidebarSide.right);
      });

      test('respects key', () {
        final k = ValueKey('sb');
        final s = Sidebar(sidebar: Text('N'), child: Text('M'), key: k);
        expect(s.key, same(k));
      });

      test('has unique id without key', () {
        final s = Sidebar(sidebar: Text('N'), child: Text('M'));
        expect(s.id, isNotNull);
        expect(s.id, isNotEmpty);
      });
    });

    group('integration', () {
      test('Sidebar inside Container', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 60,
            child: Sidebar(sidebar: Text('Menu'), child: Text('Page')),
          ),
        );

        expect(tester.locateText('Menu'), isNotNull);
        expect(tester.locateText('Page'), isNotNull);
      });

      test('Sidebar with Column children', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Sidebar(
            sidebar: Column(children: [Text('Link1'), Text('Link2')]),
            child: Column(children: [Text('Header'), Text('Body')]),
          ),
        );

        expect(tester.locateText('Link1'), isNotNull);
        expect(tester.locateText('Link2'), isNotNull);
        expect(tester.locateText('Header'), isNotNull);
        expect(tester.locateText('Body'), isNotNull);
      });

      test('Sidebar with SplitView as child', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Sidebar(
            sidebar: Text('Nav'),
            child: SplitView(
              axis: Axis.vertical,
              first: Text('Top'),
              second: Text('Bottom'),
            ),
          ),
        );

        expect(tester.locateText('Nav'), isNotNull);
        expect(tester.locateText('Top'), isNotNull);
        expect(tester.locateText('Bottom'), isNotNull);
      });
    });
  });
}
