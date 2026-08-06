import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  test('DiffReviewPane lists files and shows selected patch', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 28);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: DiffReviewPane(
          files: const [
            DiffReviewFile(
              path: 'a.dart',
              additions: 2,
              deletions: 1,
              diff: 'diff --git a/a.dart b/a.dart\n'
                  '--- a/a.dart\n'
                  '+++ b/a.dart\n'
                  '@@ -1 +1,2 @@\n'
                  '-old\n'
                  '+new\n'
                  '+line\n',
            ),
            DiffReviewFile(
              path: 'b.md',
              additions: 1,
              deletions: 0,
              diff: 'diff --git a/b.md b/b.md\n'
                  '--- a/b.md\n'
                  '+++ b/b.md\n'
                  '@@ -0,0 +1 @@\n'
                  '+hello\n',
            ),
          ],
        ),
      ),
    );
    tester.pump();

    expect(tester.find.text('a.dart'), isTrue, reason: tester.view);
    expect(tester.find.text('b.md'), isTrue, reason: tester.view);
    expect(tester.find.text('review'), isTrue, reason: tester.view);
    expect(tester.view.contains('2 files'), isTrue, reason: tester.view);
  });
}
