import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/terminal.dart' as terminal show Key;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart'
    show KeyMsg, MouseAction, MouseButton, MouseMsg;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Construction & properties
  // ---------------------------------------------------------------------------
  group('Multiline TextField construction', () {
    test('multiline defaults to false', () {
      final tf = TextField();
      expect(tf.multiline, isFalse);
    });

    test('maxLines defaults to 0', () {
      final tf = TextField();
      expect(tf.maxLines, equals(0));
    });

    test('multiline can be set to true', () {
      final tf = TextField(multiline: true);
      expect(tf.multiline, isTrue);
    });

    test('maxLines can be set', () {
      final tf = TextField(multiline: true, maxLines: 5);
      expect(tf.maxLines, equals(5));
    });
  });

  // ---------------------------------------------------------------------------
  // Model configuration sync
  // ---------------------------------------------------------------------------
  group('Multiline model configuration', () {
    test('multiline flag is synced to model via controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(controller: ctrl, multiline: true, autofocus: true),
        ),
      );
      expect(ctrl.model.multiline, isTrue);
    });

    test('maxLines is synced to model.maxHeight', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            multiline: true,
            maxLines: 5,
            autofocus: true,
          ),
        ),
      );
      expect(ctrl.model.maxHeight, equals(5));
    });

    test('single-line mode leaves multiline false on model', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(TextField(controller: ctrl, autofocus: true));
      expect(ctrl.model.multiline, isFalse);
    });
  });

  group('TextField mouse selection', () {
    test('mouse drag messages are handled without mutating text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 8,
          child: TextField(controller: ctrl, multiline: true, autofocus: true),
        ),
      );

      for (final c in 'Hello World'.split('')) {
        tester.sendKey(c);
      }

      tester.sendMsg(
        const MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 3,
          y: 1,
        ),
      );
      tester.sendMsg(
        const MouseMsg(
          action: MouseAction.motion,
          button: MouseButton.left,
          x: 8,
          y: 1,
        ),
      );

      expect(ctrl.text, equals('Hello World'));
    });

    test(
      'selection copies immediately when mouse leaves input hit-test',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final ctrl = TextFieldController();
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 8,
            child: TextField(
              controller: ctrl,
              multiline: true,
              autofocus: true,
            ),
          ),
        );

        for (final c in 'Hello World'.split('')) {
          tester.sendKey(c);
        }

        final pos = tester.locateText('Hello World');
        expect(pos, isNotNull);
        final clickPos = pos!;

        tester.sendMsg(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: clickPos.x + 1,
            y: clickPos.y,
          ),
        );
        tester.sendMsg(
          MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.none,
            x: clickPos.x + 6,
            y: clickPos.y,
          ),
        );

        expect(ctrl.selection.isCollapsed, isFalse);

        // Move outside the text field while still dragging.
        tester.sendMsg(
          MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.none,
            x: clickPos.x + 50,
            y: clickPos.y + 8,
          ),
        );

        expect(ctrl.selection.isCollapsed, isTrue);
        expect(ctrl.text, equals('Hello World'));
      },
    );

    test('click after moving cursor to start does not jump to end', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 6,
          child: TextField(
            controller: ctrl,
            multiline: true,
            prompt: '',
            autofocus: true,
          ),
        ),
      );

      for (final c in 'hello world'.split('')) {
        tester.sendKey(c);
      }
      expect(ctrl.model.position, equals(ctrl.text.length));

      tester.sendSpecialKey(KeyType.home);
      expect(ctrl.model.position, equals(0));

      tester.tapAt(3, 0);

      expect(ctrl.model.position, greaterThan(0));
      expect(ctrl.model.position, lessThan(ctrl.text.length));
    });

    test(
      'nested layout click maps to local cursor position (regression)',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final ctrl = TextFieldController();
        await tester.pumpWidget(
          Container(
            width: 120,
            height: 30,
            child: Row(
              children: [
                SizedBox(width: 60, child: Text('sidebar')),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 2,
                      right: 2,
                      top: 1,
                      bottom: 1,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: ctrl,
                          multiline: true,
                          prompt: ' ',
                          autofocus: true,
                          maxLines: 6,
                        ),
                        SizedBox(height: 1),
                        Text('metadata'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        for (final c in 'hello world hello world hello world'.split('')) {
          tester.sendKey(c);
        }
        final len = ctrl.text.length;
        expect(ctrl.model.position, equals(len));

        tester.sendSpecialKey(KeyType.home);
        expect(ctrl.model.position, equals(0));

        // Approximate absolute click inside the text line near the beginning:
        // sidebar(60) + container left padding(2) + prompt(1) + 3 chars.
        tester.tapAt(66, 1);

        expect(ctrl.model.position, greaterThan(0));
        expect(ctrl.model.position, lessThan(len));
      },
    );

    test('deeply offset layout click maps to local cursor position', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 130,
          height: 35,
          child: Column(
            children: [
              SizedBox(height: 19, child: Text('header area')),
              Row(
                children: [
                  SizedBox(width: 60, child: Text('sidebar')),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 2, right: 2, top: 1),
                      child: TextField(
                        controller: ctrl,
                        multiline: true,
                        prompt: ' ',
                        autofocus: true,
                        maxLines: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      for (final c in 'hello world hello world hello world'.split('')) {
        tester.sendKey(c);
      }
      final len = ctrl.text.length;

      tester.sendSpecialKey(KeyType.home);
      expect(ctrl.model.position, equals(0));

      tester.tapAt(66, 20);

      expect(ctrl.model.position, greaterThan(0));
      expect(ctrl.model.position, lessThan(len));
    });
  });

  // ---------------------------------------------------------------------------
  // Basic rendering
  // ---------------------------------------------------------------------------
  group('Multiline TextField rendering', () {
    test('renders inside a Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(prompt: '> ', multiline: true, autofocus: true),
        ),
      );
      final view = tester.view;
      expect(view.isNotEmpty, isTrue);
    });

    test('typing characters works in multiline mode', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      tester.sendKey('h');
      tester.sendKey('e');
      tester.sendKey('l');
      tester.sendKey('l');
      tester.sendKey('o');
      expect(ctrl.model.value, equals('hello'));
      expect(tester.locateText('hello'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Newline insertion
  // ---------------------------------------------------------------------------
  group('Multiline newline insertion', () {
    test('shift+enter inserts a newline', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      tester.sendKey('a');
      tester.sendKey('b');
      // Send Shift+Enter
      tester.sendMsg(KeyMsg(terminal.Key(KeyType.enter, shift: true)));
      tester.sendKey('c');

      // The value should contain a newline character
      expect(ctrl.model.value.contains('\n'), isTrue);
      expect(ctrl.model.value, equals('ab\nc'));
    });

    test('enter also inserts a newline in multiline mode', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      tester.sendKey('x');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('y');

      expect(ctrl.model.value.contains('\n'), isTrue);
      expect(ctrl.model.value, equals('x\ny'));
    });

    test('multiple newlines create multiple lines', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      tester.sendKey('a');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('b');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('c');

      expect(ctrl.model.value, equals('a\nb\nc'));
    });
  });

  // ---------------------------------------------------------------------------
  // Width from constraints
  // ---------------------------------------------------------------------------
  group('Multiline width from constraints', () {
    test('model.width is set from container width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 30,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      // After layout, the model's width should be set from constraints
      // The render object sets model.width = constraints.maxWidth
      expect(ctrl.model.width, equals(30));
    });

    test('model.width updates when container resizes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 30,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      expect(ctrl.model.width, equals(30));

      // Resize by pumping with a new width
      await tester.pumpWidget(
        Container(
          width: 50,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      expect(ctrl.model.width, equals(50));
    });
  });

  // ---------------------------------------------------------------------------
  // Arrow key navigation
  // ---------------------------------------------------------------------------
  group('Multiline arrow navigation', () {
    test('up/down arrows navigate between lines', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      // Type "hello\nworld" — cursor is at end of "world"
      tester.sendKey('h');
      tester.sendKey('e');
      tester.sendKey('l');
      tester.sendKey('l');
      tester.sendKey('o');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('w');
      tester.sendKey('o');
      tester.sendKey('r');
      tester.sendKey('l');
      tester.sendKey('d');

      expect(ctrl.model.value, equals('hello\nworld'));

      // Press Up — cursor should move to first line
      final posBefore = ctrl.model.position;
      tester.sendSpecialKey(KeyType.up);
      final posAfter = ctrl.model.position;

      // Position should have changed (moved up from "world" line to "hello" line)
      expect(posAfter, isNot(equals(posBefore)));
      // Position should be somewhere in the first line (0..5 range)
      expect(posAfter, lessThanOrEqualTo(5));
    });

    test('down arrow from first line moves to second line', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      // Type "hello\nworld"
      tester.sendKey('h');
      tester.sendKey('e');
      tester.sendKey('l');
      tester.sendKey('l');
      tester.sendKey('o');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('w');
      tester.sendKey('o');
      tester.sendKey('r');
      tester.sendKey('l');
      tester.sendKey('d');

      // Move to beginning of first line
      tester.sendSpecialKey(KeyType.up);
      tester.sendSpecialKey(KeyType.home);

      final posAtHome = ctrl.model.position;

      // Press Down — should move to second line
      tester.sendSpecialKey(KeyType.down);
      final posAfterDown = ctrl.model.position;

      // Position should now be on the second line (after the newline)
      expect(posAfterDown, greaterThan(posAtHome));
    });
  });

  // ---------------------------------------------------------------------------
  // Backspace across newlines
  // ---------------------------------------------------------------------------
  group('Multiline backspace', () {
    test('backspace at start of second line joins lines', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '> ',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      // Type "ab\ncd"
      tester.sendKey('a');
      tester.sendKey('b');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('c');
      tester.sendKey('d');
      expect(ctrl.model.value, equals('ab\ncd'));

      // Move to beginning of second line (right after the \n)
      // Home goes to start of current line in the model
      tester.sendSpecialKey(KeyType.home);

      // Backspace should delete the newline, joining "ab" and "cd"
      tester.sendSpecialKey(KeyType.backspace);
      expect(ctrl.model.value, equals('abcd'));
    });
  });

  // ---------------------------------------------------------------------------
  // onChanged callback
  // ---------------------------------------------------------------------------
  group('Multiline onChanged', () {
    test('onChanged fires when text changes in multiline mode', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final values = <String>[];
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: TextField(
            prompt: '> ',
            multiline: true,
            autofocus: true,
            onChanged: (v) => values.add(v),
          ),
        ),
      );

      tester.sendKey('a');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('b');

      expect(values.length, equals(3));
      expect(values[0], equals('a'));
      expect(values[1], equals('a\n'));
      expect(values[2], equals('a\nb'));
    });
  });

  // ---------------------------------------------------------------------------
  // Focus behavior in multiline
  // ---------------------------------------------------------------------------
  group('Multiline focus', () {
    test('does not process input when not focused', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      final fc = FocusController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: FocusScope(
            controller: fc,
            child: TextField(
              controller: ctrl,
              multiline: true,
              focusId: 'multi',
              // no autofocus
            ),
          ),
        ),
      );

      tester.sendKey('a');
      expect(ctrl.model.value, isEmpty);
    });

    test('autofocus works in multiline mode', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: FocusScope(
            controller: fc,
            child: TextField(
              multiline: true,
              focusId: 'multi',
              autofocus: true,
            ),
          ),
        ),
      );

      expect(fc.isFocused('multi'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Backward compatibility — single-line unchanged
  // ---------------------------------------------------------------------------
  group('Single-line backward compatibility', () {
    test('default TextField still works as single-line', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        TextField(controller: ctrl, prompt: '> ', autofocus: true),
      );

      tester.sendKey('h');
      tester.sendKey('i');
      expect(ctrl.model.value, equals('hi'));
      expect(ctrl.model.multiline, isFalse);
    });

    test('enter in single-line does NOT insert newline', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(
        TextField(controller: ctrl, prompt: '> ', autofocus: true),
      );

      tester.sendKey('a');
      tester.sendSpecialKey(KeyType.enter);
      tester.sendKey('b');

      // Single-line: enter should NOT insert a newline
      expect(ctrl.model.value.contains('\n'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Render object (layout pipeline integration)
  // ---------------------------------------------------------------------------
  group('Multiline render object', () {
    test(
      'multiline uses custom render object (view contains newlines)',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final ctrl = TextFieldController();
        await tester.pumpWidget(
          Container(
            width: 40,
            height: 10,
            child: TextField(
              controller: ctrl,
              prompt: '> ',
              multiline: true,
              autofocus: true,
            ),
          ),
        );

        // Type enough to get two lines via newline
        tester.sendKey('a');
        tester.sendSpecialKey(KeyType.enter);
        tester.sendKey('b');

        final view = tester.view;
        // The rendered view should contain content from both lines
        expect(view.contains('a'), isTrue);
        expect(view.contains('b'), isTrue);
      },
    );

    test('soft-wrapping occurs at container width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      // Use a narrow container so text must wrap
      await tester.pumpWidget(
        Container(
          width: 10,
          height: 10,
          child: TextField(
            controller: ctrl,
            prompt: '',
            multiline: true,
            autofocus: true,
          ),
        ),
      );

      // Type more characters than the container width
      for (final c in 'abcdefghijklmnop'.split('')) {
        tester.sendKey(c);
      }

      // The model should have width set from the container
      expect(ctrl.model.width, equals(10));

      // The view should have multiple lines due to soft-wrapping
      final view = tester.view;
      final lines = view.split('\n');
      expect(
        lines.length,
        greaterThan(1),
        reason: '16 chars in width=10 should wrap',
      );
    });
  });
}
