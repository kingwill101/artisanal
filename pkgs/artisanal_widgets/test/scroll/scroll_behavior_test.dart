import 'package:artisanal/runtime.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  test('quarter rows accumulate even across idle gaps', () {
    final wheel = w.ScrollWheelAccumulator();
    var offset = 0;
    final steps = <int>[];
    for (var pulse = 0; pulse < 4; pulse++) {
      final delta = wheel.consume(
        1,
        behavior: const w.ScrollBehavior(wheelStep: .25),
        offset: offset,
        maxOffset: 100,
        timestamp: Duration(seconds: pulse),
      );
      offset += delta;
      steps.add(delta);
    }
    expect(steps, [0, 0, 0, 1]);
  });

  test('adaptive acceleration caps and resets after idle or reversal', () {
    final wheel = w.ScrollWheelAccumulator();
    var offset = 50;
    int pulse(int direction, int milliseconds) {
      final delta = wheel.consume(
        direction,
        behavior: const w.ScrollBehavior(
          wheelStep: 2,
          acceleration: w.ScrollAcceleration.adaptive,
        ),
        offset: offset,
        maxOffset: 200,
        timestamp: Duration(milliseconds: milliseconds),
      );
      offset += delta;
      return delta;
    }

    expect(
      [for (var count = 0; count < 8; count++) pulse(1, count * 20)],
      [2, 3, 4, 5, 6, 7, 8, 8],
    );
    expect(pulse(1, 500), 2);
    expect(pulse(-1, 520), -2);
    expect(pulse(-1, 10), -2);
  });

  test('reversal, policy and external offsets discard stale fractions', () {
    final wheel = w.ScrollWheelAccumulator();
    int pulse(int direction, int offset, [double step = .75]) => wheel.consume(
      direction,
      behavior: w.ScrollBehavior(wheelStep: step),
      offset: offset,
      maxOffset: 20,
      timestamp: Duration.zero,
    );
    expect(pulse(1, 5), 0);
    expect(pulse(-1, 5), 0);
    expect(pulse(-1, 5), -1);
    expect(pulse(-1, 4, .25), 0);
    expect(pulse(-1, 10, .25), 0);
  });

  test('bounds discard pressure without delaying reverse movement', () {
    final wheel = w.ScrollWheelAccumulator();
    const behavior = w.ScrollBehavior(wheelStep: 2);
    expect(wheel.consume(1, behavior: behavior, offset: 9, maxOffset: 10), 1);
    expect(wheel.consume(1, behavior: behavior, offset: 10, maxOffset: 10), 0);
    expect(
      wheel.consume(-1, behavior: behavior, offset: 10, maxOffset: 10),
      -2,
    );
  });

  for (final surface in [
    'single',
    'scroll',
    'list',
    'builder',
    'separated',
    'virtual',
    'virtualBuilder',
    'viewport',
    'scrollbar',
    'gitDiff',
  ]) {
    test(
      '$surface inherits fractional policy and applies live changes',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 6);
        addTearDown(tester.dispose);
        final w.ScrollController controller = surface == 'viewport'
            ? w.ViewportController()
            : w.WidgetScrollController();
        final content = List.generate(80, (index) => 'Line $index').join('\n');
        w.Widget child() => switch (surface) {
          'single' => w.SingleChildScrollView(
            controller: controller,
            child: w.Text(content),
          ),
          'scroll' => w.ScrollView(
            controller: controller,
            child: w.Text(content),
          ),
          'list' => w.ListView(
            controller: controller,
            children: List.generate(80, (index) => w.Text('Line $index')),
          ),
          'builder' => w.ListView.builder(
            controller: controller,
            itemCount: 80,
            itemBuilder: (_, index) => w.Text('Line $index'),
          ),
          'separated' => w.ListView.separated(
            controller: controller,
            itemCount: 80,
            itemBuilder: (_, index) => w.Text('Line $index'),
            separatorBuilder: (_, _) => w.Text('-'),
          ),
          'virtual' => w.VirtualListView(
            controller: controller,
            children: List.generate(80, (index) => w.Text('Line $index')),
          ),
          'virtualBuilder' => w.VirtualListView.builder(
            controller: controller,
            itemCount: 80,
            itemBuilder: (_, index) => w.Text('Line $index'),
          ),
          'viewport' => w.Viewport(
            controller: controller as w.ViewportController,
            content: content,
            width: 40,
            height: 6,
          ),
          'gitDiff' => w.GitDiffViewer(
            diff:
                'diff --git a/a.dart b/a.dart\n--- a/a.dart\n+++ b/a.dart\n@@ -0,0 +1,80 @@\n'
                '${List.generate(80, (index) => '+line $index').join('\n')}',
            scrollController: controller,
            width: 40,
            height: 6,
          ),
          _ => w.Scrollbar(
            controller: controller,
            child: w.SingleChildScrollView(
              controller: controller,
              scrollBehavior: const w.ScrollBehavior(wheelStep: 5),
              child: w.Text(content),
            ),
          ),
        };
        late void Function(double) setStep;
        Future<void> mount() => tester.pumpWidget(
          _PolicyHost(
            ready: (change) => setStep = change,
            child: w.SizedBox(width: 40, height: 6, child: child()),
          ),
        );
        void wheel() => tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: surface == 'scrollbar' ? 39 : 2,
            y: 2,
          ),
        );
        await mount();
        for (var count = 0; count < 3; count++) {
          wheel();
        }
        expect(controller.offset, 0);
        wheel();
        expect(controller.offset, 1);
        setStep(2);
        tester.pump();
        expect(controller.offset, 1);
        wheel();
        expect(controller.offset, 3);
      },
    );
  }

  test(
    'explicit policy overrides scope and fractional child owns its wheel',
    () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 6);
      addTearDown(tester.dispose);
      final outer = w.WidgetScrollController();
      final inner = w.WidgetScrollController();
      await tester.pumpWidget(
        w.ScrollBehaviorScope(
          behavior: const w.ScrollBehavior(wheelStep: 5),
          child: w.SingleChildScrollView(
            controller: outer,
            child: w.Column(
              children: [
                w.SizedBox(
                  height: 3,
                  child: w.SingleChildScrollView(
                    controller: inner,
                    scrollBehavior: const w.ScrollBehavior(wheelStep: .25),
                    child: w.Text(
                      List.generate(30, (index) => 'Inner $index').join('\n'),
                    ),
                  ),
                ),
                w.Text(List.generate(30, (index) => 'Outer $index').join('\n')),
              ],
            ),
          ),
        ),
      );
      for (var count = 0; count < 4; count++) {
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: 2,
            y: 1,
          ),
        );
      }
      expect(inner.offset, 1);
      expect(outer.offset, 0);
    },
  );
}

class _PolicyHost extends w.StatefulWidget {
  _PolicyHost({required this.ready, required this.child});
  final void Function(void Function(double)) ready;
  final w.Widget child;

  @override
  w.State<_PolicyHost> createState() => _PolicyHostState();
}

class _PolicyHostState extends w.State<_PolicyHost> {
  double step = .25;

  @override
  void initState() {
    super.initState();
    widget.ready((value) => setState(() => step = value));
  }

  @override
  w.Widget build(w.BuildContext context) => w.ScrollBehaviorScope(
    behavior: w.ScrollBehavior(wheelStep: step),
    child: widget.child,
  );
}
