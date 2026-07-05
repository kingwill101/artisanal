import 'package:artisanal/style.dart' show Colors, Style;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart'
    show Cmd, KeyMsg, Msg, MouseMsg, MouseAction, MouseButton;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

class _PaintCounter {
  int count = 0;
}

class _CountingLeaf extends LeafRenderObjectWidget {
  _CountingLeaf({required this.label, required this.counter});

  final String label;
  final _PaintCounter counter;

  @override
  RenderObject createRenderObject() {
    return _CountingRenderBox(label: label, counter: counter);
  }

  @override
  Object view() => label;

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _CountingRenderBox;
    ro
      ..label = label
      ..counter = counter;
  }
}

class _EmptyLeaf extends LeafRenderObjectWidget {
  _EmptyLeaf();

  @override
  RenderObject createRenderObject() => _EmptyRenderLeaf();

  @override
  Object view() => 'empty';
}

class _EmptyRenderLeaf extends RenderBox {
  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    size = constraints.constrain(const Size(1, 1));
  }

  @override
  String paint() => '';
}

class _CountingRenderBox extends RenderBox {
  _CountingRenderBox({required this.label, required this.counter});

  String label;
  _PaintCounter counter;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    size = constraints.constrain(Size(label.length.toDouble(), 1));
  }

  @override
  String paint() {
    counter.count++;
    return label;
  }
}

({int index, int offsetInItem}) _resolveOffsetForDebugViewport(
  dynamic renderViewport,
  int offset,
) {
  final value = (renderViewport as dynamic).debugResolveOffsetForContentOffset(
    offset,
  );
  return (
    index: (value as dynamic).index as int,
    offsetInItem: (value as dynamic).offsetInItem as int,
  );
}

dynamic _findRenderListViewport(Widget listViewWidget) {
  final start = elementOf(listViewWidget);
  if (start == null) {
    fail('VirtualListView element should be mounted');
  }

  Element current = start;
  final seen = <Element>{};
  while (true) {
    if (!seen.add(current)) {
      fail('Detected element cycle while locating RenderListViewport');
    }

    final ro = current.renderObject;
    if (ro != null) {
      final typeName = ro.runtimeType.toString();
      if (typeName.contains('RenderListViewport')) return ro;
    }

    final nextChild = current.children.isNotEmpty
        ? current.children.first
        : null;
    if (nextChild == null) {
      if (ro == null) {
        fail('VirtualListView render object should exist');
      }

      // Fallback if type-name matching changes.
      try {
        (ro as dynamic).debugResolveOffsetForContentOffset(0);
      } catch (_) {
        fail(
          'VirtualListView render object with debugResolveOffsetForContentOffset should exist',
        );
      }

      return ro;
    }
    current = nextChild;
  }
}

String _variableHeightItem(int index, int lines) {
  return List.generate(
    lines,
    (line) => 'Item $index line ${line + 1}',
  ).join('\n');
}

int _variableItemHeightOffset(
  List<int> heights,
  int index,
  int separatorBreaks,
) {
  var offset = 0;
  final lastIndex = index - 1;
  for (var i = 0; i <= lastIndex; i++) {
    offset += heights[i];
    if (i < heights.length - 1) {
      offset += separatorBreaks;
    }
  }
  return offset;
}

int _contentHeightFromHeights(List<int> heights, int separatorBreaks) {
  var total = 0;
  for (var i = 0; i < heights.length; i++) {
    total += heights[i];
    if (i < heights.length - 1) total += separatorBreaks;
  }
  return total;
}

int _resolveExpectedItemIndex(
  List<int> heights,
  int separatorBreaks,
  int offset,
) {
  if (heights.isEmpty) return 0;
  var remaining = offset.clamp(0, 0x7fffffff).toInt();
  for (var i = 0; i < heights.length; i++) {
    final stride = heights[i] + (i < heights.length - 1 ? separatorBreaks : 0);
    if (remaining < stride) return i;
    remaining -= stride;
  }
  return heights.length - 1;
}

void main() {
  // ---------------------------------------------------------------------------
  // ViewportController
  // ---------------------------------------------------------------------------
  group('ViewportController', () {
    test('starts at offset 0', () {
      final vc = ViewportController();
      expect(vc.offset, equals(0));
      expect(vc.yOffset, equals(0));
    });

    test('setContent updates content', () {
      final vc = ViewportController();
      vc.setContent('line1\nline2\nline3');
      expect(vc.contentExtent, greaterThan(0));
    });

    test('configure sets dimensions', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 10);
      vc.setContent(_lines(20));
      expect(vc.viewportExtent, equals(10));
    });

    test('scrollBy scrolls down', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));
      final changed = vc.scrollBy(3);
      expect(changed, isTrue);
      expect(vc.offset, equals(3));
    });

    test('scrollBy scrolls up', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));
      vc.scrollBy(5);
      final changed = vc.scrollBy(-2);
      expect(changed, isTrue);
      expect(vc.offset, equals(3));
    });

    test('scrollBy returns false when at boundary', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));
      // Already at top
      final changed = vc.scrollBy(-1);
      expect(changed, isFalse);
      expect(vc.offset, equals(0));
    });

    test('scrollBy(0) returns false', () {
      final vc = ViewportController();
      expect(vc.scrollBy(0), isFalse);
    });

    test('jumpTo sets offset directly', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));
      final changed = vc.jumpTo(10);
      expect(changed, isTrue);
      expect(vc.offset, equals(10));
    });

    test('scrollPercent is 0 at top', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));
      expect(vc.scrollPercent, equals(0.0));
    });

    test('scrollPercent is 1.0 when content fits viewport', () {
      // ViewportModel returns 1.0 when everything is visible (h >= total),
      // meaning "fully scrolled" / "everything visible".
      final vc = ViewportController();
      vc.configure(width: 40, height: 20);
      vc.setContent(_lines(5));
      expect(vc.scrollPercent, equals(1.0));
    });

    test('maxOffset is content minus viewport', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));
      expect(vc.maxOffset, equals(15));
    });

    test('maxOffset is 0 when content fits', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 20);
      vc.setContent(_lines(5));
      expect(vc.maxOffset, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // ListViewController
  // ---------------------------------------------------------------------------
  group('ListViewController', () {
    test('starts at offset 0', () {
      final lvc = ListViewController();
      expect(lvc.offset, equals(0));
      expect(lvc.viewportHeight, equals(0));
      expect(lvc.contentHeight, equals(0));
    });

    test('setViewportHeight updates viewport', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      expect(lvc.viewportHeight, equals(10));
      expect(lvc.viewportExtent, equals(10));
    });

    test('setContentHeight updates content extent', () {
      final lvc = ListViewController();
      lvc.setContentHeight(50);
      expect(lvc.contentHeight, equals(50));
      expect(lvc.contentExtent, equals(50));
    });

    test('scrollBy scrolls within bounds', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(50);
      final changed = lvc.scrollBy(5);
      expect(changed, isTrue);
      expect(lvc.offset, equals(5));
    });

    test('scrollBy clamps to maxOffset', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(20);
      lvc.scrollBy(100);
      expect(lvc.offset, equals(10)); // maxOffset = 20 - 10
    });

    test('scrollBy clamps to 0', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(20);
      lvc.scrollBy(5);
      lvc.scrollBy(-100);
      expect(lvc.offset, equals(0));
    });

    test('jumpTo sets absolute offset', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(50);
      lvc.jumpTo(20);
      expect(lvc.offset, equals(20));
    });

    test('jumpTo clamps to bounds', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(20);
      lvc.jumpTo(100);
      expect(lvc.offset, equals(10));
    });

    test('maxOffset computed correctly', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(50);
      expect(lvc.maxOffset, equals(40));
    });

    test('scrollPercent tracks position', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(20);
      expect(lvc.scrollPercent, equals(0.0));
      lvc.jumpTo(5);
      expect(lvc.scrollPercent, equals(0.5));
      lvc.jumpTo(10);
      expect(lvc.scrollPercent, equals(1.0));
    });

    test('negative height treated as 0', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(-5);
      expect(lvc.viewportHeight, equals(0));
      lvc.setContentHeight(-10);
      expect(lvc.contentHeight, equals(0));
    });

    test('setContentHeight notifies when clamping offset', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(100);
      lvc.jumpTo(90);

      var fired = 0;
      lvc.addListener(() => fired++);

      final clamped = lvc.setContentHeight(20);

      expect(clamped, isTrue);
      expect(lvc.offset, equals(10));
      expect(fired, equals(1));
    });

    test('setViewportHeight notifies when clamping offset', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(50);
      lvc.jumpTo(40);

      var fired = 0;
      lvc.addListener(() => fired++);

      final clamped = lvc.setViewportHeight(45);

      expect(clamped, isTrue);
      expect(lvc.offset, equals(5));
      expect(fired, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Viewport widget rendering
  // ---------------------------------------------------------------------------
  group('Viewport widget', () {
    test('renders content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Viewport(content: 'Hello World', width: 20, height: 5),
      );
      expect(tester.locateText('Hello World'), isNotNull);
    });

    test('renders with scrollbar when content exceeds height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Viewport(
          content: _lines(20),
          width: 20,
          height: 5,
          showScrollbar: true,
        ),
      );
      // Should render something — content + scrollbar
      expect(tester.view.isNotEmpty, isTrue);
      // First line should be visible
      expect(tester.locateText('Line 1'), isNotNull);
    });

    test('renders first N lines only when height limited', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Viewport(content: _lines(30), width: 20, height: 3),
      );
      expect(tester.locateText('Line 1'), isNotNull);
      expect(tester.locateText('Line 2'), isNotNull);
      expect(tester.locateText('Line 3'), isNotNull);
      // Line 4 should not be visible
      expect(tester.locateText('Line 4'), isNull);
    });

    test('controller allows programmatic scrolling', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ViewportController();
      await tester.pumpWidget(
        Viewport(
          content: _lines(30),
          width: 20,
          height: 3,
          controller: controller,
        ),
      );

      // Initially at top
      expect(tester.locateText('Line 1'), isNotNull);
      expect(controller.offset, equals(0));

      // External scrollBy triggers re-render via listener → markNeedsPaint.
      final changed = controller.scrollBy(5);
      expect(changed, isTrue);
      expect(controller.offset, equals(5));
      tester.pump();
      // After scrolling by 5, Line 6 should be visible, Line 1 should not.
      expect(tester.locateText('Line 6'), isNotNull);
      expect(tester.locateText('Line 1'), isNull);
    });

    test('properties are set correctly', () {
      final vp = Viewport(
        content: 'test',
        width: 30,
        height: 10,
        showScrollbar: true,
        softWrap: true,
        fillHeight: true,
        showLineNumbers: true,
        mouseWheelEnabled: false,
        mouseWheelDelta: 5,
        handleKeys: false,
      );
      expect(vp.content, equals('test'));
      expect(vp.width, equals(30));
      expect(vp.height, equals(10));
      expect(vp.showScrollbar, isTrue);
      expect(vp.softWrap, isTrue);
      expect(vp.fillHeight, isTrue);
      expect(vp.showLineNumbers, isTrue);
      expect(vp.mouseWheelEnabled, isFalse);
      expect(vp.mouseWheelDelta, equals(5));
      expect(vp.handleKeys, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // ScrollView
  // ---------------------------------------------------------------------------
  group('ScrollView', () {
    test('renders child widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 5,
          child: ScrollView(child: Text('ScrollContent')),
        ),
      );
      expect(tester.locateText('ScrollContent'), isNotNull);
    });

    test('renders tall child with limited height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 3,
          child: ScrollView(
            child: Column(
              children: [
                Text('Line A'),
                Text('Line B'),
                Text('Line C'),
                Text('Line D'),
                Text('Line E'),
              ],
            ),
          ),
        ),
      );
      // First 3 lines should be visible
      expect(tester.locateText('Line A'), isNotNull);
      expect(tester.locateText('Line B'), isNotNull);
      expect(tester.locateText('Line C'), isNotNull);
      // Beyond viewport
      expect(tester.locateText('Line D'), isNull);
    });

    test('properties are set correctly', () {
      final sv = ScrollView(
        handleKeys: false,
        mouseWheelDelta: 5,
        child: Text('x'),
      );
      expect(sv.handleKeys, isFalse);
      expect(sv.mouseWheelDelta, equals(5));
    });
  });

  // ---------------------------------------------------------------------------
  // SingleChildScrollView
  // ---------------------------------------------------------------------------
  group('SingleChildScrollView', () {
    test('renders child widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 5,
          child: SingleChildScrollView(child: Text('Scrollable')),
        ),
      );
      expect(tester.locateText('Scrollable'), isNotNull);
    });

    test('limits visible content by height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 2,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('First'),
                Text('Second'),
                Text('Third'),
                Text('Fourth'),
              ],
            ),
          ),
        ),
      );
      expect(tester.locateText('First'), isNotNull);
      expect(tester.locateText('Second'), isNotNull);
      expect(tester.locateText('Third'), isNull);
    });

    test('properties are set correctly', () {
      final ctrl = WidgetScrollController();
      final scsv = SingleChildScrollView(
        controller: ctrl,
        handleKeys: false,
        mouseWheelDelta: 5,
        child: Text('c'),
      );
      expect(scsv.controller, same(ctrl));
      expect(scsv.handleKeys, isFalse);
      expect(scsv.mouseWheelDelta, equals(5));
    });
  });

  // ---------------------------------------------------------------------------
  // ListView
  // ---------------------------------------------------------------------------
  group('ListView', () {
    test('renders list of children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 5,
          child: ListView(
            children: [Text('Item 1'), Text('Item 2'), Text('Item 3')],
          ),
        ),
      );
      expect(tester.locateText('Item 1'), isNotNull);
      expect(tester.locateText('Item 2'), isNotNull);
      expect(tester.locateText('Item 3'), isNotNull);
    });

    test('builder constructor renders generated items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 8,
          child: ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) => Text('Built $index'),
          ),
        ),
      );

      expect(tester.locateText('Built 0'), isNotNull);
      expect(tester.locateText('Built 1'), isNotNull);
      expect(tester.locateText('Built 2'), isNotNull);
      expect(tester.locateText('Built 3'), isNotNull);
    });

    test('separated constructor inserts separator widgets', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 8,
          child: ListView.separated(
            itemCount: 3,
            itemBuilder: (context, index) => Text('Row $index'),
            separatorBuilder: (context, index) => Text('Sep $index'),
          ),
        ),
      );

      expect(tester.locateText('Row 0'), isNotNull);
      expect(tester.locateText('Sep 0'), isNotNull);
      expect(tester.locateText('Sep 1'), isNotNull);
      expect(tester.locateText('Row 2'), isNotNull);
    });

    test('limits visible items by height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 2,
          child: ListView(
            children: [Text('Visible1'), Text('Visible2'), Text('Hidden')],
          ),
        ),
      );
      expect(tester.locateText('Visible1'), isNotNull);
      expect(tester.locateText('Visible2'), isNotNull);
      expect(tester.locateText('Hidden'), isNull);
    });

    test('properties are set correctly', () {
      final lv = ListView(
        separator: '\n\n',
        handleKeys: false,
        mouseWheelDelta: 5,
        children: [Text('a')],
      );
      expect(lv.separator, equals('\n\n'));
      expect(lv.handleKeys, isFalse);
      expect(lv.mouseWheelDelta, equals(5));
    });

    test('controller allows programmatic scrolling', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 30,
          height: 2,
          child: ListView(
            controller: controller,
            children: [Text('A'), Text('B'), Text('C'), Text('D'), Text('E')],
          ),
        ),
      );

      expect(tester.locateText('A'), isNotNull);
      expect(controller.offset, equals(0));

      // External scrollBy triggers re-render via listener → markNeedsPaint.
      final changed = controller.scrollBy(2);
      expect(changed, isTrue);
      expect(controller.offset, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // VirtualListView
  // ---------------------------------------------------------------------------
  group('VirtualListView', () {
    test('renders visible items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Default separator is '\n' which adds 1 line between items.
      // Each item is 1 line, so stride = 2 lines per item.
      // With height 5, we can see items at lines 0, 2, 4 → 3 items visible.
      // Wrap in Container so the VirtualListView receives loose constraints.
      await tester.pumpWidget(
        Container(
          child: VirtualListView(
            width: 30,
            height: 5,
            children: List.generate(20, (i) => Text('Item $i')),
          ),
        ),
      );
      expect(tester.locateText('Item 0'), isNotNull);
      expect(tester.locateText('Item 1'), isNotNull);
      expect(tester.locateText('Item 2'), isNotNull);
      // At least the first visible slice is rendered.
    });

    test('properties are set correctly', () {
      final vlv = VirtualListView(
        width: 20,
        height: 5,
        itemExtent: 2,
        variableHeight: true,
        estimatedItemExtent: 3,
        separator: '---',
        handleKeys: false,
        mouseWheelEnabled: false,
        children: [Text('x')],
      );
      expect(vlv.width, equals(20));
      expect(vlv.height, equals(5));
      expect(vlv.itemExtent, equals(2));
      expect(vlv.variableHeight, isTrue);
      expect(vlv.estimatedItemExtent, equals(3));
      expect(vlv.separator, equals('---'));
      expect(vlv.handleKeys, isFalse);
      expect(vlv.mouseWheelEnabled, isFalse);
    });

    test('builder only mounts fixed-height visible children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ListViewController();
      final built = <int>[];
      final listView = VirtualListView.builder(
        width: 30,
        height: 5,
        controller: controller,
        itemCount: 10_000,
        itemBuilder: (_, i) {
          built.add(i);
          return Text('Row $i');
        },
      );

      await tester.pumpWidget(Container(height: 5, child: listView));

      expect(built, equals(<int>[0, 1, 2]));
      final viewport = _findRenderListViewport(listView);
      expect((viewport as dynamic).debugActiveChildCount, equals(3));
      expect(
        (viewport as dynamic).debugActiveChildIndices,
        equals(<int>{0, 1, 2}),
      );

      controller.jumpTo(2000);
      tester.pump();

      expect(tester.locateText('Row 1000'), isNotNull);
      expect(built, equals(<int>[0, 1, 2, 1000, 1001, 1002]));
      expect((viewport as dynamic).debugActiveChildCount, equals(3));
      expect(
        (viewport as dynamic).debugActiveChildIndices,
        equals(<int>{1000, 1001, 1002}),
      );
    });

    test('builder parent rebuild updates only mounted children', () {
      var revision = 0;
      final built = <String>[];

      VirtualListView makeList() {
        return VirtualListView.builder(
          width: 30,
          height: 5,
          itemCount: 10_000,
          itemBuilder: (_, i) {
            built.add('$revision:$i');
            return Text('R$revision Row $i');
          },
        );
      }

      final tree = ElementTree(makeList());
      addTearDown(tree.unmount);

      expect(tree.render(), contains('R0 Row 0'));
      expect(built, equals(<String>['0:0', '0:1', '0:2']));

      built.clear();
      revision = 1;
      tree.update(makeList());
      final output = tree.render();

      expect(output, contains('R1 Row 0'));
      expect(output, isNot(contains('R1 Row 99')));
      expect(built, equals(<String>['1:0', '1:1', '1:2']));
    });

    test('builder preserves multi-line fixed-height children', () {
      final tree = ElementTree(
        VirtualListView.builder(
          width: 40,
          height: 6,
          itemExtent: 2,
          separator: '',
          itemCount: 3,
          itemBuilder: (_, i) => SizedBox(
            height: 2,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Title $i'),
                  const TextSpan(text: '\n'),
                  TextSpan(text: 'meta $i'),
                ],
              ),
            ),
          ),
        ),
      );
      addTearDown(tree.unmount);

      final output = tree.render();

      expect(output, contains('Title 0'));
      expect(output, contains('meta 0'));
      expect(output, contains('Title 1'));
      expect(output, contains('meta 1'));
      expect(output, contains('Title 2'));
      expect(output, contains('meta 2'));
    });

    test('builder preserves styled padded fixed-height children', () {
      final titleStyle = Style()..foreground(Colors.white);
      final metaStyle = Style()..foreground(Colors.brightBlack);
      final accentStyle = Style()..foreground(Colors.yellow);
      final statusStyle = Style()..foreground(Colors.green);
      final tree = ElementTree(
        VirtualListView.builder(
          width: 48,
          height: 6,
          itemExtent: 2,
          separator: '',
          itemCount: 3,
          itemBuilder: (_, i) => SizedBox(
            height: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              color: i.isEven ? Colors.black : Colors.brightBlack,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '│', style: accentStyle),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: '#${i + 1} Paged PR ${i + 1}',
                      style: titleStyle,
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(text: 'ok', style: statusStyle),
                    const TextSpan(text: '\n  '),
                    TextSpan(text: 'octo$i / updated now', style: metaStyle),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      addTearDown(tree.unmount);

      final output = tree.render();
      final plainLines = Style.stripAnsi(output).split('\n');
      final firstMetaLine = plainLines.indexWhere((line) {
        return line.contains('octo0 / updated now');
      });
      final secondTitleLine = plainLines.indexWhere((line) {
        return line.contains('#2 Paged PR 2');
      });

      expect(output, contains('#1 Paged PR 1'));
      expect(output, contains('octo0'));
      expect(output, contains('#2 Paged PR 2'));
      expect(output, contains('octo1'));
      expect(output, contains('#3 Paged PR 3'));
      expect(output, contains('octo2'));
      expect(firstMetaLine, isNonNegative);
      expect(secondTitleLine, greaterThan(firstMetaLine));
      expect(plainLines[secondTitleLine], isNot(contains('octo0')));
    });

    test('variable height renders visible items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          child: VirtualListView(
            width: 30,
            height: 4,
            variableHeight: true,
            estimatedItemExtent: 2,
            children: [
              Text('Item 0'),
              Text('Item 1\nLine 2'),
              Text('Item 2'),
              Text('Item 3\nLine 2\nLine 3'),
            ],
          ),
        ),
      );

      expect(tester.locateText('Item 0'), isNotNull);
      expect(tester.locateText('Item 1'), isNotNull);
      expect(tester.locateText('Item 2'), isNotNull);
    });

    test(
      'spinner repaint does not repaint unchanged visible siblings',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 8);
        addTearDown(() => tester.dispose());

        final counter = _PaintCounter();
        await tester.pumpWidget(
          Container(
            child: VirtualListView(
              width: 40,
              height: 5,
              variableHeight: true,
              estimatedItemExtent: 2,
              children: [
                Row(
                  children: [
                    SpinnerIndicator(
                      frames: const ['1', '2', '3'],
                      interval: const Duration(milliseconds: 40),
                    ),
                    Text(' spinning'),
                  ],
                ),
                _CountingLeaf(label: 'HEAVY-ROW', counter: counter),
              ],
            ),
          ),
        );

        tester.pump();
        final baselinePaintCount = counter.count;
        expect(baselinePaintCount, greaterThan(0));

        await Future<void>.delayed(const Duration(milliseconds: 180));
        tester.pump();

        final advanced = tester.find.text('2') || tester.find.text('3');
        expect(advanced, isTrue);
        expect(counter.count, lessThanOrEqualTo(baselinePaintCount + 1));
      },
    );

    test('variable height hit testing dispatches taps after scroll', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ListViewController();
      var tapped = -1;

      await tester.pumpWidget(
        Container(
          child: VirtualListView(
            width: 40,
            height: 7,
            controller: controller,
            variableHeight: true,
            estimatedItemExtent: 3,
            children: List.generate(20, (i) {
              final extraLines = List.generate(
                (i % 3) + 1,
                (j) => 'line ${i}_$j',
              ).join('\n');
              return GestureDetector(
                onTap: () {
                  tapped = i;
                  return null;
                },
                child: Text('Tap item $i\n$extraLines'),
              );
            }),
          ),
        ),
      );

      controller.jumpTo(18);
      tester.pump();

      ({int x, int y})? location;
      for (var i = 0; i < 20; i++) {
        final candidate = tester.locateText('Tap item $i');
        if (candidate != null) {
          location = candidate;
          break;
        }
      }

      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(tapped, isNot(equals(-1)));
    });

    test('controller tracks scroll position', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ListViewController();
      await tester.pumpWidget(
        VirtualListView(
          width: 30,
          height: 3,
          controller: controller,
          children: List.generate(20, (i) => Text('Row $i')),
        ),
      );
      expect(controller.offset, equals(0));
      expect(controller.viewportHeight, greaterThan(0));
    });

    test(
      'large variable-height list resolves offsets via fenwick lookup',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final separatorBreaks = 1;
        final itemHeights = List<int>.generate(10_000, (i) => (i % 4) + 1);
        final children = List<Text>.generate(
          itemHeights.length,
          (i) => Text(_variableHeightItem(i, itemHeights[i])),
        );
        final controller = ListViewController();
        final listView = VirtualListView(
          width: 80,
          height: 12,
          controller: controller,
          variableHeight: true,
          estimatedItemExtent: 1,
          separator: '\n',
          children: children,
        );
        await tester.pumpWidget(listView);

        final viewport = _findRenderListViewport(listView);
        final totalHeight = _contentHeightFromHeights(
          itemHeights,
          separatorBreaks,
        );
        final checks = <int>[
          0,
          10,
          123,
          1_000,
          totalHeight ~/ 3,
          totalHeight ~/ 2,
          totalHeight - 1,
        ];

        final resolvedIndices = <int>[];
        for (final offset in checks) {
          final resolved = _resolveOffsetForDebugViewport(viewport, offset);
          final expected = _resolveExpectedItemIndex(
            itemHeights,
            separatorBreaks,
            offset,
          );
          expect(resolved.index, equals(expected));
          expect(resolved.index, greaterThanOrEqualTo(0));
          expect(resolved.index, lessThan(itemHeights.length));
          expect(resolved.offsetInItem, greaterThanOrEqualTo(0));
          resolvedIndices.add(resolved.index);
        }

        for (var i = 0; i < resolvedIndices.length - 1; i++) {
          expect(
            resolvedIndices[i + 1],
            greaterThanOrEqualTo(resolvedIndices[i]),
          );
        }
      },
    );

    test(
      'large variable-height list resolves offsets with 100K+ item count',
      timeout: const Timeout(Duration(minutes: 6)),
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        const itemCount = 100_000;
        final children = List<Widget>.generate(itemCount, (_) => _EmptyLeaf());
        final controller = ListViewController();
        final listView = VirtualListView(
          width: 80,
          height: 12,
          controller: controller,
          variableHeight: true,
          estimatedItemExtent: 1,
          separator: '\n',
          children: children,
        );
        await tester.pumpWidget(listView);
        tester.pump();

        final viewport = _findRenderListViewport(listView);
        final contentHeight = _contentHeightFromHeights(
          List<int>.filled(itemCount, 1),
          1,
        );
        final checks = <int>[
          0,
          10,
          1_000,
          20_000,
          50_000,
          150_000,
          contentHeight - 1,
        ];

        var previousIndex = 0;
        for (final offset in checks) {
          final resolved = _resolveOffsetForDebugViewport(viewport, offset);
          expect(resolved.index, greaterThanOrEqualTo(previousIndex));
          expect(resolved.index, lessThan(itemCount));
          expect(resolved.offsetInItem, greaterThanOrEqualTo(0));
          previousIndex = resolved.index;
        }
      },
    );

    test(
      'variable-height content extent converges after visiting items',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final separatorBreaks = 1;
        final itemHeights = List<int>.generate(120, (i) => (i % 5) + 3);
        final children = List<Text>.generate(
          itemHeights.length,
          (i) => Text(_variableHeightItem(i, itemHeights[i])),
        );
        final expectedTotal = _contentHeightFromHeights(
          itemHeights,
          separatorBreaks,
        );
        final controller = ListViewController();
        final listView = VirtualListView(
          width: 80,
          height: 10,
          controller: controller,
          variableHeight: true,
          estimatedItemExtent: 1,
          separator: '\n',
          children: children,
        );
        await tester.pumpWidget(listView);

        final viewport = _findRenderListViewport(listView);
        final contentHeights = <int>[controller.contentHeight];
        for (var i = 0; i < itemHeights.length; i++) {
          final targetOffset = _variableItemHeightOffset(
            itemHeights,
            i,
            separatorBreaks,
          );
          final resolved = _resolveOffsetForDebugViewport(
            viewport,
            targetOffset,
          );
          expect(resolved.index, equals(i));
          controller.jumpTo(targetOffset);
          tester.pump();
          contentHeights.add(controller.contentHeight);
        }

        expect(contentHeights.last, equals(expectedTotal));
        expect(contentHeights.any((value) => value < expectedTotal), isTrue);
      },
    );
  });

  test(
    'content extent does not shrink when adaptive estimate inflates',
    () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // 38 items: first 3 tall (50 lines), rest short (1 line).
      // Simulates chat with a few diffs followed by short text messages.
      const itemCount = 38;
      final itemHeights = List<int>.generate(
        itemCount,
        (i) => i < 3 ? 50 : 1,
      );
      final children = List<Widget>.generate(
        itemCount,
        (i) => Text(_variableHeightItem(i, itemHeights[i])),
      );

      final controller = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 80,
          height: 10,
          child: VirtualListView(
            width: 80,
            height: 10,
            controller: controller,
            variableHeight: true,
            estimatedItemExtent: 1,
            separator: '\n',
            children: children,
          ),
        ),
      );

      final expectedTotal = _contentHeightFromHeights(itemHeights, 1);
      final extents = <int>[controller.contentExtent];

      // Visit items in chunks to converge measurements across all items.
      for (var i = 0; i < itemCount; i += 5) {
        final targetOffset = _variableItemHeightOffset(
          itemHeights,
          i,
          1,
        );
        controller.jumpTo(targetOffset.clamp(0, controller.maxOffset));
        tester.pump();
        extents.add(controller.contentExtent);
      }

      expect(controller.contentExtent, equals(expectedTotal));

      // Content extent must be monotonically non-decreasing because the
      // estimate (1) is <= every actual item height. A drop would indicate
      // _syncCache rebuilt unmeasured items with an inflated estimate that
      // was then corrected by measurements.
      for (var i = 1; i < extents.length; i++) {
        expect(
          extents[i],
          greaterThanOrEqualTo(extents[i - 1]),
          reason: 'content dropped from ${extents[i - 1]} to ${extents[i]} '
              '-- _syncCache rebuilt with inflated adaptive estimate',
        );
      }
    },
  );

  // ---------------------------------------------------------------------------
  // ScrollArea
  // ---------------------------------------------------------------------------
  group('ScrollArea', () {
    test('renders child widget', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ScrollArea(width: 30, height: 5, child: Text('AreaContent')),
      );
      expect(tester.locateText('AreaContent'), isNotNull);
    });

    test('defaults to showScrollbar true', () {
      final sa = ScrollArea(child: Text('x'));
      expect(sa.showScrollbar, isTrue);
    });

    test('properties are set correctly', () {
      final sa = ScrollArea(
        width: 25,
        height: 8,
        showScrollbar: false,
        child: Text('c'),
      );
      expect(sa.width, equals(25));
      expect(sa.height, equals(8));
      expect(sa.showScrollbar, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration
  // ---------------------------------------------------------------------------
  group('Scroll integration', () {
    test('ListView inside Container with fixed dimensions', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 40,
          height: 5,
          child: ListView(children: [Text('One'), Text('Two'), Text('Three')]),
        ),
      );
      expect(tester.locateText('One'), isNotNull);
      expect(tester.locateText('Two'), isNotNull);
      expect(tester.locateText('Three'), isNotNull);
    });

    test('SingleChildScrollView inside Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Header'),
            Container(
              width: 30,
              height: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: [Text('Scroll1'), Text('Scroll2'), Text('Scroll3')],
                ),
              ),
            ),
          ],
        ),
      );
      expect(tester.locateText('Header'), isNotNull);
      expect(tester.locateText('Scroll1'), isNotNull);
    });

    test('Viewport with scrollbar and controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ViewportController();
      await tester.pumpWidget(
        Viewport(
          content: _lines(50),
          width: 20,
          height: 5,
          showScrollbar: true,
          controller: controller,
        ),
      );

      expect(tester.locateText('Line 1'), isNotNull);
      expect(controller.offset, equals(0));

      // External jumpTo triggers re-render via listener → markNeedsPaint.
      final changed = controller.jumpTo(25);
      expect(changed, isTrue);
      expect(controller.offset, equals(25));
    });
  });
  // ---------------------------------------------------------------------------
  // Bug 4 regression: External scroll triggers re-render via listeners
  // ---------------------------------------------------------------------------
  group('Bug 4 regression — controller listener re-render', () {
    test('ViewportController.scrollBy notifies listeners', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));

      var callCount = 0;
      void listener() => callCount++;
      vc.addListener(listener);

      vc.scrollBy(3);
      expect(callCount, equals(1));

      vc.scrollBy(2);
      expect(callCount, equals(2));

      vc.removeListener(listener);
      vc.scrollBy(1);
      expect(callCount, equals(2)); // no longer listening
    });

    test('ViewportController.jumpTo notifies listeners', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));

      var callCount = 0;
      vc.addListener(() => callCount++);

      vc.jumpTo(10);
      expect(callCount, equals(1));
    });

    test('ViewportController does not notify when position unchanged', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));

      var callCount = 0;
      vc.addListener(() => callCount++);

      // Already at 0, scrolling up should not change
      vc.scrollBy(-1);
      expect(callCount, equals(0));

      // scrollBy(0) returns false, no notification
      vc.scrollBy(0);
      expect(callCount, equals(0));
    });

    test('ListViewController.scrollBy notifies listeners', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(50);

      var callCount = 0;
      void listener() => callCount++;
      lvc.addListener(listener);

      lvc.scrollBy(5);
      expect(callCount, equals(1));

      lvc.scrollBy(3);
      expect(callCount, equals(2));

      lvc.removeListener(listener);
      lvc.scrollBy(1);
      expect(callCount, equals(2)); // no longer listening
    });

    test('ListViewController.jumpTo notifies listeners', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(50);

      var callCount = 0;
      lvc.addListener(() => callCount++);

      lvc.jumpTo(20);
      expect(callCount, equals(1));
    });

    test('ListViewController does not notify when at boundary', () {
      final lvc = ListViewController();
      lvc.setViewportHeight(10);
      lvc.setContentHeight(20);

      var callCount = 0;
      lvc.addListener(() => callCount++);

      // Already at 0, scrolling up should not change
      lvc.scrollBy(-5);
      expect(callCount, equals(0));

      // Scroll to max and try going further
      lvc.jumpTo(10);
      expect(callCount, equals(1));
      lvc.scrollBy(100);
      expect(callCount, equals(1)); // already at max
    });

    test('Viewport external scrollBy triggers visible re-render', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ViewportController();
      // Use unique item labels that are not substrings of each other.
      final content = List.generate(
        30,
        (i) => 'Item-${String.fromCharCode(65 + i % 26)}-$i',
      ).join('\n');
      await tester.pumpWidget(
        Viewport(
          content: content,
          width: 30,
          height: 3,
          controller: controller,
        ),
      );

      // Initially at top
      expect(tester.locateText('Item-A-0'), isNotNull);
      expect(tester.locateText('Item-J-9'), isNull);

      // External scroll — listener fires markNeedsPaint
      controller.scrollBy(9);
      tester.pump();

      // After scrolling by 9, Item-J-9 should be visible, Item-A-0 not
      expect(tester.locateText('Item-J-9'), isNotNull);
      expect(tester.locateText('Item-A-0'), isNull);
    });

    test('Viewport external jumpTo triggers visible re-render', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ViewportController();
      final content = List.generate(
        30,
        (i) => 'Entry-${String.fromCharCode(65 + i % 26)}-$i',
      ).join('\n');
      await tester.pumpWidget(
        Viewport(
          content: content,
          width: 30,
          height: 3,
          controller: controller,
        ),
      );

      expect(tester.locateText('Entry-A-0'), isNotNull);

      controller.jumpTo(20);
      tester.pump();

      // Entry at index 20 should be visible
      expect(tester.locateText('Entry-U-20'), isNotNull);
      expect(tester.locateText('Entry-A-0'), isNull);
    });

    test('VirtualListView external scrollBy triggers re-render', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ListViewController();
      await tester.pumpWidget(
        VirtualListView(
          width: 30,
          height: 5,
          controller: controller,
          children: List.generate(20, (i) => Text('Row $i')),
        ),
      );

      // Initially at top
      expect(tester.locateText('Row 0'), isNotNull);

      // External scrollBy — listener fires markNeedsPaint
      // Default separator '\n' gives stride=2 per item.
      // Scrolling by 4 rows should skip 2 items.
      controller.scrollBy(4);
      tester.pump();

      // Row 2 should now be visible at the top
      expect(tester.locateText('Row 2'), isNotNull);
      expect(tester.locateText('Row 0'), isNull);
    });

    test('VirtualListView external jumpTo triggers re-render', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = ListViewController();
      await tester.pumpWidget(
        VirtualListView(
          width: 30,
          height: 5,
          controller: controller,
          children: List.generate(20, (i) => Text('Row $i')),
        ),
      );

      expect(tester.locateText('Row 0'), isNotNull);

      // Jump to offset 10 — with stride 2, that's item 5
      controller.jumpTo(10);
      tester.pump();

      expect(tester.locateText('Row 5'), isNotNull);
      expect(tester.locateText('Row 0'), isNull);
    });

    test('multiple listeners all fire', () {
      final vc = ViewportController();
      vc.configure(width: 40, height: 5);
      vc.setContent(_lines(20));

      var count1 = 0;
      var count2 = 0;
      vc.addListener(() => count1++);
      vc.addListener(() => count2++);

      vc.scrollBy(1);
      expect(count1, equals(1));
      expect(count2, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // WidgetScrollController unit tests
  // ---------------------------------------------------------------------------
  group('WidgetScrollController', () {
    test('starts at offset 0 with zero extents', () {
      final ctrl = WidgetScrollController();
      expect(ctrl.offset, equals(0));
      expect(ctrl.viewportExtent, equals(0));
      expect(ctrl.contentExtent, equals(0));
      expect(ctrl.maxOffset, equals(0));
      expect(ctrl.scrollPercent, equals(0.0));
    });

    test('updateMetrics sets viewport and content extents', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);
      expect(ctrl.viewportExtent, equals(10));
      expect(ctrl.contentExtent, equals(50));
      expect(ctrl.maxOffset, equals(40));
    });

    test('updateMetrics clamps offset when content shrinks', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);
      ctrl.jumpTo(40); // at max
      expect(ctrl.offset, equals(40));

      // Shrink content — offset should be clamped.
      final clamped = ctrl.updateMetrics(viewportExtent: 10, contentExtent: 20);
      expect(clamped, isTrue);
      expect(ctrl.offset, equals(10)); // new max = 20 - 10
    });

    test('updateMetrics returns false when no clamping needed', () {
      final ctrl = WidgetScrollController();
      final clamped = ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);
      expect(clamped, isFalse);
    });

    test('updateMetrics treats negative values as 0', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: -5, contentExtent: -10);
      expect(ctrl.viewportExtent, equals(0));
      expect(ctrl.contentExtent, equals(0));
      expect(ctrl.maxOffset, equals(0));
    });

    test('scrollBy scrolls within bounds', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);
      expect(ctrl.scrollBy(5), isTrue);
      expect(ctrl.offset, equals(5));
    });

    test('scrollBy clamps to maxOffset', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 20);
      ctrl.scrollBy(100);
      expect(ctrl.offset, equals(10));
    });

    test('scrollBy clamps to 0 (no negative offset)', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 20);
      ctrl.scrollBy(5);
      ctrl.scrollBy(-100);
      expect(ctrl.offset, equals(0));
    });

    test('scrollBy(0) returns false', () {
      final ctrl = WidgetScrollController();
      expect(ctrl.scrollBy(0), isFalse);
    });

    test('scrollBy returns false at boundary', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 20);
      // At top, scrolling up returns false.
      expect(ctrl.scrollBy(-1), isFalse);
      // Scroll to bottom.
      ctrl.jumpTo(10);
      // At bottom, scrolling down returns false.
      expect(ctrl.scrollBy(1), isFalse);
    });

    test('jumpTo sets offset directly', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);
      expect(ctrl.jumpTo(20), isTrue);
      expect(ctrl.offset, equals(20));
    });

    test('jumpTo clamps to bounds', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 20);
      ctrl.jumpTo(100);
      expect(ctrl.offset, equals(10));
      ctrl.jumpTo(-5);
      expect(ctrl.offset, equals(0));
    });

    test('jumpTo returns false when position unchanged', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);
      expect(ctrl.jumpTo(0), isFalse); // already at 0
    });

    test('scrollPercent tracks position correctly', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 20);
      expect(ctrl.scrollPercent, equals(0.0));
      ctrl.jumpTo(5);
      expect(ctrl.scrollPercent, equals(0.5));
      ctrl.jumpTo(10);
      expect(ctrl.scrollPercent, equals(1.0));
    });

    test('scrollPercent is 0 when content fits viewport', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 20, contentExtent: 5);
      expect(ctrl.scrollPercent, equals(0.0));
      expect(ctrl.maxOffset, equals(0));
    });

    test('addListener / removeListener', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);

      var callCount = 0;
      void listener() => callCount++;
      ctrl.addListener(listener);

      ctrl.scrollBy(3);
      expect(callCount, equals(1));

      ctrl.scrollBy(2);
      expect(callCount, equals(2));

      ctrl.removeListener(listener);
      ctrl.scrollBy(1);
      expect(callCount, equals(2)); // no longer listening
    });

    test('jumpTo notifies listeners', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);

      var callCount = 0;
      ctrl.addListener(() => callCount++);

      ctrl.jumpTo(20);
      expect(callCount, equals(1));
    });

    test('does not notify when position unchanged', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);

      var callCount = 0;
      ctrl.addListener(() => callCount++);

      // Already at 0
      ctrl.scrollBy(-1);
      expect(callCount, equals(0));

      ctrl.scrollBy(0);
      expect(callCount, equals(0));

      ctrl.jumpTo(0);
      expect(callCount, equals(0));
    });

    test('multiple listeners all fire', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 10, contentExtent: 50);

      var count1 = 0;
      var count2 = 0;
      ctrl.addListener(() => count1++);
      ctrl.addListener(() => count2++);

      ctrl.scrollBy(1);
      expect(count1, equals(1));
      expect(count2, equals(1));
    });

    test('maxOffset never negative', () {
      final ctrl = WidgetScrollController();
      ctrl.updateMetrics(viewportExtent: 100, contentExtent: 5);
      expect(ctrl.maxOffset, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Scroll integration — StatefulWidget state preservation
  // ---------------------------------------------------------------------------
  group('Scroll StatefulWidget state preservation', () {
    test(
      'SingleChildScrollView preserves StatefulWidget state across scrolls',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 3,
            child: SingleChildScrollView(
              controller: ctrl,
              child: Column(
                children: [
                  Text('Line-A'),
                  Text('Line-B'),
                  Text('Line-C'),
                  _CounterWidget(label: 'Counter'),
                  Text('Line-E'),
                  Text('Line-F'),
                ],
              ),
            ),
          ),
        );

        // Initially Line-A, Line-B, Line-C visible (3 lines).
        expect(tester.locateText('Line-A'), isNotNull);
        expect(tester.locateText('Counter: 0'), isNull); // off-screen

        // Increment the counter via key event.
        tester.sendKey('+');
        tester.pump();

        // Scroll down to see the counter.
        ctrl.scrollBy(3);
        tester.pump();

        // Counter should show incremented value — state preserved.
        expect(tester.locateText('Counter: 1'), isNotNull);
      },
    );

    test('ListView preserves StatefulWidget state across scrolls', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 2,
          child: ListView(
            controller: ctrl,
            children: [
              Text('Item-A'),
              Text('Item-B'),
              _CounterWidget(label: 'ItemCounter'),
              Text('Item-D'),
            ],
          ),
        ),
      );

      // Initially Item-A, Item-B visible.
      expect(tester.locateText('Item-A'), isNotNull);
      expect(tester.locateText('ItemCounter: 0'), isNull);

      // Increment counter.
      tester.sendKey('+');

      // Scroll down to reveal the counter widget.
      ctrl.scrollBy(2);
      tester.pump();

      // Counter state should be preserved.
      expect(tester.locateText('ItemCounter: 1'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Keyboard scrolling tests
  // ---------------------------------------------------------------------------
  group('Keyboard scrolling', () {
    test('SingleChildScrollView scrolls with arrow keys', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 3,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Row-0'),
                Text('Row-1'),
                Text('Row-2'),
                Text('Row-3'),
                Text('Row-4'),
              ],
            ),
          ),
        ),
      );

      // Initially first 3 rows visible.
      expect(tester.locateText('Row-0'), isNotNull);
      expect(tester.locateText('Row-3'), isNull);

      // Press down arrow once — scroll by 1.
      tester.sendSpecialKey(KeyType.down);
      expect(tester.locateText('Row-3'), isNotNull);
      expect(tester.locateText('Row-0'), isNull);

      // Press up arrow — scroll back.
      tester.sendSpecialKey(KeyType.up);
      expect(tester.locateText('Row-0'), isNotNull);
    });

    test('SingleChildScrollView handles PageDown/PageUp', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 3,
          child: SingleChildScrollView(
            child: Column(children: List.generate(20, (i) => Text('PgRow-$i'))),
          ),
        ),
      );

      expect(tester.locateText('PgRow-0'), isNotNull);

      // PageDown scrolls by viewport height (3 rows).
      tester.sendSpecialKey(KeyType.pageDown);
      expect(tester.locateText('PgRow-3'), isNotNull);
      expect(tester.locateText('PgRow-0'), isNull);

      // PageUp scrolls back.
      tester.sendSpecialKey(KeyType.pageUp);
      expect(tester.locateText('PgRow-0'), isNotNull);
    });

    test('SingleChildScrollView handles Home/End', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 3,
          child: SingleChildScrollView(
            child: Column(children: List.generate(10, (i) => Text('HERow-$i'))),
          ),
        ),
      );

      // End — jump to bottom.
      tester.sendSpecialKey(KeyType.end);
      expect(tester.locateText('HERow-9'), isNotNull);
      expect(tester.locateText('HERow-0'), isNull);

      // Home — jump to top.
      tester.sendSpecialKey(KeyType.home);
      expect(tester.locateText('HERow-0'), isNotNull);
    });

    test(
      'SingleChildScrollView ignores keys when handleKeys is false',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 30,
            height: 3,
            child: SingleChildScrollView(
              handleKeys: false,
              child: Column(children: List.generate(10, (i) => Text('NK-$i'))),
            ),
          ),
        );

        expect(tester.locateText('NK-0'), isNotNull);

        // Arrow keys should NOT scroll.
        tester.sendSpecialKey(KeyType.down);
        expect(tester.locateText('NK-0'), isNotNull);
      },
    );

    test('ListView scrolls with arrow keys', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 2,
          child: ListView(
            children: [Text('LV-0'), Text('LV-1'), Text('LV-2'), Text('LV-3')],
          ),
        ),
      );

      expect(tester.locateText('LV-0'), isNotNull);
      expect(tester.locateText('LV-2'), isNull);

      // Down arrow scrolls by 1 line.
      tester.sendSpecialKey(KeyType.down);
      expect(tester.locateText('LV-1'), isNotNull);
    });

    test('ScrollView scrolls with arrow keys', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 3,
          child: ScrollView(
            child: Column(children: List.generate(10, (i) => Text('SV-$i'))),
          ),
        ),
      );

      expect(tester.locateText('SV-0'), isNotNull);
      expect(tester.locateText('SV-3'), isNull);

      tester.sendSpecialKey(KeyType.down);
      expect(tester.locateText('SV-3'), isNotNull);
      expect(tester.locateText('SV-0'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Mouse wheel scrolling tests
  // ---------------------------------------------------------------------------
  group('Mouse wheel scrolling', () {
    test('SingleChildScrollView scrolls on mouse wheel down', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 30,
          height: 3,
          child: SingleChildScrollView(
            mouseWheelDelta: 2,
            child: Column(children: List.generate(20, (i) => Text('MW-$i'))),
          ),
        ),
      );

      expect(tester.locateText('MW-0'), isNotNull);

      // Send mouse wheel down event.
      tester.sendMsg(
        MouseMsg(
          action: MouseAction.press,
          button: MouseButton.wheelDown,
          x: 5,
          y: 1,
        ),
      );

      // Should have scrolled by mouseWheelDelta=2 rows.
      expect(tester.locateText('MW-2'), isNotNull);
      expect(tester.locateText('MW-0'), isNull);
    });

    test('SingleChildScrollView scrolls on mouse wheel up', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 30,
          height: 3,
          child: SingleChildScrollView(
            controller: ctrl,
            mouseWheelDelta: 2,
            child: Column(children: List.generate(20, (i) => Text('MWU-$i'))),
          ),
        ),
      );

      // Scroll down first.
      ctrl.scrollBy(6);
      tester.pump();
      expect(tester.locateText('MWU-6'), isNotNull);

      // Send mouse wheel up event.
      tester.sendMsg(
        MouseMsg(
          action: MouseAction.press,
          button: MouseButton.wheelUp,
          x: 5,
          y: 1,
        ),
      );

      // Should have scrolled up by 2.
      expect(tester.locateText('MWU-4'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Controller shared between Scrollbar and scroll widget
  // ---------------------------------------------------------------------------
  group('Shared scroll controller', () {
    test('SingleChildScrollView and Scrollbar share controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 5,
          child: Scrollbar(
            controller: ctrl,
            child: SingleChildScrollView(
              controller: ctrl,
              child: Column(
                children: List.generate(20, (i) => Text('Shared-$i')),
              ),
            ),
          ),
        ),
      );

      expect(tester.locateText('Shared-0'), isNotNull);

      // Programmatic scroll updates both widgets.
      ctrl.scrollBy(3);
      tester.pump();

      expect(tester.locateText('Shared-3'), isNotNull);
      expect(tester.locateText('Shared-0'), isNull);
      // The scrollbar should be visible (view has content).
      expect(tester.view.isNotEmpty, isTrue);
    });

    test('Scrollbar thumb drag updates shared controller offset', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 24,
          height: 6,
          child: Scrollbar(
            controller: ctrl,
            gap: 1,
            child: SingleChildScrollView(
              controller: ctrl,
              child: Column(
                children: List.generate(40, (i) => Text('Drag-$i')),
              ),
            ),
          ),
        ),
      );

      expect(ctrl.offset, equals(0));

      // Container width=24, gap=1, track width=1 -> track column is x=23.
      tester.mouseDown(23, 1);
      tester.mouseMove(23, 5);
      tester.mouseUp(23, 5);

      expect(ctrl.offset, greaterThan(0));
    });

    test('raw mouse press does not steal scrollbar drag capture', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 24,
          height: 8,
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: ctrl,
                  gap: 1,
                  child: SingleChildScrollView(
                    controller: ctrl,
                    child: Column(
                      children: List.generate(40, (i) => Text('Capture-$i')),
                    ),
                  ),
                ),
              ),
              _GreedyCaptureWidget(),
            ],
          ),
        ),
      );

      expect(ctrl.maxOffset, greaterThan(0));
      expect(ctrl.offset, equals(0));

      // Track column for width=24, gap=1, track=1 is x=23.
      tester.mouseDown(23, 1);
      tester.mouseMove(23, 5);
      tester.mouseUp(23, 5);

      expect(ctrl.offset, greaterThan(0));
      final greedyState =
          tester
                  .elementsWhere((e) => e.widget is _GreedyCaptureWidget)
                  .whereType<StatefulElement>()
                  .first
                  .state
              as _GreedyCaptureWidgetState;
      expect(greedyState.sawRawPress, isFalse);
    });

    test('ListView.builder and Scrollbar share controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = WidgetScrollController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 5,
          child: Scrollbar(
            controller: ctrl,
            child: ListView.builder(
              controller: ctrl,
              itemCount: 30,
              itemBuilder: (context, index) => Text('Builder-$index'),
            ),
          ),
        ),
      );

      expect(tester.locateText('Builder-0'), isNotNull);

      ctrl.scrollBy(8);
      tester.pump();

      expect(tester.locateText('Builder-8'), isNotNull);
      expect(tester.locateText('Builder-0'), isNull);
      expect(tester.view.isNotEmpty, isTrue);
    });

    test(
      'WidgetScrollController updates metrics correctly after layout',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final ctrl = WidgetScrollController();
        await tester.pumpWidget(
          Container(
            width: 30,
            height: 5,
            child: SingleChildScrollView(
              controller: ctrl,
              child: Column(children: List.generate(20, (i) => Text('Met-$i'))),
            ),
          ),
        );

        // After layout, metrics should be set.
        expect(ctrl.viewportExtent, equals(5));
        expect(ctrl.contentExtent, equals(20));
        expect(ctrl.maxOffset, equals(15));
      },
    );
  });
}

/// Helper to generate numbered lines.
String _lines(int count) {
  final buffer = StringBuffer();
  for (var i = 0; i < count; i++) {
    if (i > 0) buffer.write('\n');
    buffer.write('Line ${i + 1}');
  }
  return buffer.toString();
}

/// A simple stateful counter widget used to verify state preservation.
///
/// Increments its counter when a '+' key is pressed.
class _CounterWidget extends StatefulWidget {
  _CounterWidget({required this.label});

  final String label;

  @override
  State createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Text('${widget.label}: $_count');
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg) {
      final key = msg.key;
      if (key.type == KeyType.runes && String.fromCharCodes(key.runes) == '+') {
        setState(() => _count++);
      }
    }
    return null;
  }
}

class _GreedyCaptureWidget extends StatefulWidget {
  @override
  State createState() => _GreedyCaptureWidgetState();
}

class _GreedyCaptureWidgetState extends State<_GreedyCaptureWidget> {
  bool sawRawPress = false;

  @override
  Widget build(BuildContext context) => Text('greedy');

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is MouseMsg &&
        msg.action == MouseAction.press &&
        msg.button == MouseButton.left) {
      sawRawPress = true;
      elementOf(widget)?.captureMouse();
    }
    return null;
  }
}
