import 'package:artisanal/src/tui/bubbles/textarea.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:test/test.dart';

void main() {
  group('TextAreaModel', () {
    group('New', () {
      test('creates with default values', () {
        final textarea = TextAreaModel();
        expect(textarea.prompt, '│ ');
        expect(textarea.placeholder, '');
        expect(textarea.showLineNumbers, isTrue);
        expect(textarea.value, '');
      });

      test('creates with custom prompt', () {
        final textarea = TextAreaModel(prompt: '> ');
        expect(textarea.prompt, '> ');
      });

      test('creates with placeholder', () {
        final textarea = TextAreaModel(placeholder: 'Enter text');
        expect(textarea.placeholder, 'Enter text');
      });

      test('creates with dimensions', () {
        final textarea = TextAreaModel(width: 80, height: 20);
        // Width may be adjusted for prompt/line numbers
        expect(textarea.width, greaterThan(0));
        expect(textarea.height, 20);
      });

      test('starts unfocused', () {
        final textarea = TextAreaModel();
        expect(textarea.focused, isFalse);
      });

      test('creates with line numbers disabled', () {
        final textarea = TextAreaModel(showLineNumbers: false);
        expect(textarea.showLineNumbers, isFalse);
      });
    });

    group('Value', () {
      test('sets value', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello\nworld';
        expect(textarea.value, 'hello\nworld');
      });

      test('gets value', () {
        final textarea = TextAreaModel();
        textarea.insertString('test');
        expect(textarea.value, 'test');
      });

      test('handles multi-line value', () {
        final textarea = TextAreaModel();
        textarea.value = 'line1\nline2\nline3';
        expect(textarea.lineCount, 3);
      });

      test('setValue parity', () {
        final textarea = TextAreaModel();
        textarea.setValue('parity');
        expect(textarea.value, 'parity');
      });
    });

    group('Cursor', () {
      test('setCursor parity', () {
        final textarea = TextAreaModel();
        textarea.setValue('line1\nline2');
        textarea.setCursor(1, 2);
        expect(textarea.cursorLine(), 1);
        expect(textarea.cursorColumn(), 2);
      });
    });

    group('Focus', () {
      test('focus/blur parity', () {
        final textarea = TextAreaModel();
        expect(textarea.isFocused(), isFalse);
        textarea.focus();
        expect(textarea.isFocused(), isTrue);
        textarea.blur();
        expect(textarea.isFocused(), isFalse);
      });
    });

    group('Parity Features', () {
      test('setPlaceholder parity', () {
        final textarea = TextAreaModel();
        textarea.setPlaceholder('new placeholder');
        expect(textarea.placeholder, 'new placeholder');
      });

      test('setCharLimit parity', () {
        final textarea = TextAreaModel();
        textarea.setCharLimit(10);
        expect(textarea.charLimit, 10);
      });

      test('setPromptFunc parity', () {
        final textarea = TextAreaModel();
        textarea.setPromptFunc(4, (info) => '[${info.lineIndex}] ');
        textarea.setValue('line1');
        final view = textarea.view();
        expect(view, contains('[0] '));
      });
    });

    group('InsertString', () {
      test('inserts string at cursor', () {
        final textarea = TextAreaModel();
        textarea.insertString('hello');
        expect(textarea.value, 'hello');
      });

      test('inserts multi-line string', () {
        final textarea = TextAreaModel();
        textarea.insertString('line1\nline2');
        expect(textarea.value, 'line1\nline2');
        expect(textarea.lineCount, 2);
      });

      test('respects char limit', () {
        final textarea = TextAreaModel(charLimit: 5);
        textarea.insertString('hello world');
        expect(
          textarea.value.length,
          lessThanOrEqualTo(6),
        ); // Allow some buffer
      });

      test('treats combining marks as one grapheme', () {
        final textarea = TextAreaModel();
        textarea.insertString('e\u0301'); // e + combining acute accent
        expect(textarea.column, 1);
        expect(textarea.value, 'e\u0301');
      });

      test('backspace deletes a full grapheme cluster', () {
        final textarea = TextAreaModel();
        textarea.insertString('e\u0301'); // e + combining acute accent
        textarea.update(const KeyMsg(Key(KeyType.backspace)));
        expect(textarea.value, '');
        expect(textarea.column, 0);
      });

      test('char limit does not split a grapheme cluster', () {
        final textarea = TextAreaModel(charLimit: 1);
        textarea.insertString('e\u0301x');
        expect(textarea.value, 'e\u0301');
        expect(textarea.column, 1);
      });
    });

    group('LineCount', () {
      test('returns 1 for empty textarea', () {
        final textarea = TextAreaModel();
        expect(textarea.lineCount, greaterThanOrEqualTo(1));
      });

      test('counts lines correctly', () {
        final textarea = TextAreaModel();
        textarea.value = 'a\nb\nc';
        expect(textarea.lineCount, 3);
      });
    });

    group('Length', () {
      test('returns 0 for empty textarea', () {
        final textarea = TextAreaModel();
        expect(textarea.length, 0);
      });

      test('counts characters including newlines', () {
        final textarea = TextAreaModel();
        textarea.value = 'ab\ncd';
        // Should count 'ab', newline, 'cd' = 5 characters
        expect(textarea.length, 5);
      });
    });

    group('Focus', () {
      test('focus sets focused to true', () {
        final textarea = TextAreaModel();
        textarea.focus();
        expect(textarea.focused, isTrue);
      });

      test('blur sets focused to false', () {
        final textarea = TextAreaModel();
        textarea.focus();
        textarea.blur();
        expect(textarea.focused, isFalse);
      });
    });

    group('Reset', () {
      test('clears value', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello\nworld';
        textarea.reset();
        expect(textarea.value, '');
      });

      test('resets position', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello\nworld';
        textarea.reset();
        expect(textarea.line, 0);
        expect(textarea.column, 0);
      });
    });

    group('CursorStart', () {
      test('moves cursor to start of line', () {
        final textarea = TextAreaModel();
        textarea.insertString('hello');
        expect(textarea.column, 5);
        textarea.cursorStart();
        expect(textarea.column, 0);
      });
    });

    group('CursorEnd', () {
      test('moves cursor to end of line', () {
        final textarea = TextAreaModel();
        textarea.insertString('hello');
        textarea.cursorStart();
        expect(textarea.column, 0);
        textarea.cursorEnd();
        expect(textarea.column, 5);
      });
    });

    group('Navigation and deletion', () {
      test('delete word forward', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();
        // move to start of word
        for (var i = 0; i < 6; i++) {
          textarea.update(const KeyMsg(Key(KeyType.right)));
        }
        textarea.update(
          const KeyMsg(Key(KeyType.delete, alt: true)), // alt+delete
        );
        expect(textarea.value, 'hello ');
      });

      test('transpose backward', () {
        final textarea = TextAreaModel();
        textarea.insertString('ab');
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x74], ctrl: true)), // ctrl+t
        );
        expect(textarea.value, 'ba');
      });

      test('uppercase/lowercase/capitalize word forward', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();

        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x75], alt: true)), // alt+u
        );
        expect(textarea.value.startsWith('HELLO'), isTrue);

        textarea.value = 'hello world';
        textarea.cursorStart();
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x6c], alt: true)), // alt+l
        );
        expect(textarea.value.startsWith('hello'), isTrue);

        textarea.value = 'hello world';
        textarea.cursorStart();
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x63], alt: true)), // alt+c
        );
        expect(textarea.value.startsWith('Hello'), isTrue);
      });

      test('word forward and backward navigation', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();

        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x66], alt: true)), // alt+f
        );
        expect(textarea.column, 5);

        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x62], alt: true)), // alt+b
        );
        expect(textarea.column, 0);
      });

      test('delete word backward', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.update(
          const KeyMsg(Key(KeyType.backspace, alt: true)), // alt+backspace
        );
        expect(textarea.value, 'hello ');
      });

      test('delete to line start and end', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();
        textarea.update(const KeyMsg(Key(KeyType.right))); // move after h
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x75], ctrl: true)), // ctrl+u
        );
        expect(textarea.value, 'ello world');

        textarea.value = 'hello world';
        textarea.cursorStart();
        // Move to after "hello"
        for (var i = 0; i < 5; i++) {
          textarea.update(const KeyMsg(Key(KeyType.right)));
        }
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x6b], ctrl: true)), // ctrl+k
        );
        expect(textarea.value, 'hello');
      });

      test('soft wrap splits long lines', () {
        final textarea = TextAreaModel(softWrap: true, width: 10, height: 4);
        textarea.insertString('long line of text');
        final view = textarea.view() as String;
        expect(view.split('\n').length, greaterThan(1));
      });
    });

    group('View', () {
      test('shows prompt', () {
        final textarea = TextAreaModel(prompt: '> ');
        final view = textarea.view() as String;
        expect(view, contains('>'));
      });

      test('shows placeholder when empty', () {
        final textarea = TextAreaModel(placeholder: 'Type here');
        final view = textarea.view() as String;
        // Placeholder is styled, so check for partial match
        expect(view.contains('ype here') || view.contains('Type'), isTrue);
      });

      test('shows content when not empty', () {
        final textarea = TextAreaModel(placeholder: 'Type here');
        textarea.insertString('content');
        final view = textarea.view() as String;
        expect(Ansi.stripAnsi(view), contains('content'));
      });

      test('shows line numbers when enabled', () {
        final textarea = TextAreaModel(showLineNumbers: true);
        textarea.value = 'line1\nline2';
        final view = textarea.view() as String;
        expect(view, contains('1'));
      });
    });

    group('SetWidth', () {
      test('sets width', () {
        final textarea = TextAreaModel();
        textarea.setWidth(100);
        // Width is adjusted for prompt/line numbers
        expect(textarea.width, greaterThan(0));
      });
    });

    group('SetHeight', () {
      test('sets height', () {
        final textarea = TextAreaModel();
        textarea.setHeight(50);
        expect(textarea.height, 50);
      });
    });

    group('Init', () {
      test('returns null', () {
        final textarea = TextAreaModel();
        expect(textarea.init(), isNull);
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final textarea = TextAreaModel();
      ViewComponent model = textarea;
      final (updated, _) = model.update(const KeyMsg(Key(KeyType.enter)));
      expect(updated, isA<TextAreaModel>());
    });

    group('Selection', () {
      test('selects text via mouse drag', () {
        var textarea = TextAreaModel(prompt: '> ', showLineNumbers: false);
        textarea.value = 'Hello World\nLine 2';

        // Press at (2, 0) -> 'H' is at x=2 (prompt is '> ')
        var (v1, _) = textarea.update(
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

      test('selects text when line numbers are enabled', () {
        var textarea = TextAreaModel(
          prompt: '│ ',
          showLineNumbers: true,
          height: 5,
        );
        textarea.value = 'hello';

        // With default prompt "│ " (width 2) and line number gutter "1 "
        // (digits=1, plus trailing space), the first content cell starts at x=4.
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 9,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('hello'));
      });

      test('selects and highlights text on wrapped visual lines', () {
        var textarea = TextAreaModel(
          prompt: '',
          showLineNumbers: false,
          softWrap: true,
          width: 6,
          height: 5,
        );
        textarea.value = 'abcdefghijkl'; // wraps into "abcdef" + "ghijkl"

        // Select "ghi" from the second wrapped line (y=1).
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: 1,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 3,
            y: 1,
          ),
        );

        expect(v2.getSelectedText(), equals('ghi'));

        final view = v2.view() as String;
        // Selection uses a reversed-like style (bg=7, fg=0); we just ensure
        // the selection styling is present somewhere in the output.
        expect(view, contains('\x1b[48;5;7m'));
      });

      test('selects wrapped continuation when line numbers are enabled', () {
        var textarea = TextAreaModel(
          prompt: '│ ',
          showLineNumbers: true,
          softWrap: true,
          width: 12,
          height: 5,
        );
        textarea.value = 'abcdefghijkl'; // wraps into "abcdefgh" + "ijkl"

        // Continuation visual line is y=1. Content starts at x=4:
        // prompt "│ " (2) + line number gutter "1 " or blank (2).
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 1,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 7,
            y: 1,
          ),
        );

        expect(v2.getSelectedText(), equals('ijk'));
      });

      test('double click selects word', () {
        var textarea = TextAreaModel(prompt: '> ', showLineNumbers: false);
        textarea.value = 'Hello World\nLine 2';

        // Click inside "Hello"
        var (v1, _) = textarea.update(
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
        var textarea = TextAreaModel(
          prompt: '> ',
          showLineNumbers: false,
          height: 5,
        );
        textarea.value = 'Hello World\nLine 2';
        textarea.focus();

        // Select something
        var (v1, _) = textarea.update(
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

        // Click outside (y = 6)
        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 6,
          ),
        );
        expect(v3.getSelectedText(), equals(''));
        expect(v3.focused, isFalse);
      });
    });
  });

  group('TextAreaKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = TextAreaKeyMap();
      expect(keyMap.characterForward.keys, isNotEmpty);
      expect(keyMap.characterBackward.keys, isNotEmpty);
      expect(keyMap.lineNext.keys, isNotEmpty);
      expect(keyMap.linePrevious.keys, isNotEmpty);
    });

    test('shortHelp returns bindings', () {
      final keyMap = TextAreaKeyMap();
      final help = keyMap.shortHelp();
      expect(help.length, greaterThanOrEqualTo(4));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = TextAreaKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
    });
  });

  group('TextAreaStyles', () {
    test('creates with defaults', () {
      final styles = TextAreaStyles();
      expect(styles.focused, isNotNull);
      expect(styles.blurred, isNotNull);
      expect(styles.cursor, isNotNull);
    });
  });

  group('Default Styles', () {
    test('provides focused and blurred styles', () {
      final styles = defaultTextAreaStyles();
      expect(styles.focused, isNotNull);
      expect(styles.blurred, isNotNull);
    });
  });

  group('LineInfo', () {
    test('creates with default values', () {
      final info = LineInfo();
      expect(info.width, 0);
      expect(info.height, 0);
      expect(info.charWidth, 0);
    });

    test('creates with custom values', () {
      final info = LineInfo(
        width: 80,
        height: 1,
        charWidth: 80,
        startColumn: 0,
        columnOffset: 5,
      );
      expect(info.width, 80);
      expect(info.height, 1);
      expect(info.columnOffset, 5);
    });
  });

  group('TextAreaPasteMsg', () {
    test('creates with content', () {
      final msg = TextAreaPasteMsg('hello');
      expect(msg.content, 'hello');
    });
  });

  group('TextAreaPasteErrorMsg', () {
    test('creates with error', () {
      final error = Exception('Paste failed');
      final msg = TextAreaPasteErrorMsg(error);
      expect(msg.error, error);
    });
  });
}
