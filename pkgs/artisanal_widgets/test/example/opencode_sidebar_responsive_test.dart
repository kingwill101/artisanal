/// OpenCode-style responsive sidebar visibility.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/models/chat_model.dart';
import '../../example/opencode/screens/session.dart';
import '../../example/opencode/theme.dart';

void main() {
  group('ChatModel sidebar visibility (OpenCode parity)', () {
    test('auto mode shows only when width > 120', () {
      final model = ChatModel(
        sidebarMode: SidebarVisibilityMode.auto,
        sidebarOpen: false,
      );
      expect(model.isSidebarVisible(80), isFalse);
      expect(model.isSidebarVisible(120), isFalse);
      expect(model.isSidebarVisible(121), isTrue);
      expect(model.isSidebarVisible(160), isTrue);
    });

    test('force open shows on narrow widths', () {
      final model = ChatModel(
        sidebarMode: SidebarVisibilityMode.auto,
        sidebarOpen: true,
      );
      expect(model.isSidebarVisible(40), isTrue);
      expect(model.isSidebarVisible(200), isTrue);
    });

    test('hide mode stays hidden unless force open', () {
      final model = ChatModel(
        sidebarMode: SidebarVisibilityMode.hide,
        sidebarOpen: false,
      );
      expect(model.isSidebarVisible(200), isFalse);

      final forced = model.copyWith(sidebarOpen: true);
      expect(forced.isSidebarVisible(80), isTrue);
    });

    test('toggle matches OpenCode batch semantics', () {
      final auto = ChatModel(
        sidebarMode: SidebarVisibilityMode.auto,
        sidebarOpen: false,
      );
      // Wide: visible → hide
      final hidden = auto.toggleSidebar(160);
      expect(hidden.sidebarMode, SidebarVisibilityMode.hide);
      expect(hidden.sidebarOpen, isFalse);
      expect(hidden.isSidebarVisible(160), isFalse);

      // Narrow: not visible → force open
      final shown = hidden.toggleSidebar(80);
      expect(shown.sidebarMode, SidebarVisibilityMode.auto);
      expect(shown.sidebarOpen, isTrue);
      expect(shown.isSidebarVisible(80), isTrue);
    });
  });

  group('SessionShell responsive sidebar', () {
    test('hides sidebar on narrow terminal', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 30);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: openCodeTheme(),
            child: SessionShell(
              model: ChatModel(
                sessionTitle: 'Narrow Session',
                workingDirectory: '~/x',
                sidebarMode: SidebarVisibilityMode.auto,
                sidebarOpen: false,
                mcpServers: const [McpServer('filesystem')],
              ),
              scrollController: WidgetScrollController(),
              promptController: TextFieldController(),
              statusHint: '/status',
              replayEvents: const [],
              replayHistory: const ReplayEventHistoryState(
                filter: ReplayEventHistoryFilter.renderCaptures,
                mode: ReplayEventHistoryMode.grouped,
              ),
            ),
          ),
        );

        // Sidebar title would appear if visible; session header still shows.
        expect(tester.find.text('Narrow Session'), isTrue, reason: tester.view);
        // MCP section only lives in the sidebar pane.
        expect(tester.find.text('filesystem'), isFalse, reason: tester.view);
      } finally {
        await tester.dispose();
      }
    });

    test('shows sidebar on wide terminal in auto mode', () async {
      final tester = WidgetTester(screenWidth: 160, screenHeight: 30);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: openCodeTheme(),
            child: SessionShell(
              model: ChatModel(
                sessionTitle: 'Wide Session',
                workingDirectory: '~/x',
                sidebarMode: SidebarVisibilityMode.auto,
                sidebarOpen: false,
                mcpServers: const [McpServer('filesystem')],
              ),
              scrollController: WidgetScrollController(),
              promptController: TextFieldController(),
              statusHint: '/status',
              replayEvents: const [],
              replayHistory: const ReplayEventHistoryState(
                filter: ReplayEventHistoryFilter.renderCaptures,
                mode: ReplayEventHistoryMode.grouped,
              ),
            ),
          ),
        );

        expect(tester.find.text('Wide Session'), isTrue, reason: tester.view);
        expect(tester.find.text('filesystem'), isTrue, reason: tester.view);
      } finally {
        await tester.dispose();
      }
    });
  });
}
