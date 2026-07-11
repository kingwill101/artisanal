import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

// Reproduces a comment block shaped like the real inline comment card
// (header + multi-line body) as a widget, and scrolls through it to ensure the
// composed scrollable content stays exactly viewportHeight rows. The
// GitDiffViewer composes its own SingleChildScrollView (diff lines + comment
// widget blocks) and clips it to the viewer height, so the column never
// overflows into surrounding widgets (e.g. the status bar).
Widget _blockWidget(String label, int lines) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$label header'),
      for (var i = 1; i < lines; i++) Text('$label body ${i - 1}'),
    ],
  );
}

void main() {
  group('GitDiffViewer clip repro', () {
    for (final blockHeight in const [4, 6]) {
      for (final blockLine in const [5, 20]) {
        test(
          'block h=$blockHeight at line $blockLine scrolls cleanly',
          () async {
            final tester = WidgetTester();
            addTearDown(() => tester.dispose());
            final controller = GitDiffController();
            final scroll = WidgetScrollController();

            const total = 60;
            final diff =
                '''
diff --git a/lib/a.dart b/lib/a.dart
index 111..222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,${total - 3} +1,${total - 3} @@
${List<String>.generate(total - 3, (i) => ' ${i.toString().padLeft(4)}  code line ${i + 1}').join('\n')}
}''';

            GitDiffViewer make() => GitDiffViewer(
              diff: diff,
              width: 80,
              height: 12,
              controller: controller,
              scrollController: scroll,
              commentBlocks: [
                DiffCommentBlock(
                  renderLine: blockLine,
                  height: blockHeight,
                  child: _blockWidget('C', blockHeight),
                ),
              ],
            );

            // Scroll through every visual offset around the block.
            for (
              var off = blockLine - 2;
              off <= blockLine + blockHeight + 2;
              off++
            ) {
              scroll.jumpTo(off);
              await tester.pumpWidget(make(), width: 80, height: 12);
              final rows = tester.view.split('\n');
              expect(
                rows.length,
                12,
                reason: 'offset $off: viewport must be exactly 12 rows',
              );
            }
          },
        );
      }
    }
  });
}
