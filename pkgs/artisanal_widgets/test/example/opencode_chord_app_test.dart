import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/app.dart';
import '../../example/opencode/chords.dart';
import '../../example/opencode/theme.dart';

void main() {
  test('KeymapSequencePrefix shows which-key overlay', () async {
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

    // Which-key dock is painted by the session shell (above footer).
    tester.sendKey('h');
    tester.sendKey('\n');
    tester.pump();

    final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
    expect(prefix, isA<tui.KeymapSequencePrefixMsg>());
    tester.sendMsg(prefix!);
    tester.pump();
    print('SESSION CHORD:\n${tester.view}');
    expect(tester.find.text('which-key'), isTrue, reason: tester.view);
    expect(tester.find.text('toggle sidebar'), isTrue);
    expect(tester.find.text('models'), isTrue);
    expect(tester.find.text('themes'), isTrue);

    tester.sendMsg(
      tui.KeymapSequenceCancelledMsg(surfaceId: 'session'),
    );
    tester.pump();
    expect(tester.find.text('which-key'), isFalse);
  });
}
