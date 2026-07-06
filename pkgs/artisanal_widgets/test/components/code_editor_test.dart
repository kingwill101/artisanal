import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/bubbles.dart'
    show
        TextDecorationRange,
        TextDiagnosticRange,
        TextDiagnosticSeverity,
        textSearchDecorationLayerKey,
        textSearchDecorationLayerPriority,
        textSearchMatchDecorationKey,
        textSyntaxDecorationLayerKey;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('CodeEditor', () {
    late FocusController focusController;

    setUp(() {
      focusController = FocusController();
    });

    test('renders editor chrome and syntax preview', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 60);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(
        text: 'void main() {\n  print("hi");\n}',
      );
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
              onSave: (_) => null,
            ),
          ),
        ),
      );

      expect(tester.view, contains('main.dart'));
      expect(tester.view, contains('Preview · dart'));
      expect(tester.view, contains('void main()'));
      expect(tester.view, contains('ctrl+f'));
      expect(tester.view, contains('ctrl+g'));
      expect(tester.view, contains('ctrl+a'));
      expect(tester.view, contains('ctrl+l'));
      expect(tester.view, contains('alt+j'));
      expect(tester.view, contains('ctrl+shift+k'));
      expect(tester.view, contains('ctrl+shift+d'));
      expect(tester.view, contains('alt+↑'));
      expect(tester.view, contains('alt+↓'));
      expect(tester.view, contains('alt+shift+↑'));
      expect(tester.view, contains('alt+shift+↓'));
      expect(tester.view, contains('alt+shift+f'));
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
      expect(tester.view, contains('shift+tab'));
      expect(tester.view, contains('alt+shift+j'));
      expect(tester.view, contains('ctrl+/'));
      expect(tester.view, contains('alt+shift+a'));
      expect(tester.view, contains('ctrl+s'));
      expect(tester.view, contains('ctrl+z'));
    });

    test(
      'keeps syntax decorations while a higher-priority search layer comes and goes',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 40);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(
          text: 'void main() {\n  print("hi");\n}\nvoid other() {}',
        );
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
              ),
            ),
          ),
        );

        expect(
          controller.decorationsForLayer(textSyntaxDecorationLayerKey),
          isNotEmpty,
        );
        expect(
          controller.decorationsForLayer(textSearchDecorationLayerKey),
          isEmpty,
        );

        controller.setDecorationLayer(
          textSearchDecorationLayerKey,
          const [
            TextDecorationRange(
              startOffset: 0,
              endOffset: 4,
              styleKey: textSearchMatchDecorationKey,
            ),
            TextDecorationRange(
              startOffset: 29,
              endOffset: 33,
              styleKey: textSearchMatchDecorationKey,
            ),
          ],
          priority: textSearchDecorationLayerPriority,
        );

        expect(
          controller.decorationsForLayer(textSyntaxDecorationLayerKey),
          isNotEmpty,
        );
        expect(
          controller.decorationsForLayer(textSearchDecorationLayerKey).length,
          2,
        );

        controller.clearDecorationLayer(textSearchDecorationLayerKey);

        expect(
          controller.decorationsForLayer(textSearchDecorationLayerKey),
          isEmpty,
        );
        expect(
          controller.decorationsForLayer(textSyntaxDecorationLayerKey),
          isNotEmpty,
        );
      },
    );

    test(
      'f8 navigates typed diagnostics through the embedded editor',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(
          text: 'void main() {}\n\nTODO fix this',
        );
        controller.setDiagnostics(const [
          TextDiagnosticRange(
            startOffset: 0,
            endOffset: 4,
            severity: TextDiagnosticSeverity.info,
            code: 'BOOT001',
            message:
                'Bootstrap entrypoint is only informational in this sample.',
            source: 'playground',
          ),
          TextDiagnosticRange(
            startOffset: 16,
            endOffset: 20,
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            message: 'Address TODO markers before shipping this sample.',
            source: 'playground',
          ),
        ]);

        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
              ),
            ),
          ),
        );

        tester.sendSpecialKey(terminal_keys.KeyType.f8);
        expect(controller.selectedText, equals('void'));
        expect(tester.view, contains('info [playground/BOOT001] L1:C1'));
        expect(tester.view, contains('Bootstrap entrypoint is only'));
        expect(tester.view, contains('in this sample.'));

        tester.sendSpecialKey(terminal_keys.KeyType.f8);
        expect(controller.selectedText, equals('TODO'));
      },
    );

    test(
      'clicking a diagnostic gutter marker selects that diagnostic through CodeEditor',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(
          text: 'void main() {}\n\nTODO fix this',
        );
        controller.setDiagnostics(const [
          TextDiagnosticRange(
            startOffset: 0,
            endOffset: 4,
            severity: TextDiagnosticSeverity.info,
            code: 'BOOT001',
            message:
                'Bootstrap entrypoint is only informational in this sample.',
            source: 'playground',
          ),
          TextDiagnosticRange(
            startOffset: 16,
            endOffset: 20,
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            message: 'Address TODO markers before shipping this sample.',
            source: 'playground',
          ),
        ]);

        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
              ),
            ),
          ),
        );

        tester.tap(tester.find.textLocation('3~'));

        expect(controller.selectedText, equals('TODO'));
        expect(controller.selectionBase, equals((line: 2, column: 0)));
        expect(tester.view, contains('warning [playground/TODO001] L3:C1'));
      },
    );

    test('opening bracket inserts a matching closing delimiter', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 40);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'print');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setCursor(0, controller.text.length);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('(')));

      expect(controller.text, 'print()');
      expect(controller.line, 0);
      expect(controller.column, 6);
    });

    test('opening delimiter wraps the current selection', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setSelection(
        baseLine: 0,
        baseColumn: 1,
        extentLine: 0,
        extentColumn: 4,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('(')));

      expect(controller.text, 'a(lph)a');
      expect(controller.selectionBase, (line: 0, column: 2));
      expect(controller.selectionExtent, (line: 0, column: 5));
    });

    test(
      'typing a closing delimiter skips over an existing closing pair',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'print()');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
              ),
            ),
          ),
        );

        controller.setCursor(0, 6);
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char(')')));

        expect(controller.text, 'print()');
        expect(controller.line, 0);
        expect(controller.column, 7);
      },
    );

    test('backspace between an empty pair removes both delimiters', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'print()');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setCursor(0, 6);
      tester.pump();
      tester.sendSpecialKey(tui.KeyType.backspace);

      expect(controller.text, 'print');
      expect(controller.line, 0);
      expect(controller.column, 5);
    });

    test(
      'backspace inside a non-empty pair keeps normal delete behavior',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'print(a)');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
              ),
            ),
          ),
        );

        controller.setCursor(0, 7);
        tester.pump();
        tester.sendSpecialKey(tui.KeyType.backspace);

        expect(controller.text, 'print()');
        expect(controller.line, 0);
        expect(controller.column, 6);
      },
    );

    test(
      'typing a closing brace on an indented blank line snaps it outward',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'if (ready) {\n  ');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
                indentWidth: 2,
              ),
            ),
          ),
        );

        controller.setCursor(1, 2);
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('}')));

        expect(controller.text, 'if (ready) {\n}');
        expect(controller.line, 1);
        expect(controller.column, 1);
      },
    );

    test(
      'typing a closing brace on a nested blank line removes one indent level',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: '  if (ready) {\n    ');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
                indentWidth: 2,
              ),
            ),
          ),
        );

        controller.setCursor(1, 4);
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('}')));

        expect(controller.text, '  if (ready) {\n  }');
        expect(controller.line, 1);
        expect(controller.column, 3);
      },
    );

    test('preview updates when controller text changes', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'print("old");');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.text = 'final count = 1;';
      tester.pump();

      expect(tester.view, contains('final count = 1;'));
    });

    test('ctrl+s saves through the embedded editor', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final savedValues = <String>[];
      final controller = TextAreaController(text: 'print("hi");');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
              onSave: (value) {
                savedValues.add(value);
                return null;
              },
            ),
          ),
        ),
      );

      controller.insertText('\nprint("bye");');
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('s', ctrl: true)));

      expect(savedValues, ['print("hi");\nprint("bye");']);
      expect(tester.view, contains('saved'));
    });

    test('ctrl+/ toggles comments and keeps undo working', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(
        text: 'void main() {\n  print("hi");\n}',
      );
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setCursor(1, 2);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('/', ctrl: true)));

      expect(controller.text, 'void main() {\n  // print("hi");\n}');
      tester.sendMsg(tui.KeyMsg(tui.Key.char('z', ctrl: true)));
      expect(controller.text, 'void main() {\n  print("hi");\n}');
    });

    test('ctrl+/ toggles comments across selected lines', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
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
      tester.sendMsg(tui.KeyMsg(tui.Key.char('/', ctrl: true)));
      expect(controller.text, '// alpha\n// beta\ngamma');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('/', ctrl: true)));
      expect(controller.text, 'alpha\nbeta\ngamma');
    });

    test('alt+shift+a toggles block comments for the selected block', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
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

      tester.sendMsg(tui.KeyMsg(tui.Key.char('a', alt: true, shift: true)));
      expect(controller.text, '/* alpha\nbeta */\ngamma');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('a', alt: true, shift: true)));
      expect(controller.text, 'alpha\nbeta\ngamma');
    });

    test('alt+shift+j splits the current line', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha beta');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
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

    test('enter preserves the current line indentation', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: '  alpha');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setCursor(0, 7);
      tester.pump();
      tester.sendSpecialKey(tui.KeyType.enter);

      expect(controller.text, '  alpha\n  ');
      expect(controller.line, 1);
      expect(controller.column, 2);
    });

    test('enter after an opening brace increases indentation', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'if (ready) {');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
              indentWidth: 2,
            ),
          ),
        ),
      );

      controller.setCursor(0, controller.text.length);
      tester.pump();
      tester.sendSpecialKey(tui.KeyType.enter);

      expect(controller.text, 'if (ready) {\n  ');
      expect(controller.line, 1);
      expect(controller.column, 2);
    });

    test('enter between braces opens a new indented block line', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'if (ready) {}');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
              indentWidth: 2,
            ),
          ),
        ),
      );

      controller.setCursor(0, controller.text.indexOf('}'));
      tester.pump();
      tester.sendSpecialKey(tui.KeyType.enter);

      expect(controller.text, 'if (ready) {\n  \n}');
      expect(controller.line, 1);
      expect(controller.column, 2);
    });

    test(
      'enter before a closing brace replaces spacer whitespace with block indentation',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'if (ready) {   }');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
                indentWidth: 2,
              ),
            ),
          ),
        );

        controller.setCursor(0, controller.text.indexOf('{') + 1);
        tester.pump();
        tester.sendSpecialKey(tui.KeyType.enter);

        expect(controller.text, 'if (ready) {\n  \n}');
        expect(controller.line, 1);
        expect(controller.column, 2);
      },
    );

    test('tab and shift+tab indent and outdent selected lines', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
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

      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.tab)));
      expect(controller.text, '  alpha\n  beta\ngamma');

      tester.sendMsg(const tui.KeyMsg(tui.Key(tui.KeyType.tab, shift: true)));
      expect(controller.text, 'alpha\nbeta\ngamma');
    });

    test('alt+up and alt+down move the selected lines', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
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

    test(
      'ctrl+shift+d duplicates the current line or selected block',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
              ),
            ),
          ),
        );

        controller.setCursor(1, 1);
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('d', ctrl: true, shift: true)));
        expect(controller.text, 'alpha\nbeta\nbeta\ngamma');

        controller.setSelection(
          baseLine: 1,
          baseColumn: 0,
          extentLine: 2,
          extentColumn: 4,
        );
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('d', ctrl: true, shift: true)));
        expect(controller.text, 'alpha\nbeta\nbeta\nbeta\nbeta\ngamma');
      },
    );

    test(
      'alt+shift+up and alt+shift+down duplicate the selected lines',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
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
        tester.sendMsg(
          const tui.KeyMsg(tui.Key(tui.KeyType.up, alt: true, shift: true)),
        );
        expect(controller.text, 'alpha\nbeta\nbeta\ngamma');
        expect(controller.selectionBase, (line: 1, column: 0));
        expect(controller.selectionExtent, (line: 1, column: 4));

        controller.text = 'alpha\nbeta\ngamma';
        controller.setSelection(
          baseLine: 1,
          baseColumn: 0,
          extentLine: 1,
          extentColumn: 4,
        );
        tester.pump();
        tester.sendMsg(
          const tui.KeyMsg(tui.Key(tui.KeyType.down, alt: true, shift: true)),
        );
        expect(controller.text, 'alpha\nbeta\nbeta\ngamma');
        expect(controller.selectionBase, (line: 2, column: 0));
        expect(controller.selectionExtent, (line: 2, column: 4));
      },
    );

    test(
      'alt+shift+f cleans trailing whitespace in the selected block or whole buffer',
      () async {
        final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
        addTearDown(() => tester.dispose());

        final controller = TextAreaController(text: 'alpha  \nbeta\t\ngamma  ');
        await tester.pumpWidget(
          FocusScope(
            controller: focusController,
            child: Container(
              width: 80,
              child: CodeEditor(
                title: 'main.dart',
                language: 'dart',
                controller: controller,
                focusController: focusController,
                focusId: 'code',
                autofocus: true,
                height: 6,
                previewHeight: 6,
              ),
            ),
          ),
        );

        controller.setSelection(
          baseLine: 0,
          baseColumn: 0,
          extentLine: 1,
          extentColumn: 5,
        );
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('f', alt: true, shift: true)));
        expect(controller.text, 'alpha\nbeta\ngamma  ');
        expect(controller.selectionExtent, (line: 1, column: 4));

        controller.text = 'alpha  \nbeta\t\n\n';
        controller.clearSelection();
        controller.setCursor(3, 0);
        tester.pump();
        tester.sendMsg(tui.KeyMsg(tui.Key.char('f', alt: true, shift: true)));
        expect(controller.text, 'alpha\nbeta');
        expect(controller.line, 1);
        expect(controller.column, 4);
      },
    );

    test('alt+shift+u transforms the current line in CodeEditor', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha beta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setCursor(0, 4);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('u', alt: true, shift: true)));

      expect(controller.text, 'ALPHA BETA\ngamma');
      expect(controller.line, 0);
      expect(controller.column, 4);
    });

    test('alt+shift+s sorts lines in CodeEditor', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'delta\nbeta\nalpha');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      tester.sendMsg(tui.KeyMsg(tui.Key.char('s', alt: true, shift: true)));
      expect(controller.text, 'alpha\nbeta\ndelta');
    });

    test('ctrl+shift+k deletes the current line or selected block', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\nbeta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setCursor(1, 1);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('k', ctrl: true, shift: true)));
      expect(controller.text, 'alpha\ngamma');

      controller.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 5,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('k', ctrl: true, shift: true)));
      expect(controller.text, '');
    });

    test('alt+j joins the current line or selected block', () async {
      final tester = WidgetTester(screenWidth: 100, screenHeight: 32);
      addTearDown(() => tester.dispose());

      final controller = TextAreaController(text: 'alpha\n  beta\ngamma');
      await tester.pumpWidget(
        FocusScope(
          controller: focusController,
          child: Container(
            width: 80,
            child: CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: controller,
              focusController: focusController,
              focusId: 'code',
              autofocus: true,
              height: 6,
              previewHeight: 6,
            ),
          ),
        ),
      );

      controller.setCursor(0, 1);
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('j', alt: true)));
      expect(controller.text, 'alpha beta\ngamma');

      controller.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 5,
      );
      tester.pump();
      tester.sendMsg(tui.KeyMsg(tui.Key.char('j', alt: true)));
      expect(controller.text, 'alpha beta gamma');
    });
  });
}
