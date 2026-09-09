import 'dart:typed_data';

import 'package:artisanal/git_diff.dart' as d;
import 'package:artisanal/runtime.dart' as tui;
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/uv.dart' as uv;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

String _patch(int lines) =>
    '''
diff --git a/a.dart b/a.dart
--- a/a.dart
+++ b/a.dart
@@ -0,0 +1,$lines @@
${List.generate(lines, (i) => '+CODE${(i + 1).toString().padLeft(5, '0')}').join('\n')}
''';

d.DiffCommentLineKey _key(int line) => d.DiffCommentLineKey(
  path: 'a.dart',
  line: line,
  side: d.DiffCommentSide.right,
);

d.DiffReviewThread _thread(String id, int line) =>
    d.DiffReviewThread(id: id, range: d.DiffReviewRange(_key(line)));

w.DiffReviewController _controller({
  int lines = 50,
  List<d.DiffReviewThread>? threads,
  int width = 60,
  int height = 8,
}) {
  final controller = w.DiffReviewController(
    d.DiffReviewModel(
      documentId: 'pr',
      revision: '1',
      diff: d.GitDiffModel(width: width, height: height).setDiff(_patch(lines)),
      threads: threads ?? [_thread('thread', 1)],
    ),
  );
  for (final thread in controller.model.threads.values) {
    controller.update(d.DiffReviewExpandMsg(thread.id, expanded: true));
  }
  return controller;
}

class _GrowingBody extends w.StatefulWidget {
  _GrowingBody(this.ready);
  final void Function(void Function(int)) ready;
  @override
  w.State<_GrowingBody> createState() => _GrowingBodyState();
}

class _GrowingBodyState extends w.State<_GrowingBody> {
  int rows = 2;
  @override
  void initState() {
    super.initState();
    widget.ready((value) => setState(() => rows = value));
  }

  @override
  w.Widget build(w.BuildContext context) =>
      w.Text(List.generate(rows, (i) => 'GROW_$i').join('\n'), softWrap: false);
}

void main() {
  for (final explicit in [false, true]) {
    test(
      'parent bounds control review geometry (explicit: $explicit)',
      () async {
        final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
        addTearDown(tester.dispose);
        final controller = _controller(threads: [], width: 100, height: 30);
        final viewport = w.DiffReviewViewport(
          controller: controller,
          width: explicit ? 100 : null,
          height: explicit ? 30 : null,
          threadBuilder: (_, _) => w.Text('BODY'),
        );
        for (final width in [24, 12, 32]) {
          await tester.pumpWidget(
            w.Align(
              alignment: w.Alignment.topLeft,
              child: w.SizedBox(width: width, height: 6, child: viewport),
            ),
          );
          expect(controller.model.diff.width, width);
          expect(controller.model.diff.height, 6);
          expect(controller.scrollController.viewportExtent, 6);
          final expected = d.GitDiffModel(
            width: width,
            height: 6,
          ).setDiff(_patch(50));
          expect(controller.model.diff.renderedLines, expected.renderedLines);
          controller.update(d.DiffReviewSelectMsg(_key(30)));
          controller.revealSelection();
          tester.pump();
          final source = controller.firstVisibleSource();
          expect(source, isNotNull);
          tester.mouseDown(1, 0);
          tester.mouseUp(1, 0);
          tester.pump();
          expect(controller.model.selected, source);
        }
      },
    );
  }

  for (final mode in [d.DiffViewMode.unified, d.DiffViewMode.sideBySide]) {
    test(
      'rich inline cards preserve Kitty payloads and surrounding code in $mode',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 40);
        addTearDown(tester.dispose);
        final controller = _controller(
          width: 80,
          height: 40,
          threads: [_thread('first', 1), _thread('second', 5)],
        );
        controller.update(d.DiffReviewPresentationMsg(viewMode: mode));
        final bytes = Uint8List.fromList(
          img.encodePng(img.Image(width: 4, height: 4)),
        );
        await tester.pumpWidget(
          w.DiffReviewViewport(
            controller: controller,
            width: 80,
            height: 40,
            threadBuilder: (_, placement) => w.Row(
              crossAxisAlignment: w.CrossAxisAlignment.start,
              children: [
                w.Image(
                  image: w.MemoryImage(bytes),
                  width: 8,
                  height: 4,
                  renderMode: w.ImageRenderMode.kitty,
                ),
                w.Column(
                  children: [
                    w.Text('AUTHOR_${placement.thread.id}'),
                    w.Text('BODY_${placement.thread.id}'),
                  ],
                ),
              ],
            ),
          ),
        );
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          tester.pump();
          if (uv
                  .parseTerminalGraphicsControls(tester.view)
                  .where((control) => control.displaysImage)
                  .length ==
              2) {
            break;
          }
        }
        expect(tester.view, contains('\x1b_G'));
        final displays = uv
            .parseTerminalGraphicsControls(tester.view)
            .where((control) => control.displaysImage)
            .toList();
        expect(displays, hasLength(2));
        for (final display in displays) {
          expect(display.sequence, endsWith('\x1b\\'));
          expect(display.sequence, isNot(contains('\n')));
          expect(display.displayColumns, 8);
          expect(display.displayRows, 4);
        }
        expect(tester.view, contains('AUTHOR_first'));
        expect(tester.view, contains('BODY_second'));
        for (var line = 1; line <= 10; line++) {
          expect(
            tester.view,
            contains('CODE${line.toString().padLeft(5, '0')}'),
          );
        }
        final layout = controller.model.diff.layout;
        controller.scrollController.scrollBy(8);
        tester.pump();
        expect(controller.model.diff.layout, same(layout));
        expect(tester.view, contains('BODY_second'));
        controller.scrollController.jumpTo(0);
        tester.pump();
        expect(tester.view, contains('AUTHOR_first'));
      },
    );
  }

  test(
    'real scrollbar drag tolerates body resizing and later collapse',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final controller = _controller(width: 58, height: 8);
      late void Function(int) resizeBody;
      await tester.pumpWidget(
        w.SizedBox(
          width: 60,
          height: 8,
          child: w.Scrollbar(
            controller: controller.scrollController,
            gap: 1,
            child: w.DiffReviewViewport(
              controller: controller,
              width: 58,
              height: 8,
              threadBuilder: (_, _) =>
                  _GrowingBody((resize) => resizeBody = resize),
            ),
          ),
        ),
      );
      final layout = controller.model.diff.layout;
      final scroll = controller.scrollController;
      final initialExtent = scroll.contentExtent;
      tester.mouseDown(59, 0);
      expect(scroll.thumbDragActive, isTrue);
      for (final rows in [12, 3, 17]) {
        resizeBody(rows);
        tester.pump();
        expect(scroll.contentExtent, initialExtent);
        expect(tester.view, contains('GROW_0'));
      }
      tester.mouseMove(59, 7);
      tester.mouseUp(59, 7);
      tester.pump();
      expect(scroll.thumbDragActive, isFalse);
      expect(scroll.contentExtent, layout.lines.length + 18);
      controller.update(const d.DiffReviewExpandMsg('thread', expanded: false));
      tester.pump();
      expect(scroll.contentExtent, layout.lines.length + 1);
      scroll.jumpTo(scroll.maxOffset);
      tester.pump();
      expect(tester.view, contains('CODE00050'));
      expect(controller.model.diff.layout, same(layout));
    },
  );

  test('visible source lookup skips metadata and tall thread bodies', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    final controller = _controller(lines: 20, height: 6);
    await tester.pumpWidget(
      w.DiffReviewViewport(
        controller: controller,
        width: 60,
        height: 6,
        threadBuilder: (_, _) => w.Text('BODY\n' * 20),
      ),
    );
    expect(controller.firstVisibleSource(), _key(1));
    controller.revealThread('thread');
    tester.pump();
    controller.scrollController.scrollBy(2);
    tester.pump();
    expect(controller.firstVisibleSource(), isNull);
    controller.update(d.DiffReviewSelectMsg(_key(12)));
    controller.revealSelection();
    tester.pump();
    expect(controller.firstVisibleSource()!.line, greaterThan(1));
    expect(controller.firstVisibleSource()!.line, lessThanOrEqualTo(12));
  });

  test(
    'rich comments and code share one scroll extent; every tall-card row is reachable',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final controller = _controller(lines: 4, height: 6);
      await tester.pumpWidget(
        w.DiffReviewViewport(
          controller: controller,
          width: 60,
          height: 6,
          threadBuilder: (_, _) =>
              w.Text(List.generate(20, (i) => 'CARD_$i!').join('\n')),
        ),
      );
      final layout = controller.model.diff.layout;
      controller.revealThread('thread');
      tester.pump();
      expect(
        controller.scrollController.contentExtent,
        layout.lines.length + 21,
      );
      final seen = <int>{};
      for (
        var offset = 0;
        offset <= controller.scrollController.maxOffset;
        offset++
      ) {
        controller.scrollController.jumpTo(offset);
        tester.pump();
        expect(
          Style.stripAnsi(
            tester.view,
          ).split('\n').skip(6).every((line) => line.trim().isEmpty),
          isTrue,
        );
        for (final match in RegExp(r'CARD_(\d+)!').allMatches(tester.view)) {
          seen.add(int.parse(match[1]!));
        }
      }
      expect(seen, Set.from(List.generate(20, (i) => i)));
      expect(tester.view, contains('CODE00004'));
      expect(controller.model.diff.layout, same(layout));
    },
  );

  test(
    'wheel and page keys use composed rows, not source-line offsets',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final controller = _controller();
      await tester.pumpWidget(
        w.DiffReviewViewport(
          controller: controller,
          width: 60,
          height: 8,
          threadBuilder: (_, _) =>
              w.Text(List.generate(30, (i) => 'CARD_$i!').join('\n')),
        ),
      );
      controller.revealThread('thread');
      tester.pump();
      final before = controller.scrollController.offset;
      tester.sendMsg(
        const tui.MouseMsg(
          action: tui.MouseAction.press,
          button: tui.MouseButton.wheelDown,
          x: 3,
          y: 2,
        ),
      );
      expect(controller.scrollController.offset, before + 3);
      tester.sendSpecialKey(tui.KeyType.pageDown);
      expect(controller.scrollController.offset, before + 11);
      expect(tester.view, contains('CARD_10!'));
    },
  );

  test(
    'tapping code below a comment selects its source key; tapping header expands',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final controller = _controller(height: 20);
      await tester.pumpWidget(
        w.DiffReviewViewport(
          controller: controller,
          width: 60,
          height: 20,
          threadBuilder: (_, _) => w.Text('COMMENT_BODY'),
        ),
      );
      tester.tap(tester.find.textLocation('CODE00002'));
      expect(controller.model.selected, _key(2));
      final expandedHeight = controller.scrollController.contentExtent;
      tester.tap(tester.find.textLocation('thread'));
      expect(controller.model.expandedThreadIds, isEmpty);
      expect(tester.view, isNot(contains('COMMENT_BODY')));
      expect(controller.scrollController.contentExtent, expandedHeight - 1);
    },
  );

  test('large jumps do not build preceding offscreen thread widgets', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    final controller = _controller(
      lines: 10000,
      threads: [for (var i = 1; i <= 10000; i += 100) _thread('t$i', i)],
    );
    final builds = <String>[];
    await tester.pumpWidget(
      w.DiffReviewViewport(
        controller: controller,
        width: 60,
        height: 8,
        threadBuilder: (_, placement) {
          builds.add(placement.thread.id);
          return w.Text('BODY_${placement.thread.id}');
        },
      ),
    );
    expect(builds.toSet(), {'t1'});
    final layout = controller.model.diff.layout;
    controller.revealThread('t9901');
    tester.pump();
    expect(builds.toSet(), {'t1', 't9901'});
    expect(tester.view, contains('BODY_t9901'));
    controller.revealThread('t1');
    tester.pump();
    expect(tester.view, contains('BODY_t1'));
    expect(controller.model.expandedThreadIds, hasLength(100));
    expect(controller.model.diff.layout, same(layout));
  });

  test(
    'expanding an offscreen thread preserves the visible source anchor',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final controller = _controller();
      await tester.pumpWidget(
        w.DiffReviewViewport(
          controller: controller,
          width: 60,
          height: 8,
          threadBuilder: (_, _) => w.Text('ONE\nTWO\nTHREE\nFOUR'),
        ),
      );
      controller.update(d.DiffReviewSelectMsg(_key(30)));
      controller.revealSelection();
      tester.pump();
      final before = Style.stripAnsi(tester.view);
      controller.update(const d.DiffReviewExpandMsg('thread', expanded: false));
      tester.pump();
      expect(Style.stripAnsi(tester.view), before);
    },
  );

  test('async body growth and shrink update metrics and hit testing', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    final controller = _controller(height: 20);
    late void Function(int) resizeBody;
    await tester.pumpWidget(
      w.DiffReviewViewport(
        controller: controller,
        width: 60,
        height: 20,
        threadBuilder: (_, _) => _GrowingBody((resize) => resizeBody = resize),
      ),
    );
    final before = controller.scrollController.contentExtent;
    resizeBody(10);
    tester.pump();
    expect(controller.scrollController.contentExtent, before + 8);
    expect(tester.view, contains('GROW_9'));
    tester.tap(tester.find.textLocation('CODE00002'));
    expect(controller.model.selected, _key(2));
    resizeBody(1);
    tester.pump();
    expect(controller.scrollController.contentExtent, before - 1);
    expect(tester.view, isNot(contains('GROW_9')));
  });

  test(
    'resize keeps the source selection and uses effective split columns',
    () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 20);
      addTearDown(tester.dispose);
      final controller = _controller(width: 60, height: 20);
      controller.update(
        const d.DiffReviewPresentationMsg(viewMode: d.DiffViewMode.sideBySide),
      );
      await tester.pumpWidget(
        w.DiffReviewViewport(
          controller: controller,
          threadBuilder: (_, _) => w.Text('RIGHT_BODY'),
        ),
      );
      controller.update(d.DiffReviewSelectMsg(_key(1)));
      tester.pump();
      final bodyRow = Style.stripAnsi(
        tester.view,
      ).split('\n').firstWhere((line) => line.contains('RIGHT_BODY'));
      expect(
        bodyRow.indexOf('RIGHT_BODY'),
        controller.model.diff.splitColumns!.leftWidth + 1,
      );
      tester.resize(10, 20);
      expect(controller.model.diff.splitColumns, isNull);
      expect(controller.model.selected, _key(1));
      expect(
        Style.stripAnsi(tester.view)
            .split('\n')
            .firstWhere((line) => line.contains('RIGHT_BODY'))
            .indexOf('RIGHT_BODY'),
        0,
      );
    },
  );

  test('unmapped threads remain visible after an empty patch', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    final controller = w.DiffReviewController(
      d.DiffReviewModel(
        documentId: 'pr',
        revision: '1',
        diff: d.GitDiffModel(),
        threads: [_thread('missing', 999)],
      ),
    );
    await tester.pumpWidget(
      w.DiffReviewViewport(
        controller: controller,
        width: 60,
        height: 8,
        threadBuilder: (_, _) => w.Text('UNMAPPED_BODY'),
      ),
    );
    expect(tester.view, contains('unmapped'));
    tester.tap(tester.find.textLocation('missing'));
    expect(tester.view, contains('UNMAPPED_BODY'));
  });
}
