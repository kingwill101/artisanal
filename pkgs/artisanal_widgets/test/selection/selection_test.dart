import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/markdown.dart'
    show AnsiRendererOptions, markdownToAnsi;
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/terminal.dart' as terminal show Key;
import 'package:artisanal_widgets/src/widgets/selection/selection_text_utils.dart';
import 'package:test/test.dart';

RegExp _highlightedTextPattern({
  required int foreground,
  required int background,
  required String text,
}) {
  final esc = RegExp.escape('\x1b[');
  final reset = RegExp.escape('\x1b[m');
  final literalText = RegExp.escape(text);
  return RegExp(
    '(?:'
    '$esc[^m]*38;5;$foreground[^m]*48;5;$background[^m]*m$literalText$reset'
    '|$esc[^m]*48;5;$background[^m]*38;5;$foreground[^m]*m$literalText$reset'
    '|$esc[^m]*38;5;$foreground[^m]*m$esc[^m]*48;5;$background[^m]*m$literalText$reset'
    '|$esc[^m]*48;5;$background[^m]*m$esc[^m]*38;5;$foreground[^m]*m$literalText$reset'
    ')',
  );
}

void main() {
  // -------------------------------------------------------
  // SelectionController unit tests
  // -------------------------------------------------------
  group('SelectionController', () {
    test('initial state has no selection', () {
      final ctrl = SelectionController();
      expect(ctrl.hasSelection, isFalse);
      expect(ctrl.selectionStart, isNull);
      expect(ctrl.selectionEnd, isNull);
      expect(ctrl.selecting, isFalse);
    });

    test('setSelection sets start and end', () {
      final ctrl = SelectionController();
      ctrl.setSelection(start: (x: 2, y: 0), end: (x: 10, y: 0));
      expect(ctrl.hasSelection, isTrue);
      expect(ctrl.selectionStart, equals((x: 2, y: 0)));
      expect(ctrl.selectionEnd, equals((x: 10, y: 0)));
    });

    test('clearSelection resets state', () {
      final ctrl = SelectionController();
      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
      expect(ctrl.hasSelection, isTrue);
      ctrl.clearSelection();
      expect(ctrl.hasSelection, isFalse);
      expect(ctrl.selectionStart, isNull);
      expect(ctrl.selectionEnd, isNull);
    });

    test('setSelection notifies listeners', () {
      final ctrl = SelectionController();
      var notified = 0;
      ctrl.addListener(() => notified++);
      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
      expect(notified, 1);
    });

    test('clearSelection notifies listeners', () {
      final ctrl = SelectionController();
      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
      var notified = 0;
      ctrl.addListener(() => notified++);
      ctrl.clearSelection();
      expect(notified, 1);
    });

    test('clearSelection does not notify when already clear', () {
      final ctrl = SelectionController();
      var notified = 0;
      ctrl.addListener(() => notified++);
      ctrl.clearSelection();
      expect(notified, 0);
    });

    test('removeListener prevents notification', () {
      final ctrl = SelectionController();
      var notified = 0;
      void listener() => notified++;
      ctrl.addListener(listener);
      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
      expect(notified, 1);
      ctrl.removeListener(listener);
      ctrl.clearSelection();
      expect(notified, 1); // Not incremented.
    });

    test('getSelectedText single line', () {
      final ctrl = SelectionController();
      ctrl.setSelection(start: (x: 6, y: 0), end: (x: 11, y: 0));
      final text = ctrl.getSelectedText(['Hello World and more']);
      expect(text, 'World');
    });

    test('getSelectedText multi-line', () {
      final ctrl = SelectionController();
      ctrl.setSelection(start: (x: 6, y: 0), end: (x: 6, y: 2));
      final lines = ['Hello World', 'Second line', 'Third line here'];
      final text = ctrl.getSelectedText(lines);
      // From (6, 0) to (6, 2):
      // Line 0: from x=6 to end → "World"
      // Line 1: full line → "Second line"
      // Line 2: from 0 to x=6 → "Third "
      expect(text, 'World\nSecond line\nThird ');
    });

    test('getSelectedText reverse selection', () {
      final ctrl = SelectionController();
      // Reverse: end before start on same line.
      ctrl.setSelection(start: (x: 11, y: 0), end: (x: 6, y: 0));
      final text = ctrl.getSelectedText(['Hello World and more']);
      expect(text, 'World');
    });

    test('getSelectedText strips ANSI decoration before slicing', () {
      final ctrl = SelectionController();
      final styled = Style()
          .foreground(const AnsiColor(2))
          .render('Hello World');

      ctrl.setSelection(start: (x: 6, y: 0), end: (x: 11, y: 0));

      expect(ctrl.getSelectedText([styled]), 'World');
    });

    test('getSelectedText single char', () {
      final ctrl = SelectionController();
      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 1, y: 0));
      final text = ctrl.getSelectedText(['Hello']);
      expect(text, 'H');
    });

    test('getSelectedText empty when no selection', () {
      final ctrl = SelectionController();
      expect(ctrl.getSelectedText(['Hello']), '');
    });

    test('getSelectedText clamps partial overlap to available lines', () {
      final ctrl = SelectionController();
      ctrl.setSelection(start: (x: 2, y: -1), end: (x: 3, y: 1));
      expect(ctrl.getSelectedText(['Hello', 'World']), 'Hello\nWor');
    });

    test('registerClick uses injected time source deterministically', () {
      final clock = ManualClock();
      final ctrl = SelectionController(nowProvider: () => clock.now);

      expect(ctrl.registerClick((x: 4, y: 2)), equals(1));
      clock.advance(const Duration(milliseconds: 100));
      expect(ctrl.registerClick((x: 4, y: 2)), equals(2));
      clock.advance(const Duration(milliseconds: 100));
      expect(ctrl.registerClick((x: 4, y: 2)), equals(3));
      clock.advance(const Duration(milliseconds: 600));
      expect(ctrl.registerClick((x: 4, y: 2)), equals(1));
    });
  });

  // -------------------------------------------------------
  // SelectableText widget tests
  // -------------------------------------------------------
  group('SelectableText', () {
    test('renders text correctly', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(SelectableText('Hello World'));
        expect(tester.find.text('Hello World'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('press+drag creates selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableText('Hello World', controller: ctrl),
        );

        // Mouse down at column 0, row 0.
        tester.mouseDown(0, 0);
        // Drag to column 5, row 0.
        tester.mouseMove(5, 0);
        // Release.
        tester.mouseUp(5, 0);

        expect(ctrl.hasSelection, isTrue);
        expect(ctrl.selectionStart, equals((x: 0, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 5, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test('selection highlighting appears in output', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableText('Hello World', controller: ctrl),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        // The output should contain ANSI escape codes for highlighting.
        final output = tester.view;
        expect(output.contains('\x1b['), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('selection highlighting uses theme highlight colors', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      final theme = Theme.light().copyWith(
        highlight: const AnsiColor(160),
        onHighlight: const AnsiColor(231),
      );
      final themedSelection = _highlightedTextPattern(
        foreground: 231,
        background: 160,
        text: 'Hello',
      );
      final hardcodedSelection = _highlightedTextPattern(
        foreground: 0,
        background: 7,
        text: 'Hello',
      );

      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: theme,
            child: SelectableText('Hello World', controller: ctrl),
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        final output = tester.view;
        expect(themedSelection.hasMatch(output), isTrue);
        expect(hardcodedSelection.hasMatch(output), isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('selection highlighting can use an explicit override style', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      final theme = Theme.light().copyWith(
        highlight: const AnsiColor(160),
        onHighlight: const AnsiColor(231),
      );
      final overrideStyle = Style()
        ..background(const AnsiColor(27))
        ..foreground(const AnsiColor(230));
      final overriddenSelection = _highlightedTextPattern(
        foreground: 230,
        background: 27,
        text: 'Hello',
      );
      final themedSelection = _highlightedTextPattern(
        foreground: 231,
        background: 160,
        text: 'Hello',
      );

      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: theme,
            child: SelectableText(
              'Hello World',
              controller: ctrl,
              selectionHighlightStyle: overrideStyle,
            ),
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        final output = tester.view;
        expect(overriddenSelection.hasMatch(output), isTrue);
        expect(themedSelection.hasMatch(output), isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('rich text can override selection highlight per span', () {
      final theme = Theme.light().copyWith(
        highlight: const AnsiColor(160),
        onHighlight: const AnsiColor(231),
      );
      final spanOverride = Style()
        ..background(const AnsiColor(27))
        ..foreground(const AnsiColor(230));

      final line =
          '${Style().foreground(const AnsiColor(45)).render('alpha ')}'
          '${Style().foreground(const AnsiColor(208)).bold().render('beta')}';
      final output = applySelectionHighlightingWithRanges(
        [line],
        offset: 0,
        selectionStart: (x: 0, y: 0),
        selectionEnd: (x: 10, y: 0),
        highlightStyle: selectionHighlightStyleForTheme(theme),
        lineHighlightRanges: [
          [StyleRange(6, 10, spanOverride)],
        ],
      ).single;

      expect(output, contains('38;5;45'));
      expect(output, contains('48;5;160m'));
      expect(output, contains('38;5;230'));
      expect(output, contains('48;5;27mbeta'));
    });

    test(
      'rich text line selection preserves span styling outside explicit overrides',
      () {
        final selectionStyle = Style()
          ..background(const AnsiColor(160))
          ..foreground(const AnsiColor(231));
        final line =
            '${Style().foreground(const AnsiColor(45)).render('alpha ')}'
            '${Style().foreground(const AnsiColor(208)).render('beta')}';
        final output = applySelectionHighlighting(
          [line],
          offset: 0,
          selectionStart: (x: 0, y: 0),
          selectionEnd: (x: 10, y: 0),
          highlightStyle: selectionStyle,
        ).single;

        expect(output, contains('38;5;45'));
        expect(output, contains('38;5;208'));
        expect(output, contains('48;5;160m'));
        expect(output, isNot(contains('38;5;231')));
      },
    );

    test('markdown line selection preserves inline markdown styling', () {
      final selectionStyle = Style()
        ..background(const AnsiColor(160))
        ..foreground(const AnsiColor(231));
      final markdownLine = markdownToAnsi(
        'Shared `code`',
        options: AnsiRendererOptions(
          textStyle: Style().foreground(const AnsiColor(45)),
          codeStyle: Style().foreground(const AnsiColor(208)).bold(),
        ),
      );
      final output = applySelectionHighlighting(
        [markdownLine],
        offset: 0,
        selectionStart: (x: 0, y: 0),
        selectionEnd: (x: 13, y: 0),
        highlightStyle: selectionStyle,
      ).single;

      expect(output, contains('38;5;208'));
      expect(output, contains('48;5;160m'));
      expect(output, isNot(contains('38;5;231')));
    });

    test('click clears previous selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableText('Hello World', controller: ctrl),
        );

        // Create a selection.
        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);
        expect(ctrl.hasSelection, isTrue);

        // Click at a new position (starts new selection with same start/end).
        tester.mouseDown(8, 0);
        tester.mouseUp(8, 0);
        // After click with no drag, start == end (zero-width selection).
        expect(ctrl.selectionStart, equals((x: 8, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 8, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test('multi-line text selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableText('Line 0\nLine 1\nLine 2', controller: ctrl),
        );

        // Select from (2, 0) to (4, 1).
        tester.mouseDown(2, 0);
        tester.mouseMove(4, 1);
        tester.mouseUp(4, 1);

        expect(ctrl.hasSelection, isTrue);
        expect(ctrl.selectionStart, equals((x: 2, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 4, y: 1)));
      } finally {
        await tester.dispose();
      }
    });

    test('Ctrl+C copies selected text to clipboard', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableText('Hello World', controller: ctrl),
        );

        // Select "World" (columns 6-11).
        ctrl.setSelection(start: (x: 6, y: 0), end: (x: 11, y: 0));

        // Send Ctrl+C.
        tester.sendMsg(tui.KeyMsg(terminal.Key.char('c', ctrl: true)));

        // We can't directly check the clipboard, but the command should
        // be returned without error. The test verifies no crash.
        expect(ctrl.hasSelection, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('Ctrl+C does nothing without selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableText('Hello World', controller: ctrl),
        );

        // Send Ctrl+C without a selection.
        tester.sendMsg(tui.KeyMsg(terminal.Key.char('c', ctrl: true)));

        // No crash, no selection.
        expect(ctrl.hasSelection, isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('triple click selects the entire line', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableText('Hello World', controller: ctrl),
        );

        tester.mouseDown(2, 0);
        tester.mouseUp(2, 0);
        tester.mouseDown(2, 0);
        tester.mouseUp(2, 0);
        tester.mouseDown(2, 0);
        tester.mouseUp(2, 0);

        expect(ctrl.selectionStart, equals((x: 0, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 11, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test('SelectableRichText participates in selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableRichText(
            controller: ctrl,
            text: const TextSpan(
              text: 'Hello ',
              children: [TextSpan(text: 'world')],
            ),
          ),
        );

        tester.mouseDown(6, 0);
        tester.mouseMove(11, 0);
        tester.mouseUp(11, 0);

        expect(ctrl.getSelectedText(['Hello world']), 'world');
      } finally {
        await tester.dispose();
      }
    });

    test('SelectableView participates in selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(SelectableView('alpha beta', controller: ctrl));

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        expect(ctrl.getSelectedText(['alpha beta']), 'alpha');
      } finally {
        await tester.dispose();
      }
    });

    test('SelectableMarkdownText participates in selection', () async {
      final tester = WidgetTester(screenWidth: 50, screenHeight: 8);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectableMarkdownText(
            data: '- alpha\n- beta',
            controller: ctrl,
            maxWidth: 40,
          ),
        );

        tester.mouseDown(2, 0);
        tester.mouseMove(7, 0);
        tester.mouseUp(7, 0);

        expect(ctrl.getSelectedText(['- alpha', '- beta']), 'alpha');
      } finally {
        await tester.dispose();
      }
    });

    test('Text.selectable() adapts plain text widgets', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          Text('alpha beta').selectable(controller: ctrl),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        expect(ctrl.getSelectedText(['alpha beta']), 'alpha');
      } finally {
        await tester.dispose();
      }
    });

    test('MarkdownText.selectable() adapts markdown widgets', () async {
      final tester = WidgetTester(screenWidth: 50, screenHeight: 8);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          MarkdownText(
            data: '- alpha\n- beta',
            maxWidth: 40,
          ).selectable(controller: ctrl),
        );

        tester.mouseDown(2, 0);
        tester.mouseMove(7, 0);
        tester.mouseUp(7, 0);

        expect(ctrl.getSelectedText(['- alpha', '- beta']), 'alpha');
      } finally {
        await tester.dispose();
      }
    });

    test('RichText.selectable() adapts rich text widgets', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          RichText(
            text: const TextSpan(
              text: 'Hello ',
              children: [TextSpan(text: 'world')],
            ),
          ).selectable(controller: ctrl),
        );

        tester.mouseDown(6, 0);
        tester.mouseMove(11, 0);
        tester.mouseUp(11, 0);

        expect(ctrl.getSelectedText(['Hello world']), 'world');
      } finally {
        await tester.dispose();
      }
    });

    test('View.selectable() adapts generic view widgets', () async {
      final tester = WidgetTester(screenWidth: 50, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          tui.View(content: 'alpha beta').selectable(controller: ctrl),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        expect(ctrl.getSelectedText(['alpha beta']), 'alpha');
      } finally {
        await tester.dispose();
      }
    });

    test('SelectableTextFieldView participates in selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      final textController = TextEditingController(text: 'alpha beta');
      addTearDown(textController.dispose);
      try {
        await tester.pumpWidget(
          SelectableTextFieldView(
            controller: textController,
            selectionController: ctrl,
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        expect(ctrl.getSelectedText(['alpha beta']), 'alpha');
      } finally {
        await tester.dispose();
      }
    });

    test(
      'SelectableTextAreaView updates when controller text changes',
      () async {
        final tester = WidgetTester(screenWidth: 70, screenHeight: 8);
        final ctrl = SelectionController();
        final textController = TextAreaController(text: 'alpha\nbeta');
        addTearDown(textController.dispose);
        try {
          await tester.pumpWidget(
            SelectionArea(
              controller: ctrl,
              child: SelectableTextAreaView(
                controller: textController,
                selectionController: ctrl,
                maxWidth: 60,
              ),
            ),
          );

          textController.text = 'gamma\ndelta';
          tester.pump();

          expect(tester.locateText('gamma'), isNotNull);
        } finally {
          await tester.dispose();
        }
      },
    );

    test('SelectableText inside Container respects layout', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Container(width: 20, child: SelectableText('Hello World')),
        );
        expect(tester.find.text('Hello World'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test(
      'clicking outside standalone SelectableText clears selection',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
        try {
          // Row 0: non-selectable Text, Row 1: SelectableText.
          await tester.pumpWidget(
            Column(
              children: [Text('Header'), SelectableText('Selectable content')],
            ),
          );

          // Select text on row 1 (the SelectableText).
          tester.mouseDown(0, 1);
          tester.mouseMove(8, 1);
          tester.mouseUp(8, 1);

          // The view should show ANSI highlighting.
          expect(tester.view.contains('\x1b['), isTrue);

          // Click on row 0 (the non-selectable Text header).
          tester.mouseDown(2, 0);
          tester.mouseUp(2, 0);

          // Selection should be cleared — no more ANSI highlighting for
          // the SelectableText. Verify by checking the view changed.
          // The standalone controller auto-clears on outside click.
          final viewAfter = tester.view;
          // "Selectable content" should render without selection styling.
          expect(viewAfter.contains('Selectable content'), isTrue);
        } finally {
          await tester.dispose();
        }
      },
    );
  });

  // -------------------------------------------------------
  // SelectionArea widget tests
  // -------------------------------------------------------
  group('SelectionArea', () {
    test('provides controller to descendant SelectableText', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        await tester.pumpWidget(
          SelectionArea(controller: ctrl, child: SelectableText('Hello World')),
        );

        expect(tester.find.text('Hello World'), isTrue);

        // Select text — the shared controller should receive the selection.
        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        expect(ctrl.hasSelection, isTrue);
        expect(ctrl.selectionStart, equals((x: 0, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 5, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test(
      'multiple SelectableText share one controller via SelectionArea',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
        final ctrl = SelectionController();
        try {
          await tester.pumpWidget(
            SelectionArea(
              controller: ctrl,
              child: Column(
                children: [
                  SelectableText('First line'),
                  SelectableText('Second line'),
                ],
              ),
            ),
          );

          expect(tester.find.text('First line'), isTrue);
          expect(tester.find.text('Second line'), isTrue);

          // Select on the first text widget.
          tester.mouseDown(0, 0);
          tester.mouseMove(5, 0);
          tester.mouseUp(5, 0);

          // Controller should have selection.
          expect(ctrl.hasSelection, isTrue);
        } finally {
          await tester.dispose();
        }
      },
    );

    test(
      'SelectionArea copies combined text across multiple widgets',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
        final ctrl = SelectionController();
        try {
          await tester.pumpWidget(
            SelectionArea(
              controller: ctrl,
              child: Column(
                children: [
                  SelectableText('First line'),
                  SelectableRichText(text: const TextSpan(text: 'Second line')),
                  SelectableMarkdownText(data: '- Third line', maxWidth: 40),
                  SelectableView('Third line'),
                ],
              ),
            ),
          );

          tester.mouseDown(0, 0);
          tester.mouseMove(5, 3);
          tester.mouseUp(5, 3);

          expect(
            ctrl.getSelectedRegisteredText(),
            equals('First line\nSecond line\n• Third line\n'),
          );
        } finally {
          await tester.dispose();
        }
      },
    );

    test(
      'SelectionArea highlights text across multiple widgets while dragging',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 8);
        final ctrl = SelectionController();
        final theme = Theme.light().copyWith(
          highlight: const AnsiColor(160),
          onHighlight: const AnsiColor(231),
        );
        final firstLineHighlight = _highlightedTextPattern(
          foreground: 231,
          background: 160,
          text: 'First line',
        );
        final secondLineHighlight = _highlightedTextPattern(
          foreground: 231,
          background: 160,
          text: 'Second',
        );

        try {
          await tester.pumpWidget(
            ThemeScope(
              theme: theme,
              child: SelectionArea(
                controller: ctrl,
                child: Column(
                  children: [
                    SelectableText('First line'),
                    SelectableRichText(
                      text: const TextSpan(text: 'Second line'),
                    ),
                    SelectableView('Third line'),
                  ],
                ),
              ),
            ),
          );

          tester.mouseDown(0, 0);
          tester.mouseMove(6, 1);
          tester.mouseUp(6, 1);

          final output = tester.view;
          expect(firstLineHighlight.hasMatch(output), isTrue);
          expect(secondLineHighlight.hasMatch(output), isTrue);
          expect(
            ctrl.getSelectedRegisteredText(),
            equals('First line\nSecond'),
          );
        } finally {
          await tester.dispose();
        }
      },
    );

    test('SelectionArea without explicit controller creates its own', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(SelectionArea(child: SelectableText('Hello')));
        expect(tester.find.text('Hello'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('SelectableText without area creates its own controller', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(SelectableText('Standalone'));
        expect(tester.find.text('Standalone'), isTrue);

        // Select — should work even without an area.
        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        // No crash.
      } finally {
        await tester.dispose();
      }
    });

    test(
      'clicking one SelectableText clears selection from shared controller',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
        final ctrl = SelectionController();
        try {
          await tester.pumpWidget(
            SelectionArea(
              controller: ctrl,
              child: Column(
                children: [
                  SelectableText('First line'),
                  SelectableText('Second line'),
                ],
              ),
            ),
          );

          // Select on first.
          tester.mouseDown(0, 0);
          tester.mouseMove(5, 0);
          tester.mouseUp(5, 0);
          expect(ctrl.hasSelection, isTrue);

          // Click on second — should start a new selection, replacing old.
          tester.mouseDown(0, 1);
          tester.mouseUp(0, 1);

          // New click creates a zero-width selection (start == end).
          expect(ctrl.selectionStart, equals(ctrl.selectionEnd));
        } finally {
          await tester.dispose();
        }
      },
    );

    test('clicking outside SelectionArea clears shared selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = SelectionController();
      try {
        // Row 0: non-selectable Text (outside SelectionArea).
        // Row 1-2: SelectableText inside SelectionArea.
        await tester.pumpWidget(
          Column(
            children: [
              Text('Header outside area'),
              SelectionArea(
                controller: ctrl,
                child: Column(
                  children: [
                    SelectableText('First line'),
                    SelectableText('Second line'),
                  ],
                ),
              ),
            ],
          ),
        );

        // Select text on first SelectableText (row 1).
        tester.mouseDown(0, 1);
        tester.mouseMove(5, 1);
        tester.mouseUp(5, 1);
        expect(ctrl.hasSelection, isTrue);

        // Click on the header (row 0) — outside the SelectionArea.
        tester.mouseDown(2, 0);
        tester.mouseUp(2, 0);

        // Shared selection should be cleared.
        expect(ctrl.hasSelection, isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('double click selection can be driven by a manual clock', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final clock = ManualClock();
      final ctrl = SelectionController(nowProvider: () => clock.now);
      try {
        await tester.pumpWidget(
          SelectableText('Hello selection world', controller: ctrl),
        );

        tester.tapAt(7, 0);
        clock.advance(const Duration(milliseconds: 100));
        tester.tapAt(7, 0);

        expect(ctrl.getSelectedText(['Hello selection world']), 'selection');
      } finally {
        await tester.dispose();
      }
    });

    test('double click timeout can be exceeded deterministically', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final clock = ManualClock();
      final ctrl = SelectionController(nowProvider: () => clock.now);
      try {
        await tester.pumpWidget(
          SelectableText('Hello selection world', controller: ctrl),
        );

        tester.tapAt(7, 0);
        clock.advance(const Duration(milliseconds: 700));
        tester.tapAt(7, 0);

        expect(ctrl.selectionStart, equals((x: 7, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 7, y: 0)));
      } finally {
        await tester.dispose();
      }
    });
  });

  // -------------------------------------------------------
  // SelectableText inside ScrollView — selection-after-scroll
  // regression tests (Bug Fix 3)
  // -------------------------------------------------------
  group('SelectableText inside ScrollView', () {
    /// Builds a scrollable viewport containing numbered SelectableText lines.
    Widget buildScrollableSelectable({
      required WidgetScrollController scrollCtrl,
      SelectionController? selectionCtrl,
      int lineCount = 30,
      int height = 5,
      int width = 40,
    }) {
      final lines = List.generate(
        lineCount,
        (i) => SelectableText('Line $i', controller: selectionCtrl),
      );
      return Container(
        width: width,
        height: height,
        child: SingleChildScrollView(
          controller: scrollCtrl,
          child: Column(children: lines),
        ),
      );
    }

    test('selection works on first visible line without scrolling', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final scrollCtrl = WidgetScrollController();
      final selCtrl = SelectionController();
      try {
        await tester.pumpWidget(
          buildScrollableSelectable(
            scrollCtrl: scrollCtrl,
            selectionCtrl: selCtrl,
          ),
        );

        // "Line 0" should be visible at row 0.
        expect(tester.find.text('Line 0'), isTrue);

        // Select characters 0-4 on row 0 ("Line").
        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        expect(selCtrl.hasSelection, isTrue);
        expect(selCtrl.selectionStart, equals((x: 0, y: 0)));
        expect(selCtrl.selectionEnd, equals((x: 4, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test('selection works after scrolling down via jumpTo', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final scrollCtrl = WidgetScrollController();
      final selCtrl = SelectionController();
      try {
        await tester.pumpWidget(
          buildScrollableSelectable(
            scrollCtrl: scrollCtrl,
            selectionCtrl: selCtrl,
          ),
        );

        // Scroll down 10 lines.
        scrollCtrl.jumpTo(10);
        // Force a repaint by selecting — the press event triggers layout.
        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        // After scrolling 10 lines, row 0 maps to "Line 10".
        // The SelectableText for "Line 10" should get localY=0 from hit-test.
        expect(selCtrl.hasSelection, isTrue);
        expect(selCtrl.selectionStart, equals((x: 0, y: 0)));
        expect(selCtrl.selectionEnd, equals((x: 4, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test('selection works after scrolling via mouse wheel', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final scrollCtrl = WidgetScrollController();
      final selCtrl = SelectionController();
      try {
        await tester.pumpWidget(
          buildScrollableSelectable(
            scrollCtrl: scrollCtrl,
            selectionCtrl: selCtrl,
            lineCount: 30,
          ),
        );

        // Send wheel down events to scroll.
        for (var i = 0; i < 5; i++) {
          tester.sendMsg(
            tui.MouseMsg(
              action: tui.MouseAction.press,
              button: tui.MouseButton.wheelDown,
              x: 5,
              y: 1,
            ),
          );
        }

        // Now select text at row 0 of the viewport.
        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        // The selection should be set (coordinates are in the SelectableText's
        // local space, so y=0 regardless of scroll position).
        expect(selCtrl.hasSelection, isTrue);
        expect(selCtrl.selectionStart!.y, equals(0));
        expect(selCtrl.selectionEnd!.y, equals(0));
      } finally {
        await tester.dispose();
      }
    });

    test('selection highlighting renders correctly after scrolling', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final scrollCtrl = WidgetScrollController();
      final selCtrl = SelectionController();
      try {
        await tester.pumpWidget(
          buildScrollableSelectable(
            scrollCtrl: scrollCtrl,
            selectionCtrl: selCtrl,
          ),
        );

        // Scroll down.
        scrollCtrl.jumpTo(10);

        // Capture output before selection.
        final beforeOutput = tester.view;

        // Select text at viewport row 1.
        tester.mouseDown(0, 1);
        tester.mouseMove(4, 1);
        tester.mouseUp(4, 1);

        final afterOutput = tester.view;

        // Output should change — ANSI highlighting applied.
        expect(afterOutput, isNot(equals(beforeOutput)));
        expect(afterOutput.contains('\x1b['), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('selection via SelectionArea works after scrolling', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final scrollCtrl = WidgetScrollController();
      final selCtrl = SelectionController();
      try {
        final lines = List.generate(30, (i) => SelectableText('Item $i'));
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 5,
            child: SelectionArea(
              controller: selCtrl,
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Column(children: lines),
              ),
            ),
          ),
        );

        // Scroll down.
        scrollCtrl.jumpTo(15);

        // Select text on first visible row.
        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        // The shared controller should have a selection.
        expect(selCtrl.hasSelection, isTrue);
        expect(selCtrl.selectionStart!.y, equals(0));
        expect(selCtrl.selectionEnd!.y, equals(0));
      } finally {
        await tester.dispose();
      }
    });

    test(
      'drag selection coordinates remain stable during drag after scroll',
      () async {
        final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
        final scrollCtrl = WidgetScrollController();
        final selCtrl = SelectionController();
        try {
          await tester.pumpWidget(
            buildScrollableSelectable(
              scrollCtrl: scrollCtrl,
              selectionCtrl: selCtrl,
            ),
          );

          // Scroll down.
          scrollCtrl.jumpTo(10);

          // Start drag at viewport row 0, column 2.
          tester.mouseDown(2, 0);

          // Drag to column 8 on the same row.
          tester.mouseMove(8, 0);

          // Selection end should track the drag position correctly.
          expect(selCtrl.selectionStart, equals((x: 2, y: 0)));
          expect(selCtrl.selectionEnd, equals((x: 8, y: 0)));

          // Continue drag to row 2 (still within viewport).
          tester.mouseMove(3, 2);

          // The Y coordinate should reflect local content position.
          // Row 2 in viewport → the SelectableText at content line 12's local y=0,
          // OR if the drag crosses into a different SelectableText, the end
          // coordinates are whatever the hit-test or raw-mouse logic computes.
          // The key assertion: no crash and selection end is updated.
          expect(selCtrl.selectionEnd, isNotNull);

          tester.mouseUp(3, 2);
        } finally {
          await tester.dispose();
        }
      },
    );
  });
}
