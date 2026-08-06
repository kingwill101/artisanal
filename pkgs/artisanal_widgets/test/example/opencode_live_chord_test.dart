import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/app.dart';
import '../../example/opencode/chords.dart';
import '../../example/opencode/theme.dart';

void main() {
  test('full interceptor + program send shows which-key and footer hint', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final hub = openCodeKeymapHub();

    await tester.pumpWidget(
      ThemeScope(theme: openCodeTheme(), child: OpenCodeApp(hub: hub)),
      width: 120,
      height: 36,
    );
    tester.pump();

    // Navigate to session (registers session surface).
    tester.sendKey('x');
    tester.sendKey('\n');
    tester.pump();

    final raw = tui.KeyMsg(tui.Keys.ctrl('x'));
    final out = hub.onSend(raw);
    expect(out, isA<tui.KeymapSequencePrefixMsg>());
    tester.sendMsg(out!);
    tester.pump();

    print('VIEW:\n${tester.view}');
    expect(tester.find.text('which-key'), isTrue, reason: tester.view);
    expect(tester.find.text('toggle sidebar'), isTrue, reason: tester.view);
    expect(
      tester.view.contains(openCodeChordStatusHint) ||
          tester.view.contains('ctrl+x'),
      isTrue,
      reason: tester.view,
    );
  });
}
