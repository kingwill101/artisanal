import 'dart:io';
import 'dart:isolate';

import 'package:artisanal/artisanal.dart'
    show GithubMarkdownDetailsSegment, Style, githubDisplayMarkdownSegments;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/ui/markdown/body.dart';
import 'package:test/test.dart';

void main() {
  late String source;
  setUpAll(() async {
    final library = await Isolate.resolvePackageUri(
      Uri.parse('package:artisanal_capture/artisanal_capture.dart'),
    );
    source = await File.fromUri(
      library!.resolve('../example/scenarios/dart_sdk_64170.md'),
    ).readAsString();
  });

  test('SDK issue comment is not turned into an interactive disclosure', () {
    expect(source, contains('Supporting CLs'));
    expect(source, contains('<!--'));
    expect(
      githubDisplayMarkdownSegments(
        source,
      ).whereType<GithubMarkdownDetailsSegment>(),
      isEmpty,
    );
  });

  for (final width in [80, 112]) {
    test(
      'issue table survives F12 and remains scrollable at $width columns',
      () async {
        const height = 40;
        final tester = WidgetTester(
          screenWidth: width,
          screenHeight: height,
          enableRenderer: true,
          altScreen: true,
        );
        addTearDown(tester.dispose);
        final scroll = w.WidgetScrollController();
        await tester.pumpWidget(
          w.ThemeScope(
            theme: w.Theme.dark(),
            child: w.SingleChildScrollView(
              controller: scroll,
              child: GithubMarkdownBody(data: source, maxWidth: width),
            ),
          ),
          width: width,
          height: height,
          debugOverlayPosition: w.DebugOverlayPosition.bottomRight,
        );
        expect(Style.stripAnsi(tester.view), contains('Operation'));
        expect(scroll.maxOffset, greaterThan(0));

        // Exercise the actual Program F12 path, not only a static overlay helper.
        for (final offset in [0, 8, 24]) {
          scroll.jumpTo(offset);
          tester.pump();
          final baseline = tester.view;
          tester.clearRendererOutput();
          tester.sendSpecialKey(tui.KeyType.f12);
          tester.pump();
          final visibleOutput = Style.stripAnsi(tester.rendererOutput);
          expect(visibleOutput, contains('FPS'));
          expect(visibleOutput, isNot(contains(']8;;')));
          expect(
            visibleOutput,
            isNot(contains('dart-review.googlesource.com')),
          );
          expect(
            tester.view,
            baseline,
            reason: 'The overlay must not alter table layout or widget state.',
          );
          final capture = TerminalCapture.fromAnsi(
            tester.view,
            columns: width,
            rows: height,
          );
          expect(capture.columns, width);
          tester.clearRendererOutput();
          tester.sendSpecialKey(tui.KeyType.f12);
          tester.pump();
          expect(tester.view, baseline);
          expect(
            Style.stripAnsi(tester.rendererOutput),
            isNot(contains(']8;;')),
          );
        }

        scroll.jumpTo(scroll.maxOffset);
        tester.pump();
        final tail = Style.stripAnsi(tester.view);
        expect(tail, contains('Third-party blockers'));
        expect(tail, contains('Use cases'));
        expect(tail, contains('#63821'));
        expect(tail, isNot(contains('Supporting CLs')));
        expect(tail, isNot(contains('-->')));
      },
    );
  }
}
