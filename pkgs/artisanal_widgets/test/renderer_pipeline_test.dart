// Test the full renderer pipeline: widget view → StyledString.draw → ScreenBuffer
// This tests what actually gets painted on screen, not just the widget tree output.
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/style.dart' as style hide Padding, Align;
import 'package:artisanal/uv.dart' as uv;
import 'package:artisanal/tui.dart' show View;
import 'package:test/test.dart';

void main() {
  test('Widget view output survives StyledString.draw into ScreenBuffer', () async {
    const termWidth = 120;
    const termHeight = 40;

    final tester = WidgetTester(
      screenWidth: termWidth,
      screenHeight: termHeight,
    );
    try {
      final theme = w.Theme.dark().copyWith(
        background: style.BasicColor('#1a1a2e'),
        surface: style.BasicColor('#25254a'),
        onBackground: style.BasicColor('#e0e0e0'),
        onSurface: style.BasicColor('#d0d0d0'),
        border: style.BasicColor('#3a3a6e'),
        muted: style.BasicColor('#6a6a9e'),
        primary: style.BasicColor('#6366f1'),
      );

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

      // ChatInput analog (Frame-based, like the real app)
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

      // Chat messages
      final messages = <w.Widget>[
        for (var i = 0; i < 10; i++) ...[
          w.Text(
            '> User message $i',
            style: style.Style()..foreground(style.BasicColor('#70e070')),
          ),
          w.Text(
            'Assistant reply to message $i with a moderately long response '
            'that contains detailed technical information.',
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
            w.Divider(style: style.Style()..foreground(theme.border)),
            w.Text('> LSP'),
            w.Text('v Todo (6)'),
            ...List.generate(
              6,
              (i) => w.Text('  [${i < 3 ? 'x' : ' '}] Todo item $i'),
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

      // Get the raw widget view output
      final viewOutput = tester.view;
      final viewLines = viewOutput.split('\n');
      final viewHeight = style.Layout.getHeight(viewOutput);
      final viewWidth = style.Layout.getWidth(viewOutput);
      print('Widget view: ${viewWidth}x$viewHeight lines=${viewLines.length}');

      // Now simulate what the renderer does: draw into a ScreenBuffer
      final screen = uv.ScreenBuffer(termWidth, termHeight);
      final ss = uv.StyledString(viewOutput)..wrap = true;
      ss.draw(screen, screen.bounds());

      // Read back what ended up in the screen buffer
      final screenLines = <String>[];
      for (var y = 0; y < termHeight; y++) {
        final buf = StringBuffer();
        for (var x = 0; x < termWidth; x++) {
          final cell = screen.cellAt(x, y);
          if (cell == null || cell.isZero) {
            buf.write(' ');
          } else {
            buf.write(cell.content);
          }
        }
        screenLines.add(buf.toString());
      }

      print('');
      print('--- ScreenBuffer last 8 lines ---');
      for (var i = termHeight - 8; i < termHeight; i++) {
        final line = screenLines[i].trimRight();
        print(
          '  [$i]: "${line.length > 100 ? '${line.substring(0, 100)}...' : line}"',
        );
      }

      // Check if status bar content is present in the screen buffer
      final lastLine = screenLines[termHeight - 1];
      print('');
      print('Last screen line: "${lastLine.trimRight()}"');

      // The critical assertion: status bar should be on the last line of the screen buffer
      expect(
        lastLine.contains('interrupt') || lastLine.contains('commands'),
        isTrue,
        reason:
            'Status bar should be on the last line of the ScreenBuffer. '
            'This tests the renderer pipeline, not just the widget tree.',
      );

      // Also check for overwidth lines that would cause wrapping
      var overwidthCount = 0;
      for (var i = 0; i < viewLines.length; i++) {
        final lineWidth = style.Layout.getWidth(viewLines[i]);
        if (lineWidth > termWidth) {
          overwidthCount++;
          print('  LINE $i overwidth: $lineWidth cols (max $termWidth)');
        }
      }
      print('Lines exceeding $termWidth cols: $overwidthCount');
    } finally {
      await tester.dispose();
    }
  });

  test('Simple Column+StatusBar survives renderer pipeline', () async {
    const termWidth = 80;
    const termHeight = 24;

    final tester = WidgetTester(
      screenWidth: termWidth,
      screenHeight: termHeight,
    );
    try {
      await tester.pumpWidget(
        w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Expanded(
              child: w.ScrollArea(
                showScrollbar: true,
                child: w.Column(
                  children: List.generate(
                    50,
                    (i) => w.Text('Line $i of content'),
                  ),
                ),
              ),
            ),
            w.Text('== STATUS BAR =='),
          ],
        ),
      );

      final viewOutput = tester.view;
      print(
        'Simple test - view: ${style.Layout.getWidth(viewOutput)}x${style.Layout.getHeight(viewOutput)}',
      );

      // Simulate renderer pipeline
      final screen = uv.ScreenBuffer(termWidth, termHeight);
      final ss = uv.StyledString(viewOutput)..wrap = true;
      ss.draw(screen, screen.bounds());

      // Read back last line
      final buf = StringBuffer();
      for (var x = 0; x < termWidth; x++) {
        final cell = screen.cellAt(x, termHeight - 1);
        if (cell == null || cell.isZero) {
          buf.write(' ');
        } else {
          buf.write(cell.content);
        }
      }
      final lastLine = buf.toString();
      print('Last screen line: "${lastLine.trimRight()}"');

      expect(
        lastLine.contains('STATUS BAR'),
        isTrue,
        reason: 'Status bar should be on the last line after StyledString.draw',
      );
    } finally {
      await tester.dispose();
    }
  });

  test('Full UvTerminalRenderer pipeline: first frame paints status bar', () async {
    const termWidth = 120;
    const termHeight = 40;

    final tester = WidgetTester(
      screenWidth: termWidth,
      screenHeight: termHeight,
    );
    try {
      final theme = w.Theme.dark().copyWith(
        background: style.BasicColor('#1a1a2e'),
        surface: style.BasicColor('#25254a'),
        onBackground: style.BasicColor('#e0e0e0'),
        onSurface: style.BasicColor('#d0d0d0'),
        border: style.BasicColor('#3a3a6e'),
        muted: style.BasicColor('#6a6a9e'),
        primary: style.BasicColor('#6366f1'),
      );

      final statusBar = w.StatusBar(
        items: [
          w.KeyHint(keyLabel: 'esc', description: 'interrupt'),
          w.KeyHint(keyLabel: 'ctrl+t', description: 'variants'),
          w.KeyHint(keyLabel: 'tab', description: 'agents'),
          w.KeyHint(keyLabel: 'ctrl+p', description: 'commands'),
        ],
        trailing: w.Badge('Claude Opus 4.6'),
      );

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

      final messages = <w.Widget>[
        for (var i = 0; i < 10; i++) ...[
          w.Text(
            '> User message $i',
            style: style.Style()..foreground(style.BasicColor('#70e070')),
          ),
          w.Text(
            'Assistant reply to message $i with a moderately long response '
            'that contains detailed technical information.',
          ),
          w.SizedBox(height: 1),
        ],
      ];
      final chatBody = w.ScrollArea(
        showScrollbar: true,
        child: w.Column(children: messages),
      );

      final chatArea = w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Expanded(child: chatBody),
          chatInput,
        ],
      );

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
            w.Divider(style: style.Style()..foreground(theme.border)),
            w.Text('> LSP'),
            w.Text('v Todo (6)'),
            ...List.generate(
              6,
              (i) => w.Text('  [${i < 3 ? 'x' : ' '}] Todo item $i'),
            ),
          ],
        ),
      );

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

      final viewOutput = tester.view;

      // --- Simulate the EXACT same thing UltravioletTuiRenderer does ---

      // 1. Create ScreenBuffer (like renderer._initialize)
      final screen = uv.ScreenBuffer(termWidth, termHeight);

      // 2. Create UvTerminalRenderer with a StringSink to capture output
      final outputBuf = StringBuffer();
      final renderer = uv.UvTerminalRenderer(
        outputBuf,
        env: ['TERM=xterm-256color', 'TTY_FORCE=1'],
      );
      renderer.setFullscreen(true);
      renderer.setRelativeCursor(false);
      renderer.setMapNewline(true);
      renderer.setScrollOptim(true);

      // 3. saveCursor + erase (like renderer._initialize does)
      renderer.saveCursor();
      renderer.erase();

      // 4. Draw widget view into ScreenBuffer (like _flushInternal)
      final ss = uv.StyledString(viewOutput)..wrap = true;
      ss.draw(screen, screen.bounds());

      // 5. Render the buffer through UvTerminalRenderer (the diff engine)
      renderer.render(screen.buffer);
      renderer.flush();

      final terminalOutput = outputBuf.toString();

      // Check if the terminal output contains the status bar text
      final hasInterrupt = terminalOutput.contains('interrupt');
      final hasCommands = terminalOutput.contains('commands');
      final hasVariants = terminalOutput.contains('variants');

      print('Terminal output length: ${terminalOutput.length} bytes');
      print('Contains "interrupt": $hasInterrupt');
      print('Contains "commands": $hasCommands');
      print('Contains "variants": $hasVariants');

      // Also verify the ScreenBuffer has correct content
      final lastLineBuf = StringBuffer();
      for (var x = 0; x < termWidth; x++) {
        final cell = screen.cellAt(x, termHeight - 1);
        if (cell == null || cell.isZero) {
          lastLineBuf.write(' ');
        } else {
          lastLineBuf.write(cell.content);
        }
      }
      final screenLastLine = lastLineBuf.toString();
      print('ScreenBuffer last line: "${screenLastLine.trimRight()}"');

      // Check that UvTerminalRenderer.render() ACTUALLY emitted the status bar
      expect(
        hasInterrupt && hasCommands,
        isTrue,
        reason:
            'UvTerminalRenderer.render() should emit status bar content '
            'on the first frame. Output contained ${terminalOutput.length} bytes.',
      );

      // Also test a SECOND render (same content) to verify frame skipping
      outputBuf.clear();
      final ss2 = uv.StyledString(viewOutput)..wrap = true;
      ss2.draw(screen, screen.bounds());
      renderer.render(screen.buffer);
      renderer.flush();

      final secondOutput = outputBuf.toString();
      print('');
      print('Second render output: ${secondOutput.length} bytes');
      print(
        'Second render skipped: ${secondOutput.isEmpty || secondOutput.length < 10}',
      );
    } finally {
      await tester.dispose();
    }
  });

  test('Full pipeline with View wrapper (backgroundColor set)', () async {
    const termWidth = 120;
    const termHeight = 40;

    final tester = WidgetTester(
      screenWidth: termWidth,
      screenHeight: termHeight,
    );
    try {
      // Simple layout with status bar
      await tester.pumpWidget(
        w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Expanded(
              child: w.ScrollArea(
                showScrollbar: true,
                child: w.Column(
                  children: List.generate(
                    50,
                    (i) => w.Text('Line $i of content'),
                  ),
                ),
              ),
            ),
            w.Text('== STATUS BAR CONTENT =='),
          ],
        ),
      );

      final viewOutput = tester.view;

      // Wrap in View (like WidgetApp does when backgroundColor is set)
      final view = View(
        content: viewOutput,
        backgroundColor: style.BasicColor('#1a1a2e'),
      );

      // Extract content the same way the renderer does
      final String content = view.content;

      // Full renderer pipeline
      final screen = uv.ScreenBuffer(termWidth, termHeight);
      final outputBuf = StringBuffer();
      final renderer = uv.UvTerminalRenderer(
        outputBuf,
        env: ['TERM=xterm-256color', 'TTY_FORCE=1'],
      );
      renderer.setFullscreen(true);
      renderer.setRelativeCursor(false);
      renderer.setMapNewline(true);
      renderer.setScrollOptim(true);
      renderer.saveCursor();
      renderer.erase();

      final ss = uv.StyledString(content)..wrap = true;
      ss.draw(screen, screen.bounds());
      renderer.render(screen.buffer);
      renderer.flush();

      final terminalOutput = outputBuf.toString();
      print('View pipeline output: ${terminalOutput.length} bytes');
      print('Contains STATUS BAR: ${terminalOutput.contains('STATUS BAR')}');

      expect(
        terminalOutput.contains('STATUS BAR'),
        isTrue,
        reason:
            'Status bar should be present in terminal output '
            'even when wrapped in View object',
      );
    } finally {
      await tester.dispose();
    }
  });
}
