import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

/// Sample unified diff for widget tests.
const _sampleDiff = '''
diff --git a/lib/main.dart b/lib/main.dart
index abc1234..def5678 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,5 +1,6 @@
 import 'dart:io';
 
-void main() {
+void main(List<String> args) {
+  print('Hello');
   exit(0);
 }''';

final _longDiff =
    '''
diff --git a/lib/main.dart b/lib/main.dart
index abc1234..def5678 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,3 +1,33 @@
 void main() {
${List<String>.generate(30, (index) {
      final line = (index + 1).toString().padLeft(3, '0');
      return "+  print('line $line');";
    }).join('\n')}
  }''';

/// A `StatefulWidget` card whose `view()` would throw if measured via
/// `renderWidget` (the original broken approach). It renders [rows] text lines
/// so it has a real, measurable height. Used to lock in the `ElementTree`-based
/// measurer, which must handle `StatefulWidget` subtrees without throwing.
class _StatefulCard extends StatefulWidget {
  _StatefulCard({required this.rows});

  final int rows;

  @override
  State<_StatefulCard> createState() => _StatefulCardState();
}

class _StatefulCardState extends State<_StatefulCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.rows; i++) Text('STATEFUL_LINE_$i'),
      ],
    );
  }
}

void main() {
  group('GitDiffViewer', () {
    test('renders diff content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        GitDiffViewer(diff: _sampleDiff, width: 80, height: 24),
      );

      // The rendered output should contain parts of the diff
      expect(tester.find.text('main.dart'), isTrue);
    });

    test('shows line content from diff', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        GitDiffViewer(diff: _sampleDiff, width: 80, height: 40),
      );

      expect(tester.find.text('dart:io'), isTrue);
    });

    test('renders with controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();

      await tester.pumpWidget(
        GitDiffViewer(
          diff: _sampleDiff,
          width: 80,
          height: 24,
          controller: controller,
        ),
      );

      expect(controller.files, hasLength(1));
      expect(controller.totalAdditions, 2);
      expect(controller.totalDeletions, 1);
    });

    test('handles empty diff', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(GitDiffViewer(diff: '', width: 80, height: 24));

      // Should render without error
      expect(tester.find.text('main.dart'), isFalse);
    });

    test('respects showLineNumbers false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        GitDiffViewer(
          diff: _sampleDiff,
          width: 80,
          height: 40,
          showLineNumbers: false,
        ),
      );

      // Should still render content
      expect(tester.find.text('main.dart'), isTrue);
    });

    test('supports key', () {
      final viewer = GitDiffViewer(
        key: ValueKey('diff-key'),
        diff: _sampleDiff,
      );
      expect(viewer.id, equals('diff-key'));
    });

    test('has unique id', () {
      final v1 = GitDiffViewer(diff: '');
      final v2 = GitDiffViewer(diff: '');
      expect(v1.id, isNot(equals(v2.id)));
    });

    test('mouse wheel scrolls when comment hit-testing is enabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        GitDiffViewer(
          diff: _longDiff,
          width: 80,
          height: 8,
          onCommentAnchorSelected: (_) => tui.Cmd.none(),
        ),
      );

      expect(tester.view, contains('line 001'));
      expect(tester.view, isNot(contains('line 010')));

      for (var i = 0; i < 3; i++) {
        tester.sendMsg(
          const tui.MouseMsg(
            action: tui.MouseAction.press,
            button: tui.MouseButton.wheelDown,
            x: 4,
            y: 2,
          ),
        );
      }

      expect(tester.view, isNot(contains('line 001')));
      expect(tester.view, contains('line 010'));
    });
  });

  group('GitDiffController', () {
    test('creates with default model', () {
      final controller = GitDiffController();
      expect(controller.model, isNotNull);
      expect(controller.files, isEmpty);
      expect(controller.totalAdditions, 0);
      expect(controller.totalDeletions, 0);
    });

    test('setDiff parses content', () {
      final controller = GitDiffController();
      controller.setDiff(_sampleDiff);
      expect(controller.files, hasLength(1));
      expect(controller.totalAdditions, 2);
      expect(controller.totalDeletions, 1);
    });

    test('setSize updates dimensions', () {
      final controller = GitDiffController();
      controller.setSize(120, 40);
      expect(controller.model.width, 120);
      expect(controller.model.height, 40);
    });

    test('configure updates options', () {
      final controller = GitDiffController();
      controller.configure(showLineNumbers: false);
      expect(controller.model.showLineNumbers, isFalse);
    });

    test('configure re-renders when viewMode changes', () {
      final controller = GitDiffController();
      controller.setDiff(_sampleDiff);
      final unifiedView = controller.model.view();

      controller.configure(viewMode: DiffViewMode.pretty);
      final prettyView = controller.model.view();

      // Pretty mode uses a different header format ("← Edit ...")
      expect(prettyView, contains('\u2190 Edit'));
      // Unified mode uses raw diff header (diff --git ...)
      expect(unifiedView, isNot(contains('\u2190 Edit')));
    });

    test('notifies listeners on setDiff', () {
      final controller = GitDiffController();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setDiff(_sampleDiff);
      expect(notified, isTrue);
    });

    test('removeListener stops notifications', () {
      final controller = GitDiffController();
      var count = 0;
      void listener() => count++;
      controller.addListener(listener);
      controller.setDiff(_sampleDiff);
      expect(count, 1);
      controller.removeListener(listener);
      controller.setDiff('');
      expect(count, 1); // not incremented again
    });
  });

  group('GitDiffViewer integration', () {
    test('in Column with other widgets', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Diff Viewer'),
            GitDiffViewer(diff: _sampleDiff, width: 80, height: 20),
          ],
        ),
      );

      expect(tester.find.text('Diff Viewer'), isTrue);
      expect(tester.find.text('main.dart'), isTrue);
    });
  });

  group('GitDiffViewer theme integration', () {
    test('renders with theme-derived styles when no custom styles', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: GitDiffViewer(diff: _sampleDiff, width: 80, height: 40),
        ),
      );

      // Should render successfully using theme colors
      expect(tester.find.text('main.dart'), isTrue);
      expect(tester.find.text('dart:io'), isTrue);
    });

    test('renders with light theme', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final originalDarkBackground = hasDarkBackground;
      addTearDown(() => setHasDarkBackground(originalDarkBackground));
      setHasDarkBackground(false);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.light(),
          child: GitDiffViewer(
            diff: _sampleDiff,
            width: 80,
            height: 40,
            controller: controller,
          ),
        ),
      );

      expect(tester.find.text('main.dart'), isTrue);
      expect(controller.model.styles.addedLine.hasDarkBackground, isFalse);
      expect(controller.model.styles.fileHeader.hasDarkBackground, isFalse);
    });

    test('custom DiffStyles override theme defaults', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();

      final customStyles = DiffStyles();

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: GitDiffViewer(
            diff: _sampleDiff,
            width: 80,
            height: 40,
            styles: customStyles,
            controller: controller,
          ),
        ),
      );

      // When custom styles are provided, theme should not override them
      expect(controller.model.styles, equals(customStyles));
    });

    test('theme styles apply to all view modes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      for (final mode in DiffViewMode.values) {
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: GitDiffViewer(
              diff: _sampleDiff,
              width: 120,
              height: 40,
              viewMode: mode,
            ),
          ),
        );

        // All modes should render without errors
        expect(
          tester.find.text('main.dart'),
          isTrue,
          reason: '$mode should render file name',
        );
      }
    });

    test('without ThemeScope still renders with defaults', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // No ThemeScope wrapping — should fall back to currentTheme
      await tester.pumpWidget(
        GitDiffViewer(diff: _sampleDiff, width: 80, height: 40),
      );

      expect(tester.find.text('main.dart'), isTrue);
    });

    test('comment highlights adapt to terminal background', () {
      final dark = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
        hasDarkBackground: true,
      );
      final light = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
        hasDarkBackground: false,
      );

      expect(
        dark.selectedCommentLine.render('x'),
        isNot(equals(light.selectedCommentLine.render('x'))),
      );
      expect(
        dark.commentRangeLine.render('x'),
        isNot(equals(light.commentRangeLine.render('x'))),
      );
      expect(
        dark.commentThreadLine.render('x'),
        isNot(equals(light.commentThreadLine.render('x'))),
      );
    });

    test('comment range accepts custom theme styling', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final originalDarkBackground = hasDarkBackground;
      addTearDown(() => setHasDarkBackground(originalDarkBackground));
      setHasDarkBackground(false);

      const rangeBg = BasicColor('#cfe8ff');
      const rangeGutterBg = BasicColor('#9bc7ff');

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.light().copyWith(
            gitDiffTheme: const GitDiffThemeData(
              commentRangeLineBackground: rangeBg,
              commentRangeGutterBackground: rangeGutterBg,
            ),
          ),
          child: GitDiffViewer(
            diff: _sampleDiff,
            width: 80,
            height: 24,
            controller: controller,
            commentHighlights: const [
              DiffCommentLineHighlight(
                key: DiffCommentLineKey(
                  path: 'lib/main.dart',
                  line: 3,
                  side: DiffCommentSide.right,
                ),
                kind: DiffCommentLineHighlightKind.range,
              ),
            ],
          ),
        ),
      );

      expect(tester.find.text('main.dart'), isTrue);
      expect(
        controller.model.styles.commentRangeLine.render('x'),
        contains('48;2;207;232;255'),
      );
      expect(
        controller.model.styles.commentRangeGutter.render('x'),
        contains('48;2;155;199;255'),
      );
    });

    test('renders comment blocks between diff lines', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final scroll = WidgetScrollController();

      await tester.pumpWidget(
        GitDiffViewer(
          diff: _sampleDiff,
          width: 80,
          height: 24,
          controller: controller,
          scrollController: scroll,
          commentBlocks: [
            DiffCommentBlock(
              renderLine: 2,
              height: 1,
              child: Text('INLINE_COMMENT_MARKER'),
            ),
          ],
        ),
      );

      // Diff content still renders.
      expect(tester.find.text('main.dart'), isTrue);
      // Inline comment block is rendered in the tree.
      expect(tester.find.text('INLINE_COMMENT_MARKER'), isTrue);
    });

    test('renders comment blocks without a scroll controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        GitDiffViewer(
          diff: _sampleDiff,
          width: 80,
          height: 24,
          commentBlocks: [
            DiffCommentBlock(
              renderLine: 2,
              height: 1,
              child: Text('STILL_APPEARS'),
            ),
          ],
        ),
      );

      expect(tester.find.text('STILL_APPEARS'), isTrue);
    });

    test('renders comments placed via anchor renderLine (real flow)', () async {
      // Mimics github_cli's _selectedFileDiff: the controller is pre-loaded
      // with setDiff/setSize, then GitDiffViewer injects the comment blocks.
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final scroll = WidgetScrollController();

      controller.setDiff(_sampleDiff);
      controller.setSize(80, 30);
      final anchors = controller.model.commentAnchors;
      expect(anchors, isNotEmpty);

      // Pick a stable anchor (e.g. the first non-file-header anchor).
      final anchor = anchors.first;
      final placedLine = anchor.renderLine;
      expect(placedLine, lessThan(controller.renderedLines.length));

      await tester.pumpWidget(
        GitDiffViewer(
          diff: _sampleDiff,
          width: 80,
          height: 30,
          controller: controller,
          scrollController: scroll,
          commentBlocks: [
            DiffCommentBlock(
              renderLine: placedLine,
              height: 1,
              child: Text('ANCHORED_COMMENT_BODY'),
            ),
          ],
        ),
      );

      expect(
        tester.find.text('ANCHORED_COMMENT_BODY'),
        isTrue,
        reason: 'comment must render inline at its anchor line',
      );
      // The diff lines around the anchor should still be present.
      expect(tester.find.text('main.dart'), isTrue);
    });

    test('scrolls comment blocks through the viewport (no overflow)', () async {
      // Comment blocks are composed into the viewer's own scrollable content
      // (diff lines + widget cards), so the SingleChildScrollView clips the
      // composed column to the viewer height (no overflow into other widgets
      // such as the status bar). The external scroll controller is in
      // render-line space; the viewer translates it into the composed
      // content-row space internally.
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final scroll = WidgetScrollController();

      const blockLine = 10;
      final commentLines = ['B0', 'B1', 'B2', 'B3', 'B4'];

      Future<void> pump() => tester.pumpWidget(
        GitDiffViewer(
          diff: _longDiff,
          width: 80,
          height: 12,
          controller: controller,
          scrollController: scroll,
          commentBlocks: [
            DiffCommentBlock(
              renderLine: blockLine,
              height: commentLines.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final c in commentLines) Text(c)],
              ),
            ),
          ],
        ),
        width: 80,
        height: 12,
      );

      await pump();
      expect(
        tester.view.split('\n').length,
        12,
        reason: 'viewport must stay exactly height rows (no overflow)',
      );

      // Scroll (render-line space) so the block is at the top of the viewport.
      scroll.jumpTo(blockLine);
      await pump();
      expect(
        tester.find.text('B0'),
        isTrue,
        reason: 'comment block is visible when scrolled to its render-line',
      );
      expect(
        tester.view.split('\n').length,
        12,
        reason: 'viewport height is preserved while scrolled',
      );

      // Scroll deeper so the comment block is scrolled past the bottom.
      scroll.jumpTo(blockLine + 12);
      await pump();
      expect(
        tester.find.text('B3'),
        isFalse,
        reason: 'comment block is scrolled out of view',
      );
      expect(
        tester.view.split('\n').length,
        12,
        reason: 'viewport height is preserved at the bottom clip',
      );
    });

    test('tapping a diff line below a comment selects that line, not the '
        'comment', () async {
      // Regression: tapping a diff line below a comment card must resolve to
      // the tapped line's own anchor (or nothing), never snap to and jump to
      // the comment card above it.
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final scroll = WidgetScrollController();
      DiffCommentAnchor? selected;

      Future<void> pump() => tester.pumpWidget(
        GitDiffViewer(
          diff: _sampleDiff,
          width: 80,
          height: 12,
          controller: controller,
          scrollController: scroll,
          commentBlocks: [
            DiffCommentBlock(
              renderLine: 8,
              height: 3,
              child: Text('COMMENT_CARD'),
            ),
          ],
          onCommentAnchorSelected: (anchor) {
            selected = anchor;
            return tui.Cmd.none();
          },
        ),
        width: 80,
        height: 12,
      );

      await pump();

      // The comment block sits at render-line 8 (content rows 9..11). Tap a
      // diff line at content row 7 (render-line 7, an anchor line ABOVE the
      // comment). Before the fix, the nearest-anchor lookup could snap to the
      // comment; now it must resolve to the tapped line exactly.
      const y = 7;
      tester.mouseDown(2, y);
      tester.mouseUp(2, y);

      expect(
        selected,
        isNotNull,
        reason: 'tapping a diff line should select an anchor',
      );
      expect(
        selected!.renderLine,
        equals(7),
        reason:
            'tapping a diff line must resolve to that line, not the '
            'comment at render-line 8',
      );
      expect(
        selected!.renderLine,
        isNot(equals(8)),
        reason: 'tapping must not snap to / jump to the comment',
      );
    });

    test('tapping below a tall comment card resolves to the visible line '
        '(no height-estimate offset)', () async {
      // Regression: the row->render-line map must use the comment card's REAL
      // rendered height, not DiffCommentBlock.height. When the card renders
      // taller than its height estimate, every line below it shifts, so tapping
      // the line displayed at screen row R must select that exact line.
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final scroll = WidgetScrollController();
      DiffCommentAnchor? selected;

      // A card that renders to 7 rows (a multi-line Text) but is described to
      // the viewer with a height estimate of 1 (much too small).
      final tallCard = Text(
        <String>[for (var i = 0; i < 7; i++) 'CARD_LINE_$i'].join('\n'),
      );

      const cardRenderLine = 10;
      const targetRenderLine = 30; // an anchor well below the card in _longDiff

      Future<void> pump() => tester.pumpWidget(
        GitDiffViewer(
          diff: _longDiff,
          width: 80,
          height: 40,
          controller: controller,
          scrollController: scroll,
          commentBlocks: [
            DiffCommentBlock(
              renderLine: cardRenderLine,
              height: 1, // deliberately wrong (small) estimate
              child: tallCard,
            ),
          ],
          onCommentAnchorSelected: (anchor) {
            selected = anchor;
            return tui.Cmd.none();
          },
        ),
        width: 80,
        height: 40,
      );

      await pump();

      // Real on-screen row of targetRenderLine: renderLine r occupies row r for
      // r <= cardRenderLine; the 7-row card then occupies the next 7 rows, so
      // each later line shifts by +7. Thus row = targetRenderLine + 7.
      const cardRows = 7;
      final screenRow = targetRenderLine + cardRows;
      tester.mouseDown(2, screenRow);
      tester.mouseUp(2, screenRow);

      expect(
        selected,
        isNotNull,
        reason: 'tapping a visible diff line should select an anchor',
      );
      expect(
        selected!.renderLine,
        equals(targetRenderLine),
        reason:
            'tapping the line displayed at screen row $screenRow must '
            'resolve to render-line $targetRenderLine, not an offset line',
      );
    });

    test('tapping below a StatefulWidget comment card resolves correctly '
        '(ElementTree measurer handles StatefulWidgets)', () async {
      // Regression for the Build crash: measuring a comment card whose subtree
      // contains a StatefulWidget (e.g. MarkdownText/Image in github_cli) via
      // renderWidget().view() throws "StatefulWidget requires WidgetApp
      // rendering". The viewer must mount such cards via ElementTree instead.
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final scroll = WidgetScrollController();
      DiffCommentAnchor? selected;

      const cardRenderLine = 10;
      const targetRenderLine = 30;
      const cardRows = 7;

      Future<void> pump() => tester.pumpWidget(
        GitDiffViewer(
          diff: _longDiff,
          width: 80,
          height: 40,
          controller: controller,
          scrollController: scroll,
          commentBlocks: [
            DiffCommentBlock(
              renderLine: cardRenderLine,
              height: 1, // deliberately wrong (small) estimate
              child: _StatefulCard(rows: cardRows),
            ),
          ],
          onCommentAnchorSelected: (anchor) {
            selected = anchor;
            return tui.Cmd.none();
          },
        ),
        width: 80,
        height: 40,
      );

      await pump();

      // Real on-screen row of targetRenderLine: renderLine r occupies row r for
      // r <= cardRenderLine; the 7-row card then occupies the next 7 rows, so
      // each later line shifts by +7. Thus row = targetRenderLine + 7.
      final screenRow = targetRenderLine + cardRows;
      tester.mouseDown(2, screenRow);
      tester.mouseUp(2, screenRow);

      expect(
        selected,
        isNotNull,
        reason: 'tapping a visible diff line should select an anchor',
      );
      expect(
        selected!.renderLine,
        equals(targetRenderLine),
        reason:
            'tapping the line displayed at screen row $screenRow must '
            'resolve to render-line $targetRenderLine, not an offset line',
      );
    });

    test('end-to-end: review comments map to comment blocks', () async {
      // Replicates github_cli's _selectedFileDiff mapping path with a
      // multi-file diff and comments whose path/line/side match anchors.
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final controller = GitDiffController();
      final scroll = WidgetScrollController();

      const multiDiff = '''
diff --git a/lib/a.dart b/lib/a.dart
index 1111111..2222222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,3 +1,4 @@
 class A {
+  int x = 1;
   void foo() {}
 }
diff --git a/lib/b.dart b/lib/b.dart
index 3333333..4444444 100644
--- a/lib/b.dart
+++ b/lib/b.dart
@@ -1,2 +1,3 @@
 class B {
+  int y = 2;
   void bar() {}
 }''';

      controller.setDiff(multiDiff);
      controller.setSize(80, 40);
      final anchors = controller.model.commentAnchors;
      expect(anchors, isNotEmpty);

      // Fake a review comment that matches the first anchor exactly.
      final target = anchors.first;
      final fakeComment = _FakeReviewComment(
        path: target.path,
        line: target.line,
        side: target.side == DiffCommentSide.left ? 'LEFT' : 'RIGHT',
        body: 'MAPPED_COMMENT_BODY',
      );

      // Replicate mapReviewCommentsToRenderLines.
      final commentsByLine = <int, List<_FakeReviewComment>>{};
      for (final comment in [fakeComment]) {
        final commentSide = comment.side == 'LEFT'
            ? DiffCommentSide.left
            : DiffCommentSide.right;
        for (final anchor in anchors) {
          if (anchor.path == comment.path &&
              anchor.line == comment.line &&
              anchor.side == commentSide) {
            commentsByLine.putIfAbsent(anchor.renderLine, () => [])
              .add(comment);
            break;
          }
        }
      }
      expect(
        commentsByLine,
        isNotEmpty,
        reason: 'comment should map to a render line',
      );

      final commentBlocks = [
        for (final entry in commentsByLine.entries)
          DiffCommentBlock(
            renderLine: entry.key,
            height: 1,
            child: Text(entry.value.first.body),
          ),
      ];

      await tester.pumpWidget(
        GitDiffViewer(
          diff: multiDiff,
          width: 80,
          height: 40,
          controller: controller,
          scrollController: scroll,
          commentBlocks: commentBlocks,
        ),
      );

      expect(
        tester.find.text('MAPPED_COMMENT_BODY'),
        isTrue,
        reason: 'mapped review comment must render inline',
      );
    });
  });
}

/// Minimal stand-in for github_cli's GithubPullRequestReviewComment.
final class _FakeReviewComment {
  const _FakeReviewComment({
    required this.path,
    required this.line,
    required this.side,
    required this.body,
  });
  final String path;
  final int line;
  final String side;
  final String body;
}
