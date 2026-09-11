import 'package:artisanal/runtime.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/models/display_item.dart';
import 'package:github_cli/src/ui/dialogs/diff_dialog.dart';
import 'package:test/test.dart';

const item = GithubDisplayItem(
  target: GithubDisplayTarget.pullRequest,
  kind: 'pr',
  number: 42,
  title: 'Dialog review',
  body: '',
  url: '',
  repository: 'owner/repo',
  author: '',
  status: '',
  updatedAt: null,
  footer: '',
  headRefOid: 'head',
);

void main() {
  test(
    'dialog reuses review layout while scrolling and keeps layout shortcuts',
    () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 40);
      addTearDown(tester.dispose);
      var closed = false;
      await tester.pumpWidget(
        GithubDiffDialog(
          item: item,
          diff:
              '''
diff --git a/file.dart b/file.dart
--- a/file.dart
+++ b/file.dart
@@ -0,0 +1,100 @@
${List.generate(100, (i) => '+DIALOG_LINE_$i').join('\n')}
''',
          loading: false,
          error: null,
          onClose: () {
            closed = true;
            return tui.Cmd.none();
          },
        ),
      );
      final viewport =
          tester.find.byType<w.DiffReviewViewport>().single.widget
              as w.DiffReviewViewport;
      final controller = viewport.controller;
      final layout = controller.model.diff.layout;
      expect(tester.view, contains('DIALOG_LINE_0'));
      tester.sendKey('j');
      tester.pump();
      expect(controller.scrollController.offset, 1);
      expect(controller.model.diff.layout, same(layout));
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.pageDown)));
      tester.pump();
      expect(controller.scrollController.offset, greaterThan(1));
      expect(tester.view, isNot(contains('DIALOG_LINE_0')));
      tester.sendKey('v');
      tester.pump();
      expect(controller.model.diff.viewMode, w.DiffViewMode.sideBySide);
      tester.sendKey('s');
      tester.pump();
      expect(controller.model.diff.viewMode, w.DiffViewMode.pretty);
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.escape)));
      tester.pump();
      expect(closed, isTrue);
    },
  );
}
