import 'package:artisanal/artisanal.dart'
    show Layout, Style, renderSequenceDiagram;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/ui/markdown/body.dart';
import 'package:test/test.dart';

// Exact Mermaid block from:
// https://github.com/kingwill101/devtools-profiler/pull/10#issuecomment-5610973298
const _sequence = '''
sequenceDiagram
  participant Agent
  participant Marionette
  participant SearchScenario
  participant WorkerIsolate
  participant DevToolsProfiler
  Agent->>Marionette: call profiler_demo_search
  Marionette->>SearchScenario: pass seed and workload limits
  SearchScenario->>DevToolsProfiler: start marionette-search region
  SearchScenario->>WorkerIsolate: execute seeded search
  WorkerIsolate-->>SearchScenario: return checksum
  SearchScenario->>DevToolsProfiler: stop profiling region
  SearchScenario-->>Marionette: return completion result
''';

void main() {
  for (final source in [
    'flowchart TD\nA-->B',
    'sequenceDiagram\nparticipant A\nunsupported directive',
  ]) {
    test(
      'unsupported Mermaid stays readable: ${source.split('\n').first}',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 30);
        addTearDown(tester.dispose);
        await tester.pumpWidget(
          GithubMarkdownBody(
            data: '```mermaid\n$source\n```\n\nAfter diagram',
            maxWidth: 100,
          ),
        );
        final text = Style.stripAnsi(tester.view);
        expect(text, contains(source.split('\n').last));
        expect(text, contains('After diagram'));
        expect(text, isNot(contains('Unhandled exception')));
        if (source.startsWith('sequenceDiagram')) {
          expect(text, contains('Sequence diagram could not be rendered'));
        }
      },
    );
  }

  for (final width in [80, 120, 180]) {
    test(
      'Markdown preserves complete sequence output at $width columns',
      () async {
        final direct = Style.stripAnsi(
          renderSequenceDiagram(_sequence, maxWidth: width),
        ).trimRight();
        final expectedLines = direct.split('\n');
        final tester = WidgetTester(
          screenWidth: width,
          screenHeight: expectedLines.length + 8,
        );
        addTearDown(tester.dispose);
        await tester.pumpWidget(
          w.ThemeScope(
            theme: w.Theme.dark(),
            child: GithubMarkdownBody(
              data:
                  'Before diagram\n\n```mermaid\n$_sequence```\n\nAfter diagram',
              maxWidth: width,
            ),
          ),
        );
        final lines = Style.stripAnsi(tester.view).split('\n');
        final start = lines.indexWhere(
          (line) => line.trimRight() == expectedLines.first.trimRight(),
        );
        expect(start, greaterThanOrEqualTo(0), reason: tester.view);
        expect(
          lines
              .skip(start)
              .take(expectedLines.length)
              .map((line) => line.trimRight()),
          expectedLines.map((line) => line.trimRight()),
          reason:
              'The Markdown adapter must not lose messages or diagram rows.',
        );
        expect(
          lines.indexWhere((line) => line.contains('After diagram')),
          greaterThanOrEqualTo(start + expectedLines.length),
        );
        expect(Layout.getWidth(tester.view), lessThanOrEqualTo(width));
      },
    );
  }
}
