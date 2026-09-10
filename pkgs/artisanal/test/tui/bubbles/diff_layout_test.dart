import 'package:artisanal/git_diff.dart';
import 'package:test/test.dart';

void main() {
  String patch(String context) =>
      '''
diff --git a/example.dart b/example.dart
--- a/example.dart
+++ b/example.dart
@@ -1,2 +1,2 @@
 $context
-before
+after
''';

  group('DiffLayout', () {
    test('split anchors follow actual asymmetric panel wrapping', () {
      // At width 40, the left panel has 12 content columns and the right 13.
      final model = GitDiffModel(
        width: 40,
        viewMode: DiffViewMode.sideBySide,
      ).setDiff(patch('1234567890123'));
      final context = model.commentAnchors.where((a) => a.line == 1).toList();
      final left = context.singleWhere((a) => a.side == DiffCommentSide.left);
      final right = context.singleWhere((a) => a.side == DiffCommentSide.right);
      expect(left.renderLineEnd - left.renderLine, 2);
      expect(right.renderLineEnd - right.renderLine, 1);
      final next = model.commentAnchors.firstWhere((a) => a.line == 2);
      expect(next.renderLine, left.renderLineEnd);
      expect(model.renderedLines[next.renderLine], contains('before'));
      expect(model.renderedLines[next.renderLine], contains('after'));
    });

    for (final mode in DiffViewMode.values) {
      test('$mode shares immutable rows and exact source lookup', () {
        final model = GitDiffModel(
          width: 40,
          viewMode: mode,
        ).setDiff(patch('context'));
        expect(identical(model.layout.lines, model.renderedLines), isTrue);
        for (final anchor in model.commentAnchors) {
          expect(model.layout.anchorFor(anchor.key), same(anchor));
          expect(anchor.renderLine, greaterThanOrEqualTo(0));
          expect(
            anchor.renderLineEnd,
            lessThanOrEqualTo(model.renderedLines.length),
          );
        }
        expect(
          model.layout.anchorFor(
            const DiffCommentLineKey(
              path: 'missing.dart',
              line: 1,
              side: DiffCommentSide.right,
            ),
          ),
          isNull,
        );
        expect(() => model.layout.lines.clear(), throwsUnsupportedError);
        expect(() => model.layout.anchors.clear(), throwsUnsupportedError);
      });
    }

    test('viewport-only updates reuse layout and anchor identities', () {
      final model = GitDiffModel(height: 1).setDiff(patch('context'));
      final scrolled = model.copyWith(viewport: model.viewport.setYOffset(1));
      expect(scrolled.layout, same(model.layout));
      expect(scrolled.commentAnchors, same(model.commentAnchors));
    });

    test('resize preserves source identity and replaces geometry', () {
      final model = GitDiffModel(width: 80).setDiff(patch('x' * 90));
      final resized = model.copyWith(width: 30).rerender();
      expect(resized.layout, isNot(same(model.layout)));
      expect(
        resized.commentAnchors.map((a) => a.key),
        orderedEquals(model.commentAnchors.map((a) => a.key)),
      );
      expect(
        resized.renderedLines.length,
        greaterThan(model.renderedLines.length),
      );
    });

    test('narrow split fallback emits unified geometry', () {
      final raw = patch('context');
      final split = GitDiffModel(
        width: 10,
        viewMode: DiffViewMode.sideBySide,
      ).setDiff(raw);
      final unified = GitDiffModel(width: 10).setDiff(raw);
      expect(split.renderedLines, unified.renderedLines);
      expect(
        split.commentAnchors.map((a) => (a.key, a.renderLine, a.renderLineEnd)),
        orderedEquals(
          unified.commentAnchors.map(
            (a) => (a.key, a.renderLine, a.renderLineEnd),
          ),
        ),
      );
    });
  });
}
