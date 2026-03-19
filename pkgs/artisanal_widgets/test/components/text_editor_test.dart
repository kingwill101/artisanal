import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('TextEditor', () {
    late FocusController focusController;

    setUp(() {
      focusController = FocusController();
    });

    test('renders title, stats, and help bar', () async {
      final tester = WidgetTester(screenWidth: 144, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'hello');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 128,
            child: TextEditor(
              title: 'Notes.md',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      expect(tester.view, contains('Notes.md'));
      expect(tester.view, contains('Ln 1, Col 6'));
      expect(tester.view, contains('5 chars'));
      expect(tester.view, contains('ctrl+f'));
      expect(tester.view, contains('ctrl+g'));
      expect(tester.view, contains('ctrl+a'));
      expect(tester.view, contains('ctrl+l'));
      expect(tester.view, contains('shift+tab'));
      expect(tester.view, contains('alt+j'));
      expect(tester.view, contains('ctrl+shift+k'));
      expect(tester.view, contains('ctrl+shift+d'));
      expect(tester.view, contains('alt+↑'));
      expect(tester.view, contains('alt+↓'));
      expect(tester.view, contains('alt+shift+↑'));
      expect(tester.view, contains('alt+shift+↓'));
      expect(tester.view, contains('alt+shift+j'));
      expect(tester.view, contains('alt+shift+u'));
      expect(tester.view, contains('alt+shift+l'));
      expect(tester.view, contains('alt+shift+c'));
      expect(tester.view, contains('alt+shift+s'));
      expect(tester.view, contains('alt+shift+q'));
      expect(tester.view, contains('alt+shift+b'));
      expect(tester.view, contains('alt+shift+x'));
      expect(tester.view, contains('alt+shift+n'));
      expect(tester.view, contains('alt+shift+m'));
      expect(tester.view, contains('alt+shift+r'));
      expect(tester.view, contains('alt+shift+h'));
      expect(tester.view, contains('alt+shift+f'));
      expect(tester.view, contains('alt+shift+w'));
      expect(tester.view, contains('ctrl+z'));
    });

    test('header stats update as the controller changes', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'hello');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Notes.md',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.text = 'hello\nworld';
      controller.setCursor(1, 5);
      tester.pump();

      expect(tester.view, contains('Ln 2, Col 6'));
      expect(tester.view, contains('11 chars'));
    });

    test('ctrl+z and ctrl+y work through the embedded editor', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController();
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Scratch',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      tester.sendKey('h');
      tester.sendKey('i');
      expect(controller.text, 'hi');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('z', ctrl: true)));
      expect(controller.text, '');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('y', ctrl: true)));
      expect(controller.text, 'hi');
    });

    test('ctrl+a selects all text through the embedded editor', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Scratch',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      tester.sendMsg(tui.KeyMsg(tui.Key.char('a', ctrl: true)));

      expect(controller.hasSelection, isTrue);
      expect(controller.selectionBase, (line: 0, column: 0));
      expect(controller.selectionExtent, (line: 1, column: 4));
      expect(controller.selectedText, 'alpha\nbeta');
    });

    test(
      'ctrl+l selects the current line through the embedded editor',
      () async {
        final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 72,
              child: TextEditor(
                title: 'Scratch',
                controller: controller,
                focusController: focusController,
                focusId: 'editor',
                height: 6,
                autofocus: true,
              ),
            ),
          ),
        );

        controller.setCursor(1, 2);
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('l', ctrl: true)));

        expect(controller.hasSelection, isTrue);
        expect(controller.selectionBase, (line: 1, column: 0));
        expect(controller.selectionExtent, (line: 1, column: 4));
        expect(controller.selectedText, 'beta');
      },
    );

    test('ctrl+s saves and clears the dirty status', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final savedValues = <String>[];
      final controller = TextAreaController(text: 'hello');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Scratch',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
              onSave: (value) {
                savedValues.add(value);
                return null;
              },
            ),
          ),
        ),
      );

      expect(tester.view, contains('saved'));

      controller.insertText(' world');
      tester.pump();
      expect(tester.view, contains('modified'));
      expect(tester.view, contains('ctrl+s'));

      tester.sendMsg(tui.KeyMsg(tui.Key.char('s', ctrl: true)));

      expect(savedValues, ['hello world']);
      expect(tester.view, contains('saved'));
    });

    test('tab inserts indentation spaces', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController();
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Indent',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
              indentWidth: 4,
            ),
          ),
        ),
      );

      tester.sendSpecialKey(terminal_keys.KeyType.tab);

      expect(controller.text, '    ');
      expect(tester.view, contains('tab'));
    });

    test('tab and shift+tab indent and outdent selected lines', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Indent Block',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
              indentWidth: 2,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );
      tester.pump();
      tester.sendSpecialKey(terminal_keys.KeyType.tab);
      expect(controller.text, '  alpha\n  beta');

      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.tab, shift: true)));
      expect(controller.text, 'alpha\nbeta');
    });

    test('alt+shift+j splits the current line', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha beta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Split',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setCursor(0, 5);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('j', alt: true, shift: true)));

      expect(controller.text, 'alpha\n beta');
      expect(controller.line, 1);
      expect(controller.column, 0);
    });

    test(
      'alt+shift+u/l/c transform the current line or selected block',
      () async {
        final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha beta\nGAMMA DELTA');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 72,
              child: TextEditor(
                title: 'Transform',
                controller: controller,
                focusController: focusController,
                focusId: 'editor',
                height: 6,
                autofocus: true,
              ),
            ),
          ),
        );

        controller.setCursor(0, 3);
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('u', alt: true, shift: true)));
        expect(controller.text, 'ALPHA BETA\nGAMMA DELTA');

        controller.setSelection(
          baseLine: 1,
          baseColumn: 0,
          extentLine: 1,
          extentColumn: 11,
        );
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('l', alt: true, shift: true)));
        expect(controller.text, 'ALPHA BETA\ngamma delta');

        tester.sendMsg(tui.KeyMsg(tui.Key.char('c', alt: true, shift: true)));
        expect(controller.text, 'ALPHA BETA\nGamma Delta');
        expect(controller.selectionExtent, (line: 1, column: 11));
      },
    );

    test('alt+shift+s sorts the selected block or whole buffer', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'delta\nbeta\nalpha\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Sort',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 1,
        baseColumn: 0,
        extentLine: 3,
        extentColumn: 5,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('s', alt: true, shift: true)));
      expect(controller.text, 'delta\nalpha\nbeta\ngamma');

      controller.text = 'delta\nbeta\nalpha';
      controller.clearSelection();
      controller.setCursor(2, 3);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('s', alt: true, shift: true)));
      expect(controller.text, 'alpha\nbeta\ndelta');
      expect(controller.line, 2);
      expect(controller.column, 3);
    });

    test('alt+j joins the current line or selected block', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\n  beta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Join',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setCursor(0, 1);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('j', alt: true)));
      expect(controller.text, 'alpha beta');
      expect(controller.line, 0);
      expect(controller.column, 10);
    });

    test('alt+up and alt+down move the selected block', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Move',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 1,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );
      tester.pump();
      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.up, alt: true)));
      expect(controller.text, 'beta\nalpha\ngamma');

      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.down, alt: true)));
      expect(controller.text, 'alpha\nbeta\ngamma');
    });

    test('ctrl+shift+d duplicates the current line or selection', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Duplicate',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setCursor(1, 1);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('d', ctrl: true, shift: true)));
      expect(controller.text, 'alpha\nbeta\nbeta\ngamma');
      expect(controller.line, 2);
    });

    test('ctrl+shift+k deletes the current line or selection', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Delete',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setCursor(1, 1);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('k', ctrl: true, shift: true)));
      expect(controller.text, 'alpha\ngamma');
      expect(controller.line, 1);
    });

    test(
      'alt+shift+q toggles quote prefixes on the current line or selection',
      () async {
        final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha\nbeta');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 72,
              child: TextEditor(
                title: 'Quote',
                controller: controller,
                focusController: focusController,
                focusId: 'editor',
                height: 6,
                autofocus: true,
              ),
            ),
          ),
        );

        controller.setSelection(
          baseLine: 0,
          baseColumn: 0,
          extentLine: 1,
          extentColumn: 4,
        );
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('q', alt: true, shift: true)));
        expect(controller.text, '> alpha\n> beta');
        expect(controller.selectionBase, (line: 0, column: 0));
        expect(controller.selectionExtent, (line: 1, column: 6));

        tester.sendMsg(tui.KeyMsg(tui.Key.char('q', alt: true, shift: true)));
        expect(controller.text, 'alpha\nbeta');
        expect(controller.selectionBase, (line: 0, column: 0));
        expect(controller.selectionExtent, (line: 1, column: 4));
      },
    );

    test(
      'alt+shift+b and alt+shift+x toggle bullet and checklist prefixes',
      () async {
        final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha\nbeta');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 72,
              child: TextEditor(
                title: 'Lists',
                controller: controller,
                focusController: focusController,
                focusId: 'editor',
                height: 6,
                autofocus: true,
              ),
            ),
          ),
        );

        controller.setSelection(
          baseLine: 0,
          baseColumn: 0,
          extentLine: 1,
          extentColumn: 4,
        );
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('b', alt: true, shift: true)));
        expect(controller.text, '- alpha\n- beta');
        expect(controller.selectionBase, (line: 0, column: 0));
        expect(controller.selectionExtent, (line: 1, column: 6));

        tester.sendMsg(tui.KeyMsg(tui.Key.char('b', alt: true, shift: true)));
        expect(controller.text, 'alpha\nbeta');

        tester.sendMsg(tui.KeyMsg(tui.Key.char('x', alt: true, shift: true)));
        expect(controller.text, '- [ ] alpha\n- [ ] beta');
        expect(controller.selectionBase, (line: 0, column: 0));
        expect(controller.selectionExtent, (line: 1, column: 10));

        tester.sendMsg(tui.KeyMsg(tui.Key.char('x', alt: true, shift: true)));
        expect(controller.text, 'alpha\nbeta');
      },
    );

    test('alt+shift+n toggles numbered list prefixes', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Numbers',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('n', alt: true, shift: true)));
      expect(controller.text, '1. alpha\n2. beta');
      expect(controller.selectionBase, (line: 0, column: 0));
      expect(controller.selectionExtent, (line: 1, column: 7));

      tester.sendMsg(tui.KeyMsg(tui.Key.char('n', alt: true, shift: true)));
      expect(controller.text, 'alpha\nbeta');
      expect(controller.selectionBase, (line: 0, column: 0));
      expect(controller.selectionExtent, (line: 1, column: 4));
    });

    test('alt+shift+m toggles checklist completion state', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: '- [ ] alpha\n- [x] beta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Checklist',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 10,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('m', alt: true, shift: true)));
      expect(controller.text, '- [x] alpha\n- [x] beta');
      expect(controller.selectionBase, (line: 0, column: 0));
      expect(controller.selectionExtent, (line: 1, column: 10));

      tester.sendMsg(tui.KeyMsg(tui.Key.char('m', alt: true, shift: true)));
      expect(controller.text, '- [ ] alpha\n- [ ] beta');
    });

    test('alt+shift+r renumbers numbered list items', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: '9. alpha\n10. beta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Renumber',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 8,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('r', alt: true, shift: true)));
      expect(controller.text, '1. alpha\n2. beta');
      expect(controller.selectionBase, (line: 0, column: 0));
      expect(controller.selectionExtent, (line: 1, column: 7));
    });

    test('alt+shift+h toggles markdown heading prefixes', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\n## beta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Heading',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 7,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('h', alt: true, shift: true)));
      expect(controller.text, '# alpha\n# beta');
      expect(controller.selectionBase, (line: 0, column: 0));
      expect(controller.selectionExtent, (line: 1, column: 6));

      tester.sendMsg(tui.KeyMsg(tui.Key.char('h', alt: true, shift: true)));
      expect(controller.text, 'alpha\nbeta');
      expect(controller.selectionBase, (line: 0, column: 0));
      expect(controller.selectionExtent, (line: 1, column: 4));
    });

    test(
      'alt+shift+f cleans trailing whitespace in the selection or whole buffer',
      () async {
        final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha  \nbeta\t\n\n');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 72,
              child: TextEditor(
                title: 'Cleanup',
                controller: controller,
                focusController: focusController,
                focusId: 'editor',
                height: 6,
                autofocus: true,
              ),
            ),
          ),
        );

        tester.sendMsg(tui.KeyMsg(tui.Key.char('f', alt: true, shift: true)));
        expect(controller.text, 'alpha\nbeta');
        expect(controller.line, 1);
        expect(controller.column, 4);
      },
    );

    test('typing an opening delimiter wraps the current selection', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha beta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Wrap',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 6,
        extentLine: 0,
        extentColumn: 10,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('(')));

      expect(controller.text, 'alpha (beta)');
      expect(controller.selectionBase, (line: 0, column: 7));
      expect(controller.selectionExtent, (line: 0, column: 11));
    });

    test('alt+shift+w unwraps the current selection', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 24);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha (beta)');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Wrap',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 7,
        extentLine: 0,
        extentColumn: 11,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('w', alt: true, shift: true)));

      expect(controller.text, 'alpha beta');
      expect(controller.selectionBase, (line: 0, column: 6));
      expect(controller.selectionExtent, (line: 0, column: 10));
    });

    test('ctrl+f opens search and enter jumps between matches', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 28);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nworld\nbeta\nworld');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Search.md',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      tester.sendMsg(tui.KeyMsg(tui.Key.char('f', ctrl: true)));
      expect(tester.view, contains('Find'));
      expect(tester.view, contains('Type to search'));

      tester.sendKey('w');
      tester.sendKey('o');
      tester.sendKey('r');
      tester.sendKey('l');
      tester.sendKey('d');

      expect(tester.view, contains('1/2 matches'));
      expect(tester.view, contains('Ln 2, Col 1'));

      tester.sendSpecialKey(terminal_keys.KeyType.enter);
      expect(tester.view, contains('2/2 matches'));
      expect(tester.view, contains('Ln 4, Col 1'));

      tester.sendMsg(const tui.KeyMsg(tui.Key(terminal_keys.KeyType.escape)));
      expect(tester.view, isNot(contains('Find in document')));
    });

    test('ctrl+g opens go to line and moves the cursor', () async {
      final tester = WidgetTester(screenWidth: 96, screenHeight: 28);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma\ndelta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 72,
            child: TextEditor(
              title: 'Goto.md',
              controller: controller,
              focusController: focusController,
              focusId: 'editor',
              height: 6,
              autofocus: true,
            ),
          ),
        ),
      );

      tester.sendMsg(tui.KeyMsg(tui.Key.char('g', ctrl: true)));
      expect(tester.view, contains('Go to line'));
      expect(tester.view, contains('Line 4 of 4'));

      tester.sendSpecialKey(terminal_keys.KeyType.backspace);
      tester.sendKey('2');

      expect(tester.view, contains('Line 2 of 4'));
      expect(tester.view, contains('Ln 2, Col 1'));

      tester.sendSpecialKey(terminal_keys.KeyType.enter);
      expect(tester.view, isNot(contains('Go to line')));
    });
  });
}
