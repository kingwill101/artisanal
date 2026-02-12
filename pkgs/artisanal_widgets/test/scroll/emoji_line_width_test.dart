import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/uv.dart' show stringWidth;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

/// Compute visible width accounting for wide characters (CJK, emoji).
/// Strips ANSI escapes first, then delegates to the canonical [stringWidth].
int _visibleWidth(String s) {
  final stripped = s.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
  return stringWidth(stripped);
}

/// Minimal reproduction of scroll rendering corruption with emoji content.
/// Tests that all lines have consistent visible width at every scroll position.
void main() {
  group('Emoji scroll line width consistency', () {
    test('all viewport lines have same visible width after scrolling', () async {
      // 30 lines of content, 10-line viewport → scrollable
      final lines = <Widget>[
        // 5 plain text lines
        Text('Plain line 1'),
        Text('Plain line 2'),
        Text('Plain line 3'),
        Text('Plain line 4'),
        Text('Plain line 5'),
        // 5 emoji lines
        Text('Faces: 😀 😎 🤔 😱 💩 🎉 🔥'),
        Text('Hands: 👍 👎 👋 🙏 💪'),
        Text('Animals: 🐱 🐶 🦊 🐻 🐝 🐍'),
        Text('Food: 🍕 🍔 🍣 🍰 ☕ 🍺'),
        Text('Weather: ☀️ 🌤️ ⛅ 🌧️'),
        // 5 more plain text lines
        Text('After emoji line 1'),
        Text('After emoji line 2'),
        Text('After emoji line 3'),
        Text('After emoji line 4'),
        Text('After emoji line 5'),
        // 5 more emoji lines
        Text('Symbols: ✅ ❌ ⚠️ 🚫 ⭐ 💡'),
        Text('Flags: 🏳️ 🏴 🏁'),
        Text('Arrows: ← ↑ → ↓'),
        Text('Box: ┌───┐  ╭───╮'),
        Text('Math: ∞ ≈ ≠ ≤'),
        // 10 more plain text lines to ensure scrollability
        Text('Tail line 1'),
        Text('Tail line 2'),
        Text('Tail line 3'),
        Text('Tail line 4'),
        Text('Tail line 5'),
        Text('Tail line 6'),
        Text('Tail line 7'),
        Text('Tail line 8'),
        Text('Tail line 9'),
        Text('Tail line 10'),
      ];

      const w = 40;
      const h = 10;
      final tester = WidgetTester(screenWidth: w, screenHeight: h);
      try {
        final controller = WidgetScrollController();
        await tester.pumpWidget(
          Scrollbar(
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: lines,
              ),
            ),
          ),
        );

        // Check line widths at various scroll positions
        for (var scroll = 0; scroll < 20; scroll++) {
          final view = tester.view;
          final viewLines = view.split('\n');

          // Strip ANSI for width checking
          final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
          for (var i = 0; i < viewLines.length; i++) {
            final stripped = viewLines[i].replaceAll(ansiRegex, '');
            final visLen = _visibleWidth(stripped);
            expect(
              visLen,
              w,
              reason:
                  'Scroll=$scroll, line $i: visible width should be $w but '
                  'got $visLen. Line: "${stripped.length > 60 ? stripped.substring(0, 60) : stripped}"',
            );
          }

          // Scroll down by 1
          tester.sendSpecialKey(KeyType.down);
        }
      } finally {
        await tester.dispose();
      }
    });

    test(
      'viewport content lines have consistent width before joinHorizontal',
      () async {
        // This tests the paint output of SingleChildScrollView viewport directly
        const w = 40;
        const h = 5;
        final tester = WidgetTester(screenWidth: w, screenHeight: h);
        try {
          final controller = WidgetScrollController();
          await tester.pumpWidget(
            SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Plain text line'),
                  Text('😀 😎 🤔 emoji line'),
                  Text('Another plain line'),
                  Text('🐱 🐶 more emoji'),
                  Text('Final plain line'),
                  Text('Extra line 1'),
                  Text('Extra line 2'),
                  Text('Extra line 3'),
                  Text('Extra line 4'),
                  Text('Extra line 5'),
                ],
              ),
            ),
          );

          // Check view at offset 0
          var view = tester.view;
          var viewLines = view.split('\n');
          final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');

          for (var i = 0; i < viewLines.length; i++) {
            final stripped = viewLines[i].replaceAll(ansiRegex, '');
            final visLen = _visibleWidth(stripped);
            expect(
              visLen,
              w,
              reason:
                  'At offset 0, line $i: visible width $visLen != $w. '
                  'Content: "$stripped"',
            );
          }

          // Scroll down to show emoji lines
          tester.sendSpecialKey(KeyType.down);
          view = tester.view;
          viewLines = view.split('\n');

          for (var i = 0; i < viewLines.length; i++) {
            final stripped = viewLines[i].replaceAll(ansiRegex, '');
            final visLen = _visibleWidth(stripped);
            expect(
              visLen,
              w,
              reason:
                  'At offset 1, line $i: visible width $visLen != $w. '
                  'Content: "$stripped"',
            );
          }
        } finally {
          await tester.dispose();
        }
      },
    );
  });
}
