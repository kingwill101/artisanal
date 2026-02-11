import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/terminal.dart' show Key, KeyType;
import 'package:artisanal/tui.dart' show KeyMsg;
import 'package:test/test.dart';

void main() {
  group('TextField Advanced Selection', () {
    test('Ctrl+A should select all', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello world');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        // Ctrl+A
        tester.sendMsg(
          KeyMsg(const Key(KeyType.runes, runes: [0x01], ctrl: true)),
        ); // Ctrl+A is often 0x01 or just 'a' with ctrl
        // Actually Key decoding usually gives KeyType.runes with 'a' and ctrl: true
        tester.sendMsg(
          KeyMsg(const Key(KeyType.runes, runes: [0x61], ctrl: true)),
        );

        expect(controller.model.getSelectedText(), 'hello world');
        expect(controller.model.position, 11);
      } finally {
        await tester.dispose();
      }
    });

    test('Ctrl+X should cut selection', () async {
      final tester = WidgetTester();
      try {
        final controller = w.TextEditingController(text: 'hello world');

        await tester.pumpWidget(
          w.FocusScope(
            child: w.TextField(controller: controller, autofocus: true),
          ),
        );

        tester.sendSpecialKey(KeyType.home);
        // Select 'hello'
        for (var i = 0; i < 5; i++) {
          tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        }
        expect(controller.model.getSelectedText(), 'hello');

        // Ctrl+X
        tester.sendMsg(
          KeyMsg(const Key(KeyType.runes, runes: [0x78], ctrl: true)),
        ); // 'x' with ctrl

        expect(controller.text, ' world');
        expect(controller.model.position, 0);
        expect(controller.model.getSelectedText(), '');
      } finally {
        await tester.dispose();
      }
    });
  });
}
