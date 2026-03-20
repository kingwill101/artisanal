import 'package:artisanal/testing.dart';
import 'package:artisanal/style.dart' show Style;
import 'package:test/test.dart';

import '../../example/tooltip_trace/main.dart' as example;

void main() {
  test('tooltip trace showcase renders target and state panels', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 64);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TooltipTraceDemoRoot());

    final view = Style.stripAnsi(tester.view);
    expect(view, contains('Tooltip Trace Demo'));
    expect(view, contains('Hover target'));
    expect(view, contains('Recent events'));
    expect(view, contains('hovered: false'));
    expect(view, contains('visibility: hover'));
  });
}
