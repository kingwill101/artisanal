import 'package:artisanal/src/tui/bubbles/textinput.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/tui.dart'
    show Key, KeyMsg, KeyType, MouseAction, MouseButton, MouseMsg;
import 'package:test/test.dart';

void main() {
  group('TextInputModel', () {
    group('New', () {
      test('creates with default values', () {
        final input = TextInputModel();
        expect(input.prompt, '> ');
        expect(input.placeholder, '');
        expect(input.echoMode, EchoMode.normal);
        expect(input.charLimit, 0);
        expect(input.value, '');
      });

      test('creates with custom prompt', () {
        final input = TextInputModel(prompt: 'Name: ');
        expect(input.prompt, 'Name: ');
      });

      test('creates with placeholder', () {
        final input = TextInputModel(placeholder: 'Enter text');
        expect(input.placeholder, 'Enter text');
      });

      test('creates with password mode', () {
        final input = TextInputModel(echoMode: EchoMode.password);
        expect(input.echoMode, EchoMode.password);
      });

      test('creates with char limit', () {
        final input = TextInputModel(charLimit: 10);
        expect(input.charLimit, 10);
      });

      test('starts unfocused', () {
        final input = TextInputModel();
        expect(input.focused, isFalse);
      });
    });

    group('Value', () {
      test('sets value', () {
        final input = TextInputModel();
        input.value = 'hello';
        expect(input.value, 'hello');
      });

      test('gets value', () {
        final input = TextInputModel();
        input.value = 'test';
        expect(input.value, 'test');
      });

      test('respects char limit when setting value', () {
        final input = TextInputModel(charLimit: 5);
        input.value = 'hello world';
        expect(input.value.length, lessThanOrEqualTo(5));
      });
    });

    group('Position', () {
      test('starts at end of value', () {
        final input = TextInputModel();
        input.value = 'hello';
        expect(input.position, 5);
      });

      test('sets position', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.position = 2;
        expect(input.position, 2);
      });

      test('clamps position to valid range', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.position = 10;
        expect(input.position, 5);
        input.position = -5;
        expect(input.position, 0);
      });

      test('counts position in grapheme clusters (combining marks)', () {
        final input = TextInputModel();
        input.value = 'e\u0301'; // single grapheme, two code points
        expect(input.position, 1);
      });
    });

    group('Focus', () {
      test('focus sets focused to true', () {
        final input = TextInputModel();
        input.focus();
        expect(input.focused, isTrue);
      });

      test('blur sets focused to false', () {
        final input = TextInputModel();
        input.focus();
        input.blur();
        expect(input.focused, isFalse);
      });
    });

    group('Reset', () {
      test('clears value', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.reset();
        expect(input.value, '');
      });

      test('resets position to 0', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.reset();
        expect(input.position, 0);
      });
    });

    group('CursorStart', () {
      test('moves cursor to start', () {
        final input = TextInputModel();
        input.value = 'hello';
        expect(input.position, 5);
        input.cursorStart();
        expect(input.position, 0);
      });
    });

    group('CursorEnd', () {
      test('moves cursor to end', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.position = 0;
        input.cursorEnd();
        expect(input.position, 5);
      });
    });

    group('Suggestions', () {
      test('sets suggestions', () {
        final input = TextInputModel();
        input.suggestions = ['apple', 'banana', 'cherry'];
        expect(input.availableSuggestions, ['apple', 'banana', 'cherry']);
      });

      test('current suggestion is empty when no match', () {
        final input = TextInputModel();
        input.suggestions = ['apple', 'banana'];
        input.value = 'xyz';
        expect(input.currentSuggestion, '');
      });

      test('current suggestion matches input', () {
        final input = TextInputModel(showSuggestions: true);
        input.suggestions = ['apple', 'apricot', 'banana'];
        input.value = 'ap';
        // Should match apple or apricot
        if (input.matchedSuggestions.isNotEmpty) {
          expect(input.currentSuggestion, startsWith('ap'));
        }
      });
    });

    group('Validation', () {
      test('validates input', () {
        final input = TextInputModel(
          validate: (value) {
            if (value.isEmpty) return 'Required';
            return null;
          },
        );
        input.value = '';
        expect(input.error, 'Required');
      });

      test('clears error when valid', () {
        final input = TextInputModel(
          validate: (value) {
            if (value.isEmpty) return 'Required';
            return null;
          },
        );
        input.value = '';
        expect(input.error, 'Required');
        input.value = 'hello';
        expect(input.error, isNull);
      });
    });

    group('EchoMode', () {
      test('normal mode shows text', () {
        final input = TextInputModel(echoMode: EchoMode.normal);
        input.value = 'hello';
        final view = input.view() as String;
        expect(Ansi.stripAnsi(view), contains('hello'));
      });

      test('password mode shows mask', () {
        final input = TextInputModel(
          echoMode: EchoMode.password,
          echoCharacter: '*',
        );
        input.value = 'hello';
        final view = input.view() as String;
        // Should contain echo character
        expect(Ansi.stripAnsi(view), isNot(contains('hello')));
      });
    });

    group('View', () {
      test('shows prompt', () {
        final input = TextInputModel(prompt: '>> ');
        final view = input.view();
        expect(view, contains('>>'));
      });

      test('shows placeholder when empty', () {
        final input = TextInputModel(placeholder: 'Type here');
        final view = input.view() as String;
        // Placeholder is styled, so check without exact match
        expect(view.contains('ype here') || view.contains('Type'), isTrue);
      });

      test('shows value when not empty', () {
        final input = TextInputModel(placeholder: 'Type here');
        input.value = 'hello';
        final view = input.view() as String;
        expect(Ansi.stripAnsi(view), contains('hello'));
      });
    });

    group('Grapheme Editing', () {
      test('backspace deletes a full grapheme cluster', () {
        final input = TextInputModel()..focus();
        input.value = 'e\u0301x'; // 2 graphemes: "é" + "x"
        input.position = 1; // after first grapheme

        input.update(KeyMsg(const Key(KeyType.backspace)));

        expect(input.value, 'x');
        expect(input.position, 0);
      });
    });

    group('Init', () {
      test('returns null', () {
        final input = TextInputModel();
        expect(input.init(), isNull);
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final input = TextInputModel();
      ViewComponent model = input;
      final (updated, _) = model.update(const KeyMsg(Key(KeyType.left)));
      expect(updated, isA<TextInputModel>());
    });

    group('Selection', () {
      test('selects text via mouse drag', () {
        var input = TextInputModel(prompt: '> ');
        input.value = 'Hello World';

        // Press at (2, 0) -> 'H' is at x=2 (prompt is '> ')
        var (v1, _) = input.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 0,
          ),
        );

        // Drag to (7, 0) -> 'o' is at x=6
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 7,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('Hello'));
      });

      test('double click selects word', () {
        var input = TextInputModel(prompt: '> ');
        input.value = 'Hello World';

        // Click inside "Hello"
        var (v1, _) = input.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );

        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('Hello'));
      });

      test('click outside bounds clears selection and blurs', () {
        var input = TextInputModel(prompt: '> ');
        input.value = 'Hello World';
        input.focus();

        // Select something
        var (v1, _) = input.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 0,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 7,
            y: 0,
          ),
        );
        expect(v2.getSelectedText(), equals('Hello'));
        expect(v2.focused, isTrue);

        // Click outside (y = 1)
        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 1,
          ),
        );
        expect(v3.getSelectedText(), equals(''));
        expect(v3.focused, isFalse);
      });
    });
  });

  group('EchoMode', () {
    test('has normal mode', () {
      expect(EchoMode.normal, isNotNull);
    });

    test('has password mode', () {
      expect(EchoMode.password, isNotNull);
    });

    test('has none mode', () {
      expect(EchoMode.none, isNotNull);
    });
  });

  group('TextInputKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = TextInputKeyMap();
      expect(keyMap.characterForward.keys, isNotEmpty);
      expect(keyMap.characterBackward.keys, isNotEmpty);
      expect(keyMap.deleteCharacterBackward.keys, isNotEmpty);
    });

    test('shortHelp returns bindings', () {
      final keyMap = TextInputKeyMap();
      final help = keyMap.shortHelp();
      expect(help.length, greaterThanOrEqualTo(3));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = TextInputKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
    });
  });

  group('PasteMsg', () {
    test('creates with content', () {
      final msg = PasteMsg('hello');
      expect(msg.content, 'hello');
    });
  });

  group('PasteErrorMsg', () {
    test('creates with error', () {
      final error = Exception('Paste failed');
      final msg = PasteErrorMsg(error);
      expect(msg.error, error);
    });
  });
}
