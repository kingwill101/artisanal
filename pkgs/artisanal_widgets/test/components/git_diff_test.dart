import 'package:artisanal/testing.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/widgets.dart';
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

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.light(),
          child: GitDiffViewer(diff: _sampleDiff, width: 80, height: 40),
        ),
      );

      expect(tester.find.text('main.dart'), isTrue);
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
  });
}
