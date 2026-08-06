import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('ToolCardInline', () {
    test('renders tool name and path', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ToolCardInline(
            toolName: 'Read',
            title: 'Read',
            filePath: 'lib/main.dart',
            status: ToolCardStatus.completed,
          ),
        ),
      );

      expect(tester.view, contains('Read'));
      expect(tester.view, contains('lib/main.dart'));
    });

    test('renders error text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ToolCardInline(
            toolName: 'Bash',
            status: ToolCardStatus.error,
            error: 'exit 1',
          ),
        ),
      );

      expect(tester.view, contains('exit 1'));
    });
  });

  group('ToolCard', () {
    test('renders block title and body', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ToolCard(
            toolName: 'Edit',
            title: '# Edit',
            filePath: 'a.dart',
            status: ToolCardStatus.completed,
            body: Text('diff body'),
          ),
        ),
      );

      expect(tester.find.text('# Edit'), isTrue);
      expect(tester.find.text('a.dart'), isTrue);
      expect(tester.find.text('diff body'), isTrue);
    });
  });
}
