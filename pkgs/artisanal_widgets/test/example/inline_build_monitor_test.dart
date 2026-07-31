import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/inline_build_monitor/main.dart' as example;

void main() {
  test('inline build monitor renders the full dashboard', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      example.InlineBuildMonitorView(
        snapshot: example.BuildMonitorSnapshot.initial(),
      ),
      width: 100,
      height: 11,
    );

    expect(tester.find.text(' BUILD #1842'), isTrue);
    expect(tester.find.text('RUNNING'), isTrue);
    expect(tester.viewContains('▶ resolve'), isTrue);
    expect(tester.viewContains('dart pub get'), isTrue);
    expect(tester.viewContains('native scrollback'), isTrue);
    expect(tester.viewContains('jobs/s'), isTrue);
  });

  test('inline build monitor adapts to a narrow terminal', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      example.InlineBuildMonitorView(
        snapshot: example.BuildMonitorSnapshot.initial(),
      ),
      width: 52,
      height: 11,
    );

    expect(tester.viewContains('stage 1/5 · resolve'), isTrue);
    expect(tester.viewContains('p pause · r rebuild'), isTrue);
    expect(tester.viewContains('main → linux-x64'), isFalse);
  });

  test('inline build monitor controls update the live widget state', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      example.InlineBuildMonitor(),
      width: 100,
      height: 11,
    );

    expect(tester.find.text('RUNNING'), isTrue);
    tester.sendKey('p');
    expect(tester.find.text('PAUSED'), isTrue);

    tester.sendKey('r');
    expect(tester.find.text(' BUILD #1843'), isTrue);
    expect(tester.find.text('RUNNING'), isTrue);

    tester.sendKey('e');
    expect(tester.find.text('FAILED'), isTrue);
  });
}
