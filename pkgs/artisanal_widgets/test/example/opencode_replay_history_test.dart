import 'package:artisanal/runtime.dart' as tui;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart' as w;
import 'package:test/test.dart';

import '../../example/opencode/main.dart' as example;
import '../../example/opencode/models/chat_model.dart';
import '../../example/opencode/screens/session.dart';
import '../../example/opencode/theme.dart';

void main() {
  test('OpenCode session content renders replay history controls', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 48);
    addTearDown(() => tester.dispose());

    final model = ChatModel(
      route: AppRoute.session,
      sessionTitle: 'Replay Session',
      workingDirectory: '~/code/artisanal',
      agentName: 'build',
      modelName: 'gpt-5.3-codex',
      providerName: 'OpenAI',
      mcpServers: const [McpServer('filesystem')],
      lspServers: const [LspServer('dart')],
    );

    await tester.pumpWidget(
      w.ThemeScope(
        theme: openCodeTheme(),
        child: SessionContentPane(
          model: model,
          scrollController: w.WidgetScrollController(),
          promptController: w.TextFieldController(),
          statusHint: '/status',
          replayHistory: const w.ReplayEventHistoryState(
            mode: w.ReplayEventHistoryMode.grouped,
          ),
          replayEvents: const [
            tui.ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            tui.ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            tui.ReplayEventPresentation(
              summary: 'render capture g3 120x40 cells 2 spans 1',
              statusHint: '/replay g3 120x40 c2 s1',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            tui.ReplayEventPresentation(
              summary: 'render capture g4 120x40 cells 1 spans 1',
              statusHint: '/replay g4 120x40 c1 s1',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            tui.ReplayEventPresentation(
              summary: 'render capture g5 120x40 cells 3 spans 2',
              statusHint: '/replay g5 120x40 c3 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('Replay History'));
    expect(tester.view, contains('flat'));
    expect(tester.view, contains('grouped'));
    expect(tester.view, contains('mode: grouped'));
    expect(tester.view, contains('render 4'));
    expect(tester.view, isNot(contains('render 5')));
    expect(tester.view, contains('show'));
    expect(tester.view, contains('all'));
    expect(tester.view, contains('4'));
    expect(tester.view, contains('groups'));
    expect(tester.view, contains('2 groups hidden'));
  });
}
