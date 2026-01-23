import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('CursorModel', () {
    group('New', () {
      test('creates with default values', () {
        final cursor = CursorModel();
        expect(cursor.mode, CursorMode.blink);
        expect(cursor.char, ' ');
        expect(cursor.blinkSpeed, Duration(milliseconds: 530));
      });

      test('creates with custom mode', () {
        final cursor = CursorModel(mode: CursorMode.static);
        expect(cursor.mode, CursorMode.static);
      });

      test('creates with custom char', () {
        final cursor = CursorModel(char: '█');
        expect(cursor.char, '█');
      });

      test('creates with custom blink speed', () {
        final cursor = CursorModel(blinkSpeed: Duration(milliseconds: 250));
        expect(cursor.blinkSpeed, Duration(milliseconds: 250));
      });

      test('each cursor gets unique ID', () {
        final cursor1 = CursorModel();
        final cursor2 = CursorModel();
        expect(cursor1.id, isNot(cursor2.id));
      });

      test('starts unfocused', () {
        final cursor = CursorModel();
        expect(cursor.focused, isFalse);
      });
    });

    group('Focus', () {
      test('sets focused to true', () {
        final cursor = CursorModel();
        final (focused, _) = cursor.focus();
        expect(focused.focused, isTrue);
      });

      test('returns blink command in blink mode', () {
        final cursor = CursorModel(mode: CursorMode.blink);
        final (_, cmd) = cursor.focus();
        expect(cmd, isNotNull);
      });

      test('returns no command in static mode', () {
        final cursor = CursorModel(mode: CursorMode.static);
        final (_, cmd) = cursor.focus();
        expect(cmd, isNull);
      });
    });

    group('Blur', () {
      test('sets focused to false', () {
        final cursor = CursorModel();
        final (focused, _) = cursor.focus();
        final blurred = focused.blur();
        expect(blurred.focused, isFalse);
      });
    });

    group('SetChar', () {
      test('updates cursor character', () {
        final cursor = CursorModel(char: ' ');
        final updated = cursor.setChar('█');
        expect(updated.char, '█');
      });

      test('preserves other properties', () {
        final cursor = CursorModel(
          mode: CursorMode.static,
          blinkSpeed: Duration(milliseconds: 100),
        );
        final updated = cursor.setChar('x');
        expect(updated.mode, CursorMode.static);
        expect(updated.blinkSpeed, Duration(milliseconds: 100));
      });
    });

    group('SetMode', () {
      test('updates cursor mode to static', () {
        final cursor = CursorModel(mode: CursorMode.blink);
        final (updated, _) = cursor.setMode(CursorMode.static);
        expect(updated.mode, CursorMode.static);
      });

      test('updates cursor mode to hide', () {
        final cursor = CursorModel(mode: CursorMode.blink);
        final (updated, _) = cursor.setMode(CursorMode.hide);
        expect(updated.mode, CursorMode.hide);
      });

      test('returns blink command when setting to blink while focused', () {
        final cursor = CursorModel(mode: CursorMode.static);
        final (focused, _) = cursor.focus();
        final (_, cmd) = focused.setMode(CursorMode.blink);
        expect(cmd, isNotNull);
      });
    });

    group('Update', () {
      test('handles FocusMsg(focused: true)', () {
        final cursor = CursorModel();
        final (updated, _) = cursor.update(FocusMsg(true));
        expect((updated).focused, isTrue);
      });

      test('handles FocusMsg(focused: false)', () {
        final cursor = CursorModel();
        final (focused, _) = cursor.focus();
        final (blurred, _) = focused.update(FocusMsg(false));
        expect((blurred).focused, isFalse);
      });

      test('ignores blink messages from other cursors', () {
        final cursor = CursorModel();
        final (focused, _) = cursor.focus();
        final msg = CursorBlinkMsg(id: focused.id + 999, tag: 0);
        final (result, cmd) = focused.update(msg);
        expect(result, focused);
        expect(cmd, isNull);
      });

      test('ignores non-cursor messages', () {
        final cursor = CursorModel();
        final (result, cmd) = cursor.update(_MockMsg());
        expect(result, cursor);
        expect(cmd, isNull);
      });
    });

    group('View', () {
      test('renders character when cursor is visible', () {
        final cursor = CursorModel(char: 'x', mode: CursorMode.static);
        final (focused, _) = cursor.focus();
        // After focus, the cursor should show with highlight
        expect(focused.view(), isNotEmpty);
      });

      test('renders character in hidden mode', () {
        final cursor = CursorModel(char: 'x', mode: CursorMode.hide);
        expect(cursor.view(), 'x');
      });
    });

    group('CopyWith', () {
      test('creates copy with changed mode', () {
        final cursor = CursorModel(mode: CursorMode.blink);
        final copy = cursor.copyWith(mode: CursorMode.static);
        expect(copy.mode, CursorMode.static);
        expect(cursor.mode, CursorMode.blink);
      });

      test('creates copy with changed char', () {
        final cursor = CursorModel(char: ' ');
        final copy = cursor.copyWith(char: '█');
        expect(copy.char, '█');
        expect(cursor.char, ' ');
      });

      test('preserves ID on copy', () {
        final cursor = CursorModel();
        final copy = cursor.copyWith(char: 'x');
        expect(copy.id, cursor.id);
      });
    });

    group('Init', () {
      test('returns null', () {
        final cursor = CursorModel();
        expect(cursor.init(), isNull);
      });
    });
  });

  group('CursorMode', () {
    test('has blink mode', () {
      expect(CursorMode.blink, isNotNull);
    });

    test('has static mode', () {
      expect(CursorMode.static, isNotNull);
    });

    test('has hide mode', () {
      expect(CursorMode.hide, isNotNull);
    });
  });

  group('CursorBlinkMsg', () {
    test('creates with id and tag', () {
      final msg = CursorBlinkMsg(id: 1, tag: 2);
      expect(msg.id, 1);
      expect(msg.tag, 2);
    });
  });
}

class _MockMsg implements Msg {}
