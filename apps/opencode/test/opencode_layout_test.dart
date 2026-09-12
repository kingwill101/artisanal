// Test the actual OpenCode app layout dimensions
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/style.dart' as style hide Padding, Align;
import 'package:test/test.dart';

// Minimal inline version of the OpenCode layout
// to test exact sizing behavior

w.Theme _theme() {
  return w.Theme.dark().copyWith(
    background: style.BasicColor('#1a1a2e'),
    surface: style.BasicColor('#25254a'),
    onBackground: style.BasicColor('#e0e0e0'),
    onSurface: style.BasicColor('#d0d0d0'),
    border: style.BasicColor('#3a3a6e'),
    muted: style.BasicColor('#6a6a9e'),
    primary: style.BasicColor('#6366f1'),
  );
}

void main() {
  test('OpenCode-like layout initial render height matches terminal', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
    try {
      final theme = _theme();

      // StatusBar (non-flex)
      final statusBar = w.StatusBar(
        items: [
          w.KeyHint(keyLabel: 'esc', description: 'interrupt'),
          w.KeyHint(keyLabel: 'ctrl+t', description: 'variants'),
          w.KeyHint(keyLabel: 'tab', description: 'agents'),
          w.KeyHint(keyLabel: 'ctrl+p', description: 'commands'),
        ],
        trailing: w.Badge('Claude Opus 4.6'),
      );

      // ChatInput analog (Frame-based)
      final chatInput = w.Frame(
        background: theme.surface,
        border: style.Border.rounded,
        borderColor: theme.border,
        padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 0),
        child: w.Column(
          children: [
            w.Row(
              children: [
                w.Badge('Claude Opus 4.6'),
                w.Spacer(),
                w.Text(
                  'shift+enter for newline',
                  style: style.Style()..foreground(theme.muted),
                ),
              ],
            ),
            w.TextField(placeholder: 'Ask anything...', autofocus: true),
          ],
        ),
      );

      // ChatBody analog (ScrollArea with messages)
      final messages = <w.Widget>[
        for (var i = 0; i < 10; i++) ...[
          w.Text(
            '> User message $i',
            style: style.Style()..foreground(style.BasicColor('#70e070')),
          ),
          w.Text(
            'Assistant reply to message $i with a moderately long response '
            'that contains detailed technical information about the topic at hand.',
          ),
          w.SizedBox(height: 1),
        ],
      ];
      final chatBody = w.ScrollArea(
        showScrollbar: true,
        child: w.Column(children: messages),
      );

      // Chat area column
      final chatArea = w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Expanded(child: chatBody),
          chatInput,
        ],
      );

      // Sidebar
      final sidebar = w.Container(
        color: style.BasicColor('#2a2a4a'),
        padding: const w.EdgeInsets.all(1),
        child: w.Column(
          gap: 1,
          children: [
            w.Text('Context', style: theme.titleSmall),
            w.SizedBox(height: 1),
            w.Text('Model: Claude Opus 4.6'),
            w.Text('Tokens: 128000'),
            w.Text('Used: 42%'),
            w.Text('Spent: \$0.12'),
            w.Text('CWD: ~/code/artisanal'),
            w.Divider(style: style.Style()..foreground(theme.border)),
            w.Text('> LSP'),
            w.Text('v Todo (6)'),
            ...List.generate(
              6,
              (i) => w.Text('  [${i < 3 ? 'x' : ' '}] Todo item $i'),
            ),
            w.Text('v Modified Files (6)'),
            ...List.generate(
              6,
              (i) => w.Column(
                gap: 0,
                children: [
                  w.Text('  file_$i.dart'),
                  w.Text('    +${10 + i} -$i'),
                ],
              ),
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
          child: w.Text('│', style: style.Style()..foreground(theme.border)),
        ),
        first: w.Container(
          color: theme.background,
          padding: const w.EdgeInsets.only(left: 1, right: 1, top: 1),
          child: chatArea,
        ),
        second: sidebar,
      );

      // Full layout
      final fullLayout = w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Expanded(child: mainLayout),
          statusBar,
        ],
      );

      await tester.pumpWidget(
        w.ThemeScope(
          theme: theme,
          child: w.Container(color: theme.background, child: fullLayout),
        ),
      );

      final output = tester.view;
      final height = style.Layout.getHeight(output);
      final width = style.Layout.getWidth(output);
      print(
        'OpenCode layout - Output size: ${width}x$height (expected 120x40)',
      );

      final lines = output.split('\n');
      print('Total lines: ${lines.length}');
      print('--- Last 8 lines ---');
      for (var i = lines.length - 8; i < lines.length; i++) {
        if (i >= 0) {
          final stripped = lines[i].replaceAll(RegExp(r'\x1b\[[^m]*m'), '');
          print(
            '  [$i]: "${stripped.length > 100 ? '${stripped.substring(0, 100)}...' : stripped}"',
          );
        }
      }

      expect(
        height,
        equals(40),
        reason: 'Output height should match terminal height',
      );
      expect(
        output.contains('interrupt'),
        isTrue,
        reason: 'Status bar key hints should be visible',
      );
      expect(
        output.contains('commands'),
        isTrue,
        reason: 'Status bar key hints should be visible',
      );

      // Check that NO individual line exceeds terminal width
      // (this would cause wrapping in the renderer's StyledString.draw)
      var overwidthCount = 0;
      for (var i = 0; i < lines.length; i++) {
        final lineWidth = style.Layout.getWidth(lines[i]);
        if (lineWidth > 120) {
          overwidthCount++;
          print('  LINE $i overwidth: $lineWidth cols (max 120)');
        }
      }
      print('Lines exceeding 120 cols: $overwidthCount');
      expect(
        overwidthCount,
        equals(0),
        reason: 'No line should exceed terminal width (would cause wrapping)',
      );

      // Now verify the last line contains the status bar
      final lastLine = lines.last.replaceAll(RegExp(r'\x1b\[[^m]*m'), '');
      print('Last line content: "$lastLine"');
      expect(
        lastLine.contains('interrupt') || lastLine.contains('commands'),
        isTrue,
        reason: 'Last line should be the status bar',
      );
    } finally {
      await tester.dispose();
    }
  });
}
