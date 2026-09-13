import 'dart:io';
import 'dart:isolate';

import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:github_cli/src/ui/markdown/body.dart';
import 'package:test/test.dart';

Future<String> _fixture() async {
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:artisanal_capture/artisanal_capture.dart'),
  );
  return File.fromUri(
    library!.resolve('../example/scenarios/artisanal_pr49.md'),
  ).readAsString();
}

void main() {
  for (final width in [80, 112]) {
    test(
      'GithubMarkdownBody keeps PR 49 list/code order at $width columns',
      () async {
        final tester = WidgetTester(
          screenWidth: width,
          screenHeight: 80,
          enableRenderer: true,
        );
        addTearDown(tester.dispose);
        await tester.pumpWidget(
          w.ThemeScope(
            theme: w.Theme.dark(),
            child: GithubMarkdownBody(data: await _fixture(), maxWidth: width),
          ),
          width: width,
          height: 80,
        );

        final lines = Style.stripAnsi(tester.view).split('\n');
        final prose = lines.indexWhere(
          (line) => line.contains('901 tests passed'),
        );
        final command = lines.indexWhere((line) => line.contains('dart test'));
        final nextItem = lines.indexWhere(
          (line) => line.contains('Targeted dart analyze'),
        );
        expect(prose, greaterThanOrEqualTo(0));
        expect(command, greaterThan(prose));
        expect(nextItem, greaterThan(command));
        expect(
          lines
              .sublist(command, nextItem)
              .any((line) => RegExp(r'[╰└]').hasMatch(line)),
          isTrue,
        );
        // Keep this as an app-level capture assertion, rather than only testing
        // the Markdown renderer's intermediate ANSI string.
        expect(
          TerminalCapture.fromAnsi(
            tester.view,
            columns: width,
            rows: 80,
          ).columns,
          width,
        );
      },
    );
  }
}
