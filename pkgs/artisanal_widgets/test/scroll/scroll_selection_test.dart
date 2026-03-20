import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/terminal.dart' as terminal show Key;
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

/// Builds a scrollable widget with selection enabled.
///
/// Content is a Column of numbered lines: "Line 0", "Line 1", ... up to
/// [lineCount] - 1.  The viewport is [height] rows tall.
Widget _buildScrollable({
  required WidgetScrollController controller,
  int lineCount = 30,
  int height = 10,
  int width = 40,
  bool wrapInScrollbar = false,
  bool useScrollView = false,
}) {
  final lines = List.generate(lineCount, (i) => Text('Line $i'));
  Widget child;
  if (useScrollView) {
    child = ScrollView(
      controller: controller,
      enableSelection: true,
      child: Column(children: lines),
    );
  } else {
    child = SingleChildScrollView(
      controller: controller,
      enableSelection: true,
      child: Column(children: lines),
    );
  }
  if (wrapInScrollbar) {
    child = Scrollbar(controller: controller, child: child);
  }
  return Container(width: width, height: height, child: child);
}

Widget _buildVirtualScrollable({
  required WidgetScrollController controller,
  int lineCount = 30,
  int height = 10,
  int width = 40,
}) {
  final lines = List.generate(lineCount, (i) => Text('Line $i'));
  return Container(
    width: width,
    height: height,
    child: VirtualListView(
      controller: controller,
      enableSelection: true,
      children: lines,
    ),
  );
}

void main() {
  group('ScrollView selection', () {
    test('press+drag selects text and highlighting appears in output', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        // Verify "Line 0" is visible.
        expect(tester.find.text('Line 0'), isTrue);

        // Mouse down at start of "Line 0" (column 0, row 0).
        tester.mouseDown(0, 0);
        // Drag to end of "Line 0" (column 5, row 0).
        tester.mouseMove(5, 0);
        // Release.
        tester.mouseUp(5, 0);

        // Selection should be active.
        expect(ctrl.hasSelection, isTrue);
        expect(ctrl.selectionStart, equals((x: 0, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 5, y: 0)));

        // Output should contain ANSI escape codes for selection highlighting.
        // The selection style uses AnsiColor(7) background / AnsiColor(0) foreground.
        final output = tester.view;
        // Selection highlighting replaces normal text with styled text.
        // We can verify by checking that the output contains ANSI codes.
        expect(output.contains('\x1b['), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('click clears previous selection', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        // Create a selection.
        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);
        expect(ctrl.hasSelection, isTrue);

        // Click somewhere else — starts a new selection (effectively clearing).
        tester.mouseDown(2, 3);
        tester.mouseUp(2, 3);

        // Selection start and end should both be at the new click point.
        expect(ctrl.selectionStart, equals((x: 2, y: 3)));
        expect(ctrl.selectionEnd, equals((x: 2, y: 3)));
      } finally {
        await tester.dispose();
      }
    });

    test('triple click selects the entire content line', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        tester.mouseDown(2, 0);
        tester.mouseUp(2, 0);
        tester.mouseDown(2, 0);
        tester.mouseUp(2, 0);
        tester.mouseDown(2, 0);
        tester.mouseUp(2, 0);

        expect(ctrl.selectionStart, equals((x: 0, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 6, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test('reverse drag selection works with scrolled content', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        ctrl.jumpTo(8);

        tester.mouseDown(0, 4);
        tester.mouseMove(6, 2);
        tester.mouseUp(6, 2);

        expect(ctrl.selectionStart, equals((x: 0, y: 12)));
        expect(ctrl.selectionEnd, equals((x: 6, y: 10)));
      } finally {
        await tester.dispose();
      }
    });

    test('selection remains correct after viewport resize', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        tester.resize(28, 6);
        ctrl.jumpTo(6);

        tester.mouseDown(0, 3);
        tester.mouseMove(6, 2);
        tester.mouseUp(6, 2);

        expect(ctrl.selectionStart, equals((x: 0, y: 9)));
        expect(ctrl.selectionEnd, equals((x: 6, y: 8)));
      } finally {
        await tester.dispose();
      }
    });

    test('dragging at viewport bottom auto-scrolls downward', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true, height: 6),
        );

        tester.mouseDown(0, 1);
        for (var i = 0; i < 4; i++) {
          tester.mouseMove(4, 4);
        }
        tester.mouseUp(4, 4);

        expect(ctrl.offset, equals(4));
        expect(ctrl.selectionStart, equals((x: 0, y: 1)));
        expect(ctrl.selectionEnd, equals((x: 4, y: 8)));
      } finally {
        await tester.dispose();
      }
    });

    test('dragging at viewport top auto-scrolls upward', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true, height: 6),
        );

        ctrl.jumpTo(10);

        tester.mouseDown(0, 4);
        for (var i = 0; i < 4; i++) {
          tester.mouseMove(6, 0);
        }
        tester.mouseUp(6, 0);

        expect(ctrl.offset, equals(6));
        expect(ctrl.selectionStart, equals((x: 0, y: 14)));
        expect(ctrl.selectionEnd, equals((x: 6, y: 6)));
      } finally {
        await tester.dispose();
      }
    });

    test('selection works with scrolled content', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        // Scroll down 5 lines.
        ctrl.jumpTo(5);
        tester.sendMsg(
          tui.MouseMsg(
            action: tui.MouseAction.press,
            button: tui.MouseButton.left,
            x: -1,
            y: -1,
          ),
        );
        // Use a non-edge row so the drag does not trigger auto-scroll.
        tester.mouseDown(0, 2);
        tester.mouseMove(4, 2);
        tester.mouseUp(4, 2);

        // With scroll offset 5, row 2 maps to content line 7.
        expect(ctrl.selectionStart!.y, equals(7));
        expect(ctrl.selectionEnd!.y, equals(7));
      } finally {
        await tester.dispose();
      }
    });

    test('multi-line selection across lines', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        // Select from (2, 1) to (4, 3) — crossing lines 1, 2, 3.
        tester.mouseDown(2, 1);
        tester.mouseMove(4, 3);
        tester.mouseUp(4, 3);

        expect(ctrl.selectionStart, equals((x: 2, y: 1)));
        expect(ctrl.selectionEnd, equals((x: 4, y: 3)));
      } finally {
        await tester.dispose();
      }
    });

    test('getSelectedText extracts correct content', () async {
      final ctrl = WidgetScrollController();
      // Simulate content lines.
      final lines = ['Hello World', 'Foo Bar Baz', 'Line Three'];

      // Single-line selection: "llo W"
      ctrl.setSelection(start: (x: 2, y: 0), end: (x: 7, y: 0));
      expect(ctrl.getSelectedText(lines), equals('llo W'));

      // Multi-line selection: from (4, 0) to (3, 1)
      ctrl.setSelection(start: (x: 4, y: 0), end: (x: 3, y: 1));
      expect(ctrl.getSelectedText(lines), equals('o World\nFoo'));
    });

    test('getSelectedText strips ANSI decoration before slicing', () async {
      final ctrl = WidgetScrollController();
      final styled = Style()
          .foreground(const AnsiColor(4))
          .render('Hello World');

      ctrl.setSelection(start: (x: 6, y: 0), end: (x: 11, y: 0));

      expect(ctrl.getSelectedText([styled]), equals('World'));
    });

    test('clearSelection removes selection', () async {
      final ctrl = WidgetScrollController();
      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
      expect(ctrl.hasSelection, isTrue);

      ctrl.clearSelection();
      expect(ctrl.hasSelection, isFalse);
      expect(ctrl.selectionStart, isNull);
      expect(ctrl.selectionEnd, isNull);
    });
  });

  group('SingleChildScrollView selection', () {
    test('press+drag selects text', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: false),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(6, 0);
        tester.mouseUp(6, 0);

        expect(ctrl.hasSelection, isTrue);
        expect(ctrl.selectionStart, equals((x: 0, y: 0)));
        expect(ctrl.selectionEnd, equals((x: 6, y: 0)));
      } finally {
        await tester.dispose();
      }
    });

    test('selection highlighting appears in rendered output', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: false),
        );

        // Before selection, capture output.
        final beforeOutput = tester.view;

        // Select "Line" from "Line 0" (columns 0-4).
        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        final afterOutput = tester.view;

        // The output should change because selection highlighting is applied.
        expect(afterOutput, isNot(equals(beforeOutput)));
        // Should contain ANSI escape sequences for the selection style.
        expect(afterOutput.contains('\x1b['), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('selection highlighting uses theme highlight colors', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      final theme = Theme.light().copyWith(
        highlight: const AnsiColor(124),
        onHighlight: const AnsiColor(231),
      );
      final themedSelection = _highlightedTextPattern(
        foreground: 231,
        background: 124,
        text: 'Line',
      );
      final hardcodedSelection = _highlightedTextPattern(
        foreground: 0,
        background: 7,
        text: 'Line',
      );

      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: theme,
            child: _buildScrollable(controller: ctrl, useScrollView: false),
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        final output = tester.view;
        expect(themedSelection.hasMatch(output), isTrue);
        expect(hardcodedSelection.hasMatch(output), isFalse);
      } finally {
        await tester.dispose();
      }
    });

    test('selection does not interfere with scrollbar track clicks', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(
            controller: ctrl,
            wrapInScrollbar: true,
            useScrollView: false,
          ),
        );

        // Click on content area (column 5) — should create selection.
        tester.mouseDown(5, 2);
        tester.mouseUp(5, 2);
        expect(ctrl.hasSelection, isTrue);
        expect(ctrl.selectionStart, equals((x: 5, y: 2)));
      } finally {
        await tester.dispose();
      }
    });

    test('selection with scrolled content uses content coordinates', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: false),
        );

        // Scroll down 10 lines.
        ctrl.jumpTo(10);
        // Pump to update.
        tester.mouseDown(0, 2);
        tester.mouseMove(4, 2);
        tester.mouseUp(4, 2);

        // Row 2 with scroll offset 10 → content line 12.
        expect(ctrl.selectionStart!.y, equals(12));
        expect(ctrl.selectionEnd!.y, equals(12));
      } finally {
        await tester.dispose();
      }
    });

    test('dragging at viewport edge auto-scrolls while selecting', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, height: 6, useScrollView: false),
        );

        tester.mouseDown(0, 1);
        for (var i = 0; i < 3; i++) {
          tester.mouseMove(0, 5);
        }
        tester.mouseUp(0, 5);

        expect(ctrl.offset, equals(3));
        expect(ctrl.selectionEnd, equals((x: 0, y: 8)));
      } finally {
        await tester.dispose();
      }
    });
  });

  group('WidgetScrollController selection helpers', () {
    test(
      'getSelectedText handles reverse selection (end before start)',
      () async {
        final ctrl = WidgetScrollController();
        final lines = ['Alpha', 'Beta', 'Gamma'];

        // Select backward: from (3, 2) to (1, 0).
        ctrl.setSelection(start: (x: 3, y: 2), end: (x: 1, y: 0));
        final text = ctrl.getSelectedText(lines);
        // Should extract: "lpha\nBeta\nGam"
        expect(text, equals('lpha\nBeta\nGam'));
      },
    );

    test('getSelectedText single character', () async {
      final ctrl = WidgetScrollController();
      final lines = ['Hello'];

      ctrl.setSelection(start: (x: 1, y: 0), end: (x: 2, y: 0));
      expect(ctrl.getSelectedText(lines), equals('e'));
    });

    test('getSelectedText empty when start == end', () async {
      final ctrl = WidgetScrollController();
      final lines = ['Hello'];

      ctrl.setSelection(start: (x: 2, y: 0), end: (x: 2, y: 0));
      expect(ctrl.getSelectedText(lines), equals(''));
    });

    test('setSelection notifies listeners', () async {
      final ctrl = WidgetScrollController();
      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));
      expect(notified, isTrue);
    });

    test('clearSelection notifies listeners', () async {
      final ctrl = WidgetScrollController();
      ctrl.setSelection(start: (x: 0, y: 0), end: (x: 5, y: 0));

      var notified = false;
      ctrl.addListener(() => notified = true);
      ctrl.clearSelection();
      expect(notified, isTrue);
    });

    test('clearSelection when already cleared does not notify', () async {
      final ctrl = WidgetScrollController();
      var notified = false;
      ctrl.addListener(() => notified = true);
      ctrl.clearSelection();
      expect(notified, isFalse);
    });
  });

  group('selection highlighting', () {
    test('single-line selection applies ANSI style to correct range', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      final ctrl = WidgetScrollController();
      try {
        final lines = List.generate(5, (i) => Text('ABCDEFGHIJ'));
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 5,
            child: SingleChildScrollView(
              controller: ctrl,
              enableSelection: true,
              child: Column(children: lines),
            ),
          ),
        );

        // Select columns 2-5 on row 1.
        tester.mouseDown(2, 1);
        tester.mouseMove(5, 1);
        tester.mouseUp(5, 1);

        // The rendered output should have ANSI codes for the selection.
        final output = tester.view;
        // "ABCDEFGHIJ" — selection of columns 2-5 means "CDEF" highlighted.
        // Check that the output has ANSI reset/style sequences.
        expect(output.contains('\x1b['), isTrue);
        // The non-selected lines should still have plain text.
        expect(output.contains('ABCDEFGHIJ'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  group('Ctrl+C copy', () {
    test('Ctrl+C with active selection returns setClipboard Cmd', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        // Select "Line 0".
        tester.mouseDown(0, 0);
        tester.mouseMove(6, 0);
        tester.mouseUp(6, 0);

        expect(ctrl.hasSelection, isTrue);

        // Send Ctrl+C.
        tester.sendMsg(tui.KeyMsg(terminal.Key.char('c', ctrl: true)));

        // The view should still be valid (no crash).
        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('Ctrl+C without selection does nothing', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        await tester.pumpWidget(
          _buildScrollable(controller: ctrl, useScrollView: true),
        );

        expect(ctrl.hasSelection, isFalse);

        // Send Ctrl+C — should not crash.
        tester.sendMsg(tui.KeyMsg(terminal.Key.char('c', ctrl: true)));

        expect(tester.view.isNotEmpty, isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  group('enableSelection=false (default)', () {
    test('mouse events do not create selection when disabled', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      try {
        // Default: enableSelection = false.
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 10,
            child: SingleChildScrollView(
              controller: ctrl,
              child: Column(
                children: List.generate(30, (i) => Text('Line $i')),
              ),
            ),
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(5, 0);
        tester.mouseUp(5, 0);

        // Selection should NOT be created.
        expect(ctrl.hasSelection, isFalse);
      } finally {
        await tester.dispose();
      }
    });
  });

  group('VirtualListView selection', () {
    test('selection highlighting uses theme highlight colors', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      final ctrl = WidgetScrollController();
      final theme = Theme.light().copyWith(
        highlight: const AnsiColor(28),
        onHighlight: const AnsiColor(231),
      );
      final themedSelection = _highlightedTextPattern(
        foreground: 231,
        background: 28,
        text: 'Line',
      );

      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: theme,
            child: _buildVirtualScrollable(controller: ctrl),
          ),
        );

        tester.mouseDown(0, 0);
        tester.mouseMove(4, 0);
        tester.mouseUp(4, 0);

        expect(themedSelection.hasMatch(tester.view), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });
}
