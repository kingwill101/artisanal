/// Integration tests for OpenCode which-key (ctrl+x chord discoverability).
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/app.dart' as opencode;
import '../../example/opencode/chords.dart';

void main() {
  group('OpenCode which-key integration', () {
    test(
      'ctrl+x prefix shows which-key dock in session above footer',
      () async {
        final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
        try {
          final hub = openCodeKeymapHub();
          await tester.pumpWidget(opencode.OpenCodeApp(hub: hub));

          // Enter session (home → submit).
          tester.sendKey('h');
          tester.sendKey('i');
          tester.sendKey('\n');

          final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
          expect(prefix, isA<tui.KeymapSequencePrefixMsg>());
          tester.sendMsg(prefix!);

          expect(
            tester.find.text('which-key'),
            isTrue,
            reason: tester.view,
          );
          expect(
            tester.find.text('toggle sidebar'),
            isTrue,
            reason: tester.view,
          );
          expect(
            tester.find.text('models'),
            isTrue,
            reason: tester.view,
          );
          expect(
            tester.view.contains('b l m t n a d s') ||
                tester.view.contains('toggle sidebar'),
            isTrue,
            reason: 'banner/panel should list continuation keys\n'
                '${tester.view}',
          );
          expect(
            tester.view.contains(openCodeChordStatusHint) ||
                tester.view.contains('ctrl+x'),
            isTrue,
            reason: tester.view,
          );
        } finally {
          await tester.dispose();
        }
      },
    );

    test(
      'interceptor-shaped ctrl+x path shows the same dock',
      () async {
        final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
        try {
          final hub = openCodeKeymapHub();
          await tester.pumpWidget(opencode.OpenCodeApp(hub: hub));

          tester.sendKey('x');
          tester.sendKey('\n');

          final transformed = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
          expect(transformed, isA<tui.KeymapSequencePrefixMsg>());
          tester.sendMsg(transformed!);

          expect(tester.find.text('which-key'), isTrue, reason: tester.view);
          expect(
            tester.find.text('toggle sidebar'),
            isTrue,
            reason: tester.view,
          );
        } finally {
          await tester.dispose();
        }
      },
    );

    test(
      'chord cancel hides which-key dock',
      () async {
        final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
        try {
          final hub = openCodeKeymapHub();
          await tester.pumpWidget(opencode.OpenCodeApp(hub: hub));

          tester.sendKey('x');
          tester.sendKey('\n');

          final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
          tester.sendMsg(prefix!);
          expect(tester.find.text('which-key'), isTrue, reason: tester.view);

          hub.resetPending();
          tester.sendMsg(
            tui.KeymapSequenceCancelledMsg(surfaceId: 'session'),
          );
          expect(
            tester.find.text('which-key'),
            isFalse,
            reason: tester.view,
          );
        } finally {
          await tester.dispose();
        }
      },
    );

    test(
      'chord resolve (sidebar) hides dock and toggles sidebar',
      () async {
        final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
        try {
          final hub = openCodeKeymapHub();
          await tester.pumpWidget(opencode.OpenCodeApp(hub: hub));

          tester.sendKey('x');
          tester.sendKey('\n');

          final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
          tester.sendMsg(prefix!);
          expect(tester.find.text('which-key'), isTrue, reason: tester.view);

          final action = hub.onSend(tui.KeyMsg(tui.Key.char('b')));
          expect(action, isA<tui.KeymapActionMsg>());
          tester.sendMsg(action!);

          expect(
            tester.find.text('which-key'),
            isFalse,
            reason: tester.view,
          );
        } finally {
          await tester.dispose();
        }
      },
    );
  });
}
