import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/src/widgets/element.dart' show elementOf;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  test('paint-only invalidation cannot downgrade pending layout work', () {
    final box = _CountingBox();
    expect(box.paintOnlyDirty, isFalse);
    box.markNeedsPaintOnly();
    expect(box.paintOnlyDirty, isFalse);
    box.clearPaintDirty();
    box.markNeedsPaintOnly();
    expect(box.paintOnlyDirty, isTrue);
    box.markDescendantNeedsPaint();
    box.markNeedsPaintOnly();
    expect(box.paintOnlyDirty, isFalse);
    box.clearPaintDirtySubtree();
    expect(box.paintDirty, isFalse);
    expect(box.paintOnlyDirty, isFalse);
  });

  test('offset-only scrolling reuses document layout and paint', () async {
    final tester = WidgetTester(screenWidth: 60, screenHeight: 12);
    final scroll = w.WidgetScrollController();
    final content = _CountingContent();
    addTearDown(tester.dispose);
    await tester.pumpWidget(_host(scroll, content));
    expect(content.box.layouts, greaterThan(0));
    expect(scroll.maxOffset, greaterThan(0));
    final layouts = content.box.layouts;
    final paints = content.box.paints;
    final initial = tester.view;

    for (var i = 1; i <= 5; i++) {
      expect(scroll.scrollBy(1), isTrue);
      tester.pump();
      expect(
        Style.stripAnsi(tester.view).split('\n').first,
        contains('row $i'),
      );
      expect(content.box.layouts, layouts);
      expect(content.box.paints, paints);
    }
    expect(tester.view, isNot(initial));
  });

  test(
    'resize and generic invalidation cannot reuse scroll-only layout',
    () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 12);
      final scroll = w.WidgetScrollController();
      final content = _CountingContent();
      addTearDown(tester.dispose);
      await tester.pumpWidget(_host(scroll, content));

      final beforeResize = content.box.layouts;
      scroll.scrollBy(1);
      tester.resize(72, 16);
      tester.pump();
      expect(content.box.layouts, greaterThan(beforeResize));
      expect(content.box.constraints.maxWidth, greaterThan(60));

      for (final scrollFirst in [false, true]) {
        final layouts = content.box.layouts;
        final paints = content.box.paints;
        if (scrollFirst) scroll.scrollBy(1);
        content.box
          ..rows += 10
          ..prefix = 'updated ${content.box.rows}';
        elementOf(content)!.markNeedsPaint();
        if (!scrollFirst) scroll.scrollBy(1);
        tester.pump();
        expect(content.box.layouts, greaterThan(layouts));
        expect(content.box.paints, greaterThan(paints));
        expect(Style.stripAnsi(tester.view), contains(content.box.prefix));
        expect(scroll.contentExtent, content.box.rows);
      }

      final gutterWidth = content.box.constraints.maxWidth;
      content.box.rows = 2;
      elementOf(content)!.markNeedsPaint();
      tester.pump();
      expect(scroll.maxOffset, 0);
      expect(content.box.constraints.maxWidth, greaterThan(gutterWidth));

      content.box.rows = 100;
      elementOf(content)!.markNeedsPaint();
      tester.pump();
      expect(scroll.maxOffset, greaterThan(0));
      expect(content.box.constraints.maxWidth, gutterWidth);
    },
  );

  test(
    'scrollbar refreshes layout-painted wrappers at the retained width',
    () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 12);
      final scroll = w.WidgetScrollController();
      final content = _CountingContent();
      addTearDown(tester.dispose);
      await tester.pumpWidget(
        w.ThemeScope(
          theme: w.Theme.dark(),
          child: w.Scrollbar(
            controller: scroll,
            child: w.Opacity(
              opacity: 1,
              child: w.Padding(
                padding: const w.EdgeInsets.symmetric(vertical: 1),
                child: w.SingleChildScrollView(
                  controller: scroll,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      );
      final layouts = content.box.layouts;
      final paints = content.box.paints;
      expect(scroll.scrollBy(4), isTrue);
      tester.pump();
      final visible = Style.stripAnsi(tester.view);
      expect(visible, contains('row 4'));
      expect(visible, isNot(contains('row 0')));
      expect(content.box.layouts, layouts);
      expect(content.box.paints, paints);
    },
  );
}

w.Widget _host(w.WidgetScrollController scroll, w.Widget child) {
  return w.ThemeScope(
    theme: w.Theme.dark(),
    child: w.Stack(
      fit: w.StackFit.expand,
      children: [
        w.Opacity(
          opacity: 1,
          child: w.Container(
            child: w.ScrollArea(controller: scroll, child: child),
          ),
        ),
      ],
    ),
  );
}

class _CountingContent extends w.LeafRenderObjectWidget {
  late _CountingBox box;

  @override
  w.RenderObject createRenderObject() => box = _CountingBox();

  @override
  Object view() => '';
}

class _CountingBox extends w.RenderBox {
  int layouts = 0;
  int paints = 0;
  int rows = 100;
  String prefix = 'row';

  @override
  void layout(w.BoxConstraints constraints) {
    layouts++;
    super.layout(constraints);
    size = constraints.constrain(
      w.Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : 30,
        rows.toDouble(),
      ),
    );
  }

  @override
  String paint() {
    paints++;
    return List.generate(rows, (index) => '$prefix $index').join('\n');
  }
}
