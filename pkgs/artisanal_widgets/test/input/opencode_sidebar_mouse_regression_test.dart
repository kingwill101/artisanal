import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/models/chat_model.dart';
import '../../example/opencode/widgets/sidebar_widget.dart';

void main() {
  test('sidebar section header is tappable across row width', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 32);
    addTearDown(() => tester.dispose());

    final taps = <String>[];
    await tester.pumpWidget(
      _SidebarTapHarness(
        onToggleMcp: () {
          taps.add('mcp');
        },
      ),
    );

    expect(tester.find.text('filesystem'), isTrue);

    final mcpLabelPos = tester.locateText('MCP');
    expect(mcpLabelPos, isNotNull);

    // Tap well to the right of "MCP" on the same row. This ensures the whole
    // sidebar row is interactive, not only the text glyph bounds.
    tester.tapAt(mcpLabelPos!.x + 16, mcpLabelPos.y);

    expect(taps, hasLength(1));
    expect(tester.find.text('filesystem'), isFalse);
  });
}

class _SidebarTapHarness extends w.StatefulWidget {
  _SidebarTapHarness({required this.onToggleMcp});

  final w.VoidCallback onToggleMcp;

  @override
  w.State createState() => _SidebarTapHarnessState();
}

class _SidebarTapHarnessState extends w.State<_SidebarTapHarness> {
  final SidebarState _state = SidebarState();

  static final ChatModel _model = ChatModel(
    route: AppRoute.session,
    sessionTitle: 'Sidebar test',
    contextTokens: 123,
    contextPercentage: 10,
    cost: 0.42,
    mcpServers: const [
      McpServer('filesystem', status: 'connected'),
      McpServer('git', status: 'connected'),
      McpServer('postgres', status: 'disabled'),
    ],
    lspServers: const [
      LspServer('dart', status: 'connected'),
      LspServer('typescript', status: 'connected'),
    ],
    todos: const [TodoItem('todo one'), TodoItem('todo two')],
    modifiedFiles: const [
      ModifiedFile('a.dart', additions: 1, deletions: 0),
      ModifiedFile('b.dart', additions: 2, deletions: 1),
      ModifiedFile('c.dart', additions: 3, deletions: 2),
    ],
  );

  @override
  w.Widget build(w.BuildContext context) {
    return w.Container(
      width: 42,
      height: 28,
      child: SidebarWidget(
        model: _model,
        sidebarState: _state,
        onToggleMcp: () {
          setState(() {
            _state.mcpExpanded = !_state.mcpExpanded;
          });
          widget.onToggleMcp();
        },
      ),
    );
  }
}
