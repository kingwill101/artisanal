import 'package:artisanal/runtime.dart';
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  test(
    'ReplayEventPanel renders summary, status hint, and detail lines',
    () async {
      final tester = WidgetTester(screenWidth: 70, screenHeight: 16);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ReplayEventPanel(
            title: 'Replay Summary',
            presentation: const ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
              detailLines: <String>[
                'Capture event: runtime.render_capture',
                'Capture last: generation 2 (100x32)',
              ],
            ),
          ),
        ),
      );

      expect(tester.view, contains('Replay Summary'));
      expect(tester.view, contains('render capture g2 100x32 cells 4 spans 2'));
      expect(tester.view, contains('/replay g2 100x32 c4 s2'));
      expect(tester.view, contains('Capture event: runtime.render_capture'));
      expect(tester.view, contains('Capture last: generation 2 (100x32)'));
    },
  );
}
