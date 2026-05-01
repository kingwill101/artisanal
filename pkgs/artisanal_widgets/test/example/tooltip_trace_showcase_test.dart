import 'package:artisanal/testing.dart';
import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/widgets.dart';
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
    expect(view, contains('Replay History'));
    expect(view, contains('hovered: false'));
    expect(view, contains('visibility: hover'));
  });

  test('tooltip trace showcase can switch replay history filters', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 64);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TooltipTraceDemoRoot());

    tester.tap(
      tester.find.byKeyLocation(ValueKey('replay-history-filter-custom')),
    );

    final view = Style.stripAnsi(tester.view);
    expect(view, contains('filter: custom events'));
    expect(view, contains('No replay events yet.'));
  });

  test('tooltip trace showcase renders replay history mode controls', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 64);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.TooltipTraceDemoRoot());

    final view = Style.stripAnsi(tester.view);
    expect(view, contains('flat'));
    expect(view, contains('grouped'));
    expect(view, contains('mode: grouped'));
  });
}
