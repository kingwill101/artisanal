import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/help_view/main.dart';

const _traceEnv = 'TRACE_HELP_VIEW_RENDER';

void _dumpFrame(String label, String view, {int maxLines = 16}) {
  final lines = view.split('\n');
  final limit = math.min(lines.length, maxLines);

  print('=== $label raw ===');
  for (var i = 0; i < limit; i++) {
    final lineNo = i.toString().padLeft(2, '0');
    print('$lineNo| ${jsonEncode(lines[i])}');
  }

  print('=== $label plain ===');
  for (var i = 0; i < limit; i++) {
    final lineNo = i.toString().padLeft(2, '0');
    print('$lineNo| ${Layout.stripAnsi(lines[i])}');
  }
}

void main() {
  test(
    'diagnostic: trace HelpView showcase rendering while scrolling',
    () async {
      if (Platform.environment[_traceEnv] != '1') return;

      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(HelpViewShowcase(), width: 100, height: 24);
      tester.pump();
      _dumpFrame('initial', tester.view);

      for (var step = 1; step <= 8; step++) {
        tester.sendMsg(
          const tui.MouseMsg(
            action: tui.MouseAction.wheel,
            button: tui.MouseButton.wheelDown,
            x: 10,
            y: 10,
          ),
        );
        _dumpFrame('scroll $step', tester.view);
      }
    },
  );
}
