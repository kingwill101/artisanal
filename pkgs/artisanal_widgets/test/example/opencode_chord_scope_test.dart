import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/app.dart';
import '../../example/opencode/chords.dart';
import '../../example/opencode/theme.dart';

void main() {
  test('sequence prefix shows which-key above session footer', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final hub = openCodeKeymapHub();
    await tester.pumpWidget(
      ThemeScope(theme: openCodeTheme(), child: OpenCodeApp(hub: hub)),
      width: 120,
      height: 40,
    );
    tester.pump();

    tester.sendKey('h');
    tester.sendKey('\n');
    tester.pump();

    final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
    tester.sendMsg(prefix!);
    tester.pump();

    print('VIEW:\n${tester.view}');
    expect(tester.find.text('which-key'), isTrue, reason: tester.view);
    expect(tester.find.text('toggle sidebar'), isTrue);
    expect(
      tester.view.contains('b l m t n a d s') ||
          tester.view.contains('toggle sidebar'),
      isTrue,
      reason: tester.view,
    );
  });
}
