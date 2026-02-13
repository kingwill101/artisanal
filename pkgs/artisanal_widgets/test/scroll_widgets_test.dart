import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  test('Viewport handles wheel events via hit-testing', () {
    final controller = w.ViewportController();
    final app = tui.WidgetApp(
      w.Viewport(
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

    final mouse = tui.MouseMsg(
      action: tui.MouseAction.wheel,
      button: tui.MouseButton.wheelDown,
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
