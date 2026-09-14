import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  test('pointer releases follow the owner of the original press', () {
    final controller = ProgramDevToolsController(
      ProgramDiagnosticsOptions(initiallyVisible: true),
    );
    controller.handle(const WindowSizeMsg(100, 30));
    final body = _point(controller, 'FPS:');
    expect(controller.handle(_mouse(0, 29, MouseAction.press)), isFalse);
    expect(
      controller.handle(_mouse(body.x, body.y, MouseAction.release)),
      isFalse,
    );
    expect(
      controller.handle(_mouse(body.x, body.y, MouseAction.press)),
      isTrue,
    );
    expect(controller.handle(_mouse(0, 29, MouseAction.release)), isTrue);
    expect(controller.handle(_mouse(0, 29, MouseAction.release)), isFalse);
  });

  test('F12 opens at the configured corner, not the model fallback', () {
    final controller = ProgramDevToolsController(ProgramDiagnosticsOptions());
    controller.handle(const WindowSizeMsg(100, 30));
    controller.handle(const KeyMsg(Key(KeyType.f12)));
    expect(_point(controller, 'Artisanal DevTools').y, 0);
  });

  test(
    'mouse tabs, title dragging, toggling and resize share painted bounds',
    () {
      final controller = ProgramDevToolsController(
        ProgramDiagnosticsOptions(
          initiallyVisible: true,
          position: ProgramDiagnosticsPosition.bottomRight,
        ),
      );
      controller.handle(const WindowSizeMsg(100, 30));
      expect(_point(controller, 'Artisanal DevTools').y, greaterThan(0));
      _click(controller, 'messages');
      expect(controller.compose('').toString(), contains('[messages]'));

      final header = _point(controller, 'Messages');
      expect(
        controller.handle(_mouse(header.x, header.y, MouseAction.press)),
        isTrue,
      );
      expect(
        controller.handle(
          _mouse(header.x - 20, header.y - 10, MouseAction.motion),
        ),
        isTrue,
      );
      controller.handle(
        _mouse(header.x - 20, header.y - 10, MouseAction.release),
      );
      final moved = _point(controller, 'Messages');
      expect(moved, (x: header.x - 20, y: header.y - 10));

      _click(controller, 'output');
      expect(controller.compose('').toString(), contains('[output]'));
      expect(_point(controller, 'Captured Output'), moved);
      controller.handle(const KeyMsg(Key(KeyType.f12)));
      controller.handle(const KeyMsg(Key(KeyType.f12)));
      expect(_point(controller, 'Captured Output'), moved);

      controller.handle(const WindowSizeMsg(60, 18));
      final resized = _point(controller, 'Captured Output');
      expect(resized.x, lessThan(moved.x));
      expect(resized.y, lessThanOrEqualTo(moved.y));
      expect(controller.handle(const KeyMsg(Key(KeyType.tab))), isFalse);
      expect(controller.handle(_mouse(0, 0, MouseAction.press)), isFalse);
    },
  );

  test('wheel over message history scrolls only that panel', () {
    final controller = ProgramDevToolsController(
      ProgramDiagnosticsOptions(initiallyVisible: true, maxMessages: 2),
    );
    controller.handle(const WindowSizeMsg(100, 30));
    for (var i = 0; i < 8; i++) {
      controller.diagnostics.recordMessage(CustomMsg('item-$i'), Duration.zero);
    }
    controller.diagnosticsChanged();
    _click(controller, 'messages');
    expect(controller.compose('').toString(), contains('item-7'));
    final point = _point(controller, '[messages]');
    expect(
      controller.handle(
        MouseMsg(
          x: point.x,
          y: point.y,
          action: MouseAction.press,
          button: MouseButton.wheelDown,
        ),
      ),
      isTrue,
    );
    expect(controller.compose('').toString(), contains('item-4'));
    expect(controller.compose('').toString(), isNot(contains('item-7')));
    expect(
      controller.handle(
        const MouseMsg(
          x: 0,
          y: 29,
          action: MouseAction.press,
          button: MouseButton.wheelDown,
        ),
      ),
      isFalse,
    );
  });
}

MouseMsg _mouse(int x, int y, MouseAction action) =>
    MouseMsg(x: x, y: y, action: action, button: MouseButton.left);

({int x, int y}) _point(ProgramDevToolsController controller, String text) {
  final lines = Style.stripAnsi(controller.compose('').toString()).split('\n');
  for (var y = 0; y < lines.length; y++) {
    final x = lines[y].indexOf(text);
    if (x >= 0) return (x: x, y: y);
  }
  fail('Could not find $text in ${lines.join('\n')}');
}

void _click(ProgramDevToolsController controller, String text) {
  final point = _point(controller, text);
  expect(
    controller.handle(_mouse(point.x, point.y, MouseAction.press)),
    isTrue,
  );
  controller.handle(_mouse(point.x, point.y, MouseAction.release));
}
