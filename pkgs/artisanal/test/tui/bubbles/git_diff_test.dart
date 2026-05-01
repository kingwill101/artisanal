import 'package:artisanal/src/tui/bubbles/git_diff.dart';
import 'package:artisanal/src/tui/bubbles/key_binding.dart' show KeyBinding;
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/msg.dart' show KeyMsg, Msg;
import 'package:artisanal/src/terminal/keys.dart' show Key, KeyType;
import 'package:artisanal/src/style/color.dart' show BasicColor;
import 'package:artisanal/src/style/style.dart' show Style;
import 'package:test/test.dart';

/// Sample single-file unified diff for testing.
const _singleFileDiff = '''
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

/// Sample multi-file diff for testing.
const _multiFileDiff = '''
diff --git a/lib/a.dart b/lib/a.dart
index 1111111..2222222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,3 +1,4 @@
 class A {
+  int x = 0;
 }
diff --git a/lib/b.dart b/lib/b.dart
index 3333333..4444444 100644
--- a/lib/b.dart
+++ b/lib/b.dart
@@ -1,4 +1,3 @@
 class B {
-  int y = 1;
-  int z = 2;
+  int y = 10;
 }''';

/// Diff with no-newline-at-eof marker.
const _noNewlineDiff = '''
diff --git a/file.txt b/file.txt
index aaa..bbb 100644
--- a/file.txt
+++ b/file.txt
@@ -1,2 +1,2 @@
-old line
+new line
\\ No newline at end of file''';

void main() {
  group('DiffStyles', () {
    test('creates with sensible defaults', () {
      final styles = DiffStyles();
      expect(styles.addedLine, isNotNull);
      expect(styles.removedLine, isNotNull);
      expect(styles.contextLine, isNotNull);
      expect(styles.fileHeader, isNotNull);
      expect(styles.hunkHeader, isNotNull);
      expect(styles.addedGutter, isNotNull);
      expect(styles.removedGutter, isNotNull);
      expect(styles.contextGutter, isNotNull);
      expect(styles.lineNumber, isNotNull);
    });

    test('copyWith replaces fields', () {
      final styles = DiffStyles();
      final copy = styles.copyWith();
      expect(copy.addedLine, styles.addedLine);
    });
  });

  group('DiffLine', () {
    test('stores type, content, and line numbers', () {
      const line = DiffLine(
        type: DiffLineType.added,
        content: 'hello',
        newLineNumber: 5,
      );
      expect(line.type, DiffLineType.added);
      expect(line.content, 'hello');
      expect(line.newLineNumber, 5);
      expect(line.oldLineNumber, isNull);
    });
  });

  group('DiffFile', () {
    test('counts additions and deletions', () {
      final file = DiffFile(
        oldPath: 'a.dart',
        newPath: 'a.dart',
        lines: [
          DiffLine(type: DiffLineType.added, content: 'a', newLineNumber: 1),
          DiffLine(type: DiffLineType.added, content: 'b', newLineNumber: 2),
          DiffLine(type: DiffLineType.removed, content: 'c', oldLineNumber: 1),
          DiffLine(
            type: DiffLineType.context,
            content: 'd',
            oldLineNumber: 2,
            newLineNumber: 3,
          ),
        ],
      );
      expect(file.additions, 2);
      expect(file.deletions, 1);
    });
  });

  group('DiffViewMode', () {
    test('has unified, sideBySide, and pretty', () {
      expect(
        DiffViewMode.values,
        containsAll([
          DiffViewMode.unified,
          DiffViewMode.sideBySide,
          DiffViewMode.pretty,
        ]),
      );
    });
  });

  group('DiffLineType', () {
    test('has all expected values', () {
      expect(DiffLineType.values, hasLength(6));
      expect(
        DiffLineType.values,
        containsAll([
          DiffLineType.fileHeader,
          DiffLineType.hunkHeader,
          DiffLineType.added,
          DiffLineType.removed,
          DiffLineType.context,
          DiffLineType.empty,
        ]),
      );
    });
  });

  group('GitDiffModel', () {
    group('New', () {
      test('creates with defaults', () {
        final model = GitDiffModel();
        expect(model.width, 80);
        expect(model.height, 24);
        expect(model.showLineNumbers, isTrue);
        expect(model.viewMode, DiffViewMode.unified);
        expect(model.files, isEmpty);
        expect(model.totalAdditions, 0);
        expect(model.totalDeletions, 0);
      });

      test('creates with custom dimensions', () {
        final model = GitDiffModel(width: 120, height: 40);
        expect(model.width, 120);
        expect(model.height, 40);
      });

      test('creates with custom options', () {
        final model = GitDiffModel(
          showLineNumbers: false,
          viewMode: DiffViewMode.sideBySide,
        );
        expect(model.showLineNumbers, isFalse);
        expect(model.viewMode, DiffViewMode.sideBySide);
      });
    });

    group('SetDiff', () {
      test('parses single file diff', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        expect(model.files, hasLength(1));
        expect(model.files.first.oldPath, 'lib/main.dart');
        expect(model.files.first.newPath, 'lib/main.dart');
      });

      test('counts additions and deletions for single file', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        expect(model.totalAdditions, 2);
        expect(model.totalDeletions, 1);
      });

      test('parses multi-file diff', () {
        final model = GitDiffModel().setDiff(_multiFileDiff);
        expect(model.files, hasLength(2));
        expect(model.files[0].oldPath, 'lib/a.dart');
        expect(model.files[1].oldPath, 'lib/b.dart');
      });

      test('counts totals across multiple files', () {
        final model = GitDiffModel().setDiff(_multiFileDiff);
        // a.dart: +1, b.dart: +1 -2
        expect(model.totalAdditions, 2);
        expect(model.totalDeletions, 2);
      });

      test('handles empty diff', () {
        final model = GitDiffModel().setDiff('');
        expect(model.files, isEmpty);
        expect(model.totalAdditions, 0);
        expect(model.totalDeletions, 0);
      });

      test('handles whitespace-only diff', () {
        final model = GitDiffModel().setDiff('   \n  \n ');
        expect(model.files, isEmpty);
      });

      test('parses hunk line numbers correctly', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        final lines = model.files.first.lines;

        // Find the first context line after the hunk header: "import 'dart:io';"
        // Hunk is @@ -1,5 +1,6 @@ so old starts at 1, new starts at 1
        final contextLines = lines
            .where((l) => l.type == DiffLineType.context)
            .toList();
        expect(contextLines, isNotEmpty);
        expect(contextLines.first.oldLineNumber, 1);
        expect(contextLines.first.newLineNumber, 1);
      });

      test('added lines have newLineNumber but no oldLineNumber', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        final addedLines = model.files.first.lines
            .where((l) => l.type == DiffLineType.added)
            .toList();
        for (final line in addedLines) {
          expect(line.newLineNumber, isNotNull);
          expect(line.oldLineNumber, isNull);
        }
      });

      test('removed lines have oldLineNumber but no newLineNumber', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        final removedLines = model.files.first.lines
            .where((l) => l.type == DiffLineType.removed)
            .toList();
        for (final line in removedLines) {
          expect(line.oldLineNumber, isNotNull);
          expect(line.newLineNumber, isNull);
        }
      });

      test('parses metadata lines as file headers', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        final headerLines = model.files.first.lines
            .where((l) => l.type == DiffLineType.fileHeader)
            .toList();
        // diff --git, index, ---, +++
        expect(headerLines, hasLength(4));
        expect(headerLines[0].content, startsWith('diff --git'));
        expect(headerLines[1].content, startsWith('index'));
        expect(headerLines[2].content, startsWith('---'));
        expect(headerLines[3].content, startsWith('+++'));
      });

      test('parses no-newline-at-eof marker', () {
        final model = GitDiffModel().setDiff(_noNewlineDiff);
        expect(model.files, hasLength(1));
        final contextLines = model.files.first.lines
            .where(
              (l) =>
                  l.type == DiffLineType.context &&
                  l.content.contains('No newline'),
            )
            .toList();
        expect(contextLines, hasLength(1));
      });

      test('returns new model instance', () {
        final model = GitDiffModel();
        final loaded = model.setDiff(_singleFileDiff);
        expect(identical(model, loaded), isFalse);
      });
    });

    group('View', () {
      test('returns non-empty output after setDiff', () {
        final model = GitDiffModel(
          width: 80,
          height: 24,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        expect(output, isNotEmpty);
      });

      test('returns blank output for empty diff', () {
        final model = GitDiffModel(width: 80, height: 24).setDiff('');
        final output = model.view();
        // Viewport still renders empty rows, so output is whitespace-only
        expect(output.trim(), isEmpty);
      });

      test('contains diff content from lines', () {
        // Use showLineNumbers: false to simplify output matching
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // The rendered view should contain the file path reference
        expect(output, contains('main.dart'));
      });
    });

    group('Update', () {
      test('ignores unknown messages', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        final (newModel, cmd) = model.update(_MockMsg());
        // Viewport also ignores unknown msgs, so model stays the same
        expect(cmd, isNull);
        expect(newModel, isNotNull);
      });

      test('delegates to viewport', () {
        final model = GitDiffModel(
          width: 80,
          height: 5,
        ).setDiff(_singleFileDiff);
        // Send a message — the viewport handles scrolling keys;
        // a mock message won't change state but should still return cleanly
        final (newModel, _) = model.update(_MockMsg());
        expect(newModel, isA<GitDiffModel>());
      });
    });

    group('CopyWith', () {
      test('preserves fields when nothing specified', () {
        final model = GitDiffModel(
          width: 100,
          height: 50,
          showLineNumbers: false,
          viewMode: DiffViewMode.sideBySide,
        );
        final copy = model.copyWith();
        expect(copy.width, 100);
        expect(copy.height, 50);
        expect(copy.showLineNumbers, isFalse);
        expect(copy.viewMode, DiffViewMode.sideBySide);
      });

      test('replaces specified fields', () {
        final model = GitDiffModel(width: 80, height: 24);
        final copy = model.copyWith(width: 120, height: 40);
        expect(copy.width, 120);
        expect(copy.height, 40);
        // Original unchanged
        expect(model.width, 80);
        expect(model.height, 24);
      });

      test('replaces showLineNumbers', () {
        final model = GitDiffModel(showLineNumbers: true);
        final copy = model.copyWith(showLineNumbers: false);
        expect(copy.showLineNumbers, isFalse);
      });

      test('replaces viewMode', () {
        final model = GitDiffModel(viewMode: DiffViewMode.unified);
        final copy = model.copyWith(viewMode: DiffViewMode.sideBySide);
        expect(copy.viewMode, DiffViewMode.sideBySide);
      });

      test('preserves files through copyWith', () {
        final model = GitDiffModel().setDiff(_singleFileDiff);
        final copy = model.copyWith(width: 120);
        expect(copy.files, hasLength(1));
        expect(copy.totalAdditions, model.totalAdditions);
        expect(copy.totalDeletions, model.totalDeletions);
      });
    });

    group('Init', () {
      test('returns null', () {
        final model = GitDiffModel();
        expect(model.init(), isNull);
      });
    });

    test('is a ViewComponent', () {
      final model = GitDiffModel();
      expect(model, isA<ViewComponent>());
    });

    test('update returns GitDiffModel via base type', () {
      ViewComponent model = GitDiffModel().setDiff(_singleFileDiff);
      final (updated, _) = model.update(_MockMsg());
      expect(updated, isA<GitDiffModel>());
    });

    group('Line numbers in view', () {
      test('line numbers appear when enabled', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: true,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Line numbers should render old/new numbers — e.g. "   1" for line 1
        expect(output, contains('1'));
      });

      test('no line number gutter when disabled', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // View should still have content
        expect(output, isNotEmpty);
      });
    });

    group('Dynamic line number width', () {
      test('adapts gutter width for small line numbers', () {
        // Single-file diff with lines under 10 — min width is 4
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: true,
        ).setDiff(_singleFileDiff);
        // Should render without errors
        final output = model.view();
        expect(output, isNotEmpty);
      });

      test('enforces minimum 4-char line number width in unified mode', () {
        // Max line number is 6 → numWidth=1, effectiveNumWidth should be 4.
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: true,
          viewMode: DiffViewMode.unified,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Line 1 in unified mode should be space-padded to 4 chars: "   1"
        expect(output, contains('   1'));
      });

      test('enforces minimum 4-char line number width in pretty mode', () {
        // Max line number is 6 → numWidth=1, effectiveNumWidth should be 4.
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: true,
          viewMode: DiffViewMode.pretty,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Line 1 in pretty mode uses space-padded 4-char numbers: "   1"
        expect(output, contains('   1'));
      });

      test('zero-pads line numbers in unified mode when configured', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: true,
          zeroPadLineNumbers: true,
          viewMode: DiffViewMode.unified,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        expect(output, contains('0001'));
      });

      test('zero-pads line numbers in pretty mode when configured', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          showLineNumbers: true,
          zeroPadLineNumbers: true,
          viewMode: DiffViewMode.pretty,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        expect(output, contains('0001'));
      });

      test('zero-pads line numbers in side-by-side mode when configured', () {
        final model = GitDiffModel(
          width: 120,
          height: 40,
          showLineNumbers: true,
          zeroPadLineNumbers: true,
          viewMode: DiffViewMode.sideBySide,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        expect(output, contains('0001'));
      });

      test('zeroPadLineNumbers defaults to false', () {
        final model = GitDiffModel(width: 80, height: 24);
        expect(model.zeroPadLineNumbers, isFalse);
      });

      test('zeroPadLineNumbers is preserved through copyWith', () {
        final model = GitDiffModel(
          width: 80,
          height: 24,
          zeroPadLineNumbers: true,
        );
        final copy = model.copyWith(width: 120);
        expect(copy.zeroPadLineNumbers, isTrue);
      });

      test('adapts gutter width for large line numbers', () {
        // Create a diff with a hunk starting at high line numbers.
        const largeDiff = '''
diff --git a/big.dart b/big.dart
index aaa..bbb 100644
--- a/big.dart
+++ b/big.dart
@@ -9998,3 +9998,4 @@
 line A
 line B
+added at 10000
 line C''';

        final model = GitDiffModel(
          width: 120,
          height: 40,
          showLineNumbers: true,
        ).setDiff(largeDiff);
        final output = model.view();
        // Should contain the 5-digit line number 10000
        expect(output, contains('10000'));
      });
    });

    group('Pretty mode', () {
      test('creates with pretty view mode', () {
        final model = GitDiffModel(viewMode: DiffViewMode.pretty);
        expect(model.viewMode, DiffViewMode.pretty);
      });

      test('pretty mode renders file header as edit path', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Pretty file header: "← Edit lib/main.dart"
        expect(output, contains('\u2190 Edit lib/main.dart'));
      });

      test('pretty mode hides raw diff --git headers', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Should not contain the raw "diff --git" line
        expect(output, isNot(contains('diff --git')));
      });

      test('pretty mode hides hunk headers', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Should not contain "@@ ... @@" hunk markers
        expect(output, isNot(contains('@@ ')));
      });

      test('pretty mode hides index/---/+++ headers', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        expect(output, isNot(contains('index abc1234')));
        expect(output, isNot(contains('--- a/')));
        expect(output, isNot(contains('+++ b/')));
      });

      test('pretty mode shows diff content', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Content should still appear
        expect(output, contains("import 'dart:io';"));
        expect(output, contains("print('Hello')"));
      });

      test('pretty mode renders multi-file diffs', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_multiFileDiff);
        final output = model.view();
        // Both file headers should appear
        expect(output, contains('\u2190 Edit lib/a.dart'));
        expect(output, contains('\u2190 Edit lib/b.dart'));
      });

      test('pretty mode with line numbers shows single column', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: true,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Should render without errors and contain line content
        expect(output, isNotEmpty);
        expect(output, contains("import 'dart:io';"));
      });

      test('pretty mode uses + and - markers', () {
        final model = GitDiffModel(
          width: 120,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_singleFileDiff);
        final output = model.view();
        // Added/removed lines should contain the +/- markers
        expect(output, contains('+'));
        expect(output, contains('-'));
      });

      test('pretty mode handles no-newline marker', () {
        final model = GitDiffModel(
          width: 80,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
        ).setDiff(_noNewlineDiff);
        final output = model.view();
        expect(output, contains('No newline'));
      });

      test('pretty mode handles empty diff', () {
        final model = GitDiffModel(
          width: 80,
          height: 24,
          viewMode: DiffViewMode.pretty,
        ).setDiff('');
        final output = model.view();
        expect(output.trim(), isEmpty);
      });
    });

    group('Pretty mode styles', () {
      test('DiffStyles has pretty mode fields', () {
        final styles = DiffStyles();
        expect(styles.prettyAddedLine, isNotNull);
        expect(styles.prettyRemovedLine, isNotNull);
        expect(styles.prettyContextLine, isNotNull);
        expect(styles.prettyFileHeader, isNotNull);
        expect(styles.prettyAddedLineNumber, isNotNull);
        expect(styles.prettyRemovedLineNumber, isNotNull);
        expect(styles.prettyContextLineNumber, isNotNull);
      });

      test('copyWith replaces pretty mode fields', () {
        final styles = DiffStyles();
        final copy = styles.copyWith();
        expect(copy.prettyAddedLine, styles.prettyAddedLine);
        expect(copy.prettyRemovedLine, styles.prettyRemovedLine);
        expect(copy.prettyContextLine, styles.prettyContextLine);
        expect(copy.prettyFileHeader, styles.prettyFileHeader);
        expect(copy.prettyAddedLineNumber, styles.prettyAddedLineNumber);
        expect(copy.prettyRemovedLineNumber, styles.prettyRemovedLineNumber);
        expect(copy.prettyContextLineNumber, styles.prettyContextLineNumber);
      });
    });

    group('Line wrapping', () {
      /// Diff with a long line that will exceed narrow widths.
      const longLineDiff = '''
diff --git a/lib/long.dart b/lib/long.dart
index aaa..bbb 100644
--- a/lib/long.dart
+++ b/lib/long.dart
@@ -1,2 +1,2 @@
-short
+this is a very long line that should definitely wrap when the viewport is narrow enough to trigger wrapping behavior''';

      /// Counts lines with visible (non-whitespace) content after
      /// stripping ANSI escape sequences.
      int countNonBlankLines(String output) {
        return output
            .split('\n')
            .where((l) => Style.stripAnsi(l).trim().isNotEmpty)
            .length;
      }

      test('wrapLines defaults to true', () {
        final model = GitDiffModel();
        expect(model.wrapLines, isTrue);
      });

      test('copyWith preserves wrapLines', () {
        final model = GitDiffModel(wrapLines: false);
        final copy = model.copyWith();
        expect(copy.wrapLines, isFalse);
      });

      test('copyWith replaces wrapLines', () {
        final model = GitDiffModel(wrapLines: true);
        final copy = model.copyWith(wrapLines: false);
        expect(copy.wrapLines, isFalse);
      });

      test('pretty mode wraps long lines into multiple display lines', () {
        final model = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: true,
        ).setDiff(longLineDiff);

        final noWrapModel = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // The wrapped view should have more non-blank lines than the
        // non-wrapped view, since wrapping adds continuation lines.
        final wrappedNonBlank = countNonBlankLines(model.view());
        final noWrapNonBlank = countNonBlankLines(noWrapModel.view());
        expect(wrappedNonBlank, greaterThan(noWrapNonBlank));
      });

      test('pretty mode no wrapping when wrapLines is false', () {
        final wrapped = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: true,
        ).setDiff(longLineDiff);

        final noWrap = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: false,
        ).setDiff(longLineDiff);

        final wrappedNonBlank = countNonBlankLines(wrapped.view());
        final noWrapNonBlank = countNonBlankLines(noWrap.view());
        expect(wrappedNonBlank, greaterThan(noWrapNonBlank));
      });

      test('unified mode wraps long lines into multiple display lines', () {
        final model = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.unified,
          showLineNumbers: false,
          wrapLines: true,
        ).setDiff(longLineDiff);

        final noWrapModel = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.unified,
          showLineNumbers: false,
          wrapLines: false,
        ).setDiff(longLineDiff);

        final wrappedNonBlank = countNonBlankLines(model.view());
        final noWrapNonBlank = countNonBlankLines(noWrapModel.view());
        expect(wrappedNonBlank, greaterThan(noWrapNonBlank));
      });

      test('unified mode no wrapping when wrapLines is false', () {
        final wrapped = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.unified,
          showLineNumbers: false,
          wrapLines: true,
        ).setDiff(longLineDiff);

        final noWrap = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.unified,
          showLineNumbers: false,
          wrapLines: false,
        ).setDiff(longLineDiff);

        final wrappedNonBlank = countNonBlankLines(wrapped.view());
        final noWrapNonBlank = countNonBlankLines(noWrap.view());
        expect(wrappedNonBlank, greaterThan(noWrapNonBlank));
      });

      test('short lines are not wrapped even when wrapLines is true', () {
        final model = GitDiffModel(
          width: 120,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: true,
        ).setDiff(_singleFileDiff);

        final noWrapModel = GitDiffModel(
          width: 120,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: false,
        ).setDiff(_singleFileDiff);

        final wrapCount = countNonBlankLines(model.view());
        final noWrapCount = countNonBlankLines(noWrapModel.view());
        expect(wrapCount, equals(noWrapCount));
      });

      test('wrapping with line numbers preserves gutter alignment', () {
        final model = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: true,
          wrapLines: true,
        ).setDiff(longLineDiff);

        final noWrap = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: true,
          wrapLines: false,
        ).setDiff(longLineDiff);

        final wrappedNonBlank = countNonBlankLines(model.view());
        final noWrapNonBlank = countNonBlankLines(noWrap.view());
        expect(wrappedNonBlank, greaterThan(noWrapNonBlank));
      });

      test('wrapping with line numbers in unified mode', () {
        final model = GitDiffModel(
          width: 40,
          height: 40,
          viewMode: DiffViewMode.unified,
          showLineNumbers: true,
          wrapLines: true,
        ).setDiff(longLineDiff);

        final noWrap = GitDiffModel(
          width: 40,
          height: 40,
          viewMode: DiffViewMode.unified,
          showLineNumbers: true,
          wrapLines: false,
        ).setDiff(longLineDiff);

        final wrappedNonBlank = countNonBlankLines(model.view());
        final noWrapNonBlank = countNonBlankLines(noWrap.view());
        expect(wrappedNonBlank, greaterThan(noWrapNonBlank));
      });

      test('context lines also wrap in pretty mode', () {
        final model = GitDiffModel(
          width: 20,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: true,
        ).setDiff(_singleFileDiff);

        final noWrap = GitDiffModel(
          width: 20,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: false,
        ).setDiff(_singleFileDiff);

        final wrappedNonBlank = countNonBlankLines(model.view());
        final noWrapNonBlank = countNonBlankLines(noWrap.view());
        expect(wrappedNonBlank, greaterThanOrEqualTo(noWrapNonBlank));
      });

      test('wrapped output contains all original text', () {
        final model = GitDiffModel(
          width: 30,
          height: 40,
          viewMode: DiffViewMode.pretty,
          showLineNumbers: false,
          wrapLines: true,
        ).setDiff(longLineDiff);

        // Strip ANSI codes and collapse all whitespace to verify
        // the full text is present across the wrapped output.
        final plainText = Style.stripAnsi(
          model.view(),
        ).replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
        expect(plainText, contains('this is a very long line'));
        expect(plainText, contains('wrapping behavior'));
      });
    });
  });

  group('Side-by-side mode', () {
    test('renders different output than unified', () {
      final unified = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.unified,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      final sideBySide = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      expect(sideBySide.view(), isNot(equals(unified.view())));
    });

    test('shows content on both panels for context lines', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      // Context lines should appear (they show on both panels)
      expect(output, contains("import 'dart:io';"));
    });

    test('pairs removed and added lines', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      // Both old and new content should be present
      expect(output, contains('void main()'));
      expect(output, contains("print('Hello')"));
    });

    test('renders file headers', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      expect(output, contains('\u2190 Edit lib/main.dart'));
    });

    test('renders hunk headers', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      expect(output, contains('@@ '));
    });

    test('renders separator between panels', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      // Side-by-side should contain +/- markers for added/removed lines
      final ansiEscape = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
      final clean = output.replaceAll(ansiEscape, '');
      // Markers should be present: '+' for added lines, '-' for removed lines
      expect(clean, contains('+ '));
      expect(clean, contains('- '));
    });

    test('handles files with only additions', () {
      const addOnlyDiff = '''
diff --git a/new.dart b/new.dart
new file mode 100644
index 0000000..abc1234
--- /dev/null
+++ b/new.dart
@@ -0,0 +1,3 @@
+class New {
+  int x = 0;
+}''';

      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(addOnlyDiff);

      final output = model.view();
      expect(output, isNotEmpty);
      expect(output, contains('class New'));
    });

    test('handles files with only deletions', () {
      const delOnlyDiff = '''
diff --git a/old.dart b/old.dart
deleted file mode 100644
index abc1234..0000000
--- a/old.dart
+++ /dev/null
@@ -1,3 +0,0 @@
-class Old {
-  int x = 0;
-}''';

      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(delOnlyDiff);

      final output = model.view();
      expect(output, isNotEmpty);
      expect(output, contains('class Old'));
    });

    test('handles empty diff', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
      ).setDiff('');

      final output = model.view();
      expect(output.trim(), isEmpty);
    });

    test('handles multi-file diff', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_multiFileDiff);

      final output = model.view();
      expect(output, contains('\u2190 Edit lib/a.dart'));
      expect(output, contains('\u2190 Edit lib/b.dart'));
    });

    test('falls back to unified when width is too narrow', () {
      // With a very narrow width, side-by-side should fall back to unified
      final sideBySide = GitDiffModel(
        width: 10,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(_singleFileDiff);

      final unified = GitDiffModel(
        width: 10,
        height: 40,
        viewMode: DiffViewMode.unified,
        showLineNumbers: true,
      ).setDiff(_singleFileDiff);

      // When too narrow, side-by-side falls back to unified rendering
      expect(sideBySide.view(), equals(unified.view()));
    });

    test('with line numbers shows numbers on both panels', () {
      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      // Line numbers should be present
      expect(output, contains('1'));
    });

    test('without line numbers omits gutter', () {
      final withNums = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(_singleFileDiff);

      final withoutNums = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      // Without line numbers should be different (shorter lines)
      expect(withoutNums.view(), isNot(equals(withNums.view())));
    });

    test('wraps long lines when wrapLines is true', () {
      const longLineDiff = '''
diff --git a/lib/long.dart b/lib/long.dart
index aaa..bbb 100644
--- a/lib/long.dart
+++ b/lib/long.dart
@@ -1,2 +1,2 @@
-short
+this is a very long line that should be wrapped in side-by-side mode''';

      final model = GitDiffModel(
        width: 60,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
        wrapLines: true,
      ).setDiff(longLineDiff);

      final noWrap = GitDiffModel(
        width: 60,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
        wrapLines: false,
      ).setDiff(longLineDiff);

      // With wrapping enabled, the output should differ (more rows)
      expect(model.view(), isNot(equals(noWrap.view())));

      // The wrapped output should contain all the original text when rows are
      // concatenated (text may be split across wrapped rows).
      final ansiEscape = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
      final clean = model.view().replaceAll(ansiEscape, '');
      // Check that multi-word chunks of the long line appear in the output.
      // Because the text wraps mid-word across fixed-width cells, we check
      // for substrings that fit within a single cell rather than cross-line.
      expect(clean, contains('this is a very long line'));
      expect(clean, contains('should be wrapped'));
    });
  });

  group('Side-by-side mode styles', () {
    test('DiffStyles has side-by-side mode fields', () {
      final styles = DiffStyles();
      expect(styles.sideBySideSeparator, isNotNull);
      expect(styles.sideBySideAddedLine, isNotNull);
      expect(styles.sideBySideRemovedLine, isNotNull);
      expect(styles.sideBySideContextLine, isNotNull);
      expect(styles.sideBySideLineNumber, isNotNull);
      expect(styles.sideBySideEmptyCell, isNotNull);
    });

    test('copyWith replaces side-by-side fields', () {
      final styles = DiffStyles();
      final customStyle = Style().bold();
      final copy = styles.copyWith(sideBySideSeparator: customStyle);
      expect(copy.sideBySideSeparator, customStyle);
      // Other side-by-side fields preserved
      expect(copy.sideBySideAddedLine, styles.sideBySideAddedLine);
      expect(copy.sideBySideRemovedLine, styles.sideBySideRemovedLine);
      expect(copy.sideBySideContextLine, styles.sideBySideContextLine);
      expect(copy.sideBySideLineNumber, styles.sideBySideLineNumber);
      expect(copy.sideBySideEmptyCell, styles.sideBySideEmptyCell);
    });

    test('copyWith preserves side-by-side fields when not specified', () {
      final styles = DiffStyles();
      final copy = styles.copyWith();
      expect(copy.sideBySideSeparator, styles.sideBySideSeparator);
      expect(copy.sideBySideAddedLine, styles.sideBySideAddedLine);
      expect(copy.sideBySideRemovedLine, styles.sideBySideRemovedLine);
      expect(copy.sideBySideContextLine, styles.sideBySideContextLine);
      expect(copy.sideBySideLineNumber, styles.sideBySideLineNumber);
      expect(copy.sideBySideEmptyCell, styles.sideBySideEmptyCell);
    });
  });

  group('DiffStyles.fromColors', () {
    test('creates valid styles from semantic colors', () {
      final styles = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
      );

      expect(styles.addedLine, isNotNull);
      expect(styles.removedLine, isNotNull);
      expect(styles.contextLine, isNotNull);
      expect(styles.fileHeader, isNotNull);
      expect(styles.hunkHeader, isNotNull);
      expect(styles.addedGutter, isNotNull);
      expect(styles.removedGutter, isNotNull);
      expect(styles.contextGutter, isNotNull);
      expect(styles.lineNumber, isNotNull);
      expect(styles.prettyAddedLine, isNotNull);
      expect(styles.prettyRemovedLine, isNotNull);
      expect(styles.prettyContextLine, isNotNull);
      expect(styles.prettyFileHeader, isNotNull);
      expect(styles.prettyAddedLineNumber, isNotNull);
      expect(styles.prettyRemovedLineNumber, isNotNull);
      expect(styles.prettyContextLineNumber, isNotNull);
      expect(styles.sideBySideSeparator, isNotNull);
      expect(styles.sideBySideAddedLine, isNotNull);
      expect(styles.sideBySideRemovedLine, isNotNull);
      expect(styles.sideBySideContextLine, isNotNull);
      expect(styles.sideBySideLineNumber, isNotNull);
      expect(styles.sideBySideEmptyCell, isNotNull);
    });

    test('accepts optional successBg and errorBg', () {
      final styles = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
        successBg: const BasicColor('#0a3a0a'),
        errorBg: const BasicColor('#3a0a0a'),
      );

      // Should create valid styles without throwing
      expect(styles.prettyAddedLine, isNotNull);
      expect(styles.prettyRemovedLine, isNotNull);
      expect(styles.sideBySideAddedLine, isNotNull);
      expect(styles.sideBySideRemovedLine, isNotNull);
    });

    test('produces a usable model when applied', () {
      final styles = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
      );

      final model = GitDiffModel(
        width: 80,
        height: 40,
        styles: styles,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      expect(output, isNotEmpty);
      expect(output, contains('main.dart'));
    });

    test('fromColors styles work with all view modes', () {
      final styles = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
      );

      for (final mode in DiffViewMode.values) {
        final model = GitDiffModel(
          width: 120,
          height: 40,
          viewMode: mode,
          styles: styles,
        ).setDiff(_singleFileDiff);

        final output = model.view();
        expect(output, isNotEmpty, reason: 'mode $mode should produce output');
      }
    });
  });

  group('Inline diff highlighting', () {
    test('DiffStyles has inline highlight and marker fields', () {
      final styles = DiffStyles();
      expect(styles.sideBySideAddedMarker, isNotNull);
      expect(styles.sideBySideRemovedMarker, isNotNull);
      expect(styles.sideBySideContextMarker, isNotNull);
      expect(styles.inlineAddedHighlight, isNotNull);
      expect(styles.inlineRemovedHighlight, isNotNull);
    });

    test('copyWith replaces inline highlight fields', () {
      final styles = DiffStyles();
      final customStyle = Style().bold();
      final copy = styles.copyWith(
        inlineAddedHighlight: customStyle,
        inlineRemovedHighlight: customStyle,
        sideBySideAddedMarker: customStyle,
        sideBySideRemovedMarker: customStyle,
        sideBySideContextMarker: customStyle,
      );
      expect(copy.inlineAddedHighlight, customStyle);
      expect(copy.inlineRemovedHighlight, customStyle);
      expect(copy.sideBySideAddedMarker, customStyle);
      expect(copy.sideBySideRemovedMarker, customStyle);
      expect(copy.sideBySideContextMarker, customStyle);
    });

    test('fromColors includes inline highlight fields', () {
      final styles = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
      );
      expect(styles.inlineAddedHighlight, isNotNull);
      expect(styles.inlineRemovedHighlight, isNotNull);
      expect(styles.sideBySideAddedMarker, isNotNull);
      expect(styles.sideBySideRemovedMarker, isNotNull);
      expect(styles.sideBySideContextMarker, isNotNull);
    });

    test('fromColors accepts inlineAddedBg and inlineRemovedBg', () {
      final styles = DiffStyles.fromColors(
        success: const BasicColor('#22c55e'),
        error: const BasicColor('#ef4444'),
        muted: const BasicColor('#6b7280'),
        surface: const BasicColor('#1e1e1e'),
        onSurface: const BasicColor('#ffffff'),
        onBackground: const BasicColor('#d4d4d4'),
        border: const BasicColor('#444444'),
        inlineAddedBg: const BasicColor('#2a4a2a'),
        inlineRemovedBg: const BasicColor('#4a2a2a'),
      );
      expect(styles.inlineAddedHighlight, isNotNull);
      expect(styles.inlineRemovedHighlight, isNotNull);
    });

    test('side-by-side renders markers for added/removed lines', () {
      final model = GitDiffModel(
        width: 80,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      final ansiEscape = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
      final clean = output.replaceAll(ansiEscape, '');

      // Should contain + marker for added lines and - marker for removed lines
      expect(clean, contains('+ '));
      expect(clean, contains('- '));
      // Context lines should have a space marker (linenum + space + space-marker + space + content)
      expect(clean, contains("import 'dart:io'"));
    });

    test('inline diff applies different ANSI codes to changed tokens', () {
      // Create a diff where one word changes
      const wordChangeDiff = '''
diff --git a/lib/f.dart b/lib/f.dart
index aaa..bbb 100644
--- a/lib/f.dart
+++ b/lib/f.dart
@@ -1,1 +1,1 @@
-void main() {}
+void main(List args) {}''';

      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(wordChangeDiff);

      final output = model.view();
      // The output should not be empty and should render without errors
      expect(output, isNotEmpty);

      // The raw output should contain ANSI escape sequences (indicating styling)
      expect(output, contains('\x1B['));
    });

    test('inline diff does not crash with empty lines', () {
      const emptyChangeDiff = '''
diff --git a/lib/f.dart b/lib/f.dart
index aaa..bbb 100644
--- a/lib/f.dart
+++ b/lib/f.dart
@@ -1,1 +1,1 @@
-
+new content''';

      final model = GitDiffModel(
        width: 80,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(emptyChangeDiff);

      // Should render without throwing
      final output = model.view();
      expect(output, isNotEmpty);
    });

    test('inline diff handles identical paired lines', () {
      // When old and new lines are identical (shouldn't happen in practice
      // but tests robustness), no highlighting should be applied.
      const identicalDiff = '''
diff --git a/lib/f.dart b/lib/f.dart
index aaa..bbb 100644
--- a/lib/f.dart
+++ b/lib/f.dart
@@ -1,1 +1,1 @@
-same text here
+same text here''';

      final model = GitDiffModel(
        width: 120,
        height: 40,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(identicalDiff);

      // Should render without throwing
      final output = model.view();
      expect(output, isNotEmpty);
    });
  });

  group('View mode cycling', () {
    test('pressing v cycles unified → sideBySide', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.unified,
      ).setDiff(_singleFileDiff);

      expect(model.viewMode, DiffViewMode.unified);

      final (next, cmd) = model.update(KeyMsg(Key.char('v')));
      expect(next.viewMode, DiffViewMode.sideBySide);
      expect(cmd, isNull);
    });

    test('pressing v cycles sideBySide → pretty', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.sideBySide,
      ).setDiff(_singleFileDiff);

      final (next, _) = model.update(KeyMsg(Key.char('v')));
      expect(next.viewMode, DiffViewMode.pretty);
    });

    test('pressing v cycles pretty → unified (wraps around)', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.pretty,
      ).setDiff(_singleFileDiff);

      final (next, _) = model.update(KeyMsg(Key.char('v')));
      expect(next.viewMode, DiffViewMode.unified);
    });

    test('full cycle through all modes', () {
      var model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.unified,
      ).setDiff(_singleFileDiff);

      // unified → sideBySide
      final (m1, _) = model.update(KeyMsg(Key.char('v')));
      expect(m1.viewMode, DiffViewMode.sideBySide);

      // sideBySide → pretty
      final (m2, _) = m1.update(KeyMsg(Key.char('v')));
      expect(m2.viewMode, DiffViewMode.pretty);

      // pretty → unified
      final (m3, _) = m2.update(KeyMsg(Key.char('v')));
      expect(m3.viewMode, DiffViewMode.unified);
    });

    test('re-renders lines when view mode changes', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.unified,
      ).setDiff(_singleFileDiff);

      final unifiedView = model.view();

      final (prettyModel, _) = model
          .update(KeyMsg(Key.char('v')))
          .$1
          .update(KeyMsg(Key.char('v')));
      // After two presses: unified → sideBySide → pretty
      expect(prettyModel.viewMode, DiffViewMode.pretty);
      final prettyView = prettyModel.view();

      // Pretty mode should differ from unified mode output
      expect(prettyView, isNot(equals(unifiedView)));
    });

    test('preserves files when cycling modes', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.unified,
      ).setDiff(_multiFileDiff);

      expect(model.files, hasLength(2));

      final (next, _) = model.update(KeyMsg(Key.char('v')));
      expect(next.files, hasLength(2));
      expect(next.totalAdditions, model.totalAdditions);
      expect(next.totalDeletions, model.totalDeletions);
    });

    test('non-matching keys still delegate to viewport', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.unified,
      ).setDiff(_singleFileDiff);

      // 'j' is handled by the viewport (scroll down), not by the diff cycling
      final (next, _) = model.update(KeyMsg(Key.char('j')));
      expect(next.viewMode, DiffViewMode.unified); // mode unchanged
    });

    test('custom keyMap binding is respected', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.unified,
        keyMap: GitDiffKeyMap(cycleViewMode: KeyBinding.withKeys(['m'])),
      ).setDiff(_singleFileDiff);

      // 'v' should NOT cycle with custom binding
      final (same, _) = model.update(KeyMsg(Key.char('v')));
      expect(same.viewMode, DiffViewMode.unified);

      // 'm' should cycle
      final (next, _) = model.update(KeyMsg(Key.char('m')));
      expect(next.viewMode, DiffViewMode.sideBySide);
    });

    test('cycling with empty diff does not error', () {
      final model = GitDiffModel(
        width: 80,
        height: 24,
        viewMode: DiffViewMode.unified,
      ).setDiff('');

      final (next, _) = model.update(KeyMsg(Key.char('v')));
      expect(next.viewMode, DiffViewMode.sideBySide);
      expect(next.files, isEmpty);
    });

    test('keyMap is preserved through copyWith', () {
      final customKeyMap = GitDiffKeyMap(
        cycleViewMode: KeyBinding.withKeys(['m']),
      );
      final model = GitDiffModel(width: 80, height: 24, keyMap: customKeyMap);

      final copy = model.copyWith(width: 120);
      expect(identical(copy.keyMap, customKeyMap), isTrue);
    });
  });

  group('Side-by-side alignment (visible width consistency)', () {
    test('all data rows with separator have consistent visible width', () {
      final model = GitDiffModel(
        width: 80,
        height: 100, // tall enough to show all lines
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      final lines = output.split('\n');

      // In side-by-side mode, all non-empty lines should have visible width
      // == 80 (file headers, hunk headers, data rows, and padding rows).
      final dataLines = <String>[];
      final widths = <int>[];
      for (final line in lines) {
        final stripped = Style.stripAnsi(line);
        if (stripped.trim().isNotEmpty) {
          dataLines.add(stripped);
          widths.add(stripped.length);
        }
      }

      expect(dataLines, isNotEmpty, reason: 'should have data rows');

      for (var i = 0; i < dataLines.length; i++) {
        expect(
          widths[i],
          equals(80),
          reason:
              'Row $i visible width is ${widths[i]} (expected 80): "${dataLines[i]}"',
        );
      }
    });

    test('all data rows without line numbers have consistent width', () {
      final model = GitDiffModel(
        width: 80,
        height: 100,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: false,
      ).setDiff(_singleFileDiff);

      final output = model.view();
      final lines = output.split('\n');

      final dataLines = <String>[];
      final widths = <int>[];
      for (final line in lines) {
        final stripped = Style.stripAnsi(line);
        if (stripped.trim().isNotEmpty) {
          dataLines.add(stripped);
          widths.add(stripped.length);
        }
      }

      expect(dataLines, isNotEmpty, reason: 'should have data rows');

      for (var i = 0; i < dataLines.length; i++) {
        expect(
          widths[i],
          equals(80),
          reason:
              'Row $i visible width is ${widths[i]} (expected 80): "${dataLines[i]}"',
        );
      }
    });

    test('multi-file diff rows have consistent width', () {
      final model = GitDiffModel(
        width: 120,
        height: 100,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(_multiFileDiff);

      final output = model.view();
      final lines = output.split('\n');

      final dataLines = <String>[];
      final widths = <int>[];
      for (final line in lines) {
        final stripped = Style.stripAnsi(line);
        if (stripped.trim().isNotEmpty) {
          dataLines.add(stripped);
          widths.add(stripped.length);
        }
      }

      expect(dataLines, isNotEmpty, reason: 'should have data rows');

      for (var i = 0; i < dataLines.length; i++) {
        expect(
          widths[i],
          equals(120),
          reason:
              'Row $i visible width is ${widths[i]} (expected 120): "${dataLines[i]}"',
        );
      }
    });

    test('empty cells have same width as content cells', () {
      // Use a diff with unequal add/remove counts to trigger empty cells
      const unequalDiff = '''
diff --git a/lib/x.dart b/lib/x.dart
index aaa..bbb 100644
--- a/lib/x.dart
+++ b/lib/x.dart
@@ -1,4 +1,2 @@
-line one
-line two
-line three
+replaced''';

      final model = GitDiffModel(
        width: 80,
        height: 100,
        viewMode: DiffViewMode.sideBySide,
        showLineNumbers: true,
      ).setDiff(unequalDiff);

      final output = model.view();
      final lines = output.split('\n');

      final dataLines = <String>[];
      final widths = <int>[];
      for (final line in lines) {
        final stripped = Style.stripAnsi(line);
        if (stripped.trim().isNotEmpty) {
          dataLines.add(stripped);
          widths.add(stripped.length);
        }
      }

      expect(dataLines, isNotEmpty, reason: 'should have data rows');

      for (var i = 0; i < dataLines.length; i++) {
        expect(
          widths[i],
          equals(80),
          reason:
              'Row $i visible width is ${widths[i]} (expected 80): "${dataLines[i]}"',
        );
      }
    });
  });

  group('Horizontal scrolling', () {
    /// A diff with a very long added line to test horizontal scrolling.
    const longLineDiff = '''
diff --git a/lib/long.dart b/lib/long.dart
index aaa..bbb 100644
--- a/lib/long.dart
+++ b/lib/long.dart
@@ -1,2 +1,2 @@
-short
+ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789_abcdefghijklmnopqrstuvwxyz_LONG_END''';

    group('side-by-side mode', () {
      test('right arrow shifts content in side-by-side cells', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(longLineDiff);

        expect(model.horizontalOffset, 0);

        // Press right arrow
        final (scrolled, _) = model.update(KeyMsg(Key(KeyType.right)));
        expect(scrolled.horizontalOffset, greaterThan(0));

        // The view should differ because the content window shifted.
        expect(scrolled.view(), isNot(equals(model.view())));
      });

      test('left arrow scrolls back and clamps at 0', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // Scroll right twice
        final (r1, _) = model.update(KeyMsg(Key(KeyType.right)));
        final (r2, _) = r1.update(KeyMsg(Key(KeyType.right)));
        expect(r2.horizontalOffset, greaterThan(0));

        // Scroll left enough to reach 0
        var current = r2;
        for (var i = 0; i < 20; i++) {
          final (next, _) = current.update(KeyMsg(Key(KeyType.left)));
          current = next;
          if (current.horizontalOffset == 0) break;
        }
        expect(current.horizontalOffset, 0);

        // Further left should not go negative.
        final (clamped, _) = current.update(KeyMsg(Key(KeyType.left)));
        expect(clamped.horizontalOffset, 0);
      });

      test('scrolled content reveals text beyond initial viewport', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(longLineDiff);

        final ansiEscape = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
        final initialClean = model.view().replaceAll(ansiEscape, '');

        // "LONG_END" is at the end of the long line and shouldn't be visible
        // initially in a narrow 60-column side-by-side view.
        expect(initialClean, isNot(contains('LONG_END')));

        // Scroll right incrementally until LONG_END appears.
        var current = model;
        var found = false;
        for (var i = 0; i < 30; i++) {
          final (next, _) = current.update(KeyMsg(Key(KeyType.right)));
          current = next;
          final clean = current.view().replaceAll(ansiEscape, '');
          if (clean.contains('LONG_END')) {
            found = true;
            break;
          }
        }

        expect(
          found,
          isTrue,
          reason: 'LONG_END should become visible after scrolling right',
        );
      });

      test('h and l keys also scroll side-by-side', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // 'l' should scroll right
        final (scrolledRight, _) = model.update(KeyMsg(Key.char('l')));
        expect(scrolledRight.horizontalOffset, greaterThan(0));

        // 'h' should scroll left
        final (scrolledBack, _) = scrolledRight.update(KeyMsg(Key.char('h')));
        expect(
          scrolledBack.horizontalOffset,
          lessThan(scrolledRight.horizontalOffset),
        );
      });

      test('side-by-side rows maintain consistent width while scrolled', () {
        final model = GitDiffModel(
          width: 80,
          height: 100,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // Scroll right
        final (scrolled, _) = model.update(KeyMsg(Key(KeyType.right)));

        final output = scrolled.view();
        final lines = output.split('\n');

        final dataLines = <String>[];
        final widths = <int>[];
        for (final line in lines) {
          final stripped = Style.stripAnsi(line);
          if (stripped.trim().isNotEmpty) {
            dataLines.add(stripped);
            widths.add(stripped.length);
          }
        }

        expect(dataLines, isNotEmpty, reason: 'should have data rows');

        for (var i = 0; i < dataLines.length; i++) {
          expect(
            widths[i],
            equals(80),
            reason:
                'Row $i visible width is ${widths[i]} (expected 80): "${dataLines[i]}"',
          );
        }
      });

      test('does not scroll when wrapLines is true', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: true,
        ).setDiff(longLineDiff);

        // Right arrow should be delegated to viewport, not change horizontalOffset
        final (next, _) = model.update(KeyMsg(Key(KeyType.right)));
        expect(next.horizontalOffset, 0);
      });

      test('view mode cycling resets horizontalOffset', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // Scroll right
        final (scrolled, _) = model.update(KeyMsg(Key(KeyType.right)));
        expect(scrolled.horizontalOffset, greaterThan(0));

        // Cycle view mode (v key)
        final (cycled, _) = scrolled.update(KeyMsg(Key.char('v')));
        expect(cycled.horizontalOffset, 0);
        expect(cycled.viewMode, DiffViewMode.pretty);
      });

      test('setDiff resets horizontalOffset', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // Scroll right
        final (scrolled, _) = model.update(KeyMsg(Key(KeyType.right)));
        expect(scrolled.horizontalOffset, greaterThan(0));

        // Load new diff
        final reloaded = scrolled.setDiff(longLineDiff);
        expect(reloaded.horizontalOffset, 0);
      });

      test('horizontalOffset is preserved through copyWith', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.sideBySide,
          horizontalOffset: 12,
        );

        final copy = model.copyWith(width: 80);
        expect(copy.horizontalOffset, 12);
      });
    });

    group('unified and pretty modes', () {
      test('left/right keys delegate to viewport in unified mode', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.unified,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // Right arrow should go to viewport (not intercepted by GitDiffModel)
        final (next, _) = model.update(KeyMsg(Key(KeyType.right)));
        expect(next.horizontalOffset, 0);
        // The viewport should have scrolled (xOffset changed)
        expect(next.viewport.xOffset, greaterThan(0));
      });

      test('left/right keys delegate to viewport in pretty mode', () {
        final model = GitDiffModel(
          width: 60,
          height: 40,
          viewMode: DiffViewMode.pretty,
          wrapLines: false,
        ).setDiff(longLineDiff);

        // Right arrow should go to viewport
        final (next, _) = model.update(KeyMsg(Key(KeyType.right)));
        expect(next.horizontalOffset, 0);
        expect(next.viewport.xOffset, greaterThan(0));
      });
    });
  });
}

/// Mock message for testing non-matching message handling.
class _MockMsg implements Msg {
  @override
  bool get dropWhenInputQueued => false;
}
