import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/ui/markdown/body.dart';
import 'package:test/test.dart';

const _parentUrl =
    'https://app.coderabbit.ai/change-stack/kingwill101/artisanal/pull/49';
const _lightSvg =
    'https://storage.googleapis.com/coderabbit_public_assets/review-stack-in-coderabbit-ui.svg';
const _darkSvg =
    'https://storage.googleapis.com/coderabbit_public_assets/review-stack-in-coderabbit-ui-dark.svg';

const _coderabbitHtml =
    '''
<p>
<a href="$_parentUrl#gh-light-mode-only"><img src="$_lightSvg" alt="Review Change Stack"></a>
<a href="$_parentUrl#gh-dark-mode-only"><img src="$_darkSvg" alt="Review Change Stack"></a>
</p>
''';

void main() {
  for (final variant in [
    (
      name: 'light',
      theme: w.Theme.light(),
      url: '$_parentUrl#gh-light-mode-only',
    ),
    (name: 'dark', theme: w.Theme.dark(), url: '$_parentUrl#gh-dark-mode-only'),
  ]) {
    test(
      'CodeRabbit linked image keeps the ${variant.name} variant only',
      () async {
        w.setHasDarkBackground(variant.name == 'dark');
        addTearDown(() => w.setHasDarkBackground(true));
        final tester = WidgetTester(
          screenWidth: 120,
          screenHeight: 12,
          enableRenderer: true,
          enableNativeFrameCapture: true,
        );
        addTearDown(tester.dispose);

        await tester.pumpWidget(
          w.ThemeScope(
            theme: variant.theme,
            child: GithubMarkdownBody(data: _coderabbitHtml, maxWidth: 120),
          ),
          width: 120,
          height: 12,
        );

        final visible = Style.stripAnsi(tester.view);
        expect(
          RegExp(r'\[Image: Review Change Stack\]').allMatches(visible).length,
          1,
        );
        expect(visible, isNot(contains(_lightSvg)));
        expect(visible, isNot(contains(_darkSvg)));
        expect(visible, isNot(contains('gh-light-mode-only')));
        expect(visible, isNot(contains('gh-dark-mode-only')));

        final frame = tester.latestNativeFrame;
        expect(frame, isNotNull);
        expect(
          TerminalCapture.fromAnsi(tester.view, columns: 120, rows: 12).columns,
          120,
        );
        final links = [
          for (final line in frame!.lines)
            for (final cell in line.cells)
              if (cell.link.url.isNotEmpty) cell.link.url,
        ];
        expect(links.toSet(), {variant.url});
        expect(links, contains(variant.url));
      },
    );
  }
}
