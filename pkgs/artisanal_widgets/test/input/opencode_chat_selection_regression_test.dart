import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import 'package:dash_ui/dash_ui.dart';
import '../../example/opencode/widgets/chat_body.dart';

void main() {
  test('chat body auto-copies and clears selection on mouse up', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final controller = WidgetScrollController();
    final messages = <ChatMessage>[
      ChatMessage.user('User selectable content line'),
      ChatMessage.assistant(const [TextPart('Assistant selectable text line')]),
    ];

    await tester.pumpWidget(
      Container(
        width: 110,
        height: 20,
        child: ChatBody(messages: messages, scrollController: controller),
      ),
    );

    final pos = tester.locateText('Assistant selectable text line');
    expect(pos, isNotNull);
    final start = pos!;

    tester.mouseDown(start.x, start.y);
    tester.mouseMove(start.x + 9, start.y);
    tester.mouseUp(start.x + 9, start.y);

    expect(controller.hasSelection, isFalse);
  });

  test(
    'chat body finalizes selection when pointer leaves hit-test area',
    () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = WidgetScrollController();
      final messages = <ChatMessage>[
        ChatMessage.user('User selectable content line'),
        ChatMessage.assistant(const [
          TextPart('Assistant selectable text line'),
        ]),
      ];

      await tester.pumpWidget(
        Container(
          width: 110,
          height: 20,
          child: ChatBody(messages: messages, scrollController: controller),
        ),
      );

      final pos = tester.locateText('Assistant selectable text line');
      expect(pos, isNotNull);
      final start = pos!;

      tester.mouseDown(start.x, start.y);
      tester.mouseMove(start.x + 9, start.y);
      expect(controller.hasSelection, isTrue);

      // Move outside chat body while still dragging. Selection should auto-copy
      // and clear immediately (no need to mouse-up over chat area).
      tester.sendMsg(
        const tui.MouseMsg(
          action: tui.MouseAction.motion,
          button: tui.MouseButton.none,
          x: 200,
          y: 50,
        ),
      );

      expect(controller.hasSelection, isFalse);
    },
  );

  test('chat body scrollbar thumb drag scrolls content', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 30);
    addTearDown(() => tester.dispose());

    final controller = WidgetScrollController();
    final messages = List<ChatMessage>.generate(
      80,
      (i) => ChatMessage.assistant([TextPart('Scrollable assistant line $i')]),
    );

    await tester.pumpWidget(
      Container(
        width: 110,
        height: 20,
        child: ChatBody(messages: messages, scrollController: controller),
      ),
    );

    expect(controller.maxOffset, greaterThan(0));
    expect(controller.offset, equals(0));

    // width=110, gap=1, gutter=3 -> track columns 107..109
    tester.mouseDown(109, 2);
    tester.mouseMove(109, 16);
    tester.mouseUp(109, 16);

    expect(controller.offset, greaterThan(0));
  });
}
