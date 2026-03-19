import 'package:artisanal/bubbles.dart' show TextAreaModel;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/testing.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('TextArea construction', () {
    test('creates with default properties', () {
      final area = TextArea();
      expect(area.autofocus, isFalse);
      expect(area.enabled, isTrue);
      expect(area.height, 6);
      expect(area.showLineNumbers, isTrue);
      expect(area.softWrap, isTrue);
      expect(area.model, isNull);
      expect(area.controller, isNull);
    });

    test('creates with custom properties', () {
      final fc = FocusController();
      final area = TextArea(
        prompt: '» ',
        placeholder: 'Write notes',
        width: 48,
        height: 8,
        showLineNumbers: false,
        charLimit: 120,
        softWrap: false,
        autofocus: true,
        enabled: false,
        focusController: fc,
        focusId: 'notes',
      );

      expect(area.prompt, '» ');
      expect(area.placeholder, 'Write notes');
      expect(area.width, 48);
      expect(area.height, 8);
      expect(area.showLineNumbers, isFalse);
      expect(area.charLimit, 120);
      expect(area.softWrap, isFalse);
      expect(area.autofocus, isTrue);
      expect(area.enabled, isFalse);
      expect(area.focusController, same(fc));
      expect(area.focusId, 'notes');
    });
  });

  group('TextAreaController', () {
    test('creates with default model', () {
      final ctrl = TextAreaController();
      expect(ctrl.model, isA<TextAreaModel>());
      expect(ctrl.text, isEmpty);
      expect(ctrl.line, 0);
      expect(ctrl.column, 0);
    });

    test('text can be read and written', () {
      final ctrl = TextAreaController();
      ctrl.text = 'hello\nworld';
      expect(ctrl.text, 'hello\nworld');
      expect(ctrl.value, 'hello\nworld');
    });

    test('insertText and setCursor update the model', () {
      final ctrl = TextAreaController(text: 'hello\nworld');

      ctrl.setCursor(0, 5);
      ctrl.insertText('!');

      expect(ctrl.text, 'hello!\nworld');
      expect(ctrl.line, 0);
      expect(ctrl.column, 6);
    });

    test('undo and redo track programmatic text changes', () {
      final ctrl = TextAreaController();

      ctrl.text = 'line one';
      ctrl.text = 'line one\nline two';

      expect(ctrl.canUndo, isTrue);
      expect(ctrl.undo(), isTrue);
      expect(ctrl.text, 'line one');
      expect(ctrl.canRedo, isTrue);
      expect(ctrl.redo(), isTrue);
      expect(ctrl.text, 'line one\nline two');
    });

    test('selection and line indent helpers are exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );

      expect(ctrl.hasSelection, isTrue);
      expect(ctrl.selectionBase, (line: 0, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 4));

      expect(ctrl.indentLines(width: 2), isTrue);
      expect(ctrl.text, '  alpha\n  beta');

      expect(ctrl.outdentLines(width: 2), isTrue);
      expect(ctrl.text, 'alpha\nbeta');

      ctrl.clearSelection();
      expect(ctrl.hasSelection, isFalse);
    });

    test('selectAll helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta');

      ctrl.selectAll();

      expect(ctrl.hasSelection, isTrue);
      expect(ctrl.selectionBase, (line: 0, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 4));
      expect(ctrl.selectedText, 'alpha\nbeta');
    });

    test('selectCurrentLine helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta\ngamma');

      ctrl.setCursor(1, 2);
      ctrl.selectCurrentLine();

      expect(ctrl.hasSelection, isTrue);
      expect(ctrl.selectionBase, (line: 1, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 4));
      expect(ctrl.selectedText, 'beta');
    });

    test('move line helpers are exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta\ngamma');

      ctrl.setSelection(
        baseLine: 1,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );

      expect(ctrl.moveLinesUp(), isTrue);
      expect(ctrl.text, 'beta\nalpha\ngamma');

      expect(ctrl.moveLinesDown(), isTrue);
      expect(ctrl.text, 'alpha\nbeta\ngamma');
    });

    test('duplicate line helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta\ngamma');

      ctrl.setCursor(1, 1);
      expect(ctrl.duplicateLinesBelow(), isTrue);
      expect(ctrl.text, 'alpha\nbeta\nbeta\ngamma');
      expect(ctrl.line, 2);
    });

    test('duplicate line above helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta\ngamma');

      ctrl.setCursor(1, 1);
      expect(ctrl.duplicateLinesAbove(), isTrue);
      expect(ctrl.text, 'alpha\nbeta\nbeta\ngamma');
      expect(ctrl.line, 1);
    });

    test('cleanup helper trims trailing whitespace and blank lines', () {
      final ctrl = TextAreaController(text: 'alpha  \nbeta\t\n\n');

      expect(ctrl.cleanupWhitespace(), isTrue);
      expect(ctrl.text, 'alpha\nbeta');
      expect(ctrl.line, 1);
      expect(ctrl.column, 4);
    });

    test('selection or line case transform helpers are exposed', () {
      final ctrl = TextAreaController(text: 'alpha beta\nGAMMA DELTA');

      ctrl.setCursor(0, 3);
      expect(ctrl.uppercaseSelectionOrLine(), isTrue);
      expect(ctrl.text, 'ALPHA BETA\nGAMMA DELTA');
      expect(ctrl.line, 0);
      expect(ctrl.column, 3);

      ctrl.setSelection(
        baseLine: 1,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 11,
      );
      expect(ctrl.lowercaseSelectionOrLine(), isTrue);
      expect(ctrl.text, 'ALPHA BETA\ngamma delta');
      expect(ctrl.selectionExtent, (line: 1, column: 11));

      expect(ctrl.capitalizeSelectionOrLine(), isTrue);
      expect(ctrl.text, 'ALPHA BETA\nGamma Delta');
      expect(ctrl.selectionExtent, (line: 1, column: 11));
    });

    test('sort line helper is exposed', () {
      final ctrl = TextAreaController(text: 'delta\nbeta\nalpha');

      expect(ctrl.sortSelectedLines(), isTrue);
      expect(ctrl.text, 'alpha\nbeta\ndelta');

      ctrl.text = 'delta\nbeta\nalpha\ngamma';
      ctrl.setSelection(
        baseLine: 1,
        baseColumn: 0,
        extentLine: 3,
        extentColumn: 5,
      );
      expect(ctrl.sortSelectedLines(), isTrue);
      expect(ctrl.text, 'delta\nalpha\nbeta\ngamma');
      expect(ctrl.selectionBase, (line: 1, column: 0));
      expect(ctrl.selectionExtent, (line: 3, column: 5));
    });

    test('wrap selection helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha beta');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 6,
        extentLine: 0,
        extentColumn: 10,
      );
      expect(ctrl.wrapSelection('(', after: ')'), isTrue);
      expect(ctrl.text, 'alpha (beta)');
      expect(ctrl.selectionBase, (line: 0, column: 7));
      expect(ctrl.selectionExtent, (line: 0, column: 11));
    });

    test('toggle line prefix helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );
      expect(ctrl.toggleLinePrefix('>'), isTrue);
      expect(ctrl.text, '> alpha\n> beta');
      expect(ctrl.selectionBase, (line: 0, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 6));
    });

    test('unwrap selection helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha (beta)');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 7,
        extentLine: 0,
        extentColumn: 11,
      );
      expect(ctrl.unwrapSelection(), isTrue);
      expect(ctrl.text, 'alpha beta');
      expect(ctrl.selectionBase, (line: 0, column: 6));
      expect(ctrl.selectionExtent, (line: 0, column: 10));
    });

    test('toggle numbered list helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );
      expect(ctrl.toggleNumberedList(), isTrue);
      expect(ctrl.text, '1. alpha\n2. beta');
      expect(ctrl.selectionBase, (line: 0, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 7));
    });

    test('toggle checklist state helper is exposed', () {
      final ctrl = TextAreaController(text: '- [ ] alpha\n- [x] beta');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 10,
      );
      expect(ctrl.toggleChecklistState(), isTrue);
      expect(ctrl.text, '- [x] alpha\n- [x] beta');
      expect(ctrl.selectionBase, (line: 0, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 10));
    });

    test('renumber numbered list helper is exposed', () {
      final ctrl = TextAreaController(text: '9. alpha\n10. beta');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 8,
      );
      expect(ctrl.renumberNumberedList(), isTrue);
      expect(ctrl.text, '1. alpha\n2. beta');
      expect(ctrl.selectionBase, (line: 0, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 7));
    });

    test('toggle heading helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\n## beta');

      ctrl.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 7,
      );
      expect(ctrl.toggleHeadingPrefix(), isTrue);
      expect(ctrl.text, '# alpha\n# beta');
      expect(ctrl.selectionBase, (line: 0, column: 0));
      expect(ctrl.selectionExtent, (line: 1, column: 6));
    });

    test('delete line helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\nbeta\ngamma');

      ctrl.setCursor(1, 1);
      expect(ctrl.deleteLines(), isTrue);
      expect(ctrl.text, 'alpha\ngamma');
      expect(ctrl.line, 1);
    });

    test('join lines helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha\n  beta');

      ctrl.setCursor(0, 1);
      expect(ctrl.joinLines(), isTrue);
      expect(ctrl.text, 'alpha beta');
      expect(ctrl.line, 0);
    });

    test('split line helper is exposed', () {
      final ctrl = TextAreaController(text: 'alpha beta');

      ctrl.setCursor(0, 5);
      expect(ctrl.splitLine(), isTrue);
      expect(ctrl.text, 'alpha\n beta');
      expect(ctrl.line, 1);
      expect(ctrl.column, 0);
    });
  });

  group('TextArea widget', () {
    test('syncs config onto the underlying model', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextAreaController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 8,
          child: TextArea(
            controller: ctrl,
            height: 8,
            showLineNumbers: false,
            softWrap: false,
            autofocus: true,
          ),
        ),
      );

      expect(ctrl.model.height, 8);
      expect(ctrl.model.showLineNumbers, isFalse);
      expect(ctrl.model.softWrap, isFalse);
    });

    test('renders placeholder and prompt', () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 12);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 40,
          height: 6,
          child: TextArea(
            prompt: '│ ',
            placeholder: 'Write something...',
            autofocus: true,
          ),
        ),
      );

      expect(tester.view, contains('Write something...'));
    });

    test('typing characters and newline updates the controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextAreaController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 6,
          child: TextArea(
            controller: ctrl,
            prompt: '',
            showLineNumbers: false,
            autofocus: true,
          ),
        ),
      );

      tester.sendKey('h');
      tester.sendKey('i');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('y');
      tester.sendKey('o');

      expect(ctrl.text, 'hi\nyo');
    });

    test('shows line numbers by default', () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 12);
      addTearDown(() => tester.dispose());

      final ctrl = TextAreaController(text: 'first\nsecond');
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 6,
          child: TextArea(controller: ctrl, autofocus: true),
        ),
      );

      expect(tester.view, contains('1 '));
      expect(tester.view, contains('2 '));
      expect(tester.view, contains('first'));
      expect(tester.view, contains('second'));
    });

    test('programmatic controller changes update the rendered view', () async {
      final tester = WidgetTester(screenWidth: 60, screenHeight: 12);
      addTearDown(() => tester.dispose());

      final ctrl = TextAreaController(text: 'first');
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 6,
          child: TextArea(controller: ctrl, autofocus: true),
        ),
      );

      ctrl.text = 'first\nsecond';
      ctrl.setCursor(1, 6);
      tester.pump();

      expect(tester.view, contains('first'));
      expect(tester.view, contains('second'));
    });

    test('ctrl+z and ctrl+y undo and redo coalesced edits', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextAreaController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 6,
          child: TextArea(
            controller: ctrl,
            prompt: '',
            showLineNumbers: false,
            autofocus: true,
          ),
        ),
      );

      tester.sendKey('h');
      tester.sendKey('i');
      expect(ctrl.text, 'hi');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('z', ctrl: true)));
      expect(ctrl.text, '');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('y', ctrl: true)));
      expect(ctrl.text, 'hi');
    });
  });
}
