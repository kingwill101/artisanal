import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

import '../../example/container_align/main.dart' as container_align;
import '../../example/layout/main.dart' as layout;
import '../../example/layout_builder/main.dart' as layout_builder;
import '../../example/limited_box/main.dart' as limited_box;
import '../../example/overflow_box/main.dart' as overflow_box;
import '../../example/uv_effects/main.dart' as uv_effects;

void main() {
  test(
    'UV effects handles unbounded width without converting infinity',
    () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 40);
      addTearDown(tester.dispose);
      await tester.pumpWidget(Row(children: [uv_effects.UvEffectsDemo()]));
      _expectHealthy(tester, 'UV Effects for Widget Subtrees');
      expect(tester.find.byType<TUIErrorWidget>(), isEmpty);
    },
  );

  test(
    'UV effects uses a size hint instead of oversized scenes in narrow panes',
    () async {
      final tester = WidgetTester(screenWidth: 24, screenHeight: 40);
      addTearDown(tester.dispose);
      await tester.pumpWidget(uv_effects.UvEffectsDemo());
      _expectHealthy(tester, 'Widen terminal');
      expect(tester.find.byType<Frame>(), isEmpty);
      tester.resize(80, 40);
      _expectHealthy(tester, 'UV Effects for Widget Subtrees');
      expect(tester.find.byType<Frame>(), isNotEmpty);
      expect(tester.find.text('Original widgets'), isTrue);
      expect(tester.find.text('CellFilter · Grayscale'), isTrue);
    },
  );

  final cases = <({String name, Widget Function() create, String content})>[
    (
      name: 'layout builder',
      create: layout_builder.LayoutBuilderExample.new,
      content: 'LayoutBuilder Widget',
    ),
    (
      name: 'UV effects',
      create: uv_effects.UvEffectsDemo.new,
      content: 'UV Effects for Widget Subtrees',
    ),
    (
      name: 'layout',
      create: layout.LayoutShowcase.new,
      content: 'Layout Primitives',
    ),
    (
      name: 'container and align',
      create: container_align.ContainerAlignShowcase.new,
      content: 'Container & Alignment Showcase',
    ),
    (
      name: 'overflow box',
      create: overflow_box.OverflowBoxDemo.new,
      content: 'OverflowBox & SizedOverflowBox Demo',
    ),
    (
      name: 'limited box',
      create: limited_box.LimitedBoxDemo.new,
      content: 'LimitedBox Widget Demo',
    ),
  ];

  for (final example in cases) {
    test(
      '${example.name} survives parent constraint sizes and resize',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(tester.dispose);

        await tester.pumpWidget(example.create());
        _expectHealthy(tester, example.content);
        if (example.name == 'layout builder') {
          expect(
            tester.find.text('maxHeight: unbounded'),
            isTrue,
            reason: tester.view,
          );
        }

        for (final size in [(40, 12), (120, 40), (80, 24)]) {
          tester.resize(size.$1, size.$2);
          await Future<void>.delayed(Duration.zero);
          _expectHealthy(tester, example.content);
        }
      },
    );
  }

  test('UV effects selection remains interactive after resizing', () async {
    final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
    addTearDown(tester.dispose);

    await tester.pumpWidget(uv_effects.UvEffectsDemo());
    expect(
      tester.find.text('CellFilter · Grayscale'),
      isTrue,
      reason: tester.view,
    );
    tester.sendSpecialKey(tui.KeyType.right);
    expect(
      tester.find.text('CellFilter · Invert'),
      isTrue,
      reason: tester.view,
    );
    tester.resize(40, 12);
    await Future<void>.delayed(Duration.zero);
    tester.sendKey('7');
    // The narrow view scrolls the scenes below the fold; the selection strip
    // remains visible and proves the key interaction updated the real app.
    expect(tester.find.text('[7:Custom stack]'), isTrue, reason: tester.view);
    _expectHealthy(tester, 'UV Effects for Widget Subtrees');
  });
}

void _expectHealthy(WidgetTester tester, String content) {
  expect(
    tester.viewContains('Unhandled exception'),
    isFalse,
    reason: tester.view,
  );
  expect(tester.find.text(content), isTrue, reason: tester.view);
}
