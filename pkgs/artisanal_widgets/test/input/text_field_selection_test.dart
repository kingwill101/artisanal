import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/terminal.dart' show Key, KeyType;
import 'package:artisanal/tui.dart' show KeyMsg;
import 'package:test/test.dart';

void main() {
  group('TextField Keyboard Selection', () {
    test('Shift+Right should select character', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        // Move to start
        tester.sendSpecialKey(KeyType.home);
        expect(controller.model.position, 0);

        // Shift+Right to select 'h'
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        expect(controller.model.position, 1);
        expect(controller.model.getSelectedText(), 'h');

        // Shift+Right to select 'he'
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        expect(controller.model.position, 2);
        expect(controller.model.getSelectedText(), 'he');
      } finally {
        await tester.dispose();
      }
    });

    test('Shift+Left should select character backward', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        // Move to end
        tester.sendSpecialKey(KeyType.end);
        expect(controller.model.position, 5);

        // Shift+Left to select 'o'
        tester.sendMsg(KeyMsg(const Key(KeyType.left, shift: true)));
        expect(controller.model.position, 4);
        expect(controller.model.getSelectedText(), 'o');

        // Shift+Left to select 'lo'
        tester.sendMsg(KeyMsg(const Key(KeyType.left, shift: true)));
        expect(controller.model.position, 3);
        expect(controller.model.getSelectedText(), 'lo');
      } finally {
        await tester.dispose();
      }
    });

    test('Shift+Home/End should select to boundaries', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello world');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        // Move to start first (since autofocus puts it at the end)
        tester.sendSpecialKey(KeyType.home);
        expect(controller.model.position, 0);

        // Move to middle (after 'hello ')
        for (var i = 0; i < 6; i++) {
          tester.sendSpecialKey(KeyType.right);
        }
        expect(controller.model.position, 6);

        // Shift+Home to select 'hello '
        tester.sendMsg(KeyMsg(const Key(KeyType.home, shift: true)));
        expect(controller.model.position, 0);
        expect(controller.model.getSelectedText(), 'hello ');

        // Shift+End to select 'world' (anchor is at 6)
        tester.sendMsg(KeyMsg(const Key(KeyType.end, shift: true)));
        expect(controller.model.position, 11);
        expect(controller.model.getSelectedText(), 'world');
      } finally {
        await tester.dispose();
      }
    });

    test('Ctrl+Shift+Right/Left should select words', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello world again');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        tester.sendSpecialKey(KeyType.home);

        // Ctrl+Shift+Right selects 'hello'
        tester.sendMsg(
          KeyMsg(const Key(KeyType.right, shift: true, ctrl: true)),
        );
        expect(controller.model.getSelectedText(), 'hello');

        // Another Ctrl+Shift+Right selects 'hello world'
        tester.sendMsg(
          KeyMsg(const Key(KeyType.right, shift: true, ctrl: true)),
        );
        expect(controller.model.getSelectedText(), 'hello world');

        // Ctrl+Shift+Left contracts to 'hello '
        tester.sendMsg(
          KeyMsg(const Key(KeyType.left, shift: true, ctrl: true)),
        );
        expect(controller.model.getSelectedText(), 'hello ');
      } finally {
        await tester.dispose();
      }
    });

    test('Typing replaces selection', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        tester.sendSpecialKey(KeyType.home);
        // Select 'he'
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        expect(controller.model.getSelectedText(), 'he');

        // Type 'y'
        tester.sendKey('y');
        expect(controller.text, 'yllo');
        expect(controller.model.position, 1);
        expect(controller.model.getSelectedText(), '');
      } finally {
        await tester.dispose();
      }
    });

    test('Backspace deletes selection', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        tester.sendSpecialKey(KeyType.home);
        // Select 'he'
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));

        // Backspace
        tester.sendSpecialKey(KeyType.backspace);
        expect(controller.text, 'llo');
        expect(controller.model.position, 0);
        expect(controller.model.getSelectedText(), '');
      } finally {
        await tester.dispose();
      }
    });

    test('Delete key deletes selection', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        tester.sendSpecialKey(KeyType.home);
        // Select 'he'
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));

        // Delete
        tester.sendSpecialKey(KeyType.delete);
        expect(controller.text, 'llo');
        expect(controller.model.position, 0);
        expect(controller.model.getSelectedText(), '');
      } finally {
        await tester.dispose();
      }
    });
  });
}
