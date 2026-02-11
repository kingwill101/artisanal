import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  setUp(() {
    tui.initGlobalZone();
  });

  tearDown(() {
    tui.closeGlobalZone();
  });

  test('Viewport registers zone and handles wheel events', () {
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
      scanZones: true,
    );

    final output = app.view();
    expect(output, isNotEmpty);

    final zoneInfo = tui.zone.get('vp');
    expect(zoneInfo, isNotNull);

    final mouse = tui.MouseMsg(
      action: tui.MouseAction.wheel,
      button: tui.MouseButton.wheelDown,
      x: zoneInfo!.startX,
      y: zoneInfo.startY,
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
