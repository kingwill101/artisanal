import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownEditor', () {
    late FocusController focusController;

    setUp(() {
      focusController = FocusController();
    });

    test('renders editor chrome and markdown preview', () async {
      final tester = WidgetTester(screenWidth: 104, screenHeight: 52);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(
        text: '# Notes\n\n- Ship MarkdownEditor',
      );
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 84,
            child: MarkdownEditor(
              title: 'README.md',
              controller: controller,
              focusController: focusController,
              focusId: 'markdown',
              autofocus: true,
              height: 8,
              previewHeight: 8,
              onSave: (_) => null,
            ),
          ),
        ),
      );

      expect(tester.view, contains('README.md'));
      expect(tester.view, contains('Preview · markdown'));
      expect(tester.view, contains('Notes'));
      expect(tester.view, contains('Ship MarkdownEditor'));
      expect(tester.view, contains('ctrl+f'));
      expect(tester.view, contains('ctrl+g'));
      expect(tester.view, contains('ctrl+s'));
    });

    test('preview updates when controller text changes', () async {
      final tester = WidgetTester(screenWidth: 104, screenHeight: 52);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: '# Notes');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 84,
            child: MarkdownEditor(
              title: 'README.md',
              controller: controller,
              focusController: focusController,
              focusId: 'markdown',
              autofocus: true,
              height: 8,
              previewHeight: 8,
            ),
          ),
        ),
      );

      controller.text = '## Updates\n\n- done';
      tester.pump();

      expect(tester.view, contains('Updates'));
      expect(tester.view, contains('done'));
    });

    test('ctrl+s saves through the embedded editor', () async {
      final tester = WidgetTester(screenWidth: 104, screenHeight: 52);
      addTearDown(() => tester.dispose());

      final savedValues = <String>[];
      final controller = TextAreaController(text: '# Notes');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 84,
            child: MarkdownEditor(
              title: 'README.md',
              controller: controller,
              focusController: focusController,
              focusId: 'markdown',
              autofocus: true,
              height: 8,
              previewHeight: 8,
              onSave: (value) {
                savedValues.add(value);
                return null;
              },
            ),
          ),
        ),
      );

      controller.insertText('\n- shipped');
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('s', ctrl: true)));

      expect(savedValues, ['# Notes\n- shipped']);
    });
  });
}
