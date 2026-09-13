import 'package:artisanal/style.dart' show Style;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/ui/markdown/body.dart';
import 'package:test/test.dart';

void main() {
  test(
    'NOTE quote keeps one native rail around disclosures and code',
    () async {
      final tester = WidgetTester(screenWidth: 76, screenHeight: 28);
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        w.ThemeScope(
          theme: w.Theme.dark(),
          child: GithubMarkdownBody(
            data: '''
> [!NOTE]
> Review configuration
>
> <details>
> <summary>Run configuration</summary>
> ```text
> ascii: [##########]
> command: dart test
> ```
> </details>
>
> <details>
> <summary>Commits</summary>
> commit abc123
> </details>
>
Outside prose has no quote rail.
''',
            maxWidth: 76,
          ),
        ),
        width: 76,
        height: 28,
      );

      String plain() => Style.stripAnsi(tester.view);
      List<String> lines() => plain().split('\n');
      expect(plain(), isNot(contains('[!NOTE]')));
      expect(plain(), contains('NOTE'));
      expect(plain(), contains('▸ Run configuration'));
      expect(plain(), contains('▸ Commits'));
      expect(plain(), contains('Outside prose has no quote rail.'));
      expect(
        lines()
            .where((line) => line.contains('Outside prose'))
            .single
            .startsWith('│'),
        isFalse,
      );
      final outsideIndex = lines().indexWhere(
        (line) => line.contains('Outside prose'),
      );
      expect(
        lines()
            .take(outsideIndex)
            .where((line) => line.trim().isNotEmpty)
            .every((line) => line.startsWith('│')),
        isTrue,
      );

      tester.tap(tester.find.textLocation('Run configuration'));
      tester.pump();
      final expanded = plain();
      expect(expanded, contains('▾ Run configuration'));
      expect(expanded, contains('ascii: [##########]'));
      expect(expanded, contains('command: dart test'));
      for (final line in lines()) {
        if (line.contains('Run configuration') ||
            line.contains('ascii:') ||
            line.contains('command:') ||
            line.contains('Review configuration')) {
          expect(line.startsWith('│'), isTrue, reason: line);
        }
      }
      expect(
        lines()
            .take(lines().indexWhere((line) => line.contains('Outside prose')))
            .where((line) => line.trim().isNotEmpty)
            .every((line) => line.startsWith('│')),
        isTrue,
      );

      tester.tap(tester.find.textLocation('Commits'));
      tester.pump();
      expect(plain(), contains('▾ Commits'));
      expect(plain(), contains('commit abc123'));
      expect(
        lines()
            .where((line) => line.contains('Outside prose'))
            .single
            .startsWith('│'),
        isFalse,
      );
    },
  );
}
