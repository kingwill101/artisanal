import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart' as w;
import 'package:test/test.dart';

import '../../example/opencode/models/chat_model.dart';
import '../../example/opencode/theme.dart';
import '../../example/opencode/screens/home.dart';

void main() {
  test('OpenCode home hero sits near vertical center', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final model = ChatModel(
      workingDirectory: '~/code/artisanal',
      mcpServers: const [McpServer('filesystem'), McpServer('git')],
      lspServers: const [LspServer('dart')],
    );

    await tester.pumpWidget(
      w.ThemeScope(
        theme: openCodeTheme(),
        child: HomeView(model: model),
      ),
      width: 160,
      height: 48,
    );
    tester.pump();

    final logo = tester.locateText('█▀▀█ █▀▀█ █▀▀█ █▀▀▄');
    final prompt = tester.locateText('Ask anything...');
    final footer = tester.locateText('~/code/artisanal');

    expect(logo, isNotNull, reason: tester.view);
    expect(prompt, isNotNull, reason: tester.view);
    expect(footer, isNotNull, reason: tester.view);

    // Hero should sit near vertical center of the content lane.
    expect(logo!.y, greaterThanOrEqualTo(18));
    expect(logo.y, lessThanOrEqualTo(28));

    // Hero should be centered horizontally (not pinned left).
    expect(logo.x, greaterThanOrEqualTo(56));
    expect(logo.x, lessThanOrEqualTo(72));

    // Prompt panel sits below logo.
    expect(prompt!.y, greaterThan(logo.y));

    // Footer stays at the bottom lane.
    expect(footer!.y, greaterThanOrEqualTo(44));
  });
}
