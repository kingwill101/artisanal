import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/app.dart';
import '../../example/opencode/chords.dart';
import '../../example/opencode/theme.dart';

void main() {
  test('debug locate which-key after chord', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final hub = openCodeKeymapHub();
    await tester.pumpWidget(
      ThemeScope(theme: openCodeTheme(), child: OpenCodeApp(hub: hub)),
      width: 100,
      height: 30,
    );
    tester.pump();
    tester.sendKey('a');
    tester.sendKey('\n');
    tester.pump();
    final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
    tester.sendMsg(prefix!);
    tester.pump();

    final loc = tester.locateText('which-key');
    print('locate which-key: $loc');
    print('view height lines: ${tester.view.split('\n').length}');
    print('VIEW:\n${tester.view}');
    expect(loc, isNotNull);
  });
}
