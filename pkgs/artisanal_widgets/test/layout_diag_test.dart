import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/style.dart' as style hide Padding, Align;
import 'package:test/test.dart';

void main() {
  test(
    'Full OpenCode-like layout: SplitView + ScrollArea + Frame + StatusBar',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        // Chat messages - lots of text that would overflow
        final messages = List.generate(
          20,
          (i) => w.Text(
            'Message $i: ${List.filled(3, 'lorem ipsum dolor sit amet').join(' ')}',
          ),
        );

        // Chat area: scrollable messages + Frame-based input
        final chatArea = w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Expanded(
              child: w.ScrollArea(
                showScrollbar: true,
                child: w.Column(children: messages),
              ),
            ),
            // ChatInput analog using Frame
            w.Frame(
              border: style.Border.rounded,
              borderColor: style.BasicColor('#555555'),
              child: w.Column(
                children: [
                  w.Row(
                    children: [
                      w.Badge('Claude Opus 4.6'),
                      w.Spacer(),
                      w.Text('shift+enter for newline'),
                    ],
                  ),
                  w.Text('> Ask anything...'),
                ],
              ),
            ),
          ],
        );

        // Sidebar
        final sidebar = w.Container(
          color: style.BasicColor('#2a2a4a'),
          padding: const w.EdgeInsets.all(1),
          child: w.Column(
            gap: 1,
            children: [
              w.Text('Context'),
              w.Text('Model: Claude Opus 4.6'),
              w.Text('Tokens: 128000'),
              w.Divider(),
              w.Text('> LSP'),
              w.Text('v Todo (6)'),
              ...List.generate(
                6,
                (i) => w.Text('  [${i < 3 ? 'x' : ' '}] Todo item $i'),
              ),
              w.Text('v Modified Files (6)'),
              ...List.generate(
                6,
                (i) => w.Text('  file_$i.dart +${10 + i} -$i'),
              ),
            ],
          ),
        );

        // Main layout: chat | sidebar
        final mainLayout = w.SplitView(
          firstFlex: 7,
          secondFlex: 3,
          gap: 0,
          separator: w.SizedBox(
            width: 1,
            child: w.Text(
              '│',
              style: style.Style()..foreground(style.BasicColor('#555555')),
            ),
          ),
          first: w.Container(
            color: style.BasicColor('#1a1a2e'),
            padding: const w.EdgeInsets.only(left: 1, right: 1, top: 1),
            child: chatArea,
          ),
          second: sidebar,
        );

        // Full layout: main + status bar
        final fullLayout = w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Expanded(child: mainLayout),
            w.StatusBar(
              items: [
                w.KeyHint(keyLabel: 'esc', description: 'interrupt'),
                w.KeyHint(keyLabel: 'ctrl+t', description: 'variants'),
                w.KeyHint(keyLabel: 'tab', description: 'agents'),
                w.KeyHint(keyLabel: 'ctrl+p', description: 'commands'),
              ],
              trailing: w.Badge('Claude Opus 4.6'),
            ),
          ],
        );

        await tester.pumpWidget(
          w.Container(color: style.BasicColor('#1a1a2e'), child: fullLayout),
        );

        final output = tester.view;
        final height = style.Layout.getHeight(output);
        final width = style.Layout.getWidth(output);
        print('Output size: ${width}x$height (expected 120x40)');

        final lines = output.split('\n');
        print('Total lines: ${lines.length}');

        // Print first 3 and last 5 lines
        print('--- First 3 lines ---');
        for (var i = 0; i < 3 && i < lines.length; i++) {
          final stripped = lines[i].replaceAll(RegExp(r'\x1b\[[^m]*m'), '');
          print(
            '  [$i]: "${stripped.length > 80 ? '${stripped.substring(0, 80)}...' : stripped}"',
          );
        }
        print('--- Last 5 lines ---');
        for (var i = lines.length - 5; i < lines.length; i++) {
          if (i >= 0) {
            final stripped = lines[i].replaceAll(RegExp(r'\x1b\[[^m]*m'), '');
            print(
              '  [$i]: "${stripped.length > 80 ? '${stripped.substring(0, 80)}...' : stripped}"',
            );
          }
        }

        expect(
          height,
          equals(40),
          reason: 'Output height should match terminal height (40)',
        );
        expect(
          output.contains('interrupt'),
          isTrue,
          reason: 'Status bar should contain "interrupt"',
        );
        expect(
          output.contains('commands'),
          isTrue,
          reason: 'Status bar should contain "commands"',
        );
      } finally {
        await tester.dispose();
      }
    },
  );

  test('Verify Frame inside Column does not break height', () async {
    // The Frame widget ignores constraints. When nested inside a RenderColumn
    // as a non-flex child, the Column measures it via render child collection.
    // This test verifies the Frame's actual paint output height matches what
    // the Column allocated for it.
    final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
    try {
      await tester.pumpWidget(
        w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Expanded(child: w.Text('Top content')),
            w.Frame(
              border: style.Border.rounded,
              child: w.Column(
                children: [
                  w.Row(
                    children: [w.Badge('Badge'), w.Spacer(), w.Text('hint')],
                  ),
                  w.Text('input line'),
                ],
              ),
            ),
            w.Text('STATUS BAR'),
          ],
        ),
      );

      final output = tester.view;
      final height = style.Layout.getHeight(output);
      print(
        'Frame test - Output size: ${style.Layout.getWidth(output)}x$height',
      );

      final lines = output.split('\n');
      for (var i = lines.length - 6; i < lines.length; i++) {
        if (i >= 0) {
          final stripped = lines[i].replaceAll(RegExp(r'\x1b\[[^m]*m'), '');
          print('  [$i]: "$stripped"');
        }
      }

      expect(height, equals(24));
      expect(
        output.contains('STATUS BAR'),
        isTrue,
        reason: 'Status bar must be visible',
      );
    } finally {
      await tester.dispose();
    }
  });
}
