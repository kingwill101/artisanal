/// Responsive smoke coverage for the OpenCode agent overview surface.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

import 'package:opencode/src/opencode/models/chat_model.dart';
import 'package:opencode/src/opencode/screens/agent_overview.dart';
import 'package:opencode/src/opencode/theme.dart';

void main() {
  test('agent overview adapts docks and footer while resizing', () async {
    final tester = w.WidgetTester(screenWidth: 100, screenHeight: 40);
    try {
      final model = ChatModel(
        sessionTitle: 'Agent session',
        workingDirectory: '~/project',
        mcpServers: const [McpServer('filesystem')],
        lspServers: const [LspServer('dart')],
      );

      var firstFrame = true;
      Future<void> pumpAt(
        int width,
        int height, {
        required bool expectPinnedDocks,
      }) async {
        if (!firstFrame) tester.resize(width, height);
        await tester.pumpWidget(
          w.ThemeScope(
            theme: openCodeTheme(),
            child: AgentOverview(model: model),
          ),
        );
        firstFrame = false;
        expect(tester.view, isNot(contains('Widget error')));
        expect(tester.find.text('Agent session'), isTrue, reason: tester.view);
        expect(tester.find.text('~/project'), isTrue, reason: tester.view);
        // Below the pinning breakpoint docks intentionally follow the
        // scrollable stream; only the wide layout reserves space for them.
        expect(
          tester.find.text('questions'),
          expectPinnedDocks ? isTrue : isFalse,
          reason: tester.view,
        );
        expect(
          tester.find.text('permission'),
          expectPinnedDocks ? isTrue : isFalse,
          reason: tester.view,
        );
      }

      await pumpAt(100, 40, expectPinnedDocks: true);
      await pumpAt(52, 24, expectPinnedDocks: false);
      await pumpAt(40, 12, expectPinnedDocks: false);

      // A resize back to a wide viewport must restore the sidebar rather than
      // retaining the narrow layout decision.
      await pumpAt(160, 40, expectPinnedDocks: true);
      expect(tester.find.text('filesystem'), isTrue, reason: tester.view);
    } finally {
      await tester.dispose();
    }
  });
}
