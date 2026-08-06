/// Regression: slash/@ autocomplete must open from TextField onChanged.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/theme.dart';
import '../../example/opencode/widgets/prompt_input.dart';

void main() {
  test('typing / opens slash autocomplete overlay', () async {
    final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
    addTearDown(() => tester.dispose());

    final controller = TextEditingController();
    await tester.pumpWidget(
      ThemeScope(
        theme: openCodeTheme(),
        child: PromptInput(controller: controller),
      ),
    );
    tester.pump();

    // Focus + type slash via key path.
    tester.sendKey('/');
    tester.pump();

    expect(
      tester.find.text('/help') || tester.view.contains('/help'),
      isTrue,
      reason: 'slash autocomplete should list /help\n${tester.view}',
    );
  });

  test('typing @ opens mention autocomplete overlay', () async {
    final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: openCodeTheme(),
        child: PromptInput(),
      ),
    );
    tester.pump();

    tester.sendKey('@');
    tester.pump();

    expect(
      tester.view.contains('lib/main.dart') ||
          tester.view.contains('pubspec.yaml'),
      isTrue,
      reason: 'mention autocomplete should list files\n${tester.view}',
    );
  });
}
