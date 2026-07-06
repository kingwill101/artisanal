import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  test('Viewport handles wheel events via hit-testing', () {
    final controller = ViewportController();
    final app = WidgetApp(
      Viewport(
        content: _contentLines(40),
        width: 12,
        height: 4,
        showScrollbar: true,
        controller: controller,
        zoneId: 'vp',
      ),
    );

    final output = app.view();
    expect(output, isNotEmpty);

    final mouse = MouseMsg(
      action: MouseAction.wheel,
      button: MouseButton.wheelDown,
      x: 0,
      y: 0,
    );

    app.update(mouse);
    expect(controller.yOffset, greaterThan(0));
  });
}

String _contentLines(int count) {
  final buffer = StringBuffer();
  for (var i = 0; i < count; i++) {
    buffer.writeln('Item ${i + 1}');
  }
  return buffer.toString().trimRight();
}
