import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('KeyMsg', () {
    test('wraps a Key', () {
      const key = Key(KeyType.enter);
      const msg = KeyMsg(key);
      expect(msg.key, equals(key));
    });

    test('equality works correctly', () {
      const msg1 = KeyMsg(Key(KeyType.enter));
      const msg2 = KeyMsg(Key(KeyType.enter));
      const msg3 = KeyMsg(Key(KeyType.tab));

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString includes key info', () {
      const msg = KeyMsg(Key(KeyType.enter));
      expect(msg.toString(), contains('KeyMsg'));
      expect(msg.toString(), contains('Enter'));
    });
  });

  group('WindowSizeMsg', () {
    test('stores width and height', () {
      const msg = WindowSizeMsg(80, 24);
      expect(msg.width, 80);
      expect(msg.height, 24);
    });

    test('equality works correctly', () {
      const msg1 = WindowSizeMsg(80, 24);
      const msg2 = WindowSizeMsg(80, 24);
      const msg3 = WindowSizeMsg(100, 30);

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString includes dimensions', () {
      const msg = WindowSizeMsg(80, 24);
      final str = msg.toString();
      expect(str, contains('80'));
      expect(str, contains('24'));
    });
  });

  group('TickMsg', () {
    test('stores time', () {
      final time = DateTime(2024, 1, 1, 12, 0, 0);
      final msg = TickMsg(time);
      expect(msg.time, time);
      expect(msg.id, isNull);
    });

    test('stores optional id', () {
      final time = DateTime.now();
      final msg = TickMsg(time, id: 'timer1');
      expect(msg.id, 'timer1');
    });

    test('equality considers time and id', () {
      final time = DateTime(2024, 1, 1);
      final msg1 = TickMsg(time, id: 'a');
      final msg2 = TickMsg(time, id: 'a');
      final msg3 = TickMsg(time, id: 'b');

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString includes time', () {
      final time = DateTime(2024, 1, 1);
      final msg = TickMsg(time);
      expect(msg.toString(), contains('TickMsg'));
    });
  });

  group('QuitMsg', () {
    test('is a singleton-like message', () {
      const msg1 = QuitMsg();
      const msg2 = QuitMsg();
      expect(msg1.toString(), contains('QuitMsg'));
      expect(msg2.toString(), contains('QuitMsg'));
    });
  });

  group('BatchMsg', () {
    test('wraps multiple messages', () {
      const messages = [KeyMsg(Key(KeyType.enter)), WindowSizeMsg(80, 24)];
      const msg = BatchMsg(messages);
      expect(msg.messages, hasLength(2));
      expect(msg.messages[0], isA<KeyMsg>());
      expect(msg.messages[1], isA<WindowSizeMsg>());
    });

    test('toString shows count', () {
      const msg = BatchMsg([QuitMsg(), QuitMsg()]);
      expect(msg.toString(), contains('2'));
    });
  });

  group('MouseMsg', () {
    test('stores all properties', () {
      const msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 10,
        y: 20,
        ctrl: true,
        alt: false,
        shift: true,
      );

      expect(msg.action, MouseAction.press);
      expect(msg.button, MouseButton.left);
      expect(msg.x, 10);
      expect(msg.y, 20);
      expect(msg.ctrl, isTrue);
      expect(msg.alt, isFalse);
      expect(msg.shift, isTrue);
    });

    test('hasModifier is true when any modifier is set', () {
      const msgWithMod = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 0,
        y: 0,
        ctrl: true,
      );
      expect(msgWithMod.hasModifier, isTrue);

      const msgWithoutMod = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 0,
        y: 0,
      );
      expect(msgWithoutMod.hasModifier, isFalse);
    });

    test('equality works correctly', () {
      const msg1 = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 10,
        y: 20,
      );
      const msg2 = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 10,
        y: 20,
      );
      const msg3 = MouseMsg(
        action: MouseAction.release,
        button: MouseButton.left,
        x: 10,
        y: 20,
      );

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString includes action and position', () {
      const msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 10,
        y: 20,
      );
      final str = msg.toString();
      expect(str, contains('MouseMsg'));
      expect(str, contains('press'));
      expect(str, contains('10'));
      expect(str, contains('20'));
    });
  });

  group('FocusMsg', () {
    test('stores focus state', () {
      const gained = FocusMsg(true);
      const lost = FocusMsg(false);

      expect(gained.focused, isTrue);
      expect(lost.focused, isFalse);
    });

    test('equality works correctly', () {
      const msg1 = FocusMsg(true);
      const msg2 = FocusMsg(true);
      const msg3 = FocusMsg(false);

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString indicates focus state', () {
      const gained = FocusMsg(true);
      const lost = FocusMsg(false);

      expect(gained.toString(), contains('gained'));
      expect(lost.toString(), contains('lost'));
    });
  });

  group('PasteMsg', () {
    test('stores pasted content', () {
      const msg = PasteMsg('hello world');
      expect(msg.content, 'hello world');
    });

    test('equality works correctly', () {
      const msg1 = PasteMsg('hello');
      const msg2 = PasteMsg('hello');
      const msg3 = PasteMsg('world');

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString shows content length', () {
      const msg = PasteMsg('hello');
      expect(msg.toString(), contains('5'));
    });
  });

  group('CustomMsg', () {
    test('wraps any value', () {
      final msg = CustomMsg<int>(42);
      expect(msg.value, 42);
    });

    test('factory constructor works', () {
      final msg = CustomMsg.of('hello');
      expect(msg.value, 'hello');
    });

    test('equality works for same type and value', () {
      final msg1 = CustomMsg<String>('hello');
      final msg2 = CustomMsg<String>('hello');
      final msg3 = CustomMsg<String>('world');

      expect(msg1, equals(msg2));
      expect(msg1, isNot(equals(msg3)));
    });

    test('toString includes type and value', () {
      final msg = CustomMsg<int>(42);
      final str = msg.toString();
      expect(str, contains('CustomMsg'));
      expect(str, contains('42'));
    });
  });

  group('MouseButton enum', () {
    test('has expected values', () {
      expect(MouseButton.values, contains(MouseButton.none));
      expect(MouseButton.values, contains(MouseButton.left));
      expect(MouseButton.values, contains(MouseButton.middle));
      expect(MouseButton.values, contains(MouseButton.right));
      expect(MouseButton.values, contains(MouseButton.wheelUp));
      expect(MouseButton.values, contains(MouseButton.wheelDown));
    });
  });

  group('MouseAction enum', () {
    test('has expected values', () {
      expect(MouseAction.values, contains(MouseAction.press));
      expect(MouseAction.values, contains(MouseAction.release));
      expect(MouseAction.values, contains(MouseAction.motion));
      expect(MouseAction.values, contains(MouseAction.wheel));
    });
  });
}
