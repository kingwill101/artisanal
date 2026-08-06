import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/app.dart';
import '../../example/opencode/chords.dart';
import '../../example/opencode/theme.dart';

void main() {
  test('real ctrl+x KeyMsg via hub path shows which-key', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final hub = openCodeKeymapHub();

    await tester.pumpWidget(
      ThemeScope(
        theme: openCodeTheme(),
        child: OpenCodeApp(hub: hub),
      ),
      width: 120,
      height: 40,
    );
    tester.pump();

    tester.sendKey('h');
    tester.sendKey('\n');
    tester.pump();

    final keyMsg = tui.KeyMsg(tui.Keys.ctrl('x'));
    final transformed = hub.onSend(keyMsg);
    print('hub result: $transformed ${transformed.runtimeType}');
    expect(transformed, isA<tui.KeymapSequencePrefixMsg>());

    tester.sendMsg(transformed!);
    tester.pump();
    print('VIEW:\n${tester.view}');
    expect(tester.find.text('which-key'), isTrue, reason: tester.view);
  });

  test('short height still shows which-key', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final hub = openCodeKeymapHub();
    await tester.pumpWidget(
      ThemeScope(
        theme: openCodeTheme(),
        child: OpenCodeApp(hub: hub),
      ),
      width: 80,
      height: 24,
    );
    tester.pump();
    tester.sendKey('h');
    tester.sendKey('\n');
    tester.pump();
    final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
    tester.sendMsg(prefix!);
    tester.pump();
    print('SHORT:\n${tester.view}');
    expect(tester.find.text('which-key'), isTrue, reason: tester.view);
  });
}
